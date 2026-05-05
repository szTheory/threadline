# Phase 50: direct-sigra-host-wiring - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the shipped Sigra integration the canonical direct host-wiring path through
`Threadline.Plug`. This phase should tighten the reference-app, docs, and tests
around the native callback composition that Phase 49 enabled:

- `actor_fn` remains the sole actor-authority path
- `context_overrides_fn` remains additive request metadata only
- Sigra stays a soft dependency

This phase is about the direct wiring contract and its proof surfaces. It is
not the phase for broadening the example app into a full auth matrix or for
turning the incident drill-down auth boundary into the main story; that belongs
to Phase 51.

</domain>

<decisions>
## Implementation Decisions

### Canonical example shape
- **D-01:** The Phoenix example app should wire directly to `Threadline.Integrations.Sigra.*` in the router and any mirrored docs. Do not preserve an example-local wrapper seam just to rename the shipped adapter.
- **D-02:** Remove the thin example-local `AuditActor` delegate if it no longer adds real host-owned behavior. A dead seam creates a second canonical name for the same contract and weakens the copy-paste story.
- **D-03:** Keep the visible wiring point where Phoenix users expect it: the `:api` router pipeline composed directly with `Threadline.Plug`, `actor_fn`, and `context_overrides_fn`.

### Proof depth and example scope
- **D-04:** The example app should prove the shortest honest golden path: the canonical session-based direct wiring flow through the real router and request pipeline.
- **D-05:** Impersonation and API-token semantics stay primarily locked at the library adapter layer (`test/threadline/integrations/sigra_test.exs`) and in the Sigra guide, not expanded into a larger example-app auth matrix.
- **D-06:** Add or tighten one example-facing proof for the no-header fallback path so the real router-driven example shows Sigra session correlation being derived through the native callback path when `x-correlation-id` is absent.
- **D-07:** Do not let the example app imply that Threadline owns impersonation policy, token issuance semantics, tenancy, or broader authorization design. Those are host concerns or later-phase concerns.

### Adapter strictness and DX posture
- **D-08:** Keep the Sigra adapter tolerant at the request edge. It should continue reading Sigra-populated maps or structs from `conn.assigns.current_scope` and `conn.private[:sigra_session]` defensively, returning `nil` / `%{}` for unsupported or absent shapes rather than raising.
- **D-09:** Keep strictness on Threadline-owned normalized output and public callback contracts, not on foreign request-state shape. This matches the project’s existing posture: strict `Threadline.Plug` contract, tolerant request-edge adapter.
- **D-10:** Tolerant does not mean vague. Documentation and tests must spell out the exact subset of Sigra-populated fields Threadline consumes, so hosts know what contract is expected without needing exact struct coupling.
- **D-11:** Do not tighten Phase 50 around “real Sigra structs only.” That would erode the soft-dependency story, make test/support shims less honest, and be less idiomatic for Plug/Phoenix request-edge integration.

### Docs and ecosystem framing
- **D-12:** The reference-app and Sigra docs should teach the canonical direct path with the shortest honest explanation: “plug the shipped adapter directly into `Threadline.Plug` after auth has established request state.”
- **D-13:** Keep the Sigra guide as the authoritative place for supported-but-not-example-expanded semantics such as impersonation and API-token mapping.
- **D-14:** Preserve the already-locked separation of concerns from Phase 49: `actor_fn` decides who acted; `context_overrides_fn` fills additive request metadata only when baseline extraction has no value; inbound request headers remain authoritative.
- **D-15:** The example README should say the app wires directly to `Threadline.Integrations.Sigra.actor_ref_from_conn/1` and `audit_context_overrides_from_conn/1`. Avoid “delegates to” wording that suggests an app-local seam is part of the blessed pattern.

### Planning / discussion preference
- **D-16:** For low- and medium-impact planning choices in this project, prefer recommendation-first synthesis backed by research over interactive option menus. Escalate interactively only when a choice materially affects semver, security model, breaking public API, or milestone scope.

### the agent's Discretion
- Exact wording of direct-wiring prose in guides and README, as long as it preserves the direct-callback story and host-owned boundaries.
- Exact naming and placement of the example-facing fallback-path test, as long as it proves the real router path rather than only unit-level adapter composition.
- Whether to document the consumed Sigra field subset as a compact list, table, or short prose block, as long as the contract stays explicit.

</decisions>

<specifics>
## Specific Ideas

- Preferred mental model: the reference app should teach the shortest honest golden path through the public integration surface, not the full space of auth variants.
- The best copy-paste story is one module name across router, guide, tests, and README: `Threadline.Integrations.Sigra`.
- If a host genuinely needs app-specific normalization, that should happen in upstream auth/normalization plugs before `Threadline.Plug`, not through a no-op delegate that renames the shipped adapter.
- The right strictness split is: permissive at the Plug/Phoenix request edge, explicit and narrow at the Threadline callback/output boundary.
- Incident drill-down auth changes currently visible in the dirty worktree should not pull Phase 50 into re-scoping. Keep Phase 50 centered on direct Sigra wiring; let Phase 51 own the authenticated drill-down story.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active milestone context
- `.planning/ROADMAP.md` — Phase 50 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — `SIGRA-04` and `SIGRA-05` define the required direct-wiring contract and example-app adoption surface.
- `.planning/STATE.md` — current milestone sequencing, dirty-worktree note, and the explicit instruction that Phase 50 is next.

