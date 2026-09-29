---
phase: 211-read-side-agreement
plan: 04
subsystem: operator-surface
tags: [phoenix-liveview, docs, changelog, requirements]

requires:
  - phase: 211-01
    provides: "Threadline.Query.RowKey / where_row/2 whole-map table_pk equality (history_query/3, as_of_query/4, row_history_query/3)"
  - phase: 211-02
    provides: "Composite-key read path and primary_key: override reads, proven by row_key_override_test.exs"
  - phase: 211-03
    provides: "audit_changes_row_history_idx and mix threadline.gen.row_history_index"
provides:
  - "change_history_path/2 guard reusing TimelineLive.Helpers.routeable_row_ref/1 so a composite, empty, or nil-keyed table_pk renders no row link"
  - "Adopter-facing docs: history/3 and as_of/4 @docs (composite/override id shapes, ArgumentError cases, scope_query_fn params.id, dropped-table fallback), guides/audit-indexing.md Row history lookups section, CHANGELOG Unreleased entries"
  - "CONF-01 marked complete in REQUIREMENTS.md"
affects: []

actuals:
  tokens: 4100
  tasks: 3
  commits: 4
  plan_head_before: aaad25d1

tech-stack:
  added: []
  patterns:
    - "Operator-surface link guards reuse the timeline's single-key predicate (TimelineLive.Helpers.routeable_row_ref/1) instead of each page defining its own, so the two surfaces cannot drift on what counts as a routeable row identity"

key-files:
  created:
    - .planning/phases/211-read-side-agreement/211-04-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/transaction_live.ex
    - test/threadline/operator_surface/transaction_live_test.exs
    - lib/threadline.ex
    - lib/threadline/query.ex
    - guides/audit-indexing.md
    - test/threadline/audit_indexing_doc_contract_test.exs
    - CHANGELOG.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "change_history_path/2 delegates entirely to Helpers.routeable_row_ref/1 rather than reimplementing the single-key rule locally; the `.link` markup is unchanged, only wrapped in `:if={row_history_path}` computed once per row via a `<% %>` binding in the :for loop"
  - "lib/threadline/query.ex stayed at 796/800 lines by keeping the added @doc prose focused on shape, errors, scope_query_fn, and the dropped-table fallback rather than repeating full option tables already documented elsewhere"
  - "CHANGELOG entries follow the file's upgrader-first convention: Breaking changes and Required action (new ArgumentError cases, the generator step) before Fixed (integer-keyed history) and Added (composite/override reads, the generator itself)"

requirements-completed: [READ-04, CONF-01]

coverage:
  - id: D1
    description: "On the transaction page, a change whose table_pk has exactly one key with a non-empty value renders the Open row history link; a composite table_pk, {} and {\"id\":null} render no row link and no link to any other row"
    requirement: READ-04
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/transaction_live_test.exs#renders a row-history link only for the single-key change (READ-04)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The existing slash-encoding link test still passes unchanged"
    requirement: READ-04
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/transaction_live_test.exs#transaction row-history links encode slash-containing record ids"
        status: pass
    human_judgment: false
  - id: D3
    description: "guides/audit-indexing.md names the index and the generator; doc contract test pins both strings"
    requirement: IDX-01
    verification:
      - kind: unit
        ref: "test/threadline/audit_indexing_doc_contract_test.exs#audit-indexing guide documents the row-history index and its generator"
        status: pass
    human_judgment: false
  - id: D4
    description: "CONF-01 read-side round trip (primary_key: override) passes at this plan's gate"
    requirement: CONF-01
    verification:
      - kind: unit
        ref: "test/threadline/query/row_key_override_test.exs"
        status: pass
    human_judgment: false
  - id: D5
    description: "mix ci.all is green"
    requirement: null
    verification:
      - kind: integration
        ref: "mix ci.all (format, credo --strict, mix test, dialyzer, mix verify.example_browser)"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-09-26
status: complete
---

# Phase 211 Plan 04: Read-Side Agreement Closeout Summary

**The transaction page's row-history link now reuses the timeline's single-key guard (no link for composite, empty, or nil-keyed rows); adopter docs, the indexing guide, and CHANGELOG carry the composite/override call shapes and the new ArgumentError cases; CONF-01 is complete; `mix ci.all` is green.**

## Performance

- **Duration:** ~55 min
- **Tasks:** 3 (1 tracer, 2 auto)
- **Files modified:** 8

## Accomplishments

