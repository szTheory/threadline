---
phase: 179-microcopy-information-architecture-sweep
plan: 03
subsystem: ui
tags: [microcopy, information-architecture, phoenix-liveview, operator-surface, audit-readiness]

requires:
  - phase: 179-microcopy-information-architecture-sweep
    provides: Shared state copy templates and unsupported-state grammar from 179-02
provides:
  - Sentence-case investigation and readiness copy for actor, transaction, row-history, and coverage pages
  - Canonical audit-domain terms for actor references, database transactions, row-level changes, row snapshots, and table coverage status
  - Preserved route, parameter, direct-link, data-testid, and full-value copy affordance behavior
affects: [operator-surface, phase-179, copy, investigation, audit-readiness]

tech-stack:
  added: []
  patterns:
    - Guard-first TDD for page-specific investigation and readiness copy
    - Page-owned copy updates that consume the 179-02 shared state grammar without introducing a copy registry
    - Targeted broader-contract updates only where this plan intentionally changed visible copy

key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/actor_live.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - lib/threadline/operator_surface/live/row_history_component.ex
    - lib/threadline/operator_surface/live/coverage_live.ex
    - test/threadline/operator_surface/live/actor_live_test.exs
    - test/threadline/operator_surface/transaction_live_test.exs
    - test/threadline/operator_surface/live/row_history_live_test.exs
    - test/threadline/operator_surface/live/coverage_live_test.exs
    - test/threadline/operator_surface/coverage_doc_contract_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix_web/sigra_auth_flow_test.exs
    - .planning/phases/179-microcopy-information-architecture-sweep/deferred-items.md

key-decisions:
  - "Actor, transaction, row-history, and coverage copy stayed inside existing page modules/components; no route, LiveView module, public API, helper registry, dependency, or capability was added."
  - "Coverage status copy now uses `covered` for table status and `need capture` for remediation, avoiding overclaims such as complete timeline answers or proof that capture is complete."
  - "Broader example and documentation contracts were updated only where the plan-owned visible copy made old `Transaction Not Found` and `Captured` assertions stale."

patterns-established:
  - "Investigation states name the object, state what happened, and give the next operator action."
  - "Readiness copy distinguishes table coverage status from audit completeness claims."

requirements-completed: [COPY-01, COPY-02, COPY-03]

duration: 13m 39s
completed: 2026-06-19
status: complete
---

# Phase 179 Plan 03: Investigation and Readiness Page Copy Summary

**Canonical investigation/readiness microcopy for actor, transaction, row-history, and coverage pages**

## Performance

- **Duration:** 13m 39s
- **Started:** 2026-06-19T19:20:03Z
- **Completed:** 2026-06-19T19:33:42Z
- **Tasks:** 1 TDD task
- **Files modified:** 12

## Accomplishments

- Normalized actor invalid-reference and no-activity states to sentence-case copy with object-specific next actions.
- Rewrote transaction not-found and no-row-change states around `database transaction`, `row-level changes`, `retention policy`, `Timeline`, and `audit readiness`.
- Rewrote row-history snapshot failure copy so deleted, before-horizon, and generic failures name the row snapshot and tell the operator which direction to move.
- Reworked coverage readiness language around table coverage status, `covered`, `need capture`, expected gaps, and retry/remediation guidance without claiming complete audit proof.
- Preserved existing route helpers, URL params, direct links, current atoms, data-testids, and `data-tl-copy` bindings.

## Task Commits

TDD commits for the single task:

1. **Task 1 RED: Sweep investigation and readiness domain copy** - `48265b0` (test)
2. **Task 1 GREEN: Sweep investigation and readiness domain copy** - `3c0b0a8` (feat)

## Files Created/Modified

