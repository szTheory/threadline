# Phase 69: Integration Contracts & Support Matrix - Research

**Researched:** 2026-05-07
**Domain:** Integration contract documentation, support-lane policy, and proof-backed compatibility claims for Threadline's existing breadth seams. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]
**Confidence:** HIGH. [VERIFIED: codebase grep]

<user_constraints>
## User Constraints (from CONTEXT.md)

The following subsections are copied from `69-CONTEXT.md` as the locked planning envelope for this phase. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]

### Locked Decisions

## Implementation Decisions

### Adapter Contract Shape

- **D-78: Phase 69 should publish a documented contract, not introduce a new behaviour/protocol abstraction.** The current seams are already concrete and test-backed; adding a new `@behaviour`, protocol, or umbrella adapter API now would create API surface before there is evidence it reduces adopter glue.
- **D-79: The stable contract is concept-first and transport-specific in shape.** Threadline standardizes one integration model across multiple entrypoints, but it does not force identical callback signatures everywhere.
  - HTTP request path: `Threadline.Plug` with `actor_fn` and `context_overrides_fn`
  - background job path: `Threadline.Job` with serialized `"actor_ref"` plus `context_opts/2`
  - operator surface path: `authorize_fn` for LiveView and optional `export_authorize_fn` for HTTP export endpoints
  - reference integrations: `Threadline.Integrations.*` modules that adapt host/framework state into those existing Threadline-native seams
- **D-80: Actor identity remains single-authority and explicit.** For request paths, `actor_fn` remains the only actor-authority callback. Additive context callbacks may fill correlation/request metadata only; they do not become a second actor channel.
- **D-81: Additive context stays narrowly scoped.** The locked contract remains:
  - `Threadline.Plug.context_overrides_fn` may fill only missing `:request_id` and `:correlation_id`
  - unknown keys and non-map returns fail closed with `ArgumentError`
  - upstream host normalization still owns proxy/IP handling and any broader request semantics
- **D-82: Job helpers stay intentionally simpler than Plug.** `Threadline.Job` is not retrofitted into a callback-based mini-framework. Its stable contract is explicit serialized data:
  - `"actor_ref"` contains a `Threadline.Semantics.ActorRef.to_map/1` payload
  - `"correlation_id"` and `"job_id"` are the stable context keys extracted by `context_opts/2`
  - any broader job-runner integration remains adapter-specific and out of core unless repeated evidence appears later
- **D-83: `Threadline.Integrations.*` modules are reference adapters, not framework ownership claims.** Their job is to translate host state into existing Threadline seams while keeping the host framework a soft dependency. They should expose obvious, composable entrypoints like `actor_ref_from_conn/1`, `audit_context_overrides_from_conn/1`, and convenience wrappers such as `actor_fn/0` when helpful.
- **D-84: Soft-dependency gating belongs inside each integration module.** The current Sigra pattern is the model: the integration module owns `Code.ensure_loaded?` checks and returns neutral defaults when the host dependency is absent; core Threadline remains free of hard framework coupling.

### Operator-Surface Composition Contract

- **D-85: Phase 69 should treat the operator surface as one breadth contract with two transport faces, not two unrelated auth systems.** The LiveView mount path and the export-controller path are one documented surface with shared telemetry semantics and shared host-owned authorization posture.
- **D-86: The host-owned auth boundary stays fixed.** Threadline standardizes where auth hooks plug in, not who the user is or what roles mean. Phase 69 must not invent a Threadline-owned auth model, permission vocabulary, or saved-scope ownership.
- **D-87: The existing auth split is the official contract.**
  - `authorize_fn` is the canonical LiveView-side contract
  - `export_authorize_fn` is an additive Conn-shaped escape hatch for export endpoints
  - when `export_authorize_fn` is absent, the synthetic `%{assigns: conn.assigns}` mirror delegation to `authorize_fn` is intentional public behavior, not an internal accident
- **D-88: Secure-by-default mount requirements are part of the contract.** The compile-time rule enforced by `threadline_operator_surface/2` remains a first-class support requirement:
  - mount inside a `pipe_through`
  - or provide `:authorize_fn`
  - or explicitly acknowledge unauthenticated mounting
  Anything that bypasses those constraints is outside the supported surface story.

### Support Matrix Policy

- **D-89: Phase 69 should reduce the breadth story to three named support lanes.** This milestone should speak in terms of:
  - `capture-only`
  - `phoenix-surface`
  - `sigra-reference`
  Avoid a broad matrix of every optional package or every Phoenix-adjacent permutation.
- **D-90: `capture-only` remains the strongest and simplest supported lane.** It is supported without optional Phoenix surface deps and is proved by `mix verify.compile_no_optional`.
- **D-91: `phoenix-surface` support means the in-tree operator surface mounted against the exact optional dependency ranges Threadline declares, with proof coming from the main test/doc/compile pipeline.** This is not a blanket claim about every Phoenix app layout or every version inside the broader ecosystem.
- **D-92: `sigra-reference` is a narrow reference-path claim, not generic Sigra compatibility.** Phase 69 should frame Sigra as:
  - the currently maintained first-party reference integration
  - soft-loaded and host-owned
  - proven only through the current example app, docs, and tests that the repo actually runs
  It should not imply support for arbitrary Sigra versions, arbitrary auth layouts, or non-Phoenix hosts.
