---
gsd_state_version: 1.0
milestone: v1.6
milestone_name: — Host staging / pooler parity
status: milestone_complete
last_updated: "2026-04-24T03:15:00Z"
last_activity: 2026-04-24 — Phase 21 executed; v1.6 STG templates, CONTRIBUTING, checklist, doc contracts landed
progress:
  total_phases: 1
  completed_phases: 1
  total_plans: 2
  completed_plans: 2
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-23)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** **v1.6** shipped (Phase **21** complete). Next milestone not yet opened on roadmap (`phase.complete` returned no next phase).

## Current Position

Phase: **21** — Host staging & pooler parity — **complete** (2026-04-24)

Plan: **21-01**, **21-02** — both SUMMARY + verification recorded

Status: STG backlog templates, CONTRIBUTING host STG section, production-checklist pointer, `ci_topology_contract_test.exs` + `stg_doc_contract_test.exs`; `DB_PORT=5433 MIX_ENV=test mix ci.all` green.

Last activity: 2026-04-24 — `/gsd-execute-phase 21` finished; planning artifacts committed

## Performance metrics

Verification: `DB_PORT=5433 MIX_ENV=test mix ci.all` (includes `verify.doc_contract`). PgBouncer topology: `THREADLINE_PGBOUNCER_TOPOLOGY=1` + CONTRIBUTING parity section.

## Accumulated context

### Decisions

- **v1.6 scope:** Host-owned staging depth only; no new capture APIs unless STG evidence forces it.
- **Phase numbering:** Continues from v1.5 (**Phase 21**); no `--reset-phase-numbers`.

### Pending todos

1. When cutting the next Hex release after substantive `main` commits, bump **`@version`** and **`CHANGELOG`**.
2. Open the next milestone on **`.planning/ROADMAP.md`** when scope is ready (no automatic next phase after 21).

### Blockers / concerns

- **STG** work is **host-dependent**; maintainer can only land doc/checklist/repo affordances — not external staging.

## Session continuity

**Milestone v1.6:** opened 2026-04-23; **Phase 21** completed 2026-04-24.

**Prior shipped:** v1.5 — 2026-04-23 (archive: `.planning/milestones/v1.5-*.md`).

**Completed phases (v1.5):** 19–20 — 2026-04-23

**Completed:** Phase 21 — Host staging & pooler parity — 2/2 plans — 2026-04-24
