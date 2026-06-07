defmodule Threadline.Query do
  @moduledoc """
  Ecto query implementations for the Threadline public API.

  All functions require an explicit `:repo` option and return plain lists of
  Ecto structs. DB errors propagate as exceptions, consistent with `Ecto.Repo.all/2`.

  ## Timeline filters

  `timeline/2`, `timeline_query/1`, and `Threadline.Export` accept the same
  filter keyword list. Only these keys are allowed: `:repo`, `:table_schema`,
  `:table`, `:actor_ref`, `:from`, `:to`, `:correlation_id`.
  Unknown keys raise `ArgumentError` (breaking vs
  pre-1.0 callers that relied on silent ignores — see CHANGELOG when upgrading).

  When `:correlation_id` is set to a non-empty string (after trimming), results are
  limited to changes whose transaction is linked to an `audit_actions` row with that
  `correlation_id` (strict inner-join semantics; see CHANGELOG). Omit the key to leave
  correlation out of the filter.

  Use `timeline_repo!/2` to resolve `:repo` from filters and opts with the same
  messages as export entrypoints.

  ## See also

  - `Threadline.Export` — CSV / JSON export using the same filter vocabulary.
  - `audit_changes_for_transaction/2` — all changes for one `audit_transactions.id` (transaction drill-down vs `timeline/2` slices).
  """

  import Ecto.Query

  alias Threadline.Capture.AuditChange
  alias Threadline.Capture.AuditTransaction
  alias Threadline.OperatorSurface.Scope, as: OperatorScope
  alias Threadline.Semantics.ActorRef
  alias Threadline.Semantics.AuditAction
  alias Threadline.StorageSchema

  @allowed_timeline_filter_keys ~w(repo table table_schema actor_ref from to correlation_id)a
  @allowed_row_history_filter_keys ~w(repo from to)a
  @default_timeline_page_size 1000

  defmodule TimelinePage do
    @moduledoc """
    One keyset page from the timeline query layer.
    """

    @enforce_keys [:entries]
    defstruct [:entries, :next_cursor]

    @type cursor :: %{captured_at: DateTime.t(), id: Ecto.UUID.t()}
    @type t :: %__MODULE__{
            entries: [AuditChange.t()],
            next_cursor: cursor() | nil
          }
  end

  @doc """
  Returns `AuditChange` records for one schema row using timeline ordering.

  The helper fixes `table_name` and primary-key containment internally so callers
  do not need to construct low-level row predicates.
  """
  @spec row_history(module(), term(), keyword(), keyword()) :: [AuditChange.t()]
  def row_history(schema_module, id, filters \\ [], opts \\ [])
      when is_list(filters) and is_list(opts) do
    validate_row_history_filters!(filters)
    repo = timeline_repo!(filters, opts)

    schema_module
    |> row_history_query(id, filters)
    |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
    |> repo.all(storage_opts(filters, opts))
  end

  @doc """
  Returns one keyset page of row history for a single schema row.
  """
  @spec row_history_page(module(), term(), keyword(), keyword()) :: TimelinePage.t()
  def row_history_page(schema_module, id, filters \\ [], opts \\ [])
      when is_list(filters) and is_list(opts) do
    validate_row_history_filters!(filters)
    repo = timeline_repo!(filters, opts)

    page_size =
      validate_timeline_page_size!(Keyword.get(opts, :page_size, @default_timeline_page_size))

    cursor = validate_timeline_cursor!(Keyword.get(opts, :cursor))

    entries =
      schema_module
      |> row_history_query(id, filters)
      |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
      |> maybe_after_timeline_cursor(cursor)
      |> limit(^page_size)
      |> repo.all(storage_opts(filters, opts))

    %TimelinePage{
      entries: entries,
      next_cursor: timeline_page_next_cursor(entries, page_size)
    }
  end

  @doc false
  @spec preload_investigation_context([AuditChange.t()], module()) :: [AuditChange.t()]
  def preload_investigation_context(changes, repo) when is_list(changes) and is_atom(repo) do
    repo.preload(changes, transaction: :action)
  end

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
        repo.preload(transaction, preloads)

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
  - `:cursor` — `%{captured_at: %DateTime{}, id: binary}` or `nil`
  """
  @spec timeline_page(keyword(), keyword()) :: TimelinePage.t()
  def timeline_page(filters \\ [], opts \\ []) when is_list(filters) and is_list(opts) do
    validate_timeline_filters!(filters)
    repo = timeline_repo!(filters, opts)

    page_size =
      validate_timeline_page_size!(Keyword.get(opts, :page_size, @default_timeline_page_size))

    cursor = validate_timeline_cursor!(Keyword.get(opts, :cursor))

    q =
      filters
      |> timeline_query()
      |> maybe_apply_scope(opts)
      |> maybe_after_timeline_cursor(cursor)
      |> limit(^page_size)

    q =
      case Keyword.get(filters, :correlation_id) do
        nil -> select(q, [ac, _at], ac)
        _ -> select(q, [ac, _at, _aa], ac)
      end

    entries = repo.all(q, storage_opts(filters, opts))

    %TimelinePage{
      entries: entries,
      next_cursor: timeline_page_next_cursor(entries, page_size)
    }
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

  ## Example

      Threadline.history(MyApp.User, user.id, repo: MyApp.Repo)

  Each `AuditChange` loads all table columns mapped on the schema, including
  `changed_from` when the database column is populated (no narrowing `select`).
  """
  def history(schema_module, id, opts) do
    repo = Keyword.fetch!(opts, :repo)
    table = schema_module.__schema__(:source)
    table_schema = schema_module.__schema__(:prefix) || "public"
    [pk_field] = schema_module.__schema__(:primary_key)
    pk_map = %{to_string(pk_field) => id}

    AuditChange
    |> where([ac], ac.table_schema == ^table_schema)
    |> where([ac], ac.table_name == ^table)
    |> where([ac], fragment("? @> ?::jsonb", ac.table_pk, ^pk_map))
    |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
    |> order_by([ac], desc: ac.captured_at)
    |> repo.all(storage_opts([], opts))
  end

  @doc false
  @spec row_history_query(module(), term(), keyword()) :: Ecto.Query.t()
  def row_history_query(schema_module, id, filters \\ []) when is_list(filters) do
    table = schema_module.__schema__(:source)
    table_schema = schema_module.__schema__(:prefix) || "public"
    [pk_field] = schema_module.__schema__(:primary_key)
    pk_map = %{to_string(pk_field) => id}

    filters
    |> timeline_base_query()
    |> where([ac, _at], ac.table_schema == ^table_schema)
    |> where([ac, _at], ac.table_name == ^table)
    |> where([ac, _at], fragment("? @> ?::jsonb", ac.table_pk, ^pk_map))
    |> timeline_order()
    |> select([ac, _at], ac)
  end

  @doc """
  Returns the latest stored row snapshot for a schema record at or before `timestamp`.

  Returns `{:ok, map}` when the latest matching snapshot is an insert/update row,
  `{:error, :deleted_record}` when the latest snapshot is a delete, and
  `{:error, :before_audit_horizon}` when the row has no snapshot at or before the
  requested timestamp.
  """
  def as_of(schema_module, id, timestamp, opts) do
    repo = Keyword.fetch!(opts, :repo)
    table = schema_module.__schema__(:source)
    table_schema = schema_module.__schema__(:prefix) || "public"
    [pk_field] = schema_module.__schema__(:primary_key)
    pk_map = %{to_string(pk_field) => id}

    snapshot =
      AuditChange
      |> where([ac], ac.table_schema == ^table_schema)
      |> where([ac], ac.table_name == ^table)
      |> where([ac], fragment("? @> ?::jsonb", ac.table_pk, ^pk_map))
      |> where([ac], ac.captured_at <= ^timestamp)
      |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
      |> order_by([ac], desc: ac.captured_at)
      |> order_by([ac], desc: ac.id)
      |> limit(1)
      |> repo.one(storage_opts([], opts))

    case snapshot do
      %AuditChange{op: "delete"} -> {:error, :deleted_record}
      %AuditChange{data_after: data_after} -> load_as_of_snapshot(schema_module, data_after, opts)
      nil -> {:error, :before_audit_horizon}
    end
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
  Returns a keyset page of `AuditTransaction` records for a given actor, ordered by
  `occurred_at` descending, then `id` descending.

  For anonymous actors, returns all anonymous transactions (no actor_id
  distinction — all anonymous transactions are equivalent by design, per ACTR-03).

  ## Options

  - `:repo` — required `Ecto.Repo` module
  - `:limit` — integer, maximum number of records to return (default 50)
  - `:after` — cursor to fetch older records
  - `:before` — cursor to fetch newer records
  - `:from` — inclusive lower bound on `occurred_at`
  - `:to` — inclusive upper bound on `occurred_at`

  ## Example

      Threadline.actor_history(actor_ref, repo: MyApp.Repo)
  """
  def actor_history(%ActorRef{} = actor_ref, opts) do
    repo = Keyword.fetch!(opts, :repo)
    actor_map = ActorRef.to_map(actor_ref)
    limit = Keyword.get(opts, :limit, 50)
    after_cursor = validate_actor_history_cursor!(Keyword.get(opts, :after))
    before_cursor = validate_actor_history_cursor!(Keyword.get(opts, :before))

    base_query =
      AuditTransaction
      |> where([at], fragment("? @> ?::jsonb", at.actor_ref, ^actor_map))
      |> actor_history_filter_from(Keyword.get(opts, :from))
      |> actor_history_filter_to(Keyword.get(opts, :to))
      |> maybe_apply_scope(actor_history_scope_opts(actor_ref, opts))

    {query, reverse?} =
      cond do
        before_cursor != nil ->
          {base_query
           |> actor_history_before_cursor(before_cursor)
           |> order_by([at], asc: at.occurred_at, asc: at.id), true}

        after_cursor != nil ->
          {base_query
           |> actor_history_after_cursor(after_cursor)
           |> order_by([at], desc: at.occurred_at, desc: at.id), false}

        true ->
          {base_query
           |> order_by([at], desc: at.occurred_at, desc: at.id), false}
      end

    entries_raw =
      query
      |> limit(^(limit + 1))
      |> repo.all(storage_opts([], opts))

    {entries, has_more?} =
      if length(entries_raw) > limit do
        if reverse? do
          {entries_raw |> Enum.reverse() |> Enum.drop(1), true}
        else
          {entries_raw |> Enum.take(limit), true}
        end
      else
        if reverse? do
          {Enum.reverse(entries_raw), false}
        else
          {entries_raw, false}
        end
      end

    has_next? = if reverse?, do: true, else: has_more?
    has_prev? = if reverse?, do: has_more?, else: after_cursor != nil

    next_cursor =
      if has_next? and entries != [] do
        %{occurred_at: List.last(entries).occurred_at, id: List.last(entries).id}
      end

    prev_cursor =
      if has_prev? and entries != [] do
        %{occurred_at: List.first(entries).occurred_at, id: List.first(entries).id}
      end

    %Threadline.Query.ActorHistoryPage{
      entries: entries,
      next_cursor: next_cursor,
      prev_cursor: prev_cursor
    }
  end

  defp actor_history_filter_from(query, nil), do: query

  defp actor_history_filter_from(query, %DateTime{} = from) do
    where(query, [at], at.occurred_at >= ^from)
  end

  defp actor_history_filter_to(query, nil), do: query

  defp actor_history_filter_to(query, %DateTime{} = to) do
    where(query, [at], at.occurred_at <= ^to)
  end

  defp actor_history_after_cursor(query, %{occurred_at: %DateTime{} = occurred_at, id: id}) do
    where(
      query,
      [at],
      fragment(
        "(?, ?) < (?, ?)",
        at.occurred_at,
        at.id,
        ^occurred_at,
        type(^id, :binary_id)
      )
    )
  end

  defp actor_history_before_cursor(query, %{occurred_at: %DateTime{} = occurred_at, id: id}) do
    where(
      query,
      [at],
      fragment(
        "(?, ?) > (?, ?)",
        at.occurred_at,
        at.id,
        ^occurred_at,
        type(^id, :binary_id)
      )
    )
  end

  defp validate_actor_history_cursor!(nil), do: nil

  defp validate_actor_history_cursor!(%{occurred_at: %DateTime{} = occurred_at, id: id})
       when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, canonical} -> %{occurred_at: occurred_at, id: canonical}
      :error -> raise ArgumentError, "cursor.id must be a UUID binary, got: #{inspect(id)}"
    end
  end

  defp validate_actor_history_cursor!(%{} = cursor) do
    has_occurred_at? = Map.has_key?(cursor, :occurred_at)
    has_id? = Map.has_key?(cursor, :id)

    cond do
      has_occurred_at? or has_id? ->
        raise ArgumentError,
              "cursor must include both :occurred_at and :id or be nil, got: #{inspect(cursor)}"

      true ->
        raise ArgumentError,
              "cursor must be nil or %{occurred_at: %DateTime{}, id: uuid}, got: #{inspect(cursor)}"
    end
  end

  defp validate_actor_history_cursor!(cursor) do
    raise ArgumentError,
          "cursor must be nil or %{occurred_at: %DateTime{}, id: uuid}, got: #{inspect(cursor)}"
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
    (intended: `[:transaction]`).

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
        repo.preload(results, preloads)

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
    OperatorScope.apply(query, opts)
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

  defp row_history_scope_opts(schema_module, id, opts) do
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
  @spec maybe_after_timeline_cursor(Ecto.Query.t(), TimelinePage.cursor() | nil) :: Ecto.Query.t()
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

  defp validate_timeline_page_size!(page_size) when is_integer(page_size) and page_size > 0,
    do: page_size

  defp validate_timeline_page_size!(page_size) do
    raise ArgumentError,
          ":page_size must be a positive integer, got: #{inspect(page_size)}"
  end

  defp validate_timeline_cursor!(nil), do: nil

  defp validate_timeline_cursor!(%{captured_at: %DateTime{} = captured_at, id: id})
       when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, canonical} -> %{captured_at: captured_at, id: canonical}
      :error -> raise ArgumentError, ":cursor.id must be a UUID binary, got: #{inspect(id)}"
    end
  end

  defp validate_timeline_cursor!(%{} = cursor) do
    has_captured_at? = Map.has_key?(cursor, :captured_at)
    has_id? = Map.has_key?(cursor, :id)

    cond do
      has_captured_at? or has_id? ->
        raise ArgumentError,
              ":cursor must include both :captured_at and :id or be nil, got: #{inspect(cursor)}"

      true ->
        raise ArgumentError,
              ":cursor must be nil or %{captured_at: %DateTime{}, id: uuid}, got: #{inspect(cursor)}"
    end
  end

  defp validate_timeline_cursor!(cursor) do
    raise ArgumentError,
          ":cursor must be nil or %{captured_at: %DateTime{}, id: uuid}, got: #{inspect(cursor)}"
  end

  defp timeline_page_next_cursor(entries, page_size) when length(entries) < page_size, do: nil

  defp timeline_page_next_cursor(entries, _page_size) do
    last = List.last(entries)
    %{captured_at: last.captured_at, id: last.id}
  end

  # --- Private filter pipeline (expects `at` binding from timeline_query) ---

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