- **D-93: Support wording must separate `supported`, `reference`, and `unclaimed`.**
  - `supported`: explicitly documented and backed by current repo proof
  - `reference`: recommended first-party composition path within a narrower host story
  - `unclaimed`: plausible or locally workable combinations that the repo does not currently verify
- **D-94: The project must stop using evidence sources that are too weak for support claims.** Declared dependency ranges alone are not enough; ecosystem norms, upstream release notes, or maintainer intuition are not enough either.

### Proof Bar And Verification Story

- **D-95: A combination is only support-claimable when docs, code, and CI all agree.** Phase 69 should lock a three-part bar:
  - contract is documented in canonical guides / README / package wording
  - code paths exist in the library or example app
  - current repo verification actually exercises the claim
- **D-96: Current proof sources are intentionally limited.** The allowed evidence set for support claims is:
  - `mix.exs` declared deps and aliases
  - current lock resolution where docs mention tested versions
  - `.github/workflows/ci.yml`
  - focused tests and example-app verification that run under those entrypoints
- **D-97: `ci.all` is necessary but not sufficient for breadth claims by itself.** Phase 69 should preserve the distinction between:
  - `verify.compile_no_optional` for capture-only
  - the main library test/doc/example path for Phoenix-surface claims
  - focused Sigra/example-path coverage for the reference lane
  One umbrella alias may call several of these, but the docs should name the specific proving entrypoints.
- **D-98: The support matrix should point at named proof obligations, not just version numbers.** For each lane, the reader should be able to answer "what in this repo proves that claim?" without guessing.
- **D-99: No new CI topology should be invented in Phase 69 unless the current jobs cannot honestly support the claim language.** The bias is to tighten wording to match existing proof before expanding automation.

### Documentation Posture

- **D-100: Phase 69 should add one canonical integration-contract document instead of scattering the contract across guides.** The planner should bias toward a single source of truth that later phases can extend and link from README, upgrade-path, operator-surface, and Sigra docs.
- **D-101: Existing docs should become narrower, not broader.**
  - `guides/upgrade-path.md` should focus on dependency/support posture for capture-only vs surface-mounted
  - `guides/integrations/sigra.md` should focus on the Sigra reference adapter and its locked behavior
  - the new Phase 69 contract doc should explain how these pieces fit together as one breadth story
- **D-102: The support matrix should be phrased at the lane level, not as a faux exhaustive compatibility spreadsheet.** Overly precise minor-by-minor claims create maintenance pressure the repo does not currently justify.

### Downstream Decision Policy

- **D-103: Later v1.19 phases should treat Phase 69 as the arbiter for breadth wording.** Phase 70 may refresh the Sigra/Phoenix path, but it should do so inside these support lanes instead of re-opening the contract.
- **D-104: Bias toward honesty over marketing breadth.** If a phrasing choice would make the support story sound larger than the test story, Phase 69 should choose the smaller claim.

### Claude's Discretion

- Exact name and file path of the canonical Phase 69 contract doc, as long as it is easy for downstream agents and future adopters to find.
- Exact lane labels (`phoenix-surface` vs `surface-mounted`, `sigra-reference` vs `sigra-backed reference path`) as long as the distinction stays narrow and unambiguous.
- Whether the support matrix lives primarily in the new contract doc, `guides/upgrade-path.md`, or both, as long as there is one clear source of truth and cross-links remain coherent.
- Whether CI proof is documented as a table, bullets, or short subsections, as long as each support claim maps to named repo evidence.

### Deferred Ideas (OUT OF SCOPE)

