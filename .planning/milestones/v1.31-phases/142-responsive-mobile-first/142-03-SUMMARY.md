---
phase: 142-responsive-mobile-first
plan: "03"
subsystem: ui
tags: [responsive, playwright, browser-uat]

requires:
  - phase: 142-responsive-mobile-first
    plan: "02"
    provides: "Source-locked responsive primitives"
provides:
  - "Browser route x viewport responsive matrix"
  - "Focused proof of root overflow <= 1 across operator routes"
affects: [operator-surface, responsive-layout, phase-142]

tech-stack:
  added: []
  patterns:
    - "Self-contained Playwright route matrix using runtime overflow, computed-style, and bounding-box assertions"

key-files:
  created:
    - "examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts"
    - ".planning/phases/142-responsive-mobile-first/142-03-SUMMARY.md"
  modified: []

key-decisions:
  - "Kept the browser matrix self-contained to avoid shared helper churn."
  - "Used `#tl-main` attachment plus visible route-owned surfaces because the direct row-history route renders its visible surface as a fixed `.tl-subview` drawer."
  - "Recorded full-suite failures as exceptions because the focused Phase 142 matrix passed in the same run and the failures are in older specs with stale route/copy/strict-selector assumptions."

patterns-established:
  - "Route x viewport responsive acceptance should assert root overflow, nav reachability, table card/desktop semantics, drawer bounds, and dense control visibility without screenshot baselines."

requirements-completed: [POLISH-RESPONSIVE]

duration: 18min
completed: 2026-06-04
---

# Phase 142 Plan 03: Responsive Browser Matrix Summary

**All Phase 142 operator routes are browser-verified at 375, 768, and 1280**

## Accomplishments

- Added `operator-responsive-mobile-first.spec.ts` with phone 375x812, tablet 768x900, and desktop 1280x900 viewports.
- Covered `/audit`, `/audit/timeline`, `/audit/coverage`, a discovered transaction route, a discovered first-class row-history route, `/audit/actors/service_account/zendesk-sync`, `/audit/evidence`, `/audit/policy/redaction`, `/audit/policy/retention`, and `/audit/exports`.
- Asserted topbar nav reachability, root horizontal overflow `<= 1`, toolbar/filter usability, coverage/retention responsive table labels below 1280, desktop table headers at 1280, row-history drawer bounds, and dense prove/find controls.

## Verification

- `mix test test/threadline/operator_surface/style_contract_test.exs` - PASS, 17 tests, 0 failures.
- `test -f examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` - PASS.
- `rg -n "375|768|1280|scrollWidth|clientWidth|tl-table--responsive|tl-toolbar__form|tl-subview|operator-nav" examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` - PASS, matrix anchors present.
- `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-responsive-mobile-first.spec.ts` - PASS, 9 tests, 0 failures.
- `rg -n "body[^}]*overflow-x:\\s*hidden|html[^}]*overflow-x:\\s*hidden|\\.threadline-ui[^}]*overflow-x:\\s*hidden" lib/threadline/operator_surface/style.ex && exit 1 || exit 0` - PASS, no blanket root overflow masking.
- `mix verify.example_browser` - RED, 93 passed / 18 failed; the new responsive matrix passed at tests 28-30, 65-67, and 102-104 in that full run.

## Full Browser Gate Exceptions

- `operator-earned-flows.spec.ts` EF1 and EF4 fail in all three projects because Home form submissions remain on `/audit` instead of navigating to `/audit/rows/...` or `/audit/timeline`.
- `operator-home-nav-mobile.spec.ts` home orientation fails in all three projects because Home now contains 2 workflow forms while the older spec expects zero forms.
- `operator-screenshots.spec.ts` admin surfaces fails in all three projects on strict-mode `[REDACTED]` text matching; both transaction and row-history surfaces contain the same redacted text.
- `operator-screenshots.spec.ts` empty states fails in all three projects waiting for stale copy `No changes match`.
- `operator.spec.ts` row-history redacted capture fails in all three projects on the same strict-mode `[REDACTED]` ambiguity.

## TDD Evidence

- RED: the new matrix initially failed on stale Coverage copy, direct row-history `#tl-main` visibility semantics, and a strict Evidence table selector.
- GREEN: the same focused matrix passed after replacing stale copy with stable route selectors, checking `#tl-main` attachment for drawer-owned routes, and scoping Evidence to the first visible record list.

## Deviations from Plan

- The matrix asserts `#tl-main` attachment rather than visibility for all routes because first-class row history renders its visible UI as a fixed `.tl-subview` drawer under `#tl-main`; the drawer itself is visible and bounded.
- Full `mix verify.example_browser` remains red for unrelated existing specs; focused Phase 142 source/browser acceptance is green.

## Issues Encountered

- The local Playwright config runs the focused spec through three projects, so the focused command reports 9 tests rather than 3.
- Playwright generated failure artifacts during RED iterations under the ignored `examples/threadline_phoenix/e2e/test-results` directory.

## Known Stubs

None.

## User Setup Required

None. Port 4002 was stopped and verified clear after browser runs.

---
*Phase: 142-responsive-mobile-first*
*Completed: 2026-06-04*
