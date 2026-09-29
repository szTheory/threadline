#!/usr/bin/env bash
# verify-phase.sh — the single Phase 222 gate (SCOPE-01, D-01..D-04).
#
# Default mode is the measurement gate: it proves the 222 copy of inert-share.py
# reproduces Phase 214 on a fresh snapshot, the D-02 minute-gate and D-03 ceiling
# tools are self-tested and deterministic, no tool ever calls a write-capable gh
# command, and no tracked file under this phase dir carries a machine-local path.
# 222-02 adds a --close mode (see the case statement below).
#
# No other flags. Read-only: no network, no git writes, no file writes outside a
# mktemp scratch file removed on exit.
#
# Usage (from anywhere inside the repo):
#   bash .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT"

P=.planning/phases/222-seed-006-change-aware-lanes-conditional
T="$P/tools"
P214=.planning/phases/214-baseline-measurement
T214="$P214/tools"

MODE="${1:-}"
case "$MODE" in
  "" | "--close")
    ;;
  *)
    echo "verify-phase: unknown argument: $MODE" >&2
    echo "usage: verify-phase.sh (default measurement gate; 222-02 adds --close)" >&2
    exit 64
    ;;
esac

OUT="$(mktemp)"
HITS="$(mktemp)"
trap 'rm -f "$OUT" "$HITS"' EXIT

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

# run_out_contains <label> <needle> <command...> — the command must exit 0 AND its
# output must contain <needle> (fixed string).
run_out_contains() {
  local label="$1" needle="$2"; shift 2
  if ! "$@" >"$OUT" 2>&1; then
    fail "$label (command exited non-zero)"
  elif ! grep -qF -- "$needle" "$OUT"; then
    fail "$label (expected to find: $needle)"
  else
    pass "$label"
  fi
}

# 1. inert-share.py --self-test
run "inert-share.py --self-test" python3 "$T/inert-share.py" --self-test

# 2. allowlist byte-identical to 214's
if cmp -s "$T214/inert-allowlist.txt" "$T/inert-allowlist.txt"; then
  pass "inert-allowlist.txt byte-identical to Phase 214's (not widened)"
else
  { echo "diff:"; diff "$T214/inert-allowlist.txt" "$T/inert-allowlist.txt" || true; } >"$OUT"
  fail "inert-allowlist.txt byte-identical to Phase 214's (not widened)"
fi

# 3. at-214 reproduces 214 exactly
AT214_OUT="$(python3 "$T/inert-share.py" --window at-214)"
if echo "$AT214_OUT" | grep -qx "1 of 40 merged PRs touch only inert paths" \
   && echo "$AT214_OUT" | grep -qx "inert PRs: #8"; then
  pass "at-214 reproduces 214: 1 of 40 merged PRs, inert PRs: #8"
else
  printf '%s\n' "$AT214_OUT" >"$OUT"
  fail "at-214 reproduces 214: 1 of 40 merged PRs, inert PRs: #8"
fi

# 4. 30d reproduces 214's 0 of 20
D30_OUT="$(python3 "$T/inert-share.py" --window 30d)"
if echo "$D30_OUT" | grep -qx "0 of 20 merged PRs touch only inert paths"; then
  pass "30d reproduces 214: 0 of 20 merged PRs"
else
  printf '%s\n' "$D30_OUT" >"$OUT"
  fail "30d reproduces 214: 0 of 20 merged PRs"
fi

# 5. the 40 file lists named in 214's index.json are byte-identical between 214's and 222's raw/prs
DIFF_NUMS="$(for n in $(jq -r '.[].number' "$P214/raw/prs/index.json"); do
  cmp -s "$P214/raw/prs/$n.files.txt" "$P/raw/prs/$n.files.txt" || echo "$n"
done)"
if [ -z "$DIFF_NUMS" ]; then
  pass "214's 40 PR file lists are byte-identical in 222's fresh snapshot"
else
  printf 'differing PR numbers: %s\n' "$DIFF_NUMS" >"$OUT"
  fail "214's 40 PR file lists are byte-identical in 222's fresh snapshot"
fi

# 6. adjacency: n(at-214) + n(since-214) = n(all)
n_of() { echo "$1" | sed -n '2p' | grep -oE '[0-9]+ of [0-9]+' | awk '{print $3}'; }
N_AT214="$(n_of "$AT214_OUT")"
N_SINCE214="$(n_of "$(python3 "$T/inert-share.py" --window since-214)")"
N_ALL="$(n_of "$(python3 "$T/inert-share.py" --window all)")"
if [ "$((N_AT214 + N_SINCE214))" -eq "$N_ALL" ]; then
  pass "adjacency: n(at-214)=$N_AT214 + n(since-214)=$N_SINCE214 = n(all)=$N_ALL"
