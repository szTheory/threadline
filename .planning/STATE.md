---
gsd_state_version: 1.0
milestone: v1.20
milestone_name: — Scale and Governance Depth
status: in_progress
last_updated: "2026-05-23T13:05:00.000Z"
last_activity: Planned gap closure phases 80-84 from milestone audit
progress:
  total_phases: 10
  completed_phases: 0
  total_plans: 8
  completed_plans: 8
  percent: 44
---

# Project State: Threadline

## Project Reference

**Core Value**: Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current Focus**: Executing milestone v1.20 — Scale and Governance Depth. Shifting from purely "capturing and reading" data to managing its lifecycle (retention pruning, background exports) and improving operator ergonomics (saved views), using built-in OTP primitives with pluggable scale-out options.

## Current Position

Phase: 80
Plan: TBD
Status: In Progress
Last activity: Planned gap closure phases 80-84 from `v1.20-MILESTONE-AUDIT.md`

## Performance Metrics

- **Total Phases**: 10 (Phases 75-84) — defined in `.planning/ROADMAP.md`
- **Phases Completed**: 0 of 10 audit-closed in active milestone
- **Requirements Covered**: 13 of 13 mapped (INFRA 2, RET 3, VIEW 2, EXP 4, ADAPT 2)
- **Last Milestone**: v1.19 — Integration Breadth (shipped 2026-05-08)
- **Milestone Readiness**: v1.20 remains open; audit on 2026-05-23 reopened closure work across evidence, retention, saved views, and exports

## Accumulated Context

### Decisions

- 2026-05-08: Open v1.20 as "Scale and Governance Depth". Thesis: to be enterprise-grade, Threadline needs safe retention pruning, async background exports, and saved views. Must be built without violating the zero-intrusion promise (no Oban hard dep).
- 2026-05-08: Rely on built-in `Task.Supervisor` and Ecto state for async exports and batched deletes out-of-the-box. Provide clean `Threadline.Storage` and `Threadline.ExportQueue` behaviours. Offer Oban and S3 adapters for adopters managing multi-node scaling.
- 2026-05-08: Saved views and export ownership will be driven strictly by the host's `actor_fn` metadata to maintain Threadline's auth-agnostic boundary.
- 2026-05-08: Phase numbering continues sequentially from 74, starting v1.20 at Phase 75.
- 2026-05-22: Completed Phase 75 implementation work. Audit on 2026-05-23 found missing verification/validation closure, so follow-up closure phases are required before milestone closeout.
- 2026-05-23: Milestone audit for v1.20 found requirements, integration, and closeout gaps; roadmap extended with Phases 80-84 to repair runtime wiring and planning evidence.

### Todos

- [ ] Run `/gsd-plan-phase 80` to begin governance and milestone-surface repair.
- [ ] Run `/gsd-plan-phase 81` to close retention runtime and verification gaps.
- [ ] Run `/gsd-plan-phase 82` to repair saved-view session handoff.
- [ ] Run `/gsd-plan-phase 83` to repair the built-in async export lifecycle.
- [ ] Run `/gsd-plan-phase 84` to complete export delivery and adapter integration.

### Blockers

- Milestone v1.20 cannot be closed until Phases 80-84 repair the audit gaps identified on 2026-05-23.

## Session Continuity

- **Last Action**: Converted the milestone audit into gap-closure Phases 80-84 and reset traceability to pending follow-up work.
- **Next Step**: Start `/gsd-plan-phase 80` to repair planning evidence and milestone surface drift before closing technical gaps.

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-06:

| Category | Item | Status |
|----------|------|--------|
| seed | SEED-001-sigra-integration-adapter | acknowledged stale at close; promoted into Phase 44 and shipped in v1.14 |
| nyquist | phase-53-54-validation-bookkeeping | verification evidence exists, but `53-VALIDATION.md` and `54-VALIDATION.md` were not created during milestone execution |
