# Phase 88: Denial / Fallback UX Closure - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the remaining support-lane denial and fallback UX gaps so the canonical `/audit` surface behaves with least surprise when an action or screen is unavailable. This phase covers export denial posture, unsupported support-lane surface messaging, fallback transport guidance, and cross-transport parity between LiveView and HTTP.

It does not add a new auth model, a second support-specific route tree, a Threadline-owned policy engine, or a new generalized operator UI family.

</domain>

<decisions>
## Implementation Decisions

### Navigation posture

- **D-01: Use a hybrid visibility model.** Hide unavailable actions from the primary UI chrome, but keep canonical `/audit` LiveView routes reachable by direct URL and render an explicit unsupported shell there.
- **D-02: Do not use disabled controls as the default support-lane pattern.** Disabled export/download buttons communicate less truth than hidden controls plus explicit direct-route messaging.
- **D-03: Keep one canonical `/audit` tree.** Unsupported support-lane pages should not 404 or redirect as if the page does not exist; they should explain that the current access tier or proven lane does not include that surface.
- **D-04: Keep risky HTTP endpoints server-authoritative.** Export/download HTTP endpoints remain plain-text `403 forbidden` through `ExportAuthPlug`; denial is not softened into a redirect or a UI-only convention.

### Export posture and support-lane auth

- **D-05: `export_authorize_fn` is the canonical per-user support-lane gate on the shared mount.** On the single canonical `/audit` tree, support denial should come from the explicit export auth callback, not from route-level `exports: false`, unless the host deliberately wants the export HTTP surface removed entirely for that mount.
- **D-06: Support-scoped users are read-only by default and export remains a separate privileged capability.** This phase should reinforce `AUTH-01`, not weaken it with softer implied inheritance from read access.
- **D-07: The LiveView and HTTP export faces must stay aligned.** Hiding export affordances in the timeline is convenience UX; the HTTP endpoints remain the real authority and must deny consistently.

### Unsupported / denied shell semantics

- **D-08: Keep one shared unsupported/denied shell component, but move to per-surface descriptors.** Threadline should not fork bespoke templates per screen, but it should stop using one fully generic body for every unavailable surface.
- **D-09: Distinguish denial from unavailability.**
  - `export_denied` is a permission boundary.
  - `coverage_unavailable`, `policy_redaction_unavailable`, and `retention_unavailable` are support-lane or transport-availability boundaries.
- **D-10: Copy should say only what Threadline knows.** The library should state that a surface/action is unavailable for the current support lane or requires explicit host authorization; it should not speculate about the adopter’s internal role/policy reasoning.
- **D-11: Keep unsupported/denied screens short and structured.** One title, one brief explanatory body, one fallback transport hint, and one recovery path back to the timeline are sufficient.
- **D-12: Accessibility stays calm by default.** Unsupported/denied screen containers stay `role="status"`; `role="alert"` is reserved for urgent dynamic failures such as failed export rows or validation errors.

### Fallback transport posture

- **D-13: Use a truthful hybrid fallback model.** When Threadline can safely and honestly derive an exact fallback transport from the current state, show it; otherwise show a surface-specific generic fallback that names the right transport without pretending exact parity.
- **D-14: Never use fake example commands as recovery guidance.** Generic demo literals such as `mix threadline.export --dry-run --table posts` are not acceptable if they do not reflect the current operator question or state.
- **D-15: Export denial gets the strongest fallback fidelity.** When current filters can be expressed safely with `mix threadline.export`, the denied export surface should prefer an exact dry-run-first command derived from the current filter/query state or persisted `job.query_params`.
- **D-16: Coverage fallback is exact only if Threadline truly supports the same shape.** If schema- or state-specific parity is not available, the UI should use a generic `mix threadline.health.coverage` fallback and not imply that the CLI reproduces the exact page state.
- **D-17: Policy redaction fallback can stay direct and surface-specific.** `mix threadline.policy.show` is a truthful fallback for the current governance view.
- **D-18: Retention history must not overclaim parity.** `mix threadline.retention.purge --dry-run` may be offered only as an operational fallback, not as if it reproduces historical retention-run viewing.
- **D-19: Future unsupported support-lane surfaces should register a fallback intent, not paste freeform strings into LiveViews.** The phase should bias toward a small internal descriptor/fallback contract so docs, tests, and copy do not drift.

### Documentation and contract alignment

