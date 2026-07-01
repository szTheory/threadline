---
phase: 181-baseline-audit-and-guard-repair
plan: 07
subsystem: testing
tags: [operator-ui, stress-route, screenshots, playwright, guardrails]

requires:
  - phase: 181-06
    provides: current stress ledger/projection/source contracts and bounded screenshot allowlist
provides:
  - Ledger-driven bounded stress CI screenshot guard
  - Env-gated local-only selected stress-state packet for happy/error/permission/boundary evidence
  - Screenshot inventory entries for Plan 07 stress guard and packet results
affects: [181-08, 181-09, 181-10, 181-11, 182, 187]

tech-stack:
  added: []
  patterns:
    - Ledger-owned screenshot allowlist consumed directly by Playwright
    - OPERATOR_STRESS_SCREENSHOT_DIR-gated local packet capture resolved from repo root
    - Tier C stress packet evidence stays outside CI toHaveScreenshot baselines

key-files:
  created:
    - .planning/phases/181-baseline-audit-and-guard-repair/181-07-SUMMARY.md
    - .planning/phases/181-baseline-audit-and-guard-repair/screenshots/stress-states/stress-page-home-happy-dark-1024.png
    - .planning/phases/181-baseline-audit-and-guard-repair/screenshots/stress-states/stress-state-unavailable-down-dark-1024.png
    - .planning/phases/181-baseline-audit-and-guard-repair/screenshots/stress-states/stress-state-permission-denied-dark-1024.png
    - .planning/phases/181-baseline-audit-and-guard-repair/screenshots/stress-states/stress-state-pagination-boundary-dark-1024.png
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts
    - .planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md

key-decisions:
  - "Stress CI screenshots now read `.planning/design-system-ledger.json` `screenshot_allowlist.ci` directly instead of a separate hardcoded allowlist."
  - "The selected happy/error/permission/boundary stress-state PNGs are local-only planning evidence, not CI `toHaveScreenshot` baselines."
  - "The example-app `mix precommit` residual remains inherited demo-seed/walkthrough drift and is recorded rather than repaired in this screenshot guard plan."

patterns-established:
  - "Bounded stress screenshot tests iterate the ledger-owned CI allowlist and separately assert the allowlist remains length 3."
  - "Selected stress packet capture first proves each story exists in the ledger and renders on `/audit/__stress` before writing PNG evidence."

requirements-completed: [BASE-02, BASE-03]

duration: 6 min
completed: 2026-06-26
status: complete
---

# Phase 181 Plan 07: Bounded Stress Screenshot Guard Freshness Summary

**Ledger-backed stress screenshot guard with four local-only selected stress-state packet PNGs for D-181-07 happy/error/permission/boundary evidence.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-26T16:18:50Z
- **Completed:** 2026-06-26T16:24:36Z
- **Tasks:** 1
- **Files modified:** 7 including this summary

## Accomplishments

- Reworked `operator-stress.spec.ts` so ledger-owned CI screenshots are read from `.planning/design-system-ledger.json` `screenshot_allowlist.ci`.
- Added an env-gated `selected Tier C stress state packet` Playwright test that captures exactly `page.home.happy`, `state.unavailable-down`, `state.permission-denied`, and `state.pagination-boundary`.
- Captured four dark 1024px desktop PNGs under `screenshots/stress-states/` and recorded their dimensions, status, and rationale in `181-SCREENSHOT-INVENTORY.md`.
- Confirmed the existing three CI stress baselines stayed fresh; no baseline PNG update was needed.

## Task Commits

1. **Task 1: Verify bounded stress screenshot guard** - `f9738816` (test)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` - Reads the CI allowlist from the ledger, keeps the guard bounded to three cells, and adds the env-gated selected Tier C packet capture.
- `181-SCREENSHOT-INVENTORY.md` - Records Plan 07 command results, local packet paths, dimensions, and precommit residual disposition.
- `screenshots/stress-states/stress-page-home-happy-dark-1024.png` - Happy-state local packet evidence.
- `screenshots/stress-states/stress-state-unavailable-down-dark-1024.png` - Error/source-down local packet evidence.
- `screenshots/stress-states/stress-state-permission-denied-dark-1024.png` - Permission local packet evidence.
- `screenshots/stress-states/stress-state-pagination-boundary-dark-1024.png` - Boundary local packet evidence.

## Verification

| Check | Result |
|---|---|
| `mix verify.operator_stress` | Passed: 42 passed, 9 skipped. The three ledger-owned desktop screenshot cells matched current rendered truth. |
| `OPERATOR_STRESS_SCREENSHOT_DIR=.planning/phases/181-baseline-audit-and-guard-repair/screenshots/stress-states ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-stress.spec.ts --grep "selected Tier C stress state packet"` | Passed: 1 passed, 2 skipped. Generated the four local-only packet PNGs in the root phase directory. |
| `mix precommit` from `examples/threadline_phoenix` | Failed: 96 tests, 7 failures. These are the same inherited demo-seed/walkthrough contract residuals recorded by Plans 01 and 03. |
| Story ID source assertion | Passed: all four selected IDs are present in `operator-stress.spec.ts` and `stress_fixtures.ex`. |
| Inventory assertion | Passed: inventory contains the stress commands, local-only packet language, selected story IDs, and three existing CI baseline names. |
| CI allowlist expansion check | Passed: `.planning/design-system-ledger.json` `screenshot_allowlist.ci` length is still 3; only the ledger-owned block calls `toHaveScreenshot`. |
| `git diff --check` | Passed. |

## Decisions Made

- Kept the three existing stress CI screenshots as the only pixel ratchet cells.
- Stored selected stress-state PNGs as Phase 181 planning evidence, not Playwright snapshot baselines.
- Resolved `OPERATOR_STRESS_SCREENSHOT_DIR` relative to the repo root so the E2E runner's working directory does not place packets under `examples/threadline_phoenix/e2e/.planning`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `examples/threadline_phoenix` `mix precommit` remains red in the inherited demo-seed/walkthrough contract tests around old `#4521`/`#4518` May anchor rows, `agent2` window rows, and `org_memberships` actor attribution. This is the same residual class recorded by Plans 01 and 03 and was not caused by Plan 07's Playwright spec, inventory, or PNG packet changes.

## Auth Gates

None.

## Known Stubs

None. Stub-pattern scan only matched the historical failed assertion text `Coverage inspection is not available` already preserved in the screenshot inventory.

## Threat Flags

None. The plan changed a Playwright spec, planning inventory, and local screenshot evidence only; it introduced no new endpoint, auth path, file access pattern outside the env-gated packet directory, schema change, dependency, route path, public component API, production story surface, or capture/query/auth semantic.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `181-08`. The stress screenshot guard is fresh, ledger-backed, bounded to the accepted CI allowlist, and the selected Tier C stress-state packet is inventoried for downstream local screenshot-regression classification.

## Self-Check: PASSED

- Found task commit `f9738816` in git history.
- Found all four stress-state PNG packet files under the phase screenshots directory.
- Found `181-SCREENSHOT-INVENTORY.md` with Plan 07 command evidence and local-only packet rows.
- Verified the working tree was clean after the task commit before summary creation.
- No tracked file deletions were introduced by the task commit.

---
*Phase: 181-baseline-audit-and-guard-repair*
*Completed: 2026-06-26*
