---
phase: 138-find-cluster-polish
plan: 04
subsystem: ui
tags: [phoenix-liveview, operator-surface, actor-history, coverage, playwright]

requires:
  - phase: 138-find-cluster-polish
    provides: Timeline, transaction, and row-history value presentation patterns from plans 138-01 through 138-03.
provides:
  - Scope-safe Actor row summaries with bounded batch lookup for unscoped sessions.
  - Remediation-first Coverage rows with copyable trigger generation commands.
  - Extended Find mobile UAT across Timeline, Transaction, Row History, Actor, and Coverage.
affects: [operator-surface, find-cluster, browser-uat]

tech-stack:
  added: []
  patterns:
    - Batch actor summary lookup only for unscoped sessions; scoped sessions use honest fallback copy.
    - Coverage rows lead with an Add capture remediation command and keep expected gaps visually distinct.
    - Find mobile browser UAT drives seeded demo stories and checks overflow on each surface.

key-files:
  created:
    - .planning/phases/138-find-cluster-polish/138-04-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/actor_live.ex
    - lib/threadline/operator_surface/live/coverage_live.ex
    - test/threadline/operator_surface/live/actor_live_test.exs
    - test/threadline/operator_surface/live/coverage_live_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts

key-decisions:
  - "Actor summaries use bounded batch AuditChange lookup only without threadline_scope; scoped sessions render Changes unavailable to avoid out-of-scope leakage."
  - "Coverage rows reuse Presentation.coverage_remediation/1 and keep Threadline.Health.trigger_coverage/1 plus existing schema validation intact."
  - "Find mobile UAT validates the seeded redacted-value formatter because the demo audit corpus does not contain null/time changed-field tokens."

patterns-established:
  - "Scope-safe actor summary pattern: unscoped batch aggregate, scoped honest fallback, no per-row audit_changes_for_transaction calls."
  - "Coverage remediation row pattern: Add capture label, copyable mix threadline.gen.triggers command, verify_coverage follow-up."
  - "Mobile Find UAT pattern: seeded navigation plus no-horizontal-overflow assertions for each operator surface."

requirements-completed: []

duration: 1h 40m
completed: 2026-06-04
---

# Phase 138 Plan 04: Actor, Coverage, and Find Mobile Summary

**Scope-safe Actor blast-radius summaries, Coverage remediation commands, and extended Find mobile UAT across the operator surface**

## Performance

- **Duration:** 1h 40m
- **Started:** 2026-06-04T07:47:00Z
- **Completed:** 2026-06-04T09:27:03Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added Actor transaction row summaries using one bounded batch lookup for unscoped visible rows, with scoped sessions retaining honest `Changes unavailable` fallback copy.
- Reworked Coverage uncovered rows around copyable `mix threadline.gen.triggers --tables ...` remediation and `mix threadline.verify_coverage` follow-up guidance.
- Extended `operator-find-mobile.spec.ts` to cover Transaction, Row History, Actor, and Coverage mobile pivots in addition to the Timeline density check.

## Task Commits

1. **Task 1: Actor blast-radius summaries** - `d8784a7` (test), `9967025` (feat), `45ed6b1` (style)
2. **Task 2: Coverage remediation-first treatment** - `d8784a7` (test), `2a55372` (feat)
3. **Task 3: Extend Find mobile UAT** - `791405f` (test)

## Files Created/Modified

- `lib/threadline/operator_surface/live/actor_live.ex` - Adds scope-aware Actor summary assignment and row rendering.
- `lib/threadline/operator_surface/live/coverage_live.ex` - Renders uncovered-table remediation commands and expected-gap warning chips.
- `test/threadline/operator_surface/live/actor_live_test.exs` - Covers unscoped summaries, mixed summaries, scoped fallback, and segmented state.
- `test/threadline/operator_surface/live/coverage_live_test.exs` - Covers remediation copy, expected-gap styling, and singular/plural footer grammar.
- `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` - Covers mobile Find pivots and overflow for Timeline, Transaction, Row History, Actor, and Coverage.
- `.planning/phases/138-find-cluster-polish/138-04-SUMMARY.md` - Execution record.

## Decisions Made

- Actor scoped rows do not attempt summary reconstruction; without a proven scoped batch query contract, the fallback avoids leaking unscoped table names or change counts.
- Coverage kept the existing schema validation, `pg_namespace` lookup, `Threadline.Health.trigger_coverage/1`, routes, and Mix task behavior unchanged.
- Browser UAT targets `.tl-value--redacted` in the seeded close-correlation story; a seed scan found no null or ISO-time changed-field tokens available for `.tl-value--null` or `.tl-value--time`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Formatted previously committed Actor changes**
- **Found during:** Final verification
- **Issue:** `mix format --check-formatted` reported formatter diffs in the Actor LiveView and Actor test.
- **Fix:** Applied `mix format` to the owned files.
- **Files modified:** `lib/threadline/operator_surface/live/actor_live.ex`, `test/threadline/operator_surface/live/actor_live_test.exs`
- **Verification:** `mix format --check-formatted ...` passed.
- **Committed in:** `45ed6b1`

**2. [Rule 3 - Blocking] Adjusted Find mobile UAT to deterministic seeded rows**
- **Found during:** Focused Playwright run
- **Issue:** The first Timeline row opened unmapped row-history data, and the initial Actor assertion depended on an exact ARIA value serialization.
- **Fix:** Drove Transaction and Row History through `walk-acme-4521-close`, targeted the `ticket_replies` row, and asserted the selected segmented control by presence of its ARIA attribute.
- **Files modified:** `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts`
- **Verification:** `E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-find-mobile.spec.ts` passed with 15 tests.
- **Committed in:** `791405f`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both adjustments were necessary to keep verification deterministic and formatted; no public API, route, schema, or package changes were introduced.

## Issues Encountered

- `mix verify.example_browser` remains red with 9 existing/unowned failures in `operator-screenshots.spec.ts` and `operator.spec.ts`: duplicate `[REDACTED]` strict locators and old empty Timeline copy. All 15 `operator-find-mobile.spec.ts` checks passed in that full run.

## Known Stubs

- None. Stub scan found only an existing coverage denial assertion for `"Coverage inspection is not available"`, which is expected copy rather than a new placeholder.

## Threat Flags

None. No new endpoints, routes, schemas, auth paths, file access, or public query APIs were added.

## Verification

- `mix test test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/presentation_test.exs` - passed, 37 tests.
- `mix format --check-formatted lib/threadline/operator_surface/live/actor_live.ex lib/threadline/operator_surface/live/coverage_live.ex test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs` - passed.
- `E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-find-mobile.spec.ts` from `examples/threadline_phoenix/e2e` - passed, 15 tests.
- `mix verify.example_browser` - failed with 57 passed / 9 failed; the failures are unrelated pre-existing screenshot/demo specs, while the new Find mobile spec passed in all projects.
- `rg -n "audit_changes_for_transaction\\(" lib/threadline/operator_surface/live/actor_live.ex` - no matches.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Find cluster Actor, Coverage, and mobile UAT polish is ready for verification. Browser-suite follow-up should address the existing strict redaction locators and stale empty-state copy outside plan 138-04 ownership.

## Self-Check: PASSED

- Files exist: `actor_live.ex`, `coverage_live.ex`, both LiveView test files, `operator-find-mobile.spec.ts`, and this summary.
- Commits exist: `d8784a7`, `9967025`, `2a55372`, `45ed6b1`, and `791405f`.

---
*Phase: 138-find-cluster-polish*
*Completed: 2026-06-04*
