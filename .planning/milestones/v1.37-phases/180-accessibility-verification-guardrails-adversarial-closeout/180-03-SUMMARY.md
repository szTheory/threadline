---
phase: 180-accessibility-verification-guardrails-adversarial-closeout
plan: 03
subsystem: ui
tags: [motion, reduced-motion, playwright, phoenix-live-view, operator-surface, style-contracts]

requires:
  - phase: 180-accessibility-verification-guardrails-adversarial-closeout
    provides: Plans 180-01 and 180-02 rendered accessibility/APG baseline for opened operator widgets.
provides:
  - MOTION-01 source contracts for tokenized, layout-safe, enabled-only motion.
  - Rendered computed-style browser checks for default and reduced-motion behavior.
  - Tokenized compositor transition behavior for modal, drawer, dropdown, popover, accordion, toast, details, and press states.
affects: [phase-180, accessibility-verification, operator-surface, motion-guardrails]

tech-stack:
  added: []
  patterns:
    - Existing ExUnit style contracts for source-level motion governance.
    - Existing Playwright media emulation and computed-style checks for rendered motion evidence.
    - Existing Phoenix.LiveView.JS transition tuples with token-synced time values.

key-files:
  created:
    - .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-03-SUMMARY.md
  modified:
    - test/threadline/operator_surface/style_contract_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts
    - examples/threadline_phoenix/e2e/playwright.config.ts
    - lib/threadline/operator_surface/style.ex
    - lib/threadline/operator_surface/ui.ex

key-decisions:
  - "Keep MOTION-01 enforcement in the existing style contract and Playwright operator-motion spec; no new dependency, animation library, route, or harness was added."
  - "Preserve legitimate enabled press feedback while making disabled and aria-disabled controls still through selector-bounded source and rendered checks."
  - "Use existing Phoenix.LiveView.JS transition tuples for dropdown, popover, and accordion motion so rendered widgets stay token-governed without a new runtime mechanism."

patterns-established:
  - "Motion contracts should ban layout-affecting transitions while allowing color/background/box-shadow affordance transitions already used for operator feedback."
  - "Rendered motion checks should assert computed transition properties, durations, timing functions, transform origin, reduced-motion collapse, and disabled-control stillness."

requirements-completed: [MOTION-01]
duration: 21m 49s
completed: 2026-06-20
status: complete
---

# Phase 180 Plan 03: Motion And Reduced-Motion Guardrails Summary

**MOTION-01 source and rendered guardrails now lock tokenized compositor motion, reduced-motion collapse, enabled-only press feedback, and disabled-control stillness.**

## Performance

- **Duration:** 21m 49s
- **Started:** 2026-06-20T01:22:52Z
- **Completed:** 2026-06-20T01:44:41Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added source contracts that reject unqualified press transforms, unsafe zero-scale collapse, layout-affecting motion transitions, and high-frequency stream/table entrance animation.
- Replaced policy details layout-transition motion with opacity-only tokenized disclosure motion and explicit reduced-motion utility collapse.
- Extended rendered Playwright coverage for modal, drawer, dropdown, popover, accordion, toast, policy details, row-history drawer, enabled active feedback, and disabled-control stillness.
- Wired dropdown, popover, and accordion through existing `Phoenix.LiveView.JS` transition tuples using the same token-synced 180ms motion contract as existing overlays.
- Included `operator-motion.spec.ts` in the system-theme Playwright project so the required system-lane verification executes real motion tests.

## Task Commits

1. **Task 1 RED: Tighten source motion contracts** - `b257341` (`test`)
2. **Task 1 GREEN: Enforce source motion guardrails** - `d9d9c5d` (`fix`)
3. **Task 2 RED: Add rendered computed-style motion checks** - `fb2364e` (`test`)
4. **Task 2 GREEN: Implement rendered motion guardrails** - `78d34f1` (`fix`)

## Files Created/Modified

- `test/threadline/operator_surface/style_contract_test.exs` - Added MOTION-01 source scans for enabled-only press feedback, reduced-motion utility coverage, layout-safe transition properties, unsafe scale collapse, and high-frequency stream stillness.
- `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` - Added computed-style browser assertions for tokenized default motion, reduced-motion collapse, disabled-control stillness, active feedback, and robust row-history discovery.
- `examples/threadline_phoenix/e2e/playwright.config.ts` - Added `operator-motion.spec.ts` to the existing system/light Playwright project filter so the required verification command runs tests.
- `lib/threadline/operator_surface/style.ex` - Added tokenized compositor transition properties/origins, enabled-only active fixture feedback, opacity-only details motion, and explicit reduced-motion resets.
- `lib/threadline/operator_surface/ui.ex` - Added token-synced `JS.toggle` transition tuples to dropdown, popover, and accordion widgets.

## Verification

