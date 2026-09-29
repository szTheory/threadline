#!/usr/bin/env python3
"""check-citations.py - every figure in a baseline doc must cite a run or a command.

Usage (from the repo root):
  python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/check-citations.py <file.md>
  python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/check-citations.py --self-test

Rule, for each line outside fenced code blocks that is not a heading and not blank:
  1. Remove exempt tokens: ISO dates (YYYY-MM-DD and MM-DD), the tokens p50/p95,
     requirement IDs ([A-Z]+-NN), phase/plan numbers only when plan-suffixed (2NN-0N),
     preceded by the word "phase" (phase 214), or immediately followed by a
     requirement/decision ID (220 D-07) — a bare phase number used as a real
     measurement (e.g. "220 billed min") is never exempted — 7-40 char hex SHAs,
     and version strings (0.11.0, v0.11.0, 1.43).
  2. If any digit remains, the line must contain either "run " followed by an
     8+ digit run ID, or a backticked span starting with one of:
     gh, mix, MIX_ENV=, git, python3, bash, jq, psql, elixir.
Lines carrying [inference] follow the same rule (they must cite their inputs).
Exit 1 if any line is uncited, else 0. Standard library only.
"""
import os
import re
import subprocess
import sys

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
FIXTURES = os.path.join(TOOLS_DIR, "fixtures")

EXEMPT = [
    re.compile(r"\b\d{4}-\d{2}-\d{2}\b"),            # ISO date
    re.compile(r"\b\d{2}-\d{2}\b"),                  # MM-DD
    re.compile(r"\bp(?:50|95)\b"),                   # percentile tokens
    re.compile(r"\bphase\s+(?:21[4-9]|22[0-2])\b", re.IGNORECASE),  # "phase NNN" wording (214-222)
    re.compile(r"\b(?:21[4-9]|22[0-2])(?=\s+[A-Z]+-\d\d\b)"),  # phase number immediately
                                                       # before a requirement/decision ID, e.g. "220 D-07"
    re.compile(r"\b[A-Z]+-\d\d\b"),                  # requirement IDs
    re.compile(r"\b(?:21[4-9]|22[0-2])-0\d\b"),      # phase/plan numbers with a plan suffix (222-01)
    re.compile(r"\b(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}\b"),  # hex SHAs (need a hex letter)
    re.compile(r"\bv?\d+\.\d+\.\d+\b"),              # x.y.z versions
    re.compile(r"\bv?1\.\d{2}\b"),                   # milestone versions like 1.43
]
RUN_CITE = re.compile(r"\brun \d{8,}")
CMD_CITE = re.compile(r"`(?:gh|mix|MIX_ENV=|git|python3|bash|jq|psql|elixir)\b[^`]*`")


def uncited_lines(path):
    problems = []
    in_fence = False
    with open(path, encoding="utf-8") as fh:
        for lineno, raw in enumerate(fh, 1):
            line = raw.rstrip("\n")
            stripped = line.strip()
            if stripped.startswith("```") or stripped.startswith("~~~"):
                in_fence = not in_fence
                continue
            if in_fence or not stripped or stripped.startswith("#"):
                continue
            rest = line
            for pattern in EXEMPT:
                rest = pattern.sub(" ", rest)
            if not re.search(r"\d", rest):
                continue
            if RUN_CITE.search(line) or CMD_CITE.search(line):
                continue
            problems.append((lineno, stripped))
    return problems


def check(path):
    problems = uncited_lines(path)
    for lineno, text in problems:
        print(f"{path}:{lineno}: uncited figure: {text}")
    return 1 if problems else 0


def self_test():
    ok = True
    for name, want in (("cited.md", 0), ("uncited.md", 1)):
        path = os.path.join(FIXTURES, name)
        got = subprocess.run([sys.executable, os.path.abspath(__file__), path],
                             capture_output=True, text=True).returncode
        status = "ok" if got == want else "FAIL"
        print(f"self-test {name}: exit {got} (want {want}) {status}")
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
