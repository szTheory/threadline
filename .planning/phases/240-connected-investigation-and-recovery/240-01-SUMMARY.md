---
phase: 240-connected-investigation-and-recovery
plan: "01"
subsystem: ui
tags: [phoenix-liveview, row-history, timeline, playwright, accessibility]

# Dependency graph
requires: []
provides:
  - Timeline-origin row-history URLs retain canonical supported filters and selected as-of state.
  - Transaction-origin row history returns to its originating transaction and is gated by parent availability.
  - Direct row-history connection failures have a retry action and truthful safe-return copy.
affects: [240-02, 240-03, operator-ui]

# Actuals (#2632)
actuals:
  tokens: 7602
  tasks: 3
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Reuse FilterParams as the sole allowlist and canonical URL builder for Timeline context.
    - Reconstruct local return destinations from a bounded origin marker, never from an arbitrary URL.
    - Gate nested row-history reads on successful transaction-parent loading.

key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/timeline_live/helpers.ex
    - lib/threadline/operator_surface/live/row_history_live.ex
    - lib/threadline/operator_surface/live/row_history_component.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface/live/row_history_live_test.exs
    - test/threadline/operator_surface/row_history_component_test.exs
    - test/threadline/operator_surface/transaction_live_test.exs
    - test/threadline/operator_surface/timeline_browse_doc_contract_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts

key-decisions:
  - "Recognize only origin=timeline; pass its filter state through FilterParams and discard unknown URL fields."
  - "Treat only DBConnection.ConnectionError as retryable row-history unavailability; preserve other evidence states."
  - "An unavailable transaction parent remains authoritative and never mounts its row-history child."

patterns-established:
  - "As-of history links merge only validated Timeline context and the selected timestamp into a local route."
  - "Retryable drawer errors use an explicit component event and preserve host repo/scope assigns."

requirements-completed: [UII-04]
coverage:
  - id: D1
    description: Timeline-origin row history retains canonical committed filters and selected as-of state, then safely returns to the originating Timeline.
    requirement: UII-04
    verification:
      - kind: integration
        ref: test/threadline/operator_surface/live/row_history_live_test.exs#timeline origin keeps only canonical filters through as-of and safe return
        status: pass
      - kind: e2e
        ref: examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts#Timeline-origin row history preserves committed filters and safe return
        status: pass
    human_judgment: false
  - id: D2
    description: Transaction-origin row history preserves its transaction identity, and unavailable parents trigger no child history read.
    requirement: UII-04
    verification:
      - kind: integration
        ref: test/threadline/operator_surface/transaction_live_test.exs#unavailable transaction parent does not read or render child row history
        status: pass
      - kind: e2e
        ref: examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts#transaction-origin row history returns to the same transaction
        status: pass
    human_judgment: false
  - id: D3
    description: Direct row-history connection failures are retryable and remain distinct from empty or absent evidence.
    requirement: UII-04
    verification:
      - kind: integration
        ref: test/threadline/operator_surface/transaction_live_test.exs#direct row-history connection failure offers retry and a safe Timeline return
        status: pass
      - kind: unit
        ref: mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/ui_test.exs
        status: pass
    human_judgment: false

# Metrics
duration: 29min
completed: 2026-10-10
status: complete
---

# Phase 240 Plan 01: Connected investigation and recovery Summary

**Timeline and transaction row-history journeys now preserve investigation context, while scoped failures recover honestly.**

## Performance

- **Duration:** 29 min
- **Started:** 2026-10-10T10:45:32Z
- **Completed:** 2026-10-10T11:14:17Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Timeline row-history links carry only the supported committed filters through the bounded `origin=timeline` marker; as-of changes retain that context, and closing reconstructs a local canonical Timeline URL.
- Transaction row history preserves the same transaction through as-of changes and return. An unavailable or missing transaction parent cannot render or query the child drawer.
- Direct database connection failures show a retryable unavailable state without leaking exception text or collapsing it into an empty result.
- Added mounted desktop/mobile journeys for Timeline and transaction entry, plus an actual Chromium 200% zoom check for row-history controls.

## Task Commits

1. **Tasks 1–3: Row-history context, parent gating, and recovery** - `7f2b4e04` (`feat`)
2. **Transaction-origin browser proof** - `7c448556` (`test`)

## Files Created/Modified

- `lib/threadline/operator_surface/live/timeline_live.ex` and `timeline_live/helpers.ex` - pass committed filters into safe row-history URLs.
- `lib/threadline/operator_surface/live/row_history_live.ex` - accept bounded origin state and reconstruct canonical return/history routes.
- `lib/threadline/operator_surface/live/row_history_component.ex` - preserve as-of context and render retryable connection failures.
- `lib/threadline/operator_surface/live/transaction_live.ex` - mount nested history only after the parent transaction loads.
- Row-history, Timeline, transaction and contract tests - cover canonical filtering, safe return, retry and parent gating.
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` - prove both origins at desktop/mobile and actual desktop 200% zoom.

## Decisions Made

- Use the existing `FilterParams` allowlist and canonical ordering for query state. Unknown origins and unsupported fields cannot influence return navigation.
- Catch only `DBConnection.ConnectionError` at the row-history read boundary; programmer errors and other evidence states remain distinguishable.
- Keep the transaction itself as the return destination for nested history, without deriving identity from actor data.

## Deviations from Plan

### Auto-fixed Issues

**1. Corrected nonexistent transaction-test paths in Phase 240 plans and validation mapping**
- **Found during:** Task 2 planning checks
- **Issue:** Plans 240-01 and 240-03 cited `test/threadline/operator_surface/live/transaction_live_test.exs`, which does not exist.
- **Fix:** Pointed the read list and commands to the actual `test/threadline/operator_surface/transaction_live_test.exs` file.
- **Verification:** The corrected command ran as part of the 199-test focused suite.
- **Committed in:** Plan metadata commit.

**2. Added the actual Timeline link caller to Plan 240-01's file inventory**
- **Found during:** Task 1 implementation
- **Issue:** Preserving committed filters required changing `TimelineLive`, which the plan omitted from `files_modified` and Task 1's file list.
- **Fix:** Updated the plan inventory and passed the current committed filter map through the safe route helper.
- **Verification:** Timeline LiveView assertions and the mounted browser journey passed.
- **Committed in:** Plan metadata commit.

**Total deviations:** 2 auto-fixed (verification-path correction and missing caller inventory).
**Impact on plan:** Both changes were required for accurate verification and the planned route behavior; scope stayed within UII-04.

## Issues Encountered

- The broader `operator-earned-flows.spec.ts` run timed out in its separate Evidence-to-Exports case; the paired mobile case was interrupted. The row-history-focused rerun passed all 7 selected desktop/mobile cases, with the actual 200% case passing on desktop and intentionally skipped on mobile.
- The initial commit attempt was blocked because the worktree's shared Git index is outside the writable workspace. The exact file-scoped GSD commit succeeded with sandbox escalation under the existing execution authorization.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 240-01 is ready for downstream saved-search and interaction work. Continue with the next incomplete Plan 240-02 task in Wave 2; retain the noted unrelated Evidence-to-Exports timeout for later classification if it recurs.

---
*Phase: 240-connected-investigation-and-recovery*
*Completed: 2026-10-10*
