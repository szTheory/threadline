---
phase: 140-earned-new-flows
plan: "02"
subsystem: operator-surface
tags: [phoenix-liveview, home, earned-flows, row-history, timeline-filters, tdd]

requires:
  - phase: 140-earned-new-flows
    provides: "Plan 01 first-class `/audit/rows/:table/:record_id` row-history route"
provides:
  - "EF1 Home record-first lookup into first-class row history"
  - "EF4 Home correlation shortcut into canonical Timeline filtering"
  - "Scoped token-backed Home earned-flow styles and style contract coverage"
affects: [operator-surface, home, earned-flows, row-history, timeline]

tech-stack:
  added: []
  patterns:
    - "Home form navigation validates user-controlled route inputs before push_navigate"
    - "Correlation Home navigation uses FilterParams.canonical_query/1 instead of ad hoc query strings"
    - "Home earned-flow styles are scoped under `.tl-home__earned-flow` and token-backed"

key-files:
  created:
    - .planning/phases/140-earned-new-flows/140-02-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/start_live.ex
    - lib/threadline/operator_surface/style.ex
    - test/threadline/operator_surface/live/start_live_test.exs
    - test/threadline/operator_surface/style_contract_test.exs

key-decisions:
  - "Keep EF1 as a mapped table selector plus record-id input, not a Timeline filter form."
  - "Use direct LiveView event submission in one test to exercise tampered unmapped-table input that a browser select would not submit."
  - "Skip normal GSD STATE/ROADMAP mutation because the user explicitly prohibited those files for this plan."

patterns-established:
  - "Home earned flows carry `data-earned-flow`, `data-persona`, and `data-jtbd` trace attributes."
  - "Home route-building helpers encode record path segments and avoid untrusted atom creation by comparing schema keys as strings."

requirements-completed: [POLISH-FLOWS]

duration: 4m23s
completed: 2026-06-04T15:58:42Z
---

# Phase 140 Plan 02: Home Earned-Flow Shortcuts Summary

**Home now offers two cordoned earned shortcuts: mapped record-first row history and canonical correlation Timeline navigation.**

## Performance

- **Duration:** 4m23s
- **Started:** 2026-06-04T15:54:19Z
- **Completed:** 2026-06-04T15:58:42Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added EF1 record-first Home controls with `data-earned-flow="EF1"`, P2/J4 trace attributes, a mapped schema/table selector, and record id input.
- Added EF4 correlation Home controls with `data-earned-flow="EF4"`, P1/J1 trace attributes, trim/blank/256-byte validation, and Timeline navigation through `FilterParams.canonical_query/1`.
- Validated blank table, unmapped table, blank record id, blank correlation id, and overlong correlation id with plain-language alerts and no route crash.
- Preserved Phase 139 Home/nav baseline coverage in StartLive tests while replacing the old "no Phase 140 forms" source guard with positive earned-flow tests and negative speculative-flow guards.
- Added scoped `.tl-home__earned-flow` styles and a style contract that keeps the Home earned-flow block token-backed and dark-only.

## Task Commits

1. **Task 1: Add Home earned-flow LiveView contracts** - `3e9cd44` (`test`)
2. **Task 2: Implement Home record-first and correlation controls** - `11e2a09` (`feat`)

## Files Created/Modified

- `lib/threadline/operator_surface/live/start_live.ex` - Adds EF1/EF4 forms, validation, path-segment encoding, schema-map table checks, and canonical correlation navigation.
- `lib/threadline/operator_surface/style.ex` - Adds scoped token-backed Home earned-flow layout styles.
- `test/threadline/operator_surface/live/start_live_test.exs` - Adds earned-flow rendering, navigation, validation, Phase 139 baseline, and non-goal source guards.
- `test/threadline/operator_surface/style_contract_test.exs` - Adds scoped CSS contract coverage for Home earned-flow controls.
- `.planning/phases/140-earned-new-flows/140-02-SUMMARY.md` - Records completion, commits, and verification evidence.

## Verification Evidence

- `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/style_contract_test.exs`
  - Result: **22 tests, 0 failures**
- `rg -n "advanced|query_dsl|bulk_export|saved_search_builder" lib/threadline/operator_surface/live/start_live.ex test/threadline/operator_surface/live/start_live_test.exs`
  - Result: matches only negative guard assertions in `start_live_test.exs`.
- `rg -n "data-earned-flow=\"EF1\"|data-earned-flow=\"EF4\"|FilterParams\\.canonical_query|/rows/" lib/threadline/operator_surface/live/start_live.ex test/threadline/operator_surface/live/start_live_test.exs`
  - Result: EF1/EF4 trace attributes, row-history navigation, and `FilterParams.canonical_query/1` found in intended files.

## Decisions Made

- EF1 remains a narrow record-first shortcut: the operator can choose only configured schema-map tables and enter one record id.
- EF4 correlation navigation delegates query encoding to `FilterParams.canonical_query/1` so Home and saved-view Timeline links share canonical semantics.
- Record route segments are encoded before `push_navigate`, and table validity is checked against configured schema keys converted to strings without creating atoms.

## Deviations from Plan

### User-Directed Execution Adjustment

**1. Skipped normal STATE/ROADMAP updates**
- **Found during:** Plan execution setup
- **Reason:** User explicitly instructed: "Do not modify `.planning/STATE.md` or `ROADMAP.md`."
- **Impact:** This summary records completion and verification evidence, but executor state files were intentionally left untouched.

## TDD Gate Compliance

- RED gate commit present: `3e9cd44` (`test(140-02): add home earned-flow contracts`)
- GREEN gate commit present after RED: `11e2a09` (`feat(140-02): add home earned-flow shortcuts`)
- Note: unrelated concurrent Phase 140-04 commit `002ead7` appeared between the two 140-02 commits in shared git history; no 140-04 owned files were modified by this plan.

## Known Stubs

None. Blank values found by the stub scan are intentional validation branches or existing empty-state rendering.

## Threat Flags

None. The new Home form input trust boundaries were already covered by the plan threat model and mitigated through schema-map validation, byte limits, route segment encoding, and canonical query construction.

## Issues Encountered

- Phoenix LiveView's `form/3` test helper correctly rejected a tampered select value before the event reached StartLive. The unmapped-table test uses `render_submit(view, "open-row-history", ...)` to exercise the server-side validation branch directly.
- Concurrent unrelated work left modified `evidence_*` and `export_status_*` files in the worktree; they were not staged or committed for this plan.

## User Setup Required

None.

## Next Phase Readiness

- Home can now launch EF1 row history via `/audit/rows/:table/:record_id`.
- Home can now launch EF4 Timeline correlation filtering via `/audit/timeline?correlation_id=...`.
- Future flow additions should remain similarly cordoned and traceable instead of expanding Home into a general query builder.

## Self-Check

PASSED.

- Found `lib/threadline/operator_surface/live/start_live.ex`
- Found `lib/threadline/operator_surface/style.ex`
- Found `test/threadline/operator_surface/live/start_live_test.exs`
- Found `test/threadline/operator_surface/style_contract_test.exs`
- Found `.planning/phases/140-earned-new-flows/140-02-SUMMARY.md`
- Found task commits `3e9cd44` and `11e2a09`

---
*Phase: 140-earned-new-flows*
*Completed: 2026-06-04*
