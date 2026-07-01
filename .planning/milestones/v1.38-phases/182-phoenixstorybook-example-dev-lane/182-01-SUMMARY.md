---
phase: 182-phoenixstorybook-example-dev-lane
plan: 01
subsystem: testing
tags: [phoenix-storybook, exunit, playwright, operator-surface, docs-contract]

requires:
  - phase: 181-baseline-audit-and-guard-repair
    provides: baseline operator-surface guardrails and stress-route contract context
provides:
  - RED root boundary contracts preventing PhoenixStorybook leakage into root package/source
  - RED example-app route and story contracts for the maintainer Storybook lane
  - Bounded Playwright Storybook smoke scaffold for representative category previews
affects: [phase-182, storybook-dev-lane, operator-surface-docs, example-phoenix]

tech-stack:
  added: []
  patterns:
    - Source-contract ExUnit tests for root optional-dependency boundaries
    - Example-app route/story RED contracts before PhoenixStorybook implementation
    - Bounded Playwright discovery-only scaffold for future Storybook smoke

key-files:
  created:
    - test/threadline/operator_surface/storybook_boundary_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_route_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts
  modified:
    - test/threadline/example_phoenix_readme_contract_test.exs
    - test/threadline/operator_surface_doc_contract_test.exs

key-decisions:
  - "Plan 182-01 is RED-only by design: it locks executable contracts before package, route, story, or documentation implementation."
  - "Storybook browser coverage stays bounded to index plus representative primitive/form/state/overlay/data-display/group stories; no screenshot matrix or external visual regression service was added."
  - "Root optional-dependency hygiene remains protected by source contracts and `mix verify.compile_no_optional`."

patterns-established:
  - "Root Storybook boundary test scans root package files and root `lib/threadline` source while allowing future Storybook terms only under `examples/threadline_phoenix`."
  - "Example-app story contracts can fail before PhoenixStorybook is installed because they inspect source files and expected story taxonomy without importing PhoenixStorybook modules."
  - "Storybook Playwright smoke uses shared `expectThreadlinePreview` and `expectNoHorizontalOverflow` helpers without screenshot assertions."

requirements-completed: [STORY-01, STORY-02, STORY-03]

duration: 7 min
completed: 2026-06-27
status: complete
---

# Phase 182 Plan 01: PhoenixStorybook RED Contracts Summary

**Executable RED contracts now lock the example-only PhoenixStorybook lane, root dependency boundary, docs posture, story taxonomy, theme wrapper, ugly-data coverage, and bounded browser smoke before implementation starts.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-27T01:02:16Z
- **Completed:** 2026-06-27T01:08:51Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added root source/package absence checks proving PhoenixStorybook terms stay out of root `mix.exs`, `mix.lock`, public router macro source, and root `lib/threadline` source.
- Extended docs contract tests with RED expectations for the Storybook-vs-`/audit/__stress` distinction and adopter install guidance.
- Added example-app RED route and story contracts for `/dev/storybook`, assets, production absence, backend/wrapper source, category spine, Threadline theme wrapper, ugly-data vocabulary, and UI-SPEC primitive/form coverage.
- Added bounded Playwright smoke scaffold for Storybook index and representative category stories, including `.threadline-ui`, `data-tl-theme`, visible preview content, and no horizontal overflow.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add root boundary and docs RED contracts** - `75fb204e` (test)
2. **Task 2: Add example route and story RED contracts** - `8cec8ca3` (test)
3. **Task 3: Add bounded Storybook browser smoke scaffold** - `9e3c4356` (test)

**Plan metadata:** recorded in the final `docs(182-01)` metadata commit.

## Files Created/Modified

- `test/threadline/operator_surface/storybook_boundary_test.exs` - root package/source boundary contracts for Storybook absence and example-app-only allowance.
- `test/threadline/example_phoenix_readme_contract_test.exs` - RED docs posture assertions for example README maintainer Storybook guidance.
- `test/threadline/operator_surface_doc_contract_test.exs` - RED operator guide assertions keeping Storybook out of adopter install guidance.
- `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_route_test.exs` - RED route/source contracts for `/dev/storybook`, assets, dev-route gating, and production absence.
- `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs` - RED story backend, wrapper, category, fixture, and UI-SPEC coverage contracts.
- `examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts` - bounded Playwright scaffold for future Storybook browser smoke.

## Decisions Made

- Plan 01 intentionally stops at RED contracts. Later Phase 182 plans own PhoenixStorybook dependency installation, route/backend/story implementation, and documentation updates.
- Browser smoke is source-discoverable now (`--list` passes) but not executed against a running Storybook route in this plan because the route is intentionally absent.
- The root boundary test scans generated/locked root package surfaces but excludes tests and planning artifacts so future Storybook terms in RED contracts do not create false positives.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope expansion; all changes are RED contracts or browser scaffold files specified by the plan.

## Issues Encountered

None. The expected RED failures are the deliverable for this plan:

- Root/docs command: 24 tests run, 2 expected failures for missing Storybook-vs-stress docs wording.
- Example route/story command: 9 tests run, 7 expected failures for missing `/dev/storybook` route, backend, wrapper, and story files.

## Verification

- `bash -lc 'set +e; mix test test/threadline/operator_surface/storybook_boundary_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs; status=$?; test "$status" -ne 0'` - PASS; inner run failed as expected with 24 tests, 2 docs-contract failures.
- `bash -lc 'set +e; cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_route_test.exs test/threadline_phoenix_web/storybook_stories_test.exs; status=$?; test "$status" -ne 0'` - PASS; inner run failed as expected with 9 tests, 7 missing-route/backend/story failures.
- `cd examples/threadline_phoenix/e2e && npx playwright test --list tests/operator-storybook.spec.ts` - PASS; 30 tests listed across chromium, desktop-chromium, and mobile-chromium projects.
- `test -s examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts` - PASS.
- `mix verify.compile_no_optional` - PASS.

## Known Stubs

None. Stub scan found only an intentional test assertion (`assert paths != []`) used to make missing Storybook story files fail the RED contract.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 182-02 to add the example-app PhoenixStorybook dependency, backend, and `/dev/storybook` route while satisfying the RED contracts from this plan.

## Self-Check: PASSED

- Created files exist: `storybook_boundary_test.exs`, `storybook_route_test.exs`, `storybook_stories_test.exs`, `operator-storybook.spec.ts`, and `182-01-SUMMARY.md`.
- Task commits found: `75fb204e`, `8cec8ca3`, `9e3c4356`.
- No missing files or missing task commits found.

---
*Phase: 182-phoenixstorybook-example-dev-lane*
*Completed: 2026-06-27*
