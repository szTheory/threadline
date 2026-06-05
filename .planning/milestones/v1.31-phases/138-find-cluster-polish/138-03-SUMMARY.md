---
phase: 138-find-cluster-polish
plan: "03"
subsystem: operator-surface-ui
tags: [operator-surface, timeline, liveview, playwright, mobile, find-cluster]

requires:
  - phase: 138-find-cluster-polish
    provides: shared Find presentation helpers and CSS primitives from plan 01
provides:
  - Dense-first Timeline result context with active filter summary above rows
  - Demoted non-clickable Timeline journey legend after result rows
  - Locked Timeline empty, future-window, invalid-filter, anonymous-actor, and long-ref behavior
  - Find mobile Playwright UAT for Timeline row-first pressure at 375px
affects: [timeline, find-cluster, example-browser-uat]

tech-stack:
  added: []
  patterns: [LiveView URL-state preservation, scoped count queries, mobile Playwright UAT]

key-files:
  created:
    - examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts
    - .planning/phases/138-find-cluster-polish/138-03-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - test/threadline/operator_surface/live/timeline_live_test.exs

key-decisions:
  - "Timeline keeps the existing orientation header, but the FIND / EXPLAIN / PACKAGE strip is now a non-clickable legend after rows."
  - "Timeline match counts now use the same scope-aware options as row queries so displayed totals match authorized result sets."
  - "The Find mobile spec is introduced as the Timeline slice only; later plan 04 can extend it for remaining Find screens."

patterns-established:
  - "Timeline long table and correlation refs use Presentation.secondary_ref/2 with full title metadata."
  - "Future-window empty copy is gated by a scoped outside-window count with from/to removed from validated filters."
  - "Find mobile UAT compares row and legend bounding boxes and checks horizontal overflow."

requirements-completed: [POLISH-FIND]

duration: 8min
completed: 2026-06-04
---

# Phase 138 Plan 03: Timeline Find Polish Summary

**Timeline now prioritizes active filters and matching rows, with precise recovery states, scoped counts, long-ref verification affordances, and mobile UAT coverage.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-04T09:01:23Z
- **Completed:** 2026-06-04T09:09:19Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added F-401 through F-405 Timeline LiveView coverage for empty copy, future-window copy, invalid-filter copy, anonymous actor hints, long refs, and dense row-first DOM order.
- Updated Timeline to render `.tl-filter-summary`, middle-truncated table/correlation refs, full `title` metadata, correlation copy controls, and a demoted `.tl-journey--legend` after rows.
- Added `operator-find-mobile.spec.ts` proving the 375px Timeline path keeps filters and rows above the inert journey legend with no horizontal overflow.

## Task Commits

1. **Task 1 RED: Add failing Timeline polish coverage** - `9047105` (test)
2. **Task 1 GREEN: Polish Timeline dense and recovery states** - `3e8eca6` (feat)
3. **Task 2: Add Find mobile Timeline UAT** - `8e722c1` (test)

## Files Created/Modified

- `lib/threadline/operator_surface/live/timeline_live.ex` - Reordered Timeline result context, added locked copy states, long-ref rendering, and scoped count options.
- `test/threadline/operator_surface/live/timeline_live_test.exs` - Added F-401 through F-405 LiveView coverage and test fixtures for long correlation IDs.
- `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` - Added Timeline dense/mobile Playwright UAT.
- `.planning/phases/138-find-cluster-polish/138-03-SUMMARY.md` - Captures execution results.

## Decisions Made

Timeline's orientation header remains, but the journey strip no longer sits before the rows or looks like cards. The strip is plain legend text with no links or buttons, avoiding a false Phase 140 export-loop implication.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Scoped Timeline match counts**
- **Found during:** Task 1
- **Issue:** The existing Timeline row query used `scope_aware_opts/1`, but the visible match count used only `repo`, which could drift from authorized row visibility.
- **Fix:** Routed Timeline match counts through `count_opts/2`, derived from `scope_aware_opts/1`; the new future-window outside count uses the same path.
- **Files modified:** `lib/threadline/operator_surface/live/timeline_live.ex`
- **Verification:** `rg` confirmed `Export.count_matching/2` calls use `count_opts/2`; focused Timeline tests pass.
- **Committed in:** `3e8eca6`

---

**Total deviations:** 1 auto-fixed (Rule 2).
**Impact on plan:** Narrow correctness/security alignment with the plan threat model; no new routes, schemas, packages, or product behavior.

## Issues Encountered

- `mix verify.example_browser` completed with the new Find mobile spec passing in all configured Playwright projects, but the full command failed 9 existing/unowned assertions:
  - Row-history/transaction screenshot specs now see duplicate `[REDACTED]` values from concurrent 138-02 value rendering.
  - Existing screenshot specs still expected the old Timeline empty heading `No changes match`, while this plan intentionally changed it to the locked `No captured changes match this window`.
- These failures are outside this plan's ownership files and were not changed here.

## Known Stubs

None. Stub scan found only existing form empty-value/control patterns and the saved-view placeholder, not new unbacked UI data.

## Threat Flags

None - no new endpoint, auth path, file access, schema change, or network surface was introduced.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/threadline/operator_surface/live/timeline_live_test.exs` - 32 tests, 0 failures
- `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/presentation_test.exs` - 46 tests, 0 failures
- `mix verify.example_browser` - 45 passed / 9 failed; `operator-find-mobile.spec.ts` passed in chromium, desktop-chromium, and mobile-chromium
- Source acceptance checks:
  - `rg` confirmed `.tl-filter-summary`, `.tl-journey--legend`, `data-testid="timeline-row"`, locked copy, `Presentation.secondary_ref/2`, `FilterParams.parse`, and `scope_aware_opts/1` references.
  - `rg` confirmed no `tl-journey-step` or `tl-journey-rail` remains in Timeline markup.

## TDD Gate Compliance

- RED test commit exists before implementation: `9047105`
- GREEN implementation commit follows it: `3e8eca6`
- Task 2 is a browser-spec-only task and was committed as test coverage: `8e722c1`

## Next Phase Readiness

Plan 04 can extend `operator-find-mobile.spec.ts` with Transaction, Row-history, Actor, and Coverage assertions after those slices land. Orchestrator-owned `.planning/STATE.md` and `.planning/ROADMAP.md` updates were intentionally skipped per executor prompt.

## Self-Check: PASSED

- Key files exist on disk.
- Commits `9047105`, `3e8eca6`, and `8e722c1` exist in git history.
- Focused ExUnit verification is green.
- Broader browser verification caveat is documented above.

---
*Phase: 138-find-cluster-polish*
*Completed: 2026-06-04*
