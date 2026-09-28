---
phase: 211-read-side-agreement
plan: 02
subsystem: database
tags: [ecto, postgres, jsonb, raw-sql, composite-key, uuid, enum, domain]

# Dependency graph
requires:
  - phase: 211-read-side-agreement
    plan: 01
    provides: "Threadline.Query.RowKey single-column resolve!/1, normalize!/2, column_types!/3, render!/3, match!/3; history/3, row_history_query/3, as_of/4 wired onto whole-map table_pk equality"
provides:
  - "Threadline.Query.RowKey.resolve!/1: primary_key: override branch mapping declared columns back to schema fields via field_source"
  - "Threadline.Query.RowKey.normalize!/2: full D-03 validation matrix for a map or keyword list of every key field (atom or string keyed, any order), never atomizing caller input"
  - "history/3, row_history_page/4, as_of/4 all read composite-key tables and primary_key:-override tables correctly"
  - "Every allowlisted key type (bigint, uuid, text, date, timestamp with fractional seconds, char(n), enum, domain-over-integer) proven to round-trip capture -> history/3"
  - "Mixed 0.10.2/regenerated-trigger rows for the same record return from one history/3 call (READ-03)"
affects: [211-03-read-side-agreement, 211-04-read-side-agreement]

actuals:
  tokens: 9868
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "String-only key-set comparison via MapSet, never Atom.to_string/String.to_atom on caller input, so an untrusted string key can never grow the atom table"
    - "Struct rejection narrowed to is_struct(id, schema) (the schema's own loaded struct), not is_struct/1 generally, so Date/NaiveDateTime/DateTime scalar key values keep round-tripping for single-column tables"

key-files:
  created:
    - test/threadline/query/row_key_composite_test.exs
    - test/threadline/query/row_key_validation_test.exs
    - test/threadline/query/row_key_override_test.exs
    - test/threadline/query/row_key_types_test.exs
    - test/threadline/query/row_key_legacy_test.exs
  modified:
    - lib/threadline/query/row_key.ex

key-decisions:
  - "normalize!/2's map/keyword-list branch fetches each resolved field first by atom key then by its string form, so a caller can mix atom and string keys freely in the same call"
  - "Given-key `got` list in D-03 error messages is Keyword.keys/1 (keyword list) or Map.keys/1 (map) in caller order — not sorted or canonicalized — since D-03 only requires the misnamed key be shown verbatim, not a specific ordering"
  - "override_fields!/2 builds a field_source -> field reverse map from schema.__schema__(:fields) once per resolve!/1 call; a declared override column with no match raises immediately, before any query is built"

patterns-established:
  - "Every RowKey argument-shape branch (struct/map/keyword-list/scalar) is a distinct function clause with a guard, not a single body with cond — keeps each D-03 message next to the shape it protects"

requirements-completed: [READ-02, READ-03]

