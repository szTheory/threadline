#!/usr/bin/env bash
# aggregate-ci-baseline.sh — THROWAWAY Phase-192 CI-01 baseline aggregator.
#
# Lives under .planning/ ONLY. It is NEVER referenced by any GitHub Actions
# workflow (D-05 observer-effect ordering: measurement must not perturb the
# pipeline it measures). Read-only against the GitHub Actions API via `gh api`.
#
# What it does:
#   1. Pages workflows/ci.yml/runs?status=success&event=push&branch=main until
#      it has collected ~15 GREEN runs (the recent window near 2026-06-26 is
#      red-heavy; successes cluster earlier — do NOT sample "last 15 total").
#   2. For each collected run, calls actions/runs/{id}/jobs and reads per-job
#      started_at/completed_at, computing each job's wall-clock duration (s).
#   3. Maps the API display `name` back to the stable ci.yml job key.
#   4. Aggregates p50/p95 per job across the sampled window, plus the aggregate
#      critical-path figure (parallel fan-out => critical path == the single
#      longest job per run).
#   5. Prints a markdown table + aggregate critical-path p50/p95 to stdout for
#      transcription into 192-BASELINE.md.
#
# Honest boundaries (NOT invented here — recorded as unavailable in the baseline):
#   - Billed minutes: public-repo billing API returns {"billable":{}} (empty).
#   - Cache-hit rate: N/A — no actions/cache configured today.
#
# Requirements: gh (authed), jq.
set -euo pipefail

REPO="szTheory/threadline"
WORKFLOW="ci.yml"
TARGET_GREEN=15   # collect ~15 GREEN runs, paging past the red-heavy window

for bin in gh jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "FATAL: $bin not found" >&2; exit 1; }
done

# --- name -> stable job key mapping (jobs endpoint returns display names) ---
name_to_key() {
  case "$1" in
    "Check formatting")                                    echo "verify-format" ;;
    "Run Credo (strict)")                                  echo "verify-credo" ;;
    "Compile without optional deps")                       echo "verify-compile-no-optional" ;;
    "Run test suite")                                      echo "verify-test" ;;
    "PgBouncer transaction topology")                      echo "verify-pgbouncer-topology" ;;
    "Hex evaluator smoke (threadline from hex.pm)")        echo "verify-hex-evaluator" ;;
    "Example app browser E2E (Playwright)")                echo "verify-example-browser" ;;
    "Build ExDoc (dev)")                                   echo "verify-docs" ;;
    "Hex package tarball")                                 echo "verify-hex-package" ;;
    "Release metadata (version / changelog)")              echo "verify-release-shape" ;;
    *)                                                     echo "UNMAPPED:$1" ;;
  esac
}

# --- 1. Collect ~15 GREEN push-on-main run ids (page until satisfied) --------
run_ids=()
page=1
while [ "${#run_ids[@]}" -lt "$TARGET_GREEN" ] && [ "$page" -le 10 ]; do
  ids=$(gh api \
    "repos/${REPO}/actions/workflows/${WORKFLOW}/runs?status=success&event=push&branch=main&per_page=100&page=${page}" \
    --jq '.workflow_runs[].id' 2>/dev/null || true)
  [ -z "$ids" ] && break
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    run_ids+=("$id")
    [ "${#run_ids[@]}" -ge "$TARGET_GREEN" ] && break
  done <<< "$ids"
  page=$((page + 1))
done

SAMPLE_N="${#run_ids[@]}"
if [ "$SAMPLE_N" -eq 0 ]; then
  echo "FATAL: no GREEN push-on-main runs collected (gh unauthenticated or API failure)." >&2
  echo "Record affected rows as honest-unavailable with a reopen trigger in 192-BASELINE.md." >&2
  exit 2
fi

echo "# CI-01 baseline aggregation" >&2
echo "# repo=${REPO} workflow=${WORKFLOW} filter=status=success,event=push,branch=main" >&2
echo "# collected ${SAMPLE_N} GREEN runs: ${run_ids[*]}" >&2

