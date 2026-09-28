---
phase: 211-read-side-agreement
plan: 01
subsystem: database
tags: [ecto, postgres, jsonb, raw-sql, catalog-lookup, uuid]

# Dependency graph
requires:
  - phase: 210-pk-agnostic-capture
    provides: "trigger-side table_pk encoding (jsonb ->> text form), key column resolution order, primary_key: override config"
provides:
  - "Threadline.Query.RowKey: single-column resolve!/1, normalize!/2, column_types!/3, render!/3, match!/3"
  - "history/3, row_history_query/3, as_of/4 matching the whole rendered table_pk map with `=` instead of jsonb containment"
  - "Ecto-type fallback map so history/as_of stay readable after the host table/column is dropped or renamed"
  - "RowHistoryComponent rescuing ArgumentError from an uncastable route id into its existing error assign"
affects: [211-02-read-side-agreement, 211-03-read-side-agreement, 211-04-read-side-agreement]

actuals:
  tokens: 7744
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Two-round-trip raw SQL: a pg_attribute/pg_type catalog lookup for the CAST target type, then a jsonb_build_object render statement, mirroring PrimaryKeySQL's migrate-time trust model but on the read path"
    - "Ecto.Type.cast/dump per schema field before binding a raw SQL parameter, since raw Ecto.Adapters.SQL.query!/4 bypasses the adapter's normal typed-schema encoding (notably :binary_id -> 16-byte Postgrex UUID)"

key-files:
  created:
    - lib/threadline/query/row_key.ex
    - test/threadline/query/row_key_read_test.exs
  modified:
    - lib/threadline/query.ex
    - lib/threadline/operator_surface/live/row_history_component.ex
    - test/threadline/query_test.exs

key-decisions:
  - "Single-column key path only in this plan; primary_key: override and composite keys raise a plain ArgumentError, deferred to 211-02"
  - "where_row/2 is one shared private helper in query.ex, using where([ac], ...) so it works on both a bare AuditChange query and timeline_base_query's joined [ac, at] query"
  - "Dropped/renamed host table or column falls back to a fixed Ecto-type -> PostgreSQL-cast-type map (bigint/uuid/text/date/timestamp/enum) instead of raising, so audit history outlives the host table"
  - "A malformed UUID-typed key value (not a valid 36-char string or 16-byte binary) now raises ArgumentError instead of crashing Postgrex with a raw encode error"
  - "RowKey's qualified-table text always includes the schema (schema.table), never a bare table for public — matches Naming.qualified/1's format so the primary_key: override lookup actually matches public-schema tables, and matches the D-07 error message shape"

patterns-established:
  - "Read-side key matching always compares the full table_pk map with `=`, never jsonb containment or a per-key ->> predicate"

requirements-completed: [READ-01]

