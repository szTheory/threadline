defmodule Threadline.Query.RowReads do
  @moduledoc false

  # The hidden raw-read primitive behind `Threadline.row_history/3`: a bare
  # list capped at `@default_limit` by default, with `:limit` overrides and
  # a `page/3` keyset-cursor mode added alongside it. Kept separate from
  # `Threadline.Query` so the row-history read path's size stays bounded on
  # its own file rather than growing the shared query module.

  import Ecto.Query

  alias Threadline.Capture.AuditChange
  alias Threadline.Query
  alias Threadline.Query.Cursors
  alias Threadline.Query.HistoryLimit

  @default_limit 200
  @default_page_size 1000

  @doc """
  Returns `AuditChange` rows for one schema row, unbounded by default — the
  raw read behind the deprecated `Threadline.history/3` and
  `Threadline.Query.history/3`, which keep their 0.12 return shape (bare
  `AuditChange`, not `LinkedChange`) and unbounded default.

  `:limit` resolution mirrors `HistoryLimit`: `nil` or `:infinity` is
  unbounded; a positive integer caps; anything else raises `ArgumentError`.
  """
  @spec audit_changes(module(), term(), keyword()) :: [AuditChange.t()]
  def audit_changes(schema_module, id, opts) when is_list(opts) do
    repo = Keyword.fetch!(opts, :repo)
    HistoryLimit.validate!(Keyword.get(opts, :limit))

    schema_module
    |> Query.history_query(id, Keyword.put(opts, :repo, repo))
    |> repo.all(Query.storage_opts([], opts))
  end

  @doc """
  Returns at most `@default_limit` `AuditChange` rows for one schema row,
  newest first, unless `opts` overrides the cap.

  `:limit` resolution:

  - absent — capped at #{@default_limit}; fires
    `[:threadline, :row_history, :truncated]` when more rows existed
  - `:infinity` — unbounded
  - a positive integer `n` — capped at `n`
  - anything else — raises `ArgumentError`
  """
  @spec list(module(), term(), keyword()) :: [AuditChange.t()]
  def list(schema_module, id, opts) when is_list(opts) do
    repo = Query.timeline_repo!([], opts)
    query = base_query(schema_module, id, opts)

    case Keyword.fetch(opts, :limit) do
      :error ->
        fetch_default(query, schema_module, repo, opts)

      {:ok, :infinity} ->
        repo.all(query, Query.storage_opts([], opts))

      {:ok, n} when is_integer(n) and n > 0 ->
        # An explicit `limit: n` never fires the truncation telemetry, even
        # when the true row count also exceeds `n` — only the implicit
        # default cap below does. This is intentional: the truncation event
        # is hardcoded to the default cap's measurement, not the caller's
        # `n`, so a symmetric emit here would misreport the limit that was
        # actually hit. Do not add one.
        query
        |> limit(^n)
        |> repo.all(Query.storage_opts([], opts))

      {:ok, other} ->
        raise ArgumentError,
              ":limit must be a positive integer or :infinity, got: #{inspect(other)}"
    end
  end

  @doc """
  Returns one keyset page of `AuditChange` rows for one schema row.

  `opts` must carry `:cursor` (`:start` to begin a walk, or a prior page's
  `cursor` to continue it) and may carry `:page_size` (positive integer,
  defaults to #{@default_page_size}).
  """
  @spec page(module(), term(), keyword()) :: Threadline.Page.t(AuditChange.t())
  def page(schema_module, id, opts) when is_list(opts) do
    repo = Query.timeline_repo!([], opts)
    page_size = Cursors.timeline_page_size!(Keyword.get(opts, :page_size, @default_page_size))
    cursor = Cursors.validate_page_cursor!(Keyword.fetch!(opts, :cursor))

    entries =
      schema_module
      |> base_query(id, opts)
      |> Query.maybe_after_timeline_cursor(cursor)
      |> limit(^(page_size + 1))
      |> repo.all(Query.storage_opts([], opts))

    Cursors.change_page(entries, page_size)
  end

  defp base_query(schema_module, id, opts) do
    schema_module
    |> Query.row_history_query(id, Keyword.take(opts, [:repo, :from, :to]))
    |> Query.maybe_apply_scope(Query.row_history_scope_opts(schema_module, id, opts))
  end

  defp fetch_default(query, schema_module, repo, opts) do
    rows =
      query
      |> limit(^(@default_limit + 1))
      |> repo.all(Query.storage_opts([], opts))

    if length(rows) > @default_limit do
      Threadline.Telemetry.emit_row_history_truncated(@default_limit, schema_module)
      Enum.take(rows, @default_limit)
    else
      rows
    end
  end
end
