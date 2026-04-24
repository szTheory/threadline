---
gsd_state_version: 1.0
milestone: v1.8
milestone_name: — Close the support loop
status: planning
last_updated: "2026-04-24T12:16:13.318Z"
last_activity: 2026-04-24 — Phase 25 discuss complete; 25-CONTEXT.md captured
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 2
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md`

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** **v1.8** — support loop (LOOP-01 — LOOP-04); Phases **25–27**.

## Current Position

Phase: **25** — context gathered; ready for `/gsd-plan-phase 25`

Plan: —

Status: LOOP-01 implementation decisions locked in `.planning/phases/25-correlation-aware-timeline-export/25-CONTEXT.md`

Last activity: 2026-04-24 — Phase 25 discuss complete; 25-CONTEXT.md captured

## Performance metrics

Verification: `DB_PORT=5433 MIX_ENV=test mix ci.all` is the local parity gate (includes **`mix verify.example`** for `examples/threadline_phoenix/`).

## Accumulated context

### Decisions

- **v1.8 scope:** SaaS trajectory chunk 1 — exploration layer focus (timeline/export + operator docs); excludes LiveView and `threadline_web`.
- **v1.9 telescope:** Ops-at-volume (telemetry, health, indexing, retention alignment) after v1.8 closes.
- **Phase 25 (LOOP-01):** Strict `AuditAction` join when `:correlation_id` set; trim + reject empty/overlong; additive JSON action ids; default CSV stable + opt-in extended columns; JSON-first timeline↔export parity test — see `25-CONTEXT.md`.

### Pending todos

1. **Phase 25** — Implement LOOP-01 (`:correlation_id` on timeline + export + tests).
2. **Phase 26** — LOOP-02 + LOOP-04 (guides + doc contract anchors).
3. **Phase 27** — LOOP-03 (example app correlation path).

### Blockers / concerns

- None for planning open.

## Session continuity

**Prior shipped:** v1.7 — Phases 22–24 — 2026-04-24.

**Archives:** `.planning/milestones/v1.7-ROADMAP.md`, `.planning/milestones/v1.7-REQUIREMENTS.md`

**Planned Phase:** 25 (Correlation-aware timeline & export) — 2 plans — 2026-04-24T12:16:13.311Z