- A formal adapter behaviour, protocol, or umbrella abstraction across Plug/Job/operator-surface integrations — defer until multiple first-party integrations prove that the current documented seams are insufficient.
- Additional first-party integrations beyond Sigra — belongs to later breadth phases once the contract is frozen.
- A broader multi-framework compatibility matrix spanning non-Phoenix hosts, alternate auth stacks, or arbitrary optional-dependency combinations — out of scope for Phase 69.
- `threadline_web` extraction pressure — explicitly deferred to Phase 72.
- New auth capabilities, saved scopes, role models, or surface-owned permissions — outside v1.19 breadth scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| INTEG-01 | Threadline publishes one stable adapter contract for actor extraction, additive context overrides, optional dependency behavior, and operator-surface composition across `Threadline.Plug`, `Threadline.Job`, and `Threadline.Integrations.*`. [VERIFIED: .planning/REQUIREMENTS.md] | Freeze the existing seams as documentation-first contract; do not add a new behaviour/protocol; centralize the contract in one canonical guide and back it with doc-contract tests. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] [VERIFIED: lib/threadline/plug.ex] [VERIFIED: lib/threadline/job.ex] [VERIFIED: lib/threadline/integrations/sigra.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] |
| COMPAT-01 | Threadline documents a narrow support matrix that names only proven combinations for Plug-only installs, Phoenix operator-surface installs, and the current Sigra-backed reference path. [VERIFIED: .planning/REQUIREMENTS.md] | Replace the current package-row emphasis with three named lanes: `capture-only`, `phoenix-surface`, and `sigra-reference`, each tied to explicit repo proof. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] [VERIFIED: guides/upgrade-path.md] [VERIFIED: examples/threadline_phoenix/README.md] |
| COMPAT-02 | Verification and CI entrypoints exercise the claimed breadth story, including compile-without-optional-deps and the named surface/reference-path combinations, so docs do not promise ranges that the repo does not prove. [VERIFIED: .planning/REQUIREMENTS.md] | Name proof per lane using existing entrypoints; treat `mix verify.compile_no_optional`, `mix verify.test`, `mix verify.example`, selected doc-contract tests, and CI job IDs as the evidence surface; avoid inventing new CI unless current wording cannot be made honest. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] [VERIFIED: mix.exs] [VERIFIED: .github/workflows/ci.yml] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Preserve the three-layer architecture boundary: capture owns row-mutation persistence, semantics owns action context, and exploration/operations owns operator workflows. [VERIFIED: CLAUDE.md]
- Use the domain terms `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation` consistently in docs and code. [VERIFIED: CLAUDE.md]
- Prefer named verification entrypoints such as `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all` over ad-hoc commands in docs and CI. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]
- Keep CI job IDs stable; wording and planning may evolve job names, but not the workflow `jobs:` keys relied on by docs and tooling. [VERIFIED: CLAUDE.md] [VERIFIED: .github/workflows/ci.yml]
- Keep the optional Phoenix/LiveView posture; capture-only adopters must remain able to compile without optional deps. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]
- Do not introduce a Threadline-owned auth model, permission vocabulary, or package split in this phase. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]

## Summary

Threadline already has the implementation seams this phase needs to standardize: `Threadline.Plug` owns request-path actor extraction and additive request metadata, `Threadline.Job` owns serialized background-job propagation, `Threadline.Integrations.Sigra` demonstrates the soft-dependency adapter posture, and the operator surface already has a split-but-coherent auth contract between LiveView mount (`authorize_fn`) and export HTTP requests (`export_authorize_fn` with mirror fallback). [VERIFIED: lib/threadline/plug.ex] [VERIFIED: lib/threadline/job.ex] [VERIFIED: lib/threadline/integrations/sigra.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex]

The main planning work is therefore documentation alignment and proof-boundary cleanup, not new runtime abstraction. The current upgrade-path guide is still package-row oriented, the README and operator-surface guide currently show tuple-style callback examples even though the implementation calls 1-arity functions directly, and the example app proves a narrower Phoenix/Sigra path than the root lockfile used by the library test suite. [VERIFIED: guides/upgrade-path.md] [VERIFIED: README.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/mix.lock]

The planner should structure Phase 69 as a docs-and-tests contract freeze: add one canonical integration-contract guide, narrow existing guides to lane-specific roles, update public wording to use three support lanes, and add doc-contract coverage that locks both the lane language and the proof obligations to specific entrypoints. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] [VERIFIED: test/threadline/integrations/sigra_doc_contract_test.exs] [VERIFIED: test/threadline/operator_surface_doc_contract_test.exs]

