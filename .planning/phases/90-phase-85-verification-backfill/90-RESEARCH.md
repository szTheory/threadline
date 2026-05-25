# Phase 90: phase-85-verification-backfill - Research

**Researched:** 2026-05-25 [VERIFIED: user prompt]  
**Domain:** Current-tree verification backfill for the original Phase 85 support-lane claim boundary, shared auth callback contract, and minimal-controls posture [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v1.21-MILESTONE-AUDIT.md]  
**Confidence:** HIGH [VERIFIED: root focused test commands] [VERIFIED: repository artifact review]

## User Constraints

- No `90-CONTEXT.md` exists; scope this research to roadmap, requirements, prior phase artifacts, and current-tree evidence rather than new discuss-phase decisions. [VERIFIED: user prompt]
- Phase 90 goal: "Close the unverified Phase 85 claim boundary with explicit current-tree proof and requirement closure." [VERIFIED: .planning/ROADMAP.md]
- Phase 90 depends on Phase 89. [VERIFIED: .planning/ROADMAP.md]
- Phase 90 must address `SCOPE-03`, `AUTH-02`, and `ADOPT-03`. [VERIFIED: user prompt] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
- Phase 90 exists because Phase 85 has summaries and context, but no verification artifact. [VERIFIED: .planning/v1.21-MILESTONE-AUDIT.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCOPE-03 | The support-lane claim names exactly which operator surfaces are proven safe today and excludes the rest. [VERIFIED: .planning/REQUIREMENTS.md] | Current-tree docs now narrow support-scoped row history / as-of out of the claimed lane, and focused contract tests plus example proof pass on that narrower truth. [VERIFIED: guides/operator-surface.md] [VERIFIED: guides/upgrade-path.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md] [VERIFIED: mix verify.example] |
| AUTH-02 | One shared `%{assigns: assigns}` authorization callback remains the canonical contract across LiveView and HTTP export faces, with stable telemetry on granted / denied / error outcomes. [VERIFIED: .planning/REQUIREMENTS.md] | The LiveView auth hook and export auth plug both use the same callback vocabulary and telemetry event, and dedicated tests passed on the current tree. [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] [VERIFIED: test/threadline/operator_surface/auth_test.exs] [VERIFIED: test/threadline/operator_surface/export_auth_plug_test.exs] |
| ADOPT-03 | Any new surface controls added in this milestone stay minimal and additive; Threadline does not introduce a role DSL, tenancy DSL, or policy engine. [VERIFIED: .planning/REQUIREMENTS.md] | The public guides and contract tests still lock host-owned `authorize_fn`, `scope_query_fn`, and optional `export_authorize_fn`, and explicitly reject DSL expansion. [VERIFIED: guides/integration-contracts.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: test/threadline/integration_contracts_doc_contract_test.exs] [VERIFIED: test/threadline/operator_surface_doc_contract_test.exs] |
</phase_requirements>

## Summary

Phase 90 should be planned as a verification and evidence-reconciliation phase, not as a fresh implementation phase. The current repo already has passing proof for the surviving support-lane contract: root contract/auth tests passed (`57 tests, 0 failures`), focused root behavior tests passed (`42 tests, 0 failures`), and the named nested example proof `mix verify.example` passed (`21 tests, 0 failures`). [VERIFIED: root focused test commands] [VERIFIED: mix verify.example]

The main planning constraint is that Phase 85's original lock is no longer the truthful contract. Phase 85 asserted that support-scoped row history / as-of would be included and safely scoped, but Phase 89 verified a narrower current-tree truth: row history / as-of remains part of the product surface, yet is `unclaimed` for support-scoped sessions on the current repo tree. Phase 90 therefore must verify the current-tree claim boundary honestly and record that Phase 85's original broader wording has been superseded by the narrower verified contract. [VERIFIED: .planning/phases/85-support-lane-surface-audit/85-CONTEXT.md] [VERIFIED: .planning/phases/85-support-lane-surface-audit/85-01-SUMMARY.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md]

Phase 90 should also close the missing requirement-evidence chain that the milestone audit called out. Existing tests and docs already prove the shared `%{assigns: assigns}` callback seam and the minimal/additive control boundary, so the execution work should focus on rerunning named proof, writing `90-VERIFICATION.md`, and updating requirement closure evidence without widening the product claim or reopening Phase 86/89 scope. [VERIFIED: .planning/v1.21-MILESTONE-AUDIT.md] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] [VERIFIED: test/threadline/operator_surface_doc_contract_test.exs] [VERIFIED: test/threadline/integration_contracts_doc_contract_test.exs]

