---
phase: 179-microcopy-information-architecture-sweep
plan: 06
subsystem: operator-surface
tags: [microcopy, stress-route, copy-evidence, phoenix-liveview, playwright]

requires:
  - phase: 179-microcopy-information-architecture-sweep
    provides: Final page-level copy and IA terminology from plans 179-01 through 179-05
  - phase: 178-per-page-flow-stress-pass-all-11-pages
    provides: Shared shell, stress route, ledger screenshot baselines, and page stress coverage
provides:
  - Phase 179 copy-state evidence rendered through existing stress story ids
  - Browser proof that permission, unavailable, redacted, pruned, stale, evidence, retention, and destructive copy render on `/audit/__stress`
  - Preserved stress story ids, ledger ids, route paths, selectors, and screenshot baselines
affects: [operator-surface, stress-route, phase-179, copy-contracts, phase-180]

tech-stack:
  added: []
  patterns:
    - Existing stress story ids carry copy evidence through fixture summaries and assigns
    - Stress page and footgun screenshots stay bounded by hiding the component matrix for non-component story categories

key-files:
  created:
    - .planning/phases/179-microcopy-information-architecture-sweep/179-06-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/stress_fixtures.ex
    - lib/threadline/operator_surface/live/stress_live.ex
    - test/threadline/operator_surface/stress_fixtures_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts
    - .planning/phases/179-microcopy-information-architecture-sweep/deferred-items.md

key-decisions:
  - "Phase 179 stress copy evidence was added to existing story ids only; no stress story, ledger id, route, selector, density knob, capability, ledger row, or DESIGN-SYSTEM projection was added."
  - "The component matrix remains available for component/state/foundation stress stories, but page, footgun, and future-reserved screenshot targets stay bounded to preserve the Phase 178 ledger baselines."

patterns-established:
  - "Final copy-state evidence is asserted both at the fixture contract layer and through the browser stress route."
  - "Broad proof wording is excluded from Evidence stress copy except the allowed `proof history` append-only context."

requirements-completed: [COPY-01, COPY-02, COPY-03]

duration: 8m
completed: 2026-06-19
status: complete
---

# Phase 179 Plan 06: Stress Copy Evidence Summary

**Stress-route copy evidence now reflects the final Phase 179 state grammar while preserving the existing stress registry and ledger contracts.**

## Performance

- **Duration:** 8m
- **Started:** 2026-06-19T20:43:57Z
- **Completed:** 2026-06-19T20:51:47Z
- **Tasks:** 1 TDD task
- **Files modified:** 5

## Accomplishments

- Added RED fixture and browser assertions for the final Phase 179 copy states on existing stress stories.
- Updated `StressFixtures` copy evidence for permission, unavailable, redacted, pruned, stale, Evidence, Retention, and destructive prune states.
- Kept story ids, ledger ids, fixture keys, selectors, route paths, and screenshot baselines stable.
- Fixed a stress-route preview issue where page/footgun screenshot baselines were capturing the full component matrix instead of the bounded story preview.

## Task Commits

1. **Task 1 RED: Add failing stress copy evidence tests** - `a9fb0c6` (`test`)
2. **Task 1 GREEN: Refresh stress copy evidence** - `a6bd7f8` (`feat`)

_TDD gate satisfied: RED test commit precedes GREEN implementation commit._

## Files Created/Modified

- `lib/threadline/operator_surface/stress_fixtures.ex` - Existing fixture summaries and permission-state assigns now carry final Phase 179 state copy.
- `lib/threadline/operator_surface/live/stress_live.ex` - Component matrix is hidden for page/footgun/future-reserved story previews so screenshot baselines remain bounded.
- `test/threadline/operator_surface/stress_fixtures_test.exs` - Fixture-level Phase 179 copy-state assertions and updated permission adapter expectation.
- `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` - Browser stress-route assertions for the final copy-state evidence.
- `.planning/phases/179-microcopy-information-architecture-sweep/deferred-items.md` - Current `mix ci.all` inherited failure list recorded.

## Decisions Made

