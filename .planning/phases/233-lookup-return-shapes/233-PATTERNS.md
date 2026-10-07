# Phase 233: Lookup Return Shapes - Pattern Map

**Mapped:** 2026-10-03
**Files analyzed:** 13 (4 lib edits, 1 new lib module, 8 test files/additions, 1 CHANGELOG, 2 guide files, 2 example-app files reviewed with no code change needed)
**Analogs found:** 11 / 13 (2 cross-cutting with no single-file analog — new exception module, new doc-contract test — use multiple partial analogs, listed under "No Analog Found")

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/query.ex` — new shared hidden fetch + `audit_transaction/2` deprecation delegate | service (query composition) | CRUD (request-response) | `lib/threadline/investigation.ex:186-221` (current `incident_bundle/2` row-first lookup) | exact (same role, same flow — row-first → tuple) |
| `lib/threadline/investigation.ex` — `transaction_context/2`, `incident_bundle/2` rewritten onto shared fetch | service | CRUD (request-response) | same file, current `incident_bundle/2` (186-221) and opts-allowlist helper (223-232) | exact |
| `lib/threadline.ex` — new `audit_transaction/2`, `audit_transaction!/2`, `transaction_context!/2`, `incident_bundle!/2` | controller/facade | request-response | `lib/threadline.ex:370-382` (`transaction_context/2`/`incident_bundle/2` delegates) + `investigation.ex` deprecated bang pattern (`row_history_page` family) | exact (facade delegate), role-match (bang pattern has no existing `!` sibling pair with raise-from-tuple shape in this codebase yet) |
| `lib/threadline/not_found_error.ex` (new) | model/utility (exception) | request-response | none in-repo (`grep defexception` → no hits outside this phase); use `Threadline.NotFoundError` sketch in CONTEXT.md verbatim | no analog — see "No Analog Found" |
| `lib/threadline/query/scope.ex` — `apply/2` fail-closed rewrite | middleware (query guard) | request-response | same file, current `apply/2` (the function itself, rewritten in place) | exact (self-analog; only the `cond` branches change) |
| `lib/threadline/operator_surface/live/transaction_live.ex` — drop `surface:`/`params:` | controller (LiveView mount) | request-response | same file (self-edit; remove 2 keys from the `Threadline.incident_bundle/2` call at lines 20-26) | exact |
| `test/threadline/not_found_error_test.exs` (new) | test | request-response | `test/threadline/deprecation_parity_test.exs` test structure (describe blocks, `@repo`, `use Threadline.DataCase`) | role-match |
| `test/threadline/lookup_return_shapes_contract_test.exs` (new, D-05) | test (doc-contract) | request-response | `test/threadline/public_surface_contract_test.exs` (`Code.fetch_docs`-driven pins, `@hidden_modules`-style pinned lists) | role-match |
| `test/threadline/query/scope_fail_closed_test.exs` (new, D-20) | test | request-response | `test/threadline/query/action_hydration_test.exs` (telemetry-attached DataCase test, `@repo`, fixture helpers) | role-match |
| `test/threadline/investigation_test.exs` — new describe blocks (bangs, malformed id, zero-change, unknown keys, two-binding scope) | test | CRUD | same file, existing present/not-found describe blocks (lines ~459, ~488-495) | exact |
| `test/threadline/deprecation_parity_test.exs` — add `{:audit_transaction, 2}` entries + parity test | test | CRUD | same file, `{:history, 3}` parity + `__info__(:deprecated)` pin pattern (lines 193-241, 463-469) | exact |
| `test/threadline/query/action_hydration_test.exs` — fix line ~349-357 (`surface:`/`params:` removal), add query-count assertion | test | CRUD / telemetry | same file's existing `@query_event` telemetry setup (lines 1-18) | exact |
| `CHANGELOG.md` — Breaking changes + Deprecations entries | config/doc | batch (doc) | same file's existing Breaking-changes/Deprecations entries (lines 29-95) | exact |
| `guides/integration-contracts.md` (~185) — document `:transaction_header` surface | config/doc | batch | same file, existing surface-list prose | exact |
| `examples/threadline_phoenix/.../router.ex`, `.../audit_transaction_controller.ex` | route/controller (reference app) | request-response | already match target shape — **no code change**, confirm only | exact (no-op) |

## Pattern Assignments

### `lib/threadline/query.ex` — shared hidden fetch (new `@doc false` function) + deprecated delegate

**Analog:** `lib/threadline/investigation.ex:186-221` (current `incident_bundle/2`) and `lib/threadline/query.ex:72-108` (current `audit_transaction/2`)

**Imports pattern** (`lib/threadline/query.ex:1-21`):
```elixir
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
```

**Core row-first lookup pattern to generalize into the shared fetch** (`lib/threadline/investigation.ex:186-221`):
```elixir
def incident_bundle(transaction_id, opts \\ []) do
  repo = Keyword.fetch!(opts, :repo)
  internal_opts = Keyword.delete(opts, :preload)

  transaction_opts =
    internal_opts
    |> Keyword.put(:surface, :transaction_header)
    |> Keyword.put(:params, %{transaction_id: transaction_id})

  case Query.audit_transaction(transaction_id, transaction_opts) do
    nil ->
      {:error, :not_found}

    transaction ->
      transaction = Query.hydrate_actions(transaction, repo, internal_opts)

      changes =
        Query.audit_changes_for_transaction(
          transaction_id,
          internal_opts
          |> Keyword.put(:preload, [:transaction])
          |> Keyword.put(:surface, :transaction)
          |> Keyword.put(:params, %{transaction_id: transaction_id})
        )
        |> Query.hydrate_actions(repo, internal_opts)

      linked_changes = to_linked_changes(changes)
      {:ok, %IncidentBundle{...}}
  end
