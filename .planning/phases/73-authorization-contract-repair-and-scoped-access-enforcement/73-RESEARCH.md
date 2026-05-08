# Phase 73: Authorization Contract Repair & Scoped Access Enforcement - Research

**Researched:** 2026-05-08 [VERIFIED: repo context]
**Domain:** Operator-surface authorization contract repair, host-owned scoped-read enforcement, and Phase 71 proof closeout [VERIFIED: `.planning/ROADMAP.md`, `.planning/v1.19-MILESTONE-AUDIT.md`]
**Confidence:** HIGH [VERIFIED: code + docs + tests]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMPAT-02 | Verification and CI entrypoints must exercise the claimed breadth story so docs do not promise ranges the repo does not prove. | Add focused scope-enforcement and example-contract tests so future drift in the shared authorizer or support-read-only story fails before `mix ci.all` goes green. [VERIFIED: `.planning/v1.19-MILESTONE-AUDIT.md`; `test/threadline/operator_surface_doc_contract_test.exs`] |
| COMPAT-03 | Example-app and guide wording must stay aligned with the supported Phoenix/Sigra line and caveats. | Repair the example router so the shared `authorize_fn` is policy-equivalent across LiveView and export transport, then lock the docs and example README around that contract. [VERIFIED: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`; `examples/threadline_phoenix/README.md`] |
| ADOPT-09 | The canonical reference path must be proven end to end in docs and the example app, with fallback equivalents named. | Keep `/audit` as the canonical path, but document and test the support-read-only enforcement seam plus explicit export posture. [VERIFIED: `guides/operator-surface.md`; `guides/getting-started-saas.md`] |
| INTEG-03 | The operator surface must have a documented and tested host-owned access pattern for router checks, mount checks, and optional scoped investigation queries. | Introduce a host-supplied scope callback for query narrowing, thread it through the operator surface, and prove it across timeline, actor, transaction, and export flows. [VERIFIED: `lib/threadline/operator_surface/live/timeline_live.ex`; `lib/threadline/operator_surface/live/actor_live.ex`; `lib/threadline/operator_surface/live/transaction_live.ex`; `lib/threadline/operator_surface/controllers/export_controller.ex`] |
| ADOPT-08 | Canonical mount recipes for secure admin and support-read-only installs must be real and provable. | Keep one `/audit` topology, but extend the recipe with a concrete scope-enforcement callback and proof steps. [VERIFIED: `.planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md`; `.planning/v1.19-MILESTONE-AUDIT.md`] |

## Summary

Phase 73 is not a docs-only repair. The current codebase already stores `:threadline_scope` in both LiveView and export auth, but only `TimelineLive` even attempts to consume it, and that bridge is a no-op. `ActorLive`, `TransactionLive`, and `ExportController` ignore scoped narrowing entirely, so the documented support-read-only story is not materially true today. [VERIFIED: `lib/threadline/operator_surface/auth.ex`; `lib/threadline/operator_surface/export_auth_plug.ex`; `lib/threadline/operator_surface/live/timeline_live.ex`; `lib/threadline/operator_surface/live/actor_live.ex`; `lib/threadline/operator_surface/live/transaction_live.ex`; `lib/threadline/operator_surface/controllers/export_controller.ex`]

The example app also still demonstrates the wrong final-gate behavior. Its `my_authorize_fn/1` correctly allows admins, but then grants any `%Phoenix.LiveView.Socket{}` as a fallback. That means the example `/audit` mount only works because the router scope is already behind `:admin_auth`, not because the shared `authorize_fn` is truly transport-equivalent. This is exactly the Phase 71 drift the audit flagged. [VERIFIED: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`; `.planning/v1.19-MILESTONE-AUDIT.md`]

