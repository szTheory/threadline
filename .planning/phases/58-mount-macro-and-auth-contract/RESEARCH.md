# Phase 58: mount-macro-and-auth-contract - Research

**Researched:** 2026-05-06
**Domain:** Elixir, Phoenix LiveView, Macros, AST Inspection
**Confidence:** HIGH

## Summary

Phase 58 focuses on establishing the core routing macro (`Threadline.OperatorSurface.Router.threadline_operator_surface/2`) and authentication contract (`Threadline.OperatorSurface.Auth`) for the Threadline operator surface. The primary technical hurdle is implementing a strict fail-closed authorization posture at compile time by inspecting the Phoenix Router's AST for `pipe_through` calls, while remaining resilient to future changes in Phoenix internals.

**Primary recommendation:** Implement AST inspection via `Module.get_attribute(__CALLER__.module, :phoenix_top_scopes)` in the mount macro. Gracefully fallback to a "deny-by-default" stance if the attribute is missing, emitting a `live_session` that wraps the upcoming LiveView screens.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
#### D-01: Compile-Time Pipeline Inspection via AST (AUTH-02)
To satisfy the strict compile-time fail-closed posture ("raises... unless the scope has at least one `pipe_through`"), the mount macro will inspect `Module.get_attribute(__CALLER__.module, :phoenix_top_scopes)`. 
- **The Idiomatic Precedent:** Libraries like LiveDashboard avoid this check because Phoenix internals change, which leads to the #1 footgun of LiveDashboard: accidentally exposing it to the public internet because developers forget the `pipe_through :browser`. Threadline's mandate is safety over convenience.
- **The Implementation:** We will safely inspect `Module.get_attribute(__CALLER__.module, :phoenix_top_scopes)`. If it exists and its `:pipes` list is empty, and the user hasn't explicitly provided `:authorize_fn` or `:adopter_acknowledges_unauthenticated`, we raise a `CompileError`. If Phoenix internals change in a future major version, the macro gracefully defaults to assuming no pipes and demands explicit auth.
- **Developer Ergonomics:** The error message must be actionable: "Threadline Operator Surface must be mounted inside a secure pipeline. Add `pipe_through :admin_browser` or explicitly provide an `:authorize_fn`."

#### D-02: Dual-Surface Auth Contract & Lifecycle Hook (AUTH-04)
The requirement specifies the `:authorize_fn` must accept `(Plug.Conn.t() | Phoenix.LiveView.Socket.t())`.
- **The Architecture:** In Phase 58, the macro emits a `live_session` with an `on_mount` hook (`Threadline.OperatorSurface.Auth`). This hook receives a `Phoenix.LiveView.Socket.t()`. We will NOT inject an additional Plug. Modern Phoenix LiveView relies securely on `on_mount` to halt both the initial disconnected HTTP render and the connected WebSocket render.
- **Why the Dual Contract:** It is highly idiomatic for dual-surface apps (like Oban) to accept both. The adopter writes pattern-matching clauses (`def auth(%Plug.Conn{} = conn)` and `def auth(%Phoenix.LiveView.Socket{} = socket)`). This future-proofs Threadline in case we ever add raw API endpoints, and allows the adopter to share their existing Plug auth functions with the LiveView surface.

#### D-03: Gated Module Enforcement (SURF-03)
Following the Phase 57 pattern, `lib/threadline/operator_surface/router.ex` and `lib/threadline/operator_surface/auth.ex` will be wrapped at file-scope with `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule ... end`.

#### D-04: Doc-Contract Test (Deferred from Phase 57)
Phase 58 picks up the deferred doc-contract test. We will write a test that uses `Code.ensure_loaded?(Threadline.OperatorSurface.Router)` to verify the module exists when `phoenix_live_view` is present, and does not exist when it is compiled without optional dependencies.

#### D-05: HexDocs Grouping (mix.exs)
We will add `Threadline.OperatorSurface` to `groups_for_modules:` in `mix.exs` `docs/0` function, creating a single, clean group for the entire UI surface.

#### D-06: Observability via Telemetry (TELEM-01)
The `on_mount` hook will execute the telemetry dispatch. It emits `[:threadline, :operator_surface, :authorize]` with `%{result: :granted | :denied | :error}` measurements and `%{path, actor_ref, scope_keys}` metadata. Denied connections will return `{:halt, redirect_or_403}` to fully seal the `live_session`.
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Route Mounting | Frontend Server (Macro) | — | Phoenix Router macros happen at compile-time to emit LiveView paths |
| Auth Enforcement | Frontend Server (LiveView) | — | LiveView `on_mount` hooks control access securely before socket connection and during HTTP mount |
| Observability | API / Backend (Telemetry) | Frontend Server | Auth outcomes must emit unified telemetry matching backend standards |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | ^0.20+ | Interactive frontend | Native Phoenix interactive tooling |
| Telemetry | ^1.0 | Observability | Elixir standard for observability events |

## Architecture Patterns