- **D-20: Docs should teach one coherent posture.** “Hide unavailable actions in the happy path; direct URLs explain; export HTTP routes still deny; fallback transports are named explicitly.”
- **D-21: Reconcile prior doc drift around `exports: false`.** Earlier support-lane wording that used `exports: false` as the default support recipe should be updated so it does not conflict with the locked single-tree `/audit` story from Phase 87 and the current per-user auth model.
- **D-22: Treat literal fallback and denial copy as product contract.** The repo’s doc-contract and LiveView tests already make this surface sticky enough that planning should handle copy changes deliberately, not as incidental polish.

### Recommendation-first downstream posture

- **D-23: Downstream planning should treat these defaults as locked unless a true high-impact issue appears** in one of the configured GSD categories: `semver`, `security_model`, `breaking_public_api`, or `scope_cut`.
- **D-24: No extra GSD preference shift is required for this phase.** `.planning/config.json` already encodes the user’s standing preference: research first, use subagent-backed discuss synthesis, discuss all gray areas by default, and interrupt only for very high-impact decisions.

### the agent's Discretion

- Exact module/function names for the per-surface descriptor or fallback-intent plumbing, as long as the public UX contract above stays intact.
- Exact body-copy wording for each unavailable surface, as long as it remains brief, truthful, and surface-specific.
- Whether exact export fallback generation lives in the LiveView, a shared helper, or an operator-surface support module, as long as unsafe or lossy command generation falls back to a generic truthful transport.
- Whether retention fallback copy explicitly says “ops fallback” or equivalent phrasing, as long as it does not imply exact history-view parity.

</decisions>

<specifics>
## Specific Ideas

- The strongest coherent recommendation is:
  one canonical `/audit` tree, hidden unavailable actions in normal navigation, explicit unsupported shells for direct-route LiveView surfaces, and hard `403` denial for HTTP export/download endpoints.
- The strongest fallback philosophy is:
  exact when truthfully derivable, otherwise surface-specific and honest, never fake-example guidance.
- The best copy split is:
  `Action Denied` for export permission boundaries, `Unsupported View` or tighter surface-specific headings for support-lane/global-governance surfaces.
- The strongest doc correction is:
  support users on the shared mount should usually fail `export_authorize_fn`; `exports: false` is reserved for mounts where the host intentionally does not expose export HTTP routes at all.
- The project-level workflow preference requested in this discussion is already shifted left in `.planning/config.json`, including:
  - `discuss_use_subagent_research`
  - `discuss_default_cohesive_recommendations`
  - `discuss_default_gray_areas: "all"`
  - `discuss_interactive_menus_high_impact_only`
  No additional config mutation is required for Phase 88.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and requirement contract
- `.planning/ROADMAP.md` — Phase 88 goal, plan slots, and dependency on the support-lane proof work from Phases 86 and 87.
- `.planning/REQUIREMENTS.md` — `AUTH-01`, `UX-01`, and `UX-02` are the direct requirement contract for this phase.
- `.planning/PROJECT.md` — overall product thesis: one truthful operator surface, host-owned auth/tenancy meaning, strong DX, and least-surprise operations.
- `.planning/config.json` — the current GSD recommendation-first discuss posture that should not be re-opened for low-impact choices.

### Prior locked context
- `.planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md` — host-owned auth boundary, transport split, and support-lane honesty policy.
- `.planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md` — one canonical `/audit` tree, fallback-parity framing, and no support-specific product tree.
- `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-CONTEXT.md` — export delivery/auth posture and job-centric operator flow.
- `.planning/phases/85-support-lane-surface-audit/85-CONTEXT.md` and `.planning/phases/85-support-lane-surface-audit/85-RECOMMENDATION.md` — support-lane claim lock and export as a separate privileged capability.
- `.planning/phases/86-scoped-read-path-closure/86-DISCUSSION.md` — read-path closure rules so Phase 88 does not mislabel row history/as-of as unsupported.
- `.planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-DISCUSSION.md` — single canonical mount story and rejection of a separate support route tree.
- `.planning/phases/88-denial-fallback-ux-closure/88-UI-SPEC.md` — locked UI contract for hidden affordances, unsupported shells, copy anchors, and accessibility rules.

