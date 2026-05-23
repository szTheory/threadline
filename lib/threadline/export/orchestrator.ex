defmodule Threadline.Export.Orchestrator do
  @moduledoc """
  Executes asynchronous export jobs safely by streaming directly to disk.
  """
  alias Threadline.Governance.ExportJob
  alias Threadline.Export

  @doc """
  Runs an export job by `job_id`. Streams records directly to a temporary file
  and then persists it via `Threadline.Storage`.
  """
  def run(job_id, opts \\ []) do
    repo = Keyword.get(opts, :repo) || default_repo()
    storage = Application.get_env(:threadline, :storage_adapter, Threadline.Storage.Local)

    case fetch_and_mark_running(repo, job_id) do
      {:ok, job} ->
        temp_path = Path.join(System.tmp_dir!(), "export_#{job_id}_#{System.unique_integer([:positive])}.csv")

        try do
          res =
            repo.transaction(fn ->
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
            end, timeout: :infinity)

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
    job = repo.get!(ExportJob, job_id)
    Ecto.Changeset.change(job, %{status: "running"})
    |> repo.update()
  end

  defp mark_completed(repo, job, file_path) do
    Ecto.Changeset.change(job, %{
      status: "completed",
      file_path: file_path,
      completed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
    })
    |> repo.update!()
  end

  defp mark_failed(repo, job, error_message) do
    Ecto.Changeset.change(job, %{status: "failed", error_message: error_message})
    |> repo.update!()
  end

  defp prepare_filters(query_params, repo) do
    base =
      Enum.map(query_params || %{}, fn {k, v} ->
        {String.to_atom(k), v}
      end)

    Keyword.put_new(base, :repo, repo)
  end
end
