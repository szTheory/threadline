# Phase 55: incident-bundle-surface - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline.ex` | utility | request-response | `lib/threadline.ex` | exact |
| `lib/threadline/investigation.ex` | service | transform | `lib/threadline/investigation.ex` | exact |
| `lib/threadline/investigation/incident_bundle.ex` | model | transform | `lib/threadline/investigation/linked_change.ex` | role-match |
| `lib/threadline/query.ex` | service | CRUD | `lib/threadline/query.ex` | exact |
| `test/threadline/investigation_test.exs` | test | request-response | `test/threadline/investigation_test.exs` | exact |
| `test/threadline/query_test.exs` | test | request-response | `test/threadline/query_test.exs` | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` | controller | request-response | `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_json.ex` | component | transform | `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex` | role-match |
| `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` | test | request-response | `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` | exact |

## Pattern Assignments

### `lib/threadline.ex` (public bundle entrypoint)

**Analog:** [lib/threadline.ex](/Users/jon/projects/threadline/lib/threadline.ex:132)

**Public discovery pattern** (lines 132-179):
```elixir
@doc """
Returns one transaction-oriented investigation slice with linked transaction
and optional action metadata.

This packages the existing transaction drill-down primitive into a reusable
helper contract without adding Phase 55 diff or incident-bundle rendering.
"""
def transaction_context(transaction_id, opts \\ []),
  do: Investigation.transaction_context(transaction_id, opts)
```

Copy this shape for `incident_bundle/2`: top-level `Threadline` docstring, thin delegator, adopter-facing discovery here rather than in `Query`.

**Projection delegator pattern** (lines 207-215):
```elixir
@doc """
Projects a single `%Threadline.Capture.AuditChange{}` into deterministic, JSON-friendly maps.
"""
defdelegate change_diff(audit_change, opts \\ []),
  to: Threadline.ChangeDiff,
  as: :from_audit_change
```

Phase 55 should package `change_diff/2` at the bundle layer, not inline it in controllers.

### `lib/threadline/investigation.ex` (incident bundle orchestration)

**Analog:** [lib/threadline/investigation.ex](/Users/jon/projects/threadline/lib/threadline/investigation.ex:119)

**Raw helper foundation pattern** (lines 119-138):
```elixir
def transaction_context(transaction_id, opts \\ []) do
  changes =
    Query.audit_changes_for_transaction(
      transaction_id,
      Keyword.put(opts, :preload, transaction: :action)
    )

  linked_changes = to_linked_changes(changes)
  transaction = linked_transaction(linked_changes)

  %LinkedTransaction{
    transaction: transaction,
    action: linked_action(transaction),
    changes: linked_changes
  }
end
```

This is the strongest implementation seam for Phase 55. Keep `transaction_context/2` unchanged and build `incident_bundle/2` beside it by transforming these linked rows into a richer wrapper that adds `change_diff`.

**List-to-wrapper mapping pattern** (lines 157-175):
```elixir
defp linked_changes(changes, opts) when is_list(changes) do
  repo = Query.timeline_repo!([], opts)

  changes
  |> Query.preload_investigation_context(repo)
  |> to_linked_changes()
end

defp to_linked_changes(changes) do
  Enum.map(changes, fn audit_change ->
    transaction = audit_change.transaction

    %LinkedChange{
      audit_change: audit_change,
      transaction: transaction,
      action: linked_action(transaction)
    }
  end)
end
```

Mirror this exact pattern for per-change incident wrappers: preload first, map once, keep raw structs attached.

### `lib/threadline/investigation/incident_bundle.ex` (new typed structs)

**Analog:** [lib/threadline/investigation/linked_change.ex](/Users/jon/projects/threadline/lib/threadline/investigation/linked_change.ex:1)

**Result-struct convention** (lines 1-35):
```elixir
defmodule Threadline.Investigation.LinkedChange do
  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.AuditAction

  @enforce_keys [:audit_change, :transaction]
  defstruct [:audit_change, :transaction, :action]
end

defmodule Threadline.Investigation.LinkedTransaction do
  alias Threadline.Capture.AuditTransaction
  alias Threadline.Investigation.LinkedChange
  alias Threadline.Semantics.AuditAction

  defstruct [:transaction, :action, changes: []]
end
```

Phase 55 should reuse this style:
- explicit modules under `Threadline.Investigation`
- `@enforce_keys` for required child wrappers
- parent bundle struct with `changes: []` default
- raw linked structs remain accessible on the wrapper

Use separate incident-bundle modules rather than mutating `LinkedTransaction`.

### `lib/threadline/query.ex` (existence-aware singular lookup support)

**Analog 1:** [lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:452)

**Transaction drill-down primitive pattern** (lines 452-481 in current file):
Use `audit_changes_for_transaction/2` as the ordering authority. Phase 55 should not fork transaction ordering logic; it should compose on top of this function or a sibling helper that preserves the same `captured_at DESC, id DESC` order.

**Analog 2:** [lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:353)

**Tagged singular lookup pattern** (lines 353-381):
```elixir
def as_of(schema_module, id, timestamp, opts) do
  repo = Keyword.fetch!(opts, :repo)
  ...
  snapshot =
    AuditChange
    |> ...
    |> repo.one()

  case snapshot do
    %AuditChange{op: "delete"} -> {:error, :deleted_record}
    %AuditChange{data_after: data_after} -> load_as_of_snapshot(schema_module, data_after, opts)
    nil -> {:error, :before_audit_horizon}
  end