coverage:
  - id: D1
    description: "history/3 returns captured rows for a default Ecto bigserial table under integer, string, and keyword-list ids; the old jsonb-containment predicate proven to return [] on the same rows"
    requirement: READ-01
    verification:
      - kind: integration
        ref: "test/threadline/query/row_key_read_test.exs#integer, string, and keyword-list ids all return the same captured rows"
        status: pass
      - kind: integration
        ref: "test/threadline/query/row_key_read_test.exs#the old jsonb-containment predicate (0.10.2) returns [] for the same rows"
        status: pass
    human_judgment: false
  - id: D2
    description: "row_history_query/3 still returns an Ecto.Query; row_history/4 and row_history_page/4 pass a repo resolved from opts into filters"
    requirement: READ-01
    verification:
      - kind: integration
        ref: "test/threadline/query/row_key_read_test.exs#row_history_query/3 returns an Ecto.Query that resolves both changes"
        status: pass
      - kind: integration
        ref: "test/threadline/query/row_key_read_test.exs#row_history_page/4 pages one entry at a time, in stable order"
        status: pass
    human_judgment: false
  - id: D3
    description: "as_of/4 returns {:ok, snapshot} and {:error, :deleted_record} unchanged for the bigserial row"
    requirement: READ-01
    verification:
      - kind: integration
        ref: "test/threadline/query/row_key_read_test.exs#as_of/4 returns the latest snapshot, then :deleted_record after a delete"
        status: pass
    human_judgment: false
  - id: D4
    description: "History of a dropped host table stays readable via the Ecto-type fallback map"
    requirement: READ-01
    verification:
      - kind: integration
        ref: "test/threadline/query/row_key_read_test.exs#stays readable for history/3 and as_of/4 after DROP TABLE"
        status: pass
    human_judgment: false
  - id: D5
    description: "An unmappable key type (no catalog entry, no fallback) raises ArgumentError naming the field, Ecto type, and qualified table"
    requirement: READ-01
    verification:
      - kind: integration
        ref: "test/threadline/query/row_key_read_test.exs#raises ArgumentError naming the field, its Ecto type, and the qualified table"
        status: pass
    human_judgment: false
  - id: D6
    description: "history(nil) raises ArgumentError before any query runs; the row-history drawer rescues ArgumentError into its error assign instead of crashing"
    requirement: READ-01
    verification:
      - kind: integration
        ref: "test/threadline/query/row_key_read_test.exs#raises ArgumentError before any query runs when id is nil"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/row_history_component_test.exs (existing error-state suite, unmodified, still passing)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Full default test suite is green with the new read path; fake-schema tests read through the fallback map with no fixture tables"
    verification:
      - kind: unit
        ref: "mix test (2075 tests, 0 failures)"
        status: pass
    human_judgment: false

duration: 13min
completed: 2026-09-25
status: complete
---

# Phase 211 Plan 01: RowKey and single-column history/row_history/as_of matching Summary

**Fixed the text-vs-integer `table_pk` mismatch by making PostgreSQL render the comparison value the same way the capture trigger did, then comparing the whole map with `=` instead of jsonb containment.**

## Performance

- **Duration:** 13 min (commit-to-commit span; investigation/reading time not counted)
- **Started:** 2026-09-25T20:49:31-04:00 (first task commit)
- **Completed:** 2026-09-25T21:02:02-04:00 (final task commit)
- **Tasks:** 3 completed
- **Files modified:** 5 (2 new, 3 modified)

## Accomplishments

- Introduced `Threadline.Query.RowKey` (single-column path): resolves a schema's key column via the D-18 order (`primary_key:` override, then `__schema__(:primary_key)`, else raise), validates the id argument eagerly (rejects `nil`, accepts a scalar or the single-field map/keyword form), and asks PostgreSQL to render the comparison value exactly as the trigger stored it (`to_jsonb(CAST($n AS <catalog type>)) #>> '{}'`), falling back to a fixed Ecto-type map when the host table/column is gone.
- Rewired `history/3`, `row_history_query/3`, and `as_of/4` (via new `@doc false` `history_query/3` and `as_of_query/4`) onto a single shared `where_row/2` helper that compares the whole `table_pk` map with `=`, replacing the `fragment("? @> ?::jsonb", ...)` containment predicate on all three paths.
- Proved on real PostgreSQL that a default Ecto bigserial table's captured rows now come back for integer, string, and keyword-list ids, and that the old containment predicate returns `[]` for the same rows under an integer id (the READ-01 root-cause bug).
- Extended the fallback path to keep history/as_of readable after `DROP TABLE` on the host table, and to raise a clean `ArgumentError` (not a raw Postgrex crash) for a key type the fallback map cannot handle.
- Made the row-history drawer rescue `ArgumentError` from an uncastable route id into its existing `:error` assign instead of crashing.
- Removed leaked planning vocabulary (decision IDs, phase prose) from packaged `lib/` source that `release_artifact_contract_test.exs` flags, and fixed five pre-existing fake-schema tests in `query_test.exs` whose default integer `:id` primary key no longer silently accepted a string id.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — bigserial history end to end through RowKey (READ-01)** - `d1e8fed9` (feat)
2. **Task 2: Expand — row_history_query/3, row_history/4, row_history_page/4, as_of/4 and the drawer error state** - `6ba12e77` (feat)
3. **Task 3: Expand — existing fake-schema suites read through the fallback; full suite green** - `089d6a53` (fix)

