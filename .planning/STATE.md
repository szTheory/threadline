---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: milestone
status: milestone_complete
last_updated: "2026-04-23T18:00:00Z"
last_activity: 2026-04-23 -- v1.5 complete — ADOP-03 closed; backlog evidence in guides/adoption-pilot-backlog.md; STG-01 tracks host pooler pilot
progress:
  total_phases: 2
  completed_phases: 2
  total_plans: 1
  completed_plans: 1
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-23)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Current focus:** **v1.5** adoption loop — **complete** (Phases 19–20). Next: milestone archive / **v1.6** kickoff when ready; **STG-01** in `REQUIREMENTS.md`.

## Current Position

Phase: **20** (first-external-pilot) — **complete**

Plan: **PLAN.md** evidence landed on **`main`** (`guides/adoption-pilot-backlog.md` + `20-VERIFICATION.md` **passed**)

Status: **Milestone v1.5** requirements satisfied — **ADOP-03** Complete in `REQUIREMENTS.md`

Last activity: 2026-04-23 — Maintainer CI evidence pass merged; `mix ci.all` green; `gsd-sdk phase.complete 20` run

## Performance metrics

Verification: `DB_PORT=5433 MIX_ENV=test mix ci.all` (includes `verify.doc_contract`).

## Accumulated context

### Decisions

- **Integrator-led v1.5:** docs and pilot matrix before new exploration APIs.
- **Hex 0.2.0:** published via tag-triggered workflow after **`v0.2.0`** push.
- **ADOP-03 closure:** Maintainer-recorded **OK** / **N/A** + test/CI citations in **`guides/adoption-pilot-backlog.md`**; topology honesty + **AP-ENV.1** → **STG-01** (not a claim of external PgBouncer staging).

### Pending todos

1. **Optional v1.6 depth:** Execute **STG-01** (host staging / pooler parity) when a host is available — see [`.planning/REQUIREMENTS.md`](REQUIREMENTS.md#stg-01).
2. When cutting the next Hex release after doc-only commits on `main`, bump **`@version`** (e.g. **0.2.1**) and add a dated **`CHANGELOG`** section.

### Blockers / concerns

- None for **v1.5** closure. **STG-01** remains the honest follow-up for **PgBouncer transaction mode** realism vs maintainer CI (direct Postgres).

## Session continuity

**Milestone v1.5:** complete on requirements (2026-04-23).

**Next (pick one):**

- **`/gsd-progress`** — confirm roadmap + STATE after merge.
- **Milestone wrap-up** — archive v1.5 per project habit (`/gsd-complete-milestone` or equivalent).
- **v1.6 planning** — prioritize **STG-01** and exploration API items from `REQUIREMENTS.md` **Future** section.

**Prior shipped:** v1.4 — 2026-04-23 (archive: `.planning/milestones/v1.4-*.md`).

**Completed phases:** 19 (Adoption operator docs), 20 (First external pilot — maintainer evidence pass) — 2026-04-23
