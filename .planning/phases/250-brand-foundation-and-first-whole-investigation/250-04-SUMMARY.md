---
phase: 250-brand-foundation-and-first-whole-investigation
plan: "04"
subsystem: ui
tags: [phoenix, liveview, css, themes, accessibility, playwright]
requires:
  - phase: 250-03
    provides:
      - Four approved embedded font faces and shared typography roles
provides:
  - Immediate System, Light, and Dark choices through the existing server-authoritative theme POST.
  - Mounted keyboard, effective-theme, focus, logo, and responsive observations for the supported theme choices.
  - Current four-face metadata in the evidence collector while preserving legacy five-face before validation.
affects: [250-05-package-assets, 250-08-rendered-browser-proof]
actuals:
  tokens: null
  tasks: 2
  commits: 8
  plan_head_before: 67450520d6c6700cfe53d04969d0a393f7b5a33d
  plan_head_after: c1bb56d3f583c54b9f52349ca2e55452e77a8e1b
tech-stack:
  added: []
  patterns:
    - Existing native POST and CSRF controls remain the authority for theme changes.
    - Browser focus checks preserve the expected 2px ring and wait for an observed settled state after DOM changes.
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/components/surface_header.ex
    - lib/threadline/operator_surface/style/02_base_shell.css
    - test/threadline/operator_surface/surface_header_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
    - examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts
    - examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts
    - examples/threadline_phoenix/e2e/support/operator-investigation-pair.test.ts
    - examples/threadline_phoenix/e2e/support/operator-journey-inventory.json
    - test/fixtures/style/operator_surface.css
    - test/threadline/operator_surface/style_byte_lock_test.exs
key-decisions:
  - Keep immediate theme selection on the existing native CSRF-protected POST and preserve the controller’s validation and return behavior.
  - Keep the legacy five-face before capsule immutable while recording the current approved four-face metadata.
  - Preserve the 2px focus requirement; a bounded poll waits for actual active, focus-visible state after the page settles. The intermittent initial cascade cause remains unproven.
patterns-established:
  - Theme preference, mounted theme, and effective System scheme are separate observations.
  - Home-route copy-script identity is nullable only when that route has no copy controls.
requirements-completed: [ADM-11]
coverage:
  - id: D1
    description: System, Light, and Dark theme choices submit immediately through the existing server flow and retain accessible, persisted behavior.
    requirement: ADM-11
    verification:
      - kind: unit
        ref: mix verify.test for surface_header, surface_header_csp, theme_auth_plug, and style_contract tests (71 passed)
        status: pass
      - kind: integration
        ref: examples/threadline_phoenix mix test operator_surface_test.exs (12 passed)
        status: pass
      - kind: automated_ui
        ref: browser-begin theme, exact desktop-chromium theme case, browser-check theme (1 passed; 0 skips or retries)
        status: pass
    human_judgment: false
  - id: D2
    description: Theme and appearance evidence distinguishes stored, effective, and System state, records current four-face metadata, and retains the legacy before contract.
    verification:
      - kind: unit
        ref: e2e tsx --test operator-ci-evidence, operator-route-evidence, and operator-investigation-pair (48 passed)
        status: pass
      - kind: unit
        ref: mix verify.test style_byte_lock_test.exs and style_contract_test.exs (70 passed)
        status: pass
      - kind: other
        ref: mix verify.format
        status: pass
    human_judgment: false
duration: null
completed: 2026-11-12
status: complete
---

# Phase 250 Plan 04: Immediate Native Theme Selection Summary

**System, Light, and Dark preferences now submit through the existing CSRF-protected native flow, with keyboard and settled focus behavior verified in the mounted Admin.**

## Performance

- **Duration:** Not measured in this executor context; the parent reconciles the managed launch-to-terminal receipt.
- **Started:** Exact start time is parent-owned and was not carried into this continuation.
- **Completed:** 2026-11-12; exact terminal time is parent-owned.
- **Tasks:** 2
- **Files modified:** 12 source and test files, excluding this summary.

## Accomplishments

- Replaced the separate theme confirmation with accessible native submit choices while retaining server-side validation, CSRF protection, session/cookie persistence, and safe return behavior.
- Updated the mounted theme observer to report stored preference, effective color scheme, and device scheme separately. It supports the current four-face metadata and keeps the legacy five-face before check intact.
- Verified the exact theme case through keyboard activation, post-navigation persistence, focus ring, visible theme logo, and the narrow responsive boundary.

## Task Commits

1. **Task 1 RED: Assert immediate theme submit controls** — 9afc9d75
2. **Task 1 GREEN: Apply themes through native submit choices** — 2cc2aac9
3. **Task 2: Verify native theme evidence and current font faces** — a0dd44d5
4. **Task 2: Refresh current font inventory anchor** — de0a5c78
5. **C14 diagnosis: Capture mounted focus cascade** — 00d4233a
6. **Fix: Check each narrow theme choice individually** — 7117fc3c
7. **Fix: Allow absent copy script on the theme home route** — 87659083
8. **Fix: Wait for the exact settled focus state** — c1bb56d3

