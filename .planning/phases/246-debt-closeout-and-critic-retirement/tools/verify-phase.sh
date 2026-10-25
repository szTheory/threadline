#!/usr/bin/env bash
# verify-phase.sh — the single Phase 246 close check (DEBT-01, DEBT-02; D-09, D-15,
# D-20, D-21, D-22).
#
# Modes:
#   (none)       hygiene greps (username, machine-path) + partition-row existence
#   --close      the above + register, WINDOWS, D-09 live-reference and SEED checks
#   --self-test  the default checks + mutation controls over synthetic fixtures
#                (never reads the live register)
#
# Every failing check prints a line starting "FAIL: " followed by its evidence;
# every passing check prints a line starting "ok: ". Failures accumulate: one run
# reports all open work, then exits 1. Check names carry stable tokens: D-09,
# partition, WINDOWS, register, SEED, machine-path.
#
# Input paths are overridable by environment: REGISTER, WINDOWS_FILE, SEED_DIR,
# CONTRIBUTING_FILE, PARTITION_FILE.
#
# Read-only: no network, no git writes, no gsd-tools write verbs, no file writes
# outside mktemp scratch removed on exit. Re-running yields the same verdict.
#
# Usage (from anywhere inside the repo):
#   bash .planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh [--close|--self-test]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT"
P="$(cd "$SCRIPT_DIR/.." && pwd)"   # survives archival to .planning/milestones/
P="${P#"$ROOT"/}"                    # repo-relative for messages
T="$P/tools"
PY=(python3 -I "$ROOT/$T/register-check.py")

MODE="${1:-}"
case "$MODE" in
  "" | "--close" | "--self-test")
    ;;
  *)
    echo "verify-phase: unknown argument: $MODE" >&2
    echo "usage: verify-phase.sh [--close|--self-test]" >&2
    exit 64
    ;;
esac

REGISTER="${REGISTER:-$P/246-DEBT-REGISTER.md}"
WINDOWS_FILE="${WINDOWS_FILE:-.planning/WINDOWS.md}"
SEED_DIR="${SEED_DIR:-.planning/seeds}"
CONTRIBUTING_FILE="${CONTRIBUTING_FILE:-CONTRIBUTING.md}"
PARTITION_FILE="${PARTITION_FILE:-test/partition_weights.txt}"

OUT="$(mktemp)"
HITS="$(mktemp)"
ST=""
trap 'rm -f "$OUT" "$HITS"; [ -z "$ST" ] || rm -rf "$ST"' EXIT

FAILED=0
ok() { echo "ok: $1"; }
bad() {
  echo "FAIL: $1"
  [ -s "$OUT" ] && sed 's/^/  | /' "$OUT"
  FAILED=1
}
# check <label> <command...> — the command must exit 0; its output is the evidence.
check() {
  local label="$1"; shift
  : >"$OUT"
  if "$@" >"$OUT" 2>&1; then ok "$label"; else bad "$label"; fi
}

# ---------------------------------------------------------------------------
# Literal expectations (D-20 / D-00a..c / D-18 / D-19). Plan 246-06 writes the
# register from the identical id list.
# ---------------------------------------------------------------------------

# The 60 WINDOWS ids open at plan time (D-20 / D-00d).
W_EXPECTED="1 3-57 61-64"

