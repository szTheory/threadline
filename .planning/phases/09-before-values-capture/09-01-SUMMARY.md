---
phase: 09-before-values-capture
plan: "01"
subsystem: database
tags: [postgres, triggers, mix, ecto]

key-files:
  created:
    - priv/repo/migrations/20260422110000_add_audit_changes_changed_from.exs
  modified:
    - lib/threadline/capture/migration.ex
    - lib/threadline/capture/trigger_sql.ex
    - lib/mix/tasks/threadline.gen.triggers.ex
    - priv/repo/migrations/20260422120000_refresh_threadline_capture_changes.exs

key-decisions:
  - "Per-table opt-in uses generated `threadline_capture_changes_<table>()` plus `create_trigger/2` `:per_table` mode."
  - "`except_columns` is enforced at SQL generation time via `ANY(<literal array>)` in emitted PL/pgSQL."

requirements-completed: [BVAL-01]

duration: —
completed: 2026-04-23
---

# Phase 9 — Plan 09-01 summary

**Shipped nullable `changed_from`, global trigger always writes NULL for it, and codegen for `--store-changed-from` / `--except-columns` with per-table capture functions.**

## Accomplishments

- Install template adds `changed_from jsonb` to `audit_changes`.
- `TriggerSQL.install_function/0-1` emits INSERTs including `changed_from`; `install_function_for_table/2` builds sparse JSON from `OLD` on UPDATE with shared `changed_fields` discovery and column exclusions.
- `mix threadline.gen.triggers` emits per-table function + trigger wiring when opted in; down migrations drop triggers then functions.

## Task commits

Implementation delivered as a single cohesive changeset (see repository history for `feat(09-01)`).

## Self-Check: PASSED

- `MIX_ENV=test mix compile` — PASS (local).
- `rg 'set_config|SET LOCAL' lib/threadline/capture/trigger_sql.ex` — no matches (PASS).
- PostgreSQL integration tests — NOT RUN (no local DB in agent environment); run `MIX_ENV=test mix test test/threadline/capture/trigger_test.exs` after migrate.

## Deviations

- None.
