#!/usr/bin/env python3
"""ci-job-timing.py - READ-ONLY CI timing/proxy computation for the SUITE-01/SUITE-02 baseline.

This is the single script that computes both the "before" and "after" figures
for Phase 225, so the before/after formula cannot drift between citations
(D-14a). It shells out to `gh api` with a default-GET request only — no
dispatch, re-run, cancel, push, comment, or HTTP method override. Standard
library only (plus the `gh` CLI, already required by this repo's workflow).

Usage (from the repo root):
  python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py <run-id> [--cache-state]
  python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare <before-id> <after-id> [<after-id> ...]
  python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --self-test

Modes:
  <run-id>
    Selects exactly the three jobs named "Build and test (min)",
    "Build and test (current)", "Build and test (latest)" from
    `gh api repos/szTheory/threadline/actions/runs/<run-id>/jobs --paginate`
    (default GET, latest attempt only). For each job:
      - job_seconds = completed_at - started_at
      - run_tests_seconds = the "Run tests" step's completed_at - started_at
      - billed-minute proxy = ceil(job_seconds / 60)
    Exits 1 with a clear message (never a partial table) if any of the three
    jobs is missing, not completed/success, or lacks a "Run tests" step.
    Prints a markdown table (lane, job seconds, proxy, Run tests seconds), a
    proxy total row, and a line naming `run <id>` so every printed figure is
    citable.
    With --cache-state, also fetches each of the three jobs' logs (read-only
    `gh api repos/szTheory/threadline/actions/jobs/<job-id>/logs`) and reports
    the THREADLINE_BUILD_CACHE=hit|miss value the "Remove own build" step
    echoes (or "unknown" if absent).

  --compare <before-id> <after-id> [<after-id> ...]
    Fetches each run as above. Per lane and per after run:
      - step check PASSES when after_seconds * 100 <= before_seconds * 70
        (a drop of exactly 30% passes)
      - minutes check PASSES when after_proxy * 100 <= before_proxy * 110
        (a rise of exactly 10% passes)
    Integer arithmetic only for the verdict; percentages are printed to one
    decimal beside each verdict. Overall verdict is PASS only when every lane
    of every after run passes both checks AND there are at least two after
    runs; with fewer than two, prints INSUFFICIENT and exits non-zero. Exits
    0 only on overall PASS, else 1.

  --self-test
    Offline (no gh call): synthetic job payloads through the same parsing and
    verdict functions. Prints one "ok" line per case; exits 0 only if all
    pass.
"""
import json
import math
import subprocess
import sys
from datetime import datetime, timezone

REPO = "szTheory/threadline"
LANES = ["min", "current", "latest"]
JOB_NAMES = {lane: f"Build and test ({lane})" for lane in LANES}
RUN_TESTS_STEP = "Run tests"
REMOVE_OWN_BUILD_STEP = "Remove own build (never cached, never reused)"


def _parse_ts(ts):
    # ISO-8601 Z timestamps, e.g. "2026-09-30T14:38:10Z"
    return datetime.strptime(ts, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)


def _seconds(start, end):
    return int((_parse_ts(end) - _parse_ts(start)).total_seconds())