end
```
This is the exact template — D-09/D-10 require making the `:transaction_header`/`:transaction`
surface split (currently only `incident_bundle` sets it) the hardcoded default of the new shared
fetch itself, not a per-caller override. D-11 requires reusing the hydrated row for each change's
`.transaction` field instead of calling `hydrate_actions` a second time per change — build the
`actions_by_id` map once (see `ActionHydration.hydrate_actions/3` below) and stamp it onto both
the row and every change in one batched call.

**Id validation to split for D-18** (`lib/threadline/query.ex:586-595`):
```elixir
defp validate_audit_transaction_id!(transaction_id) do
  case Ecto.UUID.cast(transaction_id) do
    :error ->
      raise ArgumentError,
            "invalid audit transaction id: #{inspect(transaction_id)}"

    {:ok, canonical} ->
      canonical
  end
end
```
D-18 requires splitting this: a non-binary must still raise `ArgumentError` immediately (add an
`is_binary(transaction_id)` guard before `Ecto.UUID.cast/1`), but a binary that fails `Ecto.UUID.cast/1`
must become `{:error, :not_found}` inside the new three-lookup path — **do not** change this
existing private helper's raising behavior; it is reused as-is by the deprecated
`Query.audit_transaction/2` delegate (D-06 keeps that function's current raise). Write a new,
separate id-resolution helper for the three new lookups that returns `{:ok, uuid} | :not_found`
for a cast failure, and raises `ArgumentError` only for a non-binary.

**Scope surface pattern to replace** (`lib/threadline/query.ex:687-694`):
```elixir
defp transaction_scope_opts(transaction_id, opts) do
  [
    scope: Keyword.get(opts, :scope),
    scope_query_fn: Keyword.get(opts, :scope_query_fn),
    surface: Keyword.get(opts, :surface, :transaction),   # <- D-10 bug: defaults wrong surface
    params: %{transaction_id: transaction_id}
  ]
end
```
D-10 fixes the latent bug here: the row query must always use `surface: :transaction_header`
(single `[at]` binding), and the changes query must always use `surface: :transaction`
(`[ac, at]` binding) — hardcoded inside the shared fetch, with no `Keyword.get(opts, :surface, ...)`
fallback to a caller override (D-13 forbids `:surface` in opts entirely).

**Per-function option allowlist pattern (copy verbatim style)** (`lib/threadline/investigation.ex:223-232`):
```elixir
defp validate_row_history_opts!(opts) do
  Enum.each(opts, fn {key, _value} ->
    if key not in @row_history_opt_keys do
      allowed = Enum.map_join(@row_history_opt_keys, ", ", &inspect/1)

      raise ArgumentError,
            "unknown row_history option key #{inspect(key)}. Allowed: #{allowed}"
    end
  end)
