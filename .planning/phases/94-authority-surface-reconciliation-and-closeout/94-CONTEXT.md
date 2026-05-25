# Phase 94: authority-surface-reconciliation-and-closeout - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Reconcile v1.21's active authority surfaces with the verified current-tree support-lane contract, then re-run milestone closeout honestly. This is a truth-repair and closeout phase, not a new feature phase. It may update milestone-planning files, the milestone audit, and a narrowly scoped stale narrative doc where that narrative still contradicts shipped reality.

It does not widen the support lane, invent a new auth or tenancy model, create a second support product tree, or turn Phase 94 into a broad public-doc rewrite.

</domain>

<decisions>
## Implementation Decisions

### Authority hierarchy

- **D-01:** Use a split authority hierarchy by concern rather than a single-file SSOT.
- **D-02:** `ROADMAP.md` is the active milestone contract. It states what v1.21 claims and what Phase 94 must finish.
- **D-03:** `v1.21-MILESTONE-AUDIT.md` is the closeout gate. It decides whether the current-tree proof is sufficient to call the milestone closeout-ready.
- **D-04:** `STATE.md` is execution-only. It records where the milestone run currently stands, not independent requirement truth.
- **D-05:** `PROJECT.md` is narrative/current-product framing only. It must not contradict the active contract, audit verdict, or state snapshot, but it must also not become a second bookkeeping ledger.
- **D-06:** The example app and its README remain proof artifacts for the `sigra-reference` lane, not milestone-authority surfaces.
- **D-07:** When the active roadmap wording and the milestone audit disagree, the audit wins until the roadmap is reconciled in the same closeout pass.

### Claim wording scope

- **D-08:** Use one exact proven-set claim across the active authority and public contract surfaces instead of broad “support-safe” shorthand.
- **D-09:** The reconciled v1.21 support-lane claim should name the exact proven mounted set directly: timeline, actor, transaction, support-scoped row history / as-of, and export denial posture.
- **D-10:** Coverage and policy surfaces remain admin/global or unsupported for support-scoped sessions and must be described that way explicitly.
- **D-11:** Avoid persona-matrix expansion or marketing-style broadening in Phase 94. Threadline's stronger posture is “exact proven set + unclaimed elsewhere,” not a richer role/capability framework.
- **D-12:** `guides/upgrade-path.md` remains the canonical support-matrix authority, but the active authority surfaces should repeat the same exact clause so readers do not have to infer milestone truth from cross-document abstraction.

### Closeout bar

- **D-13:** Phase 94 should use a bounded truth-bundle closeout bar, not an audit-only pass.
- **D-14:** The minimum truthful pass is: reconcile authority surfaces, refresh active traceability files where Phase 94 changes truth, then re-run the milestone audit.
- **D-15:** `REQUIREMENTS.md` must move with the same pass if `DOC-01` and `DOC-02` are being closed; otherwise the repo remains self-contradictory.
- **D-16:** `STATE.md` and the current-state sections of `PROJECT.md` should move in the same pass as the audit rerun when the “what is left / what is next” story changes.
- **D-17:** Keep Phase 80's truth taxonomy explicit in Phase 94 planning and verification:
  - `implemented` is not `integrated`
  - `integrated` is not `satisfied`
  - artifact creation alone is not proof
- **D-18:** Do not expand Phase 94 into release-ops theater such as broad RC signoff, packaging ceremony, or unrelated CI hygiene beyond what is necessary to make the milestone truth surfaces agree.

### Deferred cleanup boundary

- **D-19:** Reconcile all authoritative milestone surfaces in Phase 94 and include one narrow patch to `guides/how-threadline-works.md` where it still presents already-shipped governance/export capabilities as future work.
- **D-20:** Treat `guides/how-threadline-works.md` as a crash-course narrative doc, not a contract surface or new SSOT. Fix contradiction, not style.
- **D-21:** Do not turn Phase 94 into a broad narrative/doc sweep. Broader JTBD polishing, restructuring, and unrelated guide cleanup stay out of scope.
- **D-22:** Public contract/proof surfaces (`guides/upgrade-path.md`, `guides/operator-surface.md`, `guides/getting-started-saas.md`, `guides/integration-contracts.md`, `examples/threadline_phoenix/README.md`) should only be touched in Phase 94 if needed to preserve the already-verified support-lane claim and authority layering.

### Recommendation-first workflow posture

- **D-23:** The user's preference is to discuss all gray areas, use research-backed cohesive recommendations by default, and interrupt only for truly high-impact decisions.
- **D-24:** That preference is already encoded in `.planning/config.json` via:
  - `discuss_use_subagent_research`
  - `discuss_default_cohesive_recommendations`
  - `discuss_default_gray_areas: "all"`
  - `discuss_research_all_gray_areas_default`
  - `discuss_one_shot_cohesive_context_default`
  - `discuss_trust_cohesive_research_unless_high_impact`
  - `discuss_interactive_menus_high_impact_only`
- **D-25:** No further workflow/config mutation is required for this phase unless a later high-impact decision crosses the configured escalation tags.

### the agent's Discretion

- Exact wording for the split authority hierarchy, as long as the concern boundaries above remain explicit.
- Exact phrasing of the repeated proven-set support-lane clause, as long as it names the exact mounted support-visible set and export posture truthfully.
- Whether the targeted `guides/how-threadline-works.md` correction is framed as “remove stale future wording,” “refresh crash-course narrative,” or equivalent, as long as it remains tightly bounded.
- Exact sequencing of roadmap/state/requirements/project/audit updates, as long as the final active surfaces agree and the audit is rerun on the reconciled tree.

