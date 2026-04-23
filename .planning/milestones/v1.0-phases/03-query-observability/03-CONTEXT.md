# Phase 3: Query & Observability - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning
**Source:** AI self-discuss (headless mode)

## Phase Boundary

Phase 3 delivers:
- `Threadline.history/2` — `AuditChange` records for a given row, ordered by `captured_at` desc
- `Threadline.actor_history/1` — `AuditTransaction` records for a given actor
- `Threadline.timeline/1` — filtered `AuditChange` records across tables/actors/time ranges
- `Threadline.Health.trigger_coverage/0` — table-by-table trigger installation status
- Three `:telemetry` events: `[:threadline, :transaction, :committed]`, `[:threadline, :action, :recorded]`, `[:threadline, :health, :checked]`
- `Threadline.Query` module as the internal query implementation backing the public API

Phase 3 does NOT deliver: README, ExDoc strings, Hex publish (Phase 4).

Phase 3 assumes Phase 2 is complete: `Threadline.Semantics.ActorRef`, `Threadline.Semantics.AuditAction`, `Threadline.Capture.AuditTransaction` (with `actor_ref jsonb` and `action_id` columns), and the Phase 2 migration are in place.

---

## Implementation Decisions

### D-01: Module Structure — `Threadline.Query` + `Threadline.Health`

**Decision:** Two new internal modules:

```
lib/threadline/query.ex         # Ecto.Query implementations for history, actor_history, timeline
lib/threadline/health.ex        # trigger_coverage/0 and health telemetry
```

The top-level `Threadline` module (`lib/threadline.ex`) gains three public delegating functions:
```elixir
defdelegate history(schema_module, id, opts \\ []), to: Threadline.Query
defdelegate actor_history(actor_ref, opts \\ []), to: Threadline.Query
defdelegate timeline(filters \\ [], opts \\ []), to: Threadline.Query
```

`Threadline.Health` is a standalone public module — not delegated through `Threadline` because it is an operational concern, not a data-access concern. Callers call `Threadline.Health.trigger_coverage/0` directly.

