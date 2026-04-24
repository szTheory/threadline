---
gsd_state_version: 1.0
milestone: v1.10
milestone_name: Support-grade exploration primitives
status: defining_requirements
last_updated: "2026-04-24T12:00:00.000Z"
last_activity: 2026-04-24 — Milestone v1.10 started (requirements + roadmap defined).
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md`

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** **v1.10** — Support-grade exploration primitives (Phases **31–33** on `.planning/ROADMAP.md`).

## Current Position

Phase: Not started (awaiting discuss / plan)

Plan: —

Status: Ready to execute — requirements and roadmap defined for v1.10.

Last activity: 2026-04-24 — Milestone v1.10 initialized via `/gsd-new-milestone`.

## Performance metrics

Verification: `DB_PORT=5433 MIX_ENV=test mix ci.all` is the local parity gate (includes **`mix verify.example`** for `examples/threadline_phoenix/`).

## Accumulated context

### Decisions

- **v1.10 scope:** Exploration **primitives** only (diff presentation + transaction-scoped reads + operator docs) — no LiveView, no new capture semantics, no Hex bump unless separately decided.
- **Research:** Skipped for this milestone — brownfield APIs grounded in existing `Threadline.Query` / domain reference; no parallel ecosystem research pass.

### Pending todos

1. `/gsd-discuss-phase 31` (optional) then `/gsd-plan-phase 31` — field-level change presentation (**XPLO-01**).

### Blockers / concerns

- None.

## Session continuity

**Active milestone:** **v1.10** — Phases 31–33 — opened 2026-04-24.

**Prior shipped:** **v1.9** — Phases 28–30 — 2026-04-24 (archived).

**Next planned phase:** 31 — Field-level change presentation

**Planned Phase:** 31
