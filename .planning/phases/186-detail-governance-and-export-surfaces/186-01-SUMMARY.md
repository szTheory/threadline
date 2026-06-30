---
phase: 186-detail-governance-and-export-surfaces
plan: 01
subsystem: operator-surface
tags: [phoenix-liveview, detail-pages, drawer, actor-ref]

requires:
  - phase: 183-shell-navigation-and-home-orientation
    provides: shell navigation, page header, and Timeline nav context patterns
  - phase: 184-timeline-investigation-flow
    provides: cleaned Timeline investigation pivots and state lattice
  - phase: 185-coverage-and-audit-readiness
    provides: operator workflow hierarchy and no broad screenshot expansion posture
provides:
  - Transaction detail page with generic H1, detail header metadata, and locked state copy
  - Row history standalone page detail anatomy plus UI.drawer-backed overlay component
  - Actor activity detail page with bounded actor-kind parsing and detail metadata
affects: [operator-surface, detail-pages, timeline-drilldowns, row-history]

tech-stack:
  added: []
  patterns:
    - UI.page_header plus UI.detail_header for detail pages
    - UI.drawer for row-history overlays
    - bounded route string parsing through compile-time allowlists

key-files:
  created:
    - .planning/phases/186-detail-governance-and-export-surfaces/186-01-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/transaction_live.ex
    - lib/threadline/operator_surface/live/row_history_live.ex
    - lib/threadline/operator_surface/live/row_history_component.ex
    - lib/threadline/operator_surface/live/actor_live.ex
    - test/threadline/operator_surface/transaction_live_test.exs
    - test/threadline/operator_surface/live/row_history_live_test.exs
    - test/threadline/operator_surface/row_history_component_test.exs
    - test/threadline/operator_surface/live/actor_live_test.exs

key-decisions:
  - "Kept Transaction, Row history, and Actor activity in Timeline nav context while moving object identity out of page H1s."
  - "Converted row-history overlay to UI.drawer instead of proving parity for the old tl-subview implementation."
  - "Parsed actor route kinds with a private allowlist instead of String.to_atom/1 or untrusted atom conversion."

patterns-established:
  - "Detail pages render one page-level H1 and one UI.detail_header object summary."
  - "Route-backed row-history overlays keep data-testid=row-history-drawer while relying on UI.drawer focus and Escape behavior."

requirements-completed: [DETAIL-01]

duration: 10 min
completed: 2026-06-30
status: complete
---

# Phase 186 Plan 01: Detail Governance And Export Surfaces Summary

**Transaction, Row history, and Actor activity now share the Phase 186 detail-header contract with drawer-backed row history and bounded actor route parsing.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-06-30T11:24:22Z
- **Completed:** 2026-06-30T11:34:16Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Transaction detail now renders one page H1 named `Transaction`, a separate `UI.detail_header` title, full-value copy targets, and locked not-found/no-change recovery copy.
- Row history now renders a standalone page H1 named `Row history`, a compact detail summary, and a `UI.drawer` overlay that retains `data-testid="row-history-drawer"`, close paths, Escape/focus attributes, and as-of patching.
- Actor activity now renders one page H1 named `Actor activity`, detail metadata for actor/window/count/scope, `Open timeline` recovery actions, and an allowlisted actor-kind parser with no untrusted atom creation.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Transaction detail contract tests** - `a3d92ad8` (test)
2. **Task 1 GREEN: Transaction detail surface** - `42f0bfeb` (feat)
3. **Task 2 RED: Row history detail/drawer tests** - `43ee7e75` (test)
4. **Task 2 GREEN: Row history detail and drawer** - `6685aeb1` (feat)
5. **Task 3 RED: Actor detail and atom-safety tests** - `f331f2d3` (test)
6. **Task 3 GREEN: Actor activity detail surface** - `3022e2e0` (feat)
7. **Verification stability: serialize actor detail tests** - `9333f8fc` (test)

## Files Created/Modified

- `lib/threadline/operator_surface/live/transaction_live.ex` - Separates Transaction page H1 from object detail metadata and uses shared state components for recovery states.
- `lib/threadline/operator_surface/live/row_history_live.ex` - Adds standalone Row history page header and detail summary metadata.
- `lib/threadline/operator_surface/live/row_history_component.ex` - Uses `UI.drawer/1` for row-history overlay behavior while retaining route state and test ids.
- `lib/threadline/operator_surface/live/actor_live.ex` - Adds allowlisted actor-kind parsing and Actor activity detail metadata.
- `test/threadline/operator_surface/transaction_live_test.exs` - Locks Transaction H1/detail-header/state copy behavior.
- `test/threadline/operator_surface/live/row_history_live_test.exs` - Locks standalone Row history H1/detail summary behavior.
- `test/threadline/operator_surface/row_history_component_test.exs` - Locks row-history drawer contract markers.
- `test/threadline/operator_surface/live/actor_live_test.exs` - Locks Actor activity H1/detail metadata and invalid-kind atom safety.

## Decisions Made

- Used the existing `UI.detail_header/1` instead of page-local object-summary markup.
- Used `UI.drawer/1` for row history rather than retaining `tl-subview` and proving equivalent behavior.
- Kept actor route parsing private to `ActorLive` with the known ActorRef kinds listed as compile-time atoms.

## TDD Gate Compliance

- RED commits exist for Transaction, Row history, and Actor activity before their GREEN implementation commits.
- GREEN commits follow each RED commit and pass the targeted task verification.
- No refactor-only commits were needed.

## Verification

- `mix test test/threadline/operator_surface/transaction_live_test.exs` - passed
- `mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs` - passed
- `mix test test/threadline/operator_surface/live/actor_live_test.exs` - passed
- `mix test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/live/actor_live_test.exs` - passed
- `rg -n "String\\.to_atom\\(" lib/threadline/operator_surface/live/actor_live.ex` - no matches
- `mix compile --warnings-as-errors` - passed

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Serialized actor detail tests for the combined detail lane**
- **Found during:** Plan-level verification after Task 3
- **Issue:** The exact Phase 186 detail test lane could race shared audit table setup while `actor_live_test.exs` still ran async, causing transient foreign-key and not-found failures in the combined command despite individual task slices passing.
- **Fix:** Changed both Actor LiveView test modules to `async: false`.
- **Files modified:** `test/threadline/operator_surface/live/actor_live_test.exs`
- **Verification:** The exact combined Phase 186 detail test command passed with 37 tests.
- **Committed in:** `9333f8fc`

---

**Total deviations:** 1 auto-fixed (Rule 3).
**Impact on plan:** Verification stability improved without changing production behavior or expanding scope.

## Issues Encountered

- Concurrent executors briefly left unrelated Phase 186 files dirty while this plan was running. Those files were outside the owned write scope and were not staged or modified by this executor.

## Known Stubs

None.

## Threat Flags

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

DETAIL-01 is complete for Transaction, Row history, and Actor activity. Later Phase 186 plans can build on the shared detail anatomy without changing routes, test ids, optional dependencies, or actor/row-history safety boundaries.

## Self-Check: PASSED

- Verified all key source, test, and summary files exist on disk.
- Verified all seven `186-01` task commits exist in git history.

---
*Phase: 186-detail-governance-and-export-surfaces*
*Completed: 2026-06-30*
