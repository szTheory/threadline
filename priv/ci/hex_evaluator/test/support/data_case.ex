defmodule HexEvaluator.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias HexEvaluator.Repo

      import Ecto
      import Ecto.Query
      import HexEvaluator.DataCase
    end
  end

  setup tags do
    HexEvaluator.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(HexEvaluator.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