end
```

This is the best local pattern for `incident_bundle/2` existence semantics:
- singular lookup
- explicit tagged outcome
- `nil` becomes a concrete error atom

For Phase 55, map missing transaction row to `{:error, :not_found}` while still allowing `{:ok, bundle}` with `changes: []` when the parent row exists.

**Shared repo/preload pattern** (lines 99-103, 175-195):
```elixir
def preload_investigation_context(changes, repo) when is_list(changes) and is_atom(repo) do
  repo.preload(changes, transaction: :action)
end

def timeline_repo!(filters \\ [], opts \\ []) when is_list(filters) and is_list(opts) do
  case Keyword.get(opts, :repo) || Keyword.get(filters, :repo) do
    nil -> raise ArgumentError, ...
    repo when is_atom(repo) -> repo
    other -> raise ArgumentError, ...
  end
end
```

Keep repo resolution and preloading centralized in `Query`; do not reimplement repo validation in controllers.

### `test/threadline/investigation_test.exs` (bundle contract tests)

**Analog:** [test/threadline/investigation_test.exs](/Users/jon/projects/threadline/test/threadline/investigation_test.exs:20)

**Fixture helpers pattern** (lines 20-59):
```elixir
defp insert_transaction(attrs \\ %{}) do
  defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}
  @repo.insert!(AuditTransaction.changeset(Map.merge(defaults, attrs)))
end

defp insert_change(transaction, attrs) do
  defaults = %{
    table_schema: "public",
    table_name: "users",
    table_pk: %{"id" => "user-1"},
    op: "insert",
    data_after: %{"name" => "Alice"},
    changed_fields: ["name"],
    captured_at: DateTime.utc_now(),
    transaction_id: transaction.id
  }

  @repo.insert!(AuditChange.changeset(Map.merge(defaults, Map.new(attrs))))
end
```

Copy these helpers into new Phase 55 tests instead of building larger fixtures.

**Rich result-shape assertion pattern** (lines 241-274):
```elixir
result = Threadline.transaction_context(txn.id, repo: @repo)

assert %LinkedTransaction{} = result
assert result.transaction.id == txn.id
assert result.action.id == action.id
assert [%LinkedChange{} = linked_change] = result.changes
assert linked_change.audit_change.id == change.id
refute Map.has_key?(result, :change_diff)
refute Map.has_key?(linked_change, :change_diff)
```

Mirror this structure for Phase 55, but invert the last assertions:
- `transaction_context/2` stays without `change_diff`
- `incident_bundle/2` should assert bundled changes do include `change_diff`
- add empty-transaction and not-found cases as separate tests

### `test/threadline/query_test.exs` (backward-compatibility guardrail)

**Analog:** [test/threadline/query_test.exs](/Users/jon/projects/threadline/test/threadline/query_test.exs:714)

**Compatibility block pattern** (lines 714-771):
```elixir
test "history/3, actor_history/2, timeline/2, timeline_page/2, and audit_changes_for_transaction/2 stay raw while transaction_context/2 is richer" do
  ...
  [transaction_change] = Threadline.audit_changes_for_transaction(txn.id, repo: @repo)

  %LinkedTransaction{changes: [%LinkedChange{} = linked_change]} =
    Threadline.transaction_context(txn.id, repo: @repo)

  assert %AuditChange{} = transaction_change
  assert linked_change.audit_change.id == transaction_change.id
end
```

Extend this exact pattern for Phase 55 instead of replacing it. Add one assertion that `audit_changes_for_transaction/2` remains raw while `incident_bundle/2` is tagged and richer.

**Change-diff round-trip pattern** (lines 333-356):
```elixir
for ch <- Threadline.audit_changes_for_transaction(txn.id, repo: @repo) do
  map = Threadline.change_diff(ch, [])
  assert is_map(map)
  assert Map.has_key?(map, "field_changes")
  assert Jason.encode!(map)
end
```

Use this to verify each bundled change carries a real diff map, not an opaque placeholder.

### `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` (endpoint migration)

**Analog:** [examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex:15)

**Auth + UUID gate pattern** (lines 15-43):
```elixir
def changes(conn, %{"id" => id}) do
  case authenticated_actor(conn) do
    nil ->
      conn
      |> put_status(:unauthorized)
      |> json(%{errors: %{detail: "authentication required for incident drill-down"}})

    _actor_ref ->
      case Ecto.UUID.cast(id) do
        :error ->
          conn
          |> put_status(:bad_request)
          |> json(%{errors: %{detail: "invalid audit transaction id"}})

        {:ok, uuid} ->
          ...
      end
  end