# Minimum non-W register ids; rows may add ids, never drop these.
REQUIRED_IDS=(
  223-WR-01 223-WR-02 223-WR-03 223-WR-04 223-WR-05 223-IN-01
  215-WR-01 215-WR-03 215-WR-04 215-WR-05 215-WR-06 215-WR-07 215-WR-08 215-WR-09 215-WR-10
  215-IN-01 215-IN-02 215-IN-03 215-IN-04 215-IN-05 215-IN-06 T-215-36
  216-CR-01 216-WR-01 216-WR-02 216-IN-01 216-IN-02 216-IN-03 216-IN-04 216-IN-05
  216-SHA-PINNING 216-SETUP-NODE
  218-DIALYZER-SLICE-LINE 218-BROWSER-FULL-TIER-A 218-WR-03
  221-BASH-ENV ECON-03 202-CRITIC-TRUST-FLAKE
  231-WR-01 233-WR-01 234-WR-01 231-IN-01 233-IN-01 234-WR-02
  INCIDENT-REPLAY-SESSION GEN-TRIGGERS-DOWN GEN-BACKFILL-INVALID-CONFIG
  PARTITION-WEIGHTS BENCH-COMPILE CLEAN-CHECKOUT-TMP VERIFY-TEMP-LEAKS
  V142-GUIDE-IN-01 V142-GUIDE-IN-02 SEED-005 DR-243-01 UI-TYPOGRAPHY UI-REDACTION-COPY
)
# The 217 R1/R2 items (D-19): at least this many ids starting "217-".
PREFIX_MIN="217-:11"

# D-09 allowlist: `path` (whole file) or `path:ERE` (lines of path matching ERE).
# The CONTRIBUTING Retired pointer is exempted by section (RETIRED_HEADING), not here.
D09_ALLOW=(
  ".gitignore"
  "bin/verify-clean-checkout"
  "test/threadline/clean_checkout_contract_test.exs"
  'test/threadline/release_artifact_contract_test.exs:ADOPT\|COMP\|CRITIC'
  'test/threadline/upgrading_to_0_11_doc_contract_test.exs:ADOPT\|COMP\|CRITIC'
  "test/threadline/ci_topology_contract_test.exs:ui-critic-loop"
  "test/threadline/ui_critic_retirement_doc_contract_test.exs"
)
RETIRED_HEADING="## Retired: UI critic loop"
D09_PATTERN='critic([^a]|$)|tier[-_]a|mechanical_checker|verify\.(capture|mechanical|critic_trust|ui_critique)'

# ---------------------------------------------------------------------------
# Check functions. Each returns 0 on pass, non-zero on fail, and prints evidence.
# ---------------------------------------------------------------------------

# Username hygiene: the pattern is built at runtime, never written as a literal.
chk_username() {
  local user status
  user="$(id -un)"
  [ -n "$user" ] || { echo "id -un returned nothing"; return 1; }
  set +e
  grep -rnF -- "$user" "$@"
  status=$?
  set -e
  case "$status" in
    0) return 1 ;;
    1) return 0 ;;
    *) echo "username grep could not read its inputs (exit $status)"; return 1 ;;
  esac
}

# Machine-path hygiene (regex copied from the Phase 222 verify-phase.sh).
MACHINE_PATH='/Users/[A-Za-z0-9_]|/home/[a-z]|~/[A-Za-z0-9_.]'
chk_machine_path() {
  local status
  set +e
  grep -rnE --exclude=verify-phase.sh -- "$MACHINE_PATH" "$@"
  status=$?
  set -e
  case "$status" in
    0) return 1 ;;
    1) return 0 ;;
    *) echo "machine-path grep could not read its inputs (exit $status)"; return 1 ;;
  esac
}

# Partition rows: every "<ms> <path>" row must name an existing file.
chk_partition() {
  local file="$1" ms path rows=0 missing=0
  [ -f "$file" ] || { echo "missing $file"; return 1; }
  while read -r ms path _; do
    case "$ms" in "" | "#"*) continue ;; esac
    rows=$((rows + 1))
    if [ -z "${path:-}" ] || [ ! -f "$path" ]; then
      echo "missing: ${path:-<no path on row: $ms>}"
      missing=$((missing + 1))
    fi
  done <"$file"
  [ "$rows" -gt 0 ] || { echo "no rows parsed from $file (vacuous)"; return 1; }
  [ "$missing" -eq 0 ]
}

chk_windows() { "${PY[@]}" windows "$1"; }

chk_register_exists() { [ -f "$1" ] || { echo "missing $1"; return 1; }; }

