# Phase 211: Read-Side Agreement - Research

**Researched:** 2026-09-25
**Domain:** Ecto/PostgreSQL read-side key matching, parameterized raw SQL, PostgreSQL catalog type resolution, Phoenix LiveView row-identity rendering
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Carried forward from Phase 210 (locked; do not reopen): key column resolution order
(`primary_key:` override → `__schema__(:primary_key)` via `field_source` → raise);
matching uses `=` on the full `table_pk`, never `@>`; `{}` and `{"id":null}` both mean
"unresolved" and never match; stored encoding is `{"<column>": to_jsonb(row) ->> '<column>'}`
per key column, in key order (0.10.x triggers used the same `->>` text form for `id`).

**Composite-key argument shape (public API, additive):**
- D-01: `history/3`, `row_history_query/3`, `as_of/4`'s id argument accepts a scalar
  (single-column key only, unchanged) or a keyword list/map of the key's fields (atom or
  string keys). A single-column table accepts `[id: 1]`/`%{id: 1}` as well as the bare
  scalar. String keys are matched against known field names — never `String.to_atom/1` on
  caller input. A loaded Ecto struct as the id argument is rejected this phase (deferred).
  Reversibility: costly (public API once 0.11.0 ships).
- D-02: Keys are schema field names, not DB column names, mapped via `field_source`. For
  a `primary_key:` override table, map each declared column back to the schema field
  whose `field_source` equals it; a declared column with no mapped field raises
  `ArgumentError` naming the column and schema.
- D-03: Validation is eager, at the top of each of the three functions, before any query
  is built — one shared helper, e.g. `Threadline.Query.RowKey` (name left to Claude).
  Compare given vs. resolved key sets as `MapSet`s. Missing/extra/misnamed key, nil value,
  or scalar-for-composite-table all raise `ArgumentError`. Messages list expected fields
  in resolved key order, e.g. `expected keys [:tenant_id, :id] for MyApp.LineItem, got
  [:id]` and, for a scalar, `expected keys [:tenant_id, :id] for MyApp.LineItem, got a
  single value; pass a map or keyword list with every key field`. A schema with neither a
  primary key nor an override raises, naming the schema and pointing to `primary_key:` in
  `config/config.exs`.

**Encoding parity (Elixir value → stored text):**
- D-04: PostgreSQL renders the comparison value exactly as the write path does. The read
  query builds the key with `jsonb_build_object('<col>', to_jsonb(CAST($n AS <pg_type>))
  #>> '{}', ...)`, in key order, compared with `=` against `table_pk`. Rendering values in
  Elixir is rejected. A `::text` cast is also rejected — verified on PostgreSQL 2026-09-25
  to diverge under `DateStyle='SQL, DMY'` for timestamps, where `to_jsonb(x) #>> '{}'`
  matches byte for byte for timestamp, date, char(n) padding, bigint and uuid and ignores
  `DateStyle`. Reversibility: reversible.
- D-05: Key columns' PostgreSQL types (`format_type`) come from a catalog lookup of
  `pg_attribute` for the qualified table at read time — not the Ecto type, since enums,
  domains and custom Ecto types make an Ecto→PG map incomplete. The type string is
  interpolated only after identifier-safe handling, since it comes from `format_type` on
  the catalog, never caller input. Caching (e.g. `:persistent_term` keyed by table) is
  Claude's discretion. The no-catalog rule applies to trigger bodies only, not reads.
- D-06: Whole-map `=` on `table_pk` keeps `audit_changes_row_history_idx` usable. Per-key
  `table_pk ->> 'col' = ...` predicates are forbidden on this path.

**Legacy and mixed rows (READ-03):**
- D-07: No separate legacy branch is needed. Both eras store `->>` text for an `id` key,
  so one equality lookup returns rows from 0.10.x triggers and from regenerated triggers
  for the same record. A mixed-row fixture built from the frozen 0.10.2 SQL proves it.

**Operator-surface guard (READ-04, minimal):**
- D-08: A row link is rendered only for a `table_pk` with exactly one key.
  `timeline_live/helpers.ex` `routeable_row_identity/2` already does this. Fix
  `transaction_live.ex` `change_history_path/2` — it currently takes `Map.values() |>
  List.first()`, which links a composite row to the wrong record. Composite, `{}` and
  `{"id":null}` rows render no row link. A LiveView render test covers it; no UI redesign
  (parked).

