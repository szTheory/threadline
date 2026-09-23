defmodule Threadline.Export.Orchestrator do
  @moduledoc """
  Executes asynchronous export jobs safely by streaming directly to disk.
  """

  require Logger
  import Ecto.Query, only: [from: 2]

  alias Threadline.Export
  alias Threadline.Governance.ExportJob
  alias Threadline.Query.FilterParams
  alias Threadline.StorageSchema

  @default_retention_ttl_hours 24 * 7

  @doc """
  Runs an export job by `job_id`. Streams records directly to a temporary file
  and then persists it via `Threadline.Storage`.
  """
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

    case fetch_and_mark_running(repo, job_id, storage_opts) do
      {:ok, job} ->
        temp_path =
          Path.join(
            System.tmp_dir!(),
            "export_#{job_id}_#{System.unique_integer([:positive])}.csv"
          )

        try do
          transaction_result =
            transaction_fn.(
              fn ->
                file = File.open!(temp_path, [:write, :utf8])

                try do
                  IO.binwrite(file, Export.csv_header())

                  filters = prepare_filters(job.query_params, repo)

                  Export.stream_export_rows(filters,
                    repo: repo,
                    storage_schema: storage_schema
                  )
                  |> Stream.chunk_every(1000)
                  |> Enum.each(fn chunk ->
                    iodata = Export.format_changes_iodata(chunk, :csv)
                    IO.binwrite(file, iodata)
                  end)
                after
                  close_temp_file(file, temp_path)
                end

                :written
              end,
              timeout: :infinity
            )

          case transaction_result do
            {:ok, :written} ->
              case File.read(temp_path) do
                {:ok, csv_content} ->
                  persist_export(
                    storage.put(csv_content),
                    repo,
                    job,
                    temp_path,
                    storage,
                    storage_opts,
                    completion_fn
                  )

                {:error, reason} ->
                  remove_temp_file(temp_path)
                  mark_failed(repo, job, inspect({:temp_file_read_error, reason}), storage_opts)
                  {:error, {:temp_file_read_error, reason}}
              end

            {:error, reason} ->
              remove_temp_file(temp_path)
              mark_failed(repo, job, inspect(reason), storage_opts)
              {:error, reason}

            other ->
              remove_temp_file(temp_path)

              mark_failed(
                repo,
                job,
                inspect({:unexpected_transaction_result, other}),
                storage_opts
              )

              {:error, {:unexpected_transaction_result, other}}
          end
        rescue
          e ->
            remove_temp_file(temp_path)
            mark_failed(repo, job, Exception.message(e), storage_opts)
            {:error, e}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp persist_export(
         storage_result,
         repo,
         job,
         temp_path,
         storage,
         storage_opts,
         completion_fn
       ) do
    case storage_result do
      {:ok, file_path} ->
        remove_temp_file(temp_path)

        finalize_stored_export(
          repo,
          job,
          file_path,
          storage,
          storage_opts,
          completion_fn
        )

      {:error, reason} ->
        remove_temp_file(temp_path)
        mark_failed(repo, job, inspect({:storage_error, reason}), storage_opts)
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

  defp finalize_stored_export(
         repo,
         job,
         file_path,
         storage,
         storage_opts,
         completion_fn
       ) do
    completion_result =
      try do
        completion_fn.(repo, job, file_path, storage_opts)
      rescue
        exception -> {:error, exception}
      end

    case completion_result do
      {:ok, _job} ->
        :ok

      {:error, reason} ->
        compensate_failed_finalization(repo, job, file_path, storage, storage_opts, reason)

      other ->
        compensate_failed_finalization(
          repo,
          job,
          file_path,
          storage,
          storage_opts,
          {:unexpected_completion_result, other}
        )
    end
  end

  defp compensate_failed_finalization(repo, job, file_path, storage, storage_opts, reason) do
    case delete_stored_export(storage, file_path) do
      :ok ->
        mark_failed(repo, job, inspect(reason), storage_opts)

      {:error, delete_reason} ->
        Logger.warning(
          "retaining export object reference #{inspect(file_path)} after completion and compensation failed: #{inspect(delete_reason)}"
        )

        mark_failed(
          repo,
          job,
          "#{inspect(reason)}; compensation failed: #{inspect(delete_reason)}",
          storage_opts,
          file_path
        )
    end

    {:error, reason}
  end

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
