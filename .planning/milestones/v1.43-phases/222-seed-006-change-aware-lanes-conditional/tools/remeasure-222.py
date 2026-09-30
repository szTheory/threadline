#!/usr/bin/env python3
"""remeasure-222.py - D-02 minute gate and D-03 ceiling for the SEED-006 decision.

Usage (from the repo root):
  python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py skip-saving
  python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now
  python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py ceiling --window 30d-now
  python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py --self-test

Imports this phase's copied summarize-ci.py (job-seconds / billed-minute
arithmetic, unchanged) and copied inert-share.py (allowlist, PR loading, window
bounds, fail-closed classification, unchanged) via importlib.util.spec_from_file_location.
Never reimplements either module's arithmetic or classification rule.

D-02 two-part gate (over --window, population = merged PRs in the window, sorted
by number):
  part 1: strict fail-closed inert share is at least 20% of merged PRs, with n>=10
          (integer check: 5*k >= n)
  part 2: projected saving (k skip-eligible PRs x the fixed per-skip billed-minute
          constant) is at least 10% of the window's billed PR runner-minutes
          (integer check: 10*saving >= D)
  verdict: BUILD only if both PASS; CLOSE if n>=10 and either FAILs;
           NOT MEASURED if n=0, n<10, or the denominator D=0.
Percentages print to one decimal, half-up.

The denominator D is one representative ci.yml pull_request run per merged PR in
the window -- the highest run id, among that PR's collected runs, whose JSON has
workflow == "CI" and event == "pull_request" -- on the PR's final head SHA
(raw/prs/heads.json -> raw/ci/manifest.json key "sha:<oid>"). A PR with no
manifest entry for its head SHA is a data error (exit 2): collection is
incomplete, never silently zero. A PR whose manifest entry has no CI pull_request
run is listed and excluded from the denominator (this shrinks D, which biases
toward BUILD, never CLOSE -- never excluded the other way).

SKIP_ELIGIBLE is the fixed set of three skip-eligible lanes (Browser E2E,
Capture, PgBouncer) and the exact 219 warm run each is read from, read-only,
from .planning/phases/219-deps-only-build-cache/raw/ci/runs/<id>.json. A missing
run file or job name there is a data error (exit 2).

D-03 ceiling: three fixed, non-fail-closed classifiers (github-only, docs-only,
no-product-code) over the same window and denominator, printed as information
only -- they never vote on the D-02 verdict.

Standard library only. Reads raw JSON only; never calls GitHub.
"""
import argparse
import fnmatch
import importlib.util
import json
import os
import sys

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
PHASE_DIR = os.path.dirname(TOOLS_DIR)
PHASES_DIR = os.path.dirname(PHASE_DIR)
RAW_CI = os.path.join(PHASE_DIR, "raw", "ci")
RAW_CI_219 = os.path.join(PHASES_DIR, "219-deps-only-build-cache", "raw", "ci")
HEADS_PATH = os.path.join(PHASE_DIR, "raw", "prs", "heads.json")

SELF = "python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py"

# D-02 part 1 / part 2 thresholds, as integer-comparison constants.
PART1_N_FLOOR = 10
PART1_PCT = 20  # 5*k >= n  <=>  k/n >= 20%
PART2_PCT = 10  # 10*saving >= D  <=>  saving/D >= 10%

# The three skip-eligible lanes and the exact 219 warm run each is read from
# (219-REMEASURE.md warm column). (run id, job name, short label).
SKIP_ELIGIBLE = [
    (36455432448, "Example app browser E2E (Playwright)", "Browser E2E"),
    (36450388764, "Tier A capture lane (byte-stable evidence)", "Capture"),
    (36457705448, "PgBouncer transaction topology", "PgBouncer"),
]

# D-03 ceiling classifiers (information only; never adjusted after seeing output).
GITHUB_ONLY_GLOBS = [".github/*"]
DOCS_ONLY_GLOBS = ["*.md", "*.markdown", "*.txt", "guides/*", "docs/*", "LICENSE*", "CHANGELOG*"]
PRODUCT_CODE_GLOBS = ["lib/*", "priv/*", "config/*", "mix.exs", "mix.lock"]

