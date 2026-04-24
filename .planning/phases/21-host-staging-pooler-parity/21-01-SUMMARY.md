---
phase: 21
plan: 21-01
status: complete
completed: 2026-04-24
---

# Plan 21-01 summary

## Objective

Adoption backlog STG topology template (STG-01), audited-path rubric (STG-02/STG-03), and doc contracts in `ci_topology_contract_test.exs`.

## Delivered

- `guides/adoption-pilot-backlog.md`: sections `## STG host topology template (STG-01)` and `## STG audited write paths (STG-02)` with markers `STG-HOST-TOPOLOGY-TEMPLATE` and `STG-AUDITED-PATH-RUBRIC`, tables per plan, normative bullets for OK/N/A/Not run and CI vs host labeling. **CI-PGBOUNCER-TOPOLOGY-CONTRACT** paragraph and following table preserved after the new blocks.
- `test/threadline/ci_topology_contract_test.exs`: two tests asserting both STG markers remain in the backlog.

## Verification

- `DB_PORT=5433 MIX_ENV=test mix test test/threadline/ci_topology_contract_test.exs` — pass (4 tests).

## Self-Check: PASSED

## Key files

- `guides/adoption-pilot-backlog.md`
- `test/threadline/ci_topology_contract_test.exs`
