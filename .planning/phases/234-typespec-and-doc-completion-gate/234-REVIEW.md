---
phase: 234-typespec-and-doc-completion-gate
reviewed: 2026-10-06T16:19:10Z
depth: standard
files_reviewed: 75
files_reviewed_list:
  - CHANGELOG.md
  - CONTRIBUTING.md
  - examples/threadline_phoenix/mix.exs
  - guides/code-walkthrough.md
  - guides/integration-contracts.md
  - lib/mix/tasks/critic.measure.ex
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
  - test/threadline/cloak_advisory_reachability_contract_test.exs
  - test/threadline/dialyzer_ignore_contract_test.exs
  - test/threadline/doc_rubric_contract_test.exs
  - test/threadline/doc_spec_coverage_contract_test.exs
  - test/threadline/evidence/subject_test.exs
  - test/threadline/facade_naming_contract_test.exs
  - test/threadline/operator_surface/critic_trust_test.exs
  - test/threadline/option_allowlist_test.exs
  - test/threadline/retention/policy_test.exs
  - test/threadline/semantics/actor_ref_test.exs
  - test/threadline/source_size_contract_test.exs
  - test/threadline/transaction_lookup_test.exs
findings:
  critical: 0
  warning: 4
  info: 0
  total: 4
status: issues_found
---

# Phase 234: Code Review Report

**Reviewed:** 2026-10-06T16:19:10Z  
**Depth:** standard  
**Files Reviewed:** 75  
**Status:** issues_found

## Summary

The review found four warnings involving a broken API example, a previously documented row-history scope option that now fails validation, missing failure telemetry for rejected eager-export inputs, and a false validation claim in the job-context documentation.

## Narrative Findings (AI reviewer)

### Warnings

#### WR-01: The `record_action/2` example constructs an invalid ActorRef

**File:** `lib/threadline.ex:293`  
**Issue:** The example sets `ActorRef.type` to the string `"user"`, while the supported type is the atom `:user`. `record_action/2` accepts the struct without validating its fields; encoding the malformed struct later calls `Atom.to_string/1` with a binary and fails. An adopter copying the documented example cannot successfully record the action.  
**Fix:** Construct the reference through the validated API, for example `{:ok, actor} = ActorRef.new(:user, "u-42")`, then pass `actor` as `:actor`.

#### WR-02: Row history rejects its formerly documented `:surface` scope option

**File:** `lib/threadline/query/option_keys.ex:5-15`  
**Issue:** The new `:row_history` allowlist omits `:surface`, so `Threadline.row_history/3` now raises `ArgumentError` for an option that the prior integration contract explicitly supported for distinguishing scope callback contexts. `Query.row_history_scope_opts/3` still reads that key, but public validation makes the override unreachable. The changelog lists removed `:surface` options for other query APIs but omits row history, leaving existing adopters without a notice of this breaking change.  
**Fix:** Preserve `:surface` in the row-history allowlist if the override remains supported. If it is intentionally removed, add an explicit breaking-change entry to `CHANGELOG.md` and explain that custom row-history surface names no longer work.

#### WR-03: Eager export validation failures skip the documented failure event

**File:** `lib/threadline/export.ex:151-153`  
**Issue:** `OptionKeys.validate!/2` runs before control enters `ExportReads.to_csv_iodata/2`'s rescue block. The facade also validates filter keys before calling this function. Therefore, unknown option or filter keys raise without emitting `[:threadline, :export, :failed]`, even though the telemetry contract says this event fires when an eager CSV/JSON export fails. This makes input failures invisible to subscribers.  
**Fix:** Route eager-export validation through the same monitored failure path, or emit the failure event when these validations raise, while preserving the original exception.

#### WR-04: `Threadline.Job.context_opts/2` claims unknown options are validated

**File:** `lib/threadline/job.ex:97`  
**Issue:** The documentation says other keys are retained and validated by `record_action/2`, but that function only reads the known keys in `build_attrs/3` and silently drops the rest. A typo in `extra` is therefore not detected, and the `context_opts_result()` spec also excludes arbitrary retained options.  
**Fix:** Either reject unknown keys in `record_action/2` and update its input/result types, or document that extra keys are passed through and may be ignored.

---

_Reviewed: 2026-10-06T16:19:10Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
