# RESEARCH.md — Phase 3: Query & Observability

**Written:** 2026-04-23
**Confidence scale:** HIGH = verified in codebase / docs; MEDIUM = inferred from patterns; LOW = assumption requiring validation

---

## 1. Codebase State Entering Phase 3

### 1.1 What Exists (verified)

| File | Status | Notes |
|------|--------|-------|
| `lib/threadline/capture/audit_change.ex` | EXISTS | Schema confirmed: `table_name`, `table_pk` (`:map`/JSONB), `op`, `data_after`, `changed_fields`, `captured_at`, `belongs_to(:transaction, ...)` |
| `lib/threadline/capture/audit_transaction.ex` | EXISTS | Schema confirmed: `txid`, `occurred_at`, `source`, `meta`, `has_many(:changes, ...)`. **No `actor_ref` column yet.** |
| `lib/threadline/capture/trigger_sql.ex` | EXISTS | Trigger naming convention is `threadline_audit_<table_name>` (see §2.1 below — conflicts with 03-CONTEXT.md) |
| `lib/threadline.ex` | EXISTS | Empty façade — no delegating functions yet |
| `mix.exs` | EXISTS | `:telemetry ~> 1.2` is a runtime dep — no action needed |

**Confidence: HIGH** — all files read directly.

### 1.2 What Phase 2 Must Deliver Before Phase 3 Can Execute

Phase 3 assumes these exist (from 03-CONTEXT.md D-01 and D-04):

- `Threadline.Semantics.ActorRef` with `to_map/1`
- `Threadline.Semantics.AuditAction` schema
- `audit_transactions.actor_ref` JSONB column (Phase 2 migration)
- `Threadline.record_action/2` function in `lib/threadline.ex`

**None of these are present in the current lib/ tree.** If Phase 2 code is not yet committed, Phase 3 planning must sequence plans accordingly — do not assume Phase 2 schema columns exist at plan start.

**Confidence: HIGH** — glob of `lib/**/*.ex` returned only capture layer files.

---

## 2. Critical Discrepancy: Trigger Naming Convention

**03-CONTEXT.md (D-06) states:** trigger names follow pattern `threadline_<table_name>_audit`

**Actual code in `TriggerSQL.create_trigger/1`:**
```elixir
"CREATE TRIGGER threadline_audit_#{table_name} ..."
```

The real pattern is **`threadline_audit_<table_name>`** (prefix, not suffix).

The `trigger_coverage/0` implementation in `Threadline.Health` must use:
```sql
WHERE t.tgname LIKE 'threadline_audit_%'
```
...NOT `'threadline_%_audit'`.

**Confidence: HIGH** — verified directly in `lib/threadline/capture/trigger_sql.ex:91`.

**Action for planner:** Flag this in plan 03-01 as a required correction from the context doc.

---

## 3. Telemetry Dependency

`:telemetry ~> 1.2` is already in `mix.exs` as a runtime dependency.

Calling `:telemetry.execute/3` requires no `mix.exs` changes.

The context doc's note ("Wait: `:telemetry` should be a dep if we call `:telemetry.execute/3`. Check if it's already in `mix.exs`") is resolved: **it is already there.**

**Confidence: HIGH.**

---

## 4. Query Implementation Patterns

### 4.1 Ecto JSONB Containment (`@>`)

Elixir pattern for querying `table_pk`:
```elixir
where: fragment("? @> ?::jsonb", ac.table_pk, ^%{"id" => id})
```
For `actor_ref` on `audit_transactions`:
```elixir
where: fragment("? @> ?::jsonb", at.actor_ref, ^ActorRef.to_map(actor_ref))
```

`ActorRef.to_map/1` must produce a plain map with string keys. This is the contract between Phase 2 and Phase 3.

**Confidence: HIGH** (standard Ecto/PostgreSQL pattern).

### 4.2 Schema Introspection for `history/2`

`schema_module.__schema__(:source)` returns table name as string. `schema_module.__schema__(:primary_key)` returns list of atom key names (e.g., `[:id]`). Take `List.first/1` for simple schemas.

**Confidence: HIGH** — documented Ecto behavior, stable API since Ecto 2.x.

### 4.3 GIN Index Requirement

`actor_history/1` uses JSONB containment on `audit_transactions.actor_ref`. Without a GIN index this is a sequential scan.

Index DDL (confirmed correct from 03-CONTEXT.md D-09):
```sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS audit_transactions_actor_ref_gin
  ON audit_transactions USING GIN (actor_ref);
```

