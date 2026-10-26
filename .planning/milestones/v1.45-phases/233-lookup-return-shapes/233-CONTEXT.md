# Phase 233: Lookup Return Shapes - Context

**Gathered:** 2026-10-03
**Status:** Ready for planning

<domain>
## Phase Boundary

An adopter handles a missing transaction the same way on every single-subject lookup. The plain function returns a tagged tuple, and a `!` sibling raises when absence is a bug. The phase delivers:

- **Facade lookups.** `Threadline.audit_transaction/2` is new on the facade; today it exists only as the hidden `Threadline.Query.audit_transaction/2`. It, `transaction_context/2` and `incident_bundle/2` return `{:ok, _} | {:error, :not_found}`.
- **`!` siblings.** `audit_transaction!/2`, `transaction_context!/2` and `incident_bundle!/2` raise `Threadline.NotFoundError`.
- **One option allowlist** across the three lookups.
- **Shared existence check.** One hidden fetch that decides existence by the scoped transaction row.
- **Fail-closed scoping.** `Scope.apply`, which is used by every scoped read, fails closed. The maintainer folded this in on 2026-10-03.
- **Call sites, CHANGELOG and docs.** Every internal call site, guide, the example app and the CHANGELOG `Unreleased` section are updated.

Requirement: API-06. Read the success criteria in `.planning/ROADMAP.md` § "Phase 233". Phase 234 writes specs against these signatures, so the `@spec`s written here are final.

</domain>

<decisions>
## Implementation Decisions

Research came from four first-round advisor researchers and four deep researchers on 2026-10-03. The researchers covered:

- migration and semver;
- error design;
- naming and completeness;
- lookup semantics and security.

The maintainer accepted the full recommendation set (R1–R7) and folded the fail-closed scope fix into this phase (option 1 of 3).

### Naming and completeness of the lookup family
- **D-01:** Keep the locked plain-noun names with `!` siblings: `audit_transaction/2`, `transaction_context/2` and `incident_bundle/2`, each with its `!`. Do not use `fetch_*`.
  - Elixir's naming guide uses the trailing bang for the tuple-vs-raise pair (`File.read`/`File.read!`). `get`/`fetch` are data-structure-access conventions.
  - `Ash.get/3`/`Ash.get!/3` is precedent for a plain domain name that returns a tuple.
  - The facade's noun style (`timeline`, `as_of`, `incident_bundle`) already returns tuples where relevant.
  - Renaming would cost two more deprecations right before the 1.x freeze.
  - **Reversibility:** one-way. The names are frozen into the 1.0 contract.
- **D-02:** Add `incident_bundle!/2`. Without it, only two of the three transaction lookups have a bang, and the "everywhere" promise is false at 1.0.
- **D-03:** Explicitly exempt `as_of/4`, and say why in its `@doc` and in the contract test. Its `{:error, :deleted_record | :before_audit_horizon}` results are outcomes callers branch on, not "absence is a bug". An `as_of!/4` can be added additively in 1.x.
- **D-04:** Leave `Threadline.Evidence.get_latest_subject_ref/3` unchanged: its `get_` prefix honestly signals `nil`. Collection reads stay bare lists or `%Threadline.Page{}`.
- **D-05:** Write the "everywhere" claim as "every single-subject lookup that can be not-found". Pin it with a doc-contract test driven by `@lookups [audit_transaction: 2, transaction_context: 2, incident_bundle: 2]`. The test checks:
  - (a) both `name/2` and `name!/2` are exported;
  - (b) via `Code.fetch_docs`, the plain `@doc` starts with "Returns `{:ok,", mentions `{:error, :not_found}`, and links `name!/2`, and the bang `@doc` mentions `Threadline.NotFoundError`;
  - (c) reverse drift checks: every facade `!` function has its plain sibling listed, and every facade spec containing `{:error, :not_found}` is listed;
  - (d) an explicit exemption list holding `as_of/4`, with its reason.

  Give the new test file a partition-weight entry (the missing-weight check is permanent).

