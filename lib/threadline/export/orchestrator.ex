defmodule Threadline.Export.Orchestrator do
  @moduledoc """
  Runs asynchronous export jobs by streaming captured rows to temporary files and storage.
  """

  require Logger
  import Ecto.Query, only: [from: 2]

  alias Threadline.Export
  alias Threadline.Governance.ExportJob
  alias Threadline.Query.FilterParams
  alias Threadline.StorageSchema
  alias Threadline.Telemetry

  @default_retention_ttl_hours 24 * 7

  @typedoc "An option accepted by `run/2`."
  @type run_opt ::
          Threadline.repo_opt()
          | Threadline.storage_schema_opt()
          | {:storage_adapter, module()}
          | {:transaction_fn, function()}
          | {:completion_fn, function()}

  @typedoc "The result of running an export job; error reasons are produced by the repository or storage adapter."
  @type run_result :: :ok | {:error, term()}

  @doc """
  Runs an export job and returns `:ok` after storing its CSV, or `{:error, reason}` on failure.

  A custom `Threadline.ExportQueue` adapter can call this from its worker to
  execute a claimed job. The orchestrator streams projected rows to a temporary
  file, persists the file through `Threadline.Storage`, and records the terminal
  job state.

  ## Options

  - `:repo` — `Ecto.Repo` module. Defaults to the first configured Threadline repository.
  - `:storage_schema` — string. Defaults to the configured Threadline storage schema.
  - `:storage_adapter` — storage adapter module. Defaults to the configured adapter.
  - `:transaction_fn` — function. Defaults to `repo.transaction/2`; accepts the work function and transaction options.
  - `:completion_fn` — function. Defaults to the callback that marks the export job completed.

  Other option keys are ignored.

  ## Returns

  - `:ok` — the stored export was recorded as completed.
  - `{:error, reason}` — the job could not be claimed, generated, stored, or finalized.
  """
  @spec run(String.t(), [run_opt()]) :: run_result()
  def run(job_id, opts \\ []) do
    repo = Keyword.get(opts, :repo) || default_repo()
    storage_schema = StorageSchema.get(opts)
    storage_opts = StorageSchema.repo_opts(storage_schema: storage_schema)

    storage =
      Keyword.get(opts, :storage_adapter) ||
        Application.get_env(:threadline, :storage_adapter, Threadline.Storage.Local)

    transaction_fn =
      Keyword.get(opts, :transaction_fn, fn fun, transaction_opts ->
        repo.transaction(fun, transaction_opts)
      end)

    completion_fn = Keyword.get(opts, :completion_fn, &mark_completed/4)

    ctx = %{
      repo: repo,
      storage_schema: storage_schema,
      storage_opts: storage_opts,
      storage: storage,
      transaction_fn: transaction_fn,
      completion_fn: completion_fn
    }

    case fetch_and_mark_running(repo, job_id, storage_opts) do
      {:ok, job} -> run_job(job_id, job, ctx)
      {:error, reason} -> {:error, reason}
    end
  end

  # Load is done: stream the rows to a temp file inside the export
  # transaction, then persist. The rescue covers both steps, as before.
  defp run_job(job_id, job, ctx) do
    ctx = Map.merge(ctx, %{started_at: System.monotonic_time(), rows: :counters.new(1, [])})

    temp_path =
      Path.join(
        System.tmp_dir!(),
        "export_#{job_id}_#{System.unique_integer([:positive])}.csv"
      )

    try do
      transaction_result =
        ctx.transaction_fn.(
          fn -> write_temp_csv(temp_path, job, ctx) end,
          timeout: :infinity
        )

      handle_transaction_result(transaction_result, job, temp_path, ctx)
    rescue
      e ->
        remove_temp_file(temp_path)
        mark_failed(ctx.repo, job, Exception.message(e), ctx.storage_opts)
        Telemetry.emit_export_failed(:csv, rows_sent(ctx), :exception, e, ctx.started_at)
        {:error, e}
    end
  end

  # Runs inside the export transaction fn.
  defp write_temp_csv(temp_path, job, ctx) do
    file = File.open!(temp_path, [:write, :utf8])

    try do
      IO.binwrite(file, Export.csv_header())

      filters = prepare_filters(job.query_params, ctx.repo)

      Export.stream_export_rows(filters,
        repo: ctx.repo,
        storage_schema: ctx.storage_schema
      )
      |> Stream.chunk_every(1000)
      |> Enum.each(fn chunk ->
        iodata = Export.format_changes_iodata(chunk, :csv)
        IO.binwrite(file, iodata)
        :counters.add(ctx.rows, 1, length(chunk))
      end)
    after
      close_temp_file(file, temp_path)
    end

    :written
  end

  defp handle_transaction_result({:ok, :written}, job, temp_path, ctx) do
    case File.read(temp_path) do
      {:ok, csv_content} ->
        persist_export(ctx.storage.put(csv_content), job, temp_path, ctx)

      {:error, reason} ->
        remove_temp_file(temp_path)
        mark_failed(ctx.repo, job, inspect({:temp_file_read_error, reason}), ctx.storage_opts)
        Telemetry.emit_export_failed(:csv, rows_sent(ctx), :storage_error, nil, ctx.started_at)
        {:error, {:temp_file_read_error, reason}}
    end
  end

  defp handle_transaction_result({:error, reason}, job, temp_path, ctx) do
    remove_temp_file(temp_path)
    mark_failed(ctx.repo, job, inspect(reason), ctx.storage_opts)
    Telemetry.emit_export_failed(:csv, rows_sent(ctx), :transaction_failed, nil, ctx.started_at)
    {:error, reason}
  end

  defp handle_transaction_result(other, job, temp_path, ctx) do
    remove_temp_file(temp_path)

    mark_failed(
      ctx.repo,
      job,
      inspect({:unexpected_transaction_result, other}),
      ctx.storage_opts
    )

    Telemetry.emit_export_failed(:csv, rows_sent(ctx), :transaction_failed, nil, ctx.started_at)
    {:error, {:unexpected_transaction_result, other}}
  end

  defp persist_export(storage_result, job, temp_path, ctx) do
    case storage_result do
      {:ok, file_path} ->
        remove_temp_file(temp_path)
        finalize_stored_export(job, file_path, ctx)

      {:error, reason} ->
        remove_temp_file(temp_path)
        mark_failed(ctx.repo, job, inspect({:storage_error, reason}), ctx.storage_opts)
        Telemetry.emit_export_failed(:csv, rows_sent(ctx), :storage_error, nil, ctx.started_at)
        {:error, {:storage_error, reason}}
    end
  end

  defp default_repo do
    Application.get_env(:threadline, :ecto_repos, []) |> List.first()
  end

  defp fetch_and_mark_running(repo, job_id, storage_opts) do
    started_at = now()

    claim_query =
      from(j in ExportJob,
        where: j.id == ^job_id and j.status == "pending"
      )

    case repo.update_all(
           claim_query,
           [
             set: [
               status: "running",
               started_at: started_at,
               error_message: nil,
               updated_at: DateTime.truncate(started_at, :second)
             ]
           ],
           storage_opts
         ) do
      {1, _rows} -> {:ok, repo.get!(ExportJob, job_id, storage_opts)}
      {0, _rows} -> {:error, :not_claimable}
    end
  end

  defp mark_completed(repo, job, file_path, storage_opts) do
    Ecto.Changeset.change(job, %{
      status: "completed",
      file_path: file_path,
      completed_at: now(),
      expires_at: terminal_expiry()
    })
    |> repo.update(storage_opts)
  end

  defp mark_failed(repo, job, error_message, storage_opts, file_path \\ nil) do
    Ecto.Changeset.change(job, %{
      status: "failed",
      file_path: file_path,
      error_message: error_message,
      expires_at: terminal_expiry()
    })
    |> repo.update(storage_opts)
  end

  defp finalize_stored_export(job, file_path, ctx) do
    completion_result =
      try do
        ctx.completion_fn.(ctx.repo, job, file_path, ctx.storage_opts)
      rescue
        exception -> {:error, exception}
      end

    case completion_result do
      {:ok, _job} ->
        Telemetry.emit_export_completed(:csv, rows_sent(ctx), false, ctx.started_at)
        :ok

      {:error, reason} ->
        compensate_failed_finalization(job, file_path, ctx, reason)

      other ->
        compensate_failed_finalization(
          job,
          file_path,
          ctx,
          {:unexpected_completion_result, other}
        )
    end
  end

  defp compensate_failed_finalization(job, file_path, ctx, reason) do
    case delete_stored_export(ctx.storage, file_path) do
      :ok ->
        mark_failed(ctx.repo, job, inspect(reason), ctx.storage_opts)

      {:error, delete_reason} ->
        Logger.warning(
          "retaining export object reference #{inspect(file_path)} after completion and compensation failed: #{inspect(delete_reason)}"
        )

        mark_failed(
          ctx.repo,
          job,
          "#{inspect(reason)}; compensation failed: #{inspect(delete_reason)}",
          ctx.storage_opts,
          file_path
        )
    end

    if is_exception(reason) do
      Telemetry.emit_export_failed(:csv, rows_sent(ctx), :exception, reason, ctx.started_at)
    else
      Telemetry.emit_export_failed(:csv, rows_sent(ctx), :transaction_failed, nil, ctx.started_at)
    end

    {:error, reason}
  end

  defp rows_sent(ctx), do: :counters.get(ctx.rows, 1)

  defp delete_stored_export(storage, file_path) do
    case storage.delete(file_path) do
      :ok -> :ok
      {:error, reason} when reason in [:enoent, :not_found] -> :ok
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unexpected_delete_result, other}}
    end
  rescue
    exception -> {:error, exception}
  end

  defp close_temp_file(file, temp_path) do
    case File.close(file) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("failed to close export temp file #{temp_path}: #{inspect(reason)}")
        :ok
    end
  end

  defp remove_temp_file(temp_path) do
    case File.rm(temp_path) do
      :ok ->
        :ok

      {:error, :enoent} ->
        :ok

      {:error, reason} ->
        Logger.warning("failed to remove export temp file #{temp_path}: #{inspect(reason)}")
        :ok
    end
  end

  defp prepare_filters(query_params, repo) do
    case FilterParams.parse(query_params || %{}) do
      {:ok, filters} -> Keyword.put_new(filters, :repo, repo)
      {:error, message} -> raise ArgumentError, message
    end
  end

  defp terminal_expiry do
    now()
    |> DateTime.add(retention_ttl_seconds(), :second)
  end

  defp retention_ttl_seconds do
    hours =
      Application.get_env(:threadline, :exports, [])
      |> Keyword.get(:retention_ttl_hours, @default_retention_ttl_hours)

    hours * 60 * 60
  end

  defp now do
    DateTime.utc_now() |> DateTime.truncate(:microsecond)
  end
end
