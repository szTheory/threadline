---
phase: 1
plan: 01-02
subsystem: capture
tags: [scaffold, schema, triggers, mix-tasks, integration-tests]
key-files:
  - mix.exs
  - lib/threadline.ex
  - lib/threadline/capture/audit_transaction.ex
  - lib/threadline/capture/audit_change.ex
  - lib/threadline/capture/migration.ex
  - lib/threadline/capture/trigger_sql.ex
  - lib/mix/tasks/threadline.install.ex
  - lib/mix/tasks/threadline.gen.triggers.ex
  - test/support/repo.ex
  - test/support/data_case.ex
  - test/test_helper.exs
  - test/threadline/capture/trigger_test.exs
  - config/config.exs
  - config/test.exs
key-decisions:
  - Path B (custom TriggerSQL) used as capture substrate per gate-01-01.md
  - No Ecto sandbox — triggers fire at DB level; DataCase cleans tables between tests
  - txid_current() + INSERT ON CONFLICT DO NOTHING for transaction grouping (D-06)
  - data_after is NULL on DELETE; table_pk preserved from OLD row (D-11)
duration: ~3h
completed: 2026-04-23
---

# Plan 01-02 Summary: Library Scaffold + Schema + Capture Infrastructure

Working Elixir library with trigger-backed capture: every INSERT, UPDATE, and DELETE on an audited table produces correct `AuditChange` rows grouped under an `AuditTransaction`, confirmed by 5 integration tests against real PostgreSQL.

## Tasks Completed

| Task | Status | Notes |
|------|--------|-------|
| 1: Initialize Elixir library project | DONE | `mix.exs` with version, deps, 4 aliases, package block |
| 2: Create AuditTransaction and AuditChange schemas | DONE | D-05 columns; no Phase 2 fields; `:map` for JSONB, `{:array, :string}` for changed_fields |
| 3: Install migration + `mix threadline.install` | DONE | Idempotent (IF NOT EXISTS DDL); warns and exits 0 on re-run |
| 4: Trigger generation + `mix threadline.gen.triggers` | DONE | Path B: `TriggerSQL` module; audit-table guard with `Mix.raise/1` |
| 5: Test infrastructure + integration tests | DONE | 5 tests (INSERT, UPDATE, DELETE, txn grouping, no-recursive-loop); all pass |

## Requirements Coverage

CAP-01 through CAP-10 all satisfied. PKG-01 through PKG-05 satisfied. See `01-VERIFICATION.md` for full traceability.

## Deviations

- `mix.exs` gained a `cli/0` function setting `preferred_envs: ["ci.all": :test]` to ensure `mix ci.all` runs in the test environment — not in the original plan spec but required for correct behavior.
- `test_helper.exs` uses `Ecto.Migrator.run/3` rather than `storage_up` pattern — equivalent outcome.
- No deviation on D-05 schema, D-06 mechanism, D-09 real-DB requirement, D-10 audit-table guard, or D-11 DELETE semantics.

## Verification

- `mix compile --warnings-as-errors` ✓ — zero warnings
- `mix threadline.install` ✓ — generates migration; idempotent on second run
- `mix threadline.gen.triggers --tables users` ✓ — generates trigger migration
- `mix threadline.gen.triggers --tables audit_transactions` ✓ — exits non-zero (CAP-10 guard)
- `mix verify.test` ✓ — 5/5 tests passing (real PostgreSQL)

Plan 01-02 is **CLOSED**. Plan 01-03 is unblocked.
