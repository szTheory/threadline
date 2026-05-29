defmodule HexEvaluator.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [HexEvaluator.Repo]

    Supervisor.start_link(children, strategy: :one_for_one, name: HexEvaluator.Supervisor)
  end
end
