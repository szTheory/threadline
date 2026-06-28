---
phase: 183-shell-navigation-and-home-orientation
plan: "02"
subsystem: ui
tags: [phoenix-liveview, operator-surface, shell-navigation, home-orientation, playwright]

requires:
  - phase: 183-shell-navigation-and-home-orientation
    provides: [Phase 183 browser perception RED evidence]
provides:
  - Phase 183 source contracts for shell/Home behavior
  - Browser-passing native mobile disclosure and desktop rail shell
  - Reliable dark and system/light e2e theme lane verification
affects: [operator-surface, threadline-phoenix-example, browser-e2e]

tech-stack:
  added: []
  patterns:
    - Native mobile details toggle controls a sibling nav panel so desktop rail is not trapped by closed details semantics.
    - Example e2e runner force-compiles compile-time theme gates before browser verification.

key-files:
  created: []
  modified:
    - test/threadline/operator_surface/surface_header_test.exs
    - test/threadline/operator_surface/live/start_live_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
    - test/threadline/operator_surface/copy_contract_test.exs
    - test/threadline/operator_surface/router_test.exs
    - lib/threadline/operator_surface/components/surface_header.ex
    - lib/threadline/operator_surface/style.ex
    - examples/threadline_phoenix/e2e/tests/operator-shell-home-phase183.spec.ts
    - examples/threadline_phoenix/e2e/run-e2e.sh

key-decisions:
  - "Kept the mobile nav as a native details/summary control, but moved the single nav panel to a sibling so desktop CSS can show it without overriding closed-details internals."
  - "Scoped adjacent-route browser heading assertions to the page H1 inside #tl-main, preserving shell invariant checks without hardcoding the Home H1 on every route."
  - "Forced example e2e compilation so compile-time THREADLINE_E2E_THEME router gates reflect each dark or system/light invocation."

patterns-established:
  - "Source style contracts should assert the actual responsive selector relationship, not only the visual intent."
  - "Browser specs that share shell helpers across routes must parameterize route-specific page content."

requirements-completed: [SHELL-01, SHELL-02, SHELL-03]

duration: 68m
completed: 2026-06-28
status: complete
---

# Phase 183 Plan 02: Source Contracts and Shell/Home Retune Summary

**Native mobile disclosure with a desktop-visible shell rail, locked by source contracts and passing dark plus system/light browser proof.**

## Performance

- **Duration:** 68m
- **Started:** 2026-06-28T17:27:28Z
- **Completed:** 2026-06-28T18:35:32Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Tightened source contracts for the Phase 183 shell/Home scope: native nav disclosure, desktop rail layout, Home copy/hierarchy, theme POST route, active nav cues, and removal of readiness/evidence groups when disabled.
- Retuned the shell nav so one sibling panel is hidden by default on mobile, opened by native `<details>`, and always visible as a desktop rail at 768px and above.
- Updated the Phase 183 browser proof to validate adjacent route page headings correctly while preserving shell, active-state, theme, focus, and overflow invariants.
- Fixed the example e2e runner so dark and system/light theme lanes force a fresh router compile before browser tests.

## Task Commits

1. **Task 1: Tighten shell/Home source contracts** - `12e69800` (test)
2. **Task 2: Retune shell/Home implementation and browser proof** - `aeb93242` (fix)

## Files Created/Modified

- `test/threadline/operator_surface/surface_header_test.exs` - Locked native disclosure markup, theme form, enabled/disabled nav group contracts, and stable header affordances.
- `test/threadline/operator_surface/live/start_live_test.exs` - Locked Home H1/lede, system health status, card order, launcher validation, and old copy removal.
- `test/threadline/operator_surface/style_contract_test.exs` - Locked mobile sibling-panel disclosure behavior, desktop rail visibility, min-width constraints, and active nav cues.
- `test/threadline/operator_surface/copy_contract_test.exs` - Locked exact Theme legend copy.
- `test/threadline/operator_surface/router_test.exs` - Locked the POST `/threadline/theme` route contract.
- `lib/threadline/operator_surface/components/surface_header.ex` - Moved the single nav panel outside the closed native disclosure while preserving one panel ID and the mobile summary control.
- `lib/threadline/operator_surface/style.ex` - Switched mobile open behavior to `.tl-shell-nav__disclosure[open] + .tl-shell-nav__panel` and kept the desktop rail visible through the normal panel rule.
- `examples/threadline_phoenix/e2e/tests/operator-shell-home-phase183.spec.ts` - Parameterized adjacent-route headings and scoped heading assertions to the page H1 inside `#tl-main`.
- `examples/threadline_phoenix/e2e/run-e2e.sh` - Changed the compile step to `mix compile --force` so the compile-time theme lane follows the current invocation.

