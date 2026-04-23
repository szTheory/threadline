# Phase 19 — Adoption operator docs

**Milestone:** v1.5  
**Requirements:** ADOP-01, ADOP-02, TELEM-01, TELEM-02

## Objective

Ship operator-facing artifacts so hosts can run adoption with **evidence-backed** feedback: pilot backlog matrix, README/HexDocs discovery, and a single telemetry reference anchored from the production checklist.

## Verification

- `DB_PORT=5433 MIX_ENV=test mix ci.all` (or project-default Postgres) — green.
- `mix docs` succeeds; extras include `guides/adoption-pilot-backlog.md`.

## Outcome

Landed on `main` with `.planning` milestone files updated for **v1.5** Phase 19 complete / Phase 20 pending.
