#!/usr/bin/env bash
set -euo pipefail

EXAMPLE="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$EXAMPLE/../.." && pwd)"
E2E_DIR="$EXAMPLE/e2e"
REQUESTED_PORT="${PORT:-${THREADLINE_E2E_PORT:-}}"
PORT="${REQUESTED_PORT:-4002}"
HOST="${E2E_HOST:-127.0.0.1}"
LOG_FILE="${TMPDIR:-/tmp}/threadline_phoenix_e2e.log"
BASE_URL="${E2E_BASE_URL:-}"
CURL_BIN="${THREADLINE_E2E_CURL:-curl}"

export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-5432}"
export MIX_ENV=test
export THREADLINE_E2E=1

EVIDENCE_MODE="${THREADLINE_E2E_EVIDENCE:-0}"
PREVIEW_MODE="${THREADLINE_E2E_PREVIEW:-0}"
STOP_PREVIEW="${THREADLINE_E2E_STOP_PREVIEW:-0}"
EVIDENCE_ROOT=""
EVIDENCE_DATABASE=""
FORWARDED_ARGS=()
for runner_arg in "$@"; do
  case "$runner_arg" in
    --preview) PREVIEW_MODE=1 ;;
    --stop-preview) STOP_PREVIEW=1 ;;
    *) FORWARDED_ARGS+=("$runner_arg") ;;
  esac
done
set -- "${FORWARDED_ARGS[@]}"

port_listening() {
  local port="$1"

  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1
    return $?
  fi

  if command -v nc >/dev/null 2>&1; then
    nc -z "${HOST}" "${port}" >/dev/null 2>&1
    return $?
  fi

  (echo >/dev/tcp/"${HOST}"/"${port}") >/dev/null 2>&1
}

server_ready() {
  local port="$1"

  if command -v curl >/dev/null 2>&1; then
    curl --max-time 1 -fsS "http://${HOST}:${port}/users/log_in" >/dev/null 2>&1
    return $?
  fi

  port_listening "${port}"
}

# Single log-tail diagnostic mechanism for every preflight failure path. Phase
# 198 (D-18) added a second preflight check; factoring this out keeps ONE way to
# fail loudly with the boot log rather than two copies drifting apart.
fail_with_log() {
  echo "$1" >&2
  tail -80 "$LOG_FILE" >&2 || true
  exit 1
}

loopback_host() {
  case "${1,,}" in
    localhost|127.0.0.1|::1|\[::1\]) return 0 ;;
    *) return 1 ;;
  esac
}

