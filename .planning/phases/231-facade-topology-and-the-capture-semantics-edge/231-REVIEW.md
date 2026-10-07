---
phase: 231-facade-topology-and-the-capture-semantics-edge
reviewed: 2026-10-07T12:12:52Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - CHANGELOG.md
  - examples/threadline_phoenix/priv/scripts/incident_replay.exs
  - guides/audit-indexing.md
  - guides/code-walkthrough.md
  - guides/domain-reference.md
  - guides/how-threadline-works.md
  - guides/production-checklist.md
  - lib/threadline.ex
  - lib/threadline/audit.ex
  - lib/threadline/capture/audit_transaction.ex
  - lib/threadline/export.ex
  - lib/threadline/investigation.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/query.ex
  - lib/threadline/query/action_hydration.ex
  - lib/threadline/retention.ex
  - lib/threadline/semantics/audit_action.ex
  - mix.exs
  - test/threadline/capture_semantics_boundary_test.exs
  - test/threadline/facade_only_references_contract_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/query/action_hydration_test.exs
  - test/threadline/query_test.exs
  - examples/threadline_phoenix/lib/threadline_phoenix/incident_replay_safety.ex
  - examples/threadline_phoenix/test/threadline_phoenix/incident_replay_safety_test.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 231: Code Review Report

**Reviewed:** 2026-10-07T12:12:52Z
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

Re-reviewed the 25 Phase 231 key files and the two incident-replay safety files. Commit `b8e77ebb` fixes the disposable-database check by accepting only the exact example development database or anchored test-partition names; the script now delegates to that guard before any scenario can mutate data. The walkthrough now correctly documents `action_id` and the virtual hydrated `action` field without claiming that the removed Ecto associations can be preloaded. One advisory remains: malformed non-nil actor references still pass `Threadline.Audit` validation and can crash the transaction callback.

## Narrative Findings (AI reviewer)

### Warnings

#### WR-01: Invalid actor references crash instead of returning a validation error

**Classification:** WARNING
**File:** `lib/threadline/audit.ex:209-220`
**Issue:** `validate_actor/1` handles nil actors but its catch-all returns `:ok` for every other value. A non-nil value that is not an `%ActorRef{}` therefore reaches `set_actor_guc!/2`, whose only clauses accept `%ActorRef{}` or `nil`, and raises `FunctionClauseError` inside `repo.transaction/1`. Invalid caller input becomes a transaction crash instead of the controlled validation error this API otherwise returns.
**Fix:** Validate the actor shape before opening the transaction: accept `%ActorRef{}`, preserve the nil policy, and return `{:error, :invalid_actor_ref}` for other values.

---

_Reviewed: 2026-10-07T12:12:52Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
