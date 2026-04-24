---
phase: 29-audit-table-indexing-cookbook
plan: "01"
subsystem: documentation
requirements-completed: [IDX-01]
key-files:
  created:
    - guides/audit-indexing.md
  modified:
    - mix.exs
    - guides/domain-reference.md
    - guides/production-checklist.md
completed: 2026-04-24
---

# Phase 29 plan 01 summary

Shipped **`guides/audit-indexing.md`** as the canonical indexing cookbook: installed default index names from **`Threadline.Capture.Migration`** / **`Threadline.Semantics.Migration`**, per-table primers, access-pattern sections aligned with **`Threadline.Query`** (inner vs left join on export), **`Threadline.Retention`** batching and orphan `NOT EXISTS`, tradeoffs, and optional non-mandatory DDL example. Registered the guide in ExDoc **`extras`**, and added thin navigation from **`guides/domain-reference.md`** and **`guides/production-checklist.md`**.

## Task commits

1. **29-01-01** — `001a611` — `docs(29-01): add audit table indexing cookbook (IDX-01)`
2. **29-01-02** — `9405bfb` — `docs(29-01): register audit-indexing in ExDoc extras`
3. **29-01-03** — `a778e1a` — `docs(29-01): link indexing cookbook from domain reference and checklist`

## Verification

- `mix format`
- `mix compile --warnings-as-errors`
- `DB_PORT=5433 MIX_ENV=test mix test` — 154 tests, 0 failures

## Self-Check: PASSED
