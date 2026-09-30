#!/usr/bin/env python3
"""remeasure-218.py - post-change CI figures for 218-REMEASURE.md (ECON-07).

Usage (from the repo root):
  python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py <subcommand> [--set NAME]

Why a separate script: the copied summarize-ci.py keys its jobs / wall /
critical-path / runner-minutes modes on the plain manifest keys
("ci.yml:pull_request"), while the post-landing collection is keyed
"ci.yml:<event>:any:since-2026-09-27" and mixes pull_request with
workflow_dispatch top-ups on the same branch. This script reuses the copied
summarizer's arithmetic unchanged (imported, never edited): job duration,
nearest-rank percentiles, (seconds, run id) ordering, unrounded and billed
runner-minutes.

Sample sets (--set):
  post          every ci.yml run created at or after the land-branch push
                instant (POST_AFTER) in the 218 manifest, pull_request and
                workflow_dispatch together
  post-pr       post, pull_request only
  post-dispatch post, workflow_dispatch only
  post-success  post, run conclusion success only
  base          the 214 BASE-01 ci.yml pull_request sample (read-only)

Subcommands:
  samples                    one row per post-landing run, with which jobs failed
  runner-minutes [--set S]   per-run runner-minutes p50/p95 (all jobs that ran)
  comparable-minutes [--set S]  the same, excluding jobs added since BASE-01
                             by unrelated phases (verify-deps-audit, verify-repo-hygiene)
  wall [--set S]             per-run wall clock p50/p95
  critical-path [--set S]    per-run critical-path end offset p50/p95 and last-job counts
  jobs [--set S]             per-job duration p50/p95 (successful jobs only)
  dialyzer [--set S]         verify-dialyzer per run, labeled hit / miss from the
                             "Report exact PLT cache hit" step conclusion
  steps [--set S]            step p50 for the steps the attribution needs

Standard library only. Reads raw JSON only; never calls GitHub.
"""
import argparse
import importlib.util
import json
import os
import sys

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
PHASE_DIR = os.path.dirname(TOOLS_DIR)
PHASES_DIR = os.path.dirname(PHASE_DIR)
RAW_218 = os.path.join(PHASE_DIR, "raw", "ci")
RAW_214 = os.path.join(PHASES_DIR, "214-baseline-measurement", "raw", "ci")

SELF = "python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py"

# The land branch was pushed at 2026-09-27T23:34:10Z; the earlier runs that
# day belong to other PRs running pre-218 code.
POST_AFTER = "2026-09-27T23:34:00Z"
POST_KEYS = ("ci.yml:pull_request:any:since-2026-09-27",
             "ci.yml:workflow_dispatch:any:since-2026-09-27")
BASE_KEY = "ci.yml:pull_request"

# Jobs that phases 215-217 added to ci.yml after BASE-01. They are not ECON savings.
UNRELATED_ADDED = ("Dependency audit (all lockfiles)", "Repo hygiene (no machine-local paths)")
# Jobs removed by 218-04; the current ci.yml no longer declares them.
REMOVED_IDS = {"Mechanical checker (committed scorecards)": "verify-mechanical",
               "Build ExDoc (dev)": "verify-docs",
               "Hex package tarball": "verify-hex-package"}

_spec = importlib.util.spec_from_file_location("summarize_ci", os.path.join(TOOLS_DIR, "summarize-ci.py"))
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def load_manifest(raw):
    with open(os.path.join(raw, "manifest.json"), encoding="utf-8") as fh:
        return json.load(fh)


def load_run(raw, rid):
    with open(os.path.join(raw, "runs", f"{rid}.json"), encoding="utf-8") as fh:
        return json.load(fh)


def post_runs():
    m = load_manifest(RAW_218)["entries"]
    rids = sorted({int(r) for k in POST_KEYS for r in m[k]["run_ids"]})
    runs = [load_run(RAW_218, r) for r in rids]
    return [r for r in runs if r["created_at"] >= POST_AFTER]


