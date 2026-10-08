---
phase: 234-typespec-and-doc-completion-gate
reviewed: 2026-10-06T22:37:36Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - lib/threadline.ex
  - lib/threadline/job.ex
  - lib/threadline/capture/audit_transaction.ex
  - test/threadline/semantics/audit_action_test.exs
  - test/threadline/job_test.exs
  - test/threadline/capture_semantics_boundary_test.exs
  - examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts
  - guides/integration-contracts.md
  - CHANGELOG.md
  - lib/threadline/export.ex
  - test/threadline/export_test.exs
  - test/threadline/source_size_contract_test.exs
  - lib/threadline/telemetry.ex
  - guides/telemetry.md
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 234: Code Review Report

**Reviewed:** 2026-10-06T22:37:36Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Reviewed the Phase 234 Plans 20–22 source, test, example, and documentation scope. The job actor decoder misclassifies a present but malformed actor reference, and the new capture boundary contract test can miss valid grouped aliases.

## Narrative Findings (AI reviewer)

### Warnings

#### WR-01: Present malformed actor references are reported as missing

**Classification:** WARNING
**File:** `lib/threadline/job.ex:78`
**Issue:** When args contain an `"actor_ref"` key whose value is not a map, the catch-all returns `{:error, :missing_actor_ref}`. That result says the key was absent, even though `:invalid_actor_ref_map` is part of `actor_ref_error()` and the documented error set. Callers cannot distinguish malformed serialized input from omitted context and may incorrectly treat corrupt job data as an optional actor.
**Fix:** Add a clause for a present non-map value that returns `{:error, :invalid_actor_ref_map}`, leaving the catch-all for missing keys:

```elixir
def actor_ref_from_args(%{"actor_ref" => actor_ref_map}) when is_map(actor_ref_map),
  do: ActorRef.from_map(actor_ref_map)

def actor_ref_from_args(%{"actor_ref" => _}), do: {:error, :invalid_actor_ref_map}
def actor_ref_from_args(_args), do: {:error, :missing_actor_ref}
```

#### WR-02: Capture boundary test misses grouped aliases

**Classification:** WARNING
**File:** `test/threadline/capture_semantics_boundary_test.exs:74-88`
**Issue:** `capture_aliases/1` only handles alias AST nodes whose first argument is a direct module alias. Elixir's grouped form, such as `alias Threadline.Semantics.{AuditAction}`, has a different AST shape, so this helper does not map the short alias to `Threadline.Semantics.AuditAction`. A later `AuditAction.t()` reference in capture source can therefore evade the contract assertion and weaken the test added to enforce the capture/semantics boundary.
**Fix:** Expand aliases with `Macro.expand/2` in their lexical environment or explicitly handle grouped alias AST nodes, then add a fixture/source assertion covering `alias Threadline.Semantics.{AuditAction}` followed by `AuditAction.t()`.

---

_Reviewed: 2026-10-06T22:37:36Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
