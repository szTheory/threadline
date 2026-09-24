if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.Controllers.ExportController do
    @moduledoc false

    use Phoenix.Controller, formats: [:html]

    import Plug.Conn

    alias Threadline.Export
    alias Threadline.Governance.ExportJob
    alias Threadline.OperatorSurface.Controllers.ExportController.Encoding
    alias Threadline.Query.FilterParams
    alias Threadline.Semantics.ActorRef
    alias Threadline.StorageSchema

    @sync_threshold 5_000
    @max_rows 10_000
    @chunk_batch_size 500
    @stream_page_size 1_000

    # Three thin actions share one dispatcher.

    def csv(conn, params), do: dispatch(conn, params, :csv)
    def json(conn, params), do: dispatch(conn, params, :json)
    def ndjson(conn, params), do: dispatch(conn, params, :ndjson)

    def download(conn, %{"job_id" => job_id}) do
      repo = conn.assigns[:threadline_repo] || default_repo()
      actor_ref = conn.assigns[:threadline_actor_ref]
      storage_schema = StorageSchema.get()

      case Ecto.UUID.cast(job_id) do
        {:ok, uuid} ->
          job = fetch_export_job(repo, uuid, storage_schema)

          if owned_by_requester?(job, actor_ref) do
            deliver_export(conn, job)
          else
            export_not_found(conn)
          end

        :error ->
          conn
          |> put_resp_header("content-type", "text/plain; charset=utf-8")
          |> send_resp(400, "Invalid job ID")
      end
    end

    defp owned_by_requester?(
           %ExportJob{actor_ref: %ActorRef{} = owner_actor},
           %ActorRef{} = request_actor
         ) do
      owner_actor == request_actor and ActorRef.identifiable?(owner_actor) and
        ActorRef.identifiable?(request_actor)
    end

    defp owned_by_requester?(_job, _actor_ref), do: false

    defp export_not_found(conn) do
      conn
      |> put_resp_header("content-type", "text/plain; charset=utf-8")
      |> send_resp(404, "Export not found")
    end

    defp fetch_export_job(repo, uuid, storage_schema) do
      repo.get(ExportJob, uuid, StorageSchema.repo_opts(storage_schema: storage_schema))
    end

    defp deliver_export(conn, %{status: "completed", file_path: file_path} = job)
         when is_binary(file_path) do
      with :ok <- ensure_not_expired(job),
           {:ok, delivery} <- resolve_delivery(file_path, job) do
        send_delivery(conn, delivery, file_path)
      else
        {:error, :expired} ->
          unavailable_export(conn, 410, "Export download is no longer available")

        {:error, _reason} ->
          unavailable_export(conn, 404, "Export download is not available")
      end
    end

    defp deliver_export(conn, _job) do
      conn
      |> put_resp_header("content-type", "text/plain; charset=utf-8")
      |> send_resp(422, "Export not ready or failed")
    end

    defp resolve_delivery(file_path, job) do
      storage_adapter =
        Application.get_env(:threadline, :storage_adapter, Threadline.Storage.Local)

      if function_exported?(storage_adapter, :path, 1) do
        case storage_adapter.path(file_path) do
          {:ok, absolute_path} ->
            {:ok, {:local, absolute_path}}

          {:error, :not_local} ->
            resolve_download_url(storage_adapter, file_path, job)

          {:error, reason} ->
            {:error, reason}
        end
      else
        resolve_download_url(storage_adapter, file_path, job)
      end
    end

    defp resolve_download_url(storage_adapter, file_path, job) do
      case storage_adapter.download_url(file_path, download_url_opts(storage_adapter, job)) do
        {:ok, url} -> {:ok, {:remote, url}}
        {:error, reason} -> {:error, reason}
      end
    end

    defp send_delivery(conn, {:local, absolute_path}, file_path) do
      filename = Path.basename(file_path)
      disposition = ~s|attachment; filename="#{filename}"; filename*=UTF-8''#{filename}|
      content_type = MIME.from_path(absolute_path)

      conn
      |> put_resp_header("content-type", content_type)
      |> put_resp_header("content-disposition", disposition)
      |> put_resp_header("cache-control", "no-store")
      |> Plug.Conn.send_file(200, absolute_path)
    end

    defp send_delivery(conn, {:remote, url}, _file_path) do
      conn
      |> put_resp_header("cache-control", "no-store")
      |> redirect(external: url)
    end

    defp download_url_opts(storage_adapter, job) do
      Application.get_env(:threadline, storage_adapter, [])
      |> Keyword.merge(expiry_download_opts(job))
    end

    defp expiry_download_opts(job) do
      case seconds_until_expiry(job.expires_at) do
        seconds when is_integer(seconds) and seconds > 0 -> [expires_in: seconds]
        _ -> []
      end
    end

    defp ensure_not_expired(%{expires_at: %DateTime{} = expires_at}) do
      if DateTime.compare(expires_at, DateTime.utc_now()) == :gt do
        :ok
      else
        {:error, :expired}
      end
    end

    defp ensure_not_expired(_job), do: :ok

    defp seconds_until_expiry(%DateTime{} = expires_at) do
      DateTime.diff(expires_at, DateTime.utc_now(), :second)
    end

    defp seconds_until_expiry(_expires_at), do: nil

    defp unavailable_export(conn, status, message) do
      conn
      |> put_resp_header("content-type", "text/plain; charset=utf-8")
      |> send_resp(status, message)
    end

    defp dispatch(conn, params, format) do
      with {:ok, filters} <- FilterParams.parse(params),
           :ok <- safe_validate(filters) do
        repo = conn.assigns[:threadline_repo] || default_repo()
        filters = Keyword.put(filters, :repo, repo)

        scope_opts = [
          scope: conn.assigns[:threadline_scope],
          scope_query_fn: conn.assigns[:threadline_scope_query_fn],
          surface: :export,
          params: %{filters: filters}
        ]

        {:ok, %{count: count}} =
          Export.count_matching(filters, Keyword.merge([cap: @max_rows + 1], scope_opts))

        # Plug requires response headers to be set before send_chunked/2.
        conn = Encoding.put_headers(conn, format)

        if count <= @sync_threshold do
          send_iodata(conn, filters, format, scope_opts)
        else
          send_chunked_stream(conn, filters, format, scope_opts)
        end
      else
        {:error, message} ->
          conn
          |> put_resp_header("content-type", "text/plain; charset=utf-8")
          |> send_resp(422, "invalid filter: #{message}")
      end
    end

    # Iodata path (count <= 5_000): a single send_resp.

    defp send_iodata(conn, filters, :csv, scope_opts) do
      {:ok, %{data: iodata}} =
        Export.to_csv_iodata(filters, Keyword.merge([max_rows: @max_rows], scope_opts))

      send_resp(conn, 200, iodata)
    end

    defp send_iodata(conn, filters, :json, scope_opts) do
      {:ok, %{data: iodata}} =
        Export.to_json_document(
          filters,
          Keyword.merge([max_rows: @max_rows, json_format: :wrapped], scope_opts)
        )

      send_resp(conn, 200, iodata)
    end

    defp send_iodata(conn, filters, :ndjson, scope_opts) do
      {:ok, %{data: iodata}} =
        Export.to_json_document(
          filters,
          Keyword.merge([max_rows: @max_rows, json_format: :ndjson], scope_opts)
        )

      send_resp(conn, 200, iodata)
    end

    # Chunked path (count > 5_000): send_chunked + reduce_while.

    defp send_chunked_stream(conn, filters, format, scope_opts) do
      conn = send_chunked(conn, 200)

      # Emit per-format prefix (CSV header / JSON envelope open) as the FIRST chunk.
      conn = Encoding.emit_prefix(conn, format)

      # Stream the bounded export-row maps (join-projected; same shape as
      # to_csv_iodata/to_json_document consume internally).
      {conn, _} =
        filters
        |> Export.stream_export_rows(Keyword.merge([page_size: @stream_page_size], scope_opts))
        |> Stream.take(@max_rows)
        |> Stream.chunk_every(@chunk_batch_size)
        |> Enum.reduce_while({conn, _first_batch? = true}, fn rows, {conn, first_batch?} ->
          batch_iodata = Encoding.format_batch(rows, format, first_batch?)

          case Plug.Conn.chunk(conn, batch_iodata) do
            {:ok, conn} -> {:cont, {conn, false}}
            {:error, :closed} -> {:halt, {conn, false}}
            {:error, _other} -> {:halt, {conn, false}}
          end
        end)

      # Emit per-format suffix (JSON envelope close) as the LAST chunk.
      Encoding.emit_suffix(conn, format)
    end

    # Mirrors `TimelineLive.safe_validate/1`.
    defp safe_validate(filters) do
      Threadline.Query.validate_timeline_filters!(filters)
      :ok
    rescue
      e in ArgumentError -> {:error, e.message}
    end

    defp default_repo do
      Application.get_env(:threadline, :ecto_repos) |> hd()
    end
  end
end