**Row-history index (IDX-01):**
- D-09: New installs: `CREATE INDEX IF NOT EXISTS audit_changes_row_history_idx ON
  <audit_changes> (table_schema, table_name, table_pk, captured_at DESC, id DESC)` — in
  the existing install template in `lib/threadline/capture/migration.ex`, next to the
  current indexes, respecting the configured storage schema. Pinned in
  `test/threadline/storage_schema_migration_contract_test.exs`. Reversibility: one-way
  (frozen into adopters' generated install migrations).
- D-10: Existing adopters: a new `mix threadline.gen.row_history_index` generator writes
  a migration with `@disable_ddl_transaction true`, `@disable_migration_lock true`, and
  `CREATE INDEX CONCURRENTLY IF NOT EXISTS`; `down` is `DROP INDEX CONCURRENTLY IF
  EXISTS`; a comment notes a failed concurrent build leaves an INVALID index that `IF NOT
  EXISTS` then skips — drop and rerun. The generator and install template share one SQL
  source so they cannot drift. Phase 213's upgrade guide cites the generator as primary,
  raw SQL as fallback (not written here).
- D-11: Keep `audit_changes_table_name_idx` — `filter_by_table/2` filters by `table_name`
  alone, which a `table_schema`-leading index cannot serve.
- D-12: The EXPLAIN test sets `enable_seqscan = off` for its own session/transaction and
  asserts `audit_changes_row_history_idx` appears in the plan, for both `history` and
  `as_of`. Never asserts on timing.
- D-13: The btree key-size limit (~2.7 KB) is not a practical risk given the Phase 210
  allowlist. One sentence in `guides/audit-indexing.md` records this so it is not
  relitigated.

### Claude's Discretion

- Module and function names for the row-key helper and the catalog-type lookup, and
  whether to cache.
- Whether `row_history_query/3` (`@doc false`) shares the exact helper or a thin wrapper.
- Doc updates in `guides/audit-indexing.md` and the `history`/`as_of` `@doc`s showing
  composite usage.

### Deferred Ideas (OUT OF SCOPE)

- Accepting a loaded Ecto struct as the id argument (`history(User, user)`) — add if
  adopters ask.
- Operator-surface history pages for composite-key rows — UI design work, parked until
  1.0.0.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|--------------|---------------------|
| READ-01 | `history/3`, `row_history_query/3`, `as_of/4` return captured rows for integer-PK (bigserial) tables; fixes the text-vs-integer mismatch | Root cause identified and fixed by Pattern 1 (raw-SQL PostgreSQL-side rendering) + the `=`-not-`@>` change; verified byte-for-byte against real PostgreSQL for the bigint case |
| READ-02 | Composite-key row history via keyword list/map of key columns; `ArgumentError` naming expected columns on mismatch | `Threadline.Query.RowKey` design (resolve!/validate!) directly implements D-01/D-02/D-03; `__schema__(:field_source, field)` VERIFIED as the field↔column mapping primitive |
| READ-03 | Pre-0.11.0-captured rows and regenerated-trigger-captured rows for the same row both return from one `history` call | D-07 (no separate legacy branch needed) confirmed structurally — both eras store the same `->>`-text shape; `test/support/legacy_trigger_sql.ex` fixture reused for the test |
| READ-04 | Operator-surface links for composite-key rows show no link rather than a wrong-row link | Exact bug located and quoted: `transaction_live.ex:403`'s `Map.values() |> List.first()`; `timeline_live/helpers.ex`'s existing single-key guard is the correct pattern to mirror |
| IDX-01 | New installs create `audit_changes_row_history_idx`; existing adopters get a `CREATE INDEX CONCURRENTLY` migration; EXPLAIN proves `history`/`as_of` use the index | Index DDL and generator precedent (`migration.ex`, `gen.triggers.ex`) identified; EXPLAIN usage independently proven against real PostgreSQL with `enable_seqscan = off` |
| CONF-01 (read half) | History reads for a `primary_key:`-override table use the same declared columns as capture | D-18's resolution order (override → `__schema__(:primary_key)` → raise) implemented via `TriggerCaptureConfig.load/1`, already proven to expose `primary_key:` per Phase 210 |
</phase_requirements>

## Summary

The write side (Phase 210) always stores `table_pk` values as **JSON strings**, never
JSON numbers/booleans, because every trigger-side extraction goes through PostgreSQL's
`->>` text operator or `to_jsonb(x) #>> '{}'` (both return `text`, then get wrapped in
`jsonb_build_object`). This single fact — verified in this session by reading
`lib/threadline/capture/primary_key_sql.ex:31-52` and `test/support/legacy_trigger_sql.ex:114-140`
— is the root cause of READ-01's bug (`@>` compares `{"id": 42}` (Elixir int, JSON number)
against a stored `{"id": "42"}` (JSON string), which never matches) and it is also what
makes the read-side fix tractable: the read side only has to reproduce PostgreSQL's own
text rendering of a typed value, then build a plain jsonb object of strings, then compare
with `=` (never `@>`) against `table_pk`.

Ecto's `fragment/1` macro **cannot** take a runtime-built SQL string (verified by reading
`deps/ecto/lib/ecto/query/builder.ex:630-644`: any non-compile-time-literal first argument
raises `"to prevent SQL injection attacks, fragment(...) does not allow strings to be
interpolated"`), and `splice/1` only varies argument *count* inside a fixed compile-time
template, not the type-cast text inside each element. A composite key needs a different
`CAST($n AS <type>)` per column, and both the number of columns and the type text are
only known at runtime (they come from `pg_attribute`/`format_type` on the adopter's own
table). **The Ecto query DSL cannot express this.** The only sound construction is the one
`lib/threadline/capture/primary_key_sql.ex` already uses for migrate-time DDL: build the
SQL text with plain Elixir string interpolation (column names and the catalog type string
are validated/catalog-sourced, never caller input) and run it as **raw parameterized SQL**
via `Ecto.Adapters.SQL.query!/4` with `$1..$n` positional placeholders for the actual
values. This was proven end-to-end against real PostgreSQL 14.17 in this session (see
Verification below) for bigint, uuid, text, char(n), date, timestamp(.5), an enum, and a
domain — all eight cases matched the trigger's own rendering byte-for-byte, independent of
`DateStyle`.

That rendered value — one jsonb object such as `%{"id" => "42"}` — becomes a **normal Ecto
bind parameter** (`^rendered_map`) in the existing `AuditChange` query pipeline:
`where(query, [ac], ac.table_pk == ^rendered_map)`. This is `history/3`'s only required
structural change; `maybe_apply_scope/2`, `storage_opts/2`, `row_history_page/4`'s
keyset cursor, and every filter helper are untouched. A real-PG `EXPLAIN` in this session
confirmed `table_pk = $3` (whole-map equality) is served as an **Index Cond** by
`audit_changes_row_history_idx (table_schema, table_name, table_pk, captured_at DESC, id DESC)`
— even an **Index Only Scan** — satisfying D-06 and IDX-01's EXPLAIN requirement.

**Primary recommendation:** Build one new module, `Threadline.Query.RowKey` (name locked
by CONTEXT.md D-03), with three responsibilities: (1) resolve a schema module's expected
key fields via the D-18 order (`primary_key:` override → `__schema__(:primary_key)` →
raise) and map fields to DB columns via `__schema__(:field_source, field)`
(`deps/ecto/lib/ecto/schema.ex:455`, VERIFIED); (2) eagerly validate the caller's `id`
argument (scalar or map/keyword) against that resolved set, raising `ArgumentError` per
D-03's exact message shapes; (3) render the comparison jsonb object by issuing one raw
parameterized `SELECT jsonb_build_object(...)` against the adopter's repo, using a
`pg_attribute`/`format_type` catalog lookup (optionally `:persistent_term`-cached) to
build each column's `CAST($n AS <type>)` text, and dumping UUID values to Postgrex's
required 16-byte binary form via `Ecto.UUID.dump/1` before binding (every other allowed
type — integer, text, `Date`, `NaiveDateTime`, enum string, domain-over-any-of-these —
was proven to bind and CAST correctly with no extra conversion). `history/3`,
`row_history_query/3`, and `as_of/4` then use the returned map exactly where they
currently use `fragment("? @> ?::jsonb", ...)`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Row-key field↔column resolution & validation | API / Backend (`Threadline.Query.RowKey`) | — | Pure Elixir/Ecto-schema-introspection logic; no I/O beyond config load |
| Catalog type lookup (`pg_attribute`/`format_type`) | Database / Storage | API / Backend | The type text only exists in PostgreSQL's catalog; the library issues one read-only catalog query per resolution (cacheable) |
| Comparison-value rendering (`jsonb_build_object(... CAST ...)`) | Database / Storage | API / Backend | PostgreSQL, not Elixir, renders the text form — this is the whole point of D-04 |
| `table_pk = <rendered>` row lookup | API / Backend (`Threadline.Query`) | Database / Storage (index) | Ecto query composed with existing filters/scope; served by `audit_changes_row_history_idx` |
| Row-history index (IDX-01) | Database / Storage | — | Installed by migration (new installs) or a generated `CREATE INDEX CONCURRENTLY` migration (existing adopters) |
| Operator-surface row-link guard (READ-04) | Browser / Client (LiveView render) | API / Backend (`table_pk` shape it receives) | Purely a presentation decision over data the query layer already returns; no new query needed |

