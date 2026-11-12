---
phase: 250-brand-foundation-and-first-whole-investigation
plan: "06"
subsystem: ui
tags: [phoenix, liveview, timeline, playwright, responsive]
requires:
  - phase: 250-05
    provides:
      - Approved Admin brand assets and documentation foundation
provides:
  - All-blank Timeline searches keep an explicit existing `from=` marker so applied URLs reopen without a default date predicate.
  - Timeline pending, empty, unavailable, and long-filter states retain honest identity and usable responsive controls.
  - Shared `:no_data` copy matches the approved UI specification; loading and export state boundaries remain distinct.
affects: [250-07, 250-08]
actuals:
  tokens: null
  tasks: 2
  elapsed_seconds: 3440.957
  commits: 9
plan_head_before: 7895e790f250d3c3be0260219226583676cf564a
plan_head_after: a16e8fc25e642f4e2746423ae2e0d2aa40ea93dd
tech-stack:
  added: []
  patterns:
    - Keep explicit unconstrained query intent in Timeline's existing URL vocabulary without changing shared filter parsing.
    - Wrap unbroken status values at the narrow responsive boundary and pin intentional rendered CSS changes.
key-files:
  created: []
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/ui/data.ex
    - lib/threadline/operator_surface/style/09_responsive.css
    - test/fixtures/style/operator_surface.css
    - test/threadline/operator_surface/data_state_mapping_wave0_test.exs
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface/style_byte_lock_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
    - test/threadline/operator_surface/ui_test.exs
key-decisions:
  - "Use the existing empty `from=` parameter to preserve an all-blank applied query across URL reopen while a bare Timeline visit retains its 24-hour default."
  - "Use the UI-SPEC heading `No changes match these filters` for the shared typed `:no_data` state."
  - "Wrap long Timeline status text on mobile and update the reviewed stylesheet fixture and hash pins with the rendered CSS change."
requirements-completed: []
coverage:
  - id: D1
    description: Timeline preserves unconstrained applied URLs, pending versus committed identity, accurate empty results, complete long filter values, and narrow viewport access.
    verification:
      - kind: unit
        ref: "mix verify.test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/style_contract_test.exs"
        status: pass
      - kind: automated_ui
        ref: "Playwright desktop-chromium C21 retest: both existing Timeline cases, one result each, retries=0"
        status: pass
      - kind: other
        ref: "Read-only selected investigation pair materialization check after browser proof"
        status: pass
    human_judgment: false
  - id: D2
    description: Shared loading, no-data, unavailable, and export states retain their typed meaning and approved copy; the intentional responsive CSS change remains byte-locked.
    verification:
      - kind: unit
        ref: "mix verify.test test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/data_state_mapping_wave0_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/style_byte_lock_test.exs"
        status: pass
      - kind: other
        ref: "mix verify.format"
        status: pass
    human_judgment: false
duration: 57min
completed: 2026-11-12
status: complete
---

# Phase 250 Plan 06: Timeline query and responsive state summary

**Timeline applies and reopens unconstrained filters, keeps committed query identity during replacement, wraps long feedback on mobile, and uses the approved shared no-data copy.**

## Performance

- **Duration:** 3440.957 seconds of managed wall time, including source handoff/coordination waits; not active test runtime.
- **Started:** 2026-11-12T18:22:18.628299Z
- **Completed:** 2026-11-12T19:19:39.584843Z
- **Tasks:** 2.
- **Files modified:** 10.

## Accomplishments

- All-blank Timeline submissions preserve an explicit `from=` marker. Reopening the applied URL keeps the older matching row, blank date fields, and absent actor/correlation context; a bare fresh Timeline visit still gets its default 24-hour window.
- Existing Timeline tests and two existing Playwright cases prove pending versus committed query identity, unavailable versus empty results, accurate counts, complete filter values, transaction routing, and the 375px responsive boundary.
- The shared typed `:no_data` state now uses the approved “No changes match these filters” heading. Loading remains an accessible busy status, and accepted, pending, completed, and failed export states stay separate.
- The unknown-table status wraps long values at mobile widths. The stylesheet golden and both byte pins were updated through the existing procedure.

## Task Commits

1. **Task 1: Timeline query and responsive regressions** — `0f94cd85` (`test`).
2. **Task 1: Apply empty filters as an unconstrained query** — `417db0ef` (`feat`).
3. **Task 2: Shared loading-state assertions** — `9908f0d9` (`test`).
4. **Task 1: Reopen the all-blank applied URL** — `9d56aea5` (`test`).
5. **Task 1: Preserve unconstrained query identity across reopen** — `b6c518c7` (`feat`).
6. **Task 2: Approved no-data copy regression** — `8b4685d7` (`test`).
7. **Task 2: Align shared no-data copy** — `2730ffc5` (`feat`).
8. **Task 1: Mobile feedback wrapping contract** — `cb018561` (`test`).
9. **Task 1: Wrap long Timeline feedback and update CSS pins** — `a16e8fc2` (`fix`).

## Files Created/Modified

- `lib/threadline/operator_surface/live/timeline_live.ex` — preserves unconstrained query intent with the existing blank `from` parameter.
- `lib/threadline/operator_surface/ui/data.ex` — aligns typed no-data heading with the UI-SPEC.
- `lib/threadline/operator_surface/style/09_responsive.css` — wraps long status text on mobile.
- `test/threadline/operator_surface/live/timeline_live_test.exs` — covers blank query application and fresh URL reopen without invented metadata.
- `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` — strengthens the two existing Timeline pending, empty, and responsive cases.
- `test/threadline/operator_surface/ui_test.exs` and `test/threadline/operator_surface/data_state_mapping_wave0_test.exs` — pin accessible loading and approved typed no-data copy.
- `test/threadline/operator_surface/style_contract_test.exs` — pins mobile feedback wrapping.
- `test/fixtures/style/operator_surface.css` and `test/threadline/operator_surface/style_byte_lock_test.exs` — record and verify the intentional rendered CSS update.

## Decisions Made

- Use the existing `from=` parameter as the Timeline-local marker for an explicitly unconstrained search. Shared `FilterParams` behavior and other route contracts remain unchanged.
- Keep the typed renderer and export job vocabulary in their existing owners; no new state layer or backend event was needed.
- Update the CSS golden and pins because the responsive stylesheet's rendered bytes changed.

## Deviations from Plan

None — changes stayed within the plan's Timeline, UI.Data, responsive, and test owners.

## Issues Encountered

- An early focused test run exposed a test-only second navigation that restored the default date window. The test was corrected to render the current patch; the separate fresh-reopen regression then exposed the actual URL-intent gap.
- The first C21 browser attempt passed the populated pending case and failed the long-filter case because a 226-character unknown-table status value overflowed the 375px page. The failed report was preserved. The mobile alert now wraps the value, and the same two cases passed after the parent restarted the retained app at the committed source.
- Task 2 assertions found the shared `:no_data` heading differed from the approved UI-SPEC. The shared renderer and its two affected assertions were aligned, then the focused suite passed.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

Plan 06 is complete and Plan 07 is next. The parent-owned app served byte-matched Timeline, UI.Data, and responsive CSS from a checkout distinct from the test worktree; the selected investigation materialization matched after browser proof. Phase-wide requirements ADM-12, ADM-13, ADM-14, and ADM-16 remain pending parent acceptance.

---
*Phase: 250-brand-foundation-and-first-whole-investigation*
*Completed: 2026-11-12*

## Self-Check: PASSED

- All 10 modified source/test/style files and this summary exist.
- All 9 task commits are ancestors of the plan head recorded above.