_spec_s = importlib.util.spec_from_file_location("summarize_ci", os.path.join(TOOLS_DIR, "summarize-ci.py"))
S = importlib.util.module_from_spec(_spec_s)
_spec_s.loader.exec_module(S)

_spec_i = importlib.util.spec_from_file_location("inert_share", os.path.join(TOOLS_DIR, "inert-share.py"))
I = importlib.util.module_from_spec(_spec_i)
_spec_i.loader.exec_module(I)


class DataError(Exception):
    pass


# --------------------------------------------------------------------------- io

def load_heads():
    if not os.path.exists(HEADS_PATH):
        raise DataError(f"missing {HEADS_PATH}")
    with open(HEADS_PATH, encoding="utf-8") as fh:
        return json.load(fh)


def load_ci_manifest():
    path = os.path.join(RAW_CI, "manifest.json")
    if not os.path.exists(path):
        raise DataError(f"missing {path} -- collect-ci-runs.sh has not been run")
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def load_ci_run(rid):
    path = os.path.join(RAW_CI, "runs", f"{rid}.json")
    if not os.path.exists(path):
        raise DataError(f"missing raw run file for run {rid}")
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def load_219_run(rid):
    path = os.path.join(RAW_CI_219, "runs", f"{rid}.json")
    if not os.path.exists(path):
        raise DataError(f"missing 219 run file for run {rid}: {path}")
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


# ----------------------------------------------------------- skip-saving (D-02 part 2 constant)

def skip_saving_rows(run_loader=load_219_run):
    rows = []
    for rid, job_name, label in SKIP_ELIGIBLE:
        run = run_loader(rid)
        job = next((j for j in run.get("jobs", []) if j["name"] == job_name), None)
        if job is None:
            raise DataError(f"run {rid} has no job named {job_name!r}")
        secs = S.job_seconds(job)
        if secs is None:
            raise DataError(f"run {rid} job {job_name!r} has no measurable duration")
        billed = S.billed_minutes(secs)
        rows.append((label, secs, billed, rid))
    return rows


def skip_saving_total(run_loader=load_219_run):
    return sum(billed for _label, _secs, billed, _rid in skip_saving_rows(run_loader))


def cmd_skip_saving(args):
    rows = skip_saving_rows()
    for label, secs, billed, rid in rows:
        print(f"{label}: {secs} s → {billed} billed min (run {rid})")
    print(f"skip saving per PR run: {sum(r[2] for r in rows)} billed min")
    return 0


# ------------------------------------------------------- representative run / denominator

def head_oid_for(number, heads):
    for e in heads:
        if e["number"] == number:
            return e["headRefOid"]
    return None


def representative_run_for_pr(pr, heads, manifest, run_loader=load_ci_run):
    oid = head_oid_for(pr["number"], heads)
    if oid is None:
        raise DataError(f"PR {pr['number']}: no headRefOid in heads.json")
    key = f"sha:{oid}"
    entry = manifest.get("entries", {}).get(key)
    if entry is None:
        raise DataError(f"PR {pr['number']}: no manifest entry for {key} -- collection incomplete")
    candidates = []
    for rid in entry.get("run_ids", []):
        run = run_loader(rid)
        if run.get("workflow") == "CI" and run.get("event") == "pull_request":
            candidates.append(run)
    if not candidates:
        return None
    candidates.sort(key=lambda r: r["run_id"])
    return candidates[-1]


def compute_window_billed(prs, heads, manifest, run_loader=load_ci_run):
    """(D billed min, {pr_number: run}, [pr numbers with no ci.yml pull_request run])."""
    reps = {}
    no_run = []
    for p in sorted(prs, key=lambda x: x["number"]):
        run = representative_run_for_pr(p, heads, manifest, run_loader)
        if run is None:
            no_run.append(p["number"])
        else:
            reps[p["number"]] = run
    D = sum(S.run_seconds(r)[1] for r in reps.values())
    return D, reps, no_run


# --------------------------------------------------------------- percentages / gate math

def pct1(num, denom):
    """num/denom as a percentage, one decimal, half-up. denom=0 -> '0.0'."""
    if denom == 0:
        return "0.0"
    tenths = (2000 * num + denom) // (2 * denom)
    return f"{tenths // 10}.{tenths % 10}"


def part2_pass(saving, D):
    return 10 * saving >= D


