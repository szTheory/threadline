# Code walkthrough

This guide starts where [How Threadline works](how-threadline-works.md) stops. Follow it to trace an audited write through the implementation, understand why the main boundaries exist, and choose the right tests before changing them.

The excerpts are deliberately short and copied from the current source. `# ...` marks code removed only to keep the route readable. Module and function names are the durable navigation points; use the generated API reference or source search to open the complete definition.

> **Public API versus internals:** Reachability is not a support promise. Public modules and documented functions such as `Threadline.Audit.transaction/3`, `Threadline.Query`, `Threadline.Investigation`, `Threadline.ExportQueue`, and `Threadline.Storage` are adopter-facing contracts. Mix task implementation, generated SQL helpers, private query functions, schemas marked internal, and operator implementation modules are shown to explain the machinery. Do not call an internal function from host code merely because it appears below.

## Installation turns configuration into DDL

### 1. Storage schema resolution is centralized

Source: `Threadline.StorageSchema`.

The configured schema is validated once and reused for table and repository prefixes. That prevents generators, queries, and schemas from independently inventing qualification rules.

```elixir
def get(opts \\ []) when is_list(opts) do
  opts
  |> Keyword.get(:storage_schema, Application.get_env(:threadline, :storage_schema, @default))
  |> validate!()
end

# ...

def table(name, opts \\ []) when name in @threadline_tables do
  qualify(get(opts), name)
end

def repo_opts(opts \\ []), do: [prefix: get(opts)]
```

The important consequence is temporal: configure the storage schema before generating migrations. Existing migration SQL is host-owned and will not follow a later configuration change.

### 2. Installation adds missing migration families without overwriting

Source: `Mix.Tasks.Threadline.Install`.

Capture, semantics, and governance are separate migration families. A rerun can fill a missing family, but it does not replace one the host has already reviewed or edited.

```elixir
capture_written =
  if existing_capture_migration?(path) do
    Mix.shell().info("Threadline audit schema migration already exists — skipping.")
    false
  else
    file = Path.join(path, "#{timestamp()}_threadline_audit_schema.exs")
    create_file(file, Threadline.Capture.Migration.migration_content())
    true
  end

# ...

semantics_written =
  if existing_semantics_migration?(path) do
    Mix.shell().info("Threadline semantics schema migration already exists — skipping.")
    false
  else
    file = Path.join(path, "#{timestamp()}_threadline_semantics_schema.exs")
    create_file(file, Threadline.Semantics.Migration.migration_content())
    true
  end

# ...

governance_written =
  if existing_governance_migration?(path) do
    Mix.shell().info("Threadline governance schema migration already exists — skipping.")
    false
  else
    file = Path.join(path, "#{timestamp()}_threadline_governance_schema.exs")
    create_file(file, Threadline.Governance.Migration.migration_content())
    true
  end
```

The generated files are the review boundary between package-provided templates and the host database.

### 3. Trigger generation protects the audit tables and chooses a function shape

Source: `Mix.Tasks.Threadline.Gen.Triggers`.

The task rejects Threadline storage tables before generating anything. It then selects a shared trigger function for ordinary capture or a per-table function when sparse prior values or redaction require table-specific SQL.

```elixir
forbidden = Enum.filter(tables, &StorageSchema.threadline_table?/1)

if forbidden != [] do
  Mix.raise(
    "Cannot install audit triggers on Threadline's own tables: #{Enum.join(forbidden, ", ")}. " <>
      "This would cause a recursive audit loop (CAP-10)."
  )
end

# ...

needs_per_table = store_changed_from or exclude != [] or mask != []

%{needs_per_table: needs_per_table, opts: opts}

# ...

trig =
  if per?,
    do: TriggerSQL.create_trigger(t, :per_table),
    else: TriggerSQL.create_trigger(t)
```

This is an availability control as much as a convenience: installing a capture trigger on an audit table would make the audit write recursively audit itself.

### 4. The trigger groups row changes by PostgreSQL transaction

Source: the internal SQL generator in `Threadline.Capture.TriggerSQL`.

