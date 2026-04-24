---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: milestone
status: active
last_updated: "2026-04-24T01:52:00Z"
last_activity: 2026-04-24 -- /gsd-execute-phase 20 — verification gaps_found (ADOP-03); no SUMMARY until pilot lands
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 1
  completed_plans: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-23)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** Phase 20 — first-external-pilot

## Current Position

Phase: 20 (first-external-pilot) — AWAITING EXTERNAL PILOT

Plan: 0 of 1 complete (`PLAN.md` checklist; `20-VERIFICATION.md` = gaps_found until ADOP-03)

Status: v1.5 open — Phase 19 complete; Phase 20 blocked on **ADOP-03** (see `20-VERIFICATION.md`)

Last activity: 2026-04-24 -- execute-phase 20 ran verifier gate; backlog still pre-pilot

## Performance metrics

Verification: `DB_PORT=5433 MIX_ENV=test mix ci.all` (includes `verify.doc_contract`).

## Accumulated context

### Decisions

- **Integrator-led v1.5:** docs and pilot matrix before new exploration APIs.
- **Hex 0.2.0:** published via tag-triggered workflow after **`v0.2.0`** push.

### Pending todos

1. **Phase 20 (external):** Host fills [`guides/adoption-pilot-backlog.md`](../guides/adoption-pilot-backlog.md) per [PLAN.md](phases/20-first-external-pilot/PLAN.md); merge evidence to `main`; triage every **`Issue`** row; mark **ADOP-03** complete in `REQUIREMENTS.md`. Then **`/gsd-execute-phase 20`** on `main` for verification and phase completion.
2. When cutting the next Hex release after doc-only commits on `main`, bump **`@version`** (e.g. **0.2.1**) and add a dated **`CHANGELOG`** section.

### Blockers / concerns

- **ADOP-03** requires a credible staging/production-like pilot (see [20-CONTEXT.md](phases/20-first-external-pilot/20-CONTEXT.md)); not automatable inside the repo.

## Session continuity

**Open milestone:** v1.5 — opened 2026-04-23

**Next (pick one):**

- **After pilot PR is on `main`:** `/gsd-execute-phase 20` — code review, regression checks, verifier, `phase.complete` / roadmap updates.
- **Before pilot is ready:** `/gsd-progress` — status; no need to re-run execute-phase until backlog evidence exists.

**Prior shipped:** v1.4 — 2026-04-23 (archive: `.planning/milestones/v1.4-*.md`).

**Completed phases:** 19 (Adoption operator docs) — 2026-04-23