def gate_verdict(n, k, D, s):
    """Pure D-02 gate over (n merged PRs, k strict-inert, D billed-min denominator,
    s billed-min per skip). No disk access; used by both the real subcommand and
    the self-test."""
    if n == 0:
        return {"n": n, "verdict": "NOT MEASURED"}
    if n < PART1_N_FLOOR:
        return {"n": n, "verdict": "NOT MEASURED", "reason": f"n<{PART1_N_FLOOR}"}
    p1_pass = 5 * k >= n
    p1_pct = pct1(k, n)
    if D == 0:
        return {"n": n, "verdict": "NOT MEASURED", "reason": "D=0", "part1_pass": p1_pass, "part1_pct": p1_pct}
    saving = k * s
    p2_pass = part2_pass(saving, D)
    p2_pct = pct1(saving, D)
    verdict = "BUILD" if (p1_pass and p2_pass) else "CLOSE"
    return {"n": n, "verdict": verdict, "part1_pass": p1_pass, "part1_pct": p1_pct,
            "saving": saving, "part2_pass": p2_pass, "part2_pct": p2_pct}


# ------------------------------------------------------------------- minute-gate subcommand

def window_prs(window):
    globs = I.load_allowlist(I.ALLOWLIST)
    prs = I.load_prs(I.PRS_DIR)
    selected = [p for p in prs if I.in_window(p, window)]
    return globs, sorted(selected, key=lambda p: p["number"])


def cmd_minute_gate(args):
    globs, selected = window_prs(args.window)
    n = len(selected)
    bounds = I.WINDOWS[args.window]
    print(f"window: {args.window} {bounds}")
    if n == 0:
        print("n=0 — not measured")
        print("verdict: NOT MEASURED")
        return 0
    inert_nums = [p["number"] for p in selected if I.is_inert_pr(p["files"], globs)]
    k = len(inert_nums)
    print(f"n={n} merged PRs; {k} strict-inert ({', '.join(f'#{x}' for x in inert_nums) if inert_nums else 'none'})")

    heads = load_heads()
    manifest = load_ci_manifest()
    D, reps, no_run = compute_window_billed(selected, heads, manifest)
    for p in selected:
        if p["number"] in reps:
            run = reps[p["number"]]
            billed = S.run_seconds(run)[1]
            print(f"per-PR representative run: #{p['number']} run {run['run_id']} {billed} billed min")
    print(f"no ci.yml pull_request run: {', '.join(f'#{x}' for x in no_run) if no_run else 'none'}")
    print(f"denominator: {D} billed min over {len(reps)} PR runs")

    if n < PART1_N_FLOOR:
        print(f"verdict: NOT MEASURED (n={n} < {PART1_N_FLOOR} floor)")
        return 0

    s = skip_saving_total()
    result = gate_verdict(n, k, D, s)

    p1_status = "PASS" if result.get("part1_pass") else "FAIL"
    print(f"part 1: {k} of {n} = {result.get('part1_pct')}% (need n>={PART1_N_FLOOR} and >={PART1_PCT}%) {p1_status}")

    if D == 0:
        print("verdict: NOT MEASURED (D=0)")
        return 0

    saving = result["saving"]
    p2_status = "PASS" if result.get("part2_pass") else "FAIL"
    print(f"part 2: saving {k}×{s} = {saving} of {D} billed min = {result.get('part2_pct')}% (need >={PART2_PCT}%) {p2_status}")
    print(f"verdict: {result['verdict']}")
    return 0


# ------------------------------------------------------------------------ ceiling subcommand

def all_match(files, globs):
    return bool(files) and all(any(fnmatch.fnmatchcase(f, g) for g in globs) for f in files)


def none_match(files, globs):
    return bool(files) and not any(any(fnmatch.fnmatchcase(f, g) for g in globs) for f in files)


def is_github_only(files):
    return all_match(files, GITHUB_ONLY_GLOBS)


def is_docs_only(files):
    return all_match(files, DOCS_ONLY_GLOBS)


def is_no_product_code(files):
    return none_match(files, PRODUCT_CODE_GLOBS)


CEILING_CLASSIFIERS = [
    ("github-only", GITHUB_ONLY_GLOBS, is_github_only),
    ("docs-only", DOCS_ONLY_GLOBS, is_docs_only),
    ("no-product-code", PRODUCT_CODE_GLOBS, is_no_product_code),
]


