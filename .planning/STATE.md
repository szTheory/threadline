---
gsd_state_version: 1.0
milestone: v1.20
milestone_name: — Scale and Governance Depth
status: executing
last_updated: "2026-05-24T10:55:52.737Z"
last_activity: 2026-05-24 -- Phase 84 execution started
progress:
  total_phases: 10
  completed_phases: 9
  total_plans: 22
  completed_plans: 19
  percent: 86
---

# Project State: Threadline

## Project Reference

**Core Value**: Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current Focus**: Milestone v1.20 — Scale and Governance Depth remains in progress. Phases 82 and 83 are now complete, and Phase 84 is planned to close the remaining adapter-backed export delivery and integration gaps.

## Current Position

Phase: 84 (export-delivery-and-scale-adapter-integration-repair) — EXECUTING
Plan: 1 of 3
Status: Executing Phase 84
Last activity: 2026-05-24 -- Phase 84 execution started

## Performance Metrics

- **Total Phases**: 10 (Phases 75-84) — defined in `.planning/ROADMAP.md`
- **Phases Completed**: 9 of 10 phases have complete plan execution; repaired final-tree closure is now in place for 75 through 83, with only Phase 84 left to execute
- **Requirements Covered**: 13 of 13 mapped (INFRA 2, RET 3, VIEW 2, EXP 4, ADAPT 2)
- **Last Milestone**: v1.19 — Integration Breadth (shipped 2026-05-08)
- **Milestone Readiness**: v1.20 remains open, but only Phase 84 still blocks milestone closeout

## Accumulated Context

### Decisions

- 2026-05-08: Open v1.20 as "Scale and Governance Depth". Thesis: to be enterprise-grade, Threadline needs safe retention pruning, async background exports, and saved views. Must be built without violating the zero-intrusion promise (no Oban hard dep).
- 2026-05-08: Rely on built-in `Task.Supervisor` and Ecto state for async exports and batched deletes out-of-the-box. Provide clean `Threadline.Storage` and `Threadline.ExportQueue` behaviours. Offer Oban and S3 adapters for adopters managing multi-node scaling.
- 2026-05-08: Saved views and export ownership will be driven strictly by the host's `actor_fn` metadata to maintain Threadline's auth-agnostic boundary.
- 2026-05-08: Phase numbering continues sequentially from 74, starting v1.20 at Phase 75.
- 2026-05-22: Completed Phase 75 implementation work. Audit on 2026-05-23 found missing verification/validation closure, so follow-up closure phases are required before milestone closeout.
- 2026-05-23: Milestone audit for v1.20 found requirements, integration, and closeout gaps; roadmap extended with Phases 80-84 to repair runtime wiring and planning evidence.
- 2026-05-23: Phase 80 re-verified Phase 75 on the current tree, repaired Phase 79 evidence drift, and reconciled the authoritative milestone surfaces without claiming later runtime closure early.
- 2026-05-23: Phase 81 added built-in retention supervision, routed the retention UI through the named runtime API, and closed Phase 76 with current-tree verification and Nyquist validation artifacts.

### Todos

- [ ] Run `/gsd-execute-phase 84` to implement export delivery and scale-adapter integration closure.

### Blockers

- Milestone v1.20 cannot be closed until Phase 84 repairs the remaining export delivery and adapter integration gaps identified on 2026-05-23.

## Session Continuity

- **Last Action**: Planned Phase 84 with a three-plan split: actor-owned delivery/UI repair, adapter startup/integration closure, and evidence closeout.
- **Next Step**: Run `/gsd-execute-phase 84` to implement the remaining export delivery and adapter integration work.

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-06:

| Category | Item | Status |
|----------|------|--------|
| seed | SEED-001-sigra-integration-adapter | acknowledged stale at close; promoted into Phase 44 and shipped in v1.14 |
| nyquist | phase-53-54-validation-bookkeeping | verification evidence exists, but `53-VALIDATION.md` and `54-VALIDATION.md` were not created during milestone execution |
