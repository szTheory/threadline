# Phase 55: Incident Bundle Surface - Research

**Researched:** 2026-05-05
**Domain:** Incident-bundle packaging on top of the Phase 54 investigation helpers [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Public contract shape
- **D-01:** Phase 55 should add a distinct top-level incident bundle surface
  rather than stretching `transaction_context/2` into a shape-changing helper.
- **D-02:** The recommended public entrypoint is a dedicated
  `Threadline.incident_bundle/2`-style API that returns a typed Elixir-first
  bundle contract, not a JSON-first nested map.
- **D-03:** The bundle should be represented by explicit structs, with one
  parent bundle struct containing transaction/action context and one per-change
  wrapper carrying the linked raw change plus its diff projection.
- **D-04:** The Phase 54 raw helper contract remains valid and separate:
  `transaction_context/2` stays the lower-level linked investigation primitive
  for callers who want raw structs without incident packaging.

### Diff policy
- **D-05:** The new incident bundle surface should always include JSON-ready
  `change_diff` for every bundled change.
- **D-06:** Phase 55 should not introduce an `include_change_diff?` or similar
  shape-changing option on the bundle contract. Different functions should mean
  different contracts; one function should not sometimes return diffs and
  sometimes not.
- **D-07:** `Threadline.change_diff/2` remains the underlying projection
  primitive, but Phase 55 packages it once at the bundle layer so Phoenix and
  host code stop repeating ad-hoc `Enum.map` composition.

### Existence and empty-state semantics
- **D-08:** The new incident bundle helper should distinguish a missing parent
  transaction from an existing transaction whose change list is empty.
- **D-09:** The library contract should be existence-aware:
  `{:ok, bundle}` when the `audit_transactions` row exists and
  `{:error, :not_found}` when it does not.
- **D-10:** An existing transaction with no retained/captured child changes is
  still a valid incident bundle result and should return `{:ok, bundle}` with
  `changes: []`.
- **D-11:** The low-level `Threadline.audit_changes_for_transaction/2` contract
  stays backward-compatible and unchanged even though the richer incident bundle
  surface becomes more explicit.

### Example Phoenix endpoint contract
- **D-12:** The Phoenix example incident endpoint should move to the new bundled
  surface and teach the full incident bundle as the canonical endpoint contract,
  not keep the older minimal payload as the headline story.
- **D-13:** The endpoint should still render through a Phoenix JSON layer rather
  than dumping library structs directly. The library stays Elixir-native while
  the HTTP contract stays curated and stable.
- **D-14:** The HTTP mapping should be:
  malformed UUID -> `400`,
  authenticated request for missing transaction -> `404`,
  authenticated request for existing transaction -> `200`, including the case
  where `changes` is empty.
- **D-15:** The example app should keep the Phase 51 auth boundary unchanged:
  incident drill-down requires an authenticated actor, while tenancy and richer
  authorization remain host-owned.

### DX, architecture, and contract posture
- **D-16:** The Phase 55 surface should optimize for least surprise in the
  Elixir/Phoenix ecosystem: explicit structs, explicit tagged outcomes for
  singular lookups, and no controller-local contract assembly.
- **D-17:** The bundle contract should preserve access to raw linked structs so
  adopters can build richer host views without reverse-engineering a JSON-first
  payload.
- **D-18:** Avoid duplicate canonical shapes. After Phase 55 lands, the library
  contract, example endpoint, and docs should all point to the bundled drill-
  down story rather than teaching both a thin legacy projection and a richer
  bundle.
- **D-19:** Focused proof is preferred: tests should lock the incident bundle
  shape, diff presence, ordering, not-found semantics, empty-change semantics,
  and example-endpoint parity with the library contract.

### the agent's Discretion
- Exact struct module names, as long as they clearly communicate "incident
  bundle" vs the raw Phase 54 transaction-context types.
- The exact JSON field naming in the Phoenix renderer, provided the shape is
  explicit, curated, and aligned with the library bundle semantics.
- Whether to expose one or more small helper functions under
  `Threadline.Investigation` to support the top-level bundle entrypoint, as long
  as the primary adopter-facing contract stays on `Threadline`.

### Deferred Ideas (OUT OF SCOPE)
- Broader docs-arc convergence across README, domain reference, getting-started,
  and milestone narrative beyond the minimum needed to teach the new bundle
  contract cleanly. That belongs to Phase 56.
- New authorization, tenancy, or policy framework behavior for incident
  drill-down. Hosts continue to own those boundaries.
- Operator UI or `threadline_web` packaging on top of the new bundle surface.
- Broader config knobs for alternative diff/bundle shapes unless real adopters
  later prove a need.
</user_constraints>

## Project Constraints (from CLAUDE.md)

- Keep capture, semantics, and exploration responsibilities separate; Phase 55 should stay in the exploration layer and not mutate capture or action-recording behavior. [VERIFIED: CLAUDE.md]
- Use the domain terms `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and correlation consistently in the API and docs. [VERIFIED: CLAUDE.md]
- Prefer named Mix verification entrypoints and existing focused ExUnit files over ad-hoc test stories. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]
- Treat example README and guide wording as contract surfaces, but keep broad docs convergence for Phase 56 unless a minimal Phase 55 proof needs a narrow update. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/ROADMAP.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INCIDENT-06 | Threadline ships a first-class incident bundle surface for one audit transaction that returns ordered changes, linked transaction/action context, and JSON-ready field diffs in a single library-level contract. | Add `Threadline.incident_bundle/2` as a tagged singular lookup returning a typed bundle struct with per-change diff wrappers, while preserving the Phase 54 raw helper unchanged. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] [VERIFIED: lib/threadline.ex] [VERIFIED: lib/threadline/investigation.ex] |
| INCIDENT-07 | The Phoenix example incident drill-down path uses the packaged incident bundle surface rather than bespoke controller composition, proving the public contract is sufficient for real host endpoints. | Move the controller from `audit_changes_for_transaction/2` + controller-local `Enum.map` to `incident_bundle/2` + a dedicated Phoenix JSON renderer, then prove `400`/`404`/`200` semantics in the existing request-path test. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs] |
</phase_requirements>

## Summary

Phase 55 should ship one new public singular lookup, `Threadline.incident_bundle/2`, instead of mutating the already-shipped Phase 54 `transaction_context/2` contract. The existing raw helper currently derives parent context from child rows alone, so it cannot distinguish "missing transaction" from "existing transaction with zero retained changes"; that is the exact semantic gap this phase should close. [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] [VERIFIED: lib/threadline/investigation.ex] [VERIFIED: test/threadline/investigation_test.exs]

The concrete implementation should be narrow: fetch the parent `%AuditTransaction{}` directly, load ordered child changes through the existing `audit_changes_for_transaction/2` ordering path, wrap each linked change with one packaged `change_diff`, and return `{:error, :not_found}` only when the parent transaction row is absent after UUID validation. The Phoenix example should then render that bundle through a JSON module instead of controller-local map assembly. [VERIFIED: lib/threadline/query.ex] [VERIFIED: lib/threadline/change_diff.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex]

**Primary recommendation:** plan Phase 55 as one library contract cluster and one Phoenix proof cluster, with `transaction_context/2` preserved as the raw lower-level primitive and `incident_bundle/2` becoming the canonical incident drill-down surface. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/milestones/v1.16-phases/54-investigation-slice-apis/54-VERIFICATION.md] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Incident bundle lookup by `audit_transactions.id` | API / Backend | Database / Storage | The library owns lookup semantics, tagged outcomes, linked structs, and diff packaging, while PostgreSQL remains the source of truth for transactions and changes. [VERIFIED: lib/threadline.ex] [VERIFIED: lib/threadline/query.ex] [VERIFIED: lib/threadline/capture/audit_transaction.ex] [VERIFIED: lib/threadline/capture/audit_change.ex] |
| Ordered per-transaction change traversal | Database / Storage | API / Backend | Ordering is already defined at the query layer as `captured_at DESC, id DESC`, and the new bundle should reuse that exact database-backed ordering instead of re-sorting in memory. [VERIFIED: lib/threadline/query.ex] [VERIFIED: .planning/milestones/v1.16-phases/53-timeline-paging-contract/53-CONTEXT.md] |
| JSON-ready field diff packaging | API / Backend | — | `Threadline.ChangeDiff` is a pure Elixir projection over one `%AuditChange{}` and should remain the only diff-packaging authority. [VERIFIED: lib/threadline/change_diff.ex] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] |
| Example endpoint status mapping and response rendering | Frontend Server (SSR) | API / Backend | The Phoenix controller and JSON module own `400`/`404`/`200` HTTP behavior, while the library stays Elixir-native and framework-agnostic. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.15` project constraint, runtime `1.19.5` installed | Language/runtime for the library and example app | Phase 55 should extend existing public modules and ExUnit coverage within the current supported Elixir line, not add a parallel runtime path. [VERIFIED: mix.exs] [VERIFIED: examples/threadline_phoenix/mix.exs] [VERIFIED: local elixir version probe] |
| `ecto_sql` | `3.13.5` locked | Querying `audit_transactions` and `audit_changes` with existing repo patterns | All investigation helpers already build on Ecto query + preload behavior; the bundle should reuse those seams. [VERIFIED: mix.lock] [VERIFIED: lib/threadline/query.ex] |
| `postgrex` | `0.22.0` locked | PostgreSQL adapter backing transaction and change reads | The incident bundle is read-only over the existing Postgres-backed audit tables. [VERIFIED: mix.lock] [VERIFIED: lib/threadline/capture/audit_transaction.ex] [VERIFIED: lib/threadline/capture/audit_change.ex] |
| `jason` | `1.4.4` locked | JSON encoding for the example endpoint payload | The example should keep rendering curated JSON over the bundle rather than exposing structs directly. [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix | `1.8.5` locked in the example app | Route/controller/JSON rendering for the request-path proof | Use only for the example endpoint migration and request-path verification, not for the library contract itself. [VERIFIED: examples/threadline_phoenix/mix.lock] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] |
| `Threadline.ChangeDiff` | in-repo module | Deterministic JSON-ready projection for one `%AuditChange{}` | Use once per bundled change; do not re-encode diff semantics in the controller or a new module. [VERIFIED: lib/threadline/change_diff.ex] |
| `Threadline.Investigation.LinkedChange` / `LinkedTransaction` | in-repo modules | Raw Phase 54 linked investigation structs | Reuse them as the raw building blocks the incident bundle wraps, not as the final Phase 55 contract itself. [VERIFIED: lib/threadline/investigation/linked_change.ex] [VERIFIED: test/threadline/investigation_test.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Threadline.incident_bundle/2` | Add diff flags to `transaction_context/2` | Rejected because Phase 55 decisions explicitly forbid shape-changing options on the raw helper. [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] |
| Tagged singular lookup | Keep returning `%LinkedTransaction{transaction: nil, changes: []}` for every no-row case | Rejected because that shape cannot distinguish parent absence from empty children, which is a locked Phase 55 requirement. [VERIFIED: lib/threadline/investigation.ex] [VERIFIED: test/threadline/investigation_test.exs] |
| Dedicated Phoenix JSON module | Keep controller-local `Enum.map` assembly | Rejected because the example should prove the library contract is sufficient and keep the HTTP surface curated separately from the library structs. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] |

**Installation:** No new dependencies are needed for Phase 55; it should ship entirely on the existing library and example-app stack. [VERIFIED: mix.exs] [VERIFIED: examples/threadline_phoenix/mix.exs]

**Version verification:** Versions above were verified from the repo manifests and lockfiles because Phase 55 should not add new packages. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/mix.exs] [VERIFIED: examples/threadline_phoenix/mix.lock]

## Architecture Patterns

### System Architecture Diagram

```text
HTTP GET /api/audit_transactions/:id/changes
  -> AuditTransactionController auth gate
  -> UUID validation
  -> Threadline.incident_bundle/2
     -> fetch AuditTransaction (+ action preload)
     -> if missing => {:error, :not_found}
     -> load ordered AuditChange rows via Query.audit_changes_for_transaction/2
     -> preload transaction/action context for each change
     -> package IncidentChange{linked_change, change_diff}
     -> return IncidentBundle{transaction, action, changes}
  -> AuditTransactionJSON renders curated JSON
  -> 200 / 404 / 400 response
```

### Recommended Project Structure

```text
lib/
├── threadline.ex                               # top-level public delegator
├── threadline/investigation.ex                 # incident_bundle/2 implementation and shared builders
└── threadline/investigation/incident_bundle.ex # new IncidentBundle/IncidentChange structs

examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/
├── audit_transaction_controller.ex             # controller switches to incident_bundle/2
└── audit_transaction_json.ex                   # curated JSON rendering for the new bundle

test/
└── threadline/investigation_test.exs           # bundle semantics and compatibility coverage

examples/threadline_phoenix/test/threadline_phoenix_web/
└── posts_incident_json_path_test.exs           # 400/404/200 request-path proof
```

### Likely File Touch Points

- `lib/threadline.ex` should gain the public `incident_bundle/2` delegator alongside `transaction_context/2`. [VERIFIED: lib/threadline.ex]
- `lib/threadline/investigation.ex` is the main seam for the implementation because it already owns the higher-level helper layer and linked-change builders. [VERIFIED: lib/threadline/investigation.ex]
- `lib/threadline/investigation/linked_change.ex` establishes the current result-wrapper pattern; a new sibling file such as `incident_bundle.ex` is the cleanest place for Phase 55 structs. [VERIFIED: lib/threadline/investigation/linked_change.ex]
- `lib/threadline/query.ex` should stay unchanged at the public `audit_changes_for_transaction/2` contract level, though the implementation may reuse it internally. [VERIFIED: lib/threadline/query.ex]
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` should stop assembling per-row diffs in the controller. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex]
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` is the request-path proof file to evolve. [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs]
- Minimal doc touch points, only if needed for Phase 55 proof, are `examples/threadline_phoenix/README.md` and the incident JSON block in `guides/domain-reference.md`; broader doc arc cleanup remains Phase 56. [VERIFIED: examples/threadline_phoenix/README.md] [VERIFIED: guides/domain-reference.md] [VERIFIED: .planning/ROADMAP.md]

### Pattern 1: Tagged singular lookup over an explicit bundle struct
**What:** Expose `Threadline.incident_bundle/2` as a singular library lookup with `{:ok, bundle} | {:error, :not_found}` and keep malformed UUID handling aligned with the existing query-layer `ArgumentError` posture. [VERIFIED: lib/threadline/query.ex] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md]
**When to use:** One transaction drill-down where the caller needs linked transaction/action context and packaged diffs in one stable library contract. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: recommended shape from Phase 55 decisions + existing Threadline helper patterns
@spec incident_bundle(term(), keyword()) ::
        {:ok, Threadline.Investigation.IncidentBundle.t()} | {:error, :not_found}

case Threadline.incident_bundle(audit_transaction_id, repo: Repo) do
  {:ok, bundle} -> bundle
  {:error, :not_found} -> :missing
end
```

### Pattern 2: Preserve raw linked structs inside each bundled change
**What:** Model each bundled change as a wrapper around the existing Phase 54 `%LinkedChange{}` plus one packaged `change_diff` map. [VERIFIED: lib/threadline/investigation/linked_change.ex] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md]
**When to use:** Whenever adopters need both an easy diff projection and access to the raw `audit_change`, `transaction`, and `action` structs for richer host rendering. [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md]
**Example:**
```elixir
# Source: recommended shape built on existing LinkedChange
defmodule Threadline.Investigation.IncidentChange do
  @enforce_keys [:linked_change, :change_diff]
  defstruct [:linked_change, :change_diff]
end
```

