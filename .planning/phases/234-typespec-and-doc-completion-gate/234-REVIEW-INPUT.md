# Documentation and Typespec Review Input

## Mix.Tasks.Threadline.Continuity

Brownfield capture cutover helper — honest T0 semantics (see `guides/brownfield-continuity.md`).



## Mix.Tasks.Threadline.Evidence.Show

Shows Threadline-owned evidence proof output through one canonical viewer task.



## Mix.Tasks.Threadline.Export

Loads application config, starts the configured Ecto repo, and writes an export file
using `Threadline.Export` — **no** ad-hoc `Ecto.Query` in this task (parity with
`mix threadline.retention.purge`).



## Mix.Tasks.Threadline.Gen.RowHistoryIndex

Generates an Ecto migration that adds `audit_changes_row_history_idx` to an
existing Threadline install.



## Mix.Tasks.Threadline.Gen.Triggers

Generates an Ecto migration that installs Threadline audit triggers on the
specified tables.



## Mix.Tasks.Threadline.Health.Coverage

Shows trigger coverage as reported by `Threadline.Health.trigger_coverage/1`,
with a three-section table (default) or JSON output (`--json`).



## Mix.Tasks.Threadline.Incident

Loads application config, starts the configured Ecto repo, and fetches
the incident bundle for a given transaction ID.



## Mix.Tasks.Threadline.Install

Generates an Ecto migration file for the Threadline audit schema.



## Mix.Tasks.Threadline.Policy.Show

Shows configured versus deployed redaction policy drift for Threadline capture
triggers through the same report shape used by the operator surface.



## Mix.Tasks.Threadline.Retention.Purge

Delegates to `Threadline.Retention.purge/1` after loading application config and
starting the configured Ecto repo (same resolution pattern as `mix threadline.verify_coverage`).



## Mix.Tasks.Threadline.VerifyCoverage

Verifies that tables listed in application config have Threadline audit
triggers installed, using the same catalog queries as `Threadline.Health.trigger_coverage/1`.



## Threadline

Threadline is an audit platform that captures database row changes and links them to application actions and execution context.
Threadline combines trigger-backed row-change capture, rich action semantics
(actor/intent/context), and operator-grade exploration.

### Threadline.actor_history/2 (function)

```text
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

```

**Specs**

```elixir
actor_history(Threadline.Semantics.ActorRef.t(), [actor_history_opt()]) ::
  Threadline.Page.t(Threadline.Capture.AuditTransaction.t())
```

### Threadline.actor_window/3 (function)

```text
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

```

**Specs**

```elixir
actor_window(Threadline.Semantics.ActorRef.t(), [actor_window_filter()], [window_opt()]) ::
  [Threadline.Investigation.LinkedChange.t()]
  | Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
```

### Threadline.actor_window_page/3 (function)

```text
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

```

**Specs**

```elixir
actor_window_page(Threadline.Semantics.ActorRef.t(), [actor_window_page_filter()], [
  actor_window_page_opt()
]) :: Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
```

### Threadline.as_of/4 (function)

```text
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

```

**Specs**

```elixir
as_of(module(), row_id(), DateTime.t(), [as_of_opt()]) ::
  {:ok, json_map() | struct()}
  | {:error, :deleted_record | :before_audit_horizon}
  | {:error, {:cast_error, String.t()}}
```

### Threadline.audit_changes_for_transaction/2 (function)

```text
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

```

**Specs**

```elixir
audit_changes_for_transaction(Ecto.UUID.t(), [audit_changes_opt()]) :: [
  Threadline.Capture.AuditChange.t()
]
```

### Threadline.audit_transaction/2 (function)

```text
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

```

**Specs**

```elixir
audit_transaction(Ecto.UUID.t(), [lookup_opt()]) ::
  {:ok, Threadline.Capture.AuditTransaction.t()} | {:error, :not_found}
```

### Threadline.audit_transaction!/2 (function)

```text
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

```

**Specs**

```elixir
audit_transaction!(Ecto.UUID.t(), [lookup_opt()]) :: Threadline.Capture.AuditTransaction.t()
```

### Threadline.change_diff/2 (function)

```text
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

```

**Specs**

```elixir
change_diff(Threadline.Capture.AuditChange.t(), [change_diff_opt()]) :: json_map()
```

### Threadline.correlation_bundle/3 (function)

```text
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

```

**Specs**

```elixir
correlation_bundle(String.t(), [correlation_bundle_filter()], [window_opt()]) ::
  [Threadline.Investigation.LinkedChange.t()]
  | Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
```

### Threadline.correlation_bundle_page/3 (function)

```text
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

```

**Specs**

```elixir
correlation_bundle_page(String.t(), [correlation_bundle_page_filter()], [
  correlation_bundle_page_opt()
]) :: Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
```

### Threadline.export_csv/2 (function)

```text
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

```

**Specs**

```elixir
export_csv([timeline_filter()], [export_csv_opt()]) ::
  {:ok,
   %{
     data: iodata(),
     truncated: boolean(),
     returned_count: non_neg_integer(),
     max_rows: non_neg_integer()
   }}
```

### Threadline.export_json/2 (function)

```text
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

```

**Specs**

```elixir
export_json([timeline_filter()], [export_json_opt()]) ::
  {:ok,
   %{
     data: iodata(),
     truncated: boolean(),
     returned_count: non_neg_integer(),
     max_rows: non_neg_integer()
   }}
```

### Threadline.history/3 (function)

```text
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

```

**Specs**

```elixir
history(module(), row_id(), [history_opt()]) :: [Threadline.Capture.AuditChange.t()]
```

### Threadline.incident_bundle/2 (function)

```text
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

```

**Specs**

```elixir
incident_bundle(Ecto.UUID.t(), [lookup_opt()]) ::
  {:ok, Threadline.Investigation.IncidentBundle.t()} | {:error, :not_found}
```

### Threadline.incident_bundle!/2 (function)

```text
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

```

**Specs**

```elixir
incident_bundle!(Ecto.UUID.t(), [lookup_opt()]) :: Threadline.Investigation.IncidentBundle.t()
```

### Threadline.record_action/2 (function)

```text
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

    Threadline.record_action(:member_role_changed,
      actor: %Threadline.Semantics.ActorRef{type: "user", id: "u-42"},
      repo: MyApp.Repo,
      category: "membership",
      verb: "update",
      correlation_id: "request-8f2"
    )

```

**Specs**

```elixir
record_action(atom(), [record_action_opt()]) ::
  {:ok, Threadline.Semantics.AuditAction.t()}
  | {:error, Ecto.Changeset.t()}
  | {:error, :missing_actor | :invalid_actor_ref | :missing_repo}
```

### Threadline.row_history/3 (function)

```text
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

```

**Specs**

```elixir
row_history(module(), row_id(), [row_history_opt()]) ::
  [Threadline.Investigation.LinkedChange.t()]
  | Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
```

### Threadline.row_history/4 (function)

```text
Returns a list of linked changes for one schema row using the retired `(filters, opts)` shape and its unbounded default.

Use `row_history/3` and pass `limit: :infinity` to keep the unbounded behavior. The `filters` argument accepts only row-history filters; options are merged after filters and take precedence for duplicate keys.

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

```

**Specs**

```elixir
row_history(module(), row_id(), [row_history_filter()], [row_history_legacy_opt()]) ::
  [Threadline.Investigation.LinkedChange.t()]
  | Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
```

### Threadline.row_history_page/4 (function)

```text
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

```

**Specs**

```elixir
row_history_page(module(), row_id(), [row_history_filter()], [row_history_page_opt()]) ::
  Threadline.Page.t(Threadline.Investigation.LinkedChange.t())
```

### Threadline.timeline/2 (function)

```text
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

```

**Specs**

```elixir
timeline([timeline_filter()], [timeline_opt()]) :: [Threadline.Capture.AuditChange.t()]
```

### Threadline.timeline_page/2 (function)

```text
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

```

**Specs**

```elixir
timeline_page([timeline_filter()], [timeline_page_opt()]) ::
  Threadline.Page.t(Threadline.Capture.AuditChange.t())
```

### Threadline.transaction_context/2 (function)

```text
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

```

**Specs**

```elixir
transaction_context(Ecto.UUID.t(), [lookup_opt()]) ::
  {:ok, Threadline.Investigation.LinkedTransaction.t()} | {:error, :not_found}
```

### Threadline.transaction_context!/2 (function)

```text
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

```

**Specs**

```elixir
transaction_context!(Ecto.UUID.t(), [lookup_opt()]) ::
  Threadline.Investigation.LinkedTransaction.t()
```

### Threadline.correlation_bundle_page_opt/0 (@type)





An option accepted by the legacy paged correlation-bundle shape.



```elixir


correlation_bundle_page_opt() :: window_opt()


```

### Threadline.correlation_bundle_page_filter/0 (@type)





A filter accepted by the legacy paged correlation-bundle shape.



```elixir


correlation_bundle_page_filter() :: correlation_bundle_filter()


```

### Threadline.actor_window_page_opt/0 (@type)





An option accepted by the legacy paged actor-window shape.



```elixir


actor_window_page_opt() :: window_opt()


```

### Threadline.actor_window_page_filter/0 (@type)





A filter accepted by the legacy paged actor-window shape.



```elixir


actor_window_page_filter() :: actor_window_filter()


```

### Threadline.row_history_page_opt/0 (@type)





An option accepted by the legacy paged row-history read shape.



```elixir


row_history_page_opt() :: row_history_opt()


```

### Threadline.row_history_legacy_opt/0 (@type)





An option accepted by the legacy row-history read shape.



```elixir


row_history_legacy_opt() :: row_history_opt()


```

### Threadline.row_history_filter/0 (@type)





A row-history filter accepted by the legacy filters-and-options shapes.



```elixir


row_history_filter() :: repo_opt() | {:from, DateTime.t()} | {:to, DateTime.t()}


```

### Threadline.history_opt/0 (@type)





An option accepted by the legacy unbounded history read.



```elixir


history_opt() ::
  repo_opt()
  | storage_schema_opt()
  | scope_opt()
  | {:from, DateTime.t()}
  | {:to, DateTime.t()}
  | {:limit, pos_integer() | :infinity | nil}


```

### Threadline.change_diff_opt/0 (@type)





An option accepted by `change_diff/2`.



```elixir


change_diff_opt() :: {:format, :primary | :export_compat} | {:expand_insert_fields, boolean()}


```

### Threadline.audit_changes_opt/0 (@type)





An option accepted by `audit_changes_for_transaction/2`.



```elixir


audit_changes_opt() ::
  repo_opt()
  | storage_schema_opt()
  | scope_opt()
  | {:preload, [atom() | {atom(), atom() | [atom()]}] | nil}


```

### Threadline.as_of_opt/0 (@type)





An option accepted by `as_of/4`.



```elixir


as_of_opt() :: repo_opt() | storage_schema_opt() | scope_opt() | {:cast, boolean()}


```

### Threadline.record_action_opt/0 (@type)





An option accepted by `record_action/2`; supply either `:actor` or `:actor_ref` and a repository.



```elixir


record_action_opt() ::
  repo_opt()
  | storage_schema_opt()
  | {:actor, Threadline.Semantics.ActorRef.t()}
  | {:actor_ref, Threadline.Semantics.ActorRef.t()}
  | {:status, :ok | :error}
  | {:verb, atom() | String.t()}
  | {:category, atom() | String.t()}
  | {:reason, atom() | String.t()}
  | {:comment, String.t()}
  | {:correlation_id, String.t()}
  | {:request_id, String.t()}
  | {:job_id, String.t()}


```

### Threadline.export_json_opt/0 (@type)





An option accepted by `export_json/2`.



```elixir


export_json_opt() ::
  repo_opt()
  | storage_schema_opt()
  | scope_opt()
  | {:max_rows, non_neg_integer()}
  | {:json_format, :wrapped | :ndjson}


```

### Threadline.export_csv_opt/0 (@type)





An option accepted by `export_csv/2`.



```elixir


export_csv_opt() ::
  repo_opt()
  | storage_schema_opt()
  | scope_opt()
  | {:max_rows, non_neg_integer()}
  | {:include_action_metadata, boolean()}


```

### Threadline.window_opt/0 (@type)





An option accepted by `actor_window/3` and `correlation_bundle/3`.



```elixir


window_opt() ::
  repo_opt()
  | storage_schema_opt()
  | scope_opt()
  | {:cursor, :start | Threadline.Page.change_cursor()}
  | {:page_size, pos_integer()}


```

### Threadline.correlation_bundle_filter/0 (@type)





A filter for changes linked to one correlation id.



```elixir


correlation_bundle_filter() ::
  {:table, atom() | String.t()}
  | {:actor_ref, Threadline.Semantics.ActorRef.t()}
  | {:from, DateTime.t()}
  | {:to, DateTime.t()}
  | repo_opt()


```

### Threadline.actor_window_filter/0 (@type)





A filter for changes made by one actor.



```elixir


actor_window_filter() ::
  {:table, atom() | String.t()}
  | {:from, DateTime.t()}
  | {:to, DateTime.t()}
  | {:correlation_id, String.t()}
  | repo_opt()


```

### Threadline.actor_history_opt/0 (@type)





An option accepted by `actor_history/2`; `:after`, `:before`, and `:limit` are deprecated aliases.



```elixir


actor_history_opt() ::
  repo_opt()
  | storage_schema_opt()
  | scope_opt()
  | {:from, DateTime.t()}
  | {:to, DateTime.t()}
  | {:cursor, :start | Threadline.Page.actor_cursor() | {:before, Threadline.Page.actor_cursor()}}
  | {:page_size, pos_integer()}
  | {:after, Threadline.Page.actor_cursor()}
  | {:before, Threadline.Page.actor_cursor()}
  | {:limit, pos_integer()}


```

### Threadline.timeline_page_opt/0 (@type)





An option accepted by `timeline_page/2`.



