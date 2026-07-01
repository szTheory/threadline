---
phase: 181-baseline-audit-and-guard-repair
plan: 10
subsystem: testing
tags: [operator-ui, screenshots, playwright, baseline, local-guard]

requires:
  - phase: 181-09
    provides: no-update confirmation for Home and dense Timeline local screenshot-regression PNG baselines
provides:
  - Verified no-update confirmation for Row-history, Exports, and Retention local screenshot-regression PNG baselines
  - Inventory-backed evidence that Plan 10 did not mutate PNGs, Playwright specs, stress snapshots, or CI allowlists
affects: [181-11, 186, 187]

tech-stack:
  added: []
  patterns:
    - Accepted local screenshot baseline updates must be inventory-classified before PNG mutation
    - When inventory accepts no update, rerun the bounded subset and record no-update evidence instead of forcing snapshot churn

key-files:
  created:
    - .planning/phases/181-baseline-audit-and-guard-repair/181-10-SUMMARY.md
  modified:
    - .planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md

key-decisions:
  - "Plan 10 left all six Row-history/Exports/Retention PNG baselines untouched because Plan 08 classified them as current committed local baselines with no accepted update."
  - "No `--update-snapshots` run was performed; the bounded confirmation subset passed against existing desktop/mobile local baselines."
  - "The example-app `mix precommit` residual remains inherited demo-seed/walkthrough drift and is unrelated to Plan 10."

patterns-established:
  - "Plan 10 no-update evidence records command, project, surface, viewport, snapshot path, committed status, and rationale in `181-SCREENSHOT-INVENTORY.md`."

requirements-completed: [BASE-01, BASE-02]

duration: 3 min
completed: 2026-06-26
status: complete
---

# Phase 181 Plan 10: Accepted Row-history, Exports, and Retention Local PNG Baselines Summary

**Row-history, Exports, and Retention local screenshot-regression baselines were confirmed current without mutating PNG snapshots or expanding CI screenshot coverage.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-26T16:47:24Z
- **Completed:** 2026-06-26T16:49:49Z
- **Tasks:** 1
- **Files modified:** 2 including this summary

## Accomplishments

- Re-ran the bounded Row-history/Exports/Retention screenshot-regression subset and confirmed the existing desktop/mobile baselines still match current rendered truth.
- Added Plan 10 inventory evidence for all six target PNG paths with no-update rationale and committed status.
- Confirmed no Home, dense Timeline, stress, Playwright spec, design-system ledger, CI allowlist, Row-history, Exports, or Retention PNG file changed.

## Task Commits

1. **Task 1: Apply accepted Row-history, Exports, and Retention PNG updates** - `f9f10c16` (docs)

## Files Created/Modified

- `.planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md` - Added Plan 10 no-update confirmation, subset command result, inherited precommit residual note, per-baseline disposition rows, and BASE-02 metadata coverage.
- `.planning/phases/181-baseline-audit-and-guard-repair/181-10-SUMMARY.md` - Plan closeout summary.

## Verification

| Check | Result |
|---|---|
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshot-regression.spec.ts --grep "row-history\|Exports\|Retention"` | Passed: 6 passed, 3 skipped. |
| `mix precommit` from `examples/threadline_phoenix` | Failed: 96 tests, 7 failures. Same inherited demo-seed/walkthrough contract residuals recorded by Plans 01, 07, 08, and 09; no PNG or example-app source change was made by Plan 10. |
| `test -s 181-SCREENSHOT-INVENTORY.md && rg -n "Plan 10\|row-history-desktop-chromium\|row-history-mobile-chromium\|exports-desktop-chromium\|exports-mobile-chromium\|retention-desktop-chromium\|retention-mobile-chromium" ...` | Passed: Plan 10 evidence and all six target snapshot paths are recorded. |
| `git diff --name-only \| rg '\.png$'` | Passed: no PNG files changed. |
| `git diff --name-only \| rg 'operator-screenshot-regression\.spec\.ts\|operator-stress\.spec\.ts\|design-system-ledger\|home-\|timeline-dense\|stress'` | Passed: no spec, stress, Home, dense Timeline, or CI allowlist files changed. |
| `git diff --check` | Passed before task commit. |

## Acceptance Criteria

- **Row-history/Exports/Retention subset passes:** satisfied by the Playwright subset run.
- **Example-app precommit run:** satisfied by running `mix precommit`; failures match the inherited demo-seed residual class from earlier Phase 181 plans.
- **Changed PNGs have accepted-update rows:** satisfied vacuously because no PNGs changed; Plan 08 and Plan 10 inventory rows explicitly record no accepted update for the six target paths.
- **No unrelated PNG/spec/allowlist changes:** satisfied by git diff checks before the task commit.

## Decisions Made

- Treated Plan 08's current-baseline classification as authoritative and did not run `--update-snapshots`.
- Preserved the generic `chromium` skip behavior and kept fixed local baselines scoped to `desktop-chromium` and `mobile-chromium`.
- Recorded no-update evidence in the inventory so Plan 11 closeout can distinguish "current baseline" from "not checked."

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Documentation Metadata] Added BASE-02 to screenshot inventory requirements**
- **Found during:** Task 1 (Apply accepted Row-history, Exports, and Retention PNG updates)
- **Issue:** `181-SCREENSHOT-INVENTORY.md` frontmatter listed BASE-01 and BASE-03 while the screenshot baseline inventory also carries BASE-02 ratchet evidence.
- **Fix:** Added BASE-02 to the inventory frontmatter requirements list while recording Plan 10 evidence.
- **Files modified:** `.planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md`
- **Verification:** Inventory source check passed and Plan 10 acceptance checks confirmed no PNG/spec/allowlist drift.
- **Committed in:** `f9f10c16`

---

**Total deviations:** 1 auto-fixed (1 documentation metadata bug)
**Impact on plan:** The correction aligns metadata with the artifact's existing role and does not expand screenshot scope or mutate runtime/source behavior.

## Issues Encountered

- `examples/threadline_phoenix` `mix precommit` remains red in inherited demo-seed/walkthrough contract tests around old #4521/#4518 anchor rows, leaving-agent window rows, and org-membership actor attribution. Plan 10 did not change Elixir source, seed data, capture/query/auth semantics, route paths, Playwright specs, or PNG baselines.

## Auth Gates

None.

## Known Stubs

None. The stub scan matched a historical quoted Coverage assertion phrase in the inventory, not a hardcoded UI-empty value or newly introduced placeholder.

## Threat Flags

None. The plan changed planning inventory and summary documentation only; it introduced no endpoint, auth path, file access pattern outside existing screenshot evidence references, schema change, dependency, route path, public component API, production story surface, or capture/query/auth semantic.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `181-11`. Plan 10 confirmed the Row-history, Exports, and Retention local baselines are current and untouched; final closeout can rely on Plan 08, 09, and 10 inventory evidence for the complete local screenshot-regression baseline set.

## Self-Check: PASSED

- Found `.planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md`.
- Found task commit `f9f10c16` in git history.
- Confirmed no PNG files were modified by Plan 10.
- Confirmed no screenshot regression spec, stress spec, stress snapshot, design-system ledger, Home, dense Timeline, Row-history, Exports, or Retention PNG file was modified by Plan 10.
- Confirmed this summary file exists and records the verification residual.

---
*Phase: 181-baseline-audit-and-guard-repair*
*Completed: 2026-06-26*
