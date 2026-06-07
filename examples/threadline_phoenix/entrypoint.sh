#!/usr/bin/env bash
set -euo pipefail

DB_HOST="${DB_HOST:-postgres}"

print_demo_urls() {
  local host="${THREADLINE_DEMO_PUBLIC_HOST:-localhost}"
  local port="${THREADLINE_DEMO_PORT:-${PORT:-4000}}"
  local base_url="${THREADLINE_DEMO_PUBLIC_URL:-http://${host}:${port}}"

  cat <<EOF

Threadline demo URLs
  Home:      ${base_url}/
  Sign in:   ${base_url}/users/log_in
  Audit:     ${base_url}/audit
  Timeline:  ${base_url}/audit/timeline?correlation_id=walk-acme-4521-close
  Evidence:  ${base_url}/audit/evidence
  Redaction: ${base_url}/audit/policy/redaction
  Coverage:  ${base_url}/audit/coverage

Credentials
  admin@example.com / password123456

EOF
}

echo "Waiting for postgres to become available..."
until pg_isready -h "$DB_HOST" -U "postgres"; do
  sleep 1
done
echo "Postgres is available!"

# Ensure the database is created and migrated
echo "Running mix setup (create DB + migrate)..."
mix setup

# Load the walkthrough fiction data
echo "Loading realistic demo data..."
mix demo.seed

echo "Starting the server..."
print_demo_urls
exec "$@"
