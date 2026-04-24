ExUnit.start()

topology_pooler? = System.get_env("THREADLINE_PGBOUNCER_TOPOLOGY") == "1"

# Topology tests need PgBouncer + bootstrap DDL; keep them out of default `mix test`.
exclude = if(topology_pooler?, do: [], else: [pgbouncer_topology: true])
ExUnit.configure(exclude: exclude)

repo = Threadline.Test.Repo
config = repo.config()

unless topology_pooler? do
  case Ecto.Adapters.Postgres.storage_up(config) do
    :ok ->
      :ok

    {:error, :already_up} ->
      :ok

    {:error, reason} ->
      db = config[:database]
      host = config[:hostname] || "localhost"

      raise """
      Threadline tests: could not ensure PostgreSQL database #{inspect(db)} exists.

      #{if is_binary(reason), do: reason, else: inspect(reason)}

      Hint: start PostgreSQL (e.g. `docker compose up -d` from the repo root) and ensure \
      DB_HOST (default #{inspect(host)}), username, and password match config/test.exs.
      """
  end
end

{:ok, _} = repo.start_link()

unless topology_pooler? do
  Ecto.Migrator.run(repo, :up, all: true)
end