- `lib/threadline/operator_surface/live/actor_live.ex` - Actor invalid-reference, never-acted, and selected-window empty-state copy.
- `lib/threadline/operator_surface/live/transaction_live.ex` - Transaction not-found and row-level-change empty-state copy.
- `lib/threadline/operator_surface/live/row_history_component.ex` - Row snapshot failure copy for deleted, before-horizon, and generic states.
- `lib/threadline/operator_surface/live/coverage_live.ex` - Audit-readiness ledes, stale retry copy, coverage metrics, status chips, remediation copy, and footer summary.
- `test/threadline/operator_surface/live/actor_live_test.exs` - Actor copy contracts and scoped actor expectation.
- `test/threadline/operator_surface/transaction_live_test.exs` - Transaction copy contracts for not-found and no-row-change states.
- `test/threadline/operator_surface/live/row_history_live_test.exs` - Snapshot-as-of and row snapshot failure copy contracts.
- `test/threadline/operator_surface/live/coverage_live_test.exs` - Coverage readiness, status, and overclaim-avoidance contracts.
- `test/threadline/operator_surface/coverage_doc_contract_test.exs` - Updated broader coverage badge contract from `Captured` to `Covered`.
- `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` - Updated example transaction not-found assertions to sentence case.
- `examples/threadline_phoenix/test/threadline_phoenix_web/sigra_auth_flow_test.exs` - Updated example auth-flow transaction not-found assertion to sentence case.
- `.planning/phases/179-microcopy-information-architecture-sweep/deferred-items.md` - Recorded remaining out-of-scope full-CI failures observed during 179-03 verification.

## Decisions Made

- Kept page-specific investigation copy local to the owning LiveViews/components rather than introducing a cross-page copy registry.
- Used `covered` as the operator-facing table status and reserved `need capture` for remediation so Coverage does not overstate audit completeness.
- Treated stale example and doc-contract assertions as direct fallout from this plan's copy changes and updated them in the GREEN commit.

## Verification

- `mix test test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs` - RED before implementation: 113 tests, 12 expected failures.
- `mix test test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs` - PASS after implementation: 113 tests, 0 failures.
- `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/live` - PASS, 137 tests.
- `mix test test/threadline/operator_surface/coverage_doc_contract_test.exs` - PASS, 29 tests.
- `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/operator_surface_test.exs:27 test/threadline_phoenix_web/operator_surface_test.exs:41 test/threadline_phoenix_web/sigra_auth_flow_test.exs:101` - PASS, 3 tests.
- `mix ci.all` - FAIL after plan-caused stale contracts were fixed: root suite reported 1113 tests with 1 known PROJECT.md charter-doc failure; example verification reported 95 tests with 9 known/out-of-scope demo seed, walkthrough, and prior evidence-copy failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated stale broader contracts for plan-owned copy**
- **Found during:** Final `mix ci.all` verification.
- **Issue:** Broader contracts still expected `>Captured<` and `Transaction Not Found` after this plan intentionally changed visible coverage and transaction copy.
- **Fix:** Updated the coverage doc contract and example transaction assertions to the new `Covered` and `Transaction not found` copy.
- **Files modified:** `test/threadline/operator_surface/coverage_doc_contract_test.exs`, `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs`, `examples/threadline_phoenix/test/threadline_phoenix_web/sigra_auth_flow_test.exs`
- **Commit:** `3c0b0a8`

## Issues Encountered

- `mix ci.all` still fails in out-of-scope areas after this plan's stale contracts were fixed:
  - `test/threadline/v1_23_charter_doc_contract_test.exs:15` expects older `PROJECT.md` milestone wording.
  - `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs:75` expects prior evidence unsupported copy (`Evidence view unavailable.`).
  - Example demo seed/walkthrough tests continue to miss expected seeded audit rows, delete timestamps, close transactions, and `org_memberships` actor attribution.
- These are recorded in `.planning/phases/179-microcopy-information-architecture-sweep/deferred-items.md`.

## Known Stubs

None. Stub-pattern scan hits were existing empty-list branches, non-empty test assertions, and the established sentinel-placeholder comment for full-copy targets; none block this plan's goal.

## Threat Flags

None. This plan changed rendered copy and tests only; it introduced no new endpoint, auth path, file access pattern, schema change, dependency, or trust boundary.

## Authentication Gates

None.

## TDD Gate Compliance

- RED commit present before implementation: `48265b0`.
- GREEN commit present after RED: `3c0b0a8`.
- REFACTOR commit not needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 179-04. Investigation and audit-readiness pages now use canonical domain terms and controlled state grammar while preserving existing workflows and copy affordances.

## Self-Check: PASSED

- Verified summary path exists: `.planning/phases/179-microcopy-information-architecture-sweep/179-03-SUMMARY.md`.
- Verified modified runtime, test, example, and deferred-items files exist on disk.
- Verified task commits exist in git history: `48265b0`, `3c0b0a8`.
- Verified plan-local, carried copy/live, coverage doc, and targeted example transaction-copy tests pass.

---
*Phase: 179-microcopy-information-architecture-sweep*
*Completed: 2026-06-19*