### Migration and semver
- **D-06:** `Threadline.Query.audit_transaction/2` (documented public API in 0.12) keeps returning `AuditTransaction.t() | nil`, including its `:preload` behavior and the `:action` compat warning.
  - It becomes `@deprecated "Use Threadline.audit_transaction/2 instead."` with a one-line delegate to the new hidden fetch.
  - Prove it with a parity test: `nil` ↔ `{:error, :not_found}`, `t` ↔ `{:ok, t}`, covering the `:preload` path. Also assert that `Threadline.Query.__info__(:deprecated)` lists `{:audit_transaction, 2}`, with a mutation control as in Phase 232.
  - In the CHANGELOG, merge the existing `:preload :action` Deprecations line for this function into the new entry so the function is not described twice.
  - Changing the shape in place was rejected. nil→tuple is silent: a tuple is truthy, so `if txn = …` becomes always-true.
  - Removal no earlier than 2.0.
  - **Reversibility:** costly. The behavior is pinned by the parity test and the 1.x deprecation promise.
- **D-07:** `transaction_context/2` changes in place to `{:ok, %LinkedTransaction{}} | {:error, :not_found}`, as API-06 mandates. This is a documented 1.0 breaking change.
  - It is consistent with D-06 because struct→tuple fails loudly. The researcher checked this on Elixir 1.17: `{:error, :not_found}.transaction` raises `KeyError` with a self-explanatory message. It is also a documented facade name with a doc channel.
  - CHANGELOG `Unreleased` → Breaking changes needs:
    - a before/after snippet;
    - the 0.12 idiom `%LinkedTransaction{transaction: nil}` named explicitly, since it now falls into a catch-all branch;
    - the statement that missing ids and scope-filtered ids are now `:not_found`;
    - the required action: use `transaction_context!/2` when absence is a bug, or `case` on the tuple.
  - The landing `feat!:` squash must carry a `BREAKING CHANGE:` footer naming it. Phase 237's upgrade guide reuses the before/after verbatim.
  - **Reversibility:** one-way. It is the 1.0 return contract.
- **D-08:** Final `@spec`s land in this phase so that adopters' Dialyzer flags `ctx.changes` on a tuple:
  - `@spec audit_transaction(Ecto.UUID.t(), keyword()) :: {:ok, AuditTransaction.t()} | {:error, :not_found}`;
  - `@spec audit_transaction!(Ecto.UUID.t(), keyword()) :: AuditTransaction.t()`;
  - the same pattern with `LinkedTransaction.t()` and `IncidentBundle.t()`;
  - no `no_return` on the bangs.

  New names carry `@doc since: "1.0.0"`.

### Existence semantics, shared fetch and scope surfaces
- **D-09:** A transaction "exists" when its `audit_transactions` row passes the scope.
  - `audit_transaction/2`, `transaction_context/2` and `incident_bundle/2` all go through ONE shared hidden fetch: the row first, then the changes.
  - An existing transaction with zero changes returns `{:ok, %LinkedTransaction{changes: []}}`. This is real: retention with `delete_empty_transactions: false` (`lib/threadline/retention/policy.ex:54-59`), or a scope that filters every change.
  - Today `transaction_context` derives the transaction from its changes (`lib/threadline/investigation.ex:161-180`), so such a transaction looks missing. This fixes that.
  - **Reversibility:** one-way. It is part of the 1.0 lookup contract.
- **D-10:** Scope surfaces:
  - the row is scoped with `surface: :transaction_header` (single `[at]` binding);
  - the changes are scoped with `surface: :transaction` (`[ac, at]`).

  This fixes a latent bug: the hidden fetch defaults to `surface: :transaction` on a single-binding query (`lib/threadline/query.ex:85,691`). A two-binding adopter scope fn then fails at normalize with `unknown_binding_1!`. Only `incident_bundle`'s override at `investigation.ex:192` hides it today. A scope rejection of the row gives `:not_found`, so existence does not leak.
- **D-11:** Reuse the hydrated row. Put the already-hydrated transaction row into each change's `transaction` field instead of re-preloading and re-hydrating. This takes `incident_bundle` from 3–5 queries to 2–3. A query-count test (telemetry) asserts ≤ 3. Do not attempt a single-join query, because it would mix two binding shapes and two scope surfaces.
- **D-12:** Accept two READ COMMITTED reads; do not wrap them in a transaction or use REPEATABLE READ. Retention is the only writer. Deleting changes between the reads yields a valid fewer-changes state. Deleting the row cascades its changes (`lib/threadline/capture/migration.ex:43`), giving the row plus `[]`, which is harmless. Document this as "point-in-time per query".