```elixir


timeline_page_opt() ::
  timeline_opt()
  | {:page_size, pos_integer()}
  | {:cursor, :start | Threadline.Page.change_cursor()}


```

### Threadline.timeline_opt/0 (@type)





An option accepted by `timeline/2`.



```elixir


timeline_opt() :: repo_opt() | storage_schema_opt() | scope_opt()


```

### Threadline.timeline_filter/0 (@type)





A timeline filter for captured changes.



```elixir


timeline_filter() ::
  repo_opt()
  | {:table, atom() | String.t()}
  | {:table_schema, atom() | String.t()}
  | {:actor_ref, Threadline.Semantics.ActorRef.t()}
  | {:from, DateTime.t()}
  | {:to, DateTime.t()}
  | {:correlation_id, String.t()}


```

### Threadline.lookup_opt/0 (@type)





An option accepted by the single-transaction lookup functions.



```elixir


lookup_opt() :: repo_opt() | storage_schema_opt() | scope_opt()


```

### Threadline.row_history_opt/0 (@type)





An option accepted by `row_history/3`.



```elixir


row_history_opt() ::
  repo_opt()
  | storage_schema_opt()
  | scope_opt()
  | {:from, DateTime.t()}
  | {:to, DateTime.t()}
  | {:limit, pos_integer() | :infinity}
  | {:cursor, :start | Threadline.Page.change_cursor()}
  | {:page_size, pos_integer()}


```

### Threadline.json_map/0 (@type)





A string-keyed JSON map decoded from jsonb or bound for JSON encoding; owning types list guaranteed keys and new keys may be added.



```elixir


json_map() :: %{optional(String.t()) => json_value()}


```

### Threadline.json_value/0 (@type)





A JSON value supported in a captured or exported JSON map.



```elixir


json_value() :: nil | boolean() | number() | String.t() | [json_value()] | json_map()


```

### Threadline.row_id/0 (@type)





A single host key or every field of a composite key as a map or keyword list.



```elixir


row_id() ::
  row_key_scalar()
  | %{optional(atom() | String.t()) => row_key_scalar()}
  | [{atom() | String.t(), row_key_scalar()}]


```

### Threadline.row_key_scalar/0 (@type)





A scalar host-table key value supported by Ecto.



```elixir


row_key_scalar() ::
  String.t()
  | integer()
  | float()
  | boolean()
  | Date.t()
  | DateTime.t()
  | NaiveDateTime.t()
  | Decimal.t()


```

### Threadline.scope_opt/0 (@type)





A caller-owned scope value or callback; the scope value is opaque to Threadline.



```elixir


scope_opt() :: {:scope, term()} | {:scope_query_fn, scope_query_fn()}


```

### Threadline.scope_query_fn/0 (@type)





A query callback that applies the caller's scope; the scope value is opaque to Threadline.



```elixir


scope_query_fn() :: (Ecto.Query.t(), term(), %{surface: atom(), params: map()} -> Ecto.Query.t())


```

### Threadline.storage_schema_opt/0 (@type)





An option that selects a Threadline storage schema override.



```elixir


storage_schema_opt() :: {:storage_schema, String.t()}


```

### Threadline.repo_opt/0 (@type)





An option that selects the Ecto repository used for a read.



```elixir


repo_opt() :: {:repo, module()}


```

## Threadline.Audit

Threadline.Audit runs a domain write inside one database transaction and
optionally links the write to a semantic action.

### Threadline.Audit.transaction/3 (function)

```text
Runs `fun` inside `repo.transaction/1` after setting the transaction-local
`threadline.actor_ref` GUC and optionally recording a semantic action, then returns
`{:ok, result}` or `{:error, reason}`. On success, `result` may include an
`:audit_transaction_id` when capture creates an `audit_transactions` row: Threadline merges the
id into map results and wraps non-map results as `%{result: value, audit_transaction_id: id}`.

See module doc for options, callback rules, and return envelope.

```

**Specs**

```elixir
transaction(module(), [transaction_opt()], (-> result)) :: {:ok, result} | {:error, term()}
when result: term()
```

### Threadline.Audit.transaction_opt/0 (@type)





An option accepted by `transaction/3`.



```elixir


transaction_opt() ::
  {:actor_ref, Threadline.Semantics.ActorRef.t() | nil}
  | {:audit_context, Threadline.Semantics.AuditContext.t() | nil}
  | {:action, action_opt() | nil}
  | {:capture_only, boolean()}
  | {:allow_missing_actor, boolean()}
  | {:transaction_meta, Threadline.json_map() | nil}
  | {:correlation_id, String.t() | nil}
  | {:request_id, String.t() | nil}
  | {:job_id, String.t() | nil}
  | Threadline.storage_schema_opt()


```

### Threadline.Audit.action_opt/0 (@type)





An action name passed to `Threadline.record_action/2`, optionally paired with its typed options.



```elixir


action_opt() :: atom() | {atom(), [Threadline.record_action_opt()]}


```

## Threadline.Capture.AuditChange

An `AuditChange` is one row mutation in one audited table.

### Threadline.Capture.AuditChange.t/0 (@type)





One persisted row mutation with its captured table, row key, operation, and JSON snapshots.

`:data_after` is nil for deletes, and `:changed_fields` is nil when no update fields were captured.




```elixir


t() :: %Threadline.Capture.AuditChange{
  __meta__: Ecto.Schema.Metadata.t(),
  captured_at: DateTime.t(),
  changed_fields: [String.t()] | nil,
  changed_from: Threadline.json_map() | nil,
  data_after: Threadline.json_map() | nil,
  id: Ecto.UUID.t() | nil,
  op: String.t(),
  table_name: String.t(),
  table_pk: Threadline.json_map(),
  table_schema: String.t(),
  transaction: Threadline.Capture.AuditTransaction.t() | Ecto.Association.NotLoaded.t(),
  transaction_id: Ecto.UUID.t() | nil
}


```

## Threadline.Capture.AuditTransaction

An `AuditTransaction` groups row changes from one database transaction; it is not a request or an action.

### Threadline.Capture.AuditTransaction.t/0 (@type)





A database transaction that groups captured row changes.

The virtual `:action` is a hydrated `Threadline.Semantics.AuditAction`; nil until hydrated.




```elixir


t() :: %Threadline.Capture.AuditTransaction{
  __meta__: Ecto.Schema.Metadata.t(),
  action: Threadline.Semantics.AuditAction.t() | nil,
  action_id: Ecto.UUID.t() | nil,
  actor_ref: Threadline.Semantics.ActorRef.t() | nil,
  changes: [Threadline.Capture.AuditChange.t()] | Ecto.Association.NotLoaded.t(),
  id: Ecto.UUID.t() | nil,
  meta: Threadline.json_map() | nil,
  occurred_at: DateTime.t(),
  source: String.t() | nil,
  txid: integer()
}


```

## Threadline.ChangeDiff

Threadline.ChangeDiff projects one captured row change into deterministic, JSON-friendly maps.

### Threadline.ChangeDiff.from_audit_change/2 (function)

```text
Returns a deterministic string-keyed JSON projection for one `audit_change`.

## Primary format (default)

String keys throughout, including `"schema_version"`, `"before_values"` (`"none"` or
`"sparse"`), `"field_changes"` (lexicographically sorted by `"name"`), and core row
identifiers compatible with integrator expectations (`"op"`, `"id"`, `"transaction_id"`,
`"table_schema"`, `"table_name"`, `"table_pk"`, `"captured_at"` as ISO-8601 UTC,
`"data_after"`).

## `:export_compat`

When `opts` contains `format: :export_compat`, returns a **single flat** string-key map
aligned with **`Threadline.Export`** `change_map/1` **base** fields: `"id"`,
`"transaction_id"`, `"table_schema"`, `"table_name"`, `"op"`, `"captured_at"`,
`"table_pk"`, `"data_after"`, `"changed_fields"`, `"changed_from"`. IDs are coerced
with `to_string/1`; `table_pk` defaults to `%{}`, `changed_fields` to `[]`,
`changed_from` to `%{}` when nil. Nested `"transaction"` and `"action"` are **not**
included unless future versions add optional preload parameters.

## Options

- `:format` — `:primary` or `:export_compat`. Defaults to `:primary`.
- `:expand_insert_fields` — boolean. Defaults to `false`; adds presentation-only field rows for INSERT changes.

Unknown option keys are ignored.

## Returns

- `change_diff_result()` — a string-keyed map in the selected format.
- Raises `ArgumentError` when the captured operation is unsupported.
- Raises `FunctionClauseError` when `audit_change` is not an `%AuditChange{}`.

Results contain column values as captured; redaction is applied when
triggers are generated, not on read. Authorize reads with `:scope_query_fn`.

```

**Specs**

```elixir
from_audit_change(Threadline.Capture.AuditChange.t(), [Threadline.change_diff_opt()]) ::
  change_diff_result()
```

### Threadline.ChangeDiff.change_diff_result/0 (@type)





A JSON-bound row-change projection. The primary form includes `schema_version`,
`before_values`, `op`, `id`, `transaction_id`, `table_schema`, `table_name`,
`table_pk`, `captured_at`, `data_after`, and `field_changes`. The
`:export_compat` form includes `id`, `transaction_id`, `table_schema`,
`table_name`, `op`, `captured_at`, `table_pk`, `data_after`,
`changed_fields`, and `changed_from`. Future additive keys are allowed.




```elixir


change_diff_result() :: Threadline.json_map()


```

## Threadline.Continuity

`Threadline.Continuity` documents the post-install capture boundary that
starts each table's audit history at its first trigger-fired mutation.

### Threadline.Continuity.assert_capture_ready!/2 (function)

```text
Returns `:ok` when `table_name` exists and has a Threadline capture trigger;
raises `ArgumentError` when the table, schema, or trigger is missing, and
`KeyError` when the required `:repo` option is missing.

Bare table names resolve to the public host schema by default. Pass
`schema: "support"` for a selected host schema, or pass a schema-qualified
identifier such as `"support.tickets"`.

## Options

- `:repo` — `Ecto.Repo` module. Required.
- `:schema` — host schema string. Optional. Selects the schema for a bare table name.

## Returns

- `:ok` — the table exists and has an enabled Threadline capture trigger.
- Raises `ArgumentError` when the table or schema is unknown or the trigger is absent.

Other option keys are ignored.

```

**Specs**

```elixir
assert_capture_ready!(String.t(), [assert_capture_ready_opt()]) :: :ok
```

### Threadline.Continuity.explain_cutover/1 (function)

```text
Returns `{:ok, iodata()}` containing a human-readable, read-only explanation
of brownfield cutover steps. Raises `KeyError` when the required `:repo`
option is missing.

## Options

- `:repo` — `Ecto.Repo` module. Required for compatibility with continuity checks.

## Returns

- `{:ok, iodata()}` — the cutover checklist as newline-separated text.

Other option keys are ignored.

```

**Specs**

```elixir
explain_cutover([explain_cutover_opt()]) :: {:ok, iodata()}
```

### Threadline.Continuity.assert_capture_ready_opt/0 (@type)





An option accepted by `assert_capture_ready!/2`.



```elixir


assert_capture_ready_opt() :: Threadline.repo_opt() | {:schema, String.t()}


```

### Threadline.Continuity.explain_cutover_opt/0 (@type)





An option accepted by `explain_cutover/1`.



```elixir


explain_cutover_opt() :: Threadline.repo_opt()


```

## Threadline.Evidence

Threadline evidence records snapshot a subject's status and details at a point in time.

### Threadline.Evidence.get_latest_subject_ref/3 (function)

```text
Returns the newest `EvidenceRecord` for one subject and subject reference, or `nil` when none exists.

Use `list_subject_ref_history/4` when every snapshot for the reference is
needed. This lookup uses the full subject reference and does not apply date
bounds or a result limit.

## Options

- `:repo` — Ecto repository module. Required.
- `:storage_schema` — string storage schema override. Optional.

## Returns

Returns the newest `%Threadline.Governance.EvidenceRecord{}` or `nil` when no
row matches. Raises `ArgumentError` for an unsupported subject, an invalid
subject reference, a missing repository, or an invalid storage schema.

```

**Specs**

```elixir
get_latest_subject_ref(
  Threadline.Evidence.Subject.subject_descriptor(),
  subject_ref(),
  [get_latest_subject_ref_opt()]
) :: Threadline.Governance.EvidenceRecord.t() | nil
```

### Threadline.Evidence.list_history/2 (function)

```text
Returns matching `EvidenceRecord` snapshots ordered newest first by recorded time and ID.

Use `list_subject_ref_history/4` to read one subject reference's history.
This function can combine multiple subjects and references; `:from` and
`:to` are inclusive, and `:limit` caps the returned list.

## Filters

- `:repo` — Ecto repository module. Optional when supplied in options.
- `:subject` — supported subject name, atom, or descriptor. Optional.
- `:subject_ref` — subject reference map. Optional.
- `:from` — `DateTime`. Optional; inclusive lower bound on `recorded_at`.
- `:to` — `DateTime`. Optional; inclusive upper bound on `recorded_at`.
- `:limit` — positive integer. Optional; caps the result list.

Unknown keys raise `ArgumentError` naming the allowed keys.

## Options

- `:repo` — Ecto repository module. Required in filters or options; the option takes precedence.
- `:storage_schema` — string storage schema override. Optional.

## Returns

Returns a list of `%Threadline.Governance.EvidenceRecord{}` rows, including
an empty list when no records match. Raises `ArgumentError` for invalid
filters, a missing repository, or an invalid storage schema.

```

**Specs**

```elixir
list_history([history_filter()], [list_history_opt()]) :: [
  Threadline.Governance.EvidenceRecord.t()
]
```

### Threadline.Evidence.list_latest_subject_refs/3 (function)

