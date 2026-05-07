---
phase: 67
plan: 04
subsystem: redaction-doc-contract-and-adoption
tags:
  - elixir
  - threadline
  - docs
  - policy
  - redaction
  - doc-contract
requires:
  - 67-01
  - 67-02
  - 67-03
provides:
  - "Phase 67 doc-contract coverage for route, status, JSON, parity, and no-sample-values literals"
  - "Operator and adopter docs for /audit/policy/redaction and mix threadline.policy.show"
affects:
  - "Phase 67 CI drift visibility through policy_show_doc_contract_test.exs"
  - "README, guides, and changelog discoverability for the shipped policy redaction surface"
tech-stack:
  added: []
  patterns:
    - "Pure source-reading doc-contract test with one runtime JSON shape assertion"
    - "Cross-doc literal alignment around /audit/policy/redaction and mix threadline.policy.show"
key-files:
  created:
    - "test/threadline/operator_surface/policy_show_doc_contract_test.exs"
    - ".planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-04-SUMMARY.md"
  modified:
    - "guides/operator-surface.md"
    - "guides/domain-reference.md"
    - "guides/production-checklist.md"
    - "README.md"
    - "CHANGELOG.md"
decisions:
  - "Pinned the rerun guidance at the shared presenter layer because the LiveView and Mix task both render row.hint instead of duplicating literals."
  - "Kept the doc-contract test source-reading-first and limited runtime execution to the stable --json top-level contract."
  - "Documented the exact mounted path as /audit/policy/redaction while preserving the router literal contract live(\"/policy/redaction\", PolicyRedactionLive, :index)."
metrics:
  duration: ~18 min
  completed: 2026-05-07T23:00:00Z
  tasks: 2
  files: 7
  tests_added: 11
---

# Phase 67 Plan 04: Policy Surface Doc Contract and Adoption Summary

Plan 67-04 closes the Phase 67 adoption loop in two parts. First, `test/threadline/operator_surface/policy_show_doc_contract_test.exs` now locks the redaction policy surface contract in CI: the router literal, human status labels, JSON status enums, rerun guidance, drift-first ordering, Mix/LiveView parity columns, optional-Phoenix gating posture, and no-sample-values invariants. The test stays primarily source-reading and uses one runtime `--json` assertion to pin the stable machine contract.

Second, the operator-facing docs now describe the shipped surface directly. `guides/operator-surface.md`, `guides/domain-reference.md`, `guides/production-checklist.md`, `README.md`, and `CHANGELOG.md` all mention `/audit/policy/redaction` and `mix threadline.policy.show`, explain the three states `Config matches deployed`, `Drift detected`, and `Could not introspect`, instruct operators to rerun `mix threadline.gen.triggers` and apply the migration when drift or introspection failures appear, and state that the UI/task never show sample values.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test Contract] Corrected the doc-contract test to follow the shipped Phase 67 architecture**
- **Found during:** Task 1 RED verification
- **Issue:** The initial failing test incorrectly expected the rerun literal inside LiveView/Mix source and used `String.index/2`, which is unavailable in the current Elixir runtime.
- **Fix:** Pointed the rerun-literal assertion at the shared presenter, asserted that Mix renders `row.hint`, and replaced `String.index/2` with a byte-index helper.
- **Files modified:** `test/threadline/operator_surface/policy_show_doc_contract_test.exs`
- **Verification:** `mix test test/threadline/operator_surface/policy_show_doc_contract_test.exs`
- **Commit:** `5404e0c`

**Total deviations:** 1 auto-fixed (`Rule 1`: 1). **Impact:** the final contract test now matches the actual shared-presenter architecture from Plans 67-01 through 67-03.

## Verification

| Command | Result |
| --- | --- |
| `mix test test/threadline/operator_surface/policy_show_doc_contract_test.exs` | passed (11 tests, 0 failures) |
| `rg -n "/audit/policy/redaction|mix threadline.policy.show|Config matches deployed|Drift detected|Could not introspect|never show sample values|never renders captured sample values" guides/operator-surface.md guides/domain-reference.md guides/production-checklist.md README.md CHANGELOG.md` | matched all updated docs and changelog literals |

## Tasks → Commits

| Task | Commit | Notes |
| --- | --- | --- |
| Task 1 (RED) | `4efc22c` | Added the initial failing Phase 67 policy doc-contract test |
| Task 1 (GREEN) | `5404e0c` | Locked the final route/status/JSON/parity/no-sample-values contract |
| Task 2 | `96fcfbf` | Updated guides, README, and changelog for the shipped policy drift surface |

## Known Stubs

None.

## Self-Check: PASSED

- `test/threadline/operator_surface/policy_show_doc_contract_test.exs` exists.
- `guides/operator-surface.md` exists.
- `guides/domain-reference.md` exists.
- `guides/production-checklist.md` exists.
- `README.md` exists.
- `CHANGELOG.md` exists.
- Commits `4efc22c`, `5404e0c`, and `96fcfbf` exist in git history.
