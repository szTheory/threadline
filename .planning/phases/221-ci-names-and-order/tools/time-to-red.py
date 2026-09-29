#!/usr/bin/env python3
"""time-to-red.py - the measured source of ci.yml's time-to-red job order (D-06, D-13, D-14).

Standard library only. Reuses the Phase 219 arithmetic (job_seconds, rank,
pick, sort_samples) from 219-deps-only-build-cache/tools/summarize-ci.py by
importlib, so 214/218/219/221 figures stay comparable. It never edits that tool.

Contract
  * duration of a job = completed_at - started_at, integer seconds; only jobs
    whose conclusion is "success" are samples (summarize-ci.py job_seconds).
  * percentiles are nearest-rank, rank = ceil(q * n), over samples sorted by
    (seconds, run id) (summarize-ci.py sort_samples / pick).
  * every posted job name maps to its stable ci.yml id through the frozen
    NAME_HISTORY, so runs from before and after the 221 rename stay comparable.
  * a matrix id (several posted names, one per lane) takes the lane with the
    smallest p50, and that lane's max.
  * `ci-required` is the aggregate, not a lane, and is excluded from the order.
  * order = sort by (p50, max, id).

Subcommands
  collect   copy or GET (read-only `gh api`) the RUNS missing from raw/ci/runs/
  order     offline: print the table and the `@time_to_red_order ~w(...)` literal
  check     offline: compare the literal in the parity contract test to `order`
            (exit 0 match, 1 drift, 2 no literal)

Regenerate: python3 .planning/phases/221-ci-names-and-order/tools/time-to-red.py order
"""
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
PHASE_DIR = os.path.dirname(TOOLS_DIR)
PHASES_DIR = os.path.dirname(PHASE_DIR)
RUNS_DIR = os.path.join(PHASE_DIR, "raw", "ci", "runs")
SOURCE_RUNS_DIR = os.path.join(PHASES_DIR, "219-deps-only-build-cache", "raw", "ci", "runs")
SUMMARIZE = os.path.join(PHASES_DIR, "219-deps-only-build-cache", "tools", "summarize-ci.py")
PARITY_TEST = os.path.join("test", "threadline", "ci_workflow_parity_contract_test.exs")
REPO = "szTheory/threadline"

_spec = importlib.util.spec_from_file_location("summarize_ci", SUMMARIZE)
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)

# D-06: the 10 cited warm post-219 CI runs, in D-06's order.
RUNS = [36502353440, 36501481301, 36487483472, 36467068660, 36465241600,
        36457705448, 36456537357, 36455432448, 36454272684, 36453043277]

# Set by plan 04 at landing: the SHA of the 221 rename commit
# (`ci(221): name every CI check for what it proves (DX-01)`) as cherry-picked
# onto the land branch land/v1.43-221. It is a land-branch SHA: not the
# milestone-branch SHA of that commit and not a commit on main.
RENAME_SHA = None
# Set by plan 04 at landing: the first CI run that posts the new names (D-13).
ERA_BOUNDARY_RUN = None
# Set in the first planning sync after the maintainer squash-merges the 221
# land PR: the squash-merge commit on main that carries the rename.
MAIN_MERGE_SHA = None

AGGREGATE_ID = "ci-required"

