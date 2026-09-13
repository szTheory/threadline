---
phase: 201-rendered-output
plan: 02
subsystem: operator-surface
tags: [liveview, playwright, rendered-output, semantic-selectors, tdd]
requires:
  - phase: 201-rendered-output
    plan: 01
    provides: seven-node structural receipts and behavior-first browser baseline
provides:
  - provenance-free Start record and correlation lookup nodes
  - Start ExUnit and Playwright consumers anchored to operator-visible semantics
  - focused RED-to-GREEN proof for the six-attribute deletion
affects: [201-03, 201-04, 201-05, rendered-output, operator-surface]
actuals:
  tokens: 2147
  tasks: 1
  commits: 2
plan_head_before: 4ac77f68da5587fc10c7cdcf6e4ab9799bf8a5fd
tech-stack:
  added: []
  patterns: [semantic selector migration before deletion, negative provenance contract, structure-receipt preservation]
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/start_live.ex
    - test/threadline/operator_surface/live/start_live_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
key-decisions:
  - "Start browser consumers use existing forms, accessible labels, roles, and visible outcomes; no replacement test IDs or provenance hooks were added."
  - "The focused ExUnit contract rejects all three planning attributes only after proving both lookup controls remain present and operable."
patterns-established:
  - "Migrate direct consumers to product semantics and prove them against the old DOM before deleting non-visual provenance."
requirements-completed: [RENDER-01, RENDER-02, RENDER-06]
coverage:
  - id: D1
    description: "Start record and correlation lookup panels emit none of the three planning-provenance attributes."
    requirement: RENDER-02
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/live/start_live_test.exs (21 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Record lookup, correlation lookup, Home navigation, and responsive behavior remain intact on desktop and mobile."
    requirement: RENDER-06
    verification:
      - kind: automated_ui
        ref: "mix verify.example_browser for the three Start-coupled specs (42 tests)"
        status: pass
      - kind: integration
        ref: "examples/threadline_phoenix mix precommit (114 tests)"
        status: pass
    human_judgment: false
duration: 11min
completed: 2026-09-13
status: complete
---

# Phase 201 Plan 02: Start Provenance Cleanup Summary

**The Start page's record and correlation lookup panels are provenance-free, while every direct consumer now proves the same operator behavior through existing accessible semantics.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-09-13T20:05:53Z
- **Completed:** 2026-09-13T20:16:00Z
- **Tasks:** 1
- **Files modified:** 5 logical files

## Accomplishments

- Migrated one ExUnit and three Playwright consumers away from the Start page's EF1/P2/J4 and EF4/P1/J1 provenance triples before production deletion.
- Deleted exactly six attributes from exactly two Start panels, without changing copy, classes, hierarchy, routes, events, Auth/Coverage hooks, or responsive behavior.
- Preserved all six rendered-output structural receipts and passed the complete affected desktop/mobile browser matrix plus the example application's precommit suite.

## Task Commits

1. **RED: Add failing Start provenance contract and semantic consumers** — `8500271b` (test)
2. **GREEN: Remove the six Start provenance attributes** — `70c2220a` (feat)

## Files Modified

- `lib/threadline/operator_surface/live/start_live.ex` — removed only the two fixed three-attribute provenance triples.
- `test/threadline/operator_surface/live/start_live_test.exs` — asserts both lookup controls through forms, labels, buttons, and destinations, then rejects planning attributes.
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` — exercises record and correlation outcomes through semantic controls rather than EF1/EF4 selectors.
- `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts` — removes redundant Start provenance locators while retaining semantic form coverage.
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` — proves both Start lookup panels through labeled controls across the responsive matrix.

## Decisions Made

- Reused existing form IDs, accessible labels, roles, and visible outcomes instead of introducing a new testing hook.
- Kept the three attribute names only in the focused negative ExUnit contract, never as a locator or positive dependency.
- Left EF2 and EF3 coverage untouched because those provenance owners belong to later plan cohorts.

## TDD Gate Compliance

- **RED:** `8500271b` contains tests only. The focused target failed on the still-rendered `data-earned-flow` attribute after its semantic presence assertions passed. The runtime evidence checker returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **GREEN:** `70c2220a` deletes exactly six production attribute lines. The focused Start suite then passed 21 tests with 0 failures.
- **REFACTOR:** Not needed; the minimal GREEN change was already the final six-line deletion and no source restructuring was justified.

## Verification

- `mix test test/threadline/operator_surface/live/start_live_test.exs` — 21 tests, 0 failures.
- `mix test test/threadline/operator_surface/rendered_output_contract_test.exs` — 6 tests, 0 failures; all baseline structural receipts remain stable.
- `mix verify.mechanical` — 28 tests, 0 failures.
- `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-earned-flows.spec.ts operator-home-nav-mobile.spec.ts operator-responsive-mobile-first.spec.ts` — 42 tests passed.
- `examples/threadline_phoenix: mix precommit` — 114 tests, 0 failures.
- Exact source diff — 6 deletions and 0 additions in `start_live.ex`; no replacement metadata, EF1 selector, or EF4 selector remains.

## Deviations from Plan

None - the production and consumer changes match the plan exactly.

## Issues Encountered

- The plan's raw `npm --prefix ... exec playwright` command does not start the authenticated example server and resolves its relative test paths from the wrong working directory. The repository's canonical `mix verify.example_browser` wrapper supplied the intended locked setup, database seed, server lifecycle, browser projects, and exact three specs; all 42 cases passed twice (before deletion and at the tracer gate).
- The browser wrapper reported an expired optional Hex user session while resolving unchanged public dependencies. Resolution, compilation, unit tests, and browser tests completed successfully without private resources.
- The unsuccessful raw Playwright diagnostic created a root `test-results/` directory; it was moved intact to `/tmp/threadline-201-02-root-test-results` rather than deleted.

## Known Stubs

None. The five modified implementation/test files contain no new placeholder, TODO, FIXME, skipped test, mock-only data source, or unwired UI state.

## Threat Flags

None. This plan removes inert non-visual attributes and changes test selectors; it adds no endpoint, authorization path, file access behavior, schema, dependency, or runtime trust boundary. Existing Auth/Coverage hooks remain unchanged and pass authenticated browser coverage.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 201-03 and 201-04 can apply the same migrate-before-delete pattern to their independently owned provenance cohorts.
- RENDER-02 remains phase-level pending until the later cohorts remove the remaining 15 inventoried attributes.
- No blockers remain.

## Self-Check: PASSED

- All five logical implementation/test files and this summary exist.
- RED commit `8500271b` and GREEN commit `70c2220a` exist after the recorded `plan_head_before`; the measured task-commit count is 2.
- Focused ExUnit, structural receipts, mechanical checks, desktop/mobile browser coverage, and example precommit verification all passed after the production deletion.
- Stub and threat-surface scans found no unresolved placeholder or new runtime security boundary.

---
*Phase: 201-rendered-output*
*Completed: 2026-09-13*