```text
Returns the newest `EvidenceRecord` for each reference in one subject family, newest first.

Use `list_history/2` to inspect every snapshot in the family. The date bounds
apply before the newest row per reference is selected.

## Filters

- `:repo` — Ecto repository module. Optional when supplied in options.
- `:from` — `DateTime`. Optional; inclusive lower bound on `recorded_at`.
- `:to` — `DateTime`. Optional; inclusive upper bound on `recorded_at`.
- `:limit` — positive integer. Optional; caps the result list.

Unknown keys raise `ArgumentError` naming the allowed keys.

## Options

- `:repo` — Ecto repository module. Required in filters or options; the option takes precedence.
- `:storage_schema` — string storage schema override. Optional.

## Returns

Returns a list with at most one row per subject reference, or an empty list
when no records match. Raises `ArgumentError` for an unsupported subject, an
invalid filter, a missing repository, or an invalid storage schema.

```

**Specs**

```elixir
list_latest_subject_refs(Threadline.Evidence.Subject.subject_descriptor(), [latest_filter()], [
  list_latest_subject_refs_opt()
]) :: [Threadline.Governance.EvidenceRecord.t()]
```

### Threadline.Evidence.list_overview/2 (function)

```text
Returns the newest `EvidenceRecord` for each subject reference across all supported subjects, newest first.

Use `list_latest_subject_refs/3` when the read should cover one subject
family. Inclusive date bounds apply before each latest row is selected.

## Filters

- `:repo` — Ecto repository module. Optional when supplied in options.
- `:from` — `DateTime`. Optional; inclusive lower bound on `recorded_at`.
- `:to` — `DateTime`. Optional; inclusive upper bound on `recorded_at`.
- `:limit` — positive integer. Optional; caps the combined result list.

Unknown keys raise `ArgumentError` naming the allowed keys.

## Options

- `:repo` — Ecto repository module. Required in filters or options; the option takes precedence.
- `:storage_schema` — string storage schema override. Optional.

## Returns

Returns a list with at most one row per subject reference, or an empty list
when no records match. Raises `ArgumentError` for an invalid filter, a
missing repository, or an invalid storage schema.

```

**Specs**

```elixir
list_overview([latest_filter()], [list_overview_opt()]) :: [
  Threadline.Governance.EvidenceRecord.t()
]
```

### Threadline.Evidence.list_subject_ref_history/4 (function)

```text
Returns `EvidenceRecord` snapshots for one subject and subject reference, newest first by recorded time and ID.

Use `list_history/2` to combine multiple subjects or references. The supplied
filters add inclusive time bounds and a result limit to the fixed subject and
reference.

## Filters

- `:repo` — Ecto repository module. Optional when supplied in options.
- `:from` — `DateTime`. Optional; inclusive lower bound on `recorded_at`.
- `:to` — `DateTime`. Optional; inclusive upper bound on `recorded_at`.
- `:limit` — positive integer. Optional; caps the result list.

Unknown keys raise `ArgumentError` naming the allowed keys.

## Options

- `:repo` — Ecto repository module. Required in filters or options; the option takes precedence.
- `:storage_schema` — string storage schema override. Optional.

## Returns

Returns a list of matching `%Threadline.Governance.EvidenceRecord{}` rows,
including an empty list when none match. Raises `ArgumentError` for an
unsupported subject, invalid subject reference or filter, a missing
repository, or an invalid storage schema.

```

**Specs**

```elixir
list_subject_ref_history(
  Threadline.Evidence.Subject.subject_descriptor(),
  subject_ref(),
  [subject_ref_history_filter()],
  [list_subject_ref_history_opt()]
) :: [Threadline.Governance.EvidenceRecord.t()]
```

### Threadline.Evidence.record_export_delivery/3 (function)

```text
Records an export-delivery evidence snapshot for `subject_ref` and returns `{:ok, record}` after persistence.

Evidence records are append-only snapshots. The caller supplies the delivery
status and optional actor, source context, and details.

## Options

- `:repo` — Ecto repository module. Required.
- `:storage_schema` — string storage schema override. Optional.

## Returns

Returns `{:ok, record}` when persisted, `{:error, changeset}` when record
validation fails, `{:error, :missing_repo}` when `:repo` is omitted, or
`{:error, {:invalid_subject_ref, value}}` when `subject_ref` is not a map.
Raises `ArgumentError` for an invalid storage schema.

```

**Specs**

```elixir
record_export_delivery(subject_ref(), export_delivery_attrs(), [record_opt()]) :: record_result()
```

### Threadline.Evidence.record_redaction_policy/3 (function)

```text
Records a redaction-policy evidence snapshot for `subject_ref` and returns `{:ok, record}` after persistence.

Evidence records are append-only snapshots. The caller supplies the policy
status and optional actor, source context, and details.

## Options

- `:repo` — the Ecto repository used to persist the record (required).
- `:storage_schema` — string storage schema override.

## Returns

Returns `{:ok, %Threadline.Governance.EvidenceRecord{}}` when persisted,
`{:error, changeset}` when record validation fails, `{:error, :missing_repo}`
when `:repo` is omitted, or `{:error, {:invalid_subject_ref, value}}` when
`subject_ref` is not a map.
Raises `ArgumentError` for an invalid storage schema.

```

**Specs**

```elixir
record_redaction_policy(subject_ref(), redaction_policy_attrs_input(), [record_opt()]) ::
  record_result()
```

### Threadline.Evidence.record_retention_policy/3 (function)

```text
Records a retention-policy evidence snapshot for `subject_ref` and returns `{:ok, record}` after persistence.

Evidence records are append-only snapshots. The caller supplies the policy
status and optional actor, source context, and details.

## Options

- `:repo` — Ecto repository module. Required.
- `:storage_schema` — string storage schema override. Optional.

## Returns

Returns `{:ok, record}` when persisted, `{:error, changeset}` when record
validation fails, `{:error, :missing_repo}` when `:repo` is omitted, or
`{:error, {:invalid_subject_ref, value}}` when `subject_ref` is not a map.
Raises `ArgumentError` for an invalid storage schema.

```

**Specs**

```elixir
record_retention_policy(subject_ref(), retention_policy_attrs(), [record_opt()]) ::
  record_result()
```

### Threadline.Evidence.record_retention_run/3 (function)

```text
Records a retention-run evidence snapshot for `subject_ref` and returns `{:ok, record}` after persistence.

Evidence records are append-only snapshots. The caller supplies the run
status and optional actor, source context, and details.

## Options

- `:repo` — Ecto repository module. Required.
- `:storage_schema` — string storage schema override. Optional.

## Returns

Returns `{:ok, record}` when persisted, `{:error, changeset}` when record
validation fails, `{:error, :missing_repo}` when `:repo` is omitted, or
`{:error, {:invalid_subject_ref, value}}` when `subject_ref` is not a map.
Raises `ArgumentError` for an invalid storage schema.

```

**Specs**

```elixir
record_retention_run(subject_ref(), retention_run_attrs(), [record_opt()]) :: record_result()
```

### Threadline.Evidence.record_support_scope_posture/3 (function)

```text
Records a support-scope evidence snapshot for `subject_ref` and returns `{:ok, record}` after persistence.

Evidence records are append-only snapshots. The caller supplies the scope
status and optional actor, source context, and details.

## Options

- `:repo` — Ecto repository module. Required.
- `:storage_schema` — string storage schema override. Optional.

## Returns

Returns `{:ok, record}` when persisted, `{:error, changeset}` when record
validation fails, `{:error, :missing_repo}` when `:repo` is omitted, or
`{:error, {:invalid_subject_ref, value}}` when `subject_ref` is not a map.
Raises `ArgumentError` for an invalid storage schema.

```

**Specs**

```elixir
record_support_scope_posture(subject_ref(), support_scope_posture_attrs(), [record_opt()]) ::
  record_result()
```

### Threadline.Evidence.record_trigger_coverage/3 (function)

```text
Records a trigger-coverage evidence snapshot for `subject_ref` and returns `{:ok, record}` after persistence.

Evidence records are append-only snapshots. The caller supplies the coverage
status and optional actor, source context, and details.

## Options

- `:repo` — Ecto repository module. Required.
- `:storage_schema` — string storage schema override. Optional.

## Returns

Returns `{:ok, record}` when persisted, `{:error, changeset}` when record
validation fails, `{:error, :missing_repo}` when `:repo` is omitted, or
`{:error, {:invalid_subject_ref, value}}` when `subject_ref` is not a map.
Raises `ArgumentError` for an invalid storage schema.

```

**Specs**

```elixir
record_trigger_coverage(subject_ref(), trigger_coverage_attrs(), [record_opt()]) ::
  record_result()
```

### Threadline.Evidence.invalid_subject_ref/0 (@type)





A non-map value rejected as an Evidence subject reference.



```elixir


invalid_subject_ref() ::
  atom() | bitstring() | number() | tuple() | list() | pid() | port() | reference() | function()


```

### Threadline.Evidence.record_result/0 (@type)





Result returned by an Evidence record writer.



```elixir


record_result() ::
  {:ok, Threadline.Governance.EvidenceRecord.t()}
  | {:error, Ecto.Changeset.t()}
  | {:error, :missing_repo}
  | {:error, {:invalid_subject_ref, invalid_subject_ref()}}


```

### Threadline.Evidence.get_latest_subject_ref_opt/0 (@type)





Options accepted by `get_latest_subject_ref/3`.



```elixir


get_latest_subject_ref_opt() :: record_opt()


```

### Threadline.Evidence.list_overview_opt/0 (@type)





Options accepted by `list_overview/2`.



```elixir


list_overview_opt() :: record_opt()


```

### Threadline.Evidence.list_latest_subject_refs_opt/0 (@type)





Options accepted by `list_latest_subject_refs/3`.



```elixir


list_latest_subject_refs_opt() :: record_opt()


```

### Threadline.Evidence.list_subject_ref_history_opt/0 (@type)





Options accepted by `list_subject_ref_history/4`.



```elixir


list_subject_ref_history_opt() :: record_opt()


```

### Threadline.Evidence.list_history_opt/0 (@type)





Options accepted by `list_history/2`.



```elixir


list_history_opt() :: record_opt()


```

### Threadline.Evidence.latest_filter/0 (@type)





A latest-snapshot filter accepted by latest-read functions.



```elixir


latest_filter() ::
  Threadline.repo_opt() | {:from, DateTime.t()} | {:to, DateTime.t()} | {:limit, pos_integer()}


```

### Threadline.Evidence.subject_ref_history_filter/0 (@type)





A subject-reference history filter accepted by `list_subject_ref_history/4`.



```elixir


subject_ref_history_filter() ::
  Threadline.repo_opt() | {:from, DateTime.t()} | {:to, DateTime.t()} | {:limit, pos_integer()}


```

### Threadline.Evidence.history_filter/0 (@type)





A history filter accepted by `list_history/2`.



```elixir


history_filter() ::
  Threadline.repo_opt()
  | {:subject, Threadline.Evidence.Subject.subject_descriptor()}
  | {:subject_ref, subject_ref()}
  | {:from, DateTime.t()}
  | {:to, DateTime.t()}
  | {:limit, pos_integer()}


```

### Threadline.Evidence.support_scope_posture_attrs/0 (@type)





Caller fields for a support-scope snapshot as a map or keyword list. See `record_attrs/0` for the accepted keys.



```elixir


support_scope_posture_attrs() ::
  record_attrs() | [{redaction_policy_attr_key(), redaction_policy_attr_value()}]


```

### Threadline.Evidence.export_delivery_attrs/0 (@type)





Caller fields for an export-delivery snapshot as a map or keyword list. See `record_attrs/0` for the accepted keys.



```elixir


export_delivery_attrs() ::
  record_attrs() | [{redaction_policy_attr_key(), redaction_policy_attr_value()}]


```

### Threadline.Evidence.retention_policy_attrs/0 (@type)





Caller fields for a retention-policy snapshot as a map or keyword list. See `record_attrs/0` for the accepted keys.



```elixir


retention_policy_attrs() ::
  record_attrs() | [{redaction_policy_attr_key(), redaction_policy_attr_value()}]


```

### Threadline.Evidence.retention_run_attrs/0 (@type)





Caller fields for a retention-run snapshot as a map or keyword list. See `record_attrs/0` for the accepted keys.



```elixir


retention_run_attrs() ::
  record_attrs() | [{redaction_policy_attr_key(), redaction_policy_attr_value()}]


```

### Threadline.Evidence.trigger_coverage_attrs/0 (@type)





Caller fields for a trigger-coverage snapshot as a map or keyword list. See `record_attrs/0` for the accepted keys.



```elixir


trigger_coverage_attrs() ::
  record_attrs() | [{redaction_policy_attr_key(), redaction_policy_attr_value()}]


```

### Threadline.Evidence.redaction_policy_attrs_input/0 (@type)





Redaction-policy attrs as a map or keyword list.



```elixir


redaction_policy_attrs_input() ::
  redaction_policy_attrs() | [{redaction_policy_attr_key(), redaction_policy_attr_value()}]


```

### Threadline.Evidence.redaction_policy_attr_key/0 (@type)





A top-level atom or string key in redaction-policy evidence attrs.



```elixir


redaction_policy_attr_key() :: atom() | String.t()


```

### Threadline.Evidence.record_attrs/0 (@type)





Common caller fields cast by Evidence record changesets: `:summary_status`, `:recorded_at`, `:actor_ref`, `:provenance`, `:detail`, and `:schema_version`. Threadline supplies the subject fields and defaults.



```elixir


record_attrs() :: redaction_policy_attrs()


```

### Threadline.Evidence.redaction_policy_attrs/0 (@type)





Caller fields accepted by the changeset: `:summary_status`, `:recorded_at`, `:actor_ref`, `:provenance`, `:detail`, and `:schema_version`. Threadline supplies `:subject`, `:subject_ref`, and defaults.



```elixir


redaction_policy_attrs() :: %{optional(atom() | String.t()) => redaction_policy_attr_value()}


```

