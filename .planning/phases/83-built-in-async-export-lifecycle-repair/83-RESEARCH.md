# Phase 83: Built-In Async Export Lifecycle Repair - Research

**Researched:** 2026-05-23
**Domain:** OTP runtime ownership, export lifecycle truth, cleanup semantics, and current-tree closeout evidence
**Confidence:** HIGH

## Summary

Phase 83 is a built-in runtime repair phase, not a new export-feature phase. The current tree already has the main export primitives:

- `Threadline.ExportQueue.TaskAdapter` provides the built-in `Task.Supervisor` queue contract.
- `Threadline.Export.Orchestrator` can stream export data to local storage and persist terminal job state.
- `Threadline.Export.CleanupTask` already contains abandoned-running reconciliation plus expired-job cleanup logic.
- `TimelineLive` and `ExportStatusLive` already expose the operator request and status surfaces.

The broken seam is runtime ownership and lifecycle truth. `Threadline.Application` only starts the retention pruner, not the export runtime. That leaves the default queue adapter pointing at a supervisor that is never started, while `TimelineLive` inserts a `pending` row and redirects as though the enqueue succeeded. The lifecycle model is also incomplete: `started_at` is never set when work begins, `expires_at` is never assigned for terminal jobs, and cleanup currently sweeps any expired row instead of explicitly targeting terminal states.

**Primary recommendation:** extend the library-owned `Threadline.Application` to start a built-in export `Task.Supervisor` and `Threadline.Export.CleanupTask` whenever Threadline has a configured repo, make the request path fail `pending` rows immediately and truthfully when enqueue fails, set `started_at` on the real `pending -> running` transition, set `expires_at` only on terminal transitions using retention TTL semantics, and then close Phase 78 with current-tree verification and Nyquist validation artifacts.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Built-in export runtime startup | OTP application | Export queue adapter | The default queue contract is library-owned and must be started by the library to be truthful. |
| Enqueue failure truth | Timeline request path | Export job row | Operators need an auditable failed row plus an immediate visible failure instead of a dead `pending` row. |
| Execution lifecycle timestamps | Orchestrator | Export job schema | `started_at`, `completed_at`, and `expires_at` belong to durable DB truth, not process-local state. |
| Expired-artifact cleanup and crash recovery | CleanupTask | Storage adapter | Cleanup should reconcile stale `running` rows and delete expired artifacts using DB-driven lifecycle state. |
| Phase 78 closeout evidence | Planning artifacts | Current tree tests/code | The audit gap is both runtime behavior and missing verification/validation proof. |

## Current Tree Findings

### Verified current strengths

- `lib/threadline/export_queue/task_adapter.ex` already centralizes the built-in queue path and exposes the exact `:supervisor_not_started` failure mode that this phase must close.
- `lib/threadline/export/orchestrator.ex` already streams to a temp file inside a repo transaction and persists `completed` or `failed` state afterward.
- `lib/threadline/export/cleanup_task.ex` already has the right overall responsibilities: startup reconciliation for stale `running` jobs, periodic cleanup, and storage-behaviour-based deletion.
- `lib/threadline/governance/export_job.ex` and `lib/threadline/governance/migration.ex` already provide the durable lifecycle fields Phase 83 needs (`started_at`, `completed_at`, `expires_at`, `error_message`).
- `test/threadline/export/cleanup_test.exs`, `test/threadline/export/orchestrator_test.exs`, `test/threadline/operator_surface/live/export_status_live_test.exs`, and `test/threadline/operator_surface/live/timeline_live_test.exs` give Phase 83 a solid targeted-test starting point.

### Verified gaps

- `lib/threadline/application.ex` only starts the retention pruner. No built-in export `Task.Supervisor` or cleanup worker is started from the library runtime.
- `lib/threadline/operator_surface/live/timeline_live.ex` inserts a `pending` export row, calls `adapter.enqueue(job.id)`, ignores the result, flashes success, and redirects even when the runtime is unavailable.
- `lib/threadline/export/orchestrator.ex` flips jobs to `running` without setting `started_at`, marks `completed` without `expires_at`, and marks `failed` without retention TTL semantics.
- `lib/threadline/export/cleanup_task.ex` currently queries every row where `expires_at < now` instead of constraining cleanup to terminal states with non-null expiry, which is wider than the intended lifecycle model.
- Phase 78 still lacks `78-VERIFICATION.md`, and `78-VALIDATION.md` remains partial and does not express the repaired built-in runtime truth the audit now expects.

## Recommended Runtime Shape

### Pattern 1: Extend `Threadline.Application` with built-in export runtime children

Keep the Phase 81 precedent. `Threadline.Application` should own the built-in export runtime whenever Threadline has a configured repo:

- start a named `Task.Supervisor` for the built-in queue path,
- start `Threadline.Export.CleanupTask` with repo + runtime config,
- keep startup conditional on repo presence so capture-only adopters do not crash on missing persistence dependencies,
- do not add a second `exports.enabled` gate that leaves a shipped default path inert by surprise.

Recommended default posture:

- if a repo exists, start the built-in export runtime children;
- optional Oban/S3 adapters remain separate configuration choices, not prerequisites for the default path.

### Pattern 2: Treat enqueue failure as a first-class lifecycle transition

The request flow should remain DB-first:

