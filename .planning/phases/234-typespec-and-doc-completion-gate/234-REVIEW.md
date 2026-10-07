---
phase: 234-typespec-and-doc-completion-gate
reviewed: 2026-10-06T19:34:36Z
depth: standard
files_reviewed: 68
files_reviewed_list:
  - examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts
  - examples/threadline_phoenix/mix.exs
  - lib/mix/tasks/critic.measure.ex
  - lib/threadline.ex
  - lib/threadline/audit.ex
  - lib/threadline/capture/audit_change.ex
  - lib/threadline/capture/audit_transaction.ex
  - lib/threadline/change_diff.ex
  - lib/threadline/continuity.ex
  - lib/threadline/critic_trust/ledger_splice.ex
  - lib/threadline/critic_trust/repository_boundary.ex
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
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/row_history_component.ex
  - lib/threadline/operator_surface/live/stress_live.ex
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
  - lib/threadline/storage_schema.ex
  - lib/threadline/telemetry.ex
  - lib/threadline/verify/coverage_policy.ex
  - mix.exs
  - test/support/doc_contract.ex
  - test/threadline/capture_semantics_boundary_test.exs
  - test/threadline/cloak_advisory_reachability_contract_test.exs
  - test/threadline/dialyzer_ignore_contract_test.exs
  - test/threadline/doc_rubric_contract_test.exs
  - test/threadline/doc_spec_coverage_contract_test.exs
  - test/threadline/evidence/subject_test.exs
  - test/threadline/facade_naming_contract_test.exs
  - test/threadline/job_test.exs
  - test/threadline/operator_surface/critic_trust_test.exs
  - test/threadline/option_allowlist_test.exs
  - test/threadline/retention/policy_test.exs
  - test/threadline/semantics/actor_ref_test.exs
  - test/threadline/semantics/audit_action_test.exs
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

**Reviewed:** 2026-10-06T19:34:36Z  
**Depth:** standard  
**Files Reviewed:** 68  
**Status:** issues_found

## Summary

The Phase 234 source and test scope was reviewed, including the Plan 20 public typespec and documentation boundary and the Plan 21 reduced-motion browser interaction. Three warnings remain: the Threadline.Job.context_opts/2 public typespec does not describe the values its implementation returns, and eager export validation can raise before failure telemetry is emitted.

## Narrative Findings (AI reviewer)

### Warnings

#### WR-01 [WARNING]: context_opts/2 returns options excluded by its public type

**File:** lib/threadline/job.ex:49-55,109-116  
**Issue:** The documented behavior and implementation retain unknown extra entries, but context_opt() only permits record_action_opt() and correlation/job IDs, and context_opts_result() is limited to that union. The test passes tenant_id: "tenant-1" and asserts it is retained (test/threadline/job_test.exs:53-58), so this supported result is outside the declared spec. This gives callers and Dialyzer an incorrect contract for a public helper.  
**Fix:** Either stop retaining keys outside context_opt() (and update the docs/test) or widen the input and result types to represent retained keyword entries, for example with a separate {atom(), term()} extra-option type.

#### WR-02 [WARNING]: Job context IDs are returned without the type promised by the spec

**File:** lib/threadline/job.ex:38-55,109-116  
**Issue:** job_args() accepts any JSON-compatible value for every key, while context_opts/2 copies "correlation_id" and "job_id" directly into the result. For example, %{"job_id" => 42} returns [correlation_id: nil, job_id: 42], although the advertised result requires String.t() | nil. Passing that value into record_action/2 reaches Ecto casting and returns a changeset error rather than a valid context option. The public typespec therefore cannot be relied on at this boundary.  
**Fix:** Validate or normalize extracted IDs to strings (or omit/reject invalid values), and add input clauses/tests for non-string JSON values; alternatively, accurately widen the input/result types and document the downstream validation behavior.

#### WR-03 [WARNING]: Eager export validation raises without emitting the failure event

**File:** lib/threadline.ex:1239-1243,1292-1296; lib/threadline/export.ex:151-154,195-198  
**Issue:** The facade validates filters and options before calling Threadline.Export, and the direct eager export wrappers validate options before entering ExportReads' rescue-and-telemetry path. An unknown filter or option therefore raises ArgumentError without emitting [:threadline, :export, :failed], even though the telemetry helper documents that event for a logical export failure. Failures caused by validation are invisible to telemetry subscribers.  
**Fix:** Start the eager export failure boundary before these validations and emit the failure event on validation exceptions, preserving the original exception and ensuring exactly one event.

---

_Reviewed: 2026-10-06T19:34:36Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