end
```
Apply the same shape for the new `@lookup_opt_keys ~w(repo storage_schema scope scope_query_fn)a`
allowlist shared by all three lookups (D-13). Define one module attribute and one private
validator, called from each of the three plain functions before anything else runs.

**Reused-hydration pattern (D-11)** (`lib/threadline/query/action_hydration.ex:41-67`):
```elixir
def hydrate_actions(items, repo, opts) when is_list(items) do
  transactions = Enum.map(items, &hydrate_target_transaction/1)

  action_ids =
    transactions
    |> Enum.map(&(&1 && &1.action_id))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()

  actions_by_id = fetch_actions_by_id(action_ids, repo, opts)

  items
  |> Enum.zip(transactions)
  |> Enum.map(fn {item, transaction} ->
    apply_hydrated_action(item, transaction, actions_by_id)
  end)
end
```
This already dedupes and batches in one query — D-11's "reuse the hydrated row" requirement means:
hydrate the row once, then stamp that *same* hydrated row struct onto every change's `:transaction`
field directly (`%{change | transaction: hydrated_row}`) rather than calling `hydrate_actions` a
second time over the changes list. `ActionHydration.hydrate_actions/3` stays the one-query action
fetch; the second query elimination is in how the shared fetch assembles changes, not in
`ActionHydration` itself.

**Deprecated delegate pattern for `Query.audit_transaction/2` (D-06)** — model this on the existing
`@deprecated` + one-line delegate style already in the same file:
```elixir
# Source: lib/threadline/query.ex:27-42 (current row_history/4 deprecated delegate — same shape to copy)
@deprecated "Use Threadline.row_history/3 instead."
@doc """
...
"""
@spec row_history(module(), term(), keyword(), keyword()) :: [AuditChange.t()]
def row_history(schema_module, id, filters \\ [], opts \\ [])
    when is_list(filters) and is_list(opts) do
  RowReads.list(schema_module, id, LegacyOpts.row_history(filters, opts))
end
```
`Query.audit_transaction/2` becomes `@deprecated "Use Threadline.audit_transaction/2 instead."`
with its body converting the shared fetch's `{:ok, row, _changes}` → the row (keeping `:preload`
support unchanged) and `:not_found` → `nil`. Keep its current `ArgumentError`-raising id validation
exactly as-is (do not route it through the new D-18 malformed-id-as-not-found path — D-18 is only
for the three new facade lookups).

---

### `lib/threadline.ex` — new facade functions + bangs

**Analog:** `lib/threadline.ex:370-382` (existing tuple-returning `incident_bundle/2` delegate)

**Facade delegate pattern** (`lib/threadline.ex:370-382`):
```elixir
@doc """
Returns one transaction-oriented investigation slice with linked transaction
and optional action metadata.

This packages the existing transaction drill-down primitive into a reusable
helper contract without adding diff or incident-bundle rendering.
"""
def transaction_context(transaction_id, opts \\ []),
  do: Investigation.transaction_context(transaction_id, opts)

@doc """
Returns one transaction-focused incident bundle with linked transaction/action
context and packaged JSON-ready diffs.

Returns `{:ok, bundle}` when the parent `AuditTransaction` exists, even if it
has no captured changes. Returns `{:error, :not_found}` when the transaction
row does not exist.
"""
def incident_bundle(transaction_id, opts \\ []),
  do: Investigation.incident_bundle(transaction_id, opts)
```
`audit_transaction/2` is new on the facade with this exact delegate shape, delegating to the new
shared fetch (via `Query` or `Investigation`, per the discretion note below). `transaction_context/2`'s
`@doc` and body change in place per D-07 (struct → tuple); `incident_bundle/2`'s `@doc`/body are
unchanged except for the internal plumbing moving onto the shared fetch.

**Bang-sibling pattern (per the CONTEXT.md sketch — no raise-from-tuple precedent exists in-repo
today, so this is the literal pattern to add, not an adaptation):**
```elixir
@doc """
Returns the `%AuditTransaction{}` or raises `Threadline.NotFoundError`.
"""
@spec audit_transaction!(Ecto.UUID.t(), keyword()) :: AuditTransaction.t()
def audit_transaction!(transaction_id, opts \\ []) do
  case audit_transaction(transaction_id, opts) do
    {:ok, transaction} -> transaction
    {:error, :not_found} -> raise Threadline.NotFoundError, resource: :audit_transaction, id: transaction_id
  end
