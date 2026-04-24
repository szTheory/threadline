---
phase: 29-audit-table-indexing-cookbook
plan: "02"
subsystem: testing
requirements-completed: [IDX-02]
key-files:
  created:
    - test/threadline/audit_indexing_doc_contract_test.exs
  modified: []
completed: 2026-04-24
---

# Phase 29 plan 02 summary

Added **`Threadline.AuditIndexingDocContractTest`** mirroring **`Threadline.SupportPlaybookDocContractTest`**: asserts IDX-02 HTML marker, operator spine headings from plan 29-01, and bidirectional link strings to **`domain-reference.md`** and **`production-checklist.md`** in the cookbook body.

## Task commits

1. **29-02-01** — `bdbf07b` — `test(29-02): add audit indexing guide doc contract (IDX-02)`

## Verification

- `mix format`
- `mix compile --warnings-as-errors`
- `DB_PORT=5433 MIX_ENV=test mix test test/threadline/audit_indexing_doc_contract_test.exs`
- `DB_PORT=5433 MIX_ENV=test mix test` — 156 tests, 0 failures

## Self-Check: PASSED
