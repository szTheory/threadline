---
gsd_state_version: 1.0
milestone: v1.26
milestone_name: Auth Lane Breadth
status: executing
last_updated: "2026-05-28T02:19:40.745Z"
last_activity: 2026-05-28 -- Phase 121 planning complete
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 6
  completed_plans: 4
  percent: 67
---

# Project State: Threadline

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-27)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current focus:** Phase null

## Current Position

Phase: 121
Plan: Not started
Status: Ready to execute
Last activity: 2026-05-28 -- Phase 121 planning complete

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

- **119-02 (2026-05-28):** phx-gen-auth-reference lane vocabulary added to upgrade-path prose only; matrix row deferred to Phase 120; explicit not Sigra-compatible boundary.
- **119-01 (2026-05-28):** phx guide uses host-owned `MyApp.AuditActor`, not `Threadline.Integrations.Sigra`; reference semantics list Phase 120 proof targets without citing test files.
- **119-01 (2026-05-28):** Optional correlation stays header-first; no `phx-session:` format table (Sigra-only pattern).
- **v1.26 (2026-05-27):** Auth lane breadth over compliance expansion; guide + root proof, not second reference app or Sigra replacement.
- **Diminishing-returns assessment (2026-05-27):** Library engine largely complete; finish phx.gen.auth reach wedge, then shift to adopter-driven maintenance.
- Full decision log: `.planning/PROJECT.md` Key Decisions table.

### Blockers

- None for planning. **Hex publish** is maintainer ops, not a phase blocker.

## Session Continuity

- **Last Action**: Completed 119-02 — phx-gen-auth-reference lane prose in `guides/upgrade-path.md`.
- **Next Step**: Phase 120 — matrix row, root integration tests, four-lane doc-contract locks
- **Resume file**: None

## Operator Next Steps

- Plan **Phase 120** — upgrade-path matrix row + root integration tests + doc-contract locks
- Maintainer: push **`v0.6.0`** tag when ready for hex.pm publish
- Do **not** open external-pilot milestone until sustained adopter signal
