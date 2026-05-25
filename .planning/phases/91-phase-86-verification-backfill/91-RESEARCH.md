# Phase 91: Phase 86 Verification Backfill - Research

**Researched:** 2026-05-25  
**Domain:** Verification backfill for scoped read-path proof on the current tree [VERIFIED: codebase grep]  
**Confidence:** HIGH [VERIFIED: codebase grep]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01: Phase 91 must use a three-layer proof bar.** Do not treat query-level assertions alone as sufficient closure.
- **D-02: Query-level proof is mandatory.** Verification must explicitly cover `Threadline.history/3`, `Threadline.as_of/4`, `Threadline.row_history/4`, and `Threadline.row_history_page/4` with support-style scoping applied.
- **D-03: Mounted LiveView proof is mandatory.** Verification must show that the scoped row-history path is actually wired through the shipped `/audit` transaction flow, not merely available as a lower-level API.
- **D-04: Example-host and public-proof surfaces should only be included where the repo already claims support-lane truth.** Do not over-promote the example app or docs into proof for support-scoped row history / as-of unless the current tree truly proves that path.

### Truth-first fallback
- **D-05: Use asymmetric truth handling.** If verification exposes only a small, local, same-pass proof gap, a narrow repair is allowed only when it can be fully verified immediately on the current tree.
- **D-06: Prefer narrowing over stretching the claim.** If row history / as-of still lacks proof at the same seriousness level as timeline, actor, and transaction support-lane behavior, keep that path `unclaimed` for support sessions.
- **D-07: Artifact creation is not closure by itself.** The phase only closes when the written verification artifact matches the actual current-tree proof, not the older implementation intent from Phase 86.