Every trigger invocation resolves the current PostgreSQL transaction ID, idempotently creates its parent capture row, and selects that row for the following `AuditChange` insert.

```elixir
defp transaction_capture_begin_sql(opts) do
  """
    v_txid := txid_current();

    -- Upsert the audit_transactions row keyed on the PostgreSQL transaction ID.
    -- ON CONFLICT DO NOTHING is idempotent: multiple writes in the same transaction
    -- reuse the existing row. This is PgBouncer-safe because txid_current() is
    -- transaction-scoped, not session-scoped.
    INSERT INTO #{StorageSchema.table("audit_transactions", opts)} (id, txid, occurred_at, actor_ref)
    VALUES (
      gen_random_uuid(),
      v_txid,
      clock_timestamp(),
      NULLIF(current_setting('threadline.actor_ref', true), '')::jsonb
    )
    ON CONFLICT (txid) DO NOTHING;

    SELECT id INTO v_tx_id
    FROM #{StorageSchema.table("audit_transactions", opts)}
    WHERE txid = v_txid;
  """
end
```

The uniqueness constraint on `txid` turns repeated row-level trigger calls into one capture transaction. The actor value is read, never assigned, by the trigger.

### 5. Redaction transforms the row before the audit insert

Source: the internal redaction builder in `Threadline.Capture.TriggerSQL`.

Excluded keys are removed. Masked keys are replaced with a stable JSON string. The generator emits these statements into the trigger body before it inserts the captured row.

```elixir
defp data_after_redaction_statements(_var, [], [], _placeholder), do: ""

defp data_after_redaction_statements(var, exclude, mask, placeholder) do
  strip =
    exclude
    |> Enum.map(fn col ->
      lit = sql_string_literal(col)
      "        #{var} := #{var} - #{lit};\n"
    end)
    |> IO.iodata_to_binary()

  mask_obj =
    if mask == [] do
      ""
    else
      pairs =
        mask
        |> Enum.map(fn col ->
          k = sql_string_literal(col)
          pe = mask_placeholder_sql_expr(placeholder)
          "#{k}, #{pe}"
        end)
        |> Enum.join(", ")

      "        #{var} := #{var} || jsonb_build_object(#{pairs});\n"
    end

  strip <> mask_obj
end
```

This is why changing only runtime configuration is insufficient: deployed PostgreSQL runs the SQL from the generated migration.

## Host context becomes transaction-local database facts

### 6. Actor references reject ambiguous identities

Source: `Threadline.Semantics.ActorRef`.

Non-anonymous actors require a known type and non-empty ID. Anonymous is explicit and serializes without an ID.

```elixir
def new(type, _id) when type not in @types do
  {:error, :unknown_actor_type}
end

def new(:anonymous, _id) do
  {:ok, %__MODULE__{type: :anonymous, id: nil}}
end

def new(type, id) when id in [nil, ""] do
  _ = type
  {:error, :missing_actor_id}
end

def new(type, id) when is_binary(id) do
  {:ok, %__MODULE__{type: type, id: id}}
end

# ...

def to_map(%__MODULE__{type: type, id: id}) do
  %{"type" => Atom.to_string(type), "id" => id}
end
```

The typed map is both the Ecto value and the payload published to PostgreSQL.

### 7. The Plug stays at the HTTP edge

Source: the public Plug callback in `Threadline.Plug`.

The Plug builds transient context and assigns it to the connection. There is intentionally no repository call here.

```elixir
def call(conn, %{actor_fn: actor_fn, context_overrides_fn: context_overrides_fn}) do
  context =
    %AuditContext{
      actor_ref: extract_actor(conn, actor_fn),
      request_id: extract_request_id(conn),
      correlation_id: get_req_header(conn, "x-correlation-id") |> List.first(),
      remote_ip: format_ip(conn.remote_ip)
    }
    |> apply_context_overrides(conn, context_overrides_fn)

  assign(conn, :audit_context, context)
end
```

This separation prevents request processing from placing identity on a database connection before the application has established a transaction boundary.

### 8. The audited-write helper owns that boundary

Source: public `Threadline.Audit.transaction/3` plus its internal GUC bridge.

