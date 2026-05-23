---
gsd_state_version: 1.0
milestone: v1.20
milestone_name: — Scale and Governance Depth
status: completed
last_updated: "2026-05-23T12:00:00.000Z"
last_activity: Completed 78-03-PLAN.md
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 8
  completed_plans: 8
  percent: 100
---

# Project State: Threadline

## Project Reference

**Core Value**: Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current Focus**: Executing milestone v1.20 — Scale and Governance Depth. Shifting from purely "capturing and reading" data to managing its lifecycle (retention pruning, background exports) and improving operator ergonomics (saved views), using built-in OTP primitives with pluggable scale-out options.

## Current Position

Phase: 78
Plan: 03 (Export Status UI & Trigger Integration)
Status: Completed
Last activity: Completed 78-03-PLAN.md

## Performance Metrics

- **Total Phases**: 5 (Phases 75-79) — defined in `.planning/milestones/v1.20-ROADMAP.md`
- **Phases Completed**: 1 of 5 in active milestone
- **Requirements Covered**: 13 of 13 mapped (INFRA 2, RET 3, VIEW 2, EXP 4, ADAPT 2)
- **Last Milestone**: v1.19 — Integration Breadth (shipped 2026-05-08)
- **Milestone Readiness**: v1.20 roadmap and requirements are formalized and ready for planning

## Accumulated Context

### Decisions

- 2026-05-08: Open v1.20 as "Scale and Governance Depth". Thesis: to be enterprise-grade, Threadline needs safe retention pruning, async background exports, and saved views. Must be built without violating the zero-intrusion promise (no Oban hard dep).
- 2026-05-08: Rely on built-in `Task.Supervisor` and Ecto state for async exports and batched deletes out-of-the-box. Provide clean `Threadline.Storage` and `Threadline.ExportQueue` behaviours. Offer Oban and S3 adapters for adopters managing multi-node scaling.
- 2026-05-08: Saved views and export ownership will be driven strictly by the host's `actor_fn` metadata to maintain Threadline's auth-agnostic boundary.
- 2026-05-08: Phase numbering continues sequentially from 74, starting v1.20 at Phase 75.
- 2026-05-22: Completed Phase 75: Governance Infrastructure & State. Created migrations, Ecto schemas, and behaviours (`Threadline.Storage`, `Threadline.ExportQueue`).

### Todos

- [ ] Run `/gsd-plan-phase 76` to begin execution of Retention Pruning Ergonomics.
- [x] Run `/gsd-plan-phase 75` to begin execution of Governance Infrastructure & State.
- [x] Define precise Ecto migrations for `threadline_export_jobs`, `threadline_retention_runs`, and `threadline_saved_views` in Phase 75.
- [x] Draft explicit doc-contracts for the new Storage and ExportQueue behaviours.

### Blockers

- None. Milestone is ready for execution.

## Session Continuity

- **Last Action**: Completed Phase 75 Governance Infrastructure & State. Ecto schemas and migrations generated, behaviours implemented.
- **Next Step**: Start `/gsd-plan-phase 76` to begin implementing Retention Pruning Ergonomics.

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-06:

| Category | Item | Status |
|----------|------|--------|
| seed | SEED-001-sigra-integration-adapter | acknowledged stale at close; promoted into Phase 44 and shipped in v1.14 |
| nyquist | phase-53-54-validation-bookkeeping | verification evidence exists, but `53-VALIDATION.md` and `54-VALIDATION.md` were not created during milestone execution |
