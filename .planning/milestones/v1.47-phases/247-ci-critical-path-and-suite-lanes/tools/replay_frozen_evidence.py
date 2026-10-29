#!/usr/bin/env python3
"""Offline, source-bound replay of Phase 247's frozen partition evidence."""
import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
ROOT = BASE.parents[2]
B3_IDS = [40433193088, 40434036118, 40434884357]
B4_IDS = [40449332597, 40450141708, 40450801580, 40451533079]
DIAG_ID = 40504321590
B3_HEAD = "89add23ede29b7840e6cfa29cd70eb3c8ea59ae2"
B4_HEAD = "02d115a32e4479f353d284c04fc838ba58938d16"
DIAG_HEAD = "8177d00d74b03527c2b14bbb0ef17f6c5895b464"
LANES = ("current", "latest", "min")
FROZEN_REPLAY_SHA256 = "5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def file_hash(path):
    return digest(path.read_bytes())


def git(head, path):
    return subprocess.run(["git", "show", f"{head}:{path}"], cwd=ROOT,
                          check=True, stdout=subprocess.PIPE).stdout


def json_file(name):
    return json.loads((BASE / name).read_text())


def frozen_artifact_expectations():
    raw = (BASE / "247-FROZEN-REPLAY.json").read_bytes()
    if digest(raw) != FROZEN_REPLAY_SHA256:
        raise ValueError("saved replay receipt differs from the pinned historical evidence")
    receipt = json.loads(raw)
    expected = {}
    for item in receipt.get("manifest", {}).get("artifact_hashes", []):
        key = (int(item["run_id"]), item["lane"], int(item["partition"]))
        if key in expected:
            raise ValueError(f"duplicate pinned artifact identity: {key}")
        expected[key] = item["artifact_sha256"]
    return expected


def verify_artifact_payload(payload, expected, label):
    actual = digest(payload if isinstance(payload, bytes) else payload.encode())
    if actual != expected:
        raise ValueError(f"{label}: payload digest mismatch (expected {expected}, got {actual})")


def verify_b4_artifact_identity(run, lane, artifacts_path):
    if not artifacts_path.is_file():
        raise ValueError(f"missing saved upstream artifact metadata for B4 run {run}")
    records = json.loads(artifacts_path.read_text())
    expected_name = f"partition-timings-{lane}-{run}"
    matches = [a for a in records if a.get("name") == expected_name]
    if len(matches) != 1 or not matches[0].get("digest", "").startswith("sha256:"):
        raise ValueError(f"B4 artifact name/digest identity missing or ambiguous: {expected_name}")
    workflow = matches[0].get("workflow_run", {})
    if workflow.get("id") != run or workflow.get("head_sha") != B4_HEAD or matches[0].get("expired"):
        raise ValueError(f"B4 artifact run/head/expiry binding mismatch: {expected_name}")
    return {"name": expected_name, "archive_sha256": matches[0]["digest"].removeprefix("sha256:")}


def source(head):
    code = git(head, "bin/ci-test-partitions")
    weights = {lane: git(head, f"test/partition_weights_{lane}.txt").decode()
               if lane != "current" else git(head, "test/partition_weights.txt").decode()
               for lane in LANES}
    colocate = git(head, "test/partition_colocate.txt").decode().splitlines()
    files = subprocess.run(["git", "ls-tree", "-r", "--name-only", head, "test"],
                           cwd=ROOT, check=True, text=True, capture_output=True).stdout.splitlines()
    files = sorted(f for f in files if f.endswith("_test.exs") and "/." not in f)
    async_rx = re.compile(rb"^[ \t]*use [A-Za-z0-9_.]+,.*async:[ \t]*true", re.M)
    repo_rx = re.compile(rb"^[ \t]*@moduletag :repo_contract[ \t]*$", re.M)
    classified = {}
    blob_hashes = {"bin/ci-test-partitions": digest(code),
                   "test/partition_colocate.txt": digest(git(head, "test/partition_colocate.txt"))}
    for path in files:
        blob = git(head, path)
        classified[path] = {"async": bool(async_rx.search(blob)),
                             "repo_contract": bool(repo_rx.search(blob))}
        blob_hashes[path] = digest(blob)
    for lane in LANES:
        p = "test/partition_weights.txt" if lane == "current" else f"test/partition_weights_{lane}.txt"
        blob_hashes[p] = digest(git(head, p))
    factor = int(re.search(rb"ASYNC_FACTOR_PERMILLE=(\d+)", code).group(1))
    return {"head": head, "source_hashes": blob_hashes, "files": files,
            "classified": classified, "weights": weights, "groups": colocate,
            "factor_permille": factor}


