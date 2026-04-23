---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: — Adoption feedback loop
status: in_progress
last_updated: "2026-04-23T21:50:00.000Z"
last_activity: 2026-04-23 — v1.5 opened; Hex 0.2.0 published; Phase 19 docs landed on main.
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 0
  completed_plans: 0
  percent: 50
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-23)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** **v1.5** — close **ADOP-03** with a real host pilot using [`guides/adoption-pilot-backlog.md`](../guides/adoption-pilot-backlog.md) + [`guides/production-checklist.md`](../guides/production-checklist.md).

## Current Position

Phase: 20 — First external pilot (pending host)

Plan: —

Status: Phase 19 complete; awaiting pilot evidence for ADOP-03

Last activity: 2026-04-23 — v0.2.0 tag + Hex publish; adoption pilot backlog + telemetry domain reference shipped.

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

**Next:** `/gsd-discuss-phase 20` or `/gsd-plan-phase 20` — pilot protocol and evidence capture for **ADOP-03**.

**Prior shipped:** v1.4 — 2026-04-23 (archive: `.planning/milestones/v1.4-*.md`).

**Completed phases:** 19 (Adoption operator docs) — 2026-04-23