### Prior decisions that constrain this phase
- `.planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md` — locks the direct `Threadline.Plug` callback story, additive-only override semantics, and header precedence.
- `.planning/milestones/v1.14-phases/44-sigra-integration-adapter/44-CONTEXT.md` — locks the Sigra adapter scope, soft-dependency posture, mapping semantics, and earlier example-app adoption choices.
- `.planning/milestones/v1.14-phases/47-saas-adopter-onramp/47-CONTEXT.md` — reinforces the project preference for the shortest honest adoption path and marker-backed example/docs alignment.
- `.planning/milestones/v1.14-phases/48-threadline-0.3.0-release/48-CONTEXT.md` — records the recommendation-first preference for low/medium-impact decisions and the docs-layering expectations.

### Code surfaces to inspect and likely change
- `lib/threadline/integrations/sigra.ex` — direct Sigra adapter contract, soft-dependency boundary, and request-edge tolerance.
- `lib/threadline/plug.ex` — native callback composition and additive override enforcement already locked by Phase 49.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — canonical direct-wiring proof point in the example app.
- `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` — remove if it remains a dead delegate with no host-owned behavior.
- `examples/threadline_phoenix/README.md` — example-app explanation of the direct callback path.
- `guides/integrations/sigra.md` — authoritative adopter-facing Sigra wiring guide.
- `test/threadline/integrations/sigra_test.exs` — adapter-level truth for impersonation, API-token, and callback composition semantics.
- `test/threadline/integrations/sigra_doc_contract_test.exs` — doc drift guard for the Sigra integration contract.
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs` — canonical session-backed example path.
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs` — likely home for proving the router-driven no-header fallback correlation path.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` — reference for what belongs to Phase 51 instead of Phase 50.

### External ecosystem guidance
- `https://hexdocs.pm/phoenix/plug.html` — Phoenix/Plug guidance for wiring real plugs directly at the expected request pipeline boundary.
- `https://hexdocs.pm/plug/Plug.RequestId.html` — precedent for “existing request header wins; only fill when absent.”
- `https://hexdocs.pm/phoenix/mix_phx_gen_auth.html` — example of teaching the app-facing auth contract via the shortest golden path instead of an exhaustive auth matrix.
- `https://hexdocs.pm/guardian/plug-pipelines.html` — composable Plug pipeline guidance; useful contrast for when app-local bundling is warranted versus unnecessary indirection.
- `https://hexdocs.pm/ueberauth/Ueberauth.html` — direct library integration pattern for request-edge auth wiring.
- `https://github.com/pow-auth/pow` — reference for narrow getting-started flow with alternate behaviors documented separately.
- `https://www.django-rest-framework.org/api-guide/authentication/` — example of keeping distinct auth schemes explicit instead of overloading one reference path.
- `https://django-auditlog.readthedocs.io/en/latest/usage.html` — actor/correlation concerns kept explicit at the request edge in a mature audit library.
- `https://www.rubydoc.info/gems/paper_trail/PaperTrail%2FRequest.whodunnit%3D` — actor identity kept distinct from additional controller/request metadata.
- `https://www.rubydoc.info/gems/paper_trail/11.0.0/PaperTrail%2FRequest.controller_info` — additive request metadata separated from actor attribution in a mature audit library.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Integrations.Sigra.actor_ref_from_conn/1` and `audit_context_overrides_from_conn/1` already provide the canonical callback pair the phase wants to bless.
- `test/threadline/integrations/sigra_test.exs` already exercises the richer actor and correlation-shape matrix; Phase 50 should reuse that truth rather than duplicating it in the example app.
- The example router already shows the direct callback wiring pattern in the place Phoenix users expect to see it.

### Established Patterns
- Threadline prefers explicit, narrow, inspectable public contracts over hidden indirection.
- Phase 49 already established the “direct callbacks on `Threadline.Plug`” story; Phase 50 should simplify the example surface around that choice rather than softening it with aliases.
- The repo’s doc-contract discipline favors one canonical explanation path plus targeted drift guards, not multiple near-duplicate narratives.
- The project config now explicitly biases discuss/planning toward research-first cohesive recommendations and high-impact-only interactive menus; this context should preserve that posture for downstream agents.

### Integration Points
- Router and example README are the main user-facing surfaces for the canonical direct path.
- Sigra guide and Sigra doc-contract tests are the right place to keep fuller adapter semantics without inflating the example app into a broader auth tutorial.
- Example request tests should prove the golden path through the real Plug/Phoenix pipeline, while library tests retain the broader adapter matrix.

</code_context>

<deferred>
## Deferred Ideas

- Worked impersonation walkthrough in the example app — supported semantics can stay in the Sigra guide and library tests until a future phase explicitly broadens the example app’s auth story.
- Worked API-token walkthrough in the example app — same reasoning; avoid turning Phase 50 into a multi-mode auth tutorial.
- Any move toward requiring exact Sigra structs at runtime — only reconsider if the project intentionally abandons the soft-dependency posture in a future milestone.
- Broader incident drill-down auth/tenancy framing — belongs to Phase 51.
- Any additional host-owned normalization seam in the example app unless a future phase introduces real host behavior that justifies it.

</deferred>

---

*Phase: 50-direct-sigra-host-wiring*
*Context gathered: 2026-05-05*
