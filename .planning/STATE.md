---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: — Production adoption
status: milestone_complete
last_updated: "2026-04-23T21:30:00.000Z"
last_activity: 2026-04-23 — Phase 14 export shipped (`Threadline.Export`, `mix threadline.export`).
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 6
  completed_plans: 6
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-23)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** Milestone **v1.3** complete (phases 12–14 shipped). Next: define v1.4 / polish milestone in `ROADMAP.md` when ready.

## Current Position

Phase: 14

Plan: 2/2 complete

Status: Milestone complete

Last activity: 2026-04-23 — Phase 14 export shipped.

## Performance metrics

Phases 12–14 complete — see `12-VERIFICATION.md`, `13-VERIFICATION.md`, and `14-VERIFICATION.md`.

## Accumulated context

### Decisions

Capture substrate remains **Path B** (custom `Threadline.Capture.TriggerSQL`) per archived `gate-01-01.md`. v1.3 changes must preserve PgBouncer-safe capture (no new session-local writes in the trigger path unless explicitly gated and reviewed).

**Phase 12 (redaction):** Shipped — `config :threadline, :trigger_capture` with per-table `exclude` / `mask`; `RedactionPolicy` validates at codegen; README and `guides/domain-reference.md` document semantics. Context: `12-CONTEXT.md`.

**Phase 13 (retention & purge):** Shipped — `Threadline.Retention.Policy`, `Threadline.Retention.purge/1`, `mix threadline.retention.purge`, config `:retention`, docs in README + `guides/domain-reference.md`. See `13-VERIFICATION.md`.

**Phase 14 (export):** Shipped — `Threadline.Export`, shared `validate_timeline_filters!/1` / `timeline_query/1`, `mix threadline.export`, README + domain guide. See `14-VERIFICATION.md`.

### Pending todos

1. Run `DB_PORT=5433 MIX_ENV=test mix ci.all` when using Docker Postgres on host port 5433.

### Blockers / concerns

- Agent environment may lack PostgreSQL; CI is the authoritative signal for DB-backed tests.

## Session continuity

**Opened milestone:** v1.3 — 2026-04-23

**Next:** Plan next milestone (v1.4 candidate: onboarding & polish in `REQUIREMENTS.md`).

**Prior milestone:** v1.2 — shipped 2026-04-23 (archive: `.planning/milestones/v1.2-*.md`).

**Completed phases:** 12 (Redaction) — 2026-04-23; 13 (Retention & batched purge) — 2026-04-23; 14 (Export) — 2026-04-23
