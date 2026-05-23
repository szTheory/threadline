---
phase: 78
slug: async-exports-ui
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
updated: 2026-05-23T20:53:47Z
---

# Phase 78 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 78 is validated on the repaired final tree after Phase 83 closed the missing built-in export runtime path. The primary risk is drifting back to a summary-only story where export UI exists but the default queue, lifecycle truth, and cleanup contract are still incomplete.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit runtime tests, LiveView tests, controller tests, and code-surface grep verification |
| **Config file** | `mix.exs`; `config/config.exs`; `config/test.exs`; `lib/threadline/application.ex`; `lib/threadline/export_queue/task_adapter.ex`; `lib/threadline/export/orchestrator.ex`; `lib/threadline/export/cleanup_task.ex`; `lib/threadline/operator_surface/live/timeline_live.ex`; `lib/threadline/operator_surface/live/export_status_live.ex`; `lib/threadline/operator_surface/controllers/export_controller.ex` |
| **Quick run command** | `mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/export/orchestrator_test.exs test/threadline/export/cleanup_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs --max-failures 1` |
| **Phase gate command** | `mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/export/orchestrator_test.exs test/threadline/export/cleanup_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~10-25 seconds on a warm cache |
| **Estimated runtime — full** | ~90-180 seconds on a warm cache |

---

## Sampling Rate

- Re-run the export runtime quintet after any change to `Threadline.Application`, the built-in queue adapter, the orchestrator, the cleanup worker, or the background-export request path.
- Re-run the actor-scoped LiveView tests whenever enqueue truth, failure rendering, or export-status visibility changes.
- Re-run the download controller tests whenever lifecycle-state semantics, `file_path` handling, or storage-adapter integration changes, so Phase 78 does not overclaim the Phase 84 adapter-backed delivery closure.
- Re-run the grep proof whenever verification artifacts are repaired so the active evidence continues to point at built-in startup, truthful enqueue failure, runtime timestamps, and terminal-state cleanup.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 78-01-01 | 01 | 1 | EXP-01 | T-83-01 | `Threadline.Application` starts the built-in export `Task.Supervisor` and `CleanupTask` when a repo exists, so the default queue path is real without extra host wiring. | code-surface + targeted unit | `rg -n 'TaskSupervisor|CleanupTask|cleanup_interval_ms|stale_running_cutoff_hours|retention_ttl_hours' lib/threadline/application.ex config/config.exs config/test.exs test/threadline/export_queue/task_adapter_test.exs && mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/export/cleanup_test.exs --max-failures 1` | ✅ | ✅ green |
| 78-01-02 | 03 | 1 | EXP-01, EXP-03 | T-83-02 | `TimelineLive` preserves the job row and flips enqueue failures to `failed` with a durable reason instead of misreporting success, while the actor-scoped status page renders the persisted failure truth. | targeted liveview | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs --max-failures 1` | ✅ | ✅ green |
| 78-01-03 | 01 | 1 | EXP-02 | T-83-03 | `Threadline.Export.Orchestrator` records `started_at` on real execution start and writes terminal `completed_at` and `expires_at` metadata only when the export is complete or failed. | targeted unit | `rg -n 'started_at|completed_at|expires_at|terminal_expiry|failed' lib/threadline/export/orchestrator.ex test/threadline/export/orchestrator_test.exs && mix test test/threadline/export/orchestrator_test.exs --max-failures 1` | ✅ | ✅ green |
| 78-02-01 | 02 | 1 | EXP-04 | T-83-04 | `CleanupTask` reconciles abandoned `running` jobs into terminal failed rows with expiry and deletes only expired `completed` or `failed` jobs/artifacts. | targeted unit | `rg -n 'bootstrap_reconcile|running|failed|completed|expires_at|delete' lib/threadline/export/cleanup_task.ex test/threadline/export/cleanup_test.exs && mix test test/threadline/export/cleanup_test.exs --max-failures 1` | ✅ | ✅ green |
| 78-02-02 | 02 | 1 | EXP-03 | T-83-04 | Completed exports still expose download readiness on the actor-scoped status page and controller path without broadening into Phase 84 adapter-backed delivery claims. | liveview + controller | `mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs --max-failures 1` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/78-async-exports-ui/78-01-PLAN.md`
- [x] `.planning/phases/78-async-exports-ui/78-02-PLAN.md`
- [x] `.planning/phases/78-async-exports-ui/78-03-PLAN.md`
- [x] `.planning/phases/78-async-exports-ui/78-01-SUMMARY.md`
- [x] `.planning/phases/78-async-exports-ui/78-02-SUMMARY.md`
- [x] `.planning/phases/78-async-exports-ui/78-03-SUMMARY.md`
- [x] `.planning/phases/78-async-exports-ui/78-VERIFICATION.md`
- [x] `.planning/phases/78-async-exports-ui/78-VALIDATION.md`

Wave 0 is complete. Phase 78 now has a repaired current-tree evidence chain for the built-in export runtime, lifecycle truth, and cleanup path.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review that the repaired Phase 78 closeout stays inside the built-in export runtime boundary and does not claim S3-backed delivery, adapter-backed downloads, or full Oban runtime closure early | EXP-01, EXP-04 | The highest-risk failure mode is milestone wording drift rather than missing targeted tests | Read `78-VERIFICATION.md` and confirm it proves only built-in startup, enqueue truth, lifecycle fields, and DB-driven cleanup while explicitly naming Phase 84 as the remaining adapter-backed delivery work. |

---

## Validation Sign-Off

- [x] Phase 78 has explicit automated coverage for startup, enqueue truth, orchestrator lifecycle metadata, cleanup semantics, and actor-scoped status visibility on the repaired tree.
- [x] The active evidence references the current repaired tree instead of relying on historical summary prose.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** finalized on 2026-05-23 after Phase 83 repaired the built-in export runtime and backfilled the Phase 78 verification and validation artifacts around that repaired truth.
