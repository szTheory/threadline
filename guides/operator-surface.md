# Operator Surface

The Threadline Operator Surface provides a suite of mountable, drop-in LiveView screens to investigate row mutations, actor histories, and transaction contexts directly in your host application.

It is designed to be fully optional: `phoenix`, `phoenix_live_view`, `phoenix_html`, and `phoenix_pubsub` are optional dependencies, so capture-only integrations aren't forced to bring in UI code.

For compatibility, support boundaries, and deprecation policy, see `guides/upgrade-path.md`. This guide stays focused on mount, auth, and screens.
For the broader composition contract across `Threadline.Plug`, `Threadline.Job`,
reference adapters, and operator-surface auth/export auth, see
`guides/integration-contracts.md`.

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
      actor_fn: &MyApp.Audit.current_actor/1,
      authorize_fn: &MyApp.Audit.authorize_operator/1
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

The `:authorize_fn` callback is invoked directly as a 1-arity function. For the
LiveView surface it receives the socket-shaped value passed into
`Threadline.OperatorSurface.Auth.on_mount/4`; when export routes fall back to
it, they call it with a synthetic `%{assigns: conn.assigns}` mirror. The
callback should return:

- `:ok` or `true` - Allowed.
- `{:ok, scope}` - Allowed. The `scope` will be passed into investigation queries (e.g., restricting to a specific organization or tenant).
- any other value - Denied.

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

## Coverage dashboard

The operator surface ships a polled coverage dashboard at `/audit/coverage` that wraps `Threadline.Health.trigger_coverage/1`. Every LV in the surface also renders a small "uncovered count" pill in its header so operators notice drift from any screen.

### Reading the dashboard

The dashboard renders three buckets:

- **covered** — tables that have a Threadline trigger installed.
- **uncovered** — tables that DO NOT have a trigger and are NOT marked expected.
- **expected** — tables intentionally not audited (e.g. `schema_migrations`). The `SOURCE` column shows whether the entry comes from the hardcoded baseline or from your `:expected_uncovered_tables` config.

### Polling

The dashboard polls every 30 seconds by default. Override globally:

```elixir
config :threadline, :coverage_poll_ms, 30_000
```

Floor is `5_000` ms — below this the two `pg_*` queries become a noisy neighbor on busy schemas.

### Multi-schema adopters

Pass `?schema=NAME` to view a non-`public` schema:

    /audit/coverage?schema=tenant_42

The schema is validated at the LV edge (regex + `pg_namespace` lookup); invalid input renders a `Schema 'X' not found.` error.

The surface header always queries the `"public"` schema — multi-schema is opt-in on the dashboard only.

### Marking expected-uncovered tables

Adopters typically have bookkeeping tables that are not application data (Oban, application metrics, vendor add-ons). Declare them so the dashboard shows them as `expected` rather than `uncovered`:

```elixir
config :threadline, :health,
  expected_uncovered_tables: ["oban_jobs", "oban_peers", "oban_producers"],
  audit_anyway: []
```

Validate at boot in your `application.ex`:

```elixir
Threadline.Health.Policy.validate!(Application.get_env(:threadline, :health, []))
```

The `:audit_anyway` key removes a baseline entry. Use rarely — it overrides the safe default. Example:

```elixir
config :threadline, :health,
  audit_anyway: ["schema_migrations"]  # very unusual — opts in to auditing migrations
```

### Mix-task parity

Capture-only adopters who do not mount the surface get the same data via:

    mix threadline.health.coverage
    mix threadline.health.coverage --json
    mix threadline.health.coverage --schema=NAME

The Mix task is a viewer (always exits 0). The CI gate is the existing `mix threadline.verify_coverage` task, which now also accepts `--schema=NAME`.

## Policy redaction drift

The operator surface also ships a read-only redaction drift viewer at `/audit/policy/redaction`. It reconciles your configured `config :threadline, :trigger_capture` policy against the deployed trigger SQL that PostgreSQL is actually running.

### What it shows

The page groups tables into three operator-safe states:

- **Drift detected** — configured redaction does not match deployed trigger SQL. Rerun `mix threadline.gen.triggers` and apply the migration.
- **Could not introspect** — Threadline could not safely parse the deployed trigger SQL. Treat this as unresolved drift; rerun `mix threadline.gen.triggers` and do not assume capture is aligned.
- **Config matches deployed** — configured redaction matches deployed trigger redaction.

Tables are shown alphabetically within each section. Expanding a row shows the exact configured and deployed `exclude`, `mask`, and `mask placeholder` facts for that table.

### No sample values

This surface never renders captured sample values. It only shows column names and placeholder metadata, so operators can confirm policy shape without exposing redacted payloads in the UI.

### Mix-task parity

Capture-only adopters can inspect the same facts without Phoenix:

    mix threadline.policy.show
    mix threadline.policy.show --json

Default output prints one summary line, one aligned `TABLE / STATUS / CONFIG / DEPLOYED / HINT` table, then extra detail blocks only for `Drift detected` and `Could not introspect`. `--json` exposes the same top-level states as stable machine values:

- `drift_detected`
- `could_not_introspect`
- `config_matches_deployed`

### Telemetry

`[:threadline, :health, :checked]` fires on every successful poll with measurements `%{covered, uncovered, expected_uncovered}`. The `expected_uncovered` measurement is additive (Phase 66) — old subscribers reading only `covered`/`uncovered` keep working unchanged.

`[:threadline, :health, :checked, :error]` fires on poll failure with metadata `%{error: message}`; alert on this for sustained drift.
