---
phase: 226-pure-property-tests-and-run-budget
plan: 02
subsystem: testing
tags: [stream_data, property-testing, cursor-paging, keyset, mutation-testing]

requires:
  - phase: 226-pure-property-tests-and-run-budget
    provides: "Threadline.Test.PropertyRuns (pure/1, db/1 run-budget knob) and the reusable .planning/.../tools/mutation-control.sh runner (226-01)"
provides:
  - "Threadline.Query.Cursors.actor_history_page/4 — the whole actor-history post-fetch step (trim, has_next?/has_prev?, next/prev cursors), callable without a database"
  - "Threadline.Test.CursorGenerators (test/support/cursor_generators.ex): entries_gen/0, paging_gen/0 — tie-heavy, shuffled, size-independent"
  - "Threadline.Test.KeysetModel (test/support/keyset_model.ex): expected_order/1, actor_history_fetch/4, timeline_fetch/3, walk_actor_history/2, walk_timeline/2 — independent in-memory model of the keyset SQL, pinned to real Cursors functions"
  - "PROP-01 property: test/threadline/query/cursors_property_test.exs"
  - "D-05 DB agreement tests in test/threadline/query_test.exs (new actor-history tie test + model-agreement addition to the existing timeline tie test)"
  - "Two PROP-01 mutation controls recorded in evidence/"
affects: [226-03, 226-04, 226-05, 226-06, 227]

actuals:
  tokens: 7930
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "A pure in-memory model drives the real lib/ post-fetch/cursor functions directly (not a copy of their logic), so a property test exercises the code the product runs without a database"
    - "The model and the SQL never share a comparator or ordering constant — each mutation control targets only one side, so a SQL ordering bug can be invisible to the pure property and still be caught by a DB-pinned example test"
    - "A bounded Enum.reduce_while walker (n + 2 steps) turns a broken cursor into a named failure instead of a hang"

key-files:
  created:
    - test/support/cursor_generators.ex
    - test/support/keyset_model.ex
    - test/threadline/query/cursors_property_test.exs
    - .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/cursor.patch
    - .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/cursor_sql.patch
    - .planning/phases/226-pure-property-tests-and-run-budget/evidence/PROP-01-mutation-cursor.md
    - .planning/phases/226-pure-property-tests-and-run-budget/evidence/PROP-01-mutation-cursor-sql.md
    - .planning/phases/226-pure-property-tests-and-run-budget/deferred-items.md
  modified:
    - lib/threadline/query/cursors.ex
    - lib/threadline/query.ex
    - test/threadline/query_test.exs

key-decisions:
  - "D-01's refactor stopped at actor_history_page/4: timeline_page/2 and row_history_page/4 already delegate their post-fetch glue to the standalone pure Cursors.timeline_page_next_cursor/2, so no further extraction was needed there (research open question 1 resolved)"
  - "KeysetModel.walk_actor_history/2 and walk_timeline/2 route both directions through one private call site (actor_history_page/5) into the real Cursors.actor_history_page/4, so the mutation-control acceptance grep (exactly 1 occurrence) holds even though both forward and backward walks exercise it"
  - "The D-05 actor-history test builds its own forward/backward walk inline (mirroring the public API's after:/before: contract) rather than reusing KeysetModel's walker, then asserts both walks equal KeysetModel's own walk on the same fixture — this is what ties the model to the real SQL"

requirements-completed: [PROP-01]

