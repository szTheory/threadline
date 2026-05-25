# Phase 89: Contract Lock & Final Verification - Research

**Researched:** 2026-05-25 [VERIFIED: codebase grep]
**Domain:** Current-tree contract lock, support-lane proof, and milestone-closeout verification for the `/audit` surface [VERIFIED: codebase grep]
**Confidence:** HIGH for current-tree surfaces and proof entrypoints; MEDIUM for the exact amount of drift because some closeout truth still depends on whether row-history/as-of is repaired or narrowed in this phase [VERIFIED: codebase grep]

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01: Use layered authority by concern, not a single-doc SSOT.** [VERIFIED: codebase grep]
  - `guides/upgrade-path.md` is the authority for whether the lane is claimed at all and whether it is `supported`, `reference`, or `unclaimed`. [VERIFIED: codebase grep]
  - `guides/operator-surface.md` is the authority for the `/audit` support-lane behavior contract itself. [VERIFIED: codebase grep]
  - `guides/getting-started-saas.md` is the authority for the canonical first-hour/adopter recipe. [VERIFIED: codebase grep]
  - `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` and `examples/threadline_phoenix/README.md` are the runnable proof of the narrower Phoenix/Sigra reference path. [VERIFIED: codebase grep]
  - Tests enforce this hierarchy; they are not the primary public authority. [VERIFIED: codebase grep]
- **D-02: Do not promote the example app into the top-level contract authority.** The example proves the `sigra-reference` lane; it must not silently become the authority for the broader `phoenix-surface` support claim. [VERIFIED: codebase grep]
- **D-03: Do not treat tests as the canonical product surface.** ExUnit files are enforcement artifacts for maintainers, not the user-facing contract for adopters. [VERIFIED: codebase grep]
- **D-04: Keep `.planning/` artifacts out of the public contract layer.** They guide planning and verification, but public adopters should not have to infer the support claim from internal phase context. [VERIFIED: codebase grep]
- **D-05: Use a layered contract-lock verification bar.** Phase 89 is only “locked” when four evidence bands agree on the current tree: public contract text, root behavioral proof, example-host proof, and named verification/CI proof. [VERIFIED: codebase grep]
- **D-06: Public contract text is first-class product evidence.** The support-lane boundary must be aligned across `guides/operator-surface.md`, `guides/upgrade-path.md`, `guides/getting-started-saas.md`, `guides/integration-contracts.md`, and `examples/threadline_phoenix/README.md`. [VERIFIED: codebase grep]
- **D-07: Behavioral proof must be server-authoritative, not UI-only.** Hidden affordances are convenience UX only; support-lane proof must include scoped queries, explicit denial behavior, and transport parity where claimed. [VERIFIED: codebase grep]
- **D-08: If row history / as-of remains in the support-lane claim, it must have explicit proof equal in seriousness to timeline, actor, transaction, and export posture.** If that proof is not available on the current tree, the public claim must be narrowed rather than hand-waved. [VERIFIED: codebase grep]
- **D-09: The example app is mandatory proof, not optional garnish.** The routed Phoenix host path is part of the public truth model for this milestone. [VERIFIED: codebase grep]
- **D-10: Named `mix verify.*` entrypoints and CI jobs are part of the contract lock.** The current-tree proof must remain discoverable and rerunnable through stable aliases and workflow jobs. [VERIFIED: codebase grep]
- **D-11: Use truth-first reconciliation with asymmetric bias.** If closeout finds drift between code, docs, example behavior, or milestone wording, narrow the public claim immediately unless the repair is already small, non-controversial, and fully provable on the current tree in the same pass. [VERIFIED: codebase grep]
- **D-12: Prefer narrowing over speculative “almost true” repair when the mismatch touches support scoping, export posture, auth, tenant semantics, or multi-surface proof.** [VERIFIED: codebase grep]
- **D-13: Repair in closeout only when the change is local and bounded.** The repair must not widen the milestone claim, cross into new capability work, or depend on future cleanup to become true. [VERIFIED: codebase grep]
- **D-14: Docs-only repair is insufficient when behavior is wrong, and code-only repair is insufficient when public docs/examples still overclaim.** Public contract surfaces and proof surfaces must converge together. [VERIFIED: codebase grep]
- **D-15: Preserve the Phase 80 taxonomy during closeout.** `implemented` is not `integrated`; `integrated` is not `satisfied`; artifact creation alone is not proof. [VERIFIED: codebase grep]
- **D-16: Do not normalize `89-03` as routine ceremony.** Minor guide/example/test alignment stays inside `89-01`; verification evidence refresh stays inside `89-02`. [VERIFIED: codebase grep]
- **D-17: Open `89-03` only for authoritative-surface drift that changes milestone truth.** [VERIFIED: codebase grep]
- **D-18: Authoritative-surface drift means one or more of the following:** `ROADMAP.md`, `STATE.md`, or current-state parts of `PROJECT.md` need correction; the correction changes milestone truth; the correction spans multiple authoritative artifacts or needs explicit “implemented vs integrated vs satisfied” reconciliation; or absorbing the work into `89-01`/`89-02` would muddy the closeout boundary. [VERIFIED: codebase grep]
- **D-19: Do not open `89-03` for ordinary doc cleanup, proof tightening, or backlog capture.** [VERIFIED: codebase grep]
- **D-20: The support lane remains one truthful `/audit` surface, not a separate Threadline-owned product mode.** [VERIFIED: codebase grep]
- **D-21: Host-owned auth and scope semantics remain the architectural center.** The contract lock should reinforce `authorize_fn`, `scope_query_fn`, and `export_authorize_fn`, not invent a policy DSL. [VERIFIED: codebase grep]
- **D-22: Great DX means “one obvious place for each answer.”** [VERIFIED: codebase grep]
- **D-23: Great UX here means least surprise and explicit truth.** If something is unsupported, denied, scoped, or example-only, the docs and proof surfaces must say so plainly. [VERIFIED: codebase grep]

