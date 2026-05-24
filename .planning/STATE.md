---
gsd_state_version: 1.0
milestone: v1.20
milestone_name: — Scale and Governance Depth
status: shipped
last_updated: "2026-05-24T13:00:00Z"
last_activity: 2026-05-24 -- Milestone v1.20 archived and marked shipped
progress:
  total_phases: 10
  completed_phases: 10
  total_plans: 22
  completed_plans: 22
  percent: 100
---

# Project State: Threadline

## Project Reference

**Core Value**: Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current Focus**: v1.20 — Scale and Governance Depth is shipped. The planning surface is reset for the next milestone definition cycle.

## Current Position

Phase: none — milestone closed
Plan: none
Status: Awaiting next milestone definition
Last activity: 2026-05-24 -- Archived v1.20 and cleared open-artifact audit

## Performance Metrics

- **Total Phases**: 10 (Phases 75-84) — defined in `.planning/ROADMAP.md`
- **Phases Completed**: 10 of 10 phases and 22 of 22 plans are complete for v1.20
- **Requirements Covered**: 13 of 13 mapped (INFRA 2, RET 3, VIEW 2, EXP 4, ADAPT 2)
- **Last Milestone**: v1.19 — Integration Breadth (shipped 2026-05-08)
- **Milestone Readiness**: v1.20 shipped on 2026-05-24

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
- 2026-05-23: Phase 82 repaired default operator-surface session handoff so saved views are actor-owned on the normal `actor_fn` mount path, then backfilled Phase 77 verification and validation.
- 2026-05-23: Phase 83 repaired the built-in export runtime, lifecycle truth, and cleanup path, then backfilled Phase 78 verification and validation on the repaired tree.
- 2026-05-24: Phase 84 closed actor-owned export delivery, configured-path Oban/S3 integration proof, and the final Phase 79/84 evidence chain, clearing the remaining milestone blockers.
- 2026-05-24: `SEED-002` was marked shipped with v1.20 and `SEED-003` was retired as a dormant implementation seed after its future-strategy value was captured elsewhere.

### Todos

- [ ] Run `/gsd-new-milestone` to define the next milestone requirements and roadmap.

### Blockers

- None. v1.20 is closed.

## Session Continuity

- **Last Action**: Archived v1.20 after clearing the milestone close audit and synchronizing the authoritative planning surfaces.
- **Next Step**: Start the next milestone with `/gsd-new-milestone`.

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-06:

| Category | Item | Status |
|----------|------|--------|
| seed | SEED-001-sigra-integration-adapter | acknowledged stale at close; promoted into Phase 44 and shipped in v1.14 |
| nyquist | phase-53-54-validation-bookkeeping | verification evidence exists, but `53-VALIDATION.md` and `54-VALIDATION.md` were not created during milestone execution |