### Authority updates when truth changes
- **D-08: If Phase 91 changes the current-tree truth, update every authoritative surface touched by that truth.** This includes the phase artifact plus `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and any public support-lane docs/examples whose wording would otherwise overclaim.
- **D-09: Keep authority updates requirement-scoped and exact.** Only `SCOPE-01` and `SCOPE-02` should move in this phase; do not imply broader v1.21 closeout.
- **D-10: Public wording must follow proof, not implementation aspiration.** If docs currently say support-scoped row history / as-of is `unclaimed`, that wording remains correct unless Phase 91 produces explicit current-tree proof strong enough to change it.

### Locked upstream product posture
- **D-11: Do not reopen the original Phase 86 behavioral decisions.** The locked product direction remains:
  row history / as-of should be scope-enforced when claimed, and coverage is a separate gated admin/global surface.
- **D-12: Keep the support lane host-owned.** Proof should reinforce `scope_query_fn` and `coverage_authorize_fn` as the canonical seams, not invent a Threadline-owned policy layer.

### the agent's Discretion
- Exact choice of proof commands and test subsets, as long as the three-layer verification bar is satisfied.
- Whether a same-pass repair is done in code, tests, docs, or phase artifacts, as long as it is narrowly bounded and fully re-verified immediately.
- Exact wording inside the verification artifact, as long as it states the current-tree truth plainly and distinguishes proven from unclaimed behavior.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCOPE-01 | Support-scoped operators can only see records allowed by the host-owned scope across the supported `/audit` read paths. | Query-level scoping already exists in `Threadline.Query`, but Phase 91 still needs explicit scoped assertions plus mounted `/audit` transaction-history proof to close the support-visible read-path claim. [VERIFIED: codebase grep] |
| SCOPE-02 | Row history / as-of behavior for support-scoped sessions is honest and enforced end to end: either scope-aware with proof, or explicitly unavailable with proof and user-facing messaging. | Current public docs still mark support-scoped row history / as-of as `unclaimed`, so Phase 91 must either add the missing same-seriousness proof and update authority surfaces, or preserve that narrower wording and artifact it explicitly. [VERIFIED: codebase grep] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Threadline has three architecture layers and this phase sits across exploration/operations proof while relying on capture/query primitives; do not conflate capture persistence, semantic actions, and operator-surface behavior. [CITED: CLAUDE.md]
- Use the repo's canonical verification entrypoints when they fit the proof surface: `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all`. [CITED: CLAUDE.md]
- Prefer named verification aliases over ad-hoc commands in docs and artifacts. [CITED: CLAUDE.md]
- Keep domain language exact: `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation` are not interchangeable. [CITED: CLAUDE.md]
- Keep auth and tenant semantics host-owned; this phase must strengthen proof around `scope_query_fn` / `coverage_authorize_fn`, not introduce a Threadline-owned policy layer. [CITED: CLAUDE.md]
- When planning state transitions with GSD, Phase 20 warns that `gsd-sdk query state.begin-phase` must use positional args; keep that convention if Phase 91 execution touches state helpers. [CITED: CLAUDE.md]

## Summary

Phase 91 is a proof phase, not a behavior-design phase. The current tree already contains the row-history scoping implementation seam in `Threadline.Query`, the investigation wrapper passthrough in `Threadline.Investigation`, and the mounted transaction-to-row-history wiring in `TransactionLive` plus `RowHistoryComponent`. Those are implementation facts on the current tree. [VERIFIED: codebase grep]

The planning risk is evidence drift, not missing architecture. Current public surfaces still say support-scoped row history / as-of is `unclaimed`, and the current targeted test coverage I verified does not yet show the same-seriousness scoped proof chain that exists for timeline, actor, transaction, and export posture. Specifically, I found no scoped assertions in `query_test.exs` or `investigation_test.exs`, no dedicated `row_history_component_test.exs`, and only an out-of-scope transaction denial test in the scoped LiveView file. [VERIFIED: codebase grep]

The best plan is therefore binary and truth-first: first prove the existing current-tree behavior through the locked three-layer bar; then only if that proof is complete, promote the claim and update authority surfaces. If the mounted scoped row-history / as-of path still lacks strong proof after targeted test strengthening, keep the path explicitly `unclaimed` and close Phase 91 with honest evidence instead of stretching the claim. [VERIFIED: codebase grep]

**Primary recommendation:** Plan Phase 91 around a three-band closure sequence: strengthen scoped query/helper tests, add mounted `/audit` row-history proof through `TransactionLive`, then update authority surfaces only if that current-tree proof is strong enough to replace the existing `unclaimed` wording. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Scope `history/3` and `as_of/4` | API / Backend | — | These functions compose the final `AuditChange` query and already call `maybe_apply_scope(row_history_scope_opts(...))`. [VERIFIED: codebase grep] |
| Scope `row_history/4` and `row_history_page/4` | API / Backend | — | The investigation helpers delegate to `Threadline.Query`, and the query functions already apply the same row-history scope helper. [VERIFIED: codebase grep] |
| Thread support scope from mounted `/audit` transaction flow into row history | Frontend Server (LiveView) | API / Backend | `TransactionLive` passes `scope` and `scope_query_fn` into `RowHistoryComponent`, which then calls `Threadline.history/3` and `Threadline.as_of/4`. [VERIFIED: codebase grep] |
| Decide whether support-scoped row history is claimed or remains `unclaimed` | Planning / Authority Surface | Docs / Tests | The repo currently treats this as a proof-bound claim, and doc-contract tests enforce the current `unclaimed` wording. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto / `Ecto.Query` | `3.13.5` [VERIFIED: mix deps] | Query composition for scoped audit reads. [VERIFIED: codebase grep] | `Threadline.Query` already centralizes all row-history scoping through Ecto query composition, so Phase 91 should prove that seam instead of adding another abstraction. [VERIFIED: codebase grep] |
| Phoenix LiveView | `1.1.30` [VERIFIED: mix deps] | Mounted `/audit` transaction and history flow. [VERIFIED: codebase grep] | The shipped support surface is a LiveView route tree, and the required mounted proof must pass through that exact path. [VERIFIED: codebase grep] |
| ExUnit | Bundled with Elixir `1.19.5` / Mix `1.19.5` [VERIFIED: mix --version] | Current-tree verification and doc-contract closure. [VERIFIED: codebase grep] | All current proof surfaces for this phase are already test-driven with ExUnit, including doc-contract and mounted-surface suites. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix LiveViewTest | `1.1.30` via `phoenix_live_view` [VERIFIED: mix deps] | Exercise mounted `/audit` routes and history patches. [VERIFIED: codebase grep] | Use for the mandatory mounted transaction-history proof in `transaction_live_test.exs`. [VERIFIED: codebase grep] |
| Repo-backed DataCase | In-repo test support [VERIFIED: codebase grep] | Real query behavior against `Threadline.Test.Repo`. [VERIFIED: codebase grep] | Use for scoped `history/3`, `as_of/4`, `row_history/4`, and `row_history_page/4` assertions. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Scoped proof via current ExUnit + LiveView tests | Manual screenshots or prose-only artifact updates | Reject this. The milestone already treats tests and doc-contracts as authority surfaces; manual proof is weaker and would not satisfy D-01 to D-03. [VERIFIED: codebase grep] |
| Proving the mounted path through `TransactionLive` | Adding a new isolated component-only proof path | Component-only proof is insufficient because D-03 requires the shipped `/audit` transaction flow, not only lower-level APIs or isolated component behavior. [VERIFIED: codebase grep] |

**Installation:** No new packages are recommended for this phase. Reuse the current repo stack. [VERIFIED: codebase grep]

**Version verification:** Existing repo stack versions were confirmed with `mix --version` and `mix deps`; no dependency additions are needed for Phase 91. [VERIFIED: mix deps]

## Architecture Patterns

### System Architecture Diagram

```text
support operator session
  -> /audit/transactions/:id/history/:table/:record_id [mounted LiveView route]
  -> Threadline.OperatorSurface.Auth.on_mount/4 [host authorize_fn establishes opaque scope]
  -> TransactionLive.handle_params/3 [history params parsed]
  -> RowHistoryComponent.update/2 [scope + scope_query_fn threaded into opts]
  -> Threadline.history/3 and Threadline.as_of/4
  -> Threadline.Query.maybe_apply_scope(row_history_scope_opts(...))
  -> host-owned scope_query_fn(query, scope, %{surface, params})
  -> Postgres-backed Threadline.Test.Repo / host repo
  -> rendered history + snapshot OR truthful unsupported/unclaimed authority wording
