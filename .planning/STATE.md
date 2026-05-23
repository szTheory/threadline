---
gsd_state_version: 1.0
milestone: v1.20
milestone_name: — Scale and Governance Depth
status: planning
last_updated: "2026-05-23T21:14:08.791Z"
last_activity: 2026-05-23
progress:
  total_phases: 10
  completed_phases: 9
  total_plans: 19
  completed_plans: 19
  percent: 90
---

# Project State: Threadline

## Project Reference

**Core Value**: Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current Focus**: Milestone v1.20 — Scale and Governance Depth remains in progress after Phase 81 repaired the retention runtime and closed Phase 76 evidence. RET requirements are now closed; Phases 82-84 still own saved-view handoff, built-in export lifecycle, and adapter-backed delivery closure.

## Current Position

Phase: 84
Plan: Not started
Status: Ready to plan
Last activity: 2026-05-23

## Performance Metrics

- **Total Phases**: 10 (Phases 75-84) — defined in `.planning/ROADMAP.md`
- **Phases Completed**: 7 of 10 phases have complete plan execution; repaired final-tree closure is now in place for 75, 76 via Phase 81, 79, 80, and 81
- **Requirements Covered**: 13 of 13 mapped (INFRA 2, RET 3, VIEW 2, EXP 4, ADAPT 2)
- **Last Milestone**: v1.19 — Integration Breadth (shipped 2026-05-08)
- **Milestone Readiness**: v1.20 remains open; retention closure is now complete, but Phases 82-84 still block milestone closeout

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

- [ ] Run `/gsd-execute-phase 82` to execute the saved-view session handoff repair plans.
- [ ] Run `/gsd-plan-phase 83` to repair the built-in async export lifecycle.
- [ ] Run `/gsd-plan-phase 84` to complete export delivery and adapter integration.

### Blockers

- Milestone v1.20 cannot be closed until Phases 82-84 repair the remaining audit gaps identified on 2026-05-23.

## Session Continuity

- **Last Action**: Planned Phase 82 with a two-plan split: default mount-path actor handoff/runtime repair plus Phase 77 verification/validation closeout.
- **Next Step**: Run `/gsd-execute-phase 82` to implement the saved-view actor/session handoff repair before planning or executing later export-runtime phases.

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-06:

| Category | Item | Status |
|----------|------|--------|
| seed | SEED-001-sigra-integration-adapter | acknowledged stale at close; promoted into Phase 44 and shipped in v1.14 |
| nyquist | phase-53-54-validation-bookkeeping | verification evidence exists, but `53-VALIDATION.md` and `54-VALIDATION.md` were not created during milestone execution |
