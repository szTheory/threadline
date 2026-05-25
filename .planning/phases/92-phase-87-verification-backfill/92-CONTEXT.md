# Phase 92: Phase 87 Verification Backfill - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the missing verification chain for Phase 87 on the current tree. This phase proves the canonical `/audit` mount recipe and example-app support lane honestly enough to close `ADOPT-01` and `ADOPT-02` without widening Threadline into a new auth model, support-specific route tree, or policy subsystem.

This is a verification-backfill phase, not new feature work. It may refresh proof, tighten docs/tests/example evidence, and reconcile authority surfaces if the truthful current-tree claim is narrower than the original Phase 87 intent. It does not reopen the one-tree `/audit` product decision, add a Threadline-owned role/tenant DSL, or smuggle Phase 93 denial/fallback scope into this phase.

</domain>

<decisions>
## Implementation Decisions

### Verification proof bar
- **D-01: Phase 92 should use a layered adopter-proof bar.** Do not close `ADOPT-01` and `ADOPT-02` with docs-only or test-only evidence.
- **D-02: Public contract proof is mandatory.** The canonical `/audit` recipe and example-host story must agree across `guides/getting-started-saas.md`, `examples/threadline_phoenix/README.md`, `guides/operator-surface.md`, and `guides/upgrade-path.md` where applicable.
- **D-03: Runnable example-host proof is mandatory.** Phase 92 must prove the shared `/audit` router recipe on the example Phoenix app, including the same-tree admin/support posture and admin-only export denial for support users.
- **D-04: Named rerun surfaces are part of the proof bar.** Verification should close through stable entrypoints already used by the repo such as `mix verify.doc_contract`, `mix verify.example`, and their CI jobs, not through one-off shell commands hidden only in the artifact.
- **D-05: Keep the proof bar adopter-facing.** Phase 92 is about proving the canonical recipe and example-host path; it should rely on upstream Phase 91 for row-history/as-of scope closure rather than re-expanding into deeper query proof unless the canonical recipe/example claim specifically depends on it.

### Truth-first drift handling
- **D-06: Use hybrid truth-first drift handling.** Repair inline when a mismatch is local, non-controversial, and fully provable on the current tree in the same pass.
- **D-07: Narrow the claim immediately when proof is weaker than intent.** If the current tree cannot honestly prove some part of the Phase 87 recipe/example story during this phase, mark that part narrower rather than preserving the older implementation aspiration.
- **D-08: Separate authority-surface reconciliation only when milestone truth changes.** If fixing or narrowing the claim requires updates to `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md`, or requirement status, treat that as explicit authority-surface work rather than burying it inside ordinary doc cleanup.
- **D-09: Respect Threadline’s claim taxonomy.** Anything not proven on the current tree should be treated as `unclaimed` or narrower, not implicitly supported because the architecture intends it.
- **D-10: Do not let Phase 92 absorb Phase 93 concerns.** Export fallback copy, unsupported-shell UX nuance, and broader denial ergonomics belong to the denial/fallback backfill unless they directly block truthful closure of the canonical recipe/example proof.

### Verification artifact shape
- **D-11: Use the existing split artifact pattern.** Phase 92 should produce `87-VERIFICATION.md` and `87-VALIDATION.md`, not a single omnibus verification document.
- **D-12: `87-VERIFICATION.md` owns the verdicts.** It should state phase goal, exact claim boundary, `ADOPT-01` / `ADOPT-02` closure status, canonical `/audit` recipe proof, example-host proof, caveats, and explicit “not closed here” boundaries.
- **D-13: `87-VALIDATION.md` owns the rerunnable evidence map.** It should capture requirement-to-command mapping, named verify aliases, CI discoverability, any Nyquist-style sampling notes, and final sign-off against the current tree.
- **D-14: Keep public docs/tests as product authority and `.planning/` as maintainer evidence.** The artifact records why the claim is true; it does not become the primary public contract adopters must read first.

### Locked upstream product posture
- **D-15: Keep one canonical `/audit` tree.** The original Phase 87 decision remains locked: admin and support personas share one host-owned route tree with narrower support capability on the same mount.
- **D-16: Keep auth, scope, and tenancy host-owned.** The canonical seams remain `authorize_fn`, `scope_query_fn`, and `export_authorize_fn`; no Threadline-owned policy DSL or support-role abstraction should be introduced.
- **D-17: Preserve least surprise for Phoenix adopters.** The recipe should continue to look like idiomatic Phoenix composition: host auth in front, mount macro inside one route scope, explicit server-authoritative export auth, and stable example proof.
- **D-18: Favor DX that is copy-pasteable and rerunnable.** The same files that teach the recipe should be the ones contract tests and example-host verification actually prove.

### the agent's Discretion
- Exact selection of command/test subsets, as long as the layered adopter-proof bar is satisfied.
- Exact wording for truth narrowing or inline repair, as long as the final claim matches the current tree.
- Exact section names inside `87-VERIFICATION.md` and `87-VALIDATION.md`, as long as verdicts and evidence remain clearly separated.

</decisions>

<specifics>
## Specific Ideas

- The strongest cohesive recommendation is:
  close Phase 92 only when adopter-facing docs, the example router, example-host behavior, and stable verify/CI surfaces all agree on the same canonical `/audit` story.
