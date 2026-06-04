---
phase: 137-prove-cluster-polish
plan: 02
subsystem: ui
tags: [operator-surface, exports, readiness, liveview]
requires:
  - phase: 137-prove-cluster-polish
    provides: Plan 01 shared readiness and ref primitives
provides:
  - Readiness-grouped export monitor
  - Ready-only primary download affordance
  - Failed export recovery copy and inset alert
affects: [exports, timeline-handoff, prove-cluster]
tech-stack:
  added: []
  patterns: [assigned grouped LiveView lists, shared presentation readiness]
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/export_status_live.ex
    - test/threadline/operator_surface/live/export_status_live_test.exs
key-decisions:
  - "Exports uses assigned grouped lists instead of streams so readiness sections can render in fixed operator order."
  - "Only Presentation.export_downloadable?/2 gates the primary Download export action."
patterns-established:
  - "Exports groups by Presentation.export_readiness/2 and sorts ready/preparing/needs-attention/unavailable."
  - "Actor refs and query values use Presentation.secondary_ref/2 with .tl-secondary-ref."
requirements-completed: [POLISH-PROVE]
duration: 4min
completed: 2026-06-04
---

# Phase 137: Plan 02 Summary

**Exports now renders as a readiness-first handoff monitor with explicit non-ready states and secondary recovery.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-04T07:32:18Z
- **Completed:** 2026-06-04T07:36:15Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Replaced flat streamed export rendering with readiness-grouped assigned lists.
- Changed the page title and empty copy to the locked handoff-monitor language.
- Reserved the primary button for `Download export`; preparing, failed, expired, and missing-file jobs render explicit state labels.
- Added failed export recovery copy with an inset `.tl-alert--error` and `Reopen source search`.

## Task Commits

1. **Task 1: Rebuild Exports around readiness groups and a single ready signal** - `8e839d4` (feat)

## Files Created/Modified

- `lib/threadline/operator_surface/live/export_status_live.ex` - Readiness grouping, ready-only action, secondary refs, failed alert.
- `test/threadline/operator_surface/live/export_status_live_test.exs` - Contract coverage for title, empty state, groups, action labels, and ref metadata.

## Decisions Made

Used assigned grouped lists instead of `phx-update="stream"` because the required fixed readiness sections are the primary interaction model.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/threadline/operator_surface/live/export_status_live_test.exs` - 10 tests, 0 failures
- `rg -n "What's ready to hand off\\?|Ready to hand off|Preparing|Needs attention|Unavailable|Download export|Reopen source search" lib/threadline/operator_surface/live/export_status_live.ex` - static copy/action labels present; readiness headings covered through rendered helper tests

## Self-Check: PASSED

- Key files exist on disk.
- Commit `8e839d4` contains the implementation and tests.
- No new routes, export creation flows, actor scoping changes, or export persistence semantics were introduced.

## Next Phase Readiness

Exports is complete for Phase 137 and can be included in the final Prove-cluster verification sweep.

---
*Phase: 137-prove-cluster-polish*
*Completed: 2026-06-04*
