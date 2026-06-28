---
phase: 183-shell-navigation-and-home-orientation
plan: 01
subsystem: testing
tags: [playwright, phoenix-example, operator-shell, home-orientation, accessibility]

requires:
  - phase: 181-baseline-audit-and-guard-repair
    provides: "Current operator UI baseline and bounded browser evidence posture"
  - phase: 182-phoenixstorybook-example-dev-lane
    provides: "Example-app Playwright lane and light/system project boundary"
provides:
  - "Narrow Phase 183 browser perception supplement for shell navigation and Home orientation"
  - "System/light lane inclusion for the Phase 183 shell/Home browser supplement"
  - "Actionable RED evidence for Plan 02 shell/Home retuning"
affects: [phase-183, shell-navigation, home-orientation, example-browser]

tech-stack:
  added: []
  patterns:
    - "Self-contained Playwright semantic supplement with no screenshot baselines"
    - "Existing desktop-chromium-light lane reuse under THREADLINE_E2E_THEME=system"

key-files:
  created:
    - examples/threadline_phoenix/e2e/tests/operator-shell-home-phase183.spec.ts
  modified:
    - examples/threadline_phoenix/e2e/playwright.config.ts

key-decisions:
  - "Plan 01 remains RED/proof-only: browser failures are actionable Plan 02 evidence, not production retuning scope."
  - "The Phase 183 supplement is admitted to the existing system/light lane rather than adding a new Playwright project or screenshot matrix."

patterns-established:
  - "Phase-specific browser perception specs should assert semantic shell/Home contracts directly and leave page-content polish to owning phases."

requirements-completed:
  - SHELL-01
  - SHELL-02
  - SHELL-03

duration: 15 min
completed: 2026-06-28
status: complete
---

# Phase 183 Plan 01: Browser Perception Proof Summary

**Phase 183 shell/Home perception proof with strict breakpoint, theme, active-state, focus, overflow, and launcher assertions wired into dark and system/light browser lanes.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-06-28T17:07:00Z
- **Completed:** 2026-06-28T17:21:50Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `operator-shell-home-phase183.spec.ts` as the Wave 0 browser supplement for 320, 375, 768, 1024, 1280, and 1440px shell/Home perception cells.
- Covered native mobile disclosure keyboard/pointer behavior, desktop rail visibility, active nav non-color cues, selected theme radios, Home hierarchy, launcher validation, route transitions, adjacent shell invariants, focus visibility, and overflow.
- Included the supplement in `desktop-chromium-light` under the existing `THREADLINE_E2E_THEME=system` guard without adding screenshots, projects, dependencies, routes, or production code.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Phase 183 shell/Home browser supplement** - `bba62f29` (test)
2. **Task 2: Include the supplement in the light/system browser lane** - `93f74b84` (test)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/tests/operator-shell-home-phase183.spec.ts` - New semantic Playwright proof for Phase 183 shell/Home perception.
- `examples/threadline_phoenix/e2e/playwright.config.ts` - Adds the new spec to the existing gated `desktop-chromium-light` lane.

## Verification

- `cd examples/threadline_phoenix/e2e && npx playwright test --list tests/operator-shell-home-phase183.spec.ts` - **PASS**, 27 tests listed across existing dark projects.
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-shell-home-phase183.spec.ts` - **ACTIONABLE RED**, 9 passed / 18 failed. Mobile 320/375 and primary Home route transitions passed. Desktop/tablet cells failed because `.tl-shell-nav__toggle` is hidden at 768px+ while `.tl-shell-nav__panel` remains hidden inside a closed native `<details>`, making active nav links hidden too.
- `cd examples/threadline_phoenix/e2e && THREADLINE_E2E_THEME=system npx playwright test --list tests/operator-shell-home-phase183.spec.ts --project=desktop-chromium-light` - **PASS**, 9 tests listed under `desktop-chromium-light`.
- `mix verify.example_browser_light tests/operator-shell-home-phase183.spec.ts` - **ACTIONABLE RED**, 1 passed / 8 failed. The 320/375 cells rendered `.threadline-ui[data-tl-theme="dark"]` instead of expected `system`; 768px+ repeated the hidden desktop rail panel failure.
- `cd examples/threadline_phoenix && MIX_ENV=test mix precommit` - **INHERITED RESIDUAL**, 109 tests / 7 failures in demo-seed and walkthrough contracts (`ticket_replies`/`tickets` seeded audit rows and actor attribution). No failure references the new Phase 183 Playwright spec or config.

## Decisions Made

- Kept Plan 01 as test-only RED proof because the plan explicitly allows browser failures as actionable evidence for Plan 02 and forbids implementation retuning beyond proof wiring.
- Reused the existing light/system Playwright project instead of creating another browser lane.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The targeted browser commands produced planned actionable failures:
  - Desktop/tablet rail: `.tl-shell-nav__panel` remains hidden when `<details>` is closed at 768px+ even though the summary toggle is hidden.
  - System/light theme: the targeted light command rendered `data-tl-theme="dark"` for the new spec where the proof expects `system`.
- Example-app `mix precommit` still fails inherited demo-seed/walkthrough contracts unrelated to Plan 183-01.

## Known Stubs

None found in files created or modified by this plan.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 183-02. Plan 02 has concrete browser evidence for the desktop/tablet rail visibility bug, active nav hidden state, and system/light selected-theme mismatch, while mobile 320/375 disclosure behavior and primary Home route transitions already have green proof.

## Self-Check: PASSED

- Summary exists at `.planning/phases/183-shell-navigation-and-home-orientation/183-01-SUMMARY.md`.
- Key files exist: `operator-shell-home-phase183.spec.ts` and `playwright.config.ts`.
- Task commits are reachable: `bba62f29` and `93f74b84`.

---
*Phase: 183-shell-navigation-and-home-orientation*
*Completed: 2026-06-28*
