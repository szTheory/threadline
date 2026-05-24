# Architecture Patterns

**Domain:** Scoped support/operator lane on Phoenix
**Researched:** 2026-05-24

## Recommended Architecture

The right architecture for Option 2 is a **three-boundary model**:

1. **Plug pipeline** authenticates and establishes host-owned operator context.
2. **LiveView `on_mount`** performs page-entry authorization and stores opaque scope.
3. **Ecto query transform** narrows visible data for support scopes.

This keeps Threadline aligned with Phoenix's security model and avoids pretending that UI affordances alone are security controls.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| Host router pipeline | Authenticates the operator and populates session/assigns | `authorize_fn`, `actor_fn`, Phoenix session |
| `Threadline.OperatorSurface.Auth` | LiveView mount authorization and scope assignment | LiveView socket assigns |
| `Threadline.OperatorSurface.ExportAuthPlug` | HTTP export authorization and denial | Plug conn assigns, export controller |
| `Threadline.OperatorSurface.Scope` | Dispatches host-owned query transform | Query layer and investigation APIs |
| `Threadline.Query` / investigation APIs | Load only visible rows | Repo, scoped `Ecto.Query` |
| Example app router/helpers | First-party proof of host composition | Current user, support/admin fixtures |

### Data Flow

**Shared `/audit` support lane**

1. Browser request enters host `pipe_through [:browser, :operator_auth]`.
2. Host pipeline authenticates the operator and stores the host user/session values.
3. `threadline_operator_surface/2` mounts the LiveView session.
4. `authorize_fn` returns `:ok` for admin or `{:ok, scope}` for support.
5. Threadline stores `:threadline_scope` and passes it into scoped query paths.
6. Timeline, actor, transaction, and export queries call `scope_query_fn` where implemented.
7. UI hides export affordances when export auth is denied; direct export URLs still return HTTP `403`.

## Patterns to Follow

### Pattern 1: Plug auth first, LiveView auth second
**What:** Put authentication in the host pipeline and authorization in `on_mount`.
**When:** Every mounted support/operator recipe.
**Example:**
```elixir
scope "/audit" do
  pipe_through([:browser, :operator_auth])

  threadline_operator_surface("/",
    authorize_fn: &MyApp.Audit.authorize_operator/1,
    scope_query_fn: &MyApp.Audit.scope_operator_query/3,
    repo: MyApp.Repo
  )
end
```

### Pattern 2: Shared assigns-shaped authorizer
**What:** Authorize both transports through one `%{assigns: assigns}` callback when possible.
**When:** Default recipe and most adopters.
**Example:**
```elixir
def authorize_operator(%{assigns: assigns}) do
  case assigns[:current_user] do
    %{is_admin: true} -> :ok
    %{role: :support, organization_id: org_id} -> {:ok, %{organization_id: org_id}}
    _ -> {:error, :unauthorized}
  end
end
```

### Pattern 3: Query scoping stays in Ecto
**What:** Narrow visibility by transforming the query, not by filtering rendered results.
**When:** Timeline, actor history, transaction bundle, export queries, and any future support-safe view.
**Example:**
```elixir
def scope_operator_query(query, %{organization_id: org_id}, %{surface: :timeline})
    when is_binary(org_id) and org_id != "" do
  where(query, [_ac, at], fragment("?->>'organization_id' = ?", at.meta, ^org_id))
end
```

### Pattern 4: Unsupported support workflows must be explicitly gated
**What:** If a workflow is not scope-safe, disable it for support rather than silently overclaim.
**When:** Any screen or subview that bypasses the scope seam today.
**Example:** Treat row-history/as-of this way unless it is scoped during v1.21.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Turning `scope` into a Threadline policy object
**What:** Defining reserved keys, built-in role semantics, or org rules in Threadline.
**Why bad:** It converts a host-owned integration seam into a fake universal auth model.
**Instead:** Keep `scope` opaque and document only how Threadline transports it.

### Anti-Pattern 2: Page-specific authorization logic in LiveViews
**What:** Teaching each screen its own support rules instead of using one scope seam.
**Why bad:** Duplicates policy, drifts across screens, and produces inconsistent leaks.
**Instead:** Keep `authorize_fn` as entry authorization and `scope_query_fn` as row-visibility enforcement.

### Anti-Pattern 3: Claiming support-safe row history before it is scoped
**What:** Marketing the whole operator surface as support-safe while `history/as_of` bypasses scope.
**Why bad:** Breaks trust and creates a real leakage risk.
**Instead:** Scope that path or exclude/gate it.

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| Support-lane auth | Straightforward shared mount | Still fine; complexity is policy clarity, not scale | Still host-policy-bound; no new Threadline DSL needed |
| Query scoping | Simple `where` clauses are enough | Hosts may need better indexes on scoped metadata keys | Hosts may need domain-specific schema/index work, but the seam remains the same |
| Denial UX | Manual testing is enough | Need fixture-backed example coverage | Need explicit support matrix and verification, not broader auth abstraction |

## Sources

- Local repo:
  - `lib/threadline/operator_surface/router.ex`
  - `lib/threadline/operator_surface/auth.ex`
  - `lib/threadline/operator_surface/export_auth_plug.ex`
  - `lib/threadline/operator_surface/scope.ex`
  - `lib/threadline/query.ex`
  - `lib/threadline/operator_surface/live/timeline_live.ex`
  - `lib/threadline/operator_surface/live/actor_live.ex`
  - `lib/threadline/operator_surface/live/transaction_live.ex`
  - `lib/threadline/operator_surface/live/row_history_component.ex`
  - `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`
- Official docs:
  - Phoenix LiveView security model: https://hexdocs.pm/phoenix_live_view/security-model.html
  - Phoenix LiveView router: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html
  - Plug.Conn: https://hexdocs.pm/plug/Plug.Conn.html
  - Ecto.Query: https://hexdocs.pm/ecto/Ecto.Query.html
