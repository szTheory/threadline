---
phase: 201-rendered-output
plan: 03
subsystem: operator-surface
tags: [liveview, playwright, rendered-output, semantic-selectors, tdd]
requires:
  - phase: 201-rendered-output
    plan: 01
    provides: seven-node structural receipts and immutable mechanical reference corpus
  - phase: 201-rendered-output
    plan: 02
    provides: migrate-before-delete semantic selector pattern for provenance cleanup
provides:
  - provenance-free Timeline and Evidence export context nodes
  - provenance-free Evidence carry-to-Exports handoff
  - behavior-first ExUnit and desktop/mobile Playwright consumers for the three nodes
affects: [201-04, 201-05, rendered-output, operator-surface]
actuals:
  tokens: 2932
  tasks: 1
  commits: 2
plan_head_before: 4485498622ab7a567eb1e5aa129c8e587f688a74
tech-stack:
  added: []
  patterns: [semantic selector migration before deletion, negative provenance contract, tracer re-verification]
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/export_status_live.ex
    - test/threadline/operator_surface/live/export_status_live_test.exs
    - lib/threadline/operator_surface/live/evidence_live.ex
    - test/threadline/operator_surface/live/evidence_live_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts
key-decisions:
  - "Existing export-context task IDs and the accessible Carry to Exports link express the complete behavior contract without replacement provenance metadata."
  - "The shared earned-flow browser journey uses roles, visible names, routes, and existing product test IDs for both this cohort and the later Row History/Timeline cohort."
patterns-established:
  - "Move every direct consumer to product semantics and prove an intentional negative provenance assertion before deleting a rendered taxonomy triple."
requirements-completed: [RENDER-01, RENDER-02, RENDER-06]
coverage:
  - id: D1
    description: "Timeline and Evidence export contexts remain distinct and navigable while carrying no planning-provenance attributes."
    requirement: RENDER-02
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/live/export_status_live_test.exs (27 tests within the combined 40-test run)"
        status: pass
      - kind: automated_ui
        ref: "operator-earned-flows.spec.ts desktop/mobile Timeline and Evidence carry cases"
        status: pass
    human_judgment: false
  - id: D2
    description: "Evidence carry-to-Exports preserves its authenticated route, canonical query handoff, and accessible action without replacement metadata."
    requirement: RENDER-06
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/live/evidence_live_test.exs (13 tests within the combined 40-test run)"
        status: pass
      - kind: automated_ui
        ref: "mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-earned-flows.spec.ts (10 tests)"
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-09-13
status: complete
---

# Phase 201 Plan 03: Exports and Evidence Provenance Cleanup Summary

**Three Exports/Evidence handoff nodes are free of nine planning attributes while semantic LiveView and desktop/mobile browser journeys preserve their copy, structure, navigation, and authorization behavior.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-09-13T20:20:08Z
- **Completed:** 2026-09-13T20:26:48Z
- **Tasks:** 1
- **Files modified:** 5

## Accomplishments

- Migrated both export-context ExUnit contracts and the Evidence handoff contract to `Phoenix.LiveViewTest` semantic selectors before production deletion.
- Removed exactly the EF3/P3/J6 triple from the Timeline export context, Evidence export context, and Evidence carry action: nine deletions, zero additions.
- Removed all EF2/EF3 selectors and helper abstractions from the shared Playwright journey while preserving Row History, Timeline, Evidence, and Exports behavior on desktop and mobile.

## Task Commits

1. **RED: Add failing Exports and Evidence provenance contract** — `40a76e99` (test)
2. **GREEN: Remove the nine Exports and Evidence provenance attributes** — `d31a72bc` (feat)

## Files Modified

