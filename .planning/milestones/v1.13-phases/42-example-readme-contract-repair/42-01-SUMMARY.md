---
phase: 42-example-readme-contract-repair
plan: 01
subsystem: docs
tags: [readme, examples, docs-contract, elixir, phoenix]
requires:
  - phase: 41
    provides: root README contract repaired and doc-contract baseline established
provides:
  - Phoenix example README aligned to the runnable reference app contract
  - Narrow doc-contract coverage for the example README and examples index literals
affects: [examples, docs contract tests]
tech-stack:
  added: []
  patterns: [literal README contract assertions, explicit example walkthrough naming]
key-files:
  created:
    - .planning/phases/42-example-readme-contract-repair/42-01-SUMMARY.md
  modified:
    - examples/README.md
    - examples/threadline_phoenix/README.md
    - test/threadline/readme_doc_contract_test.exs
requirements-completed: [DOC-02, DOC-03]
duration: 10 min
completed: 2026-04-26
---

# Phase 42: Example README Contract Repair Summary

**The Phoenix example docs now explicitly describe the runnable contract, and the doc-contract test locks the install/runbook, walkthrough, and index literals.**

## Performance

- **Duration:** 10 min
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Sharpened `examples/threadline_phoenix/README.md` so it frames the install, run, test, and reconstruction commands as the runnable example contract.
- Reworded `examples/README.md` to make the nested Phoenix README the canonical entry point for the example contract.
- Tightened `test/threadline/readme_doc_contract_test.exs` to assert the example index, install/runbook literals, and audited HTTP / historical reconstruction literals.

## Task Commits

1. **Task 1: Repair the example README contract and keep the index/test aligned** - not committed in this session

## Files Created/Modified

- `examples/README.md` - canonical example index wording
- `examples/threadline_phoenix/README.md` - runnable example contract wording
- `test/threadline/readme_doc_contract_test.exs` - example contract regression assertions

## Decisions Made

- Kept the root README slice untouched so Phase 42 only repairs the example docs surface.
- Locked the example surface with exact literal checks instead of broad substring coverage.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None.

## User Setup Required

None.

## Verification

- `mix test test/threadline/readme_doc_contract_test.exs --seed 0`

## Next Phase Readiness

Phase 42 is complete at the docs/test level and ready for any state or roadmap reconciliation.

---
*Phase: 42-example-readme-contract-repair*
*Completed: 2026-04-26*
