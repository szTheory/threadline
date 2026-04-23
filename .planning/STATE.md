---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: — Production adoption
status: planning
last_updated: "2026-04-23T20:30:00.000Z"
last_activity: 2026-04-23 — Phase 12 discuss-phase complete (CONTEXT + research synthesis)
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-23)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** Milestone **v1.3** — Phase 12 context locked; next **`/gsd-plan-phase 12`** (retention / export follow in Phases 13–14).

## Current Position

Phase: 12 (context gathered; not implemented)

Plan: — / —

Status: **Discuss complete** — see `.planning/phases/12-redaction-at-capture-time/12-CONTEXT.md`

Last activity: 2026-04-23 — Phase 12 CONTEXT.md committed (config-first policy, mask semantics, exclude/mask/`changed_from` rules, per-table trigger layout)

## Performance metrics

_v1.3 not started._

## Accumulated context

### Decisions

Capture substrate remains **Path B** (custom `Threadline.Capture.TriggerSQL`) per archived `gate-01-01.md`. v1.3 changes must preserve PgBouncer-safe capture (no new session-local writes in the trigger path unless explicitly gated and reviewed).

**Phase 12 (redaction):** Canonical exclude/mask policy in **`config :threadline, …`**; Mix task loads config; per-table PL/pgSQL only when redaction and/or `store_changed_from`; shared SQL core to limit duplication; `exclude ∩ mask` hard error; mask applies symmetrically to `data_after` and `changed_from`; whole-value mask for json/jsonb columns. Full detail: `12-CONTEXT.md`.

### Pending todos

1. Run `MIX_ENV=test mix ci.all` locally with PostgreSQL when touching integration paths.

### Blockers / concerns

- Agent environment may lack PostgreSQL; CI is the authoritative signal for DB-backed tests.

## Session continuity

**Opened milestone:** v1.3 — 2026-04-23

**Next:** `/gsd-plan-phase 12` — redaction at capture time (REDN-01, REDN-02). Resume file: `.planning/phases/12-redaction-at-capture-time/12-CONTEXT.md`.

**Prior milestone:** v1.2 — shipped 2026-04-23 (archive: `.planning/milestones/v1.2-*.md`).
