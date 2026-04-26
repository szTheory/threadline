# ThreadlinePhoenix

Canonical **path-dependent** Phoenix reference app for the [`threadline`](https://github.com/szTheory/threadline) library. Treat the install, run, test, and reconstruction commands in this document as the runnable example contract. Mix commands in this document are meant to be run **from `examples/threadline_phoenix/`**; the dependency `{:threadline, path: "../.."}` points at the **repository root** (two levels up from this directory).

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

5. (Optional) Load neutral synthetic seed rows:

   ```bash
   mix run priv/repo/seeds.exs
   ```

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

The example wires **`Threadline.Plug`** on the `:api` pipeline and exposes **`POST /api/posts`**, which creates a row through **`ThreadlinePhoenix.Blog.create_post/2`** inside a single **`Repo.transaction`** with a transaction-local **`threadline.actor_ref`** GUC before insert, then **`Threadline.record_action/2`** with correlation metadata and a link from **`audit_transactions.action_id`** to that action so strict filters work (see **Correlation** below). **`test/threadline_phoenix_web/posts_audit_path_test.exs`** proves capture sees **`AuditChange`** rows for **`posts`** with **`AuditTransaction.actor_ref`** populated.

In production, replace the synthetic **`actor_fn`** (see `ThreadlinePhoenix.AuditActor`) with one derived from your auth layer.

## Incident JSON drill-down (`audit_transaction_id` → changes)

Successful **`POST /api/posts`** responses include **`audit_transaction_id`** (the UUID of the **`audit_transactions`** row for that request’s database transaction). Call **`GET /api/audit_transactions/:id/changes`** with that UUID to list every **`AuditChange`** in stable library order (**`Threadline.audit_changes_for_transaction/2`**) and a JSON-ready **`change_diff`** per row (**`Threadline.change_diff/2`**). See **`guides/domain-reference.md`** (anchor **`COMP-EXAMPLE-INCIDENT-JSON`**, subsection **Reference example: incident JSON**).

CI: **`ThreadlinePhoenixWeb.PostsIncidentJsonPathTest`**. **Security:** add authorization (and usually tenancy checks) before exposing transaction drill-down in production; this example stays intentionally minimal.

## Historical reconstruction walkthrough

Copy-paste this when you want one row back as it existed at a point in time:

```elixir
as_of_at = DateTime.utc_now()

case Threadline.as_of(ThreadlinePhoenix.Post, post_id, as_of: as_of_at, repo: ThreadlinePhoenix.Repo) do
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
  Threadline.as_of(ThreadlinePhoenix.Post, post_id,
    as_of: as_of_at,
    cast: true,
    repo: ThreadlinePhoenix.Repo
  )
```

Deleted rows stay explicit — do not treat `:deleted_record` as a current record.

## Correlation: HTTP → audit_actions → timeline

**Operator contract:** when you pass **`:correlation_id`** to **`Threadline.timeline/2`** or **`Threadline.export_json/2`**, Threadline applies a **strict** join: only **`audit_changes`** whose **`audit_transactions`** row is linked (**`audit_transactions.action_id`**) to an **`audit_actions`** row with that correlation id are returned. Headers such as **`x-correlation-id`** populate **`AuditContext`** at the edge; durable queryability requires **`Threadline.record_action/2`** in the **same** database transaction as the audited writes, as implemented in **`Blog.create_post/2`**. Timeline and export share the same filter vocabulary (see **`Threadline.Query`** and **LOOP-01** in **`CHANGELOG.md`**).

CI proof for the HTTP slice lives in **`ThreadlinePhoenixWeb.PostsCorrelationPathTest`** (`test/threadline_phoenix_web/posts_correlation_path_test.exs`).

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

This repo’s concrete pattern is **`ThreadlinePhoenix.Workers.PostTouchWorker`** → **`ThreadlinePhoenix.Blog.touch_post_for_job/2`**: the worker passes a serialized **`actor_ref`** map (and optional correlation metadata) on the job args, merges **`job_id`** from the **`Oban.Job`**, then runs GUC + post update + **`record_action(:post_title_refreshed_from_queue, …)`** once. See **`Threadline.Job`** in the library (`../../lib/threadline/job.ex`) for **`actor_ref_from_args/1`** and **`context_opts/1`**.

## Documentation & production adoption

- **[Production checklist](../../guides/production-checklist.md)** — operator-facing checks before you treat an environment as production-ready.
- **[Adoption pilot / STG backlog](../../guides/adoption-pilot-backlog.md)** — phased rollout and staging evidence expectations.

**Integrator responsibility:** your team owns the **host-class** staging topology matrix, evidence, and promotion criteria for *your* URLs and regions. Threadline’s CI and this example app prove **reference patterns** (capture, HTTP and job semantics, tests); they do **not** certify third-party staging hosts or production endpoints. Use your fork/PR workflow per **`CONTRIBUTING.md`** when you need project-specific evidence.

For **`POST /api/posts`**, the example sets **`audit_transactions.action_id`** in the same transaction as **`record_action`**, so **`:correlation_id`** filters match the rows operators expect.

Example request (include **`x-request-id`** for traceability; no credential-shaped demo values):

```bash
curl -sS -X POST "http://localhost:4000/api/posts" \
  -H "content-type: application/json" \
  -H "x-request-id: $(uuidgen)" \
  -H "x-correlation-id: demo-corr" \
  -d '{"post":{"title":"Hello","slug":"hello-demo-slug"}}'
```

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
