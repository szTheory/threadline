---
phase: 73
plan: "73-02"
subsystem: docs
tags:
  - docs
  - example-app
  - contract-tests
provides:
  - COMPAT-02
  - COMPAT-03
  - ADOPT-09
  - ADOPT-08
key_files:
  created:
    - .planning/phases/73-authorization-contract-repair-and-scoped-access-enforcement/73-02-SUMMARY.md
  modified:
    - guides/operator-surface.md
    - guides/integration-contracts.md
    - guides/getting-started-saas.md
    - guides/integrations/sigra.md
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
    - examples/threadline_phoenix/README.md
    - test/threadline/operator_surface_doc_contract_test.exs
    - test/threadline/integration_contracts_doc_contract_test.exs
    - test/threadline/getting_started_saas_doc_contract_test.exs
    - test/threadline/integrations/sigra_doc_contract_test.exs
    - test/threadline/example_phoenix_readme_contract_test.exs
decisions:
  - Remove the example router's unconditional socket allow path and teach one shared `%{assigns: assigns}` contract everywhere.
  - Name `scope_query_fn` explicitly in the canonical support-read-only recipe rather than implying that assigned scope is enforced magically.
  - Keep `export_authorize_fn` documented as an advanced override and `exports: false` as the default support posture.
---

# Phase 73 Plan 73-02 Summary

Repaired the canonical docs and example contract around the new scoped-access
seam so the public runbook and runnable reference path now match the enforced
behavior.

## Completed Tasks

| Task | Outcome |
| --- | --- |
| 1 | Updated the guides, example router, and example README to teach one shared `authorize_fn`, name `scope_query_fn`, preserve `exports: false` as the support default, and keep Threadline auth-agnostic. |
| 2 | Extended the focused doc-contract suite so future drift in the example router, support-read-only wording, or host-owned scope story fails immediately. |

## Verification

- `mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1`
  Result: passed (`26 tests, 0 failures`).

## Deviations from Plan

None. The slice executed as planned.

## Self-Check

PASSED

