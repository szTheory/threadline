defmodule Mix.Tasks.Threadline.VerifyTopology do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs PgBouncer topology ExUnit tags (requires THREADLINE_PGBOUNCER_TOPOLOGY=1)"

  @impl Mix.Task
  def run(args) do
    unless System.get_env("THREADLINE_PGBOUNCER_TOPOLOGY") == "1" do
      Mix.raise(
        "THREADLINE_PGBOUNCER_TOPOLOGY=1 is required (DB_* must point at PgBouncer transaction pool). " <>
          "See verify-pgbouncer-topology job in .github/workflows/ci.yml."
      )
    end

    Mix.Task.run("test", ["--only", "pgbouncer_topology"] ++ args)
  end
end