end
```

Keep this auth boundary and malformed-UUID handling exactly as-is.

**What to replace** (lines 29-40):
```elixir
changes = Threadline.audit_changes_for_transaction(uuid, repo: Repo)

json(conn, %{
  audit_transaction_id: uuid,
  changes:
    Enum.map(changes, fn ac ->
      %{
        audit_change_id: to_string(ac.id),
        change_diff: Threadline.change_diff(ac, [])
      }
    end)
})
```

This is the composition seam Phase 55 should delete. Controller should switch from library assembly to `Threadline.incident_bundle/2`, then render through a JSON module.

### `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_json.ex` (new renderer)

**Analog:** [examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex:1)

**Curated render-module pattern** (lines 1-16):
```elixir
defmodule ThreadlinePhoenixWeb.PostJSON do
  @moduledoc false

  def post(%{post: post} = assigns) do
    base = %{
      id: post.id,
      title: post.title,
      slug: post.slug,
      inserted_at: post.inserted_at
    }

    case Map.get(assigns, :audit_transaction_id) do
      nil -> base
      at_id -> Map.put(base, :audit_transaction_id, at_id)
    end
  end
end
```

Phase 55 should add an `AuditTransactionJSON` module in this style:
- `@moduledoc false`
- pure map-building function
- curated HTTP shape, not direct struct serialization
- controller calls `render/3` instead of `json/2` on success

### `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` (request-path proof)

**Analog:** [examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs:6)

**End-to-end contract test pattern** (lines 6-39):
```elixir
conn2 =
  build_conn()
  |> sigra_conn(%{user_id: "incident-user-1", session_id: "incident-session-1"})
  |> get(~p"/api/audit_transactions/#{atid}/changes")

assert response(conn2, 200)
drill = Jason.decode!(conn2.resp_body)
assert drill["audit_transaction_id"] == atid
assert is_list(drill["changes"])

first = hd(drill["changes"])
assert is_binary(first["audit_change_id"])
assert is_map(first["change_diff"])
assert first["change_diff"]["schema_version"] == 1
```

Keep this request-path structure, but widen assertions to the curated bundle contract: transaction/action metadata, bundled change wrapper fields, and empty-change `200`.

**Negative-path pattern** (lines 41-64):
```elixir
assert response(conn, 401)
assert Jason.decode!(conn.resp_body) == %{
  "errors" => %{"detail" => "authentication required for incident drill-down"}
}

assert response(conn, 400)
assert Jason.decode!(conn.resp_body) == %{
  "errors" => %{"detail" => "invalid audit transaction id"}
}
```

Add a sibling `404` case for authenticated requests where the transaction row is missing.

## Shared Patterns

### Public API layering
**Source:** [lib/threadline.ex](/Users/jon/projects/threadline/lib/threadline.ex:132), [lib/threadline/investigation.ex](/Users/jon/projects/threadline/lib/threadline/investigation.ex:119)

Apply to the new bundle API:
- top-level `Threadline` is the discoverable facade
- `Investigation` owns orchestration
- `Query` owns repo access, ordering, and preload helpers

### Typed wrapper contracts over raw structs
**Source:** [lib/threadline/investigation/linked_change.ex](/Users/jon/projects/threadline/lib/threadline/investigation/linked_change.ex:1)

Apply to:
- bundle parent struct
- per-change bundle struct

Rule: keep raw `audit_change`, `transaction`, and `action` reachable on the bundle wrapper; add `change_diff` alongside them rather than replacing them.

### Explicit tagged outcomes for singular lookups
**Source:** [lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:353)

Apply to:
- `Threadline.incident_bundle/2`

Rule: return `{:ok, bundle}` or `{:error, :not_found}`. Do not overload `changes: []` to mean missing transaction.

### Phoenix controller/render split
**Source:** [examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_controller.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_controller.ex:23), [examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex:1)

Apply to the example migration:
- controller handles auth, status codes, and library calls
- JSON module curates response shape
- keep error JSON inline or via `ErrorJSON`

### Compatibility-first regression coverage
**Source:** [test/threadline/query_test.exs](/Users/jon/projects/threadline/test/threadline/query_test.exs:714), [test/threadline/investigation_test.exs](/Users/jon/projects/threadline/test/threadline/investigation_test.exs:241)

Apply to tests:
- one suite for the new rich contract
- one compatibility block proving old primitives still return raw structs

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `examples/threadline_phoenix/test/threadline_phoenix_web/controllers/audit_transaction_json_test.exs` | test | transform | No direct JSON-module unit test pattern exists for controller JSON modules other than `ErrorJSON`; prefer request-path coverage unless Phase 55 explicitly adds renderer unit tests. |

## Metadata

**Analog search scope:** `lib/`, `test/`, `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/`, `examples/threadline_phoenix/test/threadline_phoenix_web/`, `.planning/milestones/v1.16-phases/54-investigation-slice-apis/`, `.planning/milestones/v1.16-phases/55-incident-bundle-surface/`
**Files scanned:** 13
**Pattern extraction date:** 2026-05-05
