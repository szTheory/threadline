---
phase: 73
plan: "73-01"
subsystem: operator-surface
tags:
  - auth
  - scope
  - liveview
  - export
provides:
  - INTEG-03
  - ADOPT-08
key_files:
  created:
    - lib/threadline/operator_surface/scope.ex
    - .planning/phases/73-authorization-contract-repair-and-scoped-access-enforcement/73-01-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/router.ex
    - lib/threadline/operator_surface/auth.ex
    - lib/threadline/operator_surface/export_auth_plug.ex
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/actor_live.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - lib/threadline/operator_surface/controllers/export_controller.ex
    - lib/threadline/query.ex
    - lib/threadline/investigation.ex
    - lib/threadline/export.ex
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface/live/actor_live_test.exs
    - test/threadline/operator_surface/transaction_live_test.exs
    - test/threadline/operator_surface/controllers/export_controller_test.exs
decisions:
  - Keep `scope` opaque and host-owned while adding one shared `scope_query_fn` seam for all operator-surface query paths.
  - Reuse the query layer and investigation layer rather than adding page-specific scope logic in controllers or LiveViews.
  - Treat out-of-scope actor and transaction requests as hidden/not-found behavior instead of leaking identifiers.
---

# Phase 73 Plan 73-01 Summary

Implemented the real scoped-access enforcement seam for the operator surface and
proved it behaviorally across timeline, actor, transaction, and export flows.

## Completed Tasks

| Task | Outcome |
| --- | --- |
| 1 | Added `Threadline.OperatorSurface.Scope`, threaded `scope_query_fn` through auth/export assigns and the query/export layers, and replaced the old timeline no-op scope bridge with host-owned query transforms. |
| 2 | Extended actor-history and transaction drill-down flows to use the same scope seam, then added focused scoped LiveView/controller tests so out-of-scope data is hidden instead of merely assigned on mount. |

## Verification

- `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs --max-failures 1`
  Result: passed (`57 tests, 0 failures`).
- `mix verify.compile_no_optional`
  Result: passed.

## Deviations from Plan

None. The slice executed as planned once the dirty-tree constraint forced execution on the main working tree rather than isolated worktrees.

## Self-Check

PASSED

