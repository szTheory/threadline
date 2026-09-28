# Phase 211: Read-Side Agreement - Context

**Gathered:** 2026-09-25
**Status:** Ready for planning

<domain>
## Phase Boundary

What a developer reads through `Threadline.history/3`, `row_history_query/3` and `as_of/4` must match exactly what the trigger stored, for every key shape Phase 210 captures:
- single integer keys (default Ecto bigserial)
- uuid and text keys
- composite keys
- `primary_key:` override tables
- rows written by 0.10.x triggers

Row lookups must use a shipped `audit_changes_row_history_idx`. This phase also includes the minimal operator-surface guard for composite-key rows.

Requirements: READ-01, READ-02, READ-03, READ-04, IDX-01, plus the read half of CONF-01. CONF-01 is marked Complete when this phase passes.

Out of scope:
- operator-UI design work (parked until 1.0.0)
- health checks and adopter twins (Phase 212)
- the 0.11.0 upgrade guide prose (Phase 213)
- widening the PK type allowlist

</domain>

<decisions>
## Implementation Decisions

### Carried forward from Phase 210 (locked; do not reopen)
- **Key column resolution** (210 D-18), in this order:
  1. the `primary_key:` override for the qualified table, via `Threadline.Capture.TriggerCaptureConfig.load()`
  2. `__schema__(:primary_key)` mapped through `field_source`
  3. otherwise raise
- **Matching** (210 D-04):
  - Use `=` equality against the full `table_pk` jsonb, never `@>`, because `x @> '{}'` is true for every row.
  - A row key must never be empty, and must never contain a null value.
- **Unresolved keys** (210 D-04): `{}` and `{"id":null}` both mean "unresolved". Neither can ever match a lookup.
- **Stored encoding** (210 D-05): `table_pk` holds `{"<column>": to_jsonb(row) ->> '<column>'}` for each key column, in key order. The 0.10.x triggers used the same `->>` text form for `id`. See `test/support/legacy_trigger_sql.ex`.

### Composite-key argument shape (public API, additive)
- **D-01:** The id argument of `history/3`, `row_history_query/3` and `as_of/4` accepts:
  - a **scalar**, for a single-column key only. This is unchanged from today.
  - a **keyword list or map** of that key's fields, with atom or string keys.
    - A single-column table accepts `[id: 1]` or `%{id: 1}` as well as the bare scalar, so one calling convention works for both table shapes.
    - String keys are matched against the known field names. **Never** call `String.to_atom/1` on caller input.
  - Rejected in this phase: a loaded Ecto struct as the id argument. It is deferred until adopters ask, because a mutated or stale in-memory struct would silently produce a wrong lookup.
  - **Reversibility:** costly. Once 0.11.0 ships, this becomes public API that adopters call. Loosening it later is additive; narrowing it would be breaking.
- **D-02:** Keys are **schema field names**, not DB column names. The library maps each field to its column through `field_source`.
  - For a `primary_key:` override table, map each declared column back to the schema field whose `field_source` equals it.
  - If a declared column has no mapped field, raise `ArgumentError` naming the column and the schema. The schema cannot address that key.
- **D-03:** Validation is eager, at the top of each of the three functions, before any query is built. It is one shared helper, e.g. `Threadline.Query.RowKey`, whose name is left to Claude.
  - Compare the given key set to the resolved set as `MapSet`s.
  - A missing, extra or misnamed key raises `ArgumentError`, and so do a nil value and a scalar passed for a composite table.
  - Messages list the expected fields in resolved key order, for example:
    - `expected keys [:tenant_id, :id] for MyApp.LineItem, got [:id]`
    - for a scalar: `expected keys [:tenant_id, :id] for MyApp.LineItem, got a single value; pass a map or keyword list with every key field`
  - A schema that has neither a primary key nor an override raises, naming the schema and pointing to `primary_key:` in `config/config.exs`.

