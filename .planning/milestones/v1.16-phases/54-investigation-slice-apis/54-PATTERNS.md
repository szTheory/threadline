# Phase 54: Investigation Slice APIs - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 5 likely targets
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline.ex` | utility | request-response | `lib/threadline.ex` | exact |
| `lib/threadline/query.ex` | service | CRUD | `lib/threadline/query.ex` | exact |
| `lib/threadline/investigation.ex` or `lib/threadline/investigation/*.ex` | service | request-response | `lib/threadline/export.ex` | role-match |
| `lib/threadline/investigation/*.ex` result structs | model | transform | `lib/threadline/query.ex` (`TimelinePage`), `lib/threadline/semantics/actor_ref.ex` | role-match |
| `test/threadline/investigation_test.exs` or `test/threadline/query_test.exs` additions | test | request-response | `test/threadline/query_test.exs`, `test/threadline/export_test.exs` | exact |

## Pattern Assignments

### `lib/threadline.ex` (public API surface, request-response)

**Analog:** `lib/threadline.ex`

**Public delegator pattern** ([lib/threadline.ex](/Users/jon/projects/threadline/lib/threadline.ex:97))
```elixir
@doc """
Returns `AuditChange` records across tables, filtered by the given options,
ordered by `captured_at` descending, then `id` descending
"""
def timeline(filters \\ [], opts \\ []), do: Threadline.Query.timeline(filters, opts)

@doc """
Returns one explicit keyset page of timeline results without changing `timeline/2`.
"""
def timeline_page(filters \\ [], opts \\ []), do: Threadline.Query.timeline_page(filters, opts)
```

**Reuse for Phase 54**
- Add new top-level helpers here first; Phase 54 context is explicit that adopters should discover them on `Threadline`, not through controller-only composition or `Threadline.Query` internals.
- Keep docs short and contract-focused like `history/3`, `timeline/2`, and `audit_changes_for_transaction/2`; defer broad story cleanup to Phase 56.

### `lib/threadline/query.ex` (query composition, CRUD)

**Analog:** `lib/threadline/query.ex`

**Strict validation + repo resolution** ([lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:54))
```elixir
def validate_timeline_filters!(filters) when is_list(filters) do
  for {key, value} <- filters do
    cond do
      key not in @allowed_timeline_filter_keys ->
        raise ArgumentError, "unknown timeline filter key ..."
      key == :correlation_id ->
        validate_correlation_id_filter!(value)
      true ->
        :ok
    end
  end

  :ok
end

def timeline_repo!(filters \\ [], opts \\ []) when is_list(filters) and is_list(opts) do
  case Keyword.get(opts, :repo) || Keyword.get(filters, :repo) do
    nil -> raise ArgumentError, "missing :repo for timeline/export ..."
    repo when is_atom(repo) -> repo
    other -> raise ArgumentError, "timeline/export :repo must be an Ecto.Repo module ..."
  end
end
```

**Shared query-stack pattern** ([lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:135))
```elixir
def timeline_query(filters) when is_list(filters) do
  filters
  |> timeline_base_query()
  |> filter_by_correlation(filters)
  |> timeline_order()
end
```

**Existing low-level investigation primitives** ([lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:257), [lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:329), [lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:369), [lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:423))
```elixir
def history(schema_module, id, opts) do
  ...
  |> where([ac], ac.table_name == ^table)
  |> where([ac], fragment("? @> ?::jsonb", ac.table_pk, ^pk_map))
  |> order_by([ac], desc: ac.captured_at)
  |> repo.all()
end

def actor_history(%ActorRef{} = actor_ref, opts) do
  ...
  |> where([at], fragment("? @> ?::jsonb", at.actor_ref, ^actor_map))
  |> order_by([at], desc: at.occurred_at)
  |> repo.all()
end

def audit_changes_for_transaction(transaction_id, opts) do
  ...
  |> where([ac], ac.transaction_id == ^uuid)
  |> timeline_order()
  |> repo.all()
end
```

**Reuse for Phase 54**
- Compose new helpers from these primitives instead of replacing them.
- Preserve strict `:correlation_id` inner-join semantics and `(captured_at DESC, id DESC)` ordering everywhere change rows are returned.
- If helper shapes need linked transaction/action context, copy the join/select posture from `export_changes_query/1` rather than inventing a second join vocabulary.

### `lib/threadline/investigation.ex` or `lib/threadline/investigation/*.ex` (new helper layer)

**Analog:** `lib/threadline/export.ex`

**Packaging pattern above Query** ([lib/threadline/export.ex](/Users/jon/projects/threadline/lib/threadline/export.ex:70), [lib/threadline/export.ex](/Users/jon/projects/threadline/lib/threadline/export.ex:146), [lib/threadline/export.ex](/Users/jon/projects/threadline/lib/threadline/export.ex:184))
```elixir
def to_csv_iodata(filters, opts \\ []) when is_list(filters) and is_list(opts) do
  Query.validate_timeline_filters!(filters)
  repo = Query.timeline_repo!(filters, opts)
  ...
  rows = repo.all(Query.export_changes_query(filters) |> limit(^limit))
  ...
end

def count_matching(filters, opts \\ []) when is_list(filters) and is_list(opts) do
  Query.validate_timeline_filters!(filters)
  repo = Query.timeline_repo!(filters, opts)
  ...
end

def stream_changes(filters, opts \\ []) when is_list(filters) and is_list(opts) do
  Query.validate_timeline_filters!(filters)
  Stream.resource(...)
end
```

**Reuse for Phase 54**
- Put helper orchestration in a dedicated library module if the top-level `Threadline` should stay thin.
- Follow Export’s shape: validate once, resolve repo once, delegate to Query/shared primitives, then package explicit return structs/maps.
- Good fit for eager and paged companion APIs: one eager helper returning a bundle, one paged helper wrapping `timeline_page/2`.

### `lib/threadline/investigation/*.ex` result structs (new wrapper structs, transform)

**Analogs:** `Threadline.Query.TimelinePage`, `Threadline.Semantics.ActorRef`

**Minimal struct pattern** ([lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:39), [lib/threadline/semantics/actor_ref.ex](/Users/jon/projects/threadline/lib/threadline/semantics/actor_ref.ex:21))
```elixir
@enforce_keys [:entries]
defstruct [:entries, :next_cursor]

@enforce_keys [:type]
defstruct [:type, :id]
```

**Reuse for Phase 54**
- Keep wrapper structs explicit and small: enforce only the fields callers must rely on.
- Favor durable names like `changes`, `transactions`, `action`, `next_cursor`, `filters` over opaque tuples.
- If a helper packages linked semantics, make transaction/action/change context explicit in the struct shape so Phase 55 can build incident bundles without another rewrite.

### `test/threadline/investigation_test.exs` or `test/threadline/query_test.exs` additions (focused behavior tests)

**Analogs:** `test/threadline/query_test.exs`, `test/threadline/export_test.exs`

**Fixture and helper style** ([test/threadline/query_test.exs](/Users/jon/projects/threadline/test/threadline/query_test.exs:11))
```elixir
defp insert_transaction(attrs \\ %{}) do
  defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}
  @repo.insert!(AuditTransaction.changeset(Map.merge(defaults, attrs)))
end

defp insert_change(transaction, attrs \\ %{}) do
  defaults = %{table_schema: "public", table_name: "users", ...}
  @repo.insert!(AuditChange.changeset(Map.merge(defaults, Map.new(attrs))))
end
```

**Delegation/parity testing** ([test/threadline/query_test.exs](/Users/jon/projects/threadline/test/threadline/query_test.exs:300), [test/threadline/query_test.exs](/Users/jon/projects/threadline/test/threadline/query_test.exs:510), [test/threadline/export_test.exs](/Users/jon/projects/threadline/test/threadline/export_test.exs:220))
```elixir
q = Threadline.Query.audit_changes_for_transaction(txn.id, repo: @repo)
t = Threadline.audit_changes_for_transaction(txn.id, repo: @repo)
assert q == t

public_page = Threadline.timeline_page(filters, page_size: 2)
query_page = Threadline.Query.timeline_page(filters, page_size: 2)
assert public_page == query_page

timeline_ids =
  filters
  |> Threadline.timeline(opts)
  |> Enum.map(& &1.id)
  |> Enum.sort()
```

**Reuse for Phase 54**
- Prefer narrow behavior tests over snapshots: delegation, ordering, linkage, strict filters, and parity between eager vs paged helper variants.
- Copy the export parity style when proving helper bundles still match underlying change IDs.
- Keep tests at the operator-question level: one row history helper, one actor-window helper, one correlation helper, one transaction-oriented helper shell.

## Shared Patterns

### Ordering
**Source:** [lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:236)
```elixir
defp timeline_order(query) do
  query
  |> order_by([ac], desc: ac.captured_at)
  |> order_by([ac], desc: ac.id)
end
```
Apply to all helpers that traverse `AuditChange` rows.

### Strict correlation linkage
**Source:** [lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:147)
```elixir
Validates filters, then builds the same predicate stack as `timeline/2`, adds an
optional `LEFT JOIN` to `audit_actions` when `:correlation_id` is absent ...
```
Apply when helper results need action context: no best-effort orphan inclusion when `:correlation_id` is present.

### JSON-ready per-change projection
**Sources:** [lib/threadline/change_diff.ex](/Users/jon/projects/threadline/lib/threadline/change_diff.ex:68), [test/threadline/change_diff_test.exs](/Users/jon/projects/threadline/test/threadline/change_diff_test.exs:204)
```elixir
defdelegate change_diff(audit_change, opts \\ []),
  to: Threadline.ChangeDiff,
  as: :from_audit_change
```
Use `Threadline.change_diff/2` when a helper needs deterministic field-level projections; do not duplicate diff logic in the new slice APIs.

### Real host composition pressure
**Sources:** [examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex:11), [examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs:21)
```elixir
changes = Threadline.audit_changes_for_transaction(uuid, repo: Repo)

rows = Threadline.timeline(filters, [])
```
These are not Phase 54 edit targets, but they are the strongest proof of the current adopter pain: manual composition in controllers/tests should collapse into library helpers.

## No Exact Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/threadline/investigation.ex` or `lib/threadline/investigation/*.ex` | service | request-response | No existing investigation-slice helper module yet; closest pattern is `Threadline.Export` for “validate once, compose Query, return explicit contract”. |

## Notes For Planning

- Highest-confidence edit set: `lib/threadline.ex`, `lib/threadline/query.ex`, and a focused library helper module plus tests.
- `guides/domain-reference.md` is a low-confidence, minimal-touch target only if discoverability needs one small routing update; broad docs convergence is explicitly Phase 56.
- The Phoenix example controller/test are analogs only. Replacing that bespoke transaction drill-down contract is explicitly Phase 55, not Phase 54.

## Metadata

**Analog search scope:** `lib/`, `test/`, `examples/threadline_phoenix/`, `.planning/`
**Pattern extraction date:** 2026-05-05