- Reused existing stress story ids such as `state.permission-denied`, `state.unavailable-down`, `state.unavailable-redacted`, `state.unavailable-pruned`, `state.stale`, `page.evidence.happy`, `page.retention.happy`, and `group.modal-destructive.current`.
- Did not edit `.planning/design-system-ledger.json` or `DESIGN-SYSTEM.md`; ledger parity stayed green because only copy-owned fixture fields changed.
- Preserved `proof history` only for append-only Evidence detail context and rejected broader `proof` wording in the Evidence stress copy.

## Verification

- RED observed: `mix test test/threadline/operator_surface/stress_fixtures_test.exs --max-failures 1` failed on the new `state.permission-denied` Phase 179 copy assertion, proving the old fixture copy was still present.
- Passed: `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs` - 29 tests, 0 failures.
- Passed: `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-stress.spec.ts` - 42 passed, 6 skipped across Chromium, desktop Chromium, and mobile Chromium.
- Failed with inherited issues: `mix ci.all`.
  - Root suite: 1114 tests, 1 failure in `test/threadline/v1_23_charter_doc_contract_test.exs:15` for older milestone wording.
  - Example suite: 95 tests, 7 failures in demo seed/walkthrough audit-row expectations.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Bounded page/footgun stress screenshot previews**
- **Found during:** Task 1 GREEN browser verification.
- **Issue:** `operator-stress.spec.ts` copy assertions passed, but the same spec failed three ledger screenshot baselines because page/footgun stories captured the full Phase 173 component matrix at 6355px tall instead of the bounded 478px story preview.
- **Fix:** `StressLive` now renders the component matrix only for foundation, primitive, form-control, group, and state story categories.
- **Files modified:** `lib/threadline/operator_surface/live/stress_live.ex`
- **Verification:** `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-stress.spec.ts` passed, including the existing ledger screenshot baselines.
- **Committed in:** `a6bd7f8`

---

**Total deviations:** 1 auto-fixed (Rule 3 blocking verification issue)
**Impact on plan:** The fix preserved existing Phase 178 screenshot coverage while keeping component/state stress previews intact. No route, story id, ledger id, capability, public API, dependency, or ledger/projection file changed.

## Issues Encountered

- `mix ci.all` still fails outside this plan on the inherited root charter-doc wording mismatch and example demo seed/audit-row expectations. The current 179-06 failure list is recorded in `deferred-items.md`.

## Deferred Issues

- `test/threadline/v1_23_charter_doc_contract_test.exs:15` expects older `PROJECT.md` milestone wording.
- Example demo seed/walkthrough tests cannot find expected `#4521` close transactions, delete incidents, leaving-agent counts, or `org_memberships` actor attribution rows.

## Known Stubs

- `lib/threadline/operator_surface/live/stress_live.ex:269` contains `UI.avatar src="" alt="Avatar"` inside the pre-existing component matrix. This is an intentional stress atom for the avatar fallback state, not mock data wired to production UI.

## Threat Flags

None. This plan changed fixture copy, stress preview rendering, and assertions only; it introduced no endpoint, auth path, file access pattern, schema change, dependency, route, or public API.

## Authentication Gates

None.

## TDD Gate Compliance

- RED commit present before implementation: `a9fb0c6`.
- GREEN commit present after RED: `a6bd7f8`.
- REFACTOR commit not needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 179 is complete. Phase 180 can use the stress route as final copy-state evidence for accessibility, motion, guardrail, and adversarial closeout work, with the inherited full-CI failures tracked separately.

## Self-Check: PASSED

- Verified summary path exists: `.planning/phases/179-microcopy-information-architecture-sweep/179-06-SUMMARY.md`.
- Verified task commits exist in git history: `a9fb0c6`, `a6bd7f8`.
- Verified key modified files exist on disk and no tracked files were deleted by either task commit.
- Verified untracked files remain unrelated and unstaged: `.git-commit-task1.sh`, `.git-commit-task2.sh`, `.planning/v1.37-MILESTONE-AUDIT.md`, `.update_roadmap.rb`, `fix_theme.exs`.

---
*Phase: 179-microcopy-information-architecture-sweep*
*Completed: 2026-06-19*