### Option surface
- **D-13:** All three lookups, in plain and bang forms, accept exactly `[:repo, :storage_schema, :scope, :scope_query_fn]`.
  - Unknown keys raise `ArgumentError`, following Phase 232 D-03 (a per-function allowlist, not NimbleOptions).
  - `:surface`, `:params` and `:preload` are no longer accepted:
    - `:params` is built internally (`query.ex:692`);
    - an adopter-settable `:surface` lets callers relabel a binding shape;
    - `:preload` on the row would reach `repo.preload(:changes)`, which is unscoped and unbounded.
  - Today `transaction_context` silently drops `:preload` and honors a caller `:surface`, while `incident_bundle` overwrites `:surface`. Rejecting the keys is a loud 1.0 break and gets its own CHANGELOG breaking line.
  - `lib/threadline/operator_surface/live/transaction_live.ex:20` stops passing `surface:`/`params:`.
  - **Reversibility:** costly. Widening later is additive, but narrowing after 1.0 is breaking.
- **D-14:** The facade `audit_transaction/2` always hydrates `.action`.
  - It costs 0 queries when `action_id` is nil (`lib/threadline/query/action_hydration.ex:79`), otherwise 1.
  - It removes the ambiguity where `nil` means either "no action" or "not hydrated".
  - The facade is the exploration layer, so this does not breach the capture/semantics boundary. The schema itself stays semantics-free, as Phase 231 requires.
  - This overrides the first-round advisor's "no hydration" pick.
- **D-15:** A wrong `:storage_schema` stays loud:
  - an invalid identifier raises `ArgumentError` (`lib/threadline/storage_schema.ex`);
  - a nonexistent schema raises the Postgrex `undefined_table` error;
  - a valid schema without the row returns `:not_found`.

  Do not rescue a misconfiguration into `:not_found`: in an audit library that hides breakage.

### Error design
- **D-16:** The error value stays the bare atom `:not_found`.
  - The `FallbackController` that `phx.gen.json` generates already has a `{:error, :not_found}` clause, so a `with` chain falls through to a 404.
  - It is the same shape as `incident_bundle`, `TransactionLive` and the example app.
  - An exception struct in the tuple (the Req/Mint style) was rejected: a lookup has exactly one failure reason.
- **D-17:** The `!` functions raise a new public `Threadline.NotFoundError` with `defexception [:resource, :id]` and `@type t`.
  - The message is `"audit transaction not found: <inspect(id)>"`: only the id the caller passed in, never row data, scope terms, or "exists but filtered" wording.
  - All three bangs use `resource: :audit_transaction`, because that is the subject looked up.
  - Implement `Plug.Exception` unconditionally (`status/1` → 404, `actions/1` → `[]`); `:plug` is a non-optional dependency (`mix.exs:95`). The moduledoc notes that, unlike Ecto (which gets its 404 from phoenix_ecto), a library with a Plug dependency owns its status.
  - Pin the module in `test/threadline/public_surface_contract_test.exs`. It needs a moduledoc (the Phase 234 gate).
  - `Ecto.NoResultsError` was rejected: its message prints the query, which leaks scope SQL, it needs `queryable:`, and adopters could not tell our misses from their own `Repo.one!` misses.
  - **Reversibility:** one-way. It is a 1.0 public module.
- **D-18:** Malformed ids:
  - A binary that is not a valid UUID returns `{:error, :not_found}`, and the bang raises `NotFoundError`, on all three facade lookups.
  - A non-binary (`nil`, an integer, …) still raises `ArgumentError`.
  - Rationale: no such transaction can exist, so not-found is true. It fixes a real bug: `TransactionLive` passes the raw URL id (`transaction_live.ex:20`) into a lookup that raises `ArgumentError` (`query.ex:586`), so `/audit/transactions/garbage` is a 500 today. Every adopter would also otherwise need an `Ecto.UUID.cast` guard, and no third return shape is introduced.
  - Collection reads (`audit_changes_for_transaction/2`, `row_history`, …) keep their strict `ArgumentError` validation. The deprecated `Query.audit_transaction/2` delegate keeps its current raise.
  - Each lookup `@doc` states this.
- **D-19:** No telemetry on not-found. Callers instrument their own lookups.

