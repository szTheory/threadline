---
phase: 239-investigation-entry-and-transaction-composition
plan: "01"
subsystem: operator-ui
tags: [phoenix-liveview, playwright, timeline, investigation]
requires: []
provides:
  - A truthful Home-to-Timeline-to-transaction browser journey
  - Home lookup validation that retains entered values and reports unavailable health honestly
  - Regression evidence for applied filters, cursor resets, and server-owned tenant scope
affects: [239-02, operator-surface, timeline]
actuals:
  tokens: 6167
  tasks: 3
  commits: 5
plan_head_before: 43c5bcfa960b1a10cb07ef997e2231e9615dca6f
plan_head_after: a3c218fd927899cf5d0f38534acd670320370a34
tech-stack:
  added: []
  patterns:
    - Mounted Playwright journey proves the operator path through real rendered LiveViews.
    - Enabled health reads distinguish unavailable data from a healthy result.
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/start_live.ex
    - test/threadline/operator_surface/live/start_live_test.exs
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts
key-decisions:
  - "Use the approved Home copy to say recorded actions and context may be absent."
  - "Keep form input verbatim for correction while validating normalized values for navigation."
  - "Report enabled health-source failures as unavailable, never as all systems healthy."
  - "Keep Timeline results tied to applied allowlisted URL filters and server-owned scope."
requirements-completed: [UIS-02, UII-01, UII-02, UII-03, UIA-04]
coverage:
  - id: D1
    description: Home entry applies a Timeline filter, survives reload, and opens its transaction with a distinct row change.
    requirement: UII-01
    verification:
      - kind: e2e
        ref: "operator-timeline-investigation-flow.spec.ts#starts at Home, applies a Timeline query, and opens its transaction"
        status: pass
    human_judgment: false
  - id: D2
    description: Home lookup errors retain the submitted values, and failed enabled health sources render unavailable status.
    requirement: UIA-04
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/live/start_live_test.exs#reports health as unavailable when enabled health sources fail"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/live/start_live_test.exs#record-first lookup validates blank and unmapped input without navigating"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/live/start_live_test.exs#correlation shortcut validates blank and overlong ids without navigating"
        status: pass
    human_judgment: false
  - id: D3
    description: Draft filters do not change applied results; Apply, history, paging, and forged URL scope input preserve query and tenant boundaries.
    requirement: UII-03
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/live/timeline_live_test.exs#a changed applied query resets streamed rows and the older-page cursor"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/live/timeline_live_test.exs#forged URL scope parameters cannot widen the server-owned tenant scope"
        status: pass
      - kind: e2e
        ref: "operator-timeline-investigation-flow.spec.ts#keeps draft edits unapplied and drops unsupported URL parameters"
        status: pass
    human_judgment: false
duration: 31min
completed: 2026-10-09
status: complete
---

# Phase 239 Plan 01: Investigation entry and transaction composition Summary

**Truthful Home copy, retained lookup corrections, honest health status, and a verified Home-to-transaction investigation path**

## Performance

- **Duration:** 31 min
- **Started:** 2026-10-09T12:30:00Z
- **Completed:** 2026-10-09T13:01:08Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added a mounted Chromium journey from Home through an explicitly applied, reloadable Timeline query to a transaction and its distinct `INSERT` change.
- Updated Home language so it does not claim every change has an action or context; validation preserves submitted record and correlation values, and enabled health-source failures render as unavailable.
- Added LiveView and browser regression coverage for unchanged results before Apply, query history, cursor reset, unsupported parameters, and server-owned scope.

## Task Commits

1. **Task 1: Home-to-transaction browser tracer RED** - `ebc0a329` (`test`)
2. **Task 1: Truthful Home entry and browser tracer GREEN** - `8cf4a8b6` (`feat`)
3. **Task 2: Home validation and unavailable-health tests** - `0153fdf4` (`test`)
4. **Task 2: Preserve Home input and health truth** - `b344dc07` (`feat`)
5. **Task 3: Applied-query and scope regression coverage** - `a3c218fd` (`test`)

## Files Created/Modified

- `lib/threadline/operator_surface/live/start_live.ex` - truthful Home copy, retained validation values, explicit unavailable health state.
- `test/threadline/operator_surface/live/start_live_test.exs` - copy, validation, and failing-health-repository coverage.
- `test/threadline/operator_surface/live/timeline_live_test.exs` - result/cursor reset and server-owned scope coverage.
- `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts` - Home journey and unapplied-draft/unsupported-parameter browser assertions.

## Decisions Made

- Kept the existing routes, controls, validation boundary, and query allowlist.
- Retained raw form values for visible correction while continuing to validate trimmed values.
- Kept Timeline query and tenant scope server-owned; URL input cannot widen authorization.
- Added no dependencies or public routes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reused the matching cached Chromium binary after the runner's browser install stalled**
- **Found during:** Task 1
- **Issue:** The canonical browser runner stalled while requesting a redundant Chromium install, despite Playwright 1.60's Chromium revision 1223 already being cached.
- **Fix:** Used a temporary `/private/tmp` npx shim that skips only `playwright install chromium`; all other runner commands remained unchanged. The scoped canonical browser command then completed successfully.
- **Files modified:** None in the repository.
- **Verification:** `mix verify.example_browser --project=desktop-chromium operator-timeline-investigation-flow.spec.ts` passed with 11 discovered browser tests.
- **Committed in:** Not applicable; the shim is outside the repository.

**Total deviations:** 1 auto-fixed (1 blocking environment issue). **Impact:** No project dependency, source, or configuration changes were added for the workaround.

## Issues Encountered

- The seeded browser record fell outside the default 24-hour filter window; the journey now selects a deterministic 2020–2099 window before applying its filters.
- The browser empty-state assertion was aligned with the UI's existing “No captured changes match this window” wording.
- The tenant-scope negative control distinguishes rows by visible operation and asserts only the authorized row renders.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 239-02. The Home entry path and existing applied-query behavior now have mounted browser and LiveView evidence.

## Verification Results

- `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs` — 79 tests, 0 failures.
- `mix verify.example_browser --project=desktop-chromium operator-timeline-investigation-flow.spec.ts` — 11 browser tests passed; the command also discovered and passed 21 Node unit tests.
- `mix format --check-formatted` on the changed Elixir source and tests — passed.
- `git diff --check` — passed.
- `gsd_run check evaluation-scope --plan "239-01" --commits-only --raw` — resolved 5 plan commits on this branch.

## Self-Check: PASSED

- All four modified source/test files and this summary exist.
- All five task commits are ancestors of the current worktree HEAD.
- Coverage classification reports 3 deliverables, all automatically covered, with no schema errors.
- The final combined Home/Timeline suite passed 79 tests; the mounted Chromium suite passed 11 tests.

---
*Phase: 239-investigation-entry-and-transaction-composition*
*Completed: 2026-10-09*
