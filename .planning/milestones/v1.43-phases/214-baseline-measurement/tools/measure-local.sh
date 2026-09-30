#!/usr/bin/env bash
# measure-local.sh — local BASE-01 captures (Phase 214, plan 02).
#
# Steps:
#   env            raw/local/env.txt (toolchain, hardware, test-DB state; no user/host/path)
#   slowest        `MIX_ENV=test mix test --slowest 25` -> raw/local/slowest-25.{txt,summary.json}
#   live-dialyzer  the isolated `:live_dialyzer` test, warm PLT and cold PLT
#                  -> raw/local/live-dialyzer.json, live-dialyzer-{warm,cold}.txt
#   ci-steps       read-only `gh run view <id> --json jobs` for one green push run
#                  -> raw/local/ci-test-steps.json
#
# Safety:
#   - The cold-PLT run moves `.dialyzer` aside to `.dialyzer.214-warm` and installs an
#     EXIT/INT/TERM trap that deletes the freshly built PLT and moves the warm one back.
#     If `.dialyzer.214-warm` already exists the script refuses to run.
#   - The local test DB is only read (the stale public capture function is recorded,
#     not fixed). GitHub access is read-only (gh run list / gh run view).
#   - Output is ANSI-stripped; the repo root becomes <repo> and $HOME becomes <home>.
#
# Usage: bash .planning/phases/214-baseline-measurement/tools/measure-local.sh [step ...]
#        (default: env slowest live-dialyzer ci-steps)
set -euo pipefail

REPO="szTheory/threadline"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE_DIR="$(dirname "$SCRIPT_DIR")"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
RAW="$PHASE_DIR/raw/local"
SCRATCH="${TMPDIR:-/tmp}"
mkdir -p "$RAW"
cd "$ROOT"

PLT=".dialyzer"
PLT_BACKUP=".dialyzer.214-warm"
LIVE_CMD='MIX_ENV=test mix test test/threadline/dialyzer_slice_contract_test.exs --only live_dialyzer'
SLOWEST_CMD='MIX_ENV=test mix test --slowest 25'
# the command the :live_dialyzer test shells out to (bin/verify-dialyzer-slice)
RAW_DIALYZER_CMD='MIX_ENV=dev mix dialyzer --no-check --format raw --ignore-exit-status'
# the CI verify-dialyzer cache-miss step's command
PLT_BUILD_CMD='MIX_ENV=dev mix dialyzer --plt'
COLD_LABEL='cold PLT, warm dev compile: .dialyzer moved aside for the run (any PLT built meanwhile is deleted and the warm one restored); _build/dev kept, unlike CI test lanes which also lack a warm dev _build'

scrub() {
  sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g' \
    | sed -e "s#${ROOT}#<repo>#g" -e "s#${HOME}#<home>#g" -e "s#$(whoami)#<user>#g"
}

# timed <cmd> <outfile>: runs cmd under bash -c with stdout+stderr to outfile
# (scrubbed); prints "<real seconds> <exit code>"
timed() {
  local cmd="$1" out="$2" tfile rc
  tfile="$(mktemp "$SCRATCH/time.XXXXXX")"
  set +e
  { /usr/bin/time -p bash -c "$cmd 2>&1" > "$out.rawcap" ; } 2> "$tfile"
  rc=$?
  set -e
  scrub < "$out.rawcap" > "$out"
  rm -f "$out.rawcap"
  printf '%s %s\n' "$(awk '/^real/{print $2}' "$tfile")" "$rc"
  rm -f "$tfile"
}

psql_test() {
  PGPASSWORD=postgres psql -h "${DB_HOST:-localhost}" -p "${DB_PORT:-5432}" -U postgres \
    -d threadline_test -tAc "$1" 2>/dev/null
}

step_env() {
  local cpu stale server
  if [ "$(uname -s)" = Darwin ]; then cpu="$(sysctl -n hw.ncpu)"; else cpu="$(nproc)"; fi
  server="$(psql_test 'show server_version' || echo 'unreachable')"
  stale="$(psql_test "select coalesce(to_regprocedure('public.threadline_capture_changes()')::text, 'absent')" || echo 'unreachable')"
  {
    echo "captured_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "git_head: $(git rev-parse HEAD)"
    echo "os_arch: $(uname -sm)"
    echo "cpu_count: $cpu"
    echo "tool_versions: $(tr '\n' ';' < .tool-versions)"
    echo "elixir_version: |"
    bash -c 'elixir --version' 2>&1 | sed 's/^/  /'
    echo "psql_client: $(psql --version)"
    echo "postgres_server_version (threadline_test): $server"
    echo "stale_public_capture_function (public.threadline_capture_changes()): $stale  [recorded, not fixed]"
    echo "plt_present_at_start: $([ -e "$PLT" ] && echo yes || echo no)"
  } | scrub > "$RAW/env.txt"
}

