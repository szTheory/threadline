# Phase 1: Capture Foundation — Research

**Phase:** 1 of 4 — Capture Foundation
**Written:** 2026-04-22
**Consumed by:** Planner (Phase 1 plan generation)
**Status:** RESEARCH COMPLETE

---

## Executive Summary

Phase 1 delivers the trigger-backed capture substrate, correct PgBouncer-safe schema, Mix tasks, CI pipeline, and CONTRIBUTING.md skeleton. All major design decisions are already locked in CONTEXT.md (D-01 through D-12). The planner's primary job is to sequence three plans:

1. **Plan 01-01** — Carbonite research gate (binary decision: Carbonite or custom triggers)
2. **Plan 01-02** — Library scaffolding + schema migrations + capture infrastructure (using gate result)
3. **Plan 01-03** — CI pipeline + CONTRIBUTING.md + integration tests

This document answers "what do I need to know to plan these three plans well?"

---

## Section 1: Carbonite Research Gate (Plan 01-01)

**Confidence: HIGH on questions; MEDIUM on pre-gate answers**

### What the Gate Must Resolve

The gate is binary. After Plan 01-01, all subsequent plans lock to either:
- **Path A:** `{:carbonite, "~> 0.16"}` — wrap Carbonite's migration helpers and trigger functions
- **Path B:** Custom trigger SQL in `Threadline.Capture.TriggerSQL` module — no external capture dep

### Specific Questions (from STATE.md and CONTEXT.md D-01)

| Question | Why It Matters | Fail Condition |
|----------|---------------|----------------|
| Is Carbonite ~> 0.16 the current version? | Version lock in `mix.exs` | Major version bump with breaking changes |
| Does Carbonite support PostgreSQL ≥ 14? | Threadline's stated minimum floor | Requires PG 15+ or has known PG 14 bugs |
| Does Carbonite use a transaction-row for metadata (not `SET LOCAL`)? | PgBouncer-safe propagation — a schema constraint, not implementation detail | Uses `SET LOCAL` for metadata with no transaction-row path |
| Is Carbonite actively maintained? | Can't build on abandonware | No activity in 12+ months; open critical bugs unresolved |

### What We Already Know (from STACK.md, SUMMARY.md)

- Carbonite v0.16.x is confirmed as current in ecosystem research (MEDIUM confidence — verify in gate)
- Carbonite uses a `carbonite_transactions` table keyed on `txid_current()` — this is the transaction-row approach Threadline needs (HIGH confidence from ecosystem analysis; verify matches D-06 design)
- Carbonite handles: composite PKs, schema isolation via `carbonite_prefix`, column filtering, `Ecto.Multi`, outbox abstraction
- Known Carbonite gaps (acceptable): TRUNCATE not captured, metadata propagation is app responsibility

### Gate Output Format

Plan 01-01 must produce a gate result document at `.planning/phases/01-capture-foundation/gate-01-01.md` with:
- Binary decision: `Carbonite` or `Custom`
- If Carbonite: exact version constraint to use
- If Custom: confirmation that custom TriggerSQL module is the path
- Specific findings on each gate question above

### Planning Impact

If Carbonite passes: Plan 01-02 adds `{:carbonite, "~> 0.16"}` to `mix.exs` and wraps Carbonite's `Carbonite.Migrations` helpers in Threadline's own Mix tasks.

If Carbonite fails: Plan 01-02 implements `Threadline.Capture.TriggerSQL` with raw PL/pgSQL DDL embedded in Ecto migration modules. The trigger SQL itself is not complex — the main work is the Ecto migration wrapping and test coverage.

---

## Section 2: Schema Design

**Confidence: HIGH — fully specified in CONTEXT.md D-05**

### `audit_transactions` Table (Phase 1 columns only)

```sql
id              uuid PRIMARY KEY DEFAULT gen_random_uuid()
occurred_at     timestamptz NOT NULL DEFAULT now()
source          text                          -- application name, nullable
meta            jsonb                         -- catch-all; future metadata
```

**Phase 2 will add additively:** `actor_ref jsonb`, `action_id uuid`. Do not pre-add these nullable columns in Phase 1.

### `audit_changes` Table

```sql
id              uuid PRIMARY KEY DEFAULT gen_random_uuid()
transaction_id  uuid NOT NULL REFERENCES audit_transactions(id)
table_schema    text NOT NULL
table_name      text NOT NULL
table_pk        jsonb NOT NULL               -- row identity; preserved on DELETE
op              text NOT NULL CHECK (op IN ('insert','update','delete'))
data_after      jsonb                        -- NULL on DELETE (not empty {})
changed_fields  text[]                       -- NULL on DELETE; field names changed
captured_at     timestamptz NOT NULL DEFAULT now()
```

