defmodule Threadline do
  @moduledoc """
  Threadline is an audit platform that captures database row changes and links them to application actions and execution context.
  Threadline combines trigger-backed row-change capture, rich action semantics
  (actor/intent/context), and operator-grade exploration.

  ## Jobs

  - **Capture & Transactions**: read a captured transaction with `audit_transaction/2`, `transaction_context/2`, or `incident_bundle/2`.
  - **Querying & Timelines**: inspect all changes with `timeline/2`, page through them with `timeline_page/2`, or reconstruct a row with `row_history/3`.
  - **Actions & Context**: record semantic intent with `record_action/2`, follow an actor with `actor_history/2`, or inspect a correlation with `correlation_bundle/3`.
  - **Operations**: export captured changes with `export_csv/2` or `export_json/2`; retention, health and coverage live in their dedicated modules and tasks.

  The older names (`history/3`, `row_history/4`, `row_history_page/4`,
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

  @moduledoc groups: [
               %{
                 title: "Capture & Transactions",
                 description:
                   "Capture is installed by the triggers your migrations generate with `mix threadline.gen.triggers`; these functions read one captured AuditTransaction by id."
               },
               %{
                 title: "Querying & Timelines",
                 description:
                   "Read captured changes across tables, follow a row through time, or inspect its state at a point in time."
               },
               %{
                 title: "Actions & Context",
                 description:
                   "Record semantic actions and connect captured changes to actors, requests, jobs, and correlations."
               },
               %{
                 title: "Operations",
                 description:
                   "Export captured changes; retention, health, and coverage live in Threadline.Retention, Threadline.Health, and mix threadline.verify_coverage."
               }
             ]

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

  @typedoc "A filter for changes made by one actor."
  @type actor_window_filter ::
          {:table, atom() | String.t()}
          | {:from, DateTime.t()}
          | {:to, DateTime.t()}
          | {:correlation_id, String.t()}
          | repo_opt()

  @typedoc "A filter for changes linked to one correlation id."
  @type correlation_bundle_filter ::
          {:table, atom() | String.t()}
          | {:actor_ref, ActorRef.t()}
          | {:from, DateTime.t()}
          | {:to, DateTime.t()}
          | repo_opt()

  @typedoc "An option accepted by `actor_window/3` and `correlation_bundle/3`."
  @type window_opt ::
          repo_opt()
          | storage_schema_opt()
          | scope_opt()
          | {:cursor, :start | Threadline.Page.change_cursor()}
          | {:page_size, pos_integer()}

  @typedoc "An option accepted by `export_csv/2`."
  @type export_csv_opt ::
          repo_opt()
          | storage_schema_opt()
          | scope_opt()
          | {:max_rows, non_neg_integer()}
          | {:include_action_metadata, boolean()}

  @typedoc "An option accepted by `export_json/2`."
  @type export_json_opt ::
          repo_opt()
          | storage_schema_opt()
          | scope_opt()
          | {:max_rows, non_neg_integer()}
          | {:json_format, :wrapped | :ndjson}

  @typedoc "An option accepted by `record_action/2`; supply either `:actor` or `:actor_ref` and a repository."
  @type record_action_opt ::
          repo_opt()
          | storage_schema_opt()
          | {:actor, ActorRef.t()}
          | {:actor_ref, ActorRef.t()}
          | {:status, :ok | :error}
          | {:verb, atom() | String.t()}
          | {:category, atom() | String.t()}
          | {:reason, atom() | String.t()}
          | {:comment, String.t()}
          | {:correlation_id, String.t()}
          | {:request_id, String.t()}
          | {:job_id, String.t()}

  @typedoc "An option accepted by `as_of/4`."
  @type as_of_opt ::
          repo_opt()
          | storage_schema_opt()
          | scope_opt()
          | {:cast, boolean()}

  @typedoc "An option accepted by `audit_changes_for_transaction/2`."
  @type audit_changes_opt ::
          repo_opt()
          | storage_schema_opt()
          | scope_opt()
          | {:preload, [atom() | {atom(), atom() | [atom()]}] | nil}

  @typedoc "An option accepted by `change_diff/2`."
  @type change_diff_opt ::
          {:format, :primary | :export_compat}
          | {:expand_insert_fields, boolean()}

  @typedoc "An option accepted by the legacy unbounded history read."
  @type history_opt ::
          repo_opt()
          | storage_schema_opt()
          | scope_opt()
          | {:from, DateTime.t()}
          | {:to, DateTime.t()}
          | {:limit, pos_integer() | :infinity | nil}

  @typedoc "A row-history filter accepted by the legacy filters-and-options shapes."
  @type row_history_filter ::
          repo_opt()
          | {:from, DateTime.t()}
          | {:to, DateTime.t()}

  @typedoc "An option accepted by the legacy row-history read shape."
  @type row_history_legacy_opt :: row_history_opt()

  @typedoc "An option accepted by the legacy paged row-history read shape."
  @type row_history_page_opt :: row_history_opt()

  @typedoc "A filter accepted by the legacy paged actor-window shape."
  @type actor_window_page_filter :: actor_window_filter()

  @typedoc "An option accepted by the legacy paged actor-window shape."
  @type actor_window_page_opt :: window_opt()

  @typedoc "A filter accepted by the legacy paged correlation-bundle shape."
  @type correlation_bundle_page_filter :: correlation_bundle_filter()

  @typedoc "An option accepted by the legacy paged correlation-bundle shape."
  @type correlation_bundle_page_opt :: window_opt()

  @doc false
  @spec __option_keys__(atom()) :: [atom()] | :not_closed
  def __option_keys__(name), do: OptionKeys.allowed(name)

  @doc false
  @spec __filter_keys__(atom()) :: [atom()] | :not_closed
  def __filter_keys__(name), do: OptionKeys.filters(name)

  @doc """
  Records an `%AuditAction{}` that names the application event associated with a database transaction and returns `{:ok, AuditAction}` on success or `{:error, reason}` for a changeset failure, missing actor, invalid actor reference, or missing repository.
  Use `actor_history/2` or `correlation_bundle/3` to explore captured changes associated with the actor or correlation after recording the action.

  ## Options

  - `:actor` — `%ActorRef{}` identifying who performed the action. Required unless `:actor_ref` is supplied.
  - `:actor_ref` — `%ActorRef{}` identifying who performed the action. Required unless `:actor` is supplied.
  - `:repo` — `Ecto.Repo` module used for insertion. Required.
  - `:storage_schema` — Threadline storage schema override. Optional.
  - `:status` — `:ok` or `:error`. Optional; defaults to `:ok`.
  - `:verb` — string or atom describing the operation, such as `"update"`. Optional.
  - `:category` — string or atom grouping the action, such as `"membership"`. Optional.
  - `:reason` — string or atom explaining the action. Optional.
  - `:comment` — free-text explanation. Optional.
  - `:correlation_id` — string connecting work across boundaries. Optional.
  - `:request_id` — request ID, such as one from `Plug.RequestId`. Optional.
  - `:job_id` — Oban job ID. Optional.

  ## Returns

  - `{:ok, %AuditAction{}}` on success
  - `{:error, %Ecto.Changeset{}}` if changeset validation fails
  - `{:error, :missing_actor}` if no actor was provided
  - `{:error, :invalid_actor_ref}` if the actor fails ActorRef validation
  - `{:error, :missing_repo}` if `:repo` is not provided

  ## Examples

      {:ok, actor} = Threadline.Semantics.ActorRef.new(:user, "u-42")

      Threadline.record_action(:member_role_changed,
        actor: actor, repo: MyApp.Repo,
        category: "membership", verb: "update",
        correlation_id: "request-8f2"
      )
  """
  @doc group: "Actions & Context"
  @spec record_action(atom(), [record_action_opt()]) ::
          {:ok, AuditAction.t()}
          | {:error, Ecto.Changeset.t()}
          | {:error, :missing_actor | :invalid_actor_ref | :missing_repo}
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
  Returns a list of `%Threadline.Capture.AuditChange{}` rows for one schema record, newest first.

  Use `row_history/3` for linked change records and cursor paging. This deprecated function keeps its unbounded default and returns plain `%AuditChange{}` structs; map `.audit_change` over a `row_history/3` result to obtain the same row type.

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

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — storage schema override. Optional.
  - `:scope` — caller-owned scope value. Optional and opaque to Threadline.
  - `:scope_query_fn` — callback that adds caller scope predicates. Optional.
  - `:from` — inclusive lower bound on `captured_at`. Optional.
  - `:to` — inclusive upper bound on `captured_at`. Optional.
  - `:limit` — positive integer or `:infinity`. Optional; absent or `nil` keeps the unbounded legacy default. This caps rows and does not page.

  ## Returns

  - A list of `%Threadline.Capture.AuditChange{}` rows ordered by `captured_at` and `id` descending.
  - Raises `ArgumentError` for an invalid row key or limit, and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.history(MyApp.User, 42, repo: MyApp.Repo)
      Threadline.history(MyApp.LineItem, [tenant_id: 1, id: 5], repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc group: "Querying & Timelines"
  @spec history(module(), row_id(), [history_opt()]) :: [Threadline.Capture.AuditChange.t()]
  def history(schema_module, id, opts),
    do: RowReads.audit_changes(schema_module, id, LegacyOpts.history(opts))

  @doc """
  Returns the row snapshot at a timestamp as a string-keyed map or loaded schema struct.

  Use `row_history/3` to inspect the captured changes that produced the snapshot. `id` uses the `row_id()` scalar or composite-key shapes; invalid key shapes raise `ArgumentError`.

  Returns `{:ok, snapshot}`, `{:error, :deleted_record}` when the latest
  snapshot at or before `timestamp` was a delete, or
  `{:error, :before_audit_horizon}` when the row has no snapshot at or before
  the requested timestamp. These are outcomes callers branch on, not a lookup
  miss — a deleted or pre-horizon row is not "absence is a bug" — so
  There is no `!` sibling because deletion and the audit horizon are expected results.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — storage schema override. Optional.
  - `:scope` — caller-owned scope value. Optional and opaque to Threadline.
  - `:scope_query_fn` — callback that adds caller scope predicates. Optional.
  - `:cast` — load the captured map into the schema struct. Optional; defaults to `false`.

  ## Returns

  - `{:ok, snapshot}` — the latest captured row state at or before `timestamp`.
  - `{:error, :deleted_record}` — the latest change at that time is a delete.
  - `{:error, :before_audit_horizon}` — no captured state exists at or before the timestamp.
  - `{:error, {:cast_error, message}}` — schema loading failed with `cast: true`.
  - Raises `ArgumentError` for an invalid row key and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.as_of(MyApp.User, 42, ~U[2026-01-01 00:00:00Z], repo: MyApp.Repo)
      Threadline.as_of(MyApp.LineItem, [tenant_id: 1, id: 5], timestamp, repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc group: "Querying & Timelines"
  @spec as_of(module(), row_id(), DateTime.t(), [as_of_opt()]) ::
          {:ok, json_map() | struct()}
          | {:error, :deleted_record | :before_audit_horizon}
          | {:error, {:cast_error, String.t()}}
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
  @doc group: "Actions & Context"
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

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc group: "Querying & Timelines"
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

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.

  ## Examples

      first = Threadline.timeline_page([table: "users"], repo: MyApp.Repo)
      Threadline.timeline_page([table: "users"], repo: MyApp.Repo, cursor: first.cursor)
  """
  @doc group: "Querying & Timelines"
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

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc since: "1.0.0", group: "Querying & Timelines"
  @spec row_history(module(), row_id(), [row_history_opt()]) ::
          [Threadline.Investigation.LinkedChange.t()]
          | Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  def row_history(schema_module, id, opts \\ []) when is_list(opts),
    do: Investigation.row_history(schema_module, id, opts)

  @deprecated "Use Threadline.row_history/3 instead."
  @doc """
  Returns a list of linked changes for one schema row using the retired `(filters, opts)` shape and its unbounded default.

  Use `row_history/3` and pass `limit: :infinity` to keep the unbounded behavior. The `filters` argument accepts only row-history filters. For duplicate `:repo`, `:from`, or `:to` keys, the value in `filters` takes precedence over the value in `opts`, preserving the legacy call's ordering.

  ## Filters

  - `:repo` — `Ecto.Repo` module. Optional when supplied in `opts`.
  - `:from` — inclusive lower bound on `captured_at`. Optional.
  - `:to` — inclusive upper bound on `captured_at`. Optional.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — storage schema override. Optional.
  - `:scope` — caller-owned scope value. Optional and opaque to Threadline.
  - `:scope_query_fn` — callback that adds caller scope predicates. Optional.
  - `:from` — inclusive lower bound on `captured_at`. Optional.
  - `:to` — inclusive upper bound on `captured_at`. Optional.
  - `:limit` — positive integer or `:infinity`. Optional; defaults to `:infinity` for this deprecated shape.
  - `:cursor` — `:start` or a prior row-history cursor. Optional; returns a page.
  - `:page_size` — positive integer. Optional; applies with `:cursor`.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - A list of `%Threadline.Investigation.LinkedChange{}` rows.
  - Raises `ArgumentError` for invalid filters, options, or row keys, and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.row_history(MyApp.User, 42, [from: start_time], repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc group: "Querying & Timelines"
  @spec row_history(module(), row_id(), [row_history_filter()], [row_history_legacy_opt()]) ::
          [Threadline.Investigation.LinkedChange.t()]
          | Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  def row_history(schema_module, id, filters, opts)
      when is_list(filters) and is_list(opts) do
    row_history(schema_module, id, LegacyOpts.row_history(filters, opts))
  end

  @deprecated "Use Threadline.row_history/3 instead."
  @doc """
  Returns a `%Threadline.Page{}` of linked changes for one schema row using the retired first-page convention.

  Use `row_history/3` with `cursor: :start` and optional `page_size:`. An absent or `nil` cursor here still begins the first page.

  ## Filters

  - `:repo` — `Ecto.Repo` module. Optional when supplied in `opts`.
  - `:from` — inclusive lower bound on `captured_at`. Optional.
  - `:to` — inclusive upper bound on `captured_at`. Optional.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — storage schema override. Optional.
  - `:scope` — caller-owned scope value. Optional and opaque to Threadline.
  - `:scope_query_fn` — callback that adds caller scope predicates. Optional.
  - `:from` — inclusive lower bound on `captured_at`. Optional.
  - `:to` — inclusive upper bound on `captured_at`. Optional.
  - `:limit` — positive integer or `:infinity`. Optional.
  - `:cursor` — `:start` or a prior row-history cursor. Optional; an absent or `nil` value begins the first page.
  - `:page_size` — positive integer. Optional; defaults to `1000`.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - A `%Threadline.Page{}` of matching linked changes.
  - Raises `ArgumentError` for invalid filters, options, cursor, or row keys, and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.row_history_page(MyApp.User, 42, [from: start_time], repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc group: "Querying & Timelines"
  @spec row_history_page(module(), row_id()) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  @spec row_history_page(module(), row_id(), [row_history_filter()]) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  @spec row_history_page(
          module(),
          row_id(),
          [row_history_filter()],
          [row_history_page_opt()]
        ) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  def row_history_page(schema_module, id, filters \\ [], opts \\ []),
    do:
      %Threadline.Page{} =
        Investigation.row_history(
          schema_module,
          id,
          LegacyOpts.row_history_page(filters, opts)
        )

  @doc """
  Returns `%Threadline.Investigation.LinkedChange{}` rows made by one actor
  across audited tables, newest first, as a list or `%Threadline.Page{}`.

  Use `actor_history/2` for one row per transaction. Pass `:cursor` to walk the
  changes in keyset pages.

  ## Filters

  - `:table` — string or atom. Optional. Matches `table_name`.
  - `:from` — `DateTime`. Optional. Inclusive lower bound on `captured_at`.
  - `:to` — `DateTime`. Optional. Inclusive upper bound on `captured_at`.
  - `:correlation_id` — non-empty string. Optional. Matches linked action correlation.
  - `:repo` — `Ecto.Repo` module. Optional when supplied in `opts`.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — string. Optional. Selects a Threadline storage schema override.
  - `:scope` — caller-owned value. Optional. Opaque to Threadline and passed to `:scope_query_fn`.
  - `:scope_query_fn` — function. Optional. Adds the caller's scope predicates to the read.
  - `:cursor` — `:start` or a prior page cursor. Optional. Returns a page instead of a list.
  - `:page_size` — positive integer. Defaults to `1000`; applies when `:cursor` is set.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - A list of `%Threadline.Investigation.LinkedChange{}` rows, or a `%Threadline.Page{}` when `:cursor` is set.
  - Raises `ArgumentError` for invalid filters, cursor values, or a missing `:repo`.

  ## Examples

      Threadline.actor_window(actor_ref, [table: "members"], repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc since: "1.0.0", group: "Actions & Context"
  @spec actor_window(ActorRef.t(), [actor_window_filter()], [window_opt()]) ::
          [Threadline.Investigation.LinkedChange.t()]
          | Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  def actor_window(actor_ref, filters \\ [], opts \\ []) do
    OptionKeys.validate_filters!(filters, :actor_window)
    OptionKeys.validate!(opts, :actor_window)
    Investigation.actor_window(actor_ref, filters, opts)
  end

  @deprecated "Use Threadline.actor_window/3 instead."
  @doc """
  Returns a `%Threadline.Page{}` of linked changes made by one actor using the retired first-page convention.

  Use `actor_window/3` with `cursor: :start` and optional `page_size:`. An absent or `nil` cursor here still begins the first page.

  ## Filters

  - `:table` — string or atom. Optional; matches `table_name`.
  - `:from` — inclusive lower bound on `captured_at`. Optional.
  - `:to` — inclusive upper bound on `captured_at`. Optional.
  - `:correlation_id` — string. Optional; matches the linked action correlation.
  - `:repo` — `Ecto.Repo` module. Optional when supplied in `opts`.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — storage schema override. Optional.
  - `:scope` — caller-owned scope value. Optional and opaque to Threadline.
  - `:scope_query_fn` — callback that adds caller scope predicates. Optional.
  - `:cursor` — `:start` or a prior change cursor. Optional; an absent or `nil` value begins the first page.
  - `:page_size` — positive integer. Optional; defaults to `1000`.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - A `%Threadline.Page{}` of matching linked changes.
  - Raises `ArgumentError` for invalid filters, options, or cursor, and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.actor_window_page(actor_ref, [table: "members"], repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc group: "Actions & Context"
  @spec actor_window_page(ActorRef.t()) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  @spec actor_window_page(ActorRef.t(), [actor_window_page_filter()]) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  @spec actor_window_page(
          ActorRef.t(),
          [actor_window_page_filter()],
          [actor_window_page_opt()]
        ) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  def actor_window_page(actor_ref, filters \\ [], opts \\ []),
    do:
      %Threadline.Page{} =
        Investigation.actor_window(actor_ref, filters, LegacyOpts.cursor(opts))

  @doc """
  Returns linked change rows for one `correlation_id`, newest first, as a list
  or `%Threadline.Page{}`. Correlation uses strict inner-join semantics.

  Use `actor_window/3` to read changes for one actor across tables. Pass
  `:cursor` to walk correlation results in keyset pages.

  ## Filters

  - `:table` — string or atom. Optional. Matches `table_name`.
  - `:actor_ref` — `%ActorRef{}`. Optional. Matches the transaction actor.
  - `:from` — `DateTime`. Optional. Inclusive lower bound on `captured_at`.
  - `:to` — `DateTime`. Optional. Inclusive upper bound on `captured_at`.
  - `:repo` — `Ecto.Repo` module. Optional when supplied in `opts`.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — string. Optional. Selects a Threadline storage schema override.
  - `:scope` — caller-owned value. Optional. Opaque to Threadline and passed to `:scope_query_fn`.
  - `:scope_query_fn` — function. Optional. Adds the caller's scope predicates to the read.
  - `:cursor` — `:start` or a prior page cursor. Optional. Returns a page instead of a list.
  - `:page_size` — positive integer. Defaults to `1000`; applies when `:cursor` is set.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - A list of `%Threadline.Investigation.LinkedChange{}` rows, or a `%Threadline.Page{}` when `:cursor` is set.
  - Raises `ArgumentError` for invalid filters, cursor values, or a missing `:repo`.

  ## Examples

      Threadline.correlation_bundle("member-42", [table: "members"], repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc since: "1.0.0", group: "Actions & Context"
  @spec correlation_bundle(String.t(), [correlation_bundle_filter()], [window_opt()]) ::
          [Threadline.Investigation.LinkedChange.t()]
          | Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  def correlation_bundle(correlation_id, filters \\ [], opts \\ []) do
    OptionKeys.validate_filters!(filters, :correlation_bundle)
    OptionKeys.validate!(opts, :correlation_bundle)
    Investigation.correlation_bundle(correlation_id, filters, opts)
  end

  @deprecated "Use Threadline.correlation_bundle/3 instead."
  @doc """
  Returns a `%Threadline.Page{}` of linked changes for one correlation using the retired first-page convention.

  Use `correlation_bundle/3` with `cursor: :start` and optional `page_size:`. An absent or `nil` cursor here still begins the first page.

  ## Filters

  - `:table` — string or atom. Optional; matches `table_name`.
  - `:actor_ref` — `%ActorRef{}`. Optional; matches the transaction actor.
  - `:from` — inclusive lower bound on `captured_at`. Optional.
  - `:to` — inclusive upper bound on `captured_at`. Optional.
  - `:repo` — `Ecto.Repo` module. Optional when supplied in `opts`.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — storage schema override. Optional.
  - `:scope` — caller-owned scope value. Optional and opaque to Threadline.
  - `:scope_query_fn` — callback that adds caller scope predicates. Optional.
  - `:cursor` — `:start` or a prior change cursor. Optional; an absent or `nil` value begins the first page.
  - `:page_size` — positive integer. Optional; defaults to `1000`.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - A `%Threadline.Page{}` of matching linked changes.
  - Raises `ArgumentError` for invalid filters, options, or cursor, and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.correlation_bundle_page("member-42", [table: "members"], repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc group: "Actions & Context"
  @spec correlation_bundle_page(String.t()) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  @spec correlation_bundle_page(String.t(), [correlation_bundle_page_filter()]) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  @spec correlation_bundle_page(
          String.t(),
          [correlation_bundle_page_filter()],
          [correlation_bundle_page_opt()]
        ) ::
          Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
  def correlation_bundle_page(correlation_id, filters \\ [], opts \\ []),
    do:
      %Threadline.Page{} =
        Investigation.correlation_bundle(
          correlation_id,
          filters,
          LegacyOpts.cursor(opts)
        )

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
  @doc since: "1.0.0", group: "Capture & Transactions"
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
  @doc since: "1.0.0", group: "Capture & Transactions"
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

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc group: "Capture & Transactions"
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

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc since: "1.0.0", group: "Capture & Transactions"
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

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc group: "Capture & Transactions"
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

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc since: "1.0.0", group: "Capture & Transactions"
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

  Use `transaction_context/2` when the transaction, action, and linked changes belong in one result. The query applies the transaction visibility predicate supplied through `:scope_query_fn`.

  `transaction_id` is `audit_transactions.id`. Accepts UUID strings or 16-byte
  binaries; raises `ArgumentError` when the id is not a valid UUID. Returns `[]`
  when the UUID is well-formed but no matching rows exist. Ordered by
  `captured_at` descending, then `id` descending — the same total order as
  `timeline/2`.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:storage_schema` — storage schema override. Optional.
  - `:scope` — caller-owned scope value. Optional and opaque to Threadline.
  - `:scope_query_fn` — callback that adds caller scope predicates. Optional.
  - `:preload` — optional association list, e.g. `[:transaction]`, forwarded to
    `repo.preload/3` when non-empty. Preloading `:action` under `:transaction`
    (`transaction: :action` / `transaction: [:action, ...]`) is deprecated: it
    still hydrates `transaction.action`, but emits one warning per call and will
    be removed no earlier than Threadline 2.0. Prefer `transaction_context/2`.

  ## Returns

  - A list of `%Threadline.Capture.AuditChange{}` rows ordered by `captured_at` and `id` descending.
  - Raises `ArgumentError` for an invalid UUID or preload value, and `KeyError` when `:repo` is missing.

  ## Examples

      Threadline.audit_changes_for_transaction(transaction_id, repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc group: "Capture & Transactions"
  @spec audit_changes_for_transaction(Ecto.UUID.t(), [audit_changes_opt()]) ::
          [Threadline.Capture.AuditChange.t()]
  def audit_changes_for_transaction(transaction_id, opts),
    do: Threadline.Query.audit_changes_for_transaction(transaction_id, opts)

  @doc """
  Returns CSV iodata and truncation metadata for matching captured changes.

  Use `export_json/2` when consumers need JSON; both functions share the
  timeline filter vocabulary and bounded export behavior.

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
  - `:scope_query_fn` — function. Optional. Adds the caller's scope predicates to the export read.
  - `:max_rows` — non-negative integer. Defaults to `10_000`; controls truncation.
  - `:include_action_metadata` — boolean. Defaults to `false`; appends action columns when true.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - `{:ok, %{data: iodata, truncated: boolean, returned_count: non_neg_integer, max_rows: non_neg_integer}}` — CSV output and export counts.
  - Raises `ArgumentError` for invalid filters or missing `:repo`; repository errors are reraised.

  ## Examples

      Threadline.export_csv([table: "members"], repo: MyApp.Repo)

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc group: "Operations"
  @spec export_csv([timeline_filter()], [export_csv_opt()]) ::
          {:ok,
           %{
             data: iodata(),
             truncated: boolean(),
             returned_count: non_neg_integer(),
             max_rows: non_neg_integer()
           }}
  def export_csv(filters \\ [], opts \\ []) do
    started_at = System.monotonic_time()

    try do
      OptionKeys.validate_filters!(filters, :timeline)
      OptionKeys.validate!(opts, :export_csv)
    rescue
      exception ->
        Threadline.Telemetry.emit_export_failed(:csv, 0, :exception, exception, started_at)
        reraise exception, __STACKTRACE__
    end

    Threadline.Export.to_csv_iodata(filters, opts)
  end

  @doc """
  Returns JSON iodata and truncation metadata for matching captured changes.

  Use `export_csv/2` when consumers need CSV; both functions share the
  timeline filter vocabulary and bounded export behavior.

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
  - `:scope_query_fn` — function. Optional. Adds the caller's scope predicates to the export read.
  - `:max_rows` — non-negative integer. Defaults to `10_000`; controls truncation.
  - `:json_format` — `:wrapped` or `:ndjson`. Defaults to `:wrapped`.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Returns

  - `{:ok, %{data: iodata, truncated: boolean, returned_count: non_neg_integer, max_rows: non_neg_integer}}` — JSON output and export counts.
  - Raises `ArgumentError` for invalid filters or missing `:repo`, `CaseClauseError` for an unsupported format, and reraises repository errors.

  ## Examples

      Threadline.export_json([table: "members"], repo: MyApp.Repo, json_format: :ndjson)

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc group: "Operations"
  @spec export_json([timeline_filter()], [export_json_opt()]) ::
          {:ok,
           %{
             data: iodata(),
             truncated: boolean(),
             returned_count: non_neg_integer(),
             max_rows: non_neg_integer()
           }}
  def export_json(filters \\ [], opts \\ []) do
    started_at = System.monotonic_time()

    format =
      if Keyword.keyword?(opts) and Keyword.get(opts, :json_format) == :ndjson,
        do: :ndjson,
        else: :json

    try do
      OptionKeys.validate_filters!(filters, :timeline)
      OptionKeys.validate!(opts, :export_json)
    rescue
      exception ->
        Threadline.Telemetry.emit_export_failed(format, 0, :exception, exception, started_at)
        reraise exception, __STACKTRACE__
    end

    Threadline.Export.to_json_document(filters, opts)
  end

  @doc """
  Projects a captured `%Threadline.Capture.AuditChange{}` into a deterministic string-keyed map.

  Use `Threadline.row_history/3` to obtain linked changes before projecting them. This function delegates to `Threadline.ChangeDiff.from_audit_change/2`; its default output includes schema and before-value metadata, while `format: :export_compat` returns the export-compatible field set.

  ## Options

  - `:format` — `:primary` or `:export_compat`. Optional; defaults to `:primary`.
  - `:expand_insert_fields` — boolean. Optional; defaults to `false` and derives field rows for INSERT changes from `data_after`.

  ## Returns

  - A string-keyed map describing the captured change, with field-level changes and captured values.

  ## Examples

      Threadline.change_diff(audit_change)
      Threadline.change_diff(audit_change, format: :export_compat)

  Results contain column values as captured; redaction is applied when triggers are generated, not on read. Authorize reads with `:scope_query_fn`.
  """
  @doc group: "Querying & Timelines"
  @spec change_diff(Threadline.Capture.AuditChange.t()) :: json_map()
  @spec change_diff(Threadline.Capture.AuditChange.t(), [change_diff_opt()]) :: json_map()
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
