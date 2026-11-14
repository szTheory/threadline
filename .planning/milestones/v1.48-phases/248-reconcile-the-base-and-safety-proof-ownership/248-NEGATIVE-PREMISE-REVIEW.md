---
phase: 248-negative-fixture-premise
reviewed: 2026-11-11T19:54:29Z
depth: standard
files_reviewed: 33
files_reviewed_list:
  - .github/workflows/flake-detection.yml
  - AGENTS.md
  - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
  - guides/code-walkthrough.md
  - guides/integration-contracts.md
  - guides/operator-surface.md
  - lib/threadline/operator_surface/router.ex
  - release-please-config.json
  - test/threadline/browser_journey_evidence_contract_test.exs
  - test/threadline/code_walkthrough_doc_contract_test.exs
  - test/threadline/formatter_topology_contract_test.exs
  - test/threadline/operator_surface/breadcrumb_test.exs
  - test/threadline/operator_surface/card_nesting_regression_test.exs
  - test/threadline/operator_surface/controllers/export_controller_test.exs
  - test/threadline/operator_surface/copy_contract_test.exs
  - test/threadline/operator_surface/exports_mix_parity_test.exs
  - test/threadline/operator_surface/gating_test.exs
  - test/threadline/operator_surface/live/actor_live_test.exs
  - test/threadline/operator_surface/live/coverage_live_test.exs
  - test/threadline/operator_surface/live/evidence_live_test.exs
  - test/threadline/operator_surface/live/policy_redaction_live_test.exs
  - test/threadline/operator_surface/live/retention_history_live_test.exs
  - test/threadline/operator_surface/live/row_history_live_test.exs
  - test/threadline/operator_surface/live/start_live_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
  - test/threadline/operator_surface/rendered_output_contract_test.exs
  - test/threadline/operator_surface/router_test.exs
  - test/threadline/operator_surface/skip_link_test.exs
  - test/threadline/operator_surface/transaction_live_test.exs
  - test/threadline/operator_surface_doc_contract_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/repo_contract_scope_contract_test.exs
  - test/threadline/storage_schema_call_site_contract_test.exs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
  necessity: 0
status: clean
---

# Phase 248: Code Review Report

**Reviewed:** 2026-11-11T19:54:29Z  
**Depth:** standard  
**Files Reviewed:** 33  
**Status:** clean

## Summary

Reviewed source commit `9b695ca25b41be882902ddfb06716141e5a462db`. Thirty-two files match the prior review input byte-for-byte; the changed `repo_contract_scope_contract_test.exs` was read in full and compared with both the original `10442d31a8c7df50111effe1614c99bf5e7e87ee` behavior and the intermediate `eaedaf5e1a92c9fd797f37fefaffad14b5376e8e` version. All 33 source hashes match the new input manifest. No active findings remain in this bounded recheck.

The earlier clean review at `the private intermediate file-pressure review` is superseded: its assertion that negative-fixture coverage was preserved missed the missing tag premise in `eaedaf5`. The reported `WR-02` premise defect is resolved in the current source, as detailed below. No tests were run in this review, and this report does not make a test-pass claim.

## Prior Finding Disposition

### WR-02: Negative fixture bodies were untagged at the detector boundary — resolved

**Severity:** WARNING (historical; resolved)  
**File:** `test/threadline/repo_contract_scope_contract_test.exs:633-635`  
**Issue:** In `eaedaf5`, the helper had changed to accept full source while the nine benign fixture bodies were still passed raw. `dodging_offenders/2` filters on `tagged?(source)` at line 445, so those negative assertions did not evaluate the detector for the intended tagged-file case.  
**Resolution:** The loop now constructs `source = tagged_source(body)`, asserts `tagged?(source)`, then refutes `flagged?(source, modules)`. This makes the detector’s precondition explicit for each fixture and prevents a missing wrapper from silently making the check vacuous.

## Narrative Findings (AI reviewer)

No active findings.

### Coverage checks confirmed

- All 13 positive bodies still call `flagged?(tagged_source(body), modules)`; their fixture strings and failure messages are unchanged.
- All nine benign negative bodies are wrapped once with `tagged_source/1`, have an explicit tagged-source premise assertion, and are passed as complete source to `flagged?/2`. Their fixture strings and negative classification are unchanged.
- `flagged?/2` forwards the supplied source unchanged to `dodging_offenders/2`; it does not wrap again.
- The intentional untagged and near-miss controls remain raw full-source controls and call the helper without an explicit module list, so each retains a fresh default inventory.
- The two fixture loops each compute one library-module inventory for reuse only within that test. There is no cross-test cache.
- The tag filter in `dodging_offenders/2` remains in place, so the new premise assertions exercise the real gate.

---

_Reviewed: 2026-11-11T19:54:29Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
