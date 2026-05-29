---
phase: 129-walkthrough-truth
plan: 02
subsystem: testing
tags: [walkthrough, doc-contract, WALK-03]

requires:
  - phase: 129-01
    provides: WALKTHROUGH.md truth edits
provides:
  - Two-tier walkthrough doc-contract locks under mix verify.example
affects: []

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs

requirements-completed: [WALK-03]

duration: 10min
completed: 2026-05-28
---

# Phase 129 Plan 02 Summary

**Doc-contract tests prevent WALKTHROUGH verify and row-history regressions.**

## Performance

- **Duration:** ~10 min
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Added `section_slice/3` and `step_do_slice/3` helpers (readme pattern)
- WALK-01 describe locks `mix threadline.verify_coverage` and refutes `mix verify.threadline`
- WALK-02 describe locks canonical history route and Do-step refutes for WALK-03-01/04/04-02
- Router cross-check asserts transaction-scoped history route is mounted
- Preserved existing RUN-01 literal-presence test

## Task Commits

1. **WALK-01/02 contract tests** - `957e989` (test)

## Self-Check: PASSED

- All 8 tests pass in `walkthrough_doc_contract_test.exs`
- Gated by existing `mix verify.example`
