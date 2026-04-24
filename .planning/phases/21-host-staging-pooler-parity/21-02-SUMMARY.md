---
phase: 21
plan: 21-02
status: complete
completed: 2026-04-24
---

# Plan 21-02 summary

## Objective

CONTRIBUTING host STG evidence, production-checklist cross-link, and `stg_doc_contract_test.exs` tying anchors to backlog markers.

## Delivered

- `CONTRIBUTING.md`: section `## Host STG evidence (integrators)` after PgBouncer topology CI parity; fork + pull request workflow; pointers to `guides/adoption-pilot-backlog.md`, `STG-HOST-TOPOLOGY-TEMPLATE`, `STG-AUDITED-PATH-RUBRIC`; **redact** emphasis; integrator-owned vs maintainer merge scope.
- `guides/production-checklist.md`: intro paragraph linking STG-01–STG-03 to backlog with **`STG-AUDITED-PATH-RUBRIC`** substring.
- `test/threadline/stg_doc_contract_test.exs`: doc contracts for CONTRIBUTING heading, checklist substrings, backlog marker regression.

## Verification

- `DB_PORT=5433 MIX_ENV=test mix test test/threadline/stg_doc_contract_test.exs` — pass.
- `DB_PORT=5433 MIX_ENV=test mix ci.all` — pass (143 tests, doc contract included).

## Self-Check: PASSED

## Key files

- `CONTRIBUTING.md`
- `guides/production-checklist.md`
- `test/threadline/stg_doc_contract_test.exs`