**Primary recommendation:** Plan Phase 90 as a two-part backfill: rerun the current-tree proof for `SCOPE-03`, `AUTH-02`, and `ADOPT-03`, then write a verification artifact that explicitly says Phase 85's row-history inclusion claim was narrowed by Phase 89 and that the narrower contract is the only truthful closure baseline now. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Support-lane claim boundary (`supported` vs `unclaimed`) [VERIFIED: guides/operator-surface.md] [VERIFIED: guides/upgrade-path.md] | Frontend Server (SSR) | API / Backend | The claimed `/audit` surface is expressed through mounted LiveView routes and guide text, but its truth depends on backend scoping and denial behavior. [VERIFIED: guides/operator-surface.md] [VERIFIED: lib/threadline/operator_surface/auth.ex] |
| Shared `%{assigns: assigns}` auth contract across LV and export [VERIFIED: guides/integration-contracts.md] | API / Backend | Frontend Server (SSR) | The contract is implemented in `Auth.on_mount/4` and `ExportAuthPlug.call/2`; LiveView only consumes that backend-owned decision vocabulary. [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] |
| Minimal additive controls boundary (`authorize_fn`, `scope_query_fn`, optional `export_authorize_fn`) [VERIFIED: guides/integration-contracts.md] | API / Backend | Frontend Server (SSR) | The host-owned callbacks are library seam contracts, not browser features or storage policy objects. [VERIFIED: guides/integration-contracts.md] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] |
| Requirement closure evidence and verification artifact [VERIFIED: .planning/ROADMAP.md] | API / Backend | — | The proof comes from testable library/runtime behavior plus phase artifacts, not from browser-only inspection. [VERIFIED: test/threadline/operator_surface/auth_test.exs] [VERIFIED: test/threadline/operator_surface/export_auth_plug_test.exs] |

## Project Constraints (from CLAUDE.md)

