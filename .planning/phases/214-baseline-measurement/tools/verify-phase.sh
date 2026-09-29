#!/usr/bin/env bash
# verify-phase.sh — the single Phase 214 gate (BASE-01, BASE-02).
#
# Runs every phase check in order, prints one PASS/FAIL line per check, and exits non-zero
# on the first failure. No flags. Read-only: no network, no git writes, no file writes
# outside a mktemp scratch file that is removed on exit.
#
# Usage (from anywhere inside the repo):
#   bash .planning/phases/214-baseline-measurement/tools/verify-phase.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT"

P=.planning/phases/214-baseline-measurement
T="$P/tools"
DOC="$P/214-BASELINE.md"
OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT

pass() { echo "PASS: $1"; }
fail() {
  echo "FAIL: $1"
  sed 's/^/  | /' "$OUT"
  exit 1
}

# run <label> <command...> — the command must exit 0.
run() {
  local label="$1"; shift
  if "$@" >"$OUT" 2>&1; then pass "$label"; else fail "$label"; fi
}

# run_fails_with <label> <reason> <command...> — negative self-test: the command must exit
# non-zero AND its output must contain <reason> (fixed string), so it fails for the named cause.
run_fails_with() {
  local label="$1" reason="$2"; shift 2
  if "$@" >"$OUT" 2>&1; then
    fail "$label (expected a non-zero exit)"
  elif ! grep -qF -- "$reason" "$OUT"; then
    fail "$label (expected reason: $reason)"
  else
    pass "$label"
  fi
}

run "check-citations.py --self-test (cited fixture passes, uncited fixture fails)" \
  python3 "$T/check-citations.py" --self-test
run "check-citations.py on 214-BASELINE.md (every figure cited)" \
  python3 "$T/check-citations.py" "$DOC"
run "check-baseline-complete.py --self-test (incomplete fixture fails, real doc passes)" \
  python3 "$T/check-baseline-complete.py" --self-test
run "check-baseline-complete.py on 214-BASELINE.md (eight BASE-01 elements, n >= 10)" \
  python3 "$T/check-baseline-complete.py" "$DOC"
run "check-project-baseline.sh on PROJECT.md (BASE-02 facts, Out of Scope byte-identical)" \
  bash "$T/check-project-baseline.sh"
run_fails_with "check-project-baseline.sh on fixtures/project-bad-streak.md must fail" \
  "MISSING: flake_fast_fail_first" \
  bash "$T/check-project-baseline.sh" "$T/fixtures/project-bad-streak.md"
run_fails_with "check-project-baseline.sh on fixtures/project-stale-wall.md must fail (gap G2 wall-time drift)" \
  "MISSING: stale_wall_wording:" \
  bash "$T/check-project-baseline.sh" "$T/fixtures/project-stale-wall.md"
run "inert-share.py --self-test (fail-closed classification, n=0 line)" \
  python3 "$T/inert-share.py" --self-test
run "summarize-ci.py jobs --min 10, pull_request" \
  python3 "$T/summarize-ci.py" jobs --workflow ci.yml --event pull_request --min 10 --format md
run "summarize-ci.py jobs --min 10, push" \
  python3 "$T/summarize-ci.py" jobs --workflow ci.yml --event push --min 10 --format md

# Read-only GitHub: no tool may use a write-capable gh command or an HTTP method override.
# This file is excluded because the next line is the pattern itself.
GH_WRITE='gh (workflow run|run rerun|run cancel|pr create|pr comment|pr merge|issue)|--method|-X (POST|PUT|PATCH|DELETE)'
if grep -nE "$GH_WRITE" $(ls "$T"/*.sh "$T"/*.py | grep -v '/verify-phase\.sh$') >"$OUT" 2>&1; then
  fail "no write-capable gh usage in tools/*.sh and tools/*.py"
else
  pass "no write-capable gh usage in tools/*.sh and tools/*.py"
fi

# No machine-local path in the doc, raw data or fixtures.
# Excluded: tools/measure-base02.sh and raw/base02/facts.json legitimately hold the path-search
# regexes that BASE-02 counts with (tools/ other than fixtures is not scanned at all).
MACHINE_PATH='/Users/[A-Za-z0-9_]|/home/[a-z]|~/[A-Za-z0-9_.]'
HITS="$(mktemp)"
trap 'rm -f "$OUT" "$HITS"' EXIT
set +e
grep -rnE "$MACHINE_PATH" "$DOC" "$P/raw" "$T/fixtures" >"$HITS" 2>"$OUT"
GREP_STATUS=$?
set -e
# grep exit 2 (unreadable path) must not read as "no match": fail closed.
[ "$GREP_STATUS" -le 1 ] || fail "machine-path grep could not read its inputs (exit $GREP_STATUS)"
if grep -v "^$P/raw/base02/facts\.json:" "$HITS" >"$OUT"; then
  fail "no machine-local path in 214-BASELINE.md, raw/ and tools/fixtures"
else
  pass "no machine-local path in 214-BASELINE.md, raw/ and tools/fixtures"
fi

echo "verify-phase: all checks passed"
