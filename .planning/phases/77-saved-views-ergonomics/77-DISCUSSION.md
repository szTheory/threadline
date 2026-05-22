# Phase 77: Saved Views Ergonomics - Discussion & Recommendation

## Architectural Gray Areas

The primary requirement (`VIEW-01`) states that we must "Implement actor-owned saved filter states relying strictly on the host's `actor_fn` to determine ownership without forcing a User schema dependency."

However, we face an impedance mismatch:
1. `Threadline.Plug` defines `actor_fn` as `(Plug.Conn.t() -> ActorRef.t() | nil)`.
2. The Operator Surface UI is built in **LiveView**, which only has access to a `Phoenix.LiveView.Socket` at mount time, and no `Plug.Conn`.

### Tradeoffs & Alternative Approaches

**1. The Session-Injection Approach (Push)**
We could require adopters to build a small `Plug` that executes their `actor_fn` and explicitly writes the resulting serialized `actor_ref` into the `Plug.Conn` session before entering the `/audit` router scope.
* **Pros:** LiveView can trivially read the session during `on_mount`.
* **Cons:** Ergonomic friction. It forces adopters to build a custom plug just to power a UI feature, leaking implementation details.

**2. The Socket-Based Delegate Approach (Pull)**
Update the `threadline_operator_surface/2` macro to accept an optional `socket_actor_fn: (Phoenix.LiveView.Socket.t() -> ActorRef.t() | nil)`.
* **Pros:** Cleanly scopes the data to LiveView.
* **Cons:** Adopters have to maintain *two* actor resolution functions—one for HTTP/Plug (`conn`), and one for LiveView (`socket`), violating the DRY principle and the specific mandate to rely strictly on `actor_fn`.

**3. The Scope Extraction Approach (Idiomatic Threadline)**
The existing `authorize_fn` contract for `threadline_operator_surface` returns `{:ok, scope}`. Currently, `Threadline.OperatorSurface.Auth.on_mount/4` extracts an `actor_ref` from this opaque `scope` map for telemetry:
```elixir
actor_ref = if is_map(scope), do: Map.get(scope, :actor_ref) || Map.get(scope, :user_id), else: nil
```
* **Pros:** Adopters are already building `scope` from their `socket.assigns` inside `authorize_fn`. By making `actor_ref` a first-class required or highly-encouraged field inside the returned `scope` map, we unify authorization and identity without needing a separate `actor_fn` callback.
* **Cons:** Strictly speaking, this relies on `authorize_fn`'s return value rather than the core `actor_fn` plug.

**4. The `assign_new` / Synthetic Conn Approach (One-Shot Recommendation)**
If we must use the **exact** `actor_fn` used by `Threadline.Plug`, we can update the router macro to accept `:actor_fn` (which expects a `conn`). For HTTP routes (exports), we execute it directly. For LiveView, we require that the `actor_fn` rely *only* on `conn.assigns` (not headers/session directly) and we synthesize a mock `%Plug.Conn{assigns: socket.assigns}` to evaluate it.
* **Pros:** Completely DRY. One `actor_fn` rules them all.
* **Cons:** Brittle. If the adopter's `actor_fn` reads from `conn.req_headers`, it will crash when provided a mock `conn` during LiveView mount.

## Deep Recommendation

We recommend **Approach 3 (Scope Extraction) formalized with an upgrade path**, blended with **Approach 1 (Session Auto-Injection)**.

### Why?
LiveView ergonomics dictate that auth context should arrive via `session` to avoid database roundtrips on WebSocket connect. To honor the requirement of using the host's `actor_fn` without introducing brittle `conn` mocking, we should provide a new **built-in Plug**: `Threadline.OperatorSurface.SessionPlug`.

1. **Provide an optional pipeline plug:** Adopters can drop `plug Threadline.OperatorSurface.SessionPlug, actor_fn: &MyApp.Auth.actor_fn/1` into their router pipeline *before* the `threadline_operator_surface` macro.
2. This Plug evaluates the `actor_fn(conn)`, serializes the resulting `ActorRef` to JSON, and stores it in `conn` session under `"threadline_actor_ref"`.
3. Inside `Threadline.OperatorSurface.Auth.on_mount/4`, we read this session key and assign `@threadline_actor_ref` to the socket.
4. If the session key is missing, we fall back to extracting `actor_ref` from the `{:ok, scope}` return of `authorize_fn` (preserving backwards compatibility).

This shifts the decision-making "left": it provides a seamless developer experience (drop in one plug, get saved views automatically scoped to the actor), maintains strict `ActorRef` encapsulation, and gracefully falls back to the existing `scope` map if the adopter is doing complex multi-tenant routing.

### UI / UX Ergonomics
For the UI (`VIEW-02`), we should introduce a collapsible "Saved Views" sidebar or a dropdown adjacent to the "Filters" toolbar.
* **State Management:** Storing views as JSONB in `threadline_saved_views` ensures we aren't creating rigid schemas. The UI simply serializes the current form state to JSONB.
* **Least Surprise:** Applying a view is a simple `push_patch` with the decoded filters, reusing the exact same navigation flow already present in `timeline_live.ex`.
* **UI Polish:** Saving a view should flash a success toast. Trying to save over an existing name should prompt for an update vs create-new flow (or just silently overwrite if it's the same actor, keeping it simple for V1).

This recommendation ensures we remain zero-intrusion on the host's domain model (no explicit User schema dependency), while delivering a modern, state-driven UI experience inside the Timeline.
