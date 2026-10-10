defmodule Threadline.Retention.Pruner do
  @moduledoc false

  use GenServer
  require Logger
  import Ecto.Query

  alias Ecto.Adapters.SQL
  alias Threadline.Governance.RetentionRun
  alias Threadline.StorageSchema

  @lock_key :erlang.phash2("threadline_retention_pruner")
  @acceptance_lock_prefix :erlang.phash2("threadline_retention_acceptance")
  @default_interval_ms :timer.minutes(60)
  @default_sleep_ms 50
  @lock_retry_ms 100
  @run_id_key {Threadline.Retention, :accepted_run_id}

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
    case Process.whereis(__MODULE__) do
      nil ->
        {:error, :not_started}

      pid ->
        try do
          GenServer.call(pid, :prune)
        catch
          :exit, {:noproc, _} -> {:error, :not_started}
        end
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
    storage_schema = StorageSchema.get(opts)
    storage_opts = StorageSchema.repo_opts(storage_schema: storage_schema)

    # Clean up abandoned accepted runs (e.g. from node crashes).
    cutoff = DateTime.utc_now() |> DateTime.add(-24, :hour) |> DateTime.truncate(:microsecond)

    from(r in RetentionRun,
      where:
        (r.status == "running" and r.started_at < ^cutoff) or
          (r.status == "queued" and r.inserted_at < ^cutoff)
    )
    |> repo.update_all(
      [
        set: [
          status: "failed",
          error_message: "Abandoned",
          completed_at: DateTime.utc_now(:microsecond),
          updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
        ]
      ],
      storage_opts
    )

    schedule_next(interval_ms)

    {:ok,
     %{
       repo: repo,
       interval_ms: interval_ms,
       sleep_ms: sleep_ms,
       storage_schema: storage_schema,
       storage_opts: storage_opts
     }}
  end

  @impl true
  def handle_call(:prune, _from, state) do
    {:reply, accept_or_coalesce(state), state}
  end

  @impl true
  def handle_info(:run_purge, state) do
    _ = accept_or_coalesce(state)
    schedule_next(state.interval_ms)
    {:noreply, state}
  end

  def handle_info({:execute, run_id}, state) do
    %{repo: repo, sleep_ms: sleep_ms, storage_schema: storage_schema, storage_opts: storage_opts} =
      state

    case Task.start(fn ->
           execute_when_lock_available(repo, run_id, sleep_ms, storage_schema, storage_opts)
         end) do
      {:ok, _pid} ->
        :ok

      {:error, reason} ->
        Logger.error("threadline retention worker could not start", reason: inspect(reason))
    end

    {:noreply, state}
  end

  defp accept_or_coalesce(state) do
    %{repo: repo, storage_schema: storage_schema, storage_opts: storage_opts} = state

    result =
      repo.transaction(
        fn ->
          SQL.query!(repo, "SELECT pg_advisory_xact_lock($1)", [
            acceptance_lock_key(storage_schema)
          ])

          active =
            repo.one(
              from(r in RetentionRun,
                where: r.status in ["queued", "running"],
                order_by: [desc: r.inserted_at],
                limit: 1
              ),
              storage_opts
            )

          case active do
            %RetentionRun{} = run ->
              {:active, run}

            nil ->
              run =
                repo.insert!(
                  RetentionRun.changeset(%RetentionRun{}, %{
                    status: "queued",
                    deleted_count: 0
                  }),
                  storage_opts
                )

              {:created, run}
          end
        end,
        storage_opts
      )

    case result do
      {:ok, {:created, run}} ->
        send(self(), {:execute, run.id})
        :ok

      {:ok, {:active, _run}} ->
        :ok

      {:error, _reason} ->
        {:error, :unavailable}
    end
  rescue
    exception ->
      Logger.warning("threadline retention acceptance failed",
        reason: inspect(exception.__struct__)
      )

      {:error, :unavailable}
  end

  defp execute_when_lock_available(repo, run_id, sleep_ms, storage_schema, storage_opts) do
    acquired? =
      repo.checkout(fn ->
        if acquire_lock(repo) do
          previous_run_id = Process.put(@run_id_key, run_id)

          try do
            Threadline.Retention.purge(
              repo: repo,
              sleep_ms: sleep_ms,
              storage_schema: storage_schema
            )
          after
            restore_run_id(previous_run_id)
            release_lock(repo)
          end

          true
        else
          false
        end
      end)

    if acquired? == false do
      Logger.debug("threadline_retention_pruner lock held elsewhere, waiting")
      Process.sleep(@lock_retry_ms)
      execute_when_lock_available(repo, run_id, sleep_ms, storage_schema, storage_opts)
    end
  end

  defp restore_run_id(nil), do: Process.delete(@run_id_key)
  defp restore_run_id(value), do: Process.put(@run_id_key, value)

  defp acceptance_lock_key(storage_schema) do
    :erlang.phash2({@acceptance_lock_prefix, storage_schema})
  end

  defp schedule_next(interval_ms) do
    Process.send_after(self(), :run_purge, interval_ms)
  end

  defp acquire_lock(repo) do
    %{rows: [[acquired]]} =
      SQL.query!(repo, "SELECT pg_try_advisory_lock($1)", [@lock_key])

    acquired
  end

  defp release_lock(repo) do
    SQL.query!(repo, "SELECT pg_advisory_unlock($1)", [@lock_key])
  end
end