The helper validates first, then begins one repository transaction, publishes the actor locally, runs domain code, and finalizes linkage before commit.

```elixir
def transaction(repo, opts, fun) when is_function(fun, 0) do
  resolved = resolve_opts(opts)

  with :ok <- validate_actor(resolved) do
    repo.transaction(fn ->
      set_actor_guc!(repo, resolved.actor_ref)

      result = fun.()

      case finalize_success(repo, resolved, result) do
        {:error, reason} -> repo.rollback(reason)
        ok -> ok
      end
    end)
    |> normalize_transaction_result()
  end
end

# ...

defp set_actor_guc!(repo, %ActorRef{} = actor_ref) do
  json =
    actor_ref
    |> ActorRef.to_map()
    |> Jason.encode!()

  repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
end
```

The third argument to `set_config` is `true`, making the value transaction-local. Host callbacks should not reproduce this bridge manually.

### 9. Semantic action linkage is part of success

Source: internal finalization in `Threadline.Audit`.

With an action, success means the action exists, the current capture transaction points to it, and the capture transaction ID is available. Any failed step returns an error to the outer transaction and causes rollback.

```elixir
defp finalize_success(repo, resolved, result) do
  case resolved.action_name do
    nil ->
      with :ok <- apply_capture_meta(repo, resolved),
           result_with_id <- attach_audit_transaction_id(repo, resolved, result) do
        result_with_id
      end

    action_name ->
      with {:ok, %AuditAction{id: action_id}} <- record_action(repo, resolved, action_name),
           :ok <- link_action(repo, action_id, resolved),
           {:ok, audit_transaction_id} <- fetch_audit_transaction_id(repo, resolved) do
        envelope(result, audit_transaction_id)
      end
  end
end

# ...

defp link_action(repo, action_id, resolved) do
  {count, _} =
    repo.update_all(
      from(at in AuditTransaction, where: at.txid == fragment("txid_current()")),
      [set: [action_id: action_id, meta: resolved.transaction_meta]],
      repo_opts(resolved)
    )

  if count == 1 do
    :ok
  else
    {:error, :missing_audit_transaction_for_link}
  end
end
```

The `count == 1` check catches a write callback that produced no capture row when correlation was promised.

### 10. Associations preserve the three different facts

Sources: `Threadline.Semantics.AuditAction`, `Threadline.Capture.AuditTransaction`, and `Threadline.Capture.AuditChange`.

The Ecto relationships mirror the database design: an optional action describes capture transactions, and every change belongs to exactly one capture transaction.

```elixir
schema "audit_actions" do
  field(:name, :string)
  field(:actor_ref, Threadline.Semantics.ActorRef)
  field(:correlation_id, :string)
  # ...
  has_many(:transactions, Threadline.Capture.AuditTransaction, foreign_key: :action_id)
end

# ...

schema "audit_transactions" do
  field(:txid, :integer)
  field(:occurred_at, :utc_datetime_usec)
  field(:meta, :map)
  field(:actor_ref, Threadline.Semantics.ActorRef)
  belongs_to(:action, Threadline.Semantics.AuditAction)
  has_many(:changes, Threadline.Capture.AuditChange, foreign_key: :transaction_id)
end

# ...

schema "audit_changes" do
  belongs_to(:transaction, Threadline.Capture.AuditTransaction, foreign_key: :transaction_id)
  field(:table_schema, :string)
  field(:table_name, :string)
  field(:table_pk, :map)
  field(:op, :string)
  field(:data_after, :map)
  field(:changed_fields, {:array, :string})
  field(:changed_from, :map)
end
```

Do not flatten these into a single “audit event” mentally. Their cardinalities explain capture-only rows, multi-row domain operations, and strict semantic filters.

## The read path assembles an investigation

### 11. Timeline correlation is an inner join, not a header search

Source: public query composition and its internal correlation filter in `Threadline.Query`.

Base predicates always join changes to their capture transaction. A correlation ID adds an inner join through the linked action.

```elixir
def timeline_query(filters) when is_list(filters) do
  filters
  |> timeline_base_query()
  |> filter_by_correlation(filters)
  |> timeline_order()
end

# ...

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
```

