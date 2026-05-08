if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.Controllers.ExportController do
    @moduledoc """
    HTTP-side parity controller for the operator-surface "Download CSV / JSON
    / NDJSON" affordances. Three actions (`csv/2`, `json/2`, `ndjson/2`); each
    dispatches through one private `dispatch/3` so the format-vs-transport
    branching is in one place.

    Per request:

    1. Parse URL params via `Threadline.OperatorSurface.Exports.FilterParams.parse/1`
       (single source of truth shared with `TimelineLive`).
    2. Re-validate via `Threadline.Query.validate_timeline_filters!/1` (single
       source of truth shared with the lib + Mix task).
    3. Pre-flight `Threadline.Export.count_matching/2` with `cap: 10_001` so
       multi-million-row tables short-circuit instead of hitting
       `statement_timeout`.
    4. Dispatch:
       - `count <= 5_000`: full iodata via `to_csv_iodata/2` /
         `to_json_document/2` and `send_resp(200, iodata)`.
       - `count > 5_000`: `send_chunked(200)` then stream via
         `stream_export_rows(filters, page_size: 1_000) |> Stream.take(10_000) |>
         Stream.chunk_every(500) |> Enum.reduce_while/3` calling
         `Plug.Conn.chunk/2` per chunk; halts on client disconnect.

    Response headers (set BEFORE `send_chunked/2` per Plug API):

    - `Content-Type: text/csv; charset=utf-8` / `application/json; charset=utf-8` / `application/x-ndjson; charset=utf-8`
    - `Content-Disposition: attachment; filename="<canonical>"; filename*=UTF-8''<canonical>` (RFC 6266 §4.3 dual-emit)
    - `Cache-Control: no-store` (audit-data hygiene)

    Filename comes from `Threadline.OperatorSurface.Exports.Filename.for/2`
    (UTC, minute granularity, hyphen-not-colon between hours and minutes for
    Windows compatibility).
    """

    use Phoenix.Controller, formats: [:html]

    import Plug.Conn

    alias Threadline.Export
    alias Threadline.OperatorSurface.Exports.Filename
    alias Threadline.OperatorSurface.Exports.FilterParams

    @sync_threshold 5_000
    @max_rows 10_000
    @chunk_batch_size 500
    @stream_page_size 1_000

    # ---- Three thin actions, one shared dispatcher ----

    def csv(conn, params), do: dispatch(conn, params, :csv)
    def json(conn, params), do: dispatch(conn, params, :json)
    def ndjson(conn, params), do: dispatch(conn, params, :ndjson)

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

        # Headers MUST be set BEFORE send_chunked/2 (Pitfall 2).
        conn = put_export_headers(conn, format)

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

    # ---- Iodata path (count <= 5_000): single send_resp ----

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

    # ---- Chunked path (count > 5_000): send_chunked + reduce_while ----

    defp send_chunked_stream(conn, filters, format, scope_opts) do
      conn = send_chunked(conn, 200)

      # Emit per-format prefix (CSV header / JSON envelope open) as the FIRST chunk.
      conn = emit_prefix(conn, format)

      # Stream the bounded export-row maps (join-projected; same shape as
      # to_csv_iodata/to_json_document consume internally).
      {conn, _} =
        filters
        |> Export.stream_export_rows(Keyword.merge([page_size: @stream_page_size], scope_opts))
        |> Stream.take(@max_rows)
        |> Stream.chunk_every(@chunk_batch_size)
        |> Enum.reduce_while({conn, _first_batch? = true}, fn rows, {conn, first_batch?} ->
          batch_iodata = format_batch(rows, format, first_batch?)

          case Plug.Conn.chunk(conn, batch_iodata) do
            {:ok, conn} -> {:cont, {conn, false}}
            {:error, :closed} -> {:halt, {conn, false}}
            {:error, _other} -> {:halt, {conn, false}}
          end
        end)

      # Emit per-format suffix (JSON envelope close) as the LAST chunk.
      emit_suffix(conn, format)
    end

    # ---- Per-format prefix emission (BEFORE the first row chunk) ----

    defp emit_prefix(conn, :csv) do
      header = Export.csv_header([])

      case Plug.Conn.chunk(conn, header) do
        {:ok, conn} -> conn
        {:error, _} -> conn
      end
    end

    defp emit_prefix(conn, :json) do
      # Wrapped-JSON envelope opener (RESEARCH §"Open Question O-2" recommendation O-2a).
      generated_at =
        DateTime.utc_now() |> DateTime.truncate(:microsecond) |> DateTime.to_iso8601()

      prefix = ~s|{"format_version":1,"generated_at":"#{generated_at}","changes":[|

      case Plug.Conn.chunk(conn, prefix) do
        {:ok, conn} -> conn
        {:error, _} -> conn
      end
    end

    defp emit_prefix(conn, :ndjson) do
      # NDJSON has no envelope; nothing to emit.
      conn
    end

    # ---- Per-batch row formatting ----
    #
    # CSV and NDJSON: each batch is independent iodata.
    # JSON wrapped: rows must be comma-separated WITHIN and ACROSS batches; the
    # very first row of the very first batch has NO leading comma.

    defp format_batch(rows, :csv, _first_batch?) do
      Export.format_changes_iodata(rows, :csv, [])
    end

    defp format_batch(rows, :json, first_batch?) do
      json_rows = Export.format_changes_iodata(rows, :json_wrapped, [])

      json_rows
      |> Enum.with_index()
      |> Enum.map(fn
        {row, 0} -> if first_batch?, do: row, else: [",", row]
        {row, _} -> [",", row]
      end)
    end

    defp format_batch(rows, :ndjson, _first_batch?) do
      Export.format_changes_iodata(rows, :ndjson, [])
    end

    # ---- Per-format suffix emission (AFTER the last row chunk) ----

    defp emit_suffix(conn, :csv), do: conn

    defp emit_suffix(conn, :json) do
      case Plug.Conn.chunk(conn, "]}") do
        {:ok, conn} -> conn
        {:error, _} -> conn
      end
    end

    defp emit_suffix(conn, :ndjson), do: conn

    # ---- Headers ----
    #
    # Use put_resp_header/3 directly (NOT put_resp_content_type/2) because the
    # latter always appends "; charset=<charset>" — passing "text/csv;
    # charset=utf-8" would produce a doubled charset. Plan 04's doc-contract
    # test pins the exact literals "text/csv; charset=utf-8",
    # "application/json; charset=utf-8", "application/x-ndjson; charset=utf-8".

    defp put_export_headers(conn, :csv),
      do: put_export_headers(conn, "text/csv; charset=utf-8", "csv")

    defp put_export_headers(conn, :json),
      do: put_export_headers(conn, "application/json; charset=utf-8", "json")

    defp put_export_headers(conn, :ndjson),
      do: put_export_headers(conn, "application/x-ndjson; charset=utf-8", "ndjson")

    defp put_export_headers(conn, content_type, ext) do
      filename = Filename.for(ext, DateTime.utc_now())
      disposition = ~s|attachment; filename="#{filename}"; filename*=UTF-8''#{filename}|

      conn
      |> put_resp_header("content-type", content_type)
      |> put_resp_header("content-disposition", disposition)
      |> put_resp_header("cache-control", "no-store")
    end

    # ---- Filter validation (lifted from timeline_live.ex:366-373) ----

    defp safe_validate(filters) do
      try do
        Threadline.Query.validate_timeline_filters!(filters)
        :ok
      rescue
        e in ArgumentError -> {:error, e.message}
      end
    end

    # ---- Repo resolution ----

    defp default_repo do
      Application.get_env(:threadline, :ecto_repos) |> hd()
    end
  end
end
