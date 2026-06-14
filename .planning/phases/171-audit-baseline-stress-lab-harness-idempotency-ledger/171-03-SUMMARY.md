---
phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger
plan: 03
subsystem: operator-surface
tags: [elixir, phoenix-liveview, router, stress-lab, design-system]
requires:
  - phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger
    provides: fixture registry and JSON design-system ledger from Plans 171-01 and 171-02
provides:
  - authenticated internal `/audit/__stress` route in the example app
  - dev/test-only `Threadline.OperatorSurface.StressRouter.threadline_operator_surface_stress/2`
  - ledger-backed `Threadline.OperatorSurface.Live.StressLive`
affects: [171-04-browser-harness, 172-foundations, 173-primitives]
tech-stack:
  added: []
  patterns:
    - internal stress router macro separate from public operator surface API
    - LiveView param allowlists using strings and integers only
    - ledger-to-fixture story rendering through the real operator shell
key-files:
  created:
    - lib/threadline/operator_surface/stress_router.ex
    - lib/threadline/operator_surface/live/stress_live.ex
    - test/threadline/operator_surface/stress_router_test.exs
    - test/support/stress_router_prod_compile.exs
  modified:
    - lib/threadline/operator_surface/style.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
key-decisions:
  - "The stress route remains an internal macro and does not add a `stress: true` option to `threadline_operator_surface/2`."
  - "The example app explicitly omits the stress route in prod, while direct prod use of the macro still raises."
  - "StressLive reads the JSON ledger at runtime and lists every fixture-backed ledger story with reserved placeholders for future-owned cases."
requirements-completed: [DS-01, DS-02, DS-03, DS-04]
duration: 31min
completed: 2026-06-14
---

# Phase 171 Plan 03: Authenticated Stress Lab Summary

**Authenticated dev/test stress route with ledger-backed fixture previews and fail-closed production gating**

## Performance

- **Duration:** 31 min
- **Completed:** 2026-06-14
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added failing router/LiveView contracts for prod gating, route hygiene, auth reuse, safe params, source API freeze, and ledger story round-trip coverage.
- Implemented `Threadline.OperatorSurface.StressRouter.threadline_operator_surface_stress/2` as a separate internal dev/test macro using `live_session :threadline_stress`.
- Implemented `Threadline.OperatorSurface.Live.StressLive` with the real operator shell, `data-tl-theme`, `SurfaceHeader`, inline CSS assets, ledger score metadata, screenshot status, category/status filters, and fixture-backed previews.
- Mounted `/audit/__stress` in both example router theme branches under the existing authenticated `/audit` scope.
- Added stress-lab CSS inside the existing token system without external services, Tailwind, Storybook, or visual-regression dependencies.

## Task Commits

1. **Task 1: Write stress route and LiveView contracts** - `9bd5d66` (`test`)
2. **Task 2: Implement internal stress router, LiveView, mount, and styles** - `23797e5` (`feat`)

## Files Created/Modified

- `lib/threadline/operator_surface/stress_router.ex` - Internal stress macro with prod raise and example prod omission support.
- `lib/threadline/operator_surface/live/stress_live.ex` - Ledger-backed stress lab LiveView.
- `lib/threadline/operator_surface/style.ex` - Token-scoped stress lab layout, list, metric, and preview styles.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` - Example `/audit/__stress` mount in both theme branches.
- `test/threadline/operator_surface/stress_router_test.exs` - Route, auth, prod gate, source, param, and ledger round-trip contracts.
- `test/support/stress_router_prod_compile.exs` - Isolated real `MIX_ENV=prod` macro gate script.

## Decisions Made

- Kept production behavior two-layered: direct use of the stress macro in prod raises, while the example app passes an internal `:omit` sentinel so production example compilation remains usable.
- Used string allowlists for `story`, `category`, `status`, `theme`, and `viewport`; no user param is converted to an atom.
- Rendered reserved future-owned inventory as explicit placeholder copy, not hidden ledger-only rows.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Omitted example stress route during prod example compilation**
- **Found during:** Task 2
- **Issue:** `(cd examples/threadline_phoenix && mix precommit)` exercises a prod compile path for `demo.reset`; expanding the stress macro there caused the demo reset test to fail before it could assert its own prod guard.
- **Fix:** Added an internal `:omit` stress-env sentinel used only by the example router in prod. Direct prod macro use still raises and is verified by `test/support/stress_router_prod_compile.exs`.
- **Files modified:** `lib/threadline/operator_surface/stress_router.ex`, `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`
- **Verification:** `mix test test/threadline/operator_surface/stress_router_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs`; `(cd examples/threadline_phoenix && mix precommit)`
- **Committed in:** `23797e5`

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Preserved fail-closed prod semantics while keeping the example app's existing prod compile workflows usable.

## Known Stubs

Intentional reserved stress stories remain visible for planned inventory not implemented in Phase 171: form controls, groups, page fixtures, primitive placeholders, and folded future-owned cases. Each is fixture-backed, ledger-backed, and rendered with explicit `Reserved for Phase ...` copy.

## Threat Flags

None beyond the plan threat model. The new route is internal, authenticated through the existing operator `Auth` and coverage `on_mount` hooks, dev/test-only, and rejects user-controlled params through closed allowlists.

## Verification

- `mix test test/threadline/operator_surface/stress_router_test.exs` - expected RED failure before implementation: missing `Threadline.OperatorSurface.StressRouter`.
- `mix test test/threadline/operator_surface/stress_router_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs` - 30 tests, 0 failures.
- `MIX_ENV=prod mix run --no-start test/support/stress_router_prod_compile.exs` - exits non-zero with `Threadline stress surface is dev/test-only`.
- `(cd examples/threadline_phoenix && mix precommit)` - 95 tests, 0 failures.
- `rg -n 'threadline_operator_surface_stress\("/__stress"' examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` - 2 matches.
- `rg -n 'stress: true' lib/threadline/operator_surface examples/threadline_phoenix/lib test/threadline/operator_surface` - no matches.
- `rg -n 'String\.to_atom|PhoenixStorybook|Tailwind|Chromatic|Percy|Applitools' lib/threadline/operator_surface/stress_router.ex lib/threadline/operator_surface/live/stress_live.ex lib/threadline/operator_surface/style.ex` - no matches.

## Self-Check: PASSED

- Found `lib/threadline/operator_surface/stress_router.ex`
- Found `lib/threadline/operator_surface/live/stress_live.ex`
- Found `test/threadline/operator_surface/stress_router_test.exs`
- Found `test/support/stress_router_prod_compile.exs`
- Found task commit `9bd5d66`
- Found task commit `23797e5`

## User Setup Required

None - no external services, package installs, or manual setup required.

## Next Phase Readiness

Plan 171-04 can drive browser semantics and bounded screenshots against `/audit/__stress`; every ledger-owned fixture story is now routed, listed, and previewable through the authenticated operator shell.

---
*Phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger*
*Completed: 2026-06-14*