**Primary recommendation:** Use a single canonical contract document plus lane-level proof tables, and treat all existing code paths as the contract surface instead of introducing any new adapter abstraction. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| HTTP request-path actor and metadata contract | API / Backend | Frontend Server (SSR) | `Threadline.Plug` extracts actor, request ID, correlation ID, and remote IP from `Plug.Conn`, so the contract belongs to request-processing code, not the browser. [VERIFIED: lib/threadline/plug.ex] |
| Background job audit-context contract | API / Backend | Database / Storage | `Threadline.Job` is pure map-to-keyword translation for durable job args and feeds action recording inside backend jobs. [VERIFIED: lib/threadline/job.ex] |
| Reference integration adapter posture | API / Backend | Frontend Server (SSR) | `Threadline.Integrations.Sigra` adapts host request state into Threadline seams with `Code.ensure_loaded?` gating and no framework ownership claim. [VERIFIED: lib/threadline/integrations/sigra.ex] |
| Operator-surface auth composition | Frontend Server (SSR) | API / Backend | The router macro, LiveView `on_mount`, and export auth plug all run in Phoenix server-side request handling and define where host auth hooks into the surface. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] |
| Support-lane proof policy | API / Backend | Frontend Server (SSR) | The proof sources are package metadata, tests, example app execution, and CI entrypoints; the browser owns none of this contract. [VERIFIED: mix.exs] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: guides/upgrade-path.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `threadline` | `0.4.0` [VERIFIED: mix.exs] | Package whose breadth contract is being frozen. [VERIFIED: mix.exs] | Phase 69 is explicitly about documenting existing `threadline` seams rather than adding new dependencies. [VERIFIED: .planning/REQUIREMENTS.md] |
| `phoenix` | declared `~> 1.7`, root lock `1.8.7`, example lock `1.8.5` [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/mix.lock] | Optional operator-surface host framework. [VERIFIED: mix.exs] | This is the current in-tree surface stack the repo already tests and documents. [VERIFIED: guides/operator-surface.md] [VERIFIED: .github/workflows/ci.yml] |
| `phoenix_live_view` | declared `~> 1.0`, root lock `1.1.30`, example lock `1.1.28` [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/mix.lock] | Optional LiveView surface runtime. [VERIFIED: mix.exs] | The operator surface is implemented as LiveViews and already covered by the main suite plus example app. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: .github/workflows/ci.yml] |
| `phoenix_html` | declared `~> 4.0`, root lock `4.3.0` [VERIFIED: mix.exs] [VERIFIED: mix.lock] | Optional surface HTML helpers. [VERIFIED: mix.exs] | Existing support claims already name this range and resolution. [VERIFIED: guides/upgrade-path.md] |
| `phoenix_pubsub` | declared `~> 2.1`, root lock `2.2.0` [VERIFIED: mix.exs] [VERIFIED: mix.lock] | Optional surface PubSub dependency. [VERIFIED: mix.exs] | Existing support claims already name this range and resolution. [VERIFIED: guides/upgrade-path.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `sigra` | example host dep `~> 0.2`, example lock `0.2.5` [VERIFIED: guides/integrations/sigra.md] [VERIFIED: examples/threadline_phoenix/mix.exs] [VERIFIED: examples/threadline_phoenix/mix.lock] | Current first-party reference adapter host stack. [VERIFIED: guides/integrations/sigra.md] | Use only for the narrow `sigra-reference` lane; do not generalize this into generic Sigra support. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] |
| ExUnit doc-contract tests | existing repo test pattern, no extra dependency required. [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] [VERIFIED: test/threadline/integrations/sigra_doc_contract_test.exs] [VERIFIED: test/threadline/operator_surface_doc_contract_test.exs] | Locks public wording and literals against drift. [VERIFIED: codebase grep] | Use for the new canonical contract guide and all support-lane cross-links. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] |
| GitHub Actions CI job IDs | `verify-compile-no-optional`, `verify-test`, `verify-docs` plus related jobs. [VERIFIED: .github/workflows/ci.yml] | Public proof anchors for support claims. [VERIFIED: .github/workflows/ci.yml] | Use when docs point to concrete repo evidence for a support lane. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Documenting existing seams | New `@behaviour` or protocol abstraction | Rejected for this phase because there is only one reference integration and the current seams are already concrete and tested. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] |
| Three support lanes | Exhaustive package/version spreadsheet | Rejected because the repo does not currently prove every permutation and the phase explicitly wants honesty over breadth. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] [VERIFIED: guides/upgrade-path.md] |
| Existing CI/topology with tighter wording | New CI topology | Rejected unless current wording cannot be made honest with existing proof. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] |

**Installation:** No new package installation should be part of Phase 69; the milestone explicitly rejects new hard dependencies. [VERIFIED: .planning/REQUIREMENTS.md]

```bash
mix deps.get
```

**Version verification:** Phase 69 should treat declared ranges and current lock resolutions as the authoritative version source because the support story is repo-proof-based, not “latest available” based. [VERIFIED: guides/upgrade-path.md] [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/mix.lock]

## Architecture Patterns

### System Architecture Diagram

```text
Host HTTP request
  -> Threadline.Plug
  -> AuditContext in conn.assigns
  -> record_action / capture flow
  -> "request-path" contract section

Host job args
  -> Threadline.Job
  -> actor_ref_from_args + context_opts
  -> record_action in worker transaction
  -> "job-path" contract section

Host Phoenix router / LiveView mount
  -> threadline_operator_surface/2
  -> Auth.on_mount + ExportAuthPlug
  -> shared authorize telemetry / threadline_scope
  -> "operator-surface" contract section

Host-specific request state
  -> Threadline.Integrations.Sigra
  -> actor_ref_from_conn / audit_context_overrides_from_conn
  -> existing Threadline seams
  -> "reference adapter" contract section

Canonical integration-contract guide
  -> names support lanes
  -> links each lane to proof entrypoints
  -> narrows README / upgrade-path / Sigra guide wording
  -> doc-contract tests lock lane language and proof obligations
```

The planner should keep the contract organized by entrypoint and proof lane, not by package boundary or speculative future adapters. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]

### Recommended Project Structure

