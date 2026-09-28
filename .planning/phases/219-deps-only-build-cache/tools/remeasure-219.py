#!/usr/bin/env python3
"""remeasure-219.py - deps-only build cache CI figures for 219-REMEASURE.md (CACHE-01).

Usage (from the repo root):
  python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py <subcommand> [--set NAME]
  python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py --self-test

Modeled on 218's remeasure-218.py. It imports this phase's copied
summarize-ci.py unchanged (job duration, nearest-rank percentiles,
(seconds, run id) ordering, unrounded and billed runner-minutes) and applies
it to named sample sets. The 214 and 218 raw data are read in place,
read-only; no JSON is ever copied between phases.

Sample sets (--set):
  base      the 214 BASE-01 ci.yml pull_request sample (read-only)
  post218   218's post-landing ci.yml set: every run in the 218 manifest's
            since-keyed pull_request and workflow_dispatch entries created at
            or after 218's land-branch push instant (POST_AFTER), read-only
  all219    every non-cancelled ci.yml run in this phase's own raw data that
            ran the 219 code (some job has a compile-on-miss step)
  warm      all219 runs labelled warm (every voting pair a genuine hit)
  cold      all219 runs labelled cold (every voting pair a miss or in-run)
  mixed     all219 runs labelled mixed (reported, never a warm or cold sample)

Hit / miss labels (D-18, D-25), from committed job JSON only:
  A (job, cache) pair VOTES only when the install step immediately before its
  compile-on-miss step in the committed steps list concluded success. The
  collector keeps list order and drops the API's step numbers, so position in
  the list is the only order used. A voting pair is "hit" when its
  compile-on-miss step concluded skipped and "miss" when it concluded success;
  anything else is "n/a". A hit is relabelled "in-run" when another job of
  the same run had already saved that cache family successfully when this
  pair's restore step started: no entry for the key existed in the scope when
  the run began, so it is cold-run evidence, never a warm hit.
    example family: any sibling's "Save example deps and deps-only build cache"
    root family:    only "Run test suite (current)"'s "Save deps-only build
                    cache", and only for jobs that restore that key
                    (ROOT_KEY_SHARERS); the min lane's root key differs
  A run is warm when it has a voting pair and every one is a genuine hit,
  cold when it has one and every one is miss or in-run, mixed otherwise.

Subcommands:
  samples                    one row per all219 run: event, head, scope, conclusion,
                             per job-lane root / example label, and the run class
  cache [--set S]            one row per (run, job, cache): label, gate, restore start,
                             and every sibling save's conclusion and completion time
  cache-steps [--set S]      p50/p95 of the restore, deps.compile, rm and save steps
                             per cached job-lane, split by label
  runner-minutes [--set S]   per-run runner-minutes p50/p95 (all jobs that ran)
  wall [--set S]             per-run wall clock p50/p95
  critical-path [--set S]    per-run critical-path end offset p50/p95 and last-job counts
  jobs [--set S]             per-job duration p50/p95 (successful jobs only)
  steps [--set S]            p50/p95 of the non-cache steps that did the dependency compile
                             before phase 219 (successful steps of successful jobs only)

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
RAW_219 = os.path.join(PHASE_DIR, "raw", "ci")
RAW_218 = os.path.join(PHASES_DIR, "218-ci-economy-remove-waste", "raw", "ci")
RAW_214 = os.path.join(PHASES_DIR, "214-baseline-measurement", "raw", "ci")

SELF = "python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py"

# 218's post set, exactly as remeasure-218.py defines it: the 218 land branch
# was pushed at 2026-09-27T23:34:10Z; earlier runs that day ran pre-218 code.
POST_AFTER = "2026-09-27T23:34:00Z"
POST_KEYS = ("ci.yml:pull_request:any:since-2026-09-27",
             "ci.yml:workflow_dispatch:any:since-2026-09-27")
BASE_KEY = "ci.yml:pull_request"

# Jobs removed by 218-04; the current ci.yml no longer declares them.
REMOVED_IDS = {"Mechanical checker (committed scorecards)": "verify-mechanical",
               "Build ExDoc (dev)": "verify-docs",
               "Hex package tarball": "verify-hex-package"}

# Cache scope per event (RESEARCH r2). Task 4 of 219-03 names the PR and branch.
SCOPES = {"pull_request": "refs/pull/<pr>/merge",
          "workflow_dispatch": "refs/heads/<branch>",
          "push": "refs/heads/main"}

SETS = ["base", "post218", "all219", "warm", "cold", "mixed"]

# --------------------------------------------------------------- cache labels
ROOT_MISS_STEP = "Compile dependencies on build cache miss"
EXAMPLE_MISS_STEP = "Compile example dependencies on cache miss"
ROOT_GATE_STEP = "Install dependencies"
EXAMPLE_GATE_STEP = "Install example dependencies"
ROOT_RESTORE_STEP = "Restore deps-only build cache"
EXAMPLE_RESTORE_STEP = "Restore example deps and deps-only build cache"
ROOT_SAVE_STEP = "Save deps-only build cache"
EXAMPLE_SAVE_STEP = "Save example deps and deps-only build cache"
ROOT_RM_STEP = "Remove own build (never cached, never reused)"
EXAMPLE_RM_STEP = "Remove example app's own build (never cached, never reused)"
# The one job that saves the root key pgbouncer restores (D-11).
ROOT_KEY_OWNER_JOB = "Run test suite (current)"
# Jobs whose root restore key equals the owner's. The min lane's differs.
ROOT_KEY_SHARERS = ("PgBouncer transaction topology",)

FAMILIES = {
    "root": {"gate": ROOT_GATE_STEP, "miss": ROOT_MISS_STEP, "restore": ROOT_RESTORE_STEP,
             "rm": ROOT_RM_STEP, "save": ROOT_SAVE_STEP},
    "example": {"gate": EXAMPLE_GATE_STEP, "miss": EXAMPLE_MISS_STEP, "restore": EXAMPLE_RESTORE_STEP,
                "rm": EXAMPLE_RM_STEP, "save": EXAMPLE_SAVE_STEP},
}

# Job-lanes carrying a cache pair, in the order the samples table prints them.
CACHED = (
    ("Run test suite (current)", "root"),
    ("Run test suite (current)", "example"),
    ("Run test suite (min)", "root"),
    ("Run test suite (min)", "example"),
    ("PgBouncer transaction topology", "root"),
    ("Example app browser E2E (Playwright)", "example"),
    ("Tier A capture lane (byte-stable evidence)", "example"),
)
SHORT = {"Run test suite (current)": "Test (current)", "Run test suite (min)": "Test (min)",
         "PgBouncer transaction topology": "PgBouncer",
         "Example app browser E2E (Playwright)": "Browser E2E",
         "Tier A capture lane (byte-stable evidence)": "Capture"}

VOTING = ("hit", "in-run", "miss")

# Steps that compiled dependencies before phase 219 (they still compile first-party code).
STEPS = (
    ("Run test suite (current)", "Compile (warnings as errors)"),
    ("Run test suite (current)", "Run tests"),
    ("Run test suite (current)", "Verify Threadline Phoenix example"),
    ("Run test suite (min)", "Compile (warnings as errors)"),
    ("Run test suite (min)", "Run tests"),
    ("PgBouncer transaction topology", "Compile (warnings as errors)"),
    ("PgBouncer transaction topology", "Bootstrap test DB (direct Postgres, bypass pooler)"),
    ("PgBouncer transaction topology", "Topology tests + verify_coverage through PgBouncer"),
    ("Example app browser E2E (Playwright)", "Run example Playwright suite"),
    ("Tier A capture lane (byte-stable evidence)", "Regenerate Tier A capture"),
)

_spec = importlib.util.spec_from_file_location("summarize_ci", os.path.join(TOOLS_DIR, "summarize-ci.py"))
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def find_step(steps, name):
    for st in steps:
        if st["name"] == name:
            return st
    return None


def label_pair(steps, gate_name, miss_name):
    """hit | miss | n/a for one (job, cache) pair, by committed list position."""
    idx = next((i for i, st in enumerate(steps) if st["name"] == miss_name), None)
    if idx is None or idx == 0:
        return "n/a"
    gate = steps[idx - 1]
    if gate["name"] != gate_name or gate.get("conclusion") != "success":
        return "n/a"
    conc = steps[idx].get("conclusion")
    if conc == "skipped":
        return "hit"
    if conc == "success":
        return "miss"
    return "n/a"


def in_run_source(run_jobs, job, family):
    """True when a sibling saved this family's key before this job's restore started."""
    fam = FAMILIES[family]
    restore = find_step(job.get("steps", []), fam["restore"])
    if not restore or not restore.get("started_at"):
        return False
    if family == "root" and job["name"] not in ROOT_KEY_SHARERS:
        return False
    started = S.ts(restore["started_at"])
    for other in run_jobs:
        if other is job:
            continue
        if family == "root" and other["name"] != ROOT_KEY_OWNER_JOB:
            continue
        save = find_step(other.get("steps", []), fam["save"])
        if save and save.get("conclusion") == "success" and save.get("completed_at") \
                and S.ts(save["completed_at"]) <= started:
            return True
    return False


def job_pairs(job):
    """The cache families this job carries (it has that family's compile-on-miss step)."""
    names = {st["name"] for st in job.get("steps", [])}
    return [f for f in ("root", "example") if FAMILIES[f]["miss"] in names]


def label_run_pairs(run_jobs):
    """{(job name, family): hit | in-run | miss | n/a} for every cache pair in the run."""
    out = {}
    for job in run_jobs:
        for fam in job_pairs(job):
            lab = label_pair(job.get("steps", []), FAMILIES[fam]["gate"], FAMILIES[fam]["miss"])
            if lab == "hit" and in_run_source(run_jobs, job, fam):
                lab = "in-run"
            out[(job["name"], fam)] = lab
    return out


def label_run(run_jobs):
    votes = [v for v in label_run_pairs(run_jobs).values() if v in VOTING]
    if votes and all(v == "hit" for v in votes):
        return "warm"
    if votes and all(v in ("miss", "in-run") for v in votes):
        return "cold"
    return "mixed"


# ------------------------------------------------------------------------ io

def load_manifest(raw):
    with open(os.path.join(raw, "manifest.json"), encoding="utf-8") as fh:
        return json.load(fh)


def load_run(raw, rid):
    with open(os.path.join(raw, "runs", f"{rid}.json"), encoding="utf-8") as fh:
        return json.load(fh)


def post218_runs():
    m = load_manifest(RAW_218)["entries"]
    rids = sorted({int(r) for k in POST_KEYS for r in m[k]["run_ids"]})
    runs = [load_run(RAW_218, r) for r in rids]
    return [r for r in runs if r["created_at"] >= POST_AFTER]


def is_219_code(run):
    return any(job_pairs(j) for j in run["jobs"])


def runs_219():
    """Non-cancelled ci.yml runs in 219's own raw data that ran the 219 code."""
    if not os.path.exists(os.path.join(RAW_219, "manifest.json")):
        return []
    m = load_manifest(RAW_219)["entries"]
    rids = sorted({int(r) for k, e in m.items() if k.startswith("ci.yml:") for r in e["run_ids"]})
    runs = [load_run(RAW_219, r) for r in rids]
    return [r for r in runs if r["conclusion"] != "cancelled" and is_219_code(r)]


def runs_for(name):
    if name == "base":
        m = load_manifest(RAW_214)["entries"]
        return [load_run(RAW_214, r) for r in sorted({int(x) for x in m[BASE_KEY]["run_ids"]})]
    if name == "post218":
        return post218_runs()
    runs = runs_219()
    if name == "all219":
        return runs
    if name in ("warm", "cold", "mixed"):
        return [r for r in runs if label_run(r["jobs"]) == name]
    sys.exit(f"remeasure-219: unknown set {name!r}")


def job_id(name):
    declared = S.workflow_jobs("ci.yml")
    jid = S.job_id_for(name, declared)
    return REMOVED_IDS.get(name, jid) if jid == "?" else jid


def cmd(sub, sset=None):
    return f"`{SELF} {sub}`" if sset is None else f"`{SELF} {sub} --set {sset}`"


def pcell(samples, unit="s"):
    s = S.sort_samples(samples)
    p50, p95 = S.pick(s, 50), S.pick(s, 95)
    return (f"p50 {p50[0]} {unit} (run {p50[1]}) | p95 {p95[0]} {unit} (run {p95[1]}) | "
            f"min–max {s[0][0]}–{s[-1][0]} {unit}")


def empty(sub, sset=None):
    label = f"set {sset}" if sset else "phase 219 raw data"
    print(f"| {label} | no samples yet: nothing to measure | {cmd(sub, sset)} |")
    return 0


# ------------------------------------------------------------ cache subcommands

def sub_samples(args):
    runs = runs_219()
    if not runs:
        return empty("samples")
    heads = " | ".join(f"{SHORT[j]} {f}" for j, f in CACHED)
    print(f"| Run | Event | Head | Scope | Conclusion | {heads} | Class | Regenerate |")
    print("|---" * (7 + len(CACHED)) + "|")
    for r in runs:
        labels = label_run_pairs(r["jobs"])
        cells = " | ".join(labels.get(k, "absent") for k in CACHED)
        print(f"| run {r['run_id']} | {r['event']} | {r['head_sha'][:8]} | "
              f"{SCOPES.get(r['event'], r['event'])} | {r['conclusion']} | {cells} | "
              f"{label_run(r['jobs'])} | {cmd('samples')} |")
    return 0


def sub_cache(args):
    runs = runs_for(args.set)
    if not runs:
        return empty("cache", args.set)
    for r in runs:
        labels = label_run_pairs(r["jobs"])
        for job in r["jobs"]:
            for fam in job_pairs(job):
                steps = job.get("steps", [])
                fs = FAMILIES[fam]
                gate = find_step(steps, fs["gate"])
                restore = find_step(steps, fs["restore"])
                saves = []
                for other in r["jobs"]:
                    if other is job:
                        continue
                    sv = find_step(other.get("steps", []), fs["save"])
                    if sv:
                        saves.append(f"{SHORT.get(other['name'], other['name'])} "
                                     f"{sv.get('conclusion')} {sv.get('completed_at') or '-'}")
                print(f"| run {r['run_id']} | {SHORT.get(job['name'], job['name'])} | {fam} | "
                      f"{labels[(job['name'], fam)]} | gate {gate.get('conclusion') if gate else 'absent'} | "
                      f"restore started {restore.get('started_at') if restore else '-'} | "
                      f"sibling saves: {'; '.join(saves) if saves else 'none'} | "
                      f"{cmd('cache', args.set)} |")
    return 0


def sub_cache_steps(args):
    runs = runs_for(args.set)
    if not runs:
        return empty("cache-steps", args.set)
    for job_name, fam in CACHED:
        fs = FAMILIES[fam]
        for step_key in ("restore", "miss", "rm", "save"):
            by = {}
            for r in runs:
                labels = label_run_pairs(r["jobs"])
                for j in r["jobs"]:
                    if j["name"] != job_name or (job_name, fam) not in labels:
                        continue
                    st = find_step(j.get("steps", []), fs[step_key])
                    if st and st.get("conclusion") == "success" and st.get("started_at") and st.get("completed_at"):
                        sec = S.seconds(st["started_at"], st["completed_at"])
                        by.setdefault(labels[(job_name, fam)], []).append((sec, r["run_id"]))
            for lab in VOTING:
                if lab in by:
                    print(f"| {SHORT[job_name]} | {fam} | step: {fs[step_key]} | label {lab} | set {args.set} | "
                          f"n={len(by[lab])} | {pcell(by[lab])} | {cmd('cache-steps', args.set)} |")
    return 0


# ------------------------------------------------------------- timing subcommands

def minutes(runs):
    u, b = [], []
    for r in runs:
        secs = [S.job_seconds(j) for j in r["jobs"] if S.ran(j)]
        u.append((sum(secs), r["run_id"]))
        b.append((sum(S.billed_minutes(x) for x in secs), r["run_id"]))
    return S.sort_samples(u), S.sort_samples(b)


def sub_runner_minutes(args):
    runs = runs_for(args.set)
    if not runs:
        return empty("runner-minutes", args.set)
    u, b = minutes(runs)
    u50, u95, b50, b95 = S.pick(u, 50), S.pick(u, 95), S.pick(b, 50), S.pick(b, 95)
    print(f"| per ci.yml run, every job that ran | set {args.set} | n={len(u)} | "
          f"unrounded p50 {S.fmt_min(u50[0])} min (run {u50[1]}) | "
          f"unrounded p95 {S.fmt_min(u95[0])} min (run {u95[1]}) | billed p50 {b50[0]} min (run {b50[1]}) | "
          f"billed p95 {b95[0]} min (run {b95[1]}) | {cmd('runner-minutes', args.set)} |")
    return 0


def sub_wall(args):
    s = [(S.run_wall(r), r["run_id"]) for r in runs_for(args.set) if S.run_wall(r) is not None]
    if not s:
        return empty("wall", args.set)
    print(f"| wall clock | set {args.set} | n={len(s)} | {pcell(s)} | {cmd('wall', args.set)} |")
    return 0


def critical_path_end(run_jobs):
    """(offset seconds, names of the last voting jobs) for one run, or None.

    None when no job ran or no voting job succeeded: all219 keeps failed runs,
    and such a run has no critical-path end to measure (IN-02, 219 review).
    """
    jobs = [j for j in run_jobs if S.ran(j)]
    voting = [j for j in jobs if j["conclusion"] == "success" and job_id(j["name"]) != "ci-required"]
    if not jobs or not voting:
        return None
    first = min(S.ts(j["started_at"]) for j in jobs)
    latest = max(S.ts(j["completed_at"]) for j in voting)
    names = [j["name"] for j in voting if S.ts(j["completed_at"]) == latest]
    return int((latest - first).total_seconds()), names


def sub_critical_path(args):
    offs, last, skipped = [], {}, []
    for r in runs_for(args.set):
        end = critical_path_end(r["jobs"])
        if end is None:
            skipped.append(r["run_id"])
            continue
        offs.append((end[0], r["run_id"]))
        for name in end[1]:
            last[name] = last.get(name, 0) + 1
    if skipped:
        print(f"| critical-path: runs with no successful voting job, not measured | set {args.set} | "
              f"n={len(skipped)} | runs {', '.join(str(x) for x in skipped)} | "
              f"{cmd('critical-path', args.set)} |")
    if not offs:
        return empty("critical-path", args.set)
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
    if not by:
        return empty("jobs", args.set)
    for name in sorted(by, key=lambda n: (job_id(n), n)):
        print(f"| {job_id(name)} | {name} | set {args.set} | n={len(by[name])} | {pcell(by[name])} | "
              f"{cmd('jobs', args.set)} |")
    return 0


def sub_steps(args):
    runs = runs_for(args.set)
    if not runs:
        return empty("steps", args.set)
    for job_name, step in STEPS:
        s = []
        for r in runs:
            for j in r["jobs"]:
                if j["name"] != job_name or j["conclusion"] != "success":
                    continue
                st = find_step(j.get("steps", []), step)
                if st and st.get("conclusion") == "success" and st.get("started_at") and st.get("completed_at"):
                    s.append((S.seconds(st["started_at"], st["completed_at"]), r["run_id"]))
        if s:
            print(f"| {SHORT[job_name]} | step: {step} | set {args.set} | n={len(s)} | {pcell(s)} | "
                  f"{cmd('steps', args.set)} |")
        else:
            print(f"| {SHORT[job_name]} | step: {step} | set {args.set} | n=0, not measured | "
                  f"{cmd('steps', args.set)} |")
    return 0


# ------------------------------------------------------------------ self-test

def _t(sec):
    base = 1_790_000_000 + sec  # any fixed instant; only ordering matters
    from datetime import datetime, timezone
    return datetime.fromtimestamp(base, tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _st(name, conc, start, end):
    return {"name": name, "conclusion": conc, "started_at": _t(start), "completed_at": _t(end)}


def _root_block(miss, t0, save_end, gate="success"):
    """Root cache steps in ci.yml order. miss: True, False (hit) or None (upstream skip)."""
    comp = "success" if miss else "skipped"
    save = "success" if miss else "skipped"
    if gate != "success":
        comp, save = "skipped", "skipped"
    return [_st(ROOT_RESTORE_STEP, "success", t0, t0 + 2),
            _st("Cache deps", "success", t0 + 2, t0 + 4),
            _st(ROOT_GATE_STEP, gate, t0 + 4, t0 + 6),
            _st(ROOT_MISS_STEP, comp, t0 + 6, t0 + 40),
            _st(ROOT_RM_STEP, "success" if gate == "success" else "skipped", t0 + 40, t0 + 41),
            _st(ROOT_SAVE_STEP, save, t0 + 41, save_end)]


def _example_block(state, t0, save_end, save=None):
    """Example cache steps. state: 'miss', 'hit' or 'lane' (lane guard skips the block)."""
    if state == "lane":
        return [_st(EXAMPLE_RESTORE_STEP, "skipped", t0, t0),
                _st(EXAMPLE_GATE_STEP, "skipped", t0, t0),
                _st(EXAMPLE_MISS_STEP, "skipped", t0, t0),
                _st(EXAMPLE_RM_STEP, "success", t0, t0 + 1),
                _st(EXAMPLE_SAVE_STEP, "skipped", t0 + 1, t0 + 1)]
    miss = state == "miss"
    if save is None:
        save = "success" if miss else "skipped"
    return [_st(EXAMPLE_RESTORE_STEP, "success", t0, t0 + 3),
            _st(EXAMPLE_GATE_STEP, "success", t0 + 3, t0 + 5),
            _st(EXAMPLE_MISS_STEP, "success" if miss else "skipped", t0 + 5, t0 + 30),
            _st(EXAMPLE_RM_STEP, "success", t0 + 30, t0 + 31),
            _st(EXAMPLE_SAVE_STEP, save, t0 + 31, save_end)]


def _job(name, steps):
    return {"name": name, "conclusion": "success", "steps": steps}


def _run(root_cur="miss", root_min="miss", root_pgb="miss", ex_cur="miss", ex_browser="miss",
         ex_capture="miss", pgb_restore=10, cur_ex_restore=500, browser_save_end=120,
         capture_save_end=130, browser_save=None, capture_save=None):
    rb = lambda s: {"miss": True, "hit": False}[s]
    return [
        _job("Run test suite (current)",
             _root_block(rb(root_cur), 0, 100) + [_st("Run tests", "success", 101, 480)]
             + _example_block(ex_cur, cur_ex_restore, cur_ex_restore + 60)),
        _job("Run test suite (min)", _root_block(rb(root_min), 0, 90) + _example_block("lane", 400, 400)),
        _job("PgBouncer transaction topology", _root_block(rb(root_pgb), pgb_restore, pgb_restore)[:5]),
        _job("Example app browser E2E (Playwright)",
             _example_block(ex_browser, 60, browser_save_end, browser_save)),
        _job("Tier A capture lane (byte-stable evidence)",
             _example_block(ex_capture, 70, capture_save_end, capture_save)),
    ]


def self_test():
    fails = []

    def check(case, got, want):
        if got != want:
            fails.append(f"FAIL {case}: got {got!r}, want {want!r}")

    # (a) cold: min lane example lane-skipped, every other compile-on-miss step success.
    run_a = _run(cur_ex_restore=50)  # restore before any sibling save: a plain miss
    check("a min-lane example pair", label_run_pairs(run_a)[("Run test suite (min)", "example")], "n/a")
    check("a run", label_run(run_a), "cold")
    # (b) warm: every executed compile-on-miss step skipped, no save success anywhere.
    run_b = _run(root_cur="hit", root_min="hit", root_pgb="hit", ex_cur="hit", ex_browser="hit",
                 ex_capture="hit")
    check("b run", label_run(run_b), "warm")
    check("b pgbouncer root pair", label_run_pairs(run_b)[("PgBouncer transaction topology", "root")], "hit")
    # (c) failed install gate: the skipped compile step is n/a, never a hit.
    steps_c = _root_block(False, 0, 0, gate="failure")
    check("c pair", label_pair(steps_c, ROOT_GATE_STEP, ROOT_MISS_STEP), "n/a")
    # the gate must be the step immediately before the compile step
    steps_c2 = [s for s in _root_block(False, 0, 0)]
    steps_c2.insert(3, _st("Unrelated step", "success", 5, 6))
    check("c non-adjacent gate", label_pair(steps_c2, ROOT_GATE_STEP, ROOT_MISS_STEP), "n/a")
    steps_c3 = _root_block(True, 0, 0)
    steps_c3[3]["conclusion"] = "cancelled"
    check("c cancelled compile", label_pair(steps_c3, ROOT_GATE_STEP, ROOT_MISS_STEP), "n/a")
    # (d) a genuine hit and a miss mix.
    run_d = [_job("Run test suite (current)", _root_block(False, 0, 100)),
             _job("PgBouncer transaction topology", _root_block(True, 10, 10)[:5])]
    check("d run", label_run(run_d), "mixed")
    # (e) no voting pair at all.
    run_e = [_job("Run test suite (current)", _root_block(False, 0, 0, gate="failure")),
             _job("Run test suite (min)", _example_block("lane", 0, 0))]
    check("e run", label_run(run_e), "mixed")
    check("e empty run", label_run([]), "mixed")
    # (f) fresh scope: siblings missed and saved the example key before verify-test current restored it.
    run_f = _run(ex_cur="hit")
    pairs_f = label_run_pairs(run_f)
    check("f current example pair", pairs_f[("Run test suite (current)", "example")], "in-run")
    check("f run", label_run(run_f), "cold")
    # (g) as (f), and pgbouncer's root hit came after Run test suite (current) saved the root key.
    run_g = _run(ex_cur="hit", root_pgb="hit", pgb_restore=150)
    pairs_g = label_run_pairs(run_g)
    check("g pgbouncer root pair", pairs_g[("PgBouncer transaction topology", "root")], "in-run")
    check("g run", label_run(run_g), "cold")
    # the min lane's root key differs: a min root hit is never in-run, even after the owner saved.
    run_g2 = _run(ex_cur="hit", root_min="hit")
    run_g2[1]["steps"][0]["started_at"] = _t(200)
    check("g min root never in-run", label_run_pairs(run_g2)[("Run test suite (min)", "root")], "hit")
    # a pgbouncer hit restored BEFORE the owner's save completed is a genuine hit
    run_g3 = _run(ex_cur="hit", root_pgb="hit", pgb_restore=10)
    check("g early pgbouncer hit", label_run_pairs(run_g3)[("PgBouncer transaction topology", "root")], "hit")
    # (h) the same hit as (f) with every sibling example save skipped ...
    run_h1 = _run(ex_cur="hit", browser_save="skipped", capture_save="skipped")
    check("h1 current example pair", label_run_pairs(run_h1)[("Run test suite (current)", "example")], "hit")
    check("h1 run", label_run(run_h1), "mixed")
    # ... or with the only sibling save completing AFTER the restore started.
    run_h2 = _run(ex_cur="hit", browser_save="skipped", capture_save_end=600)
    check("h2 current example pair", label_run_pairs(run_h2)[("Run test suite (current)", "example")], "hit")
    check("h2 run", label_run(run_h2), "mixed")
    # equal timestamps count as "at or before"
    run_h3 = _run(ex_cur="hit", browser_save="skipped", capture_save_end=500)
    check("h3 save at restore instant", label_run_pairs(run_h3)[("Run test suite (current)", "example")],
          "in-run")

    # (i) critical path: a run whose every voting job failed, or where no job ran,
    # is skipped instead of raising ValueError (IN-02).
    failed = [dict(j, conclusion="failure") for j in _run()]
    for j in failed:
        j["started_at"], j["completed_at"] = _t(0), _t(10)
    check("i all voting failed", critical_path_end(failed), None)
    check("i no job ran", critical_path_end([]), None)
    ok = [{"name": "Run test suite (current)", "conclusion": "success",
           "started_at": _t(0), "completed_at": _t(300)},
          {"name": "CI required", "conclusion": "success", "started_at": _t(0), "completed_at": _t(400)}]
    check("i one voting job", critical_path_end(ok), (300, ["Run test suite (current)"]))

    for f in fails:
        print(f)
    if fails:
        return 1
    print("self-test: ok")
    return 0


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if argv == ["--self-test"]:
        return self_test()
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="sub", required=True)
    table = {"samples": sub_samples, "cache": sub_cache, "cache-steps": sub_cache_steps,
             "runner-minutes": sub_runner_minutes, "wall": sub_wall,
             "critical-path": sub_critical_path, "jobs": sub_jobs, "steps": sub_steps}
    for name in table:
        sp = sub.add_parser(name)
        sp.add_argument("--set", default="all219", choices=SETS)
    args = p.parse_args(argv)
    return table[args.sub](args)


if __name__ == "__main__":
    sys.exit(main())
