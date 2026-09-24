defmodule Threadline.OperatorSurface.Controllers.ExportController.Encoding do
  @moduledoc false

  # Per-format wire encoding for export responses: the response headers, and for
  # the chunked path the prefix sent before the first row chunk, the formatting
  # of each row batch, and the suffix sent after the last row chunk.

  import Plug.Conn, only: [put_resp_header: 3]

  alias Threadline.Export
  alias Threadline.OperatorSurface.Exports.Filename

  # Headers use put_resp_header/3 directly, NOT put_resp_content_type/2, because
  # the latter always appends "; charset=<charset>". Passing "text/csv;
  # charset=utf-8" would produce a doubled charset. The exports doc-contract
  # test pins the exact literals "text/csv; charset=utf-8",
  # "application/json; charset=utf-8", "application/x-ndjson; charset=utf-8".

  def put_headers(conn, :csv),
    do: put_headers(conn, "text/csv; charset=utf-8", "csv")

  def put_headers(conn, :json),
    do: put_headers(conn, "application/json; charset=utf-8", "json")

  def put_headers(conn, :ndjson),
    do: put_headers(conn, "application/x-ndjson; charset=utf-8", "ndjson")

  defp put_headers(conn, content_type, ext) do
    filename = Filename.for(ext, DateTime.utc_now())
    disposition = ~s|attachment; filename="#{filename}"; filename*=UTF-8''#{filename}|

    conn
    |> put_resp_header("content-type", content_type)
    |> put_resp_header("content-disposition", disposition)
    |> put_resp_header("cache-control", "no-store")
  end

  # Prefix, sent BEFORE the first row chunk.

  def emit_prefix(conn, :csv) do
    header = Export.csv_header([])

    case Plug.Conn.chunk(conn, header) do
      {:ok, conn} -> conn
      {:error, _} -> conn
    end
  end

  def emit_prefix(conn, :json) do
    # Wrapped-JSON envelope opener.
    generated_at =
      DateTime.utc_now() |> DateTime.truncate(:microsecond) |> DateTime.to_iso8601()

    prefix = ~s|{"format_version":1,"generated_at":"#{generated_at}","changes":[|

    case Plug.Conn.chunk(conn, prefix) do
      {:ok, conn} -> conn
      {:error, _} -> conn
    end
  end

  def emit_prefix(conn, :ndjson) do
    # NDJSON has no envelope; nothing to emit.
    conn
  end

  # Per-batch row formatting.
  #
  # CSV and NDJSON: each batch is independent iodata.
  # JSON wrapped: rows must be comma-separated WITHIN and ACROSS batches; the
  # very first row of the very first batch has NO leading comma.

  def format_batch(rows, :csv, _first_batch?) do
    Export.format_changes_iodata(rows, :csv, [])
  end

  def format_batch(rows, :json, first_batch?) do
    json_rows = Export.format_changes_iodata(rows, :json_wrapped, [])

    json_rows
    |> Enum.with_index()
    |> Enum.map(fn
      {row, 0} -> if first_batch?, do: row, else: [",", row]
      {row, _} -> [",", row]
    end)
  end

  def format_batch(rows, :ndjson, _first_batch?) do
    Export.format_changes_iodata(rows, :ndjson, [])
  end

  # Suffix, sent AFTER the last row chunk.

  def emit_suffix(conn, :csv), do: conn

  def emit_suffix(conn, :json) do
    case Plug.Conn.chunk(conn, "]}") do
      {:ok, conn} -> conn
      {:error, _} -> conn
    end
  end

  def emit_suffix(conn, :ndjson), do: conn
end