- The strongest ecosystem lesson is:
  successful Elixir/Phoenix operator surfaces keep auth and tenant meaning host-owned, scope every read path explicitly, and treat exports/actions as a separate capability from read-only browsing.
- The strongest product-trust lesson from Threadline’s own recent history is:
  do not preserve broader wording just because it was once planned; if proof is weaker than intent, narrow first and reopen only with fresh proof.
- The strongest maintainer-ergonomics recommendation is:
  keep Phase 92 evidence easy to rerun through `mix verify.doc_contract`, `mix verify.example`, and CI-discoverable jobs instead of bespoke artifact-only commands.
- The user’s requested GSD preference shift is already active in `.planning/config.json`, including:
  - `discuss_use_subagent_research`
  - `discuss_default_cohesive_recommendations`
  - `discuss_interactive_menus_high_impact_only`
  - `discuss_default_gray_areas: "all"`
  - `discuss_research_all_gray_areas_default`
  - `discuss_one_shot_cohesive_context_default`
  - `discuss_trust_cohesive_research_unless_high_impact`
  No further config mutation is required for this phase.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and requirement contract
- `.planning/ROADMAP.md` — Phase 92 goal, plan slots, and dependency on Phase 91.
- `.planning/REQUIREMENTS.md` — `ADOPT-01` and `ADOPT-02` are the direct requirement contract for this phase.
- `.planning/STATE.md` — current milestone routing, including Phase 91 complete and Phase 92 queued.
- `.planning/PROJECT.md` — current milestone thesis: one canonical `/audit` mount, host-owned auth/scope semantics, and truthful support-lane claims.

### Locked upstream context
- `.planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-DISCUSSION.md` — original Phase 87 locked product posture and rejection of a separate support tree.
- `.planning/phases/89-contract-lock-final-verification/89-CONTEXT.md` — layered authority, truth-first drift handling, and verification-bar philosophy.
- `.planning/phases/91-phase-86-verification-backfill/91-CONTEXT.md` — current-tree backfill posture and how verification phases should treat proof vs aspiration.
- `.planning/research/v1.21-cross-ecosystem-lessons.md` — strongest support-lane lessons from Phoenix/Elixir and adjacent ecosystems.
- `.planning/research/v1.21-option1-proof-only-support-lane.md` — narrow proof-only milestone framing for the shared `/audit` lane.
- `prompts/threadline-elixir-oss-dna.md` — repo-level OSS quality bar around verify aliases, docs-as-product-surface, and example-host proof.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — broader audit-platform strategy and recurring ecosystem footguns.

### Public contract surfaces
- `guides/getting-started-saas.md` — canonical first-hour adoption story and `/audit` mount recipe.
- `examples/threadline_phoenix/README.md` — runnable example-host proof narrative for the `sigra-reference` lane.
- `guides/operator-surface.md` — operator-surface mount/auth/screen contract.
- `guides/upgrade-path.md` — lane taxonomy and current support/reference/unclaimed posture.

### Current implementation and proof surfaces
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — one shared `/audit` mount and host-owned auth/scope/export seams.
- `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` — example-host proof for auth boundary, scoped support visibility, and export denial.
- `test/threadline/example_phoenix_readme_contract_test.exs` — locks the example README’s canonical operator-surface story.
- `test/threadline/getting_started_saas_doc_contract_test.exs` — locks the SaaS quickstart’s canonical mount and support-lane wording.
- `test/threadline/operator_surface_doc_contract_test.exs` — locks root operator-surface guide posture and mounted parity table.
- `mix.exs` — named verify aliases, especially `mix verify.doc_contract` and `mix verify.example`.
- `.github/workflows/ci.yml` — CI discoverability and rerun surface for the named verify jobs.

### Ecosystem guidance worth mirroring
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The repo already has the core layered proof ingredients: canonical recipe docs, example-host README, example-host integration tests, doc-contract tests, and named verify aliases.
- The example router already demonstrates the exact product posture this phase needs to verify: one shared `/audit` tree, shared assigns-shaped authorizer, explicit `export_authorize_fn`, and host-owned `scope_query_fn`.
- Current CI already exposes `mix verify.example` and `mix verify.doc_contract`, so Phase 92 can close through established project habits instead of inventing a new verification workflow.

### Established Patterns
- Threadline treats docs, tests, example apps, and verification artifacts as one contract chain.
- The project prefers truth-first narrowing over closeout theater when proof is weaker than wording.
- Host-owned auth and transport-neutral scoping are stable architectural pillars for the operator surface.
- Verification backfills in this milestone close against the current tree, not against the original implementation intent.

### Integration Points
- Re-verify the canonical `/audit` recipe across router, docs, and example-host tests.
- Confirm the public contract surfaces and example-host behavior agree on admin/support posture and export denial.
- If any claim changes, update the relevant authority surfaces and requirement status in the same pass.
- Produce `87-VERIFICATION.md` and `87-VALIDATION.md` using the established split verdict/evidence pattern.

</code_context>

<deferred>
## Deferred Ideas

- A heavier machine-readable evidence bundle or automated verification manifest system
- Any new Threadline-owned auth/tenant/role DSL
- A second support-specific route tree or broader support product mode
- Broader denial/fallback UX refinement beyond what is necessary to keep Phase 92 truthful

</deferred>

---

*Phase: 92-phase-87-verification-backfill*
*Context gathered: 2026-05-25*