# chk_register <file> <counts|cells|routes|unique|coverage>
chk_register() {
  local file="$1" what="$2"
  if [ "$what" = "coverage" ]; then
    "${PY[@]}" register "$file" coverage "$W_EXPECTED" "$PREFIX_MIN" "${REQUIRED_IDS[@]}"
  else
    "${PY[@]}" register "$file" "$what"
  fi
}

# chk_d09_filter <hits-file> <contributing-file> [allow-entry ...]
chk_d09_filter() {
  local hits="$1" contributing="$2"; shift 2
  "${PY[@]}" d09-filter "$hits" "$contributing" "$RETIRED_HEADING" "$@"
}

# D-09 refined live-reference grep over the tracked tree, filtered.
chk_d09() {
  local status
  set +e
  git grep -nIiE "$D09_PATTERN" \
    -- ':!.planning' ':!CHANGELOG.md' ':!CHANGELOG-GENERATED.md' ':!prompts/' ':!bench/baselines/assets/' >"$HITS"
  status=$?
  set -e
  case "$status" in
    0) ;;
    1) return 0 ;;
    *) echo "D-09 git grep failed (exit $status)"; return 1 ;;
  esac
  chk_d09_filter "$HITS" "$CONTRIBUTING_FILE" "${D09_ALLOW[@]}"
}

# Every allowlist entry must name an existing path, so the list cannot rot.
chk_d09_stale() {
  local entry path stale=0
  for entry in "$@"; do
    path="${entry%%:*}"
    if [ ! -e "$path" ]; then
      echo "stale allowlist entry (path does not exist): $entry"
      stale=1
    fi
  done
  [ "$stale" -eq 0 ]
}

# SEED-005 carries the SEED-006 closure schema (D-21); SEED-008 exists with reopen_when (D-22).
chk_seeds() {
  local dir="$1" rc=0 s5 s8
  s5=("$dir"/SEED-005-*.md)
  s8=("$dir"/SEED-008-*.md)
  if [ "${#s5[@]}" -ne 1 ] || [ ! -f "${s5[0]}" ]; then
    echo "SEED-005: expected exactly one $dir/SEED-005-*.md"; rc=1
  else
    grep -qx 'status: closed' "${s5[0]}" || { echo "SEED-005: no exact 'status: closed' line"; grep '^status:' "${s5[0]}" || true; rc=1; }
    grep -q '^closed_on:' "${s5[0]}" || { echo "SEED-005: no closed_on:"; rc=1; }
    grep -q '^closed_during: v1\.47 Phase 246' "${s5[0]}" || { echo "SEED-005: no 'closed_during: v1.47 Phase 246'"; rc=1; }
    grep -q '^closed_reason:' "${s5[0]}" || { echo "SEED-005: no closed_reason:"; rc=1; }
    if grep -qF 'Status:** Open' "${s5[0]}"; then echo "SEED-005: still carries a 'Status:** Open' line"; rc=1; fi
  fi
  if [ "${#s8[@]}" -ne 1 ] || [ ! -f "${s8[0]}" ]; then
    echo "SEED-008: expected exactly one $dir/SEED-008-*.md"; rc=1
  else
    grep -q '^reopen_when:' "${s8[0]}" || { echo "SEED-008: no reopen_when:"; rc=1; }
  fi
  return "$rc"
}

# ---------------------------------------------------------------------------
# Default mode (runs in every mode)
# ---------------------------------------------------------------------------
SEED_FILES=()
for f in "$SEED_DIR"/SEED-005-*.md "$SEED_DIR"/SEED-008-*.md; do
  [ -f "$f" ] && SEED_FILES+=("$f")
done

check "username hygiene grep over $P and SEED-005/SEED-008" chk_username "$P" "${SEED_FILES[@]+"${SEED_FILES[@]}"}"

MP_TARGETS=("$T")
[ -f "$P/246-DEBT-REGISTER.md" ] && MP_TARGETS+=("$P/246-DEBT-REGISTER.md")
[ -f "$P/246-LANDING.md" ] && MP_TARGETS+=("$P/246-LANDING.md")
MP_TARGETS+=("${SEED_FILES[@]+"${SEED_FILES[@]}"}")
check "machine-path grep over the phase evidence files and SEED-005/SEED-008" chk_machine_path "${MP_TARGETS[@]}"