### Encoding parity (Elixir value → stored text)
- **D-04:** PostgreSQL renders the comparison value exactly as the write path does. The read query builds the key with `jsonb_build_object('<col>', to_jsonb(CAST($n AS <pg_type>)) #>> '{}', ...)`, in key order, and compares it with `=` against `table_pk`.
  - Rendering values in Elixir is rejected.
  - A `::text` cast is also rejected. It was verified on PostgreSQL on 2026-09-25 to diverge from the stored form:
    - The trigger stores a timestamp as `2026-09-25T12:00:00.5`.
    - `::text` under `DateStyle='SQL, DMY'` gives `25/09/2026 12:00:00.5`.
    - `to_jsonb(x) #>> '{}'` matches byte for byte for timestamp, date, char(n) padding, bigint and uuid, and it ignores `DateStyle`.
  - **Reversibility:** reversible.
- **D-05:** The key columns' PostgreSQL types (`format_type`) come from a catalog lookup of `pg_attribute` for the qualified table at read time. The Ecto type is not used, because enums, domains and custom Ecto types make an Ecto→PG map incomplete.
  - The type string is interpolated only after identifier-safe handling, since it comes from `format_type` on the catalog, never from caller input.
  - Caching, such as a `:persistent_term` keyed by table, is Claude's discretion.
  - The no-catalog rule applies to trigger bodies only, not to reads.
- **D-06:** Whole-map `=` on `table_pk` keeps `audit_changes_row_history_idx` usable. Per-key `table_pk ->> 'col' = ...` predicates are forbidden on this path.

### Legacy and mixed rows (READ-03)
- **D-07:** No separate legacy branch is needed. Both eras store `->>` text for an `id` key, so one equality lookup returns rows from 0.10.x triggers and from regenerated triggers for the same record. A mixed-row fixture built from the frozen 0.10.2 SQL proves it.

### Operator-surface guard (READ-04, minimal)
- **D-08:** A row link is rendered only for a `table_pk` with exactly one key. `timeline_live/helpers.ex` `routeable_row_identity/2` already does this.
  - Fix `transaction_live.ex` `change_history_path/2`. It currently takes `Map.values() |> List.first()`, which links a composite row to the wrong record.
  - Composite, `{}` and `{"id":null}` rows render no row link.
  - A LiveView render test covers it. There is no UI redesign (parked).

### Row-history index (IDX-01)
- **D-09:** New installs: add `CREATE INDEX IF NOT EXISTS audit_changes_row_history_idx ON <audit_changes> (table_schema, table_name, table_pk, captured_at DESC, id DESC)`.
  - It goes in the existing install template in `lib/threadline/capture/migration.ex`, next to the current indexes, and respects the configured storage schema.
  - Pin it in `test/threadline/storage_schema_migration_contract_test.exs`.
  - **Reversibility:** one-way. The index is frozen into adopters' generated install migrations.
- **D-10:** Existing adopters: a new `mix threadline.gen.row_history_index` generator writes a migration with `@disable_ddl_transaction true`, `@disable_migration_lock true` and `CREATE INDEX CONCURRENTLY IF NOT EXISTS`.
  - Its `down` is `DROP INDEX CONCURRENTLY IF EXISTS`.
  - It carries a comment saying that a failed concurrent build leaves an INVALID index, which `IF NOT EXISTS` then skips, so drop it and rerun.
  - The generator and the install template share one SQL source so they cannot drift.
  - Phase 213's upgrade guide cites the generator as the primary path and the raw SQL as the fallback. That prose is not written here.
- **D-11:** Keep `audit_changes_table_name_idx`. `filter_by_table/2` filters by `table_name` alone, which a `table_schema`-leading index cannot serve.
- **D-12:** The EXPLAIN test sets `enable_seqscan = off` for its own session or transaction and asserts that `audit_changes_row_history_idx` appears in the plan, for both `history` and `as_of`. It never asserts on timing.
- **D-13:** The btree key-size limit (about 2.7 KB) is not a practical risk. Keys come from the Phase 210 allowlist (ints, uuid, short text, date, timestamp), so a composite `table_pk` is tens of bytes. One sentence in `guides/audit-indexing.md` records this so it is not relitigated.

