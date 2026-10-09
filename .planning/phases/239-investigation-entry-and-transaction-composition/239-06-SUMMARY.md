---
phase: 239-investigation-entry-and-transaction-composition
plan: "06"
subsystem: operator-surface
tags: [elixir, phoenix, liveview, playwright, accessibility, theme, overlay]
requires:
  - phase: 239-01
    provides: browser harness and operator-surface baseline
provides:
  - Browser and LiveView proof for the session-backed System theme preference
  - Overlay toast focus restoration and full-viewport scrim dismissal behavior
affects: [239-07, operator-surface, accessibility]
actuals:
  tokens: 2810
  tasks: 1
  commits: 2
  plan_head_before: 9433cf5fa407afea382ad2adb514836216a02fa0
  plan_head_after: b222f86efdbfe2a50289ce319dc514c19c7a4f7a
tech-stack:
  added: []
  patterns:
    - Session-backed theme choice remains separate from OS-derived effective colors
    - Full-viewport scrims provide outside dismissal without lower-layer click-away
key-files:
  created:
    - .planning/phases/239-investigation-entry-and-transaction-composition/239-06-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/ui/overlay.ex
    - test/threadline/operator_surface/live/start_live_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts
key-decisions:
  - "Keep Light/Dark/System in the existing server session; computed appearance follows OS emulation only while System is selected."
  - "Use the full-screen modal/drawer scrim for outside dismissal so toast input cannot dismiss an underlying layer."
requirements-completed: []
coverage:
  - id: D1
    description: Session theme choice stays selected while effective colors follow OS appearance across navigation and reload.
    requirement: UIA-02
    verification:
      - kind: integration
        ref: test/threadline/operator_surface/live/start_live_test.exs#invalid theme submission retains System
        status: pass
      - kind: e2e
        ref: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts#keeps System selection while served colors follow OS through investigation navigation
        status: pass
    human_judgment: false
  - id: D2
    description: Shared overlays preserve toast/drawer focus and remain readable at a short, narrow viewport.
    requirement: UIA-03
    verification:
      - kind: e2e
        ref: mix verify.example_browser --project=desktop-chromium operator-accessibility.spec.ts operator-component-contracts.spec.ts (19/19 passed)
        status: pass
      - kind: e2e
        ref: focused stress-drawer Escape regression (drawer remained visible after Escape)
        status: fail
    human_judgment: true
    rationale: Drawer Escape dismissal remains unproven, and the stress-story selector uses full-page navigation instead of a LiveView patch.

status: halted
duration: not recorded
completed: 2026-10-09
---

# Phase 239 Plan 06: Investigation Entry and Transaction Composition Summary

**System theme appearance is verified in Chromium, and overlay pointer dismissal now preserves the drawer under a toast; drawer Escape and patch acceptance remain unresolved.**

## Performance

- **Duration:** Not recorded at executor start; not inferred from other artifacts.
- **Started:** Not recorded.
- **Completed:** 2026-10-09T14:56:34Z
- **Tasks:** Task 1 complete; Task 2 partially implemented, acceptance incomplete.
- **Files modified:** 4 source/test files, plus this summary.

## Accomplishments

- Verified System remains the selected session preference while emulated OS appearance changes the rendered background, foreground, and border colors through Home, Timeline, transaction navigation, and reload.
- Added a LiveView invalid-theme submission assertion that checks the canonical redirect and confirms no saved theme cookie or false success state.
- Removed modal/drawer global click-away handlers; their full-viewport scrims retain outside dismissal while preventing a toast click from dismissing the drawer behind it.
- Added toast/drawer focus-return and short-viewport long-content browser coverage. The full accessibility/component browser suite passed 19/19 tests.

## Task Commits

1. **Task 1: Keep chosen System preference while OS appearance changes across the journey** — `76d955f8` (`test(239-06): verify session theme follows system appearance`)
2. **Task 2: Dismiss overlapping toast, menu and drawer with deterministic focus return** — `b222f86e` (`fix(239-06): keep overlay clicks and focus scoped`); partial, with the open acceptance items below.

## Files Created/Modified

- `test/threadline/operator_surface/live/start_live_test.exs` — invalid preference submission stays on System and does not set a preference cookie.
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` — System color-scheme journey and toast/drawer focus behavior.
- `examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts` — long toast/drawer content at a 320×420 viewport.
- `lib/threadline/operator_surface/ui/overlay.ex` — scrim-based modal/drawer outside dismissal and toast-close focus restoration.

## Decisions Made

- Kept the existing session-backed theme controller as the only preference source; no client preference store was introduced.
- Kept outside dismissal on the full-viewport scrim. LiveView dispatches click-away globally, which allowed a toast click to reach and dismiss the drawer beneath it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prevented toast pointer input from dismissing the underlying dialog.**
- **Found during:** Task 2.
- **Issue:** A toast close click also triggered the drawer/modal `phx-click-away` handler through LiveView's global dispatch.
- **Fix:** Removed those click-away handlers and retained dismissal on each full-viewport scrim. Toast close now restores focus to the visible dialog control.
- **Files modified:** `lib/threadline/operator_surface/ui/overlay.ex`, `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts`, `examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts`.
- **Verification:** Full browser suite 19/19 passed; component contract suite 25/25 passed.
- **Committed in:** `b222f86e`.

**Total deviations:** 1 auto-fixed (Rule 1 - Bug). **Impact:** The observed pointer/focus issue is fixed; the plan remains halted because other Task 2 acceptance evidence is incomplete.

## Issues Encountered

- A focused browser probe left the stress drawer visible after Escape, despite the existing `phx-window-keydown` binding. This criterion is not counted as passed.
- The stress fixture's story list uses ordinary `href` navigation, not a LiveView patch. A DOM marker negative control confirmed the navigation replaced the document, so that fixture cannot prove patch lifetime.
- `UIA-02` remains explicitly unclassified in `239-EDGE-PROBE.json`; this plan did not classify that probe row.

## Checks Run

- `mix test test/threadline/operator_surface/live/start_live_test.exs` — 23/23 passed.
- `mix test test/threadline/operator_surface/component_contract_test.exs` — 25/25 passed.
- `mix verify.example_browser --project=desktop-chromium operator-accessibility.spec.ts operator-component-contracts.spec.ts` — 19/19 passed; 21/21 runner unit checks passed.
- `mix verify.example_browser_light --project=desktop-chromium-light operator-accessibility.spec.ts` — 12/12 passed; 21/21 runner unit checks passed.
- `mix format --check-formatted` — passed (exit 0).

## User Setup Required

None.

## Next Phase Readiness

Halted. Resolve and test drawer Escape dismissal, obtain genuine repeated LiveView-patch evidence, and let the parent classify the open UIA-02 probe before advancing the phase.

## Self-Check: FAILED

- Task 1 acceptance passed.
- Task 2 still lacks passing proof for drawer Escape and repeated LiveView patches; do not mark this plan complete or advance the phase from this summary.

---
*Phase: 239-investigation-entry-and-transaction-composition*
*Completed: 2026-10-09*