def cmd_ceiling(args):
    _globs, selected = window_prs(args.window)
    n = len(selected)
    print("ceiling (D-03, information only, does not vote)")
    print(f"window: {args.window}")
    if n == 0:
        print("n=0 — not measured")
        return 0

    heads = load_heads()
    manifest = load_ci_manifest()
    D, _reps, no_run = compute_window_billed(selected, heads, manifest)
    s = skip_saving_total()

    for label, globs, predicate in CEILING_CLASSIFIERS:
        matched = [p["number"] for p in selected if predicate(p["files"])]
        k = len(matched)
        saving = k * s
        pct = pct1(saving, D) if D else "0.0"
        print(f"{label} (globs: {', '.join(globs)}): {k} of {n} ({', '.join(f'#{x}' for x in matched) if matched else 'none'}); "
              f"projected saving {k}×{s} = {saving} billed min = {pct}% of D={D}")
    if no_run:
        print(f"no ci.yml pull_request run (excluded from D): {', '.join(f'#{x}' for x in no_run)}")
    return 0


# ------------------------------------------------------------------------ self-test

def _fake_job(name, secs, conclusion="success", labels=None):
    return {"name": name, "conclusion": conclusion, "started_at": "2026-01-01T00:00:00Z",
            "completed_at": f"2026-01-01T00:{secs // 60:02d}:{secs % 60:02d}Z", "labels": labels or []}


def _fake_run(run_id, workflow, event, jobs):
    return {"run_id": run_id, "workflow": workflow, "event": event, "jobs": jobs}


