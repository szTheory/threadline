---
gsd_state_version: 1.0
milestone: v1.6
milestone_name: host-staging-pooler-parity
status: defining_requirements
last_updated: "2026-04-23T22:00:00Z"
last_activity: 2026-04-23 — Milestone v1.6 started (STG-01); requirements + roadmap authored
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-23)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** **v1.6** — Host staging / pooler parity (**STG-01**–**STG-03**). Phase **21** on roadmap.

## Current Position

Phase: **21** — Host staging & pooler parity (not started)

Plan: —

Status: Requirements and roadmap defined; ready for `/gsd-discuss-phase 21` or `/gsd-plan-phase 21`

Last activity: 2026-04-23 — `/gsd-new-milestone` confirmed; `phases.clear`; planning docs committed

## Performance metrics

Verification: `DB_PORT=5433 MIX_ENV=test mix ci.all` (includes `verify.doc_contract`). PgBouncer topology: `THREADLINE_PGBOUNCER_TOPOLOGY=1` + CONTRIBUTING parity section.

## Accumulated context

### Decisions

- **v1.6 scope:** Host-owned staging depth only; no new capture APIs unless STG evidence forces it.
- **Phase numbering:** Continues from v1.5 (**Phase 21**); no `--reset-phase-numbers`.

### Pending todos

1. **`/gsd-discuss-phase 21`** or **`/gsd-plan-phase 21`** — Execute host STG evidence and doc updates.
2. When cutting the next Hex release after substantive `main` commits, bump **`@version`** and **`CHANGELOG`**.

### Blockers / concerns

- **STG** work is **host-dependent**; maintainer can only land doc/checklist/repo affordances — not external staging.

## Session continuity

**Milestone v1.6:** opened 2026-04-23.

**Prior shipped:** v1.5 — 2026-04-23 (archive: `.planning/milestones/v1.5-*.md`).

**Completed phases (v1.5):** 19–20 — 2026-04-23