**Plan metadata:** committed separately with this summary.

## Files Created/Modified

- **surface_header.ex** — Native System, Light, and Dark submit buttons.
- **style/02_base_shell.css** — Pressed-state and focus styling for the new controls.
- **surface_header_test.exs** and **style_contract_test.exs** — Header, focus, and style contracts.
- **operator_surface_test.exs** — Mounted POST, session, cookie, CSRF, and return-path coverage.
- **operator-route-states.spec.ts** — Keyboard theme case and bounded focus-state diagnostics.
- **operator-browser-evidence.ts** — Pressed-button preference observation.
- **operator-investigation-pair.ts** and **operator-investigation-pair.test.ts** — Four-face current metadata and focused browser receipt support.
- **operator-journey-inventory.json** — Current theme and evidence inventory.
- **operator_surface.css** and **style_byte_lock_test.exs** — Updated fixture and byte-lock assertions.

## Decisions Made

- Reused the existing native POST, CSRF, session, cookie, and validated return path; no public API or client-side persistence was added.
- Marked ADM-11 complete because this plan establishes the immediate server-resolved theme flow. ADM-08, ADM-09, and ADM-17 remain phase-wide requirements and are not claimed complete by this partial contribution.
- Kept the required 2px focus ring. Chromium’s initial post-reload sample sometimes reported 3px with zero offset despite current served CSS and a matching 2px author rule; the test now records that initial state and requires the exact 2px focus-visible state to settle. The cause of the transient sample is not claimed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Check each theme choice instead of a multi-match locator**
- **Found during:** Task 2 browser proof.
- **Issue:** The visibility assertion matched all three theme buttons and Playwright rejected the strict locator.
- **Fix:** Assert visibility for each button individually.
- **Files modified:** examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
- **Committed in:** 7117fc3c

**2. [Rule 1 - Bug] Allow the home route to omit the copy-script marker**
- **Found during:** Task 2 browser proof.
- **Issue:** The /audit home shell has no copy controls or copy script, but the observer required the script marker on every route.
- **Fix:** Record a null inline-script digest when there are no copy controls; continue to fail if copy controls exist without the script.
- **Files modified:** examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts
- **Committed in:** 87659083

**3. [Rule 1 - Bug] Wait for the exact focus state after DOM transitions**
- **Found during:** Task 2 browser proof.
- **Issue:** One initial post-reload sample reported a 3px outline and zero offset although the mounted style body matched the fixture and the 2px rule matched.
- **Fix:** Capture initial inline, animation, and Chromium CSS cascade evidence, then use a bounded poll for the unchanged active, focus-visible, 2px solid, 2px-offset requirement. The check still fails if the expected state never appears.
- **Files modified:** examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
- **Committed in:** 00d4233a and c1bb56d3

**Total deviations:** 3 auto-fixed (all Rule 1 test/evidence corrections). **Impact:** The final proof keeps the planned expectations and server contracts; no production focus value was changed.

## Issues Encountered

- An early browser preflight compared a full commit SHA with an abbreviated value and stopped before browser-begin; it launched no browser. The guard was corrected before the next diagnostic.
- The first preserved C14 attempt failed on a 3px versus 2px outline assertion. A later diagnostic run reached the planned focus checks but exposed the strict multi-button locator; the next run exposed the home-route copy-script assumption; another run captured the post-reload 3px sample. Each report and diagnostic was preserved.
- The final C14 run passed exactly one desktop Chromium case with no skips, retries, or flaky results. browser-check accepted the fresh report.
- A read-only post-browser materialization check still matched the accepted investigation snapshot. The test checkout and retained serving checkout remained distinct; the parent-owned app was not restarted or stopped.

## Verification

- mix verify.test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/surface_header_csp_test.exs test/threadline/operator_surface/theme_auth_plug_test.exs test/threadline/operator_surface/style_contract_test.exs — 71 tests passed.
- cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/operator_surface_test.exs — 12 tests passed.
- C14 browser-begin → direct desktop-chromium Playwright case → browser-check — 1 passed, no skips, retries, or flaky results.
- cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts support/operator-investigation-pair.test.ts — 48 tests passed.
- mix verify.test test/threadline/operator_surface/style_byte_lock_test.exs test/threadline/operator_surface/style_contract_test.exs — 70 tests passed.
- mix verify.format — passed.
- The read-only materialization helper reported the accepted snapshot matched after the browser proof.

## User Setup Required

None.

## Next Phase Readiness

The immediate theme flow, source locks, current appearance metadata, and selected mounted proof are ready for the remaining package, logo, and complete font-loading proofs. Full loaded/computed/blocked/disabled font behavior remains assigned to Plan 250-08. No user action is needed; the parent owns shared phase state and independent review.

---
*Phase: 250-brand-foundation-and-first-whole-investigation*
*Completed: 2026-11-12*

## Self-Check: PASSED

All listed key files exist, the eight measured plan commits are ancestors of this branch HEAD, the assigned acceptance criteria passed, and the plan-scoped evaluation resolver found the eight commits on this branch.