end
```
Repeat for `transaction_context!/2` (resource: `:audit_transaction`, per D-17 — all three bangs
use that resource atom because the transaction is the subject looked up) and `incident_bundle!/2`.

**`@spec` pattern (D-08, final, written in this phase):**
```elixir
@spec audit_transaction(Ecto.UUID.t(), keyword()) :: {:ok, AuditTransaction.t()} | {:error, :not_found}
@spec audit_transaction!(Ecto.UUID.t(), keyword()) :: AuditTransaction.t()
```
Mirror with `LinkedTransaction.t()` / `IncidentBundle.t()`. No `no_return` on the bangs (D-08 explicit).
Add `@doc since: "1.0.0"` to every new name.

---

### `lib/threadline/not_found_error.ex` (new)

**Analog:** none in-repo. Use the CONTEXT.md sketch verbatim as the base, since no existing
`defexception` exists to model against:
```elixir
defmodule Threadline.NotFoundError do
  @moduledoc """
  Raised by the `!` sibling of a single-subject lookup (`audit_transaction!/2`,
  `transaction_context!/2`, `incident_bundle!/2`) when the row does not exist
  or is rejected by the configured scope. The message carries only the id the
  caller passed in — never row data, scope terms, or whether the row exists
  but was filtered by scope.
  """

  defexception [:resource, :id]

  @type t :: %__MODULE__{resource: atom(), id: term()}

  @impl true
  def message(%{resource: resource, id: id}) do
    "#{resource |> to_string() |> String.replace("_", " ")} not found: #{inspect(id)}"
  end
end

defimpl Plug.Exception, for: Threadline.NotFoundError do
  def status(_), do: 404
  def actions(_), do: []
end
```
Moduledoc is mandatory (the Phase 234 gate, per CONTEXT.md D-17) — every project module with a
public doc surface in this codebase carries one; see `lib/threadline.ex`'s own moduledoc for the
house style of stating what a function/module is for in the first paragraph.

---

### `lib/threadline/query/scope.ex` — fail-closed `apply/2`

**Analog:** the same file, current fail-open implementation (full file, 25 lines):
```elixir
defmodule Threadline.Query.Scope do
  @moduledoc false

  @spec apply(Ecto.Queryable.t(), keyword()) :: Ecto.Queryable.t()
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
end
```
D-20 rewrite needs to distinguish three cases rather than two — keep the `cond`/module shape
(same `@moduledoc false`, same single public `apply/2`), but replace the collapsed
`is_nil(scope) or is_nil(scope_query_fn) -> query` branch and the catch-all `true -> query` branch
with:
1. no `:scope` and no `:scope_query_fn` → `query` (opt-in stays opt-in, unchanged);
2. `:scope` present, `:scope_query_fn` missing or not arity-3 → `raise ArgumentError` naming the
   problem (this currently falls into branch 1 above when `scope_query_fn` is `nil`, or into
   `true -> query` when it is non-nil but wrong-arity — both must become a raise);
3. `:scope_query_fn` present (valid arity-3), `:scope` missing → raise as well (currently silently
   unscoped via the `is_nil(scope)` half of branch 1 — recommendation in D-20, not yet locked as
   "must raise" wording, but CONTEXT.md recommends raising).

Error-handling style precedent for the `ArgumentError` wording — copy the
`investigation.ex:223-232` allowlist-raise phrasing style ("unknown X. Allowed: Y") adapted to
name which side is missing/wrong-arity.

---

### `lib/threadline/operator_surface/live/transaction_live.ex` — drop forbidden opts

**Analog:** the file itself, lines 16-40 (self-edit)
```elixir
case Threadline.incident_bundle(id,
       repo: repo,
       scope: socket.assigns[:threadline_scope],
       scope_query_fn: socket.assigns[:threadline_scope_query_fn],
       surface: :transaction,          # <- REMOVE (D-13 forbids this key)
       params: %{transaction_id: id}   # <- REMOVE (D-13 forbids this key)
     ) do
  {:error, :not_found} ->
    {:ok, assign(socket, :not_found, true)}

  {:ok, bundle} ->
    ...