That invariant is why `AuditContext.correlation_id` alone is insufficient. The write must create and link an action for the filter to match.

### 12. Keyset pagination has a total order

Source: `Threadline.Query`.

The timestamp is the primary sort key and the UUID is the stable tiebreaker. The cursor uses the same tuple comparison, preventing duplicate or skipped rows when timestamps tie.

```elixir
defp timeline_order(query) do
  query
  |> order_by([ac], desc: ac.captured_at)
  |> order_by([ac], desc: ac.id)
end

# ...

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
```

Any change to ordering must update both halves together and retain tests with tied timestamps.

### 13. An incident bundle adds linked context and deterministic diffs

Source: public `Threadline.Investigation.incident_bundle/2` and its internal mapper.

The higher-level API loads the transaction header, applies host scope to both reads, loads linked actions, and packages each change with `Threadline.change_diff/1`.

```elixir
def incident_bundle(transaction_id, opts \\ []) do
  # ...
  case Query.audit_transaction(transaction_id, transaction_opts) do
    nil ->
      {:error, :not_found}

    transaction ->
      changes =
        Query.audit_changes_for_transaction(
          transaction_id,
          opts
          |> Keyword.put(:preload, transaction: :action)
          |> Keyword.put(:surface, :transaction)
          |> Keyword.put(:params, %{transaction_id: transaction_id})
        )

      linked_changes = to_linked_changes(changes)

      {:ok,
       %IncidentBundle{
         transaction: transaction,
         action: linked_action(transaction),
         changes: Enum.map(linked_changes, &to_incident_change/1)
       }}
  end
end

# ...

defp to_incident_change(%LinkedChange{} = linked_change) do
  %IncidentChange{
    linked_change: linked_change,
    change_diff: Threadline.change_diff(linked_change.audit_change)
  }
end
```

The public investigation layer is the better extension point for operator questions; callers do not need to reproduce preload and diff assembly.

## Optional surfaces compose outward

### 14. The router macro refuses an accidental open mount

Source: `Threadline.OperatorSurface.Router`.

The optional Phoenix surface is compiled only when LiveView is present. At mount time the macro requires a host pipeline, an authorization callback, or an explicit unauthenticated acknowledgement.

```elixir
defmacro threadline_operator_surface(path, opts \\ []) do
  has_auth_fn? = Keyword.has_key?(opts, :authorize_fn)
  has_actor_fn? = Keyword.has_key?(opts, :actor_fn)
  has_ack? = Keyword.get(opts, :adopter_acknowledges_unauthenticated, false)
  exports_enabled? = Keyword.get(opts, :exports, true)
  theme = Keyword.get(opts, :theme, :dark)
  caller_file = __CALLER__.file
  caller_line = __CALLER__.line

  unless theme in [:dark, :light, :system] do
    raise CompileError,
      file: caller_file,
      line: caller_line,
      description: "Threadline Operator Surface theme must be one of :dark | :light | :system"
  end

  # ...
end
```

Inside the omitted quoted router definition, LiveViews and controller exports receive distinct auth paths because a LiveView `on_mount` hook cannot guard ordinary controller routes.

### 15. Capability gates fail closed while tenant scope remains host-owned

Sources: internal `Threadline.OperatorSurface.Auth` and `Threadline.OperatorSurface.Scope`.

The main mount can rely on the host's secure pipeline or authorization callback. More sensitive coverage, policy, and evidence capabilities default to false. Once authorization returns a scope, Threadline treats it as opaque and invokes the host's query transformer.

```elixir
defp coverage_enabled_for_socket?(coverage_authorize_fn, socket)
     when is_function(coverage_authorize_fn, 1) do
  mirror = %{assigns: socket.assigns}

  case coverage_authorize_fn.(mirror) do
    :ok -> true
    true -> true
    {:ok, _scope} -> true
    _ -> false
  end
rescue
  _ -> false
end

# ...

def apply(query, opts \\ []) do
  scope = Keyword.get(opts, :scope)
  scope_query_fn = Keyword.get(opts, :scope_query_fn)

  cond do
    is_nil(scope) or is_nil(scope_query_fn) ->
      query

    is_function(scope_query_fn, 3) ->
      context = %{
        surface: Keyword.get(opts, :surface),
        params: Keyword.get(opts, :params, %{})
      }

      scope_query_fn.(query, scope, context)

    true ->
      query
  end
end
```

