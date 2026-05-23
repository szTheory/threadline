---
phase: 78-async-exports-ui
verified: 2026-05-23T20:53:47Z
status: passed
score: 4/4 truths verified
overrides_applied: 1
---

# Phase 78: Async Exports & UI — Verification Report

**Phase Goal:** Prove on the current tree that Threadline's built-in export path now starts by default, reports enqueue failures truthfully, records lifecycle timestamps at the correct runtime transitions, and cleans up expired terminal jobs through DB-driven state.

**Verified:** 2026-05-23T20:53:47Z
**Status:** passed
**Re-verification:** Yes — verified after Phase 83 repaired the missing built-in runtime startup path and backfilled the closeout evidence around the repaired tree

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `Threadline.Application` now starts the built-in export `Task.Supervisor` and `Threadline.Export.CleanupTask` whenever an Ecto repo is configured, so the default queue path is library-owned and real. | ✓ VERIFIED | `lib/threadline/application.ex`; `config/config.exs`; `config/test.exs`; `test/threadline/export_queue/task_adapter_test.exs` |
| 2 | `TimelineLive` preserves the export job row and converts enqueue failures into durable `failed` jobs with a human-readable error message and terminal expiry metadata instead of leaving dead `pending` rows. | ✓ VERIFIED | `lib/threadline/operator_surface/live/timeline_live.ex`; `test/threadline/operator_surface/live/timeline_live_test.exs`; `test/threadline/operator_surface/live/export_status_live_test.exs` |
| 3 | `Threadline.Export.Orchestrator` sets `started_at` on the real `pending -> running` transition and assigns `expires_at` only when jobs become `completed` or `failed`. | ✓ VERIFIED | `lib/threadline/export/orchestrator.ex`; `test/threadline/export/orchestrator_test.exs` |
| 4 | `Threadline.Export.CleanupTask` reconciles stale `running` jobs into terminal failed rows and deletes only expired terminal jobs/artifacts through the configured storage behaviour. | ✓ VERIFIED | `lib/threadline/export/cleanup_task.ex`; `test/threadline/export/cleanup_test.exs` |

**Score:** 4/4 truths verified

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|----------------|-------------|--------|----------|
| EXP-01 | 78-01, 78-03, 83-01 | Built-in background export execution runs on the default library path without extra host supervision and fails truthfully when startup is unavailable. | ✓ SATISFIED | `lib/threadline/application.ex`; `lib/threadline/export_queue/task_adapter.ex`; `lib/threadline/operator_surface/live/timeline_live.ex`; `test/threadline/export_queue/task_adapter_test.exs`; `test/threadline/operator_surface/live/timeline_live_test.exs` |
| EXP-02 | 78-01, 83-01 | Large exports still stream through the orchestrator safely while recording truthful lifecycle metadata on the repaired runtime path. | ✓ SATISFIED | `lib/threadline/export/orchestrator.ex`; `test/threadline/export/orchestrator_test.exs`; controller and LiveView export tests |
| EXP-04 | 78-02, 83-01 | Cleanup now uses terminal lifecycle truth to expire export rows and artifacts on the built-in path. | ✓ SATISFIED | `lib/threadline/export/cleanup_task.ex`; `test/threadline/export/cleanup_test.exs`; `test/threadline/operator_surface/live/export_status_live_test.exs` |

### Commands Run On Final Tree

1. Built-in runtime startup and lifecycle proof

```bash
rg -n 'TaskSupervisor|CleanupTask|retention_ttl_hours|stale_running_cutoff_hours|started_at|expires_at' \
  lib/threadline/application.ex \
  lib/threadline/export/orchestrator.ex \
  lib/threadline/export/cleanup_task.ex \
  config/config.exs \
  config/test.exs
```

Result: PASS

2. Truthful enqueue failure and actor-scoped status proof

```bash
rg -n 'Background export could not start|error_message|Request Background Export|expires_at' \
  lib/threadline/operator_surface/live/timeline_live.ex \
  lib/threadline/operator_surface/live/export_status_live.ex \
  test/threadline/operator_surface/live/timeline_live_test.exs \
  test/threadline/operator_surface/live/export_status_live_test.exs
```

Result: PASS

3. Targeted repaired-runtime tests

```bash
mix test \
  test/threadline/export_queue/task_adapter_test.exs \
  test/threadline/export/cleanup_test.exs \
  test/threadline/export/orchestrator_test.exs \
  test/threadline/operator_surface/live/timeline_live_test.exs \
  test/threadline/operator_surface/live/export_status_live_test.exs \
  --max-failures 1
```

Result: PASS

### Verification Notes

- This artifact intentionally replaces the older summary-derived Phase 78 story with current-tree proof from the repaired built-in export path.
- The closeout language stays inside the built-in runtime boundary. Adapter-backed delivery semantics, S3 download integration, and full Oban runtime closure still belong to Phase 84 and are not claimed here.

### Gaps Summary

No blocking gaps remain for EXP-01, EXP-02, or EXP-04 on the built-in export path. Remaining milestone work sits outside Phase 78's repaired boundary and stays owned by Phase 84.