def self_test():
    fails = []

    def check(case, got, want):
        if got != want:
            fails.append(f"FAIL {case}: got {got!r}, want {want!r}")

    # skip-saving on the three frozen 219 warm runs: exact billed-minute constant.
    rows = skip_saving_rows()
    by_label = {label: (secs, billed, rid) for label, secs, billed, rid in rows}
    check("skip-saving Browser E2E", by_label["Browser E2E"], (547, 10, 36455432448))
    check("skip-saving Capture", by_label["Capture"], (413, 7, 36450388764))
    check("skip-saving PgBouncer", by_label["PgBouncer"], (72, 2, 36457705448))
    check("skip-saving total", skip_saving_total(), 19)

    # minute-gate n=0.
    check("gate n=0 verdict", gate_verdict(0, 0, 0, 19)["verdict"], "NOT MEASURED")

    # minute-gate 0<n<10.
    r_small = gate_verdict(5, 1, 100, 19)
    check("gate n<10 verdict", r_small["verdict"], "NOT MEASURED")
    check("gate n<10 reason", r_small.get("reason"), "n<10")

    # synthetic k=0 of n=28, denominator 1400: part1 FAIL, part2 FAIL, verdict CLOSE.
    r0 = gate_verdict(28, 0, 1400, 19)
    check("k=0 n=28 part1_pass", r0["part1_pass"], False)
    check("k=0 n=28 part1_pct", r0["part1_pct"], "0.0")
    check("k=0 n=28 part2_pass", r0["part2_pass"], False)
    check("k=0 n=28 part2_pct", r0["part2_pct"], "0.0")
    check("k=0 n=28 verdict", r0["verdict"], "CLOSE")

    # synthetic k=6 of n=28, denominator 1000: part1 PASS, part2 PASS, verdict BUILD.
    r6 = gate_verdict(28, 6, 1000, 19)
    check("k=6 n=28 part1_pass", r6["part1_pass"], True)
    check("k=6 n=28 part1_pct", r6["part1_pct"], "21.4")
    check("k=6 n=28 saving", r6["saving"], 114)
    check("k=6 n=28 part2_pass", r6["part2_pass"], True)
    check("k=6 n=28 part2_pct", r6["part2_pct"], "11.4")
    check("k=6 n=28 verdict", r6["verdict"], "BUILD")

    # threshold edges: k=2 of n=10 passes part1 exactly at 20%.
    r_edge1 = gate_verdict(10, 2, 10000, 0)  # s=0 so part2 is deliberately starved; only part1 checked
    check("edge k=2 n=10 part1_pass", r_edge1["part1_pass"], True)
    check("edge k=2 n=10 part1_pct", r_edge1["part1_pct"], "20.0")
    # saving 100 of denominator 1000 passes part2 exactly at 10%.
    check("edge saving=100 D=1000 part2_pass", part2_pass(100, 1000), True)
    check("edge saving=100 D=1000 part2_pct", pct1(100, 1000), "10.0")

    # 30d-now-shaped: a PR whose head SHA has no manifest entry raises a data error.
    heads = [{"number": 1, "headRefOid": "deadbeef"}]
    manifest_missing = {"entries": {}}
    try:
        representative_run_for_pr({"number": 1, "mergedAt": "2026-01-01T00:00:00Z", "files": ["x"]},
                                   heads, manifest_missing, run_loader=lambda rid: {})
        got_missing_manifest = False
    except DataError:
        got_missing_manifest = True
    check("missing manifest entry raises DataError", got_missing_manifest, True)

    # a PR whose manifest entry has no CI/pull_request run is listed and excluded.
    manifest_no_pr_run = {"entries": {"sha:deadbeef": {"run_ids": [999]}}}

    def loader_push_only(rid):
        return _fake_run(rid, "CI", "push", [_fake_job("Run test suite (current)", 100)])

    pr1 = {"number": 1, "mergedAt": "2026-01-01T00:00:00Z", "files": ["x"]}
    D, reps, no_run = compute_window_billed([pr1], heads, manifest_no_pr_run, run_loader=loader_push_only)
    check("no pull_request run excluded from D", D, 0)
    check("no pull_request run listed", no_run, [1])
    check("no pull_request run reps empty", reps, {})

    # the highest-run-id pull_request run on the SHA is the representative.
    manifest_two_runs = {"entries": {"sha:deadbeef": {"run_ids": [100, 200]}}}

    def loader_two_runs(rid):
        if rid == 100:
            return _fake_run(rid, "CI", "pull_request", [_fake_job("Run test suite (current)", 60)])
        return _fake_run(rid, "CI", "pull_request", [_fake_job("Run test suite (current)", 120)])

    D2, reps2, no_run2 = compute_window_billed([pr1], heads, manifest_two_runs, run_loader=loader_two_runs)
    check("representative run is highest id", reps2[1]["run_id"], 200)
    check("representative run billed", D2, 2)
    check("no_run empty when a run exists", no_run2, [])

    # D-03 ceiling classifiers.
    check("github-only alone", is_github_only([".github/workflows/ci.yml"]), True)
    check("docs-only mixed md files", is_docs_only(["README.md", "guides/x.md"]), True)
    check("no-product-code test file", is_no_product_code(["test/foo_test.exs"]), True)
    check("lib file is none of the three", is_github_only(["lib/threadline.ex"]), False)
    check("lib file is not docs-only", is_docs_only(["lib/threadline.ex"]), False)
    check("lib file is not no-product-code", is_no_product_code(["lib/threadline.ex"]), False)
    check("empty file list fails closed (github-only)", is_github_only([]), False)
    check("empty file list fails closed (docs-only)", is_docs_only([]), False)
    check("empty file list fails closed (no-product-code)", is_no_product_code([]), False)

    for f in fails:
        print(f)
    if fails:
        return 1
    print("self-test: ok")
    return 0


# ---------------------------------------------------------------------- main

class ArgParser(argparse.ArgumentParser):
    def error(self, message):
        print(f"remeasure-222: {message}", file=sys.stderr)
        sys.exit(64)


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if argv == ["--self-test"]:
        return self_test()
    p = ArgParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="sub", required=True)

    sub.add_parser("skip-saving")

    sp = sub.add_parser("minute-gate")
    sp.add_argument("--window", required=True, choices=list(I.WINDOWS.keys()))

    sp = sub.add_parser("ceiling")
    sp.add_argument("--window", required=True, choices=list(I.WINDOWS.keys()))

    args = p.parse_args(argv)
    try:
        if args.sub == "skip-saving":
            return cmd_skip_saving(args)
        if args.sub == "minute-gate":
            return cmd_minute_gate(args)
        if args.sub == "ceiling":
            return cmd_ceiling(args)
    except DataError as err:
        print(f"ERROR: {err}", file=sys.stderr)
        return 2
    return 64


if __name__ == "__main__":
    sys.exit(main())
