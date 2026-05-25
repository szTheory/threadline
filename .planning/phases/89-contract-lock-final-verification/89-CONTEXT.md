# Phase 89: Contract Lock & Final Verification - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Lock the named v1.21 support lane as a truthful current-tree contract, then verify that the public docs, example app, tests, and milestone-closeout surfaces all prove the same story on the shipped tree.

This phase is a contract-and-proof closeout phase, not a new feature phase. It may tighten claims, align docs, refresh example proof, add missing verification coverage, and, only if necessary, reconcile milestone authority surfaces. It does not widen Threadline into a new auth model, role DSL, tenancy DSL, second support-specific route tree, or broader compliance/evidence product.

</domain>

<decisions>
## Implementation Decisions

### Contract authority

- **D-01: Use layered authority by concern, not a single-doc SSOT.**
  - `guides/upgrade-path.md` is the authority for whether the lane is claimed at all and whether it is `supported`, `reference`, or `unclaimed`.
  - `guides/operator-surface.md` is the authority for the `/audit` support-lane behavior contract itself.
  - `guides/getting-started-saas.md` is the authority for the canonical first-hour/adopter recipe.
  - `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` and `examples/threadline_phoenix/README.md` are the runnable proof of the narrower Phoenix/Sigra reference path.
  - Tests enforce this hierarchy; they are not the primary public authority.
- **D-02: Do not promote the example app into the top-level contract authority.** The example proves the `sigra-reference` lane; it must not silently become the authority for the broader `phoenix-surface` support claim.
- **D-03: Do not treat tests as the canonical product surface.** ExUnit files are enforcement artifacts for maintainers, not the user-facing contract for adopters.
- **D-04: Keep `.planning/` artifacts out of the public contract layer.** They guide planning and verification, but public adopters should not have to infer the support claim from internal phase context.

### Verification bar

- **D-05: Use a layered contract-lock verification bar.** Phase 89 is only “locked” when four evidence bands agree on the current tree:
  - public contract text,
  - root behavioral proof,
  - example-host proof,
  - named verification/CI proof.
- **D-06: Public contract text is first-class product evidence.** The support-lane boundary must be aligned across `guides/operator-surface.md`, `guides/upgrade-path.md`, `guides/getting-started-saas.md`, `guides/integration-contracts.md`, and `examples/threadline_phoenix/README.md`.
- **D-07: Behavioral proof must be server-authoritative, not UI-only.** Hidden affordances are convenience UX only; support-lane proof must include scoped queries, explicit denial behavior, and transport parity where claimed.
- **D-08: If row history / as-of remains in the support-lane claim, it must have explicit proof equal in seriousness to timeline, actor, transaction, and export posture.** If that proof is not available on the current tree, the public claim must be narrowed rather than hand-waved.
- **D-09: The example app is mandatory proof, not optional garnish.** The routed Phoenix host path is part of the public truth model for this milestone.
- **D-10: Named `mix verify.*` entrypoints and CI jobs are part of the contract lock.** The current-tree proof must remain discoverable and rerunnable through stable aliases and workflow jobs.

### Drift handling

- **D-11: Use truth-first reconciliation with asymmetric bias.** If closeout finds drift between code, docs, example behavior, or milestone wording, narrow the public claim immediately unless the repair is already small, non-controversial, and fully provable on the current tree in the same pass.
- **D-12: Prefer narrowing over speculative “almost true” repair when the mismatch touches support scoping, export posture, auth, tenant semantics, or multi-surface proof.** Threadline’s credibility matters more than preserving the larger claim.
- **D-13: Repair in closeout only when the change is local and bounded.** The repair must not widen the milestone claim, cross into new capability work, or depend on future cleanup to become true.
- **D-14: Docs-only repair is insufficient when behavior is wrong, and code-only repair is insufficient when public docs/examples still overclaim.** Public contract surfaces and proof surfaces must converge together.
- **D-15: Preserve the Phase 80 taxonomy during closeout.**
  - `implemented` is not `integrated`
  - `integrated` is not `satisfied`
  - artifact creation alone is not proof

### Optional 89-03 trigger

