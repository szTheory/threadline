#!/usr/bin/env bash
# measure-base02.sh — re-measure every fact BASE-02 names (Phase 214, plan 02).
#
# READ-ONLY toward GitHub: only `gh run list` and default-GET `gh api` calls.
# No dispatch, re-run, cancel, push, PR/issue writes, and no HTTP method override.
#
# Every step writes scrubbed raw output under raw/base02/ and MERGES its keys
# (plus the command that produced each key, under .commands) into
# raw/base02/facts.json. Scrubbing: the repo root becomes <repo>, $HOME becomes
# <home>, ANSI escapes are stripped. Exception: the `wall` step writes only
# facts.json keys and no raw/base02 file; its raw input is the already-committed
# raw/ci data (manifest.json + runs/*.json), read via summarize-ci.py, never modified.
#
# Usage (from anywhere inside the repo):
#   bash .planning/phases/214-baseline-measurement/tools/measure-base02.sh [step ...]
# Steps: flake advisories paths xref wall (default: all steps)
#   wall is offline: it reads raw/ci via summarize-ci.py and makes no gh call.
set -euo pipefail

REPO="szTheory/threadline"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE_DIR="$(dirname "$SCRIPT_DIR")"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
RAW="$PHASE_DIR/raw/base02"
FACTS="$RAW/facts.json"
mkdir -p "$RAW"
cd "$ROOT"

# Fast-failure threshold (minutes). Fixed by the plan; recorded in facts.json.
FAST_FAIL_MIN=10

scrub() {
  sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g' \
    | sed -e "s#${ROOT}#<repo>#g" -e "s#${HOME}#<home>#g"
}

# merge_facts <json-object>: deep-merge into facts.json (never clobbers other keys)
merge_facts() {
  local new="$1" tmp
  [ -f "$FACTS" ] || echo '{}' > "$FACTS"
  tmp="$(mktemp "${TMPDIR:-/tmp}/facts.XXXXXX")"
  jq -S --argjson n "$new" '. * $n' "$FACTS" > "$tmp"
  mv "$tmp" "$FACTS"
}

step_flake() {
  local cmd="gh run list --repo $REPO --workflow flake-detection.yml --event schedule --limit 200 --json databaseId,createdAt,updatedAt,conclusion,status"
  echo "[flake] $cmd" >&2
  # shellcheck disable=SC2086
  $cmd | scrub | jq -S 'sort_by(.createdAt)' > "$RAW/flake-runs.json"

  local timeout
  timeout="$(awk '
    /^  verify-flake:/ {f=1; next}
    f && /^  [A-Za-z0-9_-]+:/ {f=0}
    f && /timeout-minutes:/ {print $2; exit}
  ' .github/workflows/flake-detection.yml)"
  [ -n "$timeout" ] || { echo "[flake] could not read verify-flake timeout-minutes" >&2; exit 1; }

  local out
  out="$(python3 - "$RAW/flake-runs.json" "$FAST_FAIL_MIN" <<'PY'
import json, sys
from datetime import datetime
runs = json.load(open(sys.argv[1]))
thr = float(sys.argv[2])
def ts(s): return datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ")
runs = [r for r in runs if r.get("status") == "completed"]
runs.sort(key=lambda r: (r["createdAt"], r["databaseId"]))
best, cur = [], []
for r in runs:
    dur = (ts(r["updatedAt"]) - ts(r["createdAt"])).total_seconds() / 60
    if r["conclusion"] == "failure" and dur < thr:
        cur.append(r)
        if len(cur) > len(best): best = list(cur)
    else:
        cur = []
if not best:
    print(json.dumps({"flake_fast_fail_count": 0})); sys.exit(0)
f, l = best[0], best[-1]
print(json.dumps({
  "flake_fast_fail_first": f["createdAt"][5:10],
  "flake_fast_fail_last": l["createdAt"][5:10],
  "flake_fast_fail_first_date": f["createdAt"][:10],
  "flake_fast_fail_last_date": l["createdAt"][:10],
  "flake_fast_fail_first_run": f["databaseId"],
  "flake_fast_fail_last_run": l["databaseId"],
  "flake_fast_fail_count": len(best),
  "flake_scheduled_runs_seen": len(runs),
}))
PY
)"
  local cmds
  cmds="$(jq -n --arg c "$cmd" --arg t "awk verify-flake timeout-minutes .github/workflows/flake-detection.yml" --arg rule "longest contiguous (createdAt order) run of conclusion=failure with updatedAt-createdAt < ${FAST_FAIL_MIN} min, over: $cmd" '{
    commands: {
      flake_fast_fail_first: $rule, flake_fast_fail_last: $rule,
      flake_fast_fail_first_run: $rule, flake_fast_fail_last_run: $rule,
      flake_fast_fail_count: $rule, flake_scheduled_runs_seen: $c,
      flake_fast_fail_threshold_min: "fixed by 214-02-PLAN (fast failure = under 10 min)",
      flake_timeout_min: $t
    }}')"
  merge_facts "$(jq -n --argjson o "$out" --argjson c "$cmds" --argjson t "$timeout" --argjson thr "$FAST_FAIL_MIN" \
    '$o + {flake_timeout_min: $t, flake_fast_fail_threshold_min: $thr} + $c')"
}