## Package Legitimacy Audit

Not applicable — this phase adds no new dependencies. `Ecto.Adapters.SQL.query!/4`,
`Ecto.UUID`, and `Ecto.Query` are already-vendored transitive dependencies
(`ecto 3.14.2`, `ecto_sql`, `postgrex 0.22.4` — confirmed present in `mix.lock`).

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|---------------|
| `ecto` | 3.14.2 (VERIFIED — `mix.lock:9`) | Query composition, schema introspection (`__schema__/1,2`) | Already the project's ORM; no substitute needed |
| `ecto_sql` | matching `ecto` (transitive; VERIFIED present via `deps/ecto_sql`) | `Ecto.Adapters.SQL.query!/4` for the raw parameterized render statement | The only sanctioned way to run genuinely dynamic-arity/dynamic-type-text SQL through a repo connection |
| `postgrex` | 0.22.4 (VERIFIED — `mix.lock:39`) | Wire encoding of bind parameters | Already the project's PostgreSQL driver |

No new packages. `Ecto.UUID.dump/1` is part of `ecto` core (`Ecto.UUID` module), not a
separate dependency.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Raw parameterized SQL via `Ecto.Adapters.SQL.query!/4` | `fragment/1` with a runtime-built SQL string | **Rejected — not possible.** Ecto's macro explicitly refuses a non-literal fragment string at compile time (VERIFIED, see below); this is not a style preference, it is a hard API boundary. |
| Raw parameterized SQL | `dynamic/2` + `splice/1` composing many small per-column fragments, `||`-concatenated | Solves variable *arity* but not variable *type-cast text* per column — the CAST target must still be compile-time-literal SQL text inside each fragment; a generic library function serving every adopter schema cannot have that literal fixed at compile time. Rejected for the same reason as the direct fragment approach. |
| Two round trips (catalog lookup, then render) | Fold catalog lookup into the render statement via a CTE | **Rejected.** `CAST(expr AS type)` requires `type` to be a fixed SQL-grammar token, not a value read from a subquery in the same statement — PostgreSQL cannot parameterize a cast target. The type text must be fetched in a prior statement and spliced into the second statement's literal SQL text, exactly as `primary_key_sql.ex` already does for DDL. |
| Rendering the comparison value in PostgreSQL | Rendering it in Elixir (e.g. `Date.to_iso8601/1`, string interpolation) then sending as an opaque jsonb param | **Rejected per D-04.** Verified independently in this session: `to_jsonb(CAST($1 AS timestamp)) #>> '{}'` is unaffected by `DateStyle`, but any Elixir-side text rendering risks diverging from whatever PostgreSQL itself would have produced for an edge case not yet enumerated (locale, precision, a future allowlisted type). Only PostgreSQL's own rendering is guaranteed identical to the trigger's rendering, because the trigger also asked PostgreSQL to render it. |

**Installation:** none required.

**Version verification:** `ecto 3.14.2` and `postgrex 0.22.4` confirmed via `mix.lock` (already vendored; no `npm view`/`pip index`-equivalent lookup needed for an already-resolved Hex lockfile entry — this is an in-repo file read, not a registry claim).

## Architecture Patterns

### System Architecture Diagram

```
Caller                     Threadline.Query.RowKey              Threadline.Query          PostgreSQL
  |  history(User, id, ..)         |                                    |                        |
  |------------------------------->|                                    |                        |
  |                                | 1. resolve!(User)                  |                        |
  |                                |    - primary_key: override?        |                        |
  |                                |      (TriggerCaptureConfig.load)   |                        |
  |                                |    - else __schema__(:primary_key) |                        |
  |                                |      mapped via field_source       |                        |
  |                                |                                    |                        |
  |                                | 2. validate!(resolved, id)         |                        |
  |                                |    raises ArgumentError on         |                        |
  |                                |    missing/extra/nil/scalar-       |                        |
  |                                |    for-composite                   |                        |
  |                                |                                    |                        |
  |                                | 3. catalog_types!(table, cols)  -------------------------->  |
  |                                |    (persistent_term cache?)         SELECT format_type(...)  |
  |                                |                                    <--------------------------
  |                                |                                    |  pg_attribute/pg_type   |
  |                                |                                    |                          |
  |                                | 4. render!(repo, table, cols,   -------------------------->  |
  |                                |    types, values)                   SELECT jsonb_build_object(|
  |                                |                                       'col', to_jsonb(CAST($n |
  |                                |                                       AS <type>)) #>> '{}'... |
  |                                |                                    <--------------------------
  |                                |                                    |  %{"col" => "text"}      |
  |                                |<-----------------------------------|                          |
  |                                | returns rendered_map               |                          |
  |------------------------------->|                                    |                          |
  |                                                                     | 5. AuditChange            |
  |                                                                     |    |> where(table_schema)  |
  |                                                                     |    |> where(table_name)    |
  |                                                                     |    |> where(table_pk ==    |
  |                                                                     |         ^rendered_map)  ------------->
  |                                                                     |    |> maybe_apply_scope    | Index Cond on
  |                                                                     |    |> order_by             | audit_changes_
  |                                                                     |    |> repo.all             | row_history_idx
  |<--------------------------------------------------------------------|                          |
  |  [%AuditChange{}, ...]                                                                          |
```

### Recommended Project Structure

```
lib/threadline/query/
├── row_key.ex          # NEW — resolve!/1, validate!/2, catalog_types!/2, render!/4 (or split render into its own module, see below)
├── cursors.ex           # existing, unchanged
└── scope.ex              # existing, unchanged
lib/threadline/capture/
└── row_history_index_sql.ex  # NEW — shared SQL for IDX-01 install-template index + gen.row_history_index generator
lib/mix/tasks/
└── threadline.gen.row_history_index.ex  # NEW — IDX-01 generator, mirrors threadline.gen.triggers.ex's Mix.Generator/MigrationsPath/MigrationVersion pattern
```

