---
phase: 41-readme-contract-repair
plan: 01
subsystem: docs
tags: [readme, docs-contract, elixir, phoenix]
requires:
  - phase: 40
    provides: shipped API surface and doc-contract baseline
provides:
  - Root README aligned to the shipped public API surface
  - Narrow doc-contract coverage for the root README literals
affects: [phase 42, docs contract tests]
tech-stack:
  added: []
  patterns: [literal README contract assertions, explicit public API naming]
key-files:
  created:
    - .planning/phases/41-readme-contract-repair/41-01-SUMMARY.md
  modified:
    - README.md
    - test/threadline/readme_doc_contract_test.exs
requirements-completed: [DOC-01, DOC-03]
duration: 5 min
completed: 2026-04-26
---

# Phase 41: README Contract Repair Summary

**Root README now names the shipped public API and the contract test locks those literals to prevent docs drift.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-26T00:57:50Z
- **Completed:** 2026-04-26T01:02:46Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Reworked the root README intro, feature list, and quickstart so they explicitly reference `Threadline.Plug`, `Threadline.record_action/2`, `Threadline.history/3`, `Threadline.timeline/2`, `Threadline.export_json/2`, and `Threadline.as_of/4`.
- Preserved the core documentation links to `guides/domain-reference.md`, `guides/production-checklist.md`, `guides/adoption-pilot-backlog.md`, and `CONTRIBUTING.md`.
- Tightened `test/threadline/readme_doc_contract_test.exs` so the root README contract now fails on API-name or guide-link drift while leaving the example README assertions for Phase 42 intact.

## Task Commits

1. **Task 1: Repair the root README contract and lock it with tests** - pending commit

## Files Created/Modified

- `README.md` - root docs surface aligned to the shipped public API
- `test/threadline/readme_doc_contract_test.exs` - literal contract assertions for the root README

## Decisions Made

- Kept the scope to the root README only so Phase 42 can repair the example README independently.
- Used exact public API names in both prose and regression checks to make future drift obvious.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 42 can proceed with the Phoenix example README contract repair.

---
*Phase: 41-readme-contract-repair*
*Completed: 2026-04-26*
