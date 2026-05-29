#!/usr/bin/env bash
set -euo pipefail

EXAMPLE="$(cd "$(dirname "$0")/.." && pwd)"
E2E_DIR="$EXAMPLE/e2e"
PORT="${PORT:-4002}"
HOST="${E2E_HOST:-127.0.0.1}"
BASE_URL="${E2E_BASE_URL:-http://${HOST}:${PORT}}"
LOG_FILE="${TMPDIR:-/tmp}/threadline_phoenix_e2e.log"

export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-5432}"
export MIX_ENV=test
export THREADLINE_E2E=1
export PORT
export E2E_BASE_URL="$BASE_URL"

if command -v lsof >/dev/null 2>&1; then
  lsof -ti ":${PORT}" | xargs kill -9 2>/dev/null || true
fi

cd "$EXAMPLE"
mix deps.get --only test
mix compile
mix ecto.create --quiet -r ThreadlinePhoenix.Repo 2>/dev/null || true
mix ecto.migrate --quiet
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
}
trap cleanup EXIT

port_open() {
  (echo >/dev/tcp/"${HOST}"/"${PORT}") >/dev/null 2>&1
}

: >"$LOG_FILE"
cd "$EXAMPLE"
mix phx.server >>"$LOG_FILE" 2>&1 &
PHX_PID=$!

ready=0
for _ in $(seq 1 120); do
  if port_open; then
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