def runs_for(name):
    if name == "base":
        m = load_manifest(RAW_214)["entries"]
        return [load_run(RAW_214, r) for r in sorted({int(x) for x in m[BASE_KEY]["run_ids"]})]
    runs = post_runs()
    if name == "post":
        return runs
    if name == "post-pr":
        return [r for r in runs if r["event"] == "pull_request"]
    if name == "post-dispatch":
        return [r for r in runs if r["event"] == "workflow_dispatch"]
    if name == "post-success":
        return [r for r in runs if r["conclusion"] == "success"]
    sys.exit(f"remeasure-218: unknown set {name!r}")


def job_id(name):
    declared = S.workflow_jobs("ci.yml")
    jid = S.job_id_for(name, declared)
    return REMOVED_IDS.get(name, jid) if jid == "?" else jid


def cmd(sub, sset):
    return f"`{SELF} {sub} --set {sset}`"


def pcell(samples, unit="s"):
    s = S.sort_samples(samples)
    p50, p95 = S.pick(s, 50), S.pick(s, 95)
    return (f"p50 {p50[0]} {unit} (run {p50[1]}) | p95 {p95[0]} {unit} (run {p95[1]}) | "
            f"min–max {s[0][0]}–{s[-1][0]} {unit}")


def sub_samples(args):
    print("| Run | Event | Head | Conclusion | Jobs that ran | Jobs not success | Regenerate |")
    print("|---|---|---|---|---|---|---|")
    for r in post_runs():
        ran = [j for j in r["jobs"] if S.ran(j)]
        bad = sorted(j["name"] for j in ran if j["conclusion"] != "success")
        print(f"| run {r['run_id']} | {r['event']} | {r['head_sha'][:8]} | {r['conclusion']} | "
              f"{len(ran)} jobs | {', '.join(bad) if bad else 'none'} | `{SELF} samples` |")
    return 0


def minutes(runs, exclude=()):
    u, b = [], []
    for r in runs:
        secs = [S.job_seconds(j) for j in r["jobs"] if S.ran(j) and j["name"] not in exclude]
        u.append((sum(secs), r["run_id"]))
        b.append((sum(S.billed_minutes(x) for x in secs), r["run_id"]))
    return S.sort_samples(u), S.sort_samples(b)


def print_minutes(label, runs, exclude, sub, sset):
    u, b = minutes(runs, exclude)
    u50, u95, b50, b95 = S.pick(u, 50), S.pick(u, 95), S.pick(b, 50), S.pick(b, 95)
    print(f"| {label} | set {sset} | n={len(u)} | unrounded p50 {S.fmt_min(u50[0])} min (run {u50[1]}) | "
          f"unrounded p95 {S.fmt_min(u95[0])} min (run {u95[1]}) | billed p50 {b50[0]} min (run {b50[1]}) | "
          f"billed p95 {b95[0]} min (run {b95[1]}) | {cmd(sub, sset)} |")


def sub_runner_minutes(args):
    print_minutes("per ci.yml run, every job that ran", runs_for(args.set), (), "runner-minutes", args.set)
    return 0


def sub_comparable(args):
    print_minutes("per ci.yml run, excluding jobs added since BASE-01 by phases 215-217",
                  runs_for(args.set), UNRELATED_ADDED, "comparable-minutes", args.set)
    return 0


def sub_wall(args):
    s = [(S.run_wall(r), r["run_id"]) for r in runs_for(args.set) if S.run_wall(r) is not None]
    print(f"| wall clock | set {args.set} | n={len(s)} | {pcell(s)} | {cmd('wall', args.set)} |")
    return 0


def sub_critical_path(args):
    offs, last = [], {}
    for r in runs_for(args.set):
        jobs = [j for j in r["jobs"] if S.ran(j)]
        first = min(S.ts(j["started_at"]) for j in jobs)
        voting = [j for j in jobs if j["conclusion"] == "success" and job_id(j["name"]) != "ci-required"]
        latest = max(S.ts(j["completed_at"]) for j in voting)
        offs.append((int((latest - first).total_seconds()), r["run_id"]))
        for j in voting:
            if S.ts(j["completed_at"]) == latest:
                last[j["name"]] = last.get(j["name"], 0) + 1
    print(f"| critical-path end offset (last voting job) | set {args.set} | n={len(offs)} | {pcell(offs)} | "
          f"{cmd('critical-path', args.set)} |")
    for name in sorted(last, key=lambda n: (-last[n], n)):
        print(f"| last to finish: {name} | set {args.set} | last in {last[name]} of {len(offs)} runs | "
              f"{cmd('critical-path', args.set)} |")
    return 0