end
```
Must land together with the shared fetch's hardcoded `:transaction_header`/`:transaction` split
(D-10) — removing the override alone, before the shared fetch computes the right surface
internally, reintroduces the `unknown_binding_1!` failure D-10 describes (Pitfall 2 in research).
D-18 also requires this mount to handle a malformed (non-UUID) `id` param as `{:error, :not_found}`
→ render not-found, rather than crashing — `id` here is a raw LiveView route param, always a
binary, so no `ArgumentError`-raising path is reachable from this call site; no `is_binary` guard
needed in this file.

---

### `test/threadline/not_found_error_test.exs` (new)

**Analog:** `test/threadline/deprecation_parity_test.exs` describe-block / `use Threadline.DataCase`
structure (lines 1-20, `@repo Threadline.Test.Repo`). Cover: `Plug.Exception.status/1 == 404`,
`actions/1 == []`, message contains only the id (`inspect(id)`), and is byte-equal between a
missing-UUID case and a scope-rejected-row case (D-22).

---

### `test/threadline/lookup_return_shapes_contract_test.exs` (new, D-05)

**Analog:** `test/threadline/public_surface_contract_test.exs:1-40` — pinned-list + `Code.fetch_docs`
pattern:
```elixir
@hidden_modules [
  ...
  Threadline.Query,
  Threadline.Investigation
]
```
and (from the same file's body, lines 260-265):
```elixir
test "the Threadline moduledoc names Threadline.Query.timeline_query/1 as the one escape hatch" do
  {:docs_v1, _, _, _, moduledoc, _, _} = Code.fetch_docs(Threadline)
  text = Map.fetch!(moduledoc, "en")

  assert text =~ @escape_hatch_reference,
         "expected the Threadline moduledoc to name #{@escape_hatch_reference}"
end
```
Model the new file on this: a `@lookups [audit_transaction: 2, transaction_context: 2, incident_bundle: 2]`
module attribute, `Code.fetch_docs/1`-driven assertions per D-05(a)-(c), and an explicit
`@exempt [as_of: 4]` list with its reason per D-05(d). Give the new file a partition-weight entry
(see Wave-0 gap in RESEARCH.md — run `bin/ci-test-partitions --write-weights` after adding it).

---

### `test/threadline/query/scope_fail_closed_test.exs` (new, D-20)

**Analog:** `test/threadline/query/action_hydration_test.exs:1-18` — `use Threadline.DataCase`,
`@repo Threadline.Test.Repo`, `@query_event Keyword.fetch!(Repo.config(), :telemetry_prefix) ++ [:query]`,
`import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]`. Reuse this setup block verbatim
for the new file; cover every scoped read named in D-22 (timeline, actor, transaction lookups,
export, operator-surface mounts) with both failure shapes (`:scope` + no/bad `scope_query_fn`,
and `scope_query_fn` + no `:scope`).

---

### `test/threadline/deprecation_parity_test.exs` — add `{:audit_transaction, 2}`

**Analog:** same file, `{:history, 3}` parity + pin pattern:
```elixir
# Source: test/threadline/deprecation_parity_test.exs:193-205 (parity test template)
test "apply(Threadline.Query, :history, ...) returns the same ids as the facade's deprecated history/3" do
  ...
  facade_results = apply(Threadline, :history, facade_args)
  query_results = apply(Threadline.Query, :history, query_args)

  assert Enum.map(query_results, & &1.id) == Enum.map(facade_results, & &1.id)
end

# Source: test/threadline/deprecation_parity_test.exs:237-241 (single-entry pin)
test "Threadline.__info__(:deprecated) names {:history, 3} with the exact message" do
  assert {{:history, 3}, "Use Threadline.row_history/3 instead."} in Threadline.__info__(:deprecated)
end

# Source: test/threadline/deprecation_parity_test.exs:467-469 (exact-inventory mutation control)
test "Threadline.Query.__info__(:deprecated) equals the exact expected inventory" do
  assert Enum.sort(Threadline.Query.__info__(:deprecated)) == Enum.sort(@query_deprecated)
end
```
Add `{{:audit_transaction, 2}, "Use Threadline.audit_transaction/2 instead."}` to `@query_deprecated`
(line ~38-44 of the same file) — this is the "mutation control" D-06 asks for: the exact-inventory
equality assertion already fails loudly if the entry is missing, dropped, or has the wrong message,
with no extra scaffolding needed. Add the parity assertions: `nil` ↔ `{:error, :not_found}`,
`t` ↔ `{:ok, t}`, covering the `:preload` path, using the same `apply(Module, :fun, args)` indirection
this file uses throughout so the file's own compilation never warns on the deprecated call.

---

### `CHANGELOG.md` — Breaking changes / Deprecations entries

**Analog:** same file's existing entries (lines 29-95), e.g.:
```markdown
### Breaking changes

- An un-hydrated `AuditTransaction.action` is now `nil` instead of
  `%Ecto.Association.NotLoaded{}`. ... Required action: read the linked
  action through `Threadline.transaction_context/2` or
  `Threadline.incident_bundle/2`, ...
```
and the Deprecations entry to merge per D-06:
```markdown
### Deprecations