def weight_map(src, lane):
    result = {}
    for line in src["weights"][lane].splitlines():
        bits = line.split()
        if len(bits) >= 2 and bits[0].isdigit():
            result[bits[1]] = result.get(bits[1], 0) + int(bits[0])
    vals = sorted(result.values())
    median = 1000 if not vals else vals[(len(vals)-1)//2] if len(vals)%2 else (vals[len(vals)//2-1]+vals[len(vals)//2])//2
    return {f: result.get(f, median) for f in src["files"]}


def parse_tsv(text, run, lane, partition):
    lines = text.splitlines()
    header = re.fullmatch(r"# threadline\.partition-timings/1 partition=([1-4]) lane=(current|latest|min) boot_ms=(\d+) wall_ms=(\d+)", lines[0] if lines else "")
    if not header or int(header[1]) != partition or header[2] != lane:
        raise ValueError(f"{run}/{lane}/{partition}: timing header mismatch")
    files, rows = set(), []
    for line in lines[1:]:
        bits = line.split("\t")
        if len(bits) != 3 or not re.fullmatch(r"test/[^\s]+_test\.exs", bits[0]) or not all(x.isdigit() for x in bits[1:]):
            raise ValueError(f"{run}/{lane}/{partition}: malformed TSV row")
        if bits[0] in files:
            raise ValueError(f"{run}/{lane}/{partition}: duplicate file {bits[0]}")
        files.add(bits[0]); rows.append((bits[0], int(bits[1]), int(bits[2])))
    return {"boot_ms": int(header[3]), "wall_ms": int(header[4]), "rows": rows,
            "file_count": len(rows), "sha256": digest(text.encode())}


def cost(rows, src, lane, observed=False, standardized=False):
    sm = am = longest = 0
    weights = weight_map(src, lane)
    for path, boot, wall in rows:
        async_file = src["classified"].get(path, {}).get("async")
        if async_file is None:
            raise ValueError(f"unclassified source file {path}")
        amount = wall if observed else weights.get(path, 1000)
        if async_file:
            am += amount; longest = max(longest, amount)
        else:
            sm += amount
    factor = 292 if standardized else src["factor_permille"]
    discount = max(1, am * factor // 1000) if am else 0
    return {"sync_sum_ms": sm, "async_sum_ms": am, "longest_async_ms": longest,
            "cost_ms": sm + max(discount, longest),
            "formula": "S + max(floor(A * factor / 1000), L)"}


def grouped_sources():
    b3, b4, diag = source(B3_HEAD), source(B4_HEAD), source(DIAG_HEAD)
    return {B3_HEAD: b3, B4_HEAD: b4, DIAG_HEAD: diag}


def assignments_check(tsvs, src, lane, expected_count):
    assigned = {}
    for p, parsed in tsvs.items():
        for path, _, _ in parsed["rows"]:
            if path in assigned or path not in src["files"]:
                raise ValueError(f"assignment duplicate/outside source inventory: {path}")
            assigned[path] = p
    expected = [f for f in src["files"] if lane == "current" or not src["classified"][f]["repo_contract"]]
    if len(expected) != expected_count or set(expected) != set(assigned):
        raise ValueError(f"{lane}: inventory mismatch expected={len(expected)} observed={len(assigned)}")
    for line in src["groups"]:
        group = [f for f in line.split() if f in assigned]
        if len({assigned[f] for f in group}) > 1:
            raise ValueError("colocation group split across partitions")
    return {"expected_files": expected_count, "observed_files": len(assigned),
            "exactly_once": True, "colocation_groups_valid": True}


def artifact_path(run, lane, p, b3_root, b4_root, diag_root):
    if run in B3_IDS:
        return Path(b3_root) / str(run) / lane / f"partition-timings-{p}.tsv"
    if run in B4_IDS:
        return Path(b4_root) / str(run) / f"partition-timings-{lane}-{run}" / f"partition-timings-{p}.tsv"
    return Path(diag_root) / f"partition-timings-{lane}-{run}" / f"partition-timings-{p}.tsv"


def replay(b3_root, b4_root, diag_root):
    expected_artifacts = frozen_artifact_expectations()
    evidence = {"247-B3-MEASUREMENT.json": json_file("247-B3-MEASUREMENT.json"),
                "247-B4-INCOMPLETE.json": json_file("247-B4-INCOMPLETE.json"),
                "247-DIAGNOSTIC-EVIDENCE.json": json_file("247-DIAGNOSTIC-EVIDENCE.json"),
                "247-LOCAL-CANARY.json": json_file("247-LOCAL-CANARY.json")}
    sources = grouped_sources()
    inputs = {name: file_hash(BASE / name) for name in evidence}
    inputs["247-LOCAL-CANARY-PREFLIGHT.json"] = file_hash(BASE / "247-LOCAL-CANARY-PREFLIGHT.json")
    rows, provenance, invalid = [], [], []
    run_metadata = {}
    artifact_metadata = {}
    for run, head, cache in ([(r, B3_HEAD, Path(b3_root).parent / "threadline-247-b3-weights") for r in B3_IDS] +
                             [(r, B4_HEAD, Path(b4_root) / str(r)) for r in B4_IDS]):
        meta_path = cache / f"{run}-metadata.json" if run in B3_IDS else cache / "run.json"
        if not meta_path.is_file():
            raise ValueError(f"missing frozen run metadata for {run}")
        meta = json.loads(meta_path.read_text())
        if meta.get("id") != run or meta.get("head_sha") != head or int(meta.get("run_attempt", 0)) != 1 or meta.get("conclusion") != "success":
            raise ValueError(f"run metadata identity/attempt/conclusion mismatch for {run}")
        run_metadata[str(run)] = {"head": head, "attempt": 1, "conclusion": "success",
                                  "metadata_sha256": file_hash(meta_path)}
    cohorts = [("B3_TRAINING", B3_IDS, B3_HEAD, 269), ("B4_HOLDOUT", B4_IDS, B4_HEAD, 269),
              ("DIAGNOSTIC_OFF_MAIN", [DIAG_ID], DIAG_HEAD, 269)]
    for role, ids, head, full_count in cohorts:
        src = sources[head]
        for run in ids:
            per_run = {}
            for lane in LANES:
                per_lane = {}
                for p in range(1, 5):
                    path = artifact_path(run, lane, p, b3_root, b4_root, diag_root)
                    if role == "DIAGNOSTIC_OFF_MAIN":
                        # The receipt embeds only min. Current/latest use the saved, exact-run
                        # artifacts; never synthesize file-level observations from aggregates.
                        if not path.is_file():
                            raise ValueError(f"missing exact diagnostic artifact: {path}")
                        text = path.read_text()
                        diagnostic = evidence["247-DIAGNOSTIC-EVIDENCE.json"]
                        if lane == "min":
                            raw = diagnostic["raw_min_timings"][f"partition-timings-{p}.tsv"]
                            if text != raw:
                                raise ValueError("diagnostic min TSV differs from canonical embedded timing")
                        expected = next(x["timing_sha256"] for x in diagnostic["lanes"][lane]["partitions"]
                                        if x["partition"] == p)
                        verify_artifact_payload(text, expected, f"diagnostic {run}/{lane}/{p}")
                        if expected_artifacts.get((run, lane, p)) != expected:
                            raise ValueError(f"diagnostic digest disagrees with pinned receipt: {run}/{lane}/{p}")
                    else:
                        if not path.is_file():
                            raise ValueError(f"missing frozen artifact: run {run} lane {lane} partition {p}")
                        text = path.read_text()
                        expected = expected_artifacts.get((run, lane, p))
                        if not expected:
                            raise ValueError(f"no immutable expected digest for {run}/{lane}/{p}")
                        verify_artifact_payload(text, expected, f"frozen {run}/{lane}/{p}")
                        if run in B4_IDS and lane not in artifact_metadata.setdefault(str(run), {}):
                            meta_path = Path(b4_root) / str(run) / "artifacts.json"
                            artifact_metadata[str(run)][lane] = verify_b4_artifact_identity(run, lane, meta_path)
                    parsed = parse_tsv(text, run, lane, p)
                    parsed["path"] = str(path); per_lane[p] = parsed
                    obs = cost(parsed["rows"], src, lane, observed=True)
                    pred = cost(parsed["rows"], src, lane)
                    std = cost(parsed["rows"], src, lane, observed=True, standardized=True)
                    if role == "B3_TRAINING":
                        printed_ratio = evidence["247-B3-MEASUREMENT.json"]["ratios"][lane][B3_IDS.index(run)]
                    elif role == "B4_HOLDOUT":
                        printed_ratio = evidence["247-B4-INCOMPLETE.json"]["ratios"][lane][B4_IDS.index(run)]
                    else:
                        printed_ratio = evidence["247-DIAGNOSTIC-EVIDENCE.json"]["lanes"][lane]["printed_ratio"]
                    rows.append({"role": role, "run_id": run, "head": head, "attempt": 1,
                        "lane": lane, "partition": p, "boot_ms": parsed["boot_ms"], "wall_ms": parsed["wall_ms"],
                        "tsv_sha256": parsed["sha256"], "row_count": parsed["file_count"],
                        "assignment": {"exact_once_lane_inventory": True},
                        "source_formula": src["factor_permille"], "historical_observed": obs,
                        "committed_weight_prediction": pred,
                        "standardized_current_formula": std,
                        "weight_error_ms": obs["cost_ms"] - pred["cost_ms"],
                        "active_residual_ms": parsed["wall_ms"] - parsed["boot_ms"] - obs["cost_ms"],
                        "body_ratio_diagnostic": round((parsed["wall_ms"] - parsed["boot_ms"]) / parsed["wall_ms"], 6),
                        "printed_total_ratio_authoritative": printed_ratio,
                        "printed_ratio_source": "canonical measurement JSON; diagnostic lane aggregate only" if role == "DIAGNOSTIC_OFF_MAIN" else "canonical measurement JSON"})
                expected = 206 if lane in ("min", "latest") else full_count
                check = assignments_check(per_lane, src, lane, expected)
                for row in rows[-4:]:
                    if row["run_id"] == run and row["lane"] == lane: row["assignment"] = check
                per_run[lane] = per_lane
                for p, parsed in per_lane.items():
                    provenance.append({"run_id": run, "lane": lane, "partition": p, "artifact_sha256": parsed["sha256"]})
    # Preserve the frozen failed attempts as exclusions, never timing rows.
    excluded = []
    for name in ("247-B3-MEASUREMENT.json", "247-B4-INCOMPLETE.json"):
        d = evidence[name]
        for e in d.get("excluded", []):
            excluded.append({"run_id": e["id"], "head": e["head_sha"], "reason": e["reason"], "included": False})
    # A failed initial PR check is historical process evidence, not a B4 sample.
    excluded.append({"run_id": 40446515239, "role": "INITIAL_PR_FAILURE",
                     "reason": "failed initial PR check; preserved, never retried or included", "included": False})
    # Canonical identity checks and historical printed-ratio authority.
    for run in evidence["247-B3-MEASUREMENT.json"]["runs"]:
        if run["id"] in B3_IDS and (run["head_sha"] != B3_HEAD or run.get("conclusion", "success") != "success"):
            raise ValueError("B3 run identity/status mismatch")
    for run in evidence["247-B4-INCOMPLETE.json"]["runs"]:
        if run["id"] in B4_IDS and run["head_sha"] != B4_HEAD:
            raise ValueError("B4 run head mismatch")
    diag = evidence["247-DIAGNOSTIC-EVIDENCE.json"]["run"]
    if diag["id"] != DIAG_ID or diag["head_sha"] != DIAG_HEAD or diag["run_attempt"] != 1:
        raise ValueError("diagnostic identity mismatch")
    return {"schema": "threadline.phase247-frozen-replay/1", "status": "VALID",
        "manifest": {"B3_training": B3_IDS, "B4_holdout": B4_IDS, "failed_exclusions": excluded,
                     "diagnostic_separate": DIAG_ID, "inputs_sha256": inputs,
                     "run_metadata": run_metadata,
                     "source_snapshots": {h: s["source_hashes"] for h, s in sources.items()},
                     "artifact_hashes": provenance}, "rows": rows,
        "decision_projection": {"canary_status": evidence["247-LOCAL-CANARY.json"]["result"]["status"],
            "historical_ci_cause": "UNPROVEN", "CI-02": "INCOMPLETE", "CI-03": "MISS",
            "B4_fixed_first_three_min_ratios": [1.24, 1.28, 1.27],
            "B4_success_count": 4, "required_success_count": 5}}


def validate_report(path, validation, data):
    report = Path(path).read_text(); val = Path(validation).read_text()
    required = ["canary is `INVALID`", "historical cause `UNPROVEN`", "CI-02 is **INCOMPLETE**", "CI-03 is **MISS**", "1.24", "1.28", "1.27", "40433193088", "40434036118", "40434884357", "40435657557", "40446515239", "40449332597", "40450141708", "40450801580", "40451533079", "40452150109", "40452833440", "40504321590", "profile-only", "one warmup", "decision"]
    missing = [x for x in required if x not in report]
    if missing: raise ValueError("decision projection missing: " + ", ".join(missing))
    if "source: automated-review" not in report or "sha256:" not in report:
        raise ValueError("independent review receipt absent")
    body = report.split("\n## Independent review receipt\n", 1)[0]
    match = re.search(r"Reviewed body SHA-256:\*\* `([0-9a-f]{64})`", report)
    if not match or match.group(1) != digest(body.encode()):
        raise ValueError("review receipt does not bind this decision body")
    expected_hashes = [digest((BASE / name).read_bytes()) for name in
                       ("247-FROZEN-REPLAY.json", "247-LOCAL-CANARY.json", "247-LOCAL-CANARY-PREFLIGHT.json")]
    if any(h not in report for h in expected_hashes):
        raise ValueError("review receipt omits or alters a checked evidence hash")
    if "B3" not in val or "B4" not in val or "247-21" not in val:
        raise ValueError("plan-specific validation addendum absent")
    if data.get("decision_projection", {}).get("CI-02") != "INCOMPLETE" or data.get("decision_projection", {}).get("CI-03") != "MISS":
        raise ValueError("decision projection attempts acceptance override")


def verify_candidate(candidate, expected):
    if candidate != expected:
        raise ValueError("persisted replay differs from canonical evidence/source recomputation")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", action="store_true"); ap.add_argument("--verify")
    ap.add_argument("--report"); ap.add_argument("--validation")
    ap.add_argument("--b3-root", default="/tmp/threadline-247-b3-artifacts")
    ap.add_argument("--b4-root", default="/tmp/threadline-247-b4-artifacts")
    ap.add_argument("--diag-root", default="/tmp/threadline-247-diag-artifacts")
    ap.add_argument("--output", default=str(BASE / "247-FROZEN-REPLAY.json"))
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    try:
        if a.self_test:
            good = replay(a.b3_root, a.b4_root, a.diag_root)
            expected_hashes = frozen_artifact_expectations()
            run, lane, partition = B4_IDS[0], "min", 1
            payload_path = artifact_path(run, lane, partition, a.b3_root, a.b4_root, a.diag_root)
            original_payload = payload_path.read_text()
            changed_payload = re.sub(r"(?<=\t)\d", lambda m: str((int(m.group()) + 1) % 10),
                                     original_payload, count=1)
            if changed_payload == original_payload:
                raise ValueError("payload mutation fixture did not change bytes")
            parse_tsv(changed_payload, run, lane, partition)  # preserve valid TSV shape
            try:
                verify_artifact_payload(changed_payload, expected_hashes[(run, lane, partition)],
                                        "mutated fixture")
            except ValueError:
                pass
            else:
                raise ValueError("changed valid-schema payload passed its pinned digest")
            bad_source = json.loads(json.dumps(good)); bad_source["manifest"]["source_snapshots"][B3_HEAD]["bin/ci-test-partitions"] = "0" * 64
            bad_metric = json.loads(json.dumps(good)); bad_metric["rows"][0]["active_residual_ms"] += 1
            for candidate in (bad_source, bad_metric):
                try:
                    verify_candidate(candidate, good)
                except ValueError:
                    pass
                else:
                    raise ValueError("mutated source/arithmetic receipt passed verification")
            print("self-test: source, arithmetic, and valid-shape payload mutations rejected")
            return 0
        if a.run:
            data = replay(a.b3_root, a.b4_root, a.diag_root)
            if Path(a.output).resolve() == (BASE / "247-FROZEN-REPLAY.json").resolve():
                raise ValueError("refusing to overwrite immutable historical replay receipt")
            Path(a.output).write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
            print(f"wrote {a.output}: {data['status']}, {len(data['rows'])} lane/partition rows")
            return 0
        if a.verify:
            data = json.loads(Path(a.verify).read_text())
            regenerated = replay(a.b3_root, a.b4_root, a.diag_root)
            verify_candidate(data, regenerated)
            if a.report or a.validation:
                if not a.report or not a.validation: raise ValueError("both --report and --validation required")
                validate_report(a.report, a.validation, data)
            print(f"verify: {data['status']} replay; {len(data['rows'])} rows and frozen projection checked")
            return 0
        ap.error("choose --run, --verify or --self-test")
    except (ValueError, OSError, subprocess.CalledProcessError, KeyError, TypeError) as exc:
        print(f"replay_frozen_evidence: INVALID: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
