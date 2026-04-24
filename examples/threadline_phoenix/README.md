# ThreadlinePhoenix

Canonical **path-dependent** Phoenix reference app for the [`threadline`](https://github.com/szTheory/threadline) library. Mix commands in this document are meant to be run **from `examples/threadline_phoenix/`**; the dependency `{:threadline, path: "../.."}` points at the **repository root** (two levels up from this directory).

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
