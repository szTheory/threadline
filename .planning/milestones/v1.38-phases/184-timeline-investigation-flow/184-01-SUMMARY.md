---
phase: 184-timeline-investigation-flow
plan: "01"
subsystem: ui
tags: [phoenix-liveview, operator-surface, timeline, row-history, exports]

requires:
  - phase: 180-operator-surface-audit-coverage
    provides: "Timeline, row history, transaction, and export operator routes used by the investigation flow."
  - phase: 184-timeline-investigation-flow
    provides: "Phase 184 context, research, patterns, and UI contract for Timeline-first investigations."
provides:
  - "Timeline row-first investigation workflow with direct safe row-history pivots."
  - "Source and behavior contracts for Timeline filter placement, canonical export handoff, and row pivot safety."
  - "Canonical CSV/JSON/NDJSON export query preservation from Timeline through ExportController."
affects: [phase-184, timeline, row-history, operator-exports, investigation-flow]

tech-stack:
  added: []
  patterns:
    - "TDD source contracts before LiveView workflow retuning."
    - "Routeable row-history links require exactly one nonblank scalar primary key."
    - "Timeline export links share FilterParams.canonical_query/1 with ExportController filtering."

key-files:
  created:
    - .planning/phases/184-timeline-investigation-flow/184-01-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/style.ex
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface/timeline_browse_doc_contract_test.exs
    - test/threadline/operator_surface/exports/filter_params_test.exs
    - test/threadline/operator_surface/controllers/export_controller_test.exs

key-decisions:
  - "Timeline row-history links are emitted only for rows with exactly one nonblank scalar primary-key value; unsafe identities keep the transaction pivot only."
  - "Timeline export handoff remains canonical-query driven through FilterParams and ExportController rather than duplicating filter semantics in the UI."
  - "The Timeline command surface reports result facts once through the facts/filter summary; duplicate status copy and its dead selector were removed."

patterns-established:
  - "Source contract tests lock route paths, data-testid additions, export filter ordering, and safety helper names before implementation."
  - "UI pivots to sensitive row routes should be additive and absent-by-default when identity safety cannot be proven."
  - "Timeline workflow verification pairs rendered LiveView behavior with direct controller boundary tests for export handoff."

requirements-completed: [TIME-01]

duration: 10 min
completed: 2026-06-28
status: complete
---

# Phase 184 Plan 01: Timeline Workflow Source Contracts and Handoff Summary

**Timeline-first audit investigation now exposes safe row-history pivots, canonical export handoff links, and locked source contracts for filter placement and row identity safety.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-06-28T22:14:31Z
- **Completed:** 2026-06-28T22:24:26Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added RED contracts for Timeline starter filters, drawer-only advanced filters, canonical export query ordering, row-history link safety, and removal of duplicate command status copy.
- Added direct `timeline-row-history-link` pivots for routeable Timeline rows while preserving the transaction pivot as the safe default for unsafe row identities.
- Kept Timeline export handoff canonical across Carry to Exports, CSV, JSON, NDJSON, and direct `ExportController` filtering.
- Removed the duplicate Timeline command status copy so result facts are presented once through the command facts and active filter summary.

## Task Commits

Each task was committed atomically:

1. **Task 1: Lock Timeline workflow source contracts** - `6e23e616` (test / RED)
2. **Task 2: Implement row-first command, pivots, and handoff** - `60858ff6` (feat / GREEN)

**Plan metadata:** recorded in the final `docs(184-01)` metadata commit.

## Files Created/Modified

- `lib/threadline/operator_surface/live/timeline_live.ex` - Adds safe row-history path helpers, routeable row identity gating, direct row-history links, export action ordering, and duplicate status removal.
- `lib/threadline/operator_surface/style.ex` - Removes the dead Timeline command status selector so the removed status class is absent from rendered pages.
- `test/threadline/operator_surface/live/timeline_live_test.exs` - Locks rendered Timeline row pivots, unsafe identity behavior, canonical export links, and single-source command facts.
- `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` - Locks source contracts for starter filters, drawer advanced filters, row-history helper names, and route path stability.
- `test/threadline/operator_surface/exports/filter_params_test.exs` - Locks canonical Timeline export query order and anonymous actor-id normalization.
- `test/threadline/operator_surface/controllers/export_controller_test.exs` - Verifies CSV/JSON/NDJSON controller exports honor the canonical Timeline filter query.

## Verification

- `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs` - **RED before implementation:** 89 tests, 3 expected failures for missing helper/link and duplicate status copy.
- `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs` - **PASS after implementation:** 89 tests, 0 failures.
- `mix format --check-formatted lib/threadline/operator_surface/live/timeline_live.ex lib/threadline/operator_surface/style.ex test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs` - **PASS**.

## Decisions Made

- Kept row-history pivots absent unless Timeline can derive exactly one nonblank scalar PK from the row, because composite, nested, blank, or nil identities are safer through the transaction view.
- Preserved `FilterParams.canonical_query/1` and `ExportController` as the export filter source of truth, with the LiveView only carrying canonical query strings to existing endpoints.
- Removed command status duplication instead of restyling it, keeping result count and window information in the existing command facts/filter summary.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed dead Timeline command status selector**
- **Found during:** Task 2 (Implement row-first command, pivots, and handoff)
- **Issue:** The duplicate status markup was removed from `TimelineLive`, but the inline stylesheet still shipped `.tl-timeline-command__status`, causing the literal removal contract to fail in rendered HTML.
- **Fix:** Removed the unused selector from `Threadline.OperatorSurface.Style`.
- **Files modified:** `lib/threadline/operator_surface/style.ex`
- **Verification:** Targeted Timeline/export suite passed with 89 tests, 0 failures; format check passed.
- **Committed in:** `60858ff6`

---

**Total deviations:** 1 auto-fixed (Rule 1: 1).
**Impact on plan:** The fix removed dead styling for markup intentionally deleted by the plan. No route, auth, parser, schema, dependency, or export boundary changed.

## Issues Encountered

- The first GREEN test run failed only because the removed status class remained in the inline stylesheet. Removing the dead selector resolved the contract without changing UI behavior.

## Known Stubs

None. Stub-pattern scan found only intentional input placeholder attributes and existing test assertions for unavailable export downloads; no unwired UI/data stub was introduced.

## Threat Flags

None. The new row-history pivot was explicitly in the plan threat model and is gated to routeable scalar primary keys; no unplanned endpoint, auth path, file access pattern, schema change, dependency, or trust-boundary surface was introduced.

## Auth Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 184-02. Timeline has locked source and behavior contracts for row-first browsing, safe row-history pivots, canonical export handoff, and stable command filter placement.

## Self-Check: PASSED

- Found summary: `.planning/phases/184-timeline-investigation-flow/184-01-SUMMARY.md`
- Found modified source files: `lib/threadline/operator_surface/live/timeline_live.ex` and `lib/threadline/operator_surface/style.ex`
- Found modified test files: `timeline_live_test.exs`, `timeline_browse_doc_contract_test.exs`, `filter_params_test.exs`, and `export_controller_test.exs`
- Found task commits: `6e23e616` and `60858ff6`
- No tracked file deletions were introduced by task commits.

---
*Phase: 184-timeline-investigation-flow*
*Completed: 2026-06-28*
