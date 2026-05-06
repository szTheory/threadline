# Operator Surface

The Threadline Operator Surface provides a suite of mountable, drop-in LiveView screens to investigate row mutations, actor histories, and transaction contexts directly in your host application.

It is designed to be fully optional: `phoenix`, `phoenix_live_view`, `phoenix_html`, and `phoenix_pubsub` are optional dependencies, so capture-only integrations aren't forced to bring in UI code.

## 1-Minute Mount

To enable the UI, first ensure you have the optional dependencies installed in your `mix.exs`:

```elixir
def deps do
  [
    # ...
    {:threadline, "~> 0.3.0"},
    {:phoenix, "~> 1.7"},
    {:phoenix_live_view, "~> 1.0"},
    {:phoenix_html, "~> 4.0"},
    {:phoenix_pubsub, "~> 2.1"}
  ]
end
```

Then, use the `threadline_operator_surface/2` macro in your host application's router:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import Threadline.OperatorSurface.Router

  pipeline :admin_auth do
    # You MUST provide your own pipeline to authenticate admins.
    plug :require_authenticated_admin
  end

  scope "/admin", MyAppWeb do
    pipe_through [:browser, :admin_auth]

    # Mount the operator surface with access control options
    threadline_operator_surface "/audit",
      actor_fn: {MyApp.Audit, :current_actor},
      authorize_fn: {MyApp.Audit, :authorize_operator}
  end
end
```

## Security and Authorization (Fail-Closed Default)

Threadline adopts a **fail-closed security posture by default**. The `threadline_operator_surface/2` macro requires a secure mount. Multi-tenancy and authorization stay host-owned.

Unless explicitly bypassed, the macro will fail at compile time unless one of the following is true:
1. The route `scope` has at least one `pipe_through`.
2. The `:authorize_fn` option is provided.
3. The `:adopter_acknowledges_unauthenticated: true` option is explicitly supplied (this raises in test and loudly logs a warning in prod).

### `:authorize_fn`

The `:authorize_fn` callback determines whether the current request is allowed to access the operator surface and can scope queries to a specific tenant. It expects a tuple of `{Module, :function_name}` that takes the `Plug.Conn.t()` and returns:
- `{:ok, scope}` - Allowed. The `scope` will be passed into investigation queries (e.g., restricting to a specific organization or tenant).
- `:error` - Denied.

Telemetry event `[:threadline, :operator_surface, :authorize]` is emitted with the outcome (`:granted`, `:denied`, or `:error`).

### `:actor_fn`

The `:actor_fn` acts just like the native `Threadline.Plug` configuration, determining the identity performing actions in the operator surface.

## Available Screens (v1.17)

The surface provides three must-have workflows out of the box. Together they answer the vast majority of investigation questions on click 1.

### Incident Drill-down (`/audit/transactions/:id`)

**Answers:** "What exactly changed in this transaction, and why?"
Shows all mutations that occurred within a single database transaction, visualizing what was added, removed, or changed. This uses `Threadline.incident_bundle/2` under the hood.

### Actor Window (`/audit/actors/:kind/:id`)

**Answers:** "What did this user/system do recently?"
A time-windowed view of all transactions initiated by a specific actor identity. From here, you can deep-link into specific Incident Drill-down screens.

### Row History / As-of Sub-view (`/audit/rows/:table/:pk`)

**Answers:** "When did this specific record change, and what did it look like at 2:00 PM yesterday?"
Reachable directly from drill-down rows, this screen shows the full mutation lifecycle of a single record and reconstructs its exact state as-of any point in time.

## `mix threadline.incident` Companion Task

For operators who rely on SSH or CLI access (and for projects not using Phoenix), Threadline provides parity via a Mix task.

You can query the exact same incident data natively in the terminal without mounting the LiveView surface:

```bash
mix threadline.incident <transaction_id>
```
