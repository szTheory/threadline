#!/usr/bin/env bash
# Re-runnable mutation-control runner (D-20).
#
# Usage: mutation-control.sh [--inverted GREEN_FILE] [--max-runs M] PATCH RED_FILE [K]
#
# Applies PATCH (lib/-only), proves RED_FILE goes red on K of K seeds
# (default 5), reverses the patch, and proves RED_FILE is green again.
# In --inverted mode (for a property that should stay green under the
# mutant while a separate DB-agreement file goes red) GREEN_FILE must
# exit 0 on every seed instead.
#
# Never commits, stashes, checks out, or resets. Refuses to start on a
# dirty lib/, and reverse-applies the patch via a trap so a failure
# midway never leaves a mutated lib/ behind.
set -euo pipefail

ORIG_PWD="$(pwd)"

INVERTED_GREEN_FILE=""
MAX_RUNS=""
POSITIONAL=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --inverted)
      INVERTED_GREEN_FILE="$2"
      shift 2
      ;;
    --max-runs)
      MAX_RUNS="$2"
      shift 2
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if [ "${#POSITIONAL[@]}" -lt 2 ]; then
  echo "Usage: mutation-control.sh [--inverted GREEN_FILE] [--max-runs M] PATCH RED_FILE [K]" >&2
  exit 2
fi

PATCH="${POSITIONAL[0]}"
RED_FILE="${POSITIONAL[1]}"
K="${POSITIONAL[2]:-5}"

