# Phase 1 Capture Foundation — Verification Report

**Date:** 2026-04-22
**Verifier:** Claude Sonnet 4.6 (goal-backward verification pass)
**Phase Goal:** Every INSERT, UPDATE, and DELETE on an audited table is durably captured in a correct, SQL-queryable schema — regardless of how the write occurred.

---

## Status: `gaps_found`

## Score: 3/5 success criteria verified

---

## Artifact Table

| Artifact | Exists | Substantive | Wired |
|---|---|---|---|
| `mix.exs` with aliases (`verify.format`, `verify.credo`, `verify.test`, `ci.all`) | YES | YES | YES |
| `lib/threadline/capture/audit_transaction.ex` | YES | YES — correct D-05+D-06 columns | YES — referenced by tests |
| `lib/threadline/capture/audit_change.ex` | YES | YES — correct D-05 columns | YES — referenced by tests |
| `lib/threadline/capture/migration.ex` | YES | YES — full DDL with `IF NOT EXISTS` | YES — called by install task |
| `lib/threadline/capture/trigger_sql.ex` | YES | YES — PL/pgSQL with `txid_current()` | YES — called by gen.triggers task |
| `lib/mix/tasks/threadline.install.ex` | YES | YES — generates migration, idempotent | YES — uses `Migration.migration_content/0` |
| `lib/mix/tasks/threadline.gen.triggers.ex` | YES | YES — table guard + migration gen | YES — uses `TriggerSQL` |
| `priv/repo/migrations/20260101000000_threadline_audit_schema.exs` | YES | YES — full DDL, not a stub | YES — auto-run by `test_helper.exs` |
| `test/support/repo.ex` | YES | YES | YES — used by DataCase and trigger tests |
| `test/support/data_case.ex` | YES | YES — no sandbox (correct for trigger tests) | YES — used by trigger_test.exs |
| `test/threadline/capture/trigger_test.exs` | YES | YES — 5 real assertions, no mocks | YES — uses DataCase + Repo |
| `test/test_helper.exs` | YES | YES — starts repo, runs Ecto.Migrator | YES — entry point for all tests |
| `config/config.exs` | YES | YES (minimal, correct for library) | YES |
| `config/test.exs` | YES | YES — `DB_HOST` env var, correct repo config | YES |
| `.credo.exs` | YES | YES — strict mode | YES — invoked by `verify.credo` alias |
| `.formatter.exs` | YES | YES | YES — invoked by `verify.format` alias |
| `.github/workflows/ci.yml` | **NO** | — | — |
| `CONTRIBUTING.md` | **NO** | — | — |
| `lib/threadline/audit_transaction.ex` (top-level, duplicate) | YES | PROBLEMATIC — Phase 2 fields present, no `txid`, wrong schema | Orphaned — not used by tests |
| `lib/threadline/audit_change.ex` (top-level, duplicate) | YES | PROBLEMATIC — `table_pk :string` (wrong), `op Ecto.Enum` (wrong) | Orphaned — not used by tests |
| `lib/threadline/audit_action.ex` | YES | Phase 2 artifact — correct semantics-layer schema | Orphaned — no tests, no wiring |

---

## Truth Table

| # | Success Criterion | Status | Notes |
|---|---|---|---|
| SC-1 | Developer can run `mix threadline.install` and `mix threadline.gen.triggers` to set up schema and triggers | **verified** | Both tasks exist, are substantive, and generate correct migration files. `install` is idempotent (warns on re-run, exits 0). `gen.triggers` guards against audit table names with `Mix.raise/1`. |
| SC-2 | Every INSERT, UPDATE, and DELETE produces a correct `AuditChange` row with correct op, JSONB data, and grouped `AuditTransaction` | **uncertain** | Trigger SQL logic is correct for tables with an `id` UUID primary key column. All five integration tests are substantively written. However, `mix verify.test` has not been confirmed passing (Plan 01-02 summary explicitly notes: "requires a running PostgreSQL instance; not run during scaffold"). No PostgreSQL available in the current environment to re-confirm. The code is correct by inspection, but the criterion requires a passing test run. |
| SC-3 | Writes made directly via SQL or `Ecto.Repo` calls bypass application-layer callbacks and are still captured | **verified** | The trigger fires at the PostgreSQL level. All test assertions use `Repo.query!/2` (raw SQL) and `Repo.transaction/1`, not higher-level Ecto callbacks. `DataCase` explicitly does not use `Ecto.Sandbox`. This is architecturally correct. |
| SC-4 | Running `mix threadline.install` twice is safe — no data corruption, no migration failure | **verified** | `install` task checks for existing `*_threadline_audit_schema.exs` files before writing; prints warning and exits 0 on re-run. Migration DDL uses `CREATE TABLE IF NOT EXISTS` and `CREATE INDEX IF NOT EXISTS`. `CREATE OR REPLACE FUNCTION` for the trigger. All three idempotency vectors are covered. |
| SC-5 | `mix ci.all` passes: `verify.format`, `verify.credo`, and `verify.test` all green; `CONTRIBUTING.md` skeleton exists | **failed** | `verify.format` exits 0 (confirmed). `verify.credo` exits 0 (confirmed, 0 issues in 14 files). `verify.test` requires PostgreSQL (not confirmed passing). **`CONTRIBUTING.md` does not exist** (required by DOC-04, D-12, Plan 01-03 Task 5). **`.github/workflows/ci.yml` does not exist** (required by CI-01 through CI-07, D-08, Plan 01-03 Task 3). Plan 01-03 has no SUMMARY file — it was never executed. |