else
  printf 'at-214=%s since-214=%s all=%s\n' "$N_AT214" "$N_SINCE214" "$N_ALL" >"$OUT"
  fail "adjacency: n(at-214) + n(since-214) = n(all)"
fi

# 7. determinism: two runs each of every window, --last 20, minute-gate and ceiling
DET_OK=1
DET_MSG=""
for w in all 30d at-214 since-214 30d-now; do
  a="$(python3 "$T/inert-share.py" --window "$w")"
  b="$(python3 "$T/inert-share.py" --window "$w")"
  if [ "$a" != "$b" ]; then DET_OK=0; DET_MSG="window $w not byte-identical across two runs"; fi
done
a="$(python3 "$T/inert-share.py" --last 20)"
b="$(python3 "$T/inert-share.py" --last 20)"
if [ "$a" != "$b" ]; then DET_OK=0; DET_MSG="--last 20 not byte-identical across two runs"; fi
a="$(python3 "$T/remeasure-222.py" minute-gate --window 30d-now)"
b="$(python3 "$T/remeasure-222.py" minute-gate --window 30d-now)"
if [ "$a" != "$b" ]; then DET_OK=0; DET_MSG="minute-gate --window 30d-now not byte-identical across two runs"; fi
a="$(python3 "$T/remeasure-222.py" ceiling --window 30d-now)"
b="$(python3 "$T/remeasure-222.py" ceiling --window 30d-now)"
if [ "$a" != "$b" ]; then DET_OK=0; DET_MSG="ceiling --window 30d-now not byte-identical across two runs"; fi
if [ "$DET_OK" -eq 1 ]; then
  pass "determinism: windows, --last 20, minute-gate and ceiling byte-identical across two runs"
else
  printf '%s\n' "$DET_MSG" >"$OUT"
  fail "determinism: windows, --last 20, minute-gate and ceiling byte-identical across two runs"
fi

# 8. check-citations.py --self-test
run "check-citations.py --self-test" python3 "$T/check-citations.py" --self-test

# 9. remeasure-222.py --self-test; skip-saving; minute-gate exactly one verdict line
run "remeasure-222.py --self-test" python3 "$T/remeasure-222.py" --self-test
run_out_contains "remeasure-222.py skip-saving reports 19 billed min" \
  "skip saving per PR run: 19 billed min" \
  python3 "$T/remeasure-222.py" skip-saving
MG_OUT="$(python3 "$T/remeasure-222.py" minute-gate --window 30d-now)"
VERDICT_COUNT="$(printf '%s\n' "$MG_OUT" | grep -cE '^verdict: (CLOSE|BUILD|NOT MEASURED)$' || true)"
if [ "$VERDICT_COUNT" -eq 1 ]; then
  pass "remeasure-222.py minute-gate --window 30d-now prints exactly one verdict line"
else
  printf '%s\n' "$MG_OUT" >"$OUT"
  fail "remeasure-222.py minute-gate --window 30d-now prints exactly one verdict line"
fi