step_slowest() {
  echo "[slowest] $SLOWEST_CMD" >&2
  local res wall rc
  res="$(timed "$SLOWEST_CMD" "$RAW/slowest-25.txt")"
  wall="${res% *}"; rc="${res#* }"
  summarize_slowest "$wall" "$rc"
}

# summarize_slowest <wall_s> <exit_code>: re-derivable from raw/local/slowest-25.txt
summarize_slowest() {
  python3 -c '
import json, re, sys
t = open(sys.argv[1]).read()
wall, rc, cmd = float(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
line = next((l for l in t.splitlines() if re.search(r"\d+ tests?, \d+ failures?", l)), None)
nums = lambda pat: (int(re.search(pat, line)[1]) if line and re.search(pat, line) else None)
fin = re.search(r"Finished in ([\d.]+) seconds \(([\d.]+)s async, ([\d.]+)s sync\)", t)
top = re.search(r"Top 25 slowest \(([\d.]+)s\), ([\d.]+)% of total time", t)
block = t.split("Top 25 slowest", 1)[1] if "Top 25 slowest" in t else ""
entries = re.findall(r"^\s+\* test .* \((\d+(?:\.\d+)?)ms\) \[", block, re.M)
mc = re.search(r"max_cases: (\d+)", t)
print(json.dumps({
  "command": cmd, "exit_code": rc, "wall_s": wall,
  "summary_line": line,
  "tests": nums(r"(\d+) tests?"), "failures": nums(r"(\d+) failures?"),
  "excluded": nums(r"(\d+) excluded"), "skipped": nums(r"(\d+) skipped"),
  "doctests": nums(r"(\d+) doctests?"),
  "exunit_finished_s": float(fin[1]) if fin else None,
  "async_s": float(fin[2]) if fin else None, "sync_s": float(fin[3]) if fin else None,
  "top25_total_s": float(top[1]) if top else None,
  "top25_pct_of_total": float(top[2]) if top else None,
  "top25_entries_found": len(entries),
  "max_cases": int(mc[1]) if mc else None,
  "note": "--slowest turns on ExUnit trace mode (max_cases: 1), so every test runs serially; wall_s is not the default parallel suite time",
}, indent=2, sort_keys=True))
' "$RAW/slowest-25.txt" "$1" "$2" "$SLOWEST_CMD" > "$RAW/slowest-25.summary.json"
}

restore_plt() {
  if [ -e "$PLT_BACKUP" ]; then
    rm -rf "$PLT"
    mv "$PLT_BACKUP" "$PLT"
    echo "[live-dialyzer] warm PLT restored" >&2
  fi
}

step_live_dialyzer() {
  [ -e "$PLT_BACKUP" ] && { echo "FATAL: $PLT_BACKUP already exists; refusing to run" >&2; exit 1; }
  [ -e "$PLT" ] || { echo "FATAL: no warm $PLT to measure against" >&2; exit 1; }

  echo "[live-dialyzer] warm-up run" >&2
  local warmup warm cold cold_raw plt_build warm_raw
  warmup="$(timed "$LIVE_CMD" "$SCRATCH/live-dialyzer-warmup.txt")"
  echo "[live-dialyzer] warm PLT timed run" >&2
  warm="$(timed "$LIVE_CMD" "$RAW/live-dialyzer-warm.txt")"
  warm_raw="$(timed "$RAW_DIALYZER_CMD" "$RAW/live-dialyzer-warm-raw-dialyzer.txt")"

  echo "[live-dialyzer] cold PLT timed run (moving $PLT aside)" >&2
  mv "$PLT" "$PLT_BACKUP"
  trap restore_plt EXIT INT TERM
  cold="$(timed "$LIVE_CMD" "$RAW/live-dialyzer-cold.txt")"
  # What the shelled Dialyzer command actually does with no PLT (it passes --no-check,
  # which skips the PLT check/build step), then the real cold PLT build cost.
  cold_raw="$(timed "$RAW_DIALYZER_CMD" "$RAW/live-dialyzer-cold-raw-dialyzer.txt")"
  plt_build="$(timed "$PLT_BUILD_CMD" "$RAW/dialyzer-plt-build-cold.txt")"
  restore_plt
  trap - EXIT INT TERM
  [ -e "$PLT" ] && [ ! -e "$PLT_BACKUP" ] || { echo "FATAL: PLT restore check failed" >&2; exit 1; }

  jq -n --arg cmd "$LIVE_CMD" --arg wu "$warmup" --arg w "$warm" --arg c "$cold" \
    --arg wr "$warm_raw" --arg cr "$cold_raw" --arg pb "$plt_build" \
    --arg rawcmd "$RAW_DIALYZER_CMD" --arg pbcmd "$PLT_BUILD_CMD" --arg coldlabel "$COLD_LABEL" \
    --argjson warm_warns "$(grep -c '^{:warn_' "$RAW/live-dialyzer-warm-raw-dialyzer.txt" || true)" \
    --argjson cold_warns "$(grep -c '^{:warn_' "$RAW/live-dialyzer-cold-raw-dialyzer.txt" || true)" '
    def s($x): ($x | split(" ") | .[0] | tonumber);
    def rc($x): ($x | split(" ") | .[1] | tonumber);
    {
      command: ("/usr/bin/time -p bash -c \"" + $cmd + "\""),
      warm_s: s($w), warm_exit: rc($w),
      cold_plt_s: s($c), cold_plt_exit: rc($c),
      warmup_s: s($wu), warmup_exit: rc($wu),
      raw_dialyzer_command: $rawcmd,
      raw_dialyzer_warm_s: s($wr), raw_dialyzer_warm_exit: rc($wr), raw_dialyzer_warm_warn_lines: $warm_warns,
      raw_dialyzer_cold_plt_s: s($cr), raw_dialyzer_cold_plt_exit: rc($cr), raw_dialyzer_cold_plt_warn_lines: $cold_warns,
      plt_build_command: $pbcmd,
      plt_build_cold_s: s($pb), plt_build_cold_exit: rc($pb),
      labels: {
        warm_s: "warm PLT, warm dev compile: second consecutive run with .dialyzer present",
        cold_plt_s: $coldlabel
      },
      procedure: "warm-up run, timed warm run, timed raw Dialyzer command (warm); then mv .dialyzer .dialyzer.214-warm with an EXIT/INT/TERM trap, timed cold run, timed raw Dialyzer command (no PLT), timed mix dialyzer --plt (fresh PLT build), rm -rf .dialyzer, mv .dialyzer.214-warm .dialyzer",
      outputs: {warm: "raw/local/live-dialyzer-warm.txt", cold: "raw/local/live-dialyzer-cold.txt",
        warm_raw_dialyzer: "raw/local/live-dialyzer-warm-raw-dialyzer.txt",
        cold_raw_dialyzer: "raw/local/live-dialyzer-cold-raw-dialyzer.txt",
        plt_build_cold: "raw/local/dialyzer-plt-build-cold.txt"}
    }' > "$RAW/live-dialyzer.json"
  rm -f "$SCRATCH/live-dialyzer-warmup.txt"
  annotate_live_dialyzer
}

# annotate_live_dialyzer: record whether the no-PLT run actually analyzed anything
annotate_live_dialyzer() {
  local err tmp
  err="$(grep -m1 -o 'Could not read PLT file.*' "$RAW/live-dialyzer-cold-raw-dialyzer.txt" || true)"
  tmp="$(mktemp "$SCRATCH/ld.XXXXXX")"
  jq --arg err "$err" --arg coldlabel "$COLD_LABEL" '.labels.cold_plt_s = $coldlabel | . + {
    cold_plt_dialyzer_error: (if $err == "" then null else $err end),
    cold_plt_vacuous_pass: ($err != "" and .cold_plt_exit == 0),
    finding: (if $err != "" and .cold_plt_exit == 0 then
      "With no PLT the shelled command (--no-check skips the PLT build) fails with \"Could not read PLT file\", --ignore-exit-status turns that into exit 0 with no warning lines, and the :live_dialyzer test passes without analyzing anything. cold_plt_s is therefore NOT the cost of a cold-PLT Dialyzer analysis; plt_build_cold_s is the local cost of building the PLT."
      else null end)
  }' "$RAW/live-dialyzer.json" > "$tmp"
  mv "$tmp" "$RAW/live-dialyzer.json"
}

