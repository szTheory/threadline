defmodule Threadline.Query do
  @moduledoc false

  import Ecto.Query

  alias Threadline.Capture.AuditChange
  alias Threadline.Capture.AuditTransaction
  alias Threadline.Query.{
    ActionHydration,
    Cursors,
    HistoryLimit,
    LegacyOpts,
    RowKey,
    RowReads,
    Scope
  }
  alias Threadline.Semantics.ActorRef
  alias Threadline.Semantics.AuditAction
  alias Threadline.StorageSchema

  @allowed_timeline_filter_keys ~w(repo table table_schema actor_ref from to correlation_id)a
  @allowed_row_history_filter_keys ~w(repo from to)a
  @default_timeline_page_size 1000

  @doc """
  Returns `AuditChange` records for one schema row using timeline ordering,
  with 0.12's unbounded default.

  Deprecated: use `Threadline.row_history/3` instead — this delegates onto
  the hidden raw-read function that backs it, merging `filters` into `opts`
  and defaulting `:limit` to `:infinity` so 0.12 callers stay unbounded.
  """
  @spec row_history(module(), term(), keyword(), keyword()) :: [AuditChange.t()]
  def row_history(schema_module, id, filters \\ [], opts \\ [])
      when is_list(filters) and is_list(opts) do
    RowReads.list(schema_module, id, LegacyOpts.row_history(filters, opts))
  end

  @doc """
  Returns one keyset page of row history for a single schema row.
  """
  @spec row_history_page(module(), term(), keyword(), keyword()) ::
          Threadline.Page.t(AuditChange.t())
  def row_history_page(schema_module, id, filters \\ [], opts \\ [])
      when is_list(filters) and is_list(opts) do
    validate_row_history_filters!(filters)
    repo = timeline_repo!(filters, opts)

    page_size =
      Cursors.timeline_page_size!(Keyword.get(opts, :page_size, @default_timeline_page_size))

    cursor = Cursors.validate_page_cursor!(Keyword.get(opts, :cursor, :start))

    entries =
      schema_module
      |> row_history_query(id, Keyword.put(filters, :repo, repo))
      |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
      |> maybe_after_timeline_cursor(cursor)
      |> limit(^(page_size + 1))
      |> repo.all(storage_opts(filters, opts))

    Cursors.change_page(entries, page_size)
  end

  @doc false
  @spec preload_investigation_context([AuditChange.t()], module(), keyword()) :: [AuditChange.t()]
  def preload_investigation_context(changes, repo, opts \\ [])
      when is_list(changes) and is_atom(repo) and is_list(opts) do
    changes
    |> repo.preload([:transaction], storage_opts([], opts))
    |> hydrate_actions(repo, opts)
  end

  @doc false
  defdelegate hydrate_actions(items, repo, opts \\ []), to: ActionHydration

  @doc """
  Returns one `AuditTransaction` by id or `nil` when the row does not exist.

  Raises `ArgumentError` when `transaction_id` is not a valid UUID.
  """
  @spec audit_transaction(term(), keyword()) :: AuditTransaction.t() | nil
  def audit_transaction(transaction_id, opts) do
    repo = Keyword.fetch!(opts, :repo)
    uuid = validate_audit_transaction_id!(transaction_id)

    transaction =
      AuditTransaction
      |> where([at], at.id == ^uuid)
      |> maybe_apply_scope(transaction_scope_opts(transaction_id, opts))
      |> repo.one(storage_opts([], opts))

    case Keyword.get(opts, :preload) do
      preloads when preloads in [nil, []] ->
        transaction

      preloads when is_list(preloads) or is_atom(preloads) ->
        {action_requested?, preloads} = ActionHydration.extract_action_preload(preloads)
        ActionHydration.maybe_warn_deprecated_action_preload(action_requested?)

        result =
          case preloads do
            [] -> transaction
            _ -> repo.preload(transaction, preloads, storage_opts([], opts))
          end

        if action_requested?, do: hydrate_actions(result, repo, opts), else: result

      other ->
        raise ArgumentError,
              ":preload must be nil, [], an atom, or a list, got: #{inspect(other)}"
    end
  end

  @doc """
  Validates that `filters` contains only timeline filter keys.

  Allowed keys: `:repo`, `:table_schema`, `:table`,
  `:actor_ref`, `:from`, `:to`, `:correlation_id`.

  Returns `:ok` or raises `ArgumentError`.
  """
  @spec validate_timeline_filters!(keyword()) :: :ok
  def validate_timeline_filters!(filters) when is_list(filters) do
    for {key, value} <- filters do
      cond do
        key not in @allowed_timeline_filter_keys ->
          raise ArgumentError,
                "unknown timeline filter key #{inspect(key)}. Allowed: :repo, :table_schema, :table, :actor_ref, :from, :to, :correlation_id. " <>
                  "See `Threadline.Query` and `Threadline.Export`."

        key == :correlation_id ->
          validate_correlation_id_filter!(value)

        true ->
          :ok
      end
    end

    :ok
  end

  @doc """
  Validates row-history helper filters.

  Allowed keys: `:repo`, `:from`, `:to`.
  """
  @spec validate_row_history_filters!(keyword()) :: :ok
  def validate_row_history_filters!(filters) when is_list(filters) do
    for {key, _value} <- filters do
      if key not in @allowed_row_history_filter_keys do
        raise ArgumentError,
              "unknown row_history filter key #{inspect(key)}. Allowed: :repo, :from, :to."
      end
    end

    validate_timeline_filters!(filters)
  end

  defp validate_correlation_id_filter!(nil) do
    raise ArgumentError,
          ":correlation_id cannot be nil — omit the key entirely when you do not want to filter by correlation id."
  end

  defp validate_correlation_id_filter!(value) when not is_binary(value) do
    raise ArgumentError,
          ":correlation_id must be a binary string, got: #{inspect(value)}"
  end

  defp validate_correlation_id_filter!(value) when is_binary(value) do
    trimmed = String.trim(value)

    if trimmed == "" do
      raise ArgumentError,
            ":correlation_id cannot be empty after trimming whitespace — omit the key to disable this filter."
    end

    if byte_size(trimmed) > 256 do
      raise ArgumentError,
            ":correlation_id must be at most 256 UTF-8 bytes after trimming (got #{byte_size(trimmed)})"
    end

    :ok
  end

  @doc """
  Resolves `Ecto.Repo` for `timeline/2`, export, and related APIs.

  Checks `opts` first, then `filters`. Raises `ArgumentError` if missing or not an atom module.
  """
  @spec timeline_repo!(keyword(), keyword()) :: module()
  def timeline_repo!(filters \\ [], opts \\ []) when is_list(filters) and is_list(opts) do
    case Keyword.get(opts, :repo) || Keyword.get(filters, :repo) do
      nil ->
        raise ArgumentError,
              "missing :repo for timeline/export — pass `repo: MyApp.Repo` in filters or opts " <>
                "(see `Threadline.Query.timeline/2` and `Threadline.Export`)."

      repo when is_atom(repo) ->
        repo

      other ->
        raise ArgumentError,
              "timeline/export :repo must be an Ecto.Repo module (atom), got: #{inspect(other)}"
    end
  end

  @doc """
  Builds the shared `AuditChange` query used by `timeline/2` and export.

  Does **not** call `validate_timeline_filters!/1` — callers must validate first
  when accepting external filter lists.
  """
  @spec timeline_query(keyword()) :: Ecto.Query.t()
  def timeline_query(filters) when is_list(filters) do
    filters
    |> timeline_base_query()
    |> filter_by_correlation(filters)
    |> timeline_order()
  end

  @doc """
  Query returning one row per matching change with change + transaction columns
  for export (`Threadline.Export`).

  Validates filters, then builds the same predicate stack as `timeline/2`, adds an
  optional `LEFT JOIN` to `audit_actions` when `:correlation_id` is absent (so JSON
  can surface linked action metadata without changing filter semantics), and selects
  export column maps.
  """
  @spec export_changes_query(keyword()) :: Ecto.Query.t()
  def export_changes_query(filters) when is_list(filters) do
    export_changes_query(filters, [])
  end

  @spec export_changes_query(keyword(), keyword()) :: Ecto.Query.t()
  def export_changes_query(filters, opts) when is_list(filters) and is_list(opts) do
    validate_timeline_filters!(filters)

    base =
      case Keyword.get(filters, :correlation_id) do
        nil ->
          filters
          |> timeline_base_query()
          |> join(:left, [ac, at], aa in AuditAction, on: at.action_id == aa.id)

        _ ->
          filters
          |> timeline_base_query()
          |> filter_by_correlation(filters)
      end
      |> maybe_apply_scope(opts)
      |> timeline_order()

    select(base, [ac, at, aa], %{
      id: ac.id,
      transaction_id: ac.transaction_id,
      table_schema: ac.table_schema,
      table_name: ac.table_name,
      op: ac.op,
      captured_at: ac.captured_at,
      table_pk: ac.table_pk,
      data_after: ac.data_after,
      changed_fields: ac.changed_fields,
      changed_from: ac.changed_from,
      tx_occurred_at: at.occurred_at,
      tx_actor_ref: at.actor_ref,
      tx_source: at.source,
      aa_id: aa.id,
      aa_correlation_id: aa.correlation_id
    })
  end

  @doc """
  Returns one keyset page of `AuditChange` records in timeline order.

  Paging controls live in `opts`:

  - `:page_size` — positive integer, defaults to `#{@default_timeline_page_size}`
  - `:cursor` — `:start` (or omitted) begins a walk; a prior page's `cursor` to
    continue. `cursor: nil` raises `ArgumentError`.
  """
  @spec timeline_page(keyword(), keyword()) :: Threadline.Page.t(AuditChange.t())
  def timeline_page(filters \\ [], opts \\ []) when is_list(filters) and is_list(opts) do
    validate_timeline_filters!(filters)
    repo = timeline_repo!(filters, opts)

    page_size =
      Cursors.timeline_page_size!(Keyword.get(opts, :page_size, @default_timeline_page_size))

    cursor = Cursors.validate_page_cursor!(Keyword.get(opts, :cursor, :start))

    q =
      filters
      |> timeline_query()
      |> maybe_apply_scope(opts)
      |> maybe_after_timeline_cursor(cursor)
      |> limit(^(page_size + 1))

    q =
      case Keyword.get(filters, :correlation_id) do
        nil -> select(q, [ac, _at], ac)
        _ -> select(q, [ac, _at, _aa], ac)
      end

    entries = repo.all(q, storage_opts(filters, opts))

    Cursors.change_page(entries, page_size)
  end

  defp timeline_base_query(filters) do
    AuditChange
    |> join(:inner, [ac], at in AuditTransaction, on: ac.transaction_id == at.id)
    |> filter_by_table_schema(Keyword.get(filters, :table_schema))
    |> filter_by_table(Keyword.get(filters, :table))
    |> filter_by_actor(Keyword.get(filters, :actor_ref))
    |> filter_by_from(Keyword.get(filters, :from))
    |> filter_by_to(Keyword.get(filters, :to))
  end

  # Keyset order: (captured_at DESC, id DESC). The `id` is a stable tiebreaker so the
  # cursor never skips/duplicates rows when two changes share a `captured_at`.
  #
  # The single-column `audit_changes (captured_at)` index covers the leading sort key.
  # A composite `(captured_at, id)` index could also cover the tiebreaker on very deep
  # timelines, but index ownership belongs to the capture migration layer. With
  # microsecond timestamps and random UUID primary keys, ties are rare, so PostgreSQL
  # normally sorts only a singleton `captured_at` group for the second key.
  defp timeline_order(query) do
    query
    |> order_by([ac], desc: ac.captured_at)
    |> order_by([ac], desc: ac.id)
  end

  @doc """
  Returns `AuditChange` records for a given schema record, ordered by
  `captured_at` descending.

  ## Options

  - `:repo` — required `Ecto.Repo` module
  - `:limit` — optional positive integer, caps to the n most recent changes
    (`captured_at desc, id desc`); it does not page — use `row_history_page/4`.
    `nil` (default) is unbounded; invalid values raise `ArgumentError`.

  ## Examples

      Threadline.history(MyApp.User, 42, repo: MyApp.Repo)
      Threadline.history(MyApp.LineItem, [tenant_id: 1, id: 5], repo: MyApp.Repo)
      Threadline.history(MyApp.LineItem, %{"tenant_id" => 1, "id" => 5}, repo: MyApp.Repo)
      Threadline.history(MyApp.User, 42, repo: MyApp.Repo, limit: 20)

  Each `AuditChange` loads all table columns mapped on the schema, including
  `changed_from` when the database column is populated (no narrowing `select`).

  `id` names every key field: the schema's field names, or a `primary_key:`
  override's declared columns when one is configured for the table. A missing,
  extra, or misnamed key, a `nil` value, a scalar for a composite table, or a
  loaded struct all raise `ArgumentError` (via the internal row-key
  normalizer).

  If `:scope_query_fn` is configured, it should only add predicates: it
  receives `id` unchanged as `context.params.id` — exactly what the caller
  passed, not the normalized key list — and a limit it sets is overridden by
  `:limit`'s final `LIMIT`; the cap counts only rows the scope predicate left
  in scope.

  History for a table that has since been dropped or renamed keeps working:
  each key column's comparison type falls back to the schema field's Ecto
  type when the catalog no longer has a live entry. The one inexact case is a
  fixed-width `char(n)` key, whose stored blank-padding the fallback cannot
  reproduce — pass the value already padded to the original column width.
  """
  def history(schema_module, id, opts) do
    repo = Keyword.fetch!(opts, :repo)
    HistoryLimit.validate!(Keyword.get(opts, :limit))

    schema_module
    |> history_query(id, Keyword.put(opts, :repo, repo))
    |> repo.all(storage_opts([], opts))
  end

  @doc false
  @spec history_query(module(), term(), keyword()) :: Ecto.Query.t()
  def history_query(schema_module, id, opts) when is_list(opts) do
    repo = Keyword.fetch!(opts, :repo)
    matched = RowKey.match!(schema_module, id, repo)

    AuditChange
    |> where_row(matched)
    |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
    |> order_by([ac], desc: ac.captured_at)
    |> order_by([ac], desc: ac.id)
    |> HistoryLimit.apply(Keyword.get(opts, :limit))
  end

  # Applies the three `where`s every read function in this module needs:
  # table_schema, table_name, and a whole-map equality match on table_pk
  # (never a per-key predicate, so the row-history index stays usable).
  # `where([ac], ...)` only names the first binding, so this works whether
  # `query` is a bare `AuditChange` query or `timeline_base_query`'s joined
  # `[ac, at]` query.
  defp where_row(query, %{table_schema: table_schema, table_name: table_name, table_pk: table_pk}) do
    query
    |> where([ac], ac.table_schema == ^table_schema)
    |> where([ac], ac.table_name == ^table_name)
    |> where([ac], ac.table_pk == type(^table_pk, :map))
  end

  @doc false
  @spec row_history_query(module(), term(), keyword()) :: Ecto.Query.t()
  def row_history_query(schema_module, id, filters \\ []) when is_list(filters) do
    repo = timeline_repo!(filters, [])
    matched = RowKey.match!(schema_module, id, repo)

    filters
    |> timeline_base_query()
    |> where_row(matched)
    |> timeline_order()
    |> select([ac, _at], ac)
  end

  @doc """
  Returns the latest stored row snapshot for a schema record at or before `timestamp`.

  Returns `{:ok, map}` when the latest matching snapshot is an insert/update row,
  `{:error, :deleted_record}` when the latest snapshot is a delete, and
  `{:error, :before_audit_horizon}` when the row has no snapshot at or before the
  requested timestamp.

  ## Examples

      Threadline.as_of(MyApp.User, 42, ~U[2026-01-01 00:00:00Z], repo: MyApp.Repo)
      Threadline.as_of(MyApp.LineItem, [tenant_id: 1, id: 5], ts, repo: MyApp.Repo)

  `id` accepts the same scalar, map, and keyword-list shapes as `history/3`,
  keyed by schema field names (or a `primary_key:` override's declared
  columns), and raises the same `ArgumentError` cases for a missing, extra, or
  misnamed key, a `nil` value, a scalar for a composite table, or a loaded
  struct. If `:scope_query_fn` is configured, it receives `id` unchanged as
  `context.params.id`.

  History of a dropped or renamed table, or a retyped key column, keeps
  working via the same Ecto-type fallback as `history/3` — including the
  `char(n)` blank-padding caveat.
  """
  def as_of(schema_module, id, timestamp, opts) do
    repo = Keyword.fetch!(opts, :repo)

    snapshot =
      schema_module
      |> as_of_query(id, timestamp, opts)
      |> repo.one(storage_opts([], opts))

    case snapshot do
      %AuditChange{op: "delete"} -> {:error, :deleted_record}
      %AuditChange{data_after: data_after} -> load_as_of_snapshot(schema_module, data_after, opts)
      nil -> {:error, :before_audit_horizon}
    end
  end

  @doc false
  @spec as_of_query(module(), term(), DateTime.t(), keyword()) :: Ecto.Query.t()
  def as_of_query(schema_module, id, timestamp, opts) do
    repo = Keyword.fetch!(opts, :repo)
    matched = RowKey.match!(schema_module, id, repo)

    AuditChange
    |> where_row(matched)
    |> where([ac], ac.captured_at <= ^timestamp)
    |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
    |> order_by([ac], desc: ac.captured_at)
    |> order_by([ac], desc: ac.id)
    |> limit(1)
  end

  defp load_as_of_snapshot(schema_module, data_after, opts) do
    if Keyword.get(opts, :cast, false) do
      try do
        {:ok, Ecto.embedded_load(schema_module, data_after, :json)}
      rescue
        e in [ArgumentError, Ecto.ChangeError] ->
          {:error, {:cast_error, Exception.message(e)}}
      end
    else
      {:ok, data_after}
    end
  end

  @doc """
  Returns a `%Threadline.Page{}` of `AuditTransaction` records for a given actor,
  ordered by `occurred_at` descending, then `id` descending.

  For an anonymous actor, returns every transaction whose actor identity is absent.
  Anonymous transactions intentionally have no finer-grained actor distinction, so
  they are equivalent for this query.

  ## Options

  - `:repo` — required `Ecto.Repo` module
  - `:cursor` — `:start` (or omitted) begins a walk; a prior page's `cursor` to
    continue it older; `{:before, cursor}` to continue it newer. `cursor: nil`
    raises `ArgumentError`.
  - `:page_size` — positive integer, defaults to 50
  - `:from` — inclusive lower bound on `occurred_at`
  - `:to` — inclusive upper bound on `occurred_at`

  ## Deprecated options

  - `:after` — use `:cursor` instead
  - `:before` — use `cursor: {:before, cursor}` instead
  - `:limit` — use `:page_size` instead

  Each still works, and each emits one deprecation warning per call. Removal
  is no earlier than Threadline 2.0. `:cursor` combined with `:after` or
  `:before` raises `ArgumentError`, as does `:page_size` combined with
  `:limit`.

  ## Example

      Threadline.actor_history(actor_ref, repo: MyApp.Repo)
  """
  @spec actor_history(ActorRef.t(), keyword()) :: Threadline.Page.t(AuditTransaction.t())
  def actor_history(%ActorRef{} = actor_ref, opts) do
    repo = Keyword.fetch!(opts, :repo)
    actor_map = ActorRef.to_map(actor_ref)

    {raw_cursor, raw_page_size} = LegacyOpts.actor_history(opts)
    page_size = Cursors.timeline_page_size!(raw_page_size)
    {cursor_map, direction} = Cursors.validate_actor_history_page_cursor!(raw_cursor)

    {before_cursor, after_cursor} =
      case direction do
        :forward -> {nil, cursor_map}
        :backward -> {cursor_map, nil}
      end

    base_query =
      AuditTransaction
      |> where([at], fragment("? @> ?::jsonb", at.actor_ref, ^actor_map))
      |> Cursors.actor_history_filter_from(Keyword.get(opts, :from))
      |> Cursors.actor_history_filter_to(Keyword.get(opts, :to))
      |> maybe_apply_scope(actor_history_scope_opts(actor_ref, opts))

    {query, _reverse?} = Cursors.actor_history_window(base_query, before_cursor, after_cursor)

    entries_raw =
      query
      |> limit(^(page_size + 1))
      |> repo.all(storage_opts([], opts))

    Cursors.actor_history_page(entries_raw, page_size, direction)
  end

  @doc """
  Returns every `%AuditChange{}` for a single capture transaction.

  `transaction_id` is `audit_transactions.id` — the same column as
  `AuditChange.transaction_id` (`:binary_id`). Accepts UUID strings or 16-byte
  binaries per `Ecto.UUID.cast/1`.

  ## Ordering

  Same total order as `timeline/2`: `captured_at` descending, then `id` descending
  (via `timeline_order/1`). Random `binary_id` values are **not** a monotonic
  sequence; ordering is only defined on `(captured_at, id)`.

  ## Empty results

  Returns `[]` when the UUID is well-formed but no `audit_changes` rows match
  (whether the parent transaction row exists or not).

  ## Options

  - `:repo` — required `Ecto.Repo` module (`Keyword.fetch!/2` if missing).
  - `:preload` — optional association list for `repo.preload/3` when non-empty
    (intended: `[:transaction]`). `:action` under `:transaction`
    (`transaction: :action` / `transaction: [:action, ...]`) is deprecated:
    it still hydrates `transaction.action`, but emits one warning per call
    and will be removed no earlier than Threadline 2.0.

  ## Errors

  Raises `ArgumentError` with message containing `invalid audit transaction id`
  when `transaction_id` fails UUID cast (before hitting Postgrex).
  """
  @spec audit_changes_for_transaction(term(), keyword()) :: [AuditChange.t()]
  def audit_changes_for_transaction(transaction_id, opts) do
    repo = Keyword.fetch!(opts, :repo)
    uuid = validate_audit_transaction_id!(transaction_id)

    results =
      AuditChange
      |> where([ac], ac.transaction_id == ^uuid)
      |> join(:inner, [ac], at in AuditTransaction, on: ac.transaction_id == at.id)
      |> maybe_apply_scope(transaction_scope_opts(transaction_id, opts))
      |> timeline_order()
      |> select([ac, _at], ac)
      |> repo.all(storage_opts([], opts))

    case Keyword.get(opts, :preload) do
      preloads when preloads in [nil, []] ->
        results

      preloads when is_list(preloads) ->
        {action_requested?, preloads} = ActionHydration.extract_tx_action_preload(preloads)
        ActionHydration.maybe_warn_deprecated_action_preload(action_requested?)

        result =
          case preloads do
            [] -> results
            _ -> repo.preload(results, preloads, storage_opts([], opts))
          end

        if action_requested?, do: hydrate_actions(result, repo, opts), else: result

      other ->
        raise ArgumentError,
              ":preload must be nil, [], or a list, got: #{inspect(other)}"
    end
  end

  defp validate_audit_transaction_id!(transaction_id) do
    case Ecto.UUID.cast(transaction_id) do
      :error ->
        raise ArgumentError,
              "invalid audit transaction id: #{inspect(transaction_id)}"

      {:ok, canonical} ->
        canonical
    end
  end

  @doc """
  Returns `AuditChange` records across tables, filtered by the given options,
  ordered by `captured_at` descending, then `id` descending.

  ## Options

  - `:table` — string or atom; filters by `table_name`
  - `:table_schema` — string or atom; filters by captured host table schema
  - `:actor_ref` — `%ActorRef{}`; filters by actor via joined `audit_transactions`
  - `:from` — `DateTime`; inclusive lower bound on `captured_at`
  - `:to` — `DateTime`; inclusive upper bound on `captured_at`
  - `:correlation_id` — binary; strict filter on linked `AuditAction.correlation_id` (see moduledoc / CHANGELOG)
  - `:repo` — required `Ecto.Repo` module (in `filters` or `opts`; see `Threadline.Export`)
  - `:storage_schema` — optional Threadline storage schema override

  ## Example

      Threadline.timeline(table: "users", from: ~U[2026-01-01 00:00:00Z], repo: MyApp.Repo)

  ## See also

  - `Threadline.Export` — CSV / JSON export using the same filter vocabulary.
  - `Threadline.export_csv/2` and `Threadline.export_json/2` — top-level delegators.
  """
  def timeline(filters \\ [], opts \\ []) do
    validate_timeline_filters!(filters)
    repo = timeline_repo!(filters, opts)

    q =
      filters
      |> timeline_query()
      |> maybe_apply_scope(opts)

    q =
      case Keyword.get(filters, :correlation_id) do
        nil -> select(q, [ac, at], ac)
        _ -> select(q, [ac, at, _aa], ac)
      end

    repo.all(q, storage_opts(filters, opts))
  end

  @doc false
  def maybe_apply_scope(query, opts) do
    Scope.apply(query, opts)
  end

  @doc false
  def storage_opts(filters \\ [], opts \\ []) do
    StorageSchema.repo_opts(storage_schema_opts(filters, opts))
  end

  defp storage_schema_opts(_filters, opts) do
    case Keyword.get(opts, :storage_schema) do
      nil -> []
      storage_schema -> [storage_schema: storage_schema]
    end
  end

  defp actor_history_scope_opts(actor_ref, opts) do
    [
      scope: Keyword.get(opts, :scope),
      scope_query_fn: Keyword.get(opts, :scope_query_fn),
      surface: Keyword.get(opts, :surface, :actor_history),
      params: %{
        actor_ref: actor_ref,
        from: Keyword.get(opts, :from),
        to: Keyword.get(opts, :to),
        after: Keyword.get(opts, :after),
        before: Keyword.get(opts, :before)
      }
    ]
  end

  @doc false
  def row_history_scope_opts(schema_module, id, opts) do
    [
      scope: Keyword.get(opts, :scope),
      scope_query_fn: Keyword.get(opts, :scope_query_fn),
      surface: Keyword.get(opts, :surface, :row_history),
      params: %{schema_module: schema_module, id: id}
    ]
  end

  defp transaction_scope_opts(transaction_id, opts) do
    [
      scope: Keyword.get(opts, :scope),
      scope_query_fn: Keyword.get(opts, :scope_query_fn),
      surface: Keyword.get(opts, :surface, :transaction),
      params: %{transaction_id: transaction_id}
    ]
  end

  @doc false
  @spec maybe_after_timeline_cursor(Ecto.Query.t(), Threadline.Page.change_cursor() | nil) ::
          Ecto.Query.t()
  def maybe_after_timeline_cursor(query, nil), do: query

  def maybe_after_timeline_cursor(query, %{captured_at: %DateTime{} = captured_at, id: id}) do
    where(
      query,
      [ac],
      fragment(
        "(?, ?) < (?, ?)",
        ac.captured_at,
        ac.id,
        ^captured_at,
        type(^id, :binary_id)
      )
    )
  end

  defp filter_by_table(query, nil), do: query

  defp filter_by_table(query, table) when is_atom(table) do
    filter_by_table(query, to_string(table))
  end

  defp filter_by_table(query, table) when is_binary(table) do
    where(query, [ac], ac.table_name == ^table)
  end

  defp filter_by_table_schema(query, nil), do: query

  defp filter_by_table_schema(query, schema) when is_atom(schema) do
    filter_by_table_schema(query, to_string(schema))
  end

  defp filter_by_table_schema(query, schema) when is_binary(schema) do
    where(query, [ac], ac.table_schema == ^schema)
  end

  defp filter_by_actor(query, nil), do: query

  defp filter_by_actor(query, %ActorRef{} = actor_ref) do
    actor_map = ActorRef.to_map(actor_ref)

    where(query, [ac, at], fragment("? @> ?::jsonb", at.actor_ref, ^actor_map))
  end

  defp filter_by_from(query, nil), do: query

  defp filter_by_from(query, %DateTime{} = from) do
    where(query, [ac], ac.captured_at >= ^from)
  end

  defp filter_by_to(query, nil), do: query

  defp filter_by_to(query, %DateTime{} = to) do
    where(query, [ac], ac.captured_at <= ^to)
  end

  defp filter_by_correlation(query, filters) do
    case Keyword.get(filters, :correlation_id) do
      nil ->
        query

      cid when is_binary(cid) ->
        cid = String.trim(cid)

        join(query, :inner, [ac, at], aa in AuditAction,
          on: at.action_id == aa.id and aa.correlation_id == ^cid
        )
    end
  end
end