### Pattern 1: Compile-Time Scope Introspection
**What:** Safely checking Phoenix Router's internal attribute to verify `pipe_through` calls.
**When to use:** When enforcing secure default mounting rules at compile time.
**Example:**
```elixir
defmacro threadline_operator_surface(path, opts \\ []) do
  caller = __CALLER__.module
  
  scopes = Module.get_attribute(caller, :phoenix_top_scopes)
  
  # Phoenix 1.7 internally stores scopes in a map/struct with a :pipes list.
  # We pattern match defensively to handle future Phoenix internal changes.
  has_pipes? = case scopes do
    %{pipes: [_ | _]} -> true
    _ -> false # Default to closed/unpiped if nil or unexpected shape
  end

  explicit_auth? = Keyword.has_key?(opts, :authorize_fn)
  acknowledged? = Keyword.get(opts, :adopter_acknowledges_unauthenticated, false)

  if not has_pipes? and not explicit_auth? and not acknowledged? do
    raise CompileError,
      description: "Threadline Operator Surface must be mounted inside a secure pipeline. Add `pipe_through :admin_browser` or explicitly provide an `:authorize_fn`.",
      file: __CALLER__.file,
      line: __CALLER__.line
  end
  
  quote do
    import Phoenix.LiveView.Router, only: [live_session: 3]
    # In Phase 58, we set up the live_session without inner routes yet
    live_session :threadline, on_mount: [{Threadline.OperatorSurface.Auth, unquote(opts)}] do
       # Scope blocks for LiveView (to be populated in Phase 59+)
    end
  end
end
```

### Pattern 2: Dual-Surface Auth via `on_mount`
**What:** Using LiveView's `on_mount` hook to authenticate both disconnected rendering and WebSocket upgrades.
**When to use:** For all LiveView endpoints to guarantee auth before mount.
**Example:**
```elixir
defmodule Threadline.OperatorSurface.Auth do
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    # Assuming `opts` passes the `:authorize_fn` MFA
    # We call the user's function passing the socket
    # It must handle pattern matching `def authorize(%Phoenix.LiveView.Socket{} = socket)`
    case run_authorize(socket) do
      :ok -> 
        :telemetry.execute([:threadline, :operator_surface, :authorize], %{result: :granted}, %{})
        {:cont, socket}
      {:error, redirect_path} -> 
        :telemetry.execute([:threadline, :operator_surface, :authorize], %{result: :denied}, %{})
        {:halt, redirect(socket, to: redirect_path)}
    end
  end
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Route Auth | Custom Plugs for LiveView | `on_mount` hooks | LiveView requires `on_mount` to securely block WebSocket connections. Standard Plugs only block the HTTP render. |
| Configuration Gating | Runtime checks for missing deps | `Code.ensure_loaded?` file wrapper | File-scope compilation wrapping is needed for HexDocs to exclude the files entirely if LiveView is not loaded. |

## Common Pitfalls

### Pitfall 1: Brittle Internal API Usage
**What goes wrong:** Phoenix internal `get_attribute(__CALLER__.module, :phoenix_top_scopes)` could change shape or disappear in a future version.
**Why it happens:** Phoenix's Router is macro-heavy and doesn't explicitly guarantee stable internals.
**How to avoid:** Never assume the attribute exists. Use a strict default pattern match (`%{pipes: [_ | _]}`) and fallback to treating missing/unmatched data as "unpiped." This satisfies the requirement to fail closed natively and demand explicit auth if Phoenix breaks the integration.

### Pitfall 2: `authorize_fn` Function Pointers in Macros
**What goes wrong:** Passing `authorize_fn: &MyApp.auth/1` to the router macro can fail if the session data must be serialized, or it can be challenging to reconstruct in the hook.
**How to avoid:** Encourage passing `{Mod, :fun}` MFA tuples rather than anonymous functions, or evaluate the function invocation securely inside the macro's `quote` block to inject it into the `live_session`'s `on_mount` args.

### Pitfall 3: Failing to Halt Connection
**What goes wrong:** Returning `{:cont, socket}` when authorization fails.
**Why it happens:** Missing the `{:halt, redirect(...) }` tuple.
**How to avoid:** Ensure the telemetry wrapper accurately redirects or returns a 403-equivalent for the user.

## Code Examples

### Doc-Contract Gating Example
```elixir
# lib/threadline/operator_surface/router.ex
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Router do
    @moduledoc """
    Operator Surface Routing Macros.
    """
    
    # ...
  end
end
```

## Validation Architecture

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-02 | Fails compile if not piped or explicit | unit | `mix test test/threadline/operator_surface/router_test.exs` | ❌ Wave 0 |
| AUTH-04 | Accepts connection on auth success | unit | `mix test test/threadline/operator_surface/auth_test.exs` | ❌ Wave 0 |
| SURF-03 | Module existence gated by LiveView | unit | `mix test test/threadline/operator_surface/router_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/threadline/operator_surface/router_test.exs` — Needs to define a dynamic module in tests that uses the router macro to capture `CompileError`.
- [ ] `test/threadline/operator_surface/auth_test.exs` — Needs isolated LiveView testing primitives to trigger `on_mount`.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified)
