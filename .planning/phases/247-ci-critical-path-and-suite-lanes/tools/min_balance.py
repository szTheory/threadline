#!/usr/bin/env python3
"""Phase 247 Plan 27 (D-25(b)): min-lane weight derivation and replay.

Standard library only; run as `python3 -I`. The repository root is resolved
from this file's own path, so a scratch copy (`git archive`) works the same
way. Every subcommand prints JSON on stdout and exits non-zero when any check
is violated. Not a CI gate.

  fetch --out <dir>
      Verify 247-FROZEN-REPLAY.json against its pinned sha256, download the
      partition-timings-min-<run> artifacts of the three B4 training runs into
      <dir>/train/<run>/min and of B4 holdout 40451533079 into
      <dir>/holdout/40451533079/min, write diagnostic 40504321590's
      raw_min_timings texts to <dir>/holdout/40504321590/min, and require all
      20 TSVs to equal their pinned artifact_sha256.
  derive --rule max --train <dir> --output <path>
      Strictly validate the three training runs by running the runner's own
      strict ingest in a temporary copy of the lane weights path, then write
      the per-file maximum wall_ms (floor 1) in the ingest's header and
      `<ms> <file>` format, sorted by path. Any other rule is refused.
  predict --lane <current|min|latest> [--weights <path>] [--max-ratio R]
      Run `bin/ci-test-partitions 4` with MIX_BIN=false (it stops at the
      serial compile, before any test runs), recompute S, A, L, D and
      cost = S + max(D, L) per partition, and cross-check every partition's
      effective-weight sum against the runner's printed weight.
  replay --lane min --root <dir> [--weights <path>]
      Cost the production assignment of the (candidate) min weights against
      each <root>/**/<run>/min run's observed per-file wall_ms.
  --self-test
      Offline unit checks of the cost, derivation, hash and restore logic.

`--weights` places a candidate at the lane path temporarily and restores the
original bytes afterwards, including on error or signal.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path

PHASE_DIR = Path(__file__).resolve().parents[1]
ROOT = PHASE_DIR.parents[2]
RUNNER_REL = "bin/ci-test-partitions"
COLOCATE_REL = "test/partition_colocate.txt"
LANE_WEIGHTS = {
    "current": "test/partition_weights.txt",
    "min": "test/partition_weights_min.txt",
    "latest": "test/partition_weights_latest.txt",
}
REPO = "szTheory/threadline"
FROZEN_REPLAY_SHA256 = "5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1"
TRAIN_RUNS = [40449332597, 40450141708, 40450801580]
B4_HOLDOUT = 40451533079
DIAG_RUN = 40504321590
N_PARTITIONS = 4
SPACE = r"[ \t\r\f\v]"
ASYNC_RX = re.compile(r"^" + SPACE + r"*use [A-Za-z0-9_.]+,.*async:" + SPACE + r"*true", re.M)
HEADER_RX = re.compile(
    r"# threadline\.partition-timings/1 partition=([1-4]) lane=([a-z][a-z0-9-]*) "
    r"boot_ms=(\d+) wall_ms=(\d+)")
ROW_RX = re.compile(r"test/[^\s]+_test\.exs")
PRINTED_RX = re.compile(r"^ci-test-partitions: partition (\d+): (\d+) files, weight (\d+) ms$", re.M)


class CheckError(Exception):
    pass


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def sha256_file(path):
    return sha256_bytes(Path(path).read_bytes())


def require(cond, message):
    if not cond:
        raise CheckError(message)


# --- formulas -------------------------------------------------------------------

def bin_cost(sync_sum, async_sum, longest_async, factor_permille):
    """cost = S + max(D, L), D = floor(A * factor / 1000), at least 1 when A > 0."""
    discounted = async_sum * factor_permille // 1000
    if async_sum > 0 and discounted < 1:
        discounted = 1
    return sync_sum + max(discounted, longest_async)


def effective_weight(raw, is_async, factor_permille):
    eff = raw * factor_permille // 1000 if is_async else raw
    return max(eff, 1)


def factor_permille(root=ROOT):
    m = re.search(r"^ASYNC_FACTOR_PERMILLE=(\d+)$", (root / RUNNER_REL).read_text(), re.M)
    require(m, "ASYNC_FACTOR_PERMILLE not found in the runner")
    return int(m.group(1))


def is_async(path, root=ROOT):
    return bool(ASYNC_RX.search((root / path).read_text(errors="replace")))


def read_weights(path):
    """Runner semantics: `<ms> <file>` lines, comments and blanks skipped, duplicates summed."""
    weights = {}
    for line in Path(path).read_text().splitlines():
        if re.match(r"^[ \t]*#", line) or re.match(r"^[ \t]*$", line):
            continue
        # awk's split($0, p, /[ \t]+/): a leading blank yields an empty first field.
        bits = re.split(r"[ \t]+", line)
        if len(bits) >= 2 and re.fullmatch(r"[0-9]+", bits[0]):
            weights[bits[1]] = weights.get(bits[1], 0) + int(bits[0])
    return weights


def raw_weight_map(weights, files):
    """Median fallback over the enumerated files that carry a weight (assign_files)."""
    vals = sorted(weights[f] for f in files if f in weights)
    m = len(vals)
    if m == 0:
        med = 1000
    elif m % 2 == 1:
        med = vals[(m + 1) // 2 - 1]
    else:
        med = (vals[m // 2 - 1] + vals[m // 2]) // 2
    return {f: weights.get(f, med) for f in files}


def partition_costs(assignment, amount, async_map, factor):
    """assignment: {partition: [files]}; amount: {file: ms}."""
    out = {}
    for p in sorted(assignment):
        s = a = longest = 0
        for f in assignment[p]:
            if async_map[f]:
                a += amount[f]
                longest = max(longest, amount[f])
            else:
                s += amount[f]
        out[p] = {"S": s, "A": a, "L": longest,
                  "D": (max(1, a * factor // 1000) if a > 0 else 0),
                  "cost": bin_cost(s, a, longest, factor),
                  "files": len(assignment[p])}
    return out


def ratio_of(costs):
    vals = [c["cost"] for c in costs.values() if c["files"] > 0]
    require(vals and min(vals) > 0, "no non-empty partition with a positive cost")
    return max(vals) / min(vals)


# --- TSV parsing ----------------------------------------------------------------

def parse_tsv(text, lane, partition=None):
    lines = text.splitlines()
    header = HEADER_RX.fullmatch(lines[0] if lines else "")
    require(header is not None, "invalid timing header")
    require(header.group(2) == lane, f"wrong-lane timing header: lane={header.group(2)}, expected {lane}")
    if partition is not None:
        require(int(header.group(1)) == partition, f"partition header {header.group(1)} != {partition}")
    rows = {}
    for line in lines[1:]:
        bits = line.split("\t")
        require(len(bits) == 3 and ROW_RX.fullmatch(bits[0]) and bits[1].isdigit() and bits[2].isdigit(),
                f"malformed timing row: {line!r}")
        require(bits[0] not in rows, f"duplicate timing row: {bits[0]}")
        rows[bits[0]] = int(bits[1])
    return {"partition": int(header.group(1)), "boot_ms": int(header.group(3)),
            "wall_ms": int(header.group(4)), "rows": rows}


def load_run(run_dir, lane):
    """A <run>/<lane> directory holding partition-timings-1..4.tsv."""
    parts = {}
    for p in range(1, N_PARTITIONS + 1):
        f = run_dir / f"partition-timings-{p}.tsv"
        require(f.is_file(), f"missing {f}")
        parts[p] = parse_tsv(f.read_text(), lane, p)
    extra = sorted(x.name for x in run_dir.glob("partition-timings-*.tsv")
                   if x.name not in {f"partition-timings-{p}.tsv" for p in range(1, N_PARTITIONS + 1)})
    require(not extra, f"unexpected timing files in {run_dir}: {extra}")
    observed = {}
    for parsed in parts.values():
        for f, wall in parsed["rows"].items():
            require(f not in observed, f"file observed twice in one run: {f}")
            observed[f] = wall
    return {"observed": observed, "max_boot_ms": max(x["boot_ms"] for x in parts.values()),
            "partition_wall_ms": {p: x["wall_ms"] for p, x in parts.items()}}


def find_runs(root, lane):
    runs = {}
    for d in sorted(Path(root).rglob(lane)):
        if d.is_dir() and d.parent.name.isdigit() and any(d.glob("partition-timings-*.tsv")):
            run = d.parent.name
            require(run not in runs, f"run {run} appears twice under {root}")
            runs[run] = d
    require(runs, f"no <run>/{lane} timing directories under {root}")
    return runs


# --- weights placement ----------------------------------------------------------

@contextmanager
def placed(target, candidate):
    """Put candidate bytes at target; restore the original bytes on exit, error or signal."""
    target = Path(target)
    if candidate is None:
        yield
        return
    original = target.read_bytes() if target.exists() else None
    data = Path(candidate).read_bytes()
    previous = {}

    def on_signal(signum, _frame):
        raise KeyboardInterrupt(f"signal {signum}")

    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        previous[sig] = signal.signal(sig, on_signal)
    try:
        target.write_bytes(data)
        yield
    finally:
        if original is None:
            target.unlink(missing_ok=True)
        else:
            target.write_bytes(original)
        for sig, handler in previous.items():
            signal.signal(sig, handler)
        require(original is None or target.read_bytes() == original, f"failed to restore {target}")


# --- predict --------------------------------------------------------------------

def run_assignment(lane, root=ROOT):
    log_dir = Path(tempfile.mkdtemp(prefix="min-balance-predict-"))
    try:
        env = dict(os.environ)
        env.update({"MIX_BIN": "false", "CI_TEST_PARTITIONS_LOG_DIR": str(log_dir / "logs"),
                    "THREADLINE_CI_LANE": lane})
        env.pop("GITHUB_STEP_SUMMARY", None)
        if lane in ("min", "latest"):
            env["THREADLINE_TEST_SCOPE"] = "toolchain"
        else:
            env.pop("THREADLINE_TEST_SCOPE", None)
        proc = subprocess.run([str(root / RUNNER_REL), str(N_PARTITIONS)], cwd=root, env=env,
                              capture_output=True, text=True, timeout=300)
        require(proc.returncode != 0 and "serial compile failed" in proc.stderr,
                f"runner did not stop at the serial compile (exit {proc.returncode}): {proc.stderr[-400:]}")
        assignment_tsv = log_dir / "logs" / "assignment.tsv"
        require(assignment_tsv.is_file(), "runner wrote no assignment.tsv")
        assignment, eff = {p: [] for p in range(1, N_PARTITIONS + 1)}, {}
        for line in assignment_tsv.read_text().splitlines():
            p, f, w = line.split("\t")
            assignment[int(p)].append(f)
            eff[f] = int(w)
        printed = {int(m.group(1)): (int(m.group(2)), int(m.group(3)))
                   for m in PRINTED_RX.finditer(proc.stdout)}
        require(sorted(printed) == list(range(1, N_PARTITIONS + 1)), "runner did not print every partition weight")
        enumerated = (log_dir / "logs" / "enumerated.txt").read_text().splitlines()
        return assignment, eff, printed, enumerated
    finally:
        shutil.rmtree(log_dir, ignore_errors=True)


def predict_core(lane, root=ROOT):
    factor = factor_permille(root)
    assignment, eff, printed, enumerated = run_assignment(lane, root)
    files = sorted(eff)
    require(sorted(enumerated) == files, "assignment does not cover the enumerated files exactly once")
    raw = raw_weight_map(read_weights(root / LANE_WEIGHTS[lane]), enumerated)
    async_map = {f: is_async(f, root) for f in files}
    for f in files:
        require(effective_weight(raw[f], async_map[f], factor) == eff[f],
                f"effective weight mismatch for {f}: runner {eff[f]}")
    for p, members in assignment.items():
        require(printed[p] == (len(members), sum(eff[f] for f in members)),
                f"partition {p}: printed {printed[p]} != recomputed")
    costs = partition_costs(assignment, raw, async_map, factor)
    return {"assignment": assignment, "raw": raw, "async": async_map, "costs": costs,
            "factor": factor, "printed": printed}


def cmd_predict(args):
    lane_path = ROOT / LANE_WEIGHTS[args.lane]
    with placed(lane_path, args.weights):
        core = predict_core(args.lane)
        weights_sha = sha256_file(lane_path)
    ratio = ratio_of(core["costs"])
    out = {
        "lane": args.lane,
        "partitions": N_PARTITIONS,
        "costs_ms": [core["costs"][p]["cost"] for p in sorted(core["costs"])],
        "bins": {str(p): c for p, c in core["costs"].items()},
        "printed_weights_ms": [core["printed"][p][1] for p in sorted(core["printed"])],
        "ratio": round(ratio, 6),
        "files": len(core["raw"]),
        "async_files": sum(1 for v in core["async"].values() if v),
        "all_sync_partitions": [p for p, c in core["costs"].items() if c["files"] > 0 and c["A"] == 0],
        "async_factor_permille": core["factor"],
        "sha256": {"runner": sha256_file(ROOT / RUNNER_REL),
                   "colocation": sha256_file(ROOT / COLOCATE_REL),
                   "weights": weights_sha},
        "weights_source": str(args.weights) if args.weights else LANE_WEIGHTS[args.lane],
    }
    if args.max_ratio is not None:
        out["max_ratio"] = args.max_ratio
        out["within_max_ratio"] = ratio <= args.max_ratio
    print(json.dumps(out, indent=2, sort_keys=True))
    if args.max_ratio is not None and ratio > args.max_ratio:
        return 1
    return 0


# --- replay ---------------------------------------------------------------------

def replay_core(lane, root_dir, root=ROOT):
    core = predict_core(lane, root)
    files = set(core["raw"])
    out = {}
    for run, run_dir in find_runs(root_dir, lane).items():
        data = load_run(run_dir, lane)
        observed = data["observed"]
        require(set(observed) == files,
                f"run {run}: observed inventory differs from the lane inventory "
                f"(missing {sorted(files - set(observed))[:5]}, extra {sorted(set(observed) - files)[:5]})")
        costs = partition_costs(core["assignment"], observed, core["async"], core["factor"])
        errors = sorted(((observed[f] - core["raw"][f], f) for f in files),
                        key=lambda e: (-abs(e[0]), e[1]))[:5]
        out[run] = {"costs_ms": [costs[p]["cost"] for p in sorted(costs)],
                    "spread": round(ratio_of(costs), 6),
                    "max_boot_ms": data["max_boot_ms"],
                    "all_sync_partitions": [p for p, c in costs.items() if c["files"] > 0 and c["A"] == 0],
                    "top_errors": [{"file": f, "observed_ms": observed[f], "weight_ms": core["raw"][f],
                                    "error_ms": e} for e, f in errors]}
    return out


def cmd_replay(args):
    lane_path = ROOT / LANE_WEIGHTS[args.lane]
    with placed(lane_path, args.weights):
        runs = replay_core(args.lane, Path(args.root))
        weights_sha = sha256_file(lane_path)
    print(json.dumps({"lane": args.lane, "weights_sha256": weights_sha, "runs": runs}, indent=2, sort_keys=True))
    return 0


# --- fetch ----------------------------------------------------------------------

def frozen_expectations(phase_dir=PHASE_DIR):
    raw = (phase_dir / "247-FROZEN-REPLAY.json").read_bytes()
    require(sha256_bytes(raw) == FROZEN_REPLAY_SHA256, "247-FROZEN-REPLAY.json differs from its pinned sha256")
    expected = {}
    for item in json.loads(raw)["manifest"]["artifact_hashes"]:
        key = (int(item["run_id"]), item["lane"], int(item["partition"]))
        require(key not in expected, f"duplicate pinned artifact identity {key}")
        expected[key] = item["artifact_sha256"]
    return expected


def verify_hash(path, expected, label):
    actual = sha256_file(path)
    require(actual == expected, f"{label}: sha256 {actual} != pinned {expected}")
    return actual


def cmd_fetch(args):
    out = Path(args.out).resolve()
    expected = frozen_expectations()
    for sub in ("train", "holdout"):
        require(not (out / sub).exists(), f"{out / sub} already exists; use an empty directory")
    plan = [("train", r) for r in TRAIN_RUNS] + [("holdout", B4_HOLDOUT)]
    for group, run in plan:
        dest = out / group / str(run) / "min"
        dest.mkdir(parents=True)
        proc = subprocess.run(["gh", "run", "download", str(run), "-R", REPO,
                               "-n", f"partition-timings-min-{run}", "-D", str(dest)],
                              capture_output=True, text=True, timeout=300)
        require(proc.returncode == 0, f"gh run download {run} failed: {proc.stderr.strip()}")
    diag = json.loads((PHASE_DIR / "247-DIAGNOSTIC-EVIDENCE.json").read_text())["raw_min_timings"]
    dest = out / "holdout" / str(DIAG_RUN) / "min"
    dest.mkdir(parents=True)
    for p in range(1, N_PARTITIONS + 1):
        (dest / f"partition-timings-{p}.tsv").write_bytes(diag[f"partition-timings-{p}.tsv"].encode())
    verified = {}
    for group, run in plan + [("holdout", DIAG_RUN)]:
        run_dir = out / group / str(run) / "min"
        names = sorted(x.name for x in run_dir.iterdir())
        require(names == [f"partition-timings-{p}.tsv" for p in range(1, N_PARTITIONS + 1)],
                f"{run}: unexpected artifact contents {names}")
        for p in range(1, N_PARTITIONS + 1):
            f = run_dir / f"partition-timings-{p}.tsv"
            key = (run, "min", p)
            require(key in expected, f"no pinned hash for {key}")
            verified[f"{run}/min/{p}"] = verify_hash(f, expected[key], f"{run}/min/{p}")
            parse_tsv(f.read_text(), "min", p)
    require(len(verified) == 20, f"expected 20 verified TSVs, got {len(verified)}")
    print(json.dumps({"out": str(out), "frozen_replay_sha256": FROZEN_REPLAY_SHA256,
                      "training_runs": TRAIN_RUNS, "holdout_runs": [B4_HOLDOUT, DIAG_RUN],
                      "verified": len(verified), "tsv_sha256": verified}, indent=2, sort_keys=True))
    return 0


# --- derive ---------------------------------------------------------------------

def strict_ingest_copy(train_dir, lane, root=ROOT):
    """Run the runner's strict ingest in a temporary copy (runner + test tree) and return its output."""
    tmp = Path(tempfile.mkdtemp(prefix="min-balance-derive-"))
    try:
        (tmp / "bin").mkdir()
        shutil.copy2(root / RUNNER_REL, tmp / RUNNER_REL)
        for src in (root / "test").rglob("*"):
            if src.is_file():
                dst = tmp / src.relative_to(root)
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
        proc = subprocess.run([str(tmp / RUNNER_REL), "--ingest-weights", str(Path(train_dir).resolve()),
                               "--lane", lane, "--output", LANE_WEIGHTS[lane]],
                              cwd=tmp, capture_output=True, text=True, timeout=300)
        require(proc.returncode == 0, f"strict ingest rejected the training runs: {proc.stderr.strip()}")
        inventory = sorted(f.relative_to(tmp).as_posix() for f in (tmp / "test").rglob("*_test.exs")
                           if not any(part.startswith(".") for part in f.relative_to(tmp).parts))
        return (tmp / LANE_WEIGHTS[lane]).read_text(), inventory
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def max_rule(header_lines, runs):
    """runs: list of {file: wall_ms}. Per-file maximum, floor 1, sorted by path."""
    files = set().union(*[set(r) for r in runs])
    for r in runs:
        require(set(r) == files, "every file must appear in every training run")
    body = [f"{max(1, max(r[f] for r in runs))} {f}" for f in sorted(files, key=lambda s: s.encode())]
    return "\n".join(list(header_lines) + body) + "\n"


