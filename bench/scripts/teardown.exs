# Run with: MIX_ENV=test mix run scripts/teardown.exs

unless Mix.env() == :test do
  IO.puts(:stderr, "Use MIX_ENV=test")
  System.halt(1)
end

{:ok, _} = Application.ensure_all_started(:postgrex)
{:ok, _} = Application.ensure_all_started(:ecto_sql)

# Ensure threadline is started to load the Repo
{:ok, _} = Application.ensure_all_started(:threadline)

# Start your target Repo
{:ok, pid} = Threadline.Test.Repo.start_link()

try do
  IO.puts("Threadline: tearing down benchmark data...")

  # Truncate tables cleanly
  Ecto.Adapters.SQL.query!(
    Threadline.Test.Repo,
    "TRUNCATE audit_changes, audit_transactions CASCADE"
  )

  IO.puts("Threadline: benchmark teardown complete")
after
  GenServer.stop(pid, :normal, :infinity)
end
