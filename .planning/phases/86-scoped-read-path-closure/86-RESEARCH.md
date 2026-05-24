# Phase 86: Scoped Read-Path Closure - Research

**Researched:** `2024-05-24` (Simulated Date)
**Domain:** Read-Path Security & Feature Closure
**Confidence:** HIGH

## Summary

This phase resolves security boundaries for tenant-scoped operators using the Threadline support surface. It addresses two specific vectors: (1) ensuring the `RowHistoryComponent` ("As-Of" feature) scopes its historical queries using the host-provided `scope_query_fn` to prevent cross-tenant data leaks, and (2) introducing a `coverage_authorize_fn` callback to explicitly gate the `/coverage` dashboard, ensuring system-global DB schema topologies are not leaked to tenant-scoped support staff.

**Primary recommendation:** Use the existing `maybe_apply_scope/2` pattern in `Threadline.Query` for the Row History APIs, and replicate the `assign_exports_enabled/2` auth flow from `Auth.on_mount/4` to gate coverage.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Apply `scope_query_fn` to Row History | API / Backend (`Threadline.Query`) | Frontend Server (LV Component) | `Threadline.Query` owns composing the final `Ecto.Query`. The LV component merely threads the config down. |
| Gate `/coverage` surface | Frontend Server (`Auth.on_mount/4`) | API / Backend | LiveView `on_mount` is the canonical perimeter for auth in Phoenix; it evaluates host-provided functions and assigns booleans. |
| Halt coverage telemetry polling | Frontend Server (`Coverage.OnMount`) | — | `Coverage.OnMount` owns the 30s timer loop. It must check the assigned boolean to avoid silent background querying. |

## User Constraints (from CONTEXT / DISCUSSION)

### Locked Decisions
- **Row History:** Extend `Threadline.history/3` and `Threadline.as_of/4` to apply `scope_query_fn` to the `AuditChange` queries. Preserve the UX; do not disable the component.
- **Coverage Dashboard:** Implement `coverage_authorize_fn` (defaulting to `false`) to explicitly gate the Coverage surface. Do not leak global database schemas to tenant-scoped support staff.

## Standard Stack

This phase does not introduce new dependencies. It relies exclusively on:
- `Ecto.Query` for composition.
- `Phoenix.LiveView` hooks (`on_mount` / `push_navigate`).

## Architecture Patterns

### Pattern 1: Extending `maybe_apply_scope/2`
**What:** The `Threadline.Query` module relies on `maybe_apply_scope(query, opts)` to invoke `OperatorScope.apply/2` when `scope_query_fn` is provided. We will introduce a `row_history_scope_opts/3` private helper and pipe `maybe_apply_scope` into `history/3`, `as_of/4`, `row_history/4`, and `row_history_page/4`.
**Example:**
```elixir
defp row_history_scope_opts(schema_module, id, opts) do
  [
    scope: Keyword.get(opts, :scope),
    scope_query_fn: Keyword.get(opts, :scope_query_fn),
    surface: Keyword.get(opts, :surface, :row_history),
    params: %{schema_module: schema_module, id: id, timestamp: Keyword.get(opts, :timestamp)}
  ]
end

def history(schema_module, id, opts) do
  # ...
  AuditChange
  |> where(...)
  |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
  |> order_by(...)
  |> repo.all()
end
```

### Pattern 2: Component Config Threading
**What:** State from `Auth.on_mount/4` must bridge down to components. `TransactionLive` must pass `@threadline_scope` and `@threadline_scope_query_fn` into `<.live_component module={RowHistoryComponent} />`. `RowHistoryComponent` unpacks them into `opts`.

### Pattern 3: Gated Middleware Assignment (`Auth.on_mount/4`)
**What:** Just like `assign_exports_enabled`, we evaluate `coverage_authorize_fn` against a simulated `%Socket{}` mirror to avoid leaking internal assignments.
**Example:**
```elixir
defp assign_coverage_enabled(socket, opts) do
  coverage_authorize_fn = Keyword.get(opts, :coverage_authorize_fn, fn _ -> false end)
  
  Phoenix.Component.assign(
    socket,
    :threadline_coverage_enabled,
    coverage_enabled_for_socket?(coverage_authorize_fn, socket)
  )
end
```

