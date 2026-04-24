---
gsd_state_version: 1.0
milestone: v1.8
milestone_name: — Close the support loop
status: milestone_complete
last_updated: "2026-04-24T13:09:00.639Z"
last_activity: 2026-04-24 — Phase 27 shipped (LOOP-03); v1.8 milestone complete
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 5
  completed_plans: 5
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md`

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** **v1.8 closed** — next milestone planning: **v1.9** (ops-at-volume); see `.planning/MILESTONES.md`.

## Current Position

Phase: **27** — **complete** (`27-VERIFICATION.md`, `27-01-SUMMARY.md`)

Plan: **27-01** complete

Status: **v1.8 — Close the support loop** milestone complete (Phases 25–27).

Last activity: 2026-04-24 — Phase 27 execution — LOOP-03 example correlation path shipped

## Performance metrics

Verification: `DB_PORT=5433 MIX_ENV=test mix ci.all` is the local parity gate (includes **`mix verify.example`** for `examples/threadline_phoenix/`).

## Accumulated context

### Decisions

- **v1.8 scope:** SaaS trajectory chunk 1 — exploration layer focus (timeline/export + operator docs); excludes LiveView and `threadline_web`.
- **v1.9 telescope:** Ops-at-volume (telemetry, health, indexing, retention alignment) after v1.8 closes.
- **Phase 25 (LOOP-01):** Shipped — strict `AuditAction` inner join when `:correlation_id` set; export uses optional left join when unset for JSON `action` metadata; trim + reject empty/overlong; default CSV stable + `include_action_metadata`; see `CHANGELOG.md` and `25-CONTEXT.md`.
- **Phase 26 (LOOP-02, LOOP-04):** Shipped — `## Support incident queries` in `guides/domain-reference.md` and `guides/production-checklist.md`; marker `LOOP-04-SUPPORT-INCIDENT-QUERIES`; `test/threadline/support_playbook_doc_contract_test.exs`.
- **Phase 27 (LOOP-03):** Shipped — `Blog.create_post/2` calls `record_action` + links `audit_transactions.action_id`; `ThreadlinePhoenixWeb.PostsCorrelationPathTest`; README correlation + `export_json` / `jq`; see `27-CONTEXT.md`, `27-01-SUMMARY.md`.

### Pending todos

1. **v1.9** — Open **MILESTONES.md** / roadmap when ready to start ops-at-volume work.

### Blockers / concerns

- None.

## Session continuity

**Prior shipped:** v1.7 — Phases 22–24 — 2026-04-24.

**Archives:** `.planning/milestones/v1.7-ROADMAP.md`, `.planning/milestones/v1.7-REQUIREMENTS.md`

**Resume:** `.planning/MILESTONES.md` — v1.9 planning when scheduled.

**Last completed phase:** 27 (Example app correlation path) — 2026-04-24
