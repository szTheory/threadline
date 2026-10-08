# Phase 233: Lookup Return Shapes - Research

**Researched:** 2026-10-03
**Domain:** Elixir/Ecto single-subject lookup return-shape unification + fail-closed scoping
**Confidence:** HIGH

## Summary

Phase 233 is a pure in-repo refactor with no new external dependencies: unify three
single-subject lookups (`audit_transaction/2`, `transaction_context/2`, `incident_bundle/2`)
onto `{:ok, _} | {:error, :not_found}` plus `!` siblings, back them with one shared hidden
fetch, tighten the option allowlist, and make `Threadline.Query.Scope.apply/2` fail closed
instead of silently unscoped. All decisions (D-01..D-22) are locked in `233-CONTEXT.md`; this
research verifies the exact code shapes the context cites, enumerates every caller that must
change, and maps each success criterion / D-22 test requirement to concrete test files and
commands.

Every line number CONTEXT.md cites was re-read this session and confirmed current (query.ex,
investigation.ex, scope.ex, action_hydration.ex, transaction_live.ex, the example app, and the
retention/capture-migration cross-references). One blast-radius item not named in CONTEXT.md
was found: `test/threadline/query/action_hydration_test.exs:352` calls
`Threadline.incident_bundle/2` with explicit `surface:`/`params:` opts that D-13 forbids — this
call must also be rewritten (see Pitfall 1).

**Primary recommendation:** Build the shared hidden fetch first (row-then-changes, surfaces per
D-10, `[:repo, :storage_schema, :scope, :scope_query_fn]` allowlist), then layer the three
facade lookups and their bangs and `NotFoundError` on top, then migrate every caller found in
the blast-radius grep below in the same change, then land `Scope.apply` fail-closed last (it is
independently reversible-risk and touches every scoped read, so isolating it limits blast
radius if something regresses).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Shared existence fetch (row + changes, two scope surfaces) | API / Backend (`Threadline.Query`/`Threadline.Investigation`) | — | Pure Ecto read composition; no capture-layer or browser involvement |
| `audit_transaction/2`/`!`, `transaction_context/2`/`!`, `incident_bundle/2`/`!` facade functions | API / Backend (`Threadline` facade) | — | Exploration-layer read API per the three-layer architecture; the facade is the one public surface (API-04) |
| `Threadline.NotFoundError` + `Plug.Exception` impl | API / Backend | Frontend Server (SSR via Phoenix/Plug) | Raised in the backend, but its `status/1 -> 404` is consumed by `FallbackController`/Plug error handling, which lives at the SSR boundary |
| `Scope.apply/2` fail-closed | API / Backend | — | Pure query-composition guard; every scoped read (timeline, actor, transaction, export, operator-surface mounts) routes through it |
| `TransactionLive` not-found render | Frontend Server (LiveView) | — | Consumes the `{:error, :not_found}` tuple; no new backend logic, just branch handling |
| Example app controller/router scope fn | Frontend Server (SSR, reference app) | — | Demonstrates the `:transaction_header` surface clause; already present (see Pitfall 4) |

## Standard Stack

No new dependencies. `:plug` is already a required (non-optional) runtime dependency
[VERIFIED: mix.exs:95 — `{:plug, "~> 1.15"},`], which is what lets `Threadline.NotFoundError`
implement `Plug.Exception` unconditionally per D-17.

### Alternatives Considered
All "alternatives" here are pre-decided in CONTEXT.md (D-01 `fetch_*` naming, D-16 exception
struct in tuple, D-17 `Ecto.NoResultsError`) — no open alternatives remain for this phase.

**Installation:** none — no new packages.

## Package Legitimacy Audit

Not applicable. This phase installs no external packages.

## Architecture Patterns

### System Architecture Diagram

```
Caller (facade)
  Threadline.audit_transaction(id, opts)         Threadline.transaction_context(id, opts)      Threadline.incident_bundle(id, opts)
  Threadline.audit_transaction!(id, opts)        Threadline.transaction_context!(id, opts)     Threadline.incident_bundle!(id, opts)
        |                                               |                                               |
        v                                               v                                               v
  [opts allowlist: repo/storage_schema/scope/scope_query_fn -- unknown key -> ArgumentError]
        |                                               |                                               |
        +------------------------>  SHARED HIDDEN FETCH (new; Query or Investigation)  <----------------+
                                           |
                                 1. validate id (UUID or non-binary -> ArgumentError;
                                    malformed-but-binary -> treat as not-found, D-18)
                                 2. SELECT audit_transactions WHERE id == uuid
                                      |> Scope.apply(surface: :transaction_header, params: %{transaction_id: id})
                                 3. row nil or scope-rejected -> :not_found
                                 4. row found -> SELECT audit_changes WHERE transaction_id == uuid
                                      |> Scope.apply(surface: :transaction, params: %{transaction_id: id})
                                 5. hydrate_actions/3 on the row (reused for every change's
                                    .transaction field per D-11 -- no second hydration pass)
                                           |
                                           v
                              {:ok, row, changes} | :not_found  (internal shape, Claude's discretion)
        |                                               |                                               |
        v                                               v                                               v
  {:ok, %AuditTransaction{}}                  {:ok, %LinkedTransaction{}}                    {:ok, %IncidentBundle{}}
  | {:error, :not_found}                      | {:error, :not_found}                         | {:error, :not_found}
        |                                               |                                               |
        v (bang wraps: {:ok,v}->v; {:error,:not_found}->raise NotFoundError)
  TransactionLive.mount/3  --------------------------------------------------------------- consumes {:ok,_}|{:error,:not_found}
  example app controller   --------------------------------------------------------------- consumes {:ok,_}|{:error,:not_found}
  mix threadline.incident   -------------------------------------------------------------- consumes {:ok,_}|{:error,:not_found}

Threadline.Query.audit_transaction/2 (deprecated, kept) -> nil | AuditTransaction.t(), delegates
  onto the shared hidden fetch, converts {:ok,row}->row / :not_found->nil, keeps :preload.
```