- `lib/threadline/operator_surface/live/export_status_live.ex` — removed only the two three-attribute provenance triples from the existing task-identified context sections.
- `test/threadline/operator_surface/live/export_status_live_test.exs` — proves distinct Timeline/Evidence contexts, actions, filters, and absence of all three planning attributes through LiveViewTest selectors.
- `lib/threadline/operator_surface/live/evidence_live.ex` — removed only the three provenance attributes from the existing accessible carry link.
- `test/threadline/operator_surface/live/evidence_live_test.exs` — proves the carry action and canonical destination while rejecting all three planning attributes.
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` — uses roles, names, routes, visible outcomes, and existing task IDs instead of EF2/EF3 metadata.

## Decisions Made

- Reused `timeline-export-context`, `evidence-export-context`, and the accessible `Carry to Exports` link; no new DOM hook or parallel taxonomy was necessary.
- Migrated Row History and Timeline uses in the shared browser spec in the RED commit so Plan 201-04 is not coupled to metadata that its production cohort will delete.
- Kept the GREEN implementation as the final nine-line deletion; no refactor commit was justified.

## TDD Gate Compliance

- **RED:** `40a76e99` contains only test-consumer changes. The named LiveView test first proved the Timeline context and queue button were present, then failed because `data-earned-flow` remained on the context node. `/tmp/threadline-201-03-task1-red-evidence.json` returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **GREEN:** `d31a72bc` contains exactly nine production deletions and no additions. The focused combined LiveView suite then passed 40 tests with 0 failures.
- **REFACTOR:** Not needed; the minimal GREEN deletion is the intended final source shape and introduces no duplication or abstraction.

## Verification

- `mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs` — 40 tests, 0 failures.
- `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-earned-flows.spec.ts` — 19 unit preflight tests and 10 browser tests passed.
- `mix test test/threadline/operator_surface/rendered_output_contract_test.exs` — 6 tests, 0 failures; all structural receipts remain stable.
- `mix verify.mechanical` — 28 tests, 0 failures against the unchanged reference corpus.
- `examples/threadline_phoenix: mix precommit` — 114 tests, 0 failures.
- `npm --prefix examples/threadline_phoenix/e2e run typecheck` — TypeScript check passed.
- Exact production diff — 9 deletions and 0 additions; no provenance attribute remains in the two owned LiveViews.

## Deviations from Plan

None - the production and consumer changes match the plan exactly.

## Issues Encountered

- The plan's literal raw Playwright command ran without the repository wrapper and therefore had no base URL or authenticated example server; all five cases stopped at `page.goto` before a product assertion. The canonical `mix verify.example_browser` wrapper supplied the locked DB seed, server lifecycle, and desktop/mobile projects, and all 10 browser cases passed twice, including the tracer re-run.
- The unsuccessful raw Playwright diagnostic created a root `test-results/` directory; it was moved intact to `/tmp/threadline-201-03-root-test-results` rather than deleted.
- The browser wrapper reported an expired optional Hex user session while resolving unchanged public dependencies. Resolution, compilation, unit tests, and browser tests completed without private resources.

## Known Stubs

None. The five modified source/test files add no placeholder, TODO, FIXME, skipped test, mock-only data source, or unwired UI state.

## Threat Flags

None. This plan removes inert non-visual attributes and changes test selectors; it adds no endpoint, authorization path, file access behavior, schema, dependency, or runtime trust boundary. Existing Auth/Coverage hooks pass the authenticated browser journey.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 201-04 can delete the final Row History and Timeline provenance triples because their shared browser consumers are already semantic.
- The baseline structural receipts and immutable mechanical corpus remain green with no fixture, scorecard, snapshot, capture, or critic changes.
- No blockers remain.

## Self-Check: PASSED

- All five implementation/test files and this summary exist.
- RED commit `40a76e99` and GREEN commit `d31a72bc` exist after the recorded `plan_head_before`; the measured task-commit count is 2.
- The production commit contains exactly nine deletions and zero additions across the two LiveViews.
- No fixture, scorecard, or PNG baseline moved, and the shared browser consumer contains no EF2/EF3 or provenance selector.

---
*Phase: 201-rendered-output*
*Completed: 2026-09-13*