coverage:
  - id: D1
    description: "Cursors.actor_history_page/4 is the whole actor-history post-fetch step (trim, has_next?/has_prev?, next/prev cursor construction), and Query.actor_history/2 delegates to it with no behaviour change — existing query_test.exs tests pass unchanged"
    requirement: "PROP-01"
    verification:
      - kind: unit
        ref: "mix test test/threadline/query_test.exs test/threadline/investigation_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "PROP-01 property proves both the actor-history and timeline cursors return every generated entry exactly once, in the independent byte-order order, with set equality, no duplicates, and (actor history) backward-walk page reproduction / (timeline) the honest at-most-one-empty-trailing-page behaviour — at scale 1 and THREADLINE_PROPERTY_SCALE=5"
    requirement: "PROP-01"
    verification:
      - kind: unit
        ref: "mix test test/threadline/query/cursors_property_test.exs"
        status: pass
      - kind: unit
        ref: "THREADLINE_PROPERTY_SCALE=5 mix test test/threadline/query/cursors_property_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-05 DB agreement: a new actor-history tie test (7 transactions, 3/1/3 occurred_at tie groups, fixed timestamps) and the existing timeline tie test both compare real paged DB output to KeysetModel.expected_order/1 and the model's own walk on the same fixture"
    requirement: "PROP-01"
    verification:
      - kind: unit
        ref: "mix test test/threadline/query_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "Both D-06 mutation controls recorded: cursor.patch (wrong-end reverse trim) kills the PROP-01 property 5/5; cursor_sql.patch (id tie-break flipped) leaves the property green 5/5 while failing the D-05 DB agreement tests 5/5, with the D-06 coverage-boundary sentence recorded verbatim"
    verification:
      - kind: other
        ref: "bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh --max-runs 200 .planning/.../tools/mutations/cursor.patch test/threadline/query/cursors_property_test.exs 5"
        status: pass
      - kind: other
        ref: "bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh --inverted test/threadline/query/cursors_property_test.exs .planning/.../tools/mutations/cursor_sql.patch test/threadline/query_test.exs 5"
        status: pass
    human_judgment: false

duration: ~1h
completed: 2026-10-01
status: complete
---

# Phase 226 Plan 2: Pure Property Tests and Run Budget — PROP-01 Cursor Paging Summary

**PROP-01 cursor-paging property (actor-history + timeline) against an independent keyset-SQL model, pinned to real Postgres with new DB tie-agreement tests, with both D-06 mutation controls recorded 5/5.**

## Performance

- **Duration:** ~1h
- **Started:** 2026-10-01 (approx. 12:30 ET)
- **Completed:** 2026-10-01T13:18:01Z
- **Tasks:** 3
- **Files modified:** 8 (5 created, 3 modified)

## Accomplishments

- `Cursors.actor_history_page/4` — the whole actor-history post-fetch step moved out of `Query.actor_history/2` into one pure function in `Cursors`, so the property exercises the exact code the product runs. No test changes needed for this task; `query_test.exs` and `investigation_test.exs` pass unchanged (D-01).
- `Threadline.Test.CursorGenerators` — 0..60 entries built as tie groups (`frequency`-weighted sizes so 60-70% share a timestamp with a neighbour, adjacent groups often 1µs apart), unique ids by construction, shuffled output order, and `paging_gen/0` biasing page size toward 1-3 while also drawing `n` and `n+1` (D-02).
- `Threadline.Test.KeysetModel` — an in-memory model of the keyset SQL comparing `{usec, lowercase uuid}` keys, built independently of any `lib/` comparator (D-03). `walk_actor_history/2` and `walk_timeline/2` drive the real `Cursors.actor_history_page/4` and `Cursors.timeline_page_next_cursor/2` against the model's own fetch, bounded at `n + 2` steps, failing with `"cursor did not advance"` instead of hanging (D-04.6).
- PROP-01 property (`cursors_property_test.exs`) proves, for both cursors: concatenated page ids equal the independent byte-order oracle; set equality with the input; no duplicates; (actor history) walking `before:` back from the last page reproduces every earlier forward page; (timeline) at most one empty trailing page, only when `n == 0` or the entries divide evenly by the page size (D-04). Green at scale 1 and `THREADLINE_PROPERTY_SCALE=5`, and re-verified green across 5 different seeds at scale 5.
- D-05: a new DB example test ("pages across occurred_at ties forward and backward without duplicates or skips") pages 7 transactions in 3/1/3 fixed-timestamp tie groups forward then backward and asserts against `KeysetModel`; the existing timeline tie test gained the same model-agreement assertion (`timeline_page_fixture/1` now returns its inserted changes instead of discarding them).
- Both D-06 mutation controls recorded 5/5 in `evidence/`: `cursor.patch` (wrong-end reverse trim) kills the property strongly (shrinks to 0-1 successful runs); `cursor_sql.patch` (id tie-break flipped to `asc` in both `actor_history_window/3` and `timeline_order/1`) leaves the property green as predicted while failing all three D-05-style DB tests, with the D-06 coverage-boundary sentence recorded verbatim.

## Task Commits

Each task was committed atomically:

1. **Task 1: D-01 — move actor-history page assembly into Cursors.actor_history_page/4** - `ccf57a6e` (refactor)
2. **Task 2: Tie-heavy generators, the keyset model and the PROP-01 property** - `8313c268` (test)
3. **Task 3: D-05 DB agreement tests and both D-06 mutation controls** - `6f1abf30` (test, D-05) + `9965e921` (test, mutation evidence)

