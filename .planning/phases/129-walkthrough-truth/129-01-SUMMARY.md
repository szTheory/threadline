---
phase: 129-walkthrough-truth
plan: 01
subsystem: docs
tags: [walkthrough, operator-surface, verify-coverage, doc-contract]

requires: []
provides:
  - WALKTHROUGH.md with honest example-app verify cwd and row-history URL presentation
affects: [129-02 walkthrough doc-contract tests]

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/WALKTHROUGH.md

key-decisions:
  - "Walk verify uses mix threadline.verify_coverage from examples/threadline_phoenix/"
  - "Hybrid row-history pattern: navigation-first Do steps, shorthand-labeled tables, §0 SSOT"

requirements-completed: [WALK-01, WALK-02]

duration: 15min
completed: 2026-05-28
---

# Phase 129 Plan 01 Summary

**WALKTHROUGH.md no longer sends maintainers to root verify or pasteable /audit/rows/ URLs.**

## Performance

- **Duration:** ~15 min
- **Tasks:** 4
- **Files modified:** 1

## Accomplishments

- §0 documents walk vs contributor cwd split with CONTRIBUTING cross-link
- §0 Row history URLs subsection with canonical route and operator-surface SSOT
- WALK-01-02 and WALK-04-03 optional verify use `mix threadline.verify_coverage`
- WALK-03-01/04 and WALK-04-02 Do steps use History-link navigation
- Operator-surface tables label shorthand vs canonical drill-down paths

## Task Commits

1. **All tasks (WALKTHROUGH truth)** - `3083f5a` (docs)

## Self-Check: PASSED

- `examples/threadline_phoenix/WALKTHROUGH.md` exists
- No bare `mix verify.threadline` walk steps
- `grep -c 'mix threadline.verify_coverage'` >= 2