### Key Schema Decisions (locked)

- **UUIDs everywhere** — `gen_random_uuid()` for all PKs; no sequential integers
- **`data_after` is NULL on DELETE** (CAP-03, D-11) — not empty `{}`; `table_pk` preserves row identity
- **`changed_fields` is NULL on DELETE** — no fields "changed"; row was removed
- **No `data_before`** — v2 requirement (BVAL-01); do not add in Phase 1
- **No actor columns** — Phase 2 additive migration; null today is correct by design
- **`CREATE TABLE IF NOT EXISTS`** pattern — idempotency for PKG-04

### Indexes Required

```sql
CREATE INDEX audit_changes_transaction_id_idx ON audit_changes(transaction_id);
CREATE INDEX audit_changes_table_name_idx ON audit_changes(table_name);
CREATE INDEX audit_changes_captured_at_idx ON audit_changes(captured_at DESC);
```

---

## Section 3: Context Propagation Mechanism

**Confidence: HIGH — locked as non-negotiable in STATE.md and D-06**

### The Constraint

PgBouncer transaction pooling is the baseline deployment assumption. `SET LOCAL` is connection-scoped and silently wrong under transaction pooling. This is **a schema constraint, not an implementation detail** — it cannot be retrofitted.

### The Mechanism (D-06)

```
Trigger fires → txid_current() → UPSERT into audit_transactions ON CONFLICT DO NOTHING
                                  keyed on txid → INSERT into audit_changes referencing it
```

The trigger function reads `txid_current()` and upserts an `audit_transactions` row (creating one if none exists for this txid, reusing it if one already exists from a prior write in the same transaction). `audit_changes` rows reference the transaction row via FK.

**Phase 2 will add:** Application-side insert of actor context using the same txid key to fill in `actor_ref` on the existing `audit_transactions` row.

### Carbonite Compatibility Check (for gate)

If Carbonite uses this txid-keyed transaction-row approach for its `carbonite_transactions` table, it is compatible. If it uses `SET LOCAL` anywhere for metadata, it fails the gate.

---

## Section 4: Elixir Library Project Structure

**Confidence: HIGH — locked in D-03, standard Elixir library patterns**

### Directory Layout

```
lib/
  threadline.ex                          # top-level module, @moduledoc only in Phase 1
  threadline/
    capture/
      audit_transaction.ex               # Ecto schema
      audit_change.ex                    # Ecto schema
      migration.ex                       # migration helper functions
    mix/
      tasks/
        threadline.install.ex            # mix threadline.install
        threadline.gen.triggers.ex       # mix threadline.gen.triggers
priv/
  migrations/                            # generated migration templates (if any)
test/
  threadline/
    capture/                             # integration tests (real PostgreSQL)
      audit_transaction_test.exs
      audit_change_test.exs
      trigger_test.exs                   # key: tests trigger behavior via real DB
  support/
    repo.ex                              # test Ecto.Repo
    data_case.ex                         # DB-backed test case helper
config/
  config.exs
  test.exs                               # DB_HOST env var for CI/local compat
mix.exs
.credo.exs
.github/
  workflows/
    ci.yml
CONTRIBUTING.md
```

### `mix.exs` Structure

```elixir
defp deps do
  [
    {:ecto_sql, "~> 3.10"},
    {:postgrex, "~> 0.17"},
    {:jason, "~> 1.4"},
    {:telemetry, "~> 1.2"},
    # Capture substrate — locked after gate
    {:carbonite, "~> 0.16"},            # Path A only; remove if gate fails

    # Optional integrations
    {:plug, "~> 1.14", optional: true},

    # Dev/test only
    {:ex_doc, "~> 0.34", only: :dev, runtime: false},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:excoveralls, "~> 0.18", only: :test}
  ]
end
```

### Mix Aliases (CI-01 through CI-04, D-07)

```elixir
aliases: [
  "verify.format": ["format --check-formatted"],
  "verify.credo": ["credo --strict"],
  "verify.test": ["test"],
  "ci.all": ["verify.format", "verify.credo", "verify.test"]
]
```

These aliases must exist from Plan 01-02 so CI and CONTRIBUTING.md can cite them verbatim.

---

## Section 5: Mix Tasks

