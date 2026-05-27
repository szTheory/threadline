defmodule Mix.Tasks.Demo.Reset do
  @shortdoc "Truncate demo tables and re-run demo.seed (dev/test walkthrough recovery)"

  @moduledoc """
  Truncates demo fiction tables and invokes `ThreadlinePhoenix.Demo.Seed.run/0`.

  Canonical walkthrough recovery is **`mix demo.reset`**. Use **`mix ecto.reset`**
  only when you need schema/trigger recovery (D-107-03c).

  In `MIX_ENV=prod`, raises unless `DEMO_ALLOW_RESET=1` is set.
  """

  use Mix.Task

  @impl Mix.Task
  def run(_argv) do
    ThreadlinePhoenix.Demo.Reset.assert_dev_or_allowed!()
    Mix.Task.run("app.start")
    ThreadlinePhoenix.Demo.Reset.run(skip_assert: true)
  end
end