```

The planner should treat this as one proof chain with three required checkpoints: query seam, investigation/helper seam, and mounted route seam. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
lib/
├── threadline/query.ex                           # Canonical row-history/as-of scope application
├── threadline/investigation.ex                   # Public helper passthrough to scoped query layer
└── threadline/operator_surface/live/             # Mounted /audit transaction + row-history path
test/
├── threadline/query_test.exs                     # Direct scoped history/as_of proof
├── threadline/investigation_test.exs             # Direct scoped row_history/page proof
└── threadline/operator_surface/transaction_live_test.exs
                                                # Mounted /audit row-history proof
guides/
├── operator-surface.md
├── upgrade-path.md
└── getting-started-saas.md                       # Public truth surfaces that may need updates
.planning/
└── phases/86-scoped-read-path-closure/           # Destination for 86-VERIFICATION.md / 86-VALIDATION.md
```

### Pattern 1: Reuse the existing row-history scope seam
**What:** `history/3`, `as_of/4`, `row_history/4`, and `row_history_page/4` already route row-history scoping through `maybe_apply_scope(row_history_scope_opts(...))`. [VERIFIED: codebase grep]  
**When to use:** Use this as the primary backend proof band before touching docs or artifacts. [VERIFIED: codebase grep]  
**Example:**
```elixir
def row_history(schema_module, id, filters \\ [], opts \\ [])
    when is_list(filters) and is_list(opts) do
  validate_row_history_filters!(filters)
  repo = timeline_repo!(filters, opts)

  schema_module
  |> row_history_query(id, filters)
  |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
  |> repo.all()
end
```
Source: `lib/threadline/query.ex` [VERIFIED: codebase grep]