# D-13, frozen: every ci.yml job name posted in the measured eras -> stable id.
# Never delete an entry; old runs keep their old names forever.
NAME_HISTORY = {
    # pre-221, verbatim from the ci.yml `name:` lines
    "Check formatting": "verify-format",
    "Run Credo (strict)": "verify-credo",
    "Dialyzer (current toolchain)": "verify-dialyzer",
    "Compile without optional deps": "verify-compile-no-optional",
    "Run test suite": "verify-test",  # matrix: "Run test suite (<lane>)"
    "Hex evaluator smoke (threadline from hex.pm)": "verify-hex-evaluator",
    "Example app browser E2E (Playwright)": "verify-example-browser",
    "Tier A capture lane (byte-stable evidence)": "verify-capture",
    "PgBouncer transaction topology": "verify-pgbouncer-topology",
    "Release metadata (version / changelog)": "verify-release-shape",
    "Bump rehearsal (next minor)": "verify-bump-rehearsal",
    "Dependency audit (all lockfiles)": "verify-deps-audit",
    "Repo hygiene (no machine-local paths)": "verify-repo-hygiene",
    "CI required": "ci-required",
    # removed by 218-04 (copied from 218 remeasure-218.py REMOVED_IDS)
    "Mechanical checker (committed scorecards)": "verify-mechanical",
    "Build ExDoc (dev)": "verify-docs",
    "Hex package tarball": "verify-hex-package",
    # post-221 (D-13), verbatim from the ci.yml `name:` lines. Each maps to the
    # same id as its pre-221 name; the four unchanged names above
    # (Compile without optional deps, Dependency audit (all lockfiles),
    # Repo hygiene (no machine-local paths), CI required) serve both eras.
    "Formatting": "verify-format",
    "Credo (strict)": "verify-credo",
    "Dialyzer (full optional build)": "verify-dialyzer",
    "Build and test": "verify-test",  # matrix: "Build and test (<lane>)"
    "Hex package install (rehearsal registry)": "verify-hex-evaluator",
    "Example app browser E2E (2 projects)": "verify-example-browser",
    "Capture evidence byte-stable": "verify-capture",
    "Tests through PgBouncer (transaction mode)": "verify-pgbouncer-topology",
    "CHANGELOG matches version": "verify-release-shape",
    "Next-minor release rehearsal (docs + contracts)": "verify-bump-rehearsal",
}

# The names ci.yml posts after the 221 rename (the ten renamed names above).
POST_221_NAMES = (
    "Formatting",
    "Credo (strict)",
    "Dialyzer (full optional build)",
    "Build and test",
    "Hex package install (rehearsal registry)",
    "Example app browser E2E (2 projects)",
    "Capture evidence byte-stable",
    "Tests through PgBouncer (transaction mode)",
    "CHANGELOG matches version",
    "Next-minor release rehearsal (docs + contracts)",
)


def name_history_errors():
    """D-13 self-check: no post-221 name collides, none reaches an orphan id."""
    errors = []
    pre_ids = {jid for name, jid in NAME_HISTORY.items() if name not in POST_221_NAMES}
    seen = {}
    for name in POST_221_NAMES:
        if name not in NAME_HISTORY:
            errors.append(f"post-221 name {name!r} has no NAME_HISTORY entry")
            continue
        jid = NAME_HISTORY[name]
        if jid not in pre_ids:
            errors.append(f"orphan id: post-221 name {name!r} -> {jid!r}, which no pre-221 name reaches")
        if jid in seen:
            errors.append(f"collision: post-221 names {seen[jid]!r} and {name!r} both map to {jid!r}")
        seen.setdefault(jid, name)
    return errors


def assert_name_history():
    errors = name_history_errors()
    if errors:
        print("time-to-red: NAME_HISTORY self-check failed:", file=sys.stderr)
        for err in errors:
            print(f"  {err}", file=sys.stderr)
        sys.exit(1)


def job_id(name):
    if name in NAME_HISTORY:
        return NAME_HISTORY[name]
    for base, jid in NAME_HISTORY.items():
        if name.startswith(base + " ("):  # matrix lane suffix
            return jid
    return "?"


def run_path(run_id):
    return os.path.join(RUNS_DIR, f"{run_id}.json")


def load_run(run_id):
    path = run_path(run_id)
    if not os.path.exists(path):
        sys.exit(f"time-to-red: missing raw run file for run {run_id}; run `collect` first")
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def repo_root():
    here = TOOLS_DIR
    while True:
        if os.path.exists(os.path.join(here, "mix.exs")):
            return here
        parent = os.path.dirname(here)
        if parent == here:
            sys.exit("time-to-red: could not find the repo root (no mix.exs above this tool)")
        here = parent


# --------------------------------------------------------------------- collect