# 10. Read-only GitHub: no tool may use a write-capable gh command or an HTTP method override.
# This file is excluded because the next line is the pattern itself.
GH_WRITE='gh (workflow run|run rerun|run cancel|pr create|pr comment|pr merge|issue)|--method|-X (POST|PUT|PATCH|DELETE)'
if grep -nE "$GH_WRITE" $(ls "$T"/*.sh "$T"/*.py | grep -v '/verify-phase\.sh$') >"$OUT" 2>&1; then
  fail "no write-capable gh usage in tools/*.sh and tools/*.py"
else
  pass "no write-capable gh usage in tools/*.sh and tools/*.py"
fi

# 11. No machine-local path in raw/, tools/fixtures, COVERAGE.md (and 222-DECISION.md once it exists).
MACHINE_PATH='/Users/[A-Za-z0-9_]|/home/[a-z]|~/[A-Za-z0-9_.]'
SCAN_TARGETS=("$P/raw" "$T/fixtures")
[ -f "$P/COVERAGE.md" ] && SCAN_TARGETS+=("$P/COVERAGE.md")
[ -f "$P/222-DECISION.md" ] && SCAN_TARGETS+=("$P/222-DECISION.md")
set +e
grep -rnE "$MACHINE_PATH" "${SCAN_TARGETS[@]}" >"$HITS" 2>"$OUT"
GREP_STATUS=$?
set -e
# grep exit 2 (unreadable path) must not read as "no match": fail closed.
[ "$GREP_STATUS" -le 1 ] || fail "machine-path grep could not read its inputs (exit $GREP_STATUS)"
if [ -s "$HITS" ]; then
  cp "$HITS" "$OUT"
  fail "no machine-local path in raw/, tools/fixtures, COVERAGE.md and 222-DECISION.md"
else
  pass "no machine-local path in raw/, tools/fixtures, COVERAGE.md and 222-DECISION.md"
fi

if [ "$MODE" = "--close" ]; then
  BASE=ea5b96dc
  SEED=.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md
  DECISION="$P/222-DECISION.md"
  REQ=.planning/REQUIREMENTS.md
  CTX220=.planning/phases/220-newest-toolchain-lane/220-CONTEXT.md

  # 12. check-citations.py on the decision record
  run "check-citations.py on 222-DECISION.md" python3 "$T/check-citations.py" "$DECISION"

  # 13. the decision's standalone verdict line equals remeasure-222.py's verdict
  DOC_VERDICT="$(grep -x '^\(CLOSE\|BUILD\|NOT MEASURED\)$' "$DECISION" | head -1)"
  TOOL_VERDICT="$(python3 "$T/remeasure-222.py" minute-gate --window 30d-now | sed -n 's/^verdict: //p')"
  if [ -n "$DOC_VERDICT" ] && [ "$DOC_VERDICT" = "$TOOL_VERDICT" ]; then
    pass "222-DECISION.md verdict ($DOC_VERDICT) equals minute-gate --window 30d-now verdict ($TOOL_VERDICT)"
  else
    printf 'doc verdict: %s\ntool verdict: %s\n' "$DOC_VERDICT" "$TOOL_VERDICT" >"$OUT"
    fail "222-DECISION.md verdict equals minute-gate --window 30d-now verdict"
  fi

  # 14. the honesty note is present
  if grep -qi "chosen after" "$DECISION"; then
    pass "222-DECISION.md carries the honesty note (chosen after)"
  else
    fail "222-DECISION.md carries the honesty note (chosen after)"
  fi

  # 15. SEED-006 closure frontmatter
  if grep -qx "status: closed" "$SEED" \
     && grep -qF "decision: $P/222-DECISION.md" "$SEED" \
     && grep -q "^reopen_when:" "$SEED" \
     && [ "$(grep -c '^trigger_when:' "$SEED")" -eq 0 ]; then
    pass "SEED-006 has status: closed, a decision: pointer, reopen_when: and no top-level trigger_when:"
  else
    { echo "status:"; grep '^status:' "$SEED" || true
      echo "decision:"; grep '^decision:' "$SEED" || true
      echo "reopen_when:"; grep -c '^reopen_when:' "$SEED" || true
      echo "trigger_when count:"; grep -c '^trigger_when:' "$SEED" || true
    } >"$OUT"
    fail "SEED-006 has status: closed, a decision: pointer, reopen_when: and no top-level trigger_when:"
  fi

  # 16. REQUIREMENTS.md closure edits
  if grep -q '^- \[x\] \*\*SCOPE-01\*\*' "$REQ" \
     && grep -q '^  Outcome: closed, measured, not worth it (222-DECISION.md:' "$REQ" \
     && grep -qF 'SCOPE-01 | Phase 222 | Complete' "$REQ"; then
    pass "REQUIREMENTS.md has SCOPE-01 [x], its Outcome line and the Complete traceability row"
  else
    fail "REQUIREMENTS.md has SCOPE-01 [x], its Outcome line and the Complete traceability row"
  fi

  # 17. 220-CONTEXT.md pointer line appears exactly once
  POINTER_COUNT="$(grep -cF 'Superseded by 222 D-05: kept every-run; see 222-DECISION.md.' "$CTX220" || true)"
  if [ "$POINTER_COUNT" -eq 1 ]; then
    pass "220-CONTEXT.md contains the D-05 pointer line exactly once"
  else
    printf 'pointer count: %s\n' "$POINTER_COUNT" >"$OUT"
    fail "220-CONTEXT.md contains the D-05 pointer line exactly once"
  fi

  # 18. no protected path changed since the base commit
  PROTECTED_DIFF="$(git diff --name-only "$BASE..HEAD" -- .github bin test CONTRIBUTING.md \
    .planning/phases/214-baseline-measurement \
    .planning/phases/218-ci-economy-remove-waste \
    .planning/phases/219-deps-only-build-cache \
    .planning/phases/221-ci-names-and-order || true)"
  if [ -z "$PROTECTED_DIFF" ]; then
    pass "no protected path changed since $BASE"
  else
    printf '%s\n' "$PROTECTED_DIFF" >"$OUT"
    fail "no protected path changed since $BASE"
  fi

  # 19. machine-path grep also covers 222-DECISION.md (re-run explicitly for --close)
  set +e
  grep -nE "$MACHINE_PATH" "$DECISION" >"$HITS" 2>"$OUT"
  GREP_STATUS=$?
  set -e
  [ "$GREP_STATUS" -le 1 ] || fail "machine-path grep on 222-DECISION.md could not read its input (exit $GREP_STATUS)"
  if [ -s "$HITS" ]; then
    cp "$HITS" "$OUT"
    fail "no machine-local path in 222-DECISION.md"
  else
    pass "no machine-local path in 222-DECISION.md"
  fi
fi

echo "verify-phase: all checks passed"
