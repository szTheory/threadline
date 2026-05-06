# Phase 58: mount-macro-and-auth-contract - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 58 ships the **mount macro** and **auth contract** for the v1.17 operator surface. It provides the `Threadline.OperatorSurface.Router.threadline_operator_surface/2` macro, the compile-time fail-closed check for missing `pipe_through` or explicit authorization, the telemetry event for authorization, and the doc-contract test for the gating behavior (deferred from Phase 57).

It is **not** the phase for the actual LiveView screens (Phases 59-61), the `mix threadline.incident` Mix task (Phase 62), or the updated guides/CHANGELOG entries (Phase 63). The macro will set up the `live_session` and `on_mount` hooks, but the actual routes inside the macro will remain absent/placeholders until the screens are implemented in subsequent phases.
</domain>

<decisions>
## Implementation Decisions & Ecosystem Synthesis

Based on deep research into Elixir/Phoenix ecosystem patterns, successful dual-surface libraries (like Oban Web and Sentry), and the "fail-closed by default" requirement, the following architectural decisions are locked for Phase 58.

### D-01: Compile-Time Pipeline Inspection via AST (AUTH-02)
To satisfy the strict compile-time fail-closed posture ("raises... unless the scope has at least one `pipe_through`"), the mount macro will inspect `Module.get_attribute(__CALLER__.module, :phoenix_top_scopes)`. 
- **The Idiomatic Precedent:** Libraries like LiveDashboard avoid this check because Phoenix internals change, which leads to the #1 footgun of LiveDashboard: accidentally exposing it to the public internet because developers forget the `pipe_through :browser`. Threadline's mandate is safety over convenience.
- **The Implementation:** We will safely inspect `Module.get_attribute(__CALLER__.module, :phoenix_top_scopes)`. If it exists and its `:pipes` list is empty, and the user hasn't explicitly provided `:authorize_fn` or `:adopter_acknowledges_unauthenticated`, we raise a `CompileError`. If Phoenix internals change in a future major version, the macro gracefully defaults to assuming no pipes and demands explicit auth.
- **Developer Ergonomics:** The error message must be actionable: "Threadline Operator Surface must be mounted inside a secure pipeline. Add `pipe_through :admin_browser` or explicitly provide an `:authorize_fn`."

### D-02: Dual-Surface Auth Contract & Lifecycle Hook (AUTH-04)
The requirement specifies the `:authorize_fn` must accept `(Plug.Conn.t() | Phoenix.LiveView.Socket.t())`.
- **The Architecture:** In Phase 58, the macro emits a `live_session` with an `on_mount` hook (`Threadline.OperatorSurface.Auth`). This hook receives a `Phoenix.LiveView.Socket.t()`. We will NOT inject an additional Plug. Modern Phoenix LiveView relies securely on `on_mount` to halt both the initial disconnected HTTP render and the connected WebSocket render.
- **Why the Dual Contract:** It is highly idiomatic for dual-surface apps (like Oban) to accept both. The adopter writes pattern-matching clauses (`def auth(%Plug.Conn{} = conn)` and `def auth(%Phoenix.LiveView.Socket{} = socket)`). This future-proofs Threadline in case we ever add raw API endpoints, and allows the adopter to share their existing Plug auth functions with the LiveView surface.

### D-03: Gated Module Enforcement (SURF-03)
Following the Phase 57 pattern, `lib/threadline/operator_surface/router.ex` and `lib/threadline/operator_surface/auth.ex` will be wrapped at file-scope with `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule ... end`.

### D-04: Doc-Contract Test (Deferred from Phase 57)
Phase 58 picks up the deferred doc-contract test. We will write a test that uses `Code.ensure_loaded?(Threadline.OperatorSurface.Router)` to verify the module exists when `phoenix_live_view` is present, and does not exist when it is compiled without optional dependencies.

### D-05: HexDocs Grouping (mix.exs)
We will add `Threadline.OperatorSurface` to `groups_for_modules:` in `mix.exs` `docs/0` function, creating a single, clean group for the entire UI surface.

### D-06: Observability via Telemetry (TELEM-01)
The `on_mount` hook will execute the telemetry dispatch. It emits `[:threadline, :operator_surface, :authorize]` with `%{result: :granted | :denied | :error}` measurements and `%{path, actor_ref, scope_keys}` metadata. Denied connections will return `{:halt, redirect_or_403}` to fully seal the `live_session`.
</decisions>