```text
guides/
├── integrations-and-support.md    # new canonical contract + lane matrix source of truth
├── upgrade-path.md                # narrowed lifecycle/support lane summary
├── integrations/
│   └── sigra.md                   # narrowed reference-adapter guide
README.md                          # public top-level support wording
examples/threadline_phoenix/README.md
test/threadline/
├── integration_contract_doc_contract_test.exs
├── upgrade_path_doc_contract_test.exs
├── readme_doc_contract_test.exs
└── integrations/sigra_doc_contract_test.exs
```

The exact filename is discretionary, but the canonical guide should live under `guides/` and be added to ExDoc extras so it is discoverable and testable. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] [VERIFIED: mix.exs]

### Pattern 1: Canonical Contract Guide
**What:** One guide explains the four existing breadth seams and how they compose into one support story. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]
**When to use:** Use for every top-level contract statement that later phases must inherit. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]
**Example:**
```elixir
# Source: lib/threadline/plug.ex
plug Threadline.Plug,
  actor_fn: &MyApp.Auth.to_actor_ref/1,
  context_overrides_fn: &MyApp.Auth.audit_context_overrides/1
```

### Pattern 2: Lane-Level Support Table
**What:** Document breadth as `capture-only`, `phoenix-surface`, and `sigra-reference`, with a proof column naming exact entrypoints. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]
**When to use:** Use in the canonical guide and cross-link from `guides/upgrade-path.md`. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]
**Example:**
```text
capture-only  -> mix verify.compile_no_optional -> CI: verify-compile-no-optional
phoenix-surface -> mix verify.test + mix ci.all -> CI: verify-test, verify-docs
sigra-reference -> mix verify.example + Sigra guide/tests -> CI: verify-test
```

### Pattern 3: Doc-Contract Locking for Public Breadth Claims
**What:** Treat support wording as testable contract, not free-form narrative. [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] [VERIFIED: test/threadline/integrations/sigra_doc_contract_test.exs]
**When to use:** Any guide or README text that names a support lane, callback shape, or proof command. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: test/threadline/upgrade_path_doc_contract_test.exs
assert String.contains?(guide, "mix verify.compile_no_optional")
assert String.contains?(guide, "Anything outside the listed ranges is not claimed, even if it may work.")
```

### Anti-Patterns to Avoid
- **New adapter abstraction:** Do not add a behaviour, protocol, or registry layer in this phase. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]
- **Package-row marketing matrix:** Do not imply every version inside a declared range is equally proven. [VERIFIED: guides/upgrade-path.md] [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]
- **Second actor channel:** Do not let context overrides become actor identity. [VERIFIED: lib/threadline/plug.ex] [VERIFIED: test/threadline/plug_test.exs]
- **Tuple callback examples:** Do not preserve tuple-style `actor_fn` / `authorize_fn` examples unless the implementation grows tuple support; the current implementation invokes 1-arity functions directly. [VERIFIED: README.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-entrypoint adapter API | New behaviour/protocol layer | Existing documented seams in `Plug`, `Job`, operator auth, and `Integrations.*` | The repo has only one reference adapter and already-tested concrete seams. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] [VERIFIED: lib/threadline/plug.ex] [VERIFIED: lib/threadline/job.ex] [VERIFIED: lib/threadline/integrations/sigra.ex] |
| Threadline-owned permissions | Roles, scopes, or user model inside Threadline | Host-owned `authorize_fn` and optional `export_authorize_fn` | The auth boundary is explicitly host-owned and must remain so. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] |
| Hard dependency switching | Core-level framework gate or global adapter switch | Per-module `Code.ensure_loaded?` soft-dep gate | That is the current Sigra model and preserves capture-only installs. [VERIFIED: lib/threadline/integrations/sigra.ex] [VERIFIED: mix.exs] |
| Generic compatibility spreadsheet | Claims by ecosystem intuition | Lane table with proof entrypoints | Support claims are only allowed when docs, code, and CI all agree. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] |

**Key insight:** Phase 69 is a contract freeze and evidence-alignment pass, not an architecture-expansion phase. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Root-vs-example proof drift
**What goes wrong:** Docs may imply one Phoenix/Sigra support story even though the root library lock and the example app lock resolve different versions. [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/mix.lock]
**Why it happens:** `guides/upgrade-path.md` currently uses root-lock resolutions, while `mix verify.example` exercises the example app's narrower Sigra/Phoenix path. [VERIFIED: guides/upgrade-path.md] [VERIFIED: mix.exs] [VERIFIED: examples/threadline_phoenix/mix.lock]
**How to avoid:** Split proof by lane and name the proof source per lane instead of flattening everything into one matrix row family. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]
**Warning signs:** One document cites Phoenix `1.8.7` while the example app still runs Phoenix `1.8.5`. [VERIFIED: guides/upgrade-path.md] [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/mix.lock]

### Pitfall 2: Named proof alias drift
**What goes wrong:** A guide may point to `mix verify.doc_contract` as “the doc proof” even though that alias currently runs only `test/threadline/readme_doc_contract_test.exs`. [VERIFIED: mix.exs]
**Why it happens:** Most doc-contract coverage currently runs through `mix verify.test`, not the narrower alias. [VERIFIED: mix.exs] [VERIFIED: codebase grep]
**How to avoid:** Either expand `verify.doc_contract` to cover the intended guide tests or document the precise test/alias combination per lane. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]
**Warning signs:** New contract-guide tests exist, but no named entrypoint besides `mix test` mentions them. [VERIFIED: codebase grep]

### Pitfall 3: Callback-shape docs diverge from code
**What goes wrong:** Adopters copy tuple-based callback examples that the implementation does not invoke correctly. [VERIFIED: README.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: lib/threadline/operator_surface/auth.ex]
**Why it happens:** Current docs show `{Module, :function}` examples, but runtime code uses `authorize_fn.(socket)` and `authorize_fn.(mirror)` direct function invocation. [VERIFIED: README.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex]
**How to avoid:** Normalize public examples to 1-arity function captures in Phase 69 or explicitly add tuple support in code later; this phase should prefer the doc fix. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]
**Warning signs:** README and guide examples disagree with working tests, which always pass function captures or inline functions. [VERIFIED: test/threadline/operator_surface/auth_test.exs] [VERIFIED: test/threadline/operator_surface/export_auth_plug_test.exs]

### Pitfall 4: Actor identity leaks into additive context
**What goes wrong:** Adapter docs may suggest `context_overrides_fn` can inject actor identity or broader request semantics. [VERIFIED: lib/threadline/plug.ex] [VERIFIED: guides/integrations/sigra.md]
**Why it happens:** There are two callbacks on the request path, and only one of them is authoritative for actor identity. [VERIFIED: lib/threadline/plug.ex]
**How to avoid:** Keep the contract explicit that `actor_fn` decides actor identity and `context_overrides_fn` only fills missing `request_id` / `correlation_id`. [VERIFIED: lib/threadline/plug.ex] [VERIFIED: test/threadline/plug_test.exs] [VERIFIED: test/threadline/integrations/sigra_test.exs]
**Warning signs:** Docs mention tenant IDs, IP overrides, or actor replacement in `context_overrides_fn`. [VERIFIED: test/threadline/plug_test.exs]

## Code Examples

Verified patterns from repo sources:

### Request-path contract
```elixir
# Source: lib/threadline/plug.ex
plug Threadline.Plug,
  actor_fn: &MyApp.Auth.to_actor_ref/1,
  context_overrides_fn: &MyApp.Auth.audit_context_overrides/1