# --- advisories -------------------------------------------------------------
# run_audit <label> <dir>: mix hex.audit in <dir>; ANSI-stripped, scrubbed output
run_audit() {
  local label="$1" dir="$2" out="$RAW/hex-audit-$1.txt" rc
  echo "[advisories] ($label) mix hex.audit" >&2
  : > "$out"
  if [ ! -d "$dir/deps" ]; then
    echo "[advisories] $label has no deps/, running mix deps.get (locked versions only)" >&2
    (cd "$dir" && bash -c 'mix deps.get' >/dev/null 2>&1)
    echo "note: mix deps.get was run first (deps/ absent)" >> "$out"
  fi
  set +e
  (cd "$dir" && bash -c 'mix hex.audit' 2>&1) \
    | grep -v 'authentication session has expired' | scrub >> "$out"
  rc=${PIPESTATUS[0]}
  set -e
  printf 'exit_code: %s\n' "$rc" >> "$out"
}

# parse_audit <file>: JSON array of {package, version, id, severity, ghsa}
parse_audit() {
  python3 -c '
import json, re, sys
out, cur = [], None
for line in open(sys.argv[1]):
    m = re.match(r"^  (\S+) (\S+) - (\S+) \((\w+)\)\s*$", line)
    if m:
        cur = {"package": m[1], "version": m[2], "id": m[3], "severity": m[4], "ghsa": None}
        out.append(cur); continue
    m = re.search(r"(GHSA-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4})", line)
    if cur and m and "aka:" in line:
        cur["ghsa"] = m[1]
print(json.dumps(out))
' "$1"
}