### Threadline.Evidence.redaction_policy_attr_value/0 (@type)





Values accepted for redaction-policy evidence fields cast by the record changeset.



```elixir


redaction_policy_attr_value() ::
  String.t()
  | DateTime.t()
  | NaiveDateTime.t()
  | Threadline.Semantics.ActorRef.t()
  | subject_ref()
  | pos_integer()
  | nil


```

### Threadline.Evidence.record_opt/0 (@type)





Options accepted by Evidence record writers.



```elixir


record_opt() :: Threadline.repo_opt() | Threadline.storage_schema_opt()


```

### Threadline.Evidence.subject_ref/0 (@type)





A subject reference accepted by an Evidence writer. Atom keys and values are normalized to strings.



```elixir


subject_ref() :: %{optional(atom() | String.t()) => subject_ref_value()}


```

### Threadline.Evidence.subject_ref_value/0 (@type)





A subject reference represented with atom or string keys and JSON-compatible values.



```elixir


subject_ref_value() ::
  Threadline.json_value() | atom() | %{optional(atom() | String.t()) => subject_ref_value()}


```

## Threadline.Evidence.Proof

A proof document summarizes evidence snapshots and the claims they support.

### Threadline.Evidence.Proof.proof_document/2 (function)

```text
Builds a JSON-ready proof document from matching evidence snapshots and their claim assessment.

Use `to_json_iodata/2` when the encoded JSON is the desired output. The
request selects an overview or one subject, a latest or history read, and
optional date bounds and limit. Unrecognized request keys are ignored.

## Request

- `:subject` — supported subject name or descriptor. Optional; omission selects the overview.
- `:subject_ref` — subject reference map. Optional.
- `:mode` — `:latest` or `:history`. Optional; defaults to `:latest`.
- `:from` — `DateTime`. Optional; inclusive lower bound on the record time.
- `:to` — `DateTime`. Optional; inclusive upper bound on the record time.
- `:limit` — positive integer. Optional; caps the matching records.

## Options

- `:repo` — Ecto repository module. Required.
- `:generated_at` — `DateTime`. Optional; defaults to the current UTC time.

## Returns

Returns a string-keyed JSON map containing the format version, generation
time, selected subject and mode, filters, record counts, claim assessment,
and matching records. Raises `KeyError` when `:repo` is omitted and
`ArgumentError` for an unsupported subject, invalid subject reference, or
invalid Evidence filter.

```

**Specs**

```elixir
proof_document(proof_request(), [proof_opt()]) :: proof_document()
```

### Threadline.Evidence.Proof.render_human/1 (function)

```text
Prints a JSON-ready proof document in human-readable form through the Mix shell and returns `:ok`.

```

**Specs**

```elixir
render_human(proof_document()) :: :ok
```

### Threadline.Evidence.Proof.render_json/1 (function)

```text
Prints a JSON-ready proof document to standard output and returns `:ok`.

```

**Specs**

```elixir
render_json(proof_document()) :: :ok
```

### Threadline.Evidence.Proof.to_json_iodata/2 (function)

```text
Encodes matching evidence snapshots and their claim assessment as `{:ok, iodata}`.

Use `proof_document/2` when the JSON-ready map is needed instead of encoded
output. The request and options have the same meaning as that function;
unrecognized request keys are ignored.

## Request

- `:subject` — supported subject name or descriptor. Optional; omission selects the overview.
- `:subject_ref` — subject reference map. Optional.
- `:mode` — `:latest` or `:history`. Optional; defaults to `:latest`.
- `:from` — `DateTime`. Optional; inclusive lower bound on the record time.
- `:to` — `DateTime`. Optional; inclusive upper bound on the record time.
- `:limit` — positive integer. Optional; caps the matching records.

## Options

- `:repo` — Ecto repository module. Required.
- `:generated_at` — `DateTime`. Optional; defaults to the current UTC time.

## Returns

Returns `{:ok, iodata()}` containing the encoded proof document. Raises
`KeyError` when `:repo` is omitted and `ArgumentError` for an unsupported
subject, invalid subject reference, or invalid Evidence filter.

```

**Specs**

```elixir
to_json_iodata(proof_request(), [proof_opt()]) :: {:ok, iodata()}
```

### Threadline.Evidence.Proof.presented_record/0 (@type)





A row formatted for the evidence viewer.



```elixir


presented_record() :: %{
  subject: Threadline.json_value(),
  subject_ref: Threadline.json_value(),
  summary_status: Threadline.json_value(),
  recorded_at: String.t() | nil,
  verdict_status: claim_status(),
  verdict_kind: claim_kind(),
  verdict_reason: Threadline.json_value()
}


```

### Threadline.Evidence.Proof.evidence_record_input/0 (@type)





An evidence row supplied to a proof projection.



```elixir


evidence_record_input() :: Threadline.Governance.EvidenceRecord.t() | Threadline.json_map()


```

### Threadline.Evidence.Proof.proof_document/0 (@type)





A JSON-ready proof document with guaranteed keys `format_version`, `generated_at`, `proof_type`, `subject`, `mode`, `filters`, `summary`, `claim_assessment`, and `records`; new JSON keys may be added.



```elixir


proof_document() :: Threadline.json_map()


```

### Threadline.Evidence.Proof.claim_kind/0 (@type)





A proof category string: `direct_fact`, `posture_snapshot`, or `unsupported_claim`.



```elixir


claim_kind() :: String.t()


```

### Threadline.Evidence.Proof.claim_status/0 (@type)





A proof status string: `proven`, `inferred_posture`, or `unsupported`.



```elixir


claim_status() :: String.t()


```

### Threadline.Evidence.Proof.proof_opt/0 (@type)





An option accepted by proof document reads.



```elixir


proof_opt() :: Threadline.repo_opt() | {:generated_at, DateTime.t()}


```

### Threadline.Evidence.Proof.proof_filter/0 (@type)





A filter accepted by a proof read.



```elixir


proof_filter() :: {:from, DateTime.t()} | {:to, DateTime.t()} | {:limit, pos_integer()}


```

### Threadline.Evidence.Proof.proof_mode/0 (@type)





A supported proof read mode.



```elixir


proof_mode() :: :latest | :history


```

### Threadline.Evidence.Proof.proof_request/0 (@type)





A keyword list selecting the evidence included in a proof document.



```elixir


proof_request() :: [proof_request_opt()]


```

### Threadline.Evidence.Proof.proof_request_opt/0 (@type)





A key accepted in a proof request. Unrecognized keys are ignored.



```elixir


proof_request_opt() ::
  {:subject, Threadline.Evidence.Subject.subject_descriptor() | nil}
  | {:subject_ref, Threadline.Evidence.subject_ref() | nil}
  | {:mode, :latest | :history}
  | {:from, DateTime.t()}
  | {:to, DateTime.t()}
  | {:limit, pos_integer()}


```

## Threadline.Evidence.Subject

The closed set of subject names accepted by Threadline evidence records.

### Threadline.Evidence.Subject.supported?/1 (function)

```text
Returns `true` when a subject or subject descriptor is supported, and `false` for every other
input.

```

**Specs**

```elixir
supported?(subject_input()) :: boolean()
```

### Threadline.Evidence.Subject.supported_subjects/0 (function)

```text
Returns the six subject names accepted by Evidence record writers.

```

**Specs**

```elixir
supported_subjects() :: [String.t()]
```

### Threadline.Evidence.Subject.validate/1 (function)

```text
Returns `:ok` for a supported subject or `{:error, {:unsupported_subject, value}}` otherwise.

The unsupported value is the normalized subject for recognized descriptors and the original
input for values that cannot be normalized. The inventory is closed to `supported_subjects/0`.

```

**Specs**

```elixir
validate(subject_input()) :: :ok | {:error, {:unsupported_subject, term()}}
```

### Threadline.Evidence.Subject.subject_input/0 (@type)





Any value accepted by the subject validator and predicate.



```elixir


subject_input() ::
  atom()
  | bitstring()
  | number()
  | %{optional(subject_input()) => subject_input()}
  | tuple()
  | list()
  | pid()
  | port()
  | reference()
  | function()


```

### Threadline.Evidence.Subject.subject_descriptor/0 (@type)





A subject name or descriptor. Recognized keys, in precedence order, are atom `:subject`, atom
`:name`, string `"subject"`, and string `"name"`. Each recognized value may be an atom, string,
or another descriptor, and nested recognized descriptors are normalized recursively. Key
precedence applies at each nested level; unknown-only maps remain unchanged as unsupported
values.

When a recognized key is present, other keys are ignored. If a map has no recognized key, it is
returned unchanged as the unsupported value. The string-key map arm also represents extra keys
and mixed atom/string maps.




```elixir


subject_descriptor() ::
  atom()
  | String.t()
  | %{
      optional(:subject) => atom() | String.t() | subject_descriptor(),
      optional(:name) => atom() | String.t() | subject_descriptor()
    }
  | %{optional(String.t()) => atom() | String.t() | subject_descriptor()}


```

## Threadline.Export

Exports captured row changes as bounded CSV or JSON data and lazy streams.

### Threadline.Export.count_matching/2 (function)

```text
Returns the count of changes matching `filters` without loading row payloads.

Use `to_csv_iodata/2` or `to_json_document/2` to retrieve bounded export
data after checking the match count.

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
- `:cap` — positive integer or `nil`. Optional. Stops counting at this value; `nil` keeps the full count.

Unknown keys raise `ArgumentError` naming the allowed keys.

## Returns

- `{:ok, count_result()}` — a count of matching changes, capped when requested.
- Raises `ArgumentError` for invalid filters or unknown options; repository errors are reraised.

```

**Specs**

```elixir
count_matching([Threadline.timeline_filter()], [count_matching_opt()]) :: {:ok, count_result()}
```

### Threadline.Export.csv_header/1 (function)

```text
Returns the CSV header row as iodata, ending in `\r\n`.

Use `to_csv_iodata/2` when the caller wants a bounded document with its
header included. The header uses the same column order as that function.

## Options

- `:include_action_metadata` — boolean. Defaults to `false`; appends `correlation_id` and `action_id` when true.

Unknown keys raise `ArgumentError` naming the allowed keys.

## Returns

- A list of binary chunks containing one CSV header row.
- Raises `ArgumentError` for unknown options.

```

**Specs**

```elixir
csv_header([csv_header_opt()]) :: [binary()]
```

### Threadline.Export.format_changes_iodata/3 (function)

```text
Returns formatted export-row chunks for a pre-fetched batch and format.

Use `to_csv_iodata/2` or `to_json_document/2` for a complete bounded
document. This function formats rows only; callers add the CSV header or
JSON envelope and separators.

- `:csv` — CSV data rows (each terminated by `\r\n` per RFC 4180); the
  caller MUST emit `csv_header/1` as the first chunk.
- `:json_wrapped` — each row as `Jason.encode!/1` output (a JSON object).
  The caller emits the surrounding `{"format_version": ..., "generated_at":
  ..., "changes": [` prefix and `]}` suffix as separate chunks plus the
  inter-row comma separators.
- `:ndjson` — each row as `Jason.encode!/1` output followed by `\n` (no
  envelope; pure line-delimited JSON).

## Options

- `:include_action_metadata` — boolean. Defaults to `false`; adds action columns in CSV output.

Unknown keys raise `ArgumentError` naming the allowed keys.

## Returns

- A list of binary chunks formatted for the requested export format.
- Raises `ArgumentError` for unknown options.
- Raises `FunctionClauseError` for an unsupported format.

```

**Specs**

```elixir
format_changes_iodata([export_row()], :csv | :json_wrapped | :ndjson, [format_changes_opt()]) :: [
  binary()
]
```

### Threadline.Export.stream_changes/2 (function)

```text
Lazily enumerates matching `AuditChange` records in timeline order using keyset pages.

Use `to_csv_iodata/2` or `to_json_document/2` for bounded output. This stream
does not apply `max_rows`; combine it with `Stream.take/2` when needed.

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
- `:page_size` — positive integer. Defaults to `1000`.

Unknown keys raise `ArgumentError` naming the allowed keys.

## Returns

- A lazy enumerable of `%Threadline.Capture.AuditChange{}` records.
- Raises `ArgumentError` for invalid filters or unknown options; repository errors are reraised when enumerated.

Results contain column values as captured; redaction is applied when triggers
are generated, not on read. Authorize reads with `:scope_query_fn`.

```

**Specs**

```elixir
stream_changes([Threadline.timeline_filter()], [stream_changes_opt()]) :: Enumerable.t()
```

### Threadline.Export.stream_export_rows/2 (function)

```text
Lazily enumerates the join-projected export rows used by the chunked
controller in timeline order using keyset pages.

Each emitted item is a map with the keys `:id`, `:transaction_id`,
`:table_schema`, `:table_name`, `:op`, `:captured_at`, `:table_pk`,
`:data_after`, `:changed_fields`, `:changed_from`, `:tx_occurred_at`,
`:tx_actor_ref`, `:tx_source`, `:aa_id`, `:aa_correlation_id` — exactly the
projection the export query builds. This matches what
`format_changes_iodata/3` expects, so the operator-surface export
controller's chunked path produces byte-identical output to the iodata path.

Use `to_csv_iodata/2` or `to_json_document/2` for bounded output. This stream
does not apply `max_rows`; combine it with `Stream.take/2` when needed.

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
- `:page_size` — positive integer. Defaults to `1000`.

Unknown keys raise `ArgumentError` naming the allowed keys.

## Returns

- A lazy enumerable of join-projected `export_row()` maps.
- Raises `ArgumentError` for invalid filters, missing `:repo`, or unknown options; repository errors are reraised when enumerated.

Results contain column values as captured; redaction is applied when triggers
are generated, not on read. Authorize reads with `:scope_query_fn`.

```

**Specs**

```elixir
stream_export_rows([Threadline.timeline_filter()], [stream_export_rows_opt()]) :: Enumerable.t()
```

