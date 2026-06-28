---
phase: 184-timeline-investigation-flow
plan: "02"
subsystem: ui
tags: [phoenix-liveview, operator-surface, timeline, copy-contracts, responsive-css]

requires:
  - phase: 184-timeline-investigation-flow
    provides: "Plan 01 row-first Timeline workflow, safe row-history pivots, canonical export handoff, and command filter placement."
provides:
  - "Timeline state lattice contracts for first-run, filtered, future-window, unknown-table, invalid-filter, export, large-result, and capped-result states."
  - "Full-value copy/title preservation for long Timeline table, actor, correlation, and routeable row refs."
  - "Timeline row/copy-control reflow source contracts for narrow viewports without new tokens, breakpoints, or decorative motion."
affects: [phase-184, timeline, operator-surface, phase-184-plan-03]

tech-stack:
  added: []
  patterns:
    - "TDD RED/GREEN execution with state/copy/style contracts committed before implementation."
    - "Timeline empty states resolve through an explicit private reason lattice: first_run, filtered, future_window."
    - "Long Timeline refs preserve full values through Presentation/UI.ref and data-tl-copy metadata."

key-files:
  created:
    - .planning/phases/184-timeline-investigation-flow/184-02-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/style.ex
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface/copy_contract_test.exs
    - test/threadline/operator_surface/style_contract_test.exs

key-decisions:
  - "Timeline empty states now distinguish first-run, filtered no-data, and future-window copy through private reason helpers instead of a single future-window boolean."
  - "Timeline rows expose full table, actor, correlation, and safe row-id values for copy/title use while preserving transaction and row-history pivots."
  - "No fake Timeline stale branch was added; stale/last-good proof remains with shared UI.stale_banner/data-state primitives because Timeline has no dedicated stale assign."
  - "Presentation and pager source did not need changes; existing helper and pager contracts already satisfied the new Plan 02 tests."

patterns-established:
  - "Use private Timeline reason helpers for state-specific copy instead of duplicating string branches in render markup."
  - "Add copy metadata at the row surface only when the value is operator-useful and already available in scoped Timeline data."
  - "Lock responsive behavior through source contracts on existing tl-* selectors before adding CSS."

requirements-completed: [TIME-02, TIME-03]

duration: 9 min
completed: 2026-06-28
status: complete
---

# Phase 184 Plan 02: Timeline Resilience Contracts and Retuning Summary

**Timeline ugly-data handling now distinguishes state meanings, preserves full long refs for copy, and keeps row/copy controls reflow-safe without new motion or token surface.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-06-28T22:32:59Z
- **Completed:** 2026-06-28T22:41:39Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added RED contracts for first-run versus filtered empty state copy, full-value Timeline ref copy, calm Timeline vocabulary, and narrow-width row/copy-control CSS.
- Retuned `TimelineLive` to use explicit private state-reason helpers for first-run, filtered, and future-window empty states.
- Added full-value `data-tl-copy`/`title` handling for long table refs plus copyable actor and routeable row refs, while keeping existing correlation, transaction, and row-history pivots.
- Added minimal CSS source rules for `.tl-change__summary`, `.tl-change__actions`, `.tl-ref`, `.tl-copy`, and `.tl-timeline-drawer` so narrow viewports reflow at the component level.

## Task Commits

Each task was committed atomically:

1. **Task 1: Lock Timeline state, copy, long-value, and motion contracts** - `71ea577a` (test / RED)
2. **Task 2: Retune Timeline states, responsive layout, copy, and motion** - `e42f250f` (feat / GREEN)

**Plan metadata:** recorded in the final `docs(184-02)` metadata commit.

## Files Created/Modified

- `lib/threadline/operator_surface/live/timeline_live.ex` - Adds private empty-state reason helpers, first-run copy, table copy metadata, actor copy refs, row-id copy refs, and keeps safe row-history gating intact.
- `lib/threadline/operator_surface/style.ex` - Adds narrow-width stability rules for Timeline row summaries/actions, refs, copy controls, and drawer content.
- `test/threadline/operator_surface/live/timeline_live_test.exs` - Locks distinct state copy and long table/actor/correlation/row full-value copy behavior.
- `test/threadline/operator_surface/copy_contract_test.exs` - Locks primary Timeline copy against incident-pressure vocabulary footguns.
- `test/threadline/operator_surface/style_contract_test.exs` - Locks Timeline row/copy-control reflow source contracts.

## Verification

- `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/pager_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` - **RED before implementation:** 137 tests, 3 expected failures for first-run state copy, full-value table/actor/row copy, and Timeline reflow CSS.
- `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/pager_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` - **PASS after implementation:** 137 tests, 0 failures.
- `mix format --check-formatted lib/threadline/operator_surface/live/timeline_live.ex lib/threadline/operator_surface/presentation.ex lib/threadline/operator_surface/style.ex test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/pager_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` - **PASS**.
- Source checks confirmed exact state/export copy anchors, full-value copy attributes, no Timeline `transition: all`, no Timeline row animation source additions, and no root/TL overflow-hiding workaround.

Full `mix verify.test` was not rerun for this plan because the orchestrator already classified inherited full-suite residuals in Coverage and the stale v1.23 planning-doc contract as outside 184-02 scope.

## Decisions Made

- Split Timeline empty copy by reason (`first_run`, `filtered`, `future_window`) so first-run no-data and filtered no-data no longer share the same heading.
- Kept direct row-history safety unchanged: row-id copy appears only when the existing routeable-row identity helper can prove a single nonblank scalar primary key.
- Used existing `UI.ref/1` and `Presentation.secondary_ref/2` patterns rather than adding a new component family.
- Did not fabricate a Timeline stale/last-good branch; shared `UI.stale_banner/1` remains the proof source unless Timeline later renders a real stale state.

## Deviations from Plan

None - plan executed within the declared Timeline files and constraints. `Presentation` and pager implementation changes were unnecessary because existing helpers and tests already satisfied the new contracts.

## Issues Encountered

- The first copy-contract draft expected row-action copy while rendering an empty Timeline. This was corrected before the RED commit by seeding one scoped row in the test setup.

## Known Stubs

None. Stub-pattern scan found only intentional test literals, guard assertions, and existing input placeholder attributes; no unwired UI/data stub was introduced.

## Threat Flags

None. The plan changed no route, auth path, schema, file access, dependency, or export controller boundary. Long-ref copy handling was explicitly covered by the plan threat model and remains HEEx-rendered through existing primitives.

## Auth Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 184-03. Timeline now has source and LiveView proof for the state/copy/motion lattice, so the next plan can focus on bounded browser proof without touching Coverage cleanup or stale planning-doc residuals.

## Self-Check: PASSED

- Found summary: `.planning/phases/184-timeline-investigation-flow/184-02-SUMMARY.md`
- Found modified source files: `lib/threadline/operator_surface/live/timeline_live.ex` and `lib/threadline/operator_surface/style.ex`
- Found modified test files: `timeline_live_test.exs`, `copy_contract_test.exs`, and `style_contract_test.exs`
- Found task commits: `71ea577a` and `e42f250f`
- No tracked file deletions were introduced by task commits.

---
*Phase: 184-timeline-investigation-flow*
*Completed: 2026-06-28*
