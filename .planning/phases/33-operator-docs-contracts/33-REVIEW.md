---
status: clean
phase: 33-operator-docs-contracts
reviewed: 2026-04-24
---

# Phase 33 — Code review

## Scope

Doc edits under `guides/` and new async doc contract test `test/threadline/exploration_routing_doc_contract_test.exs`.

## Findings

None. Public API names in the routing table were cross-checked against `lib/threadline.ex` delegators / `Threadline.Query` entrypoints.

## Notes

- Explicit `<span id="exploration-api-routing-v110">` avoids ambiguity vs auto-generated heading slugs for the `(v1.10+)` title.
