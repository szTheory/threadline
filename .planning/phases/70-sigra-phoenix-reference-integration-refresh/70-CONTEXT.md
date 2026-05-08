# Phase 70: Sigra/Phoenix Reference Integration Refresh - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Refresh the existing Sigra-backed Phoenix reference path so it matches the locked support-lane contract from Phase 69, the current optional-dependency posture, and the canonical surface-first adoption story from Phase 68. This phase updates the reference integration wording, example-app contract, proof pins, and fallback guidance. It does not add a second reference integration, broaden support claims into a larger compatibility matrix, make Sigra a hard dependency, or move Threadline toward owning auth.

</domain>

<decisions>
## Implementation Decisions

### Version posture and proof pins

- **D-105: Use lane-split version wording.** Library/package/install docs should keep declared semver ranges for the reusable `phoenix-surface` lane, while the narrower `sigra-reference` lane names exact tested resolutions from the example app lockfile as proof pins.
- **D-106: Keep exact proof pins out of generic install snippets.** Root library wording should not imply that exact Phoenix or Sigra patch versions are required for every adopter. Exact versions belong in the support matrix and the example-app reference contract.
- **D-107: Distinguish root-lane proof from example-lane proof explicitly.**
  - `phoenix-surface` proof comes from root `mix.exs`, root `mix.lock`, root CI, and root doc-contract coverage.
  - `sigra-reference` proof comes from `examples/threadline_phoenix/`, its lockfile, its README, and `mix verify.example`.
- **D-108: Avoid range-only compatibility language for the Sigra lane.** `{:sigra, "~> 0.2", optional: true}` is a host install shape, not a promise that all Sigra `0.2.x` hosts are covered.

### Reference-path auth story

- **D-109: Keep Sigra as the request-capture adapter only.** The canonical Sigra story remains: a Phoenix host already using Sigra wires `Threadline.Integrations.Sigra` into `Threadline.Plug` for request capture.
- **D-110: Keep the operator surface behind host-owned browser/admin auth.** `/audit` remains a host-mounted operator surface protected first by host pipeline/session policy, then by Threadline's final authorization hooks.
- **D-111: Document the dual-transport auth contract as intentional.**
  - request capture auth is host-owned and adapted through `actor_fn` + `context_overrides_fn`
  - LiveView operator auth is host-owned and checked through `authorize_fn`
  - export HTTP auth shares the same policy by default via the synthetic mirror fallback, with `export_authorize_fn` documented as the explicit advanced override
- **D-112: Do not romanticize Sigra into end-to-end auth.** Phase 70 wording must not imply that Sigra secures the operator surface or that Threadline owns roles, tenancy, or admin policy.

### Narrative shape

- **D-113: Keep one canonical surface-first reference narrative.** The main reference-path story should walk the adopter through Sigra-backed request capture, one audited request, mounting `/audit`, and verifying the same incident through the operator surface.
- **D-114: Name capture-only parity at each relevant step.** Surface-first does not mean UI-only. Every recommended surface-first operator flow should name the equivalent Mix-task or API/CLI fallback for capture-only adopters.
- **D-115: Preserve the “one obvious path” rule from Phase 68.** Do not present surface-first and capture-first as equal top-level onboarding choices.
- **D-116: Keep the example app as proof, not as the primary narrative owner.** User-facing guidance should stay canonical in guides; `examples/threadline_phoenix/README.md` remains the runnable contract that proves the path.

### Scope of the Sigra reference lane

- **D-117: Keep one maintained narrow Sigra lane.** `sigra-reference` means one first-party reference path for Phoenix hosts already using Sigra, one guide, one example app, and one proved callback pair.
- **D-118: Do not add a variants matrix in Phase 70.** Alternative router/auth/layout combinations may be plausible, but they remain `unclaimed` unless the repo adds proof for them later.
- **D-119: Keep the adapter concrete and small.** `Threadline.Integrations.Sigra` remains a soft-loaded reference adapter around the current Plug callback pair; Phase 70 should not turn it into a mini-framework or broader host-integration program.
- **D-120: Favor credibility over breadth theater.** If wording could be read as “generic Sigra compatibility,” tighten it until it clearly means “current first-party reference path only.”

### Downstream decision policy

- **D-121: Bias toward cohesive researched defaults over repeated user arbitration.** For this phase, downstream agents should treat the recommendations above as locked unless they uncover a direct contradiction in repo proof.
- **D-122: Interactive escalation should stay reserved for high-impact exceptions.** Only reopen decisions if the planner/researcher finds a conflict touching semver support claims, security model, breaking public API, or a real scope cut.

### the agent's Discretion

