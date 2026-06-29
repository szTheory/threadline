---
phase: 185-coverage-and-audit-readiness
plan: 01
subsystem: ui
tags: [phoenix-liveview, operator-surface, coverage, audit-readiness, playwright]
requires:
  - phase: 184-timeline-investigation-flow
    provides: Timeline row-link and browser-proof patterns reused by Coverage.
provides:
  - Selected-schema Coverage readiness verdict before table triage.
  - Native schema URL-state selector with invalid-schema recovery and stale refresh handling.
  - Narrow browser proof for Coverage mobile readability, focus, disclosure/copy layout, and public Timeline links.
affects: [operator-surface, coverage, docs, example-browser-proof]
tech-stack:
  added: []
  patterns:
    - Private CoverageLive verdict helpers derive readiness from existing Snapshot fields.
    - Browser proof stays narrow and behavior-focused rather than screenshot-baseline based.
key-files:
  created:
    - examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts
    - .planning/phases/185-coverage-and-audit-readiness/185-VERIFICATION.md
    - .planning/phases/185-coverage-and-audit-readiness/185-01-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/coverage_live.ex
    - lib/threadline/operator_surface/style.ex
    - test/threadline/operator_surface/live/coverage_live_test.exs
    - test/threadline/operator_surface/coverage_doc_contract_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
    - test/threadline/operator_surface/copy_contract_test.exs
    - examples/threadline_phoenix/e2e/playwright.config.ts
    - examples/threadline_phoenix/e2e/tests/operator-features.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
    - guides/operator-surface.md
    - guides/production-checklist.md
key-decisions:
  - "Coverage now answers readiness through one selected-schema verdict and keeps table rows as triage/action detail."
  - "Invalid schemas preserve rejected copy and recovery affordance without rendering stale public rows as selected-schema truth."
  - "Phase 185 browser proof is a narrow behavior spec admitted to the existing light/system lane, with no screenshot baseline expansion."
patterns-established:
  - "Coverage verdict pattern: one region after UI.page_header, with counts, checked metadata, and one schema-level next step."
  - "Coverage browser proof pattern: viewport/focus/disclosure/link checks in Playwright, with non-public schema truth owned by LiveViewTest."
requirements-completed: [COV-01, COV-02, COV-03]
duration: 19m
completed: 2026-06-29
status: complete
---

# Phase 185 Plan 01: Coverage Selected-Schema Readiness Summary

**Selected-schema Coverage readiness verdict with native schema URL state, stale/invalid safety, docs, and narrow browser proof.**

## Performance

- **Duration:** 19 min
- **Started:** 2026-06-29T20:04:14Z
- **Completed:** 2026-06-29T20:23:02Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments

- Replaced the old Coverage trust rail, metric tiles, and standalone remediation block with one `Selected schema readiness` region before `[data-testid="coverage-table"]`.
- Added/tightened LiveView, style, docs, and copy contracts for native schema selection, invalid schema recovery, stale refresh, expected-gap rows, row Add capture actions, and public/non-public Timeline links.
- Added `operator-coverage-readiness.spec.ts` and admitted it to the existing light/system Playwright lane for viewport, focus, disclosure/copy, and public-link proof.
- Created `185-VERIFICATION.md` with command evidence, decision coverage, threat evidence, and residual classification.

## Task Commits

1. **Task 1: Lock Coverage readiness, schema, and remediation contracts** - `a490dd50` (`test`)
2. **Task 2: Implement the selected-schema verdict and docs-aligned Coverage flow** - `36086b9a` (`feat`)
3. **Task 3: Add narrow Coverage browser proof and verification closeout** - `62f3f5a6` (`test`)

## Files Created/Modified