- Keep the three-layer boundary intact: capture owns durable row mutation truth, semantics owns action intent, and exploration/operations owns timelines, diffs, as-of, exports, health, retention, and operator workflows. [VERIFIED: CLAUDE.md]
- Use Threadline domain terms consistently: `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation`. [VERIFIED: CLAUDE.md]
- Prefer named verification entrypoints over ad-hoc commands: `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all`. [VERIFIED: CLAUDE.md]
- Treat README, guides, and example README as contract surfaces, with doc-contract tests as part of the quality bar. [VERIFIED: CLAUDE.md]
- Keep CI job ids stable. [VERIFIED: CLAUDE.md] [VERIFIED: .github/workflows/ci.yml]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `1.19.5` local runtime; project floor `~> 1.15` [VERIFIED: `elixir --version`] [VERIFIED: mix.exs] | Compile and run the repo plus Mix verification commands. [VERIFIED: mix.exs] | Phase 90 proof is Mix/ExUnit-driven and should run against the real local runtime plus the repo-declared floor. [VERIFIED: mix.exs] |
| ExUnit / Mix aliases | `1.19.5` via local Mix [VERIFIED: `mix --version`] | Named verification entrypoints and focused test execution. [VERIFIED: mix.exs] | The repo already encodes proof in `verify.doc_contract`, `verify.example`, `verify.test`, and `ci.all`; do not invent a new verification harness. [VERIFIED: mix.exs] |
| Phoenix operator surface stack | Phoenix `1.8.7`, LiveView `1.1.30`, Phoenix HTML `4.3.0`, Phoenix PubSub `2.2.0` [VERIFIED: mix.lock] | Mounted `/audit` surface and route-level support-lane behavior. [VERIFIED: mix.lock] | These are the root current tested resolutions named in the support-lane compatibility docs and covered by doc-contract tests. [VERIFIED: guides/upgrade-path.md] [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] |
| Ecto SQL / PostgreSQL | Ecto SQL `3.13.5`, Postgrex `0.22.0`, local `psql 14.17` [VERIFIED: mix.lock] [VERIFIED: `psql --version`] | Real DB-backed integration proof for operator-surface queries and exports. [VERIFIED: test/test_helper.exs] | The repo intentionally uses real PostgreSQL integration tests rather than SQL sandbox for trigger correctness. [VERIFIED: test/support/data_case.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jason | `1.4.4` [VERIFIED: mix.lock] | Session actor serialization and export/auth test payloads. [VERIFIED: lib/threadline/operator_surface/auth.ex] | Needed when verifying actor/session handoff and JSON export surfaces. [VERIFIED: test/threadline/operator_surface/auth_test.exs] |
| NimbleCSV | `1.3.0` [VERIFIED: mix.lock] | CSV export behavior under the shared auth/export seam. [VERIFIED: mix.lock] | Relevant for export denial/parity proof that Phase 90 may cite for `AUTH-02`. [VERIFIED: test/threadline/operator_surface/controllers/export_controller_test.exs] |
| Docker | `29.4.1` local [VERIFIED: `docker --version`] | Fallback for local PostgreSQL boot if the DB is absent. [VERIFIED: test/test_helper.exs] | Use only when the local DB is unavailable; the repo hint is `docker compose up -d`. [VERIFIED: test/test_helper.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `mix verify.example` [VERIFIED: mix.exs] | Running the example test file directly from the repo root [VERIFIED: root example compile failure] | Incorrect from root: `examples/.../operator_surface_test.exs` depends on the nested example app `ConnCase` and failed to compile from the root project. [VERIFIED: root example compile failure] |
| Focused root proof commands [VERIFIED: root focused test commands] | `mix ci.all` alone [VERIFIED: mix.exs] | `mix ci.all` is still the full-suite gate, but it can fail for unrelated formatting drift and is too noisy to be the only Phase 90 proof source. [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VALIDATION.md] |
| Existing doc-contract suites [VERIFIED: mix.exs] | Writing a new custom verifier for claim text | Unnecessary: the repo already has locked contract tests for the exact docs and wording surfaces Phase 90 needs. [VERIFIED: test/threadline/operator_surface_doc_contract_test.exs] [VERIFIED: test/threadline/integration_contracts_doc_contract_test.exs] |

**Installation:** Existing repo stack only; no new dependency is recommended for Phase 90. [VERIFIED: mix.exs]

```bash
mix deps.get
```

**Version verification:** Root current tested resolutions came from `mix.lock`; example-host proof came from `mix verify.example` resolving the nested example stack in this session. [VERIFIED: mix.lock] [VERIFIED: mix verify.example]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 85 lock artifacts
  + current requirements/roadmap
  + current guides/example/router
  + auth/export implementation
  + focused tests / named aliases
            |
            v
   Compare original Phase 85 claim
   against current-tree contract truth
            |
            +--> If still true today -> record direct proof
            |
            +--> If narrowed or superseded -> record the narrower truth
                 and cite the superseding artifact
            |
            v
   Write 90-VERIFICATION.md
            |
            +--> requirement closure evidence (`SCOPE-03`, `AUTH-02`, `ADOPT-03`)
            +--> explicit command log
            +--> no new scope widening
```

### Recommended Project Structure

```text
.planning/phases/90-phase-85-verification-backfill/
├── 90-RESEARCH.md        # this research artifact
├── 90-01-PLAN.md         # focused proof rerun
├── 90-02-PLAN.md         # verification artifact + requirement closure
└── 90-VERIFICATION.md    # current-tree evidence log
```

### Pattern 1: Verify The Current Tree, Not The Historical Intent

**What:** Treat Phase 90 as proof of the repo as it exists now, even when that means recording that Phase 85's earlier wording was superseded. [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md]  
**When to use:** Any backfill phase where earlier plan summaries conflict with later verified contract truth. [VERIFIED: .planning/v1.21-MILESTONE-AUDIT.md]  
**Example:**

```bash
# Source: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md
mix verify.doc_contract
MIX_ENV=test mix test \
  test/threadline/operator_surface_doc_contract_test.exs \
  test/threadline/integration_contracts_doc_contract_test.exs \
  test/threadline/operator_surface/auth_test.exs \
  test/threadline/operator_surface/export_auth_plug_test.exs \
  test/threadline/operator_surface/controllers/export_controller_test.exs \
  test/threadline/operator_surface/live/timeline_live_test.exs \
  --max-failures 1
mix verify.example
```

### Pattern 2: Use Layered Proof Bands

**What:** Verify one requirement boundary across four bands: public docs, root runtime behavior, example-host proof, and named verification entrypoints. [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-RESEARCH.md]  
**When to use:** Requirement closures that are part behavior and part product-contract wording. [VERIFIED: .planning/REQUIREMENTS.md]  
**Example:**

```text
docs -> guides/operator-surface.md + guides/upgrade-path.md + guides/getting-started-saas.md
runtime -> Auth.on_mount/4 + ExportAuthPlug.call/2 + focused operator-surface tests
example -> examples/threadline_phoenix router + mix verify.example
named proof -> mix verify.doc_contract + mix verify.example + CI job ids
```

### Anti-Patterns to Avoid

- **Re-proving the obsolete Phase 85 row-history promise:** Phase 89 already narrowed the truthful claim; Phase 90 should verify that narrower truth, not invent fresh row-history support proof. [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md]
- **Using root-path compilation for nested example tests:** The example file depends on example-local test helpers; use `mix verify.example`. [VERIFIED: root example compile failure] [VERIFIED: mix.exs]
- **Treating `mix ci.all` as the only signal:** It is the phase gate, not the only investigative tool. Targeted proof is required for honest diagnosis. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VALIDATION.md]
- **Parallelizing DB-backed suites blindly:** The repo uses a real PostgreSQL DB without sandboxing, so planner tasks should serialize the heavy DB-backed proof commands. [VERIFIED: test/support/data_case.ex] [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-RESEARCH.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Requirement closure ledger [VERIFIED: .planning/v1.21-MILESTONE-AUDIT.md] | A fresh ad-hoc checklist or narrative-only summary | `90-VERIFICATION.md` plus the existing requirements mapping surfaces [VERIFIED: .planning/REQUIREMENTS.md] | The milestone audit already identifies the missing evidence shape; Phase 90 should close that exact gap, not invent a second bookkeeping format. [VERIFIED: .planning/v1.21-MILESTONE-AUDIT.md] |
| Shared auth seam proof [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] | A new mock auth harness | Existing `auth_test.exs`, `export_auth_plug_test.exs`, `export_controller_test.exs`, and example proof [VERIFIED: test/threadline/operator_surface/auth_test.exs] [VERIFIED: test/threadline/operator_surface/export_auth_plug_test.exs] [VERIFIED: test/threadline/operator_surface/controllers/export_controller_test.exs] [VERIFIED: mix verify.example] | The seam is already codified and tested across both transports. [VERIFIED: root focused test commands] |
| Minimal-controls boundary proof [VERIFIED: .planning/REQUIREMENTS.md] | Snapshotting more docs or adding a role-model prototype | Existing doc-contract suites and guide literals [VERIFIED: test/threadline/operator_surface_doc_contract_test.exs] [VERIFIED: test/threadline/integration_contracts_doc_contract_test.exs] | The requirement is explicitly "minimal and additive"; building more control surface would violate the requirement while trying to verify it. [VERIFIED: .planning/REQUIREMENTS.md] |

**Key insight:** Phase 90 should consume existing proof surfaces and convert them into missing verification evidence; it should not widen runtime scope, add new abstractions, or create a second verification framework. [VERIFIED: .planning/v1.21-MILESTONE-AUDIT.md] [VERIFIED: mix.exs]

## Common Pitfalls

### Pitfall 1: Verifying The Wrong Claim

**What goes wrong:** The planner tries to "close Phase 85" by proving row-history/as-of support scoping because that was the original Phase 85 wording. [VERIFIED: .planning/phases/85-support-lane-surface-audit/85-CONTEXT.md]  
**Why it happens:** Phase 85 summaries still record the broader claim, but Phase 89 later narrowed the truthful contract. [VERIFIED: .planning/phases/85-support-lane-surface-audit/85-01-SUMMARY.md] [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md]  
**How to avoid:** Make `90-VERIFICATION.md` explicitly state that current-tree closure is based on the narrower Phase 89 contract. [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md]  
**Warning signs:** Any Phase 90 plan item that creates new row-history support tests or code instead of backfill evidence. [VERIFIED: .planning/ROADMAP.md]

### Pitfall 2: Mixing Example-Host Proof With Root-App Proof

**What goes wrong:** The example test file is run from the root project and fails, producing a false negative. [VERIFIED: root example compile failure]  
**Why it happens:** The example file depends on `ThreadlinePhoenixWeb.ConnCase`, which exists only inside the nested example project. [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs]  
**How to avoid:** Use `mix verify.example` as the named root entrypoint for example-host proof. [VERIFIED: mix.exs]  
**Warning signs:** Commands that reference `examples/.../operator_surface_test.exs` directly from the repo root. [VERIFIED: root example compile failure]

### Pitfall 3: Using `mix ci.all` As Investigative Proof

**What goes wrong:** A noisy full-suite failure obscures whether the Phase 90 boundary is actually broken. [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VALIDATION.md]  
**Why it happens:** `mix ci.all` includes formatting and unrelated checks, and the local tree may already be dirty. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VALIDATION.md]  
**How to avoid:** Use focused proof commands first, then run `mix ci.all` once as the final honest phase gate. [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VALIDATION.md]  
**Warning signs:** A plan that offers only `mix ci.all` and no targeted reruns for the three Phase 90 requirements. [VERIFIED: .planning/REQUIREMENTS.md]

## Code Examples

Verified patterns from the current tree:

### Shared `%{assigns: assigns}` Callback Contract

```elixir
# Source: guides/integration-contracts.md
def authorize_operator(%{assigns: assigns}) do
  case assigns[:current_user] do
    %{role: :admin} ->
      :ok

    %{role: :support, organization_id: org_id} ->
      {:ok, %{access: :support_read_only, organization_id: org_id}}

    _ ->
      {:error, :unauthorized}
  end
end
```

### Export Fallback Mirror

```elixir
# Source: lib/threadline/operator_surface/export_auth_plug.ex
mirror = %{assigns: conn.assigns}
authorize_fn.(mirror)
```

### Example-Host Minimal Additive Mount

```elixir
# Source: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
threadline_operator_surface "/",
  actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
  authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
  export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
  scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
  repo: ThreadlinePhoenix.Repo
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 85 lock claimed support-lane safety for timeline, actor, transaction, and row history/as-of. [VERIFIED: .planning/phases/85-support-lane-surface-audit/85-CONTEXT.md] | The verified current-tree contract claims timeline, actor, transaction, and export-auth seams, while support-scoped row history/as-of is `unclaimed`. [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md] [VERIFIED: guides/operator-surface.md] | 2026-05-25 during Phase 89 verification. [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md] | Phase 90 must backfill evidence against the narrower truthful contract, not the superseded broader wording. [VERIFIED: .planning/v1.21-MILESTONE-AUDIT.md] |
| `mix verify.doc_contract` previously sounded broader than it was. [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-RESEARCH.md] | `mix verify.doc_contract` now covers the full support-lane doc-contract suite in `:test`. [VERIFIED: mix.exs] | 2026-05-25 in Phase 89. [VERIFIED: mix.exs] | Phase 90 can rely on the named alias directly for doc proof. [VERIFIED: mix.exs] |

**Deprecated/outdated:**

- Treating the example app test file as a root-project test target is outdated for current verification practice; the repo-standard proof surface is `mix verify.example`. [VERIFIED: root example compile failure] [VERIFIED: mix.exs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | This research should stay valid until 2026-06-24 unless Phase 89/90/89-03 artifacts change first. [ASSUMED] | Metadata | A planner could rely on stale authority-layer or proof-surface conclusions after new phase work lands. |

## Open Questions

1. **Should Phase 90 update only `90-VERIFICATION.md`, or also mark requirement completion in other planning surfaces?**
   - What we know: the milestone audit says the missing gap is verification-chain evidence for `SCOPE-03`, `AUTH-02`, and `ADOPT-03`. [VERIFIED: .planning/v1.21-MILESTONE-AUDIT.md]
   - What's unclear: whether the planner should also update requirement status tables or defer that to a later milestone reconciliation phase. [VERIFIED: .planning/REQUIREMENTS.md]
   - Recommendation: include requirement-closure evidence wherever the current milestone workflow normally consumes it, but keep authority-layer reconciliation out of Phase 90 unless the change is strictly limited to those three requirements. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md]

2. **Should Phase 90 wait for `89-03` authority reconciliation first?**
   - What we know: `89-VERIFICATION.md` says authority drift exists in `ROADMAP.md` and `STATE.md`, but Phase 90 itself is already defined and explicitly targets the missing Phase 85 verification chain. [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md] [VERIFIED: .planning/ROADMAP.md]
   - What's unclear: whether the planner wants strict sequential cleanup of authority drift before any backfill phase runs. [VERIFIED: .planning/STATE.md]
   - Recommendation: Phase 90 can proceed if it uses the narrowed current-tree contract as truth and records any remaining authority contradictions instead of silently patching unrelated milestone surfaces. [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix aliases and tests | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Named verification entrypoints | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL server | Root DB-backed tests | ✓ [VERIFIED: `pg_isready`] | reachable on `:5432` [VERIFIED: `pg_isready`] | If absent later, use `docker compose up -d` as hinted by `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| `psql` client | DB diagnostics | ✓ [VERIFIED: `psql --version`] | `14.17` [VERIFIED: `psql --version`] | — |
| Docker | Local DB bootstrap fallback | ✓ [VERIFIED: `docker --version`] | `29.4.1` [VERIFIED: `docker --version`] | — |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment probes]

**Missing dependencies with fallback:** None in this session. [VERIFIED: local environment probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit plus named Mix aliases [VERIFIED: mix.exs] |
| Config file | `test/test_helper.exs` and `test/support/data_case.ex` [VERIFIED: test/test_helper.exs] [VERIFIED: test/support/data_case.ex] |
| Quick run command | `mix verify.doc_contract` [VERIFIED: mix.exs] |
| Full suite command | `mix ci.all` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCOPE-03 | Support-lane docs and example name the proven surfaces and leave support-scoped row history/as-of `unclaimed`. [VERIFIED: guides/operator-surface.md] [VERIFIED: guides/upgrade-path.md] | doc-contract + example | `mix verify.doc_contract && mix verify.example` [VERIFIED: mix.exs] | ✅ [VERIFIED: test/threadline/operator_surface_doc_contract_test.exs] [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] [VERIFIED: test/threadline/getting_started_saas_doc_contract_test.exs] |
| AUTH-02 | One shared `%{assigns: assigns}` callback works across LiveView and export, with stable `:granted | :denied | :error` telemetry. [VERIFIED: .planning/REQUIREMENTS.md] | unit + integration | `MIX_ENV=test mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs --max-failures 1` [VERIFIED: root focused test commands] | ✅ [VERIFIED: test/threadline/operator_surface/auth_test.exs] [VERIFIED: test/threadline/operator_surface/export_auth_plug_test.exs] [VERIFIED: test/threadline/operator_surface/controllers/export_controller_test.exs] |
| ADOPT-03 | Surface controls remain limited to host-owned callbacks and optional overrides, without Threadline-owned DSL expansion. [VERIFIED: .planning/REQUIREMENTS.md] | doc-contract + example | `MIX_ENV=test mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs --max-failures 1 && mix verify.example` [VERIFIED: root focused test commands] [VERIFIED: mix verify.example] | ✅ [VERIFIED: test/threadline/operator_surface_doc_contract_test.exs] [VERIFIED: test/threadline/integration_contracts_doc_contract_test.exs] |

### Sampling Rate

- **Per task commit:** `mix verify.doc_contract` after doc/artifact edits; targeted auth/export tests after proof-command changes. [VERIFIED: mix.exs]
- **Per wave merge:** `MIX_ENV=test mix test ...auth/export/timeline... --max-failures 1` serialized, then `mix verify.example`. [VERIFIED: root focused test commands] [VERIFIED: mix verify.example]
- **Phase gate:** `mix ci.all`, recorded honestly if unrelated dirty-tree failures remain. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VALIDATION.md]

### Wave 0 Gaps

- None in test infrastructure; existing suites already cover the Phase 90 behaviors. [VERIFIED: root focused test commands]
- Artifact gap remains: `90-VERIFICATION.md` does not yet exist, which is the actual phase output this research recommends. [VERIFIED: .planning/phases/90-phase-85-verification-backfill]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: guides/operator-surface.md] | Host-owned authenticated route pipeline plus `authorize_fn`; Threadline verifies the seam, not the identity system. [VERIFIED: guides/operator-surface.md] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] |
| V3 Session Management | no [VERIFIED: guides/operator-surface.md] | Session handling is present, but Phase 90 is not redesigning session semantics. [VERIFIED: lib/threadline/operator_surface/auth.ex] |
| V4 Access Control | yes [VERIFIED: .planning/REQUIREMENTS.md] | Shared `%{assigns: assigns}` contract, `scope_query_fn`, optional `export_authorize_fn`, and plain-text `403` export denial. [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] |
| V5 Input Validation | yes [VERIFIED: test/threadline/operator_surface/controllers/export_controller_test.exs] | Existing route/controller tests and fail-closed callback vocabulary; do not widen control inputs in Phase 90. [VERIFIED: test/threadline/operator_surface/export_auth_plug_test.exs] |
| V6 Cryptography | no [VERIFIED: .planning/ROADMAP.md] | Not a Phase 90 concern. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overclaiming support-scoped row-history/as-of support | Information Disclosure | Verify the narrower `unclaimed` boundary and reject stale broader wording. [VERIFIED: guides/operator-surface.md] [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md] |
| UI-only auth truth without HTTP export parity | Elevation of Privilege | Keep export denial server-authoritative through `ExportAuthPlug` and test the shared callback seam on both transports. [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] [VERIFIED: test/threadline/operator_surface/export_auth_plug_test.exs] |
| Host-policy drift into a Threadline-owned DSL | Tampering | Lock docs/tests on host-owned `authorize_fn`, `scope_query_fn`, and optional `export_authorize_fn` only. [VERIFIED: guides/integration-contracts.md] [VERIFIED: test/threadline/integration_contracts_doc_contract_test.exs] |
| Flaky or misleading DB-backed proof due to parallel execution | Denial of Service | Serialize heavy DB-backed proof commands and rely on the repo's real-DB test conventions. [VERIFIED: test/support/data_case.ex] |

## Sources

### Primary (HIGH confidence)

- [mix.exs](/Users/jon/projects/threadline/mix.exs) - named verification aliases, dependency floors, and example-proof entrypoint. [VERIFIED: mix.exs]
- [CLAUDE.md](/Users/jon/projects/threadline/CLAUDE.md) - project constraints and verification conventions. [VERIFIED: CLAUDE.md]
- [.planning/REQUIREMENTS.md](/Users/jon/projects/threadline/.planning/REQUIREMENTS.md) - Phase 90 requirement targets. [VERIFIED: .planning/REQUIREMENTS.md]
- [.planning/ROADMAP.md](/Users/jon/projects/threadline/.planning/ROADMAP.md) - Phase 90 goal and sequencing. [VERIFIED: .planning/ROADMAP.md]
- [.planning/v1.21-MILESTONE-AUDIT.md](/Users/jon/projects/threadline/.planning/v1.21-MILESTONE-AUDIT.md) - why Phase 90 exists and what evidence is missing. [VERIFIED: .planning/v1.21-MILESTONE-AUDIT.md]
- [.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md](/Users/jon/projects/threadline/.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md) - current-tree narrowed contract truth. [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md]
- [guides/operator-surface.md](/Users/jon/projects/threadline/guides/operator-surface.md) - screen-level contract and `unclaimed` row-history wording. [VERIFIED: guides/operator-surface.md]
- [guides/integration-contracts.md](/Users/jon/projects/threadline/guides/integration-contracts.md) - canonical shared callback contract and minimal-controls boundary. [VERIFIED: guides/integration-contracts.md]
- [examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex) - example-host proof shape. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]

### Secondary (MEDIUM confidence)

- None. All material used was verified from repo artifacts or current command output. [VERIFIED: repository artifact review]

### Tertiary (LOW confidence)

- None. [VERIFIED: repository artifact review]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - versions and aliases were verified from `mix.exs`, `mix.lock`, and local runtime probes. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: local environment probes]
- Architecture: HIGH - the support-lane boundary, shared auth seam, and example proof are explicit in code, guides, and passing tests. [VERIFIED: guides/operator-surface.md] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: root focused test commands]
- Pitfalls: HIGH - each pitfall is grounded in either the milestone audit, the Phase 89 verification report, or a command failure reproduced in this session. [VERIFIED: .planning/v1.21-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md] [VERIFIED: root example compile failure]

**Research date:** 2026-05-25 [VERIFIED: user prompt]  
**Valid until:** 2026-06-24 for repo-local planning evidence unless Phase 89/90/89-03 artifacts change first. [ASSUMED]
