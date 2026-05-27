# ThreadlinePhoenix

Canonical **path-dependent** Phoenix reference app for the [`threadline`](https://github.com/szTheory/threadline) library. Treat the install, run, test, and reconstruction commands in this document as the runnable example contract. Mix commands in this document are meant to be run **from `examples/threadline_phoenix/`**; the dependency `{:threadline, path: "../.."}` points at the **repository root** (two levels up from this directory).

This app is the current `sigra-reference` lane: the maintained first-party
reference path for a Phoenix host that already uses Sigra. It proves a narrow
composition story through this example app, the companion guides, and repo
verification. It does not claim that arbitrary Sigra versions, arbitrary auth
layouts, or non-Phoenix hosts are supported automatically.

For the **reference-app maintainer walk** (Phase 109 dry-run), start with
[`./WALKTHROUGH.md`](./WALKTHROUGH.md). Integrators wiring Threadline into their
own app should still use
[`../../guides/getting-started-saas.md`](../../guides/getting-started-saas.md).
Treat this README as the runnable proof artifact behind both paths.

## Prerequisites

- **Elixir** ~> 1.15 (see root `mix.exs` for the exact constraint used in CI)
- **Erlang/OTP** matching the Elixir version you install
- **PostgreSQL** with trigger support, reachable before you run database tasks

Optional: from the **repository root**, `docker compose up -d postgres` publishes Postgres on **`DB_PORT=5433`** by default (see root `docker-compose.yml` and `CONTRIBUTING.md`). When using that compose service, set **`DB_HOST`** / **`DB_PORT`** so this app’s `config/*.exs` resolves the same host and port (defaults remain `localhost` / `5432` if unset).

## Regenerating the skeleton (generator contract)

This tree was created with **`mix phx.new`** using an API-lean, asset-free flag set. To reproduce or refresh after a Phoenix upgrade, align the command with upstream **`Mix.Tasks.Phx.New`** for your installed Phoenix version, then diff port Threadline-specific files (`mix.exs` path dep, migrations, README).

```bash
cd examples
mix phx.new threadline_phoenix \
  --module ThreadlinePhoenix \
  --app threadline_phoenix \
  --database postgres \
  --adapter bandit \
  --no-html \
  --no-assets \
  --no-mailer \
  --no-dashboard \
  --no-gettext \
  --no-install
```

## Installation (Threadline capture + first audited table)

1. Install Hex deps and compile:

   ```bash
   mix deps.get
   mix compile
   ```

2. Ensure PostgreSQL is **already running and reachable** at the host/port in `config/dev.exs` (overridable with `DB_HOST` / `DB_PORT`). A quick check against compose is:

   ```bash
   pg_isready -h "${DB_HOST:-localhost}" -p "${DB_PORT:-5432}"
   ```

3. Create the application database the first time you work on a machine:

   ```bash
   mix ecto.create
   ```

4. Generate and apply Threadline base schema migrations, then add triggers for the reference `posts` table, then migrate:

   ```bash
   mix threadline.install
   mix threadline.gen.triggers --tables posts
   mix ecto.migrate
   ```

`mix threadline.gen.triggers` calls **`Mix.Task.run("app.config", [])`** first, so use the same **`MIX_ENV`** locally and in CI when regenerating trigger SQL; otherwise config-driven SQL may not match what you expect.

5. Install Sigra auth (controller mode, no Sigra org tables — help-desk owns tenancy):

   ```bash
   mix sigra.install Accounts User users --no-live --no-organizations --no-passkeys --no-admin --yes
   ```

   If the generator was already run on this checkout, skip the command above.

6. Apply all migrations and optional seeds:

   ```bash
   mix ecto.setup
   ```

7. (Optional) Load neutral synthetic seed rows:

   ```bash
   mix run priv/repo/seeds.exs
   ```

## Demo walkthrough data

After `mix ecto.setup`, load synthetic help-desk fiction:

```bash
mix demo.seed
```

Recover a clean walkthrough state (truncate demo tables + re-seed):

```bash
mix demo.reset
```

Credentials: see [DEMO_USERS.md](DEMO_USERS.md). Literals: [DEMO-MANIFEST.md](DEMO-MANIFEST.md).

`ecto.setup` does **not** run `demo.seed` automatically.

`mix ecto.reset` is schema/trigger recovery only — use `mix demo.reset` for the daily walkthrough loop.

## Sigra walkthrough URLs

After `mix phx.server` (see below), use these browser paths:

| Action | URL |
|--------|-----|
| Home (links when logged out) | `http://localhost:4000/` |
| Register | `http://localhost:4000/users/register` |
| Log in | `http://localhost:4000/users/log_in` |
| Log out | `POST` `http://localhost:4000/users/log_out` (while authenticated) |
| Dev email mailbox (confirmation) | `http://localhost:4000/dev/mailbox` |

Registration auto-provisions a help-desk organization membership for the new Sigra user id.

## `mix setup` (does not start Postgres)

`mix setup` runs **`deps.get` → `compile` → `ecto.setup`**. It **does not start PostgreSQL** for you — the server must already be reachable or database commands will fail with connection errors.

## Run the API

After migrations succeed:

```bash
mix phx.server
```

Or inside IEx:

```bash
iex -S mix phx.server
```

## Audited HTTP path (`POST /api/posts`)

The example wires **`Threadline.Plug`** with both **`actor_fn`** and
**`context_overrides_fn`** on the `:api` pipeline and exposes **`POST /api/posts`**,
which creates a row through **`ThreadlinePhoenix.Blog.create_post/2`** via
**`Threadline.Audit.transaction/3`** with correlation metadata and automatic
**`audit_transactions.action_id`** linkage so strict filters work (see **Correlation** below).
**`test/threadline_phoenix_web/posts_audit_path_test.exs`** proves capture sees
**`AuditChange`** rows for **`posts`** with **`AuditTransaction.actor_ref`**
populated.

In the shipped example, both callbacks are wired directly into `Threadline.Plug`:
**`Threadline.Integrations.Sigra.actor_ref_from_conn/1`** decides actor identity and
**`Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1`** fills additive
request metadata only when `x-correlation-id` is absent. In production, feed
Sigra-authenticated request state into the conn before the Threadline plug runs.
That is the narrow first-party reference path: soft-loaded, host-owned, and
proven here rather than generalized into a blanket Sigra compatibility promise.

### Authenticate before the audited API call

**`Threadline.Integrations.Sigra.actor_ref_from_conn/1`** reads Sigra state from
**`current_scope`**. The `:api` pipeline runs **`plug(:fetch_session)`** and
**`plug(:fetch_current_scope)`** before **`Threadline.Plug`** so a browser login
can populate that assign on **`POST /api/posts`**. This example does not ship API bearer tokens — your host owns authentication (see
**[../../guides/integrations/sigra.md](../../guides/integrations/sigra.md)**).

1. Run **`mix phx.server`** (after **`mix ecto.migrate`**).
2. Optional: **`mix demo.seed`** for walkthrough fiction — demo logins live in
   **[DEMO_USERS.md](DEMO_USERS.md)**.
3. Sign in at **`/users/log_in`** in your browser.
4. Copy the **`_threadline_phoenix_key`** session cookie from DevTools.
5. Send the audited request with **`-b '_threadline_phoenix_key=PASTE_FROM_BROWSER'`**.

**Expected with session:** **`201`** and **`audit_transaction_id`** in the JSON body.

**Without session:** **`500`** with **`missing actor`** is intentional on this
reference lane (capture ran, semantics rejected a missing actor). Production
hosts should fail earlier with their own **`401`**/**`403`** plugs.

**CI without a browser:** **`mix test test/threadline_phoenix_web/posts_audit_path_test.exs`**
— tests stage scope via **`sigra_conn/2`** in tests only.

```bash
curl -sS -X POST "http://localhost:4000/api/posts" \
  -H "content-type: application/json" \
  -H "x-request-id: $(uuidgen)" \
  -H "x-correlation-id: demo-corr" \
  -b '_threadline_phoenix_key=PASTE_FROM_BROWSER' \
  -d '{"post":{"title":"Hello","slug":"hello-demo-slug"}}'
```

## Incident JSON drill-down (`audit_transaction_id` → bundled incident)

Successful **`POST /api/posts`** responses include **`audit_transaction_id`** (the UUID of the **`audit_transactions`** row for that request’s database transaction). Call **`GET /api/audit_transactions/:id/changes`** with that UUID to fetch the curated incident bundle rendered from **`Threadline.incident_bundle/2`**: linked transaction/action context plus ordered changes with packaged **`change_diff`** payloads. See **`guides/domain-reference.md`** (anchor **`COMP-EXAMPLE-INCIDENT-JSON`**, subsection **Reference example: incident JSON**) for the canonical "which API first?" routing story and the lower-level building blocks behind this bundled default.

CI: **`ThreadlinePhoenixWeb.PostsIncidentJsonPathTest`**. **Security:**
the reference app now requires an authenticated actor before it serves the
drill-down endpoint. Hosts still need their own tenancy and policy checks
before exposing transaction drill-down in production.

Capture-only parity for the same request-level drill-down lives at
`mix threadline.incident <audit_transaction_id>`.

## Operator Surface

Threadline provides an optional LiveView-based operator UI that is mounted
directly in the host router. This reference app demonstrates the runnable,
secured `/audit` path without becoming the primary onboarding narrative.

For support language, treat this as a `sigra-reference` example layered on top
of the root library's broader `phoenix-surface` lane. The root library declares
optional Phoenix dependency ranges in `mix.exs`; this example app proves the
narrower resolved path it actually ships with Sigra `0.2.5`, Phoenix `1.8.5`,
Phoenix LiveView `1.1.28`, Phoenix HTML `4.3.0`, and Phoenix PubSub `2.2.0`.
Evidence access stays narrower still: `/audit/evidence` is a separately
authorized capability on this reference lane, not a blanket claim that every
mounted `/audit` path inherits evidence access automatically.

See `lib/threadline_phoenix_web/router.ex` for the end-to-end integration. The
operator surface lives at `/audit` because the router uses one shared operator
scope and pipeline, and the example authorizer uses one shared `%{assigns: assigns}`
callback instead of separate `%Plug.Conn{}` and `%Phoenix.LiveView.Socket{}`
heads. The same mount proves both lanes, but not with identical breadth:
admins get the full surface, while support operators get the current scoped
read-only proof for timeline, actor, transaction, and export denial through the
host-owned `scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3`
seam:

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

`pipeline :operator_browser` maps Sigra `current_scope` to help-desk-aware
`current_user` (org UUID + role) before `pipeline :operator_auth` requires an
authenticated operator user. `authorize_fn` acts as the final fail-closed gate. Admins
return `:ok`; support users return an opaque scope such as
`%{access: :support_read_only, organization_id: "org_123"}`. This is the
`phx.gen.auth`-style posture to copy into a host app: your app owns browser
auth first, then Threadline runs inside that boundary.

Because this mount provides `actor_fn`, the standard
`threadline_operator_surface/2` path auto-installs
`Threadline.OperatorSurface.SessionPlug` and carries the returned `ActorRef`
into LiveView automatically. No extra manual session plug is required for the
default `/audit` recipe.

Treat that single mount as the canonical shared operator recipe. It natively
supports both Admin and Support personas securely. By combining `authorize_fn`,
`export_authorize_fn`, and `scope_query_fn` on one tree, Threadline degrades
the UI gracefully for support operators. They remain on the same `/audit` path,
but see fewer records, cannot trigger exports, and still receive standard `403`
errors if they attempt direct HTTP access to restricted functionality. This
provides a seamless UX without the complexity of managing multiple router scopes.
On the current tree, the shared scoped `/audit` proof now includes
support-scoped row history / as-of on the same reference lane.

LiveView `live_session` / `on_mount` auth does not secure export controller
routes. Export denials stay HTTP-native `403`, so `export_authorize_fn` is the
primary and intended way to degrade export capability for support roles. Manual
`SessionPlug` composition is still available as an advanced escape hatch, but
it is no longer the primary story for the standard mount.

Coverage and policy surfaces stay admin/global. In this support lane, deny them
with `coverage_authorize_fn` / `policy_authorize_fn` and let the mounted
unsupported state route operators to `mix threadline.health.coverage` or `mix
threadline.policy.show` instead of silently bouncing them around.

Mounted `/audit/evidence` is separately gated via `evidence_authorize_fn`. Admins
reach the evidence LiveView; support users who can open the scoped `/audit`
timeline are **denied** on `/audit/evidence` (Unsupported View) and should use
the CLI fallback `mix threadline.evidence.show`.

On the repaired export lane, the operator surface still exposes one actor-owned
download action keyed by export job ID. Local storage stays app-served through
that controller route, adapter-backed storage resolves a backend-native URL only
after authorization, and the host app still owns Oban supervision even though
Threadline now validates configured adapters for static truth at startup.

Run `mix phx.server`, sign in as an admin or support user, and open
`http://localhost:4000/audit`. For the **reference-app maintainer walk**, use
[`./WALKTHROUGH.md`](./WALKTHROUGH.md). For integrator first-hour wiring, use
[`../../guides/getting-started-saas.md`](../../guides/getting-started-saas.md).
For the mount/auth/screens guide, use
[`../../guides/operator-surface.md`](../../guides/operator-surface.md).
Coverage and policy-drift parity stay available without the mounted surface via
`mix threadline.health.coverage` and `mix threadline.policy.show`. Incident
drill-down parity lives at `mix threadline.incident <audit_transaction_id>`.

## Historical reconstruction walkthrough

Copy-paste this when you want one row back as it existed at a point in time:

```elixir
as_of_at = DateTime.utc_now()

case Threadline.as_of(ThreadlinePhoenix.Post, post_id, as_of_at, repo: ThreadlinePhoenix.Repo) do
  {:ok, post} ->
    post

  {:error, :deleted_record} ->
    :deleted

  {:error, :before_audit_horizon} ->
    :no_history_yet
end
```

By default, `as_of/4` returns a map. Add `cast: true` when you want the current `ThreadlinePhoenix.Post` struct shape back instead:

```elixir
{:ok, post} =
  Threadline.as_of(ThreadlinePhoenix.Post, post_id, as_of_at,
    cast: true,
    repo: ThreadlinePhoenix.Repo
  )
```

Deleted rows stay explicit — do not treat `:deleted_record` as a current record.

## Correlation: HTTP → audit_actions → timeline

**Operator contract:** when you pass **`:correlation_id`** to **`Threadline.timeline/2`** or **`Threadline.export_json/2`**, Threadline applies a **strict** join: only **`audit_changes`** whose **`audit_transactions`** row is linked (**`audit_transactions.action_id`**) to an **`audit_actions`** row with that correlation id are returned. Headers such as **`x-correlation-id`** populate **`AuditContext`** at the edge; durable queryability requires **`Threadline.record_action/2`** in the **same** database transaction as the audited writes, as implemented in **`Blog.create_post/2`**. Timeline and export share the same filter vocabulary (see **`Threadline.Query`** and **LOOP-01** in **`CHANGELOG.md`**).

CI proof for the HTTP slice lives in **`ThreadlinePhoenixWeb.PostsCorrelationPathTest`** (`test/threadline_phoenix_web/posts_correlation_path_test.exs`), including both the explicit-header path and the no-header Sigra fallback path.

```elixir
filters = [
  table: "posts",
  correlation_id: "demo-corr",
  repo: ThreadlinePhoenix.Repo
]

# Same filters for export — NDJSON one JSON object per line
Threadline.export_json(filters, json_format: :ndjson)
# |> jq -r '.table_name'   # example: read a field from each NDJSON line
```

## Semantics in jobs

Trigger-backed **`audit_changes`** rows record **what** changed on each audited table. When row diffs are not enough for operators (intent, correlation across async work, or queue provenance), call **`Threadline.record_action/2`** in the **same** `Ecto.Repo.transaction/1` as the audited writes so semantics stay consistent with capture.

This repo’s concrete pattern is **`ThreadlinePhoenix.Workers.PostTouchWorker`** → **`ThreadlinePhoenix.Blog.touch_post_for_job/2`**, which uses **`Threadline.Audit.transaction/3`** with **`actor_ref:`** and **`action: {:post_title_refreshed_from_queue, Job.context_opts(args)}`**. See **`Threadline.Job`** in the library (`../../lib/threadline/job.ex`) for **`actor_ref_from_args/1`** and **`context_opts/1`**.

## Documentation & production adoption

- **[Production checklist](../../guides/production-checklist.md)** — operator-facing checks before you treat an environment as production-ready.
- **[Adoption pilot / STG backlog](../../guides/adoption-pilot-backlog.md)** — phased rollout and staging evidence expectations.

**Integrator responsibility:** your team owns the **host-class** staging topology matrix, evidence, and promotion criteria for *your* URLs and regions. Threadline’s CI and this example app prove **reference patterns** (capture, HTTP and job semantics, tests); they do **not** certify third-party staging hosts or production endpoints. Use your fork/PR workflow per **`CONTRIBUTING.md`** when you need project-specific evidence.

For **`POST /api/posts`**, the example links **`audit_transactions.action_id`** via **`Threadline.Audit.transaction/3`**, so **`:correlation_id`** filters match the rows operators expect.

## Tests

Create the dedicated test database once (default name **`threadline_phoenix_test`**, see `config/test.exs`):

```bash
createdb threadline_phoenix_test
```

Run the example suite:

```bash
MIX_ENV=test mix test
```

The tests ensure the repo can migrate and that the `posts` schema is available; use the same **`DB_HOST` / `DB_PORT`** values as in development when Postgres is not on `localhost:5432`.

## Learn more

- Threadline docs: <https://hexdocs.pm/threadline>
- Phoenix guides: <https://hexdocs.pm/phoenix/overview.html>
