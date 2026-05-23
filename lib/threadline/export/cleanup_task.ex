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

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    interval_ms = Keyword.get(opts, :interval_ms, @default_interval_ms)

    # Clean up any abandoned runs (e.g. from node crashes)
    cutoff = DateTime.utc_now() |> DateTime.add(-24, :hour) |> DateTime.truncate(:microsecond)

    from(j in ExportJob,
      where: j.status == "running" and j.started_at < ^cutoff
    )
    |> repo.update_all(
      set: [
        status: "failed",
        error_message: "Abandoned",
        updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
      ]
    )

    schedule_next(interval_ms)

    {:ok, %{repo: repo, interval_ms: interval_ms}}
  end

  @impl true
  def handle_info(:run_cleanup, state) do
    %{repo: repo, interval_ms: interval_ms} = state

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

    schedule_next(interval_ms)
    {:noreply, state}
  end

  defp perform_cleanup(repo) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    # Find expired jobs
    query = from(j in ExportJob, where: j.expires_at < ^now)
    expired_jobs = repo.all(query)

    for job <- expired_jobs do
      if job.file_path do
        storage_adapter = Application.get_env(:threadline, :storage_adapter, Threadline.Storage.Local)
        storage_adapter.delete(job.file_path)
      end
      repo.delete!(job)
    end
  end

  defp schedule_next(interval_ms) do
    Process.send_after(self(), :run_cleanup, interval_ms)
  end

  defp acquire_lock(repo) do
    %{rows: [[acquired]]} =
      Ecto.Adapters.SQL.query!(repo, "SELECT pg_try_advisory_lock($1)", [@lock_key])

    acquired
  end

  defp release_lock(repo) do
    Ecto.Adapters.SQL.query!(repo, "SELECT pg_advisory_unlock($1)", [@lock_key])
  end
end
