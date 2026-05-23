defmodule Threadline.Application do
  @moduledoc false

  use Application

  alias Threadline.Retention.Pruner

  @impl true
  def start(_type, args) do
    name = Keyword.get(args, :name, __MODULE__.Supervisor)
    Supervisor.start_link(children(), strategy: :one_for_one, name: name)
  end

  @doc false
  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start, [:normal, args]},
      type: :supervisor
    }
  end

  defp children do
    case retention_child() do
      nil -> []
      child -> [child]
    end
  end

  defp retention_child do
    retention = Application.get_env(:threadline, :retention, [])
    repo = Application.get_env(:threadline, :ecto_repos, []) |> List.first()

    if Keyword.get(retention, :enabled, false) and repo do
      {Pruner, pruner_opts(repo, retention)}
    end
  end

  defp pruner_opts(repo, retention) do
    [repo: repo]
    |> maybe_put(:interval_ms, Keyword.get(retention, :interval_ms))
    |> maybe_put(:sleep_ms, Keyword.get(retention, :sleep_ms))
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
