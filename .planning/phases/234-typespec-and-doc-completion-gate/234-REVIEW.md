---
phase: 234-typespec-and-doc-completion-gate
reviewed: 2026-10-05T16:00:36Z
depth: standard
files_reviewed: 65
files_reviewed_list:
  - CHANGELOG.md
  - CONTRIBUTING.md
  - guides/code-walkthrough.md
  - guides/integration-contracts.md
  - lib/mix/tasks/threadline.gen.row_history_index.ex
  - lib/mix/tasks/threadline.incident.ex
  - lib/mix/tasks/threadline.install.ex
  - lib/threadline.ex
  - lib/threadline/audit.ex
  - lib/threadline/capture/audit_change.ex
  - lib/threadline/capture/audit_transaction.ex
  - lib/threadline/change_diff.ex
  - lib/threadline/continuity.ex
  - lib/threadline/critic_trust/ledger_splice.ex
  - lib/threadline/evidence.ex
  - lib/threadline/evidence/proof.ex
  - lib/threadline/evidence/subject.ex
  - lib/threadline/export.ex
  - lib/threadline/export/orchestrator.ex
  - lib/threadline/export_queue.ex
  - lib/threadline/export_queue/task_adapter.ex
  - lib/threadline/governance/evidence_record.ex
  - lib/threadline/health.ex
  - lib/threadline/health/finding.ex
  - lib/threadline/health/legacy_key_findings.ex
  - lib/threadline/health/policy.ex
  - lib/threadline/health/trigger_findings.ex
  - lib/threadline/integrations/sigra.ex
  - lib/threadline/investigation.ex
  - lib/threadline/investigation/incident_bundle.ex
  - lib/threadline/investigation/linked_change.ex
  - lib/threadline/job.ex
  - lib/threadline/not_found_error.ex
  - lib/threadline/operator_surface/auth.ex
  - lib/threadline/operator_surface/controllers/export_controller.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/row_history_component.ex
  - lib/threadline/operator_surface/live/stress_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/presentation.ex
  - lib/threadline/operator_surface/router.ex
  - lib/threadline/page.ex
  - lib/threadline/query.ex
  - lib/threadline/query/cursors.ex
  - lib/threadline/query/export_reads.ex
  - lib/threadline/query/option_keys.ex
  - lib/threadline/query/transaction_lookup.ex
  - lib/threadline/retention.ex
  - lib/threadline/retention/policy.ex
  - lib/threadline/semantics/actor_ref.ex
  - lib/threadline/semantics/audit_action.ex
  - lib/threadline/semantics/audit_context.ex
  - lib/threadline/storage.ex
  - lib/threadline/storage/s3.ex
  - lib/threadline/storage_schema.ex
  - lib/threadline/telemetry.ex
  - lib/threadline/verify/coverage_policy.ex
  - mix.exs
  - test/partition_weights.txt
  - test/support/doc_contract.ex
  - test/threadline/dialyzer_ignore_contract_test.exs
  - test/threadline/doc_rubric_contract_test.exs
  - test/threadline/doc_spec_coverage_contract_test.exs
  - test/threadline/facade_naming_contract_test.exs
  - test/threadline/operator_surface/exports_doc_contract_test.exs
  - test/threadline/operator_surface/timeline_browse_doc_contract_test.exs
  - test/threadline/option_allowlist_test.exs
  - test/threadline/source_size_contract_test.exs
  - test/threadline/transaction_lookup_test.exs
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 234: Code Review Report

**Reviewed:** 2026-10-05T16:00:36Z  
**Depth:** standard  
**Files Reviewed:** 65  
**Status:** issues_found

## Summary

Reviewed the Phase 234 source scope derived from plans 01–06 and cross-checked it against the phase diff. The runtime changes and test-only contract walkers reviewed did not reveal a confirmed behavioral or security defect. Three newly added typespecs misstate concrete values that the implementation returns or accepts, weakening the published contracts and potentially producing incorrect downstream Dialyzer conclusions.

## Warnings

### WR-01: Actor map type does not require its documented `type` key

**Classification:** WARNING  
**File:** `lib/threadline/semantics/actor_ref.ex:31`  
**Issue:** `actor_map()` is documented as requiring a string `"type"` key, but `%{optional(String.t()) => String.t() | nil}` permits an empty map and arbitrary string keys. `to_map/1` always emits `"type"` and emits `"id"` for non-anonymous actors, so consumers lose the discriminator guarantee in the return contract.  
**Fix:** Describe the actual variants, for example `@type actor_map :: %{"type" => String.t(), optional("id") => String.t()}` (or an equivalent union that distinguishes anonymous from identified actors).

### WR-02: Hydrated transaction action is typed as any struct

**Classification:** WARNING  
**File:** `lib/threadline/capture/audit_transaction.ex:63`  
**Issue:** `ActionHydration` loads `Threadline.Semantics.AuditAction` into the virtual `:action` field, but the new `AuditTransaction.t()` uses `struct() | nil`. This allows unrelated structs in the public schema type and defeats the precise result shape available at the hydration boundary.  
**Fix:** Narrow the field to `Threadline.Semantics.AuditAction.t() | nil`.

### WR-03: Export projection type excludes nullable transaction source

**Classification:** WARNING  
**File:** `lib/threadline/export.ex:86`  
**Issue:** `export_row.tx_source` is declared as `String.t()`, while the selected value is `audit_transactions.source`, whose database column is nullable (`priv/repo/migrations/20260101000000_threadline_audit_schema.exs:12`) and whose schema type is `String.t() | nil`. Rows from older or host-created transactions can therefore contain `nil`, contrary to this export-row type.  
**Fix:** Declare `tx_source: String.t() | nil` and keep the encoder's existing nil-compatible behavior.

---

_Reviewed: 2026-10-05T16:00:36Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