coverage:
  - id: D1
    description: "A composite-key row is returned by history/3, row_history_page/4, and as_of/4 when its key is passed as a keyword list, an atom-keyed map, or a string-keyed map, in any order; a sibling key with a shared column value stays separate"
    requirement: READ-02
    verification:
      - kind: integration
        ref: "test/threadline/query/row_key_composite_test.exs#keyword list, atom-keyed map, and string-keyed map all return the (1,5) history"
        status: pass
      - kind: integration
        ref: "test/threadline/query/row_key_composite_test.exs#(2,5) returns only its own insert, never the (1,5) rows"
        status: pass
      - kind: integration
        ref: "test/threadline/query/row_key_composite_test.exs#row_history_page/4 and as_of/4 agree for (1,5)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A stored single-key change ({\"id\": \"5\"}) is never returned by a composite lookup (adjacency edge); a composite table's history stays readable after DROP TABLE via the fallback type map"
    requirement: READ-02
    verification:
      - kind: integration
        ref: "test/threadline/query/row_key_composite_test.exs#adjacency: a hand-built change with a single-key table_pk is never returned by a composite lookup"
        status: pass
      - kind: integration
        ref: "test/threadline/query/row_key_composite_test.exs#a dropped composite table (fallback type map) stays readable for history/3 and as_of/4 after DROP TABLE"
        status: pass
    human_judgment: false
  - id: D3
    description: "A missing, extra, or misnamed key, a nil field value, an empty map/keyword list, a scalar for a composite table, and a loaded struct all raise ArgumentError with the D-03 message shapes; a caller string key that names no field never grows the atom table"
    requirement: READ-02
    verification:
      - kind: unit
        ref: "test/threadline/query/row_key_validation_test.exs (13 tests, DB-free, async: true)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A primary_key: override table (declared columns mapped to schema fields via field_source) reads through history/3 under both the bare and \"public.\"-qualified config-key spelling; a declared column with no mapped field raises naming the column and schema"
    requirement: CONF-01
    verification:
      - kind: integration
        ref: "test/threadline/query/row_key_override_test.exs (4 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Every allowlisted key type (bigint, uuid, text byte-exact, date, a .5-fractional-second timestamp, char(8) padding, a PostgreSQL enum given as atom and string, a domain-over-integer) round-trips capture -> history/3, independent of SET LOCAL DateStyle = 'SQL, DMY'"
    requirement: READ-02
    verification:
      - kind: integration
        ref: "test/threadline/query/row_key_types_test.exs (8 tests, each run plainly and inside a DateStyle-altered transaction)"
        status: pass
    human_judgment: false
  - id: D6
    description: "One history/3 call returns both a row captured by the frozen 0.10.2 trigger and a row captured after the trigger is regenerated, byte-identical table_pk; hand-inserted {} and {\"id\": null} rows are never returned; two changes sharing captured_at come back in stable order across repeated calls"
    requirement: READ-03
    verification:
      - kind: integration
        ref: "test/threadline/query/row_key_legacy_test.exs (3 tests)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Full default test suite is green with the composite/override/type-matrix read path"
    verification:
      - kind: unit
        ref: "mix test (2107 tests, 0 failures, 1 excluded)"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-09-26
status: complete
---

# Phase 211 Plan 02: Composite keys, primary_key: override reads, and the full type matrix Summary

**Finished `Threadline.Query.RowKey` for every key shape Phase 210 captures — composite keys via keyword list or map, `primary_key:`-override tables, the full allowlisted type matrix, and mixed 0.10.x/regenerated rows — and fixed two real bugs the composite-key path exposed in 211-01's UUID handling and struct rejection.**

## Performance

- **Duration:** 55 min (commit-to-commit span; investigation/reading time not counted)
- **Started:** 2026-09-26T01:22:xx-04:00 (first task commit)
- **Completed:** 2026-09-26T02:17:xx-04:00 (final task commit)
- **Tasks:** 3 completed
- **Files modified:** 6 (5 new test files, 1 modified library module)

## Accomplishments

- Finished `RowKey.resolve!/1`'s `primary_key:` override branch: `override_fields!/2` maps each declared column back to the schema field whose `field_source` equals it, in declared order, raising `ArgumentError` naming the column and schema when no field maps to it.
- Generalized `RowKey.normalize!/2` to the full D-03 validation matrix: a map or keyword list of every key field (atom- or string-keyed, in any order) is validated by comparing `MapSet`s of the given and resolved field names as strings, never atomizing caller input. A missing/extra/misnamed key, a nil field value, an empty map/keyword list, a scalar for a composite table, and a loaded struct of the schema itself all raise `ArgumentError` with the exact D-03 message shapes. Single-column tables keep accepting a bare scalar as sugar.
- Proved on real PostgreSQL that `history/3`, `row_history_page/4`, and `as_of/4` all read composite-key tables correctly (sibling-key isolation, adjacency against a hand-built single-key change, the dropped-table fallback) and that `primary_key:`-override tables read through the declared columns under both the bare and schema-qualified config-key spelling.
- Proved every allowlisted key type — bigint, uuid, text, date, a `.5`-fractional-second timestamp, `char(8)` padding, a PostgreSQL enum (atom and string), and a domain-over-integer — round-trips capture to `history/3`, independent of a `SET LOCAL DateStyle = 'SQL, DMY'` change in the reading transaction.
- Proved READ-03: one `history/3` call returns both a row captured under the frozen 0.10.2 trigger and a row captured after the trigger is regenerated, with byte-identical `table_pk`; hand-inserted `{}` and `{"id": null}` rows are never returned; two changes sharing `captured_at` return in stable `captured_at DESC, id DESC` order across repeated calls.
- Fixed a double-dump bug in `maybe_dump_uuid/2`: an `Ecto.UUID`-typed schema field already dumps to the 16-byte binary form itself (unlike `:binary_id`, whose dump is a pass-through no-op), so calling `Ecto.UUID.dump/1` again on that binary raised `ArgumentError` for every composite key with an `Ecto.UUID` field — discovered by the dropped composite-table test in Task 1.
- Fixed `normalize!/2`'s struct rejection: it originally matched *any* struct value (`is_struct/1`), not just a loaded struct of the schema itself, so a `Date` or `NaiveDateTime` scalar id — a legitimate, allowlisted key value — raised instead of round-tripping. Narrowed to `is_struct(id, schema)`; the generic map clause now explicitly excludes structs so a non-schema struct falls through to the scalar path for single-column tables.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — composite key end to end via keyword list and map (READ-02)** - `204bd854` (feat)
2. **Task 2: Expand — D-03 validation matrix and primary_key: override reads (CONF-01 read half)** - `f39ea9a4` (test)
3. **Task 3: Expand — type round-trip matrix, mixed legacy rows, unresolved sentinels (READ-02 encoding, READ-03)** - `e6f612d5` (fix)