- Exact section and table wording used in `guides/upgrade-path.md`, `guides/integrations/sigra.md`, and `examples/threadline_phoenix/README.md`, as long as the lane boundaries above stay explicit.
- Exact placement of fallback-path reminders in guides and example docs, as long as surface-first remains the canonical flow.
- Exact doc-contract test file changes needed to lock proof-pin wording, lane language, and auth-boundary literals.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase contract
- `.planning/ROADMAP.md` §"Phase 70: Sigra/Phoenix Reference Integration Refresh" — goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` lines for `INTEG-02`, `COMPAT-03`, and `ADOPT-09` — the requirement contract this phase must satisfy.
- `.planning/PROJECT.md` §"Current Milestone: v1.19 — Integration Breadth" — breadth posture, optional-deps constraints, and milestone intent.
- `.planning/STATE.md` §"Current Position" and §"Session Continuity" — active sequencing and explicit next-step framing for Phase 70.

### Prior locked context
- `.planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md` — canonical surface-first narrative and "one obvious path" rule.
- `.planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md` — locked support-lane, auth-boundary, and proof-bar policy.

### Current support-lane and integration docs
- `guides/integration-contracts.md` — canonical breadth contract for `Threadline.Plug`, `Threadline.Job`, `Threadline.Integrations.*`, and operator-surface auth.
- `guides/upgrade-path.md` — canonical lane/support/proof matrix that Phase 70 must refresh, not widen.
- `guides/integrations/sigra.md` — current Sigra reference-lane wording and callback contract.
- `guides/getting-started-saas.md` — canonical first-hour narrative that the Phase 70 reference story must stay coherent with.
- `guides/operator-surface.md` — mount/auth/screens guide for the surface-first path.
- `README.md` — public entry wording for support lanes and reference-path discovery.

### Example-app proof path
- `examples/threadline_phoenix/README.md` — runnable reference contract and current Sigra/Phoenix proof pins.
- `examples/threadline_phoenix/mix.exs` — declared example-app dependency shape.
- `examples/threadline_phoenix/mix.lock` — exact tested example-lane resolutions.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — current request-path Sigra wiring and host-owned `/audit` boundary.

### Code seams and proof anchors
- `lib/threadline/integrations/sigra.ex` — current soft-loaded Sigra adapter behavior.
- `lib/threadline/operator_surface/router.ex` — secure-by-default operator-surface mount contract.
- `lib/threadline/operator_surface/auth.ex` — LiveView-side authorization contract.
- `lib/threadline/operator_surface/export_auth_plug.ex` — export-side authorization parity and synthetic mirror fallback.
- `mix.exs` — root optional dependency ranges and support-facing package posture.
- `mix.lock` — current tested root resolutions for the `phoenix-surface` lane.

### Tests that lock public wording and proof
- `test/threadline/integration_contracts_doc_contract_test.exs` — breadth-contract wording anchors.
- `test/threadline/upgrade_path_doc_contract_test.exs` — support-lane/proof matrix anchors.
- `test/threadline/integrations/sigra_doc_contract_test.exs` — Sigra guide contract anchors.
- `test/threadline/integrations/sigra_test.exs` — Sigra adapter behavior contract.
- `test/threadline/example_phoenix_readme_contract_test.exs` — example-app contract and version/proof wording anchors.
- `test/threadline/operator_surface/auth_test.exs` — LiveView-side auth behavior.
- `test/threadline/operator_surface/export_auth_plug_test.exs` — export auth parity behavior.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Integrations.Sigra` already provides the correct soft-loaded callback seam; Phase 70 should refine its presentation, not replace its shape.
- `guides/upgrade-path.md` already contains the three-lane matrix and current proof pins, giving Phase 70 a focused place to tighten wording.
- `examples/threadline_phoenix/README.md` already proves the current reference path end to end and names exact resolved versions.
- Operator-surface auth code already cleanly separates host browser/admin auth from Threadline's final authorization hooks.

### Established Patterns
- Threadline prefers a narrow, evidence-backed support story over broad compatibility language.
- Public docs are locked by focused doc-contract tests; Phase 70 should extend this pattern rather than rely on prose alone.
- The repo already distinguishes reusable library lanes from narrower example-app proof lanes.
- Prior phases established a canonical surface-first flow with explicit capture-only fallback parity.

### Integration Points
- Refresh `guides/upgrade-path.md` so lane wording, proof pins, and caveats stay coherent with current root/example resolution reality.
- Refresh `guides/integrations/sigra.md` so it clearly states the request-capture-only Sigra role and the host-owned operator-surface boundary.
- Refresh `examples/threadline_phoenix/README.md` so the reference path tells one surface-first story with explicit API/Mix fallback parity and accurate proof pins.
- Update any root README or guide cross-links needed so the support-lane discovery flow remains coherent.
- Extend doc-contract tests wherever wording or proof-pin literals change.

</code_context>

<specifics>
## Specific Ideas

- The strongest reference-path flow is: wire Sigra into `Threadline.Plug` -> send one audited request -> mount `/audit` behind host admin auth -> inspect the same incident in the surface -> name the equivalent API/Mix fallback path for capture-only operators.
- The most idiomatic support wording is: semver ranges in install/package docs, exact tested resolutions in support-matrix and example-proof docs.
- The most important caveat to repeat is: `sigra-reference` is a maintained first-party Phoenix reference path, not generic Sigra compatibility.
- The current project config already reflects the user's preferred GSD posture for this kind of phase: research-first, discuss all gray areas by default, cohesive recommendations by default, and only high-impact interactive escalation. Downstream agents should preserve that posture here.

</specifics>

<deferred>
## Deferred Ideas

- Additional Sigra/Phoenix router/auth/layout variants documented as first-party paths — defer until repo proof exists for them.
- A second first-party integration or non-Phoenix reference lane — separate future breadth work if justified.
- Expanding `Threadline.Integrations.Sigra` into telemetry hooks, richer host semantics, or a larger adapter abstraction — out of scope for Phase 70.
- Any wording that upgrades `reference` into `supported` without new proof.

</deferred>

---

*Phase: 70-sigra-phoenix-reference-integration-refresh*
*Context gathered: 2026-05-07*