### Fail-closed scoping (folded in by the maintainer, 2026-10-03)
- **D-20:** `Threadline.Query.Scope.apply/2` (`lib/threadline/query/scope.ex:9-22`) currently fails open. With `:scope` set and `:scope_query_fn` nil, or a scope fn that is not arity-3, it returns the query unscoped. Change it as follows:
  - `:scope` given without an arity-3 `scope_query_fn` raises `ArgumentError` naming the problem.
  - No `:scope`, and no `:scope_query_fn`, stays unscoped as today: scoping is opt-in.
  - Decide and document the case of a `:scope_query_fn` without `:scope`. Recommendation: raise as well, since it is almost certainly a wiring mistake.
  - Tests cover every scoped read: timeline, actor, transaction lookups, export, and the operator surface mount paths.
  - CHANGELOG `Unreleased` gets a breaking entry: previously-silent misconfiguration now raises, with the required action.
  - Document in `guides/integration-contracts.md`:
    - the `:transaction_header` surface and its single `[at]` binding (today the guide lists only "timeline, actor, transaction, export" at ~line 185);
    - the risk that an adopter `scope_query_fn` with no `:transaction_header` clause falls into its own catch-all and returns another tenant's row.

    Update `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (~157-168) if its catch-all is permissive.
  - **Reversibility:** one-way. Loosening it again after 1.0 would reintroduce a security hole; tightening it after 1.0 would need 2.0.

### Call sites, guides, verification
- **D-21:** No internal caller may use a deprecated name (Phase 232 D-13). `Investigation.incident_bundle/2` and `transaction_context/2` move to the shared hidden fetch. Also update:
  - `guides/code-walkthrough.md:375`, which quotes `Query.audit_transaction`; the facade-only reference scanner must stay green;
  - `test/threadline/investigation_test.exs:459` and `:488-495`, which should expect `{:error, :not_found}`;
  - `test/threadline/storage_schema_integration_test.exs:121`, `test/threadline/query_test.exs:1647` and `test/threadline/query/action_hydration_test.exs:338`, which should match `{:ok, _}`.

  Before any change, grep guides, the README and the example app for `transaction_context`, `audit_transaction` and the removed option keys, and rewrite every hit in the same change. `mix compile --warnings-as-errors` must stay clean for `lib/`, `test/` and the example app, and `mix ci.all` must be green at phase close.
- **D-22:** Required tests:
  - present and not-found cases for all six functions;
  - an existing zero-change transaction, both by direct insert and via retention with `delete_empty_transactions: false`;
  - a scope-rejected row → `:not_found` from all three, with a bang message byte-equal to the missing-UUID case;
  - a scope fn keyed only on `:transaction_header` with an `[at]` binding works on the facade `audit_transaction`;
  - unknown keys (`:surface`, `:params`, `:preload`) raise on all three;
  - the facade `audit_transaction` hydrates `.action`;
  - the `incident_bundle` query count is ≤ 3;
  - `"garbage"` → `:not_found`, while `nil`/`123` raise `ArgumentError`, in both forms;
  - `Plug.Exception.status(%Threadline.NotFoundError{}) == 404`;
  - the message contains the id and no column values;
  - `TransactionLive` at `/transactions/not-a-uuid` renders the not-found state;
  - the D-06 parity and deprecation tests;
  - the D-05 doc-contract test;
  - the D-20 fail-closed tests on every scoped read.

### Claude's Discretion
- The names of the shared hidden fetch and its internal return shape (for example `{:ok, txn, changes} | :not_found`), and whether it lives in `Query` or `Investigation`.
- The exact `ArgumentError` wording for D-13 and D-20.
- How to split the work into plans. Suggested split:
  1. shared fetch, surfaces and option allowlist;
  2. facade lookups, bangs and `NotFoundError`;
  3. migration of callers and guides, CHANGELOG, contract tests;
  4. `Scope.apply` fail-closed.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/ROADMAP.md` § "Phase 233" — goal, SC1–SC3, and the cross-cutting invariants (breaking changes recorded when made, grep before hiding, warnings stay errors, no planning vocabulary in product code)
- `.planning/REQUIREMENTS.md` — API-06 and the out-of-scope table (operator UI parked; only forced call sites are touched)
- `.planning/research/SUMMARY.md` ~lines 225–245 and 530–540 — the return-shape convention and the Phase 233 sketch