### Claude's Discretion

- Exact wording for the doc hierarchy, as long as authority by concern remains explicit. [VERIFIED: codebase grep]
- Exact test/file selection for the Phase 89 proof chain, as long as the four evidence bands remain intact. [VERIFIED: codebase grep]
- Whether row-history/as-of proof is strengthened or the public claim is narrowed, as long as the final contract is honest on the current tree. [VERIFIED: codebase grep]
- Whether `89-03` is described as “reconciliation,” “surface repair,” or equivalent, as long as it remains reserved for milestone-truth drift rather than ordinary finishing work. [VERIFIED: codebase grep]

### Deferred Ideas (OUT OF SCOPE)

- A single-document SSOT for all support-lane concerns. [VERIFIED: codebase grep]
- Treating the example app as the top-level contract authority for the root library. [VERIFIED: codebase grep]
- Browser-driven full E2E matrix expansion beyond the current layered proof bar. [VERIFIED: codebase grep]
- Routine reconciliation/cleanup subphases for every milestone closeout. [VERIFIED: codebase grep]
- Any new auth model, role DSL, tenancy DSL, or second support-specific route tree. [VERIFIED: codebase grep]

## Project Constraints (from CLAUDE.md)

- Keep the three-layer boundary intact: capture owns durable row mutation truth, semantics owns action intent, and exploration/operations owns timeline/export/health/retention/operator workflows. [VERIFIED: codebase grep]
- Use Threadline’s domain language consistently: `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation`. [VERIFIED: codebase grep]
- Prefer named verification entrypoints over ad-hoc commands: `mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix ci.all`. [VERIFIED: codebase grep]
- Treat README, guides, and example README as contract surfaces; doc contract tests are part of the quality bar. [VERIFIED: codebase grep]
- Keep CI job ids stable and keep expensive jobs running on `main` even if path filtering is added later. [VERIFIED: codebase grep]

## Current-Tree Contract Surfaces

- `guides/upgrade-path.md` is already the public authority for lane breadth and the `supported` / `reference` / `unclaimed` vocabulary. It ties each named lane to declared dependency ranges, lockfiles, CI coverage, and proof commands. [VERIFIED: codebase grep]
- `guides/operator-surface.md` is already the screen-level contract for the `/audit` surface, including the shared `%{assigns: assigns}` auth shape, export `403` posture, support-read-only recipe, and the claim that row history / as-of is part of the surface. [VERIFIED: codebase grep]
- `guides/getting-started-saas.md` is already the canonical adopter recipe and explicitly points operators to `/audit`, `mix threadline.incident`, `mix threadline.export --dry-run`, `mix threadline.health.coverage`, `mix threadline.policy.show`, `Threadline.history/3`, and `Threadline.as_of/4`. [VERIFIED: codebase grep]
- `guides/integration-contracts.md` is already the breadth contract for `Threadline.Plug`, `Threadline.Job`, `Threadline.Integrations.*`, and `threadline_operator_surface/2`, with host-owned auth and export semantics. [VERIFIED: codebase grep]
- `examples/threadline_phoenix/README.md` and `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` already prove the narrower `sigra-reference` lane with one shared `/audit` mount, host-owned operator auth, support scope returns, and admin-only export posture. [VERIFIED: codebase grep]
- The current milestone authority surfaces already flag row history / as-of as the remaining truth-sensitive area: `STATE.md` says the support scope seam was bypassed on 2026-05-24, `ROADMAP.md` says row history / as-of must be safely scoped rather than disabled, and `PROJECT.md` says that path must be treated conservatively until proven. [VERIFIED: codebase grep]