### Threadline.Export.to_csv_iodata/2 (function)

```text
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
- `:max_rows` — non-negative integer. Defaults to `10000`.
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

```

**Specs**

```elixir
to_csv_iodata([Threadline.timeline_filter()], [Threadline.export_csv_opt()]) ::
  {:ok, export_result()}
```

### Threadline.Export.to_json_document/2 (function)

```text
Returns JSON iodata and truncation metadata for matching captured changes.

Use `to_csv_iodata/2` when consumers need CSV; both functions use the same
timeline filter vocabulary and bounded row behavior. Use `stream_changes/2`
when the caller needs an uncapped stream of `AuditChange` records.

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
- `:max_rows` — non-negative integer. Defaults to `10000`.
- `:json_format` — `:wrapped` or `:ndjson`. Defaults to `:wrapped`.

Unknown keys raise `ArgumentError` naming the allowed keys.

## Returns

- `{:ok, export_result()}` — wrapped JSON or NDJSON iodata and row-limit metadata.
- Raises `ArgumentError` for invalid filters, missing `:repo`, or unknown options.
- Raises `CaseClauseError` for an unsupported JSON format; repository errors are reraised.

Results contain column values as captured; redaction is applied when triggers
are generated, not on read. Authorize reads with `:scope_query_fn`.

```

**Specs**

```elixir
to_json_document([Threadline.timeline_filter()], [Threadline.export_json_opt()]) ::
  {:ok, export_result()}
```

### Threadline.Export.stream_changes_opt/0 (@type)





An option accepted by `stream_changes/2`.



```elixir


stream_changes_opt() :: Threadline.timeline_opt() | {:page_size, pos_integer()}


```

### Threadline.Export.stream_export_rows_opt/0 (@type)





An option accepted by `stream_export_rows/2`.



```elixir


stream_export_rows_opt() :: Threadline.timeline_opt() | {:page_size, pos_integer()}


```

### Threadline.Export.format_changes_opt/0 (@type)





An option accepted by `format_changes_iodata/3`.



```elixir


format_changes_opt() :: {:include_action_metadata, boolean()}


```

### Threadline.Export.csv_header_opt/0 (@type)





An option accepted by `csv_header/1`.



```elixir


csv_header_opt() :: {:include_action_metadata, boolean()}


```

### Threadline.Export.count_matching_opt/0 (@type)





An option accepted by `count_matching/2`.



```elixir


count_matching_opt() :: Threadline.timeline_opt() | {:cap, pos_integer() | nil}


```

### Threadline.Export.export_row/0 (@type)





The join-projected fields used to encode one captured row in an export stream.



```elixir


export_row() :: %{
  id: Ecto.UUID.t(),
  transaction_id: Ecto.UUID.t(),
  table_schema: String.t(),
  table_name: String.t(),
  op: String.t(),
  captured_at: DateTime.t(),
  table_pk: Threadline.json_map() | nil,
  data_after: Threadline.json_map() | nil,
  changed_fields: [String.t()] | nil,
  changed_from: Threadline.json_map() | nil,
  tx_occurred_at: DateTime.t(),
  tx_actor_ref: Threadline.Semantics.ActorRef.t() | nil,
  tx_source: String.t() | nil,
  aa_id: Ecto.UUID.t() | nil,
  aa_correlation_id: String.t() | nil
}


```

### Threadline.Export.count_result/0 (@type)





The count returned by `count_matching/2`.



```elixir


count_result() :: %{count: non_neg_integer()}


```

### Threadline.Export.export_result/0 (@type)





A bounded CSV or JSON result with encoded data and row-limit metadata.



```elixir


export_result() :: %{
  data: iodata(),
  truncated: boolean(),
  returned_count: non_neg_integer(),
  max_rows: non_neg_integer()
}


```

## Threadline.Export.Orchestrator

Runs asynchronous export jobs by streaming captured rows to temporary files and storage.

### Threadline.Export.Orchestrator.run/2 (function)

```text
Runs an export job and returns `:ok` after storing its CSV, or `{:error, reason}` on failure.

A custom `Threadline.ExportQueue` adapter can call this from its worker to
execute a claimed job. The orchestrator streams projected rows to a temporary
file, persists the file through `Threadline.Storage`, and records the terminal
job state.

## Options

- `:repo` — `Ecto.Repo` module. Defaults to the first configured Threadline repository.
- `:storage_schema` — string. Defaults to the configured Threadline storage schema.
- `:storage_adapter` — storage adapter module. Defaults to the configured adapter.
- `:transaction_fn` — function. Defaults to `repo.transaction/2`; accepts the work function and transaction options.
- `:completion_fn` — function. Defaults to the callback that marks the export job completed.

Other option keys are ignored.

## Returns

- `:ok` — the stored export was recorded as completed.
- `{:error, reason}` — the job could not be claimed, generated, stored, or finalized.

```

**Specs**

```elixir
run(String.t(), [run_opt()]) :: run_result()
```

### Threadline.Export.Orchestrator.run_result/0 (@type)





The result of running an export job; the repository or storage adapter owns the error reason.



```elixir


run_result() :: :ok | {:error, error_reason()}


```

### Threadline.Export.Orchestrator.error_reason/0 (@type)





Any Elixir value returned as an export orchestration error reason.



```elixir


error_reason() ::
  atom()
  | number()
  | bitstring()
  | pid()
  | port()
  | reference()
  | function()
  | tuple()
  | maybe_improper_list(error_reason(), error_reason())
  | %{optional(error_reason()) => error_reason()}


```

### Threadline.Export.Orchestrator.run_opt/0 (@type)





An option accepted by `run/2`.



```elixir


run_opt() ::
  Threadline.repo_opt()
  | Threadline.storage_schema_opt()
  | {:storage_adapter, module()}
  | {:transaction_fn, function()}
  | {:completion_fn, function()}


```

## Threadline.ExportQueue

Enqueues Threadline export jobs for asynchronous processing.

### Threadline.ExportQueue.error_reason/0 (@type)





Any Elixir value returned by an adapter as an error reason; Threadline treats it as opaque.



```elixir


error_reason() ::
  atom()
  | number()
  | bitstring()
  | pid()
  | port()
  | reference()
  | function()
  | tuple()
  | maybe_improper_list(error_reason(), error_reason())
  | %{optional(error_reason()) => error_reason()}


```

### Threadline.ExportQueue.options/0 (@type)





Adapter-defined keyword options that Threadline passes through without interpreting their keys.



```elixir


options() :: Threadline.Storage.options()


```

### Threadline.ExportQueue.job_id/0 (@type)





The identifier of an existing export job passed to the configured queue adapter.



```elixir


job_id() :: String.t() | binary()


```

## Threadline.ExportQueue.Oban

Enqueues Threadline exports in Oban.



## Threadline.ExportQueue.TaskAdapter

Runs export jobs in supervised, in-process tasks.

### Threadline.ExportQueue.TaskAdapter.enqueue/2 (function)

```text
Enqueues an export job by spawning a supervised task and returns `:ok` when accepted.

Use this in-process adapter for single-node work; use the Oban adapter when
jobs must survive process restarts or run across nodes. The task calls
`Threadline.Export.Orchestrator.run/2` with the selected storage schema.

## Options

- `:storage_schema` — string. Defaults to the configured Threadline storage schema.
- `:supervisor` — process or registered supervisor name. Defaults to the application export task supervisor.

Other option keys are ignored.

## Returns

- `:ok` — the supervised task was started.
- `{:error, reason}` — the supervisor rejected the child or is not started.

```

**Specs**

```elixir
enqueue(String.t(), [enqueue_opt()]) :: enqueue_result()
```

### Threadline.ExportQueue.TaskAdapter.enqueue_result/0 (@type)





The result of starting an export task; the task supervisor owns the error reason.



```elixir


enqueue_result() :: :ok | {:error, Threadline.Export.Orchestrator.error_reason()}


```

### Threadline.ExportQueue.TaskAdapter.enqueue_opt/0 (@type)





An option accepted by `enqueue/2`.



```elixir


enqueue_opt() :: Threadline.storage_schema_opt() | {:supervisor, pid() | atom() | tuple()}


```

## Threadline.Governance.EvidenceRecord

An EvidenceRecord is an append-only snapshot of a Threadline subject at a point in time.

### Threadline.Governance.EvidenceRecord.t/0 (@type)





A persisted snapshot of a Threadline subject.



```elixir


t() :: %Threadline.Governance.EvidenceRecord{
  __meta__: Ecto.Schema.Metadata.t(),
  actor_ref: Threadline.Semantics.ActorRef.t() | nil,
  detail: Threadline.json_map() | nil,
  id: Ecto.UUID.t() | nil,
  inserted_at: DateTime.t() | nil,
  provenance: Threadline.json_map() | nil,
  recorded_at: DateTime.t() | nil,
  schema_version: pos_integer() | nil,
  subject: String.t() | nil,
  subject_ref: Threadline.json_map() | nil,
  summary_status: String.t() | nil
}


```

## Threadline.Health

Reports capture health and trigger coverage for Threadline installations.

### Threadline.Health.legacy_key_findings/1 (function)

```text
Returns a list of `Threadline.Health.Finding` structs (`:unresolved_legacy_keys`)
for audit rows captured before their table's trigger was regenerated and
still carrying an unresolved primary key that a key-based row lookup cannot
resolve. Unlike `trigger_findings/1`, which is catalog-only, this scans
`audit_changes` per table.

## Options

- `:repo` — `Ecto.Repo` module. Required.
- `:schema` — schema name string or list of strings. Optional. Omitting it covers every non-system schema.
- `:statement_timeout` — milliseconds. Defaults to `15_000`. Applied with a
  transaction-local setting, so it is safe through PgBouncer transaction
  pooling. When the timeout elapses — typically a missing row-history index —
  this function raises `Postgrex.Error` with postgres code `:query_canceled`;
  see [Step 4](upgrading-to-0.11.md#step-4-add-the-row-history-index).

Each table's probe is capped at 10,000 rows; a capped finding's
`details["unresolved_count"]` is `10000` and its message reads "at least
10000". DELETE rows, rows whose key columns were redacted or are otherwise
absent from `data_after`, and dropped tables are never counted — see
[What cannot be recovered](upgrading-to-0.11.md#what-cannot-be-recovered).
A finding's `details` map has string keys `"unresolved_count"` (integer),
`"capped"` (boolean), and `"key_columns"` (list of strings).

Emits no telemetry event.

Unknown option keys are ignored.

## Example

    Threadline.Health.legacy_key_findings(repo: MyApp.Repo)
    #=> [%Threadline.Health.Finding{code: :unresolved_legacy_keys, ...}]

```

**Specs**

```elixir
legacy_key_findings([legacy_key_findings_opt()]) :: [Threadline.Health.Finding.t()]
```

### Threadline.Health.trigger_coverage/1 (function)

```text
Returns trigger coverage entries for user tables in a schema, defaulting to `"public"`.

Audit tables (`audit_transactions`, `audit_changes`, `audit_actions`) are
excluded from the result — they are not expected to have triggers (CAP-10).

A third tuple variant `{:expected_uncovered, name}` is supported for
bookkeeping tables that are intentionally not audited (e.g. `schema_migrations`).
The bucket is computed from a hardcoded baseline plus
`config :threadline, :health, expected_uncovered_tables: [...]`, with
`:audit_anyway` removing entries from the union.

## Options

- `:repo` — `Ecto.Repo` module. Required.
- `:schema` — schema name string. Defaults to `"public"`. Programmatic
  callers are responsible for sanitizing or trusting their own input —
  this function does NOT validate `:schema` against `pg_namespace`. Surfaces
  that take untrusted input (LV / Mix task) MUST validate at the edge.

A disabled or replica-only trigger no longer counts as covered — see
`trigger_findings/1`, which reports it as `:capture_trigger_disabled`.

Other option keys are ignored.

## Returns

- A list of `coverage_entry()` values in table-name order.
- Raises `KeyError` when `:repo` is missing; repository errors are reraised.

## Example

Threadline.Health.trigger_coverage(repo: MyApp.Repo)
#=> [{:covered, "users"}, {:expected_uncovered, "schema_migrations"}, {:uncovered, "orders"}]

```

**Specs**

```elixir
trigger_coverage([trigger_coverage_opt()]) :: [coverage_entry()]
```

### Threadline.Health.trigger_findings/1 (function)

```text
Returns a list of `Threadline.Health.Finding` structs describing detected
capture problems: disabled or replica-only triggers, duplicate capture
triggers, drifted or missing key columns, and shared per-table functions.

## Options

- `:repo` — `Ecto.Repo` module. Required.
- `:schema` — schema name string or list of strings. Optional.
  Omitting it covers every non-system schema (excludes `pg_catalog`,
  `information_schema`, `pg_toast*`, `pg_temp*`, and the configured
  Threadline storage schema's own tables). This is deliberately different
  from `trigger_coverage/1`'s `"public"` default: two tables with the same
  name in different schemas, and a per-table function shared across
  schemas, cannot be seen one schema at a time. The shared-function check
  always scans the whole catalog regardless of `:schema` — the option only
  filters which findings, by their table's schema, are returned.

A malformed `:trigger_capture` config raises the same `ArgumentError` that
the internal trigger-capture config loader raises for capture itself.

Findings are sorted by `{schema, table, code}`, with message as the final
tie-break, so two consecutive calls return identical lists. One table may
produce more than one finding; there is no short-circuit.

Unknown option keys are ignored.

## Example

    Threadline.Health.trigger_findings(repo: MyApp.Repo)
    #=> [%Threadline.Health.Finding{code: :capture_trigger_disabled, ...}]

```

**Specs**

```elixir
trigger_findings([trigger_findings_opt()]) :: [Threadline.Health.Finding.t()]
```

### Threadline.Health.trigger_coverage_opt/0 (@type)





