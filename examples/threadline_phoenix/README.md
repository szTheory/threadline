# ThreadlinePhoenix

Canonical **path-dependent** Phoenix reference app for the [`threadline`](https://github.com/szTheory/threadline) library. Treat the install, run, test, and reconstruction commands in this document as the runnable example contract.

## 🚀 Quick Start (Zero-Friction Docker Demo)

Want to see the Operator Surface and click around realistic walkthrough data immediately? You can spin up the entire demo environment (app, PostgreSQL, and seeded data) with a single command from the **repository root**:

```bash
# Run from the repository root (two levels up)
docker compose --profile demo up demo --build
```

The app will be available at **http://localhost:4000**.
Sign in with the seeded cross-org admin credentials:
- **Email:** `admin@example.com`
- **Password:** `password123456`

*(See [DEMO_USERS.md](DEMO_USERS.md) for other seeded roles like `closer@acme.example.com`)*.

Running multiple UI demos at once? Give each Compose stack a unique project
name and host ports:

```bash
COMPOSE_PROJECT_NAME=threadline-demo-a THREADLINE_DEMO_PORT=4100 THREADLINE_DB_PORT=5434 \
  docker compose --profile demo up demo --build
```

Compose keeps service DNS stable inside the stack (`postgres:5432`), while the
project name isolates containers, networks, and volumes. Local ports are bound
to `127.0.0.1` by default; see the root [`.env.example`](../../.env.example) for
all Docker overrides. Normal cleanup is:

```bash
docker compose down --remove-orphans
```

---

This app is the current `sigra-reference` lane: the maintained first-party
reference path for a Phoenix host that already uses Sigra. It proves a narrow
composition story through this example app, the companion guides, and repo
verification. It does not claim that arbitrary Sigra versions, arbitrary auth
layouts, or non-Phoenix hosts are supported automatically.

For the **reference-app maintainer walk**, start with
[`./WALKTHROUGH.md`](./WALKTHROUGH.md). Integrators wiring Threadline into their
own app should still use
[`../../guides/getting-started-saas.md`](../../guides/getting-started-saas.md).
Treat this README as the runnable proof artifact behind both paths.

## Prerequisites

- **Elixir** ~> 1.15 (see root `mix.exs` for the exact constraint used in CI)
- **Erlang/OTP** matching the Elixir version you install
- **PostgreSQL** with trigger support, reachable before you run database tasks

Optional: from the **repository root**, `docker compose up -d postgres` publishes Postgres on **`DB_PORT=5433`** by default (see root `docker-compose.yml` and `CONTRIBUTING.md`). When using that compose service, set **`DB_HOST`** / **`DB_PORT`** so this app’s `config/*.exs` resolves the same host and port (defaults remain `localhost` / `5432` if unset). The full Phoenix demo is behind the `demo` Compose profile.

## Choose your path

| Goal | Start here | Requires `mix demo.seed`? |
|------|------------|---------------------------|
| First audited write (`POST /api/posts`) on migrated DB | **Track A** | **No** |
| Maintainer walk, seeded operators, `/audit` exercises | **Track B** + [WALKTHROUGH.md](./WALKTHROUGH.md) | **Yes** |
| Threadline in your own Phoenix app | [getting-started-saas.md](../../guides/getting-started-saas.md) | N/A |

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

On a **generator-fresh** skeleton (not this committed checkout), add Threadline capture, triggers, and Sigra auth before migrate:

```bash
mix threadline.install
mix threadline.gen.triggers --tables posts
mix sigra.install Accounts User users --no-live --no-organizations --no-passkeys --no-admin --yes
mix ecto.migrate
```

`mix threadline.gen.triggers` calls **`Mix.Task.run("app.config", [])`** first, so use the same **`MIX_ENV`** locally and in CI when regenerating trigger SQL; otherwise config-driven SQL may not match what you expect.

## Base install (all paths)

> **Committed checkout:** **skip generators on a normal clean clone.** Migrations for Threadline capture, triggers, and Sigra auth are **already committed** — do **not** run `mix threadline.install`, `mix threadline.gen.triggers`, or `mix sigra.install` on a normal clone. Generators belong in [Regenerating the skeleton](#regenerating-the-skeleton-generator-contract) only.

1. Install Hex deps and compile:

   ```bash
   mix deps.get
   mix compile
   ```

2. Ensure PostgreSQL is **already running and reachable** at the host/port in `config/dev.exs` (overridable with `DB_HOST` / `DB_PORT`):

   ```bash
   pg_isready -h "${DB_HOST:-localhost}" -p "${DB_PORT:-5432}"
   ```

3. Create the application database the first time you work on a machine:

   ```bash
   mix ecto.create
   ```

4. Apply committed migrations (Threadline audit schema, help-desk tables, Sigra auth, triggers):

   ```bash
   mix ecto.migrate
   ```

5. Optional convenience bootstrap — create, migrate, and run neutral **`priv/repo/seeds.exs`** (two posts; not walkthrough fiction):

   ```bash
   mix ecto.setup
   ```

   Running `mix run priv/repo/seeds.exs` separately is redundant if `ecto.setup` already ran.

**Seed terminology:** **`priv/repo/seeds.exs`** runs **neutral** seeds (two posts). **`mix demo.seed`** loads **walkthrough fiction** — never use “seed” alone when you mean demo fiction.

## Track A — First audited write

After [Base install](#base-install-all-paths):

1. Start the server: **`mix phx.server`**
2. Sign in at **`/users/log_in`** in your browser (register first if needed).
3. Follow **[Authenticate before the audited API call](#authenticate-before-the-audited-api-call)** under **Audited HTTP path** — copy the **`_threadline_phoenix_key`** cookie and send the documented curl.
4. Optional: **`GET /api/audit_transactions/:id/changes`** with the returned **`audit_transaction_id`**.

This track **does not require `mix demo.seed`**.

## Track B — Walkthrough fiction

After [Base install](#base-install-all-paths), follow **[WALKTHROUGH.md](./WALKTHROUGH.md)** for the maintainer dry-run:

```bash
mix demo.seed
```

Recover a clean walkthrough state:

```bash
mix demo.reset
```

Credentials: [DEMO_USERS.md](DEMO_USERS.md).

### Tour in five minutes

```bash
mix setup
mix demo.seed
mix phx.server
```

Sign in as **`admin@example.com`** / **`password123456`**, then open:

| Surface | URL |
|---------|-----|
| Timeline + correlation filter | `http://localhost:4000/audit?correlation_id=walk-acme-4521-close` |
| Evidence plane | `http://localhost:4000/audit/evidence` |
| Redaction policy drift | `http://localhost:4000/audit/policy/redaction` |
| Trigger coverage | `http://localhost:4000/audit/coverage` |

Automated ConnCase proofs: `walkthrough_happy_path_test.exs`, `walkthrough_evidence_test.exs`, `track_a_golden_path_test.exs`. Optional browser suite: `mix verify.example_browser` from the repo root. See [`../../guides/adoption-evidence-playbook.md`](../../guides/adoption-evidence-playbook.md).

## Demo walkthrough data

**Track B** and **[WALKTHROUGH.md](./WALKTHROUGH.md)** own walkthrough fiction. See **[Mix task reference](#mix-task-reference)** for how **`ecto.setup`**, **`demo.seed`**, and **`demo.reset`** differ. Literals: [DEMO-MANIFEST.md](DEMO-MANIFEST.md).

`ecto.setup` does **not** run `demo.seed` automatically.

`mix ecto.reset` is schema/trigger recovery only — use `mix demo.reset` for the daily walkthrough loop.

## Mix task reference

| Task | Runs | Demo fiction? |
|------|------|---------------|
| `mix setup` | deps + compile + `ecto.setup` | No |
| `mix ecto.setup` | create + migrate + neutral `priv/repo/seeds.exs` | No |
| `mix ecto.reset` | drop + `ecto.setup` | No |
| `mix demo.seed` | walkthrough fiction | **Yes** |
| `mix demo.reset` | truncate demo tables + re-seed fiction | **Yes** |

> **Greenfield integrators:** wiring Threadline into your own Phoenix app follows a different generator order. Start with **[getting-started-saas.md](../../guides/getting-started-saas.md)** — `threadline.install` → `threadline.gen.triggers --tables …` → `ecto.migrate` → Sigra when adopting the sigra-reference lane.

## Mix task ownership

**Ecto** owns the database object and applying SQL migrations. **Threadline** owns audit schema and trigger **generators**. **Sigra** owns auth **generators**. **This example** owns neutral **`priv/repo/seeds.exs`** and **`demo.*`** walkthrough fiction.

| Task | Owns | When to run | Don't confuse with |
|------|------|-------------|-------------------|
| `mix ecto.create` | Database object | First machine / missing DB | `threadline.install` (files, not DB) |
| `mix threadline.install` | Migration files: capture function, audit tables | Greenfield / new base migrations | `ecto.migrate`; `ecto.create` |
| `mix threadline.gen.triggers --tables …` | Per-table trigger migrations; reads `app.config` | After install; same `MIX_ENV` as CI | `threadline.install`; auditing `audit_*` tables |
| `mix ecto.migrate` | Applies all pending SQL | After any new migration file | Generator tasks (emit only) |
| `mix sigra.install …` | Sigra auth migrations + modules | Generator-fresh app without committed Sigra migrations | `threadline.*`; **skip on this checkout** |
| `mix ecto.setup` | create + migrate + `priv/repo/seeds.exs` | Convenience bootstrap | `demo.seed`; does **not** install triggers by itself |
| `mix demo.seed` | Walkthrough fiction | After migrate; WALKTHROUGH / `/audit` | `ecto.setup`; not auto-run |
| `mix demo.reset` | Truncate demo tables + re-seed fiction | Walkthrough recovery | `ecto.reset` |
| `mix ecto.reset` | drop + `ecto.setup` | Schema/trigger recovery | `demo.reset` |
| `mix setup` | deps + compile + `ecto.setup` | Quick bootstrap after Postgres up | Starting Postgres; `demo.seed` |

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
      coverage_authorize_fn: &ThreadlinePhoenixWeb.Router.my_coverage_authorize_fn/1,
      policy_authorize_fn: &ThreadlinePhoenixWeb.Router.my_policy_authorize_fn/1,
      scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
      schemas: %{
        "tickets" => ThreadlinePhoenix.HelpDesk.Ticket,
        "ticket_replies" => ThreadlinePhoenix.HelpDesk.TicketReply
      },
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
