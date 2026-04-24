---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: milestone
status: executing
last_updated: "2026-04-24T01:05:26.117Z"
last_activity: 2026-04-24 -- Phase 20 execution started
progress:
  total_phases: 2
  completed_phases: 0
  total_plans: 1
  completed_plans: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-23)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** Phase 20 — first-external-pilot

## Current Position

Phase: 20 (first-external-pilot) — EXECUTING

Plan: 1 of 1

Status: Executing Phase 20

Last activity: 2026-04-24 -- Phase 20 execution started

## Performance metrics

Verification: `DB_PORT=5433 MIX_ENV=test mix ci.all` (includes `verify.doc_contract`).

## Accumulated context

### Decisions

- **Integrator-led v1.5:** docs and pilot matrix before new exploration APIs.
- **Hex 0.2.0:** published via tag-triggered workflow after **`v0.2.0`** push.

### Pending todos

1. Run **Phase 20**: one staging/production-like host fills [`guides/adoption-pilot-backlog.md`](../guides/adoption-pilot-backlog.md); triage `Issue` rows; then `/gsd-transition` or extend requirements for v1.6 as needed.
2. When cutting the next Hex release after doc-only commits on `main`, bump **`@version`** (e.g. **0.2.1**) and add a dated **`CHANGELOG`** section.

### Blockers / concerns

- None in-repo; external pilot availability is the gating item for ADOP-03.

## Session continuity

**Open milestone:** v1.5 — opened 2026-04-23

**Next:** Host runs [PLAN.md](phases/20-first-external-pilot/PLAN.md) checklist → evidence PR to `main` for [`guides/adoption-pilot-backlog.md`](../guides/adoption-pilot-backlog.md) → triage → maintainer closes **ADOP-03** in `REQUIREMENTS.md`. Re-run `/gsd-execute-phase 20` after evidence lands to drive verification / completion. Context: [20-CONTEXT.md](phases/20-first-external-pilot/20-CONTEXT.md).

**Prior shipped:** v1.4 — 2026-04-23 (archive: `.planning/milestones/v1.4-*.md`).

**Completed phases:** 19 (Adoption operator docs) — 2026-04-23