`CONCURRENTLY` cannot run inside a transaction block — the Phase 3 migration must call `execute/1` with `[disable_ddl_transaction: true, disable_migration_lock: true]`.

**Confidence: HIGH** (standard Ecto concurrent index migration pattern).

---

## 5. Health Check Implementation

### 5.1 System Catalog Queries

Two queries, resolved in Elixir:

**Query 1 — all user tables in `public` schema:**
```sql
SELECT tablename FROM pg_tables WHERE schemaname = 'public'
```

**Query 2 — tables with a Threadline trigger:**
```sql
SELECT DISTINCT c.relname
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE t.tgname LIKE 'threadline_audit_%'
```

Exclude audit tables (`audit_transactions`, `audit_changes`, `audit_actions`) from "uncovered" list to satisfy CAP-10.

**Confidence: HIGH** — standard PostgreSQL system catalog queries; pattern matches 03-CONTEXT.md D-06.

### 5.2 Repo Usage for Raw SQL

These system catalog queries can be run with `Ecto.Adapters.SQL.query!/3` via the caller-provided repo:
```elixir
repo.__adapter__() |> ...
# or simply:
Ecto.Adapters.SQL.query!(repo, sql, [])
```

**Confidence: HIGH** — standard pattern for raw queries in Ecto library code.

---

## 6. Telemetry Event Design

All three events per requirements:

| Event | Emitted from | Measurements |
|-------|-------------|--------------|
| `[:threadline, :transaction, :committed]` | `record_action/2` (proxy, Phase 3 patch) OR `Threadline.Telemetry.transaction_committed/2` helper | `%{table_count: n}` |
| `[:threadline, :action, :recorded]` | `record_action/2` (Phase 3 patch to Phase 2 code) | `%{status: :ok \| :error}` |
| `[:threadline, :health, :checked]` | `Threadline.Health.trigger_coverage/0` | `%{covered: n, uncovered: m}` |

The proxy approach for `[:threadline, :transaction, :committed]` is pragmatic — PostgreSQL triggers have no Elixir call stack hook. Document `Threadline.Telemetry.transaction_committed/2` as the integration point for precise per-transaction telemetry.

**Confidence: HIGH** (design rationale solid in 03-CONTEXT.md D-07).

---

## 7. Module Structure

```
lib/threadline/query.ex      # history/2, actor_history/1, timeline/1 + private filter pipeline
lib/threadline/health.ex     # trigger_coverage/0 + telemetry emit
lib/threadline/telemetry.ex  # transaction_committed/2, action_recorded/2 public helpers
```

`lib/threadline.ex` gains three `defdelegate` calls for history/actor_history/timeline.

No new Mix tasks in Phase 3 (TOOL-01 is v2).

**Confidence: HIGH** — matches 03-CONTEXT.md D-01, cross-checked against requirements.

---

## 8. Risks & Watch-Outs for Planner

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Phase 2 code not present — actor_ref JSONB column missing | HIGH | Plan 03-01 must verify Phase 2 migration ran; include fallback plan if column absent |
| Trigger naming pattern in CONTEXT doc is wrong | HIGH | Use `threadline_audit_%` (not `threadline_%_audit`) — verified in source |
| `CREATE INDEX CONCURRENTLY` inside migration transaction | MEDIUM | Use `disable_ddl_transaction: true` option in migration |
| Anonymous actor_history returns ALL anonymous transactions | LOW | Document behavior in @doc; acceptable per ACTR-03 |
| `:telemetry` was listed as optional in context doc | LOW | Already a runtime dep — no action needed |

---

## 9. Suggested Plan Breakdown (for planner)

**03-01: Query Core** — `Threadline.Query` module with `history/2`, `actor_history/1`, `timeline/1`; delegating functions on `Threadline`; GIN index migration. Integration tests against real Postgres.

**03-02: Health + Telemetry** — `Threadline.Health.trigger_coverage/0`; `Threadline.Telemetry` helper module; patch `record_action/2` (Phase 2 code) to emit `:action, :recorded` and proxy `:transaction, :committed`; emit `:health, :checked` from coverage function. Integration tests for all three events.

This breakdown keeps DB query logic isolated from instrumentation logic and allows 03-01 to be verified green before 03-02 touches cross-cutting concerns.

**Confidence: MEDIUM** — reasonable split based on dependency graph; planner may restructure.
