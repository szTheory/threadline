# Phase 93: Phase 88 Verification Backfill - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the missing verification chain for Phase 88 on the current tree. This phase proves the denial / fallback UX contract across the shipped `/audit` surface, HTTP export enforcement, public docs, example-host guidance, and named verification entrypoints.

This is a verification-backfill phase, not a new UX or auth phase. It may add or tighten proof, refresh artifacts, and update requirement-scoped authority surfaces when current-tree truth changes. It does not reopen the original Phase 88 product decisions, invent a new support tree, soften server-authoritative export denial, or absorb the broader milestone reconciliation work reserved for Phase 94.

</domain>

<decisions>
## Implementation Decisions

### Verification proof bar
- **D-01: Use a layered current-tree proof bar.** Phase 93 closes only when four evidence bands agree on the current tree:
  - root behavioral proof,
  - public doc-contract proof,
  - example-host proof,
  - verification artifacts plus requirement bookkeeping.
- **D-02: Behavior-only closure is insufficient.** Root tests for hidden export affordances, unsupported shells, and plain-text HTTP `403` are necessary but not enough to close `AUTH-01`, `UX-01`, and `UX-02`.
- **D-03: Release-grade global proof is unnecessary for this phase by default.** `mix ci.all` or broader release hygiene may be useful context, but Phase 93 should not depend on unrelated full-tree cleanliness unless the current-tree denial/fallback claim itself requires it.
- **D-04: The mandatory behavioral proof band must stay server-authoritative.** Hidden UI affordances are convenience UX only; proof must include direct HTTP denial and the mounted LiveView denial/unavailable states.
- **D-05: The mandatory doc/example proof band must explicitly cover the denial/fallback story adopters read first.** That means the operator guide, SaaS quickstart, integration contract wording where relevant, and the example README must all align with the same denial/fallback truth.
- **D-06: The mandatory rerun surfaces should stay discoverable.** Prefer named `mix verify.*` aliases and existing CI-visible proof entrypoints over one-off shell folklore.

### Truth-first drift handling
- **D-07: Use hybrid truth-first handling.** If Phase 93 finds drift, repair inline only when the mismatch is local, non-controversial, and fully re-provable on the current tree in the same pass.
- **D-08: Otherwise narrow immediately.** If making the older Phase 88 intent true would require non-local behavioral work, broader scope reopening, or speculative cleanup, narrow the claim instead of preserving intent by inertia.
- **D-09: Current-tree proof outranks continuity theater.** The artifact must describe what the repo proves today, not what the earlier phase meant to prove.
- **D-10: Partial convergence is a failure mode.** Do not repair code without matching docs/tests/authority surfaces, and do not narrow docs while behavior still overclaims.
- **D-11: Keep auth/export boundaries especially strict.** Any drift touching support export denial, fallback transport truthfulness, or authorization semantics should bias toward conservative narrowing unless the fix is truly small and same-pass provable.

### Authority surfaces and bookkeeping boundary
- **D-12: Phase 93 should update active authority surfaces only when proof changes truthful status or wording for this phase's mapped concerns.**
- **D-13: Requirement-scoped authority updates are allowed and expected when closure is real.** If Phase 93 closes `AUTH-01`, `UX-01`, and `UX-02`, update `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` narrowly and exactly.
- **D-14: Verification artifacts alone are insufficient when active milestone surfaces would remain falsely pending or otherwise misleading.**
- **D-15: Do not absorb Phase 94’s broader reconciliation job.** Public-contract cleanup and requirement-scoped status movement are fine here; milestone-wide authority reconciliation beyond Phase 93 truth remains separate work.
- **D-16: Broad reconciliation inside Phase 93 is justified only if the current tree contains a blocking contradiction so severe that deferring would leave the repo materially dishonest.**

### Cohesive DX/UX proof posture
- **D-17: Keep layered public authority by concern plus the shared internal descriptor contract.** Docs remain adopter-facing and readable; the descriptor-driven unsupported/denied shell remains the internal mechanism that reduces copy drift.
- **D-18: Keep one canonical `/audit` tree.** Denial/fallback verification should reinforce scoped behavior on the shared mount, not suggest separate admin/support feature trees or mount-specific product branches.
- **D-19: Keep docs/tests/examples as a unified product contract, not a generated maintainer-only matrix.** A generated SSOT or manifest-driven docs system is not the right default for this repo at its current size and product posture.
- **D-20: Preserve least surprise for adopters and contributors.** A human should be able to read the guides/example first, then rerun the same story through `mix verify.*`, without needing hidden maintainer knowledge.
- **D-21: Keep fake fallback examples out of the proof story.** The exact-vs-generic export fallback rule from Phase 88 is part of the contract and must remain truthful across runtime, docs, and tests.

