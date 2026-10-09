---
phase: 239-investigation-entry-and-transaction-composition
plan: "04"
subsystem: operator-timeline
tags: [phoenix, liveview, timeline, browser, query-state]
requires:
  - phase: 239-01
    provides: accepted investigation entry and browser test setup
provides:
  - Truthful populated-to-pending-to-empty Timeline query identity
  - Separate retryable query error and filtered empty states
  - Apply progress feedback that survives the LiveView request
affects: [operator-timeline, phase-239-plan-05]
actuals:
  tokens: 4425
  tasks: 2
  commits: 4
  plan_head_before: a6a570e032cfac5662ec5490120a77f0364a788e
  plan_head_after: b940a131c62701e96263ca0cc6ecdb3888672dff
tech-stack:
  added: []
  patterns: [supervised parallel Timeline reads, explicit retryable query-error state]
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/timeline_live/filters.ex
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
key-decisions:
  - "Keep the previous result summary and rows paired while a replacement query is pending; publish the new identity only with its result."
  - "Treat a failed scoped read as a retryable error and retain the canonical applied query, without weakening host scope."
requirements-completed: [UII-02, UIA-04, UIS-02]
coverage:
  - id: D1
    description: Populated query A remains paired with its rows while query B is pending; completion replaces both with B and restores the Apply control.
    requirement: UII-02
    verification:
      - kind: automated_ui
        ref: "examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts#Timeline keeps populated query identity while an applied replacement is pending"
        status: pass
      - kind: integration
        ref: "mix verify.example_browser --project=desktop-chromium operator-route-states.spec.ts"
        status: pass
    human_judgment: false
  - id: D2
    description: Filtered empty results use the specified copy, while failed reads show a distinct retryable error and preserve the applied query in the retry link.
    requirement: UIA-04
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/live/timeline_live_test.exs#F-401: filtered empty state uses the canonical heading and body"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/live/timeline_live_test.exs#a scope query failure renders a retryable error instead of reading unscoped"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/operator_surface/live/timeline_live_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: A 232-character correlation value remains intact through the pending and completed populated-to-empty query transition.
    requirement: UIS-02
    verification:
      - kind: automated_ui
        ref: "examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts#Timeline keeps populated query identity while an applied replacement is pending"
        status: pass
    human_judgment: false
duration: not-recorded
completed: 2026-10-09
status: complete
---

# Phase 239 Plan 04: Investigation Entry and Transaction Composition Summary

**Timeline keeps populated rows paired with their applied query through pending replacement, then distinguishes filtered empty results from retryable read errors.**

## Performance

- **Duration:** Not recorded in the inherited executor context.
- **Started:** Not captured; no timestamp is inferred from a later artifact.
- **Completed:** 2026-10-09T14:01:04Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added a real-browser regression that holds the LiveView request after populated query A, confirms A remains paired with its rows while B is pending, then confirms B's filtered-empty result and restored Apply control.
- Added Apply progress feedback and distinct filtered-empty and retryable query-error states. Failed reads clear stale rows and retain the canonical applied query for retry.
- Added LiveView coverage for filtered-empty copy and the fail-closed scoped-read error state.

## Task Commits

1. **Task 1: Apply B while populated A is held in view, then complete B** — `f4c7e65a` (test)
2. **Task 1: Apply progress feedback** — `d1ae5d29` (feat)
3. **Task 2: Recover accurately from empty, failed and denied queries** — `e945f196` (test)
4. **Task 2: Preserve Timeline query result states** — `b940a131` (feat)

## Files Created/Modified

- `lib/threadline/operator_surface/live/timeline_live.ex` — Keeps query errors separate from empty results; supervised parallel reads return a safe error state without stale rows and preserve the applied query for retry.
- `lib/threadline/operator_surface/live/timeline_live/filters.ex` — Shows “Applying filters…” while the LiveView request is pending.
- `test/threadline/operator_surface/live/timeline_live_test.exs` — Covers canonical filtered-empty copy and retryable failure behavior.
- `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` — Holds a populated-to-empty replacement request and checks query identity, pending feedback, long value retention, and restored Apply control.

## Decisions Made

- Pending query B does not relabel query A's still-visible rows; B becomes the displayed identity only after its result arrives.
- Read failures are shown as errors, not empty results. Retry uses the same canonical query and existing server-owned scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Use the application task supervisor for failure-isolated reads**
- **Found during:** Task 2
- **Issue:** `Task.async_nolink/1` is unavailable on the project's Elixir 1.17.3 runtime, so the initial ExUnit run could not exercise the error path.
- **Fix:** Used the existing `Threadline.Export.TaskSupervisor` for both parallel query tasks, then handled task exits/timeouts as the retryable error state.
- **Files modified:** `lib/threadline/operator_surface/live/timeline_live.ex`
- **Verification:** The focused LiveView suite passed 57/57 after the change.
- **Committed in:** `b940a131`

**Total deviations:** 1 auto-fixed (1 blocking runtime compatibility issue). **Impact:** Preserved the planned supervised parallel query behavior without adding a dependency or changing the public API.

## Issues Encountered

- The initial ExUnit run exposed the unsupported task function and an inaccurate test label that implied an unscoped route was scoped. Both were corrected before completion.
- Existing evidence-only browser cases remained skipped in the normal focused run; the required populated-query browser regression ran and passed. The 232-character layout/overflow gate remains with Plan 05 as specified.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Timeline query identity and error recovery are ready for Plan 05's separate long-value layout and overflow work.
- Existing authorization behavior remains server-owned; the query retry path does not remove or broaden scope.

## Checks Run

- Focused LiveView suite: **57/57 passed** (`mix test test/threadline/operator_surface/live/timeline_live_test.exs`).
- Focused Chromium spec: **1/1 executed scenario passed**; 11 evidence-only scenarios were skipped by the suite gate. The populated query identity test ran on a fresh partition and unique port. Playwright 1.60.0 matched the installed Chromium revision.
- Evaluation scope: resolved; 4 task commits found for `239-04` on this branch.
- Actuals: 17,701 changed-diff bytes / 4 = 4,425 tokens; 2 tasks; 4 task commits.

## Self-Check: PASSED

- All four plan-owned source/test files exist and are included in the four task commits.
- The task commits are ancestors of the current branch HEAD.
- No phase tracker or parent-owned planning files are included in this plan summary commit.

---
*Phase: 239-investigation-entry-and-transaction-composition*
*Completed: 2026-10-09*
