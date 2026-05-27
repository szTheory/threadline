defmodule Mix.Tasks.Demo.Seed do
  @shortdoc "Plant deterministic demo fiction (orgs, tickets, audit history)"

  @moduledoc """
  Invokes `ThreadlinePhoenix.Demo.Seed.run/0` to plant walkthrough demo data.

  In `MIX_ENV=prod`, raises unless `DEMO_ALLOW_RESET=1` is set (same guard as
  `mix demo.reset`).
  """

  use Mix.Task

  @impl Mix.Task
  def run(_argv) do
    ThreadlinePhoenix.Demo.Reset.assert_dev_or_allowed!()
    Mix.Task.run("app.start")
    ThreadlinePhoenix.Demo.Seed.run()
  end
end
