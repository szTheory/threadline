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

Ecto.Adapters.SQL.Sandbox.mode(ThreadlinePhoenix.Repo, :manual)
