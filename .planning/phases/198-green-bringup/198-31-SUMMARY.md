---
phase: 198-green-bringup
plan: 31
subsystem: testing
tags: [playwright, e2e, ci, diagnosis, accessibility]

requires:
  - phase: 198-green-bringup
    provides: "plan 198-25's export-status copy fix (canonical 'Export expired' literal); round-4 CI measurement (33253587315) and its honest 'cause not established' record for operator-responsive-mobile-first.spec.ts:577:5"
provides:
  - "Two self-caused-regression Playwright rows re-anchored to canonical product copy"
  - "operator-responsive-mobile-first.spec.ts:577:5 diagnosed at cause and fixed (row-history route's own phx-click-away being triggered by the shared mobile-nav-toggle chrome check)"
  - "WR-08, WR-09, WR-11 closed with strictly-added assertions"
  - "Local unbounded Playwright measurement (both projects) recorded beside round 4's CI-capped figures"
affects: [198-round5-remaining-plans, playwright-lane-red-row-count]

actuals:
  tokens: 62000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Diagnosis-before-fix for CI-only discoveries: read the trace.zip network log + accessibility-tree DOM snapshot before writing a fix, not after"
    - "Direct standalone-script reproduction of a suspected browser-interaction mechanism, outside the full test harness, to confirm cause independent of full-suite timing"
    - "exerciseMobileNav-style opt-out on a shared chrome-check helper, scoped to the one route where the shared interaction would self-conflict, rather than weakening the helper for everyone"

key-files:
  created:
    - .planning/audits/198-round5-playwright.md
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts

key-decisions:
  - "operator-responsive-mobile-first.spec.ts:577:5's cause is the shared expectOperatorChrome helper's mobile-nav-toggle click firing the row-history drawer's own phx-click-away (row_history_component.ex), not a product regression — confirmed by direct standalone reproduction, not inferred from the CI symptom alone."
  - "Fixed at cause with a scoped exerciseMobileNav opt-out for the one route (row history) where the shared toggle-click interaction self-conflicts with the route's own modal, rather than reordering assertions globally or loosening the exact:true heading match."
  - "No lib/ file touched anywhere in this plan; both /Expired/ locator fixes move the test toward the canonical product literal ('Export expired'), never the reverse."

requirements-completed: []

coverage:
  - id: D1
    description: "Both self-caused /Expired/ regression rows (operator-accessibility.spec.ts:565:3, operator-prove-mobile.spec.ts:38:3) pass by name, anchored to the canonical 'Export expired' literal"
    requirement: null
    verification:
      - kind: e2e
        ref: "operator-accessibility.spec.ts:565:3 (desktop-chromium + mobile-chromium)"
        status: pass
      - kind: e2e
        ref: "operator-prove-mobile.spec.ts:38:3 (desktop-chromium + mobile-chromium)"
        status: pass
    human_judgment: false
  - id: D2
    description: "operator-responsive-mobile-first.spec.ts:577:5 diagnosed at an established, cited cause and fixed; phone-viewport row-history route passes by name"
    requirement: null
    verification:
      - kind: e2e
        ref: "operator-responsive-mobile-first.spec.ts:584:5 'operator responsive matrix: phone' (desktop-chromium + mobile-chromium)"
        status: pass
    human_judgment: false
  - id: D3
    description: "WR-08, WR-09, WR-11 closed by strictly-added assertions, no expect() removed"
    requirement: null
    verification:
      - kind: e2e
        ref: "operator-phase-175-uat.spec.ts:84:3, operator-screenshots.spec.ts:90:3, operator-find-mobile.spec.ts:103:3 (desktop-chromium + mobile-chromium)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Local unbounded Playwright measurement recorded beside round 4's CI-capped figures, with the non-nested-population caveat stated"
    requirement: null
    verification: []
    human_judgment: true
    rationale: "This is a measurement/documentation deliverable, not a pass/fail assertion — recorded below and in the audit doc for human review, not machine-verifiable as pass/fail."

duration: 55min
completed: 2026-08-30
status: complete
---

# Phase 198 Plan 31: Round-5 Playwright Repair Summary