def cmd_derive(args):
    require(args.rule == "max", f"refusing rule {args.rule!r}: only the pre-registered max rule is allowed")
    train = Path(args.train)
    runs = find_runs(train, "min")
    require(sorted(int(r) for r in runs) == TRAIN_RUNS, f"training runs {sorted(runs)} != {TRAIN_RUNS}")
    median_text, _ = strict_ingest_copy(train, "min")
    header = [line for line in median_text.splitlines() if line.startswith("#")]
    require(header and median_text.startswith("\n".join(header) + "\n"), "unexpected ingest header layout")
    observed = [load_run(runs[r], "min")["observed"] for r in sorted(runs)]
    ingested = {line.split(" ", 1)[1] for line in median_text.splitlines() if not line.startswith("#")}
    require(ingested == set(observed[0]), "strict-ingest inventory differs from the observed files")
    text = max_rule(header, observed)
    order = lambda t: [line.split(" ", 1)[1] for line in t.splitlines() if not line.startswith("#")]
    require(order(text) == order(median_text), "max-rule file order differs from the strict ingest's order")
    Path(args.output).write_text(text)
    print(json.dumps({"rule": "max", "training_runs": sorted(int(r) for r in runs), "files": len(ingested),
                      "output": str(args.output), "weights_sha256": sha256_bytes(text.encode())},
                     indent=2, sort_keys=True))
    return 0