## Files Created/Modified

- `lib/threadline/query/row_key.ex` - New module: `resolve!/1`, `normalize!/2`, `column_types!/3`, `render!/3`, `match!/3` (single-column path)
- `lib/threadline/query.ex` - `history/3`, `history_query/3` (new, `@doc false`), `row_history_query/3`, `as_of/4`, `as_of_query/4` (new, `@doc false`), `where_row/2` (new, private), doc updates
- `lib/threadline/operator_surface/live/row_history_component.ex` - `update/2` now rescues `ArgumentError` from `Threadline.history/3` / `Threadline.as_of/4` into the `:error` assign
- `test/threadline/query/row_key_read_test.exs` - New real-PG regression suite for READ-01 (9 tests)
- `test/threadline/query_test.exs` - Five `FakeUser*` schemas given `@primary_key {:id, :string, autogenerate: false}`; one test's arbitrary non-UUID id argument against `AuditChange` (binary_id key) switched to a generated UUID

## Decisions Made

- Single-column key path only; `primary_key:` override and composite-key branches in `RowKey.resolve!/1` and `normalize!/2` raise a plain `ArgumentError` for now (211-02 finishes them with the full D-02/D-03 validation message matrix).
- `column_types!/3` reads the catalog fresh on every call — no cross-call cache — because the test suite drops and recreates same-named tables with different key types, and a real adopter can retype a key column.
- The catalog lookup and the render step stay two round trips: `CAST(expr AS type)` requires `type` to be a fixed SQL-grammar token, so PostgreSQL cannot take it from a subquery in the same statement.
- `RowKey`'s qualified-table text always includes the schema (`"#{schema}.#{table}"`), never a bare table name for `public` — this both matches `Naming.qualified/1`'s always-qualified format (so the `primary_key:` override lookup actually matches public-schema tables, which the initial bare-for-public form silently never did) and matches the D-07 error message's `public.invoices`-style shape.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `override_primary_key/1` used a qualified-table format that never matched `Naming.qualified/1`'s output for `public`-schema tables**
- **Found during:** Task 1 (implementation, before any test ran against it)
- **Issue:** `resolve!/1` built its own "qualified" text that omitted the `public.` prefix for public-schema tables, while `Naming.qualified/1` (used to key the `TriggerCaptureConfig.load()` map for comparison) always includes the schema. The override lookup would therefore never match a public-schema table's `primary_key:` config entry.
- **Fix:** Removed the public-schema special case; `qualified_text/2` now always returns `"#{schema}.#{table}"`, matching `Naming.qualified/1` exactly. This also fixed the D-07 fallback error message, which needs the same `public.invoices` shape.
- **Files modified:** `lib/threadline/query/row_key.ex`
- **Verification:** Covered indirectly by the unmappable-type test (message now includes `public.rk_unmappable_users`); the override path itself is exercised in 211-02.
- **Committed in:** `6ba12e77` (part of Task 2's commit, discovered while adding the unmappable-type test)

**2. [Rule 1 - Bug] A malformed UUID-typed key value crashed with a raw Postgrex encode error instead of a clean ArgumentError**
- **Found during:** Task 1, while running the wider `query_test.exs` suite (`history/3 accepts explicit repo` test, which passed an arbitrary non-UUID string against the real `AuditChange` schema's `binary_id` key)
- **Issue:** `maybe_dump_uuid/2` only attempted `Ecto.UUID.dump/1` when the dumped value was exactly 36 bytes (canonical UUID string length). A value that is neither a canonical UUID string nor a 16-byte binary (e.g. an arbitrary short string) was passed straight through to Postgrex as a raw parameter for a `uuid`-typed `CAST`, which raised `DBConnection.EncodeError` instead of an `ArgumentError` naming the uncastable value.
- **Fix:** `maybe_dump_uuid/2` now always calls `Ecto.UUID.dump/1` for a `uuid` base type regardless of length; a dump failure now flows into `dump_value!/4`'s existing "cannot cast" `ArgumentError`, per D-06.
- **Files modified:** `lib/threadline/query/row_key.ex`
- **Verification:** `test/threadline/query_test.exs` "history/3 accepts explicit repo" now uses a generated UUID and passes; the fallback path is otherwise unaffected for well-formed values.
- **Committed in:** `d1e8fed9` (Task 1's commit)

**3. [Rule 3 - Blocking issue] Packaged planning vocabulary in `lib/` failed `release_artifact_contract_test.exs`**
- **Found during:** Task 3's `mix test` run
- **Issue:** Internal comments and two runtime `ArgumentError` messages in `row_key.ex` and `query.ex` referenced decision IDs (`D-04`, `D-05`, `D-06`, `D-18`) and phase prose (`Phase 211`, `211-02`), which `release_artifact_contract_test.exs` treats as leaked planning vocabulary in packaged source — this would have shipped in the Hex package.
- **Fix:** Reworded every flagged comment and message to durable domain rationale with no decision-ID or phase references (e.g. "This is finished in an upcoming release." instead of "This is finished in a later plan of Phase 211.").
- **Files modified:** `lib/threadline/query/row_key.ex`, `lib/threadline/query.ex`
- **Verification:** `mix test test/threadline/release_artifact_contract_test.exs` (19 tests, 0 failures)
- **Committed in:** `089d6a53` (Task 3's commit)

**4. [Rule 1 - Bug] Five pre-existing `query_test.exs` fake schemas used the default integer `:id` primary key while passing string ids**
- **Found during:** Task 3's `mix test` run (as anticipated by the plan)
- **Issue:** `FakeUser`, `FakeUser2`, `FakeUser3`, `FakeUserBval`, and `FakeUser4` had no `@primary_key` override, so their default `:id` (integer) type rejected string ids like `"u-1"` under `Ecto.Type.cast/2`, which RowKey now runs before querying.
- **Fix:** Added `@primary_key {:id, :string, autogenerate: false}` to each, matching every other fake schema already in the suite.
- **Files modified:** `test/threadline/query_test.exs`
- **Verification:** `mix test test/threadline/query_test.exs` (74 tests, 0 failures)
- **Committed in:** `089d6a53` (Task 3's commit)

---

**Total deviations:** 4 auto-fixed (3 Rule 1 bug fixes, 1 Rule 3 blocking-issue fix). All were necessary for correctness or to keep packaged source clean; no scope creep beyond this plan's stated tasks.
**Impact on plan:** None of the deviations changed the plan's design — they corrected bugs discovered while implementing and verifying it.

## Issues Encountered

None beyond the deviations documented above.

## Known Stubs

None. `primary_key:` override and composite-key support in `RowKey` are explicitly out of scope for this plan (raise a plain `ArgumentError`), documented in the plan and design decisions, and finished in 211-02.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `Threadline.Query.RowKey` and `where_row/2` are in place and proven for the single-column case; 211-02 extends `resolve!/1`/`normalize!/2` to the `primary_key:` override and composite-key paths without needing to touch `history/3`, `row_history_query/3`, or `as_of/4` again.
- `column_types!/3`'s fallback-type map and the two-round-trip catalog/render pattern are reusable as-is for composite keys.
- No blockers for 211-02, 211-03 (row-history index), or 211-04 (operator-surface composite-key guard).

## Self-Check: PASSED

- FOUND: `lib/threadline/query/row_key.ex`
- FOUND: `test/threadline/query/row_key_read_test.exs`
- FOUND: commit `d1e8fed9` (`git log --oneline --all | grep d1e8fed9`)
- FOUND: commit `6ba12e77` (`git log --oneline --all | grep 6ba12e77`)
- FOUND: commit `089d6a53` (`git log --oneline --all | grep 089d6a53`)

---
*Phase: 211-read-side-agreement*
*Completed: 2026-09-25*
