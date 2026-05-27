# Operator Surface

The Threadline Operator Surface provides a suite of mountable, drop-in LiveView screens to investigate row mutations, actor histories, and transaction contexts directly in your host application.

It is designed to be fully optional: `phoenix`, `phoenix_live_view`, `phoenix_html`, and `phoenix_pubsub` are optional dependencies, so capture-only integrations aren't forced to bring in UI code.

For compatibility, support boundaries, and deprecation policy, see `guides/upgrade-path.md`. This guide stays focused on mount, auth, and screens.
For the broader composition contract across `Threadline.Plug`, `Threadline.Job`,
reference adapters, and operator-surface auth/export auth, see
`guides/integration-contracts.md`.

## 1-Minute Mount

To enable the UI, first ensure your host app has the root Threadline dependency
and the optional Phoenix surface stack that matches your host app. Keep exact
Phoenix proof pins in `guides/upgrade-path.md`; this guide stays on the mount,
auth, and screen contract.

```elixir
def deps do
  [
    # ...
    {:threadline, "~> 0.6"}
  ]
end
```

Then, use the `threadline_operator_surface/2` macro in your host application's router.
The canonical topology is one host-owned `/audit` mount behind your browser/auth
pipeline, with one shared `authorize_fn` that works for both the LiveView
surface and the export fallback:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import Threadline.OperatorSurface.Router

  pipeline :admin_auth do
    # You MUST provide your own pipeline to authenticate admins.
    plug :require_authenticated_admin
  end

  scope "/audit", MyAppWeb do
    pipe_through [:browser, :admin_auth]

    threadline_operator_surface "/",
      actor_fn: &MyApp.Audit.current_actor/1,
      authorize_fn: &MyApp.Audit.authorize_operator/1,
      repo: MyApp.Repo
  end
end
```

Admin-first recipe:

- Keep `/audit` behind `pipe_through [:browser, :admin_auth]`.
- Return a real `Threadline.Semantics.ActorRef` from `actor_fn`; the standard
  mount path auto-installs `Threadline.OperatorSurface.SessionPlug` and carries
  that actor into LiveView for saved views and other actor-owned affordances.
- Let `authorize_fn` make the final allow/deny decision.
- Keep export routes enabled for admins unless your host wants stricter posture.

support-read-only variation:

- Reuse the same `/audit` surface and the same host auth boundary.
- Return `{:ok, %{access: :support_read_only, organization_id: "org_123"}}` or
  another host-owned scope from `authorize_fn`.
- Use `export_authorize_fn` to keep export affordances and direct HTTP export
  requests behind explicit host authorization on the same tree.
- Keep coverage and policy surfaces behind their own explicit
  `coverage_authorize_fn` / `policy_authorize_fn` callbacks; when denied,
  Threadline renders an unsupported state and points operators to the matching
  Mix-task fallback.

```elixir
threadline_operator_surface "/",
  actor_fn: &MyApp.Audit.current_actor/1,
  authorize_fn: &MyApp.Audit.authorize_operator/1,
  export_authorize_fn: &MyApp.Audit.authorize_operator_export/1,
  repo: MyApp.Repo