# Resolve to absolute paths against the caller's cwd before we cd to the
# repo root, so relative paths passed on the command line keep working.
case "$PATCH" in
  /*) : ;;
  *) PATCH="$ORIG_PWD/$PATCH" ;;
esac

if [ -n "$INVERTED_GREEN_FILE" ]; then
  case "$INVERTED_GREEN_FILE" in
    /*) : ;;
    *) INVERTED_GREEN_FILE="$ORIG_PWD/$INVERTED_GREEN_FILE" ;;
  esac
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

if [ ! -f "$PATCH" ]; then
  echo "FATAL: patch file not found: $PATCH" >&2
  exit 2
fi

# RED_FILE / GREEN_FILE are passed to `mix test` as-is: relative to the repo
# root (the normal way `mix test path/to/file.exs` is invoked), so they are
# left untouched.

# Refuse on a dirty lib/ (index or working tree).
if ! git diff --quiet -- lib || ! git diff --cached --quiet -- lib; then
  echo "FATAL: lib/ is dirty. Commit or revert lib/ changes before running a mutation control." >&2
  exit 2
fi

# Refuse unless every patched path is under lib/.
NUMSTAT="$(git apply --numstat "$PATCH")"
while IFS=$'\t' read -r _add _del path; do
  [ -z "$path" ] && continue
  case "$path" in
    lib/*) : ;;
    *)
      echo "FATAL: patch touches a non-lib/ path: $path" >&2
      exit 2
      ;;
  esac
done <<<"$NUMSTAT"

git apply --check "$PATCH"
git apply "$PATCH"

REVERTED=0
revert_once() {
  if [ "$REVERTED" -eq 0 ]; then
    REVERTED=1
    git apply -R "$PATCH" 2>/dev/null || true
  fi
}
trap revert_once EXIT INT TERM

TMP_BASE="${TMPDIR:-/tmp}"
RUNS_DIR="$(mktemp -d "$TMP_BASE/mutation-control.XXXXXX")"

run_one() {
  local file="$1" seed="$2" out="$3"
  set +e
  mix test "$file" --seed "$seed" >"$out" 2>&1
  local status=$?
  set -e
  echo "$status"
}

extract_n() {
  grep -oE 'after [0-9]+ successful run' "$1" | head -1 | grep -oE '[0-9]+' || true
}

extract_counterexample() {
  # Everything from "Failed with generated values" through the next blank
  # line (StreamData's shrunk-counterexample block).
  awk '/Failed with generated values/{flag=1} flag{print} flag && /^\s*$/{exit}' "$1"
}

extract_failure_headers() {
  grep -E '^\s*[0-9]+\) ' "$1" || true
}

SEED_RESULTS=()
FIRST_COUNTEREXAMPLE=""
N_VALUES=()
ANY_SURVIVED=0

for seed in $(seq 1 "$K"); do
  out_red="$RUNS_DIR/red-seed-$seed.log"
  status="$(run_one "$RED_FILE" "$seed" "$out_red")"

  if [ "$status" -eq 0 ]; then
    ANY_SURVIVED=1
  fi

  n="$(extract_n "$out_red")"
  counterexample="$(extract_counterexample "$out_red")"
  [ -z "$counterexample" ] && counterexample="$(extract_failure_headers "$out_red")"
  first_line="$(printf '%s\n' "$counterexample" | sed -n '1p')"

  if [ -n "$n" ]; then
    N_VALUES+=("$n")
  fi

  if [ "$seed" -eq 1 ]; then
    FIRST_COUNTEREXAMPLE="$counterexample"
  fi

  SEED_RESULTS+=("seed=$seed exit=$status n=${n:-n/a} first=\"$first_line\"")

  if [ -n "$INVERTED_GREEN_FILE" ]; then
    out_green="$RUNS_DIR/green-seed-$seed.log"
    green_status="$(run_one "$INVERTED_GREEN_FILE" "$seed" "$out_green")"
    if [ "$green_status" -ne 0 ]; then
      echo "FATAL: --inverted GREEN_FILE failed at seed $seed (expected green)" >&2
      cat "$out_green" >&2
      exit 1
    fi
  fi
done

if [ "$ANY_SURVIVED" -eq 1 ]; then
  echo "FATAL: RED_FILE exited 0 on at least one seed — the mutant survived." >&2
  exit 1
fi

# Re-run seed 1 and require a byte-identical counterexample.
out_reproduce="$RUNS_DIR/red-seed-1-reproduce.log"
run_one "$RED_FILE" 1 "$out_reproduce" >/dev/null
reproduce_counterexample="$(extract_counterexample "$out_reproduce")"
[ -z "$reproduce_counterexample" ] && reproduce_counterexample="$(extract_failure_headers "$out_reproduce")"

if [ "$reproduce_counterexample" != "$FIRST_COUNTEREXAMPLE" ]; then
  echo "FATAL: seed 1 did not reproduce the same counterexample on a second run." >&2
  exit 1
fi

# Disarm the trap and reverse-apply explicitly, then require green + clean lib/.
REVERTED=1
git apply -R "$PATCH"
trap - EXIT INT TERM

out_restored="$RUNS_DIR/restored-seed-1.log"
restored_status="$(run_one "$RED_FILE" 1 "$out_restored")"
if [ "$restored_status" -ne 0 ]; then
  echo "FATAL: RED_FILE did not pass at seed 1 after reverting the patch." >&2
  cat "$out_restored" >&2
  exit 1
fi

if ! git diff --quiet -- lib; then
  echo "FATAL: lib/ is not clean after reverting the patch." >&2
  exit 1
fi

# Weakness check.
WEAK=0
if [ -n "$MAX_RUNS" ] && [ "${#N_VALUES[@]}" -gt 0 ]; then
  SORTED=($(printf '%s\n' "${N_VALUES[@]}" | sort -n))
  COUNT="${#SORTED[@]}"
  MID=$((COUNT / 2))
  if [ $((COUNT % 2)) -eq 1 ]; then
    MEDIAN="${SORTED[$MID]}"
  else
    MEDIAN=$(( (${SORTED[$((MID - 1))]} + ${SORTED[$MID]}) / 2 ))
  fi
  HALF=$((MAX_RUNS / 2))
  if [ "$MEDIAN" -gt "$HALF" ]; then
    WEAK=1
  fi
fi

# Scrub absolute paths, $HOME and whoami before printing (repo-hygiene guard).
HOME_DIR="${HOME:-}"
USER_NAME="$(whoami)"

scrub() {
  local text="$1"
  text="${text//$REPO_ROOT/<repo>}"
  if [ -n "$HOME_DIR" ]; then
    text="${text//$HOME_DIR/<home>}"
  fi
  text="${text//$USER_NAME/<user>}"
  printf '%s' "$text"
}

PATCH_DIFF="$(cat "$PATCH")"
COMMAND="mix test $RED_FILE --seed <seed>"

REPORT="$(
  {
    echo "## Mutation control: $(basename "$PATCH")"
    echo
    echo "\`\`\`diff"
    echo "$PATCH_DIFF"
    echo "\`\`\`"
    echo
    echo "Command: \`$COMMAND\`"
    echo
    echo "\`\`\`text"
    for line in "${SEED_RESULTS[@]}"; do
      echo "$line"
    done
    echo "\`\`\`"
    echo
    echo "Kill rate: ${K}/${K}"
    echo "Reproduce: seed 1 reproduces the same counterexample on a second run."
    echo "Green after restore: RED_FILE passes at seed 1 after reverting the patch; \`git diff --quiet -- lib\` is clean."
    if [ "$WEAK" -eq 1 ]; then
      echo
      echo "WEAK: median after-N-successful-runs exceeds max_runs/2 (${MAX_RUNS})."
    fi
  }
)"

scrub "$REPORT"
echo

if [ "$WEAK" -eq 1 ]; then
  exit 1
fi

exit 0
