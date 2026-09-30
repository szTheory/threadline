#!/usr/bin/env python3
"""check-baseline-complete.py - the Phase 214 baseline doc holds all eight BASE-01 elements.

Usage (from the repo root):
  python3 .planning/phases/214-baseline-measurement/tools/check-baseline-complete.py <file.md>
  python3 .planning/phases/214-baseline-measurement/tools/check-baseline-complete.py --self-test

Checks (each miss prints "INCOMPLETE: <what>"; any miss exits 1, else 0):
  1. A heading (case-insensitive substring) exists for each of the eight BASE-01 elements:
     per-job duration, runner-minutes, critical path, Flake Detection, Browser-full,
     slowest 25, live_dialyzer, inert-path share.
  2. The section under the runner-minutes heading names all three units:
     per PR, push-to-main, release cycle.
  3. Every per-job row (a table row containing "| pull_request |" or "| push |" and "n=")
     has n >= 10. A row whose n cannot be parsed counts as a miss.
  4. Every job id declared under `jobs:` in .github/workflows/ci.yml, except ci-required,
     has at least one pull_request row and one push row whose first cell is that job id.

--self-test asserts exit 1 on tools/fixtures/incomplete.md and exit 0 on 214-BASELINE.md.
Standard library only.
"""
import os
import re
import subprocess
import sys

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
PHASE_DIR = os.path.dirname(TOOLS_DIR)
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(PHASE_DIR)))
CI_YML = os.path.join(ROOT, ".github", "workflows", "ci.yml")
MIN_N = 10

ELEMENTS = [
    "per-job duration",
    "runner-minutes",
    "critical path",
    "flake detection",
    "browser-full",
    "slowest 25",
    "live_dialyzer",
    "inert-path share",
]
RUNNER_UNITS = ["per pr", "push-to-main", "release cycle"]
HEADING = re.compile(r"^(#{1,6})\s+(.*)$")
N_VALUE = re.compile(r"\bn=(\d+)\b")


def ci_job_ids(path):
    ids = []
    in_jobs = False
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if re.match(r"^jobs:\s*$", line):
                in_jobs = True
                continue
            if in_jobs and re.match(r"^\S", line):
                break
            m = re.match(r"^  ([A-Za-z0-9_-]+):\s*$", line)
            if in_jobs and m:
                ids.append(m.group(1))
    return [i for i in ids if i != "ci-required"]


def headings(lines):
    out = []
    for idx, line in enumerate(lines):
        m = HEADING.match(line)
        if m:
            out.append((idx, len(m.group(1)), m.group(2)))
    return out


def section_text(lines, heads, needle):
    for pos, (idx, level, text) in enumerate(heads):
        if needle in text.lower():
            end = len(lines)
            for idx2, level2, _ in heads[pos + 1:]:
                if level2 <= level:
                    end = idx2
                    break
            return "\n".join(lines[idx:end])
    return None


def check(path):
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    heads = headings(lines)
    misses = []

    for element in ELEMENTS:
        if not any(element in text.lower() for _, _, text in heads):
            misses.append(f"no heading for BASE-01 element '{element}'")

    runner = section_text(lines, heads, "runner-minutes")
    if runner is not None:
        low = runner.lower()
        for unit in RUNNER_UNITS:
            if unit not in low:
                misses.append(f"runner-minutes section does not name the unit '{unit}'")

    seen = {}
    for lineno, line in enumerate(lines, 1):
        if not line.startswith("|"):
            continue
        event = "pull_request" if "| pull_request |" in line else ("push" if "| push |" in line else None)
        if event is None or "n=" not in line:
            continue
        m = N_VALUE.search(line)
        if not m:
            misses.append(f"line {lineno}: {event} row has no parseable n")
            continue
        n = int(m.group(1))
        if n < MIN_N:
            misses.append(f"line {lineno}: {event} row has n={n} (< {MIN_N})")
        first_cell = line.strip().strip("|").split("|")[0].strip()
        seen.setdefault(first_cell, set()).add(event)

    try:
        job_ids = ci_job_ids(CI_YML)
    except OSError as err:
        misses.append(f"cannot read ci.yml job ids: {err}")
        job_ids = []
    if not job_ids and os.path.exists(CI_YML):
        misses.append("no job ids parsed from ci.yml")
    for job in job_ids:
        for event in ("pull_request", "push"):
            if event not in seen.get(job, set()):
                misses.append(f"ci.yml job '{job}' has no {event} row")

    for miss in misses:
        print(f"INCOMPLETE: {miss}")
    return 1 if misses else 0


def self_test():
    ok = True
    cases = (
        (os.path.join(TOOLS_DIR, "fixtures", "incomplete.md"), 1),
        (os.path.join(PHASE_DIR, "214-BASELINE.md"), 0),
    )
    for path, want in cases:
        proc = subprocess.run([sys.executable, os.path.abspath(__file__), path],
                              capture_output=True, text=True)
        got = proc.returncode
        n_lines = sum(1 for ln in proc.stdout.splitlines() if ln.startswith("INCOMPLETE:"))
        status = "ok" if got == want else "FAIL"
        print(f"self-test {os.path.basename(path)}: exit {got} (want {want}), {n_lines} INCOMPLETE lines {status}")
        ok = ok and got == want
    return 0 if ok else 1


def main(argv):
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 64
    if argv[1] == "--self-test":
        return self_test()
    return check(argv[1])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