### Ecosystem alignment
- **D-22: Stay idiomatic for Phoenix/Plug/LiveView.** Authorization must remain server-authoritative at the router/plug/mount boundary, never implied by hidden controls alone.
- **D-23: Stay idiomatic for an Ecto/Postgres audit library.** Verification should look like targeted ExUnit proof, named Mix entrypoints, and example-host reruns, not a heavy browser-first or generated-contract workflow.
- **D-24: Keep the project’s host-owned seam discipline.** Support-lane proof should continue reinforcing `authorize_fn`, `export_authorize_fn`, and related host callbacks rather than drifting toward a Threadline-owned policy DSL.

### the agent's Discretion
- Exact test and command selection, as long as the layered current-tree proof bar is satisfied.
- Exact wording inside `93-VERIFICATION.md` and `93-VALIDATION.md`, as long as verdicts stay narrower than implementation intent when truth is narrower.
- Whether a small same-pass repair happens in code, docs, tests, or phase artifacts, as long as it remains local and fully re-verified immediately.

</decisions>

<specifics>
## Specific Ideas

- The strongest cohesive recommendation is:
  use the same verification-backfill pattern established in Phases 90-92, but tuned to Phase 88’s denial/fallback contract: layered proof, truth-first drift handling, and narrow bookkeeping updates only when closure is real.
- The strongest ecosystem lesson is:
  successful Elixir/Phoenix libraries keep auth/tenant meaning host-owned, keep verification rerunnable through named Mix commands, and treat docs/tests/examples as one contract chain rather than scattered folklore.
- The most relevant outside examples are:
  Carbonite for durable truth posture and scope discipline, Hex.pm / Bytepack-style audit narratives for explicit operator truth, Oban for named rerunnable verification ergonomics, and PaperTrail as a reminder that lighter-weight or opt-in flows can look ergonomic while still letting proof drift if the contract is not enforced.
- The key footguns to avoid are:
  closing requirements from UI-only behavior,
  relying on hidden affordances without HTTP denial proof,
  preserving Phase 88 intent when current-tree proof is weaker,
  updating artifacts without updating active milestone truth,
  or reopening the one-tree `/audit` product direction.
- The user’s desired GSD preference shift is already reflected in `.planning/config.json`:
  - `research_before_questions: true`
  - `discuss_default_research_synthesis: true`
  - `discuss_use_subagent_research: true`
  - `discuss_default_cohesive_recommendations: true`
  - `discuss_interactive_menus_high_impact_only: true`
  - `discuss_default_gray_areas: "all"`
  - `discuss_research_all_gray_areas_default: true`
  - `discuss_one_shot_cohesive_context_default: true`
  - `discuss_trust_cohesive_research_unless_high_impact: true`
  No additional config mutation is required for this preference set.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and requirement contract
- `.planning/ROADMAP.md` — Phase 93 goal, plan slots, and dependency chain
- `.planning/REQUIREMENTS.md` — `AUTH-01`, `UX-01`, and `UX-02`
- `.planning/PROJECT.md` — project thesis and current milestone posture
- `.planning/STATE.md` — active milestone execution state and next-step sequencing

### Locked upstream context
- `.planning/phases/88-denial-fallback-ux-closure/88-CONTEXT.md` — locked product decisions for denial/fallback UX
- `.planning/phases/88-denial-fallback-ux-closure/88-UI-SPEC.md` — locked UI/copy/accessibility contract
- `.planning/phases/88-denial-fallback-ux-closure/88-RESEARCH.md` — implementation shape and proof targets
- `.planning/phases/88-denial-fallback-ux-closure/88-01-SUMMARY.md` — descriptor-driven denial/unavailability implementation summary
- `.planning/phases/88-denial-fallback-ux-closure/88-02-SUMMARY.md` — docs/contract-lock implementation summary
- `.planning/phases/89-contract-lock-final-verification/89-CONTEXT.md` — layered authority, truth-first drift handling, and closeout precedent
- `.planning/phases/90-phase-85-verification-backfill/90-RESEARCH.md` — pattern for narrow current-tree backfill and requirement-scoped closure
- `.planning/phases/91-phase-86-verification-backfill/91-CONTEXT.md` — verification-backfill proof-bar precedent
- `.planning/phases/92-phase-87-verification-backfill/92-RESEARCH.md` — layered adopter-proof precedent
- `.planning/v1.21-MILESTONE-AUDIT.md` — original gap source for the verification backfill chain

