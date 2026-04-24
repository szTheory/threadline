---
gsd_state_version: 1.0
milestone: v1.11
milestone_name: — Composable incident surface
status: defining_requirements
last_updated: "2026-04-24T12:00:00.000Z"
last_activity: 2026-04-24 — Milestone **v1.11** opened; **COMP-01–COMP-03** implemented in-repo (Phase **37** slice); planning KPI **integrator composition speed**.
progress:
  total_phases: 1
  completed_phases: 1
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md`

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** **v1.11** — prove **`audit_transaction_id` → `GET …/changes`** composition in **`examples/threadline_phoenix/`** with doc anchor **`COMP-EXAMPLE-INCIDENT-JSON`**.

**Milestone KPI (locked):** **Integrator composition speed** — not a dedicated Hex-only release milestone and not as-of exploration for this slice.

## Current Position

Phase: **37** — Example incident JSON path — **complete** (implementation + verification in one slice)

Plan: —

Status: **v1.11** requirements **COMP-01–COMP-03** satisfied in-repo; run **`/gsd-complete-milestone`** when ready to archive and reset living files.

Last activity: 2026-04-24 — **v1.11** planning artifacts + example **`AuditTransactionController`**, **`PostsIncidentJsonPathTest`**, domain-reference + doc contract.

## Performance metrics

Verification: `DB_PORT=5433 MIX_ENV=test mix ci.all` is the local parity gate (includes **`mix verify.example`** for `examples/threadline_phoenix/`).

## Accumulated context

### Decisions

- **v1.11 scope:** Composition only — example HTTP JSON on **`Threadline.audit_changes_for_transaction/2`** + **`Threadline.change_diff/2`**; no LiveView, no **`threadline_web`**, no capture semantics changes.
- **KPI choice:** **Integrator composition speed** over Hex semver signal or as-of exploration for this milestone (see **`.planning/REQUIREMENTS.md`** intro).

### Pending todos

- Optional: **`/gsd-complete-milestone`** when audit + archive for **v1.11** is desired.

### Blockers / concerns

- None.

## Session continuity

**In-flight milestone:** **v1.11** — Phase **37** — composition / incident JSON example path.

**Prior shipped:** **v1.10** — Phases 31–36 — 2026-04-24 (archived).

**Verification pointers:** **`mix verify.example`**, **`test/threadline/exploration_routing_doc_contract_test.exs`**, **`examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs`**.
