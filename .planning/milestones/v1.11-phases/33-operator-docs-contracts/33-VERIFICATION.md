---
status: passed
phase: 33-operator-docs-contracts
verified: 2026-04-24
---

# Phase 33 — Verification

## Automated

| Check | Command | Result |
|-------|---------|--------|
| Format | `DB_PORT=5433 mix format --check-formatted` | pass |
| Doc contracts | `DB_PORT=5433 mix test test/threadline/exploration_routing_doc_contract_test.exs test/threadline/support_playbook_doc_contract_test.exs` | pass (4 tests) |
| Compile | `DB_PORT=5433 mix compile --warnings-as-errors` | pass |

## must_haves (from 33-01-PLAN)

- [x] `guides/domain-reference.md` — `## Exploration API routing (v1.10+)` before `## Support incident queries`, **XPLO-03-API-ROUTING**, table covers five mandatory intents + optional actor row; link to `#support-incident-queries`.
- [x] `guides/production-checklist.md` — link to `domain-reference.md#exploration-api-routing-v110`; existing `#support-incident-queries` link retained.
- [x] `mix test test/threadline/exploration_routing_doc_contract_test.exs` — exit 0 (with Postgres on `DB_PORT=5433` per project parity).

## Requirement traceability

- **XPLO-03** — satisfied by routing section, checklist cross-link, and doc contract tests.

## human_verification

None required (guide + test-only phase).
