---
phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger
plan: 01
subsystem: testing
tags: [elixir, exunit, phoenix-liveview, operator-surface, stress-fixtures]
requires:
  - phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger
    provides: locked DS-04 fixture decisions and Phase 171 stress-lab context
provides:
  - Threadline.OperatorSurface.StressFixtures pure static registry
  - DS-04 ugly-data case matrix contract
  - stable story IDs, ledger IDs, and component assign adapters
affects: [171-02-ledger, 171-03-stress-route, 171-04-browser-harness]
tech-stack:
  added: []
  patterns:
    - pure static story registry with string IDs
    - ExUnit source contract for synthetic fixture safety
    - Phoenix.LiveViewTest component adapter smoke checks
key-files:
  created:
    - lib/threadline/operator_surface/stress_fixtures.ex
    - test/threadline/operator_surface/stress_fixtures_test.exs
  modified: []
key-decisions:
  - "Stress fixture ledger_id values match story IDs so downstream JSON ledger rows can round-trip directly."
  - "Not-yet-implemented form controls, groups, primitives, pages, and folded todos are explicit reserved stories with reserved_for_phase metadata."
patterns-established:
  - "StressFixtures.all/0 returns deterministic story maps sorted by string id."
  - "StressFixtures.assigns_for/1 returns component-ready assigns or {:error, :unknown_story}; unknown strings never raise."
requirements-completed: [DS-04]
duration: 12min
completed: 2026-06-14
---

# Phase 171 Plan 01: Stress Fixture Registry Summary

**Static DS-04 stress fixture registry with stable story IDs, synthetic data, reserved future cases, and component adapter contracts**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-14T21:35:00Z
- **Completed:** 2026-06-14T21:47:46Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created `Threadline.OperatorSurface.StressFixtures` as a pure static registry for DS-04 stress stories.
- Added ExUnit contracts for required ugly-data cases, stable IDs, synthetic-only source rules, reserved folded todos, and planned inventory story coverage.
- Added representative adapter smoke tests for `SurfaceHeader.surface_header/1` and `UnsupportedView.unsupported_view/1`.

## Task Commits

1. **Task 1: Write fixture registry contract tests** - `2592559` (`test`)
2. **Task 2: Implement static stress fixture registry** - `347396d` (`feat`)

## Files Created/Modified

- `lib/threadline/operator_surface/stress_fixtures.ex` - Pure static story registry, lookup helpers, case/theme/viewport metadata, and component assign adapters.
- `test/threadline/operator_surface/stress_fixtures_test.exs` - DS-04 matrix and adapter drift contract.

## Decisions Made

- Used story IDs as ledger IDs for Plan 171-02 round-trip simplicity and deterministic downstream references.
- Represented planned-but-not-extracted inventory as reserved stories, not ledger-only rows, so later route and ledger plans can render every entry.
- Kept all data synthetic and local to the library module; no example database lane or external package registry is involved.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added missing `long_id` case coverage**
- **Found during:** Task 2
- **Issue:** The first implementation included a long synthetic ID value but did not tag any story with the `long_id` DS-04 case.
- **Fix:** Added `long_id` to the `foundation.z-index` story case list.
- **Files modified:** `lib/threadline/operator_surface/stress_fixtures.ex`
- **Verification:** `mix test test/threadline/operator_surface/stress_fixtures_test.exs`
- **Committed in:** `347396d`

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Correctness-only fix; no scope expansion.

## Issues Encountered

None beyond the auto-fixed DS-04 case metadata gap.

## Known Stubs

Intentional reserved baseline stories exist for planned inventory not implemented in Phase 171: form controls, groups, several primitives, pages, and the folded future-owned cases `future.theme-picker-idiomatic-ui`, `footgun.coverage-schema-card-declutter`, and `footgun.transaction-page-left-push-desktop`. These are explicit plan requirements and include `status: "reserved"` plus `reserved_for_phase` metadata.

## Threat Flags

None. This plan adds no network endpoints, auth paths, file access beyond test source assertions, or schema trust boundaries.

## Verification

- `mix test test/threadline/operator_surface/stress_fixtures_test.exs` - 9 tests, 0 failures
- `rg -n 'ThreadlinePhoenix|Repo\.|Ecto\.Query|String\.to_atom|PhoenixStorybook|Tailwind' lib/threadline/operator_surface/stress_fixtures.ex` - no matches
- `mix run -e 'IO.inspect(Threadline.OperatorSurface.StressFixtures.by_id("not-a-story"))'` - `:error`

## Self-Check: PASSED

- Found `lib/threadline/operator_surface/stress_fixtures.ex`
- Found `test/threadline/operator_surface/stress_fixtures_test.exs`
- Found task commit `2592559`
- Found task commit `347396d`

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 171-02 can seed `.planning/design-system-ledger.json` directly from `StressFixtures.all/0`; every story has stable `id`, `ledger_id`, and `fixture_key` values, and reserved placeholders are already represented as renderable unsupported-state assigns.

---
*Phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger*
*Completed: 2026-06-14*
