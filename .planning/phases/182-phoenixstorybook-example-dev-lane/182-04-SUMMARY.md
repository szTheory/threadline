---
phase: 182-phoenixstorybook-example-dev-lane
plan: 04
subsystem: example-app
tags: [phoenix-storybook, storybook, playwright, operator-surface, stress-fixtures]

requires:
  - phase: 182-phoenixstorybook-example-dev-lane
    provides: Storybook wrapper, read-only fixtures, category spine, and core stories from 182-03
provides:
  - Curated Overlay and Data Display Storybook stories for the remaining component catalog
  - Recurring Groups and small Patterns Storybook stories backed by an explicit stress fixture allowlist
  - Bounded Playwright smoke coverage for the Storybook index and representative category stories
  - Light-lane Playwright inclusion for the Storybook smoke without adding a screenshot matrix
affects: [phase-182, storybook-dev-lane, operator-surface-docs, example-phoenix]

tech-stack:
  added: []
  patterns:
    - Source-contract Storybook coverage tests for each remaining story family
    - Explicit group sample allowlist around Threadline.OperatorSurface.StressFixtures
    - Bounded Storybook smoke using backend-discovered story paths and nested Threadline theme previews

key-files:
  created:
    - examples/threadline_phoenix/storybook/overlays/modal.story.exs
    - examples/threadline_phoenix/storybook/data_display/data_table.story.exs
    - examples/threadline_phoenix/storybook/groups/operator_groups.story.exs
    - examples/threadline_phoenix/storybook/patterns/operator_patterns.story.exs
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex
    - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts
    - examples/threadline_phoenix/e2e/playwright.config.ts

key-decisions:
  - "Storybook coverage remains curated component documentation; `/audit/__stress` remains the flow-level stress harness."
  - "Groups sample existing stress data only through an explicit helper allowlist instead of mirroring the ledger or full stress registry."
  - "The light/system Playwright lane includes Storybook only through `operator-storybook.spec.ts`, and the spec asserts the bounded config contract."
  - "Browser smoke uses backend-discovered underscore story paths and targets the nested `.threadline-ui[data-tl-theme]` preview."

patterns-established:
  - "TDD story source contracts are tightened before adding each Storybook story family."
  - "Storybook group fixtures expose named samples with stable `group.*.current` labels rather than generated navigation."
  - "Storybook E2E coverage validates rendered previews and viewport overflow without screenshots or external visual-regression services."

requirements-completed: [STORY-02, STORY-03]

duration: 18 min
completed: 2026-06-27
status: complete
---

# Phase 182 Plan 04: Remaining Storybook Coverage And Bounded Smoke Summary

**Overlay, data-display, recurring group, and small pattern Storybook coverage now renders through the Threadline wrapper with bounded browser smoke while `/audit/__stress` remains the flow stress harness.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-27T01:44:20Z
- **Completed:** 2026-06-27T02:02:12Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added Overlays and Data Display stories covering modal, drawer, toast, tooltip, popover, dropdown, accordion, tabs, segmented control, refs, key/value rows, data tables, panels, code blocks, detail headers, and toolbars.
- Added recurring Groups and small Patterns stories for toolbar/filter, detail-header/metadata, data-panel/state, inert destructive modal, offline/reconnect, and permission-denied assemblies.
- Extended the Storybook fixture helper with an explicit group sample allowlist and missing state samples required by rendered stories.
- Turned the bounded Storybook Playwright smoke green across configured Chromium projects without screenshots or external visual-regression services.
- Verified `mix verify.operator_stress` still passes, preserving `/audit/__stress` as the canonical flow-level stress harness.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add overlay and data-display stories** - `5529ddc2` (RED test), `518d22c6` (GREEN feature)
2. **Task 2: Add recurring group and pattern stories** - `ead95994` (RED test), `e9d3ffc3` (GREEN feature)
3. **Task 3: Turn bounded browser smoke green** - `7ec49c08` (RED test), `d0737256` (GREEN feature)

**Plan metadata:** recorded in the final `docs(182-04)` metadata commit.

## Files Created/Modified

