# Phase 1: Capture Foundation - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning
**Source:** AI self-discuss (headless mode)

## Phase Boundary

Phase 1 delivers a working Elixir library project with:
- PostgreSQL trigger-backed row capture (INSERT/UPDATE/DELETE) for all audited tables
- Correct, PgBouncer-safe schema with `audit_transactions` and `audit_changes` tables
- `mix threadline.install` and `mix threadline.gen.triggers` Mix tasks
- GitHub Actions CI with `mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix ci.all`
- CONTRIBUTING.md skeleton

Phase 1 does NOT deliver: actor semantics (Phase 2), query API (Phase 3), README/Hex publish (Phase 4).

## Implementation Decisions

### D-01: Carbonite Research Gate Is Plan 01-01

**Decision:** The first plan in Phase 1 is a research/validation plan that confirms Carbonite compatibility before any capture infrastructure is built. It must close before Plan 01-02 can start.

**Rationale:** The Carbonite research gate is explicitly flagged in STATE.md and SUMMARY.md as a blocker. The specific questions are: (1) Is Carbonite ~> 0.16 current/maintained? (2) Does it support PostgreSQL ≥ 14? (3) Does it use `SET LOCAL` or a transaction-row for metadata? (4) Does its metadata mechanism conflict with Threadline's transaction-row-insert requirement? Resolving this in Plan 01-01 means all subsequent plans lock to either Path A (Carbonite) or Path B (custom triggers).

**Output:** A gate result document with a binary decision (Carbonite / custom) and the version/constraint to lock.

---

### D-02: Capture Substrate Default Is Carbonite — Custom Triggers Are the Fallback

**Decision:** Assume Carbonite ~> 0.16 is the capture substrate. The Carbonite research gate (D-01) must confirm this. If Carbonite fails the gate (hard incompatibility, abandonware, `SET LOCAL` only with no transaction-row path), the fallback is a custom trigger implementation using raw PostgreSQL DDL via Ecto migrations.

**Rationale:** Carbonite is the best-maintained trigger library in the Elixir ecosystem. It handles composite PKs, schema isolation, Ecto.Multi, column filtering, and outbox. Writing the same from scratch in Phase 1 is feasible but duplicates solved work. The fallback is not a regression — Threadline's trigger SQL is not complex; the hard part is the Ecto migration DSL wrapping, which is straightforward.

**If Carbonite passes gate:** Add `{:carbonite, "~> 0.16"}` to `mix.exs` deps. Use Carbonite's migration helpers and trigger functions as the substrate. Threadline wraps Carbonite for install and trigger gen tasks.

**If Carbonite fails gate:** Implement trigger functions directly in PostgreSQL DDL, embedded in Ecto migration modules. Use a `Threadline.Capture.TriggerSQL` module that generates the DDL strings. No external capture dep.

---

### D-03: Project Structure — Standard Elixir Library, No Umbrella

**Decision:** Initialize as a single Elixir library with `mix new threadline --module Threadline`. Directory structure:

```
lib/
  threadline.ex                  # top-level module, @moduledoc
  threadline/
    capture/                     # Phase 1: trigger infrastructure
      audit_transaction.ex       # Ecto schema
      audit_change.ex            # Ecto schema
      migration.ex               # migration helper functions
    mix/
      tasks/
        threadline.install.ex    # mix threadline.install
        threadline.gen.triggers.ex  # mix threadline.gen.triggers
priv/
  migrations/                    # generated migration templates
test/
  threadline/
    capture/                     # integration tests (real PostgreSQL)
  support/
    repo.ex                      # test repo
    data_case.ex                 # test case with DB sandbox
mix.exs
.credo.exs
```

**Rationale:** No umbrella needed at v0.1. Single package with clear internal module boundaries by subdirectory mirrors the bounded-context separation without prematurely splitting into multiple OTP apps. The `threadline/capture/` subdirectory establishes the layer boundary for Phase 1 code.

---

### D-04: `mix threadline.install` Generates Migration Files, Does Not Execute Them

**Decision:** `mix threadline.install` generates an Ecto migration file into the host app's `priv/repo/migrations/` directory with the `audit_transactions` and `audit_changes` table DDL. The developer runs `mix ecto.migrate` themselves.

**Rationale:** This is the standard Elixir library pattern used by Oban, Swoosh, PaperTrail, and others. Generating files rather than auto-executing gives developers visibility, auditability, and the ability to review before applying. It also makes idempotency (PKG-04) the migration's responsibility via Ecto's built-in migration tracking — not Threadline's.

**Implementation:** Use `Mix.Generator.create_file/2` to write the migration. Generate a timestamp-prefixed filename. Detect existing migrations to warn on re-run rather than overwrite.

