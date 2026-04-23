---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: — Adoption & release readiness
status: between_milestones
last_updated: "2026-04-23T12:00:00.000Z"
last_activity: 2026-04-23 — v1.4 phases 15–18 complete; Hex **0.2.0** in `mix.exs` (publish `v0.2.0` when ready).
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 0
  completed_plans: 0
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-23)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** Between milestones — **`/gsd-new-milestone`** for **v1.5**. v1.4 delivered onboarding/README, `guides/production-checklist.md`, `Threadline.Query.timeline_repo!/2` + validation order, **0.2.0** + CHANGELOG + ExDoc updates.

## Current Position

Phase: Not started (next milestone)

Plan: —

Status: Milestone v1.4 complete; awaiting v1.5 definition

Last activity: 2026-04-23 — v1.4 adoption & release readiness shipped in-repo.

## Performance metrics

Phases 15–18 — verification: `mix ci.all` (includes `verify.doc_contract`).

## Accumulated context

### Decisions

v1.4 intentionally avoided new capture semantics; focus was docs, operator checklist, actionable `ArgumentError` messages for timeline/export, and semver **0.2.0** to signal capabilities since the first Hex **0.1.0** release.

### Pending todos

1. Maintainer: tag **`v0.2.0`** at the 0.2.0 release commit and run **`mix hex.publish`** when ready (see CONTRIBUTING).
2. Run `DB_PORT=5433 MIX_ENV=test mix ci.all` when using Docker Postgres on host port 5433.

### Blockers / concerns

- Agent environment may lack PostgreSQL; CI is the authoritative signal for DB-backed tests.

## Session continuity

**Closed milestone:** v1.4 — 2026-04-23

**Next:** `/gsd-new-milestone` — define **v1.5**.

**Prior milestone:** v1.3 — shipped 2026-04-23 (archive: `.planning/milestones/v1.3-*.md`).

**Completed phases:** 15 (Onboarding) — 2026-04-23; 16 (Production checklist) — 2026-04-23; 17 (DX) — 2026-04-23; 18 (Release 0.2.0) — 2026-04-23