The cleanest repair is to keep auth host-owned and opaque while adding one new host-supplied scope-enforcement seam for operator-surface investigation queries. The repo does not currently have a generic way to interpret `%{access: :support_read_only, organization_id: ...}` or any other support scope across timeline, actor-history, transaction, and export queries. Hard-coding an `organization_id` meaning into Threadline would violate the host-owns-auth boundary. The phase should therefore add a callback such as `scope_query_fn.(query, scope, context)` that lets hosts transform the underlying Ecto query for each operator flow while keeping Threadline's public auth vocabulary unchanged. [INFERRED from `lib/threadline/query.ex`; `lib/threadline/investigation.ex`; `.planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md`]

## Recommended Contract

### New operator-surface option

Add a new optional router/mount option:

```elixir
scope_query_fn: &MyApp.Audit.scope_operator_query/3
```

Recommended callback shape:

```elixir
fn query, scope, %{surface: surface, params: params} -> query end
```

Rules:

- `scope` is the opaque map previously returned from `authorize_fn`.
- `surface` is one of `:timeline | :actor_history | :transaction | :export`.
- `params` carries small context needed for host filtering, such as `filters`, `actor_ref`, or `transaction_id`.
- Returning the query unchanged is allowed for full-access admins.
- Threadline must never interpret host role names or organization semantics itself.

### Why this seam

- Timeline/export already have query-builder seams and can be narrowed without public API breakage. [VERIFIED: `lib/threadline/query.ex`; `lib/threadline/export.ex` via `ExportController` usage]
- Actor history and transaction drill-down currently call high-level helpers directly, so the phase should add internal query-builder helpers or operator-surface-private wrappers rather than broadening public Threadline APIs unnecessarily. [VERIFIED: `lib/threadline/query.ex`; `lib/threadline/investigation.ex`; `lib/threadline/operator_surface/live/actor_live.ex`; `lib/threadline/operator_surface/live/transaction_live.ex`]
- The callback keeps `organization_id` and any other tenant semantics host-owned, which preserves the v1.19 contract. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md`]

## Recommended Plan Shape

1. Add the scope-enforcement seam and wire it through the operator surface.
2. Repair the canonical docs/example contract and focused proof tests around the new seam.
3. Recreate missing Phase 71 verification evidence on the post-fix tree and finalize the draft validation artifact.

## Concrete Files To Expect

- `lib/threadline/operator_surface/router.ex`
- `lib/threadline/operator_surface/auth.ex`
- `lib/threadline/operator_surface/export_auth_plug.ex`
- `lib/threadline/operator_surface/live/timeline_live.ex`
- `lib/threadline/operator_surface/live/actor_live.ex`
- `lib/threadline/operator_surface/live/transaction_live.ex`
- `lib/threadline/operator_surface/controllers/export_controller.ex`
- `lib/threadline/operator_surface/scope.ex` or equivalent helper module
- `lib/threadline/query.ex`
- `lib/threadline/investigation.ex`
- `guides/operator-surface.md`
- `guides/integration-contracts.md`
- `guides/getting-started-saas.md`
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`
- `examples/threadline_phoenix/README.md`
- focused LiveView/controller/auth/doc-contract tests
- `.planning/phases/71-mount-recipes-and-access-tiers/71-VERIFICATION.md`
- `.planning/phases/71-mount-recipes-and-access-tiers/71-VALIDATION.md`

## Verification Recommendations

- Add one scoped test router/endpoint for each affected surface so support-read-only enforcement is proven, not inferred.
- Prefer actor/source-based scoping in tests instead of app-specific organization tables, because those fields already exist in Threadline's generic schema. [VERIFIED: `lib/threadline/capture/audit_transaction.ex`; `test/threadline/operator_surface/live/timeline_live_test.exs`]
- Keep the example router failure mode explicit: LiveView should no longer be allowed just because the transport is a socket.
- Re-run the Phase 71 focused contract/auth suite plus new scope tests before regenerating `71-VERIFICATION.md`.

## Risks

- Adding a scope callback that is too narrow, such as timeline-only, would leave the audit blocker unresolved.
- Adding a Threadline-owned scope DSL would violate v1.19's host-owns-auth boundary.
- Widening public `Threadline.*` APIs unnecessarily would create more compatibility surface than this repair needs.

## RESEARCH COMPLETE