step_ci_steps() {
  local id
  id="$(gh run list --repo "$REPO" --workflow ci.yml --event push --branch main --status success --limit 1 --json databaseId --jq '.[0].databaseId')"
  echo "[ci-steps] gh run view $id --json jobs" >&2
  gh run view "$id" --repo "$REPO" --json databaseId,headSha,createdAt,jobs \
    | jq -S --arg cmd "gh run view $id --repo $REPO --json databaseId,headSha,createdAt,jobs" '{
        command: $cmd,
        note: "GitHub-hosted runner timings; different hardware from raw/local captures",
        run_id: .databaseId, head_sha: .headSha, created_at: .createdAt,
        jobs: [.jobs[] | select(.name | test("test"; "i")) | {
          name, conclusion, startedAt, completedAt,
          steps: [.steps[] | {name, number, conclusion, startedAt, completedAt}]
        }]
      }' | scrub > "$RAW/ci-test-steps.json"
}

STEPS=("$@")
[ ${#STEPS[@]} -gt 0 ] || STEPS=(env slowest live-dialyzer ci-steps)
for s in "${STEPS[@]}"; do
  case "$s" in
    env) step_env ;;
    slowest) step_slowest ;;
    slowest-summary) summarize_slowest "$(jq -r .wall_s "$RAW/slowest-25.summary.json")" "$(jq -r .exit_code "$RAW/slowest-25.summary.json")" ;;
    live-dialyzer) step_live_dialyzer ;;
    live-dialyzer-annotate) annotate_live_dialyzer ;;
    ci-steps) step_ci_steps ;;
    *) echo "unknown step: $s" >&2; exit 2 ;;
  esac
done
echo "[done] $RAW" >&2