An option accepted by `trigger_coverage/1`.



```elixir


trigger_coverage_opt() :: Threadline.repo_opt() | {:schema, String.t()}


```

### Threadline.Health.legacy_key_findings_opt/0 (@type)





An option accepted by `legacy_key_findings/1`.



```elixir


legacy_key_findings_opt() ::
  Threadline.repo_opt() | {:schema, schema_filter()} | {:statement_timeout, pos_integer()}


```

### Threadline.Health.trigger_findings_opt/0 (@type)





An option accepted by `trigger_findings/1`.



```elixir


trigger_findings_opt() :: Threadline.repo_opt() | {:schema, schema_filter()}


```

### Threadline.Health.schema_filter/0 (@type)





A schema name or list of schema names used to select health findings.



```elixir


schema_filter() :: String.t() | [String.t()]


```

### Threadline.Health.coverage_entry/0 (@type)





A host table name paired with its trigger coverage status.



```elixir


coverage_entry() :: {coverage_status(), String.t()}


```

### Threadline.Health.coverage_status/0 (@type)





A status assigned to a host table by trigger coverage.



```elixir


coverage_status() :: :covered | :uncovered | :expected_uncovered


```

## Threadline.Health.Finding

A health finding reports a detected capture issue with one host table and an actionable fix.

### Threadline.Health.Finding.t/0 (@type)





A health finding's code, severity, host table, message, and JSON details.



```elixir


t() :: %Threadline.Health.Finding{
  code: code(),
  details: details(),
  message: String.t(),
  schema: String.t(),
  severity: severity(),
  table: String.t()
}


```

### Threadline.Health.Finding.details/0 (@type)





Code-specific JSON-encodable details, with atom or string keys.



```elixir


details() :: %{optional(atom() | String.t()) => Threadline.json_value()}


```

### Threadline.Health.Finding.code/0 (@type)





A finite health-finding code; new codes may be added in a minor release.



```elixir


code() ::
  :legacy_trigger_no_pk_args
  | :pk_drift
  | :shared_capture_function
  | :duplicate_capture_trigger
  | :capture_trigger_disabled
  | :unresolved_legacy_keys


```

### Threadline.Health.Finding.severity/0 (@type)





Whether a health finding blocks or warns about capture health.



```elixir


severity() :: :error | :warning


```

## Threadline.Health.Policy

Validates `:expected_uncovered_tables` and `:audit_anyway` configuration
for `Threadline.Health.trigger_coverage/1`'s third bucket.

### Threadline.Health.Policy.validate!/1 (function)

```text
Returns `:ok` after validating `:expected_uncovered_tables` and `:audit_anyway`
config, or raises `ArgumentError` when the config is invalid.

Accepts a keyword list or a map, matching the dual-form intake used by
capture-time redaction validation.

Raises `ArgumentError` on:
- non-binary entries inside either list
- duplicate entries inside either list
- unknown top-level keys
- non-keyword / non-map input shape

```

**Specs**

```elixir
validate!(config()) :: :ok
```

### Threadline.Health.Policy.config/0 (@type)





The keyword-list or map form accepted by `validate!/1`.



```elixir


config() ::
  [config_opt()]
  | %{
      optional(:expected_uncovered_tables) => [String.t()],
      optional(:audit_anyway) => [String.t()]
    }


```

### Threadline.Health.Policy.config_opt/0 (@type)





A health policy configuration entry containing a list of table names.



```elixir


config_opt() :: {:expected_uncovered_tables, [String.t()]} | {:audit_anyway, [String.t()]}


```

## Threadline.Integrations.Sigra

The Sigra integration derives Threadline audit context from optional Sigra request state.

### Threadline.Integrations.Sigra.actor_fn/0 (function)

```text
Returns the adapter callback in a form suitable for `Threadline.Plug`.

```

**Specs**

```elixir
actor_fn() :: (Plug.Conn.t() -> Threadline.Semantics.ActorRef.t() | nil)
```

### Threadline.Integrations.Sigra.actor_ref_from_conn/1 (function)

```text
Returns an `ActorRef` derived from Sigra request state, or `nil` when the
request does not carry a supported Sigra actor shape.

```

**Specs**

```elixir
actor_ref_from_conn(Plug.Conn.t()) :: Threadline.Semantics.ActorRef.t() | nil
```

### Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1 (function)

```text
Returns additive audit context overrides derived from Sigra request state.

```

**Specs**

```elixir
audit_context_overrides_from_conn(Plug.Conn.t()) :: audit_overrides()
```

### Threadline.Integrations.Sigra.audit_overrides/0 (@type)





Additive audit context values derived from Sigra request state.



```elixir


audit_overrides() :: %{optional(:correlation_id) => String.t()}


```

## Threadline.Investigation.IncidentBundle

An IncidentBundle groups one captured transaction with its linked action and change diffs.

### Threadline.Investigation.IncidentBundle.t/0 (@type)





A captured transaction with its optional action and bundled incident changes.



```elixir


t() :: %Threadline.Investigation.IncidentBundle{
  action: Threadline.Semantics.AuditAction.t() | nil,
  changes: [Threadline.Investigation.IncidentChange.t()],
  transaction: Threadline.Capture.AuditTransaction.t()
}


```

## Threadline.Investigation.IncidentChange

An incident change pairs a linked audit change with its JSON diff for
investigation review.

### Threadline.Investigation.IncidentChange.t/0 (@type)





A linked incident change and its JSON change diff.



```elixir


t() :: %Threadline.Investigation.IncidentChange{
  change_diff: Threadline.json_map(),
  linked_change: Threadline.Investigation.LinkedChange.t()
}


```

## Threadline.Investigation.LinkedChange

A LinkedChange connects one captured row mutation to its transaction and optional action.

### Threadline.Investigation.LinkedChange.t/0 (@type)





A captured row change linked to its transaction and optional semantic action.



```elixir


t() :: %Threadline.Investigation.LinkedChange{
  action: Threadline.Semantics.AuditAction.t() | nil,
  audit_change: Threadline.Capture.AuditChange.t(),
  transaction: Threadline.Capture.AuditTransaction.t()
}


```

## Threadline.Investigation.LinkedTransaction

A linked transaction groups its audit changes and optional action into one
investigation slice.

### Threadline.Investigation.LinkedTransaction.t/0 (@type)





A transaction-centered investigation result with linked changes and optional action.



```elixir


t() :: %Threadline.Investigation.LinkedTransaction{
  action: Threadline.Semantics.AuditAction.t() | nil,
  changes: [Threadline.Investigation.LinkedChange.t()],
  transaction: Threadline.Capture.AuditTransaction.t() | nil
}


```

## Threadline.Job

Carries serialized actor references and stable context keys through background-job argument maps.

### Threadline.Job.actor_ref_from_args/1 (function)

```text
Returns the `ActorRef` serialized in a job argument map.

Looks for an `"actor_ref"` key containing a map serialized by
`ActorRef.to_map/1`.

## Returns

- `{:ok, %ActorRef{}}` — the serialized reference was valid.
- `{:error, :missing_actor_ref | :invalid_actor_ref_map | :unknown_actor_type | :missing_actor_id}` — the arguments do not contain a valid reference.

```

**Specs**

```elixir
actor_ref_from_args(job_args()) :: actor_ref_result()
```

### Threadline.Job.context_opts/2 (function)

```text
Builds `record_action/2` keyword opts from job args.

Extracts `:correlation_id` and `:job_id` from the args map. Pass these opts
(merged with `:actor` and `:repo`) to `Threadline.record_action/2`. Values
supplied in `extra` override the values extracted from `args`.

## Options

- `:repo` — `Ecto.Repo` module. Optional. Passed through to `record_action/2`.
- `:storage_schema` — string. Optional. Passed through to `record_action/2`.
- `:actor` — `ActorRef`. Optional. Passed through to `record_action/2`.
- `:actor_ref` — `ActorRef`. Optional. Passed through to `record_action/2`.
- `:status` — `:ok` or `:error`. Optional. Passed through to `record_action/2`.
- `:verb` — atom or string. Optional. Passed through to `record_action/2`.
- `:category` — atom or string. Optional. Passed through to `record_action/2`.
- `:reason` — atom or string. Optional. Passed through to `record_action/2`.
- `:comment` — string. Optional. Passed through to `record_action/2`.
- `:correlation_id` — string or `nil`. Optional. Read from `args`, then overridden by `extra` when supplied.
- `:request_id` — string. Optional. Passed through to `record_action/2`.
- `:job_id` — string or `nil`. Optional. Read from `args`, then overridden by `extra` when supplied.

Other option keys are retained and validated by `record_action/2` when used.

## Returns

- A keyword list of record-action options.

## Example

    opts = Threadline.Job.context_opts(args)
    Threadline.record_action(:event, [actor: actor_ref, repo: Repo] ++ opts)

```

**Specs**

```elixir
context_opts(job_args(), [context_opt()]) :: context_opts_result()
```

### Threadline.Job.context_opts_result/0 (@type)





The record-action options returned from `context_opts/2`.



```elixir


context_opts_result() :: [context_opt()]


```

### Threadline.Job.context_opt/0 (@type)





An option passed through to `Threadline.record_action/2` or extracted from job arguments.



```elixir


context_opt() ::
  Threadline.record_action_opt()
  | {:correlation_id, String.t() | nil}
  | {:job_id, String.t() | nil}


```

### Threadline.Job.actor_ref_result/0 (@type)





The decoded actor reference or its known decoding failure.



```elixir


actor_ref_result() :: {:ok, Threadline.Semantics.ActorRef.t()} | {:error, actor_ref_error()}


```

### Threadline.Job.actor_ref_error/0 (@type)





A failure returned while decoding an actor reference from job arguments.



```elixir


actor_ref_error() ::
  :missing_actor_ref | :invalid_actor_ref_map | :unknown_actor_type | :missing_actor_id


```

### Threadline.Job.job_args/0 (@type)





A JSON-compatible job argument map with string keys.



```elixir


job_args() :: Threadline.json_map()


```

## Threadline.NotFoundError

`Threadline.NotFoundError` is raised by the `!` sibling of a single-subject
lookup when the subject does not exist or is not visible under the caller's
scope.

### Threadline.NotFoundError.t/0 (@type)





A missing audit transaction identified by its caller-supplied UUID.



```elixir


t() :: %Threadline.NotFoundError{
  __exception__: true,
  id: Ecto.UUID.t(),
  resource: :audit_transaction
}


```

## Threadline.OperatorSurface

Namespace for the Threadline operator surface — the opt-in mountable
LiveView surface that turns Threadline's investigation contracts into
one-click answers for documented support questions.



## Threadline.OperatorSurface.Auth

Uses host authorization callbacks to admit or halt Threadline operator LiveView mounts.

### Threadline.OperatorSurface.Auth.on_mount/4 (function)

```text
Allows or halts an operator LiveView mount using the host authorization callback.

The callback receives the socket-shaped value and may return `:ok`, `true`,
or `{:ok, scope}` to continue. Other results or callback exceptions halt the
mount and redirect to `/`.

## Mount options

- `:authorize_fn` — function. Optional here; the router macro requires a secure pipeline, this callback, or explicit acknowledgement.
- `:scope_query_fn` — function. Optional. Applies host-owned query scoping.
- `:repo` — `Ecto.Repo` module. Optional. Assigned to the LiveView socket.
- `:schemas` — map from host table names to Ecto schema modules. Optional.
- `:theme` — `:dark`, `:light`, or `:system`. Defaults to `:dark`.
- `:exports` — boolean. Defaults to `true`; enables or disables export affordances.
- `:export_authorize_fn` — function. Optional. Applies export-specific authorization.
- `:coverage_authorize_fn` — function. Optional. Defaults to deny access to coverage.
- `:policy_authorize_fn` — function. Optional. Defaults to deny access to policy views.
- `:evidence_authorize_fn` — function. Optional. Defaults to deny access to evidence.

Other mount options are consumed by the router macro or companion hooks.

## Returns

- `{:cont, socket}` — authorization allows the mount.
- `{:halt, socket}` — authorization denies or errors; the socket is redirected.

```

**Specs**

```elixir
on_mount(
  [on_mount_opt()],
  on_mount_params(),
  on_mount_session(),
  Phoenix.LiveView.Socket.t()
) :: {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
```

### Threadline.OperatorSurface.Auth.on_mount_session/0 (@type)





String- or atom-keyed session values passed to an operator LiveView mount.



```elixir


on_mount_session() :: %{optional(String.t() | atom()) => on_mount_session_value()}


```

### Threadline.OperatorSurface.Auth.on_mount_session_value/0 (@type)





An opaque host-defined value carried in the LiveView session.



```elixir


on_mount_session_value() ::
  atom()
  | number()
  | bitstring()
  | pid()
  | port()
  | reference()
  | function()
  | tuple()
  | maybe_improper_list(on_mount_session_value(), on_mount_session_value())
  | %{optional(on_mount_session_value()) => on_mount_session_value()}


```

### Threadline.OperatorSurface.Auth.on_mount_params/0 (@type)





String-keyed route parameters passed to an operator LiveView mount.



```elixir


on_mount_params() :: %{optional(String.t()) => String.t()}


```

### Threadline.OperatorSurface.Auth.on_mount_opt/0 (@type)





An option read by the operator LiveView authorization hook.



```elixir


on_mount_opt() ::
  {:authorize_fn, function()}
  | {:scope_query_fn, function()}
  | Threadline.repo_opt()
  | {:schemas, %{optional(String.t() | atom()) => module()}}
  | {:theme, :dark | :light | :system | String.t()}
  | {:exports, boolean()}
  | {:export_authorize_fn, function()}
  | {:coverage_authorize_fn, function()}
  | {:policy_authorize_fn, function()}
  | {:evidence_authorize_fn, function()}


```

## Threadline.OperatorSurface.Router

Mounts Threadline's operator interface in a Phoenix router with host-owned
authorization and query scoping.