Whether the catalog lookup and the render step live in one module (`RowKey`) or split
into `RowKey` (resolve/validate) + a `RowKeyMatch`/`RowKeyRender` helper (catalog +
render) is Claude's Discretion per CONTEXT.md — both were proven to work; the split
mainly affects testability of the two DB-touching steps independently.

### Pattern 1: Raw parameterized SQL for dynamic-arity, dynamic-type-cast comparison values

**What:** Build `SELECT jsonb_build_object($col_lit_1, to_jsonb(CAST($1 AS <type_1>))
#>> '{}', $col_lit_2, to_jsonb(CAST($2 AS <type_2>)) #>> '{}', ...)` as an Elixir string
(column names quoted as jsonb-object-key string literals via the same escaping
`primary_key_sql.ex` already uses for column identifiers; the `<type_N>` text comes only
from a prior `format_type()` catalog lookup, never from caller input), then execute it
with `Ecto.Adapters.SQL.query!(repo, sql, values)`.

**When to use:** Whenever the SQL structure (arity, or any embedded literal such as a
type name) is only known at runtime and cannot be reduced to a `splice/1` of *count-only*
values.

**Example (proven against real PostgreSQL 14.17 in this session):**
```elixir
# Source: this session's verification run (see below), not upstream docs — this is a
# from-scratch technique combining Ecto.Adapters.SQL.query!/4 with a catalog-sourced
# CAST target, following the same trust model already used in
# lib/threadline/capture/primary_key_sql.ex's key_type_check_sql/1.
sql = """
SELECT
  to_jsonb(CAST($1 AS bigint)) #>> '{}' AS id
"""
Ecto.Adapters.SQL.query!(repo, sql, [42])
# => %{rows: [["42"]], columns: ["id"]}
```

