defmodule ThreadlinePhoenix.Demo.Reset do
  @moduledoc """
  Truncates demo fiction tables and re-runs `ThreadlinePhoenix.Demo.Seed.run/0`.

  Canonical walkthrough recovery is **`mix demo.reset`**. Use **`mix ecto.reset`**
  only when you need schema/trigger recovery (D-107-03c).

  In `MIX_ENV=prod`, raises unless `DEMO_ALLOW_RESET=1` is set.
  """

  alias ThreadlinePhoenix.{Demo, Repo}

  @doc """
  Truncates `@demo_tables` then invokes `Demo.Seed.run/0`.
  """
  @spec run(keyword()) :: :ok
  def run(opts \\ []) do
    unless Keyword.get(opts, :skip_assert, false) do
      assert_dev_or_allowed!()
    end

    Repo.query!(Demo.Tables.truncate_sql())
    Demo.Seed.run()
    :ok
  end

  @doc """
  Raises in `:prod` unless `DEMO_ALLOW_RESET=1` (T-107-03).

  Called from `mix demo.reset` before `app.start` so production fails fast
  without requiring database configuration.
  """
  @spec assert_dev_or_allowed!(atom()) :: :ok
  def assert_dev_or_allowed!(env \\ Mix.env()) do
    if env == :prod and System.get_env("DEMO_ALLOW_RESET") != "1" do
      raise RuntimeError, prod_reset_message()
    end

    :ok
  end

  defp prod_reset_message do
    "demo.reset: in MIX_ENV=prod set DEMO_ALLOW_RESET=1 to confirm this destructive operation."
  end
end