### Threadline.OperatorSurface.Router.threadline_operator_surface/2 (macro)

```text
Adds the Threadline operator LiveView and sibling HTTP routes to the host router.

The macro requires a secure enclosing pipeline, `:authorize_fn`, or an
explicit acknowledgement that the mount is unauthenticated.

## Mount options

- `:exports` — boolean; defaults to `true`. Set to `false` to suppress the
  sibling export-controller scope (rare LV-only adopters).
- `:scope_query_fn` — `(Ecto.Query.t(), scope, %{surface: atom(), params: map()} -> Ecto.Query.t())`; optional. This host-owned query transform is used when `:authorize_fn` returns `{:ok, scope}`. Threadline treats `scope` as opaque data and calls this function for timeline, actor-history, transaction, and export flows.
- `:export_authorize_fn` — `(Plug.Conn.t() -> :ok | true | {:ok, scope} | _)`; defaults to delegating to `:authorize_fn` via a synthetic `%{assigns: conn.assigns}` mirror. Use a separate callback when HTTP authorization needs more than the assigns inspected by the LiveView callback; the synthetic mirror is sufficient when authorization only reads values such as `assigns.current_user`.
- `:coverage_authorize_fn` — `(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)`; optional. Explicitly gates the coverage dashboard and related badge, and defaults to fail closed.
- `:policy_authorize_fn` — `(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)`; optional. Explicitly gates policy and retention surfaces, and defaults to fail closed.
- `:evidence_authorize_fn` — `(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)`; optional. Explicitly gates the mounted evidence surface, and defaults to fail closed.
- `:theme` — `:dark | :light | :system`; defaults to `:dark`. Selects the default server-rendered operator-surface theme lane. `:system` follows the visitor's OS preference through scoped CSS only. A runtime dark/light/system theme picker is available in the shell (session-backed and resolved server-side; a response cookie mirrors the choice); Threadline adds no JavaScript and no local storage.

```

**Specs**

```elixir

```

## Threadline.Page

`Threadline.Page` represents one page of a Threadline paged read.

### Threadline.Page.t/0 (@type)





A `Threadline.Page` of unspecified entry type.



```elixir


t() :: t(term())


```

### Threadline.Page.t/1 (@type)





A `Threadline.Page` whose entries are of type `entry`.



```elixir


t(entry) :: %Threadline.Page{cursor: cursor() | nil, entries: [entry], has_more: boolean()}


```

### Threadline.Page.cursor/0 (@type)





Any cursor a paged Threadline read accepts: a forward change or actor
cursor, or `{:before, actor_cursor()}` to walk an actor history backward
toward newer records.




```elixir


cursor() :: change_cursor() | actor_cursor() | {:before, actor_cursor()}


```

### Threadline.Page.actor_cursor/0 (@type)





A cursor for a paged actor-transaction read (`actor_history/2`).
`occurred_at` is microsecond precision (`utc_datetime_usec`), matching
`AuditTransaction.occurred_at`.




```elixir


actor_cursor() :: %{occurred_at: DateTime.t(), id: Ecto.UUID.t()}


```

### Threadline.Page.change_cursor/0 (@type)





A cursor for a paged change read (`timeline_page/2`, the row-history pagers).
`captured_at` is microsecond precision (`utc_datetime_usec`), matching
`AuditChange.captured_at`.




```elixir


change_cursor() :: %{captured_at: DateTime.t(), id: Ecto.UUID.t()}


```

## Threadline.Plug

Plug that extracts `AuditContext` from a `Plug.Conn` and stores it in
`conn.assigns[:audit_context]`.



## Threadline.Retention

`Threadline.Retention` batches expiry of `AuditChange` rows and optionally
removes empty `AuditTransaction` rows.

### Threadline.Retention.purge/1 (function)

```text
Returns `purge_result()` after deleting expired `AuditChange` rows, or
`{:error, :disabled}` when retention is disabled. Raises `ArgumentError` for
invalid policy or a cutoff newer than the policy cutoff; repository errors
are reraised.

The cutoff comes from `Threadline.Retention.Policy`; an explicit cutoff must
be older than or equal to that policy cutoff.

## Options

- `:repo` — `Ecto.Repo` module. Required.
- `:storage_schema` — string. Optional. Selects the Threadline storage schema.
- `:batch_size` — positive integer. Defaults to `500`; maximum rows per delete pass.
- `:max_batches` — positive integer. Defaults to `10_000`; maximum change batches plus orphan draining.
- `:dry_run` — boolean. Defaults to `false`; when true, no deletes and returns counts of rows that **would**
  match delete predicates (`:deleted_changes` / `:deleted_transactions` are
  those counts, `:batches_run` is `0`). The preview assumes the run completes;
  a run cut short by `:max_batches` deletes fewer. **`:batch_size` and
  `:max_batches` are ignored in dry-run mode** — the preview is a single
  full-table count, not a batched simulation, so passing either alongside
  `dry_run: true` has no effect on the returned counts.
- `:sleep_ms` — non-negative integer. Defaults to `50`; delay between delete batches.
- `:cutoff` — UTC `DateTime`. Optional. Must be at or before the policy cutoff.

Other option keys are ignored.

## Returns

- `purge_result()` — cumulative deletion counts and whether the run was a dry run.
- `{:error, :disabled}` — the retention policy does not have `enabled: true`.
- Raises `ArgumentError` for invalid policy or a cutoff newer than the policy cutoff; repository errors are reraised.

```

**Specs**

```elixir
purge([purge_opt()]) :: purge_result() | {:error, :disabled}
```

### Threadline.Retention.purge_opt/0 (@type)





An option accepted by `purge/1`.



```elixir


purge_opt() ::
  Threadline.repo_opt()
  | Threadline.storage_schema_opt()
  | {:batch_size, pos_integer()}
  | {:max_batches, pos_integer()}
  | {:dry_run, boolean()}
  | {:sleep_ms, non_neg_integer()}
  | {:cutoff, DateTime.t()}


```

### Threadline.Retention.purge_result/0 (@type)





Accumulator returned by `purge/1` on success (counts are cumulative).



```elixir


purge_result() :: %{
  deleted_changes: non_neg_integer(),
  deleted_transactions: non_neg_integer(),
  batches_run: non_neg_integer(),
  dry_run: boolean()
}


```

## Threadline.Retention.Policy

Validates **`config :threadline, :retention`** before purge runs.

### Threadline.Retention.Policy.cutoff_utc_datetime_usec!/1 (function)

```text
Returns UTC `DateTime` strictly **before** which `AuditChange.captured_at` values
are considered expired for purge (i.e. delete rows with `captured_at < cutoff`).

Uses `DateTime.add/3` in microsecond mode for consistency with `:utc_datetime_usec`.

## Options

- `:policy` — normalized retention policy. Optional. Defaults to the configured policy.

## Returns

- The UTC cutoff timestamp.

Other option keys are ignored.

```

**Specs**

```elixir
cutoff_utc_datetime_usec!([cutoff_opt()]) :: DateTime.t()
```

### Threadline.Retention.Policy.resolve!/1 (function)

```text
Resolves config into a struct or raises like `validate_config!/1`.

```

**Specs**

```elixir
resolve!(config()) :: t()
```

### Threadline.Retention.Policy.validate_config!/1 (function)

```text
Returns `:ok` when retention config from `Application.get_env(:threadline, :retention)` is valid.

Raises `ArgumentError` with a message containing `"retention"` when either boolean option is
not a boolean or its string spelling, when both window keys are set, or when a window is
non-positive or missing outside the test environment.

In `:test`, missing `:keep_days` / `:max_age_seconds` is allowed only when the
caller passes a non-empty map/list that still fails other checks — for empty
config in test, hosts should set explicit values in `config/test.exs`.

```

**Specs**

```elixir
validate_config!(config()) :: :ok
```

### Threadline.Retention.Policy.cutoff_opt/0 (@type)





An option accepted by `cutoff_utc_datetime_usec!/1`.



```elixir


cutoff_opt() :: {:policy, t()}


```

### Threadline.Retention.Policy.config/0 (@type)





The keyword-list or map form accepted by retention policy validation and resolution.



```elixir


config() :: [config_opt()] | config_map()


```

### Threadline.Retention.Policy.config_map/0 (@type)





A retention config map. Recognized keys are atom or string spellings of `:enabled`,
`:delete_empty_transactions`, `:keep_days`, and `:max_age_seconds`. The boolean keys accept
booleans or the strings `"true"` and `"false"`; window values accept positive integers.
Other keys are ignored, and the string-key map arm represents extra keys and mixed atom/string
maps.

For boolean keys, a present atom key wins over its string spelling even when its value is
invalid. For window keys, `atom_value || string_value` is used, so atom nil or false falls back
to the matching string key while 0 or another truthy invalid atom value keeps its validation
error. Positive window values remain mutually exclusive; when both are absent, the test
environment uses a one-day default.




```elixir


config_map() ::
  %{
    optional(:enabled) => boolean() | String.t(),
    optional(:delete_empty_transactions) => boolean() | String.t(),
    optional(:keep_days) => pos_integer() | nil | false,
    optional(:max_age_seconds) => pos_integer() | nil | false
  }
  | %{optional(String.t()) => boolean() | String.t() | pos_integer()}


```

### Threadline.Retention.Policy.config_opt/0 (@type)





An atom-keyed option in the retention policy configuration.



```elixir


config_opt() ::
  {:enabled, boolean() | String.t()}
  | {:delete_empty_transactions, boolean() | String.t()}
  | {:keep_days, pos_integer() | nil | false}
  | {:max_age_seconds, pos_integer() | nil | false}


```

### Threadline.Retention.Policy.t/0 (@type)





Normalized retention options as returned by `resolve/1`.



```elixir


t() :: %Threadline.Retention.Policy{
  delete_empty_transactions: boolean(),
  enabled: boolean(),
  window_seconds: pos_integer()
}


```

## Threadline.Semantics.ActorRef

An actor reference identifies who performed an audited operation, including when the actor is not a user.

### Threadline.Semantics.ActorRef.from_map/1 (function)

```text
Returns an ActorRef decoded from a string-keyed JSON object.

Accepts any input so callers can validate decoded JSON. An anonymous object has no `"id"` key;
its `"id"` value is ignored if present. Every other supported type requires a non-empty string
identifier.

Decoding recognizes only string `"type"` and `"id"` keys and ignores additional string or atom
keys. The recognized string keys take precedence over atom keys in mixed maps. An atom-only
`:type` key is not recognized and returns `{:error, :invalid_actor_ref_map}`. `to_map/1` emits
only `"type"` and, for non-anonymous actors, `"id"`.

Returns `{:ok, actor_ref}` or `{:error, reason}` for `:invalid_actor_ref_map`,
`:unknown_actor_type`, or `:missing_actor_id`.

```

**Specs**

```elixir
from_map(term()) ::
  {:ok, t()} | {:error, :invalid_actor_ref_map | :unknown_actor_type | :missing_actor_id}
```

### Threadline.Semantics.ActorRef.identifiable?/1 (function)

```text
Returns whether an actor has a stable identity suitable for resource ownership.
```

**Specs**

```elixir
identifiable?(term()) :: boolean()
```

### Threadline.Semantics.ActorRef.new/2 (function)

```text
Returns a validated ActorRef for a supported actor type and identifier.

The anonymous type discards its identifier. Other types require a non-empty string identifier.

Returns `{:ok, actor_ref}` or `{:error, reason}` where the reason is `:unknown_actor_type` for an
unsupported type or `:missing_actor_id` for a missing or empty identifier.

```

**Specs**

```elixir
new(actor_type_input(), String.t() | nil) ::
  {:ok, t()} | {:error, :unknown_actor_type | :missing_actor_id}
```

### Threadline.Semantics.ActorRef.to_map/1 (function)

```text
Returns the string-keyed JSON object used to store an ActorRef.

It always emits the string `"type"` key and no extra keys. Anonymous actors omit `"id"`; other
actor types include it. Validated non-anonymous refs have a non-empty string id, while a directly
constructed non-anonymous struct with a nil id emits `"id" => nil`.

```

**Specs**

```elixir
to_map(t()) :: actor_map()
```

### Threadline.Semantics.ActorRef.actor_map/0 (@type)





A string-keyed map emitted by `to_map/1`. It always contains `"type"`; non-anonymous refs
also contain `"id"`, and no other keys are emitted.

`from_map/1` recognizes only string `"type"` and `"id"` keys. It ignores additional string or
atom keys, and recognized string keys take precedence in mixed maps. An atom-only type key is
not recognized and returns `{:error, :invalid_actor_ref_map}`. Anonymous refs ignore `"id"`.
`new/2` and `from_map/1` produce validated refs with nil id only for anonymous refs, but a
directly constructed non-anonymous `%ActorRef{}` with nil id emits `"id" => nil`.




```elixir


actor_map() :: %{required(String.t()) => String.t() | nil}


```

### Threadline.Semantics.ActorRef.t/0 (@type)





A stable actor reference with a supported type and an optional string identifier.



```elixir


t() :: %Threadline.Semantics.ActorRef{id: String.t() | nil, type: actor_type()}


```

### Threadline.Semantics.ActorRef.actor_type_input/0 (@type)





Any value accepted by `new/2`; unsupported values return `:unknown_actor_type`.



```elixir


actor_type_input() ::
  atom()
  | bitstring()
  | number()
  | %{optional(actor_type_input()) => actor_type_input()}
  | tuple()
  | list()
  | pid()
  | port()
  | reference()
  | function()


```

### Threadline.Semantics.ActorRef.actor_type/0 (@type)





One of the actor categories accepted by `new/2`.



```elixir


actor_type() :: :anonymous | :system | :job | :service_account | :admin | :user


```

## Threadline.Semantics.AuditAction

An `AuditAction` is an application-level event that records who did what and why.

