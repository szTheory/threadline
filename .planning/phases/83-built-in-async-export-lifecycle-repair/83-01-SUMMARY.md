---
phase: 83-built-in-async-export-lifecycle-repair
plan: 01
subsystem: export-runtime
tags: [exports, liveview, cleanup, lifecycle, otp]
dependency_graph:
  requires: [phase-78 async export primitives, phase-81 application-owned runtime precedent]
  provides: [built-in export runtime startup, truthful enqueue failure handling, terminal lifecycle retention semantics]
  affects: [EXP-01, EXP-02, EXP-04, phase-78 verification]
tech_stack:
  added: []
  patterns: [application-owned-runtime, truthful-background-failure, terminal-state-cleanup]
key_files:
  created: []
  modified:
    - config/config.exs
    - config/test.exs
    - lib/threadline/application.ex
    - lib/threadline/export/orchestrator.ex
    - lib/threadline/export/cleanup_task.ex
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/export_status_live.ex
    - test/threadline/export_queue/task_adapter_test.exs
    - test/threadline/export/orchestrator_test.exs
    - test/threadline/export/cleanup_test.exs
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface/live/export_status_live_test.exs
decisions_made:
  - Start the built-in export `Task.Supervisor` and `CleanupTask` from `Threadline.Application` whenever a repo exists, matching the retention-runtime repair posture from Phase 81.
  - Preserve enqueue-failure rows and mark them `failed` with a durable supportable message instead of silently leaving dead `pending` jobs.
  - Treat `expires_at` as terminal retention metadata only, shared by request-path failures, orchestrator failures, completed exports, and cleanup reconciliation.
requirements-completed: [EXP-01, EXP-02, EXP-04]
metrics:
  duration: inline-execution
  tasks_completed: 3
  tasks_total: 3
---

# Phase 83 Plan 01: Runtime Repair Summary

## Completed Work

1. Wired `Threadline.Application` to start the built-in export `Task.Supervisor` and `Threadline.Export.CleanupTask` on the default library path, with shared export runtime config for cleanup cadence, stale-running cutoff, and terminal retention TTL.
2. Updated `TimelineLive`, `Orchestrator`, and `CleanupTask` so export jobs now move through truthful lifecycle states: enqueue failures become durable `failed` rows, `started_at` is written on real execution start, and `expires_at` is assigned only on terminal transitions.
3. Strengthened the targeted export tests and actor-scoped status assertions so the repaired built-in path is covered end to end without relying on the old dead-`pending` behavior.

## Verification

- `mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/export/cleanup_test.exs test/threadline/export/orchestrator_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs --max-failures 1`

## Deviations From Plan

- Moved `CleanupTask`'s stale-running reconciliation out of synchronous `init/1` and into a retrying bootstrap message so the library application can start safely before the host repo process is live. This preserves the planned startup reconciliation behavior while making the runtime ownership pattern work in a real library boot order.