### Recommended Project Structure

No new top-level modules required beyond what D-17/D-10 name. Likely file additions:

```
lib/threadline/
├── not_found_error.ex          # Threadline.NotFoundError + Plug.Exception impl (new, public)
├── investigation.ex            # transaction_context/2, incident_bundle/2 -- call shared fetch
├── query.ex                    # audit_transaction/2 (deprecated delegate), shared fetch lives here or in investigation.ex (discretion)
├── threadline.ex               # facade: audit_transaction/2!, transaction_context/2!, incident_bundle/2!
└── operator_surface/live/transaction_live.ex   # drop surface:/params:, handle malformed id

test/threadline/
├── lookup_return_shapes_contract_test.exs   # D-05 doc-contract test (suggested name; discretion)
├── not_found_error_test.exs                 # Plug.Exception, message shape
├── investigation_test.exs                   # existing file, present/not-found cases extended
├── query_test.exs                           # existing file, parity/deprecation assertions extended
├── query/action_hydration_test.exs          # existing, update tuple-returning callers
├── query/scope_fail_closed_test.exs         # D-20 fail-closed coverage (suggested name)
└── operator_surface/transaction_live_test.exs  # not-found render for /transactions/not-a-uuid
```

### Pattern 1: Per-function option allowlist (no NimbleOptions)

**What:** Each public function validates its own `opts` keyword list against a fixed list of
atoms, raising `ArgumentError` naming the bad key and the allowed set.
**When to use:** Every option-accepting Threadline function, per the project's locked
"no NimbleOptions" decision.
**Example (existing precedent to copy, not invent):**
```elixir
# Source: lib/threadline/investigation.ex:223-232 (read this session)
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
For the three lookups, the allowed set is `[:repo, :storage_schema, :scope, :scope_query_fn]`
per D-13 — `:surface`, `:params`, `:preload` must be rejected with this same style, not silently
dropped or honored.

### Pattern 2: Row-first existence check, scope-rejected = not-found

**What:** Look up the parent row under scope first; only query children if the row exists and
passed scope.
**When to use:** This is already `incident_bundle/2`'s structure — the template for the new
shared fetch.
**Example:**
```elixir
# Source: lib/threadline/investigation.ex:186-221 (read this session, current incident_bundle/2)
def incident_bundle(transaction_id, opts \\ []) do
  repo = Keyword.fetch!(opts, :repo)
  internal_opts = Keyword.delete(opts, :preload)

  transaction_opts =
    internal_opts
    |> Keyword.put(:surface, :transaction_header)
    |> Keyword.put(:params, %{transaction_id: transaction_id})

  case Query.audit_transaction(transaction_id, transaction_opts) do
    nil -> {:error, :not_found}
    transaction -> # ... fetch changes, build bundle
  end
end
```
Note: today only `incident_bundle/2` overrides `:surface` to `:transaction_header`; the bare
`Query.audit_transaction/2` defaults to `surface: :transaction` on a single-`[at]`-binding query
[VERIFIED: lib/threadline/query.ex:687-694 — `transaction_scope_opts/2` defaults
`surface: Keyword.get(opts, :surface, :transaction)`]. D-10 fixes this latent bug by making the
shared fetch always use `:transaction_header` for the row and `:transaction` for the changes,
not leaving it to per-caller overrides.

### Pattern 3: Query-count assertion via repo telemetry

**What:** Assert an operation issues at most N SQL queries by attaching to the repo's
`[:repo, :query]` telemetry event and counting fires.
**When to use:** D-11/D-22's "incident_bundle query count is ≤ 3" requirement.
**Example (existing precedent, read this session):**
```elixir
# Source: test/threadline/query/action_hydration_test.exs:17-18 (read this session)
alias Threadline.Test.Repo
@query_event Keyword.fetch!(Repo.config(), :telemetry_prefix) ++ [:query]
```
Combine with `Threadline.TelemetryHelpers.attach_telemetry!/1` (imported the same way in
`test/threadline/telemetry_registry_contract_test.exs:20` and
`action_hydration_test.exs:10`) and count events fired during one call to `incident_bundle/2`.

### Pattern 4: Deprecation inventory pinning + parity test

**What:** Pin the exact `{name, arity}` + message set returned by `Module.__info__(:deprecated)`
for every module with deprecated public functions, and a parity test proving the deprecated
delegate's behavior equals the replacement's.
**When to use:** D-06's `Threadline.Query.audit_transaction/2` deprecation.
**Example (existing precedent, read this session):**
```elixir
# Source: test/threadline/deprecation_parity_test.exs:237, 463-468 (read this session)
test "Threadline.__info__(:deprecated) names {:history, 3} with the exact message" do
  # ...
