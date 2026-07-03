---
status: issues_found
phase: 190-storage-schema-confidence-and-host-schema-truth
reviewed: 2026-07-01T23:37:05Z
source_review: .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-REVIEW.md
fixes_reviewed:
  - CR-01
  - CR-02
  - WR-01
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
files_reviewed: 15
files_reviewed_list:
  - lib/threadline/storage_schema.ex
  - lib/threadline/export_queue.ex
  - lib/threadline/export_queue/task_adapter.ex
  - lib/threadline/export_queue/oban.ex
  - lib/threadline/export/orchestrator.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - test/threadline/storage_schema_test.exs
  - test/threadline/export_queue/task_adapter_test.exs
  - test/threadline/export_queue/oban_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
  - test/threadline/operator_surface/live/export_status_live_test.exs
  - test/threadline/storage_schema_integration_test.exs
  - test/support/storage_schema_case.ex
  - .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-REVIEW.md
---

# Phase 190: Post-Fix Review

**Source Review:** `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-REVIEW.md`
**Status:** issues_found

## Verdict

CR-01 and CR-02 are closed. WR-01 remains a non-blocking warning because it is a test-fixture confidence gap, not an observed production runtime defect.

## Critical Findings

### CR-01: Closed - Storage schema validation rejects unsafe identifiers

**Verdict:** Closed.

**Evidence:** `Threadline.StorageSchema.validate!/1` now rejects `nil` and booleans before atom conversion, validates binary identifiers with `@identifier`, enforces the PostgreSQL 63-byte limit, and rejects other unsupported values through the catch-all clause at `lib/threadline/storage_schema.ex:31`. The error message documents the identifier and byte constraints at `lib/threadline/storage_schema.ex:50`. Regression coverage exercises nil, booleans, blank strings, invalid characters, dotted names, injection-like strings, and a 64-byte identifier at `test/threadline/storage_schema_test.exs:32`.

### CR-02: Closed - Queued exports preserve enqueue-time storage schema

**Verdict:** Closed.

**Evidence:** Timeline enqueue captures one `storage_schema`, uses it for job insertion, and passes the same value to the queue adapter at `lib/threadline/operator_surface/live/timeline_live.ex:279`. Export Status does the same at `lib/threadline/operator_surface/live/export_status_live.ex:58`. `TaskAdapter` resolves the schema from enqueue opts and passes it into `Threadline.Export.Orchestrator.run/2` at `lib/threadline/export_queue/task_adapter.ex:20`. The Oban adapter persists `storage_schema` in job args at `lib/threadline/export_queue/oban.ex:22`, and the worker forwards it to the orchestrator at `lib/threadline/export_queue/oban.ex:91`. The orchestrator uses that schema for job lookup, updates, and export streaming at `lib/threadline/export/orchestrator.ex:17`.

**Coverage:** Task execution schema drift is covered at `test/threadline/export_queue/task_adapter_test.exs:56`; Oban args preserve the schema at `test/threadline/export_queue/oban_test.exs:35`; Timeline and Export Status enqueue call sites assert `storage_schema: "threadline"` in adapter opts at `test/threadline/operator_surface/live/timeline_live_test.exs:1626` and `test/threadline/operator_surface/live/export_status_live_test.exs:319`.

## Warnings

### WR-01: WARNING - Alternate-schema fixture still does not prove schema-local FK constraints

**Verdict:** Still open as a non-blocking warning.

**Issue:** `ensure_storage_schema!/2` still creates alternate storage tables with `CREATE TABLE ... (LIKE "threadline"."table" INCLUDING ALL)` at `test/support/storage_schema_case.ex:80`. The integration tests now give useful operational confidence across `threadline` and `audit` storage schemas, including table/function presence and cross-schema isolation at `test/threadline/storage_schema_integration_test.exs:11`, but they still do not assert `pg_constraint` rows for schema-local foreign keys.

**Why not blocking:** This is a fixture fidelity gap. The reviewed production paths now pass the selected schema consistently, and the focused regression suite passes. The remaining risk is that a generated migration FK mistake could still be missed by tests that clone tables with `LIKE`.

**Fix:** Replace the alternate-schema fixture with generated migration SQL, or add explicit `pg_constraint` assertions for key schema-local FKs such as `audit_changes.transaction_id -> audit_transactions.id` and `audit_transactions.action_id -> audit_actions.id` in each configured storage schema.

## Verification

Ran:

```bash
mix test test/threadline/storage_schema_test.exs test/threadline/export_queue/task_adapter_test.exs test/threadline/export_queue/oban_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/storage_schema_integration_test.exs
```

Result: 86 tests, 0 failures.

---

_Reviewed: 2026-07-01T23:37:05Z_
_Reviewer: the agent (gsd-code-reviewer)_