```

### Job-path contract
```elixir
# Source: lib/threadline/job.ex
with {:ok, actor_ref} <- Threadline.Job.actor_ref_from_args(args) do
  opts = Threadline.Job.context_opts(args)
  Threadline.record_action(:event, [actor: actor_ref, repo: Repo] ++ opts)
end
```

### Soft-dependency reference adapter
```elixir
# Source: lib/threadline/integrations/sigra.ex
def actor_ref_from_conn(conn) do
  if Code.ensure_loaded?(Sigra.Session) do
    conn |> current_scope() |> actor_ref_from_scope()
  else
    nil
  end
end
```

### Operator-surface export auth parity
```elixir
# Source: lib/threadline/operator_surface/export_auth_plug.ex
authorizer =
  case export_authorize_fn do
    fun when is_function(fun, 1) -> fn -> fun.(conn) end
    nil -> fn -> authorize_fn.(%{assigns: conn.assigns}) end
  end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Package-row compatibility narrative centered on `surface-mounted` dependency rows. [VERIFIED: guides/upgrade-path.md] | Lane-level breadth contract centered on `capture-only`, `phoenix-surface`, and `sigra-reference`. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] | Targeted by Phase 69 planning. [VERIFIED: .planning/ROADMAP.md] | Support claims become easier to keep honest and cheaper to maintain. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] |
| Scattered breadth wording across README, upgrade path, operator-surface guide, and Sigra guide. [VERIFIED: README.md] [VERIFIED: guides/upgrade-path.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: guides/integrations/sigra.md] | One canonical contract guide with narrower supporting guides. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] | Targeted by Phase 69 planning. [VERIFIED: .planning/ROADMAP.md] | Later phases can extend one source of truth instead of re-deciding breadth wording. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] |
| Generic guide examples that drift from implementation details. [VERIFIED: README.md] [VERIFIED: guides/operator-surface.md] | Code-backed callback and proof language locked by doc-contract tests. [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] [VERIFIED: test/threadline/operator_surface_doc_contract_test.exs] | Current repo pattern; should be extended in Phase 69. [VERIFIED: codebase grep] | Public docs stop outrunning tested behavior. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] |

**Deprecated/outdated:**
- Tuple-style `actor_fn` / `authorize_fn` examples in `README.md` and `guides/operator-surface.md` are outdated relative to the current implementation shape. [VERIFIED: README.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: lib/threadline/operator_surface/auth.ex]
- The current compatibility matrix layout in `guides/upgrade-path.md` is outdated for the milestone goal because it is still package-row oriented and does not name a Sigra reference lane. [VERIFIED: guides/upgrade-path.md] [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]