### Pattern 2: Prove helper parity, not just raw queries
**What:** `Threadline.Investigation.row_history/4` and `row_history_page/4` are the public helper path and must stay aligned with query-level scope behavior. [VERIFIED: codebase grep]  
**When to use:** Add direct scoped assertions here so the planner closes the public helper contract, not only private query composition. [VERIFIED: codebase grep]  
**Example:**
```elixir
def row_history(schema_module, id, filters \\ [], opts \\ []) do
  filters = validate_helper_filters!(filters, @allowed_row_history_filter_keys, :row_history)

  schema_module
  |> Query.row_history(id, filters, opts)
  |> linked_changes(opts)
end
```
Source: `lib/threadline/investigation.ex` [VERIFIED: codebase grep]

### Pattern 3: Mounted proof must pass through `TransactionLive`
**What:** The shipped row-history UI path is `/transactions/:id/history/:table/:record_id`, and `TransactionLive` passes `scope` plus `scope_query_fn` into `RowHistoryComponent`. [VERIFIED: codebase grep]  
**When to use:** Add or strengthen tests here instead of treating isolated component tests as sufficient. [VERIFIED: codebase grep]  
**Example:**
```elixir
<.live_component
  module={Threadline.OperatorSurface.Live.RowHistoryComponent}
  id="row-history"
  table={@history_table}
  record_id={@history_record_id}
  as_of={@history_as_of}
  base_path={@base_path}
  threadline_schemas={@threadline_schemas}
  repo={@threadline_repo}
  scope={@threadline_scope}
  scope_query_fn={@threadline_scope_query_fn}
/>
```
Source: `lib/threadline/operator_surface/live/transaction_live.ex` [VERIFIED: codebase grep]

### Pattern 4: Authority surfaces must follow proof strength
**What:** Doc-contract tests currently lock `unclaimed` wording for support-scoped row history / as-of across multiple guides. [VERIFIED: codebase grep]  
**When to use:** Only edit those docs in the same pass if Phase 91 produces equivalent-strength current-tree proof. [VERIFIED: codebase grep]  
**Example:**
```elixir
assert String.contains?(guide, "support-scoped claim is currently `unclaimed`")
assert String.contains?(guide, "treat that path as `unclaimed` for support sessions")
```
Source: `test/threadline/operator_surface_doc_contract_test.exs` [VERIFIED: codebase grep]