---

## Gap Analysis

### GAP-1 (BLOCKING): Plan 01-03 Was Never Executed

**Impact:** SC-5 failed. No `CONTRIBUTING.md`, no `.github/workflows/ci.yml`.

**Missing artifacts:**
- `.github/workflows/ci.yml` — three jobs (`verify-format`, `verify-credo`, `verify-test`) with PostgreSQL 16 service on `verify-test`
- `CONTRIBUTING.md` — four sections: dev environment, running tests, running CI checks, submitting a PR

**No `01-03-SUMMARY.md` exists**, confirming this plan was never run. Plans 01-01 and 01-02 were completed; 01-03 was not started.

**Fix:** Execute Plan 01-03 as specified. Create `.github/workflows/ci.yml` matching the spec in 01-03-PLAN.md Task 3, and `CONTRIBUTING.md` matching Task 5. Run `mix ci.all` end-to-end to confirm (requires PostgreSQL). Write `01-03-SUMMARY.md`.

---

### GAP-2 (MODERATE): Duplicate Schema Modules at Wrong Namespace

**Impact:** Codebase contains two conflicting representations of the same database tables.

**Problem:**
- `lib/threadline/audit_transaction.ex` (`Threadline.AuditTransaction`) — maps to `"audit_transactions"` but contains Phase 2 fields (`actor_type`, `actor_id`), no `txid` column, no `source` column, uses `timestamps/0` macro (adds `inserted_at`/`updated_at` columns that do not exist in the DB schema).
- `lib/threadline/audit_change.ex` (`Threadline.AuditChange`) — maps to `"audit_changes"` but has `table_pk :string` (should be `:map`/JSONB) and `op Ecto.Enum` (spec says `op :string` with a DB-level CHECK constraint).

These modules were committed in an earlier task (GSD-Task S01/T02, commit `c1e1508`) before Plan 01-02 created the correct `Threadline.Capture.*` namespace versions. They were not removed when the correct versions were created.

**Currently non-breaking** because tests alias `Threadline.Capture.{AuditChange, AuditTransaction}` (the correct versions). However:
1. They create public API confusion — a consumer importing `Threadline.AuditChange` would get wrong field types.
2. `Threadline.AuditTransaction` with `timestamps()` would fail on any query against the real schema (no `inserted_at`/`updated_at` columns).
3. `table_pk :string` in the top-level `AuditChange` is wrong — the DB column is `jsonb`.
4. Phase 2 fields (`actor_type`, `actor_id`) in `Threadline.AuditTransaction` violate the D-05 constraint that Phase 1 schema has no Phase 2 columns.

**Fix:** Delete `lib/threadline/audit_transaction.ex`, `lib/threadline/audit_change.ex`, and `lib/threadline/audit_action.ex`. The canonical schemas are in `lib/threadline/capture/`. `AuditAction` belongs to Phase 2 (semantics layer) and should not exist in Phase 1. Confirm `mix compile --warnings-as-errors` still passes after deletion.

---

### GAP-3 (MINOR, DEFERRED): `table_pk` Hardcoded to `'id'` Column

**Impact:** SC-2 is partially uncertain for non-standard primary key columns.

**Problem:** The PL/pgSQL trigger function always extracts `table_pk` as `jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'))`. This silently produces `{"id": null}` for any table whose primary key column is not named `id` (e.g., `user_id`, composite PKs). The integration tests do not catch this because `test_audit_target` uses `id uuid PRIMARY KEY`.

**Severity for Phase 1:** Low — most Ecto/Phoenix tables use `id` as PK by convention, and the spec does not explicitly require composite PK support in Phase 1. The trigger does not crash; it just captures a null PK for non-`id` tables.