- `examples/threadline_phoenix/storybook/overlays/modal.story.exs` - Overlay component examples, focus notes, keyboard expectations, and inert destructive modal coverage.
- `examples/threadline_phoenix/storybook/data_display/data_table.story.exs` - Data-display examples using representative ugly data for refs, tables, panels, code, metadata, and toolbar states.
- `examples/threadline_phoenix/storybook/groups/operator_groups.story.exs` - Recurring group examples with stable `group.*.current` labels and fixture provenance.
- `examples/threadline_phoenix/storybook/patterns/operator_patterns.story.exs` - Small pattern branch for recurring operator assemblies, without full page flows or stress footguns.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex` - Added group fixture allowlist and missing state story samples.
- `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs` - Added RED source contracts for remaining story families.
- `examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts` - Added bounded config contract and final representative story URLs/selectors.
- `examples/threadline_phoenix/e2e/playwright.config.ts` - Added bounded `operator-storybook.spec.ts` inclusion to the light-lane project.
- `.planning/phases/182-phoenixstorybook-example-dev-lane/deferred-items.md` - Recorded out-of-scope inherited precommit failures.

## Decisions Made

- Kept all new stories as curated Storybook documentation under `examples/threadline_phoenix`; no root dependency, production route, public component API, full page-flow matrix, or auth behavior moved into Storybook.
- Used explicit fixture IDs for recurring groups so future maintainers can trace examples back to `StressFixtures` without turning the stress registry or ledger into generated Storybook navigation.
- Made the Storybook browser smoke responsible for rendered component docs only: index, representative category stories, theme preview selector, and small viewport overflow checks.
- Kept `/audit/__stress` verification in `mix verify.operator_stress`, which continues to run the existing route semantics and ledger-owned checks.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Tightened RED contracts for remaining Storybook families**
- **Found during:** Tasks 1 and 2
- **Issue:** Existing story tests covered earlier categories and would not fail on missing Plan 04 story files.
- **Fix:** Added source-level contracts for Overlay/Data Display and Groups/Patterns before adding implementation stories.
- **Files modified:** `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs`
- **Verification:** RED runs failed on missing story files; GREEN runs passed after the stories were added.
- **Committed in:** `5529ddc2`, `ead95994`

**2. [Rule 2 - Missing Critical] Added explicit group sample allowlist**
- **Found during:** Task 2
- **Issue:** The fixture helper did not yet expose the explicit group samples required by the plan's recurring group stories.
- **Fix:** Added `group_story_ids/0` and `group_sample/1` backed by a small allowlist into `Threadline.OperatorSurface.StressFixtures`.
- **Files modified:** `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex`
- **Verification:** Storybook source tests and stress fixture/ledger tests passed.
- **Committed in:** `e9d3ffc3`

**3. [Rule 1 - Bug] Filled missing state story samples and corrected rendered-preview targeting**
- **Found during:** Task 3
- **Issue:** Browser smoke exposed missing `error` and `zero_count` state samples and matched the PhoenixStorybook sandbox wrapper instead of the nested Threadline preview.
- **Fix:** Added the missing state samples, updated Storybook paths to backend-discovered underscore routes, and targeted `.threadline-ui[data-tl-theme]`.
- **Files modified:** `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex`, `examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts`
- **Verification:** `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-storybook.spec.ts` passed 33 tests.
- **Committed in:** `d0737256`

---

**Total deviations:** 3 auto-fixed (2 Rule 2, 1 Rule 1).
**Impact on plan:** All deviations were required for the planned Storybook coverage and smoke test to be correct. No scope moved into production routes, public APIs, external services, or screenshot baselines.

## Issues Encountered

- `cd examples/threadline_phoenix && mix precommit` still fails on inherited demo seed/walkthrough evidence drift outside this plan. The failures are in `walkthrough_evidence_test.exs`, `walkthrough_happy_path_test.exs`, and `demo_contract_test.exs`; targeted Storybook and stress verification passes. The out-of-scope item is recorded in `deferred-items.md`.

## Verification

- `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_stories_test.exs` - PASS; 9 tests, 0 failures.
- `mix test test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs` - PASS; 23 tests, 0 failures.
- `cd examples/threadline_phoenix/e2e && npx playwright test --project=chromium tests/operator-storybook.spec.ts -g "light/system"` - PASS; 1 test, 0 failures.
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-storybook.spec.ts` - PASS; 33 tests, 0 failures.
- `mix verify.operator_stress` - PASS; 42 passed, 9 configured skips.
- `mix verify.compile_no_optional` - PASS.
- `rg -n "toHaveScreenshot|screenshot\\(|Percy|Chromatic|Applitools" examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts examples/threadline_phoenix/e2e/playwright.config.ts || true` - PASS; no screenshot or external visual-regression calls found.
- `cd examples/threadline_phoenix && mix precommit` - FAIL; inherited demo seed/walkthrough failures unrelated to Storybook.

## Known Stubs

None. Stub scan found no TODO/FIXME/placeholder text or hardcoded empty UI data in files created or modified by this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 182-05 closure: the required Storybook catalog is covered, the bounded browser smoke is green, and `/audit/__stress` remains separately verified as the flow stress harness.

## Self-Check: PASSED

- Created files exist: all four Plan 04 story files, Storybook smoke spec/config, summary, and deferred log.
- Task commits found: `5529ddc2`, `518d22c6`, `ead95994`, `e9d3ffc3`, `7ec49c08`, and `d0737256`.
- No accidental deletions or generated E2E output remain in the working tree.

---
*Phase: 182-phoenixstorybook-example-dev-lane*
*Completed: 2026-06-27*
