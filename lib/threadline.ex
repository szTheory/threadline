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
  alias Threadline.Query.OptionKeys
  alias Threadline.Query.RowReads
  alias Threadline.Query.TransactionLookup
  alias Threadline.Semantics.ActorRef
  alias Threadline.Semantics.AuditAction
  alias Threadline.StorageSchema

  @typedoc "An option that selects the Ecto repository used for a read."
  @type repo_opt :: {:repo, module()}

  @typedoc "An option that selects a Threadline storage schema override."
  @type storage_schema_opt :: {:storage_schema, String.t()}

  @typedoc "A query callback that applies the caller's scope; the scope value is opaque to Threadline."
  @type scope_query_fn ::
          (Ecto.Query.t(), term(), %{surface: atom(), params: map()} -> Ecto.Query.t())

  @typedoc "A caller-owned scope value or callback; the scope value is opaque to Threadline."
  @type scope_opt :: {:scope, term()} | {:scope_query_fn, scope_query_fn()}

  @typedoc "A scalar host-table key value supported by Ecto."
  @type row_key_scalar ::
          String.t()
          | integer()
          | float()
          | boolean()
          | Date.t()
          | DateTime.t()
          | NaiveDateTime.t()
          | Decimal.t()

  @typedoc "A single host key or every field of a composite key as a map or keyword list."
  @type row_id ::
          row_key_scalar()
          | %{optional(atom() | String.t()) => row_key_scalar()}
          | [{atom() | String.t(), row_key_scalar()}]

  @typedoc "A JSON value supported in a captured or exported JSON map."
  @type json_value :: nil | boolean() | number() | String.t() | [json_value()] | json_map()

  @typedoc "A string-keyed JSON map decoded from jsonb or bound for JSON encoding; owning types list guaranteed keys and new keys may be added."
  @type json_map :: %{optional(String.t()) => json_value()}

  @typedoc "An option accepted by `row_history/3`."
  @type row_history_opt ::
          repo_opt()
          | storage_schema_opt()
          | scope_opt()
          | {:from, DateTime.t()}
          | {:to, DateTime.t()}
          | {:limit, pos_integer() | :infinity}
          | {:cursor, :start | Threadline.Page.change_cursor()}
          | {:page_size, pos_integer()}

  @typedoc "An option accepted by the single-transaction lookup functions."
  @type lookup_opt :: repo_opt() | storage_schema_opt() | scope_opt()

  @typedoc "A timeline filter for captured changes."
  @type timeline_filter ::
          repo_opt()
          | {:table, atom() | String.t()}
          | {:table_schema, atom() | String.t()}
          | {:actor_ref, ActorRef.t()}
          | {:from, DateTime.t()}
          | {:to, DateTime.t()}
          | {:correlation_id, String.t()}

  @typedoc "An option accepted by `timeline/2`."
  @type timeline_opt :: repo_opt() | storage_schema_opt() | scope_opt()

  @typedoc "An option accepted by `timeline_page/2`."
  @type timeline_page_opt ::
          timeline_opt()
          | {:page_size, pos_integer()}
          | {:cursor, :start | Threadline.Page.change_cursor()}

  @typedoc "An option accepted by `actor_history/2`; `:after`, `:before`, and `:limit` are deprecated aliases."
  @type actor_history_opt ::
          repo_opt()
          | storage_schema_opt()
          | scope_opt()
          | {:from, DateTime.t()}
          | {:to, DateTime.t()}
          | {:cursor,
             :start | Threadline.Page.actor_cursor() | {:before, Threadline.Page.actor_cursor()}}
          | {:page_size, pos_integer()}
          | {:after, Threadline.Page.actor_cursor()}
          | {:before, Threadline.Page.actor_cursor()}
          | {:limit, pos_integer()}

  @doc false
  @spec __option_keys__(atom()) :: [atom()] | :not_closed
  def __option_keys__(name), do: OptionKeys.allowed(name)

  @doc false
  @spec __filter_keys__(atom()) :: [atom()] | :not_closed
  def __filter_keys__(name), do: OptionKeys.filters(name)

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
  Returns a `%Threadline.Page{}` of `AuditTransaction` rows for one actor,
  newest first by `occurred_at` and `id`.

  Use `actor_window/3` for the change rows made by an actor across tables.
  Walk pages with `:cursor`; stop when `has_more` is `false`.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — string. Optional. Selects a Threadline storage schema override.
  - `:scope` — caller-owned value. Optional. Opaque to Threadline and passed to `:scope_query_fn`.
  - `:scope_query_fn` — function. Optional. Adds the caller's scope predicates to the read.
  - `:from` — `DateTime`. Optional. Inclusive lower bound on `occurred_at`.
  - `:to` — `DateTime`. Optional. Inclusive upper bound on `occurred_at`.
  - `:cursor` — `:start` or an actor-history cursor. Optional. `nil` raises `ArgumentError`.
  - `:page_size` — positive integer. Defaults to `50`.

  ## Deprecated options

  - `:after` — actor-history cursor. Deprecated; use `:cursor` instead.
  - `:before` — actor-history cursor. Deprecated; use `cursor: {:before, cursor}` instead.
  - `:limit` — positive integer. Deprecated; use `:page_size` instead.

  Each still works, and each emits one deprecation warning per call. Removal
  is no earlier than Threadline 2.0. `:cursor` combined with `:after` or
  `:before` raises `ArgumentError`, as does `:page_size` combined with
  `:limit`.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - A `%Threadline.Page{}` of matching transactions.
  - Raises `ArgumentError` for an invalid cursor or conflicting pagination options, and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.actor_history(actor_ref, repo: MyApp.Repo)
  """
  @spec actor_history(ActorRef.t(), [actor_history_opt()]) ::
          Threadline.Page.t(Threadline.Capture.AuditTransaction.t())
  def actor_history(actor_ref, opts) do
    OptionKeys.validate!(opts, :actor_history)
    Threadline.Query.actor_history(actor_ref, opts)
  end

  @doc """
  Returns captured `AuditChange` rows across tables in descending capture order.

  Use `timeline_page/2` when a large investigation window needs stable keyset
  traversal. `timeline/2` reads the matching rows as one list.

  ## Filters

  - `:repo` — `Ecto.Repo` module. Optional when supplied in `opts`.
  - `:table` — string or atom. Optional. Matches `table_name`.
  - `:table_schema` — string or atom. Optional. Matches the captured host schema.
  - `:actor_ref` — `%ActorRef{}`. Optional. Matches the transaction actor.
  - `:from` — `DateTime`. Optional. Inclusive lower bound on `captured_at`.
  - `:to` — `DateTime`. Optional. Inclusive upper bound on `captured_at`.
  - `:correlation_id` — non-empty string. Optional. Matches linked action correlation with strict inner-join semantics.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — string. Optional. Selects a Threadline storage schema override.
  - `:scope` — caller-owned value. Optional. Opaque to Threadline and passed to `:scope_query_fn`.
  - `:scope_query_fn` — function. Optional. Adds the caller's scope predicates to the read.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - A list of matching `%Threadline.Capture.AuditChange{}` rows.
  - Raises `ArgumentError` for invalid filters or repository options.

  ## Examples

      Threadline.timeline([table: "users"], repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers
  are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @spec timeline([timeline_filter()], [timeline_opt()]) ::
          [Threadline.Capture.AuditChange.t()]
  def timeline(filters \\ [], opts \\ []) do
    OptionKeys.validate_filters!(filters, :timeline)
    OptionKeys.validate!(opts, :timeline)
    Threadline.Query.timeline(filters, opts)
  end

  @doc """
  Returns a `%Threadline.Page{}` of captured `AuditChange` rows in timeline
  order, using the same filters as `timeline/2`.

  Use `timeline/2` when one eager list is the simpler read. A cursor walk gives
  large investigation windows stable keyset traversal; stop when `has_more` is
  `false`.

  ## Filters

  - `:repo` — `Ecto.Repo` module. Optional when supplied in `opts`.
  - `:table` — string or atom. Optional. Matches `table_name`.
  - `:table_schema` — string or atom. Optional. Matches the captured host schema.
  - `:actor_ref` — `%ActorRef{}`. Optional. Matches the transaction actor.
  - `:from` — `DateTime`. Optional. Inclusive lower bound on `captured_at`.
  - `:to` — `DateTime`. Optional. Inclusive upper bound on `captured_at`.
  - `:correlation_id` — non-empty string. Optional. Matches linked action correlation with strict inner-join semantics.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — string. Optional. Selects a Threadline storage schema override.
  - `:scope` — caller-owned value. Optional. Opaque to Threadline and passed to `:scope_query_fn`.
  - `:scope_query_fn` — function. Optional. Adds the caller's scope predicates to the read.
  - `:page_size` — positive integer. Defaults to `1000`.
  - `:cursor` — `:start` or a prior page cursor. Optional. `nil` raises `ArgumentError`.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - A `%Threadline.Page{}` of matching changes.
  - Raises `ArgumentError` for invalid filters, repository options, or cursor, and `KeyError` when `:repo` is missing.

  Results contain column values as captured; redaction is applied when triggers
  are generated, not on read. Authorize reads with `:scope_query_fn`.

  ## Examples

      first = Threadline.timeline_page([table: "users"], repo: MyApp.Repo)
      Threadline.timeline_page([table: "users"], repo: MyApp.Repo, cursor: first.cursor)
  """
  @spec timeline_page([timeline_filter()], [timeline_page_opt()]) ::
          Threadline.Page.t(Threadline.Capture.AuditChange.t())
  def timeline_page(filters \\ [], opts \\ []) do
    OptionKeys.validate_filters!(filters, :timeline)
    OptionKeys.validate!(opts, :timeline_page)
    Threadline.Query.timeline_page(filters, opts)
  end

  @doc """
  Returns a list of `%Threadline.Investigation.LinkedChange{}` or a
  `%Threadline.Page{}` for one schema row, ordered newest first.

  Use `timeline/2` to inspect changes across rows. A list is capped at 200
  entries by default; use `cursor:` to walk the full history page by page.
  `limit:` caps a list and cannot be combined with `cursor:`.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — string. Optional. Selects a Threadline storage schema override.
  - `:scope` — caller-owned value. Optional. Opaque to Threadline and passed to `:scope_query_fn`.
  - `:scope_query_fn` — function. Optional. Adds the caller's scope predicates to the read.
  - `:from` — `DateTime`. Optional. Inclusive lower bound on `captured_at`.
  - `:to` — `DateTime`. Optional. Inclusive upper bound on `captured_at`.
  - `:limit` — positive integer or `:infinity`. Defaults to 200 most recent changes; cannot be combined with `:cursor`.
  - `:cursor` — `:start` or a prior page cursor. Optional. Returns a page instead of a list; `nil` raises `ArgumentError`.
  - `:page_size` — positive integer. Defaults to `1000`; only applies with `:cursor`.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - A list of linked changes, capped at 200 by default, or a `%Threadline.Page{}` when `:cursor` is set.
  - Raises `ArgumentError` for an unknown option, an invalid key shape, or incompatible paging options.

  ## Examples

      Threadline.row_history(MyApp.LineItem, [tenant_id: 7, id: 42], repo: MyApp.Repo)

      first = Threadline.row_history(MyApp.LineItem, 42, repo: MyApp.Repo, cursor: :start)
      Threadline.row_history(MyApp.LineItem, 42, repo: MyApp.Repo, cursor: first.cursor)

  Results contain column values as captured; redaction is applied when triggers
  are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc since: "1.0.0"
  @spec row_history(module(), row_id(), [row_history_opt()]) ::
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
  Returns `{:ok, %Threadline.Capture.AuditTransaction{}}` for one visible
  transaction, or `{:error, :not_found}` when it is absent or out of scope.

  Use `audit_transaction!/2` when absence is a bug. The linked action is
  hydrated when present; a malformed UUID string is treated as not found.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — string. Optional. Selects a Threadline storage schema override.
  - `:scope` — caller-owned value. Optional. Opaque to Threadline and passed to `:scope_query_fn`.
  - `:scope_query_fn` — function. Optional. Receives the transaction header query and context.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - `{:ok, %Threadline.Capture.AuditTransaction{}}` — the visible transaction, with its action hydrated when present.
  - `{:error, :not_found}` — no visible transaction matches the UUID.
  - Raises `ArgumentError` for a non-binary id and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.audit_transaction(transaction_id, repo: MyApp.Repo)
  """
  @doc since: "1.0.0"
  @spec audit_transaction(Ecto.UUID.t(), [lookup_opt()]) ::
          {:ok, Threadline.Capture.AuditTransaction.t()} | {:error, :not_found}
  def audit_transaction(transaction_id, opts \\ []) do
    OptionKeys.validate!(opts, :audit_transaction)

    case TransactionLookup.fetch_row(transaction_id, opts) do
      {:ok, transaction} -> {:ok, transaction}
      :not_found -> {:error, :not_found}
    end
  end

  @doc """
  Returns the visible `%Threadline.Capture.AuditTransaction{}` or raises
  `Threadline.NotFoundError` when the transaction is absent or out of scope.

  Use `audit_transaction/2` when absence should be returned as
  `{:error, :not_found}`. Options and UUID handling follow that function.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — string. Optional. Selects a Threadline storage schema override.
  - `:scope` — caller-owned value. Optional. Opaque to Threadline and passed to `:scope_query_fn`.
  - `:scope_query_fn` — function. Optional. Receives the transaction header query and context.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - `%Threadline.Capture.AuditTransaction{}` — the visible transaction.
  - Raises `Threadline.NotFoundError` when no visible transaction matches the UUID.
  - Raises `ArgumentError` for a non-binary id and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.audit_transaction!(transaction_id, repo: MyApp.Repo)
  """
  @doc since: "1.0.0"
  @spec audit_transaction!(Ecto.UUID.t(), [lookup_opt()]) ::
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
  Returns `{:ok, %Threadline.Investigation.LinkedTransaction{}}` for one
  visible transaction and its visible changes, or `{:error, :not_found}`.

  Use `transaction_context!/2` when absence is a bug. The transaction and its
  changes are read by two independent queries; an existing transaction with
  no visible changes returns `changes: []`.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — string. Optional. Selects a Threadline storage schema override.
  - `:scope` — caller-owned value. Optional. Opaque to Threadline and passed to `:scope_query_fn`.
  - `:scope_query_fn` — function. Optional. Applies predicates to both the transaction and changes queries.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - `{:ok, %Threadline.Investigation.LinkedTransaction{}}` — the transaction and visible changes.
  - `{:error, :not_found}` — no visible transaction matches the UUID.
  - Raises `ArgumentError` for a non-binary id and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.transaction_context(transaction_id, repo: MyApp.Repo)
  """
  @spec transaction_context(Ecto.UUID.t(), [lookup_opt()]) ::
          {:ok, Threadline.Investigation.LinkedTransaction.t()} | {:error, :not_found}
  def transaction_context(transaction_id, opts \\ []),
    do: Investigation.transaction_context(transaction_id, opts)

  @doc """
  Returns the visible `%Threadline.Investigation.LinkedTransaction{}` or raises
  `Threadline.NotFoundError` when the transaction is absent or out of scope.

  Use `transaction_context/2` when absence should be returned as
  `{:error, :not_found}`. Options and UUID handling follow that function.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — string. Optional. Selects a Threadline storage schema override.
  - `:scope` — caller-owned value. Optional. Opaque to Threadline and passed to `:scope_query_fn`.
  - `:scope_query_fn` — function. Optional. Applies predicates to both read queries.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - `%Threadline.Investigation.LinkedTransaction{}` — the transaction and visible changes.
  - Raises `Threadline.NotFoundError` when no visible transaction matches the UUID.
  - Raises `ArgumentError` for a non-binary id and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.transaction_context!(transaction_id, repo: MyApp.Repo)
  """
  @doc since: "1.0.0"
  @spec transaction_context!(Ecto.UUID.t(), [lookup_opt()]) ::
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
  Returns `{:ok, %Threadline.Investigation.IncidentBundle{}}` with linked
  transaction/action context and ordered changes, or `{:error, :not_found}`.

  Use `incident_bundle!/2` when absence is a bug. An existing transaction with
  no visible changes returns `changes: []`; its row and changes come from two
  independent queries.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — string. Optional. Selects a Threadline storage schema override.
  - `:scope` — caller-owned value. Optional. Opaque to Threadline and passed to `:scope_query_fn`.
  - `:scope_query_fn` — function. Optional. Applies predicates to both read queries.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - `{:ok, %Threadline.Investigation.IncidentBundle{}}` — the transaction, action context, and visible changes.
  - `{:error, :not_found}` — no visible transaction matches the UUID.
  - Raises `ArgumentError` for a non-binary id and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.incident_bundle(transaction_id, repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers
  are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @spec incident_bundle(Ecto.UUID.t(), [lookup_opt()]) ::
          {:ok, Threadline.Investigation.IncidentBundle.t()} | {:error, :not_found}
  def incident_bundle(transaction_id, opts \\ []),
    do: Investigation.incident_bundle(transaction_id, opts)

  @doc """
  Returns the visible `%Threadline.Investigation.IncidentBundle{}` or raises
  `Threadline.NotFoundError` when the transaction is absent or out of scope.

  Use `incident_bundle/2` when absence should be returned as
  `{:error, :not_found}`. Options and UUID handling follow that function.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — string. Optional. Selects a Threadline storage schema override.
  - `:scope` — caller-owned value. Optional. Opaque to Threadline and passed to `:scope_query_fn`.
  - `:scope_query_fn` — function. Optional. Applies predicates to both read queries.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - `%Threadline.Investigation.IncidentBundle{}` — the transaction, action context, and visible changes.
  - Raises `Threadline.NotFoundError` when no visible transaction matches the UUID.
  - Raises `ArgumentError` for a non-binary id and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.incident_bundle!(transaction_id, repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers
  are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc since: "1.0.0"
  @spec incident_bundle!(Ecto.UUID.t(), [lookup_opt()]) ::
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
