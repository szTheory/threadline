---
phase: 186-detail-governance-and-export-surfaces
plan: 05
subsystem: testing
tags:
  - browser-proof
  - operator-surface
  - accessibility
  - responsive
  - source-contracts
dependency_graph:
  requires:
    - Phase 186 validation lane for targeted operator proof
    - 186-01 detail header and actor route contracts
    - 186-02 evidence and redaction focused-summary contracts
    - 186-03 retention destructive-confirmation contracts
    - 186-04 export download and status contracts
  provides:
    - Targeted browser proof across mobile, accessibility, timeline, earned-flow, feature-gate, and responsive lanes
    - Source contracts for Phase 186 detail, governance, export, and motion surfaces
    - Closeout verification record for dependent Wave 2 source contracts
  affects:
    - examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-features.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
    - test/threadline/operator_surface/copy_contract_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
tech_stack:
  added: []
  patterns:
    - Playwright role/name and existing test-id assertions only
    - ExUnit source-contract tests for LiveView copy, affordances, and motion guardrails
key_files:
  created:
    - .planning/phases/186-detail-governance-and-export-surfaces/186-05-SUMMARY.md
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-features.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
    - test/threadline/operator_surface/copy_contract_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
decisions:
  - Browser proof stays inside existing operator lanes and uses current role/name contracts rather than adding routes, data-testid churn, screenshot matrices, dependencies, or public component API.
  - Source contracts pin Phase 186 behavior through ExUnit string checks because the plan closes governance/export surfaces without changing runtime modules.
requirements-completed:
  - DETAIL-01
  - GOV-01
  - GOV-02
  - GOV-03
metrics:
  started: 2026-06-30T11:42:17Z
  completed: 2026-06-30T12:11:42Z
  duration: 29m25s
  tasks: 3
  files_changed: 9
status: complete
---

# Phase 186 Plan 05: Targeted Browser and Source Contract Closeout Summary

Phase 186 closeout now proves the operator detail, governance, export, accessibility, earned-flow, and responsive surfaces through targeted existing browser lanes plus source contracts for the dependent Wave 2 behavior.

## Task Results

| Task | Name | Commit | Result |
| ---- | ---- | ------ | ------ |
| 1 | Retarget mobile/accessibility/timeline browser lanes | 75f0605e | Updated existing mobile, accessibility, and timeline browser proof for Retention confirmation copy, Exports non-ready labels, detail headers, row-history dialog semantics, and actor route handoffs. |
| 2 | Retarget earned-flow/feature-gate/responsive lanes | 6dd6f2b9 | Updated earned-flow proof to use the filter handoff drawer, added scoped support-user governance/export denial checks, and aligned responsive proof with Phase 186 headers and dense mobile controls. |
| 3 | Add source contracts for Phase 186 surfaces | c3718dd3 | Added ExUnit contracts for detail title distinctions, actor atom safety, focused governance copy, export download/status behavior, and page-local motion guards. |

## What Changed

- `operator-prove-mobile.spec.ts` now verifies current Exports readiness labels and the Retention modal's `Keep retention window` confirmation path.
- `operator-accessibility.spec.ts` now asserts the actual row-history dialog wrapper semantics and captures the Retention prune modal accessibility snapshot.
- `operator-timeline-investigation-flow.spec.ts` now proves Transaction, Row history, and Actor activity detail headers during route handoffs.
- `operator-earned-flows.spec.ts` now exercises EF3 through the visible `Filters and handoff` drawer.
- `operator-features.spec.ts` now keeps copy proof on visible full-reference copy controls and adds support-user governance/export unavailable-state checks.
- `operator-responsive-mobile-first.spec.ts` now verifies Phase 186 detail headers, workflow-summary gaps, dense phone controls, and exact Exports heading behavior.
- `copy_contract_test.exs` now locks Phase 186 detail/governance/export source contracts.
- `style_contract_test.exs` now guards touched Phase 186 page modules from page-local keyframes, `transition: all`, and ungoverned animation libraries.

## Verification

Commands run:

```bash
mix verify.example_browser -- operator-prove-mobile.spec.ts operator-accessibility.spec.ts operator-timeline-investigation-flow.spec.ts
mix verify.example_browser -- operator-earned-flows.spec.ts operator-features.spec.ts operator-responsive-mobile-first.spec.ts
mix format test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs
mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs
mix verify.example_browser -- operator-prove-mobile.spec.ts operator-accessibility.spec.ts operator-timeline-investigation-flow.spec.ts operator-earned-flows.spec.ts operator-features.spec.ts operator-responsive-mobile-first.spec.ts
mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs
```

Results:

- Task 1 browser verification passed: 60 tests, 0 failures.
- Task 2 browser verification passed: 87 tests, 0 failures.
- Task 3 source-contract verification passed: 63 tests, 0 failures.
- Combined plan browser verification passed: 147 tests, 0 failures.
- Final source-contract verification passed: 63 tests, 0 failures.

Note: `mix verify.example_browser` printed an expired local Hex authentication warning and dependency advisory output while resolving unchanged dependencies. The command continued and all verification passed; no authentication gate blocked the plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Repaired stale browser assertions after Wave 1 surface changes**

- **Found during:** Task 1 and Task 2 browser verification
- **Issue:** Existing browser lanes still expected stale labels/selectors such as `Cancel`, `Preparing download`, container-level drawer dialog attributes, hidden EF3 links, and seed-specific correlation copy rows.
- **Fix:** Retargeted assertions to current visible contracts: `Keep retention window`, queued/processing and expired/unavailable status text, actual drawer dialog wrappers, the filter handoff drawer, and visible full-reference copy controls.
- **Files modified:** `operator-prove-mobile.spec.ts`, `operator-accessibility.spec.ts`, `operator-earned-flows.spec.ts`, `operator-features.spec.ts`, `operator-responsive-mobile-first.spec.ts`
- **Verification:** Task-level browser commands and combined 147-test browser proof passed.
- **Committed in:** 75f0605e, 6dd6f2b9

**2. [Rule 1 - Bug] Corrected source-contract literals and export block extraction**

- **Found during:** Task 3 formatting and ExUnit verification
- **Issue:** Initial source-contract strings used delimiter-sensitive `~s(...)` literals and the export actions helper captured the workflow-summary actions block instead of the job action block.
- **Fix:** Switched expected source text to raw pipe sigils where needed and located the export job action block by `Presentation.export_downloadable?(job)`.
- **Files modified:** `test/threadline/operator_surface/copy_contract_test.exs`
- **Verification:** `mix format` and the 63-test source-contract command passed.
- **Committed in:** c3718dd3

---

**Total deviations:** 2 auto-fixed Rule 1 issues.
**Impact on plan:** The fixes were required to make the planned proof target the already-built Phase 186 surfaces. No route churn, screenshot matrix, dependency, data-testid churn, root dependency, or public component API was added.

## Auth Gates

None. The local Hex session warning did not prevent dependency resolution or test execution.

## Known Stubs

None. Stub scan matches were existing test helper assertions/literals only; no placeholder UI or unwired data source was introduced.

## Threat Flags

None. This plan changed tests and `.planning` summary documentation only; it did not introduce runtime network endpoints, auth paths, file access behavior, schema changes, route paths, or dependencies.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/186-detail-governance-and-export-surfaces/186-05-SUMMARY.md`.
- Task commits exist: `75f0605e`, `6dd6f2b9`, `c3718dd3`.
- Final verification commands passed.
- Shared `.planning/STATE.md` and `.planning/ROADMAP.md` were not updated.
