---
gsd_state_version: 1.0
milestone: v1.8
milestone_name: — Close the support loop
status: planning
last_updated: "2026-04-24T12:58:38.149Z"
last_activity: 2026-04-24 — `/gsd-discuss-phase 27` — LOOP-03 decisions (test + README, HTTP `record_action`, timeline CI + export snippet, layered README).
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 5
  completed_plans: 4
  percent: 80
---

# Project State

## Project Reference

See: `.planning/PROJECT.md`

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** **v1.8** — Phase **27** next (example app correlation path, LOOP-03); Phases **25–26** delivered.

## Current Position

Phase: **27** — **context gathered** (`27-CONTEXT.md`); plan when ready.

Plan: —

Status: Phase 26 complete; Phase 27 discussed — implementation decisions locked in `.planning/phases/27-example-app-correlation-path/27-CONTEXT.md`. Milestone v1.8 remains open until Phase 27 ships.

Last activity: 2026-04-24 — `/gsd-discuss-phase 27` — LOOP-03 decisions (test + README, HTTP `record_action`, timeline CI + export snippet, layered README).

## Performance metrics

Verification: `DB_PORT=5433 MIX_ENV=test mix ci.all` is the local parity gate (includes **`mix verify.example`** for `examples/threadline_phoenix/`).

## Accumulated context

### Decisions

- **v1.8 scope:** SaaS trajectory chunk 1 — exploration layer focus (timeline/export + operator docs); excludes LiveView and `threadline_web`.
- **v1.9 telescope:** Ops-at-volume (telemetry, health, indexing, retention alignment) after v1.8 closes.
- **Phase 25 (LOOP-01):** Shipped — strict `AuditAction` inner join when `:correlation_id` set; export uses optional left join when unset for JSON `action` metadata; trim + reject empty/overlong; default CSV stable + `include_action_metadata`; see `CHANGELOG.md` and `25-CONTEXT.md`.
- **Phase 26 (LOOP-02, LOOP-04):** Shipped — `## Support incident queries` in `guides/domain-reference.md` and `guides/production-checklist.md`; marker `LOOP-04-SUPPORT-INCIDENT-QUERIES`; `test/threadline/support_playbook_doc_contract_test.exs`.
- **Phase 27 (LOOP-03) — discuss:** Example app — integration test as canonical proof (`record_action` in same txn as HTTP create, `timeline/2` + `:correlation_id`); README layered + export/`jq` snippet + cross-link to test; remove stale `action_id` disclaimer once code matches. See `27-CONTEXT.md`.

### Pending todos

1. **Phase 27** — LOOP-03 — **plan + execute** (`/gsd-plan-phase 27`).

### Blockers / concerns

- None.

## Session continuity

**Prior shipped:** v1.7 — Phases 22–24 — 2026-04-24.

**Archives:** `.planning/milestones/v1.7-ROADMAP.md`, `.planning/milestones/v1.7-REQUIREMENTS.md`

**Resume:** `.planning/phases/27-example-app-correlation-path/27-CONTEXT.md` — then `/gsd-plan-phase 27`.

**Planned Phase:** 27 (Example app correlation path) — 1 plans — 2026-04-24T12:58:38.116Z
