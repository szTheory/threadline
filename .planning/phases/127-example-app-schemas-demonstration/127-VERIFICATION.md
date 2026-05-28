---
status: passed
phase: 127-example-app-schemas-demonstration
verified: 2026-05-28
requirements: []
roadmap_criteria: 3/3
plans: 2/2
---

# Phase 127 Verification Report

**Phase:** 127 — Example App `:schemas` Demonstration  
**Goal:** Runnable reference app demonstrates operator-surface `:schemas` row-history reification (D-14).  
**Result:** **PASSED**

## ROADMAP success criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Example router mounts operator surface with `:schemas` for help-desk tables | ✅ | `router.ex` operator-surface-mount block; `example_phoenix_schemas_mount_contract_test.exs` |
| 2 | Getting-started §9 mount snippet matches runnable wiring | ✅ | `mix verify.doc_contract`; `getting_started_saas_doc_contract_test.exs` |
| 3 | Contract/walkthrough evidence proves history sub-route reification | ✅ | `operator_surface_test.exs` — `admin reaches ticket_replies row history via :schemas mount` |

## Commands Actually Used

| Command | Result |
|---------|--------|
| `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/operator_surface_test.exs` | PASS (8 tests) |
| `mix test test/threadline/example_phoenix_schemas_mount_contract_test.exs` | PASS (1 test) |
| `mix verify.doc_contract` | PASS (97 tests) |

## Notes

- WALKTHROUGH shorthand `/audit/rows/:table/:pk` is documentation shorthand; shipped path is `/audit/transactions/:id/history/:table/:record_id` per operator-surface guide.
- Admin `:ok` authorize path now assigns `threadline_scope: nil` so `RowHistoryComponent` renders without KeyError (library fix in `auth.ex`).

## Plan summaries

| Plan | Outcome |
|------|---------|
| 127-01 | `:schemas` map + `:row_history` scope clause; doc SSOT parity |
| 127-02 | Integration + contract tests; this verification artifact |
