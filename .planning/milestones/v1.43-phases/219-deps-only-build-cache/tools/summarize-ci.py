#!/usr/bin/env python3
"""summarize-ci.py - deterministic summaries of the Phase 214 raw CI data (BASE-01).

Reads raw/ci/manifest.json and raw/ci/runs/<run id>.json written by
collect-ci-runs.sh. Standard library only. Output is byte-identical across
repeated runs on the same raw data.

Contract
  * duration of a job = completed_at - started_at, integer seconds (queue time
    excluded); only jobs whose conclusion is "success" are duration samples.
  * samples are sorted by (seconds, run id) ascending before rank selection.
  * percentiles are nearest-rank: rank = ceil(q * n), 1-indexed
    (n = 10 -> p50 is the 5th sample, p95 is the 10th = the maximum).
  * rows are ordered by ci.yml job id, then by job name.
  * a legacy un-suffixed matrix job name ("Run test suite", from runs before
    the min/current lane matrix) is not reported when the suffixed names exist.
  * a job with zero successful samples prints "n=0 — not measured".
  * runner-minutes: "unrounded" = sum(job seconds) / 60 to one decimal;
    "billed" = sum(ceil(job seconds / 60)), GitHub's per-job rounding.

Subcommands
  jobs --workflow ci.yml --event <e> [--job NAME] [--min 10] --format md|json
  wall --workflow ci.yml --event <e>
  critical-path --workflow ci.yml --event <e>
  runner-minutes --unit pr|push|release [--tag vX.Y.Z] [--detail]
  workflow-cost --workflow <file> --event <e> --since YYYY-MM-DD [--regimes]
"""
import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
PHASE_DIR = os.path.dirname(TOOLS_DIR)
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(PHASE_DIR)))
RAW_DIR = os.path.join(PHASE_DIR, "raw", "ci")
RUNS_DIR = os.path.join(RAW_DIR, "runs")
MANIFEST = os.path.join(RAW_DIR, "manifest.json")
WORKFLOWS_DIR = os.path.join(REPO_ROOT, ".github", "workflows")

# Repo-relative invocation used in every regenerating command we print.
SELF = "python3 .planning/phases/219-deps-only-build-cache/tools/summarize-ci.py"

AGGREGATE_JOB_ID = "ci-required"


# --------------------------------------------------------------------------- io

def load_manifest():
    with open(MANIFEST, encoding="utf-8") as fh:
        return json.load(fh)


def manifest_entry(key):
    entries = load_manifest().get("entries", {})
    if key not in entries:
        sys.exit(f"summarize-ci: manifest has no entry {key!r}; run collect-ci-runs.sh first")
    return entries[key]


def load_run(run_id):
    path = os.path.join(RUNS_DIR, f"{run_id}.json")
    if not os.path.exists(path):
        sys.exit(f"summarize-ci: missing raw run file for run {run_id}")
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def run_ids_for(key):
    # Each run counted once (the collector stores the latest attempt).
    return sorted(set(int(r) for r in manifest_entry(key)["run_ids"]))


# ------------------------------------------------------------------------ maths

def ts(value):
    return datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)


def seconds(start, end):
    return int((ts(end) - ts(start)).total_seconds())


def job_seconds(job):
    if not job.get("started_at") or not job.get("completed_at"):
        return None
    s = seconds(job["started_at"], job["completed_at"])
    return s if s >= 0 else None