- `change_history_path/2` in `transaction_live.ex` now calls `Threadline.OperatorSurface.Live.TimelineLive.Helpers.routeable_row_ref/1` and returns `nil` for a composite `table_pk`, `{}`, or `{"id" => nil}`, instead of taking the first value out of the map regardless of key count. The row-history `.link` only renders when a path exists (`:if={row_history_path}`), with the path computed once per row. A new render test inserts one transaction with a single-key, a composite, an empty, and a nil-id change and asserts exactly one `row-history-link` renders, pointed at the single-key row.
- `lib/threadline.ex` and `lib/threadline/query.ex`'s `history/3` / `as_of/4` `@doc`s now show the scalar, keyword-list, and map `id` forms (including a composite example), name every `ArgumentError` case, state that `scope_query_fn` receives `context.params.id` unchanged, and describe the dropped/renamed-table Ecto-type fallback including the `char(n)` blank-padding caveat.
- `guides/audit-indexing.md` lists `audit_changes_row_history_idx` in Installed defaults and adds a "Row history lookups" section naming `mix threadline.gen.row_history_index`, the D-13 key-size/type-allowlist fact, and the dropped-table fallback; the doc contract test now pins both the index name and the task name.
- `CHANGELOG.md` Unreleased gained upgrader-first entries: Breaking changes (new `ArgumentError` cases, replacing silent `[]`), Required action (run the generator), Fixed (integer-keyed history), Added (composite/override reads, the generator).
- `CONF-01` is ticked complete in `REQUIREMENTS.md`, gated on `row_key_override_test.exs` passing in this plan's run.
- `mix ci.all` is green: 0 compile warnings, 0 credo issues (after one alphabetize-alias fix), full `mix test` 0 failures (2117 tests, 1 excluded pgbouncer tag), Dialyzer 0 errors, browser lane 318 passed / 26 skipped / 0 failed (exactly the previously-known skip set, no new failures).

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — transaction page renders a row link only for single-key rows (READ-04)** - `ff070af6` (fix)
2. **Task 2: Expand — adopter docs, indexing guide, CHANGELOG, doc contract** - `898a5aee` (docs)
   - Follow-up: `a90b336f` (style) — credo `--strict` flagged the new `Helpers` alias as out of alphabetical order; fixed inline before the gate.
3. **Task 3: Gate — mix ci.all green; mark CONF-01 complete** - `13081b62` (docs)

## Files Created/Modified

- `lib/threadline/operator_surface/live/transaction_live.ex` — `change_history_path/2` guard, `.link` wrapped in `:if`
- `test/threadline/operator_surface/transaction_live_test.exs` — new render test for the single-key-only guard
- `lib/threadline.ex` — `history/3`/`as_of/4` delegator `@doc`s expanded
- `lib/threadline/query.ex` — `history/3`/`as_of/4` `@doc`s expanded (796/800 lines)
- `guides/audit-indexing.md` — index row + Row history lookups section
- `test/threadline/audit_indexing_doc_contract_test.exs` — new assertions for the index name and generator
- `CHANGELOG.md` — Unreleased Breaking changes / Required action / Fixed / Added entries
- `.planning/REQUIREMENTS.md` — CONF-01 checkbox and traceability row

## Decisions Made

See `key-decisions` in frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] credo `--strict` alias ordering**

- **Found during:** Task 3's `mix ci.all` gate run
- **Issue:** The `alias Threadline.OperatorSurface.Live.TimelineLive.Helpers` added in Task 1 was inserted after `Presentation`/`UI`, breaking the group's alphabetical order (`credo --strict` readability check).
- **Fix:** Reordered the three aliases alphabetically (`Live.TimelineLive.Helpers`, `Presentation`, `UI`).
- **Files modified:** `lib/threadline/operator_surface/live/transaction_live.ex`
- **Verification:** `mix credo --strict` clean on rerun; `mix ci.all` green end to end.
- **Committed in:** `a90b336f`

---

**Total deviations:** 1 auto-fixed (Rule 1 — lint fix, no scope creep).
**Impact on plan:** None on delivered scope. All must-have truths, artifacts, and prohibitions in the plan frontmatter are satisfied as written.

## Issues Encountered

None beyond the credo fix above.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Phase 211 (Read-Side Agreement) is functionally complete: READ-01 through READ-04, CONF-01, and IDX-01 are all proven and (per this plan and 211-01/02/03) recorded in `REQUIREMENTS.md`. The orchestrator runs `phase.complete` after its own verification pass; this plan intentionally does not mark the phase itself complete. No blockers identified for Phase 212 (detection and adopter twins) or Phase 213 (upgrade guide), which still owns the 0.11.0 upgrade-guide prose (out of scope here).

---
*Phase: 211-read-side-agreement*
*Completed: 2026-09-26*

## Self-Check: PASSED

All modified files verified present on disk; all 4 task commit hashes (`ff070af6`, `898a5aee`, `a90b336f`, `13081b62`) verified present in `git log`.