- `mix test test/threadline/operator_surface/style_contract_test.exs` - passed, 45 tests, 0 failures.
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-motion.spec.ts` - passed, 21 tests, 0 failures.
- `THREADLINE_E2E_THEME=system ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-motion.spec.ts` - passed, 7 tests, 0 failures.
- Task 1 RED evidence: style contract ran 45 tests with 4 expected failures for missing enabled-only active selector, missing explicit reduced-motion utility coverage, unqualified active press feedback, and layout-affecting policy details transition.
- Task 2 RED evidence: default browser run reported 12 passed / 9 failed before source fixes; failures covered rendered transition duration `0s`, missing active feedback, and a brittle row-history helper timeout.

## Decisions Made

- Kept reduced-motion semantics aligned with the source contract: non-essential drawer animation computes as `animation-name: none` and transform is none/identity under reduced motion.
- Used the existing stress matrix `Active/Pressed` fixture for stable rendered active-state proof, while still using pointer/keyboard attempts to prove disabled controls do not visually press.
- Navigated row-history motion proof via extracted hrefs rather than pointer clicks because sticky operator chrome can intercept a Playwright click after automatic scrolling.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] System-theme Playwright project excluded `operator-motion.spec.ts`**
- **Found during:** Task 2 (rendered computed-style checks)
- **Issue:** The required `THREADLINE_E2E_THEME=system ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-motion.spec.ts` command would not execute the motion spec because the light/system project `testMatch` did not include it.
- **Fix:** Added `operator-motion` to the existing `desktop-chromium-light` project filter.
- **Files modified:** `examples/threadline_phoenix/e2e/playwright.config.ts`
- **Verification:** System-lane command passed 7 tests, 0 failures.
- **Committed in:** `fb2364e`

**2. [Rule 3 - Blocking] Row-history reduced-motion helper used brittle seeded correlation and pointer click**
- **Found during:** Task 2 GREEN verification
- **Issue:** The hardcoded correlation did not reliably produce a clickable transaction link in the current seeded data, and sticky toolbar chrome could intercept Playwright's auto-scrolled click.
- **Fix:** Reused the seeded `ticket_replies` table path, extracted the transaction href, navigated directly, and kept the rendered drawer computed-style assertion.
- **Files modified:** `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts`
- **Verification:** Default browser command passed 21 tests, 0 failures; system-lane command passed 7 tests, 0 failures.
- **Committed in:** `78d34f1`

**3. [Rule 2 - Missing Critical] Stress active-state fixture had no rendered press transform**
- **Found during:** Task 2 GREEN verification
- **Issue:** Source-level pseudo-class feedback existed, but the rendered stress matrix's `Active/Pressed` fixture did not compute the same active transform, leaving browser evidence for enabled feedback unstable.
- **Fix:** Added a selector-bounded `.tl-button.active:not(:disabled):not([disabled]):not([aria-disabled="true"])` transform that mirrors the enabled pseudo-state and remains excluded from disabled controls.
- **Files modified:** `lib/threadline/operator_surface/style.ex`
- **Verification:** Style contract passed and rendered motion spec passed in default/system lanes.
- **Committed in:** `78d34f1`

**Total deviations:** 3 auto-fixed (2 blocking harness issues, 1 missing critical rendered-state affordance)
**Impact on plan:** All changes were required to make MOTION-01 measurable in the existing harness. No dependency, public API, route, auth, schema, capture, or semantics change was introduced.

## Issues Encountered

- Playwright cannot reliably sample the browser `:active` pseudo-class during a mouse-down style read across all projects. The rendered proof now uses the existing stress matrix `Active/Pressed` state for enabled feedback, while disabled controls are still exercised by pointer and keyboard attempts.
- Reduced-motion source rules intentionally disable drawer animation; the rendered assertion was aligned to prove `animation-name: none` and identity transform rather than expecting the default `tl-drawer-in` keyframe under reduced motion.

## Known Stubs

None. Stub-pattern scan found only intentional Phoenix slot empty-list checks, test string fixtures, and the existing `placeholder` global-attribute allowlist; no unresolved UI stubs or mock data paths were introduced.

## Auth Gates

None.

## Threat Notes

No new network endpoint, public route, authorization path, file access path, schema change, package install, audit framework, or animation dependency was introduced. Changes are limited to CSS, internal LiveView transition attributes, and existing ExUnit/Playwright guardrails.

## Next Phase Readiness

Plan 180-04 can use the MOTION-01 source/browser guardrails as green prerequisites for MOTION-02 guardrail matrix and adversarial closeout. Remaining inherited example precommit failures from Plans 180-01/180-02 are still outside this plan and were not rerun or reclassified here.

## Self-Check: PASSED

- Verified the summary file and all modified task files exist.
- Verified task commits `b257341`, `d9d9c5d`, `fb2364e`, and `78d34f1` exist in git history.
- Verified no unrelated untracked files were staged or committed.

---
*Phase: 180-accessibility-verification-guardrails-adversarial-closeout*
*Completed: 2026-06-20*