**Confidence: HIGH — behavior specified in PKG-02, PKG-03, PKG-04, D-04, D-10**

### `mix threadline.install` (PKG-02, PKG-04, D-04)

**Behavior:**
- Generates an Ecto migration file into the host app's `priv/repo/migrations/` directory
- Timestamp-prefixed filename: `{timestamp}_threadline_audit_schema.exs`
- Migration creates `audit_transactions` and `audit_changes` tables with indexes
- Uses `create_if_not_exists` / `IF NOT EXISTS` for idempotency (PKG-04)
- Warns on re-run (file already exists) rather than overwriting
- Does NOT execute the migration — developer runs `mix ecto.migrate`

**Implementation pattern:**
```elixir
use Mix.Task

def run(_args) do
  # Determine target path
  # Use Mix.Generator.create_file/2 to write migration
  # Warn if file already exists
end
```

### `mix threadline.gen.triggers` (PKG-03, D-10)

**Behavior:**
- Accepts `--tables users,posts` or positional args
- Generates one migration per invocation with trigger DDL for specified tables
- **Guards:** If `audit_transactions` or `audit_changes` passed as table name, emit error and exit non-zero (CAP-10, D-10)
- Does NOT support column exclusion in Phase 1 (v2 feature via Carbonite's filtered columns)

**Implementation pattern:**
```elixir
def run(args) do
  {opts, tables, _} = OptionParser.parse(args, switches: [tables: :string])
  tables = parse_tables(tables, opts)
  validate_not_audit_tables!(tables)   # exit non-zero if audit tables given
  # Generate migration with trigger DDL for each table
end
```

---

## Section 6: CI Pipeline

**Confidence: HIGH — fully specified in D-08, CI-01 through CI-07**

### GitHub Actions Structure (`.github/workflows/ci.yml`)

Three jobs with **stable IDs** (never rename these — CI-05):

```yaml
on:
  push:          # all branches, no path filter
  pull_request:

jobs:
  verify-format:   # STABLE ID
    runs-on: ubuntu-latest
    steps: [checkout, setup-elixir, deps, "mix verify.format"]

  verify-credo:    # STABLE ID
    runs-on: ubuntu-latest
    steps: [checkout, setup-elixir, deps, "mix verify.credo"]

  verify-test:     # STABLE ID
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env: {POSTGRES_USER: postgres, POSTGRES_PASSWORD: postgres, POSTGRES_DB: threadline_test}
        ports: ["5432:5432"]
        options: --health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5
    steps: [checkout, setup-elixir, deps, "mix verify.test"]
```

**Key constraints:**
- All three jobs run on `push` to `main` regardless of path filters on PRs (CI-06)
- PostgreSQL 16 in CI (covers ≥ 14 requirement; no reason to test the floor)
- Job `name:` fields may change; `id:` fields are immutable
- `config/test.exs` uses `hostname: System.get_env("DB_HOST", "localhost")` for CI/local compat

### Elixir Setup Action Pattern

```yaml
- uses: erlef/setup-beam@v1
  with:
    elixir-version: '1.17'
    otp-version: '26'
- run: mix deps.get
- run: mix compile --warnings-as-errors
```

---

## Section 7: Testing Strategy

**Confidence: HIGH — locked in D-09, CI-07**

### Principle: No Silent Exclusions (CI-07)

`mix test` runs the full suite. Trigger integration tests are NOT tagged with `@tag :skip` or excluded in `test_helper.exs`. If a test requires a database, it gets a database — that is what CI services are for.

### Test Layers

**Integration tests (require real PostgreSQL):**
- `test/threadline/capture/trigger_test.exs` — INSERT, UPDATE, DELETE produce correct `audit_changes` rows
- `test/threadline/capture/audit_transaction_test.exs` — txid grouping, occurred_at, multiple writes per transaction
- Idempotency: running `mix threadline.install` migration twice does not corrupt data

**Unit tests (no DB):**
- Schema struct construction and validation
- Mix task argument parsing (`--tables`, error guards)
- Migration file path generation logic

### Test Support

```elixir
# test/support/repo.ex
defmodule Threadline.Test.Repo do
  use Ecto.Repo, otp_app: :threadline, adapter: Ecto.Adapters.Postgres
end

# test/support/data_case.ex
defmodule Threadline.DataCase do
  use ExUnit.CaseTemplate
  # Wrap each test in a transaction; rollback on completion
  # Do NOT use Ecto sandbox for trigger tests — triggers fire at DB level
end
```

**Critical:** Ecto sandbox wraps the test in a transaction but only sees app-level Ecto queries. Triggers fire at the DB level and can insert into `audit_changes` outside the Ecto sandbox's awareness. For trigger tests, use real DB operations and explicit teardown rather than sandbox isolation.

---

## Section 8: Trigger SQL Pattern

**Confidence: HIGH on approach; MEDIUM on final SQL (depends on gate)**

### Path A (Carbonite) — Planner Notes

If gate passes, Plan 01-02 wraps Carbonite's own migration helpers. The trigger SQL is Carbonite's. Threadline's Mix tasks call:

```elixir
Carbonite.Migrations.install_trigger(repo, table_name, opts)
```

Review Carbonite's migration API in the gate to confirm the exact function signatures.

### Path B (Custom) — Trigger SQL Skeleton

```sql
CREATE OR REPLACE FUNCTION threadline_capture_fn() RETURNS trigger AS $$
DECLARE
  v_txid        bigint := txid_current();
  v_transaction_id uuid;
  v_op          text;
  v_data_after  jsonb;
  v_table_pk    jsonb;
  v_changed     text[];
BEGIN
  -- Determine operation type
  v_op := lower(TG_OP);

  -- Upsert audit_transactions row for this DB transaction
  INSERT INTO audit_transactions (id, occurred_at)
  VALUES (gen_random_uuid(), now())
  ON CONFLICT DO NOTHING;   -- keyed on txid in a real impl; use a txid column

  SELECT id INTO v_txid FROM audit_transactions WHERE txid = v_txid;

  -- Build data_after and table_pk
  IF v_op = 'delete' THEN
    v_data_after := NULL;
    v_table_pk := to_jsonb(OLD) -> 'id';  -- simplified; use actual PK columns
    v_changed := NULL;
  ELSE
    v_data_after := to_jsonb(NEW);
    v_table_pk := to_jsonb(NEW) -> 'id';
    -- changed_fields: diff NEW vs OLD for UPDATE
    v_changed := ARRAY(SELECT key FROM jsonb_each(to_jsonb(NEW))
                       WHERE to_jsonb(NEW)->key IS DISTINCT FROM to_jsonb(OLD)->key);
  END IF;

  INSERT INTO audit_changes
    (id, transaction_id, table_schema, table_name, table_pk, op, data_after, changed_fields, captured_at)
  VALUES
    (gen_random_uuid(), v_transaction_id, TG_TABLE_SCHEMA, TG_TABLE_NAME,
     v_table_pk, v_op, v_data_after, v_changed, now());

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

Note: The actual `txid_current()` keying requires a `txid` column on `audit_transactions`. This is a detail to resolve in Plan 01-02 depending on gate outcome.

### Preventing Recursive Triggers (CAP-10, D-10)

The trigger generator must never install triggers on `audit_transactions` or `audit_changes`. This guard lives in the Mix task, not documentation. Both validation paths:
1. Task validates table names before generating migration
2. Trigger SQL can also include a `WHEN (TG_TABLE_NAME NOT IN ('audit_transactions', 'audit_changes'))` guard as defense-in-depth

---

## Section 9: CONTRIBUTING.md (DOC-04, D-12)

**Confidence: HIGH — Phase 1 deliverable, content specified**

Minimal skeleton. Four sections only:
1. Dev environment setup (deps, PostgreSQL)
2. Running tests: `mix verify.test`
3. Running all CI checks: `mix ci.all`
4. Submitting a PR (brief, no process complexity)

No contribution policy, no RFC process, no CoC in Phase 1 — those are Phase 4 polish.

---

## Section 10: Critical Pitfalls for Planning

**Confidence: HIGH — from SUMMARY.md, PITFALLS.md, and documented production failures**

| Pitfall | Risk Level | Mitigation in Phase 1 |
|---------|-----------|----------------------|
| `SET LOCAL` for context propagation | CRITICAL | D-06: transaction-row insert only; schema constraint |
| ETS/PID-scoped context | HIGH (Phase 2) | Defer to Phase 2; do not introduce in Phase 1 |
| Running trigger tests with Ecto sandbox | HIGH | D-09: real PostgreSQL; explicit teardown for trigger tests |
| Silently excluding trigger tests from `mix test` | HIGH | CI-07: no silent exclusions; document any in `test_helper.exs` |
| Renaming CI job `id:` fields | MEDIUM | D-08, CI-05: stable IDs are a named requirement |
| Recursive audit triggers on audit tables | MEDIUM | D-10, CAP-10: guard in Mix task and trigger SQL |
| `data_after = {}` on DELETE instead of NULL | MEDIUM | D-11, CAP-03: NULL on delete; `table_pk` preserves identity |
| Adding Phase 2 columns (`actor_ref`) in Phase 1 | LOW | D-05: Phase 1 columns only; additive migration in Phase 2 |
| Umbrella app structure | LOW | D-03: single library package |

---

## Section 11: Plan Sequencing Recommendation

**Confidence: HIGH**

### Plan 01-01: Carbonite Research Gate

**Goal:** Binary decision — Carbonite or custom triggers
**Inputs:** Gate questions from Section 1 above
**Output:** `gate-01-01.md` with decision + version constraint
**Blocks:** Plans 01-02 and 01-03 cannot start until this closes
**Duration estimate:** Single focused investigation session

### Plan 01-02: Library Scaffold + Schema + Capture Infrastructure

**Goal:** Working Elixir library with trigger capture functioning
**Inputs:** Gate result from 01-01
**Delivers:**
- `mix new threadline --module Threadline` project structure (D-03)
- `mix.exs` with deps, aliases (D-07), version `0.1.0-dev`
- `audit_transactions` + `audit_changes` schema (D-05)
- `mix threadline.install` Mix task (D-04)
- `mix threadline.gen.triggers` Mix task (D-10)
- `Threadline.Capture.AuditTransaction` + `AuditChange` Ecto schemas
- Trigger capture working (Path A: Carbonite wrapper; Path B: custom SQL)
- Integration tests proving INSERT/UPDATE/DELETE capture (D-09)
**Key constraint:** Capture uses transaction-row mechanism, never `SET LOCAL` (D-06)

### Plan 01-03: CI Pipeline + CONTRIBUTING.md

**Goal:** Passing CI, CONTRIBUTING.md skeleton
**Inputs:** Working library from 01-02
**Delivers:**
- `.github/workflows/ci.yml` with three stable-ID jobs (D-08)
- `config/test.exs` with `DB_HOST` env var
- `.credo.exs` configuration
- `CONTRIBUTING.md` skeleton (D-12, DOC-04)
- All `mix verify.*` and `mix ci.all` aliases confirmed working
**Key constraint:** All three CI jobs run on push to main, no path-filter exclusions (CI-06)

---

## Open Questions for Planner

1. **Gate failure contingency depth:** How much custom trigger SQL should Plan 01-02 pre-specify vs. design at execution time? Recommendation: pre-specify the PL/pgSQL skeleton in 01-02 so the plan is actionable regardless of gate outcome.

2. **Carbonite API surface for wrapping:** If gate passes, the planner should look up Carbonite's `Carbonite.Migrations` module API to specify exact function calls in Plan 01-02. This is available in Carbonite's Hex docs.

3. **Test database naming:** `threadline_test` is assumed. Confirm in `config/test.exs` and CI service definition.

4. **Ecto prefix for audit schema:** Phase 1 uses default public schema. Document that Carbonite's `carbonite_prefix` or an explicit `audit` Postgres schema is a v0.2+ option — don't block Plan 01-02 on this decision.

---

## Confidence Summary

| Topic | Confidence | Notes |
|-------|-----------|-------|
| Gate questions (what to ask) | HIGH | Fully specified in STATE.md, CONTEXT.md D-01 |
| Gate answers (pre-gate) | MEDIUM | Carbonite txid approach likely compatible; verify |
| Schema design | HIGH | Fully locked in D-05, CAP-01 through CAP-10 |
| Context propagation mechanism | HIGH | Non-negotiable; D-06, locked in STATE.md |
| Mix task behavior | HIGH | PKG-02, PKG-03, PKG-04, D-04, D-10 fully specified |
| Mix alias structure | HIGH | D-07; trivial to implement |
| CI structure | HIGH | D-08, CI-01 through CI-07 fully specified |
| Testing strategy | HIGH | D-09, CI-07; real PostgreSQL, no silent exclusions |
| Plan sequencing | HIGH | 01-01 gate → 01-02 infrastructure → 01-03 CI |
| Trigger SQL (Path B) | MEDIUM | Approach clear; exact SQL depends on gate outcome and txid column design |

**Overall: HIGH confidence. Phase 1 is well-specified. The gate is the only real unknown.**

---

*Research complete: 2026-04-22*
*Phase 1 ready for planning: YES*
*Blocker: None — gate is Plan 01-01, not a pre-planning blocker*
