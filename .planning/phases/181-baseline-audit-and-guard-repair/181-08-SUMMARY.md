---
phase: 181-baseline-audit-and-guard-repair
plan: 08
subsystem: testing
tags: [operator-ui, screenshots, playwright, baseline, local-guard]

requires:
  - phase: 181-07
    provides: ledger-backed bounded stress screenshot guard and local-only stress-state packet evidence
provides:
  - Verified local screenshot-regression guard result for existing operator baselines
  - Inventory classification for every committed operator-screenshot-regression local PNG baseline
  - Explicit no-update disposition for Plan 09 Home/Timeline and Plan 10 Row-history/Exports/Retention baselines
affects: [181-09, 181-10, 181-11, 183, 184, 186, 187]

tech-stack:
  added: []
  patterns:
    - Local screenshot-regression baselines are classified in inventory before any PNG mutation
    - Platform-sensitive generic Chromium screenshot rows remain local-only skips rather than CI coverage

key-files:
  created:
    - .planning/phases/181-baseline-audit-and-guard-repair/181-08-SUMMARY.md
  modified:
    - .planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md

key-decisions:
  - "All existing operator-screenshot-regression desktop/mobile local PNG baselines matched current rendered truth; no accepted Plan 09 or Plan 10 PNG updates were discovered."
  - "The generic `chromium` project skip remains intentional because fixed local screenshot baselines run on `desktop-chromium` and `mobile-chromium` only."
  - "The example-app `mix precommit` residual remains inherited demo-seed/walkthrough drift and is recorded rather than repaired in this local screenshot classification plan."

patterns-established:
  - "Plan 08 inventory rows record command, surface, project, viewport, snapshot path, status, and rationale for every local screenshot-regression baseline."

requirements-completed: [BASE-01, BASE-02]

duration: 4 min
completed: 2026-06-26
status: complete
---

# Phase 181 Plan 08: Local Screenshot-Regression Verification and Classification Summary

**Local screenshot-regression guard verified current Home, dense Timeline, row-history, Exports, and Retention desktop/mobile PNG baselines without mutating snapshots or expanding CI coverage.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-26T16:29:31Z
- **Completed:** 2026-06-26T16:33:06Z
- **Tasks:** 1
- **Files modified:** 2 including this summary

## Accomplishments

- Ran the existing local screenshot regression guard; it reached screenshot comparison and passed 10 desktop/mobile baseline checks with 5 intentional generic Chromium skips.
- Added Plan 08 inventory evidence for every committed `operator-screenshot-regression.spec.ts` baseline: Home, dense Timeline, row-history, Exports, and Retention across desktop/mobile projects.
- Confirmed no PNG baseline file changed and no local screenshot baseline was promoted into the CI allowlist.

## Task Commits

1. **Task 1: Verify and classify local screenshot-regression guard** - `277d5e43` (docs)

## Files Created/Modified

- `.planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md` - Added Plan 08 command results, local baseline classification rows, intentional skip rationale, and inherited precommit residual notes.
- `.planning/phases/181-baseline-audit-and-guard-repair/181-08-SUMMARY.md` - Plan closeout summary.

## Verification

| Check | Result |
|---|---|
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshot-regression.spec.ts` | Passed: 10 passed, 5 skipped. |
| `mix precommit` from `examples/threadline_phoenix` | Failed: 96 tests, 7 failures. Same inherited demo-seed/walkthrough contract residuals recorded by earlier Phase 181 plans; Plan 08 changed only planning inventory before this summary. |
| Inventory source assertion for `operator-screenshot-regression.spec.ts` and all ten snapshot names | Passed. |
| PNG mutation check | Passed: `git diff --name-only | rg '\.png$'` returned no files. |
| CI allowlist/source promotion check | Passed: no diff in `operator-screenshot-regression.spec.ts`, `operator-stress.spec.ts`, or `.planning/design-system-ledger.json`. |
| `git diff --check` | Passed. |

## Decisions Made

- Treated every existing desktop/mobile local screenshot-regression PNG as current committed baseline evidence.
- Recorded "no accepted update" for the Plan 09 Home/dense Timeline cells and Plan 10 row-history/Exports/Retention cells because the guard passed without screenshot drift.
- Preserved the guard's local-only/platform-sensitive skip behavior instead of broadening CI coverage.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `examples/threadline_phoenix` `mix precommit` remains red in the inherited demo-seed/walkthrough contract tests around old `#4521`/`#4518` May anchor rows, `agent2` window rows, and `org_memberships` actor attribution. This was re-recorded in the inventory and was not caused by Plan 08.

## Auth Gates

None.

## Known Stubs

None. Plan 08 introduced no hardcoded UI-empty data, placeholder copy, TODO/FIXME, or mock-data wiring.

## Threat Flags

None. The plan changed planning inventory and summary documentation only; it introduced no new endpoint, auth path, file access pattern outside existing screenshot evidence references, schema change, dependency, route path, public component API, production story surface, or capture/query/auth semantic.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `181-09` and `181-10`. Plan 08 found no accepted local screenshot-regression PNG updates for those plans; their remaining work should respect that the existing Home, dense Timeline, row-history, Exports, and Retention local regression baselines are current.

## Self-Check: PASSED

- Found `181-SCREENSHOT-INVENTORY.md` with Plan 08 command evidence and all ten local snapshot classification rows.
- Found task commit `277d5e43` in git history.
- Confirmed no PNG files were modified by Plan 08.
- Confirmed no screenshot regression or CI allowlist source file was modified by Plan 08.
- Working tree contained only this summary before summary closeout.

---
*Phase: 181-baseline-audit-and-guard-repair*
*Completed: 2026-06-26*