### Prior phases
- `.planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-CONTEXT.md` — D-02/D-04 (deprecated names keep 0.12 behavior), D-03 (option allowlist, unknown keys raise), D-11..D-13 (deprecation delegates, the arity rule, no internal calls to deprecated names)
- `.planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-CONTEXT.md` — D-08..D-10 (action hydration, the `preload: :action` compat warning), D-11..D-13 (facade-only reference scanner)

### Code
- `lib/threadline.ex` — the facade (`transaction_context/2` ~370, `incident_bundle/2` ~381)
- `lib/threadline/query.ex` — `audit_transaction/2` ~72-108, `validate_audit_transaction_id!/1` ~586, `transaction_scope_opts/2` ~687
- `lib/threadline/investigation.ex` — `transaction_context/2` ~161, `incident_bundle/2` ~186
- `lib/threadline/query/scope.ex` — the fail-open `apply/2`
- `lib/threadline/query/action_hydration.ex` — hydration helper
- `lib/threadline/operator_surface/live/transaction_live.ex` — raw-id mount (~20)
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` and `.../router.ex` (~157-168, the scope fn surfaces)
- `lib/threadline/retention.ex`, `lib/threadline/retention/policy.ex` — `delete_empty_transactions`

### Guides and changelog
- `CHANGELOG.md` "Unreleased" — existing Breaking changes and Deprecations entries to extend and merge
- `guides/integration-contracts.md` (~185) — scope surfaces
- `guides/code-walkthrough.md` (~375) — quotes `Query.audit_transaction`

### Project rules
- `CLAUDE.md` — three-layer architecture, correct by default, SQL-native, verification entrypoints
- `.planning/PROJECT.md` → Constraints → "Zero human verification by default"
- `prompts/threadline-elixir-oss-dna.md` — named verify entrypoints, doc contract tests
- `prompts/audit-lib-domain-model-reference.md` — domain vocabulary

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Query.ActionHydration` (`hydrate_actions/3`): a one-query, deduped action fill; 0 queries when there are no `action_id`s.
- The Phase 232 deprecation-test pattern (`__info__(:deprecated)` plus a mutation control, parity tests) and the opts-allowlist validator in `investigation.ex` (~20, ~223).
- `test/threadline/public_surface_contract_test.exs` (`@hidden_modules`, pins) and `test/threadline/facade_only_references_contract_test.exs` (guide scanner).
- `test/threadline/telemetry_registry_contract_test.exs`: telemetry-based query counting can follow its drive pattern.

### Established Patterns
- `incident_bundle/2` already does row-first lookup → `{:error, :not_found}`; it is the template for the shared fetch.
- Scope fns receive `(query, scope, %{surface:, params:})`. `:surface` encodes the binding shape, so it is a contract and not a label.
- The CHANGELOG `Unreleased` section has Breaking changes and Deprecations subsections. Entries state "Required action:".

### Integration Points
- The operator surface `TransactionLive` mount and the example app controller both consume `incident_bundle`.
- Every scoped read goes through `Threadline.Query.Scope.apply/2` (the D-20 blast radius).

</code_context>

<specifics>
## Specific Ideas

- Exception sketch:
  ```elixir
  defmodule Threadline.NotFoundError do
    defexception [:resource, :id]
    @type t :: %__MODULE__{resource: atom(), id: term()}
    @impl true
    def message(%{resource: r, id: id}),
      do: "#{r |> to_string() |> String.replace("_", " ")} not found: #{inspect(id)}"
  end

  defimpl Plug.Exception, for: Threadline.NotFoundError do
    def status(_), do: 404
    def actions(_), do: []
  end
  ```
- Bang shape: `case f(id, opts) do {:ok, v} -> v; {:error, :not_found} -> raise Threadline.NotFoundError, resource: :audit_transaction, id: id end`.
- Doc first lines (the API-02 precedent):
  - plain: "Returns `{:ok, %AuditTransaction{}}` when the row exists and is visible under the scope, or `{:error, :not_found}`."
  - bang: "Returns the `%AuditTransaction{}` or raises `Threadline.NotFoundError`."

</specifics>

<deferred>
## Deferred Ideas

- `as_of!/4`: can be added additively in 1.x if adopters ask (D-03).
- Changing the shape of `Evidence.get_latest_subject_ref/3`: not planned; the `get_` naming is honest.

</deferred>

---

*Phase: 233-lookup-return-shapes*
*Context gathered: 2026-10-03*