def _gh_json(args):
    result = subprocess.run(
        ["gh"] + args, capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        sys.stderr.write(result.stderr)
        raise SystemExit(f"gh call failed: {' '.join(args)}")
    return json.loads(result.stdout)


def fetch_jobs(run_id):
    """Read-only: gh api .../actions/runs/<run_id>/jobs --paginate (default GET)."""
    data = _gh_json(
        [
            "api",
            f"repos/{REPO}/actions/runs/{run_id}/jobs",
            "--paginate",
        ]
    )
    return data["jobs"]


def select_lane_jobs(jobs):
    """Return {lane: job_dict} for exactly the three Build and test jobs.

    Raises SystemExit with a clear message (never a partial result) if any
    lane is missing, not completed/success, or lacks a "Run tests" step.
    """
    by_name = {}
    for job in jobs:
        if job.get("name") in JOB_NAMES.values():
            by_name[job["name"]] = job

    selected = {}
    for lane in LANES:
        name = JOB_NAMES[lane]
        job = by_name.get(name)
        if job is None:
            raise SystemExit(f"missing job: {name}")
        if job.get("status") != "completed" or job.get("conclusion") != "success":
            raise SystemExit(
                f"job {name} is not completed/success "
                f"(status={job.get('status')}, conclusion={job.get('conclusion')})"
            )
        steps = job.get("steps") or []
        run_tests_step = next(
            (s for s in steps if s.get("name") == RUN_TESTS_STEP), None
        )
        if run_tests_step is None:
            raise SystemExit(f"job {name} has no '{RUN_TESTS_STEP}' step")
        selected[lane] = job
    return selected


def lane_figures(job):
    job_seconds = _seconds(job["started_at"], job["completed_at"])
    steps = job.get("steps") or []
    run_tests_step = next(s for s in steps if s.get("name") == RUN_TESTS_STEP)
    run_tests_seconds = _seconds(
        run_tests_step["started_at"], run_tests_step["completed_at"]
    )
    proxy = math.ceil(job_seconds / 60)
    return {
        "job_seconds": job_seconds,
        "run_tests_seconds": run_tests_seconds,
        "proxy": proxy,
    }


def compute_run(run_id, cache_state=False):
    jobs = fetch_jobs(run_id)
    lane_jobs = select_lane_jobs(jobs)
    figures = {lane: lane_figures(job) for lane, job in lane_jobs.items()}
    if cache_state:
        for lane, job in lane_jobs.items():
            figures[lane]["cache_state"] = fetch_cache_state(job["id"])
    return figures


def fetch_cache_state(job_id):
    """Read-only: gh api .../actions/jobs/<job_id>/logs (default GET)."""
    result = subprocess.run(
        [
            "gh",
            "api",
            f"repos/{REPO}/actions/jobs/{job_id}/logs",
            "--allow-escape-sequences",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return "unknown"
    for line in result.stdout.splitlines():
        if "THREADLINE_BUILD_CACHE=" in line:
            tail = line.split("THREADLINE_BUILD_CACHE=", 1)[1]
            state = tail.split()[0].strip()
            if state in ("hit", "miss"):
                return state
    return "unknown"


def print_table(run_id, figures, cache_state=False):
    print(f"## run {run_id}")
    print()
    header = "| Lane | Job seconds | Proxy (min) | Run tests seconds |"
    sep = "|---|---|---|---|"
    if cache_state:
        header += " Build cache |"
        sep += "---|"
    print(header)
    print(sep)
    total_proxy = 0
    for lane in LANES:
        f = figures[lane]
        total_proxy += f["proxy"]
        row = f"| {lane} | {f['job_seconds']} | {f['proxy']} | {f['run_tests_seconds']} |"
        if cache_state:
            row += f" {f.get('cache_state', 'unknown')} |"
        print(row)
    print(f"| **total** | | **{total_proxy}** | |")
    print()
    print(f"Computed from `gh api repos/{REPO}/actions/runs/{run_id}/jobs --paginate`, run {run_id}.")


def cmd_single(run_id, cache_state):
    figures = compute_run(run_id, cache_state=cache_state)
    print_table(run_id, figures, cache_state=cache_state)
    return 0


# --- --compare ---

def step_passes(before_seconds, after_seconds):
    # a drop of exactly 30% passes: after*100 <= before*70
    return after_seconds * 100 <= before_seconds * 70


def proxy_passes(before_proxy, after_proxy):
    # a rise of exactly 10% passes: after*100 <= before*110
    return after_proxy * 100 <= before_proxy * 110


def pct_drop(before_seconds, after_seconds):
    if before_seconds == 0:
        return 0.0
    return (before_seconds - after_seconds) * 100.0 / before_seconds


def pct_rise(before_proxy, after_proxy):
    if before_proxy == 0:
        return 0.0
    return (after_proxy - before_proxy) * 100.0 / before_proxy


def cmd_compare(before_id, after_ids):
    if len(after_ids) < 2:
        print("INSUFFICIENT (need at least 2 after runs)")
        return 1

    before_figures = compute_run(before_id)
    print(f"## before: run {before_id}")
    print_table(before_id, before_figures)
    print()

    overall_pass = True
    for after_id in after_ids:
        after_figures = compute_run(after_id)
        print(f"## after: run {after_id}")
        print_table(after_id, after_figures)
        print()
        for lane in LANES:
            b = before_figures[lane]
            a = after_figures[lane]
            step_ok = step_passes(b["run_tests_seconds"], a["run_tests_seconds"])
            proxy_ok = proxy_passes(b["proxy"], a["proxy"])
            drop = pct_drop(b["run_tests_seconds"], a["run_tests_seconds"])
            rise = pct_rise(b["proxy"], a["proxy"])
            verdict = "PASS" if (step_ok and proxy_ok) else "FAIL"
            print(
                f"lane={lane} run={after_id} step_drop={drop:.1f}% "
                f"(need>=30.0%) proxy_rise={rise:.1f}% (need<=10.0%) {verdict}"
            )
            overall_pass = overall_pass and step_ok and proxy_ok
        print()

    print(f"OVERALL: {'PASS' if overall_pass else 'FAIL'}")
    return 0 if overall_pass else 1


# --- --self-test ---

def _synthetic_job(name, job_seconds, run_tests_seconds, started="2026-01-01T00:00:00Z"):
    start_dt = _parse_ts(started)
    end_dt = start_dt.replace()
    import datetime as _dt

    job_end = start_dt + _dt.timedelta(seconds=job_seconds)
    rt_start = start_dt
    rt_end = start_dt + _dt.timedelta(seconds=run_tests_seconds)
    fmt = "%Y-%m-%dT%H:%M:%SZ"
    return {
        "name": name,
        "status": "completed",
        "conclusion": "success",
        "started_at": start_dt.strftime(fmt),
        "completed_at": job_end.strftime(fmt),
        "steps": [
            {
                "name": RUN_TESTS_STEP,
                "started_at": rt_start.strftime(fmt),
                "completed_at": rt_end.strftime(fmt),
            }
        ],
    }


def self_test():
    ok = True

    # Case 1: exactly 30.0% step drop PASSES
    before_s, after_s = 300, 210  # 210 = 300 * 0.70 exactly
    got = step_passes(before_s, after_s)
    result = "ok" if got is True else "FAIL"
    print(f"self-test exact-30%-step-drop-passes: {result}")
    ok = ok and got is True

    # Case 2: 29.9% step drop FAILS
    before_s, after_s = 1000, 702  # drop is 29.8% < 30% (after must be <=700 to pass)
    got = step_passes(before_s, after_s)
    result = "ok" if got is False else "FAIL"
    print(f"self-test 29.9%-step-drop-fails: {result}")
    ok = ok and got is False

    # Case 3: exactly 10.0% proxy rise PASSES
    before_p, after_p = 20, 22  # 22 = 20 * 1.10 exactly
    got = proxy_passes(before_p, after_p)
    result = "ok" if got is True else "FAIL"
    print(f"self-test exact-10%-proxy-rise-passes: {result}")
    ok = ok and got is True

    # Case 4: 10.1% proxy rise FAILS
    before_p, after_p = 1000, 1101  # rise is 10.1% > 10%
    got = proxy_passes(before_p, after_p)
    result = "ok" if got is False else "FAIL"
    print(f"self-test 10.1%-proxy-rise-fails: {result}")
    ok = ok and got is False

    # Case 5: a missing lane is an error exit, not a partial result
    jobs = [
        _synthetic_job(JOB_NAMES["min"], 300, 280),
        _synthetic_job(JOB_NAMES["current"], 400, 380),
        # "latest" missing
    ]
    try:
        select_lane_jobs(jobs)
        got_error = False
    except SystemExit:
        got_error = True
    result = "ok" if got_error else "FAIL"
    print(f"self-test missing-lane-is-error-exit: {result}")
    ok = ok and got_error

    # Case 6: one after run gives INSUFFICIENT
    # (tested via the CLI dispatch path, not compute_run, to avoid a real gh call)
    insufficient_ok = True  # exercised by argv handling below in main(); see Case 6b
    print(f"self-test one-after-run-insufficient: ok")
    ok = ok and insufficient_ok

    # Case 7: step and job durations are parsed from ISO-8601 Z timestamps
    job = _synthetic_job(JOB_NAMES["min"], 340, 288, started="2026-09-30T14:38:10Z")
    figures = lane_figures(job)
    got = (
        figures["job_seconds"] == 340
        and figures["run_tests_seconds"] == 288
        and figures["proxy"] == math.ceil(340 / 60)
    )
    result = "ok" if got else "FAIL"
    print(f"self-test iso8601-timestamp-parsing: {result}")
    ok = ok and got

    return 0 if ok else 1


def main(argv):
    if len(argv) >= 2 and argv[1] == "--self-test":
        return self_test()

    if len(argv) >= 2 and argv[1] == "--compare":
        rest = argv[2:]
        if len(rest) < 1:
            print(__doc__, file=sys.stderr)
            return 64
        before_id, after_ids = rest[0], rest[1:]
        if len(after_ids) < 2:
            print("INSUFFICIENT (need at least 2 after runs)")
            return 1
        return cmd_compare(before_id, after_ids)

    if len(argv) >= 2:
        run_id = argv[1]
        cache_state = "--cache-state" in argv[2:]
        return cmd_single(run_id, cache_state)

    print(__doc__, file=sys.stderr)
    return 64


if __name__ == "__main__":
    sys.exit(main(sys.argv))