# --- 2/3. Gather per-job durations keyed by stable job key -------------------
# Accumulate lines "key<TAB>duration_seconds" and "run_id<TAB>max_job_duration".
tmp_jobs=$(mktemp)
tmp_crit=$(mktemp)
rerun_count=0
trap 'rm -f "$tmp_jobs" "$tmp_crit"' EXIT

for rid in "${run_ids[@]}"; do
  # run_attempt>1 signal
  attempt=$(gh api "repos/${REPO}/actions/runs/${rid}" --jq '.run_attempt' 2>/dev/null || echo 1)
  [ "${attempt:-1}" -gt 1 ] && rerun_count=$((rerun_count + 1))

  # per-job durations for this run
  jobs_json=$(gh api "repos/${REPO}/actions/runs/${rid}/jobs" 2>/dev/null || echo '{"jobs":[]}')
  run_max=0
  while IFS=$'\t' read -r jname started completed; do
    [ -z "$jname" ] && continue
    [ "$started" = "null" ] || [ "$completed" = "null" ] && { [ "$started" = "null" ] && continue; }
    s=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$started" +%s 2>/dev/null || date -u -d "$started" +%s)
    c=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$completed" +%s 2>/dev/null || date -u -d "$completed" +%s)
    dur=$((c - s))
    [ "$dur" -lt 0 ] && continue
    key=$(name_to_key "$jname")
    printf '%s\t%s\n' "$key" "$dur" >> "$tmp_jobs"
    [ "$dur" -gt "$run_max" ] && run_max="$dur"
  done < <(echo "$jobs_json" | jq -r '.jobs[] | "\(.name)\t\(.started_at)\t\(.completed_at)"')
  printf '%s\t%s\n' "$rid" "$run_max" >> "$tmp_crit"
done

# --- 4. Percentile helper (nearest-rank) ------------------------------------
pctl() { # $1=percentile(0-100) reads durations on stdin
  jq -s --argjson p "$1" '
    sort as $a | ($a|length) as $n
    | if $n==0 then 0
      else ($a[ (( ($p/100)*$n ) | ceil ) - 1 | if .<0 then 0 else . end ]) end
  '
}

# --- 5. Emit markdown table -------------------------------------------------
echo ""
echo "## Per-job wall-clock (p50/p95) across ${SAMPLE_N} GREEN push-on-main ci.yml runs"
echo ""
echo "| job (key) | p50 (s) | p95 (s) | samples |"
echo "|-----------|--------:|--------:|--------:|"

# stable job-key order matching ci.yml header contract
for key in verify-format verify-credo verify-compile-no-optional verify-test \
           verify-pgbouncer-topology verify-hex-evaluator verify-example-browser \
           verify-docs verify-hex-package verify-release-shape; do
  durs=$(awk -F'\t' -v k="$key" '$1==k{print $2}' "$tmp_jobs")
  n=$(echo "$durs" | grep -c . || true)
  if [ "${n:-0}" -eq 0 ]; then
    printf "| %s | n/a | n/a | 0 |\n" "$key"
    continue
  fi
  p50=$(echo "$durs" | pctl 50)
  p95=$(echo "$durs" | pctl 95)
  printf "| %s | %s | %s | %s |\n" "$key" "$p50" "$p95" "$n"
done

# --- aggregate critical path (longest job per run) --------------------------
crit_durs=$(awk -F'\t' '{print $2}' "$tmp_crit")
crit_p50=$(echo "$crit_durs" | pctl 50)
crit_p95=$(echo "$crit_durs" | pctl 95)

echo ""
echo "## Aggregate critical path (parallel fan-out => longest single job per run)"
echo ""
echo "| metric | value (s) |"
echo "|--------|----------:|"
printf "| critical-path p50 | %s |\n" "$crit_p50"
printf "| critical-path p95 | %s |\n" "$crit_p95"
printf "| reruns observed (run_attempt>1) | %s of %s runs |\n" "$rerun_count" "$SAMPLE_N"
echo ""
echo "Notes: billed minutes = unavailable (public-repo billing API returns empty {\"billable\":{}});"
echo "cache-hit rate = N/A (no actions/cache configured today). Recorded as honest-unavailable rows."
