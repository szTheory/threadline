ExUnit.start()

repo = ThreadlinePhoenix.Repo
config = repo.config()

case Ecto.Adapters.Postgres.storage_up(config) do
  :ok ->
    :ok

  {:error, :already_up} ->
    :ok

  {:error, reason} ->
    db = config[:database]
    host = config[:hostname] || "localhost"

    raise """
    ThreadlinePhoenix tests: could not ensure PostgreSQL database #{inspect(db)} exists.

    #{if is_binary(reason), do: reason, else: inspect(reason)}

    Hint: start PostgreSQL (e.g. `docker compose up -d` from the repo root) and ensure \
    DB_HOST (default #{inspect(host)}), DB_PORT, username, and password match config/test.exs.
    """
end

Ecto.Migrator.run(repo, :up, all: true)

# Threadline's export cleanup child can run before this host migration creates
# `threadline_export_jobs`. Restart it against the migrated schema before tests
# exercise export task supervision (mirrors the package test bootstrap).
:ok = Application.stop(:threadline)
{:ok, _} = Application.ensure_all_started(:threadline)

# TWIN-01 shape fixtures (Phase 212): applied only for the ExUnit suite, from
# a migrations path outside priv/repo/migrations, so `mix ecto.migrate` (run
# by e2e/run-e2e.sh against the same threadline_phoenix_test database) never
# sees them and the frozen browser-lane screenshot baselines stay unaffected.
# Rolled back in ExUnit.after_suite so the shared test database is clean
# again once the suite finishes.
shape_path = Path.expand("../priv/shape_fixtures/migrations", __DIR__)
Ecto.Migrator.run(repo, shape_path, :up, all: true)

ExUnit.after_suite(fn _ ->
  Ecto.Adapters.SQL.Sandbox.mode(repo, :auto)
  Ecto.Migrator.run(repo, shape_path, :down, all: true)
end)

Ecto.Adapters.SQL.Sandbox.mode(ThreadlinePhoenix.Repo, :manual)
