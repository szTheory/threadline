defmodule Threadline.Query.ExportReads do
  @moduledoc false

  import Ecto.Query

  alias Threadline.Export.CSV
  alias Threadline.Query
  alias Threadline.Semantics.ActorRef

  @csv_header ~w(
    id transaction_id table_schema table_name op captured_at
    table_pk data_after changed_fields changed_from transaction_json
  )

  def to_csv_iodata(filters, opts) when is_list(filters) and is_list(opts) do
    started_at = System.monotonic_time()

    try do
      Query.validate_timeline_filters!(filters)
      repo = Query.timeline_repo!(filters, opts)
      max_rows = Keyword.get(opts, :max_rows, 10_000)
      include_meta = Keyword.get(opts, :include_action_metadata, false)
      limit = max_rows + 1

      rows =
        repo.all(
          Query.export_changes_query(filters, opts) |> limit(^limit),
          Query.storage_opts(filters, opts)
        )

      {truncated, rows} = split_truncated(rows, max_rows)

      header =
        if include_meta do
          @csv_header ++ ~w(correlation_id action_id)
        else
          @csv_header
        end

      data_rows = Enum.map(rows, &csv_row(&1, include_meta))
      iodata = dump_csv_to_iodata([header | data_rows])
      returned_count = length(rows)

      Threadline.Telemetry.emit_export_completed(:csv, returned_count, truncated, started_at)

      {:ok,
       %{
         data: iodata,
         truncated: truncated,
         returned_count: returned_count,
         max_rows: max_rows
       }}
    rescue
      e ->
        Threadline.Telemetry.emit_export_failed(:csv, 0, :exception, e, started_at)
        reraise e, __STACKTRACE__
    end
  end

  def to_json_document(filters, opts) when is_list(filters) and is_list(opts) do
    started_at = System.monotonic_time()
    json_format = Keyword.get(opts, :json_format, :wrapped)
    emit_format = if json_format == :ndjson, do: :ndjson, else: :json

    try do
      Query.validate_timeline_filters!(filters)
      repo = Query.timeline_repo!(filters, opts)
      max_rows = Keyword.get(opts, :max_rows, 10_000)
      limit = max_rows + 1

      rows =
        repo.all(
          Query.export_changes_query(filters, opts) |> limit(^limit),
          Query.storage_opts(filters, opts)
        )

      {truncated, rows} = split_truncated(rows, max_rows)
      changes = Enum.map(rows, &change_map/1)

      data =
        case json_format do
          :ndjson ->
            changes
            |> Enum.map(fn ch -> [Jason.encode!(ch), ?\n] end)
            |> IO.iodata_to_binary()

          :wrapped ->
            doc = %{
              "format_version" => 1,
              "generated_at" => generated_at_iso(),
              "changes" => changes
            }

            Jason.encode_to_iodata!(doc)
        end

      returned_count = length(rows)

      Threadline.Telemetry.emit_export_completed(
        emit_format,
        returned_count,
        truncated,
        started_at
      )

      {:ok,
       %{
         data: data,
         truncated: truncated,
         returned_count: returned_count,
         max_rows: max_rows
       }}
    rescue
      e ->
        Threadline.Telemetry.emit_export_failed(emit_format, 0, :exception, e, started_at)
        reraise e, __STACKTRACE__
    end
  end

  def count_matching(filters, opts) when is_list(filters) and is_list(opts) do
    Query.validate_timeline_filters!(filters)
    repo = Query.timeline_repo!(filters, opts)
    cap = Keyword.get(opts, :cap)

    base_query =
      case Keyword.get(filters, :correlation_id) do
        nil ->
          filters
          |> Query.timeline_query()
          |> Query.maybe_apply_scope(opts)
          |> select([ac, _at], ac.id)

        _ ->
          filters
          |> Query.timeline_query()
          |> Query.maybe_apply_scope(opts)
          |> select([ac, _at, _aa], ac.id)
      end

    count =
      if is_integer(cap) and cap > 0 do
        capped = base_query |> limit(^cap)

        from(sub in subquery(capped), select: count())
        |> repo.one(Query.storage_opts(filters, opts))
      else
        repo.aggregate(base_query, :count, :id, Query.storage_opts(filters, opts))
      end

    {:ok, %{count: count}}
  end

  def stream_export_rows(filters, opts) when is_list(filters) and is_list(opts) do
    Query.validate_timeline_filters!(filters)
    repo = Query.timeline_repo!(filters, opts)
    page_size = Keyword.get(opts, :page_size, 1_000)

    Stream.resource(
      fn -> :start end,
      fn
        :done ->
          {:halt, :done}

        state ->
          cursor = if state == :start, do: nil, else: state

          q =
            filters
            |> Query.export_changes_query(opts)
            |> Query.maybe_after_timeline_cursor(cursor)
            |> limit(^page_size)

          case repo.all(q, Query.storage_opts(filters, opts)) do
            [] ->
              {:halt, :done}

            rows when length(rows) < page_size ->
              {rows, :done}

            rows ->
              last = List.last(rows)
              next_cursor = %{captured_at: last.captured_at, id: last.id}
              {rows, next_cursor}
          end
      end,
      fn _ -> :ok end
    )
  end

  defp split_truncated(rows, max_rows) do
    if length(rows) > max_rows do
      {true, Enum.take(rows, max_rows)}
    else
      {false, rows}
    end
  end

  defp dump_csv_to_iodata(rows) do
    rows
    |> CSV.dump_to_iodata()
    |> Enum.map(&IO.iodata_to_binary/1)
  end

  defp csv_row(row, include_meta) do
    tx_json =
      Jason.encode!(%{
        "id" => row.transaction_id |> to_string(),
        "occurred_at" => datetime_iso(row.tx_occurred_at),
        "actor_ref" => actor_json_value(row.tx_actor_ref),
        "source" => row.tx_source
      })

    base = [
      to_string(row.id),
      to_string(row.transaction_id),
      row.table_schema,
      row.table_name,
      row.op,
      datetime_iso(row.captured_at),
      Jason.encode!(row.table_pk || %{}),
      Jason.encode!(row.data_after || %{}),
      Jason.encode!(row.changed_fields || []),
      Jason.encode!(row.changed_from || %{}),
      tx_json
    ]

    if include_meta do
      cid = Map.get(row, :aa_correlation_id)
      aid = Map.get(row, :aa_id)
      base ++ [cid || "", if(aid, do: to_string(aid), else: "")]
    else
      base
    end
  end

  defp change_map(row) do
    base = %{
      "id" => row.id |> to_string(),
      "transaction_id" => row.transaction_id |> to_string(),
      "table_schema" => row.table_schema,
      "table_name" => row.table_name,
      "op" => row.op,
      "captured_at" => datetime_iso(row.captured_at),
      "table_pk" => row.table_pk || %{},
      "data_after" => row.data_after,
      "changed_fields" => row.changed_fields || [],
      "changed_from" => row.changed_from || %{},
      "transaction" => %{
        "id" => row.transaction_id |> to_string(),
        "occurred_at" => datetime_iso(row.tx_occurred_at),
        "actor_ref" => actor_json_value(row.tx_actor_ref),
        "source" => row.tx_source
      }
    }

    aid = Map.get(row, :aa_id)

    if aid do
      cid = Map.get(row, :aa_correlation_id)

      Map.put(base, "action", %{
        "id" => aid |> to_string(),
        "correlation_id" => cid
      })
    else
      base
    end
  end

  defp actor_json_value(%ActorRef{} = ref), do: ActorRef.to_map(ref)
  defp actor_json_value(_), do: nil

  defp datetime_iso(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp datetime_iso(nil), do: nil

  defp generated_at_iso do
    DateTime.utc_now() |> DateTime.truncate(:microsecond) |> DateTime.to_iso8601()
  end
end
