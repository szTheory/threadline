#!/usr/bin/env bash
set -e

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
exec "$@"
