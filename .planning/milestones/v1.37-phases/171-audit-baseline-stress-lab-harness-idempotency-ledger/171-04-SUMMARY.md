---
phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger
plan: 04
subsystem: testing
tags: [playwright, phoenix, e2e, design-system-ledger, screenshots]
requires:
  - phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger
    provides: stress fixture registry, JSON ledger, and authenticated /audit/__stress route from plans 171-01 through 171-03
provides:
  - authenticated stress route browser semantic coverage
  - focused mix verify.operator_stress browser alias
  - ledger-owned three-cell CI screenshot allowlist
  - first three desktop Chromium stress screenshot baselines
affects: [172-foundations, 173-primitives, 178-page-stress]
tech-stack:
  added: []
  patterns:
    - Playwright spec reads ledger-owned allowlist before visual assertions
    - desktop-only screenshot ratchet with broad semantic coverage across projects
key-files:
  created:
    - examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts-snapshots/stress-page-home-happy-dark-1024-desktop-chromium.png
    - examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts-snapshots/stress-page-timeline-empty-dark-1024-desktop-chromium.png
    - examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts-snapshots/stress-footgun-transaction-desktop-centering-dark-1024-desktop-chromium.png
  modified:
    - mix.exs
    - .planning/design-system-ledger.json
    - DESIGN-SYSTEM.md
    - lib/threadline/operator_surface/stress_fixtures.ex
    - examples/threadline_phoenix/e2e/playwright.config.ts
key-decisions:
  - "Stress screenshot comparison runs only on desktop-chromium; semantic coverage runs across default, desktop, mobile, and system/light lanes."
  - "The CI screenshot allowlist is read from .planning/design-system-ledger.json and contains exactly three dark/1024 cells."
  - "Concrete page.home.happy and page.timeline.empty fixture stories were added because plan 171-04 required them as browser and screenshot targets."
patterns-established:
  - "Browser specs can assert ledger-owned screenshot allowlists before calling toHaveScreenshot."
  - "Stress snapshots use baseline_ref names from the ledger and Playwright's project-qualified snapshotPathTemplate."
requirements-completed: [DS-01, DS-03, DS-04]
duration: 60min
completed: 2026-06-14
---

# Phase 171 Plan 04: Browser Stress Harness Summary

**Authenticated Playwright stress-route guard with ledger-owned three-baseline desktop screenshot ratchet**

## Performance

- **Duration:** 60 min
- **Started:** 2026-06-14T21:22:00Z
- **Completed:** 2026-06-14T22:22:16Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Added `operator-stress.spec.ts` covering unauthenticated redirect, authenticated shell/theme reuse, story metadata, safe bad params, category current-state semantics, folded reserved-copy checks, and no horizontal overflow at 320, 375, 768, 1024, and 1440.
- Added `mix verify.operator_stress` as the focused browser alias and widened the system/light Playwright lane to include the stress spec.
- Replaced the prior provisional screenshot allowlist with exactly three ledger-owned dark/1024 CI entries.
- Generated and committed the first three desktop Chromium stress baselines.

## Task Commits