evidence_preflight() {
  local partition="${MIX_TEST_PARTITION:-}" db_check marker_dir marker output_parent receipt expected_commits actual_commits
  [[ "$EVIDENCE_MODE" == "1" ]] || return 0
  [[ -n "$partition" && "$partition" =~ ^operator_[A-Za-z0-9_]+$ ]] || {
    echo "Evidence mode requires a fresh MIX_TEST_PARTITION matching operator_<unique-id>." >&2
    return 1
  }
  loopback_host "$DB_HOST" || { echo "Evidence mode refuses non-loopback DB_HOST='$DB_HOST'." >&2; return 1; }
  [[ "$DB_PORT" =~ ^[0-9]+$ && "$DB_PORT" -ge 1 && "$DB_PORT" -le 65535 ]] || {
    echo "Evidence mode requires a valid local DB_PORT." >&2; return 1;
  }
  [[ "$HOST" == "127.0.0.1" ]] || { echo "Evidence mode binds only to 127.0.0.1; got HOST='$HOST'." >&2; return 1; }
  [[ "$PORT" =~ ^[0-9]+$ && "$PORT" -ge 1 && "$PORT" -le 65535 ]] || {
    echo "Evidence mode requires a valid local HTTP port." >&2; return 1;
  }
  [[ -z "$BASE_URL" || "$BASE_URL" == "http://127.0.0.1:${PORT}" || "$BASE_URL" == "http://localhost:${PORT}" ]] || {
    echo "Evidence mode refuses non-loopback or mismatched E2E_BASE_URL='$BASE_URL'." >&2; return 1;
  }
  [[ -z "${DATABASE_URL:-}" && -z "${DEMO_ALLOW_RESET:-}" ]] || {
    echo "Evidence mode refuses DATABASE_URL and DEMO_ALLOW_RESET overrides." >&2; return 1;
  }
  grep -Fq 'database: "threadline_phoenix_test#{System.get_env("MIX_TEST_PARTITION")}"' "$EXAMPLE/config/test.exs" || {
    echo "Evidence mode could not verify the exact test database derivation in config/test.exs." >&2; return 1;
  }
  receipt="$ROOT/.planning/phases/238-current-main-preview-and-acceptance-baseline/238-ISOLATION-RECEIPT.json"
  [[ -f "$receipt" ]] || { echo "Evidence mode requires the orchestrator isolation receipt." >&2; return 1; }
  node -e '
    const fs = require("node:fs"), crypto = require("node:crypto");
    const [path, root, branch] = process.argv.slice(1), r = JSON.parse(fs.readFileSync(path, "utf8"));
    if (r.worktree !== root || r.branch !== branch || !r.copied_context_sha256) throw new Error("Isolation receipt root, branch or copied context does not match candidate");
    for (const [file, copied] of Object.entries(r.copied_context_sha256)) {
      const expected = file === ".planning/config.json" && r.isolated_config_override ? r.isolated_config_override.active_sha256 : copied;
      const actual = crypto.createHash("sha256").update(fs.readFileSync(root + "/" + file)).digest("hex");
      if (actual !== expected) throw new Error("Copied isolation context changed: " + file);
    }
  ' "$receipt" "$ROOT" "$(git -C "$ROOT" branch --show-current)" || return 1
  THREADLINE_E2E_BASE_SHA="$(node -e 'process.stdout.write(JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8")).base_sha || "")' "$receipt")"
  [[ "$THREADLINE_E2E_BASE_SHA" =~ ^[a-f0-9]{40}$ ]] || { echo "Isolation receipt has no valid immutable base SHA." >&2; return 1; }
  [[ "$(git -C "$ROOT" rev-parse --show-toplevel)" == "$ROOT" ]] || { echo "Evidence runner cwd is not the isolated repository root." >&2; return 1; }
  git -C "$ROOT" merge-base --is-ancestor "$THREADLINE_E2E_BASE_SHA" HEAD || {
    echo "Evidence candidate HEAD is not descended from the isolation receipt base." >&2; return 1;
  }
  expected_commits="$(node -e 'const r=JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8")); process.stdout.write((r.expected_task_commits || []).join("\n"))' "$receipt")"
  actual_commits="$(git -C "$ROOT" rev-list --first-parent --reverse "$THREADLINE_E2E_BASE_SHA..HEAD")"
  [[ "$actual_commits" == "$expected_commits" ]] || {
    echo "Evidence candidate ancestry differs from the task commit sequence in the isolation receipt." >&2
    echo "Expected: ${expected_commits:-<none>}" >&2; echo "Actual: ${actual_commits:-<none>}" >&2; return 1;
  }
  export THREADLINE_E2E_BASE_SHA
  EVIDENCE_DATABASE="threadline_phoenix_test${partition}"
  [[ ${#EVIDENCE_DATABASE} -le 63 ]] || { echo "Evidence database name exceeds PostgreSQL's 63-byte identifier limit." >&2; return 1; }
  [[ "${DB_USERNAME:-postgres}" == "postgres" && "${DB_PASSWORD:-postgres}" == "postgres" ]] || {
    echo "Evidence target credentials must match config/test.exs." >&2; return 1;
  }
  command -v psql >/dev/null 2>&1 || { echo "Evidence mode requires psql to prove target ownership before reset." >&2; return 1; }
  db_check=$(PGPASSWORD="${DB_PASSWORD:-postgres}" psql -X -h "$DB_HOST" -p "$DB_PORT" -U "${DB_USERNAME:-postgres}" -d postgres -v ON_ERROR_STOP=1 -Atqc "SELECT 1 FROM pg_database WHERE datname = '${EVIDENCE_DATABASE}'" 2>&1) || {
    echo "Evidence mode could not inspect the local PostgreSQL target; refusing reset: $db_check" >&2; return 1;
  }
  [[ -z "$db_check" ]] || { echo "Evidence mode refuses existing database '$EVIDENCE_DATABASE'; target is not owned by this run." >&2; return 1; }

  marker_dir="${THREADLINE_E2E_PARTITION_REGISTRY:-${TMPDIR:-/tmp}/threadline-e2e-evidence-partitions}"
  mkdir -p "$marker_dir"
  marker="$marker_dir/${EVIDENCE_DATABASE}.used"
  ( set -o noclobber; : > "$marker" ) 2>/dev/null || {
    echo "Evidence mode refuses reused partition '$partition' (registry: $marker_dir)." >&2; return 1;
  }

  EVIDENCE_ROOT="$E2E_DIR/artifacts/operator-evidence/$partition"
  output_parent="$(dirname "$EVIDENCE_ROOT")"
  mkdir -p "$output_parent"
  [[ ! -e "$EVIDENCE_ROOT" ]] || { echo "Evidence output already exists for '$partition': $EVIDENCE_ROOT" >&2; return 1; }
  export THREADLINE_E2E_EVIDENCE_ROOT="$EVIDENCE_ROOT"
  export npm_config_cache="${TMPDIR:-/tmp}/threadline-npm-cache-$partition"
  export HEX_HOME="${TMPDIR:-/tmp}/threadline-hex-cache-$partition"
  export PLAYWRIGHT_BROWSERS_PATH="${THREADLINE_E2E_PLAYWRIGHT_CACHE:-${TMPDIR:-/tmp}/threadline-playwright-cache}"
  mkdir -p "$npm_config_cache" "$HEX_HOME" "$PLAYWRIGHT_BROWSERS_PATH"
  [[ -w "$npm_config_cache" ]] || { echo "Evidence mode npm cache is not writable: $npm_config_cache" >&2; return 1; }
  [[ -w "$HEX_HOME" ]] || { echo "Evidence mode Hex cache is not writable: $HEX_HOME" >&2; return 1; }
  [[ -w "$PLAYWRIGHT_BROWSERS_PATH" ]] || { echo "Evidence mode browser cache is not writable: $PLAYWRIGHT_BROWSERS_PATH" >&2; return 1; }
  mkdir -p "$EVIDENCE_ROOT"
  printf '{"partition":"%s","database":"%s","host":"%s","port":%s,"mode":"evidence","base_sha":"%s","candidate_head":"%s"}\n' \
    "$partition" "$EVIDENCE_DATABASE" "$DB_HOST" "$DB_PORT" "$THREADLINE_E2E_BASE_SHA" "$(git -C "$ROOT" rev-parse HEAD)" > "$EVIDENCE_ROOT/run.json"
}

stop_preview() {
  local state pid
  state="${THREADLINE_E2E_PREVIEW_STATE:-${TMPDIR:-/tmp}/threadline-e2e-preview-${MIX_TEST_PARTITION:-}.json}"
  [[ -f "$state" ]] || { echo "No preview state found at $state." >&2; return 1; }
  pid="$(sed -n 's/.*"pid":[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$state")"
  [[ -n "$pid" && "$pid" != "$$" ]] || { echo "Preview state has no valid process ID." >&2; return 1; }
  if kill -0 "$pid" 2>/dev/null; then kill "$pid"; fi
  rm -f "$state"
  echo "Stopped evidence preview process $pid."
}

if [[ "$STOP_PREVIEW" == "1" ]]; then
  stop_preview
  exit $?
fi

if [[ "$PREVIEW_MODE" == "1" && "$EVIDENCE_MODE" != "1" ]]; then
  echo "THREADLINE_E2E_PREVIEW=1 requires THREADLINE_E2E_EVIDENCE=1." >&2
  exit 1
fi

if [[ "$EVIDENCE_MODE" == "1" ]]; then
  evidence_preflight || exit 1
  if [[ "${THREADLINE_E2E_EVIDENCE_PREFLIGHT_ONLY:-0}" == "1" ]]; then exit 0; fi
fi

# Operator-surface mount preflight (Phase 198, D-18). /audit sits behind the
# example app's :operator_auth pipeline, so an unauthenticated request is
# EXPECTED to redirect (3xx) to the login page — that redirect proves the mount
# is routed and alive. A 4xx/5xx (or no response) means the operator surface is
# broken, and without this check hundreds of Playwright tests would each burn
# their own 120s timeout discovering the same thing.
#
# Phase 199 hardening. The status-class check alone was known-insufficient and said so:
# a future auth change returning "200 with an empty shell" on a BROKEN mount would have
# passed, and any 3xx counted even when it pointed somewhere other than login. Both
# branches now have to prove something about the response, not just its status class.
operator_surface_ready() {
  local response code body headers location location_count

  [[ -n "$BASE_URL" ]] || {
    echo "E2E_BASE_URL is empty; cannot validate the operator redirect origin." >&2
    return 1
  }

  command -v "$CURL_BIN" >/dev/null 2>&1 || return 0

  # -D - writes headers to stdout ahead of the body, so one request yields status,
  # Location, and body together. A redirect is NOT followed: the redirect itself is the
  # evidence we want, and following it would land us on the login page and assert nothing
  # about /audit.
  response=$("$CURL_BIN" --max-time 30 -sS -D - -o - -w '\n__HTTP_CODE__%{http_code}' \
    "${BASE_URL}/audit" 2>/dev/null || echo '__HTTP_CODE__000')

  code=${response##*__HTTP_CODE__}
  body=${response%__HTTP_CODE__*}

  case "$code" in
    3??)
      headers=${body%%$'\r\n\r\n'*}
      location_count=$(printf '%s\n' "$headers" | tr -d '\r' | awk 'tolower($0) ~ /^location:[[:space:]]*/ { count++ } END { print count+0 }')

      if [[ "$location_count" -ne 1 ]]; then
        echo "GET ${BASE_URL}/audit returned ${location_count} Location headers; expected exactly one." >&2
        return 1
      fi

      location=$(printf '%s\n' "$headers" | tr -d '\r' | awk 'tolower($0) ~ /^location:[[:space:]]*/ { sub(/^[^:]+:[[:space:]]*/, ""); print }')

      if login_target_valid "$BASE_URL" "$location"; then
        return 0
      fi

      echo "GET ${BASE_URL}/audit redirected to '${location:-<no Location header>}', not the local login page." >&2
      echo "A 3xx only proves the mount is alive when scheme, host, and effective port match." >&2
      return 1
      ;;
    2??)
      # An authenticated-or-public 200 must actually carry the operator shell. These two
      # markers are asserted by the Playwright suite itself (`.threadline-ui`, `#tl-main`),
      # so a 200 without them is a shell that renders nothing the tests can drive.
      if printf '%s' "$body" | grep -q 'threadline-ui' && printf '%s' "$body" | grep -q 'tl-main'; then
        return 0
      fi

      echo "GET ${BASE_URL}/audit returned HTTP ${code} but the body carries no operator surface." >&2
      echo "Expected the '.threadline-ui' shell and '#tl-main' region; got a 200 with neither," >&2
      echo "which is a broken mount answering successfully — exactly what this check exists to catch." >&2
      return 1
      ;;
    *)
      echo "GET ${BASE_URL}/audit returned HTTP ${code} (expected 2xx with the operator shell, or a 3xx redirect to login)." >&2
      return 1
      ;;
  esac
}

