# Phase 231: Facade Topology and the Capture/Semantics Edge - Pattern Map

**Mapped:** 2026-10-03
**Files analyzed:** 15 (6 lib modules modified, 1 config modified, 4 test files modified/added, 1 new test file, 8 doc/example call sites)
**Analogs found:** 15 / 15 (every file has an exact in-repo analog — this is a closed-world refactor; RESEARCH.md already did line-level verification)

This phase has no genuinely new structural patterns to borrow from outside the files being touched — CONTEXT.md and RESEARCH.md already pinned exact line numbers for every change. This file packages those same excerpts into the role/analog shape the planner expects, and adds the two forward-looking files (the new facade-only contract test, the new association-absence test) with the closest sibling analog.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/capture/audit_transaction.ex` | model (Ecto schema) | CRUD | itself (pre-image, same file) — association removal | exact (self-modify) |
| `lib/threadline/semantics/audit_action.ex` | model (Ecto schema) | CRUD | itself (pre-image, same file) — association removal | exact (self-modify) |
| `lib/threadline/query.ex` | service (query/read layer) | request-response | itself — new `@doc false` hydrate helper alongside existing `preload_investigation_context/3` and `storage_opts/2` | exact (self-modify, new function follows sibling pattern) |
| `lib/threadline/investigation.ex` | service | request-response | itself — 3 call sites switch from `repo.preload` to the new helper | exact (self-modify) |
| `lib/threadline/operator_surface/live/timeline_live.ex` | component (LiveView) | request-response | itself — 1 call site (`preload_visible_context/3`) | exact (self-modify) |
| `lib/threadline/operator_surface/live/transaction_live.ex` | component (LiveView) | request-response | `timeline_live.ex` mount/opts shape | role-match |
| `lib/threadline.ex` | facade / controller-equivalent | request-response | itself — moduledoc + ~12 doc-string rewrites | exact (self-modify) |
| `mix.exs` | config | batch (build-time docs config) | itself — `docs/0`, `groups_for_modules` | exact (self-modify) |
| `test/threadline/public_surface_contract_test.exs` | test | request-response (assertion over compiled module metadata) | itself — `@hidden_modules` list + `docs_visibility/1` | exact (self-modify) |
| `test/threadline/facade_only_references_contract_test.exs` | test (NEW) | batch (file-scan) | `test/threadline/audit_indexing_doc_contract_test.exs` | exact (doc-contract-test family) |
| `<new association-absence test>` (e.g. `test/threadline/capture/audit_transaction_test.exs`) | test (NEW) | request-response (schema introspection) | `test/threadline/public_surface_contract_test.exs` (assertion-over-metadata style) | role-match |
| `test/threadline/query_test.exs` (literal-source assertion ~983) | test | request-response | itself — update the substring it asserts | exact (self-modify) |
| `test/threadline/operator_surface/live/timeline_live_test.exs` (literal-source assertion ~1204) | test | request-response | itself — update the substring it asserts | exact (self-modify) |
| `guides/*.md`, `README.md`, example app docs/scripts | config/doc (no runtime role) | transform (text rewrite) | each file, straight swap per D-11 table | exact |
| `examples/threadline_phoenix/priv/scripts/incident_replay.exs` | utility (script) | batch | itself — one-line call-site swap | exact |

## Pattern Assignments

### `lib/threadline/capture/audit_transaction.ex` (model, CRUD)

**Analog:** itself (current source, before this phase's edit) — `lib/threadline/capture/audit_transaction.ex`

**Current association to remove** (schema block, read live):
```elixir
field(:actor_ref, Threadline.Semantics.ActorRef)

belongs_to(:action, Threadline.Semantics.AuditAction)

has_many(:changes, Threadline.Capture.AuditChange, foreign_key: :transaction_id)
```

**Type to leave untouched** (already bare, confirmed no `AuditAction.t()` reference):
```elixir
@typedoc "The row changes captured from one PostgreSQL database transaction."
@type t :: %__MODULE__{}
```

**Target shape per D-05:** replace `belongs_to(:action, ...)` with:
```elixir
field(:action_id, :binary_id)
field(:action, :any, virtual: true, default: nil)
```
`cast/2` already lists `:action_id` in its field list (`cast(attrs, [:txid, :occurred_at, :source, :meta, :actor_ref, :action_id])`) — no changeset edit needed there.

**Moduledoc "Relationships" section to rewrite in prose** (currently):
```
## Relationships

- `has_many :changes, Threadline.Capture.AuditChange` — the row mutations
  captured in this transaction.
- `belongs_to :action, Threadline.Semantics.AuditAction` — optional
  semantic label for this transaction.
```
Rewrite the second bullet to describe `action_id`/virtual `action` hydrated by the exploration layer, not an Ecto association.

---

### `lib/threadline/semantics/audit_action.ex` (model, CRUD)

**Analog:** itself — `lib/threadline/semantics/audit_action.ex`

**Association to remove** (schema block, read live, line ~47):
```elixir
has_many(:transactions, Threadline.Capture.AuditTransaction, foreign_key: :action_id)
```
D-06: delete this line outright (no callers found). Nothing else in the file references it — `@required_fields`/`@optional_fields`/`changeset/2` are untouched.

---

### `lib/threadline/query.ex` (service, request-response) — hydrate helper + forced call sites + preload shim

**Analog:** itself — sibling private helper `storage_opts/2` (lines ~684-694) is the exact threading pattern the new hydrate helper must reuse; `preload_investigation_context/3` (lines ~104-109) is the first forced call site.

**Storage-opts threading pattern to copy verbatim** (read live, `lib/threadline/query.ex:684-694`):
```elixir
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
```

**Forced call site #1 — `preload_investigation_context/3`** (read live, `lib/threadline/query.ex:104-109`):
```elixir
@doc false
@spec preload_investigation_context([AuditChange.t()], module(), keyword()) :: [AuditChange.t()]
def preload_investigation_context(changes, repo, opts \\ [])
    when is_list(changes) and is_atom(repo) and is_list(opts) do
  repo.preload(changes, [transaction: :action], storage_opts([], opts))
end
```
This is the most natural first caller of the new hydrate helper (per RESEARCH.md Open Question 1): replace the body's `repo.preload(changes, [transaction: :action], ...)` with a call into the hidden helper that walks `changes -> .transaction -> .action`.

**Public `:preload` validation site #1 — `audit_transaction/2`** (read live, `lib/threadline/query.ex:122-137`):
```elixir
case Keyword.get(opts, :preload) do
  preloads when preloads in [nil, []] ->
    transaction

  preloads when is_list(preloads) or is_atom(preloads) ->
    repo.preload(transaction, preloads, storage_opts([], opts))

  other ->
    raise ArgumentError,
          ":preload must be nil, [], an atom, or a list, got: #{inspect(other)}"
end
```
This `case` is the template for the D-10 deprecation shim: add a branch (or pre-filter step) that extracts `:action`/`transaction: :action` out of `preloads`, warns once, delegates the remainder to `repo.preload/3` exactly as now, then calls the hydrate helper. A nested form (`[action: :x]`) must raise `ArgumentError` with a message naming the problem — same `raise ArgumentError` style as the `other ->` branch above.

**Public `:preload` validation site #2 — `audit_changes_for_transaction/2`** (read live, `lib/threadline/query.ex:613-621`):
```elixir
case Keyword.get(opts, :preload) do
  preloads when preloads in [nil, []] ->
    results

  preloads when is_list(preloads) ->
    repo.preload(results, preloads, storage_opts([], opts))

  other ->
    raise ArgumentError,
          ":preload must be nil, [], or a list, got: #{inspect(other)}"
end
```
Apply the identical extract-warn-delegate shim here. Note this branch does not accept a bare atom (`is_list(preloads)` only) — preserve that asymmetry, do not widen it while adding the shim.

**Error-handling pattern to reuse:** both `:preload` sites fail closed with `raise ArgumentError, "...got: #{inspect(other)}"` — the new nested-`:action` rejection must match this exact style (named problem + `inspect` of the offending value), not a generic Ecto error.

---

### `lib/threadline/investigation.ex` (service, request-response) — 3 forced call sites

**Analog:** itself — `transaction_context/2` and `incident_bundle/2`, read live (`lib/threadline/investigation.ex:120-180`)

**Call site D-09 #1 — inside `transaction_context/2`** (line ~132-134):
```elixir
changes =
  Query.audit_changes_for_transaction(
    transaction_id,
    Keyword.put(opts, :preload, transaction: :action)
  )
```

**Call site D-09 #2 and #3 — inside `incident_bundle/2`** (lines ~150-168):
```elixir
transaction_opts =
  opts
  |> Keyword.put(:preload, :action)
  |> Keyword.put(:surface, :transaction_header)
  |> Keyword.put(:params, %{transaction_id: transaction_id})

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
    ...
```
These three already pass `:preload` through the public `Query` functions above — once the D-10 shim lands in `query.ex`, these call sites keep working unchanged (they are themselves exercising the shim, not bypassing it) UNLESS D-09's intent is for `investigation.ex` to call the hidden helper directly instead of routing through the now-deprecated public `:preload` shape. Re-check D-09's wording against the shim: the plan should pick one — either `investigation.ex` switches to call the hidden helper directly (preferred, avoids tripping its own deprecation warning internally), or it continues through `:preload` and the warning is suppressed for internal callers. **Flag for planner:** this ambiguity is the one place CONTEXT.md's forced-call-site list (D-09) and the public shim (D-10) could collide — resolve by having internal call sites call the hidden helper directly, never the public deprecated `:preload` path.

**Downstream struct shape, unaffected:**
```elixir
%LinkedTransaction{
  transaction: transaction,
  action: linked_action(transaction),
  changes: linked_changes
}
```
`linked_action/1` presumably reads `transaction.action` — confirm it tolerates `nil` (was `%Ecto.Association.NotLoaded{}` before, D-07).

---

### `lib/threadline/operator_surface/live/timeline_live.ex` (component/LiveView, request-response)

**Analog:** itself — `preload_visible_context/3`, read live (`lib/threadline/operator_surface/live/timeline_live.ex:548-552`)

```elixir
defp preload_visible_context(%{entries: entries} = page, repo, opts) do
  %{
    page
    | entries: repo.preload(entries, [transaction: :action], StorageSchema.repo_opts(opts))
  }
end
```
D-09 forced call site: swap `repo.preload(entries, [transaction: :action], ...)` for a call into the hidden hydrate helper, threading `StorageSchema.repo_opts(opts)` through exactly as today. Markup (`.heex`) is untouched — this is a private function body only.

**Paired literal-source test to update in the same commit** (`test/threadline/operator_surface/live/timeline_live_test.exs:1197-1204`, read live):
```elixir
test "source contract: visible Timeline preloads pass selected storage opts" do
  source = File.read!("lib/threadline/operator_surface/live/timeline_live.ex")

  assert source =~ "preload_visible_context(socket.assigns.repo, scope_aware_opts(socket))"
  assert source =~ "defp preload_visible_context(%{entries: entries} = page, repo, opts)"

  assert source =~
           "repo.preload(entries, [transaction: :action], StorageSchema.repo_opts(opts))"
end
```
The third assertion's substring must change to match whatever call shape replaces the direct `repo.preload`.

---

### `lib/threadline/operator_surface/live/transaction_live.ex` (component/LiveView, request-response)

**Analog:** `timeline_live.ex`'s mount/opts pattern (role-match, same LiveView family)

**Current `mount/3`, forced call site D-09** (read live, `lib/threadline/operator_surface/live/transaction_live.ex:15-28`):
```elixir
def mount(%{"id" => id}, _session, socket) do
  repo =
    socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

  case Threadline.incident_bundle(id,
         repo: repo,
         preload: :action,
         scope: socket.assigns[:threadline_scope],
         scope_query_fn: socket.assigns[:threadline_scope_query_fn],
         surface: :transaction,
         params: %{transaction_id: id}
       ) do
    {:error, :not_found} ->
      {:ok, assign(socket, :not_found, true)}
    ...
```
This call goes through `Threadline.incident_bundle/2` → `Investigation.incident_bundle/2` → the `:preload` shim. Per the resolution flagged above, prefer leaving this call site exactly as-is (it is a public-API consumer, not an internal `query.ex`/`investigation.ex` site) OR update the `:preload` value if `incident_bundle/2` stops accepting it internally. No markup changes regardless (D-09 explicit).

---

### `lib/threadline.ex` (facade, request-response)

**Analog:** itself — moduledoc header (read live, lines 1-7) plus ~12 `Threadline.Query.*`/`Threadline.Investigation.*` doc references (D-03) to rewrite as `Threadline.*` or inline prose.

**Current facade header, pattern to preserve:**
```elixir
defmodule Threadline do
  @moduledoc """
  Audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL.

  Threadline combines trigger-backed row-change capture, rich action semantics
  (actor/intent/context), and operator-grade exploration.
  """

  alias Threadline.Investigation
  alias Threadline.Semantics.ActorRef
  alias Threadline.Semantics.AuditAction
  alias Threadline.StorageSchema
```
Add the one named escape-hatch mention per D-01/D-02 (`Threadline.Query.timeline_query/1` as inline code, not a link) somewhere in this moduledoc. Every other `Threadline.Query.*`/`Threadline.Investigation.*` mention in docstrings throughout this file becomes a facade `Threadline.*` reference or self-contained prose (D-03) — re-grep at execution time per D-11's note that line numbers drift.

---

### `mix.exs` (config, batch)

**Analog:** itself — `docs/0`, read live (`mix.exs` ~559-650)

**`groups_for_modules["Core API"]` entry to edit** (read live):
```elixir
groups_for_modules: [
  "Core API": [
    Threadline,
    Threadline.Audit,
    Threadline.ChangeDiff,
    Threadline.Continuity,
    Threadline.Evidence,
    Threadline.Export,
    Threadline.Health,
    Threadline.Investigation,
    Threadline.Job,
    Threadline.Plug,
    Threadline.Query,
    Threadline.Retention,
    Threadline.Telemetry
  ],
```
Remove `Threadline.Investigation` and `Threadline.Query` from this list (D-pitfall-1) in the same commit as the `@moduledoc false` addition. Their child structs (`Threadline.Query.ActorHistoryPage`, `Threadline.Query.TimelinePage`, `Threadline.Investigation.IncidentBundle`, `Threadline.Investigation.IncidentChange`, `Threadline.Investigation.LinkedChange`, `Threadline.Investigation.LinkedTransaction`) already live in the separate `"Data Types"` group — confirmed present there, leave untouched.

**`skip_code_autolink_to` addition (D-01):** no existing key of this name in `docs/0` — add it as a new top-level key in the list returned by `defp docs do`:
```elixir
skip_code_autolink_to: ["Threadline.Query.timeline_query/1"]
```

---

### `test/threadline/public_surface_contract_test.exs` (test, request-response)

**Analog:** itself — `@hidden_modules` list, read live (lines 1-13)

```elixir
@hidden_modules [
  Threadline.CriticTrust.Measure,
  Threadline.CriticTrust.RankMetrics,
  Threadline.CriticTrust.LedgerSplice,
  Threadline.CriticTrust.KrippendorffAlpha,
  Threadline.CriticTrust.RepositoryBoundary,
  Mix.Tasks.Critic.Measure,
  Mix.Tasks.Critic.Synth
]
```
D-02: append `Threadline.Query` and `Threadline.Investigation` to this list. Add a new test near the existing `docs_visibility/1`-based assertions that reads the `Threadline` moduledoc via `Code.fetch_docs(Threadline)` and asserts the text contains `"Threadline.Query.timeline_query/1"`.

---

### `test/threadline/facade_only_references_contract_test.exs` (NEW test, batch/file-scan)

**Analog:** `test/threadline/audit_indexing_doc_contract_test.exs` (read live, lines 1-9) — this repo's established doc-contract-test shape:

```elixir
defmodule Threadline.AuditIndexingDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end
```
Copy this `@repo_root` + `read_rel!/1` helper shape. Build the new file around:
- a regex pair per D-12 (backtick form and call form, `Threadline\.(Query|Investigation)\.[a-z_]\w*[!?]?...`)
- a file-glob scan over `guides/*.md`, `README.md`, `examples/threadline_phoenix/README.md`, example app `lib/**/*.{ex,heex}`, example app `priv/scripts/*.exs`
- an allowlist of exactly `timeline_query`
- an alias guard (bare `alias Threadline.Query`/`alias Threadline.Investigation`, excluding struct-group aliases like `alias Threadline.Investigation.{IncidentBundle, ...}`) that fails loudly
- a self-test fixture string proving the regex is non-vacuous (31 sibling `*_doc_contract_test.exs` files establish this convention — follow their `async: true`, `@moduledoc false` header exactly)

---

### `<new association-absence test>` (NEW test, request-response/introspection)

**Analog:** `test/threadline/public_surface_contract_test.exs`'s assertion-over-compiled-metadata style (`__schema__`/`fetch_docs` introspection pattern already used in that file)

No existing schema-association test file was found (RESEARCH.md Assumption A2) — place it at `test/threadline/capture/audit_transaction_test.exs` (or a dedicated `test/threadline/schema_boundary_test.exs` if neither schema has its own test file yet; check both `lib/threadline/capture/` and `lib/threadline/semantics/` for existing test coverage before deciding). Shape:
```elixir
test "AuditTransaction and AuditAction declare no cross-schema associations" do
  refute :action in Threadline.Capture.AuditTransaction.__schema__(:associations)
  refute :transactions in Threadline.Semantics.AuditAction.__schema__(:associations)
end
```
This is the D-13 mutation control: re-adding either `belongs_to`/`has_many` turns it red.

---

### `test/threadline/query_test.exs` (literal-source test, request-response)

**Analog:** itself — read live, lines 980-985:
```elixir
test "query preload call sites pass resolved storage options" do
  source = File.read!("lib/threadline/query.ex")

  assert source =~ "repo.preload(changes, [transaction: :action], storage_opts([], opts))"
  assert source =~ "repo.preload(transaction, preloads, storage_opts([], opts))"
  assert source =~ "repo.preload(results, preloads, storage_opts([], opts))"
end
```
Update the first assertion's substring to match the new hydrate-helper call shape inside `preload_investigation_context/3`. The second and third assertions (the `:preload` shim's `repo.preload` delegation for the non-`:action` remainder) likely stay valid if the shim still calls `repo.preload(transaction, preloads, storage_opts([], opts))` for whatever remains after extracting `:action` — verify against the actual shim implementation before assuming no change needed.

---

## Shared Patterns

### Storage-schema-prefix threading
**Source:** `lib/threadline/query.ex:684-694` (`storage_opts/2`) and `lib/threadline/operator_surface/live/timeline_live.ex:547` (`StorageSchema.repo_opts(opts)`)
**Apply to:** the new hydrate helper (D-08 mandates this), both `:preload` shim branches, and both forced LiveView call sites.
```elixir
def storage_opts(filters \\ [], opts \\ []) do
  StorageSchema.repo_opts(storage_schema_opts(filters, opts))
end
```

### Fail-closed `:preload`/option validation
**Source:** `lib/threadline/query.ex:122-137` and `:613-621`
**Apply to:** the D-10 nested-`:action` rejection — raise `ArgumentError` naming the problem, same style as the existing `other -> raise ArgumentError, "...got: #{inspect(other)}"` branches. Do not let a malformed shape fall through to a raw `repo.preload/3` call.

### `@moduledoc false` to hide a module while keeping it fully compiled/tested/callable
**Source:** `lib/threadline/critic_trust/measure.ex:1-2`
```elixir
defmodule Threadline.CriticTrust.Measure do
  @moduledoc false
```
**Apply to:** `Threadline.Query` and `Threadline.Investigation` module heads (D-01). Pair every such change with removal from `mix.exs`'s `groups_for_modules` and addition to `test/threadline/public_surface_contract_test.exs`'s `@hidden_modules` — three files move together or `public_surface_contract_test.exs`'s "every visible module belongs to exactly one group" test goes red.

### Doc-contract test file shape
**Source:** `test/threadline/audit_indexing_doc_contract_test.exs:1-9`
**Apply to:** the new `facade_only_references_contract_test.exs` — same `@repo_root`/`read_rel!/1` helper, same `async: true`, same `@moduledoc false` header convention shared by the 31 sibling doc-contract test files.

## No Analog Found

None — every file in scope has a same-file (self-modify) or closely related sibling analog already identified above. This phase is a closed-world refactor with no net-new architectural shape.

## Metadata

**Analog search scope:** `lib/threadline/`, `lib/threadline/capture/`, `lib/threadline/semantics/`, `lib/threadline/operator_surface/live/`, `test/threadline/`, `mix.exs`, `guides/`, `examples/threadline_phoenix/`
**Files scanned:** 15 target files + 3 reference analogs (`critic_trust/measure.ex`, `audit_indexing_doc_contract_test.exs`, `public_surface_contract_test.exs`'s existing patterns)
**Pattern extraction date:** 2026-10-03
**Tracked-source gate:** all paths above verified via `git ls-files` — no gitignored mirror paths were named; all are tracked source under the main working tree.
