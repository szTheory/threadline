#!/usr/bin/env bash
set -euo pipefail

EXAMPLE="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$EXAMPLE/../.." && pwd)"
E2E_DIR="$EXAMPLE/e2e"
REQUESTED_PORT="${PORT:-${THREADLINE_E2E_PORT:-}}"
PORT="${REQUESTED_PORT:-4002}"
HOST="${E2E_HOST:-127.0.0.1}"
LOG_FILE="${TMPDIR:-/tmp}/threadline_phoenix_e2e.log"

export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-5432}"
export MIX_ENV=test
export THREADLINE_E2E=1

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
  if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$ROOT" clean -fX -- priv/threadline_exports examples/threadline_phoenix/priv/threadline_exports >/dev/null 2>&1 || true
  else
    rm -rf "$EXAMPLE/priv/threadline_exports"
  fi
}

PORT="$(choose_free_port)"
BASE_URL="${E2E_BASE_URL:-http://${HOST}:${PORT}}"
export PORT
export E2E_BASE_URL="$BASE_URL"

cleanup_exports

cd "$EXAMPLE"
mix deps.get --only test
mix compile
mix ecto.create --quiet -r ThreadlinePhoenix.Repo 2>/dev/null || true
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
    echo "phx.server exited before port ${PORT} opened; log follows:" >&2
    tail -80 "$LOG_FILE" >&2 || true
    exit 1
  fi
  sleep 1
done

if [[ "$ready" -ne 1 ]]; then
  echo "Timed out waiting for port ${PORT}; log follows:" >&2
  tail -80 "$LOG_FILE" >&2 || true
  exit 1
fi

sleep 2
curl --max-time 60 -fsS "${BASE_URL}/users/log_in" >/dev/null

cd "$E2E_DIR"
npm test
