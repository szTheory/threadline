defmodule Threadline do
  @moduledoc """
  Audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL.

  Threadline combines trigger-backed row-change capture, rich action semantics
  (actor/intent/context), and operator-grade exploration.

  ## Reading audit data

  The functions on this module (see the function list below) are the
  supported read API — including `timeline/2`, `timeline_page/2`,
  `row_history/3`, `as_of/4`, `actor_history/2`, `actor_window/3`,
  `correlation_bundle/3`, `audit_transaction/2`, `transaction_context/2`,
  `incident_bundle/2`, `audit_changes_for_transaction/2`, `export_csv/2`, and
  `export_json/2`.
  Build on these rather than on the internal modules behind them. Older
  names (`history/3`, `row_history/4`, `row_history_page/4`,
  `actor_window_page/3`, `correlation_bundle_page/3`) remain as deprecated
  delegates through Threadline 1.x.

  Each single-subject lookup (`audit_transaction/2`, `transaction_context/2`,
  `incident_bundle/2`) returns `{:ok, value}` or `{:error, :not_found}` and
  has a `!` sibling that raises `Threadline.NotFoundError`.

  ## Composing your own Ecto query

  `Threadline.Query.timeline_query/1` is the one supported escape hatch for
  composing your own Ecto query on top of the timeline. It returns the
  unexecuted `AuditChange` `Ecto.Query` behind `timeline/2` — same filters,
  same `captured_at` descending, `id` descending order — so you can add your
  own `where`/`select`/pagination before calling `Repo`. Unlike `timeline/2`,
  it does not validate filter keys, so pass only the documented `timeline/2`
  filter keys.
  """

  alias Threadline.Investigation
  alias Threadline.Query.LegacyOpts
  alias Threadline.Query.RowReads
  alias Threadline.Query.TransactionLookup
  alias Threadline.Semantics.ActorRef
  alias Threadline.Semantics.AuditAction
  alias Threadline.StorageSchema

  @doc """
  Records a semantic audit action.

  ## Required options

  - `:actor` or `:actor_ref` — `%ActorRef{}` identifying who performed the action
  - `:repo` — the `Ecto.Repo` module to use for insertion

  ## Optional options

  - `:status` — `:ok` or `:error` (default: `:ok`)
  - `:verb` — string or atom (e.g., `"update"`)
  - `:category` — string or atom (e.g., `"membership"`)
  - `:reason` — atom (e.g., `:insufficient_permissions`)
  - `:comment` — free-text string explanation
  - `:correlation_id` — cross-boundary correlation ID string
  - `:request_id` — request ID string (from `Plug.RequestId` / `x-request-id`)
  - `:job_id` — Oban job ID string

  ## Returns

  - `{:ok, %AuditAction{}}` on success
  - `{:error, %Ecto.Changeset{}}` if changeset validation fails
  - `{:error, :missing_actor}` if no actor was provided
  - `{:error, :invalid_actor_ref}` if the actor fails ActorRef validation
  - `{:error, :missing_repo}` if `:repo` is not provided
  """
  def record_action(name, opts \\ []) when is_atom(name) do
    repo = Keyword.get(opts, :repo)
    actor_ref = Keyword.get(opts, :actor) || Keyword.get(opts, :actor_ref)

    result =
      with :ok <- validate_repo(repo),
           {:ok, validated_ref} <- validate_actor(actor_ref) do
        attrs = build_attrs(name, validated_ref, opts)
        changeset = AuditAction.changeset(attrs)
        repo.insert(changeset, StorageSchema.repo_opts(opts))
      end

    case result do
      {:ok, _action} ->
        Threadline.Telemetry.emit_action_recorded(:ok)
        Threadline.Telemetry.emit_transaction_committed_proxy()

      {:error, _} ->
        Threadline.Telemetry.emit_action_recorded(:error)
    end

    result
  end

  @deprecated "Use Threadline.row_history/3 instead."
  @doc """
  Returns `AuditChange` records for a given schema record, ordered by
  `captured_at` descending.

  Deprecated: use `row_history/3` instead — pass `limit: :infinity` for the
  same unbounded read. This function keeps returning plain `%AuditChange{}`
  structs (the one deliberate exception to "a deprecated delegate's spec
  matches its replacement's", because the replacement returns
  `%Threadline.Investigation.LinkedChange{}`); map `.audit_change` on a
  `row_history/3` result to recover the same struct this function returns.

  Structs include `:changed_from` when present in the row (sparse prior values on
  UPDATE under an opt-in per-table capture function; `nil` when disabled or on
  INSERT/DELETE rows).

  `id` is a bare scalar for a single-column key, or a map or keyword list naming
  every key field for a composite key (atom- or string-keyed, any order):

      Threadline.history(MyApp.User, 42, repo: MyApp.Repo)
      Threadline.history(MyApp.LineItem, [tenant_id: 1, id: 5], repo: MyApp.Repo)

  Key names are the schema's field names, not database column names — unless a
  `primary_key:` override is configured for the table, in which case the
  override's declared columns are the accepted keys instead. A missing, extra,
  or misnamed key, a `nil` value, a scalar for a composite table, or a loaded
  struct all raise `ArgumentError`.

  History for a table that has since been dropped or renamed, or a key column
  whose type changed, stays readable: the key's comparison type falls back to
  the schema field's Ecto type. The one inexact case is a fixed-width `char(n)`
  key — the fallback cannot reproduce the database's stored blank-padding, so
  pass the value already padded to the original column width.

  If `:scope_query_fn` is configured, it should only add predicates: any
  limit it sets on the query is overridden by `:limit`'s final `LIMIT`, and
  the cap counts only rows the scope predicate left in scope.

  ## Options

  - `:repo` — required `Ecto.Repo` module
  - `:limit` — optional positive integer, or `:infinity`. Returns at most n
    most recent changes (`captured_at desc, id desc`). `:limit` caps, it does
    not page. `nil` (the default) is unbounded; `0`, negative and
    non-integer values (other than `:infinity`) raise `ArgumentError`.
  """
  @spec history(module(), term(), keyword()) :: [Threadline.Capture.AuditChange.t()]
  def history(schema_module, id, opts),
    do: RowReads.audit_changes(schema_module, id, LegacyOpts.history(opts))

  @doc """
  Returns the row snapshot for a schema record at a point in time.

  Accepts the same `id` shapes as `history/3` (bare scalar, or map/keyword list
  for a composite key), with the same `ArgumentError` cases and the same
  dropped-table/renamed-column fallback behavior.

  Returns `{:ok, snapshot}`, `{:error, :deleted_record}` when the latest
  snapshot at or before `timestamp` was a delete, or
  `{:error, :before_audit_horizon}` when the row has no snapshot at or before
  the requested timestamp. These are outcomes callers branch on, not a lookup
  miss — a deleted or pre-horizon row is not "absence is a bug" — so
  `as_of/4` has no `!` sibling.

  ## Options

  - `:repo` — required `Ecto.Repo` module
  """
  def as_of(schema_module, id, timestamp, opts),
    do: Threadline.Query.as_of(schema_module, id, timestamp, opts)

  @doc """
  Returns a `%Threadline.Page{}` of `Threadline.Capture.AuditTransaction` records for one
  actor — one row per database transaction, newest first (`occurred_at` desc, `id` desc).

  For the row changes an actor made across tables, use `actor_window/3`.

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
  """
  @spec actor_history(ActorRef.t(), keyword()) ::
          Threadline.Page.t(Threadline.Capture.AuditTransaction.t())
  def actor_history(actor_ref, opts), do: Threadline.Query.actor_history(actor_ref, opts)

  @doc """
  Returns `AuditChange` records across tables, filtered by the given options,
  ordered by `captured_at` descending, then `id` descending (the same total
  order `audit_changes_for_transaction/2` uses).

  Use `timeline/2` for eager, bounded slices where returning a full list is still
  the simple path. Use `timeline_page/2` for larger investigation windows where
  stable keyset traversal matters.

  Only `:repo`, `:table_schema`, `:table`, `:actor_ref`, `:from`, `:to`, and
  `:correlation_id` are allowed; an unknown key raises `ArgumentError`.

  ## Options

  - `:table` — string or atom; filters by `table_name`
  - `:table_schema` — string or atom; filters by captured host table schema
  - `:actor_ref` — `%ActorRef{}`; filters by actor via a JOIN to `audit_transactions`
  - `:from` — `DateTime`; inclusive lower bound on `captured_at`
  - `:to` — `DateTime`; inclusive upper bound on `captured_at`
  - `:correlation_id` — non-empty binary (after trimming). When set, results are limited
    to changes whose transaction is linked to an `audit_actions` row with that
    correlation id (strict inner-join semantics). Omit the key to leave correlation
    out of the filter.
  - `:repo` — required `Ecto.Repo` module
  - `:storage_schema` — optional Threadline storage schema override
  """
  def timeline(filters \\ [], opts \\ []), do: Threadline.Query.timeline(filters, opts)

  @doc """
  Returns a `%Threadline.Page{}` of `AuditChange` records in timeline order,
  without changing `timeline/2`.

  Uses the same filter vocabulary as `timeline/2`, but returns a page struct so
  large investigation windows can be traversed incrementally while `timeline/2`
  stays eager for existing callers. Paging controls live in `opts`:

  - `:page_size` — positive integer, defaults to `1000`
  - `:cursor` — `:start` (or omitted) for the first page, or a prior page's
    `cursor` to continue. `cursor: nil` raises `ArgumentError`. Stop walking
    when `has_more` is `false`.
  - `:repo` — required `Ecto.Repo` module
  """
  @spec timeline_page(keyword(), keyword()) ::
          Threadline.Page.t(Threadline.Capture.AuditChange.t())
  def timeline_page(filters \\ [], opts \\ []), do: Threadline.Query.timeline_page(filters, opts)

  @doc """
  Returns row history for one schema row — the discoverable helper for
  operators who want one row's changes without assembling table and
  primary-key predicates manually.

  Returns a list of `%Threadline.Investigation.LinkedChange{}`, newest first,
  capped at 200 entries by default. Pass `limit: n` or `limit: :infinity` to
  override the cap, or `cursor:` (with optional `page_size:`) to page through
  the full history as a `%Threadline.Page{}`.

  ## Options

  - `:repo` — required `Ecto.Repo` module
  - `:from` — inclusive lower bound on `captured_at`
  - `:to` — inclusive upper bound on `captured_at`
  - `:limit` — positive integer, or `:infinity`. Defaults to 200 most recent
    changes (`captured_at desc, id desc`). `:limit` together with `:cursor`
    raises `ArgumentError`.
  - `:cursor` — `:start` begins a walk; a prior page's `cursor` continues it.
    `cursor: nil` raises `ArgumentError`. Returns `%Threadline.Page{}` instead
    of a bare list.
  - `:page_size` — positive integer, defaults to `1000`; only valid with
    `:cursor`.

  Unknown option keys raise `ArgumentError` naming the allowed keys. The
  200-row default is not a completeness check — walk `cursor:` or pass
  `limit: :infinity` to prove the full history was read.
  """
  @doc since: "1.0.0"
  @spec row_history(module(), term(), keyword()) ::
          [Threadline.Investigation.LinkedChange.t()]
          | Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  def row_history(schema_module, id, opts \\ []) when is_list(opts),
    do: Investigation.row_history(schema_module, id, opts)

  @deprecated "Use Threadline.row_history/3 instead."
  @doc """
  Returns row history for one schema row using the retired `(filters, opts)`
  shape, with 0.12's unbounded default.

  Deprecated: use `row_history/3` instead — pass `limit: :infinity` to keep
  this function's unbounded behavior.
  """
  @spec row_history(module(), term(), keyword(), keyword()) ::
          [Threadline.Investigation.LinkedChange.t()]
  def row_history(schema_module, id, filters, opts)
      when is_list(filters) and is_list(opts) do
    row_history(schema_module, id, LegacyOpts.row_history(filters, opts))
  end

  @deprecated "Use Threadline.row_history/3 instead."
  @doc """
  Returns one keyset page of row history for a single schema row.

  Deprecated: use `row_history/3` instead — pass `cursor: :start` (with
  optional `page_size:`) for the same keyset paging. An absent or `nil`
  `:cursor` here still means "first page"; `row_history/3` itself raises on
  `cursor: nil`.
  """
  @spec row_history_page(module(), term()) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  @spec row_history_page(module(), term(), keyword()) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  @spec row_history_page(module(), term(), keyword(), keyword()) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  def row_history_page(schema_module, id, filters \\ [], opts \\ []),
    do: row_history(schema_module, id, LegacyOpts.row_history_page(filters, opts))

  @doc """
  Returns a list of `%Threadline.Investigation.LinkedChange{}` — the change rows one
  actor made across audited tables, each with its transaction and linked action,
  newest first.

  Pass `cursor:` (with optional `page_size:`) in `opts` to page through the
  results as a `%Threadline.Page{}` instead of a bare list.

  For one row per transaction instead, use `actor_history/2`.
  """
  @doc since: "1.0.0"
  @spec actor_window(ActorRef.t(), keyword(), keyword()) ::
          [Threadline.Investigation.LinkedChange.t()]
          | Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  def actor_window(actor_ref, filters \\ [], opts \\ []),
    do: Investigation.actor_window(actor_ref, filters, opts)

  @deprecated "Use Threadline.actor_window/3 instead."
  @doc """
  Returns one keyset page of change rows across tables for one actor.

  Deprecated: use `actor_window/3` instead — pass `cursor: :start` (with
  optional `page_size:`) for the same keyset paging. An absent or `nil`
  `:cursor` here still means "first page".
  """
  @spec actor_window_page(ActorRef.t()) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  @spec actor_window_page(ActorRef.t(), keyword()) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  @spec actor_window_page(ActorRef.t(), keyword(), keyword()) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  def actor_window_page(actor_ref, filters \\ [], opts \\ []),
    do: actor_window(actor_ref, filters, LegacyOpts.cursor(opts))

  @doc """
  Returns change rows linked to one `correlation_id` with strict correlation
  semantics.

  Pass `cursor:` (with optional `page_size:`) in `opts` to page through the
  results as a `%Threadline.Page{}` instead of a bare list.
  """
  @doc since: "1.0.0"
  @spec correlation_bundle(String.t(), keyword(), keyword()) ::
          [Threadline.Investigation.LinkedChange.t()]
          | Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  def correlation_bundle(correlation_id, filters \\ [], opts \\ []),
    do: Investigation.correlation_bundle(correlation_id, filters, opts)

  @deprecated "Use Threadline.correlation_bundle/3 instead."
  @doc """
  Returns one keyset page of changes linked to one `correlation_id`.

  Deprecated: use `correlation_bundle/3` instead — pass `cursor: :start`
  (with optional `page_size:`) for the same keyset paging. An absent or
  `nil` `:cursor` here still means "first page".
  """
  @spec correlation_bundle_page(String.t()) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  @spec correlation_bundle_page(String.t(), keyword()) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  @spec correlation_bundle_page(String.t(), keyword(), keyword()) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  def correlation_bundle_page(correlation_id, filters \\ [], opts \\ []),
    do: correlation_bundle(correlation_id, filters, LegacyOpts.cursor(opts))

  @doc """
  Returns `{:ok, %Threadline.Capture.AuditTransaction{}}` when the row exists and is
  visible under the scope, or `{:error, :not_found}`.

  `.action` is always hydrated — 0 extra queries when the transaction has no
  linked action, 1 otherwise. A binary that is not a valid UUID returns
  `{:error, :not_found}`; a non-binary id raises `ArgumentError`.

  ## Options

  - `:repo` — required `Ecto.Repo` module
  - `:storage_schema` — optional Threadline storage schema override
  - `:scope` — opaque scope term passed to `:scope_query_fn`
  - `:scope_query_fn` — `(query, scope, context) -> query`; sees
    `context.surface == :transaction_header` with a single `[at]` binding and
    `context.params == %{transaction_id: transaction_id}`

  Unknown option keys raise `ArgumentError`.

  Use `audit_transaction!/2` when absence is a bug.
  """
  @doc since: "1.0.0"
  @spec audit_transaction(Ecto.UUID.t(), keyword()) ::
          {:ok, Threadline.Capture.AuditTransaction.t()} | {:error, :not_found}
  def audit_transaction(transaction_id, opts \\ []) do
    TransactionLookup.validate_opts!(opts, "audit_transaction")

    case TransactionLookup.fetch_row(transaction_id, opts) do
      {:ok, transaction} -> {:ok, transaction}
      :not_found -> {:error, :not_found}
    end
  end

  @doc """
  Returns the `%Threadline.Capture.AuditTransaction{}` or raises
  `Threadline.NotFoundError`.

  See `audit_transaction/2` for the option list and the missing/scope-filtered
  semantics this raises on.
  """
  @doc since: "1.0.0"
  @spec audit_transaction!(Ecto.UUID.t(), keyword()) ::
          Threadline.Capture.AuditTransaction.t()
  def audit_transaction!(transaction_id, opts \\ []) do
    case audit_transaction(transaction_id, opts) do
      {:ok, transaction} ->
        transaction

      {:error, :not_found} ->
        raise Threadline.NotFoundError, resource: :audit_transaction, id: transaction_id
    end
  end

  @doc """
  Returns `{:ok, %Threadline.Investigation.LinkedTransaction{}}` when the
  transaction row exists and is visible under the scope, or
  `{:error, :not_found}`.

  An existing transaction with no visible changes returns `changes: []`. The
  row and its changes are read by two independent queries, each point-in-time
  under READ COMMITTED.

  A binary that is not a valid UUID returns `{:error, :not_found}`; a
  non-binary id raises `ArgumentError`.

  ## Options

  - `:repo` — required `Ecto.Repo` module
  - `:storage_schema` — optional Threadline storage schema override
  - `:scope` — opaque scope term passed to `:scope_query_fn`
  - `:scope_query_fn` — `(query, scope, context) -> query`; sees
    `context.surface == :transaction_header` with a single `[at]` binding for
    the row read, and `context.surface == :transaction` with an `[ac, at]`
    binding for the changes read — both with
    `context.params == %{transaction_id: transaction_id}`

  Unknown option keys raise `ArgumentError`.

  Use `transaction_context!/2` when absence is a bug.
  """
  @spec transaction_context(Ecto.UUID.t(), keyword()) ::
          {:ok, Threadline.Investigation.LinkedTransaction.t()} | {:error, :not_found}
  def transaction_context(transaction_id, opts \\ []),
    do: Investigation.transaction_context(transaction_id, opts)

  @doc """
  Returns the `%Threadline.Investigation.LinkedTransaction{}` or raises
  `Threadline.NotFoundError`.

  See `transaction_context/2` for the option list and the missing/scope-filtered
  semantics this raises on.
  """
  @doc since: "1.0.0"
  @spec transaction_context!(Ecto.UUID.t(), keyword()) ::
          Threadline.Investigation.LinkedTransaction.t()
  def transaction_context!(transaction_id, opts \\ []) do
    case transaction_context(transaction_id, opts) do
      {:ok, result} ->
        result

      {:error, :not_found} ->
        raise Threadline.NotFoundError, resource: :audit_transaction, id: transaction_id
    end
  end

  @doc """
  Returns `{:ok, %Threadline.Investigation.IncidentBundle{}}` when the
  transaction row exists and is visible under the scope, or
  `{:error, :not_found}`.

  The bundle carries linked transaction/action context and ordered changes
  (newest first) packaged as JSON-ready diffs. An existing transaction with no
  visible changes returns `changes: []`. The row and its changes are read by
  two independent queries, each point-in-time under READ COMMITTED.

  A binary that is not a valid UUID returns `{:error, :not_found}`; a
  non-binary id raises `ArgumentError`.

  ## Options

  - `:repo` — required `Ecto.Repo` module
  - `:storage_schema` — optional Threadline storage schema override
  - `:scope` — opaque scope term passed to `:scope_query_fn`
  - `:scope_query_fn` — `(query, scope, context) -> query`; sees
    `context.surface == :transaction_header` with a single `[at]` binding for
    the row read, and `context.surface == :transaction` with an `[ac, at]`
    binding for the changes read — both with
    `context.params == %{transaction_id: transaction_id}`

  Unknown option keys raise `ArgumentError`.

  Use `incident_bundle!/2` when absence is a bug.
  """
  @spec incident_bundle(Ecto.UUID.t(), keyword()) ::
          {:ok, Threadline.Investigation.IncidentBundle.t()} | {:error, :not_found}
  def incident_bundle(transaction_id, opts \\ []),
    do: Investigation.incident_bundle(transaction_id, opts)

  @doc """
  Returns the `%Threadline.Investigation.IncidentBundle{}` or raises
  `Threadline.NotFoundError`.

  See `incident_bundle/2` for the option list and the missing/scope-filtered
  semantics this raises on.
  """
  @doc since: "1.0.0"
  @spec incident_bundle!(Ecto.UUID.t(), keyword()) ::
          Threadline.Investigation.IncidentBundle.t()
  def incident_bundle!(transaction_id, opts \\ []) do
    case incident_bundle(transaction_id, opts) do
      {:ok, result} ->
        result

      {:error, :not_found} ->
        raise Threadline.NotFoundError, resource: :audit_transaction, id: transaction_id
    end
  end

  @doc """
  Returns every `%Threadline.Capture.AuditChange{}` for a single `audit_transactions.id`.

  `transaction_id` is `audit_transactions.id`. Accepts UUID strings or 16-byte
  binaries; raises `ArgumentError` when the id is not a valid UUID. Returns `[]`
  when the UUID is well-formed but no matching rows exist. Ordered by
  `captured_at` descending, then `id` descending — the same total order as
  `timeline/2`.

  ## Options

  - `:repo` — required `Ecto.Repo` module.
  - `:preload` — optional association list, e.g. `[:transaction]`, forwarded to
    `repo.preload/3` when non-empty. Preloading `:action` under `:transaction`
    (`transaction: :action` / `transaction: [:action, ...]`) is deprecated: it
    still hydrates `transaction.action`, but emits one warning per call and will
    be removed no earlier than Threadline 2.0. Prefer `transaction_context/2`.
  """
  def audit_changes_for_transaction(transaction_id, opts),
    do: Threadline.Query.audit_changes_for_transaction(transaction_id, opts)

  @doc """
  Exports matching audit changes as CSV using the same `filters` / `opts` vocabulary
  as `timeline/2`.

  See `Threadline.Export`.
  """
  def export_csv(filters \\ [], opts \\ []), do: Threadline.Export.to_csv_iodata(filters, opts)

  @doc """
  Exports matching audit changes as JSON using the same `filters` / `opts` vocabulary
  as `timeline/2`.

  Pass `json_format: :ndjson` in `opts` for newline-delimited objects. See `Threadline.Export`.
  """
  def export_json(filters \\ [], opts \\ []),
    do: Threadline.Export.to_json_document(filters, opts)

  @doc """
  Projects a single `%Threadline.Capture.AuditChange{}` into deterministic, JSON-friendly maps.

  Delegates to `Threadline.ChangeDiff.from_audit_change/2`. See that module for `:format`
  (including `:export_compat`) and `:expand_insert_fields`.
  """
  defdelegate change_diff(audit_change, opts \\ []),
    to: Threadline.ChangeDiff,
    as: :from_audit_change

  defp validate_repo(nil), do: {:error, :missing_repo}
  defp validate_repo(_repo), do: :ok

  defp validate_actor(nil), do: {:error, :missing_actor}
  defp validate_actor(%ActorRef{} = ref), do: {:ok, ref}
  defp validate_actor(_), do: {:error, :invalid_actor_ref}

  defp build_attrs(name, actor_ref, opts) do
    %{
      name: Atom.to_string(name),
      actor_ref: actor_ref,
      status: Keyword.get(opts, :status, :ok),
      verb: stringify_opt(Keyword.get(opts, :verb)),
      category: stringify_opt(Keyword.get(opts, :category)),
      reason: stringify_opt(Keyword.get(opts, :reason)),
      comment: Keyword.get(opts, :comment),
      correlation_id: Keyword.get(opts, :correlation_id),
      request_id: Keyword.get(opts, :request_id),
      job_id: Keyword.get(opts, :job_id)
    }
  end

  defp stringify_opt(nil), do: nil
  defp stringify_opt(v) when is_atom(v), do: Atom.to_string(v)
  defp stringify_opt(v) when is_binary(v), do: v
end
