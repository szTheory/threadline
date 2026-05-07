---
phase: 68
plan: 01
subsystem: docs
tags:
  - onboarding
  - operator-surface
  - doc-contract
requires: []
provides:
  - ADOPT-05 canonical mounted onboarding flow
affects:
  - README.md
  - guides/getting-started-saas.md
  - examples/threadline_phoenix/README.md
  - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
  - test/threadline/getting_started_saas_doc_contract_test.exs
  - test/threadline/readme_doc_contract_test.exs
  - test/threadline/example_phoenix_readme_contract_test.exs
tech_stack:
  added: []
  patterns:
    - router-backed snippet extraction
    - doc-contract source assertions
decisions:
  - Kept `guides/getting-started-saas.md` as the one canonical first-hour flow and extended it through `/audit`.
  - Kept `README.md` as a short entry map with a one-minute mount pointer instead of a second walkthrough.
  - Anchored the example router mount block and reused it in doc contracts to prevent drift.
metrics:
  started_at: 2026-05-07T21:08:04Z
  completed_at: 2026-05-07T21:08:44Z
---

# Phase 68 Plan 01: Mounted Onboarding Summary

Canonical first-hour onboarding now reaches the shipped operator surface at `/audit`, while the root README stays a short map and the Phoenix example README remains the runnable reference contract.

## Completed Tasks

| Task | Result | Commit |
| ---- | ------ | ------ |
| 1 | Rewrote the canonical guide, README pointer, example README, and router-backed mount snippet around the mounted operator surface path. | `a70d232` |
| 2 | Extended the doc-contract suites to lock the mounted `/audit` story and the router-backed snippet. | `f4978b9` |

## Verification

- `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs`
  Result: PASS, 20 tests, 0 failures.
- `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs`
  Result: PASS, 25 tests, 0 failures.
- `mix verify.example`
  Result: PASS, 19 tests, 0 failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test brittleness] Normalize snippet assertions**
- **Found during:** Task 2 verification
- **Issue:** The new doc-contract assertions compared markdown code blocks with indentation-sensitive raw strings and failed even though the router-backed snippet content matched.
- **Fix:** Switched the three new snippet assertions to whitespace-normalized comparisons while still sourcing the mount block from `GettingStartedFixtures.extract!/2`.
- **Files modified:** `test/threadline/getting_started_saas_doc_contract_test.exs`, `test/threadline/readme_doc_contract_test.exs`, `test/threadline/example_phoenix_readme_contract_test.exs`
- **Verification:** Re-ran both plan test commands successfully.
- **Commit:** `f4978b9`

**Total deviations:** 1 auto-fixed.
**Impact:** Low. The implementation stayed the same; only the test comparison strategy changed to match markdown formatting reality.

## Known Stubs

None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/68-lifecycle-ergonomics/68-01-SUMMARY.md`.
- Commit `a70d232` exists in git history.
- Commit `f4978b9` exists in git history.