### Current implementation seams
- `lib/threadline/operator_surface/auth.ex` — assigns `threadline_exports_enabled`, `threadline_coverage_enabled`, and `threadline_policy_enabled` from host-owned callbacks.
- `lib/threadline/operator_surface/export_auth_plug.ex` — HTTP export/download denial contract (`403 forbidden`) and telemetry parity.
- `lib/threadline/operator_surface/router.ex` — single `/audit` LiveView tree plus separate export HTTP scope.
- `lib/threadline/operator_surface/components/unsupported_view.ex` — shared unsupported shell component.
- `lib/threadline/operator_surface/unsupported.ex` — current title/body constants that should evolve toward per-surface descriptors.
- `lib/threadline/operator_surface/components/surface_header.ex` — coverage/policy badge visibility behavior.
- `lib/threadline/operator_surface/live/timeline_live.ex` — hidden export-affordance behavior on the primary support lane.
- `lib/threadline/operator_surface/live/export_status_live.ex` — denied export-status shell and fallback wording.
- `lib/threadline/operator_surface/live/coverage_live.ex` — unsupported coverage shell and schema-specific surface behavior.
- `lib/threadline/operator_surface/live/policy_redaction_live.ex` — unsupported policy shell.
- `lib/threadline/operator_surface/live/retention_history_live.ex` — unsupported retention-history shell.
- `lib/mix/tasks/threadline.export.ex` — exact capabilities and limits of the CLI fallback transport.

### Tests and docs that lock this surface
- `test/threadline/operator_surface/live/timeline_live_test.exs` — export-affordance hiding and support-lane behavior.
- `test/threadline/operator_surface/live/export_status_live_test.exs` — export denial copy and status-page fallback behavior.
- `test/threadline/operator_surface/live/coverage_live_test.exs` — unsupported coverage shell contract.
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs` — unsupported policy shell contract.
- `test/threadline/operator_surface/live/retention_history_live_test.exs` — unsupported retention shell contract.
- `guides/operator-surface.md` — fallback-parity and operator-surface narrative that should align with the new denial/fallback posture.
- `guides/integration-contracts.md` — host-owned auth and callback-shape contract.
- `guides/getting-started-saas.md` — canonical `/audit` mount narrative for the example adopter.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — current example proof of the shared `/audit` tree and admin-only export posture.

### Product and ecosystem guidance
- `.planning/research/v1.21-cross-ecosystem-lessons.md` — strongest cross-ecosystem lessons on scoped operator surfaces, export posture, and capability gating.
- `prompts/threadline-elixir-oss-dna.md` — Threadline’s quality bar: truthful contracts, docs/tests alignment, and least-surprise contributor/operator behavior.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — product thesis for batteries-included audit tooling and the importance of truthful operator affordances.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.OperatorSurface.Components.UnsupportedView` already gives the right shared shell; the phase should enrich it with better surface-specific descriptor data rather than replace it.
- `Threadline.OperatorSurface.Auth` already computes per-surface capability flags cleanly from host callbacks; the main work is aligning copy, routing expectations, and docs around those flags.
- `ExportAuthPlug` already establishes the correct transport-level truth boundary for export/download denial.
- `TimelineLive`, `SurfaceHeader`, `CoverageLive`, `PolicyRedactionLive`, `RetentionHistoryLive`, and `ExportStatusLive` already expose all of the key affordance/unsupported-state seams Phase 88 needs to close.

### Established Patterns
- Threadline prefers one canonical operator surface over multiple product trees.
- The project consistently treats exports as more privileged than read-only browsing.
- Host apps own auth, roles, and tenancy semantics; Threadline owns where those decisions plug into the operator surface.
- Tests and docs already treat UI copy and denial behavior as contract surface, so this phase should tighten rather than improvise.

### Integration Points
- Replace hard-coded fallback strings with a small per-surface descriptor/fallback-intent layer behind the existing unsupported shell.
- Align timeline/export-status/header/unsupported pages so navigation hiding, direct-route messaging, and HTTP denial tell one coherent story.
- Update docs and example guidance so `export_authorize_fn` versus `exports: false` is taught correctly for the shared `/audit` mount.
- Keep future unsupported support-lane surfaces on the same descriptor-driven contract so they do not drift from docs/tests.

</code_context>

<deferred>
## Deferred Ideas

- A public extensibility API for adopter-supplied unsupported/denied descriptors — unnecessary unless multiple host customization demands appear.
- Perfect exact fallback parity for every governance surface — out of scope if the underlying CLI/API transport does not actually answer the same operator question.
- A second support-specific route tree or role-aware navigation DSL — explicitly contrary to the current milestone direction.
- Broader governance/compliance product expansion beyond denial/fallback truth repair — belongs to later evidence-plane work, not Phase 88.

</deferred>

---

*Phase: 88-denial-fallback-ux-closure*
*Context gathered: 2026-05-25*