Threadline cannot infer a tenant predicate from arbitrary host data. The host must provide both the authorized scope and the function that applies it.

### 16. Queue and storage behaviours mark the adapter seams

Sources: public `Threadline.ExportQueue` and `Threadline.Storage`.

The default implementations are sufficient for a single-node process. Persistent queues and shared object storage fit behind small startup-validated contracts.

```elixir
@type job_id :: String.t() | binary()

@callback init(keyword()) :: :ok | {:error, term()}
@callback enqueue(job_id(), keyword()) :: :ok | {:error, term()}

# ...

@type file_id :: String.t()
@type path_or_content :: String.t() | binary()
@type options :: keyword()

@callback init(keyword()) :: :ok | {:error, term()}
@callback put(path_or_content(), options()) :: {:ok, file_id()} | {:error, term()}
@callback get(file_id()) :: {:ok, binary()} | {:error, term()}
@callback download_url(file_id(), options()) :: {:ok, String.t()} | {:error, term()}
@callback delete(file_id()) :: :ok | {:error, term()}
```

Adapter initialization runs during application startup when a host repository is configured, so a missing optional dependency fails early rather than at the first export.

### 17. The orchestrator streams, stores, and records a terminal state

Source: internal `Threadline.Export.Orchestrator`.

Large exports avoid holding the complete result in memory. They stream ordered rows to a temporary file, delegate persistence, clean up locally, and mark the job completed or failed.

```elixir
res =
  repo.transaction(
    fn ->
      file = File.open!(temp_path, [:write, :utf8])
      IO.binwrite(file, Export.csv_header())

      filters = prepare_filters(job.query_params, repo)

      Export.stream_export_rows(filters, repo: repo, storage_schema: storage_schema)
      |> Stream.chunk_every(1000)
      |> Enum.each(fn chunk ->
        iodata = Export.format_changes_iodata(chunk, :csv)
        IO.binwrite(file, iodata)
      end)

      File.close(file)

      case storage.put(temp_path) do
        {:ok, file_path} -> file_path
        {:error, reason} -> repo.rollback({:storage_error, reason})
      end
    end,
    timeout: :infinity
  )

# ...

case res do
  {:ok, file_path} ->
    mark_completed(repo, job, file_path, storage_opts)
    :ok

  {:error, reason} ->
    mark_failed(repo, job, inspect(reason), storage_opts)
    {:error, reason}
end
```

Retention follows the same outward-composition principle: the host enables it, a supervised pruner uses a PostgreSQL advisory lock, batched deletes yield between work units, and governance rows record the result. Evidence is narrower still: host code deliberately calls one of six public subject-specific entrypoints to append an attestation.

## Read the tests as the second implementation

The source shows mechanism; tests show which behavior maintainers have promised not to regress. Continue with one of these reading sessions:

1. **Audited request:** `Threadline.Audit` transaction tests → trigger context tests → transaction grouping tests → strict correlation tests.
2. **Capture policy:** trigger generator tests → redaction policy tests → trigger redaction integration tests → coverage tests.
3. **Investigation:** timeline pagination tests, especially timestamp ties → incident bundle tests → change-diff tests → `as_of/4` horizon and delete tests.
4. **Operator boundary:** router compilation tests → authorization tests → scope callback tests → controller export auth tests.
5. **Lifecycle:** export orchestrator and adapter contract tests → retention purge and advisory-lock tests → evidence subject and append-only history tests.
6. **Reference host:** the Phoenix example's audited context functions, generated migrations, secure router mount, and walkthrough tests show the pieces composed in an application.

When a change crosses two layers, run both sets of focused tests before the broad verification aliases. Return to [How Threadline works](how-threadline-works.md) whenever the local code makes it easy to lose sight of host ownership or the single-transaction invariant.