**Diagnosed and fixed three CI-red Playwright rows at their causes (two self-caused `/Expired/` regressions, one un-inventoried row-history phone-width failure traced to a shared test helper triggering the row-history drawer's own `phx-click-away`), and closed three open code-review warnings — no product file touched, no assertion removed.**

## Performance

- **Duration:** 55 min
- **Tasks:** 3 completed
- **Files modified:** 6 e2e spec files + 1 new audit doc

## Accomplishments

- Re-anchored the two `/Expired|File unavailable/` locators (broken by plan 198-25's correct `"Expired"` → `"Export expired"` product-copy fix) to the canonical literal, `/Export expired|File unavailable/`, with a red-then-green proof in `.planning/audits/198-round5-playwright.md`. No product file touched.
- Established the cause of `operator-responsive-mobile-first.spec.ts:577:5` from the run-33253587315 trace artifact (network log + accessibility-tree DOM snapshot, both attempt and retry), confirmed by direct standalone reproduction against a local `phx.server`: the shared `expectOperatorChrome` chrome-check helper's mobile-nav-toggle click, exercised below 768px, is a click outside the row-history route's own always-open drawer, which the drawer's `phx-click-away` (`row_history_component.ex`) treats as a dismissal — navigating to `/audit/timeline` before the "Row history" heading assertion runs. Fixed with a scoped `exerciseMobileNav` opt-out for that one route; every other chrome assertion for it, and full mobile-nav-toggle exercise for every other route, is unchanged.
- Closed WR-08 (restored the `operator-nav-shell` `<nav>` landmark + `aria-label` assertion), WR-09 (restored the actor type check via the product's `<:metadata key="Kind">` row, added `.first()`, quoted the interpolated id with `JSON.stringify`), and WR-11 (made the coverage `<details>` expansion idempotent with a state assertion and summary-text check). No `expect(` removed in any of the three files.

## Task Commits

Each task was committed atomically:

1. **Task 1: Re-anchor the two /Expired/ locators** - `82a517a0` (fix)
2. **Task 2: Establish cause and fix operator-responsive-mobile-first.spec.ts:577:5** - `887198c6` (fix)
3. **Task 3: Close WR-08, WR-09, WR-11** - `4fa1d2c9` (fix)

## Files Created/Modified

- `.planning/audits/198-round5-playwright.md` - round-5 Playwright diagnosis ledger; one section per row/warning with verbatim CI errors, cited product source lines, and passing-run proofs
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` - `/Expired/` → `/Export expired/` re-anchor
- `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts` - same re-anchor
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` - `expectOperatorChrome` gained `exerciseMobileNav`; matrix loop skips it for the row-history route
- `examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts` - WR-08 landmark assertions
- `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` - WR-09 restorations
- `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` - WR-11 idempotent expansion

## Decisions Made

- **`operator-responsive-mobile-first.spec.ts:577:5` is a test interaction-ordering bug, not a product bug.** The row-history drawer's `phx-click-away` firing on any outside click (including the unrelated shell-nav toggle) is the product working as designed for a modal dismiss pattern; the shared chrome-check helper simply should not exercise that toggle on the one route whose entire content is that modal. Fixed test-side only — no `lib/` file is in this plan's `files_modified`, and none was touched.
- **Cause established by direct reproduction, not by symptom-matching alone.** Two standalone Playwright scripts (with and without explicit `hasTouch`) against a local `mix phx.server`, matching the spec's exact `test.use` shape, deterministically reproduced the navigate-away — satisfying the plan's halt-clause bar of "confirmed or eliminated against product source rather than assumed."
- **WR-09's type assertion** is scoped to the product's own `<:metadata key="Kind">` DOM structure (`.tl-kv__row` / `.tl-kv__key` / `.tl-kv__value`) rather than a loose page-wide text regex, so it stays specific and won't accidentally match unrelated "user" text elsewhere on the page.

## Deviations from Plan

None - plan executed exactly as written. Task 2's diagnosis surfaced a genuine, reproducible cause (not a speculative guess), so the "fix at cause" branch was taken rather than the halt clause.

### Auto-fixed Issues

None beyond the plan's own three tasks - no Rule 1/2/3 deviations were needed.

---

**Total deviations:** 0.
**Impact on plan:** None - executed as specified.

## Local Unbounded Measurement vs. CI's Capped Figures (plan `<verification>` requirement)

Run locally with `maxFailures: 0` (unbounded) and `process.env.CI` unset, one project at a time (a single combined `--project=desktop-chromium --project=mobile-chromium` invocation twice hit unrelated local `mix phx.server` process instability under ~15+ minutes of sustained load and had to be restarted split by project; both split runs completed cleanly):

| Population | desktop-chromium | mobile-chromium | Combined |
|---|---|---|---|
| **This plan's local unbounded run** | 159 passed / 5 failed / 6 skipped (170 total) | 157 passed / 4 failed / 9 skipped (170 total) | 316 passed / 9 failed / 15 skipped (340 total) |
| **Round 4 CI run `33253587315`** (`maxFailures: 5`-capped) | — | — | `5 failed, 9 skipped, 188 did not run, 138 passed (5.4m)` |

**These two populations are not nested, and a delta between them is not by itself evidence of progress.** CI's figure is right-censored at exactly 5 (`Testing stopped early after 5 maximum allowed failures`) — 188 of CI's 340 tests never ran, so CI's 5-failure figure cannot be compared numerically against this run's 9. What *can* be compared is composition: **none of the 9 local failures are new** — all 9 are either the single known-flaky pixel-position assertion in `operator-prove-mobile.spec.ts:123:3` (failed once across the two local runs, passed on the other project — a genuine flake unrelated to this plan's diffs) or the 4-per-project `operator-screenshot-regression.spec.ts` baseline mismatches (pre-existing, that file is not in this plan's `files_modified` and was not touched). All three of this plan's target rows (`operator-accessibility.spec.ts:565:3`, `operator-prove-mobile.spec.ts:38:3`, `operator-responsive-mobile-first.spec.ts:584:5` phone) passed cleanly on **both** projects across **both** local runs, and all three of WR-08/WR-09/WR-11's target tests passed cleanly on both projects.

## Issues Encountered

- **Local `mix phx.server` instability under sustained load.** Running the full unbounded suite as a single `--project=desktop-chromium --project=mobile-chromium` invocation twice caused the local dev Phoenix server process to terminate unexpectedly partway through (once after ~217 tests, once with no server log output at all — consistent with an abrupt kill rather than an application crash). This is local environment fragility, not caused by this plan's diff (confirmed: the crash point varied between attempts and coincided with no code under test). Resolved pragmatically by running each project's full suite as a separate, shorter invocation, both of which completed cleanly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `Example app browser E2E (Playwright)`'s red-row count on the next measured CI run should drop by the two self-caused `/Expired/` rows and the `operator-responsive-mobile-first.spec.ts:577:5` row (three of the round-4 run's five red rows), leaving the two D-39-forbidden `operator-stress.spec.ts` `page.*` baseline diffs as the lane's remaining structural red — matching this plan's stated success criteria.
- WR-08, WR-09, WR-11 are closed and can be removed from any open review-warning tracking.
- Ready for the next round-5 plan (198-32 onward).

---
*Phase: 198-green-bringup*
*Completed: 2026-08-30*