## Proof / Test Entrypoints

- Root doc-contract coverage already exists in focused files: `operator_surface_doc_contract_test.exs`, `upgrade_path_doc_contract_test.exs`, `getting_started_saas_doc_contract_test.exs`, `integration_contracts_doc_contract_test.exs`, and `example_phoenix_readme_contract_test.exs`. A targeted local run passed in this session with `30 tests, 0 failures`. [VERIFIED: mix test]
- Root behavioral proof already exists for timeline, actor, transaction, export denial, export status, coverage, policy redaction, and retention history through the `test/threadline/operator_surface/...` suites. The coverage/policy/retention batch passed in this session with `17 tests, 0 failures`. [VERIFIED: mix test]
- Example-host proof already exists in `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` and `posts_incident_json_path_test.exs`. The focused example run passed in this session with `8 tests, 0 failures`. [VERIFIED: mix test]
- Named proof entrypoints already exist in `mix.exs`: `verify.test`, `verify.example`, `verify.compile_no_optional`, and `ci.all`. `verify.doc_contract` exists, but it only runs `test/threadline/readme_doc_contract_test.exs`, not the broader support-lane guide contract suite. [VERIFIED: codebase grep]
- CI already exposes the discoverable job ids `verify-compile-no-optional`, `verify-test`, `verify-pgbouncer-topology`, `verify-docs`, `verify-hex-package`, and `verify-release-shape`. The `verify-test` job already runs `mix verify.test`, `mix verify.threadline`, `mix verify.example`, and `mix verify.doc_contract`. [VERIFIED: codebase grep]

## Likely Drift Or Verification Risks

- The largest likely truth gap is row history / as-of. The example router scopes `:timeline`, `:transaction`, `:transaction_header`, `:actor_history`, and `:export`, but it does not define a `:row_history` branch. The row-history component passes `scope_query_fn` into `Threadline.history/3` and `Threadline.as_of/4`, so the example support lane appears to fall through to the default unscoped query unless that branch is added or the public claim is narrowed. [VERIFIED: codebase grep]
- The public guides still speak as if row history / as-of is part of the supported support-lane story, so Phase 89 cannot treat this as a minor test gap. It is a contract-truth decision. [VERIFIED: codebase grep]
- Current named verification entrypoints are slightly misleading for doc lock. `mix verify.doc_contract` sounds broader than it is; by code it only runs the README contract file. Phase 89 should not rely on that alias alone for doc lock evidence. [VERIFIED: codebase grep]
- Local behavioral suites that mutate the shared PostgreSQL test database are not safe to fan out blindly. In this session, `export_controller_test.exs` failed once with a foreign-key violation when multiple DB-backed suites were run in parallel, then passed in isolation with `16 tests, 0 failures`. `test/support/data_case.ex` explicitly says the integration tests do not use sandboxing and rely on cleanup plus `async: false` patterns. [VERIFIED: mix test] [VERIFIED: codebase grep]
- `89-03` should stay contingent, but it is a real contingency if Phase 89 ends by narrowing the row-history/as-of claim and that forces milestone authority surfaces to change rather than just public guides. `ROADMAP.md`, `STATE.md`, and `PROJECT.md` are the likely affected surfaces. [VERIFIED: codebase grep]

## Planning Recommendations

- **89-01: Public docs, support matrix, and example contract lock.** Start by reconciling only the public authority surfaces: `guides/upgrade-path.md`, `guides/operator-surface.md`, `guides/getting-started-saas.md`, `guides/integration-contracts.md`, `examples/threadline_phoenix/README.md`, and the example router. Treat row-history/as-of as the explicit decision point: either add truthful support-lane proof and example scoping for `:row_history`, or narrow every public claim that currently includes it. [VERIFIED: codebase grep]
- **89-02: End-to-end verification and Nyquist closeout.** Build the closeout around four evidence bands, not one alias: targeted doc-contract tests, root operator-surface behavioral suites, focused example-host suites, and named Mix/CI entrypoints. Keep the quick-run commands serialized for DB-backed suites, because the local test harness is intentionally non-sandboxed. [VERIFIED: codebase grep] [VERIFIED: mix test]
- **Optional 89-03: milestone-surface reconciliation.** Open this only if the final truthful contract changes milestone authority, especially if row-history/as-of must be downgraded or reclassified in `ROADMAP.md`, `STATE.md`, or current-state sections of `PROJECT.md`. Do not open it for ordinary guide wording, example README cleanup, or fresh verification artifacts alone. [VERIFIED: codebase grep]

