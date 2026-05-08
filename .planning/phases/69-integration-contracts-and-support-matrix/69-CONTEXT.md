# Phase 69: Integration Contracts & Support Matrix - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Freeze the reusable integration contract and the support-claim policy that later v1.19 phases must follow. This phase defines what Threadline officially standardizes across `Threadline.Plug`, `Threadline.Job`, `Threadline.Integrations.*`, and the operator-surface mount/auth story; it also defines which host-stack combinations the project is allowed to call supported and what repo evidence is required before making that claim. This phase does not refresh the Sigra path itself, add a second reference integration, add new auth features, or split `threadline_web`.

</domain>

<decisions>
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

### the agent's Discretion

- Exact name and file path of the canonical Phase 69 contract doc, as long as it is easy for downstream agents and future adopters to find.
- Exact lane labels (`phoenix-surface` vs `surface-mounted`, `sigra-reference` vs `sigra-backed reference path`) as long as the distinction stays narrow and unambiguous.
- Whether the support matrix lives primarily in the new contract doc, `guides/upgrade-path.md`, or both, as long as there is one clear source of truth and cross-links remain coherent.
- Whether CI proof is documented as a table, bullets, or short subsections, as long as each support claim maps to named repo evidence.

</decisions>

<specifics>
## Specific Ideas

- The simplest honest phase-69 move is to document the current seams as an intentional contract instead of inventing a new adapter abstraction. The code already tells a coherent story: request path, job path, operator-surface path, and soft-dep reference integrations.
- The current `guides/upgrade-path.md` matrix is still too package-row-oriented for the milestone goal. Phase 69 should likely compress that into lane-level support language so it answers "what kinds of installs do you support?" before "what package versions are currently resolved?"
- `sigra-reference` should probably be described as "the current first-party reference integration for Phoenix hosts already using Sigra," not as a generic Sigra support promise.
- The synthetic `%{assigns: conn.assigns}` mirror behavior in `ExportAuthPlug` is worth treating as deliberate contract because later host docs will rely on it when they explain operator-surface parity between LiveView and export endpoints.
- The repo already has enough verification primitives to support a narrower story:
  - `verify.compile_no_optional`
  - `verify.test`
  - `verify.example`
  - `verify.doc_contract`
  - stable CI job IDs in `.github/workflows/ci.yml`
  Phase 69 should prefer aligning docs to those proofs before proposing more jobs.
- Your instruction for this phase is effectively "choose the strongest recommendation and keep moving." Downstream planner/researcher agents should treat the above defaults as locked unless they uncover a concrete contradiction in the repo.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase contract
- `.planning/ROADMAP.md` §"Phase 69: Integration Contracts & Support Matrix" — phase goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` lines for `INTEG-01`, `COMPAT-01`, and `COMPAT-02` — the requirement contract this phase must satisfy.
- `.planning/PROJECT.md` §"Current Milestone: v1.19 — Integration Breadth" — milestone intent, deferrals, and package-boundary framing.
- `.planning/STATE.md` current-focus and v1.19 context entries — active milestone posture and sequencing.

### Existing integration seams
- `lib/threadline/plug.ex` — request-path contract for `actor_fn` and additive `context_overrides_fn`.
- `test/threadline/plug_test.exs` — locked semantics for additive-only overrides and fail-closed invalid shapes.
- `lib/threadline/job.ex` — job-path contract for serialized actor refs and extracted `context_opts/2`.
- `test/threadline/job_test.exs` — locked job helper semantics.
- `lib/threadline/integrations/sigra.ex` — current soft-dependency reference adapter model.
- `test/threadline/integrations/sigra_test.exs` and `test/threadline/integrations/sigra_doc_contract_test.exs` — locked Sigra behavior and guide literals.

### Operator-surface composition and auth
- `lib/threadline/operator_surface/router.ex` — secure-by-default mount contract and export-surface composition.
- `lib/threadline/operator_surface/auth.ex` — LiveView-side authorization contract.
- `lib/threadline/operator_surface/export_auth_plug.ex` — HTTP export auth contract, including `export_authorize_fn` and synthetic mirror delegation.
- `test/threadline/operator_surface/router_test.exs` — compile-time secure-mount contract.
- `test/threadline/operator_surface/auth_test.exs` and `test/threadline/operator_surface/export_auth_plug_test.exs` — locked auth-path behavior across LiveView and HTTP.

### Support-matrix and lifecycle wording
- `guides/upgrade-path.md` — current support/lifecycle wording that Phase 69 should refine and narrow.
- `test/threadline/upgrade_path_doc_contract_test.exs` — current locked upgrade-path contract.
- `guides/operator-surface.md` — operator-surface scope boundary.
- `guides/integrations/sigra.md` — current reference integration wording.
- `README.md` — public entry-point wording that must not overclaim compatibility.
- `examples/threadline_phoenix/README.md` — current reference-path narrative.

### Proof and CI anchors
- `mix.exs` — declared dependency ranges, aliases, ExDoc groups, and current support-facing package metadata.
- `.github/workflows/ci.yml` — stable job IDs and current verification topology.
- `examples/threadline_phoenix/mix.exs` — current Phoenix/Sigra reference-path dependency posture.
- `mix verify.compile_no_optional`
- `mix verify.test`
- `mix verify.example`
- `mix verify.doc_contract`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Plug` already embodies the core request-path contract cleanly: one actor callback and one additive metadata callback with strict validation.
- `Threadline.Job` already provides the right low-abstraction job contract and avoids framework lock-in.
- `Threadline.Integrations.Sigra` already demonstrates the soft-dependency reference-adapter posture that later integrations can copy.
- `Threadline.OperatorSurface.Auth` and `ExportAuthPlug` already form a coherent dual-transport auth model with shared telemetry semantics.
- `guides/upgrade-path.md` and its doc-contract test already give a place to tighten support wording without inventing lifecycle structure from scratch.

### Established Patterns
- Threadline prefers concrete, named seams over speculative abstraction layers.
- Optional dependency posture is enforced with file-scope gating and explicit compile-without-optional proof.
- Public-facing docs are increasingly locked by source-reading doc-contract tests; Phase 69 should follow the same pattern for contract and support wording.
- The project already distinguishes host-owned auth from Threadline-owned surface composition; this boundary should remain firm.

### Integration Points
- Add a new canonical contract document that explains how `Plug`, `Job`, operator-surface auth, and `Integrations.*` fit together.
- Narrow `guides/upgrade-path.md` so the support matrix becomes lane-oriented and clearly tied to repo proof.
- Refresh README and possibly Sigra guide wording so they use the Phase 69 lane vocabulary consistently.
- Extend doc-contract coverage so the integration contract and support-lane language cannot drift in later phases.
- Reuse existing CI jobs and aliases as proof anchors unless planners find a concrete mismatch between the desired wording and what the repo currently verifies.

</code_context>

<deferred>
## Deferred Ideas

- A formal adapter behaviour, protocol, or umbrella abstraction across Plug/Job/operator-surface integrations — defer until multiple first-party integrations prove that the current documented seams are insufficient.
- Additional first-party integrations beyond Sigra — belongs to later breadth phases once the contract is frozen.
- A broader multi-framework compatibility matrix spanning non-Phoenix hosts, alternate auth stacks, or arbitrary optional-dependency combinations — out of scope for Phase 69.
- `threadline_web` extraction pressure — explicitly deferred to Phase 72.
- New auth capabilities, saved scopes, role models, or surface-owned permissions — outside v1.19 breadth scope.

</deferred>

---

*Phase: 69-integration-contracts-and-support-matrix*
*Context gathered: 2026-05-07*