- Passing `:action` (or `transaction: :action`) in the `:preload` option of
  `Threadline.Query.audit_transaction/2` and
  `Threadline.Query.audit_changes_for_transaction/2` still works and still
  returns a hydrated `.action` — it now emits one deprecation warning per call.
  Removal is no earlier than Threadline 2.0.
```
Merge this existing `Threadline.Query.audit_transaction/2 :preload :action` bullet into one new
entry documenting the whole function's deprecation (D-06: "merge ... so the function is not
described twice"). Add new Breaking-changes entries for: `transaction_context/2`'s shape change
(D-07, with a before/after snippet and the `%LinkedTransaction{transaction: nil}` 0.12 idiom named
explicitly), the `:surface`/`:params`/`:preload` rejection (D-13), and `Scope.apply/2` fail-closed
(D-20). Every entry follows the house style: "Required action:" sentence, breaking-changes-before-
deprecations-before-feature-tour ordering (per the file's own HTML-comment house rule at the top).

---

## Shared Patterns

### Per-function option allowlist (no NimbleOptions)
**Source:** `lib/threadline/investigation.ex:223-232` (`validate_row_history_opts!/1`)
**Apply to:** all three new facade lookups' internal opts validation (D-13), plus the fail-closed
`Scope.apply/2` rewrite's own error-raising style (D-20).
```elixir
defp validate_row_history_opts!(opts) do
  Enum.each(opts, fn {key, _value} ->
    if key not in @row_history_opt_keys do
      allowed = Enum.map_join(@row_history_opt_keys, ", ", &inspect/1)

      raise ArgumentError,
            "unknown row_history option key #{inspect(key)}. Allowed: #{allowed}"
    end
  end)
end
```

### Row-first existence + scope-rejected = not-found
**Source:** `lib/threadline/investigation.ex:186-221` (`incident_bundle/2`)
**Apply to:** the new shared hidden fetch backing all three lookups (D-09).

### Batched action hydration (one query, 0 when no action_id)
**Source:** `lib/threadline/query/action_hydration.ex:41-67` (`hydrate_actions/3`)
**Apply to:** the facade `audit_transaction/2`'s always-hydrate requirement (D-14) and the shared
fetch's single hydration pass reused across the row and all its changes (D-11).

### Deprecation delegate + exact-inventory pin + parity test
**Source:** `test/threadline/deprecation_parity_test.exs` (full file pattern: `@query_deprecated`
list + `__info__(:deprecated)` equality test + `apply/3`-indirected parity test)
**Apply to:** `Threadline.Query.audit_transaction/2`'s new `@deprecated` status (D-06).

### Telemetry-driven query counting
**Source:** `test/threadline/query/action_hydration_test.exs:1-18` (`@query_event`, `attach_telemetry!/1`)
**Apply to:** the `incident_bundle` ≤ 3-query assertion (D-11/D-22).

### CHANGELOG Unreleased entry shape
**Source:** `CHANGELOG.md:29-95` (Breaking changes / Deprecations subsections, "Required action:" sentences)
**Apply to:** every D-06/D-07/D-13/D-20 breaking/deprecation entry this phase adds.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/threadline/not_found_error.ex` | model (exception) | request-response | No `defexception` module exists anywhere in-repo (`grep -rn defexception` outside deps/_build returns nothing); build directly from the CONTEXT.md D-17 sketch, following this project's universal moduledoc-required convention for public modules. |
| Bang (`!`) sibling functions on the facade | controller | request-response | No existing Threadline facade function pairs a tuple-returning plain function with a raise-from-tuple `!` sibling today (existing `!`-named functions, e.g. none currently on the facade for lookups); built from the CONTEXT.md bang-shape sketch (`case f(id,opts) do {:ok,v}->v; {:error,:not_found}-> raise ... end`), composed from the row-first analog above. |

## Metadata

**Analog search scope:** `lib/threadline/`, `lib/threadline/query/`, `lib/threadline/investigation.ex`,
`lib/threadline.ex`, `lib/threadline/operator_surface/live/`, `test/threadline/` (deprecation,
public-surface-contract, action-hydration-test), `CHANGELOG.md`, `examples/threadline_phoenix/`
**Files scanned:** 17 read directly this session (all confirmed git-tracked via `git ls-files`); no
gitignored mirrors encountered — this repo has no `.gsd/capabilities/` mirror structure for library
source.
**Pattern extraction date:** 2026-10-03
