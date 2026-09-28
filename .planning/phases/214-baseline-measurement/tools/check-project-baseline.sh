#!/usr/bin/env bash
# check-project-baseline.sh — BASE-02 checker (Phase 214, plan 02).
#
# Asserts that PROJECT.md's `## Current Milestone` region states every measured
# fact in raw/base02/facts.json. Expected values are read from facts.json with jq,
# never hard-coded. Prints `MISSING: <label>: <expected>` per miss; exits 1 on any.
#
# Usage: bash check-project-baseline.sh [path-to-PROJECT.md]   (default .planning/PROJECT.md)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE_DIR="$(dirname "$SCRIPT_DIR")"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
FACTS="$PHASE_DIR/raw/base02/facts.json"
TARGET="${1:-$ROOT/.planning/PROJECT.md}"

[ -f "$TARGET" ] || { echo "MISSING: file: $TARGET"; exit 1; }
[ -f "$FACTS" ] || { echo "MISSING: facts: raw/base02/facts.json"; exit 1; }

REGION="$(awk '/^## Current Milestone/{f=1; print; next} f && /^## /{f=0} f' "$TARGET")"
[ -n "$REGION" ] || { echo "MISSING: region: ## Current Milestone"; exit 1; }

fail=0
fact() { jq -er "$1" "$FACTS"; }

expect() { # expect <label> <literal>
  if ! grep -qF -- "$2" <<<"$REGION"; then
    echo "MISSING: $1: $2"; fail=1
  fi
}

# --- Flake Detection streak and timeout -------------------------------------
expect flake_fast_fail_first "$(fact .flake_fast_fail_first)"
expect flake_fast_fail_last "$(fact .flake_fast_fail_last)"
expect flake_fast_fail_streak "$(fact .flake_fast_fail_first)→$(fact .flake_fast_fail_last)"
expect flake_timeout_min "$(fact .flake_timeout_min)-min timeout"

# --- Advisories --------------------------------------------------------------
expect root_advisory_count "$(fact .root_advisory_count) advisories"
while IFS= read -r pkg; do
  expect root_advisory_package "$pkg"
done < <(jq -r '.root_advisory_packages[]' "$FACTS")
expect bench_high_count "$(fact .bench_high_count) HIGH"
expect bench_advisory_count "$(fact .bench_advisory_count) advisories"

# --- Tracked machine-local paths ----------------------------------------------
expect tracked_path_files_head "$(fact .tracked_path_files_head) tracked files"
expect tracked_path_head_sha "$(fact .tracked_path_head_sha)"
expect tracked_path_prior_art_files "$(fact .tracked_path_prior_art_files) in \`prompts/prior-art/\`"
expect tracked_path_files_origin_main "$(fact .tracked_path_files_origin_main) files"

# --- Wording and xref disposition ----------------------------------------------
expect tmp_dir_wording "tmp_dir hygiene"
expect xref_disposition "no runtime-cycle gate"
expect xref_gate "verify.xref_cycles"
expect xref_runtime_cycles "$(fact .xref_runtime_cycles) runtime cycles"
expect xref_compile_connected_cycles "$(fact .xref_compile_connected_cycles) compile-connected cycles"
# BASE-02 bullet 4: the pre-milestone flake wording must be gone
if grep -qiF -- "tmp_dir flakes" <<<"$REGION"; then
  echo "MISSING: tmp_dir_wording_replaced: region still says \"tmp_dir flakes\""; fail=1
fi

# --- CI wall time (gap G2) ---
# p50 values and run IDs from raw/base02/facts.json (measure-base02.sh wall, offline over raw/ci).
# The run ID inside each literal anchors the match.
expect ci_wall_pr_p50 "PR $(fact .ci_wall_pr_p50_min) min (run $(fact .ci_wall_pr_p50_run))"
expect ci_wall_push_p50 "push $(fact .ci_wall_push_p50_min) min (run $(fact .ci_wall_push_p50_run))"
expect browser_full_push_p50 "$(fact .browser_full_push_p50_min) min on every push to main (run $(fact .browser_full_push_p50_run))"
expect browser_full_schedule_p50 "$(fact .browser_full_schedule_p50_min) min nightly (run $(fact .browser_full_schedule_p50_run))"
# The pre-phase approximate wall-time wording (ff8e53e9) must be gone
for phrase in "PR ~9 min" "~17 min on every push"; do
  if grep -qF -- "$phrase" <<<"$REGION"; then
    echo "MISSING: stale_wall_wording: region still says \"$phrase\""; fail=1
  fi
done

# --- Out of Scope re-check (success criterion 4; re-check only, never edited) ---
# Only meaningful for a full PROJECT.md (fixtures hold just the milestone region).
if grep -q '^### Out of Scope' "$TARGET"; then
  oos() { awk '/^### Out of Scope/{f=1} /^## Context/{f=0} f'; }
  BASE_OOS="$(git -C "$ROOT" show ff8e53e9:.planning/PROJECT.md | oos)"
  CUR_OOS="$(oos < "$TARGET")"
  if [ -z "$BASE_OOS" ]; then
    echo "MISSING: out_of_scope_base: empty section at ff8e53e9"; fail=1
  elif [ "$BASE_OOS" != "$CUR_OOS" ]; then
    echo "MISSING: out_of_scope_unchanged: ### Out of Scope differs from ff8e53e9"; fail=1
  fi
  for clause in "newest-toolchain lane is in scope for v1.43, after a spike" "to make a lane's pin honest"; do
    grep -qF -- "$clause" <<<"$CUR_OOS" || { echo "MISSING: out_of_scope_clause: $clause"; fail=1; }
  done
fi

exit "$fail"