def gh_get(path, paginate=False):
    # Read-only: `gh api` without -X/--method and without -f/-F fields is a GET.
    args = ["gh", "api"] + (["--paginate"] if paginate else []) + [path]
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def fetch_run(run_id):
    run = json.loads(gh_get(f"repos/{REPO}/actions/runs/{run_id}"))
    raw_pages = gh_get(f"repos/{REPO}/actions/runs/{run_id}/jobs?per_page=100", paginate=True)
    # `--paginate` concatenates one JSON object per page.
    decoder = json.JSONDecoder()
    jobs, idx = [], 0
    raw_pages = raw_pages.strip()
    while idx < len(raw_pages):
        page, end = decoder.raw_decode(raw_pages, idx)
        jobs.extend(page.get("jobs", []))
        idx = end
        while idx < len(raw_pages) and raw_pages[idx].isspace():
            idx += 1
    keep = ("id", "name", "status", "conclusion", "started_at", "completed_at", "labels")
    step_keep = ("name", "conclusion", "started_at", "completed_at")
    return {
        "run_id": run["id"],
        "attempt": run["run_attempt"],
        "head_sha": run["head_sha"],
        "event": run["event"],
        "created_at": run["created_at"],
        "conclusion": run["conclusion"],
        "workflow": run["name"],
        "jobs": sorted(
            ({**{k: j.get(k) for k in keep},
              "steps": [{k: s.get(k) for k in step_keep} for s in (j.get("steps") or [])]}
             for j in jobs),
            key=lambda j: j["id"],
        ),
    }


def cmd_collect(_args):
    os.makedirs(RUNS_DIR, exist_ok=True)
    for run_id in RUNS:
        out = run_path(run_id)
        if os.path.exists(out):
            print(f"{run_id}: present")
            continue
        source = os.path.join(SOURCE_RUNS_DIR, f"{run_id}.json")
        if os.path.exists(source):
            shutil.copyfile(source, out)
            print(f"{run_id}: copied from 219 raw data")
            continue
        data = fetch_run(run_id)
        tmp = out + ".tmp"
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2, ensure_ascii=False)
            fh.write("\n")
        os.replace(tmp, out)
        print(f"{run_id}: fetched ({len(data['jobs'])} jobs)")
    return 0


# ----------------------------------------------------------------------- order

def compute_order():
    by_name = {}
    unknown = set()
    for run_id in RUNS:
        run = load_run(run_id)
        for job in run["jobs"]:
            if job.get("conclusion") != "success":
                continue
            if job_id(job["name"]) == "?":
                unknown.add(job["name"])
                continue
            secs = S.job_seconds(job)
            if secs is None:
                continue
            by_name.setdefault(job["name"], []).append((secs, run_id))
    if unknown:
        print("time-to-red: job names with no NAME_HISTORY entry (id `?`):", file=sys.stderr)
        for name in sorted(unknown):
            print(f"  {name}", file=sys.stderr)
        sys.exit(1)

    best = {}
    for name, samples in by_name.items():
        jid = job_id(name)
        if jid == AGGREGATE_ID:
            continue
        ordered = S.sort_samples(samples)
        p50 = S.pick(ordered, 50)[0]
        mx = S.pick(ordered, 100)[0]
        row = (p50, mx, len(ordered), name)
        if jid not in best or row[:2] < best[jid][:2]:
            best[jid] = row
    return sorted(((jid,) + row for jid, row in best.items()), key=lambda r: (r[1], r[2], r[0]))


def literal(rows):
    return "@time_to_red_order ~w(" + " ".join(r[0] for r in rows) + ")"


def cmd_order(_args):
    assert_name_history()
    rows = compute_order()
    print("id | p50 s | max s | n | lane")
    for jid, p50, mx, n, name in rows:
        print(f"{jid} | {p50} | {mx} | {n} | {name}")
    print(literal(rows))
    return 0


# ----------------------------------------------------------------------- check

def cmd_check(_args):
    assert_name_history()
    path = os.path.join(repo_root(), PARITY_TEST)
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    m = re.search(r"@time_to_red_order\s+~w\((.*?)\)", text, re.S | re.M)
    if not m:
        print("no @time_to_red_order literal")
        return 2
    pinned = m.group(1).split()
    measured = [r[0] for r in compute_order()]
    if pinned != measured:
        print("pinned:   " + " ".join(pinned))
        print("measured: " + " ".join(measured))
        return 1
    print("time-to-red order matches")
    return 0


def main(argv):
    commands = {"collect": cmd_collect, "order": cmd_order, "check": cmd_check}
    if len(argv) != 2 or argv[1] not in commands:
        print("usage: time-to-red.py collect|order|check", file=sys.stderr)
        return 64
    return commands[argv[1]](argv[2:])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
