# Getting started with Threadline in a Phoenix SaaS app

This is the canonical first-hour path for a Phoenix SaaS app: install
Threadline, capture one real write, mount the shipped operator surface, and
finish by checking the same request through `/audit` and the query APIs. The
example app in `examples/threadline_phoenix/` is the runnable contract behind
the snippets below. If you want the architecture/persona/JTBD map first, read
[How Threadline works](how-threadline-works.md) before you wire anything.

This guide and [How Threadline works](how-threadline-works.md) both treat `Threadline.Audit.transaction/3` as the recommended audited write path; §6 below is the canonical runnable snippet.

## 1. Prerequisites

- You need a Phoenix app with Ecto + PostgreSQL available before you start. If Phoenix is new to you, read <https://phoenixframework.org> first, then come back here.
- The walkthrough assumes your app has a `posts` table you want to audit first.
- Commands below use the same vocabulary as `examples/threadline_phoenix/`.
- The mounted operator surface stays behind your app's own admin/auth boundary.

## 2. Add Threadline to your app

Add Threadline to `mix.exs`:

```elixir
defp deps do
  [
    {:threadline, "~> 0.6"}
  ]
end
```

Then fetch deps:

```bash
mix deps.get
```

## 3. Install the audit schema

Generate Threadline's base migrations, then run them:

```bash
mix threadline.install
mix ecto.migrate
```

## 4. Generate triggers for posts

Generate capture triggers for your first audited table:

```bash
mix threadline.gen.triggers --tables posts
mix ecto.migrate
```

Threadline reads your app config when it generates trigger SQL, so use the same `MIX_ENV` locally and in CI when you regenerate.

## 5. Wire `Threadline.Plug` with actor and additive request metadata

Your host app establishes identity on the conn first, then wires `Threadline.Plug`
with host-owned callbacks. Threadline does not own auth — it reads the actor and
request metadata your pipeline already attached.

```elixir
plug Threadline.Plug,
  actor_fn: &MyApp.Audit.actor_ref_from_conn/1,
  context_overrides_fn: &MyApp.Audit.audit_context_overrides_from_conn/1
```

[`guides/integrations/phx-gen-auth.md`](integrations/phx-gen-auth.md) uses
`MyApp.AuditActor` for the same two callbacks — rename the module freely in
your app.

`actor_fn` remains the only actor-authority path. `context_overrides_fn` is
for additive `request_id` and `correlation_id` metadata only, and those values
fill missing fields only. Explicit `x-request-id`, explicit
`x-correlation-id`, and the actor derived by `actor_fn` still win when present.

Keep `Threadline.Plug` in the router pipeline after auth setup and after any
host-owned proxy/IP normalization. If `context_overrides_fn` returns unknown
keys or any non-map value, `Threadline.Plug` raises `ArgumentError`
immediately so the wiring contract fails loudly.

Choose an auth lane when you need a full cookbook:

- **phx-gen-auth-reference** → [`guides/integrations/phx-gen-auth.md`](integrations/phx-gen-auth.md)
- **sigra-reference** (optional) → [`guides/integrations/sigra.md`](integrations/sigra.md)
- lane matrix → [`guides/upgrade-path.md`](upgrade-path.md)

Threadline does not require Sigra; do not use `Threadline.Integrations.Sigra`
unless you adopt the optional sigra-reference lane.

### Sigra reference wiring (optional)

<!-- getting-started-sigra-reference-fence -->

**sigra-reference example app only** — not required for capture.

```elixir
    plug(:accepts, ["json"])

    plug(Threadline.Plug,
      actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
      context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
    )
```

## 6. Exercise the first audited write

### Recommended path (0.6.0+)

For new integrations, `Threadline.Audit.transaction/3` is the **recommended write path** —
it replaces the manual `set_config` → domain writes → `record_action/2` → `action_id`
linkage recipe in one call:

```elixir
    Threadline.Audit.transaction(
      Repo,
      [
        audit_context: audit_context,
        action: :post_created_via_api,
        transaction_meta: audit_transaction_meta(opts)
      ],
      fn ->
        case Repo.insert(Post.changeset(%Post{}, attrs)) do
          {:error, changeset} -> Repo.rollback(changeset)
          {:ok, post} -> %{post: post}
        end
      end
    )
```

When `:action` is present, the success map includes `:audit_transaction_id` merged into
your callback return. Omit `:action` or pass `capture_only: true` for capture-only writes;
strict `:correlation_id` filters will not match those rows.