## Decisions Made

- Kept a single rendered nav panel instead of duplicating mobile and desktop nav markup; this avoids Playwright strict-locator ambiguity and preserves one source of truth for nav links and theme controls.
- Used a sibling panel selector for mobile disclosure state because Chromium still treats non-summary descendants of closed `<details>` as hidden even when later CSS attempts to display them.
- Treated the example e2e runner stale-compile behavior as a blocking verification issue, because the system/light lane could not prove the `data-tl-theme="system"` branch without a forced compile.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Browser spec bug] Fixed adjacent-route heading assertion**
- **Found during:** Task 2
- **Issue:** The Phase 183 browser helper asserted the Home H1 (`Follow what happened.`) on every adjacent route, producing false failures after the desktop rail became visible.
- **Fix:** Added per-route expected headings and scoped the shared helper to the exact H1 inside `#tl-main`.
- **Files modified:** `examples/threadline_phoenix/e2e/tests/operator-shell-home-phase183.spec.ts`
- **Verification:** Dark/default browser proof passed: 27 tests, 0 failures.
- **Committed in:** `aeb93242`

**2. [Rule 3 - Blocking verification] Forced e2e router recompilation for theme lanes**
- **Found during:** Task 2
- **Issue:** `mix verify.example_browser_light` passed `THREADLINE_E2E_THEME=system`, but the example app reused a stale dark-compiled router and rendered `data-tl-theme="dark"`.
- **Fix:** Changed the e2e runner from `mix compile` to `mix compile --force` after touching the router.
- **Files modified:** `examples/threadline_phoenix/e2e/run-e2e.sh`
- **Verification:** System/light browser proof passed: 9 tests, 0 failures; dark/default browser proof passed again afterward: 27 tests, 0 failures.
- **Committed in:** `aeb93242`

---

**Total deviations:** 2 auto-fixed (Rule 1: 1, Rule 3: 1)
**Impact on plan:** Both fixes were required to verify the planned shell/Home outcome. No product scope was added.

## Verification

- `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/skip_link_test.exs test/threadline/operator_surface/surface_header_csp_test.exs test/threadline/operator_surface/router_test.exs` - 121 tests, 0 failures.
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-shell-home-phase183.spec.ts` - 27 tests, 0 failures.
- `mix verify.example_browser_light tests/operator-shell-home-phase183.spec.ts` - 9 tests, 0 failures.
- `cd examples/threadline_phoenix && mix precommit` - failed in pre-existing demo-seed/walkthrough contract tests unrelated to Plan 183-02 shell/Home files: 109 tests, 7 failures.

## Issues Encountered

- The first desktop rail CSS attempt tried to override the closed `<details>` descendant hiding behavior. Chromium continued to report the panel as hidden, so the implementation moved the single panel outside `<details>` and used a sibling open selector.
- Example `mix precommit` still fails in the known demo contract/walkthrough seed area from Phase 183-01. Targeted source and browser verification for Plan 183-02 passed.

## Known Stubs

None. Stub-pattern scan found only the e2e runner's runtime `PHX_PID=""` initialization, not a UI/data stub.

## Auth Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 183-03 can build on a passing shell/Home proof across source contracts, dark/default browser e2e, and system/light browser e2e. The unrelated example demo-seed/walkthrough failures remain outside this plan and should be handled by the phase that owns those contracts.

## Self-Check: PASSED

- Found summary: `.planning/phases/183-shell-navigation-and-home-orientation/183-02-SUMMARY.md`
- Found key modified files: `lib/threadline/operator_surface/components/surface_header.ex`, `lib/threadline/operator_surface/style.ex`, `examples/threadline_phoenix/e2e/tests/operator-shell-home-phase183.spec.ts`, `examples/threadline_phoenix/e2e/run-e2e.sh`
- Found task commits: `12e69800`, `aeb93242`

---
*Phase: 183-shell-navigation-and-home-orientation*
*Completed: 2026-06-28*
