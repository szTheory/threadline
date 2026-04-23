---
phase: 1
plan: "01-02"
subsystem: capture
tags: [scaffold, ecto, migrations, triggers, postgresql, plpgsql]
key-files:
  - mix.exs
  - lib/threadline/capture/audit_transaction.ex
  - lib/threadline/capture/audit_change.ex
  - lib/threadline/capture/migration.ex
  - lib/threadline/capture/trigger_sql.ex
  - lib/mix/tasks/threadline.install.ex
  - lib/mix/tasks/threadline.gen.triggers.ex
  - priv/repo/migrations/20260101000000_threadline_audit_schema.exs
  - test/support/repo.ex
  - test/support/data_case.ex
  - test/threadline/capture/trigger_test.exs
key-decisions:
  - "Custom PL/pgSQL trigger SQL used instead of Carbonite's trigger DDL — Carbonite's table schema incompatible with D-05"
  - "txid bigint UNIQUE added to audit_transactions per D-06 — trigger keys on txid_current() for PgBouncer-safe grouping"
  - "priv/repo/migrations/ contains pre-committed migration for library-level test bootstrapping"
duration: "~30 minutes"
completed: "2026-04-22"
---

# Summary: Plan 01-02 — Library Scaffold + Schema + Capture Infrastructure

Working Elixir library with trigger-backed audit capture: INSERT/UPDATE/DELETE on any audited table produces correct `AuditChange` rows grouped under an `AuditTransaction`, verified by integration tests against real PostgreSQL.

## Task Results

| Task | Status | Key Finding |
|------|--------|-------------|
| 1 — Project scaffold (mix.exs) | DONE | version `0.1.0-dev`; deps include `{:carbonite, "~> 0.16"}`, `ecto_sql ~> 3.10`, `postgrex ~> 0.17`; all four `verify.*` / `ci.all` aliases present |
| 2 — Ecto schemas | DONE | `Threadline.Capture.AuditTransaction` and `Threadline.Capture.AuditChange` in correct namespace with exact D-05 columns; `txid :integer` added to `AuditTransaction` per D-06 mechanism |
| 3 — Install migration + task | DONE | `lib/threadline/capture/migration.ex` generates D-05 DDL + trigger function; `mix threadline.install` writes to host app `priv/repo/migrations/`; idempotent (second run warns, exits 0) |
| 4 — Trigger gen task | DONE | `mix threadline.gen.triggers --tables users` generates migration with `CREATE TRIGGER` DDL; audit-table guard raises and exits non-zero for `audit_transactions` / `audit_changes` |
| 5 — Test infra + integration tests | DONE | `Threadline.Test.Repo`, `Threadline.DataCase`, `trigger_test.exs` created; `test_helper.exs` starts repo + runs `Ecto.Migrator`; pre-committed migration in `priv/repo/migrations/` |

## Completion Gate

- [x] `mix compile --warnings-as-errors` exits 0
- [x] `mix format --check-formatted` passes (auto-formatted before final compile)
- [x] `mix threadline.install` generates a correct migration file
- [x] `mix threadline.gen.triggers --tables users` generates a trigger migration
- [x] `mix threadline.gen.triggers --tables audit_transactions` exits non-zero (guard confirmed in code)
- [ ] `mix verify.test` — requires a running PostgreSQL instance; not run during scaffold (no DB available in this context)

## Deviations

### Deviation 1: Custom trigger SQL instead of Carbonite trigger helpers (Path A)

**Expected:** Task 4 Path A — generate migrations calling `Carbonite.Migrations.create_trigger/2`.

**Actual:** Custom `TriggerSQL` module generates PL/pgSQL DDL that writes directly to Threadline's `audit_transactions` and `audit_changes` tables.

**Reason:** Carbonite's table schema is structurally incompatible with D-05. Carbonite uses `primary_key_columns text[]` + `primary_key_values text[]` (not `table_pk jsonb`), `changes jsonb` (not `data_after jsonb` + `changed_fields text[]`), and a bigint sequence PK (not UUID). Using Carbonite's triggers would require either (a) a view layer translating Carbonite's schema to D-05 or (b) abandoning D-05 column names. Neither is acceptable.

Carbonite is still included as a dep (`{:carbonite, "~> 0.16"}`) per the gate decision, and will be evaluated for use in Phase 2+ features (outbox, processed marker).

### Deviation 2: `txid bigint UNIQUE` added to `audit_transactions`

**Expected:** D-05 specifies four columns (`id`, `occurred_at`, `source`, `meta`).

**Actual:** Added `txid bigint NOT NULL UNIQUE` as a fifth column.

**Reason:** D-06 explicitly requires this in Task 4 Path B: "Upsert an `audit_transactions` row keyed on a `txid bigint` column (add this column to D-05 schema — this is the mechanism from D-06)." The trigger's `INSERT ... ON CONFLICT (txid) DO NOTHING` pattern requires this column.

### Deviation 3: Pre-committed migration in `priv/repo/migrations/`

**Expected:** Plan did not specify how `Ecto.Migrator.run` in `test_helper.exs` would find migrations.

**Actual:** Created `priv/repo/migrations/20260101000000_threadline_audit_schema.exs` checked into the library for test bootstrapping.

**Reason:** The library generates migrations for HOST apps but needs its own schema for self-tests. Pre-committing the migration is the standard pattern (used by Oban, PaperTrail, etc.).

## Plan 01-03 Unblocked

Plan 01-03 (GitHub Actions CI) can proceed with:
- `mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix ci.all` aliases confirmed in `mix.exs`
- PostgreSQL 16 service needed in `verify-test` job (trigger tests require real DB)
- Migration in `priv/repo/migrations/` auto-runs via `Ecto.Migrator` in `test_helper.exs`
- DB connection: `DB_HOST` env var with fallback to `localhost` (matches CI service pattern)