## Assumptions Log

All material claims in this document were verified against repo files or local command output during this session. [VERIFIED: codebase grep]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

## Open Questions (RESOLVED)

1. **Should `mix verify.doc_contract` expand or stay narrow?**
   - Resolution: keep `mix verify.doc_contract` narrow in Phase 69 and document the precise proof commands per lane instead of broadening the alias as part of this phase. The repo already gets most doc-contract coverage through `mix verify.test`, and the plan now names focused `mix test ...` bundles plus `mix verify.compile_no_optional` and `mix verify.example` explicitly. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-02-PLAN.md] [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-03-PLAN.md]

2. **What exact filename should the canonical guide use?**
   - Resolution: use `guides/integration-contracts.md`. It is short, top-level, readable in README/ExDoc links, and accurately describes the phase as a contract freeze rather than a generic support matrix. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-01-PLAN.md]

3. **Should the existing `surface-mounted` label be renamed publicly to `phoenix-surface` now?**
   - Resolution: yes. The planner now updates the affected support-lane doc-contract tests in the same slice as the wording rewrite, so the rename does not leave verification behind. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | `mix verify.*` and `mix ci.all` proof commands. [VERIFIED: mix.exs] | ✓ [VERIFIED: local command output] | `Mix 1.19.5` [VERIFIED: local command output] | — |
| Elixir / OTP | Test and docs execution. [VERIFIED: mix.exs] [VERIFIED: .github/workflows/ci.yml] | ✓ [VERIFIED: local command output] | `Elixir 1.19.5`, `OTP 28` locally; CI uses `Elixir 1.17.3`, `OTP 27.0`. [VERIFIED: local command output] [VERIFIED: .github/workflows/ci.yml] | Use CI versions as release-proof baseline. [VERIFIED: .github/workflows/ci.yml] |
| PostgreSQL | `mix verify.test` and `mix verify.example` paths that hit the DB. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: mix.exs] | ✓ [VERIFIED: local command output] | `localhost:5432 accepting connections` [VERIFIED: local command output] | CI service container or local `docker compose up -d postgres`. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: examples/threadline_phoenix/README.md] |
| Docker | Optional local Postgres / topology parity. [VERIFIED: examples/threadline_phoenix/README.md] [VERIFIED: .github/workflows/ci.yml] | ✓ [VERIFIED: local command output] | `29.4.1` [VERIFIED: local command output] | Use existing local Postgres if Docker is unnecessary. [VERIFIED: local command output] |
| `git` | Release-shape and clean-tree commands referenced by aliases. [VERIFIED: mix.exs] | ✓ [VERIFIED: local command output] | available [VERIFIED: local command output] | — |

**Missing dependencies with no fallback:** None found. [VERIFIED: local command output]

**Missing dependencies with fallback:** None found. [VERIFIED: local command output]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix aliases. [VERIFIED: mix.exs] |
| Config file | `test/test_helper.exs` and `config/test.exs` are in use through `mix test`; no standalone `pytest`/`jest` style config applies. [VERIFIED: mix.exs] [VERIFIED: codebase grep] |
| Quick run command | `mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs -x` [VERIFIED: existing test files] |
| Full suite command | `mix ci.all` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INTEG-01 | Canonical contract guide states the stable seams and callback boundaries correctly. [VERIFIED: .planning/REQUIREMENTS.md] | doc-contract + existing unit tests | `mix test test/threadline/integration_contracts_doc_contract_test.exs test/threadline/plug_test.exs test/threadline/job_test.exs test/threadline/integrations/sigra_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs -x` | ❌ Wave 0 for new doc-contract file; existing unit files already exist. [VERIFIED: codebase grep] |
| COMPAT-01 | Public docs name only the three proven support lanes and distinguish supported/reference/unclaimed. [VERIFIED: .planning/REQUIREMENTS.md] | doc-contract | `mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs -x` | ✅ existing files, but they need updates. [VERIFIED: codebase grep] |
| COMPAT-02 | Each support lane maps to named proof entrypoints and current repo evidence. [VERIFIED: .planning/REQUIREMENTS.md] | doc-contract + CI contract | `mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/phase06_nyquist_ci_contract_test.exs -x` and `mix verify.compile_no_optional` and `mix verify.example` [VERIFIED: mix.exs] | ✅ existing CI contract file; ❌ likely needs new assertions for the Phase 69 guide/proof table. [VERIFIED: codebase grep] |

### Sampling Rate
- **Per task commit:** Run the targeted doc-contract and unit tests for the touched guides/modules. [VERIFIED: existing test files]
- **Per wave merge:** Run `mix verify.compile_no_optional` plus the targeted Phase 69 test bundle. [VERIFIED: mix.exs]
- **Phase gate:** Run `mix ci.all` before `/gsd-verify-work`. [VERIFIED: mix.exs]