- **D-16: Do not normalize `89-03` as routine ceremony.** Minor guide/example/test alignment stays inside `89-01`; verification evidence refresh stays inside `89-02`.
- **D-17: Open `89-03` only for authoritative-surface drift that changes milestone truth.** The optional reconciliation plan exists only if closeout reveals that active milestone authority surfaces would otherwise remain misleading on the current tree.
- **D-18: Authoritative-surface drift means one or more of the following:**
  - `ROADMAP.md`, `STATE.md`, or the current-state portions of `PROJECT.md` need correction, not just public guides,
  - the correction changes milestone truth rather than presentation,
  - the correction spans multiple authoritative artifacts or needs an explicit “implemented vs integrated vs satisfied” reconciliation,
  - absorbing the work into `89-01` or `89-02` would make those plans mixed-purpose and muddy the closeout boundary.
- **D-19: Do not open `89-03` for ordinary doc cleanup, proof tightening, or backlog capture.** README/guide wording drift, test refresh, or a new follow-up TODO alone are not milestone-surface reconciliation.

### Cohesive product posture

- **D-20: The support lane remains one truthful `/audit` surface, not a separate Threadline-owned product mode.** Phase 89 should lock the same posture established earlier in v1.21 rather than reopening it.
- **D-21: Host-owned auth and scope semantics remain the architectural center.** The contract lock should reinforce function-shaped seams (`authorize_fn`, `scope_query_fn`, `export_authorize_fn`) rather than invent a policy DSL.
- **D-22: Great DX means “one obvious place for each answer.”** Support-lane breadth, screen-level behavior, first-hour recipe, and example proof should remain intentionally separated instead of collapsed into one overloaded guide.
- **D-23: Great UX here means least surprise and explicit truth.** If something is unsupported, denied, scoped, or example-only, the docs and proof surfaces must say so plainly.

### the agent's Discretion

- Exact wording for the doc hierarchy, as long as authority by concern remains explicit.
- Exact test/file selection for the Phase 89 proof chain, as long as the four evidence bands remain intact.
- Whether row-history/as-of proof is strengthened or the public claim is narrowed, as long as the final contract is honest on the current tree.
- Whether `89-03` is described as “reconciliation,” “surface repair,” or equivalent, as long as it remains reserved for milestone-truth drift rather than ordinary finishing work.

</decisions>

<specifics>
## Specific Ideas

- The strongest cohesive recommendation is:
  keep layered public authority, layered proof, truth-first drift handling, and a narrow `89-03` trigger reserved for active milestone-surface reconciliation only.
- The strongest maintainability lesson from Threadline’s own history is:
  do not let closeout prose get ahead of current-tree proof; that is exactly how v1.20 needed repair phases.
- The strongest ecosystem lesson is:
  successful Phoenix/Plug/Ecto operator surfaces keep auth/tenant meaning host-owned, make permissions explicit, separate read capability from export/action capability, and use docs/tests/examples as a unified product contract rather than folklore.
- The cleanest closeout rule is:
  repair inline when the fix is small and fully provable now; otherwise narrow the claim and open explicit follow-up work.
- The user’s requested GSD preference shift is already present in `.planning/config.json`, including:
  - `discuss_use_subagent_research`
  - `discuss_default_cohesive_recommendations`
  - `discuss_interactive_menus_high_impact_only`
  - `discuss_default_gray_areas: "all"`
  - `discuss_research_all_gray_areas_default`
  - `discuss_one_shot_cohesive_context_default`
  - `discuss_trust_cohesive_research_unless_high_impact`
  No further config mutation is required for Phase 89.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and requirement contract
- `.planning/ROADMAP.md` — Phase 89 goal, plan slots, and the optional `89-03` boundary
- `.planning/REQUIREMENTS.md` — `DOC-01` and `DOC-02`
- `.planning/STATE.md` — current milestone state and closeout sequencing
- `.planning/PROJECT.md` — current milestone narrative and support-lane product thesis

