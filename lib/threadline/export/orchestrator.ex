defmodule Threadline.Export.Orchestrator do
  @moduledoc """
  Executes asynchronous export jobs safely by streaming directly to disk.
  """

  alias Threadline.Export
  alias Threadline.Governance.ExportJob
  alias Threadline.OperatorSurface.Exports.FilterParams
  alias Threadline.StorageSchema

  @default_retention_ttl_hours 24 * 7

  @doc """
  Runs an export job by `job_id`. Streams records directly to a temporary file
  and then persists it via `Threadline.Storage`.
  """
  def run(job_id, opts \\ []) do
    repo = Keyword.get(opts, :repo) || default_repo()
    storage = Application.get_env(:threadline, :storage_adapter, Threadline.Storage.Local)

    case fetch_and_mark_running(repo, job_id) do
      {:ok, job} ->
        temp_path =
          Path.join(
            System.tmp_dir!(),
            "export_#{job_id}_#{System.unique_integer([:positive])}.csv"
          )

        try do
          res =
            repo.transaction(
              fn ->
                file = File.open!(temp_path, [:write, :utf8])
                IO.binwrite(file, Export.csv_header())

                filters = prepare_filters(job.query_params, repo)

                Export.stream_export_rows(filters, repo: repo)
                |> Stream.chunk_every(1000)
                |> Enum.each(fn chunk ->
                  iodata = Export.format_changes_iodata(chunk, :csv)
                  IO.binwrite(file, iodata)
                end)

                File.close(file)

                case storage.put(temp_path) do
                  {:ok, file_path} -> file_path
                  {:error, reason} -> repo.rollback({:storage_error, reason})
                end
              end,
              timeout: :infinity
            )

          if File.exists?(temp_path), do: File.rm(temp_path)

          case res do
            {:ok, file_path} ->
              mark_completed(repo, job, file_path)
              :ok

            {:error, reason} ->
              mark_failed(repo, job, inspect(reason))
              {:error, reason}
          end
        rescue
          e ->
            if File.exists?(temp_path), do: File.rm(temp_path)
            mark_failed(repo, job, Exception.message(e))
            {:error, e}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp default_repo do
    Application.get_env(:threadline, :ecto_repos, []) |> List.first()
  end

  defp fetch_and_mark_running(repo, job_id) do
    job = repo.get!(ExportJob, job_id, StorageSchema.repo_opts())

    Ecto.Changeset.change(job, %{
      status: "running",
      started_at: now(),
      error_message: nil
    })
    |> repo.update(StorageSchema.repo_opts())
  end

  defp mark_completed(repo, job, file_path) do
    Ecto.Changeset.change(job, %{
      status: "completed",
      file_path: file_path,
      completed_at: now(),
      expires_at: terminal_expiry()
    })
    |> repo.update!(StorageSchema.repo_opts())
  end

  defp mark_failed(repo, job, error_message) do
    Ecto.Changeset.change(job, %{
      status: "failed",
      error_message: error_message,
      expires_at: terminal_expiry()
    })
    |> repo.update!(StorageSchema.repo_opts())
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