### Wave 0 Gaps
- [ ] `test/threadline/integration_contracts_doc_contract_test.exs` — no dedicated test currently locks the new canonical contract guide because the guide does not exist yet. [VERIFIED: codebase grep]
- [x] Keep `mix verify.doc_contract` narrow and name the exact proof commands per lane in the Phase 69 plans instead of broadening the alias here. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-03-PLAN.md]
- [ ] Update `test/threadline/readme_doc_contract_test.exs` and `test/threadline/operator_surface_doc_contract_test.exs` if callback examples are corrected from tuple syntax to function captures. [VERIFIED: README.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: test/threadline/readme_doc_contract_test.exs] [VERIFIED: test/threadline/operator_surface_doc_contract_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host app owns authentication; Threadline documents hook points only. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/threadline/operator_surface/auth.ex] |
| V3 Session Management | no | Out of scope for Threadline core; Sigra and host apps own session semantics. [VERIFIED: guides/integrations/sigra.md] [VERIFIED: .planning/REQUIREMENTS.md] |
| V4 Access Control | yes | `authorize_fn`, optional `export_authorize_fn`, compile-time secure mount requirement, and fail-closed deny/error handling. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] |
| V5 Input Validation | yes | `context_overrides_fn` fail-closed validation and secure route/mount constraints should be documented as part of the contract. [VERIFIED: lib/threadline/plug.ex] [VERIFIED: test/threadline/plug_test.exs] |
| V6 Cryptography | no | Phase 69 does not add crypto features or secret handling. [VERIFIED: .planning/REQUIREMENTS.md] |

### Known Threat Patterns for Threadline's breadth docs

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overclaiming a support combination that CI does not exercise | Repudiation | Require docs, code, and CI agreement before claiming support. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] |
| Adopter copies stale tuple callback docs and bypasses the intended auth hook shape | Elevation of privilege | Align callback examples with the actual 1-arity function contract and lock them with tests. [VERIFIED: README.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: lib/threadline/operator_surface/auth.ex] |
| Adapter docs imply a second actor channel via additive metadata | Spoofing | State clearly that only `actor_fn` decides actor identity; overrides may fill only missing request metadata. [VERIFIED: lib/threadline/plug.ex] [VERIFIED: test/threadline/plug_test.exs] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md` - locked decisions, canonical refs, and phase-specific constraints. [VERIFIED: file read]
- `.planning/ROADMAP.md` - phase goal, dependencies, and success criteria. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - Phase 69 requirement contract. [VERIFIED: file read]
- `CLAUDE.md` - project-level constraints and verification conventions. [VERIFIED: file read]
- `lib/threadline/plug.ex` - request-path contract. [VERIFIED: file read]
- `lib/threadline/job.ex` - job-path contract. [VERIFIED: file read]
- `lib/threadline/integrations/sigra.ex` - soft-dependency adapter posture. [VERIFIED: file read]
- `lib/threadline/operator_surface/router.ex` - secure mount and export-surface composition contract. [VERIFIED: file read]
- `lib/threadline/operator_surface/auth.ex` - LiveView auth contract. [VERIFIED: file read]
- `lib/threadline/operator_surface/export_auth_plug.ex` - HTTP export auth contract and mirror delegation behavior. [VERIFIED: file read]
- `guides/upgrade-path.md`, `guides/operator-surface.md`, `guides/integrations/sigra.md`, `README.md`, `examples/threadline_phoenix/README.md` - current public wording and support claims. [VERIFIED: file read]
- `mix.exs`, `mix.lock`, `examples/threadline_phoenix/mix.exs`, `examples/threadline_phoenix/mix.lock`, `.github/workflows/ci.yml` - declared deps, lock resolutions, aliases, and CI proof topology. [VERIFIED: file read]
- `test/threadline/*doc_contract_test.exs`, `test/threadline/plug_test.exs`, `test/threadline/job_test.exs`, `test/threadline/integrations/sigra_test.exs`, `test/threadline/operator_surface/*` - locked behavior and doc-contract coverage. [VERIFIED: file read]

### Secondary (MEDIUM confidence)
- Local command output for tool/runtime availability: `mix --version`, `elixir --version`, `pg_isready`, `docker info`, command presence checks. [VERIFIED: local command output]

### Tertiary (LOW confidence)
- None. [VERIFIED: session evidence]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended stack elements are existing repo dependencies and lock resolutions, not inferred ecosystem choices. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/mix.lock]
- Architecture: HIGH - the contract boundaries are visible directly in code and tests. [VERIFIED: lib/threadline/plug.ex] [VERIFIED: lib/threadline/job.ex] [VERIFIED: lib/threadline/operator_surface/router.ex]
- Pitfalls: HIGH - each pitfall is backed by current docs/code/test mismatches or proof topology visible in the repo. [VERIFIED: README.md] [VERIFIED: guides/upgrade-path.md] [VERIFIED: mix.exs]

**Research date:** 2026-05-07
**Valid until:** 2026-06-06 for repo-local claims unless Phase 69 or adjacent docs/tests change first. [VERIFIED: codebase grep]