</decisions>

<specifics>
## Specific Ideas

- The strongest cohesive recommendation is:
  keep authority layered by concern, repeat one exact proven-set support-lane clause, run a bounded truth-bundle closeout pass, and include one narrow crash-course-doc correction so first-time readers are not misled by stale future-tense prose.
- The strongest ecosystem lesson is:
  successful operator/admin/support surfaces separate mount/auth, query scoping, and privileged actions explicitly. Threadline's milestone truth surfaces should mirror that explicitness instead of collapsing into one vague “support mode” story.
- The strongest maintainer lesson from Threadline's own recent history is:
  if narrative or roadmap optimism outruns current-tree proof, the project pays for it later in repair phases. Phase 94 should prefer bounded truth repair over continuity theater.
- The strongest DX posture for this phase is:
  a fresh maintainer should be able to read the active milestone surfaces and get the same answer the code, tests, example app, and public contract docs prove.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` — Phase 94 goal, plan slots, and active v1.21 milestone contract
- `.planning/REQUIREMENTS.md` — `DOC-01` and `DOC-02` traceability that Phase 94 must close honestly
- `.planning/STATE.md` — current execution snapshot that must be reconciled with the repaired closeout truth
- `.planning/PROJECT.md` — current-product narrative that must not contradict the authority layer
- `.planning/v1.21-MILESTONE-AUDIT.md` — current milestone closeout gate and gap list

### Locked upstream context and precedent
- `.planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md` — truth taxonomy and authoritative-surface precedence precedent
- `.planning/phases/89-contract-lock-final-verification/89-CONTEXT.md` — layered public authority, truth-first reconciliation, and narrow follow-up boundary
- `.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md` — verified-with-followup current-tree contract state and named authority drift
- `.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md` — Phase 89 closeout evidence and explicit `89-03`-style reconciliation trigger
- `.planning/phases/90-phase-85-verification-backfill/90-VALIDATION.md`
- `.planning/phases/91-phase-86-verification-backfill/91-VALIDATION.md`
- `.planning/phases/92-phase-87-verification-backfill/92-VALIDATION.md`
- `.planning/phases/93-phase-88-verification-backfill/93-VALIDATION.md`

### Public contract and proof surfaces
- `guides/upgrade-path.md` — canonical support-matrix and lane taxonomy authority
- `guides/operator-surface.md` — `/audit` mount/auth/screens contract, including mounted parity and support-lane language
- `guides/getting-started-saas.md` — canonical first-hour `/audit` recipe and scoped support-lane walkthrough
- `guides/integration-contracts.md` — host-owned seam contract for `authorize_fn`, `scope_query_fn`, and `export_authorize_fn`
- `examples/threadline_phoenix/README.md` — runnable `sigra-reference` proof artifact
- `guides/how-threadline-works.md` — crash-course narrative doc with explicitly named stale future-tense drift

### Tests that lock the claim boundary
- `test/threadline/operator_surface_doc_contract_test.exs`
- `test/threadline/upgrade_path_doc_contract_test.exs`
- `test/threadline/getting_started_saas_doc_contract_test.exs`
- `test/threadline/integration_contracts_doc_contract_test.exs`
- `test/threadline/example_phoenix_readme_contract_test.exs`

### Research and product philosophy
- `.planning/research/v1.21-cross-ecosystem-lessons.md` — strongest operator-surface, scope, and export posture lessons
- `.planning/research/v1.21-option1-proof-only-support-lane.md` — proof-only v1.21 framing
- `prompts/threadline-elixir-oss-dna.md` — docs/tests/examples as product surface philosophy
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — ecosystem posture, DX, and product-boundary guidance
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md`
- `.planning/config.json` — already-locked recommendation-first discuss posture

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The repo already has a strong layered public contract split: `upgrade-path`, `operator-surface`, `getting-started-saas`, `integration-contracts`, and the example README each own a clear concern.
- The existing doc-contract tests already lock the exact support-lane wording tightly enough that Phase 94 can standardize one proven-set clause instead of inventing new documentation machinery.
- The example Phoenix app already proves the intended architectural shape: one shared `/audit` tree, host-owned auth, scoped support reads, and separate export denial.

### Established Patterns
- Threadline treats docs, tests, examples, and verification artifacts as first-class product and truth surfaces.
- Recent repair phases consistently move proof and active planning surfaces together instead of treating verification artifacts as sufficient on their own.
- The project prefers host-owned auth and scope semantics with function-shaped seams over library-owned policy DSLs or role models.

### Integration Points
- Phase 94 planning should connect the authority-layer files (`ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `PROJECT.md`, milestone audit) into one reconciled closeout story.
- If public contract wording changes are needed, they should reuse the same exact proven-set clause already reflected in guides/tests/example proof, not create a second wording family.
- The narrow `guides/how-threadline-works.md` patch should remove contradiction while preserving that doc's role as a crash-course narrative, not a contract source.

</code_context>

<deferred>
## Deferred Ideas

- Audit-led single-file SSOT for all milestone truth — rejected in favor of layered authority by concern
- Broad “support-safe `/audit` lane” wording without enumerating the exact proven set
- Persona/capability matrix expansion for support/admin/denied surfaces as a new maintained product surface
- Full release-closeout or RC-style operational sweep beyond the bounded truth-bundle needed for Phase 94
- Broad rewrite or restructuring of `guides/how-threadline-works.md`
- General public-doc cleanup outside contradictions that materially affect the verified v1.21 claim boundary

</deferred>

---

*Phase: 94-authority-surface-reconciliation-and-closeout*
*Context gathered: 2026-05-25*
