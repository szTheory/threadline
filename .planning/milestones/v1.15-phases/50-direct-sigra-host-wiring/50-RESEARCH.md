# Phase 50: Direct Sigra Host Wiring - Research

**Researched:** 2026-05-05
**Domain:** Direct Phoenix host wiring through `Threadline.Plug` using `Threadline.Integrations.Sigra`
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SIGRA-04 | `Threadline.Integrations.Sigra` composes directly with `Threadline.Plug` through native actor and context-override callbacks while preserving the soft-dependency contract. | The library adapter, router, and Sigra integration tests already expose the direct callback pair; Phase 50 should converge the example and docs on that exact surface rather than preserving app-local indirection. |
| SIGRA-05 | The shipped Phoenix example app demonstrates the direct Sigra wiring pattern without an example-only companion plug. | The example router already shows the direct callback pattern, but `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` still exists as a dead delegate and the example-facing docs/tests need one clearer real-path proof for the no-header fallback case. |
</phase_requirements>

<findings>
## Findings

1. The direct callback shape is already the active implementation path. `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` plugs `Threadline.Plug` with `Threadline.Integrations.Sigra.actor_ref_from_conn/1` and `audit_context_overrides_from_conn/1` directly.
2. The example-local `ThreadlinePhoenix.AuditActor` module is now only a rename seam around the shipped adapter. Keeping it weakens the canonical copy-paste story and conflicts with the locked Phase 50 preference for one visible module name.
3. Adapter-level behavior is already well covered in `test/threadline/integrations/sigra_test.exs`. Phase 50 does not need to duplicate the full impersonation or token matrix in the example app; it needs one honest router-driven proof that the direct callback path still synthesizes correlation metadata when `x-correlation-id` is absent.
4. `guides/integrations/sigra.md` is already close to the target posture. The remaining docs gap is mostly around example-facing wording: the example README still says the actor callback “delegates to” the adapter instead of teaching the direct callback names as the canonical path.
5. The worktree already contains Phase 51-adjacent incident auth changes. Planning must explicitly keep that surface out of Phase 50 except for “do not regress” awareness.
</findings>

<recommended_split>
## Recommended Plan Decomposition

### Plan 50-01: Converge the direct wiring contract in code and request-path tests

**File cluster**
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`
- `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex`
- `lib/threadline/integrations/sigra.ex`
- `test/threadline/integrations/sigra_test.exs`
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs`
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs`

**Why this is one plan**
- These files all prove the shipped runtime contract: one canonical adapter name, direct `Threadline.Plug` composition, soft-dependency-safe request-edge behavior, and a real router-driven fallback-path check.

**Verification**
- `mix test test/threadline/integrations/sigra_test.exs`
- `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_audit_path_test.exs test/threadline_phoenix_web/posts_correlation_path_test.exs`

### Plan 50-02: Align the canonical Sigra docs and drift guards

**File cluster**
- `guides/integrations/sigra.md`
- `examples/threadline_phoenix/README.md`
- `test/threadline/integrations/sigra_doc_contract_test.exs`

**Why this is one plan**
- These files are the public explanation layer for the same direct wiring contract. They should move together so the guide, example README, and doc-contract test all describe one blessed path.

**Verification**
- `mix test test/threadline/integrations/sigra_doc_contract_test.exs`

</recommended_split>

<scope_guards>
## Scope Guards

### Keep in Phase 50
- Direct callback wiring through `Threadline.Plug`
- Removal of example-only Sigra rename seams
- Adapter and example tests that prove the direct path
- Sigra guide and example README wording for the direct callback story

### Leave for Phase 51
- Auth policy expansion for `GET /api/audit_transactions/:id/changes`
- Tenancy or richer authorization language
- Incident-focused guide rewrites beyond avoiding contradictory wording
- Example-app auth matrices for impersonation, tokens, or anonymous incident access
</scope_guards>

<risks>
## Risks and Mitigations

| Risk | Why it matters | Mitigation |
|------|----------------|------------|
| Planning around the dirty worktree as if it were a clean baseline | Could produce plans that accidentally “re-add” already-landed direct router wiring. | Treat the router’s current direct callback block as the baseline and plan only convergence or cleanup around it. |
| Pulling Phase 51 incident auth into Phase 50 | Would blur requirement ownership and expand verification surface. | Keep Phase 50 centered on Sigra host wiring; mention the incident endpoint only as adjacent work that must not be regressed. |
| Repeating the full Sigra semantic matrix in example tests | Inflates example scope and duplicates library-level truth. | Keep richer impersonation/token semantics in `test/threadline/integrations/sigra_test.exs`; add only one real router-driven no-header fallback proof in the example app. |
| Keeping both `ThreadlinePhoenix.AuditActor` and `Threadline.Integrations.Sigra` as public names | Weakens adopter guidance and invites drift. | Remove the dead delegate and teach one canonical adapter name everywhere user-facing. |
</risks>

<planner_guidance>
## Planner Guidance

- Prefer a two-plan phase. A third plan is unnecessary unless the current worktree reveals a hidden implementation cluster the context does not show.
- Anchor all example-facing code and docs on the exact direct callback names already present in the router.
- Treat `test/threadline/integrations/sigra_test.exs` as the adapter-truth file and the example request-path tests as golden-path proofs only.
- Use the example README and Sigra guide to teach “plug the shipped adapter directly into `Threadline.Plug` after auth has populated request state.”
- Preserve the soft-dependency posture: tolerant request-edge reads, strict Threadline-owned callback/output contract.
</planner_guidance>

## RESEARCH COMPLETE