### Pattern 3: Phoenix JSON rendering stays separate from library structs
**What:** Follow the existing `PostJSON` pattern by adding a dedicated JSON module for the incident endpoint instead of calling `json(conn, %{...})` with controller-local bundle assembly. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex]
**When to use:** Example endpoint proof for `INCIDENT-07`. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: recommended migration following existing PostJSON pattern
case Threadline.incident_bundle(uuid, repo: Repo) do
  {:ok, bundle} ->
    render(conn, :show, bundle: bundle)

  {:error, :not_found} ->
    conn
    |> put_status(:not_found)
    |> json(%{errors: %{detail: "audit transaction not found"}})
end
```

### Anti-Patterns to Avoid
- **Inferring parent existence from child changes:** `transaction_context/2` currently does this and therefore collapses missing and empty into the same shape. Phase 55 should not repeat that for `incident_bundle/2`. [VERIFIED: lib/threadline/investigation.ex] [VERIFIED: test/threadline/investigation_test.exs]
- **Adding `include_change_diff?` or similar booleans:** the Phase 55 context explicitly rejects shape-changing flags on the new bundle contract. [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md]
- **Re-sorting changes in memory:** the canonical order is already defined at the query layer and should be preserved unchanged. [VERIFIED: lib/threadline/query.ex] [VERIFIED: .planning/milestones/v1.16-phases/53-timeline-paging-contract/53-CONTEXT.md]
- **Dumping structs directly from the controller:** the library contract should stay Elixir-native, but the example HTTP contract should remain curated through a JSON layer. [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-change diff assembly | Custom controller `Enum.map` diff projection | `Threadline.change_diff/2` inside the library bundle builder | `ChangeDiff` already owns deterministic JSON-ready projection semantics. [VERIFIED: lib/threadline/change_diff.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] |
| Parent existence detection | "If changes list is empty, treat it as missing" | Direct `AuditTransaction` fetch before packaging | Empty children and missing parent are distinct Phase 55 outcomes. [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] [VERIFIED: lib/threadline/investigation.ex] |
| Linked context reconstruction | Ad-hoc manual joins in the controller | Existing `LinkedChange` / `transaction_context`-style builders under `Threadline.Investigation` | Phase 54 already established the linked investigation wrapper pattern. [VERIFIED: lib/threadline/investigation.ex] [VERIFIED: lib/threadline/investigation/linked_change.ex] [VERIFIED: .planning/milestones/v1.16-phases/54-investigation-slice-apis/54-VERIFICATION.md] |
| Phoenix payload assembly | Inline maps in the controller action | Dedicated `AuditTransactionJSON` renderer | The example app already uses JSON modules for curated payload contracts. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex] |

**Key insight:** Phase 55 is a packaging phase, not a semantics rewrite. Reuse `audit_changes_for_transaction/2`, the linked investigation wrappers, and `ChangeDiff`; add only the missing parent-aware bundle contract on top. [VERIFIED: lib/threadline/query.ex] [VERIFIED: lib/threadline/investigation.ex] [VERIFIED: lib/threadline/change_diff.ex]

## Common Pitfalls

### Pitfall 1: Missing-vs-empty collapse
**What goes wrong:** The implementation returns the same empty shape for a nonexistent transaction and a real transaction with no changes. [VERIFIED: test/threadline/investigation_test.exs]
**Why it happens:** `transaction_context/2` currently derives the transaction from the first linked child row, so no child rows means no parent context. [VERIFIED: lib/threadline/investigation.ex]
**How to avoid:** Fetch the parent `%AuditTransaction{}` first, preload `:action`, and only then package ordered child changes. [VERIFIED: lib/threadline/capture/audit_transaction.ex] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md]
**Warning signs:** A random UUID and a retained-but-empty transaction both yield `transaction: nil` and `changes: []`. [VERIFIED: test/threadline/investigation_test.exs]

### Pitfall 2: Contract drift between raw and bundled helpers
**What goes wrong:** `transaction_context/2` gains diffs or tagged outcomes and stops being the stable raw primitive Phase 54 shipped. [VERIFIED: .planning/milestones/v1.16-phases/54-investigation-slice-apis/54-VERIFICATION.md]
**Why it happens:** The easiest implementation path is to mutate the existing helper instead of adding a new one. [VERIFIED: lib/threadline/investigation.ex]
**How to avoid:** Add `incident_bundle/2` as a separate public delegator and keep Phase 54 compatibility coverage in place. [VERIFIED: lib/threadline.ex] [VERIFIED: test/threadline/query_test.exs]
**Warning signs:** Existing compatibility tests start asserting `change_diff` fields on `%LinkedChange{}` or tagged tuples from `transaction_context/2`. [VERIFIED: test/threadline/query_test.exs] [VERIFIED: test/threadline/investigation_test.exs]

### Pitfall 3: Controller-local shape assembly surviving the new bundle
**What goes wrong:** The example endpoint still maps over raw changes in the controller after the library bundle exists. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex]
**Why it happens:** The current controller already works for `200` responses and may be left partially migrated. [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs]
**How to avoid:** Move rendering to `AuditTransactionJSON` and make the controller branch on `{:ok, bundle}` / `{:error, :not_found}` only. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md]
**Warning signs:** `Threadline.change_diff/2` is still called directly inside the controller after the new API ships. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex]

### Pitfall 4: Reopening docs-arc cleanup in Phase 55
**What goes wrong:** README, playbook, quickstart, and domain-reference wording all get swept into a broad narrative cleanup. [VERIFIED: .planning/ROADMAP.md]
**Why it happens:** The incident JSON story appears in several docs today. [VERIFIED: examples/threadline_phoenix/README.md] [VERIFIED: guides/domain-reference.md] [VERIFIED: guides/incident-playbook.md] [VERIFIED: guides/getting-started-saas.md]
**How to avoid:** Limit docs changes to the minimum Phase 55 proof surfaces if the new endpoint contract would otherwise be misstated; leave full convergence to Phase 56. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md]
**Warning signs:** The phase starts touching multiple guides without adding new Phase 55 proof. [VERIFIED: .planning/ROADMAP.md]

## Code Examples

Verified patterns from local sources:

### Existing raw transaction helper stays lower-level
```elixir
# Source: lib/threadline.ex
def transaction_context(transaction_id, opts \\ []),
  do: Investigation.transaction_context(transaction_id, opts)
