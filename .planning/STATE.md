---
gsd_state_version: 1.0
milestone: v1.21
milestone_name: — Scoped Support / Operator Proof
status: ready_for_closeout
last_updated: "2026-05-25T16:25:55.005Z"
last_activity: 2026-05-25 -- Phase 94 rerun, audit refresh, and closeout verdict completed
progress:
  total_phases: 10
  completed_phases: 10
  total_plans: 21
  completed_plans: 21
  percent: 100
---

# Project State: Threadline

## Project Reference

**Core Value**: Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current Focus**: v1.21 — Scoped Support / Operator Proof. One canonical `/audit` mount, host-owned auth and scope semantics, and one exact proven support-lane claim on the current tree: timeline, actor, transaction, support-scoped row history / as-of, and export denial posture through host-owned seams.

## Current Position

Phase: 94 (authority-surface-reconciliation-and-closeout) — COMPLETE
Plan: 2 of 2
Status: v1.21 proof chain is phase-complete and ready for milestone closeout
Last activity: 2026-05-25 -- Phase 94 rerun, audit refresh, and closeout verdict completed

## Performance Metrics

- **Total Phases**: 10 (Phases 85-94) — defined in `.planning/ROADMAP.md`
- **Phases Completed**: 10 of 10 phases complete and 21 of 21 tracked plans complete for v1.21
- **Requirements Covered**: 12 of 12 mapped for v1.21 (`SCOPE-01`, `SCOPE-02`, `SCOPE-03`, `AUTH-01`, `AUTH-02`, `ADOPT-01`, `ADOPT-02`, `ADOPT-03`, `UX-01`, `UX-02`, `DOC-01`, `DOC-02`)
- **Last Milestone**: v1.20 — Scale and Governance Depth (shipped 2026-05-24)
- **Milestone Readiness**: GREEN. The named proof rerun, Phase 94 artifacts, and refreshed `v1.21-MILESTONE-AUDIT.md` now agree that v1.21 is ready for milestone closeout.

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
- 2026-05-25: Phase 90 backfilled the missing Phase 85 verification chain, creating `85-VERIFICATION.md` and `85-VALIDATION.md` and closing `SCOPE-03`, `AUTH-02`, and `ADOPT-03` against the current-tree support-lane claim.
- 2026-05-25: Phase 91 backfilled the missing Phase 86 verification chain, added explicit query/helper/mounted proof for support-scoped row history / as-of, repaired `TransactionLive` repo threading for the mounted history path, and closed `SCOPE-01` plus `SCOPE-02` on the current tree.
- 2026-05-25: Phase 92 backfilled the missing Phase 87 verification chain, created `87-VERIFICATION.md` and `87-VALIDATION.md`, and closed `ADOPT-01` plus `ADOPT-02` against the current-tree canonical `/audit` and example-host proof.
- 2026-05-25: Phase 93 backfilled the missing Phase 88 verification chain, created `88-VERIFICATION.md` and `88-VALIDATION.md`, and closed `AUTH-01`, `UX-01`, and `UX-02` against the current-tree denial/fallback proof.
- 2026-05-25: Phase 94 reran `mix verify.doc_contract`, `mix verify.example`, and the targeted root support-lane suite; wrote `94-VERIFICATION.md` / `94-VALIDATION.md`; refreshed the v1.21 milestone audit; and closed `DOC-01` plus `DOC-02` only after the rerun evidence stayed green.
- [Phase 94]: Treated the Phase 94 rerun bundle as the only authority for closing DOC-01 and DOC-02; 94-01 summary frontmatter was explicitly non-authoritative. — Requirement closure stayed tied to current-tree rerun evidence and the refreshed audit, not inherited summary metadata.
- [Phase 94]: Passed the refreshed milestone audit while keeping plan-level 90/91 validation frontmatter drift documented as non-blocking tech debt because the canonical 85/86 phase artifacts are finalized. — The stale draft frontmatter no longer changes milestone truth because the canonical phase artifacts and final rerun bundle are green.

### Todos

- [ ] Run milestone closeout for v1.21 using the refreshed green audit and Phase 94 summary bundle.

### Blockers

- None. Phase 94 closed the remaining milestone blockers for v1.21.

## Session Continuity

- **Last Action**: Closed Phase 94 by rerunning the named proof surfaces, refreshing the v1.21 milestone audit, and closing `DOC-01` / `DOC-02` on green evidence.
- **Next Step**: Complete milestone closeout for v1.21.

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-06:

| Category | Item | Status |
|----------|------|--------|
| seed | SEED-001-sigra-integration-adapter | acknowledged stale at close; promoted into Phase 44 and shipped in v1.14 |
| nyquist | phase-53-54-validation-bookkeeping | verification evidence exists, but `53-VALIDATION.md` and `54-VALIDATION.md` were not created during milestone execution |
