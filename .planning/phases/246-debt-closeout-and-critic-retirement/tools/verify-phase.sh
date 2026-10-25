#!/usr/bin/env bash
# verify-phase.sh — the single Phase 246 close check (DEBT-01, DEBT-02; D-09, D-15).
#
# Modes:
#   (none)       hygiene greps (username, machine-path) + partition-row existence
#   --close      the above + WINDOWS, register and D-09 live-reference checks
#
# Every failing check prints a line starting "FAIL: " followed by its evidence;
# every passing check prints a line starting "ok: ". Failures accumulate: one run
# reports all open work, then exits 1.
#
# Read-only: no network, no git writes, no gsd-tools write verbs, no file writes
# outside mktemp scratch removed on exit.
#
# Usage (from anywhere inside the repo):
#   bash .planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh [--close]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT"
P="$(cd "$SCRIPT_DIR/.." && pwd)"   # survives archival to .planning/milestones/
P="${P#"$ROOT"/}"                    # repo-relative for messages
T="$P/tools"

MODE="${1:-}"
case "$MODE" in
  "" | "--close")
    ;;
  *)
    echo "verify-phase: unknown argument: $MODE" >&2
    echo "usage: verify-phase.sh [--close]" >&2
    exit 64
    ;;
esac

REGISTER="${REGISTER:-$P/246-DEBT-REGISTER.md}"
WINDOWS_FILE="${WINDOWS_FILE:-.planning/WINDOWS.md}"
PARTITION_FILE="${PARTITION_FILE:-test/partition_weights.txt}"

OUT="$(mktemp)"
HITS="$(mktemp)"
trap 'rm -f "$OUT" "$HITS"' EXIT

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

# WINDOWS: zero status == open in the ```json block, and frontmatter open_count: 0.
chk_windows() {
  python3 -I "$ROOT/$T/register-check.py" windows "$1"
}

chk_register_exists() {
  [ -f "$1" ] || { echo "missing $1"; return 1; }
}

# D-09 refined live-reference grep, filtered through the allowlist.
D09_ALLOW=()
chk_d09() {
  local status
  set +e
  git grep -nIiE 'critic([^a]|$)|tier[-_]a|mechanical_checker|verify\.(capture|mechanical|critic_trust|ui_critique)' \
    -- ':!.planning' ':!CHANGELOG.md' ':!CHANGELOG-GENERATED.md' ':!prompts/' ':!bench/baselines/assets/' >"$HITS"
  status=$?
  set -e
  case "$status" in
    0) ;;
    1) return 0 ;;
    *) echo "D-09 git grep failed (exit $status)"; return 1 ;;
  esac
  python3 -I "$ROOT/$T/register-check.py" d09-filter "$HITS" "${D09_ALLOW[@]+"${D09_ALLOW[@]}"}"
}

# ---------------------------------------------------------------------------
# Default mode (runs in every mode)
# ---------------------------------------------------------------------------
check "username hygiene grep over $P" chk_username "$P"

MP_TARGETS=("$T")
[ -f "$P/246-DEBT-REGISTER.md" ] && MP_TARGETS+=("$P/246-DEBT-REGISTER.md")
[ -f "$P/246-LANDING.md" ] && MP_TARGETS+=("$P/246-LANDING.md")
check "machine-path grep over the phase evidence files" chk_machine_path "${MP_TARGETS[@]}"

check "partition rows in $PARTITION_FILE name existing files" chk_partition "$PARTITION_FILE"

# ---------------------------------------------------------------------------
# --close
# ---------------------------------------------------------------------------
if [ "$MODE" = "--close" ]; then
  check "WINDOWS ledger has zero open rows and open_count: 0" chk_windows "$WINDOWS_FILE"
  check "register $REGISTER exists" chk_register_exists "$REGISTER"
  check "D-09 live-reference grep hits are all allowlisted" chk_d09
fi

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi
echo "verify-phase: all checks passed"
