---
gsd_state_version: 1.0
milestone: v1.21
milestone_name: — Scoped Support / Operator Proof
status: executing
last_updated: "2026-05-25T06:32:06.341Z"
last_activity: 2026-05-25 -- Phase 89 execution started
progress:
  total_phases: 5
  completed_phases: 4
  total_plans: 11
  completed_plans: 9
  percent: 80
---

# Project State: Threadline

## Project Reference

**Core Value**: Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current Focus**: v1.21 — Scoped Support / Operator Proof. One canonical `/audit` mount, host-owned auth and scope semantics, and a truthful support-safe claim on the current tree.

## Current Position

Phase: 89 (contract-lock-final-verification) — EXECUTING
Plan: 1 of 2
Status: Executing Phase 89
Last activity: 2026-05-25 -- Phase 89 execution started

## Performance Metrics

- **Total Phases**: 5 (Phases 85-89) — defined in `.planning/ROADMAP.md`
- **Phases Completed**: 0 of 5 and 0 of 11 plans complete for v1.21
- **Requirements Covered**: 0 of 12 mapped for v1.21 (SCOPE 3, AUTH 2, ADOPT 3, UX 2, DOC 2)
- **Last Milestone**: v1.20 — Scale and Governance Depth (shipped 2026-05-24)
- **Milestone Readiness**: v1.21 opened on 2026-05-24

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
- 2026-05-24: Post-close repo inspection put Threadline around 85% done for its intended scope: the strongest remaining practical gap is a proven support-safe operator lane, not another broad capability family.
- 2026-05-24: The example app now proves host-owned scoped operator access on `/audit` with support-visible query narrowing and admin-only exports, which should anchor the next milestone framing.
- 2026-05-24: `guides/how-threadline-works.md` still frames retention, saved views, and async export as future work even though v1.20 shipped them; lower confidence in milestone-choice docs until that narrative is reconciled.
- 2026-05-24: Targeted verification exposed a runtime-isolation rough edge: repeated supervised app startup still collides on the globally named `Threadline.Export.TaskSupervisor` in retention-history LiveView tests.
- 2026-05-24: v1.21 was opened after a research-first milestone pass. Recommendation set: keep one canonical `/audit` mount, keep auth and tenant semantics host-owned, keep export as a separate privileged capability, and avoid Threadline-owned RBAC or tenancy DSLs.
- 2026-05-24: Current-tree audit found the main truth gap for the support lane: row history / as-of bypasses the support scope seam today, so the milestone must either scope that path honestly or make it unavailable for support-scoped sessions.
- 2026-05-24: The GSD workflow defaults are already shifted left toward cohesive research and one-shot recommendations, with interactive questions reserved for high-impact decisions such as semver, security model, breaking public API, and scope cuts.

### Todos

- [ ] Execute Phase 85 and lock the exact v1.21 support-lane claim before implementation widens.

### Blockers

- None blocking milestone start.
- Documentation drift: `guides/how-threadline-works.md` still understates shipped governance/export scope.
- Runtime hardening follow-up: retention-history LiveView tests still reveal `Threadline.Export.TaskSupervisor` naming collision under repeated `Threadline.Application` startup.

## Session Continuity

- **Last Action**: Opened v1.21 and wrote fresh requirements plus phases 85-89 around the scoped support/operator lane.
- **Next Step**: Start Phase 85. First force the support-lane claim to be explicit, especially the row history / as-of decision, before any broader UX or docs work lands.

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-06:

| Category | Item | Status |
|----------|------|--------|
| seed | SEED-001-sigra-integration-adapter | acknowledged stale at close; promoted into Phase 44 and shipped in v1.14 |
| nyquist | phase-53-54-validation-bookkeeping | verification evidence exists, but `53-VALIDATION.md` and `54-VALIDATION.md` were not created during milestone execution |