### Claude's Discretion
- Module and function names for the row-key helper and the catalog-type lookup, and whether to cache.
- Whether `row_history_query/3` (`@doc false`) shares the exact helper or a thin wrapper.
- Doc updates in `guides/audit-indexing.md` and the `history`/`as_of` `@doc`s showing composite usage.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §Phase 211: goal, SC1–SC5, research flag
- `.planning/REQUIREMENTS.md`: READ-01..04, IDX-01, CONF-01 (traceability row says the read side is proven in 211)

### Upstream decisions (Phase 210)
- `.planning/phases/210-pk-agnostic-capture/210-CONTEXT.md`: D-01, D-04, D-05, D-14..D-18 (encoding, the unresolved-key rule, override config, read-side resolution order)
- `.planning/phases/210-pk-agnostic-capture/210-VERIFICATION.md`: what capture guarantees
- `.planning/phases/210-pk-agnostic-capture/210-REVIEW-FIX.md`: WR-03, the bare-identifier limit on `primary_key:` columns

### Code
- `lib/threadline/query.ex:363-445`: `history/3`, `row_history_query/3`, `as_of/4` (the `@>` call sites to replace)
- `lib/threadline/capture/primary_key_sql.ex`: row-key fragment and PK type allowlist
- `lib/threadline/capture/trigger_capture_config.ex`: `load/0`, which exposes `primary_key`
- `lib/threadline/capture/migration.ex`: install template indexes
- `lib/threadline/operator_surface/live/transaction_live.ex:401-407` and `lib/threadline/operator_surface/live/timeline_live/helpers.ex:141-170`: row-link identity
- `test/support/legacy_trigger_sql.ex`: frozen 0.10.2 SQL for mixed-row fixtures
- `lib/mix/tasks/threadline.gen.triggers.ex`: generator precedent for the new index generator

### Project
- `prompts/audit-lib-domain-model-reference.md`: domain model
- `prompts/threadline-elixir-oss-dna.md`: named entrypoints, doc contract tests
- `guides/audit-indexing.md`, `guides/upgrade-path.md`: doc surfaces to update or hand to Phase 213

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TriggerCaptureConfig.load/0` and `capture_tables_by_pair!`/`Naming.qualified`: resolve `"posts_tags"` and `"public.posts_tags"` to the same table on the read side.
- `Threadline.Test.LegacyTriggerSQL` (`v0_10_2_install_function/2`): builds real 0.10.x-captured rows.
- `Threadline.Test.MigrationHarness` and the real-PG patterns from Phases 209 and 210.

### Established Patterns
- `storage_opts/2` and `maybe_apply_scope/2` in `query.ex`: every read keeps honoring the storage schema prefix and scope options.
- Error style: `ArgumentError` for bad caller input at the API boundary, and `threadline:`-prefixed messages for migrate-time SQL errors.
- Doc contract tests keep README and guides aligned. Update assertions together with the docs.

### Integration Points
- `Threadline.history/3` and `as_of/4` in `lib/threadline.ex` delegate to `Threadline.Query`.
- The operator surface `/history/:table/:record_id` route consumes single-key identities only.

</code_context>

<specifics>
## Specific Ideas

- SC1's regression test must fail on the 0.10.x query code: a bigserial table where `history(User, 42)` returns `[]` under `@>` with integer 42.
- Cover the key types from the allowlist: bigint, uuid, text, date, timestamp (with a fractional-second value such as `.5`), char(n), an enum, and a domain. Round-trip each through capture and then `history`.

</specifics>

<deferred>
## Deferred Ideas

- Accepting a loaded Ecto struct as the id argument (`history(User, user)`). Add it if adopters ask.
- Operator-surface history pages for composite-key rows. This is UI design work, parked until 1.0.0.

</deferred>

---

*Phase: 211-read-side-agreement*
*Context gathered: 2026-09-25 (advisor mode, research-backed recommendations auto-accepted per maintainer instruction "auto follow your recommendations")*