check "partition rows in $PARTITION_FILE name existing files" chk_partition "$PARTITION_FILE"

# ---------------------------------------------------------------------------
# --close
# ---------------------------------------------------------------------------
if [ "$MODE" = "--close" ]; then
  check "register $REGISTER exists" chk_register_exists "$REGISTER"
  if [ -f "$REGISTER" ]; then
    check "register frontmatter counts equal its row counts (check 1)" chk_register "$REGISTER" counts
    check "register dispositions are closed/waived/routed with non-blank reasons (check 2)" chk_register "$REGISTER" cells
    check "register routed rows name v1.48-v1.51 or a SEED id (check 3)" chk_register "$REGISTER" routes
    check "register ids are unique" chk_register "$REGISTER" unique
    check "register covers the 60 W ids, the required ids and >= 11 217- ids (check 5)" chk_register "$REGISTER" coverage
  fi
  check "WINDOWS ledger has zero open rows and open_count: 0 (check 4)" chk_windows "$WINDOWS_FILE"
  check "D-09 live-reference grep hits are all allowlisted (check 6)" chk_d09
  check "D-09 allowlist has no stale entries" chk_d09_stale "${D09_ALLOW[@]}"
  check "SEED-005 closure schema and SEED-008 reopen_when (check 7)" chk_seeds "$SEED_DIR"
fi

# ---------------------------------------------------------------------------
# --self-test: mutation controls over synthetic fixtures
# ---------------------------------------------------------------------------

# gen_register <out> [closed-count-offset] — a valid register covering every
# expected id: first row waived, second routed (v1.48), the rest closed.
gen_register() {
  local out="$1" bump="${2:-0}" ids=() id n=0 closed=0 waived=0 routed=0 disp reason body="$ST/rows.tmp"
  for id in $(seq 1 1) $(seq 3 57) $(seq 61 64); do ids+=("W$id"); done
  ids+=("${REQUIRED_IDS[@]}")
  for id in $(seq -w 1 11); do ids+=("217-R1-$id"); done
  : >"$body"
  for id in "${ids[@]}"; do
    n=$((n + 1))
    case "$n" in
      1) disp=waived; reason="obsolete in the fixture"; waived=$((waived + 1)) ;;
      2) disp=routed; reason="routed to v1.48 candidate list"; routed=$((routed + 1)) ;;
      *) disp=closed; reason="fixed by fixture"; closed=$((closed + 1)) ;;
    esac
    case "$id" in
      W*) printf '| <a id="%s"></a>%s | item | file | evidence | %s | %s |\n' "$id" "$id" "$disp" "$reason" ;;
      *) printf '| `%s` | item | file | evidence | %s | %s |\n' "$id" "$disp" "$reason" ;;
    esac >>"$body"
  done
  {
    printf -- '---\nphase: fixture\ncounts:\n  closed: %d\n  waived: %d\n  routed: %d\n  total: %d\n---\n\n' \
      "$((closed + bump))" "$waived" "$routed" "$n"
    printf '| id | item | source file | evidence | disposition | reason or route |\n'
    printf '|---|---|---|---|---|---|\n'
    cat "$body"
  } >"$out"
  rm -f "$body"
}

gen_windows() {  # gen_windows <out> <open_count> <json-body>
  printf -- '---\nschema_version: 1\nopen_count: %s\n---\n\n# Ledger\n\n````json\n%s\n````\n' "$2" "$3" >"$1"
}