---

### D-05: `audit_transactions` Schema — Phase 1 Columns Only

**Decision:** Phase 1 `audit_transactions` table includes only columns needed for correct capture. Columns owned by later phases (actor_ref, action_id, context_ref) are deferred and will be additive migrations in Phase 2.

Phase 1 `audit_transactions` columns:
```sql
id              uuid PRIMARY KEY DEFAULT gen_random_uuid()
occurred_at     timestamptz NOT NULL DEFAULT now()
source          text                          -- application name, nullable
meta            jsonb                         -- catch-all for future metadata
```

Phase 1 `audit_changes` columns:
```sql
id              uuid PRIMARY KEY DEFAULT gen_random_uuid()
transaction_id  uuid NOT NULL REFERENCES audit_transactions(id)
table_schema    text NOT NULL
table_name      text NOT NULL
table_pk        jsonb NOT NULL               -- row identity; preserved on DELETE
op              text NOT NULL CHECK (op IN ('insert','update','delete'))
data_after      jsonb                        -- null on delete
changed_fields  text[]                       -- field names that changed
captured_at     timestamptz NOT NULL DEFAULT now()
```

**Rationale:** Keeping Phase 1 columns minimal avoids shipping nullable columns with no semantics yet. Phase 2 adds `actor_ref jsonb`, `action_id uuid`, and `context_ref jsonb` to `audit_transactions` in a new migration. This is additive and safe.

---

### D-06: Context Propagation — Transaction-Row Insert, No SET LOCAL

**Decision:** Threadline's context propagation mechanism is to insert an `audit_transactions` row within the application's DB transaction (before or alongside the audited write). Triggers reference this row by reading the current `txid_current()` to group changes. `SET LOCAL` is never used for actor or context metadata.

**Rationale:** This is the core correctness guarantee from STATE.md: "PgBouncer safety is a schema constraint, not an implementation detail; cannot be retrofitted." `SET LOCAL` is session-scoped and silently wrong under PgBouncer transaction pooling. Triggers linking to the in-flight `audit_transactions` row via transaction ID is pooler-agnostic.

**Implementation detail:** The trigger function reads the PostgreSQL transaction ID (`txid_current()`) and attempts an upsert into `audit_transactions` keyed on `txid`. If an `audit_transactions` row already exists for this txid (from a prior write in the same transaction), it reuses it. If not, it creates one with null actor (Phase 2 fills this in). The application-side insert of actor context (Phase 2) uses the same txid key.

**Note on Carbonite:** Carbonite uses a `carbonite_transactions` table with a similar txid-keyed approach. If the Carbonite gate passes, verify that Carbonite's transaction record mechanism is compatible with this design. If Carbonite uses `SET LOCAL` anywhere, it fails the gate.

---

### D-07: Mix Aliases for CI Entrypoints

**Decision:** Define these aliases in `mix.exs`:

```elixir
aliases: [
  "verify.format": ["format --check-formatted"],
  "verify.credo": ["credo --strict"],
  "verify.test": ["test"],
  "ci.all": ["verify.format", "verify.credo", "verify.test"]
]
```

**Rationale:** Requirements CI-01 through CI-04 specify named entrypoints. These are trivial aliases but they must exist from Phase 1 so CI and CONTRIBUTING.md can cite them verbatim. `ci.all` chains them; a failure in any step aborts the chain via Mix's default short-circuit behavior.

---

### D-08: GitHub Actions CI Structure

**Decision:** Single workflow file `.github/workflows/ci.yml`. Three jobs with stable IDs:

```yaml
jobs:
  verify-format:     # id: verify-format (never rename this)
  verify-credo:      # id: verify-credo
  verify-test:       # id: verify-test — uses services: postgres
```

Trigger: `push` (all branches) + `pull_request`. All jobs run on push to main regardless of path filters.