end

test "Threadline.Query.__info__(:deprecated) equals the exact expected inventory" do
  assert Enum.sort(Threadline.Query.__info__(:deprecated)) == Enum.sort(@query_deprecated)
end
```
This file reaches every deprecated name only through `apply/3` so its own compilation never
warns — copy that technique for the new `{:audit_transaction, 2}` entry on `Threadline.Query`.

### Anti-Patterns to Avoid

- **Changing `Query.audit_transaction/2`'s shape in place:** D-06 explicitly rejects this —
  `nil` → tuple is silently truthy (`if txn = Query.audit_transaction(...)` becomes always-true),
  so the deprecated name must keep returning `nil | AuditTransaction.t()` and only the *new*
  facade name gets the tuple.
- **Letting a caller's `:surface` override win:** today `transaction_context` silently drops
  `:preload` and honors a caller-supplied `:surface`, while `incident_bundle` overwrites
  `:surface`. Both behaviors go away under D-13 — the allowlist must raise on `:surface` from
  *any* caller, not special-case which function currently honors it.
- **Rescuing a bad `:storage_schema` into `:not_found`:** D-15 requires the Postgrex
  `undefined_table` error and the `ArgumentError` from `Threadline.StorageSchema` to stay loud.
  Do not wrap the shared fetch's repo calls in a blanket `rescue`.
- **Wrapping the two reads (row, then changes) in a DB transaction or `REPEATABLE READ`:** D-12
  explicitly accepts two independent READ COMMITTED reads as "point-in-time per query."

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Validating a UUID-shaped id | A custom regex/format check | `Ecto.UUID.cast/1`, already used at `lib/threadline/query.ex:586-595` | It is the existing, tested validator; D-18 only changes *what happens* on `:error` (return `:not_found` instead of raising), not the cast mechanism |
| 404 status mapping for a custom exception | A Plug error-view rescue clause per adopter | `defimpl Plug.Exception, for: Threadline.NotFoundError do def status(_), do: 404 end` | Plug's own exception protocol is the idiomatic hook `Phoenix.Endpoint`/`Plug.ErrorHandler` and `phx.gen.json`'s `FallbackController` already understand |
| Counting queries in a test | Manual `Ecto.Adapters.SQL.Sandbox` introspection or log-scraping | repo `[:repo, :query]` telemetry + `attach_telemetry!/1` | Established in-repo pattern (Pattern 3 above); avoids parsing SQL logs |

**Key insight:** every mechanism this phase needs (UUID casting, telemetry-based query
counting, per-function opts allowlists, deprecation-inventory pinning, doc-contract scanning)
already exists in this codebase. The work is composition and migration, not new library choices.

## Runtime State Inventory

Not applicable — this is a return-shape/behavior phase, not a rename/rebrand/migration phase.
No stored data, service config, OS-registered state, or build artifacts carry the old shapes;
only in-process function contracts change.

## Common Pitfalls

### Pitfall 1: An uncited blast-radius caller passes the now-forbidden `:surface`/`:params`

**What goes wrong:** `test/threadline/query/action_hydration_test.exs:352` calls
`Threadline.incident_bundle/2` with explicit `surface: :transaction, params: %{transaction_id:
txn.id}` [VERIFIED: test/threadline/query/action_hydration_test.exs:349-357 — read this
session; exact text: `Threadline.incident_bundle(txn.id, repo: @repo, scope: nil,
scope_query_fn: nil, surface: :transaction, params: %{transaction_id: txn.id})`]. This call is
NOT in CONTEXT.md's D-21 list of cited call sites, but under D-13 it will raise `ArgumentError`
once the allowlist lands.
**Why it happens:** D-21's grep instruction ("before any change, grep guides, the README and
the example app for transaction_context, audit_transaction and the removed option keys") names
guides/README/example app explicitly but the full blast-radius grep in this research also
caught a `test/` file passing the removed keys directly.
**How to avoid:** Grep `test/` (not just guides/README/example) for `surface:` and `params:` in
the same call expression as `incident_bundle`/`transaction_context`/`audit_transaction` before
starting Plan 2/3, and fix every hit alongside the cited ones.
**Warning signs:** `mix test` failing on this file with `** (ArgumentError) unknown option key
:surface` after the allowlist lands.

### Pitfall 2: `TransactionLive.mount/3` currently passes `surface:`/`params:` too

**What goes wrong:** `lib/threadline/operator_surface/live/transaction_live.ex:20-26` calls
`Threadline.incident_bundle(id, repo: repo, scope: ..., scope_query_fn: ..., surface:
:transaction, params: %{transaction_id: id})` [VERIFIED: lib/threadline/operator_surface/live/transaction_live.ex:20-26
— read this session]. This is explicitly named in D-13 ("stops passing surface:/params:") so it
is not a surprise, but it is easy to miss that the *shared fetch itself* must now compute
`:transaction`/`:transaction_header` internally (per D-10) rather than relying on this call site
to supply the right surface — removing the caller's override must not silently fall back to the
old buggy default (`:transaction` on the single-binding row query, which fails at normalize for
a two-binding scope fn, per D-10's bug description).
**Why it happens:** the fix is two changes at once (remove caller override AND fix the
internal default) — doing only the removal without fixing the shared fetch's internal surface
choice would silently reintroduce the `unknown_binding_1!` failure D-10 describes.
**How to avoid:** implement the shared fetch's hardcoded two-surface behavior (D-10) *before*
stripping `transaction_live.ex`'s override, and add a test with a two-binding
`scope_query_fn` matching D-22's "scope fn keyed only on `:transaction_header` with an `[at]`
binding works on the facade `audit_transaction`" requirement.
**Warning signs:** `TransactionLive` mount raising `unknown_binding_1!` instead of rendering a
page, once a scope fn with a two-binding clause is configured.

### Pitfall 3: `incident_bundle!/2`'s bang wrapper must not accidentally double-raise on malformed ids

**What goes wrong:** D-18 requires a malformed (non-UUID, but binary) id to return
`{:error, :not_found}` from all three plain lookups and raise `NotFoundError` (not
`ArgumentError`) from all three bangs — but a non-binary id (`nil`, an integer) must still raise
`ArgumentError`. If the shared fetch's id validation and the bang wrapper's
`case f(id, opts) do {:ok,v}->v; {:error,:not_found}-> raise ... end` pattern are not kept
strictly separate (cast-error → `:not_found` tuple; non-binary → `ArgumentError` raised directly,
never reaching the tuple stage), a bang call on a malformed string could surface the wrong
exception type.
**Why it happens:** `Ecto.UUID.cast/1` returns `:error` for both "not a valid UUID string" and
is never called at all for non-binaries if a `is_binary` guard runs first — the two failure
modes must be distinguished *before* calling `Ecto.UUID.cast/1`, not after.
**How to avoid:** validate `is_binary(id)` first (raise `ArgumentError` immediately if not),
then `Ecto.UUID.cast/1` on the binary (map `:error` to the internal not-found path, not an
exception).
**Warning signs:** D-22's required test "`\"garbage\"` -> `:not_found`, while `nil`/`123` raise
`ArgumentError`, in both forms" failing on the bang path specifically.