1. Insert the `pending` row.
2. Attempt `adapter.enqueue/2`.
3. If enqueue succeeds, continue as today.
4. If enqueue fails, update the row to `failed`, persist a stable human-readable `error_message`, surface an error flash, and avoid redirecting with a false success message.

This preserves the governance row for supportability while eliminating silent limbo states.

### Pattern 3: Set lifecycle timestamps at the semantically correct transition points

- `started_at` should be written inside the orchestrator when work actually begins, together with the `running` state.
- `completed_at` should remain the terminal completion timestamp.
- `expires_at` should be assigned only on terminal transitions (`completed` and `failed`) using export-retention TTL from terminal time.
- Cleanup should treat terminal-state expiry as the durable deletion contract; active jobs should not have expiry timestamps.

### Pattern 4: Keep cleanup DB-driven and terminal-state-aware

`CleanupTask` already has the right architectural location. Tighten it rather than replace it:

- on startup, reconcile stale `running` rows older than the abandonment cutoff to `failed` with a stable message and terminal expiry,
- during periodic cleanup, only fetch terminal rows (`completed`, `failed`) with non-null `expires_at < now`,
- continue deleting through the configured storage behaviour so Phase 84 can later swap local-path and adapter-backed delivery without changing cleanup ownership.

### Pattern 5: Close Phase 78 with current-tree evidence after the repair

Phase 83 should create:

- `78-VERIFICATION.md` proving the repaired built-in runtime on the current tree,
- a normalized `78-VALIDATION.md` with Nyquist frontmatter and per-task verification map,
- evidence that stays within the built-in runtime and cleanup boundary and does not claim the Phase 84 S3/Oban/download closure early.

## Common Pitfalls

### Pitfall 1: Starting only the cleanup worker without the built-in task supervisor

That would close part of EXP-04 but leave EXP-01 broken because the default queue adapter would still fail at enqueue time.

### Pitfall 2: Hiding enqueue failures by deleting the row or leaving it `pending`

Either approach weakens supportability. The correct contract is to preserve the job row and move it immediately to `failed` with a clear message.

### Pitfall 3: Setting `expires_at` at enqueue time

That turns retention into a queue lease and makes long queue delays look like expired terminal jobs. Expiry should start when the job reaches a terminal state.

### Pitfall 4: Sweeping every expired row regardless of status

Cleanup should target terminal lifecycle states explicitly. Active or malformed rows should not be silently deleted just because an expiry field exists.

### Pitfall 5: Letting Phase 83 absorb Phase 84 download and adapter work

The local-only `path/1` download limitation and adapter-backed delivery closure remain Phase 84 work. Phase 83 should make the built-in runtime truthful and verifiable without broadening into S3 or Oban system-level closure.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Targeted ExUnit runtime tests, LiveView/controller tests, and code-surface grep verification |
| Quick run | `mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/export/orchestrator_test.exs test/threadline/export/cleanup_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs --max-failures 1` |
| Phase gate | `mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/export/orchestrator_test.exs test/threadline/export/cleanup_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs --max-failures 1` |

### Requirement Map

| Req ID | Runtime truth to prove | Expected evidence |
|--------|------------------------|-------------------|
| EXP-01 | Built-in export runtime starts by default and enqueue failures are surfaced truthfully | application/runtime tests plus `78-VERIFICATION.md` |
| EXP-02 | Orchestrator still streams export rows safely on the repaired path | orchestrator tests plus `78-VERIFICATION.md` |
| EXP-04 | Terminal jobs record cleanup metadata and the cleanup worker removes expired artifacts end to end | cleanup tests plus `78-VERIFICATION.md` |

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/v1.20-MILESTONE-AUDIT.md`
- `.planning/phases/83-built-in-async-export-lifecycle-repair/83-CONTEXT.md`
- `.planning/phases/81-retention-runtime-closure/81-CONTEXT.md`
- `.planning/phases/78-async-exports-ui/78-01-PLAN.md`
- `.planning/phases/78-async-exports-ui/78-02-PLAN.md`
- `.planning/phases/78-async-exports-ui/78-03-PLAN.md`
- `.planning/phases/78-async-exports-ui/78-RESEARCH.md`
- `mix.exs`
- `config/config.exs`
- `config/test.exs`
- `lib/threadline/application.ex`
- `lib/threadline/export_queue/task_adapter.ex`
- `lib/threadline/export/orchestrator.ex`
- `lib/threadline/export/cleanup_task.ex`
- `lib/threadline/governance/export_job.ex`
- `lib/threadline/governance/migration.ex`
- `lib/threadline/operator_surface/live/timeline_live.ex`
- `lib/threadline/operator_surface/live/export_status_live.ex`
- `lib/threadline/operator_surface/controllers/export_controller.ex`
- `lib/threadline/storage.ex`
- `lib/threadline/storage/local.ex`
- `test/threadline/export_queue/task_adapter_test.exs`
- `test/threadline/export/orchestrator_test.exs`
- `test/threadline/export/cleanup_test.exs`
- `test/threadline/operator_surface/live/timeline_live_test.exs`
- `test/threadline/operator_surface/live/export_status_live_test.exs`
- `test/threadline/operator_surface/controllers/export_controller_test.exs`

## RESEARCH COMPLETE