def sub_jobs(args):
    by = {}
    for r in runs_for(args.set):
        for j in r["jobs"]:
            if j["conclusion"] == "success" and S.job_seconds(j) is not None:
                by.setdefault(j["name"], []).append((S.job_seconds(j), r["run_id"]))
    for name in sorted(by, key=lambda n: (job_id(n), n)):
        print(f"| {job_id(name)} | {name} | set {args.set} | n={len(by[name])} | {pcell(by[name])} | "
              f"{cmd('jobs', args.set)} |")
    return 0


def step_secs(job, name):
    for st in job.get("steps", []):
        if st["name"] == name and st.get("started_at") and st.get("completed_at"):
            return st["conclusion"], S.seconds(st["started_at"], st["completed_at"])
    return None, None


def sub_dialyzer(args):
    hit, miss = [], []
    for r in runs_for(args.set):
        for j in r["jobs"]:
            if not j["name"].startswith("Dialyzer") or j["conclusion"] != "success":
                continue
            rep, _ = step_secs(j, "Report exact PLT cache hit")
            bconc, bsec = step_secs(j, "Build and measure Dialyzer PLT on cache miss")
            label = "hit" if rep == "success" else "miss"
            (hit if label == "hit" else miss).append((S.job_seconds(j), r["run_id"]))
            print(f"| run {r['run_id']} | {label} | job {S.job_seconds(j)} s | PLT build step "
                  f"{bconc} {bsec} s | {cmd('dialyzer', args.set)} |")
    for label, s in (("hit", hit), ("miss", miss)):
        if s:
            print(f"| verify-dialyzer {label} samples | set {args.set} | n={len(s)} | {pcell(s)} | "
                  f"{cmd('dialyzer', args.set)} |")
    return 0


STEPS = (
    ("Dialyzer (current toolchain)", "Initialize containers"),
    ("Dialyzer (current toolchain)", "Compile full optional build"),
    ("Dialyzer (current toolchain)", "Analyze and measure with Dialyzer"),
    ("Dialyzer (current toolchain)", "Live Dialyzer slice proof (fails closed)"),
    ("Tier A capture lane (byte-stable evidence)", "Assert mechanical checker clean over real evidence"),
    ("Run test suite (current)", "Run tests"),
    ("Run test suite (min)", "Run tests"),
)


def sub_steps(args):
    runs = runs_for(args.set)
    for job_name, step in STEPS:
        s = []
        for r in runs:
            for j in r["jobs"]:
                if j["name"] == job_name and j["conclusion"] == "success":
                    conc, sec = step_secs(j, step)
                    if conc == "success":
                        s.append((sec, r["run_id"]))
        if s:
            print(f"| {job_name} | step: {step} | set {args.set} | n={len(s)} | {pcell(s)} | "
                  f"{cmd('steps', args.set)} |")
        else:
            print(f"| {job_name} | step: {step} | set {args.set} | n=0 — not measured | {cmd('steps', args.set)} |")
    return 0


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="sub", required=True)
    table = {"samples": sub_samples, "runner-minutes": sub_runner_minutes,
             "comparable-minutes": sub_comparable, "wall": sub_wall,
             "critical-path": sub_critical_path, "jobs": sub_jobs,
             "dialyzer": sub_dialyzer, "steps": sub_steps}
    for name in table:
        sp = sub.add_parser(name)
        sp.add_argument("--set", default="post",
                        choices=["post", "post-pr", "post-dispatch", "post-success", "base"])
    args = p.parse_args(argv)
    return table[args.sub](args)


if __name__ == "__main__":
    sys.exit(main())