See [Integration contracts](integration-contracts.md) § Audited write path for forbidden
callback operations and escape hatches.

### Authenticate before the audited API call

Identity must be on the conn before **`Threadline.Plug`** runs on audited
pipelines. Prefer **`401`**/**`403`** at your host auth boundary when the
caller is unauthenticated. **`500`** with **`missing actor`** means capture
ran but semantics rejected a missing actor — fix plug order or actor wiring,
not Threadline capture itself.

| Lane | Guide |
|------|-------|
| phx.gen.auth | [`guides/integrations/phx-gen-auth.md`](integrations/phx-gen-auth.md) |
| Sigra | [`guides/integrations/sigra.md`](integrations/sigra.md) |
| Choose lane | [`guides/upgrade-path.md`](upgrade-path.md) |

<details>
<summary>Runnable curl — sigra-reference example app only</summary>

Start the reference Phoenix app, then send the first audited request:

```bash
curl -sS -X POST "http://localhost:4000/api/posts" \
  -H "content-type: application/json" \
  -H "x-request-id: $(uuidgen)" \
  -H "x-correlation-id: demo-corr" \
  -b '_threadline_phoenix_key=PASTE_FROM_BROWSER' \
  -d '{"post":{"title":"Hello","slug":"hello-demo-slug"}}'
```

</details>

Cookie staging for the reference app lives in
[`examples/threadline_phoenix/README.md`](../examples/threadline_phoenix/README.md)
— sign in at **`/users/log_in`**, copy **`_threadline_phoenix_key`** from
DevTools, and pass **`-b '_threadline_phoenix_key=PASTE_FROM_BROWSER'`**. This
example does not ship API bearer tokens — host-owned auth only.

Keep the returned `audit_transaction_id`; you will use it in step 8.

## 7. Check trigger coverage

Run the coverage task in CI, and keep the direct health check handy in IEx:

```elixir
case Threadline.Health.trigger_coverage(repo: MyApp.Repo) do
  [{:covered, _} | _] = coverage ->
    coverage

  other ->
    other
end
```

The literal `{:covered, _}` shape is the fast signal that your first public table is wired.
If you are staying capture-only for now, the equivalent operator check is
`mix threadline.health.coverage` (or `mix threadline.health.coverage --json` in
CI-friendly scripts).

## 8. Investigate the captured timeline

Open IEx in the app and use the same first request to inspect row history, transaction drill-down, and point-in-time reconstruction:

```elixir
filters = [table: "posts", correlation_id: "demo-corr", repo: MyApp.Repo]

timeline = Threadline.timeline(filters)

first_page = Threadline.timeline_page(filters, page_size: 100)

{:ok, bundle} = Threadline.incident_bundle(audit_transaction_id, repo: MyApp.Repo)

as_of_at = DateTime.utc_now()

{:ok, post_as_of} =
  Threadline.as_of(MyApp.Post, post_id, as_of_at, repo: MyApp.Repo)
```

The reference app also requires an authenticated actor before it serves
`GET /api/audit_transactions/:id/changes`. That keeps the example honest about
incident drill-down: auth is included, while tenancy rules still belong to the
host app.

If you are not mounting the surface yet, `mix threadline.incident
<audit_transaction_id>` is the direct parity path for the same single-request
drill-down from the terminal.

If you need to build a custom incident view instead of using the bundled default,
drop to `Threadline.audit_changes_for_transaction/2`, `Threadline.transaction_context/2`,
or `Threadline.change_diff/2` as advanced building blocks.

That sequence gives you the first-hour operator questions and their fallback
paths:

- `Threadline.timeline/2` shows which rows moved in the request.
- `Threadline.timeline_page/2` is the same investigation path when the window is too large to read eagerly at once; continue with `first_page.next_cursor` instead of offsets.
- `Threadline.actor_history/2` gives you the actor-scoped window when the operator question is "what did this actor drive recently?"
- `Threadline.incident_bundle/2` gives you the default single-transaction incident view, including the linked context and packaged change diffs in `bundle`.
- `mix threadline.incident <audit_transaction_id>` is the direct fallback for that incident drill-down.
- `mix threadline.export --dry-run` is the direct export fallback. When the denied route can safely derive the current `table` / `from` / `to` state, it appends those exact flags instead of showing a fake example.
- `mix threadline.health.coverage` answers the same coverage question as the mounted dashboard.
- `mix threadline.policy.show` answers the same policy-drift question as the mounted redaction page.
- `Threadline.history/3` and `Threadline.as_of/4` are the direct row-history and point-in-time fallbacks.
- `Threadline.as_of/4` reconstructs what the row looked like at a chosen point in time.

## 9. Mount the operator surface and open `/audit`

Once capture is working, mount the shipped operator surface behind your existing
browser and operator pipeline. Reuse the real example router shape:

```elixir
scope "/audit" do
  pipe_through([:browser, :operator_browser, :operator_auth])

  threadline_operator_surface("/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
    evidence_authorize_fn: &ThreadlinePhoenixWeb.Router.my_evidence_authorize_fn/1,
    scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
    repo: ThreadlinePhoenix.Repo
  )
end
```

`pipe_through [:browser, :operator_browser, :operator_auth]` is the important
posture: your app owns browser auth and maps the signed-in user to the operator
assigns Threadline expects, then `authorize_fn` acts as the fail-closed final
check. Threadline does not provide host auth for you. Use one shared `%{assigns: assigns}` callback so the same
host-owned policy can serve the LiveView mount and the export fallback mirror.

When `actor_fn` is present on this standard mount path, Threadline
auto-installs `Threadline.OperatorSurface.SessionPlug` and carries the returned
`ActorRef` into LiveView automatically. No extra manual `SessionPlug` is
required for the normal `/audit` recipe.

The canonical first-hour recipe is still admin first, but the runnable example
also proves the stronger shared-operator shape: admins get the full surface,
support operators return an opaque host-owned scope such as
`%{access: :support_read_only, organization_id: "org_123"}` from
`authorize_fn`, and `scope_query_fn` narrows timeline, actor, transaction,
row-history, and as-of queries to that scope. `export_authorize_fn` keeps
direct export requests and LiveView export affordances admin-only on the same
`/audit` tree. This single mount natively supports both admin and support roles
securely without needing multiple router scopes.

`live_session` and `on_mount` only secure the LiveView pages. Export requests
cross a separate HTTP auth boundary and deny with plain-text `403` when
authorization fails. Coverage and policy views are separate admin/global
surfaces; gate them with `coverage_authorize_fn` and `policy_authorize_fn`, and
let the built-in unsupported state point operators to `mix
threadline.health.coverage` or `mix threadline.policy.show` when needed.

Mounted `/audit/evidence` is separately gated via `evidence_authorize_fn`.
Support scopes that reach the scoped timeline do **not** automatically get the
evidence UI — denied sessions see Unsupported View and should use
`mix threadline.evidence.show`. For the full runbook, see
`guides/operator-surface.md`. If you ever need a
non-standard transport shape, manual `SessionPlug` composition is still
available as an advanced escape hatch rather than the primary setup path.

Start the app if it is not already running:

```bash
mix phx.server
```

Then visit `http://localhost:4000/audit`. The shipped surface gives you the
timeline, transaction drill-down, row history / point-in-time reconstruction,
coverage dashboard, and read-only redaction policy view inside the host app you
already operate. Treat row history and point-in-time reconstruction as mounted
support-lane tools on the canonical scoped `/audit` recipe; the direct APIs
(`Threadline.history/3` and `Threadline.as_of/4`) remain the same underlying
fallback transport.

The same policy-drift facts are available without Phoenix via
`mix threadline.policy.show` when you want to confirm deployed redaction shape
from a capture-only host or a production shell.

If you are not ready to mount the UI yet, you can stop after step 8 and stay on
the capture-only path for now, but treat that as a temporary branch rather than
the main first-hour adoption story.

Keep support-lane claims and exact proof pins in
`guides/upgrade-path.md`, and keep the Sigra-specific reference path in
`guides/integrations/sigra.md`, rather than widening this first-hour guide into
its own compatibility matrix.

## Next reads

- [guides/production-checklist.md](production-checklist.md)
- [guides/incident-playbook.md](incident-playbook.md)
- [guides/performance.md](performance.md)
- [guides/integrations/phx-gen-auth.md](integrations/phx-gen-auth.md)
- [guides/integrations/sigra.md](integrations/sigra.md)
- [guides/brownfield-continuity.md](brownfield-continuity.md)
- [guides/adoption-pilot-backlog.md](adoption-pilot-backlog.md)
