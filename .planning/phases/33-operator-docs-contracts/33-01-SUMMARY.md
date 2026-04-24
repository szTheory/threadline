---
phase: 33-operator-docs-contracts
plan: 33-01
subsystem: testing
tags: [docs, XPLO-03, guides, doc-contract]
affects: [XPLO-03]
requirements-completed: [XPLO-03]

key-files:
  created:
    - test/threadline/exploration_routing_doc_contract_test.exs
  modified:
    - guides/domain-reference.md
    - guides/production-checklist.md

key-decisions:
  - "Stable fragment `exploration-api-routing-v110` via `<span id=\"...\">` before the heading (matches production-checklist link and LOOP-04-style explicit ids)."
  - "Omitted `timeline_repo!/2` from routing table because it is not established elsewhere in `domain-reference.md` (per plan grep)."

patterns-established:
  - "XPLO-03-API-ROUTING contract marker + `ExplorationRoutingDocContractTest` mirrors LOOP-04 / support playbook doc tests."

# Summary

Shipped **XPLO-03**: skimmable **Exploration API routing (v1.10+)** in `guides/domain-reference.md` (table + link into Support incident queries), a **production-checklist** discovery link to `#exploration-api-routing-v110`, and **`Threadline.ExplorationRoutingDocContractTest`** locking headings, marker, and checklist fragment.

## Self-Check: PASSED

- `DB_PORT=5433 mix format --check-formatted` — pass
- `DB_PORT=5433 mix test test/threadline/exploration_routing_doc_contract_test.exs test/threadline/support_playbook_doc_contract_test.exs` — pass (4 tests)
- `DB_PORT=5433 mix compile --warnings-as-errors` — pass

## Deviations

None.