## Files Created/Modified

- `lib/threadline/query/row_key.ex` - `override_fields!/2` (new), `normalize!/2` generalized to the full D-03 matrix (struct/map/keyword-list/scalar branches, `validate_key_set!/3`, `key_to_string/1`, `fetch_field!/3`), `maybe_dump_uuid/2` fixed for already-16-byte values
- `test/threadline/query/row_key_composite_test.exs` - New: composite lookup via all three argument shapes, sibling-key isolation, adjacency, dropped-table fallback (5 tests)
- `test/threadline/query/row_key_validation_test.exs` - New: DB-free D-03 message matrix, `async: true` (13 tests)
- `test/threadline/query/row_key_override_test.exs` - New: `primary_key:` override reads, both config-key spellings, missing-mapped-field error (4 tests)
- `test/threadline/query/row_key_types_test.exs` - New: full allowlisted type round-trip matrix, twice per case (8 tests)
- `test/threadline/query/row_key_legacy_test.exs` - New: mixed 0.10.2/regenerated rows, unresolved sentinels, ordering stability (3 tests)

## Decisions Made

- The override branch's field-mapping helper (`override_fields!/2`) builds one `field_source -> field` reverse map per `resolve!/1` call, not cached — matches 211-01's existing "no cross-call cache" precedent for `column_types!/3` (an adopter can rename a `source:` field and the read side should pick it up without an app restart).
- D-03's "got" list in error messages preserves caller order (`Keyword.keys/1` or `Map.keys/1`), not a canonicalized/sorted form — the CONTEXT.md examples only require the misnamed key be shown verbatim, and sorting would cost clarity for no D-03-mandated benefit.
- Both real bugs found in Task 1 and Task 3 (UUID double-dump, over-broad struct rejection) were fixed in `row_key.ex` directly rather than worked around in the test fixtures, since both were genuine defects that would have broken real adopter schemas (any `Ecto.UUID`-typed composite key column; any `Date`/`NaiveDateTime`/`DateTime` single-column key).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `maybe_dump_uuid/2` double-dumped an already-16-byte `Ecto.UUID`-typed value**
- **Found during:** Task 1, writing the dropped composite-table test (`RkDroppedPair` with an `Ecto.UUID`-typed `:token` field)
- **Issue:** `Ecto.Type.dump(Ecto.UUID, uuid_string)` already returns the 16-byte binary form (unlike `Ecto.Type.dump(:binary_id, uuid_string)`, which is a pass-through no-op returning the same string). `maybe_dump_uuid/2` unconditionally called `Ecto.UUID.dump/1` again on the base_type `"uuid"` result, and `Ecto.UUID.dump/1` returns `:error` for a 16-byte binary input (it only accepts a canonical 36-char string or already-dumped 16 bytes it treats identically — but in this codepath the *second* dump call received the *first* dump call's 16-byte output and rejected it), raising `ArgumentError: cannot cast ... to key field :token`.
- **Fix:** `maybe_dump_uuid/2` now matches a `<<_::128>>` (already-16-byte) value first and passes it through unchanged; only a value of any other length is sent to `Ecto.UUID.dump/1` to normalize or reject.
- **Files modified:** `lib/threadline/query/row_key.ex`
- **Verification:** `test/threadline/query/row_key_composite_test.exs` (dropped composite table, `Ecto.UUID`-typed key column) and `test/threadline/query/row_key_types_test.exs` (uuid round-trip case) both pass; `test/threadline/query/row_key_read_test.exs` (211-01's `:binary_id` malformed-UUID regression) still passes unchanged.
- **Committed in:** `204bd854` (Task 1's commit)

**2. [Rule 1 - Bug] `normalize!/2` rejected any struct value, not just a loaded struct of the schema itself**
- **Found during:** Task 3, writing the date and timestamp round-trip tests
- **Issue:** The struct-rejection clause used the `is_struct(id)` guard, which matches *any* Elixir struct — including `Date`, `NaiveDateTime`, and `DateTime`, all of which are legitimate, allowlisted scalar key values per D-04. A `Date`/`NaiveDateTime` id for a single-column date/timestamp-keyed table raised `ArgumentError: ... struct is not accepted as a row key` instead of round-tripping.
- **Fix:** Narrowed the rejection to `is_struct(id, schema)` (a loaded struct of the schema module itself, the case D-01 actually defers). The generic map-handling clause's guard was changed to `is_map(id) and not is_struct(id)`, so any other struct (Date, NaiveDateTime, DateTime, or an adopter's own unrelated struct) falls through to the single-column scalar clause instead of being misread as a field/value map.
- **Files modified:** `lib/threadline/query/row_key.ex`
- **Verification:** `test/threadline/query/row_key_types_test.exs` (date and timestamp cases) pass; `test/threadline/query/row_key_validation_test.exs`'s "a loaded struct is rejected outright" test (using `%RkLineItemV{}`, the schema's own struct) still passes.
- **Committed in:** `e6f612d5` (Task 3's commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bug fixes). Both were genuine defects in 211-01's UUID and struct handling, only exposed once composite keys and the full type matrix were exercised; no scope creep beyond this plan's stated tasks.
**Impact on plan:** Neither deviation changed the plan's design — both corrected bugs discovered while implementing and verifying it. `CONF-01`'s completion is recorded in 211-04 per the orchestrator instruction; it is not marked complete in REQUIREMENTS.md here.

## Issues Encountered

None beyond the deviations documented above.

## Known Stubs

None. Every branch this plan's `must_haves` and behavior list called for is implemented and tested against real PostgreSQL or a DB-free unit matrix; no placeholder or deferred-data paths were introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `Threadline.Query.RowKey` now handles every key shape Phase 210 captures: single-column, composite, `primary_key:` override, the full type allowlist, and mixed legacy/regenerated rows. 211-03 (row-history index) and 211-04 (operator-surface composite-key guard, CONF-01 sign-off) build on this without needing further changes to `resolve!/1` or `normalize!/2`.
- `column_types!/3`'s two-round-trip catalog/render pattern and fallback-type map, already proven for single-column keys in 211-01, are confirmed working unchanged for composite keys and every allowlisted type.
- No blockers for 211-03 or 211-04.

## Self-Check: PASSED

- FOUND: `lib/threadline/query/row_key.ex`
- FOUND: `test/threadline/query/row_key_composite_test.exs`
- FOUND: `test/threadline/query/row_key_validation_test.exs`
- FOUND: `test/threadline/query/row_key_override_test.exs`
- FOUND: `test/threadline/query/row_key_types_test.exs`
- FOUND: `test/threadline/query/row_key_legacy_test.exs`
- FOUND: commit `204bd854` (`git log --oneline --all | grep 204bd854`)
- FOUND: commit `f39ea9a4` (`git log --oneline --all | grep f39ea9a4`)
- FOUND: commit `e6f612d5` (`git log --oneline --all | grep e6f612d5`)

---
*Phase: 211-read-side-agreement*
*Completed: 2026-09-26*
