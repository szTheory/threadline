---
phase: 181-baseline-audit-and-guard-repair
plan: 04
subsystem: testing
tags: [operator-ui, source-contracts, guard-repair, tdd, exunit]

requires:
  - phase: 181-03
    provides: current operator E2E contracts and guard repair ledger baseline
provides:
  - Current source-test prose for active operator guard contracts
  - Durable ExUnit guard against stale source-test scaffold wording
  - Guard ledger evidence for G-011 through G-020 source-test prose repairs
affects: [181-05, 181-06, 181-07, 181-08, 181-09, 181-10, 181-11, 183, 184, 185, 186, 187]

tech-stack:
  added: []
  patterns:
    - TDD RED/GREEN source-prose guard for active test contract wording
    - Source-test comments describe current invariants instead of historical failure states

key-files:
  created:
    - .planning/phases/181-baseline-audit-and-guard-repair/181-04-SUMMARY.md
  modified:
    - .planning/phases/181-baseline-audit-and-guard-repair/181-GUARD-REPAIR.md
    - test/threadline/operator_surface/card_nesting_regression_test.exs
    - test/threadline/operator_surface/data_state_mapping_wave0_test.exs
    - test/threadline/operator_surface/component_contract_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
    - test/threadline/operator_surface/live/retention_history_live_test.exs
    - test/threadline/operator_surface/breadcrumb_test.exs
    - test/threadline/operator_surface/stress_fixtures_test.exs

key-decisions:
  - "181-04 repairs only active source-test prose and failure messages; assertions, route paths, feature gates, public APIs, and production source remain unchanged."
  - "A durable ExUnit source-prose guard now prevents repaired source tests from reintroducing stale scaffold wording."

patterns-established:
  - "Active guard comments must name the current invariant and historical failure state only when retained as explicit regression context."
  - "Guard-ledger source-test repairs record G-ID, commit-time file path, replacement contract, and status."

requirements-completed: [BASE-01, BASE-02]

duration: 7 min
completed: 2026-06-26
status: complete
---

# Phase 181 Plan 04: Active Source-Test Prose Repair Summary

**Source-test guard prose now describes current operator invariants, with a new ExUnit ratchet preventing old scaffold-state wording from returning.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-26T14:47:14Z
- **Completed:** 2026-06-26T14:53:59Z
- **Tasks:** 1
- **Files modified:** 8

## Accomplishments

- Added a source-prose ExUnit guard that scans the Plan 04 source-test files for stale scaffold markers.
- Reworded G-011 through G-020 active source-test comments, test names, and failure messages to describe the current contract they protect.
- Updated `181-GUARD-REPAIR.md` with Plan 04 repair evidence for each source-test finding.

## Task Commits

1. **RED: Add source prose repair guard** - `c9331d8` (test)
2. **GREEN: Repair active source-test prose** - `9db9f8d` (feat)

## Files Created/Modified

- `.planning/phases/181-baseline-audit-and-guard-repair/181-GUARD-REPAIR.md` - Added Plan 04 repair evidence for G-011 through G-020.
- `test/threadline/operator_surface/component_contract_test.exs` - Added the durable source-prose guard and repaired overlay scrim prose.
- `test/threadline/operator_surface/card_nesting_regression_test.exs` - Reworded card-nesting header comments to current DATA-05/D-12 regression language.
- `test/threadline/operator_surface/data_state_mapping_wave0_test.exs` - Reworded data-state dispatcher moduledoc to current `UI.data_state/1` behavior.
- `test/threadline/operator_surface/breadcrumb_test.exs` - Reworded breadcrumb contract prose while preserving the legacy-label refute.
- `test/threadline/operator_surface/style_contract_test.exs` - Reworded overlay utility, grid-centering, desktop scroll-offset, and token-spacing contract prose.
- `test/threadline/operator_surface/stress_fixtures_test.exs` - Reworded PAGE-01 11-subject x 7-path story ratchet prose.
- `test/threadline/operator_surface/live/retention_history_live_test.exs` - Reworded retention destructive-flow and full-value copy contract prose.

## Verification

| Check | Result |
|---|---|
| RED run: `mix test test/threadline/operator_surface/component_contract_test.exs:43` before repair | Failed as expected, listing stale source-prose offenders. |
| GREEN run: `mix test test/threadline/operator_surface/component_contract_test.exs:43` after repair | Passed: 1 test, 0 failures. |
| Targeted task slice | Passed: 104 tests, 0 failures. |
| Guard evidence check: `rg -n 'repair-now|retired with rationale|intentional guard' 181-GUARD-REPAIR.md` | Passed. |
| Stale marker scan across touched source-test files | Passed with no stale scaffold markers. |
| `mix format --check-formatted` on touched source-test files | Passed. |
| `git diff --check` | Passed. |
| File scope check | Passed: only source tests and `181-GUARD-REPAIR.md` changed. |

## Decisions Made

- Used a source-prose guard in `component_contract_test.exs` rather than adding a new test file, keeping Plan 04 changes inside the declared file list.
- Kept historical contract references only where they are active regression context, such as the Breadcrumb legacy-label refute and reserved-baseline prevention.

## TDD Gate Compliance

- RED gate present: `c9331d8 test(181-04): add source prose repair guard`.
- GREEN gate present after RED: `9db9f8d feat(181-04): repair active source-test prose`.
- No refactor commit was needed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None. Stub-pattern scan matched only existing assertion constructs and historical ledger quote text, not UI stubs or unwired data.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `181-05`. The source-test prose repair is complete, the guard ledger records replacement contracts for G-011 through G-020, and no production route, feature gate, public component API, dependency, capture/query/auth semantic, or destructive runtime redaction behavior changed.

## Self-Check: PASSED

- Found all eight modified task files on disk.
- Found task commits `c9331d8` and `9db9f8d` in git history.
- Targeted Plan 04 ExUnit slice passed after repair.
- No tracked file deletions were introduced by task commits.
- Working tree was clean before summary creation.

---
*Phase: 181-baseline-audit-and-guard-repair*
*Completed: 2026-06-26*