**Verified identical to the trigger's own rendering, independent of `DateStyle`:**
```
TRIGGER-RENDERED (jsonb_build_object('col', to_jsonb(NEW) ->> 'col'), insert time):
  bigint  -> "42"
  uuid    -> "a3bb189e-8bf9-3888-9912-ace4e6543002"
  text    -> "hello"
  char(8) -> "ab      "   (space-padded to declared length)
  date    -> "2026-09-25"
  timestamp(.5) -> "2026-09-25T12:00:00.5"
  enum    -> "active"
  domain(int) -> "7"

READ-RENDERED (to_jsonb(CAST($n AS <format_type text>)) #>> '{}', SET DateStyle='SQL, DMY'):
  bigint match: true
  uuid match: true
  text match: true
  char(8) match: true
  date match: true
  timestamp .5 match: true
  enum match: true
  domain match: true
```
Every pair matched with `==` on the returned text. The full session transcript is
reproducible via the script preserved at the end of this document (see "Verification
Scripts Run This Session").

### Pattern 2: `Ecto.Schema.__schema__(:field_source, field)` for field↔column mapping

**What:** `__schema__(:field_source, field)` returns the DB column a schema field maps
to (defaults to the field name itself unless `field :foo, :string, source: :bar` was
declared).

**When to use:** D-02 requires the public API to accept **schema field names**, not raw
DB column names, then translate to columns before hitting the catalog/trigger-args key
list (which is always column names, resolved at migrate time from `pg_attribute` or the
declared `primary_key:` override).

```elixir
# Source: deps/ecto/lib/ecto/schema.ex:455 (VERIFIED — read this session)
#   "* `__schema__(:field_source, field)` - Returns the alias of the given field;"
for field <- schema_module.__schema__(:fields), into: %{} do
  {field, to_string(schema_module.__schema__(:field_source, field))}
end
```

For a `primary_key:` override table (config-declared columns, D-14..D-18), the mapping
runs in reverse: for each declared column, find the schema field whose `field_source`
equals it (D-02: "If a declared column has no mapped field, raise `ArgumentError`").

### Pattern 3: One EXPLAIN-based test, `enable_seqscan = off`, asserting `audit_changes_row_history_idx` is used

**Verified this session** against a table shaped exactly like `audit_changes` (same
column list and the exact IDX-01 index DDL from CONTEXT.md D-09):

```
EXPLAIN SELECT * FROM audit_changes_proof
WHERE table_schema = $1 AND table_name = $2 AND table_pk = $3
ORDER BY captured_at DESC, id DESC;

  -- with enable_seqscan = off, 20,000 populated rows, ANALYZE run first:
  Index Only Scan using audit_changes_row_history_idx on audit_changes_proof
    Index Cond: ((table_schema = 'public'::text) AND (table_name = 'users'::text)
                 AND (table_pk = '{"id": "42"}'::jsonb))
```

This confirms D-06 and gives the exact assertion shape for the D-12 EXPLAIN test: assert
the plan text (or `EXPLAIN (FORMAT JSON)` `"Index Name"`) contains
`"audit_changes_row_history_idx"`, never on timing.

### Anti-Patterns to Avoid

- **Passing a UUID string directly to `Ecto.Adapters.SQL.query!/4` for a `uuid`-typed
  CAST parameter:** Postgrex's `uuid` extension only accepts a 16-byte binary
  (`is_binary(uuid) and byte_size(uuid) == 16`, VERIFIED — `deps/postgrex/lib/postgrex/extensions/uuid.ex:10-11`).
  A 36-character canonical string raises `DBConnection.EncodeError`. Convert with
  `Ecto.UUID.dump/1` first (accepts either the canonical string or an already-16-byte
  binary and normalizes to the binary Postgrex needs — VERIFIED by running it in this
  session's proof script).
- **Using `@>` (containment) anywhere on this path:** `x @> '{}'::jsonb` is true for
  every row (D-04, carried from Phase 210's D-04). READ-01's whole bug is `@>` with a
  JSON-number id against a stored JSON-string id; the fix is `=` with matched types
  *and* matched JSON value kind (string vs number) — both are satisfied automatically
  once PostgreSQL renders the comparison value the same way it rendered the stored one.
- **Building the SQL fragment text as an interpolated Elixir string and handing it to
  Ecto's `fragment/1` macro:** compiles, but only if the string is a *literal* at the
  call site; a runtime-built string raises `Ecto.Query.CompileError` with the exact
  message `"to prevent SQL injection attacks, fragment(...) does not allow strings to
  be interpolated"` (VERIFIED — `deps/ecto/lib/ecto/query/builder.ex:640-644`).
- **Per-key `table_pk ->> 'col' = ...` predicates** (D-06): defeats the whole-map btree
  index; forces a per-row JSON extraction scan.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Field→column mapping | A hand-maintained map per schema | `__schema__(:field_source, field)` | Already correct for every schema, including `source:`-renamed fields; hand-rolling it drifts the moment an adopter renames a field |
| UUID wire encoding | Manual hex-string→binary conversion | `Ecto.UUID.dump/1` | Already handles both the canonical string and pre-binary forms, and matches exactly what Postgrex's own UUID extension expects |
| Migration file naming/versioning for the new generator | A bespoke timestamp/module-name scheme | `Threadline.Mix.MigrationVersion.next/3` + `Threadline.Mix.MigrationsPath.resolve/1` (already used by `threadline.gen.triggers`) | Identical concerns (collision-free versioning, `--migrations-path`/`--repo` resolution) already solved and tested; a second implementation risks drifting from the first |

**Key insight:** Almost everything this phase needs already exists somewhere in the
codebase in a proven form (`primary_key_sql.ex`'s catalog-driven SQL construction,
`Naming`/`StorageSchema`'s identifier quoting, `gen.triggers.ex`'s migration-writing
scaffolding). The phase's actual novelty is narrow: teach the *read* side to ask
PostgreSQL to render a comparison value the same way the *write* side already does.

## Common Pitfalls

### Pitfall 1: Assuming `fragment/1` can take a runtime string
**What goes wrong:** A first implementation attempt tries `fragment(dynamic_sql_string, val1, val2)` or builds the fragment text via `<>` and pins it with `^`.
**Why it happens:** It "looks like" it should work by analogy with `splice/1`'s variable-count support.
**How to avoid:** Use `Ecto.Adapters.SQL.query!/4` for the render step instead (Pattern 1 above); keep the Ecto.Query DSL only for the final `where(ac.table_pk == ^rendered_map)`.
**Warning signs:** A `CompileError` at compile time (not even a runtime failure) citing "does not allow strings to be interpolated".

### Pitfall 2: Binding a UUID string where Postgrex expects 16 bytes
**What goes wrong:** `Ecto.Adapters.SQL.query!(repo, "...CAST($1 AS uuid)...", ["a3bb189e-..."])` raises `DBConnection.EncodeError`.
**Why it happens:** Postgrex's UUID extension is binary-only; Ecto normally hides this via `Ecto.UUID`'s `dump/1` callback when going through a typed schema field, but raw `Ecto.Adapters.SQL.query!/4` bypasses that.
**How to avoid:** Call `Ecto.UUID.dump/1` (or detect an already-16-byte binary and pass through) before binding any value whose catalog type resolves (through `typbasetype` for domains) to `uuid`.
**Warning signs:** `DBConnection.EncodeError, "a binary of 16 bytes"` in test output.

### Pitfall 3: Trying to fold the catalog lookup and the render into one round trip
**What goes wrong:** Attempting `WITH t AS (SELECT format_type(...) ...) SELECT ... CAST($1 AS (SELECT t FROM t)) ...` — invalid SQL.
**Why it happens:** It seems wasteful to pay two round trips for one logical operation.
**How to avoid:** Accept two statements (or cache the catalog lookup via `:persistent_term`, Claude's Discretion per D-05, to make repeat calls single-round-trip). `CAST(expr AS type)` requires the target type to be a compile-time SQL-grammar token, not a subquery result — this is a PostgreSQL grammar limitation, not an Ecto one.
**Warning signs:** `ERROR: syntax error at or near` when trying to parameterize or subquery a CAST target.

### Pitfall 4: `format_type()` output containing a type modifier that can't be re-quoted
**What goes wrong:** `format_type()` for `char(8)`/`bpchar(8)` returns `character(8)` — a bare (unquoted) type name with modifier. Wrapping it in `"..."` (as if it were an identifier) produces `CAST($1 AS "character"(8))`, which PostgreSQL rejects with `ERROR: type modifier is not allowed for type "character"` (reproduced in this session's proof run).
**Why it happens:** Every *other* identifier in this codebase (table names, column names) is quoted via `StorageSchema.quote_ident/1`; it is tempting to apply the same treatment to a type name.
**How to avoid:** Interpolate the `format_type()` result **verbatim, unquoted** into the CAST clause — it is already valid, unquoted PostgreSQL type syntax (this matches what `primary_key_sql.ex`'s `key_type_check_sql/1` already does: it only *compares* `format_type()` output against known type names, it never re-quotes it).
**Warning signs:** `ERROR 42601 (syntax_error): type modifier is not allowed for type "..."`.

### Pitfall 5: The `@doc false` `row_history_query/3` callers
**What goes wrong:** `row_history_query/3` is called directly (not through `history/3`/`row_history_page/4`) by `lib/threadline/continuity.ex` and indirectly informs `lib/threadline/operator_surface/live/row_history_component.ex` (`Threadline.history/3`, `Threadline.as_of/4`, always with a route-supplied scalar `record_id`). Changing `row_history_query/3`'s signature or validation behavior without checking these breaks the operator UI's row-history page.
**Why it happens:** It's `@doc false` (internal), so it's easy to assume it has no external callers.
**How to avoid:** Grep for `row_history_query`, `Threadline.history`, `Query.history`, `Threadline.as_of`, `Query.as_of` across `lib/` and `test/` before changing signatures (already done in this research — see Canonical References below). `row_history_component.ex` only ever passes a route-derived scalar, so as long as scalar-for-single-column-table keeps working (D-01 requires this), no call-site change is needed there.
**Warning signs:** `test/threadline/continuity_brownfield_test.exs`, `test/threadline/query_test.exs` regressions after touching `row_history_query/3`.

### Pitfall 6: `as_of`'s `:cast` option and `load_as_of_snapshot/3`
**What goes wrong:** `as_of/4`'s snapshot-loading path (`Ecto.embedded_load(schema_module, data_after, :json)`) is untouched by this phase's key-matching change, but a plan that "helpfully" refactors `as_of/4` more broadly risks breaking the `{:cast_error, message}` / `{:error, :deleted_record}` / `{:error, :before_audit_horizon}` contract that callers (and their tests) already depend on.
**Why it happens:** `as_of/4` is the one function in this phase's scope that does more than build a WHERE predicate.
**How to avoid:** Change only the `fragment("? @> ?::jsonb", ...)` line and the surrounding key-building code in `as_of/4`; leave `load_as_of_snapshot/3` and its `case` dispatch alone.

### Pitfall 7: `maybe_apply_scope/2` with `row_history_scope_opts/2`
**What goes wrong:** `row_history_scope_opts/2` builds `params: %{schema_module: schema_module, id: id}` for host-defined `scope_query_fn` callbacks (`lib/threadline/query.ex:656-663`). If the new `id` argument shape (scalar OR map/keyword, per D-01) is passed through unchanged to a host's `scope_query_fn`, any host-defined scope function written against the old always-scalar contract could receive a map unexpectedly for composite tables.
**Why it happens:** `scope_query_fn` is a host extension point; its contract isn't controlled by this library.
**How to avoid:** Document (in the `history`/`as_of` `@doc`s, per CONTEXT.md's discretion item) that `params.id` in a `scope_query_fn` now mirrors whatever shape the caller passed to `history`/`as_of` (scalar or map), not always a scalar. This is additive/informational, not a required code change — flag it for the plan to decide whether `RowKey`'s *resolved* map (always a map, even for single-column tables) should be what's threaded into scope params instead of the raw caller-supplied shape, for consistency.

## Code Examples

### Resolving key fields via D-18's order

```elixir
# Source: this session's design, following Threadline.Capture.TriggerCaptureConfig.load/1
# (lib/threadline/capture/trigger_capture_config.ex:22-27, VERIFIED — already exposes
# `primary_key` per table entry) and Ecto.Schema.__schema__/2
# (deps/ecto/lib/ecto/schema.ex:451,455, VERIFIED).
defp resolve_key_fields!(schema_module) do
  table = schema_module.__schema__(:source)
  table_schema = schema_module.__schema__(:prefix) || "public"
  qualified = if table_schema == "public", do: table, else: "#{table_schema}.#{table}"

  case Threadline.Capture.TriggerCaptureConfig.load()[qualified][:primary_key] do
    nil ->
      case schema_module.__schema__(:primary_key) do
        [] -> raise ArgumentError, "..."  # D-18 step 3: no primary key and no override
        pk_fields -> {pk_fields, field_source_map(schema_module, pk_fields)}
      end

    declared_columns ->
      # D-02: map each declared column back to the schema field whose field_source
      # equals it; raise ArgumentError naming the column+schema if none maps.
      {reverse_map_columns_to_fields!(schema_module, declared_columns), declared_columns}
  end
end
```

### Rendering the comparison value (two round trips, second one is the load-bearing one)

```elixir
# Source: this session's verification run against real PostgreSQL 14.17.
defp catalog_types!(repo, qualified_host_table, columns) do
  sql = """
  SELECT a.attname, format_type(a.atttypid, a.atttypmod)
  FROM pg_attribute a
  WHERE a.attrelid = to_regclass($1) AND a.attname = ANY($2)
  """
  %{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [qualified_host_table, columns])
  Map.new(rows, fn [name, type] -> {name, type} end)
end

defp render_comparison!(repo, columns_and_values, types) do
  {pairs, params, _n} =
    Enum.reduce(columns_and_values, {[], [], 1}, fn {col, val}, {pairs, params, n} ->
      type = Map.fetch!(types, col)
      val = maybe_dump_uuid(val, type)
      {pairs ++ ["'#{escape(col)}', to_jsonb(CAST($#{n} AS #{type})) #>> '{}'"], params ++ [val], n + 1}
    end)

  sql = "SELECT jsonb_build_object(#{Enum.join(pairs, ", ")})"
  %{rows: [[rendered]]} = Ecto.Adapters.SQL.query!(repo, sql, params)
  rendered
end
```

### Using the rendered map in the existing query pipeline

```elixir
# Only the predicate-building line changes in history/3, row_history_query/3, as_of/4:
AuditChange
|> where([ac], ac.table_schema == ^table_schema)
|> where([ac], ac.table_name == ^table)
|> where([ac], ac.table_pk == ^rendered_map)   # was: fragment("? @> ?::jsonb", ac.table_pk, ^pk_map)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|-------------------|---------------|--------|
| `fragment("? @> ?::jsonb", ac.table_pk, ^%{to_string(pk_field) => id})` | `ac.table_pk == ^rendered_map`, rendered by PostgreSQL from a catalog-typed CAST | This phase (211) | Fixes READ-01 (integer id vs stored string), extends to composite keys (READ-02), keeps a mixed 0.10.x/regenerated table's history in one query (READ-03), and makes the whole-map btree index usable (D-06/IDX-01) |
| No `audit_changes_row_history_idx` | `audit_changes_row_history_idx (table_schema, table_name, table_pk, captured_at DESC, id DESC)` shipped in the install template + `CREATE INDEX CONCURRENTLY` generator for existing adopters | This phase (IDX-01) | `history`/`as_of` stop full-scanning `audit_changes` for the target table's rows |

**Deprecated/outdated:**
- `@>` (jsonb containment) for row-key matching on `table_pk` — always risked a vacuous match against `{}` and, as of Phase 210's `{}`-unresolved-key semantics, remains actively wrong for that reason even before the type-mismatch bug.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|----------------|
| A1 | Whether to cache the `pg_attribute`/`format_type` catalog lookup via `:persistent_term`, and its invalidation story (schema changes require an app restart, similar to how `TriggerCaptureConfig.load/1` already assumes config doesn't change at runtime) is left as Claude's Discretion per CONTEXT.md; this research recommends caching but does not mandate a specific invalidation strategy. | Architecture Patterns, Don't Hand-Roll | Low — a wrong cache-invalidation choice costs a stale-type read after an adopter renames/retypes a key column and forgets to restart; the existing `TriggerCaptureConfig.load/1` config-caching precedent has the same shape of risk today and is accepted project-wide. |
| A2 | Non-UUID, non-integer/date/timestamp allowlisted values (enum strings, domain-over-text) that a caller supplies as an Elixir **atom** (e.g. `:active` for an `Ecto.Enum`-style field) will need an explicit `to_string/1` (or similar) conversion before binding, because this session's proof only exercised binding a **string** for the enum column — not an atom. This is an implementation detail for the plan to settle, not verified against Postgrex's atom-handling behavior in this session. | Code Examples, Pitfall list | Medium — if unhandled, an adopter passing an atom for an enum-typed composite-key column gets a `DBConnection.EncodeError` at call time rather than at eager validation time; should be caught by a real-PG test with an enum key column and an atom-valued caller argument. |
| A3 | The Ecto version compatibility of `splice/1`/`identifier/1`/`constant/1` fragment modifiers (confirmed present in `ecto` 3.14.2, the version this repo vendors) is not something adopters running older Ecto versions can rely on — but since this library builds its own SQL via `Ecto.Adapters.SQL.query!/4` rather than depending on these modifiers for the read path, this is not a binding constraint on the implementation, only a note that the modifiers were investigated and found insufficient for this use case regardless of version. | Alternatives Considered | Low — informational only; does not affect the chosen implementation. |

## Open Questions

1. **Should the resolved comparison map thread through `scope_query_fn`'s `params.id` unchanged (raw caller shape) or normalized (always the resolved map)?**
   - What we know: `row_history_scope_opts/2` (`lib/threadline/query.ex:656-663`) already forwards `id` verbatim into `params` for host-defined scope callbacks.
   - What's unclear: whether existing host `scope_query_fn` implementations pattern-match on `id` being a bare scalar; a composite-table `id` map would be new to them regardless of what this phase does, since composite-key `history/3` calls did not work before this phase at all.
   - Recommendation: forward the raw caller-supplied `id` unchanged (least surprise, no new normalization step), and call this out in the `history`/`as_of` `@doc`s as the discretion item CONTEXT.md already flags.

2. **Exact wording and DETAIL/HINT content for `RowKey`'s `ArgumentError` messages beyond the two examples D-03 gives verbatim.**
   - What we know: D-03 gives two exact message shapes (a missing/extra/misnamed key case, and a scalar-for-composite case) and requires "expected fields in resolved key order."
   - What's unclear: the exact phrasing for a nil value, for a schema with neither a PK nor an override, and for the override-column-has-no-mapped-field case (D-02).
   - Recommendation: follow the existing `threadline:`-prefixed error style used at migrate time (`primary_key_sql.ex`, Phase 209 convention) for consistency, even though D-13's exact `threadline:` prefix convention was defined for migrate-time errors specifically — the plan should decide whether read-time `ArgumentError`s also get that prefix or stay bare (existing `Threadline.Query` `ArgumentError`s, e.g. `validate_correlation_id_filter!/1`, do **not** use a `threadline:` prefix today, which is the closer precedent for this phase).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| PostgreSQL | All read-side real-DB tests, EXPLAIN test | ✓ | 14.17 (Homebrew, local) — CI matrix also runs PG 16 per `210-CONTEXT.md`'s established pattern | — |
| `mix` / Elixir / OTP | Build/test | ✓ | Elixir 1.17.3-otp-27, per `.tool-versions` | — |
| `psql` | Ad hoc verification only, not part of the test suite | ✓ | via Homebrew | — |

No missing dependencies.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit, `Threadline.DataCase` (`test/support/data_case.ex`) — real-PostgreSQL integration style, **no Ecto sandbox** (triggers fire at the DB level, outside sandbox awareness), `async: false` by default |
| Config file | `config/test.exs` (repo: `Threadline.Test.Repo`, database `threadline_test`, PgBouncer-safe `:prepare` handling already configured) |
| Quick run command | `mix test test/threadline/query_test.exs test/threadline/capture/trigger_pk_shapes_test.exs` (or the new `row_key_test.exs`/`row_history_index_test.exs` files this phase adds) |
| Full suite command | `mix verify.test` (alias for `mix test`, `mix.exs:131`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|---------------------|--------------|
| READ-01 | `history/3`/`row_history_query/3`/`as_of/4` return rows for integer-PK (bigserial) tables; regression proves `@>`-with-integer-id fails today | integration (real PG) | `mix test test/threadline/query_test.exs` (extend) or a new `test/threadline/query/row_key_test.exs` | ❌ Wave 0 — new file recommended given scope |
| READ-02 | Composite-key `history` via keyword list/map; `ArgumentError` on missing/extra/mismatched keys | integration (real PG) + unit (pure validation, no DB) | `mix test test/threadline/query/row_key_test.exs` | ❌ Wave 0 |
| READ-03 | 0.10.x-captured rows and regenerated-trigger-captured rows for the same record both return from one `history` call | integration (real PG), reusing `test/support/legacy_trigger_sql.ex` | `mix test test/threadline/query/row_key_test.exs` (mixed-row case) | ❌ Wave 0 (fixture module exists; new test cases needed) |
| READ-04 | `transaction_live.ex` `change_history_path/2` renders no link for composite/`{}`/`{"id":null}` `table_pk`; renders a link only for a single-key `table_pk` | LiveView render test (Phoenix.LiveViewTest, no browser — do NOT run Playwright directly per CLAUDE.md) | `mix test test/threadline/operator_surface/live/transaction_live_test.exs` (extend, or confirm existing file name) | Check — likely exists; extend rather than create |
| IDX-01 | New installs create `audit_changes_row_history_idx`; `mix threadline.gen.row_history_index` writes a `CONCURRENTLY` migration for existing adopters; EXPLAIN proves the index is used by `history`/`as_of` | integration (real PG), storage-schema contract pin | `mix test test/threadline/storage_schema_migration_contract_test.exs test/mix/tasks/threadline/gen_row_history_index_test.exs test/threadline/query/row_history_index_explain_test.exs` | Partial — contract test file exists (extend it, per D-09); generator test and EXPLAIN test are new |

### Sampling Rate

- **Per task commit:** the quick run command above, scoped to the files touched by that task.
- **Per wave merge:** `mix verify.test` (full suite).
- **Phase gate:** `mix ci.all` green before `/gsd-verify-work` (also runs `verify.format`, `verify.credo --strict`, `verify.dialyzer`, `verify.xref_cycles`, doc-contract tests, and the example-app lanes — never run Playwright/`verify.example_browser` directly per CLAUDE.md; let `ci.all` or its named alias invoke it).

### Wave 0 Gaps

- [ ] `test/threadline/query/row_key_test.exs` (or equivalent) — covers READ-01, READ-02, READ-03; unit-level validation cases (D-03 error messages) can be pure-Elixir (no DB) within the same file or a sibling `row_key_validation_test.exs`.
- [ ] `test/mix/tasks/threadline/gen_row_history_index_test.exs` — covers IDX-01's generator half, mirroring `test/mix/tasks/threadline/gen_triggers_test.exs`'s pattern.
- [ ] `test/threadline/query/row_history_index_explain_test.exs` (or folded into the above) — covers IDX-01's EXPLAIN requirement (D-12), `enable_seqscan = off` pattern verified in this session.
- [ ] Extend `test/threadline/storage_schema_migration_contract_test.exs` — pin the new index into the install-template contract (D-09).
- [ ] Extend the existing `transaction_live` LiveView render test — covers READ-04 / D-08's `change_history_path/2` fix.
- [ ] Confirm whether `Threadline.Test.MigrationHarness` (used by `trigger_pk_shapes_test.exs`) and its fixture tables (`pk_uuid_items`, `posts_tags_pk`, `posts_tags_incl`, etc., defined in Phase 210's test suite) can be reused directly for this phase's composite-key/override read-side round-trip tests, rather than building a second parallel fixture set.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|----------------|---------|---------------------|
| V2 Authentication | no | Out of scope — this phase touches only read-query construction and an operator-surface link guard |
| V3 Session Management | no | — |
| V4 Access Control | no | `maybe_apply_scope/2`/`scope_query_fn` (host-owned access control) is passed through unchanged, not modified |
| V5 Input Validation | yes | `Threadline.Query.RowKey.validate!/2` — eager `ArgumentError` on any id-argument shape that doesn't match the resolved key set (D-03); **never** call `String.to_atom/1` on caller-supplied string keys (explicit D-01 requirement, prevents an atom-table exhaustion DoS vector from untrusted map keys) |
| V6 Cryptography | no | — |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|------------------------|
| SQL injection via a dynamically-built `CAST(... AS <type>)` clause | Tampering | The type text is sourced **only** from `format_type()` against `pg_attribute` (catalog, never caller input) — same trust model already proven safe in `primary_key_sql.ex`'s migrate-time DO blocks. Column names embedded as jsonb object keys must be escaped identically to how `primary_key_sql.ex`'s `sql_string_literal/1` already escapes single quotes; reuse that helper rather than re-deriving it. |
| Atom-table exhaustion via `String.to_atom/1` on an attacker-controlled map key | Denial of Service | D-01 explicitly forbids this; compare caller string keys against the resolved (already-atom) field-name set with plain string equality, never coerce the caller's key into an atom |
| A malformed/oversized `id` argument (e.g. a very large map) reaching `RowKey.validate!/2` before any query executes | Denial of Service | Validation is O(key-set size), not O(input size) beyond a `MapSet` membership check per resolved field — no risk of unbounded work per D-03's "compare as MapSets" design |

## Sources

### Primary (HIGH confidence — read and/or executed against real infrastructure this session)

- `lib/threadline/query.ex` (full read) — the three functions this phase modifies and every filter/scope helper they share
- `lib/threadline/capture/primary_key_sql.ex` (full read) — the proven catalog-driven SQL-construction trust model this phase's read side reuses
- `lib/threadline/capture/trigger_capture_config.ex` (full read) — `load/1`, `primary_key:` normalization/validation already in place
- `lib/threadline/capture/migration.ex`, `lib/mix/tasks/threadline.gen.triggers.ex` (full read) — install-template and generator precedent for IDX-01
- `lib/threadline/operator_surface/live/timeline_live/helpers.ex`, `lib/threadline/operator_surface/live/transaction_live.ex:380-420` (read) — READ-04's existing single-key guard and the bug it does *not* yet have (`change_history_path/2`)
- `lib/threadline/storage_schema.ex`, `lib/threadline/capture/naming.ex` (full read) — identifier quoting/validation to reuse
- `test/support/legacy_trigger_sql.ex` (full read) — frozen 0.10.2 fixture for READ-03
- `deps/ecto/lib/ecto/schema.ex:451-455` (read) — `__schema__(:primary_key)`, `__schema__(:field_source, field)` VERIFIED present
- `deps/ecto/lib/ecto/query/api.ex:380-580`, `deps/ecto/lib/ecto/query/builder.ex:148-855` (read) — `fragment/1`'s compile-time-literal-text requirement, `splice/1`/`identifier/1`/`constant/1` behavior VERIFIED
- `deps/ecto_sql/lib/ecto/adapters/postgres/connection.ex:960-1030` (read) — confirmed `identifier` renders as a double-quoted SQL identifier via `quote_name/1` (unsuitable for CAST type text)
- `deps/postgrex/lib/postgrex/extensions/uuid.ex` (full read) — 16-byte-binary requirement VERIFIED
- `mix.lock` (read) — `ecto 3.14.2`, `postgrex 0.22.4` versions VERIFIED
- **This session's own execution against `threadline_test` on PostgreSQL 14.17**, via `Threadline.Test.Repo` and `Ecto.Adapters.SQL.query!/4`:
  - a proof that `to_jsonb(CAST($n AS <format_type text>)) #>> '{}'` byte-for-byte matches `jsonb_build_object(col, to_jsonb(NEW) ->> col)`'s trigger-time rendering for bigint, uuid (bound via `Ecto.UUID.dump/1`), text, char(8) (space-padded), date, timestamp with a `.5` fractional second, a Postgres enum, and a domain-over-integer — independent of a `SET DateStyle = 'SQL, DMY'` change between the two renderings
  - a proof that `table_pk = $3` (whole-map jsonb equality) against a table shaped like `audit_changes` with the exact IDX-01 index DDL is served by an **Index Only Scan** on `audit_changes_row_history_idx` under `EXPLAIN` with `enable_seqscan = off`

### Secondary (MEDIUM confidence)

- `.planning/phases/210-pk-agnostic-capture/210-CONTEXT.md`, `210-VERIFICATION.md` — carried-forward decisions and confirmed capture guarantees (project-internal, not independently re-verified against code in this session beyond what's cross-checked above)

### Tertiary (LOW confidence)

- None used as the basis for any Standard Stack or Architecture Pattern claim in this document.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; existing versions read directly from `mix.lock`.
- Architecture (raw-SQL render + Ecto predicate composition): HIGH — the core technical risk (can Ecto express this at all) was resolved by reading Ecto's own source and then independently proving the alternative construction against real PostgreSQL in this session, across all eight allowlisted type shapes plus the index-usage claim.
- Pitfalls: HIGH for the five items backed by a specific reproduced error or a read source line (Pitfalls 1, 2, 4, and the fragment/UUID findings); MEDIUM for Pitfalls 5–7 (call-site enumeration is thorough but the exact plan-level resolution is left as a design choice, tracked in Open Questions and the Assumptions Log).

**Research date:** 2026-09-25
**Valid until:** 30 days (stable dependencies; PostgreSQL catalog behavior and Ecto 3.14.x fragment semantics are not fast-moving) — but re-verify immediately if `ecto`, `ecto_sql`, or `postgrex` are bumped before this phase is planned, since the `fragment/1` compile-time-literal restriction and `splice/1` availability are version-specific findings.
