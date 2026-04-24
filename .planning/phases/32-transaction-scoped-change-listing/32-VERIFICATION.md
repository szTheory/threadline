---
status: passed
phase: 32-transaction-scoped-change-listing
verified: 2026-04-24
---

# Phase 32 — Verification

## Automated

| Check | Command | Result |
|-------|---------|--------|
| Format | `mix format --check-formatted` | pass |
| Compile | `mix compile --warnings-as-errors` | pass |
| Query tests | `DB_PORT=5433 mix test test/threadline/query_test.exs` | pass (35 tests) |
| Full CI gate | `DB_PORT=5433 mix ci.all` | pass (see command output in session) |

## must_haves (from 32-01-PLAN)

- [x] `@spec` + `@doc` on `audit_changes_for_transaction/2` — audit_transactions.id, total order `(captured_at, id)` desc, `binary_id` not time-ordered, `[]` empty, `ArgumentError` invalid UUID
- [x] `Threadline` exposes same function delegating to `Query`
- [x] `mix test test/threadline/query_test.exs` — exit 0
- [x] `mix compile --warnings-as-errors` — exit 0

## Requirement traceability

- **XPLO-02** — satisfied by public Query + Threadline entrypoints, multi-change ordering test, documented stable order.

## human_verification

None required for this phase (library-only API).
