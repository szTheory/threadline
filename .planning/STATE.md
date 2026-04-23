---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Before-values & developer tooling
status: ready
stopped_at: null
last_updated: "2026-04-23T12:00:00.000Z"
last_activity: 2026-04-23
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-23)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** Milestone v1.2 — Phases 9–11 (before-values, verify + doc contracts, backfill)

## Current Position

Phase: 9 — Not started

Plan: —

Status: Roadmap approved; ready to discuss or plan Phase 9

Last activity: 2026-04-23 — Milestone v1.2 roadmap created (Phases 9–11)

## Performance metrics

_Velocity for v1.2 will be recorded after the first phase completes._

## Accumulated context

### Decisions

Capture substrate remains **Path B** (custom `Threadline.Capture.TriggerSQL`) per archived `gate-01-01.md`. v1.2 extends triggers and schema only in ways that preserve PgBouncer-safe capture (no `SET LOCAL` in the capture path).

### Pending todos

1. Run `/gsd-discuss-phase 9` or `/gsd-plan-phase 9` for **Before-values capture**.

### Blockers / concerns

- None at milestone open.

## Session continuity

**Opened milestone:** v1.2 — 2026-04-23

**Next:** `/gsd-discuss-phase 9` (or `/gsd-plan-phase 9`)