```

## Security and Authorization (Fail-Closed Default)

Threadline adopts a **fail-closed security posture by default**. The `threadline_operator_surface/2` macro requires a secure mount. Multi-tenancy and authorization stay host-owned.

Unless explicitly bypassed, the macro will fail at compile time unless one of the following is true:
1. The route `scope` has at least one `pipe_through`.
2. The `:authorize_fn` option is provided.
3. The `:adopter_acknowledges_unauthenticated: true` option is explicitly supplied (this raises in test and loudly logs a warning in prod).

### `:authorize_fn`

The `:authorize_fn` callback is invoked directly as a 1-arity function. The
recommended shape is one shared callback that pattern-matches on
`%{assigns: assigns}` so the same host-owned policy works for both transports.
For the LiveView surface it receives the socket-shaped value passed into
`Threadline.OperatorSurface.Auth.on_mount/4`; when export routes fall back to
it, they call it with a synthetic `%{assigns: conn.assigns}` mirror. The
callback should return:

- `:ok` or `true` - Allowed.
- `{:ok, scope}` - Allowed. The `scope` is host-owned and opaque. Threadline
  carries it into investigation queries where implemented today, but it does
  not define a roles DSL, page-level authorization model, or universal scope
  narrowing contract.
- any other value - Denied.

Telemetry event `[:threadline, :operator_surface, :authorize]` is emitted with the outcome (`:granted`, `:denied`, or `:error`).

`live_session` and `on_mount` protect the LiveView pages only. They do not
secure the sibling HTTP export controller routes. Export denials stay
HTTP-native through `Threadline.OperatorSurface.ExportAuthPlug`: denial or
error halts with plain-text `403`, not a LiveView redirect.

If you use one shared `%{assigns: assigns}` export callback, Threadline also
uses that result to hide export affordances in the timeline LiveView for denied
operator scopes. HTTP export auth remains authoritative even if you choose a
Conn-specific callback shape and keep the buttons visible.

Coverage and policy views are separate admin/global surfaces. Gate them with
`coverage_authorize_fn` and `policy_authorize_fn`; denied sessions get an
explicit `Unsupported View` state plus the CLI fallback (`mix
threadline.health.coverage`, `mix threadline.policy.show`, or the retention Mix
path) instead of a silent redirect.

Mounted `/audit/evidence` is also separately gated. Use
`evidence_authorize_fn` for that capability; denied sessions should get the
same explicit `Unsupported View` posture plus the CLI fallback to
`mix threadline.evidence.show`. Do not describe `/audit/evidence` as
automatically available everywhere the broader `/audit` surface is mounted.

The export-status surface keeps one actor-owned `Download Export` action.
Threadline resolves the actual delivery only after authorization: local storage
stays app-served through the controller route, while adapter-backed storage can
redirect to a backend-issued URL without exposing that URL in the LiveView HTML.

### `:actor_fn`

The `:actor_fn` acts just like the native `Threadline.Plug` configuration,
determining the identity performing actions in the operator surface.

On the standard `threadline_operator_surface/2` mount path, providing
`actor_fn` auto-installs `Threadline.OperatorSurface.SessionPlug` ahead of the
LiveView routes. No extra manual `SessionPlug` is required for the normal
mount. Return a real `Threadline.Semantics.ActorRef` or `nil`.

Session actor data stays authoritative once LiveView mounts. If your
`authorize_fn` also returns a compatibility-only scope fallback such as
`%{user_id: ...}` or `%{actor_ref: ...}`, the session actor wins and Threadline
emits a low-noise mismatch telemetry event instead of silently inverting
ownership.

Manual `Threadline.OperatorSurface.SessionPlug` composition remains available as
an advanced escape hatch when you intentionally need a non-standard router or
transport shape outside the canonical mount path.

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
Reachable directly from drill-down rows, this screen shows the full mutation lifecycle of a single record and reconstructs its exact state as-of any point in time. On the current repo tree, the named support-lane claim now includes support-scoped row-history / as-of proof on the shipped `/audit` route when the host provides `scope_query_fn`.

## First verification steps

After mounting `/audit`, verify the boundary before you treat the surface as
ready:

1. Visit `/audit` as an allowed admin and confirm the timeline loads.
2. Hit an export URL without the required host auth and confirm you get `403`
   rather than a redirect loop.
3. Run `mix threadline.health.coverage` and compare it with `/audit/coverage`.
4. Run `mix threadline.policy.show` and compare it with
   `/audit/policy/redaction`.

## Mounted workflow parity

| Mounted workflow | Operator question | Fallback transport | Guarantee level |
|------|-------|----------------|
| `/audit/transactions/:id` | What changed in this one transaction? | `mix threadline.incident <transaction_id>` | Direct parity |
| `/audit/actors/:kind/:id` | What did this actor drive recently? | `Threadline.actor_history/2` or `Threadline.timeline_page/2` | API parity |
| `/audit/rows/:table/:pk` | How did this row change over time? | `Threadline.history/3` and `Threadline.as_of/4` | Mounted route exists; support-scoped row history / as-of is proven on the current tree |
| export actions from `/audit` | Can I download the same filtered audit data? | `mix threadline.export --dry-run` plus exact `--table` / `--from` / `--to` flags when the denied route can derive them safely, or a file export run | CLI parity |
| `/audit/coverage` | Which tables are covered right now? | `mix threadline.health.coverage` | Direct parity |
| `/audit/policy/redaction` | Does deployed redaction match config? | `mix threadline.policy.show` | Direct parity |

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