```

### Existing helper implementation currently lacks parent-aware semantics
```elixir
# Source: lib/threadline/investigation.ex
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

### Existing example controller still hand-assembles the incident JSON payload
```elixir
# Source: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex
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

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Example controller composes `audit_changes_for_transaction/2` + `change_diff/2` itself | Library-owned `incident_bundle/2` should package the transaction drill-down contract once | Phase 55 target, after Phase 54 shipped raw linked helpers on 2026-05-05/2026-05-06 UTC. [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/ROADMAP.md] | Host endpoints can prove the public contract directly instead of teaching bespoke controller composition. [VERIFIED: .planning/REQUIREMENTS.md] |
| `transaction_context/2` returns a richer raw struct but does not distinguish missing vs empty and does not package diffs | Keep `transaction_context/2` raw; add a distinct bundle helper for incident semantics | Phase 54 shipped the raw helper and explicitly deferred diff/bundle behavior to Phase 55. [VERIFIED: .planning/milestones/v1.16-phases/54-investigation-slice-apis/54-VERIFICATION.md] [VERIFIED: test/threadline/investigation_test.exs] | Preserves backward compatibility while closing the remaining incident gap. [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] |

**Deprecated/outdated:**
- The old headline story that `GET /api/audit_transactions/:id/changes` is only `audit_transaction_id` plus `audit_change_id`/`change_diff` maps is outdated for the canonical Phase 55 endpoint shape once the bundle ships, though broad docs convergence still belongs to Phase 56. [VERIFIED: examples/threadline_phoenix/README.md] [VERIFIED: guides/domain-reference.md] [VERIFIED: .planning/ROADMAP.md]

## Assumptions Log

All material claims in this research were verified from the repo, local planning artifacts, or local environment probes; no unverified assumptions remain. [VERIFIED: file reads] [VERIFIED: command probes]

## Open Questions (RESOLVED)

1. **What exact struct names should Phase 55 use?**
   - Resolution: use `Threadline.Investigation.IncidentBundle` for the parent
     bundle struct and `Threadline.Investigation.IncidentChange` for each
     bundled change wrapper.
   - Why this choice stands: the context leaves naming to agent discretion but
     requires one parent bundle struct and one per-change wrapper, and these
     names read clearly beside the existing raw `LinkedTransaction` /
     `LinkedChange` types without blurring the Phase 54 and Phase 55 contracts.
     [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md]
     [VERIFIED: lib/threadline/investigation/linked_change.ex]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | library compile/test | ✓ | `1.19.5` runtime installed | — |
| Mix | verification commands | ✓ | `1.19.5` | — |
| PostgreSQL CLI | example/test environment checks | ✓ | `14.17` | — |
| PostgreSQL server on `localhost:5432` | request-path and repo-backed tests | ✓ | accepting connections | If local DB changes, use the existing `DB_HOST` / `DB_PORT` overrides documented by the example app. [VERIFIED: examples/threadline_phoenix/README.md] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: command probes]

**Missing dependencies with fallback:**
- None. [VERIFIED: command probes]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix aliases. [VERIFIED: mix.exs] |
| Config file | no standalone `pytest`-style config; verification is driven by Mix aliases and the project test layout. [VERIFIED: mix.exs] |
| Quick run command | `mix test test/threadline/investigation_test.exs --max-failures 1` [VERIFIED: test/threadline/investigation_test.exs] |
| Full suite command | `mix verify.test` for the library and `mix verify.example` for the Phoenix example. [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INCIDENT-06 | `incident_bundle/2` returns ordered bundled changes with packaged diffs, `{:error, :not_found}` for missing parent, and `{:ok, changes: []}` for existing empty transactions while `transaction_context/2` stays raw. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] | unit | `mix test test/threadline/investigation_test.exs test/threadline/query_test.exs --max-failures 1` | ✅ |
| INCIDENT-07 | authenticated example endpoint renders the bundled contract and preserves `400` malformed UUID, `404` missing transaction, `200` existing transaction, and `401` anonymous auth boundary. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] | request/integration | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_incident_json_path_test.exs` | ✅ |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/investigation_test.exs --max-failures 1` for library changes or `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_incident_json_path_test.exs` for endpoint changes. [VERIFIED: test/threadline/investigation_test.exs] [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs]
- **Per wave merge:** `mix verify.test && mix verify.example`. [VERIFIED: mix.exs]
- **Phase gate:** targeted library proof + targeted request-path proof + full `mix verify.test` and `mix verify.example` green before `/gsd-verify-work`. [VERIFIED: mix.exs]

### Wave 0 Gaps
- [ ] `test/threadline/investigation_test.exs` needs new cases for `incident_bundle/2` success, `:not_found`, empty-transaction semantics, and raw-helper non-regression. [VERIFIED: test/threadline/investigation_test.exs]
- [ ] `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` needs `404` coverage for an authenticated caller requesting a nonexistent `audit_transaction_id`, plus success assertions for the bundled JSON contract. [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs]
- [ ] A new `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_json.ex` renderer file is likely needed because the example currently renders inline JSON only. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep the existing authenticated-actor gate in the Phoenix example endpoint; Phase 55 should not change the Phase 51 auth boundary. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] |
| V3 Session Management | no | No new session behavior is introduced in the library or endpoint path. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] |
| V4 Access Control | yes | Authenticated missing transactions should now produce `404`; tenancy and richer authorization remain host-owned and out of scope. [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] |
| V5 Input Validation | yes | Preserve UUID validation via `Ecto.UUID.cast/1` semantics before DB access. [VERIFIED: lib/threadline/query.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] |
| V6 Cryptography | no | Phase 55 introduces no new cryptographic behavior. [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed transaction id input | Tampering | Keep explicit UUID casting and `400` handling in the example path; keep library invalid-id errors precise. [VERIFIED: lib/threadline/query.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] |
| Unauthorized incident drill-down | Information Disclosure | Preserve the authenticated-actor gate and do not broaden authorization scope in this phase. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] |
| Contract drift between library and example payload | Tampering | Render the HTTP payload from the bundle through a JSON module and cover request-path parity in tests. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex] [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs] |

## Sources

### Primary (HIGH confidence)
- `.planning/ROADMAP.md` - Phase 55 scope and plan split. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - `INCIDENT-06` and `INCIDENT-07`. [VERIFIED: file read]
- `.planning/STATE.md` - current phase position and milestone history. [VERIFIED: file read]
- `.planning/MILESTONE-ARC.md` - why investigation ergonomics is the current priority. [VERIFIED: file read]
- `.planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md` - locked Phase 55 decisions. [VERIFIED: file read]
- `.planning/milestones/v1.16-phases/54-investigation-slice-apis/54-CONTEXT.md` and `54-VERIFICATION.md` - raw helper boundary shipped in Phase 54. [VERIFIED: file read]
- `.planning/milestones/v1.16-phases/53-timeline-paging-contract/53-CONTEXT.md` - ordering and paging semantics that must remain unchanged. [VERIFIED: file read]
- `CLAUDE.md` - project constraints and verification conventions. [VERIFIED: file read]
- `lib/threadline.ex`, `lib/threadline/investigation.ex`, `lib/threadline/investigation/linked_change.ex`, `lib/threadline/change_diff.ex`, `lib/threadline/query.ex`, `lib/threadline/capture/audit_transaction.ex`, `lib/threadline/capture/audit_change.ex` - current library seams and result shapes. [VERIFIED: file read]
- `test/threadline/investigation_test.exs`, `test/threadline/query_test.exs` - existing helper semantics and backward-compatibility proof. [VERIFIED: file read]
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex`, `post_json.ex`, `router.ex`, `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs`, `examples/threadline_phoenix/README.md` - current example runtime and docs contract. [VERIFIED: file read]
- `guides/domain-reference.md`, `guides/incident-playbook.md`, `guides/getting-started-saas.md` - current incident drill-down teaching surfaces. [VERIFIED: file read]
- `mix.exs`, `mix.lock`, `examples/threadline_phoenix/mix.exs`, `examples/threadline_phoenix/mix.lock` - stack and verification entrypoints. [VERIFIED: file read]

### Secondary (MEDIUM confidence)
- None. All material claims were verified from local primary sources. [VERIFIED: file read]

### Tertiary (LOW confidence)
- None. [VERIFIED: file read]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - current versions and verification entrypoints were read directly from the repo manifests and lockfiles. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/mix.lock]
- Architecture: HIGH - the relevant library and example seams are already present and the Phase 55 context locks the contract direction. [VERIFIED: lib/threadline.ex] [VERIFIED: lib/threadline/investigation.ex] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md]
- Pitfalls: HIGH - each identified risk is visible in the current implementation or phase boundary docs. [VERIFIED: lib/threadline/investigation.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: .planning/ROADMAP.md]

**Research date:** 2026-05-05
**Valid until:** 2026-06-04 for repo-local planning, unless Phase 55 or adjacent library/example seams change first. [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md]

## RESEARCH COMPLETE
