---
phase: 83
slug: built-in-async-export-lifecycle-repair
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
updated: 2026-05-23T23:10:00Z
---

# Phase 83 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 83 validates the repaired built-in export runtime on the current tree. The primary risk is regressing back to a summary-only story where the queue contract exists on paper but the default runtime is not actually started or lifecycle truth is still incomplete.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit runtime tests, LiveView/controller tests, and code-surface grep verification |
| **Config file** | `mix.exs`; `config/config.exs`; `config/test.exs`; `lib/threadline/application.ex`; `lib/threadline/export_queue/task_adapter.ex`; `lib/threadline/export/orchestrator.ex`; `lib/threadline/export/cleanup_task.ex`; `lib/threadline/operator_surface/live/timeline_live.ex`; `lib/threadline/operator_surface/live/export_status_live.ex`; `lib/threadline/operator_surface/controllers/export_controller.ex` |
| **Quick run command** | `mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/export/orchestrator_test.exs test/threadline/export/cleanup_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~10-25 seconds on a warm cache |
| **Estimated runtime — full** | ~90-180 seconds on a warm cache |

---

## Sampling Rate

- Re-run the runtime quintet after any change to `Threadline.Application`, the built-in queue adapter, the orchestrator, or `CleanupTask`.
- Re-run the Timeline and Export Status tests whenever enqueue, lifecycle-state rendering, or actor-scoped visibility changes.
- Re-run the controller test group when export lifecycle fields or download readiness semantics change, so Phase 83 does not accidentally claim the Phase 84 adapter-backed delivery work.
- Re-run the grep proof whenever milestone evidence files are repaired so the active artifacts continue to name the built-in runtime startup, truthful enqueue failure path, terminal expiry semantics, and DB-driven cleanup contract explicitly.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 83-01-01 | 01 | 1 | EXP-01 | T-83-01 / T-83-02 | `Threadline.Application` starts the built-in export `Task.Supervisor` and `CleanupTask` when a repo exists, so the default queue path is real instead of dangling. | code-surface + targeted unit | `rg -n 'Task.Supervisor|CleanupTask|export|repo' mix.exs lib/threadline/application.ex config/config.exs config/test.exs && mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/export/cleanup_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 83-01-02 | 01 | 1 | EXP-01 | T-83-02 / T-83-05 | `TimelineLive` preserves the job row, flips enqueue failures to `failed`, persists a stable error message, and does not redirect with a false success flash when the built-in runtime rejects the request. | targeted liveview | `mix test test/threadline/operator_surface/live/timeline_live_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 83-01-03 | 01 | 1 | EXP-02, EXP-04 | T-83-03 / T-83-04 | `Orchestrator` sets `started_at` on real execution start, assigns `completed_at` and terminal `expires_at` correctly, and failed jobs also receive bounded retention metadata. | targeted unit | `rg -n 'started_at|completed_at|expires_at|failed|completed' lib/threadline/export/orchestrator.ex test/threadline/export/orchestrator_test.exs && mix test test/threadline/export/orchestrator_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 83-01-04 | 01 | 1 | EXP-04 | T-83-04 | `CleanupTask` reconciles abandoned `running` rows into terminal failed rows with expiry and only deletes expired terminal jobs/artifacts through the storage behaviour. | targeted unit | `rg -n 'running|failed|completed|expires_at|delete' lib/threadline/export/cleanup_task.ex test/threadline/export/cleanup_test.exs && mix test test/threadline/export/cleanup_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 83-02-01 | 02 | 2 | EXP-01, EXP-02, EXP-04 | T-83-05 | `78-VERIFICATION.md` records current-tree proof for built-in runtime startup, truthful enqueue behavior, lifecycle timestamps, and DB-driven cleanup without overclaiming Phase 84 closure. | evidence grep | `rg -n 'EXP-01|EXP-02|EXP-04|Observable Truths|TaskSupervisor|CleanupTask|started_at|expires_at|Phase 84' .planning/phases/78-async-exports-ui/78-VERIFICATION.md` | ✅ | ⬜ pending |
| 83-02-02 | 02 | 2 | EXP-01, EXP-02, EXP-04 | T-83-05 | `78-VALIDATION.md` uses the current Nyquist shape and maps repaired built-in export behavior to concrete commands and artifacts on the final tree. | evidence grep | `rg -n 'nyquist_compliant: true|Per-Task Verification Map|EXP-01|EXP-02|EXP-04|orchestrator_test|cleanup_test|timeline_live_test|export_status_live_test' .planning/phases/78-async-exports-ui/78-VALIDATION.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/83-built-in-async-export-lifecycle-repair/83-CONTEXT.md`
- [x] `.planning/phases/83-built-in-async-export-lifecycle-repair/83-RESEARCH.md`
- [x] `.planning/phases/83-built-in-async-export-lifecycle-repair/83-01-PLAN.md`
- [x] `.planning/phases/83-built-in-async-export-lifecycle-repair/83-02-PLAN.md`
- [ ] `.planning/phases/78-async-exports-ui/78-VERIFICATION.md`
- [ ] `.planning/phases/78-async-exports-ui/78-VALIDATION.md` normalized to repaired Nyquist shape

Wave 0 for Phase 83 planning is complete. Execution remains responsible for creating the missing Phase 78 closeout artifacts on the repaired tree.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review that Phase 83 closeout stays inside the built-in runtime boundary and does not claim S3/Oban/download closure owned by Phase 84 | EXP-01, EXP-04 | The highest-risk failure mode is milestone wording drift, not absence of targeted tests | Read `78-VERIFICATION.md` after execution and confirm it proves only the built-in runtime, enqueue truth, lifecycle fields, and cleanup behavior while naming Phase 84 as the remaining adapter-backed delivery work. |

---

## Validation Sign-Off

- [x] Every planned runtime behavior has a targeted automated command or an explicit evidence-grep gate.
- [x] Sampling continuity is preserved across startup, request path, orchestrator lifecycle, cleanup worker, and Phase 78 evidence repair.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** planning-ready on 2026-05-23; finalize after Phase 83 execution proves the repaired built-in export runtime and backfills the Phase 78 evidence chain.