# expect <case> <pass|fail> <need-in-output|-> <forbid-in-output|-> <command...>
expect() {
  local name="$1" want="$2" need="$3" forbid="$4" got why=""; shift 4
  if ( "$@" ) >"$ST/case.out" 2>&1; then got=pass; else got=fail; fi
  [ "$got" = "$want" ] || why="expected $want, got $got"
  if [ -z "$why" ] && [ "$need" != "-" ] && ! grep -qF -- "$need" "$ST/case.out"; then why="output lacks: $need"; fi
  if [ -z "$why" ] && [ "$forbid" != "-" ] && grep -qF -- "$forbid" "$ST/case.out"; then why="output contains: $forbid"; fi
  if [ -z "$why" ]; then
    ok "self-test $name: $want as expected"
  else
    cp "$ST/case.out" "$OUT"
    bad "self-test $name: $why"
  fi
}

# mutate <src> <dst> <sed-script> — a mutation that changes nothing is a vacuous
# self-test and fails on its own.
mutate() {
  sed "$3" "$1" >"$2"
  if cmp -s "$1" "$2"; then
    echo "mutation left the fixture unchanged: $3" >"$OUT"
    bad "self-test fixture mutation applies ($3)"
  fi
}

all_register_checks() {
  local f="$1" c
  for c in counts cells routes unique coverage; do chk_register "$f" "$c" || return 1; done
}

