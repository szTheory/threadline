---
phase: 140-earned-new-flows
plan: "01"
subsystem: operator-surface
tags: [phoenix-liveview, row-history, schema-map, scoped-query, tdd]

requires:
  - phase: 139-orientation-hub-home-nav
    provides: "Operator surface IA baseline and Home/nav constraints preserved by Phase 140"
provides:
  - "First-class `/audit/rows/:table/:record_id` row-history route through RowHistoryLive"
  - "Safe schema-map validation for row-history table params without untrusted atom creation"
  - "Route-aware row-history component paths for first-class and transaction-scoped entry points"
affects: [operator-surface, earned-flows, row-history, transaction-live]

tech-stack:
  added: []
  patterns:
    - "Thin LiveView wrapper over existing RowHistoryComponent"
    - "Schema lookup by configured map keys, with atom-key compatibility via Atom.to_string/1 only"
    - "Explicit history_path and close_path assigns for shared LiveComponents"

key-files:
  created:
    - lib/threadline/operator_surface/live/row_history_live.ex
    - test/threadline/operator_surface/live/row_history_live_test.exs
  modified:
    - lib/threadline/operator_surface/router.ex
    - lib/threadline/operator_surface/live/row_history_component.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - test/threadline/operator_surface/row_history_component_test.exs

key-decisions:
  - "Keep first-class row history as a wrapper over RowHistoryComponent instead of adding a new query path."
  - "Close first-class row history to `/audit/timeline`, while transaction-scoped row history still closes to `/audit/transactions/:id`."
  - "Avoid untrusted atom creation by matching string route input against configured schema map keys."

patterns-established:
  - "Shared row-history component callers must pass explicit `history_path` and `close_path` when route shape differs."
  - "First-class operator flows carry earned-flow trace attributes on the LiveView shell."

requirements-completed: [POLISH-FLOWS]

duration: 5m16s
completed: 2026-06-04T15:52:17Z
---

# Phase 140 Plan 01: First-Class Row History Summary

**First-class row-history route mounted under the operator surface, reusing existing scoped history and snapshot queries with safe schema-map validation.**

## Performance

- **Duration:** 5m16s
- **Started:** 2026-06-04T15:47:01Z
- **Completed:** 2026-06-04T15:52:17Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Mounted `live("/rows/:table/:record_id", RowHistoryLive, :show)` inside the existing `threadline_operator_surface/2` live session.
- Added `RowHistoryLive` as a thin wrapper that passes table, record id, repo, schema map, scope, `scope_query_fn`, `history_path`, and `close_path` to `RowHistoryComponent`.
- Removed untrusted `String.to_atom/1` schema lookup from `RowHistoryComponent` while preserving compatibility with atom-keyed configured schema maps.
- Made row-history links route-aware so first-class `/audit/rows/...` patches stay first-class and transaction-scoped `/audit/transactions/:id/history/...` behavior remains intact.
- Added tests for the first-class route, unmapped table errors, source-level atom safety, as-of patching, close path behavior, and scoped row-history isolation.

## Task Commits

1. **Task 1: Add first-class row-history route contracts** - `077e5ff` (`test`)
2. **Task 2: Implement RowHistoryLive and safe component path contracts** - `457ee36` (`feat`)

## Files Created/Modified

- `lib/threadline/operator_surface/live/row_history_live.ex` - New first-class row-history LiveView wrapper with EF2/P1/J2 trace attributes.
- `lib/threadline/operator_surface/router.ex` - Adds the `/rows/:table/:record_id` LiveView route under the existing operator live session.
- `lib/threadline/operator_surface/live/row_history_component.ex` - Uses safe schema lookup and explicit `history_path` / `close_path` assigns.
- `lib/threadline/operator_surface/live/transaction_live.ex` - Passes transaction-scoped route paths into the shared row-history component.
- `test/threadline/operator_surface/live/row_history_live_test.exs` - Covers first-class row-history route, schema-map validation, atom safety, as-of patching, close path behavior, and scoped access.
- `test/threadline/operator_surface/row_history_component_test.exs` - Adds route-aware component path coverage.

## Verification Evidence

- `mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/transaction_live_test.exs`
  - Result: **20 tests, 0 failures**
- `rg -n "String\\.to_atom\\(" lib/threadline/operator_surface/live/row_history_component.ex`
  - Result: **no matches**
- `rg -n "live\\(\"/rows/:table/:record_id\", RowHistoryLive" lib/threadline/operator_surface/router.ex`
  - Result: `106: live("/rows/:table/:record_id", RowHistoryLive, :show)`

## Decisions Made

- Reused `Threadline.history/3` and `Threadline.as_of/4` exclusively through the existing `RowHistoryComponent`; no new query API was added.
- Kept transaction row-history behavior as the compatibility baseline and made first-class row history opt into its own explicit paths.
- Treated schema-map validation as a component-level guard so both first-class and transaction-scoped routes share the same safe lookup behavior.

## Deviations from Plan

### User-Directed Execution Adjustment

**1. Skipped normal STATE/ROADMAP updates**
- **Found during:** Plan execution setup
- **Reason:** User explicitly instructed: "Do not modify `.planning/STATE.md` or `ROADMAP.md`."
- **Impact:** This summary records completion and verification evidence, but executor state files were intentionally left untouched.

### Implementation Notes

- `test/threadline/operator_surface/transaction_live_test.exs` was run as required but did not need modification; existing scoped transaction row-history coverage remained valid after `TransactionLive` passed explicit component paths.
- One component path assertion was adjusted during GREEN to allow the database-returned `captured_at` microsecond precision while still locking the `/audit/rows/...` route shape.

## Known Stubs

None.

## Threat Flags

None. The new first-class route and schema-map trust boundary were already covered by the plan threat model.

## Issues Encountered

- Concurrent Phase 140-03 commits appeared in git history during execution. No 140-03 owned files were modified by this plan.

## User Setup Required

None.

## Next Phase Readiness

- EF1 record-first lookup can target `/audit/rows/:table/:record_id` without inventing a transaction id.
- Future row-history callers should pass explicit component paths instead of relying on transaction-relative defaults.

## Self-Check

PASSED.

- Found `lib/threadline/operator_surface/live/row_history_live.ex`
- Found `test/threadline/operator_surface/live/row_history_live_test.exs`
- Found `.planning/phases/140-earned-new-flows/140-01-SUMMARY.md`
- Found task commits `077e5ff` and `457ee36`

---
*Phase: 140-earned-new-flows*
*Completed: 2026-06-04*
