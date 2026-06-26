---
phase: 181-baseline-audit-and-guard-repair
plan: 09
subsystem: testing
tags: [operator-ui, screenshots, playwright, baseline, local-guard]

requires:
  - phase: 181-08
    provides: local screenshot-regression baseline classification for Home and dense Timeline
provides:
  - Verified no-update confirmation for Home and dense Timeline local screenshot-regression PNG baselines
  - Inventory-backed evidence that Plan 09 did not mutate PNGs, Playwright specs, stress snapshots, or CI allowlists
affects: [181-10, 181-11, 183, 184, 187]

tech-stack:
  added: []
  patterns:
    - Accepted local screenshot baseline updates must be inventory-classified before PNG mutation
    - When inventory accepts no update, rerun the bounded subset and record no-update evidence instead of forcing snapshot churn

key-files:
  created:
    - .planning/phases/181-baseline-audit-and-guard-repair/181-09-SUMMARY.md
  modified:
    - .planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md

key-decisions:
  - "Plan 09 left all four Home/dense Timeline PNG baselines untouched because Plan 08 classified them as current committed local baselines with no accepted update."
  - "No `--update-snapshots` run was performed; the bounded confirmation subset passed against existing desktop/mobile local baselines."
  - "The example-app `mix precommit` residual remains inherited demo-seed/walkthrough drift and is unrelated to Plan 09."

patterns-established:
  - "Plan 09 no-update evidence records command, project, surface, viewport, snapshot path, committed status, and rationale in `181-SCREENSHOT-INVENTORY.md`."

requirements-completed: [BASE-01, BASE-02]

duration: 3 min
completed: 2026-06-26
status: complete
---

# Phase 181 Plan 09: Accepted Home and Dense Timeline Local PNG Baselines Summary

**Home and dense Timeline local screenshot-regression baselines were confirmed current without mutating PNG snapshots or expanding CI screenshot coverage.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-26T16:39:06Z
- **Completed:** 2026-06-26T16:41:45Z
- **Tasks:** 1
- **Files modified:** 2 including this summary

## Accomplishments

- Re-ran the bounded Home/dense Timeline screenshot-regression subset and confirmed the existing desktop/mobile baselines still match current rendered truth.
- Added Plan 09 inventory evidence for all four target PNG paths with no-update rationale and committed status.
- Confirmed no Home, Timeline, row-history, Exports, Retention, stress, Playwright spec, design-system ledger, or CI allowlist file changed.

## Task Commits

1. **Task 1: Apply accepted Home and dense Timeline PNG updates** - `a2bfe712` (docs)

## Files Created/Modified

- `.planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md` - Added Plan 09 no-update confirmation, subset command result, inherited precommit residual note, and per-baseline disposition rows.
- `.planning/phases/181-baseline-audit-and-guard-repair/181-09-SUMMARY.md` - Plan closeout summary.

## Verification

| Check | Result |
|---|---|
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshot-regression.spec.ts --grep "global chrome\|dense Timeline"` | Passed: 4 passed, 2 skipped. |
| `mix precommit` from `examples/threadline_phoenix` | Failed: 96 tests, 7 failures. Same inherited demo-seed/walkthrough contract residuals recorded by Plans 01, 07, and 08; no PNG or example-app source change was made by Plan 09. |
| `test -s 181-SCREENSHOT-INVENTORY.md && rg -n "Plan 09|home-desktop-chromium|home-mobile-chromium|timeline-dense-desktop-chromium|timeline-dense-mobile-chromium" ...` | Passed: Plan 09 evidence and all four target snapshot paths are recorded. |
| `git diff --name-only \| rg '\.png$'` | Passed: no PNG files changed. |
| `git diff --name-only \| rg 'operator-screenshot-regression\.spec\.ts|operator-stress\.spec\.ts|design-system-ledger|row-history|exports|retention|stress'` | Passed: no spec, stress, row-history, Exports, Retention, or CI allowlist files changed. |
| `git diff --check` | Passed before task commit. |

## Acceptance Criteria

- **Home/Timeline subset passes:** satisfied by the Playwright subset run.
- **Example-app precommit run:** satisfied by running `mix precommit`; failures match the inherited demo-seed residual class from earlier Phase 181 plans.
- **Changed PNGs have accepted-update rows:** satisfied vacuously because no PNGs changed; Plan 08 and Plan 09 inventory rows explicitly record no accepted update for the four target paths.
- **No unrelated PNG/spec/allowlist changes:** satisfied by git diff checks before the task commit.

## Decisions Made

- Treated Plan 08's current-baseline classification as authoritative and did not run `--update-snapshots`.
- Preserved the generic `chromium` skip behavior and kept fixed local baselines scoped to `desktop-chromium` and `mobile-chromium`.
- Recorded no-update evidence in the inventory so Plan 10 and closeout can distinguish "current baseline" from "not checked."

## Deviations from Plan

None - plan executed within the accepted no-update branch described by the task instructions.

## Issues Encountered

- `examples/threadline_phoenix` `mix precommit` remains red in inherited demo-seed/walkthrough contract tests around old #4521/#4518 anchor rows, leaving-agent window rows, and org-membership actor attribution. Plan 09 did not change Elixir source, seed data, capture/query/auth semantics, route paths, Playwright specs, or PNG baselines.

## Auth Gates

None.

## Known Stubs

None. The stub scan matched a historical quoted Coverage assertion phrase in the inventory, not a hardcoded UI-empty value or newly introduced placeholder.

## Threat Flags

None. The plan changed planning inventory and summary documentation only; it introduced no endpoint, auth path, file access pattern outside existing screenshot evidence references, schema change, dependency, route path, public component API, production story surface, or capture/query/auth semantic.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `181-10`. Plan 09 confirmed the Home and dense Timeline local baselines are current and untouched; Plan 10 should continue from the Plan 08 no-accepted-update classification for row-history, Exports, and Retention.

## Self-Check: PASSED

- Found `.planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md`.
- Found task commit `a2bfe712` in git history.
- Confirmed no PNG files were modified by Plan 09.
- Confirmed no screenshot regression spec, stress spec, stress snapshot, design-system ledger, row-history, Exports, or Retention PNG file was modified by Plan 09.
- Confirmed this summary file exists and records the verification residual.

---
*Phase: 181-baseline-audit-and-guard-repair*
*Completed: 2026-06-26*