_Note: Task 3 split into two `test:` commits — the DB agreement test changes, then the mutation-control patches and evidence fragments — mirroring 226-01's precedent that splitting a task's natural sub-steps into separate commits is fine._

## Files Created/Modified

- `lib/threadline/query/cursors.ex` - `actor_history_page/4`: the whole trim/has_next?/has_prev?/cursor-build post-fetch step
- `lib/threadline/query.ex` - `actor_history/2` now delegates to `Cursors.actor_history_page/4`
- `test/support/cursor_generators.ex` - `Threadline.Test.CursorGenerators`: `entries_gen/0`, `paging_gen/0`
- `test/support/keyset_model.ex` - `Threadline.Test.KeysetModel`: the independent keyset-SQL model and bounded walkers
- `test/threadline/query/cursors_property_test.exs` - PROP-01 property for both cursors
- `test/threadline/query_test.exs` - new D-05 actor-history tie test; `timeline_page_fixture/1` returns its changes; existing timeline tie test gained a model-agreement assertion
- `.planning/.../tools/mutations/cursor.patch`, `.../cursor_sql.patch` - the two D-06 mutants
- `.planning/.../evidence/PROP-01-mutation-cursor.md`, `.../PROP-01-mutation-cursor-sql.md` - mutation-control evidence, 5/5 each, with the D-06 coverage-boundary sentence
- `.planning/.../deferred-items.md` - logs a pre-existing (226-01) `mix format` defect in `redaction_policy_generators.ex`, out of this task's scope

## Decisions Made

- D-01's refactor was scoped to `actor_history_page/4` only: `timeline_page/2` and `row_history_page/4` already delegate their post-fetch glue to the standalone pure `Cursors.timeline_page_next_cursor/2`, so research open question 1 ("does the timeline path need the same extraction?") resolves to no.
- Both legs of `KeysetModel.walk_actor_history/2` (forward via `after:`, backward via `before:`) route through one shared private call site into `Cursors.actor_history_page/4`, rather than two separate inline calls, so the real function is exercised identically in both directions and the plan's "exactly one call site" acceptance check holds.
- The D-05 actor-history DB test builds its own forward/backward walk against the public `Threadline.actor_history/2` API (mirroring real caller usage of `after:`/`before:`) rather than reusing `KeysetModel`'s walker for the DB side, then asserts both walks equal `KeysetModel.walk_actor_history/2`'s output on the identical fixture — this independent-walk-then-compare shape is what pins the model to the real SQL, per D-05's stated purpose.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written for `lib/` and test behavior.

### Noted but not fixed (out of scope)

**1. [Scope boundary] Pre-existing `mix format` defect in `test/support/redaction_policy_generators.ex`**
- **Found during:** Task 3, full-suite format check
- **Issue:** Two spots (`defect_tags/0`'s list, `too_long_gen/0`'s `gen all(...)` clause) are not formatted per `mix format --check-formatted`
- **Confirmed pre-existing:** checked `mix format --check-formatted` against the 226-01 commit, before any 226-02 change touched this file — same two violations present
- **Action:** logged to `.planning/phases/226-pure-property-tests-and-run-budget/deferred-items.md`, not fixed (not caused by this plan's changes; this file is untouched by 226-02)

---

**Total deviations:** 0 auto-fixed; 1 out-of-scope item logged, not fixed.
**Impact on plan:** None. No scope creep.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- PROP-01 is fully proven: the pure property, the DB agreement tests, and both D-06 mutation controls are all green/red exactly as predicted.
- `KeysetModel` and `CursorGenerators` are reusable building blocks; `229`'s generator-coverage test (D-22) can sample `CursorGenerators.entries_gen/0` directly for its tie-rate floor assertions.
- Phase 227's DB-backed, generated-data cursor layer can reuse `CursorGenerators` and the mutation-control script per the phase CONTEXT's deferred note.
- The pre-existing `redaction_policy_generators.ex` format defect (226-01) remains open in `deferred-items.md`; the full `mix format --check-formatted` is otherwise clean after this plan.
- No blockers for 226-03 onward.

---
*Phase: 226-pure-property-tests-and-run-budget*
*Completed: 2026-10-01*

## Self-Check: PASSED

All 8 created/modified files confirmed present on disk; all 4 task commits (`ccf57a6e`, `8313c268`, `6f1abf30`, `9965e921`) confirmed in `git log --oneline --all`.
