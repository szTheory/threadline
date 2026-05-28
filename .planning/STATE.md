---
gsd_state_version: 1.0
milestone: v1.26
milestone_name: Auth Lane Breadth
status: Ready for 119-02-PLAN.md
last_updated: "2026-05-28T01:39:18.103Z"
last_activity: 2026-05-28 -- Completed 119-01-PLAN.md
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 2
  completed_plans: 1
  percent: 0
---

# Project State: Threadline

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-27)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current focus:** Phase 119 — phx.gen.auth Integration Guide & Lane

## Current Position

Phase: 119 — phx.gen.auth Integration Guide & Lane (IN PROGRESS)
Plan: 1 of 2 complete
Status: Ready for 119-02-PLAN.md
Last activity: 2026-05-28 -- Completed 119-01-PLAN.md

## Performance Metrics

- **Last Milestone Shipped**: v1.25 — Adopter-Ready Release & First-Hour Truth (2026-05-28)
- **Scope completion (assessment)**: ~88–92% for stated narrow scope; phx.gen.auth lane is largest remaining reach gap
- **Hex distribution**: in-repo **0.6.0**; hex.pm latest **0.5.0** (publish via tag `v0.6.0`)

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| external-pilot | v1.27+ pilot unblockers | **Deferred** until sustained real-adopter signal (see PROJECT.md Key Decisions v1.23 re-engagement trigger) |
| maintainer-ops | Hex 0.6.0 publish | Pending tag `v0.6.0` → CI `hex-publish.yml` |
| v1.22 DEFER | COMPLIANCE-PACK, LEGAL-HOLD, IMMUTABLE-ARCHIVE | Deferred until procurement pressure |
| host-class | STG-01 host staging depth | Integrator-owned; [`guides/adoption-pilot-backlog.md`](../guides/adoption-pilot-backlog.md) |

## Accumulated Context

### Decisions

- **119-01 (2026-05-28):** phx guide uses host-owned `MyApp.AuditActor`, not `Threadline.Integrations.Sigra`; reference semantics list Phase 120 proof targets without citing test files.
- **119-01 (2026-05-28):** Optional correlation stays header-first; no `phx-session:` format table (Sigra-only pattern).
- **v1.26 (2026-05-27):** Auth lane breadth over compliance expansion; guide + root proof, not second reference app or Sigra replacement.
- **Diminishing-returns assessment (2026-05-27):** Library engine largely complete; finish phx.gen.auth reach wedge, then shift to adopter-driven maintenance.
- Full decision log: `.planning/PROJECT.md` Key Decisions table.

### Blockers

- None for planning. **Hex publish** is maintainer ops, not a phase blocker.

## Session Continuity

- **Last Action**: Completed 119-01 — shipped `guides/integrations/phx-gen-auth.md` cookbook (89 lines).
- **Next Step**: Execute 119-02 — upgrade-path lane prose (AUTH-LANE-01/02)
- **Resume file**: `.planning/phases/119-phx-gen-auth-integration-guide-lane/119-02-PLAN.md`

## Operator Next Steps

- Execute **119-02-PLAN.md** — add `phx-gen-auth-reference` lane vocabulary to `guides/upgrade-path.md`
- Maintainer: push **`v0.6.0`** tag when ready for hex.pm publish
- Do **not** open external-pilot milestone until sustained adopter signal