1. **Task 1 RED: Add failing stress route browser spec** - `ad5d270` (`test`)
2. **Task 1 GREEN: Wire stress route browser semantics** - `cab1396` (`feat`)
3. **Task 2 RED: Add failing stress screenshot ratchet spec** - `3e17c82` (`test`)
4. **Task 2 GREEN: Add ledger-owned stress screenshot ratchet** - `be07611` (`feat`)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` - Semantic stress route browser coverage and ledger-owned screenshot assertions.
- `examples/threadline_phoenix/e2e/playwright.config.ts` - System/light project now includes `operator-stress.spec.ts`.
- `mix.exs` - Added the focused `verify.operator_stress` alias.
- `.planning/design-system-ledger.json` - Added required concrete page stories, attached screenshot refs, and set the CI allowlist to three dark/1024 cells.
- `DESIGN-SYSTEM.md` - Refreshed projection rows for `page.home.happy` and `page.timeline.empty`.
- `lib/threadline/operator_surface/stress_fixtures.ex` - Added concrete fixture-backed page stories used by the plan.
- `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts-snapshots/*.png` - Three generated desktop Chromium baselines.

## Decisions Made

- Kept screenshots desktop-only and semantic checks broad to preserve D-16 through D-19.
- Used the ledger `baseline_ref` values as Playwright screenshot names, letting the existing snapshot template add the project suffix.
- Added concrete fixture-backed page stories instead of ledger-only entries so StressLive, ExUnit, and Playwright all round-trip through the same story source.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added concrete page stress stories required by the browser plan**
- **Found during:** Task 1
- **Issue:** The plan required `page.timeline.empty` and later `page.home.happy`, but prior plans only created reserved page placeholders.
- **Fix:** Added fixture-backed stories, ledger rows, ratchet locks/minimums, and DESIGN-SYSTEM projection rows.
- **Files modified:** `lib/threadline/operator_surface/stress_fixtures.ex`, `.planning/design-system-ledger.json`, `DESIGN-SYSTEM.md`
- **Verification:** `mix test test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs`; `mix verify.operator_stress`
- **Committed in:** `cab1396`

**Total deviations:** 1 auto-fixed (Rule 2)
**Impact on plan:** Required for the plan's named browser and screenshot targets; no public API, package, or runtime scope expansion.

## Issues Encountered

- First `(cd examples/threadline_phoenix && mix precommit)` run timed out in existing `threadline_evidence_show_example_test.exs` during seed setup. Immediate rerun passed: 95 tests, 0 failures. No code changes were needed.
- `mix verify.operator_stress -- --project=desktop-chromium --update-snapshots` passed an extra `--` through to Playwright, so snapshot generation was rerun through `bash examples/threadline_phoenix/e2e/run-e2e.sh operator-stress.spec.ts --project=desktop-chromium --update-snapshots`, the same e2e bootstrap harness without the Mix argument wrapper.

## Known Stubs

None. The remaining reserved stress stories are intentional Phase 171 inventory placeholders created by earlier plans and do not prevent this plan's browser or screenshot goals.

## Threat Flags

None beyond the plan threat model. The new browser spec reads `.planning/design-system-ledger.json` locally and does not introduce new network endpoints, auth paths, schema boundaries, or external visual services.

## Verification

- `mix verify.example_browser -- operator-stress.spec.ts` - RED before implementation: failed on missing `page.timeline.empty` story and missing light-lane config.
- `mix test test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs` - 19 tests, 0 failures.
- `mix verify.operator_stress` - Task 1 GREEN: 33 passed.
- `THREADLINE_E2E_THEME=system mix verify.example_browser_light -- operator-stress.spec.ts` - Task 1 GREEN: 11 passed.
- `mix verify.operator_stress` - Task 2 RED: failed on old allowlist and missing snapshots.
- `bash examples/threadline_phoenix/e2e/run-e2e.sh operator-stress.spec.ts --project=desktop-chromium --update-snapshots` - 15 passed and generated baselines.
- `mix test test/threadline/operator_surface/stress_ledger_test.exs && mix verify.operator_stress` - 10 ExUnit tests, 0 failures; 39 Playwright passed, 6 expected non-desktop screenshot skips.
- `THREADLINE_E2E_THEME=system mix verify.example_browser_light -- operator-stress.spec.ts` - 12 passed, 3 expected screenshot skips.
- `(cd examples/threadline_phoenix && mix precommit)` - rerun passed: 95 tests, 0 failures.
- `rg -n 'Chromatic|Percy|Applitools|storybook|Storybook|@storybook|phoenix_storybook' examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts .planning/design-system-ledger.json` - no matches.

## Self-Check: PASSED

- Found `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts`
- Found `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts-snapshots/stress-page-home-happy-dark-1024-desktop-chromium.png`
- Found `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts-snapshots/stress-page-timeline-empty-dark-1024-desktop-chromium.png`
- Found `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts-snapshots/stress-footgun-transaction-desktop-centering-dark-1024-desktop-chromium.png`
- Found task commit `ad5d270`
- Found task commit `cab1396`
- Found task commit `3e17c82`
- Found task commit `be07611`

## User Setup Required

None - no external services, package installs, or manual setup required.

## Next Phase Readiness

Phase 172 and later component phases can expand `screenshot_allowlist.ci` through `.planning/design-system-ledger.json` while preserving broad semantic coverage and the narrow first pixel ratchet.

---
*Phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger*
*Completed: 2026-06-14*
