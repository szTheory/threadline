defmodule Threadline.Retention.Pruner do
  @moduledoc """
  A GenServer that schedules and executes background retention pruning.

  Ensures only one node in the cluster runs the pruning process concurrently
  using PostgreSQL advisory locks.
  """

  use GenServer
  require Logger
  import Ecto.Query

  alias Threadline.Governance.RetentionRun

  @lock_key :erlang.phash2("threadline_retention_pruner")
  @default_interval_ms :timer.minutes(60)
  @default_sleep_ms 50

  @doc """
  Starts the pruner GenServer.

  ## Options
  - `:repo` (required) - The Ecto.Repo to use for DB operations.
  - `:interval_ms` (optional) - Time between pruning attempts (default: 60 minutes).
  - `:sleep_ms` (optional) - Sleep time between batches to yield DB locks (default: 50 ms).
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Triggers an immediate prune on the supervised runtime path.
  """
  def trigger do
    if started?() do
      GenServer.cast(__MODULE__, :prune)
      :ok
    else
      {:error, :not_started}
    end
  end

  @doc """
  Returns whether the named pruner runtime is currently available.
  """
  def started? do
    Process.whereis(__MODULE__) != nil
  end

  @impl true
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    interval_ms = Keyword.get(opts, :interval_ms, @default_interval_ms)
    sleep_ms = Keyword.get(opts, :sleep_ms, @default_sleep_ms)

    # Clean up any abandoned runs (e.g. from node crashes)
    cutoff = DateTime.utc_now() |> DateTime.add(-24, :hour) |> DateTime.truncate(:microsecond)

    from(r in RetentionRun,
      where: r.status == "running" and r.started_at < ^cutoff
    )
    |> repo.update_all(
      set: [
        status: "failed",
        error_message: "Abandoned",
        updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
      ]
    )

    schedule_next(interval_ms)

    {:ok, %{repo: repo, interval_ms: interval_ms, sleep_ms: sleep_ms}}
  end

  @impl true
  def handle_cast(:prune, state) do
    # Trigger an immediate purge run
    send(self(), :run_purge)
    {:noreply, state}
  end

  @impl true
  def handle_info(:run_purge, state) do
    %{repo: repo, interval_ms: interval_ms, sleep_ms: sleep_ms} = state

    repo.checkout(fn ->
      if acquire_lock(repo) do
        try do
          Threadline.Retention.purge(repo: repo, sleep_ms: sleep_ms)
        after
          release_lock(repo)
        end
      else
        Logger.debug("threadline_retention_pruner lock held elsewhere, skipping purge")
      end
    end)

    schedule_next(interval_ms)
    {:noreply, state}
  end

  defp schedule_next(interval_ms) do
    Process.send_after(self(), :run_purge, interval_ms)
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
