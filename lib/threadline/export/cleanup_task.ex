defmodule Threadline.Export.CleanupTask do
  @moduledoc """
  A GenServer that periodically cleans up expired export jobs and abandons
  jobs that have been stuck in the "running" state for too long.
  """
  use GenServer
  require Logger
  import Ecto.Query

  alias Threadline.Governance.ExportJob

  @lock_key :erlang.phash2("threadline_export_cleanup")
  @default_interval_ms :timer.minutes(60)
  @default_stale_running_cutoff_hours 24
  @default_retention_ttl_hours 24 * 7
  @bootstrap_retry_ms 1_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    interval_ms = Keyword.get(opts, :interval_ms, @default_interval_ms)

    stale_running_cutoff_hours =
      Keyword.get(opts, :stale_running_cutoff_hours, @default_stale_running_cutoff_hours)

    send(self(), :bootstrap_reconcile)
    schedule_next(interval_ms)

    {:ok,
     %{
       repo: repo,
       interval_ms: interval_ms,
       stale_running_cutoff_hours: stale_running_cutoff_hours
     }}
  end

  @impl true
  def handle_info(:bootstrap_reconcile, state) do
    if repo_started?(state.repo) do
      reconcile_abandoned_runs(state.repo, state.stale_running_cutoff_hours)
    else
      Process.send_after(self(), :bootstrap_reconcile, @bootstrap_retry_ms)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:run_cleanup, state) do
    %{repo: repo, interval_ms: interval_ms} = state

    if repo_started?(repo) do
      repo.checkout(fn ->
        if acquire_lock(repo) do
          try do
            perform_cleanup(repo)
          after
            release_lock(repo)
          end
        else
          Logger.debug("threadline_export_cleanup lock held elsewhere, skipping cleanup")
        end
      end)
    end

    schedule_next(interval_ms)
    {:noreply, state}
  end

  defp perform_cleanup(repo) do
    cutoff = now()

    query =
      from(j in ExportJob,
        where: j.status in ["completed", "failed"],
        where: not is_nil(j.expires_at) and j.expires_at < ^cutoff
      )

    expired_jobs = repo.all(query)

    for job <- expired_jobs do
      if job.file_path do
        storage_adapter =
          Application.get_env(:threadline, :storage_adapter, Threadline.Storage.Local)

        storage_adapter.delete(job.file_path)
      end

      repo.delete!(job)
    end
  end

  defp schedule_next(interval_ms) do
    Process.send_after(self(), :run_cleanup, interval_ms)
  end

  defp reconcile_abandoned_runs(repo, stale_running_cutoff_hours) do
    cutoff = now() |> DateTime.add(-stale_running_cutoff_hours, :hour)

    from(j in ExportJob,
      where: j.status == "running" and j.started_at < ^cutoff
    )
    |> repo.update_all(
      set: [
        status: "failed",
        error_message: "Abandoned",
        expires_at: terminal_expiry(),
        updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
      ]
    )
  end

  defp acquire_lock(repo) do
    %{rows: [[acquired]]} =
      Ecto.Adapters.SQL.query!(repo, "SELECT pg_try_advisory_lock($1)", [@lock_key])

    acquired
  end

  defp release_lock(repo) do
    Ecto.Adapters.SQL.query!(repo, "SELECT pg_advisory_unlock($1)", [@lock_key])
  end

  defp terminal_expiry do
    now()
    |> DateTime.add(retention_ttl_seconds(), :second)
  end

  defp retention_ttl_seconds do
    Application.get_env(:threadline, :exports, [])
    |> Keyword.get(:retention_ttl_hours, @default_retention_ttl_hours)
    |> Kernel.*(60 * 60)
  end

  defp repo_started?(repo) do
    is_atom(repo) and is_pid(Process.whereis(repo))
  end

  defp now do
    DateTime.utc_now() |> DateTime.truncate(:microsecond)
  end
end
