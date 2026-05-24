# Feature Landscape

**Domain:** Scoped support/operator adoption lane
**Researched:** 2026-05-24

## Table Stakes

Features adopters expect if Threadline claims a first-party support lane.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Canonical shared `/audit` recipe | Most Phoenix SaaS teams want one operator mount, not separate products for admin and support. | Low | Must keep one host-owned browser/auth boundary and one shared authorizer shape. |
| Separate support-tree recipe | Some teams will prefer stricter path isolation for support. | Low | Should reuse the same callbacks and keep `exports: false` by default. |
| Predictable denial semantics | Support adopters need to know when they get redirect, `403`, empty state, or not-found. | Medium | Must be explicit across LiveView and HTTP. |
| Scoped visibility proof for major screens | A support-lane claim is not credible without tests on timeline, actor, transaction, and export flows. | Medium | Much of this already exists; the claim needs tightening and completion. |
| Example-app support fixtures | Docs alone are not enough for adoption trust. | Medium | The example app should prove two organizations and a support operator story. |

## Differentiators

Features that make Threadline easy to adopt without taking over host auth.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Shared `%{assigns: assigns}` authorizer contract | One host callback can authorize both LiveView and export fallback paths. | Low | Already present; needs stronger teaching and proof. |
| Opaque host-owned `scope` | Threadline stays auth-agnostic while still enabling tenant-safe narrowing. | Low | This is the right product boundary to defend. |
| Query-layer scoping seam | Support visibility is enforced where data is loaded, not only where buttons render. | Medium | Best fit for Ecto and least-surprise for experienced Phoenix teams. |
| Support-lane surface controls | `exports: false`-style controls let the repo stay honest without inventing policy DSLs. | Medium | Use only for workflows that are not yet safely scope-aware. |

## Anti-Features

Features to explicitly NOT build in this milestone.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Threadline-owned RBAC or role enums | Different hosts mean different roles, scopes, impersonation semantics, and exception rules. | Keep `authorize_fn` and `scope_query_fn` host-owned and opaque. |
| Tenancy/org DSL in Threadline config | Forces a fake universal model over app-specific data and joins. | Let the host write the Ecto query transform it already understands. |
| Per-page authorization matrix in Threadline | Turns the library into a policy engine and duplicates host policy. | Use small surface toggles only where a workflow is not support-safe yet. |
| Broad new UI families | The milestone is about lane proof, not expanding the operator product footprint. | Polish the existing operator surface and example path instead. |

## Feature Dependencies

```text
Host browser auth pipeline -> mounted support lane
authorize_fn -> opaque scope
opaque scope -> scope_query_fn
scope_query_fn -> scoped timeline / actor / transaction / export proof
surface controls -> honest support-lane claim for any unsupported workflow
docs + example app + tests -> adoption trust
```

## MVP Recommendation

Prioritize:
1. Canonical mount recipes with exact callback shapes.
2. Denial/fallback behavior matrix for allowed, denied, and out-of-scope states.
3. Example-app proof for support scope on the currently support-safe surfaces.

Defer:
- Any role or tenant modeling beyond opaque scope.
- Any broad page-policy configuration system.
- Any claim that row-history/as-of is part of the support lane unless it is actually scoped in this milestone.

## Sources

- Local repo:
  - `guides/operator-surface.md`
  - `guides/integration-contracts.md`
  - `guides/upgrade-path.md`
  - `examples/threadline_phoenix/README.md`
  - `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`
  - `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs`
  - `test/threadline/operator_surface/auth_test.exs`
  - `test/threadline/operator_surface/export_auth_plug_test.exs`
  - `test/threadline/operator_surface/live/timeline_live_test.exs`
- Official docs:
  - Phoenix LiveView security model: https://hexdocs.pm/phoenix_live_view/security-model.html
  - Phoenix routing: https://hexdocs.pm/phoenix/routing.html
