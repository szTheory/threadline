---
phase: 182-phoenixstorybook-example-dev-lane
plan: 02
subsystem: example-app
tags: [phoenix-storybook, phoenix, dev-routes, optional-dependency, storybook]

requires:
  - phase: 182-phoenixstorybook-example-dev-lane
    provides: RED Storybook boundary and route contracts from 182-01
provides:
  - Example-app-only PhoenixStorybook dependency locked at 1.2.0
  - Prod-safe ThreadlinePhoenixWeb.Storybook backend module
  - /dev/storybook and /dev/storybook/assets route mount behind example dev_routes
  - Root package/source boundary proof for no PhoenixStorybook leakage
affects: [phase-182, example-phoenix, storybook-dev-lane, optional-dependency-boundary]

tech-stack:
  added: [phoenix_storybook 1.2.0]
  patterns:
    - Example-app dev/test dependency boundary
    - Root-scope PhoenixStorybook route mount under /dev/storybook
    - No-op compile stub for prod when a dev/test-only route macro dependency is absent

key-files:
  created:
    - examples/threadline_phoenix/lib/threadline_phoenix_web/storybook.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/router_stub.ex
  modified:
    - examples/threadline_phoenix/mix.exs
    - examples/threadline_phoenix/mix.lock
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex

key-decisions:
  - "Plan 182-02 reused the RED contracts from 182-01 instead of adding duplicate test commits."
  - "PhoenixStorybook remains an example-app dev/test dependency only; production compiles through a no-op router macro fallback when the package is absent."
  - "The maintainer Storybook lane is mounted at /dev/storybook outside /audit and outside normal operator navigation."

patterns-established:
  - "Example-only Storybook installs must prove root mix/source absence with mix verify.compile_no_optional and source contracts."
  - "Dev/test-only route macro dependencies need a production compile fallback because Elixir expands imports even inside false compile-time branches."

requirements-completed: [STORY-01]

duration: 7 min
completed: 2026-06-27
status: complete
---

# Phase 182 Plan 02: PhoenixStorybook Example Install And Route Summary

**PhoenixStorybook 1.2.0 is installed only in the Phoenix example app, with /dev/storybook and assets mounted behind dev_routes while root Threadline stays package- and route-clean.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-27T01:14:09Z
- **Completed:** 2026-06-27T01:20:41Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `{:phoenix_storybook, "~> 1.2.0", only: [:dev, :test]}` only to `examples/threadline_phoenix/mix.exs`.
- Resolved the example app lockfile with `phoenix_storybook` 1.2.0 and its transitive Hex dependencies without touching root `mix.exs` or root `mix.lock`.
- Added guarded `ThreadlinePhoenixWeb.Storybook` backend configuration pointing at the example app `storybook/` content tree.
- Mounted `/dev/storybook` and `/dev/storybook/assets` only inside the example app `dev_routes` branch.
- Preserved root optional-dependency hygiene and `/audit/__stress` route behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add example-only Storybook dependency and backend** - `dbeba805` (feat)
2. **Task 2: Mount the dev/test route and assets** - `a01d1379` (feat)

## Files Created/Modified

- `examples/threadline_phoenix/mix.exs` - Adds the direct PhoenixStorybook dependency for dev/test only.
- `examples/threadline_phoenix/mix.lock` - Locks `phoenix_storybook` 1.2.0 and transitive packages inside the example app.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook.ex` - Defines the guarded PhoenixStorybook backend module.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/router_stub.ex` - Provides no-op route macros for production compiles when PhoenixStorybook is absent.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` - Mounts Storybook route/assets under `/dev/storybook` behind `dev_routes`.

## Decisions Made

- Reused the RED contracts from Plan 182-01 rather than adding duplicate TDD RED commits in this implementation plan.
- Kept Storybook unauthenticated because the route is local dev/test-only, outside `/audit`, and absent from production.
- Added an example-local no-op `PhoenixStorybook.Router` fallback so production compilation can import the route macro module without installing the dev/test package.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed production compilation for dev/test-only route macros**
- **Found during:** Task 2 (Mount the dev/test route and assets)
- **Issue:** `MIX_ENV=prod mix compile --warnings-as-errors` failed because Elixir expands `import PhoenixStorybook.Router` even inside a false `dev_routes` branch, while `phoenix_storybook` is unavailable in prod.
- **Fix:** Added an example-local no-op router macro fallback that exists only when the real `PhoenixStorybook.Router` cannot be loaded.
- **Files modified:** `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/router_stub.ex`
- **Verification:** `cd examples/threadline_phoenix && MIX_ENV=prod mix compile --warnings-as-errors`, route tests, root Storybook boundary tests, and `mix verify.compile_no_optional` pass.
- **Committed in:** `a01d1379`

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** The fix preserves the intended dependency boundary and production route absence without expanding public or root package surface.

## Issues Encountered

- `cd examples/threadline_phoenix && mix precommit` was run per the example app guidance and failed. The failures are outside Plan 182-02's deliverable:
  - `storybook_stories_test.exs` still expects story wrapper/content files owned by later Phase 182 plans.
  - Existing demo seed and walkthrough tests still fail on inherited audit-data drift.
- Targeted Plan 182-02 gates passed after the two task commits.

## Verification

- `mix hex.info phoenix_storybook 1.2.0` - PASS; Hex metadata reports release `2026-06-11`, package `phoenix_storybook` 1.2.0, and compatible Phoenix/LiveView dependencies.
- `cd examples/threadline_phoenix && mix deps.get && MIX_ENV=test mix compile --warnings-as-errors` - PASS.
- `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_route_test.exs` - PASS; 4 tests, 0 failures.
- `mix test test/threadline/operator_surface/storybook_boundary_test.exs` - PASS; 4 tests, 0 failures.
- `mix verify.compile_no_optional` - PASS.
- `bash -lc 'set +e; rg -n "PhoenixStorybook|phoenix_storybook|live_storybook" mix.exs mix.lock lib/threadline; code=$?; test "$code" -eq 1'` - PASS; root package/source has no Storybook terms.
- `rg -n "phoenix_storybook.*1\\.2|phoenix_storybook" examples/threadline_phoenix/mix.exs examples/threadline_phoenix/mix.lock` - PASS; dependency and lockfile are example-only and locked to 1.2.0.
- `cd examples/threadline_phoenix && MIX_ENV=prod mix compile --warnings-as-errors` - PASS.
- `cd examples/threadline_phoenix && mix precommit` - FAIL; out-of-scope future Storybook story contracts plus inherited demo seed/walkthrough failures.

## Known Stubs

- `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/router_stub.ex` - Intentional no-op compile fallback for production environments where the dev/test-only PhoenixStorybook package is absent. It emits no routes and does not block Plan 182-02's goal.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 182-03 to add the curated story wrapper and story content that will turn the remaining Storybook story contracts green.

## Self-Check: PASSED

- Created files exist: `182-02-SUMMARY.md`, `storybook.ex`, and `storybook/router_stub.ex`.
- Task commits found: `dbeba805` and `a01d1379`.
- No missing files or missing task commits found.

---
*Phase: 182-phoenixstorybook-example-dev-lane*
*Completed: 2026-06-27*