### Pitfall 4: The example app's scope fn already has a `:transaction_header` clause — do not assume it needs the fix D-20 warns about

**What goes wrong:** D-20's CONTEXT text warns generically about "the risk that an adopter
`scope_query_fn` with no `:transaction_header` clause falls into its own catch-all and returns
another tenant's row," and asks to "update
`examples/threadline_phoenix/.../router.ex` (~157-168) if its catch-all is permissive."
Investigation this session found the example app's `scope_operator_query/3` **already has** a
dedicated `:transaction_header` clause [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:157-159
— read this session; exact text: `def scope_operator_query(query, %{organization_id: org_id},
%{surface: :transaction_header}) when is_binary(org_id) and org_id != "" do where(query, [at],
fragment("?->>'organization_id' = ?", at.meta, ^org_id)) end`]. The final catch-all clause at
line ~166 (`def scope_operator_query(query, _scope, _context), do: query`) is unscoped by
design (it is the host's own permissive fallback, not a Threadline bug), and is unrelated to the
`:transaction_header` binding risk.
**Why it happens:** the example app already incorporates an earlier round of this exact fix; a
planner reading only the CONTEXT prose (not the live file) could over-scope a task to "fix the
example router's catch-all" when the specific risk D-20 names is already mitigated there.
**How to avoid:** confirm during planning that the only required example-app change is
documentation (`guides/integration-contracts.md`'s `:transaction_header` surface mention), not a
router code change — unless the plan author independently decides the catch-all itself should
also be tightened for defense in depth (out of scope per D-20's own wording, which frames the
catch-all risk as the adopter's to manage).
**Warning signs:** a plan task that edits the example router when the actual gap is only in
`guides/integration-contracts.md`'s prose.

### Pitfall 5: `AuditTransaction` cascade delete means retention empties rows, not removes them, under `delete_empty_transactions: false`

**What goes wrong:** D-09/D-22 require a test for "an existing zero-change transaction... via
retention with `delete_empty_transactions: false`." Confirm the setting's effect:
[VERIFIED: lib/threadline/retention/policy.ex:54-61 — read this session; exact text:
`delete_empty_transactions = boolean_opt!(Map.get(opts, :delete_empty_transactions, Map.get(opts, "delete_empty_transactions", true)), ":delete_empty_transactions")`]
— the default is `true` (delete empty transactions), so the test must explicitly configure
`false` to produce a transaction row with zero changes that retention has deliberately left
behind. Separately, the changes table cascades on transaction delete:
[VERIFIED: lib/threadline/capture/migration.ex:43 — read this session; exact text:
`transaction_id uuid        NOT NULL REFERENCES #{audit_transactions}(id) ON DELETE CASCADE,`]
— this is the D-12 justification for accepting two independent reads (deleting the row cascades
its changes, producing a harmless "row plus `[]`" race outcome, never an orphaned-changes
outcome).
**Why it happens:** easy to build the zero-change-transaction fixture via direct insert only,
and skip the "via retention" variant D-22 explicitly requires as a separate case.
**How to avoid:** write both fixtures: (a) direct insert of a transaction row with no matching
change rows, and (b) insert transaction+change, run `Threadline.Retention` with
`delete_empty_transactions: false` after making the change itself eligible for deletion (so the
change is purged but the transaction is deliberately kept), then confirm the lookup still
returns `{:ok, %{changes: []}}`.
**Warning signs:** a plan with only one zero-change fixture, silently missing the retention
variant D-22 names explicitly.

## Code Examples

### Verified current `Query.audit_transaction/2` (the function D-06 deprecates in place)

```elixir
# Source: lib/threadline/query.ex:72-108 (read this session, line numbers confirmed current)
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
    # ... :action preload extraction, see action_hydration.ex
  end
end
```

### Verified current `Scope.apply/2` (the fail-open function D-20 fixes)

```elixir
# Source: lib/threadline/query/scope.ex:1-25 (full file, read this session)
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
D-20's fail-closed rewrite must distinguish three cases instead of the current two:
(1) no `:scope` and no `:scope_query_fn` → unscoped (opt-in stays opt-in);
(2) `:scope` with no arity-3 `:scope_query_fn` → `raise ArgumentError` (currently falls through
silently at the `true -> query` branch when `scope_query_fn` is non-nil but wrong arity, or at
the `is_nil(scope_query_fn)` branch when it's nil);
(3) `:scope_query_fn` with no `:scope` → recommendation is also raise (currently silently
unscoped via `is_nil(scope)`).

### Full blast-radius grep results (callers of the three lookups and `:surface`/`:params`)

```
# Source: ripgrep over lib/, test/, guides/, README.md, examples/ (run this session)

transaction_context — lib/threadline.ex:13,370-371,400; lib/threadline/investigation.ex:161;
  lib/threadline/capture/audit_transaction.ex:34 (doc only);
  lib/threadline/query/action_hydration.ex:169 (doc only);
  test/threadline/getting_started_saas_doc_contract_test.exs:105 (doc-contract, text match only);
  test/threadline/investigation_test.exs:413,450,459,474,488;
  test/threadline/storage_schema_integration_test.exs:121;
  test/threadline/exploration_routing_doc_contract_test.exs:18 (doc-contract, text match only);
  test/threadline/query_test.exs:1610,1647;
  test/threadline/query/action_hydration_test.exs:338;
  guides/getting-started-saas.md:279; guides/domain-reference.md:332

audit_transaction( — lib/threadline/query.ex:77-78; lib/threadline/investigation.ex:195;
  test/threadline/query/action_hydration_test.exs:217,231,281,365 (call Query.audit_transaction
    directly — these stay on the deprecated nil-returning shape, NOT migrated to the new tuple
    shape, since they are testing the deprecated delegate itself);
  guides/code-walkthrough.md:375 (quotes `Query.audit_transaction` — D-21 cites this)

incident_bundle — lib/threadline.ex:13,381-382; lib/threadline/investigation.ex:186;
  lib/threadline/operator_surface/live/transaction_live.ex:20;
  lib/mix/tasks/threadline.incident.ex:49 (already matches {:ok,_}/{:error,:not_found} — no
    change needed, confirm during planning);
  test/threadline/investigation_test.exs:497,526,550,558;
  test/threadline/query_test.exs:1610,1650;
  test/threadline/query/action_hydration_test.exs:332,349-357 (⚠ passes surface:/params:, see
    Pitfall 1);
  test/threadline/operator_surface/transaction_live_test.exs:116 (comment only);
  guides/incident-playbook.md:206; guides/operator-surface.md:245;
  guides/getting-started-saas.md:261,288; guides/domain-reference.md:295,296,328;
  examples/threadline_phoenix/README.md:69;
  examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex:29
    (already matches {:ok,_}/{:error,:not_found} — no change needed);
  guides/how-threadline-works.md:224,321,330; guides/code-walkthrough.md:368,373

Scope.apply / maybe_apply_scope callers (D-20 blast radius, every scoped read):
  lib/threadline/export.ex:212,218; lib/threadline/query.ex:85,247,291,354,434,506,559,628,640-642;
  lib/threadline/query/row_reads.ex:106
  (covers: audit_transaction, timeline, timeline_page, row history paths (both old+new),
   actor_history, audit_changes_for_transaction, timeline for export)

Tests with `scope:` present (candidates for new fail-closed assertions or regressions):
  test/threadline/row_history_test.exs, upgrade_path_doc_contract_test.exs,
  storage_schema_call_site_contract_test.exs, investigation_test.exs,
  exploration_routing_doc_contract_test.exs, evidence_test.exs,
  ci_token_permissions_contract_test.exs, query_test.exs,
  facade_only_references_contract_test.exs, capture/redaction_leak_property_test.exs,
  operator_surface/row_history_component_test.exs,
  integrations/phx_gen_auth_integration_test.exs, query/action_hydration_test.exs,
  integrations/sigra_test.exs
  — each must be checked for a `:scope` passed without an arity-3 `:scope_query_fn` (or
  vice versa); such a test would currently pass silently-unscoped and must be updated to
  either supply both or assert the new ArgumentError.
```

### Example app call sites already correct (no change needed)

```elixir
# Source: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex:29-35
# (read this session — already matches the target tuple shape)
case Threadline.incident_bundle(uuid, repo: Repo) do
  {:ok, bundle} ->
    render(conn, :show, bundle: bundle)

  {:error, :not_found} ->
    conn
    |> put_status(:not_found)
    |> json(%{errors: %{detail: "audit transaction not found"}})
end
```

```elixir
# Source: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:157-159
# (read this session — the :transaction_header clause D-20 asks to protect already exists)
def scope_operator_query(query, %{organization_id: org_id}, %{surface: :transaction_header})
    when is_binary(org_id) and org_id != "" do
  where(query, [at], fragment("?->>'organization_id' = ?", at.meta, ^org_id))
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `transaction_context/2` derives the transaction from its *changes* (so a zero-change transaction looks missing) | `transaction_context/2` and `incident_bundle/2` resolve the row first via the shared hidden fetch (D-09) | This phase | A real transaction with zero changes (e.g. `delete_empty_transactions: false`, or a scope that filters every change) now correctly returns `{:ok, %{changes: []}}` instead of looking not-found |
| `transaction_scope_opts/2` defaults to `surface: :transaction` on a single-`[at]`-binding query (latent bug, hidden only by `incident_bundle`'s override) | Shared fetch always uses `:transaction_header` for the row query, `:transaction` for the changes query (D-10) | This phase | A two-binding scope fn used on the bare row lookup stops failing with `unknown_binding_1!` |
| `Scope.apply/2` fails open: misconfigured scope (missing/wrong-arity `scope_query_fn`) silently returns the unscoped query | `Scope.apply/2` fails closed: `:scope` without a valid `scope_query_fn` raises `ArgumentError` (D-20) | This phase | Closes a cross-tenant data leak in every scoped read; also a documented breaking change |

**Deprecated/outdated:**
- `Threadline.Query.audit_transaction/2`'s `nil`-returning contract: deprecated in place (D-06),
  kept functioning through the 1.x line, removal no earlier than 2.0.
- `:preload` on all three lookups: rejected outright (not deprecated — a new, loud break per
  D-13), because an unbounded `repo.preload(:changes)` on the row is a correctness hazard, not
  a style choice.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The shared hidden fetch's internal tuple shape (`{:ok, txn, changes} \| :not_found`, as CONTEXT.md sketches) is the best internal representation, versus e.g. a 2-tuple with a map | Architecture Patterns / Architectural Responsibility Map | Low — CONTEXT.md explicitly leaves this to Claude's discretion; any internal shape satisfies the external contract |
| A2 | `mix threadline.incident` (lib/mix/tasks/threadline.incident.ex:49) and the example controller need no code change because they already match `{:ok,_}/{:error,:not_found}` | Code Examples | Low-medium — confirmed by reading both files this session; if `incident_bundle/2`'s *tuple shape itself* is unchanged (D-16 keeps the bare atom `:not_found`), these sites are unaffected by Phase 233; only `transaction_context`/`audit_transaction` change shape |
| A3 | No telemetry assertions are needed for the new lookups beyond the existing query-count check, per D-19 ("No telemetry on not-found") | Pattern 3 / Validation Architecture | Low — D-19 is an explicit locked decision |

**If this table is empty:** N/A — see rows above. All three are low-risk discretion/confirmation
notes, not load-bearing unverified claims; no user confirmation checkpoint is required beyond
what CONTEXT.md already resolved.

## Open Questions (RESOLVED)

1. **Where should the shared hidden fetch live — `Query` or `Investigation`?**
   - What we know: CONTEXT.md leaves this to Claude's discretion. `Query` currently owns
     `audit_transaction/2` and scope-opts helpers; `Investigation` currently owns
     `transaction_context/2`/`incident_bundle/2` and `LinkedTransaction`/`IncidentBundle`
     construction.
   - What's unclear: whether putting it in `Query` (closer to the raw Ecto composition) or
     `Investigation` (closer to the three call sites that need it) minimizes churn.
   - Recommendation: place it in `Query` as a `@doc false` function (e.g.
     `Query.fetch_transaction_with_changes/2`), since `Query.audit_transaction/2`'s deprecated
     delegate also needs to call it directly, and `Query` is already the lower layer
     `Investigation` depends on (avoids a new `Investigation -> Query -> Investigation` cycle).
   - RESOLVED: a new hidden module `Threadline.Query.TransactionLookup` (Plan 233-01); `query.ex` is near the 800-line source-size cap.

2. **Does the new facade `audit_transaction/2`'s `@doc` need to warn that it hydrates `.action`
   unconditionally (D-14), given the deprecated `Query.audit_transaction/2` only hydrates on
   explicit `preload: :action`?**
   - What we know: D-14 locks the behavior (always hydrate, 0 extra queries when `action_id` is
     nil per `action_hydration.ex:79`).
   - What's unclear: whether adopters relying on the deprecated name's *lack* of hydration (to
     avoid the 1-query cost when `action_id` is set) need a CHANGELOG callout beyond the
     breaking-change entry already planned for `transaction_context/2`'s shape change.
   - Recommendation: no separate CHANGELOG line needed — `audit_transaction/2` is a brand-new
     facade name (not a changed existing one), so its always-hydrate behavior is simply what the
     new function documents from day one; D-06's merged Deprecations entry for the *old*
     `Query.audit_transaction/2` already covers the `:preload :action` compat path.
   - RESOLVED: no separate CHANGELOG line; the new name documents always-hydrate from day one (Plan 233-03).

## Environment Availability

Skipped — this phase has no external tool/service dependencies beyond the already-configured
local Postgres test database and existing Elixir/Ecto toolchain, both already in active use by
every other phase in this milestone.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (ships with Elixir 1.15, per `mix.exs`) |
| Config file | `test/test_helper.exs`; partition weights `test/partition_weights.txt` |
| Quick run command | `mix test test/threadline/investigation_test.exs test/threadline/query_test.exs test/threadline/query/action_hydration_test.exs test/threadline/deprecation_parity_test.exs` |
| Full suite command | `mix ci.all` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| API-06 / SC1 | `audit_transaction/2`, `transaction_context/2` return `{:ok,_}`/`{:error,:not_found}` matching `incident_bundle/2`; both cases tested | unit | `mix test test/threadline/investigation_test.exs` | ✅ (extend existing file) |
| API-06 / SC2 | `audit_transaction!/2`, `transaction_context!/2` return bare value or raise; both cases tested | unit | `mix test test/threadline/investigation_test.exs` (or a new `not_found_error_test.exs`) | ❌ Wave 0 — new describe blocks / new file |
| API-06 / SC3 | Every internal caller migrated; CHANGELOG records it; `mix ci.all` green | integration/contract | `mix compile --warnings-as-errors && mix ci.all` | ✅ (existing contract tests: `facade_only_references_contract_test.exs`, `deprecation_parity_test.exs`, `public_surface_contract_test.exs`) |
| D-02 | `incident_bundle!/2` exists, raises | unit | `mix test test/threadline/investigation_test.exs` | ❌ new test |
| D-05 | Doc-contract: `name/2`+`name!/2` exported, `@doc` shapes, reverse-drift, `as_of/4` exemption | contract | new file, e.g. `mix test test/threadline/lookup_return_shapes_contract_test.exs` | ❌ Wave 0 |
| D-06 | `Query.audit_transaction/2` parity (nil↔error, t↔ok, :preload), `__info__(:deprecated)` entry + mutation control | unit/contract | `mix test test/threadline/deprecation_parity_test.exs test/threadline/query/action_hydration_test.exs` | ✅ extend existing |
| D-09/D-22 | Existing zero-change transaction (direct insert AND via retention `delete_empty_transactions: false`) | integration | `mix test test/threadline/investigation_test.exs` | ❌ new cases, see Pitfall 5 |
| D-10/D-22 | Two-binding scope fn on `:transaction_header` works on facade `audit_transaction` | integration | new or extended test | ❌ |
| D-11/D-22 | `incident_bundle` query count ≤ 3 via telemetry | integration | `mix test test/threadline/query/action_hydration_test.exs` (telemetry pattern already present) | ❌ new assertion, pattern exists |
| D-13/D-22 | Unknown keys (`:surface`,`:params`,`:preload`) raise on all three, both forms | unit | new tests per function | ❌ |
| D-14/D-22 | Facade `audit_transaction` hydrates `.action` | unit | new test | ❌ |
| D-17/D-22 | `Plug.Exception.status(%NotFoundError{}) == 404`; message has id, no column values | unit | new `not_found_error_test.exs` | ❌ Wave 0 |
| D-18/D-22 | `"garbage"` -> `:not_found`; `nil`/`123` -> `ArgumentError`, both forms | unit | new tests | ❌ |
| D-20/D-22 | Fail-closed on every scoped read: timeline, actor, transaction lookups, export, operator-surface mounts | integration/contract | `mix test` across the "tests with scope: present" list above + new `query/scope_fail_closed_test.exs` | ❌ Wave 0 for the new file; existing files need review per Pitfall-5-style audit |
| D-21 | `TransactionLive` at `/transactions/not-a-uuid` renders not-found | LiveView/integration | `mix test test/threadline/operator_surface/transaction_live_test.exs` | ✅ extend existing file |

### Sampling Rate
- **Per task commit:** the quick-run command above (investigation_test.exs + query_test.exs +
  action_hydration_test.exs + deprecation_parity_test.exs), plus `mix compile
  --warnings-as-errors`.
- **Per wave merge:** `mix ci.all`.
- **Phase gate:** `mix ci.all` green, plus `mix credo --strict` and (if PLT is warm) `mix
  dialyzer --no-check`. If the local Dialyzer PLT is stale, rebuild with `mix dialyzer --plt`
  before trusting a red `verify.dialyzer` result (known local-gate gotcha — do not treat a
  PLT-cache-miss failure as a real regression).

### Wave 0 Gaps
- [ ] `test/threadline/not_found_error_test.exs` (or equivalent describe block in an existing
  file) — `Threadline.NotFoundError` message shape, `Plug.Exception.status/1 == 404`,
  `actions/1 == []`.
- [ ] `test/threadline/lookup_return_shapes_contract_test.exs` — D-05's doc-contract test
  (`Code.fetch_docs`-driven, with the `as_of/4` exemption list).
- [ ] `test/threadline/query/scope_fail_closed_test.exs` (or integrated into
  `test/threadline/query_test.exs`) — D-20's fail-closed matrix across every scoped read.
- [ ] New describe blocks in `test/threadline/investigation_test.exs` for: bang siblings,
  malformed-id handling, zero-change-via-retention, unknown-key rejection, two-binding scope fn.
- [ ] New describe block / extension in `test/threadline/query/action_hydration_test.exs` for the
  `incident_bundle` query-count-≤-3 assertion (telemetry-driven, pattern already present in this
  file for other purposes).
- [ ] After adding new test files: run `bin/ci-test-partitions --write-weights` and commit the
  updated `test/partition_weights.txt` (D-05's "missing-weight entry" note; the regenerate
  command is confirmed live at `bin/ci-test-partitions:61,655`).

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Out of scope — Threadline does not own authentication (host-owned per `guides/integration-contracts.md`) |
| V3 Session Management | no | Same as above |
| V4 Access Control | **yes** | `Scope.apply/2` fail-closed (D-20) IS an access-control fix: it closes a silent scope-bypass path. Standard control: fail closed on any ambiguous/misconfigured authorization input (raise, never silently widen access) |
| V5 Input Validation | **yes** | Per-function keyword-opts allowlist (D-13) + UUID validation split (D-18, is_binary guard before `Ecto.UUID.cast/1`) |
| V6 Cryptography | no | No crypto surface touched in this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Fail-open authorization scoping (a misconfigured or missing `scope_query_fn` silently returns unscoped data) | Information Disclosure / Elevation of Privilege | D-20: raise `ArgumentError` on `:scope` without a valid arity-3 `scope_query_fn`, and vice versa; never fall through to the unscoped query |
| Existence leak via error message detail (an exception that echoes row data, scope terms, or "exists but filtered" distinguishes two attacker-relevant cases) | Information Disclosure | D-17 locks `NotFoundError`'s message to only the caller-supplied id, never row data or scope terms; a scope-rejected row and a truly-missing row both produce the identical `{:error, :not_found}` / identical bang message (D-22 requires the message be byte-equal between the missing-UUID case and the scope-rejected case) |
| Swallowing real misconfiguration (e.g. a bad `:storage_schema`) into a benign-looking "not found" | Tampering / Repudiation (masks operational errors as data-model facts in an *audit* library) | D-15: let `ArgumentError` (invalid identifier) and Postgrex `undefined_table` propagate uncaught; only a valid schema with a genuinely absent/scope-rejected row becomes `:not_found` |

## Sources

### Primary (HIGH confidence)
- `lib/threadline/query.ex` (lines 1-130, 560-710) — read this session, line numbers confirmed current against CONTEXT.md's citations
- `lib/threadline/investigation.ex` (full file) — read this session
- `lib/threadline/query/scope.ex` (full file) — read this session
- `lib/threadline/query/action_hydration.ex` (full file) — read this session
- `lib/threadline/operator_surface/live/transaction_live.ex` (full file) — read this session
- `lib/threadline/retention/policy.ex` (lines 40-70) — read this session
- `lib/threadline/capture/migration.ex` (grep for cascade) — read this session
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` (full file) — read this session
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (lines 140-175) — read this session
- `test/threadline/deprecation_parity_test.exs` (lines 1-60) — read this session
- `test/threadline/query/action_hydration_test.exs` (lines 1-40, 320-370) — read this session
- `test/threadline/public_surface_contract_test.exs` (lines 1-50) — read this session
- `test/threadline/facade_only_references_contract_test.exs` (grep) — read this session
- `CHANGELOG.md` (lines 1-110) — read this session
- `guides/integration-contracts.md` (lines 160-210) — read this session
- `test/partition_weights.txt`, `bin/ci-test-partitions` (greps) — read this session
- `mix.exs` (lines 1-32, 90-100, 130-170, 230-240) — read this session
- `.planning/phases/233-lookup-return-shapes/233-CONTEXT.md` (full file) — read this session
- `.planning/REQUIREMENTS.md` (full file) — read this session
- `.planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-CONTEXT.md` (full file) — read this session
- `.planning/STATE.md` (lines 1-271) — read this session

### Secondary (MEDIUM confidence)
None used — all claims in this document are either grounded in files read this session or
explicit CONTEXT.md decisions (which are authoritative for this phase, not researched
alternatives).

### Tertiary (LOW confidence)
None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; `:plug` dependency status verified directly in `mix.exs`.
- Architecture: HIGH — every code shape and line number cited in CONTEXT.md was re-read and confirmed this session; one additional blast-radius item (Pitfall 1) was found beyond CONTEXT.md's own list.
- Pitfalls: HIGH — all five pitfalls are grounded in files read this session, not speculation.

**Research date:** 2026-10-03
**Valid until:** 14 days (fast-moving — this phase's code is actively being edited across adjacent phases 231/232/234 in the same milestone; re-verify line numbers before executing if more than a few days elapse)