step_advisories() {
  run_audit root "$ROOT"
  run_audit bench "$ROOT/bench"
  run_audit example "$ROOT/examples/threadline_phoenix"
  git diff --quiet -- mix.lock bench/mix.lock examples/threadline_phoenix/mix.lock mix.exs \
    || { echo "[advisories] FATAL: a lockfile or mix.exs changed" >&2; exit 1; }

  local root bench example
  root="$(parse_audit "$RAW/hex-audit-root.txt")"
  bench="$(parse_audit "$RAW/hex-audit-bench.txt")"
  example="$(parse_audit "$RAW/hex-audit-example.txt")"

  # GitHub advisory severity: read-only default GET per GHSA id
  local ghsa ids adv="[]" one
  ids="$(jq -rn --argjson a "$root" --argjson b "$bench" --argjson c "$example" \
    '[$a[], $b[], $c[]] | map(.ghsa) | map(select(.)) | unique | .[]')"
  for ghsa in $ids; do
    echo "[advisories] gh api /advisories/$ghsa" >&2
    if one="$(gh api "/advisories/$ghsa" 2>/dev/null)"; then
      one="$(jq '{ghsa_id, cve_id, severity, summary, published_at, html_url,
        vulnerabilities: [(.vulnerabilities // [])[] | {package: .package.name, vulnerable_version_range, first_patched_version}]}' <<<"$one")"
    else
      # not in GitHub's global advisory database (gh api returned non-2xx, e.g. 404)
      one="$(jq -n --arg g "$ghsa" '{ghsa_id: $g, severity: null, lookup: "not found via gh api /advisories"}')"
    fi
    adv="$(jq --argjson x "$one" '. + [$x]' <<<"$adv")"
  done
  jq -S --argjson r "$root" --argjson b "$bench" --argjson e "$example" \
    '{hex_audit: {root: $r, bench: $b, example: $e}, github_advisories: .}' <<<"$adv" \
    > "$RAW/advisories.json"

  local hexv
  hexv="$(bash -c 'mix hex.info' 2>&1 | scrub | awk '/^Hex:/{print $2; exit}')"
  merge_facts "$(jq -n --argjson r "$root" --argjson b "$bench" --argjson e "$example" \
    --arg hexv "$hexv" --slurpfile gh "$RAW/advisories.json" '
    def ghsev($id): ([$gh[0].github_advisories[] | select(.ghsa_id == $id) | .severity] | first) // null;
    {
      root_advisory_count: ($r | length),
      root_advisory_packages: [$r[] | "\(.package) \(.version)"],
      root_advisories: [$r[] | . + {github_severity: ghsev(.ghsa)}],
      bench_advisory_count: ($b | length),
      bench_high_count: ([$b[] | select(.severity == "HIGH")] | length),
      bench_severity_counts: ($b | group_by(.severity) | map({(.[0].severity): length}) | add // {}),
      bench_advisory_packages: ([$b[] | "\(.package) \(.version)"] | unique),
      example_advisory_count: ($e | length),
      hex_version: $hexv,
      commands: {
        root_advisory_count: "mix hex.audit (repo root) -> raw/base02/hex-audit-root.txt",
        root_advisory_packages: "mix hex.audit (repo root)",
        root_advisories: "mix hex.audit (repo root) + gh api /advisories/<GHSA> -> raw/base02/advisories.json",
        bench_advisory_count: "cd bench && mix hex.audit -> raw/base02/hex-audit-bench.txt",
        bench_high_count: "cd bench && mix hex.audit (severity as printed by hex.audit)",
        bench_severity_counts: "cd bench && mix hex.audit",
        bench_advisory_packages: "cd bench && mix hex.audit",
        example_advisory_count: "cd examples/threadline_phoenix && mix hex.audit -> raw/base02/hex-audit-example.txt",
        hex_version: "mix hex.info"
      }
    }')"
}

# --- tracked machine-local paths ---------------------------------------------
PATH_ABS_RE='/(Users|home)/[^/[:space:]]+/'
PATH_HOME_RE='(^|[^[:alnum:]_.])~/'

# grep_files <rev> <regex>: repo-relative file names at <rev> matching <regex>
grep_files() {
  (git grep -l -I -E "$2" "$1" -- . || true) | sed -e "s#^$1:##"
}

# count_paths <rev> <slug>: writes the union list, prints a JSON breakdown
count_paths() {
  local rev="$1" list="$RAW/tracked-paths-$2.txt" abs home
  { grep_files "$rev" "$PATH_ABS_RE"; grep_files "$rev" "$PATH_HOME_RE"; } | sort -u > "$list"
  abs="$(grep_files "$rev" "$PATH_ABS_RE" | wc -l | tr -d ' ')"
  home="$(grep_files "$rev" "$PATH_HOME_RE" | wc -l | tr -d ' ')"
  python3 -c '
import json, sys, collections
files = [l.strip() for l in open(sys.argv[1]) if l.strip()]
by = collections.Counter()
for f in files:
    if f.startswith("prompts/prior-art/"): k = "prompts/prior-art"
    elif "/" in f: k = f.split("/")[0]
    else: k = "(root)"
    by[k] += 1
print(json.dumps({"total": len(files), "absolute_pattern_files": int(sys.argv[2]),
                  "home_relative_pattern_files": int(sys.argv[3]), "by_dir": dict(sorted(by.items()))}))
' "$list" "$abs" "$home"
}

step_paths() {
  echo "[paths] git fetch origin main" >&2
  git fetch --quiet origin main
  local head_sha origin_sha h o
  head_sha="$(git rev-parse --short=8 HEAD)"
  origin_sha="$(git rev-parse --short=8 origin/main)"
  h="$(count_paths HEAD HEAD)"
  o="$(count_paths origin/main origin-main)"
  local cmd="git grep -l -I -E <regex> <rev> -- . (union of the absolute and home-relative regexes in tracked_path_regexes)"
  merge_facts "$(jq -n --argjson h "$h" --argjson o "$o" --arg hs "$head_sha" --arg os "$origin_sha" \
    --arg abs "$PATH_ABS_RE" --arg home "$PATH_HOME_RE" --arg cmd "$cmd" '{
      tracked_path_files_head: $h.total,
      tracked_path_files_origin_main: $o.total,
      tracked_path_prior_art_files: ($h.by_dir["prompts/prior-art"] // 0),
      tracked_path_prior_art_files_origin_main: ($o.by_dir["prompts/prior-art"] // 0),
      tracked_path_head_sha: $hs,
      tracked_path_origin_main_sha: $os,
      tracked_path_by_dir: {HEAD: $h.by_dir, "origin/main": $o.by_dir},
      tracked_path_pattern_counts: {
        HEAD: {absolute: $h.absolute_pattern_files, home_relative: $h.home_relative_pattern_files},
        "origin/main": {absolute: $o.absolute_pattern_files, home_relative: $o.home_relative_pattern_files}},
      tracked_path_regexes: {absolute: $abs, home_relative: $home},
      commands: {
        tracked_path_files_head: ($cmd + " at HEAD -> raw/base02/tracked-paths-HEAD.txt"),
        tracked_path_files_origin_main: ("git fetch origin main; " + $cmd + " at origin/main -> raw/base02/tracked-paths-origin-main.txt"),
        tracked_path_prior_art_files: ($cmd + " at HEAD, files under prompts/prior-art/"),
        tracked_path_head_sha: "git rev-parse --short=8 HEAD",
        tracked_path_origin_main_sha: "git rev-parse --short=8 origin/main"
      }}')"
}

# --- xref cycles ---------------------------------------------------------------
# cycle_count <file>: N from "N cycles found", 0 from "No cycles found", else null
cycle_count() {
  python3 -c '
import re, sys
t = open(sys.argv[1]).read()
m = re.search(r"(\d+) cycles? found", t)
print(m[1] if m else (0 if "No cycles found" in t else "null"))
' "$1"
}

step_xref() {
  echo "[xref] mix xref graph --format cycles [--label compile-connected]" >&2
  set +e
  bash -c 'mix xref graph --format cycles --label compile-connected' 2>&1 | scrub > "$RAW/xref-compile-connected.txt"
  bash -c 'mix xref graph --format cycles' 2>&1 | scrub > "$RAW/xref-runtime.txt"
  set -e
  local cc rt cross
  cc="$(cycle_count "$RAW/xref-compile-connected.txt")"
  rt="$(cycle_count "$RAW/xref-runtime.txt")"
  if grep -q 'capture/audit_transaction.ex' "$RAW/xref-runtime.txt" \
     && grep -q 'semantics/audit_action.ex' "$RAW/xref-runtime.txt"; then cross=true; else cross=false; fi
  merge_facts "$(jq -n --argjson cc "$cc" --argjson rt "$rt" --argjson x "$cross" '{
    xref_compile_connected_cycles: $cc, xref_runtime_cycles: $rt, xref_cross_layer_edge_present: $x,
    commands: {
      xref_compile_connected_cycles: "mix xref graph --format cycles --label compile-connected -> raw/base02/xref-compile-connected.txt",
      xref_runtime_cycles: "mix xref graph --format cycles -> raw/base02/xref-runtime.txt",
      xref_cross_layer_edge_present: "grep capture/audit_transaction.ex and semantics/audit_action.ex in raw/base02/xref-runtime.txt"
    }}')"
}

# --- CI wall time (gap G2) ------------------------------------------------------
# Offline: derives wall-time p50s from the committed raw/ci data via summarize-ci.py.
# Fails closed (exit 1, nothing merged) if any expected p50 row cannot be parsed.
step_wall() {
  local sc=".planning/phases/214-baseline-measurement/tools/summarize-ci.py"
  local c_pr="python3 $sc wall --workflow ci.yml --event pull_request"
  local c_push="python3 $sc wall --workflow ci.yml --event push"
  local c_bpush="python3 $sc workflow-cost --workflow browser-full.yml --event push --since 2026-08-27"
  local c_bsched="python3 $sc workflow-cost --workflow browser-full.yml --event schedule --since 2026-08-27"
  local o_pr o_push o_bpush o_bsched
  echo "[wall] summarize-ci.py wall / workflow-cost (offline, raw/ci)" >&2
  # shellcheck disable=SC2086
  o_pr="$($c_pr | scrub)"
  # shellcheck disable=SC2086
  o_push="$($c_push | scrub)"
  # shellcheck disable=SC2086
  o_bpush="$($c_bpush | scrub)"
  # shellcheck disable=SC2086
  o_bsched="$($c_bsched | scrub)"

  local out
  out="$(python3 - "$o_pr" "$o_push" "$o_bpush" "$o_bsched" "$c_pr" "$c_push" "$c_bpush" "$c_bsched" <<'PY'
import json, re, sys
o_pr, o_push, o_bpush, o_bsched, c_pr, c_push, c_bpush, c_bsched = sys.argv[1:9]

def die(cmd):
    print(f"[wall] could not parse p50 from {cmd}", file=sys.stderr)
    sys.exit(1)

def wall(out, cmd):
    ms = [m for m in (re.search(r"p50 (\d+) s \(run (\d+)\)", l) for l in out.splitlines()) if m]
    if len(ms) != 1: die(cmd)
    return int(ms[0][1]), int(ms[0][2])

def cost(out, cmd):
    rows = [l for l in out.splitlines() if "successful wall" in l]
    if len(rows) != 1: die(cmd)
    m = re.search(r"p50 (\d+\.\d) min \(run (\d+)\)", rows[0])
    if not m: die(cmd)
    return m[1], int(m[2])

def fmt_min(secs):  # identical rule to summarize-ci.py fmt_min (half-up tenths)
    tenths = (secs * 10 + 30) // 60
    return f"{tenths // 10}.{tenths % 10}"

pr_s, pr_run = wall(o_pr, c_pr)
push_s, push_run = wall(o_push, c_push)
bp_min, bp_run = cost(o_bpush, c_bpush)
bs_min, bs_run = cost(o_bsched, c_bsched)
print(json.dumps({
  "ci_wall_pr_p50_s": pr_s, "ci_wall_pr_p50_min": fmt_min(pr_s), "ci_wall_pr_p50_run": pr_run,
  "ci_wall_push_p50_s": push_s, "ci_wall_push_p50_min": fmt_min(push_s), "ci_wall_push_p50_run": push_run,
  "browser_full_push_p50_min": bp_min, "browser_full_push_p50_run": bp_run,
  "browser_full_schedule_p50_min": bs_min, "browser_full_schedule_p50_run": bs_run,
  "commands": {
    "ci_wall_pr_p50_s": c_pr,
    "ci_wall_pr_p50_min": f"fmt_min({pr_s}) of: {c_pr}",
    "ci_wall_pr_p50_run": c_pr,
    "ci_wall_push_p50_s": c_push,
    "ci_wall_push_p50_min": f"fmt_min({push_s}) of: {c_push}",
    "ci_wall_push_p50_run": c_push,
    "browser_full_push_p50_min": f"successful wall row of: {c_bpush}",
    "browser_full_push_p50_run": f"successful wall row of: {c_bpush}",
    "browser_full_schedule_p50_min": f"successful wall row of: {c_bsched}",
    "browser_full_schedule_p50_run": f"successful wall row of: {c_bsched}",
    "wall_regenerate": "bash .planning/phases/214-baseline-measurement/tools/measure-base02.sh wall (offline; reads raw/ci)",
  },
}))
PY
)"
  merge_facts "$out"
}

STEPS=("$@")
[ ${#STEPS[@]} -gt 0 ] || STEPS=(flake advisories paths xref wall)
for s in "${STEPS[@]}"; do
  case "$s" in
    flake) step_flake ;;
    advisories) step_advisories ;;
    paths) step_paths ;;
    xref) step_xref ;;
    wall) step_wall ;;
    *) echo "unknown step: $s" >&2; exit 2 ;;
  esac
done
echo "[done] $FACTS" >&2
