#!/usr/bin/env bash
# critic-before-pole.sh — zero-touch BEFORE-pole measurement for the UI critic loop.
#
# One command replaces the manual maintainer checkpoint: boots the seeded example
# app, takes a fresh Tier-B route capture, busts the verdict cache for every
# route cell, and scores the blocking-lens panel on each route. Reads
# ANTHROPIC_API_KEY from the environment or the repo-root .env (gitignored).
#
# Usage:
#   ./critic-before-pole.sh                # capture + score all routes
#   ./critic-before-pole.sh --capture-only # skip scoring (no key needed)
#   ROUTES="actor evidence" ./critic-before-pole.sh   # subset
set -euo pipefail

E2E_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE="$(cd "$E2E_DIR/.." && pwd)"
ROOT="$(cd "$EXAMPLE/../.." && pwd)"
LOG_FILE="${TMPDIR:-/tmp}/threadline_phoenix_before_pole.log"
CACHE_DIR="$ROOT/.planning/critic-verdict-cache"
HOST="${E2E_HOST:-127.0.0.1}"
CAPTURE_ONLY=0
[[ "${1:-}" == "--capture-only" ]] && CAPTURE_ONLY=1
ROUTES_DEFAULT="timeline coverage retention actor evidence"
read -r -a ROUTE_LIST <<<"${ROUTES:-$ROUTES_DEFAULT}"

# Load ANTHROPIC_API_KEY (and friends) from the repo-root .env if not already set.
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  . "$ROOT/.env"
  set +a
fi

if [[ "$CAPTURE_ONLY" -eq 0 && -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "ANTHROPIC_API_KEY not set (env or $ROOT/.env)." >&2
  echo "Running capture only; re-run without --capture-only once the key is available." >&2
  CAPTURE_ONLY=1
fi

export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-5432}"
export MIX_ENV=test
export THREADLINE_E2E=1

port_listening() {
  lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

PORT="${THREADLINE_E2E_PORT:-${PORT:-4002}}"
if port_listening "$PORT"; then
  for candidate in $(seq 4100 4199); do
    if ! port_listening "$candidate"; then PORT="$candidate"; break; fi
  done
fi
export PORT
export E2E_BASE_URL="http://${HOST}:${PORT}"

cd "$EXAMPLE"
mix deps.get --only test
# Same compile-time theme-gate recompile forcing as run-e2e.sh (Phase 168).
touch lib/threadline_phoenix_web/router.ex
mix compile --force
mix ecto.create --quiet -r ThreadlinePhoenix.Repo 2>/dev/null || true
mix ecto.migrate --quiet
mix demo.reset
mix demo.seed

cd "$E2E_DIR"
if [[ -f package-lock.json ]]; then npm ci; else npm install; fi
npx playwright install chromium

PHX_PID=""
cleanup() {
  if [[ -n "$PHX_PID" ]] && kill -0 "$PHX_PID" 2>/dev/null; then
    kill "$PHX_PID" 2>/dev/null || true
    wait "$PHX_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

: >"$LOG_FILE"
cd "$EXAMPLE"
mix phx.server >>"$LOG_FILE" 2>&1 &
PHX_PID=$!

ready=0
for _ in $(seq 1 120); do
  if curl --max-time 1 -fsS "${E2E_BASE_URL}/users/log_in" >/dev/null 2>&1; then
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

cd "$E2E_DIR"
echo "== Fresh Tier-B route capture (${E2E_BASE_URL}) =="
npm run capture:pages

if [[ "$CAPTURE_ONLY" -eq 1 ]]; then
  echo "Capture complete. Scoring skipped (capture-only mode)."
  exit 0
fi

for route in "${ROUTE_LIST[@]}"; do
  echo "== BEFORE pole: route.${route} =="
  rm -f "$CACHE_DIR/route.${route}__dark-1280__"*.json
  npm run critic:score -- --page "route.${route}"
done

echo "== BEFORE poles complete: ${ROUTE_LIST[*]} =="