def rank(q_percent, n):
    """Nearest rank, 1-indexed: ceil(q * n) using integer arithmetic."""
    return max(1, -(-q_percent * n // 100))


def pick(samples, q_percent):
    """samples: list of (value, run_id) already sorted ascending."""
    return samples[rank(q_percent, len(samples)) - 1]


def sort_samples(samples):
    return sorted(samples, key=lambda s: (s[0], s[1]))


def billed_minutes(secs):
    return -(-secs // 60)


def fmt_min(secs):
    """Unrounded runner-minutes to one decimal (half-up on tenths)."""
    tenths = (secs * 10 + 30) // 60
    return f"{tenths // 10}.{tenths % 10}"


# ------------------------------------------------------------- ci.yml job map

def workflow_jobs(workflow_file):
    """Return [(job_id, name)] in declaration order from a workflow file."""
    path = os.path.join(WORKFLOWS_DIR, workflow_file)
    out = []
    if not os.path.exists(path):
        return out
    in_jobs = False
    current = None
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if re.match(r"^jobs:\s*$", line):
                in_jobs = True
                continue
            if not in_jobs:
                continue
            m = re.match(r"^  ([A-Za-z0-9_-]+):\s*$", line)
            if m:
                current = m.group(1)
                out.append([current, None])
                continue
            m = re.match(r"^    name:\s*(.+?)\s*$", line)
            if m and current and out and out[-1][0] == current and out[-1][1] is None:
                out[-1][1] = m.group(1).strip().strip('"').strip("'")
    return [(i, n if n is not None else i) for i, n in out]


def job_id_for(name, declared):
    for jid, jname in declared:
        if name == jname:
            return jid
    for jid, jname in declared:
        if name.startswith(jname + " ("):
            return jid
    return "?"


# ---------------------------------------------------------------------- jobs

def collect_job_samples(key):
    by_name = {}
    for rid in run_ids_for(key):
        run = load_run(rid)
        for job in run["jobs"]:
            by_name.setdefault(job["name"], [])
            if job.get("conclusion") != "success":
                continue
            s = job_seconds(job)
            if s is None:
                continue
            by_name[job["name"]].append((s, rid))
    return by_name


def current_names(declared, observed):
    """Drop a legacy un-suffixed matrix name (e.g. "Run test suite" from before
    the lane matrix existed) when suffixed variants ("Run test suite (min)")
    are also observed: it is not a job the current ci.yml can produce."""
    observed = set(observed)
    legacy = {jname for _, jname in declared
              if jname in observed and any(o.startswith(jname + " (") for o in observed)}
    return observed - legacy, sorted(legacy)


def expected_names(declared, observed):
    names, _legacy = current_names(declared, observed)
    observed = names
    for jid, jname in declared:
        if not any(job_id_for(o, declared) == jid for o in observed):
            names.add(jname)
    return names


def jobs_rows(workflow, event, job_filter):
    key = f"{workflow}:{event}"
    declared = workflow_jobs(workflow)
    samples = collect_job_samples(key)
    names = expected_names(declared, samples.keys()) if job_filter is None else {job_filter}
    rows = []
    for name in names:
        s = sort_samples(samples.get(name, []))
        row = {"job_id": job_id_for(name, declared), "job_name": name, "event": event, "n": len(s)}
        if s:
            p50, p95 = pick(s, 50), pick(s, 95)
            row.update({
                "p50_s": p50[0], "p50_run": p50[1],
                "p95_s": p95[0], "p95_run": p95[1],
                "min_s": s[0][0], "max_s": s[-1][0],
            })
        rows.append(row)
    rows.sort(key=lambda r: (r["job_id"], r["job_name"]))
    return rows


def jobs_command(workflow, event, name):
    return f'{SELF} jobs --workflow {workflow} --event {event} --job "{name}" --format md'


def jobs_md(row, workflow):
    cmd = jobs_command(workflow, row["event"], row["job_name"])
    head = f"| {row['job_id']} | {row['job_name']} | {row['event']} |"
    if row["n"] == 0:
        return f"{head} n=0 — not measured | — | — | — | `{cmd}` |"
    return (f"{head} n={row['n']} | p50 {row['p50_s']} s (run {row['p50_run']}) | "
            f"p95 {row['p95_s']} s (run {row['p95_run']}) | "
            f"min–max {row['min_s']}–{row['max_s']} s | `{cmd}` |")


def cmd_jobs(args):
    rows = jobs_rows(args.workflow, args.event, args.job)
    if args.format == "json":
        print(json.dumps(rows, indent=2, sort_keys=True))
    else:
        for row in rows:
            print(jobs_md(row, args.workflow))
    low = [r for r in rows if r["n"] < args.min]
    if low:
        for r in low:
            print(f"summarize-ci: {r['job_name']} ({args.event}) has n={r['n']} < --min {args.min}",
                  file=sys.stderr)
        return 2
    return 0


# ---------------------------------------------------------------------- wall

def ran(job):
    """A job that actually occupied a runner (skipped jobs did not)."""
    return job.get("conclusion") not in (None, "skipped") and job_seconds(job) is not None


def run_wall(run):
    jobs = [j for j in run["jobs"] if ran(j)]
    if not jobs:
        return None
    start = min(ts(j["started_at"]) for j in jobs)
    end = max(ts(j["completed_at"]) for j in jobs)
    return int((end - start).total_seconds())


def wall_stats(run_ids):
    samples = []
    for rid in run_ids:
        w = run_wall(load_run(rid))
        if w is not None:
            samples.append((w, rid))
    return sort_samples(samples)


def pct_cells(s, unit="s"):
    p50, p95 = pick(s, 50), pick(s, 95)
    return (f"p50 {p50[0]} {unit} (run {p50[1]}) | p95 {p95[0]} {unit} (run {p95[1]}) | "
            f"min–max {s[0][0]}–{s[-1][0]} {unit}")


def cmd_wall(args):
    s = wall_stats(run_ids_for(f"{args.workflow}:{args.event}"))
    cmd = f"{SELF} wall --workflow {args.workflow} --event {args.event}"
    if not s:
        print(f"| {args.workflow} | {args.event} | n=0 — not measured | — | — | — | `{cmd}` |")
        return 0
    print(f"| {args.workflow} | {args.event} | n={len(s)} | {pct_cells(s)} | `{cmd}` |")
    return 0


# -------------------------------------------------------------- critical path

def cmd_critical_path(args):
    declared = workflow_jobs(args.workflow)
    rids = run_ids_for(f"{args.workflow}:{args.event}")
    offsets = {}   # name -> [(offset, rid)]
    last = {}      # name -> count
    n_runs = 0
    for rid in rids:
        run = load_run(rid)
        jobs = [j for j in run["jobs"] if ran(j)]
        if not jobs:
            continue
        n_runs += 1
        first = min(ts(j["started_at"]) for j in jobs)
        voting = [j for j in jobs
                  if j.get("conclusion") == "success" and job_id_for(j["name"], declared) != AGGREGATE_JOB_ID]
        for j in voting:
            off = int((ts(j["completed_at"]) - first).total_seconds())
            offsets.setdefault(j["name"], []).append((off, rid))
        if voting:
            latest = max(ts(j["completed_at"]) for j in voting)
            for j in voting:
                if ts(j["completed_at"]) == latest:
                    last[j["name"]] = last.get(j["name"], 0) + 1
    names, _legacy = current_names(declared, offsets.keys())
    rows = sorted(names, key=lambda nm: (job_id_for(nm, declared), nm))
    cmd = f"{SELF} critical-path --workflow {args.workflow} --event {args.event}"
    for name in rows:
        s = sort_samples(offsets[name])
        p50, p95 = pick(s, 50), pick(s, 95)
        print(f"| {job_id_for(name, declared)} | {name} | {args.event} | "
              f"last in {last.get(name, 0)} of {n_runs} runs | n={len(s)} | "
              f"end offset p50 {p50[0]} s (run {p50[1]}) | p95 {p95[0]} s (run {p95[1]}) | `{cmd}` |")
    return 0


# ------------------------------------------------------------ runner-minutes

# Events that a push-to-main or a release cycle causes. Scheduled runs that
# happen to land on the same SHA (nightlies on an unchanged main) are excluded.
PUSH_CAUSED_EVENTS = ("push", "workflow_run")
RELEASE_EXCLUDED_EVENTS = ("schedule",)


def run_seconds(run):
    """(unrounded seconds, billed minutes) over every job that occupied a runner."""
    secs = [job_seconds(j) for j in run["jobs"] if ran(j)]
    return sum(secs), sum(billed_minutes(s) for s in secs)


def minute_cells(unrounded, billed):
    """unrounded, billed: sorted lists of (value, run_id)."""
    u50, u95 = pick(unrounded, 50), pick(unrounded, 95)
    b50, b95 = pick(billed, 50), pick(billed, 95)
    return (f"unrounded p50 {fmt_min(u50[0])} min (run {u50[1]}) | unrounded p95 {fmt_min(u95[0])} min (run {u95[1]}) | "
            f"billed p50 {b50[0]} min (run {b50[1]}) | billed p95 {b95[0]} min (run {b95[1]})")


def runner_minutes_pr(args):
    unrounded, billed = [], []
    for rid in run_ids_for("ci.yml:pull_request"):
        u, b = run_seconds(load_run(rid))
        unrounded.append((u, rid))
        billed.append((b, rid))
    cmd = f"{SELF} runner-minutes --unit pr"
    print(f"| per PR (one ci.yml pull_request run) | n={len(unrounded)} | "
          f"{minute_cells(sort_samples(unrounded), sort_samples(billed))} | `{cmd}` |")
    return 0


def push_units():
    """[(ci push run id, sha, [runs caused by that push])]"""
    entries = load_manifest()["entries"]
    out = []
    for rid in run_ids_for("ci.yml:push"):
        sha = load_run(rid)["head_sha"]
        key = f"sha:{sha}"
        if key not in entries:
            sys.exit(f"summarize-ci: no runs collected for push SHA {sha}; run collect-ci-runs.sh --head-sha {sha}")
        runs = [load_run(r) for r in sorted(set(entries[key]["run_ids"]))]
        runs = [r for r in runs if r["event"] in PUSH_CAUSED_EVENTS]
        out.append((rid, sha, runs))
    return out


def runner_minutes_push(args):
    unrounded, billed = [], []
    per_workflow = {}
    for rid, _sha, runs in push_units():
        u = b = 0
        for run in runs:
            ru, rb = run_seconds(run)
            u += ru
            b += rb
            per_workflow.setdefault(run["workflow"], []).append((ru, run["run_id"]))
        unrounded.append((u, rid))
        billed.append((b, rid))
    cmd = f"{SELF} runner-minutes --unit push"
    print(f"| per push-to-main (every push/workflow_run run on the pushed SHA; run = its ci.yml push run) | "
          f"n={len(unrounded)} | {minute_cells(sort_samples(unrounded), sort_samples(billed))} | `{cmd}` |")
    if args.detail:
        for wf in sorted(per_workflow):
            s = sort_samples(per_workflow[wf])
            p50, p95 = pick(s, 50), pick(s, 95)
            print(f"| component: {wf} | runs on {len(s)} of {len(unrounded)} pushed SHAs | "
                  f"unrounded p50 {fmt_min(p50[0])} min (run {p50[1]}) | unrounded p95 {fmt_min(p95[0])} min (run {p95[1]}) | `{cmd} --detail` |")
    return 0


def runner_minutes_release(args):
    path = os.path.join(RAW_DIR, f"release-{args.tag}.json")
    if not os.path.exists(path):
        sys.exit(f"summarize-ci: missing raw/ci/release-{args.tag}.json; run collect-ci-runs.sh --release-tag {args.tag}")
    with open(path, encoding="utf-8") as fh:
        rel = json.load(fh)
    roles = {r["sha"]: r["role"] for r in rel["sha_roles"]}
    cmd = f"{SELF} runner-minutes --unit release --tag {args.tag}"
    total_u = total_b = 0
    rows = []
    for rid in sorted(set(rel["run_ids"])):
        run = load_run(rid)
        if run["event"] in RELEASE_EXCLUDED_EVENTS:
            continue
        u, b = run_seconds(run)
        total_u += u
        total_b += b
        rows.append((roles.get(run["head_sha"], "?"), run["head_sha"][:8], run["workflow"], run["event"],
                     run["conclusion"], u, b, rid))
    order = {"release-please PR commit": 0, "release merge commit on main": 1, "distribution-sync PR commit": 2}
    rows.sort(key=lambda r: (order.get(r[0], 9), r[7]))
    if args.detail:
        for role, sha, wf, ev, concl, u, b, rid in rows:
            print(f"| {args.tag} | {role} {sha} | {wf} | {ev} | {concl} | unrounded {fmt_min(u)} min | billed {b} min | run {rid} |")
    print(f"| {args.tag} release cycle | {len(rel['head_shas'])} SHAs, {len(rows)} runs | "
          f"unrounded {fmt_min(total_u)} min | billed {total_b} min | `{cmd}` |")
    return 0


def cmd_runner_minutes(args):
    if args.unit == "pr":
        return runner_minutes_pr(args)
    if args.unit == "push":
        return runner_minutes_push(args)
    if not args.tag:
        sys.exit("summarize-ci: --unit release needs --tag vX.Y.Z")
    return runner_minutes_release(args)


# ------------------------------------------------------------- workflow cost

FAST_FAILURE_SECONDS = 600


def regime(run, wall):
    if run["conclusion"] == "success":
        return "success"
    if run["conclusion"] == "cancelled":
        return "cancelled"
    if wall is not None and wall < FAST_FAILURE_SECONDS:
        return "fast failure (< 10 min)"
    return "failure (>= 10 min)"


def cmd_workflow_cost(args):
    key = f"{args.workflow}:{args.event}:any:since-{args.since}"
    cmd = f"{SELF} workflow-cost --workflow {args.workflow} --event {args.event} --since {args.since}"
    runs = [load_run(r) for r in run_ids_for(key)]
    by_conclusion = {}
    ok_walls = []
    total_u = total_b = 0
    regimes = {}
    for run in runs:
        wall = run_wall(run)
        u, b = run_seconds(run)
        total_u += u
        total_b += b
        by_conclusion[run["conclusion"]] = by_conclusion.get(run["conclusion"], 0) + 1
        if run["conclusion"] == "success" and wall is not None:
            ok_walls.append((wall, run["run_id"]))
        rg = regimes.setdefault(regime(run, wall), [])
        rg.append((run["created_at"], run["run_id"], wall))
    first = min(runs, key=lambda r: (r["created_at"], r["run_id"]))
    last = max(runs, key=lambda r: (r["created_at"], r["run_id"]))
    counts = ", ".join(f"{k} {by_conclusion[k]}" for k in sorted(by_conclusion))
    print(f"| {args.workflow} | {args.event} | {len(runs)} runs {first['created_at'][:10]} to {last['created_at'][:10]} "
          f"(run {first['run_id']} to run {last['run_id']}) | {counts} | `{cmd}` |")
    if ok_walls:
        s = sort_samples(ok_walls)
        p50, p95 = pick(s, 50), pick(s, 95)
        print(f"| {args.workflow} | {args.event} | successful wall n={len(s)} | "
              f"p50 {fmt_min(p50[0])} min (run {p50[1]}) | p95 {fmt_min(p95[0])} min (run {p95[1]}) | "
              f"min–max {fmt_min(s[0][0])}–{fmt_min(s[-1][0])} min | `{cmd}` |")
    else:
        print(f"| {args.workflow} | {args.event} | successful wall n=0 — not measured | `{cmd}` |")
    print(f"| {args.workflow} | {args.event} | window total | unrounded {fmt_min(total_u)} min | billed {total_b} min | `{cmd}` |")
    if args.regimes:
        for name in sorted(regimes, key=lambda n: min(regimes[n])):
            rs = sorted(regimes[name])
            walls = sorted(w for _, _, w in rs if w is not None)
            span = f"wall {fmt_min(walls[0])}–{fmt_min(walls[-1])} min" if walls else "wall n/a"
            print(f"| {args.workflow} | regime: {name} | {len(rs)} runs | first {rs[0][0][:10]} (run {rs[0][1]}) | "
                  f"last {rs[-1][0][:10]} (run {rs[-1][1]}) | {span} | `{cmd} --regimes` |")
    return 0


# ---------------------------------------------------------------------- main

def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("jobs", help="per-job p50/p95")
    p.add_argument("--workflow", required=True)
    p.add_argument("--event", required=True)
    p.add_argument("--job")
    p.add_argument("--min", type=int, default=10)
    p.add_argument("--format", choices=["md", "json"], default="md")
    p.set_defaults(func=cmd_jobs)

    p = sub.add_parser("wall", help="per-run wall clock p50/p95")
    p.add_argument("--workflow", required=True)
    p.add_argument("--event", required=True)
    p.set_defaults(func=cmd_wall)

    p = sub.add_parser("critical-path", help="which job finishes last, end offsets")
    p.add_argument("--workflow", required=True)
    p.add_argument("--event", required=True)
    p.set_defaults(func=cmd_critical_path)

    p = sub.add_parser("runner-minutes", help="runner-minutes per PR / push-to-main / release cycle")
    p.add_argument("--unit", choices=["pr", "push", "release"], required=True)
    p.add_argument("--tag")
    p.add_argument("--detail", action="store_true")
    p.set_defaults(func=cmd_runner_minutes)

    p = sub.add_parser("workflow-cost", help="all completed runs of a workflow in a window")
    p.add_argument("--workflow", required=True)
    p.add_argument("--event", required=True)
    p.add_argument("--since", required=True)
    p.add_argument("--regimes", action="store_true")
    p.set_defaults(func=cmd_workflow_cost)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
