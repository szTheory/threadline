defmodule Threadline.Application do
  @moduledoc false

  use Application

  alias Threadline.Retention.Pruner

  @impl true
  def start(_type, args) do
    with :ok <- validate_configured_adapters() do
      name = Keyword.get(args, :name, __MODULE__.Supervisor)
      Supervisor.start_link(children(), strategy: :one_for_one, name: name)
    end
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
    [retention_child(), export_task_supervisor_child(), export_cleanup_child()]
    |> Enum.reject(&is_nil/1)
  end

  defp validate_configured_adapters do
    if default_repo() do
      with :ok <- validate_adapter(:storage_adapter, Threadline.Storage.Local),
           :ok <- validate_adapter(:export_queue_adapter, Threadline.ExportQueue.TaskAdapter) do
        :ok
      end
    else
      :ok
    end
  end

  defp validate_adapter(config_key, default_adapter) do
    adapter = Application.get_env(:threadline, config_key, default_adapter)
    opts = Application.get_env(:threadline, adapter, [])

    case adapter.init(opts) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, {config_key, reason}}
    end
  rescue
    error ->
      {:error, {config_key, Exception.message(error)}}
  end

  defp retention_child do
    retention = Application.get_env(:threadline, :retention, [])
    repo = default_repo()

    if Keyword.get(retention, :enabled, false) and repo do
      {Pruner, pruner_opts(repo, retention)}
    end
  end

  defp export_task_supervisor_child do
    if default_repo() do
      {Task.Supervisor, name: Threadline.Export.TaskSupervisor}
    end
  end

  defp export_cleanup_child do
    repo = default_repo()
    exports = Application.get_env(:threadline, :exports, [])

    if repo do
      {Threadline.Export.CleanupTask, export_cleanup_opts(repo, exports)}
    end
  end

  defp pruner_opts(repo, retention) do
    [repo: repo]
    |> maybe_put(:interval_ms, Keyword.get(retention, :interval_ms))
    |> maybe_put(:sleep_ms, Keyword.get(retention, :sleep_ms))
  end

  defp export_cleanup_opts(repo, exports) do
    [repo: repo]
    |> maybe_put(:interval_ms, Keyword.get(exports, :cleanup_interval_ms))
    |> maybe_put(:stale_running_cutoff_hours, Keyword.get(exports, :stale_running_cutoff_hours))
  end

  defp default_repo do
    Application.get_env(:threadline, :ecto_repos, []) |> List.first()
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