url_origin() {
  local url="$1" scheme authority host port rest

  [[ "$url" != *'\\'* && "$url" != *$'\r'* && "$url" != *$'\n'* && "$url" != *$'\t'* && "$url" != *' '* ]] || return 1
  [[ "$url" =~ ^(https?)://([^/?#]+) ]] || return 1

  scheme="${BASH_REMATCH[1],,}"
  authority="${BASH_REMATCH[2]}"
  [[ "$authority" != *'@'* ]] || return 1

  if [[ "$authority" =~ ^([A-Za-z0-9.-]+):([0-9]+)$ ]]; then
    host="${BASH_REMATCH[1],,}"
    port="${BASH_REMATCH[2]}"
  elif [[ "$authority" =~ ^[A-Za-z0-9.-]+$ ]]; then
    host="${authority,,}"
    [[ "$scheme" == "https" ]] && port=443 || port=80
  else
    return 1
  fi

  [[ -n "$host" && "$port" -ge 1 && "$port" -le 65535 ]] || return 1
  printf '%s|%s|%s' "$scheme" "$host" "$port"
}

login_target_valid() {
  local base="$1" target="$2" base_origin target_origin rest path

  [[ -n "$target" && "$target" != *'\\'* && "$target" != *$'\r'* && "$target" != *$'\n'* && "$target" != *$'\t'* && "$target" != *' '* ]] || return 1

  if [[ "$target" == /* ]]; then
    [[ "$target" != //* ]] || return 1
    path="${target%%[?#]*}"
    [[ "$path" != *'%'* ]] || return 1
    [[ "$path" == "/users/log_in" ]]
    return
  fi

  base_origin=$(url_origin "$base") || return 1
  target_origin=$(url_origin "$target") || return 1
  [[ "$base_origin" == "$target_origin" ]] || return 1

  rest="${target#*://}"
  rest="${rest#*/}"
  if [[ "$target" != *://*/* ]]; then
    path="/"
  else
    path="/${rest%%[?#]*}"
  fi

  [[ "$path" != *'%'* ]] || return 1
  [[ "$path" == "/users/log_in" ]]
}

if [[ "${THREADLINE_E2E_PREFLIGHT_ONLY:-0}" == "1" ]]; then
  if operator_surface_ready; then
    if [[ -n "${THREADLINE_E2E_PLAYWRIGHT_SENTINEL:-}" ]]; then
      "$THREADLINE_E2E_PLAYWRIGHT_SENTINEL"
    fi
    exit 0
  fi
  exit 1
fi

port_owner() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"${1}" -sTCP:LISTEN 2>/dev/null || true
  fi
}

choose_free_port() {
  local candidate

  if ! port_listening "${PORT}"; then
    echo "${PORT}"
    return
  fi

  if [[ -n "${REQUESTED_PORT}" ]]; then
    echo "Requested E2E port ${PORT} is already in use." >&2
    port_owner "${PORT}" >&2
    echo "Set THREADLINE_E2E_PORT or PORT to a free port and rerun." >&2
    exit 1
  fi

  for candidate in $(seq 4100 4199); do
    if ! port_listening "${candidate}"; then
      echo "${candidate}"
      return
    fi
  done

  echo "No free E2E port found in 4100-4199." >&2
  exit 1
}

cleanup_exports() {
  local generated_file
  if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    while IFS= read -r -d '' generated_file; do
      rm -f -- "$ROOT/$generated_file"
    done < <(git -C "$ROOT" ls-files --others --ignored --exclude-standard -z -- priv/threadline_exports examples/threadline_phoenix/priv/threadline_exports)
  else
    rm -rf "$EXAMPLE/priv/threadline_exports"
  fi
}

PORT="$(choose_free_port)"
BASE_URL="${E2E_BASE_URL:-http://${HOST}:${PORT}}"
if [[ "$EVIDENCE_MODE" == "1" ]]; then
  [[ "$BASE_URL" == "http://127.0.0.1:${PORT}" || "$BASE_URL" == "http://localhost:${PORT}" ]] || {
    echo "Evidence mode refuses non-loopback or mismatched E2E_BASE_URL='$BASE_URL'." >&2; exit 1;
  }
fi
export PORT
export E2E_BASE_URL="$BASE_URL"

PROJECT_ARGS=()
EXPLICIT_PROJECT=0
for runner_arg in "$@"; do
  case "$runner_arg" in --project|--project=*) EXPLICIT_PROJECT=1 ;; esac
done
if [[ "${THREADLINE_E2E_THEME:-}" == "system" && "$EXPLICIT_PROJECT" == "0" ]]; then
  PROJECT_ARGS+=(--project=desktop-chromium-light)
fi

if [[ "${THREADLINE_E2E_ARGUMENTS_ONLY:-0}" == "1" ]]; then
  printf 'npm test --'
  printf ' %q' "${PROJECT_ARGS[@]}" "$@"
  printf '\n'
  exit 0
fi

cleanup_exports

cd "$EXAMPLE"
mix deps.get --only test
# Force the operator-surface router to recompile so the compile-time
# THREADLINE_E2E_THEME theme gate reflects THIS invocation's env. System.get_env
# at compile time is not tracked as a recompilation trigger, so without this a
# switch between the default (:dark) and light (:system) lanes would otherwise
# reuse a stale compiled router. (Phase 168, A11Y-02 part 2.)
touch lib/threadline_phoenix_web/router.ex
mix compile --force
if [[ "$EVIDENCE_MODE" == "1" ]]; then
  mix ecto.create --quiet -r ThreadlinePhoenix.Repo
else
  mix ecto.create --quiet -r ThreadlinePhoenix.Repo 2>/dev/null || true
fi
mix ecto.migrate --quiet
mix demo.reset
mix demo.seed

cd "$E2E_DIR"
if [[ -f package-lock.json ]]; then
  npm ci
else
  npm install
fi
npx playwright install chromium

PHX_PID=""
cleanup() {
  if [[ -n "$PHX_PID" ]] && kill -0 "$PHX_PID" 2>/dev/null; then
    kill "$PHX_PID" 2>/dev/null || true
    wait "$PHX_PID" 2>/dev/null || true
  fi
  cleanup_exports
}
trap cleanup EXIT

: >"$LOG_FILE"
cd "$EXAMPLE"
mix phx.server >>"$LOG_FILE" 2>&1 &
PHX_PID=$!

ready=0
for _ in $(seq 1 120); do
  if server_ready "${PORT}"; then
    ready=1
    break
  fi
  if ! kill -0 "$PHX_PID" 2>/dev/null; then
    fail_with_log "phx.server exited before port ${PORT} opened; log follows:"
  fi
  sleep 1
done

if [[ "$ready" -ne 1 ]]; then
  fail_with_log "Timed out waiting for port ${PORT}; log follows:"
fi

if [[ "$PREVIEW_MODE" == "1" ]]; then
  PREVIEW_STATE="${THREADLINE_E2E_PREVIEW_STATE:-${TMPDIR:-/tmp}/threadline-e2e-preview-${MIX_TEST_PARTITION}.json}"
  printf '{"pid":%s,"url":"%s","database":"%s","partition":"%s"}\n' \
    "$PHX_PID" "$BASE_URL" "$EVIDENCE_DATABASE" "$MIX_TEST_PARTITION" > "$PREVIEW_STATE"
  trap - EXIT
  echo "Evidence preview running at $BASE_URL (pid $PHX_PID; database $EVIDENCE_DATABASE). Stop with THREADLINE_E2E_STOP_PREVIEW=1 and THREADLINE_E2E_PREVIEW_STATE=$PREVIEW_STATE."
  exit 0
fi

sleep 2
curl --max-time 60 -fsS "${BASE_URL}/users/log_in" >/dev/null

# Second preflight (Phase 198, D-18): the login page being up only proves the
# HOST app booted. The suite under test is the operator surface, so refuse to
# start if /audit is not mounted.
if ! operator_surface_ready; then
  fail_with_log "Operator surface preflight failed at ${BASE_URL}/audit; log follows:"
fi

cd "$E2E_DIR"
npm test -- "${PROJECT_ARGS[@]}" "$@"