PostgreSQL service in `verify-test`:
```yaml
services:
  postgres:
    image: postgres:16
    env:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: threadline_test
    ports: ["5432:5432"]
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

**Rationale:** Trigger tests require a real PostgreSQL instance (mocks cannot test DDL/triggers). PostgreSQL 16 in CI covers the ≥ 14 requirement with margin. Stable job `id:` fields are a named requirement (CI-05). Job names can be changed freely.

---

### D-09: Test Database Setup — Real PostgreSQL, Ecto Sandbox for Unit Tests

**Decision:** Integration tests (trigger behavior, migration DDL) use a real PostgreSQL database via Ecto without sandbox. Unit tests (schema structs, changeset validation, Mix task parsing logic) use ExUnit directly with no DB. A `DataCase` module provides DB-backed test helpers.

Tag integration tests with no special tag — all tests run in `mix test`. Do not silently exclude trigger tests (CI-07 requirement: no silent exclusions).

Test database configuration: `config/test.exs` sets `hostname: System.get_env("DB_HOST", "localhost")` so CI services and local Docker both work.

**Rationale:** The research is explicit: trigger behavior is DB-level; Ecto sandbox mocks will not catch DDL issues. Every test that touches `audit_changes` must run against a real PostgreSQL trigger. Running all tests together (no exclusion) is the honest default required by CI-07.

---

### D-10: CAP-10 — No Recursive Audit Triggers

**Decision:** The trigger generator (`mix threadline.gen.triggers`) never installs triggers on `audit_transactions` or `audit_changes` tables. This is enforced in the Mix task: if the user provides either table name, emit an error and exit non-zero.

**Rationale:** CAP-10 requires this. Recursive audit loops would corrupt the database. The guard belongs in the task, not just in documentation.

---

### D-11: `audit_changes.data_after` — Null on DELETE, Not Empty Object

**Decision:** On DELETE operations, `data_after` is `NULL`. The row's primary key is preserved in `table_pk` (JSONB). `changed_fields` is `NULL` on DELETE (no fields "changed" — the row was removed).

**Rationale:** CAP-03 specifies this. Storing an empty `{}` for `data_after` on DELETE would be misleading. The PK in `table_pk` is sufficient for identity reconstruction.

---

### D-12: CONTRIBUTING.md Skeleton — Phase 1 Deliverable

**Decision:** CONTRIBUTING.md is delivered in Phase 1 (DOC-04 requirement). It includes:
1. How to set up the development environment (deps, PostgreSQL)
2. How to run the test suite (`mix verify.test`)
3. How to run all CI checks (`mix ci.all`)
4. How to submit a PR

No contribution guidelines beyond this skeleton until Phase 4 polishes docs.

## AI Discretion

The following areas had no prescribed approach in requirements; decisions were made on best-practice grounds:

- **Schema column naming** (`table_pk` rather than `row_pk` or `primary_key`) — matches Carbonite's convention; reduces friction if Carbonite is adopted
- **UUID vs. integer PKs** — chose UUID (`gen_random_uuid()`) for all audit tables; avoids sequential ID predictability and works across multi-node environments without coordination
- **PostgreSQL version in CI** — chose PG 16 (not minimum 14) for CI; no reason to test on the floor when the ceiling is better supported
- **Mix task error handling** — tasks should emit descriptive error messages and exit non-zero, not raise; standard for Mix tasks that write files

## Existing Code Insights

### Reusable Assets

None — the codebase has no `.ex` files yet. Phase 1 initializes from scratch.

### Established Patterns

- **OSS DNA (`prompts/threadline-elixir-oss-dna.md`):** Named `mix verify.*` entrypoints, stable CI job IDs, honest test defaults — all encoded in D-07, D-08, D-09.
- **Prior art schema**: Carbonite's `carbonite_transactions` table uses `txid_current()` for grouping. If Carbonite passes the gate, its schema conventions inform Threadline's `audit_transactions` naming.

## Specific Ideas

- **Trigger SQL template**: The trigger function can be a PL/pgSQL function that does `INSERT INTO audit_transactions (id, occurred_at) VALUES (gen_random_uuid(), now()) ON CONFLICT DO NOTHING` keyed on txid, then `INSERT INTO audit_changes (...)` referencing it. This is the PgBouncer-safe pattern.
- **Migration idempotency**: Use `execute("CREATE TABLE IF NOT EXISTS ...")` or Ecto migration `create_if_not_exists` DSL so running `mix threadline.install` twice (PKG-04) is safe at the SQL level, not just at the migration tracking level.
- **Trigger generator**: `mix threadline.gen.triggers --tables users,posts` generates one migration per invocation with the trigger DDL for the specified tables.

## Deferred Ideas

- **`actor_ref` column on `audit_transactions`** — Phase 2; leave nullable for now
- **`action_id` FK on `audit_transactions`** — Phase 2; the nullable link between capture and semantics
- **Telemetry events** — Phase 3 requirement (HLTH-03 through HLTH-05); do not add in Phase 1
- **Trigger coverage health check** — Phase 3 requirement (HLTH-01, HLTH-02); `mix threadline.verify_coverage` is Phase 3
- **`data_before` / `changed_from` capture** — v2 requirement (BVAL-01); not in Phase 1 schema
- **Declarative partitioning docs** — mentioned in SUMMARY.md as a recommended option; defer to Phase 3/4 ops documentation
- **Oban/Plug integration** — Phase 2 (CTX-01, CTX-05)