- `lib/threadline/operator_surface/live/coverage_live.ex` - selected-schema verdict, native schema select, invalid recovery, and stale refresh preservation.
- `lib/threadline/operator_surface/style.ex` - new `.tl-coverage-verdict*` styling and retired Coverage trust-rail/page-remediation CSS.
- `test/threadline/operator_surface/live/coverage_live_test.exs` - rendered state lattice and row-action/link behavior contracts.
- `test/threadline/operator_surface/coverage_doc_contract_test.exs` - source/docs contracts for selected-schema readiness.
- `test/threadline/operator_surface/style_contract_test.exs` - CSS source contract for the verdict unit and retired structures.
- `test/threadline/operator_surface/copy_contract_test.exs` - Coverage primary copy overclaim guard.
- `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts` - narrow browser proof for Coverage readiness.
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` - responsive matrix retargeted to the verdict region.
- `examples/threadline_phoenix/e2e/tests/operator-features.spec.ts` - Coverage smoke now asserts the selected-schema region and schema control.
- `examples/threadline_phoenix/e2e/playwright.config.ts` - new Coverage spec admitted to the light/system lane.
- `guides/operator-surface.md` - Coverage docs rewritten around audit readiness, schema recovery, stale refresh, row actions, and verifier commands.
- `guides/production-checklist.md` - production checklist updated from dashboard language to selected-schema readiness language.
- `.planning/phases/185-coverage-and-audit-readiness/185-VERIFICATION.md` - Phase 185 command and residual evidence.

## Verification

- `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/copy_contract_test.exs` - expected RED before implementation: 108 tests, 12 failures.
- `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/coverage/on_mount_test.exs` - PASS, 111 tests.
- `mix format --check-formatted ...` for the targeted source/test files - PASS.
- `mix verify.format` - PASS.
- `mix verify.credo` - PASS, 230 files checked, 0 issues.
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-coverage-readiness.spec.ts` - PASS, 21 Playwright tests.
- `mix verify.example_browser_light tests/operator-coverage-readiness.spec.ts` - PASS, 7 Playwright tests.
- `mix test test/threadline/operator_surface/formless_pages_test.exs` - PASS, 6 tests after updating the stale display-only guard to exclude Coverage's Phase 185 native schema selector form.
- `mix verify.test` - NON-GREEN residual after the guard repair: 1157 tests, 2 inherited failures in `V123CharterDocContractTest` and `ExportsDocContractTest`, neither Coverage readiness.
- `cd examples/threadline_phoenix && mix precommit` - NON-GREEN residual: 109 tests, 7 failures in existing demo seed/audit-history expectations, classified in `185-VERIFICATION.md`.

## Decisions Made

- Kept `Presentation.coverage_remediation/2` unchanged because existing conservative command/follow-up behavior already satisfied Phase 185 contracts.
- Kept non-public browser proof out of Playwright because no deterministic example fixture existed; LiveViewTest owns non-public schema setup and link assertions.
- Removed retired Timeline-incompleteness wording from Coverage primary copy after the copy contract caught the conflict.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test Contract Conflict] Removed retired Timeline framing from the Coverage row-action assertion**
- **Found during:** Task 2
- **Issue:** A tightened LiveView assertion still expected `Timeline results may be incomplete for these tables` / `rerun the timeline search`, while the copy contract explicitly forbids that retired Coverage framing.
- **Fix:** Updated the assertion and implementation copy to use the Phase 185 verdict next step: fix Needs capture rows, apply the migration, run verifier, refresh readiness.
- **Files modified:** `test/threadline/operator_surface/live/coverage_live_test.exs`, `lib/threadline/operator_surface/live/coverage_live.ex`
- **Verification:** Targeted Mix slice passed with 111 tests, 0 failures.
- **Committed in:** `36086b9a`

**2. [Post-merge gate] Updated stale display-only guard for Coverage's native schema selector**
- **Found during:** Orchestrator post-merge `mix verify.test`
- **Issue:** `FormlessPagesTest` still listed `coverage_live` as a display-only page even though Phase 185 intentionally added a native schema selector form for `/audit/coverage?schema=NAME`.
- **Fix:** Removed `coverage_live` from the formless page list and documented the Phase 185 exception.
- **Files modified:** `test/threadline/operator_surface/formless_pages_test.exs`
- **Verification:** `mix test test/threadline/operator_surface/formless_pages_test.exs` passed; `mix verify.test` no longer reports the Coverage formless failure.
- **Committed in:** `067c0c11`

**Total deviations after post-merge:** 2 auto-fixed issues.
**Impact on plan:** The fixes aligned tests and implementation with COV-02 copy posture and Phase 185's native schema selector contract; no scope or boundary expansion.

## Issues Encountered

- `mix verify.test` remains non-green with two inherited residuals: stale v1.37 PROJECT.md charter posture text and Timeline export `download` attribute source-contract drift. The Phase 185 Coverage formless guard failure found by the first post-merge run was fixed in `067c0c11`.
- `cd examples/threadline_phoenix && mix precommit` remains non-green due to inherited demo seed/audit-history residuals: missing #4521 close transaction evidence, #4518 delete audit rows, leaving-agent audit transactions, and `org_memberships` actor attribution rows. Phase 185 targeted Mix and browser proof passed; residual ownership is recorded in `185-VERIFICATION.md`.

## Known Stubs

None. Stub scan hits were false positives in intentional empty-string/test assertions and existing redaction-placeholder documentation, not UI data stubs.

## Auth Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 186 can reuse the single-verdict-plus-row-actions pattern for remaining readiness/governance pages. The only residual is the pre-existing example demo seed/audit-history test drift documented in `185-VERIFICATION.md`; it does not block the Coverage UI contract.

## Self-Check: PASSED

- Found all created/modified plan files, including `operator-coverage-readiness.spec.ts`, `185-VERIFICATION.md`, and this summary.
- Found task commits `a490dd50`, `36086b9a`, and `62f3f5a6` in git history.
- Post-commit deletion checks after each task found no accidental tracked-file deletions.
- `.planning/config.json` remains unstaged and untouched except for the pre-existing orchestration auto-chain toggle.

---
*Phase: 185-coverage-and-audit-readiness*
*Completed: 2026-06-29*