if [ "$MODE" = "--self-test" ]; then
  ST="$(mktemp -d)"
  R="$ST/register.md"; gen_register "$R"
  W="$ST/windows.md"; gen_windows "$W" 0 '[{"id": 1, "status": "fixed"}, {"id": 2, "status": "waived"}]'

  # valid: every register check and the WINDOWS check pass.
  expect "valid register" pass - - all_register_checks "$R"
  expect "valid WINDOWS" pass - - chk_windows "$W"

  # ordering: reversing the row order does not change the verdict.
  { sed -n '1,/^|---/p' "$R"; sed -n '/^|---/,$p' "$R" | sed 1d | awk '{a[NR]=$0} END {for (i=NR; i>0; i--) print a[i]}'; } >"$ST/reversed.md"
  expect "reordered register" pass - - all_register_checks "$ST/reversed.md"

  mutate "$R" "$ST/blank-disp.md" '/"W5"><\/a>W5 |/s/| closed |/|  |/'
  expect "blank disposition" fail "disposition ''" - chk_register "$ST/blank-disp.md" cells

  mutate "$R" "$ST/blank-reason.md" '/"W5"><\/a>W5 |/s/| fixed by fixture |$/|  |/'
  expect "blank reason" fail "blank reason" - chk_register "$ST/blank-reason.md" cells

  mutate "$R" "$ST/unnamed-route.md" 's/routed to v1\.48 candidate list/routed later/'
  expect "unnamed route" fail "routed reason names no" - chk_register "$ST/unnamed-route.md" routes

  gen_register "$ST/drift.md" 1
  expect "count drift" fail "frontmatter closed:" - chk_register "$ST/drift.md" counts

  { cat "$R"; tail -n 1 "$R"; } >"$ST/dup.md"
  expect "duplicate id" fail "duplicate id 217-R1-11" - chk_register "$ST/dup.md" unique

  mutate "$R" "$ST/missing-w.md" '/"W64"><\/a>W64 |/d'
  expect "missing W id" fail "missing W ids: W64" - chk_register "$ST/missing-w.md" coverage

  mutate "$R" "$ST/missing-req.md" '/`216-SHA-PINNING`/d'
  expect "missing required id" fail "216-SHA-PINNING" - chk_register "$ST/missing-req.md" coverage

  sed -n '1,/^|---/p' "$R" >"$ST/empty.md"
  expect "empty register" fail "empty register fails closed" - all_register_checks "$ST/empty.md"

  gen_windows "$ST/open.md" 0 '[{"id": 1, "status": "open"}, {"id": 2, "status": "fixed"}]'
  expect "open window" fail "1 open rows: 1" - chk_windows "$ST/open.md"
  gen_windows "$ST/count.md" 1 '[{"id": 1, "status": "fixed"}]'
  expect "open_count drift" fail "open_count: 1" - chk_windows "$ST/count.md"
  gen_windows "$ST/malformed.md" 0 '[{"id": 1, "status": ]'
  expect "malformed JSON" fail "does not parse" - chk_windows "$ST/malformed.md"

  expect "grep exit 2 (machine-path)" fail "could not read its inputs" - chk_machine_path "$ST/no-such-file"
  expect "grep exit 2 (username)" fail "could not read its inputs" - chk_username "$ST/no-such-file"

  printf '1 test/a.exs\n' >"$ST/partition.txt"
  expect "partition missing file" fail "missing: test/a.exs" - chk_partition "$ST/partition.txt"
  printf '# comments only\n\n' >"$ST/partition-empty.txt"
  expect "partition vacuous" fail "vacuous" - chk_partition "$ST/partition-empty.txt"

  # retired section scope (D-09): only the hit after the Retired section survives.
  printf '# Contributing\n\n%s\n\nThe UI critic loop was removed.\n\n## Other\n\nRun the critic here.\n' \
    "$RETIRED_HEADING" >"$ST/CONTRIBUTING.md"
  printf 'CONTRIBUTING.md:5:The UI critic loop was removed.\nCONTRIBUTING.md:9:Run the critic here.\n' >"$ST/hits.txt"
  expect "retired section scope" fail "CONTRIBUTING.md:9:" "CONTRIBUTING.md:5:" \
    chk_d09_filter "$ST/hits.txt" "$ST/CONTRIBUTING.md"
  sed "s/^$RETIRED_HEADING\$/## Something else/" "$ST/CONTRIBUTING.md" >"$ST/CONTRIBUTING-noheading.md"
  expect "retired section absent (fail closed)" fail "CONTRIBUTING.md:5:" - \
    chk_d09_filter "$ST/hits.txt" "$ST/CONTRIBUTING-noheading.md"
  { cat "$ST/CONTRIBUTING.md"; printf '%s\n' "$RETIRED_HEADING"; } >"$ST/CONTRIBUTING-twice.md"
  expect "retired heading twice (fail closed)" fail "CONTRIBUTING.md:5:" - \
    chk_d09_filter "$ST/hits.txt" "$ST/CONTRIBUTING-twice.md"
  printf 'CONTRIBUTING.md:5:The UI critic loop was removed.\n' >"$ST/hits-inside.txt"
  expect "retired section only" pass - - chk_d09_filter "$ST/hits-inside.txt" "$ST/CONTRIBUTING.md"

  # path:ERE allowlist entries exempt only matching lines.
  printf 'test/x.exs:12:~r/ADOPT|COMP|CRITIC/\ntest/x.exs:20:the critic\n' >"$ST/hits-ere.txt"
  expect "allowlist path:ERE scope" fail "test/x.exs:20:" "test/x.exs:12:" \
    chk_d09_filter "$ST/hits-ere.txt" "$ST/CONTRIBUTING.md" 'test/x.exs:ADOPT\|COMP\|CRITIC'
  expect "stale allowlist entry" fail "stale allowlist entry" - chk_d09_stale "$ST/no-such-file"

  # seeds (D-21 / D-22)
  mkdir -p "$ST/seeds"
  printf -- '---\nid: SEED-005\nstatus: closed\nclosed_on: 2026-10-25\nclosed_during: v1.47 Phase 246\nclosed_reason: shipped\n---\n' \
    >"$ST/seeds/SEED-005-x.md"
  printf -- '---\nid: SEED-008\nstatus: dormant\nreopen_when: a trigger\n---\n' >"$ST/seeds/SEED-008-y.md"
  expect "valid seeds" pass - - chk_seeds "$ST/seeds"
  printf '**Status:** Open\n' >>"$ST/seeds/SEED-005-x.md"
  expect "SEED-005 still Open" fail "Status:** Open" - chk_seeds "$ST/seeds"
  rm -f "$ST/seeds/SEED-008-y.md"
  expect "SEED-008 missing" fail "SEED-008: expected exactly one" - chk_seeds "$ST/seeds"
fi

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi
echo "verify-phase: all checks passed"
