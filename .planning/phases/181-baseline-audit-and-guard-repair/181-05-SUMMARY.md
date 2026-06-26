---
phase: 181-baseline-audit-and-guard-repair
plan: 05
subsystem: testing
tags: [operator-ui, source-contracts, routes, auth, feature-gates, optional-deps]

requires:
  - phase: 181-04
    provides: current active source-test prose and guard repair ledger baseline
provides:
  - Route/export source contracts for the mounted operator surface
  - Stress-route auth, prod fail-closed, and no root Storybook/stress exposure contracts
  - Stable feature-gated nav group IDs and single-current-nav source contracts
  - Guard repair ledger evidence for D-181-05
affects: [181-06, 181-07, 181-08, 181-09, 181-10, 181-11, 182, 183, 187]

tech-stack:
  added: []
  patterns:
    - TDD RED/GREEN source-contract repair for operator route/auth/feature-gate boundaries
    - Additive semantic hooks only: stable data-testid IDs without route, copy, layout, or API churn

key-files:
  created:
    - .planning/phases/181-baseline-audit-and-guard-repair/181-05-SUMMARY.md
  modified:
    - test/threadline/operator_surface/router_test.exs
    - test/threadline/operator_surface/stress_router_test.exs
    - test/threadline/operator_surface/surface_header_test.exs
    - lib/threadline/operator_surface/components/surface_header.ex
    - .planning/phases/181-baseline-audit-and-guard-repair/181-GUARD-REPAIR.md

key-decisions:
  - "181-05 locks route/export/stress/header boundaries through focused source contracts rather than rendered UI redesign."
  - "Feature-gated nav group IDs are additive semantic hooks; existing destination IDs, hrefs, copy, active-state semantics, and public component API remain unchanged."
  - "Root `threadline` continues to exclude PhoenixStorybook/Storybook and production stress/story routes."

patterns-established:
  - "Route contracts compile throwaway routers and inspect Phoenix.Router.routes/1 for exact LiveView and export-controller surfaces."
  - "Feature-gated shell groups carry stable source IDs separate from destination IDs so later nav polish can preserve group-level contracts."

requirements-completed: [BASE-01, BASE-02]

duration: 8 min
completed: 2026-06-26
status: complete
---

# Phase 181 Plan 05: Route, Auth, Feature-Gate, and Optional-Dependency Source Contracts Summary

**Operator route/export, stress-route, feature-gate, and optional-Phoenix guardrails are now contract-tested without adding Storybook, route churn, public APIs, or dependency surface.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-26T14:59:15Z
- **Completed:** 2026-06-26T15:07:13Z
- **Tasks:** 1
- **Files modified:** 5

## Accomplishments

- Added TDD source contracts for the exact mounted operator LiveView route set and HTTP export-controller routes.
- Added source contracts proving root operator source does not expose Storybook, story routes, or `/audit/__stress`, while the stress macro remains auth-gated and prod fail-closed.
- Added stable `operator-nav-group-*` semantic IDs to existing feature-gated shell nav groups and tested their gate behavior.
- Updated `181-GUARD-REPAIR.md` with Plan 05 D-181-05 repair evidence.

## Task Commits

1. **RED: Add route and nav source contracts** - `cd51cac` (test)
2. **GREEN: Lock operator source contracts** - `372293a` (feat)

## Files Created/Modified

- `test/threadline/operator_surface/router_test.exs` - Compiles throwaway routers and locks LiveView route, export route, and ExportAuthPlug source contracts.
- `test/threadline/operator_surface/stress_router_test.exs` - Locks no root story/stress exposure, stress auth hook order, and prod fail-closed source contracts.
- `test/threadline/operator_surface/surface_header_test.exs` - Locks feature-gated nav group IDs and single-current navigation behavior.
- `lib/threadline/operator_surface/components/surface_header.ex` - Adds stable group-level `data-testid` hooks only.
- `.planning/phases/181-baseline-audit-and-guard-repair/181-GUARD-REPAIR.md` - Records Plan 05 D-181-05 source-contract evidence.

## Verification

| Check | Result |
|---|---|
| RED run: `mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/stress_router_test.exs test/threadline/operator_surface/surface_header_test.exs` before source hook repair | Failed as expected: 32 tests, 1 failure for missing `operator-nav-group-investigate`. |
| GREEN run: same targeted task slice after repair | Passed: 32 tests, 0 failures. |
| `mix verify.compile_no_optional` | Passed with exit 0. |
| `bash -lc 'set +e; rg -n "PhoenixStorybook\|phoenix_storybook\|Storybook" mix.exs lib/threadline; status=$?; test "$status" -eq 1'` | Passed: no root package or `lib/threadline` Storybook surface. |
| Source/evidence acceptance scan for D-181-05, ExportAuthPlug, stress session, and nav group hooks | Passed. |
| File-scope check | Passed: only the declared tests/source and guard ledger changed. |
| `git diff --check` | Passed before GREEN commit. |

## Decisions Made

- Used route-source tests instead of adding rendered browser coverage because this plan protects server route/auth/export boundaries.
- Added group-level `data-testid` hooks to existing nav sections rather than changing labels, hrefs, destination test IDs, or active-state logic.
- Kept PhoenixStorybook entirely out of root source; Phase 182 remains responsible for example-app dev/test Storybook work.

## TDD Gate Compliance

- RED gate present: `cd51cac test(181-05): add route and nav source contracts`.
- GREEN gate present after RED: `372293a feat(181-05): lock operator source contracts`.
- No refactor commit was needed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- An initial uncommitted RED draft assumed controller route verbs were stored as `"GET"` strings; Phoenix stores them as `:get` atoms. The test was corrected before the RED commit, and the committed RED failure was scoped to the intended missing nav group hook.

## Known Stubs

None. Stub-pattern scan only matched historical quoted ledger text and an existing stress-router test name containing "reserved placeholder"; no runtime/UI stub or unwired data source was introduced.

## Threat Flags

None. The plan added tests, additive static `data-testid` hooks, and planning evidence only; it introduced no new endpoint, auth path, file access pattern, schema change, dependency, route path, public component API, or capture/query/auth semantic.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `181-06`. Route/auth/export/stress/header guardrails are explicit, D-181-05 evidence is recorded, and the root package remains Phoenix-optional with no Storybook dependency or production story/stress route.

## Self-Check: PASSED

- Found `.planning/phases/181-baseline-audit-and-guard-repair/181-05-SUMMARY.md`.
- Found task commits `cd51cac` and `372293a` in git history.
- Found all five modified task files on disk.
- Targeted Plan 05 ExUnit slice passed after GREEN.
- `mix verify.compile_no_optional` passed.
- Negative Storybook surface scan passed.
- No tracked file deletions were introduced by task commits.
- Working tree was clean before summary creation.

---
*Phase: 181-baseline-audit-and-guard-repair*
*Completed: 2026-06-26*
