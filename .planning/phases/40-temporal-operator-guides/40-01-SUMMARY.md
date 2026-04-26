---
phase: 40-temporal-operator-guides
plan: 01
subsystem: docs
tags: [as-of, docs, phoenix, contract-tests]

# Dependency graph
requires:
  - phase: 39-reification-schema-safety
    provides: locked as_of/4 map-default, deleted/genesis error behavior, cast: true semantics
provides:
  - Time Travel (As-of) operator hub in the domain reference
  - runnable historical reconstruction walkthrough in the Phoenix example README
  - doc-contract coverage for the new guide section and walkthrough literals
affects: [guides, examples, doc-contract-tests, operator-docs]

# Tech tracking
tech-stack:
  added: []
  patterns: [docs hub section, runnable walkthrough, contract-test anchored literals]

key-files:
  created:
    - .planning/phases/40-temporal-operator-guides/40-01-SUMMARY.md
  modified:
    - guides/domain-reference.md
    - examples/threadline_phoenix/README.md
    - test/threadline/exploration_routing_doc_contract_test.exs
    - test/threadline/readme_doc_contract_test.exs
    - .planning/phases/40-temporal-operator-guides/40-CONTEXT.md
    - .planning/phases/40-temporal-operator-guides/40-RESEARCH.md

key-decisions:
  - "Keep Time Travel as a compact hub section beside the existing exploration material instead of creating a separate guide."
  - "Use the Phoenix example README for one copy-pasteable reconstruction walkthrough with ThreadlinePhoenix.Post."
  - "Lock the docs with literal assertions for ASOF-06, as_of/4, cast: true, deleted rows, and genesis gaps."

patterns-established:
  - "Pattern 1: operator guide as semantic hub with a compact behavior table"
  - "Pattern 2: runnable example README that teaches ergonomics without duplicating the full API reference"

requirements-completed: [ASOF-06]

# Metrics
duration: 45min
completed: 2026-04-25
---

# Phase 40: Temporal Operator Guides Summary

**Time Travel documentation for as_of/4 with a compact operator hub and a copy-paste Phoenix reconstruction walkthrough**

## Performance

- **Duration:** 45 min
- **Started:** 2026-04-25T22:00:00Z
- **Completed:** 2026-04-25T22:45:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added a new `## Time Travel (As-of)` hub to the domain reference with the default map result and edge cases.
- Added a runnable historical reconstruction walkthrough to the Phoenix example README using `ThreadlinePhoenix.Post`.
- Strengthened doc-contract tests so guide and README drift fails CI immediately.

## Task Commits

1. **Task 1: Add the Time Travel hub to the operator guide** - `9b8a733` (docs)
2. **Task 2: Add the runnable walkthrough to the Phoenix example README** - `35564a4` (docs)

**Plan metadata:** pending

## Files Created/Modified

- `guides/domain-reference.md` - Time Travel operator hub and ASOF-06 table
- `examples/threadline_phoenix/README.md` - runnable reconstruction walkthrough
- `test/threadline/exploration_routing_doc_contract_test.exs` - guide/anchor regression coverage
- `test/threadline/readme_doc_contract_test.exs` - walkthrough literal regression coverage

## Decisions Made

- Kept the new material near existing exploration/support docs to preserve the hub-doc pattern.
- Used a behavior table for the edge cases so the contract stays compact and readable.
- Put the runnable example in the main README flow rather than a separate appendix.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- `mix precommit` is not defined in this repo, so verification used the explicit doc-contract test commands from the plan.

## Next Phase Readiness

- Phase 40 is documentation-complete and ready for state/roadmap updates.
- Future docs should continue to anchor to the ASOF-06 contract and the Phoenix walkthrough.

## Self-Check: PASSED

---
*Phase: 40-temporal-operator-guides*
*Completed: 2026-04-25*
