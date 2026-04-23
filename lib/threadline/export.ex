defmodule Threadline.Export do
  @default_max_rows 10_000

  @moduledoc """
  CSV and JSON export for audited row changes.

  Uses the **same** `filters` and `opts` as `Threadline.Query.timeline/2`, including
  `:repo` resolution: `Keyword.get(opts, :repo) || Keyword.fetch!(filters, :repo)`.

  Filter keys are validated via `Threadline.Query.validate_timeline_filters!/1`
  (`:repo`, `:table`, `:actor_ref`, `:from`, `:to` only). Unknown keys raise
  `ArgumentError`.

  ## CSV columns

  Fixed column order: `id`, `transaction_id`, `table_schema`, `table_name`, `op`,
  `captured_at`, `table_pk`, `data_after`, `changed_fields`, `changed_from`,
  `transaction_json`. The last column is a JSON object with transaction
  `id`, `occurred_at`, `actor_ref`, and `source`. Datetimes are ISO 8601 UTC.

  ## JSON

  Wrapped format (default) is one object with `format_version`, `generated_at`,
  and `changes`. Pass `json_format: :ndjson` for one JSON object per line (no
  outer wrapper).

  ## Row limits

  Default `max_rows` is 10_000. Exports use `limit: max_rows + 1`
  to detect truncation; successful results include `truncated`, `returned_count`,
  and `max_rows`. Empty matches return header-only CSV (one header row) and
  `changes: []` in JSON.

  ## Streaming

  `stream_changes/2` pages by `(captured_at, id)` keyset and does **not** apply
  `max_rows` — cap with `Stream.take/2` or use `to_csv_iodata/2` / `to_json_document/2`
  for bounded exports.

  Database errors from `Ecto.Repo` raise like `timeline/2`.
  """

  import Ecto.Query

  alias NimbleCSV.RFC4180, as: RFC4180
  alias Threadline.Query
  alias Threadline.Semantics.ActorRef

  @csv_header ~w(
    id transaction_id table_schema table_name op captured_at
    table_pk data_after changed_fields changed_from transaction_json
  )

  @doc """
  Returns CSV as iodata plus truncation metadata.

  See module documentation for `filters`, `opts`, and column layout.

  ## Options

  - `:repo` — optional if `:repo` is present in `filters`
  - `:max_rows` — defaults to `#{@default_max_rows}`
  """
  @spec to_csv_iodata(keyword(), keyword()) :: {:ok, map()}
  def to_csv_iodata(filters, opts \\ []) when is_list(filters) and is_list(opts) do
    Query.validate_timeline_filters!(filters)
    repo = Query.timeline_repo!(filters, opts)
    max_rows = Keyword.get(opts, :max_rows, @default_max_rows)
    limit = max_rows + 1

    rows = repo.all(Query.export_changes_query(filters) |> limit(^limit))
    {truncated, rows} = split_truncated(rows, max_rows)

    data_rows = Enum.map(rows, &csv_row/1)
    iodata = RFC4180.dump_to_iodata([@csv_header | data_rows])

    {:ok,
     %{
       data: iodata,
       truncated: truncated,
       returned_count: length(rows),
       max_rows: max_rows
     }}
  end

  @doc """
  Returns JSON (wrapped object or NDJSON lines) as iodata plus truncation metadata.

  ## Options

  - `:repo`, `:max_rows` — same as `to_csv_iodata/2`
  - `:json_format` — `:wrapped` (default) or `:ndjson`
  """
  @spec to_json_document(keyword(), keyword()) :: {:ok, map()}
  def to_json_document(filters, opts \\ []) when is_list(filters) and is_list(opts) do
    Query.validate_timeline_filters!(filters)
    repo = Query.timeline_repo!(filters, opts)
    max_rows = Keyword.get(opts, :max_rows, @default_max_rows)
    json_format = Keyword.get(opts, :json_format, :wrapped)
    limit = max_rows + 1

    rows = repo.all(Query.export_changes_query(filters) |> limit(^limit))
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

    {:ok,
     %{
       data: data,
       truncated: truncated,
       returned_count: length(rows),
       max_rows: max_rows
     }}
  end

  @doc """
  Counts changes matching `filters` without loading row payloads.

  Same validation and join semantics as `Threadline.Query.timeline/2`.
  """
  @spec count_matching(keyword(), keyword()) :: {:ok, %{count: non_neg_integer()}}
  def count_matching(filters, opts \\ []) when is_list(filters) and is_list(opts) do
    Query.validate_timeline_filters!(filters)
    repo = Query.timeline_repo!(filters, opts)

    count =
      filters
      |> Query.timeline_query()
      |> select([ac], ac.id)
      |> repo.aggregate(:count, :id)

    {:ok, %{count: count}}
  end

  @doc """
  Lazily enumerates `AuditChange` structs in timeline order using keyset pages.

  Does **not** enforce `max_rows` — combine with `Stream.take/2` if needed.

  ## Options

  - `:repo` — optional if present in `filters`
  - `:page_size` — defaults to `1000`
  """
  @spec stream_changes(keyword(), keyword()) :: Enumerable.t()
  def stream_changes(filters, opts \\ []) when is_list(filters) and is_list(opts) do
    Query.validate_timeline_filters!(filters)
    repo = Query.timeline_repo!(filters, opts)
    page_size = Keyword.get(opts, :page_size, 1000)

    Stream.resource(
      fn -> nil end,
      fn
        cursor ->
          base =
            filters
            |> Query.timeline_query()
            |> select([ac, _at], ac)

          q =
            case cursor do
              nil ->
                base

              {cap, id} ->
                where(
                  base,
                  [ac],
                  fragment(
                    "(?, ?) < (?, ?)",
                    ac.captured_at,
                    ac.id,
                    ^cap,
                    type(^id, :binary_id)
                  )
                )
            end
            |> limit(^page_size)

          case repo.all(q) do
            [] ->
              {:halt, :done}

            rows ->
              last = List.last(rows)
              {rows, {last.captured_at, last.id}}
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

  defp csv_row(row) do
    tx_json =
      Jason.encode!(%{
        "id" => row.transaction_id |> to_string(),
        "occurred_at" => datetime_iso(row.tx_occurred_at),
        "actor_ref" => actor_json_value(row.tx_actor_ref),
        "source" => row.tx_source
      })

    [
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
  end

  defp change_map(row) do
    %{
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
  end

  defp actor_json_value(%ActorRef{} = ref), do: ActorRef.to_map(ref)
  defp actor_json_value(_), do: nil

  defp datetime_iso(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp datetime_iso(nil), do: nil

  defp generated_at_iso do
    DateTime.utc_now() |> DateTime.truncate(:microsecond) |> DateTime.to_iso8601()
  end
end