### Public contract surfaces
- `guides/operator-surface.md` — denial/fallback behavior and support-lane contract
- `guides/getting-started-saas.md` — first-hour support-lane recipe and fallback guidance
- `guides/integration-contracts.md` — host-owned auth/export/scope seam contract
- `guides/upgrade-path.md` — milestone support-lane framing where relevant
- `examples/threadline_phoenix/README.md` — runnable example-host support-lane guidance
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — shared `/audit` mount proof surface

### Runtime and proof seams
- `lib/threadline/operator_surface/unsupported.ex` — descriptor-driven unsupported/denied contract
- `lib/threadline/operator_surface/components/unsupported_view.ex` — shared unsupported shell
- `lib/threadline/operator_surface/export_auth_plug.ex` — server-authoritative HTTP denial contract
- `lib/threadline/operator_surface/live/timeline_live.ex` — hidden export affordance behavior
- `lib/threadline/operator_surface/live/export_status_live.ex` — denied export route behavior
- `lib/threadline/operator_surface/live/coverage_live.ex` — unsupported coverage shell
- `lib/threadline/operator_surface/live/policy_redaction_live.ex` — unsupported policy shell
- `lib/threadline/operator_surface/live/retention_history_live.ex` — unsupported retention shell

### Verification surfaces
- `test/threadline/operator_surface/live/timeline_live_test.exs`
- `test/threadline/operator_surface/controllers/export_controller_test.exs`
- `test/threadline/operator_surface/live/export_status_live_test.exs`
- `test/threadline/operator_surface/live/coverage_live_test.exs`
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs`
- `test/threadline/operator_surface/live/retention_history_live_test.exs`
- `test/threadline/operator_surface_doc_contract_test.exs`
- `test/threadline/getting_started_saas_doc_contract_test.exs`
- `test/threadline/integration_contracts_doc_contract_test.exs`
- `test/threadline/example_phoenix_readme_contract_test.exs`
- `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs`
- `mix.exs` — named `mix verify.*` aliases
- `.github/workflows/ci.yml` — CI discoverability of proof entrypoints

### Product and ecosystem guidance
- `prompts/threadline-elixir-oss-dna.md` — docs/tests/examples/verify commands as product surface
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — product strategy, footguns, and operator-surface lessons
- `prompts/audit-lib-domain-model-reference.md` — capture/semantics/exploration layering
- `prompts/prior-art/SOURCE-CANONICAL.md` — prior-art corpus map

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.OperatorSurface.Unsupported` already centralizes the denied/unavailable descriptor contract, which gives Phase 93 a stable proof anchor instead of scattered per-view literals.
- `ExportAuthPlug` already enforces the right HTTP truth boundary for support export denial.
- The repo already has doc-contract tests plus `mix verify.example`, so Phase 93 can reuse established proof entrypoints instead of inventing a new verification mechanism.

### Established Patterns
- This milestone’s backfill phases close against current-tree truth, not older intent.
- Threadline treats docs, examples, tests, and verification artifacts as a single contract chain with different authority levels.
- Host apps own auth, role meaning, and tenancy semantics; Threadline owns where those decisions plug into the operator surface.
- The project consistently prefers one canonical `/audit` tree over multiple persona-specific product trees.

### Integration Points
- Re-run and tighten the denial/fallback behavioral proof through the operator-surface LiveView and controller tests.
- Re-run and tighten the public-contract proof through guide/example doc-contract tests.
- Use `mix verify.example` as the example-host proof surface.
- Write `93-VERIFICATION.md` and `93-VALIDATION.md` as the maintainer evidence chain, then update active milestone truth surfaces narrowly if Phase 93 truly closes its mapped requirements.

</code_context>

<deferred>
## Deferred Ideas

- A generated proof manifest or machine-generated doc SSOT for denial/fallback contracts
- A separate admin/support product tree or broader mount-specific feature partitioning
- Broader milestone-surface reconciliation beyond Phase 93 truth
- Any Threadline-owned RBAC, tenancy DSL, or policy engine work

</deferred>

---

*Phase: 93-phase-88-verification-backfill*
*Context gathered: 2026-05-25*