### Locked upstream context
- `.planning/phases/85-support-lane-surface-audit/85-CONTEXT.md` — support-lane surface claim lock
- `.planning/phases/88-denial-fallback-ux-closure/88-CONTEXT.md` — denial/fallback and export posture contract
- `.planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md` — truth taxonomy and milestone-surface repair precedent
- `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-CONTEXT.md` — integrated-vs-satisfied closeout posture
- `.planning/research/v1.21-cross-ecosystem-lessons.md` — strongest cross-ecosystem support-lane guidance
- `.planning/research/v1.21-option1-proof-only-support-lane.md` — proof-only milestone framing

### Public contract surfaces
- `guides/operator-surface.md` — `/audit` contract, support-lane behavior, export posture, fallback parity
- `guides/upgrade-path.md` — lane/support matrix and `supported` vs `reference` vs `unclaimed`
- `guides/getting-started-saas.md` — canonical first-hour route to the mounted `/audit` surface
- `guides/integration-contracts.md` — host-owned auth/export/scope seam contract
- `examples/threadline_phoenix/README.md` — runnable reference proof narrative
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — canonical shared `/audit` mount with admin/support behavior

### Root proof and example proof surfaces
- `test/threadline/operator_surface_doc_contract_test.exs`
- `test/threadline/upgrade_path_doc_contract_test.exs`
- `test/threadline/getting_started_saas_doc_contract_test.exs`
- `test/threadline/integration_contracts_doc_contract_test.exs`
- `test/threadline/example_phoenix_readme_contract_test.exs`
- `test/threadline/operator_surface/live/timeline_live_test.exs`
- `test/threadline/operator_surface/live/actor_live_test.exs`
- `test/threadline/operator_surface/transaction_live_test.exs`
- `test/threadline/operator_surface/controllers/export_controller_test.exs`
- `test/threadline/operator_surface/live/export_status_live_test.exs`
- `test/threadline/operator_surface/live/coverage_live_test.exs`
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs`
- `test/threadline/operator_surface/live/retention_history_live_test.exs`
- `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs`
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs`

### Verification and packaging entrypoints
- `mix.exs` — named `mix verify.*` aliases and docs extras
- `.github/workflows/ci.yml` — current proof jobs and CI discoverability contract

### Product and ecosystem guidance
- `prompts/threadline-elixir-oss-dna.md` — Threadline’s OSS quality bar and doc/test-as-product-surface stance
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — product thesis and recurring audit-library footguns
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The current public guide split is already close to the recommended authority hierarchy; Phase 89 should tighten and name it rather than reinvent it.
- The repo already has stable doc-contract tests and named verification aliases, which means the contract-lock work can stay aligned with existing project habits instead of adding a new proof mechanism.
- The example Phoenix app already demonstrates the right architectural shape: one shared `/audit` tree, host-owned operator auth, scoped support reads, and export denial separated from general read access.

### Established Patterns
- Threadline treats docs, examples, and verification artifacts as part of the product surface.
- Threadline prefers host-owned auth/tenant semantics and function-shaped seams over a built-in policy DSL.
- Threadline has recent history showing that overstated milestone surfaces are expensive to repair later; current-tree truth must win over continuity theater.
- Optional Phoenix/UI capability remains in-tree but honest: capture-only adopters should not pay for or infer unsupported UI behavior.

### Integration Points
- Phase 89 planning should connect the public guides, example host path, and proof suites into one explicit “contract lock” story.
- If row-history/as-of remains in the support-lane claim, planning must ensure its proof is upgraded into the same first-class evidence band as timeline/actor/transaction/export.
- If closeout reveals authoritative milestone-story drift, planning must split that work cleanly into `89-03` instead of smuggling reconciliation into ordinary doc or verification tasks.

</code_context>

<deferred>
## Deferred Ideas

- A single-document SSOT for all support-lane concerns — rejected in favor of layered authority by concern
- Treating the example app as the top-level contract authority for the root library
- Browser-driven full E2E matrix expansion beyond the current layered proof bar
- Routine reconciliation/cleanup subphases for every milestone closeout
- Any new auth model, role DSL, tenancy DSL, or second support-specific route tree

</deferred>

---

*Phase: 89-contract-lock-final-verification*
*Context gathered: 2026-05-25*