**Fix (can defer to Phase 2):** Either (a) document the `id`-column assumption in `TriggerSQL` moduledoc and `mix threadline.gen.triggers` help text, or (b) use `TG_ARGV` to pass the PK column name per-trigger at install time. Add a test with a non-`id` PK column.

---

### GAP-4 (MINOR): `mix verify.test` Not Confirmed Passing

**Impact:** SC-2 is `uncertain` rather than `verified`.

**Problem:** Plan 01-02 summary explicitly notes `mix verify.test` was not run because no PostgreSQL instance was available at scaffold time. No CI run has confirmed the tests pass.

**Fix:** Run `mix verify.test` against a live PostgreSQL 16 instance. Expected result: all 5 tests in `trigger_test.exs` pass. This will be automatically resolved when GAP-1 is fixed (CI pipeline runs on every push).

---

## Deferred Items

The following gaps are by design — they are not Phase 1 failures:

| Item | Reason Deferred |
|---|---|
| `actor_ref`, `action_id`, `context_ref` columns | Phase 2 (semantics layer). Correctly absent from Phase 1 capture schemas. |
| `Threadline.AuditAction` wiring | Phase 2 semantics. Schema module exists but is unhooked — this is acceptable; it should be deleted per GAP-2 to avoid confusion. |
| Composite PK support in `table_pk` | CAP requirements do not specify composite PKs for Phase 1. Defer to Phase 2. |
| Telemetry events | Phase 3 (HLTH-03 through HLTH-05). |
| Trigger coverage health check | Phase 3 (`mix threadline.verify_coverage`). |
| Oban/Plug context integration | Phase 2 (CTX-01, CTX-05). |
| README, Hex publish | Phase 4. |

---

## Fix Plan

### Immediate (blocks Phase 1 completion)

1. **Execute Plan 01-03** — Create `.github/workflows/ci.yml` and `CONTRIBUTING.md` per the spec. Confirm `mix ci.all` passes with a live PostgreSQL instance. Write `01-03-SUMMARY.md`.

### Required before Phase 2 start

2. **Delete orphaned top-level schema files** — Remove `lib/threadline/audit_transaction.ex`, `lib/threadline/audit_change.ex`, `lib/threadline/audit_action.ex`. Verify compile and credo still pass.

### Optional (can defer to Phase 2)

3. **Document or fix `table_pk` `id`-column assumption** — Add a note to the `TriggerSQL` moduledoc that `table_pk` capture assumes a column named `id`. Add a failing test for a non-`id` PK table to make the limitation visible.

---

## Requirements Coverage Summary

| Requirement | Status |
|---|---|
| PKG-01 (library project) | PASS |
| PKG-02 (version `0.1.0-dev`) | PASS |
| PKG-03 (Hex package fields) | PASS |
| PKG-04 (idempotent install) | PASS |
| PKG-05 (Mix aliases) | PASS |
| CAP-01 (INSERT capture) | PASS — code correct, test written; awaiting DB confirmation |
| CAP-02 (UPDATE capture + changed_fields) | PASS — code correct, test written; awaiting DB confirmation |
| CAP-03 (DELETE + null data_after + table_pk preserved) | PASS — code correct, test written; awaiting DB confirmation |
| CAP-04 (real PostgreSQL, no mocks) | PASS — DataCase uses no sandbox |
| CAP-05 (transaction grouping) | PASS — code correct, test written; awaiting DB confirmation |
| CAP-06 (FK constraint, no orphans) | PASS — `REFERENCES audit_transactions(id) ON DELETE CASCADE` |
| CAP-07 (JSONB only, no Erlang terms) | PASS — schema enforces jsonb/text[]/text types |
| CAP-08 (`occurred_at` at transaction time) | PASS — `clock_timestamp()` in trigger upsert |
| CAP-09 (`captured_at` when trigger fires) | PASS — `clock_timestamp()` in audit_changes insert |
| CAP-10 (no recursive audit loop guard) | PASS — Mix.raise guard in gen.triggers; test confirms no loop |
| CI-01 (`verify.format` alias) | PASS |
| CI-02 (`verify.credo` alias) | PASS |
| CI-03 (`verify.test` alias) | PASS |
| CI-04 (`ci.all` alias) | PASS |
| CI-05 (stable CI job IDs) | **GAP** — workflow file missing |
| CI-06 (all jobs run on push to main) | **GAP** — workflow file missing |
| CI-07 (no silent test exclusion) | PASS — all tests in `mix test`, no exclusion tags |
| DOC-04 (CONTRIBUTING.md skeleton) | **GAP** — file missing |
