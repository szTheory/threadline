---
phase: 52-docs-and-contract-alignment
plan: 52-02
subsystem: testing
tags: [docs, doc-contract, sigra, incident, readme]
provides:
  - narrow doc-contract locks for the final Phase 52 host-wiring story
  - cross-doc guards that fail when one public surface drifts from the shared authenticated incident boundary
affects: [ADOPT-03]
requirements-completed: [ADOPT-03]
tech-stack:
  added: []
  patterns: [narrow literal assertions, cross-doc consistency checks, docs as contract]
key-files:
  created:
    - test/threadline/integrations/sigra_doc_contract_test.exs
    - test/threadline/example_phoenix_readme_contract_test.exs
  modified:
    - test/threadline/getting_started_saas_doc_contract_test.exs
    - test/threadline/exploration_routing_doc_contract_test.exs
    - test/threadline/incident_playbook_doc_contract_test.exs
    - test/threadline/stg_doc_contract_test.exs
key-decisions:
  - extend existing doc-contract suites instead of introducing a snapshot-style phase-specific harness
  - lock shared literals and boundaries across docs so one stale surface fails the suite even if adjacent docs are correct
duration: 12min
completed: 2026-05-05
---

# Plan 52-02 summary

Locked the final Phase 52 public wording with focused doc-contract tests that prove the same direct Sigra callback pair, additive-only override semantics, and authenticated incident boundary remain consistent across the quickstart, Sigra guide, domain reference, incident playbook, adoption backlog, and Phoenix example README.

## Task commits

1. **Task 1: Tighten the direct host-wiring contract tests on the guide and README entry points** - `fb98c88` (test)
2. **Task 2: Tighten the reference, playbook, and backlog contract tests around the shared incident boundary** - `ce0de9d` (test)

## Files changed

- `test/threadline/integrations/sigra_doc_contract_test.exs` - created the direct Sigra guide contract suite for callback names, section order, and additive-only semantics.
- `test/threadline/getting_started_saas_doc_contract_test.exs` - tightened the quickstart against the canonical router block, additive-only wording, and authenticated incident baseline.
- `test/threadline/example_phoenix_readme_contract_test.exs` - added README drift guards for the direct callback pair and the host-owned incident boundary.
- `test/threadline/exploration_routing_doc_contract_test.exs` - extended the domain-reference incident anchor checks to the authenticated baseline and host-owned authorization line.
- `test/threadline/incident_playbook_doc_contract_test.exs` - locked the minimum host auth shape and the shipped public Threadline API surface.
- `test/threadline/stg_doc_contract_test.exs` - updated the adoption backlog guard to require the shipped auth baseline and host-owned authorization disclaimer.

## Decisions made

- Reused the existing literal `String.contains?/2` style and heading-order checks so the tests stay durable without turning into whole-file snapshots.
- Added cross-doc consistency through shared literals and source-of-truth snippets rather than allowing each doc to drift with equivalent-but-different prose.

## Deviations from plan

None - the plan executed as a focused extension of the existing contract suites.

## Self-check

PASSED — `mix test test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs` and `mix test test/threadline/exploration_routing_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/stg_doc_contract_test.exs`
