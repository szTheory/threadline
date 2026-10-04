defmodule Threadline.Export do
  @default_max_rows 10_000

  @moduledoc """
  CSV and JSON export for audited row changes.

  Uses the **same** `filters` and `opts` as `Threadline.timeline/2`, including
  `:repo` resolution: `Keyword.get(opts, :repo) || Keyword.fetch!(filters, :repo)`.

  Only these filter keys are allowed: `:repo`, `:table`, `:actor_ref`, `:from`, `:to`,
  `:correlation_id`. Unknown keys raise `ArgumentError`.

  ## CSV columns

  Fixed column order: `id`, `transaction_id`, `table_schema`, `table_name`, `op`,
  `captured_at`, `table_pk`, `data_after`, `changed_fields`, `changed_from`,
  `transaction_json`. The last column is a JSON object with transaction
  `id`, `occurred_at`, `actor_ref`, and `source`. Datetimes are ISO 8601 UTC.

  Pass `include_action_metadata: true` in **opts** to append trailing columns
  `correlation_id` and `action_id` (the linked `audit_actions` row, when present).
  Default CSV shape is unchanged when this option is absent or `false`.

  ## JSON

  Wrapped format (default) is one object with `format_version`, `generated_at`,
  and `changes`. Each change may include an `"action"` object with `"id"` and
  `"correlation_id"` when the transaction is linked to an `audit_actions` row.
  Pass `json_format: :ndjson` for one JSON object per line (no outer wrapper).

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

  alias Threadline.Export.CSV
  alias Threadline.Query
  alias Threadline.Query.ExportReads
  alias Threadline.Query.OptionKeys
  alias Threadline.Semantics.ActorRef

  @csv_header ~w(
    id transaction_id table_schema table_name op captured_at
    table_pk data_after changed_fields changed_from transaction_json
  )

  @typedoc "A bounded export result containing encoded data and row-limit metadata."
  @type export_result :: %{
          data: iodata(),
          truncated: boolean(),
          returned_count: non_neg_integer(),
          max_rows: pos_integer()
        }

  @doc """
  Returns CSV iodata and truncation metadata for matching captured changes.

  Use `stream_changes/2` when the caller needs to process every matching
  `AuditChange` without a row cap. CSV columns retain the order described in
  the module documentation; the default header does not include action metadata.

  ## Filters

  - `:repo` — `Ecto.Repo` module. Required here or in options.
  - `:table_schema` — atom or string. Optional. Limits the storage schema.
  - `:table` — atom or string. Optional. Limits the captured table.
  - `:actor_ref` — `Threadline.Semantics.ActorRef`. Optional. Limits the actor.
  - `:from` — `DateTime`. Optional. Includes changes at or after this time.
  - `:to` — `DateTime`. Optional. Includes changes at or before this time.
  - `:correlation_id` — string. Optional. Limits the linked action correlation.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required unless supplied in filters.
  - `:storage_schema` — string. Optional. Selects a storage schema override.
  - `:scope` — caller-owned value. Optional. Passed to `:scope_query_fn`.
  - `:scope_query_fn` — function. Optional. Adds caller-owned scope predicates.
  - `:max_rows` — positive integer. Defaults to `#{@default_max_rows}`.
  - `:include_action_metadata` — boolean. Defaults to `false`; appends action columns when true.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - `{:ok, export_result()}` — CSV iodata and row-limit metadata.
  - Raises `ArgumentError` for invalid filters, missing `:repo`, or unknown options.
  - Repository errors are reraised.

  ## Examples

      Threadline.Export.to_csv_iodata([table: "members"], repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers
  are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @spec to_csv_iodata([Threadline.timeline_filter()], [Threadline.export_csv_opt()]) ::
          {:ok, export_result()}
  def to_csv_iodata(filters, opts \\ []) when is_list(filters) and is_list(opts) do
    OptionKeys.validate!(opts, :to_csv_iodata)
    ExportReads.to_csv_iodata(filters, opts)
  end

  @doc """
  Returns JSON (wrapped object or NDJSON lines) as iodata plus truncation metadata.

  ## Options

  - `:repo`, `:max_rows` — same as `to_csv_iodata/2`
  - `:json_format` — `:wrapped` (default) or `:ndjson`
  """
  @spec to_json_document(keyword(), keyword()) :: {:ok, map()}
  def to_json_document(filters, opts \\ []) when is_list(filters) and is_list(opts) do
    OptionKeys.validate!(opts, :to_json_document)
    ExportReads.to_json_document(filters, opts)
  end

  @doc """
  Counts changes matching `filters` without loading row payloads.

  Same validation and join semantics as `Threadline.timeline/2`.

  ## Options

  - `:repo` — optional if `:repo` is present in `filters`
  - `:cap` — when set to a positive integer, the count short-circuits at that
    value via a windowed subquery (`SELECT count(*) FROM (... LIMIT ^cap)`),
    so multi-million-row tables return immediately at the cap rather than
    waiting for a full aggregate scan. The default (`nil`) preserves the
    existing unbounded behavior. The Mix task `mix threadline.export` does
    NOT pass `:cap` and is unaffected; the operator timeline and export
    controller pass `cap: 10_001` so the LiveView can render
    "10,000+ matches" without hitting `statement_timeout`.
  """
  @spec count_matching(keyword(), keyword()) :: {:ok, %{count: non_neg_integer()}}
  def count_matching(filters, opts \\ []) when is_list(filters) and is_list(opts) do
    OptionKeys.validate!(opts, :count_matching)
    ExportReads.count_matching(filters, opts)
  end

  @doc """
  Returns the canonical CSV header row (one line ending in `\\r\\n`) for the
  operator-surface export controller's chunked path.

  Same column order as `to_csv_iodata/2`. The chunked path emits this as the
  first chunk before streaming data rows so the byte-equality parity test
  holds against the iodata path.

  ## Options

  - `:include_action_metadata` — when `true`, append `correlation_id` and
    `action_id` columns (same shape as `to_csv_iodata/2`).
  """
  @spec csv_header(keyword()) :: [binary()]
  def csv_header(opts \\ []) when is_list(opts) do
    include_meta = Keyword.get(opts, :include_action_metadata, false)

    header =
      if include_meta do
        @csv_header ++ ~w(correlation_id action_id)
      else
        @csv_header
      end

    dump_csv_to_iodata([header])
  end

  @doc """
  Formats a pre-fetched list of `%AuditChange{}` structs into iodata for the
  requested format.

  Used by the operator-surface export controller to format streamed batches;
  CSV header and JSON envelopes are NOT emitted by this function and remain
  the caller's responsibility (the chunked path emits the header / envelope
  as its first / last chunk).

  - `:csv` — CSV data rows (each terminated by `\\r\\n` per RFC 4180); the
    caller MUST emit `csv_header/1` as the first chunk.
  - `:json_wrapped` — each row as `Jason.encode!/1` output (a JSON object).
    The caller emits the surrounding `{"format_version": ..., "generated_at":
    ..., "changes": [` prefix and `]}` suffix as separate chunks plus the
    inter-row comma separators.
  - `:ndjson` — each row as `Jason.encode!/1` output followed by `\\n` (no
    envelope; pure line-delimited JSON).

  ## Options

  - `:include_action_metadata` (default `false`) — same shape as `to_csv_iodata/2`.
  """
  @spec format_changes_iodata([struct()], :csv | :json_wrapped | :ndjson, keyword()) ::
          [binary()]
  def format_changes_iodata(rows, format, opts \\ [])
      when is_list(rows) and is_list(opts) and format in [:csv, :json_wrapped, :ndjson] do
    do_format_changes_iodata(rows, format, opts)
  end

  defp do_format_changes_iodata(rows, :csv, opts) do
    include_meta = Keyword.get(opts, :include_action_metadata, false)
    data_rows = Enum.map(rows, &csv_row(&1, include_meta))
    dump_csv_to_iodata(data_rows)
  end

  defp do_format_changes_iodata(rows, :json_wrapped, _opts) do
    Enum.map(rows, fn row -> Jason.encode!(change_map(row)) end)
  end

  defp do_format_changes_iodata(rows, :ndjson, _opts) do
    Enum.map(rows, fn row -> IO.iodata_to_binary([Jason.encode!(change_map(row)), ?\n]) end)
  end

  defp dump_csv_to_iodata(rows) do
    rows
    |> CSV.dump_to_iodata()
    |> Enum.map(&IO.iodata_to_binary/1)
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

    Stream.resource(
      fn -> :start end,
      fn
        :done ->
          {:halt, :done}

        cursor ->
          case Query.timeline_page(filters, Keyword.put(opts, :cursor, cursor)) do
            %Threadline.Page{entries: [], has_more: false} ->
              {:halt, :done}

            %Threadline.Page{entries: rows, has_more: false} ->
              {rows, :done}

            %Threadline.Page{entries: rows, cursor: cursor} ->
              {rows, cursor}
          end
      end,
      fn _ -> :ok end
    )
  end

  @doc """
  Lazily enumerates the join-projected export-row maps (same shape as
  `to_csv_iodata/2` / `to_json_document/2` consume) in timeline order using
  keyset pages.

  Each emitted item is a map with the keys `:id`, `:transaction_id`,
  `:table_schema`, `:table_name`, `:op`, `:captured_at`, `:table_pk`,
  `:data_after`, `:changed_fields`, `:changed_from`, `:tx_occurred_at`,
  `:tx_actor_ref`, `:tx_source`, `:aa_id`, `:aa_correlation_id` — exactly the
  projection the export query builds. This matches what
  `format_changes_iodata/3` expects, so the operator-surface export
  controller's chunked path produces byte-identical output to the iodata path.

  Does **not** enforce `max_rows` — combine with `Stream.take/2` if needed.

  ## Options

  - `:repo` — optional if present in `filters`
  - `:page_size` — defaults to `1000`
  """
  @spec stream_export_rows(keyword(), keyword()) :: Enumerable.t()
  def stream_export_rows(filters, opts \\ []) when is_list(filters) and is_list(opts) do
    OptionKeys.validate!(opts, :stream_export_rows)
    ExportReads.stream_export_rows(filters, opts)
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

  @doc false
  @spec __option_keys__(atom()) :: [atom()] | :not_closed
  def __option_keys__(name), do: OptionKeys.allowed(name)
end