### Threadline.Semantics.AuditAction.t/0 (@type)





A persisted semantic action linked to one or more captured database transactions.



```elixir


t() :: %Threadline.Semantics.AuditAction{
  __meta__: Ecto.Schema.Metadata.t(),
  actor_ref: Threadline.Semantics.ActorRef.t(),
  category: String.t() | nil,
  comment: String.t() | nil,
  correlation_id: String.t() | nil,
  id: Ecto.UUID.t() | nil,
  inserted_at: DateTime.t() | nil,
  job_id: String.t() | nil,
  name: String.t(),
  reason: String.t() | nil,
  request_id: String.t() | nil,
  status: :ok | :error,
  verb: String.t() | nil
}


```

## Threadline.Semantics.AuditContext

An `AuditContext` carries request or job details into a semantic audit action.

### Threadline.Semantics.AuditContext.t/0 (@type)





Request or job context attached to a semantic audit action.



```elixir


t() :: %Threadline.Semantics.AuditContext{
  actor_ref: Threadline.Semantics.ActorRef.t() | nil,
  correlation_id: String.t() | nil,
  remote_ip: String.t() | nil,
  request_id: String.t() | nil
}


```

## Threadline.Storage

Stores and retrieves export files and other persistent artifacts.

### Threadline.Storage.error_reason/0 (@type)





Any Elixir value returned by an adapter as an error reason; Threadline treats it as opaque.



```elixir


error_reason() ::
  atom()
  | number()
  | bitstring()
  | pid()
  | port()
  | reference()
  | function()
  | tuple()
  | maybe_improper_list(error_reason(), error_reason())
  | %{optional(error_reason()) => error_reason()}


```

### Threadline.Storage.options/0 (@type)





Adapter-defined keyword options that Threadline passes through without interpreting their keys.



```elixir


options() :: keyword()


```

### Threadline.Storage.content/0 (@type)





Binary content passed to or returned from a storage adapter.



```elixir


content() :: binary()


```

### Threadline.Storage.file_id/0 (@type)





An opaque identifier returned by a storage adapter for a stored file.



```elixir


file_id() :: String.t()


```

## Threadline.Storage.Local

Stores Threadline exports on the local filesystem.



## Threadline.Storage.S3

Stores Threadline exports in S3-compatible object storage.



## Threadline.StorageSchema

Resolves storage schema names and builds validated SQL references to Threadline-owned tables.

### Threadline.StorageSchema.get/1 (function)

```text
Returns the configured storage schema, defaulting to the host's `public` schema.

A dedicated schema is opted into with
`config :threadline, storage_schema: "threadline"`, or per-call via the
`:storage_schema` option.

## Options

- `:storage_schema` — string. Optional. Overrides the application setting.

## Returns

- The validated storage schema name.
- Raises `ArgumentError` when the configured name is invalid.

Other option keys are ignored.

```

**Specs**

```elixir
get([Threadline.storage_schema_opt()]) :: String.t()
```

### Threadline.StorageSchema.repo_opts/1 (function)

```text
Returns Ecto repository options that target Threadline-owned storage.

## Options

- `:storage_schema` — string. Optional. Selects the configured storage schema.

## Returns

- A `:prefix` option containing the validated Threadline storage schema.
- Raises `ArgumentError` when the selected storage schema is invalid.

Other option keys are ignored.

```

**Specs**

```elixir
repo_opts([Threadline.storage_schema_opt()]) :: repo_opts_result()
```

### Threadline.StorageSchema.table/2 (function)

```text
Returns a schema-qualified SQL name for one of Threadline's storage tables.

The accepted names are `audit_transactions`, `audit_changes`,
`audit_actions`, `threadline_export_jobs`, `threadline_retention_runs`,
`threadline_saved_views`, and `threadline_evidence_records`.

## Options

- `:storage_schema` — string. Optional. Selects the configured storage schema.

## Returns

- The quoted, schema-qualified table name.
- Raises `FunctionClauseError` when `name` is not one of the Threadline tables.
- Raises `ArgumentError` when the selected storage schema is invalid.

Other option keys are ignored.

```

**Specs**

```elixir
table(String.t(), [Threadline.storage_schema_opt()]) :: String.t()
```

### Threadline.StorageSchema.threadline_table?/1 (function)

```text
Returns whether a valid host table identifier names one of Threadline's storage tables; raises `ArgumentError` for malformed identifiers.
```

**Specs**

```elixir
threadline_table?(String.t()) :: boolean()
```

### Threadline.StorageSchema.validate!/1 (function)

```text
Validates a PostgreSQL identifier and returns its trimmed name; raises `ArgumentError` for an invalid identifier.
```

**Specs**

```elixir
validate!(identifier_input()) :: String.t()
```

### Threadline.StorageSchema.role/0 (@type)





Selects the identifier-validation context: `:storage_schema` (storage schema), `:host_schema` (host schema), `:host_table` (host table), `:derived` (derived identifier), or `:primary_key_column` (primary key column).



```elixir


role() :: :storage_schema | :host_schema | :host_table | :derived | :primary_key_column


```

### Threadline.StorageSchema.repo_opts_result/0 (@type)





Repository options targeting the Threadline storage schema.



```elixir


repo_opts_result() :: [{:prefix, String.t()}]


```

### Threadline.StorageSchema.parsed_table_identifier/0 (@type)





A parsed host table identifier with validated schema and table names.



```elixir


parsed_table_identifier() :: %{schema: String.t(), table: String.t()}


```

### Threadline.StorageSchema.identifier_input/0 (@type)





An identifier accepted for schema validation; booleans and malformed names raise.



```elixir


identifier_input() :: String.t() | atom()


```

## Threadline.Telemetry

`Threadline.Telemetry` defines Threadline's emitted event contract and lets
hosts record accurate transaction table counts.

### Threadline.Telemetry.transaction_committed/2 (function)

```text
Emits `[:threadline, :transaction, :committed]` with the given table count.

Call this after a DB transaction that you know produced `AuditTransaction`
records, when you need accurate `table_count` measurements.

## Options

- `:table_count` — integer. Defaults to `0`; reports the number of audited tables in the transaction.

Other option keys are ignored.

## Returns

- `:ok` after the telemetry event is emitted.

## Example

    {:ok, txn} = MyApp.Repo.transaction(fn ->
      # ... your writes ...
    end)
    Threadline.Telemetry.transaction_committed(txn, table_count: 3)

```

**Specs**

```elixir
transaction_committed(transaction_value(), [transaction_committed_opt()]) :: :ok
```

### Threadline.Telemetry.transaction_value/0 (@type)





An opaque host transaction result passed to `transaction_committed/2`.



```elixir


transaction_value() ::
  atom()
  | number()
  | bitstring()
  | pid()
  | port()
  | reference()
  | function()
  | tuple()
  | maybe_improper_list(transaction_value(), transaction_value())
  | %{optional(transaction_value()) => transaction_value()}


```

### Threadline.Telemetry.transaction_committed_opt/0 (@type)





An option accepted by `transaction_committed/2`.



```elixir


transaction_committed_opt() :: {:table_count, integer()}


```

## Threadline.Verify.CoveragePolicy

Compares health coverage entries with the host's expected audited tables.

### Threadline.Verify.CoveragePolicy.partition_findings/2 (function)

```text
Partitions `Threadline.Health.Finding` structs into gated, not-gated and
warning buckets, given the host's expected-table positive list.

- `:gated` — `:error` findings whose `table` is in `expected_tables`. These
  are the findings a CI gate must fail on.
- `:not_gated` — `:error` findings whose `table` is not in `expected_tables`.
  Printed for visibility; never fails the task.
- `:warnings` — every `:warning` finding, regardless of table.

Each bucket keeps the input list's order. Pure; does not read the database
or call `Mix.raise`.

```

**Specs**

```elixir
partition_findings([Threadline.Health.Finding.t()], [String.t()]) :: partitioned_findings()
```

### Threadline.Verify.CoveragePolicy.summary_counts/2 (function)

```text
Returns counts of unique expected tables, tables without violations, and violations.

## Returns

- A `summary_result()` with the expected, covered, and violated counts.

```

**Specs**

```elixir
summary_counts([coverage_entry()], [String.t()]) :: summary_result()
```

### Threadline.Verify.CoveragePolicy.violations/2 (function)

```text
Returns a sorted list of violations for tables the host expects to be covered.

`coverage` contains entries from `Threadline.Health.trigger_coverage/1`.
`expected_tables` is a list of table-name strings; duplicates are ignored.

## Returns

- A sorted list of `violation()` values. Missing and uncovered tables are included.

```

**Specs**

```elixir
violations([coverage_entry()], [String.t()]) :: [violation()]
```

### Threadline.Verify.CoveragePolicy.partitioned_findings/0 (@type)





Findings divided into gated errors, other errors, and warnings.



```elixir


partitioned_findings() :: %{
  gated: [Threadline.Health.Finding.t()],
  not_gated: [Threadline.Health.Finding.t()],
  warnings: [Threadline.Health.Finding.t()]
}


```

### Threadline.Verify.CoveragePolicy.summary_result/0 (@type)





Counts of expected, covered, and violated table names.



```elixir


summary_result() :: %{
  expected: non_neg_integer(),
  covered: non_neg_integer(),
  violated: non_neg_integer()
}


```

### Threadline.Verify.CoveragePolicy.violation/0 (@type)





A violation kind and the expected table name that caused it.



```elixir


violation() :: {:missing | :uncovered, String.t()}


```

### Threadline.Verify.CoveragePolicy.coverage_entry/0 (@type)





A coverage entry accepted from `Threadline.Health.trigger_coverage/1`.



```elixir


coverage_entry() :: Threadline.Health.coverage_entry()


```

## Hidden entries and reasons

- `Mix.Tasks.Threadline.Health.Coverage.legacy_findings_or_hint/2` — Builds the internal fallback when a coverage report is empty.
- `Threadline.Capture.AuditChange.changeset/2` — Validates an internal captured-row persistence record.
- `Threadline.Capture.AuditTransaction.changeset/2` — Validates an internal transaction persistence record.
- `Threadline.Evidence.Proof.present_record/1` — newly hidden for 1.0: renders an evidence record for the operator surface.
- `Threadline.Evidence.Proof.record_claim_assessment/1` — newly hidden for 1.0: builds a claim assessment for the operator surface.
- `Threadline.Governance.EvidenceRecord.changeset/2` — Validates an internal evidence persistence record.
- `Threadline.Health.classify/3` — Classifies captured tables for the internal health report.
- `Threadline.Health.coverage_by_schema/1` — Groups internal coverage rows by storage schema.
- `Threadline.Semantics.AuditAction.changeset/2` — Validates an internal action persistence record.
- `Threadline.Storage.S3.delete/2` — Deletes an object through the internal S3 adapter contract.
- `Threadline.Storage.S3.get/2` — Reads an object through the internal S3 adapter contract.
- `Threadline.StorageSchema.function/2` — newly hidden for 1.0: builds an internal storage function name.
- `Threadline.StorageSchema.host_table_suffix/1` — newly hidden for 1.0: derives the internal host-table suffix.
- `Threadline.StorageSchema.parse_table_identifier/1` — newly hidden for 1.0: parses a table identifier for internal SQL.
- `Threadline.StorageSchema.qualified_host_table/1` — newly hidden for 1.0: resolves a host table to a qualified identifier.
- `Threadline.StorageSchema.qualify/2` — newly hidden for 1.0: qualifies an identifier with its storage schema.
- `Threadline.StorageSchema.quote_ident/1` — newly hidden for 1.0: quotes an identifier for internal generated SQL.
- `Threadline.StorageSchema.validate_identifier!/3` — Validates identifiers for internal schema-owned SQL statements.
- `Threadline.Telemetry.emit_action_recorded/1` — Emits the internal action-recorded event.
- `Threadline.Telemetry.emit_actor_ref_mismatch/0` — Emits the internal actor-reference mismatch event.
- `Threadline.Telemetry.emit_batch_purged/3` — Emits the internal retention batch event.
- `Threadline.Telemetry.emit_export_authorize_error/0` — Emits the internal export authorization error event.
- `Threadline.Telemetry.emit_export_completed/4` — Emits the internal export completion event.
- `Threadline.Telemetry.emit_export_failed/5` — Emits the internal export failure event.
- `Threadline.Telemetry.emit_findings_checked/2` — Emits the internal health findings event.
- `Threadline.Telemetry.emit_health_checked/3` — Emits the internal coverage check event.
- `Threadline.Telemetry.emit_health_checked_error/1` — Emits the internal coverage check error event.
- `Threadline.Telemetry.emit_operator_surface_authorize/3` — Emits the internal operator authorization event.
- `Threadline.Telemetry.emit_row_history_truncated/2` — Emits the internal row-history truncation event.
- `Threadline.Telemetry.emit_transaction_committed_proxy/0` — Emits the internal transaction-committed proxy event.
- `Threadline.Telemetry.purge_span/2` — Measures an internal retention purge span.

## Permanent broad-type allowances and rules

- `Threadline type scope_opt/0` — R1: the caller's scope value is opaque to Threadline
- `Threadline type scope_query_fn/0` — R1: the callback receives an opaque scope and open surface-specific context params
- `Threadline.Audit spec transaction/3` — R1: callback results and caller-owned rollback reasons remain opaque
- `Threadline.Evidence.Subject spec validate/1` — R2: validator accepts arbitrary input and includes the unsupported value in its error
- `Threadline.Page type t/0` — R1: the producer chooses the page entry type; callers should prefer t(entry)
- `Threadline.Semantics.ActorRef spec from_map/1` — R2: validator accepts arbitrary input and reports when it is not an ActorRef JSON map
- `Threadline.Semantics.ActorRef spec identifiable?/1` — R2: predicate accepts arbitrary input and reports whether it identifies an actor
- `Threadline.Storage type options/0` — R4: storage options are defined by the adapter contract