# --- self-test ------------------------------------------------------------------

def self_test():
    checks = []

    def check(name, cond):
        require(cond, f"self-test failed: {name}")
        checks.append(name)

    # Long async floor dominates: A=10000 discounts to 2920, but L=9000 wins.
    check("long async floor dominates", bin_cost(5000, 10000, 9000, 292) == 14000)
    check("discount dominates when L is short", bin_cost(5000, 10000, 2000, 292) == 7920)
    # D floor of 1: A=1 discounts to 0, floored to 1, which beats L=1 only by tie.
    check("D floor of 1", bin_cost(0, 1, 0, 292) == 1 and bin_cost(7, 3, 0, 292) == 8)
    check("no async means no D", bin_cost(7, 0, 0, 292) == 7)
    check("effective weight floor", effective_weight(1, True, 292) == 1 and effective_weight(1000, True, 292) == 292)
    costs = partition_costs({1: ["a", "b"], 2: ["c"]}, {"a": 100, "b": 50, "c": 120},
                            {"a": True, "b": True, "c": False}, 292)
    check("partition cost uses longest async raw", costs[1]["cost"] == 100 and costs[2]["cost"] == 120)
    check("ratio over partitions", abs(ratio_of(costs) - 1.2) < 1e-9)
    # Max-rule derivation.
    header = ["# h1", "# h2"]
    text = max_rule(header, [{"test/b_test.exs": 5, "test/a_test.exs": 0},
                             {"test/b_test.exs": 9, "test/a_test.exs": 0},
                             {"test/b_test.exs": 7, "test/a_test.exs": 0}])
    check("max rule", text == "# h1\n# h2\n1 test/a_test.exs\n9 test/b_test.exs\n")
    try:
        max_rule(header, [{"test/a_test.exs": 1}, {}])
        check("max rule rejects a missing file", False)
    except CheckError:
        checks.append("max rule rejects a missing file")
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        f = tmp / "x.tsv"
        f.write_bytes(b"payload")
        try:
            verify_hash(f, sha256_bytes(b"other"), "x")
            check("hash mismatch rejected", False)
        except CheckError:
            checks.append("hash mismatch rejected")
        check("hash match accepted", verify_hash(f, sha256_bytes(b"payload"), "x") == sha256_bytes(b"payload"))
        good = "# threadline.partition-timings/1 partition=2 lane=min boot_ms=5 wall_ms=10\ntest/a_test.exs\t3\t2\n"
        check("min header parses", parse_tsv(good, "min", 2)["rows"] == {"test/a_test.exs": 3})
        try:
            parse_tsv(good.replace("lane=min", "lane=current"), "min", 2)
            check("wrong-lane header rejected", False)
        except CheckError:
            checks.append("wrong-lane header rejected")
        try:
            parse_tsv(good + "bogus\n", "min", 2)
            check("malformed row rejected", False)
        except CheckError:
            checks.append("malformed row rejected")
        # Byte restoration after --weights, on success and on error.
        target, cand = tmp / "weights.txt", tmp / "cand.txt"
        original = b"# header\r\n100 test/a_test.exs\n\n"
        target.write_bytes(original)
        cand.write_bytes(b"1 test/a_test.exs\n")
        with placed(target, cand):
            check("candidate placed", target.read_bytes() == b"1 test/a_test.exs\n")
        check("bytes restored after success", target.read_bytes() == original)
        try:
            with placed(target, cand):
                raise RuntimeError("boom")
        except RuntimeError:
            pass
        check("bytes restored after error", target.read_bytes() == original)
    check("async regex", bool(ASYNC_RX.search("  use ExUnit.Case, async: true\n"))
          and not ASYNC_RX.search("  use ExUnit.Case, async: false\n")
          and not ASYNC_RX.search("# use ExUnit.Case,\n async: true\n"))
    print(json.dumps({"self_test": "pass", "checks": checks}, indent=2))
    return 0


def main(argv):
    if argv == ["--self-test"]:
        return self_test()
    parser = argparse.ArgumentParser(prog="min_balance.py")
    sub = parser.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("fetch")
    p.add_argument("--out", required=True)
    p = sub.add_parser("derive")
    p.add_argument("--rule", required=True)
    p.add_argument("--train", required=True)
    p.add_argument("--output", required=True)
    p = sub.add_parser("predict")
    p.add_argument("--lane", required=True, choices=sorted(LANE_WEIGHTS))
    p.add_argument("--weights")
    p.add_argument("--max-ratio", type=float)
    p = sub.add_parser("replay")
    p.add_argument("--lane", required=True, choices=["min"])
    p.add_argument("--root", required=True)
    p.add_argument("--weights")
    args = parser.parse_args(argv)
    if getattr(args, "weights", None):
        args.weights = str(Path(args.weights).resolve())
    return {"fetch": cmd_fetch, "derive": cmd_derive, "predict": cmd_predict, "replay": cmd_replay}[args.cmd](args)


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except (CheckError, subprocess.SubprocessError, OSError, KeyError, ValueError) as exc:
        print(json.dumps({"error": str(exc)}), file=sys.stderr)
        sys.exit(1)