### Pattern 4: Halting Polling (`Coverage.OnMount`)
**What:** Prevent the background telemetry loop from executing on restricted sessions.
**Example:**
```elixir
socket =
  if connected?(socket) and socket.assigns[:threadline_coverage_enabled] do
    ref = Process.send_after(...)
    # ...
  else
    socket
  end
```

### Pattern 5: Surface Halt (`CoverageLive`)
**What:** Immediate deflection if a user manually forces the `/coverage` URL.
**Example:**
```elixir
def mount(_params, _session, socket) do
  if socket.assigns[:threadline_coverage_enabled] do
    # ... allow mount
  else
    {:ok, push_navigate(socket, to: "/")}
  end
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Denying coverage access in LiveView | A custom plug or controller redirect | `push_navigate` / conditional UI rendering | The Coverage view operates within the `live_session`; checking assigns in `mount/3` is idiomatic. |
| Passing auth state manually | Reading sessions directly in components | LiveView `@assigns` established by `Auth.on_mount` | Keeps components pure and adheres to existing lifecycle hooks. |

## Common Pitfalls

### Pitfall 1: Leaking `pg_namespace` via `Coverage.OnMount`
**What goes wrong:** Adding conditional UI but forgetting to gate `Threadline.OperatorSurface.Coverage.OnMount`.
**Why it happens:** The `on_mount` hook fires for *all* pages in the `:threadline` live session. If not gated by `:threadline_coverage_enabled`, it will still hit the database every 30s to run coverage scans.
**Prevention:** In `Coverage.OnMount.on_mount/4`, ensure both `assign_initial_coverage(socket)` and the `Process.send_after` block are strictly gated.

### Pitfall 2: Forgetting to update `row_history/4` / `row_history_page/4`
**What goes wrong:** `history/3` and `as_of/4` get secured, but the keyset variations (`row_history/4`) remain open.
**Why it happens:** Following only the literal mention of `history/3` in the Discussion document.
**Prevention:** Apply `maybe_apply_scope` to all 4 functions in `Threadline.Query` that return row history.

### Pitfall 3: Propagating Assigns in Caller Views
**What goes wrong:** `RowHistoryComponent` queries with `nil` scope.
**Why it happens:** `TransactionLive` (and any other LV rendering it) wasn't updated to pass `scope={@threadline_scope}` and `scope_query_fn={@threadline_scope_query_fn}` to the `.live_component`.
**Prevention:** Explicitly thread these attributes in the rendering LVs.

### Pitfall 4: Gating the badge vs passing the attr
**What goes wrong:** `SurfaceHeader` throws a KeyError or renders a broken badge.
**Prevention:** Introduce `attr :coverage_enabled, :boolean, default: false` to `SurfaceHeader` and pass `coverage_enabled={@threadline_coverage_enabled}` from the parent LVs where it's called (ActorLive, TimelineLive, TransactionLive, etc.).

### Open Questions (RESOLVED)
None. The parameters and scope mapping are completely defined.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `config/test.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-86-1 | `history/3` and `as_of/4` respect `scope_query_fn` | unit / integration | `mix test test/threadline/query_test.exs` | ✅ |
| REQ-86-2 | `coverage_authorize_fn` defaults to false | unit | `mix test test/threadline/operator_surface/auth_test.exs` | ✅ |
| REQ-86-3 | Unauthorized users get empty coverage/no polling | integration | `mix test test/threadline/operator_surface/coverage/on_mount_test.exs` | ✅ |

### Wave 0 Gaps
- `test/threadline/operator_surface/live/row_history_component_test.exs` — (If exists) must verify options threaded successfully.

## Sources
### Primary (HIGH confidence)
- Codebase structure of `lib/threadline/query.ex` and `lib/threadline/operator_surface/auth.ex`.
- Phase discussion document: `86-DISCUSSION.md`.
- Phase patterns output: `86-PATTERNS.md`.
