# Run with:
#   MIX_ENV=test DB_HOST=localhost DB_PORT=<direct_postgres_port> THREADLINE_TOPOLOGY_BOOTSTRAP=1 mix run priv/ci/topology_bootstrap.exs
#
# Applies Ecto migrations and pooler-topology fixture DDL on **direct** Postgres
# (PgBouncer transaction mode cannot run DDL).

unless System.get_env("THREADLINE_TOPOLOGY_BOOTSTRAP") == "1" do
  IO.puts(:stderr, "Set THREADLINE_TOPOLOGY_BOOTSTRAP=1")
  System.halt(1)
end

unless Mix.env() == :test do
  IO.puts(:stderr, "Use MIX_ENV=test")
  System.halt(1)
end

table = "threadline_pooler_topology_ctx"

{:ok, _} = Application.ensure_all_started(:postgrex)
{:ok, _} = Application.ensure_all_started(:ecto_sql)

{:ok, pid} = Threadline.Test.Repo.start_link()

try do
  Ecto.Migrator.run(Threadline.Test.Repo, :up, all: true)

  Threadline.Test.Repo.query!("""
  CREATE TABLE IF NOT EXISTS #{table} (
    id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name  text NOT NULL,
    value integer
  )
  """)

  Threadline.Test.Repo.query!(Threadline.Capture.TriggerSQL.drop_trigger(table))
  Threadline.Test.Repo.query!(Threadline.Capture.TriggerSQL.create_trigger(table))

  IO.puts("Threadline: topology bootstrap OK (migrations + #{table})")
after
  GenServer.stop(pid, :normal, :infinity)
end