**Rationale:** Keeps `lib/threadline.ex` as a thin public API facade (same pattern as Ecto's `Ecto` module delegating to `Ecto.Query`). Internal query logic is isolatable and testable without the facade. `Threadline.Health` as a named module matches HLTH-01's explicit reference to it in the requirements.

---

### D-02: Query Function Signatures and Return Types

**Decision:**

```elixir
# Returns [%AuditChange{}, ...] ordered by captured_at DESC
Threadline.history(schema_module, id, repo: MyApp.Repo)

# Returns [%AuditTransaction{}, ...] ordered by occurred_at DESC
Threadline.actor_history(%ActorRef{}, repo: MyApp.Repo)

# Returns [%AuditChange{}, ...] ordered by captured_at DESC
Threadline.timeline([table: "users", actor_ref: ref, from: dt, to: dt], repo: MyApp.Repo)
```

All three return plain lists (not `{:ok, list}` tuples). DB errors propagate as exceptions — consistent with `Ecto.Repo.all/2` behavior. No opaque wrapper types (QUERY-05).

`repo:` is a required option for all three functions (no global config lookup). Consistent with Phase 2's `record_action/2` decision (D-06 in 02-CONTEXT.md).

**Rationale:** QUERY-05 requires plain Ecto structs. Returning `{:ok, [structs]}` would force callers to unwrap before using standard Enum/Stream functions, which is friction without benefit for read operations. Write operations return tagged tuples because validation failures are expected; query failures are exceptional. The explicit `repo:` requirement keeps the library config-free.

---

### D-03: `history/2` — Schema Module to Table Name Resolution

**Decision:** `history/2` takes an Ecto schema module and a record ID. Table name is resolved via `schema_module.__schema__(:source)`. Primary key column is resolved via `schema_module.__schema__(:primary_key)` — returns `[:id]` for standard schemas; take the first key.

The query filters `audit_changes` by `table_name = schema_module.__schema__(:source)` AND `table_pk @> '{"id": "..."}'::jsonb` (JSONB containment on `table_pk`). `table_pk` is stored as a JSONB map with column names as keys.

For non-UUID primary keys (integer IDs), the containment query still works: `table_pk @> '{"id": 42}'::jsonb`. Ecto's `:map` type handles JSON value encoding.

**Rationale:** Using `__schema__/1` introspection is the standard Ecto pattern — avoids requiring callers to pass table names as strings. JSONB containment on `table_pk` is the correct approach since `table_pk` is a free-form map (could have composite keys). Phase 1 decision (D-11 in 01-CONTEXT.md) confirmed `table_pk` stores the row identity.

---

### D-04: `actor_history/1` — JSONB Containment Query

**Decision:** `actor_history/1` takes an `%ActorRef{}` and queries `audit_transactions` where `actor_ref @> '{"type": "user", "id": "123"}'::jsonb`.

Uses `Ecto.Query.where` with a fragment:
```elixir
where: fragment("? @> ?::jsonb", at.actor_ref, ^ActorRef.to_map(actor_ref))
```

Returns `[%AuditTransaction{}]` with `preload: [:changes]` as an optional keyword argument (`:preload` option, default `false`).

Anonymous actor history (`type: "anonymous"`) queries by type only: `actor_ref @> '{"type": "anonymous"}'::jsonb`. This returns all anonymous transactions.

**Rationale:** Phase 2 decision D-02 (02-CONTEXT.md) noted that a GIN index on `audit_actions.actor_ref` should be added for this query. The same GIN index on `audit_transactions.actor_ref` is needed here. This index decision is confirmed for Phase 3 (add in the Phase 2 migration or as a Phase 3 migration). JSONB containment is the natural query for a stored ActorRef value object.

---

### D-05: `timeline/1` — Filter Options and Query Composition

**Decision:** `timeline/1` accepts a keyword list of filters:

```elixir
Threadline.timeline(
  table: "users",          # string or atom; filters audit_changes.table_name
  actor_ref: %ActorRef{},  # JSONB containment on audit_transactions.actor_ref (requires JOIN)
  from: ~U[2026-01-01 00:00:00Z],  # audit_changes.captured_at >= from
  to: ~U[2026-12-31 23:59:59Z],    # audit_changes.captured_at <= to
  repo: MyApp.Repo
)
```

Implementation builds a composable `Ecto.Query` by piping through filter functions:
```elixir
base_query()
|> filter_by_table(opts[:table])
|> filter_by_actor(opts[:actor_ref])
|> filter_by_from(opts[:from])
|> filter_by_to(opts[:to])
|> repo.all()
```

Each `filter_by_*` function receives the query and an option value; returns the query unchanged if the option is `nil`. This pipeline pattern is testable — each filter can be unit-tested by passing a queryable and inspecting the resulting SQL.

`actor_ref:` filter requires a JOIN to `audit_transactions`. When this filter is present, the query joins `audit_changes` to `audit_transactions` on `transaction_id`. Without the filter, no join is needed (avoids unnecessary join overhead).

**Rationale:** QUERY-03 specifies these four filter options. The composable private function pipeline is the idiomatic Ecto pattern (used in Phoenix LiveView, Ash, and Flop). Conditional joining avoids performance regression for common use cases that don't filter by actor.

---

### D-06: `trigger_coverage/0` — PostgreSQL System Catalog Query

**Decision:** `trigger_coverage/0` queries two things:
1. All user tables in the `public` schema: `pg_tables WHERE schemaname = 'public'`
2. All tables with a Threadline trigger installed: `pg_trigger JOIN pg_class WHERE trigger_name LIKE 'threadline_%'`

Threadline trigger naming convention (established in Phase 1): `threadline_<table_name>_audit`. This is the naming convention `Threadline.Capture.TriggerSQL` uses when generating trigger DDL.

Returns a list of tagged tuples:
```elixir
[{:covered, "users"}, {:covered, "posts"}, {:uncovered, "orders"}, {:uncovered, "audit_transactions"}]
```

Audit tables (`audit_transactions`, `audit_changes`, `audit_actions`) are excluded from the "uncovered" list — they are not expected to have triggers (CAP-10).

`repo:` is required (same as query functions).

Emits `[:threadline, :health, :checked]` telemetry after computing coverage: `%{covered: n, uncovered: m}`.

**Rationale:** HLTH-01 and HLTH-02 define the expected API shape. Querying the PostgreSQL system catalog is the only reliable way to check trigger installation without maintaining a separate registry. The audit tables exclusion prevents false "uncovered" warnings that would confuse operators.

---

### D-07: Telemetry Design — Three Events, Pragmatic Timing

**Decision:**

**`[:threadline, :action, :recorded]`** (HLTH-04): Emitted from `Threadline.record_action/2` (Phase 2) after successful `Repo.insert`. Phase 3 *adds* this call to the existing function. Measurements: `%{status: :ok | :error}`. This is straightforward — the insert is application-initiated code.

**`[:threadline, :health, :checked]`** (HLTH-05): Emitted from `Threadline.Health.trigger_coverage/0` after computing coverage. Measurements: `%{covered: n, uncovered: m}`. Straightforward — app-initiated.

**`[:threadline, :transaction, :committed]`** (HLTH-03): This is the hard case — `AuditTransaction` records are created by PostgreSQL triggers, not by application code. The application has no natural hook point for per-trigger-commit telemetry.

**Decision for HLTH-03**: Emit from `Threadline.record_action/2` as a proxy. When `record_action/2` succeeds, emit `[:threadline, :transaction, :committed]` with `%{table_count: 0}`. The `table_count: 0` is honest — the action was recorded but transaction linkage is done post-facto (per Phase 2 D-05). Callers that need accurate table counts after explicit `Repo.transaction` calls can emit the event themselves using a documented `Threadline.Telemetry.transaction_committed/1` helper.

Alternatively: Phase 3 introduces `Threadline.Telemetry.transaction_committed(%AuditTransaction{}, table_count: n)` as a public helper that emits the standardized event. Application code calls this after a known DB transaction commit where they have the transaction record. Document this as the integration point.

**Rationale:** The trigger fires at DB level with no Elixir call stack. A Postgrex LISTEN/NOTIFY subscription would work but adds infrastructure complexity (OTP process, reconnection logic) that is out of scope for Phase 3 and not required by HLTH-03 literally. The `Threadline.Telemetry` helper pattern is pragmatic: it gives the user the instrumented surface without forcing them to adopt a Threadline-managed subscription. Emit from `record_action/2` satisfies the requirement for the common case.

---

### D-08: Phase 2 Telemetry Addition — Patch `record_action/2`

**Decision:** Phase 3 adds `:telemetry` calls to the `Threadline.record_action/2` function implemented in Phase 2. This is a modification to `lib/threadline.ex` (or wherever `record_action/2` lives), adding `telemetry` as a Phase 3 deliverable rather than a Phase 2 deliverable (per the Phase 2 deferred section in 02-CONTEXT.md).

The modification is minimal: add `require Telemetry` (or `:telemetry.execute/3`) after the `case Repo.insert(...)` call.

**Rationale:** Phase 2 explicitly deferred HLTH-04 to Phase 3. Phase 3 is the correct place to add all three telemetry events. Modifying `record_action/2` in Phase 3 is consistent with the phased design.

---

### D-09: GIN Index on `audit_transactions.actor_ref`

**Decision:** Phase 3 includes a migration adding a GIN index on `audit_transactions.actor_ref` if Phase 2 did not already add it.

```sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS audit_transactions_actor_ref_gin
  ON audit_transactions USING GIN (actor_ref);
```

Phase 2 planned a GIN index on `audit_actions.actor_ref` (02-CONTEXT.md Specific Ideas). Phase 3 needs the same index on `audit_transactions.actor_ref` for `actor_history/1` performance.

Migration filename: `20260103000000_threadline_query_indexes.exs` (additive, non-breaking).

**Rationale:** JSONB containment queries (`@>`) without a GIN index perform a sequential scan. For production audit tables with millions of rows, this is unacceptable. `CONCURRENTLY` allows the index to be created without locking the table.

---

## AI Discretion

Areas where requirements left room for judgment:

- **Return type: list vs. tagged tuple** — chose plain list (following `Repo.all/2` convention) over `{:ok, list}`. DB errors are exceptional, not expected validation failures. Unwrapping tuples in every caller adds boilerplate with no semantic value.
- **`timeline/1` signature: positional filters vs. options** — chose keyword list for filters (`timeline(table: "users", from: dt)`) over a filter map or positional args. Keyword lists are idiomatic Elixir for optional parameters; they compose naturally with `Keyword.merge` for higher-level helpers.
- **`trigger_coverage/0` scope: `public` schema only** — could have scoped to all schemas. `public` is the correct default for standard Phoenix/Ecto applications. Multi-schema support is a v2 concern (multi-tenant is explicitly out of scope in REQUIREMENTS.md).
- **Telemetry for HLTH-03: proxy via `record_action/2`** — the cleanest option given the trigger-level commit problem. Documented honestly. Operators needing accurate per-transaction telemetry can subscribe via `Threadline.Telemetry.transaction_committed/1`.
- **`actor_history/1` anonymous behavior** — decided to return all anonymous transactions (by type only) rather than returning an error. Anonymous actors are legitimate; they just lack identity. Consistent with ACTR-03.

---

## Existing Code Insights

### Reusable Assets

- `Threadline.Capture.AuditChange` (`lib/threadline/capture/audit_change.ex`) — primary struct for `history/2` and `timeline/1` results. Already has `belongs_to(:transaction, ...)` which Phase 3 uses for actor_ref join.
- `Threadline.Capture.AuditTransaction` (`lib/threadline/capture/audit_transaction.ex`) — primary struct for `actor_history/1`. Phase 2 should have added `actor_ref` and `action_id` columns to this schema.
- `Threadline.Semantics.ActorRef` — used in `actor_history/1` parameter and JSONB query construction via `ActorRef.to_map/1`.
- `Threadline.Capture.TriggerSQL` (`lib/threadline/capture/trigger_sql.ex`) — contains the trigger naming convention. Phase 3's `trigger_coverage/0` must use the same naming convention to correctly identify Threadline-installed triggers.
- Test infrastructure (`DataCase`, `Test.Repo`) — fully reusable for Phase 3 integration tests. Query tests need real PostgreSQL with audit data seeded.

### Established Patterns

- **Ecto.Query composable pipeline**: the `filter_by_*` private function pattern is not yet in the codebase but is the dominant pattern across Phoenix ecosystem apps. Phase 3 establishes it for Threadline.
- **Explicit `repo:` option**: established in Phase 2's `record_action/2`. Phase 3 query functions follow the same convention consistently.
- **Raw SQL via `fragment/1`**: JSONB containment (`@>`) requires `Ecto.Query.fragment/1`. Phase 1's trigger SQL generator established precedent for raw SQL in this codebase.

---

## Specific Ideas

- **`filter_by_table/2` with atom support**: `table: :users` should work alongside `table: "users"` — convert atom to string via `to_string/1` in the filter function.
- **`trigger_coverage/0` SQL**: Use two queries joined in Elixir (not a SQL JOIN) for clarity:
  1. `SELECT tablename FROM pg_tables WHERE schemaname = 'public'`
  2. `SELECT DISTINCT c.relname FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid WHERE t.tgname LIKE 'threadline_%'`
  Then compute `covered` and `uncovered` sets in Elixir with `MapSet` difference.
- **`Threadline.Telemetry` module**: a small module at `lib/threadline/telemetry.ex` with `transaction_committed/2` and `action_recorded/2` as public helpers. Keeps telemetry call sites consolidated. `:telemetry` stays an optional dependency (not added to `mix.exs` — callers who don't use telemetry don't pay the dep).

Wait: `:telemetry` should be a dep if we call `:telemetry.execute/3`. Check if it's already in `mix.exs` from Phase 1. If not, add it in Phase 3 as `{:telemetry, "~> 1.0"}`.

- **`timeline/1` `from:`/`to:` inclusivity**: `from:` is inclusive (`>=`), `to:` is inclusive (`<=`). Standard for time range filters; document in `@doc`.

---

## Deferred Ideas

- **`Threadline.history/3` with options**: a `limit:` or `page:` option for pagination. Useful but not required by QUERY-01. Deferred to v2.
- **`Threadline.timeline/1` result ordering**: currently ordered by `captured_at` desc. A `order:` option (`:asc | :desc`) would be ergonomic. Deferred.
- **Postgrex NOTIFY listener for HLTH-03**: a proper `Threadline.TransactionObserver` GenServer that subscribes to PostgreSQL NOTIFY events and emits accurate `[:threadline, :transaction, :committed]` telemetry per transaction. Correct solution but out of scope for Phase 3; document as a v2 enhancement.
- **`Threadline.Health.trigger_coverage/1` with explicit table list**: `trigger_coverage(expected: [:users, :posts])` to check specific tables rather than all public tables. Useful for large schemas; defer to v2.
- **Query result streaming**: `Threadline.stream_timeline/1` returning an Elixir `Stream` for large result sets. Defer to v2.
- **`mix threadline.verify_coverage` Mix task**: v2 requirement (TOOL-01). Phase 3 adds the `trigger_coverage/0` function; the Mix task wrapper is v2.
- **As-of queries**: explicitly out of scope per REQUIREMENTS.md "Out of Scope" table.
