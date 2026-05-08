# Phase 73: Authorization Contract Repair & Scoped Access Enforcement - Pattern Map

**Mapped:** 2026-05-08
**Files analyzed:** 17
**Analogs found:** 17 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/operator_surface/router.ex` | macro contract | mount opts -> LV/export scopes | current operator-surface mount macro | exact |
| `lib/threadline/operator_surface/auth.ex` | auth seam | authorize_fn result -> socket assigns | current `:threadline_scope` assignment | exact |
| `lib/threadline/operator_surface/export_auth_plug.ex` | auth seam | authorize_fn/export_authorize_fn -> conn assigns | current export auth twin | exact |
| `lib/threadline/operator_surface/live/timeline_live.ex` | LiveView | scope + filters -> `Query.timeline_page/2` | current timeline scope stub | exact |
| `lib/threadline/operator_surface/live/actor_live.ex` | LiveView | scope -> actor-history query | current actor screen | exact |
| `lib/threadline/operator_surface/live/transaction_live.ex` | LiveView | scope -> incident bundle query | current transaction screen | exact |
| `lib/threadline/operator_surface/controllers/export_controller.ex` | controller | scope + filters -> export query | current export controller | exact |
| `lib/threadline/operator_surface/scope.ex` | helper | host callback dispatch | existing auth/export helper style | close |
| `lib/threadline/query.ex` | query builders | filters/scope -> Ecto query | current `timeline_query/1`, `actor_history/2`, `export_changes_query/1` | exact |
| `lib/threadline/investigation.ex` | investigation | tx id -> bundle | current `incident_bundle/2` builder | exact |
| `guides/operator-surface.md` | guide | recipe/proof | current Phase 71 recipe guide | exact |
| `guides/integration-contracts.md` | guide | auth/export contract | current shared callback contract guide | exact |
| `guides/getting-started-saas.md` | guide | first verification path | current `/audit` walkthrough | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | example code | reference mount/auth recipe | current example router mount | exact |
| `examples/threadline_phoenix/README.md` | example proof | runnable contract | current example README | exact |
| focused LiveView/controller/auth tests | proof | scope enforcement | current timeline/export/auth test suites | exact |
| `71-VERIFICATION.md` / `71-VALIDATION.md` | proof artifact | phase closeout evidence | current `72-VERIFICATION.md`, draft `71-VALIDATION.md` | exact |

## Pattern Assignments

### Scope-carry pattern

**Analogs:** `lib/threadline/operator_surface/auth.ex`, `lib/threadline/operator_surface/export_auth_plug.ex`

Keep the current grant vocabulary unchanged:

```elixir
:ok | true | {:ok, scope}
```

Both transports already persist opaque scope in assigns. Extend that same pattern with one additional assign for the host-supplied scope callback if needed, rather than inventing a second auth result vocabulary.

### Query-transform pattern

**Analogs:** `lib/threadline/query.ex`, `lib/threadline/investigation.ex`

Follow the existing split between:

- public helpers that validate inputs and call `repo`
- internal query builders that assemble Ecto queries

Phase 73 should insert host scoping at the internal query-builder layer, not by special-casing HTML in controllers or LiveViews.

### LiveView enforcement pattern

**Analogs:** `lib/threadline/operator_surface/live/timeline_live.ex`, `test/threadline/operator_surface/live/timeline_live_test.exs`

Reuse the existing scoped test-endpoint style from `TimelineLiveScopedTest`. Create equivalent scoped endpoints/cases for actor and transaction flows so scope enforcement is proven with the same repo fixtures and not just unit-tested in isolation.

### Export enforcement pattern

**Analogs:** `lib/threadline/operator_surface/controllers/export_controller.ex`, `test/threadline/operator_surface/controllers/export_controller_test.exs`

Keep export auth and export query enforcement separate:

- auth decides whether the request may proceed at all
- scoped query transform decides which rows are visible if it does

This mirrors the existing `authorize_fn` plus export-query split and avoids overloading `export_authorize_fn` with row-level policy.

### Documentation lock pattern

**Analogs:** `test/threadline/operator_surface_doc_contract_test.exs`, `test/threadline/integration_contracts_doc_contract_test.exs`, `test/threadline/example_phoenix_readme_contract_test.exs`

Use the current `String.contains?/2` / `refute String.contains?/2` contract-test style. Lock:

- the shared `authorize_fn` contract
- the new `scope_query_fn` hook and its host-owned meaning
- support-read-only `exports: false` default
- explicit statement that Threadline does not interpret host role names or organizations
- example router no longer granting any LiveView socket

### Verification artifact pattern

**Analogs:** `.planning/phases/72-packaging-boundary-scorecard-and-closeout/72-VERIFICATION.md`, `.planning/phases/71-mount-recipes-and-access-tiers/71-VALIDATION.md`

Phase 71 closeout artifacts should use the same truth-table and command-run structure as recent verification reports, and the existing Phase 71 validation file should be finalized rather than replaced with a new draft.

## Recommended Plan Split

1. Scope enforcement seam and code-path wiring.
2. Canonical contract and example repair.
3. Verification/validation artifact regeneration.

## PATTERN MAPPING COMPLETE