### Anti-Patterns to Avoid
- **Artifact-only closure:** Writing `86-VERIFICATION.md` without adding or rerunning the missing proof bands would violate D-07 and repeat the original verification gap. [VERIFIED: codebase grep]
- **Query-only victory:** Passing backend scope tests alone is not enough because D-03 requires mounted `/audit` proof. [VERIFIED: codebase grep]
- **Premature doc promotion:** Rewriting guides from `unclaimed` to claimed before mounted proof exists would break current doc-contract expectations and overstate the support lane. [VERIFIED: codebase grep]
- **New policy layer:** Do not add Threadline-owned roles/tenant rules; Phase 91 should reinforce `scope_query_fn` as the host-owned seam already used by the repo. [CITED: CLAUDE.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Support-lane scoping proof | A new policy abstraction or fake adapter | Existing `scope_query_fn` + `maybe_apply_scope` seam | The current tree already routes scope through these seams; adding another layer increases surface area without closing the actual evidence gap. [VERIFIED: codebase grep] |
| Mounted history verification | Browser-manual proof only | `Phoenix.LiveViewTest` against `transaction_live_test.exs` | The repo already proves mounted surfaces through LiveView tests, and the phase requires repeatable current-tree evidence. [VERIFIED: codebase grep] |
| Requirement closure bookkeeping | Broad milestone edits | Requirement-scoped updates to `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` only if truth changes | Phase 90 already established narrow authority-surface reconciliation as the pattern for verification backfills. [VERIFIED: codebase grep] |

**Key insight:** The shortest safe path is to prove the tree the repo already has, not to redesign it. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Mistaking implementation presence for support-lane proof
**What goes wrong:** The planner assumes row-history is already closed because `Threadline.Query` and `TransactionLive` contain the scope threading. [VERIFIED: codebase grep]  
**Why it happens:** The current tree does contain those seams, but public docs and current tests still stop short of proving the support-scoped path at the same seriousness level. [VERIFIED: codebase grep]  
**How to avoid:** Treat implementation and proof as separate deliverables; Phase 91 must explicitly strengthen tests and/or preserve `unclaimed` wording. [VERIFIED: codebase grep]  
**Warning signs:** No scoped assertions in `query_test.exs` / `investigation_test.exs`; no mounted row-history assertion in `transaction_live_test.exs`; current docs still say `unclaimed`. [VERIFIED: codebase grep]

### Pitfall 2: Updating docs before deciding truth
**What goes wrong:** The plan edits guides and README surfaces early, then later discovers mounted proof is still weak. [VERIFIED: codebase grep]  
**Why it happens:** The current doc-contract suite already encodes the narrower claim, so premature promotion creates avoidable churn. [VERIFIED: codebase grep]  
**How to avoid:** Sequence work as proof first, authority updates second. [VERIFIED: codebase grep]  
**Warning signs:** Planner schedules guide edits before query/helper/mounted test additions. [VERIFIED: codebase grep]

### Pitfall 3: Relying on component-only proof
**What goes wrong:** A planner adds a new isolated component test and treats that as mounted closure. [VERIFIED: codebase grep]  
**Why it happens:** `RowHistoryComponent` is easy to target in isolation, but D-03 requires proof through the shipped transaction route. [VERIFIED: codebase grep]  
**How to avoid:** Keep `TransactionLive` as the primary mounted proof seam; add component tests only if they materially reduce ambiguity. [VERIFIED: codebase grep]  
**Warning signs:** No `live(conn, "/audit_scoped/transactions/.../history/...")`-style proof or equivalent route-driven assertion appears in the plan. [ASSUMED]

## Code Examples

Verified patterns from the current tree:

### Scoped row-history helper in the query layer
```elixir
defp row_history_scope_opts(schema_module, id, opts) do
  [
    scope: Keyword.get(opts, :scope),
    scope_query_fn: Keyword.get(opts, :scope_query_fn),
    surface: Keyword.get(opts, :surface, :row_history),
    params: %{schema_module: schema_module, id: id}
  ]
end
```
Source: `lib/threadline/query.ex` [VERIFIED: codebase grep]

### Mounted transaction flow threads scope into row history
```elixir
opts = [
  repo: assigns.repo,
  scope: assigns[:scope],
  scope_query_fn: assigns[:scope_query_fn]
]

history = Threadline.history(schema_module, assigns.record_id, opts)
snapshot = Threadline.as_of(schema_module, assigns.record_id, as_of_dt, opts)
```
Source: `lib/threadline/operator_surface/live/row_history_component.ex` [VERIFIED: codebase grep]

### Current doc-contract guard for the narrower public claim
```elixir
assert String.contains?(guide, "history / as-of remains `unclaimed`")
assert String.contains?(guide, "keep support-lane row-history / as-of wording narrower")
```
Source: `test/threadline/upgrade_path_doc_contract_test.exs`, `test/threadline/getting_started_saas_doc_contract_test.exs` [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat original Phase 86 implementation intent as closure | Close only against current-tree proof and authority wording | By 2026-05-25 Phase 90 backfill pattern [VERIFIED: planning artifact] | Phase 91 must verify or narrow; it cannot inherit closure from older implementation intent. [VERIFIED: codebase grep] |
| Broad support-lane narrative | Explicit `supported` / `reference` / `unclaimed` wording in guides and doc-contract tests | Current v1.21 planning surface and docs [VERIFIED: codebase grep] | Public support-lane promotion now requires concrete proof, not plausibility. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Assuming row-history / as-of is already in the named support-lane claim is outdated relative to current guides and doc-contract tests. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A mounted proof assertion will likely take the form of a direct `/audit_scoped/transactions/:id/history/:table/:record_id` LiveView test or an equivalent route-driven assertion. | Common Pitfalls | Low. The exact test shape can vary, but the planner still needs mounted route proof through `TransactionLive`. |

## Open Questions (RESOLVED)

1. **Does the current mounted `/audit` history route already prove support-scoped row history if targeted tests are added, or is there still a behavioral gap?**
   - What we know: The code path threads `scope` and `scope_query_fn` into `RowHistoryComponent`, and current targeted tests passed. [VERIFIED: codebase grep]
   - Resolution: Treat this as the primary execution checkpoint, not a planning ambiguity. Plan `91-01` must add the missing mounted scoped-history assertion and then choose the truth branch from the result: if the route proves cleanly with narrow tests, the claim may be promoted; if not, the Phase 91 verdict must keep support-scoped row history / as-of `unclaimed` and document the exact limit. [VERIFIED: codebase grep]

2. **Should Phase 91 update example-host surfaces?**
   - What we know: Context D-04 says example-host proof should only be included where the repo already claims support-lane truth, and the current example README explicitly says row history / as-of is not yet proof. [VERIFIED: codebase grep]
   - Resolution: Example-host wording is conditional follow-on only if the root library proof is promoted in the same pass and the example surface is actually part of that proof chain. Otherwise Phase 91 should leave the example-host wording unchanged and let Phase 92 own any broader example-proof promotion. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | All test and verification commands | ✓ [VERIFIED: shell probe] | Mix `1.19.5` [VERIFIED: mix --version] | — |
| `elixir` | ExUnit / LiveView test execution | ✓ [VERIFIED: shell probe] | Elixir `1.19.5` with OTP `28` [VERIFIED: mix --version] | — |
| PostgreSQL local server | Repo-backed test suite in `config/test.exs` | ✓ [VERIFIED: shell probe] | `psql 14.17`; `pg_isready` accepted on `localhost:5432` [VERIFIED: shell probe] | — |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: shell probe]

**Missing dependencies with fallback:**
- None found. [VERIFIED: shell probe]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix LiveViewTest + doc-contract tests [VERIFIED: codebase grep] |
| Config file | `mix.exs`, `config/test.exs` [VERIFIED: codebase grep] |
| Quick run command | `MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/transaction_live_test.exs --max-failures 1` [VERIFIED: command run] |
| Full suite command | `mix verify.test` for full root tests; `mix verify.example` only if Phase 91 truth promotion touches example-host proof. [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCOPE-01 | Support scope applies across supported mounted read paths, including transaction drill-down and any claimed row-history path. [VERIFIED: requirements + context] | unit + mounted integration | `MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/transaction_live_test.exs --max-failures 1` | ✅ but scoped assertions are incomplete today. [VERIFIED: codebase grep] |
| SCOPE-02 | Row history / as-of is either scope-aware with proof or explicitly unavailable with matching user-facing wording. [VERIFIED: requirements + context] | mounted integration + doc-contract | `MIX_ENV=test mix test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` | ✅ but current docs lock the narrower `unclaimed` truth. [VERIFIED: codebase grep] |

### Sampling Rate
- **Per task commit:** Re-run the targeted scoped proof slice after every change to query/helper tests or mounted history tests. [VERIFIED: codebase grep]
- **Per wave merge:** Re-run the doc-contract subset if any public wording changes. [VERIFIED: codebase grep]
- **Phase gate:** Full targeted proof green, plus example-host verification only if the phase changes example-host truth. [VERIFIED: codebase grep]

### Wave 0 Gaps
- [ ] Add explicit scoped assertions to `test/threadline/query_test.exs` for `Threadline.history/3` and `Threadline.as_of/4`; current tests verify behavior but not support-style scope narrowing. [VERIFIED: codebase grep]
- [ ] Add explicit scoped assertions to `test/threadline/investigation_test.exs` for `Threadline.row_history/4` and `Threadline.row_history_page/4`; current tests verify row filtering and paging but not host scope application. [VERIFIED: codebase grep]
- [ ] Strengthen `test/threadline/operator_surface/transaction_live_test.exs` to prove the mounted row-history route through the scoped `/audit` tree; current scoped proof only covers out-of-scope transaction denial. [VERIFIED: codebase grep]
- [ ] Create `86-VERIFICATION.md` and `86-VALIDATION.md` only after the proof verdict is known. [VERIFIED: planning artifact]
- [ ] If proof promotes the public claim, update the matching doc-contract assertions and affected guide/example wording in the same pass. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: CLAUDE + codebase scope] | Host app owns authentication before Threadline mount. [CITED: CLAUDE.md] |
| V3 Session Management | no [VERIFIED: codebase scope] | Not the primary concern of this phase; the phase verifies scoped read behavior after session auth. [VERIFIED: codebase grep] |
| V4 Access Control | yes [VERIFIED: requirements + context] | Host-owned `authorize_fn` + `scope_query_fn` + mounted LiveView proof. [VERIFIED: codebase grep] |
| V5 Input Validation | yes [VERIFIED: codebase grep] | Existing filter validation in `Threadline.Query` / `Threadline.Investigation`; tests should ensure scoped params flow is valid and bounded. [VERIFIED: codebase grep] |
| V6 Cryptography | no [VERIFIED: phase scope] | No crypto behavior is changed or verified in this phase. [VERIFIED: codebase grep] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant historical row disclosure through unscoped `history/3` / `as_of/4` | Information Disclosure | Prove `maybe_apply_scope(row_history_scope_opts(...))` with host-owned `scope_query_fn`. [VERIFIED: codebase grep] |
| Mounted `/audit` history route bypassing backend scope wiring | Elevation of Privilege | Prove `TransactionLive` -> `RowHistoryComponent` -> `Threadline.history/3` / `as_of/4` end to end. [VERIFIED: codebase grep] |
| Public docs overstating support-lane safety | Repudiation / Information Disclosure | Keep doc-contract surfaces aligned with the strongest current-tree proof only. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- `CLAUDE.md` - architecture layers, domain language, canonical verification aliases, and host-owned auth/scope posture. [CITED: CLAUDE.md]
- `.planning/phases/91-phase-86-verification-backfill/91-CONTEXT.md` - locked decisions, proof bar, truth-first fallback, and authority-update rules. [CITED: 91-CONTEXT.md]
- `.planning/REQUIREMENTS.md` - `SCOPE-01` and `SCOPE-02` contract. [CITED: REQUIREMENTS.md]
- `lib/threadline/query.ex` - current row-history/as-of scope implementation seam. [VERIFIED: codebase grep]
- `lib/threadline/investigation.ex` - helper passthrough for row-history public APIs. [VERIFIED: codebase grep]
- `lib/threadline/operator_surface/live/transaction_live.ex` and `row_history_component.ex` - mounted `/audit` history wiring. [VERIFIED: codebase grep]
- `test/threadline/query_test.exs`, `test/threadline/investigation_test.exs`, `test/threadline/operator_surface/transaction_live_test.exs` - current proof coverage and current gaps. [VERIFIED: codebase grep]
- `guides/operator-surface.md`, `guides/upgrade-path.md`, `guides/getting-started-saas.md`, `examples/threadline_phoenix/README.md` - current public truth surfaces. [VERIFIED: codebase grep]
- `mix.exs`, `config/test.exs` - aliases, test environment, and current versions/runtimes. [VERIFIED: codebase grep]
- Commands run on 2026-05-25:
  - `mix --version`
  - `mix deps | rg 'phoenix|ecto|jason|plug|telemetry'`
  - `MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/transaction_live_test.exs --max-failures 1`
  - `MIX_ENV=test mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1`

### Secondary (MEDIUM confidence)
- None. This research did not need external ecosystem sources because the phase is about current-tree proof and authority surfaces. [VERIFIED: scope reasoning]

### Tertiary (LOW confidence)
- None. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Versions and aliases were confirmed locally with `mix --version`, `mix deps`, and `mix.exs`. [VERIFIED: local commands]
- Architecture: HIGH - The relevant implementation seams and route wiring were read directly from the current tree. [VERIFIED: codebase grep]
- Pitfalls: HIGH - They come from direct mismatch between current code, tests, and doc-contract surfaces. [VERIFIED: codebase grep]

**Research date:** 2026-05-25  
**Valid until:** 2026-06-24 for planning on this repo state, or earlier if Phase 91 implementation changes the scoped row-history claim. [VERIFIED: current-tree scope]
