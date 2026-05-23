# Phase 82: Saved Views Session Handoff Repair - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Repair the saved-view actor/session handoff so the normal `threadline_operator_surface/2` mount path delivers reliable actor-owned behavior for saved views and related operator-surface ownership flows. This phase closes the broken default mount-path gap from the v1.20 audit. It does not add new saved-view capabilities, invent a Threadline-owned auth model, or broaden scope into export delivery/runtime work owned by later phases.

</domain>

<decisions>
## Implementation Decisions

### Normal mount behavior
- **D-01:** The default operator-surface mount path must auto-wire actor session handoff when `threadline_operator_surface/2` receives `:actor_fn`. Saved views should work in the canonical mount recipe without adopters adding an extra router plug manually.
- **D-02:** `Threadline.OperatorSurface.SessionPlug` remains a real module and reusable seam, but it is no longer the primary DX path for standard mounts. The macro-owned mount boundary should install or compose the handoff automatically for the optional Phoenix surface lane.
- **D-03:** Auto-wiring is conditional, not universal: only activate actor session handoff when `:actor_fn` is present. No `:actor_fn` means no actor-owned saved-view behavior is promised.
- **D-04:** Preserve an escape hatch for advanced adopters who truly want manual control or explicit opt-out, but do not make the manual path the documented default.

### Actor authority and precedence
- **D-05:** `actor_fn`-derived session actor is the canonical ownership authority for saved views whenever it exists.
- **D-06:** `authorize_fn` scope stays authorization/scoping data, not a second primary actor channel. `scope.actor_ref` / legacy `scope.user_id` fallback remains compatibility-only when no session actor is available.
- **D-07:** If both sources exist and disagree, session actor wins. Do not silently let `authorize_fn` scope override saved-view ownership.
- **D-08:** Planner should include an explicit mismatch signal for the “session actor and fallback scope actor differ” case. Warning/telemetry is preferred over silent ambiguity.

### Contract and ecosystem posture
- **D-09:** Keep Threadline’s host-owned auth boundary intact: `actor_fn` determines identity, `authorize_fn` determines allow/deny and optional scope, `export_authorize_fn` remains the HTTP-specific override seam.
- **D-10:** The fix should strengthen the existing public contract rather than add a new vocabulary. Threadline already says `actor_fn` is the only actor-authority callback on the request path; Phase 82 should make the operator surface behave the same way in practice.
- **D-11:** The normal conn -> session -> LiveView handoff is the idiomatic Phoenix/LiveView path for a reusable library. Do not introduce a second canonical actor API for sockets or teach scope-as-identity as an equal model.

### DX and least-surprise guardrails
- **D-12:** Saved-view ownership should feel “automatic once you provide `actor_fn`” because that is what adopters will reasonably infer from the current docs and mount examples.
- **D-13:** `actor_fn` used for operator-surface handoff should be documented as pure, idempotent, and host-auth-derived. Avoid side effects or expensive work inside the callback because it may run on normal surface requests.
- **D-14:** The example app and guides must stop demonstrating ambiguous actor semantics. The canonical example mount should use a real `ActorRef`-returning `actor_fn`, not a free-form map shape that `SessionPlug` cannot serialize.
- **D-15:** Brownfield compatibility matters, but it should be framed honestly: fallback from scope-derived actor data is a temporary bridge for existing mounts/tests, not the preferred long-term ownership model.

### Verification posture
- **D-16:** Phase 82 must close both implementation and evidence gaps for Phase 77. Verification/validation should prove the standard mount path, not only scoped or synthetic fallback paths.
- **D-17:** Tests should explicitly cover: standard mount with `actor_fn`, no-actor mount behavior, legacy scope-only fallback, and mismatch precedence when both sources exist.

### the agent's Discretion
- Exact macro composition technique for auto-wiring `SessionPlug`, as long as the public mounted DX becomes truthful and the host-owned auth boundary remains clear.
- Exact mismatch signaling mechanism (telemetry, warning log, or both), as long as conflicting actor sources are not silently normalized.
- Exact deprecation wording/timeline for `scope.user_id` fallback, as long as docs clearly demote it from first-class semantics.

</decisions>

<specifics>
## Specific Ideas

- The coherent recommendation set is:
  - macro-owned session handoff for the optional operator-surface lane
  - `actor_fn` session actor as sole canonical owner when present
  - scope-derived actor only as compatibility fallback
  - explicit mismatch signaling instead of silent override
  - example/docs/tests aligned around that one story
- Relevant ecosystem lesson: successful Phoenix/LiveView libraries keep authentication in the host pipeline/session and treat mount hooks as consumers of that state, not as a second identity-definition layer. Threadline should follow that posture.
- Key local inconsistency to repair: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` currently returns a plain map from `my_actor_fn/1`, while `SessionPlug` persists only `%Threadline.Semantics.ActorRef{}` values. The canonical example must be corrected or adapted so the default mount path actually exercises the documented contract.
- User workflow preference for future GSD discussions:
  - discuss all meaningful gray areas by default
  - research first, including `prompts/` prior art when useful
  - synthesize one cohesive recommendation set with defaults chosen
  - interrupt only for truly high-impact decisions the user is likely to care about personally

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract and audit driver
- `.planning/ROADMAP.md` — Phase 82 goal, success criteria, and audit-gap framing.
- `.planning/REQUIREMENTS.md` — `VIEW-01` and `VIEW-02` requirements.
- `.planning/v1.20-MILESTONE-AUDIT.md` — authoritative description of the broken normal mount path and missing verification closure.
- `.planning/STATE.md` — current milestone position and next-step framing.

### Prior locked context
- `.planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md` — host-owned auth boundary, canonical `/audit` mount topology, shared `%{assigns: assigns}` auth posture, and least-surprise operator-surface defaults.
- `.planning/phases/77-saved-views-ergonomics/77-DISCUSSION.md` — original design tradeoffs for session handoff vs other approaches.
- `.planning/phases/77-saved-views-ergonomics/77-01-SUMMARY.md` — shipped `SessionPlug` and LiveView session extraction baseline.
- `.planning/phases/77-saved-views-ergonomics/77-02-SUMMARY.md` — saved-view UI behavior assumptions and current claimed closure.
- `.planning/phases/73-authorization-contract-repair-and-scoped-access-enforcement/73-RESEARCH.md` — locked guidance on shared `%{assigns: assigns}` authorization and transport parity without inventing a second auth vocabulary.

### Current code and contract seams
- `lib/threadline/operator_surface/router.ex` — current mount macro boundary that must become responsible for the saved-view handoff in the default path.
- `lib/threadline/operator_surface/session_plug.ex` — existing conn-to-session actor handoff implementation.
- `lib/threadline/operator_surface/auth.ex` — session-first actor extraction plus scope fallback behavior.
- `lib/threadline/operator_surface/live/timeline_live.ex` — saved-view ownership behavior keyed off `@threadline_actor_ref`.
- `lib/threadline/operator_surface/export_auth_plug.ex` — export-side auth contract and shared `%{assigns: assigns}` fallback shape.
- `lib/threadline/plug.ex` — request-path contract stating `actor_fn` is the actor-authority callback.
- `lib/threadline/semantics/actor_ref.ex` — canonical actor value object and serialization contract.
- `lib/threadline/governance/saved_view.ex` — persisted actor-owned saved-view schema/changeset.

### Docs and example path that must stay coherent
- `guides/operator-surface.md` — canonical mount/auth/screens guide currently implying `actor_fn`-powered mounts should just work.
- `guides/integration-contracts.md` — public statement that `actor_fn` is the only actor-authority callback and `authorize_fn` owns authorization.
- `guides/integrations/sigra.md` — reference adapter posture separating request-path actor extraction from LiveView/export auth.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — canonical example mount and current actor-shape inconsistency.
- `examples/threadline_phoenix/README.md` — runnable example proof path that should align with the repaired mount story.

### Existing tests that define today’s behavior
- `test/threadline/operator_surface/session_plug_test.exs` — `SessionPlug` serialization behavior.
- `test/threadline/operator_surface/auth_test.exs` — session-first actor extraction and fallback behavior.
- `test/threadline/operator_surface/live/timeline_live_test.exs` — saved-view UI behavior, including current scope-only fallback path.
- `test/threadline/operator_surface/router_test.exs` — mount macro contract tests.
- `test/threadline/operator_surface/controllers/export_controller_test.exs` — operator-surface actor-owned export behavior implications.
- `test/threadline/operator_surface_doc_contract_test.exs` — public operator-surface wording lock.
- `test/threadline/integration_contracts_doc_contract_test.exs` — integration seam wording lock.
- `test/threadline/example_phoenix_readme_contract_test.exs` — example mount contract lock.

### Prompt / prior-art references
- `prompts/threadline-elixir-oss-dna.md` — least-surprise, doc-contract, canonical-example, and DX guardrails for Threadline.
- `prompts/audit-lib-domain-model-reference.md` — product thesis around “hardest to get wrong, easiest to understand, easiest to operate” and strong LiveView/Plug ergonomics.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — modern Phoenix/LiveView guidance on thin LiveViews, URL/state contracts, auth boundaries, and conn/session/socket patterns.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — operator ergonomics and ecosystem lessons for audit tooling.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.OperatorSurface.SessionPlug` already performs the core conn-to-session actor handoff. Phase 82 should reuse it rather than inventing a second transfer mechanism.
- `Threadline.OperatorSurface.Auth` already prefers session actor and only falls back to scope-derived actor data when session actor is absent.
- `TimelineLive` already gates saved-view loading and mutations on `@threadline_actor_ref`, so the main defect is delivery of that assign in the standard mount path.
- `ExportAuthPlug` and the surrounding operator-surface auth design already separate identity, authorization, and scoped visibility in a coherent way worth preserving.

### Established Patterns
- Threadline consistently treats `actor_fn` as the identity seam and `authorize_fn` as the allow/deny seam.
- The project favors one canonical mount story with host-owned auth, not multiple co-equal integration narratives.
- Public contracts are aggressively locked by focused doc-contract tests and example-path tests; Phase 82 should extend that pattern rather than relying on prose alone.
- The repo’s product posture prizes “correct by default” and “hardest to get wrong,” which argues against keeping a hidden manual plug prerequisite for a shipped surface capability.

### Integration Points
- Repair the macro mount path so `actor_fn`-backed mounts populate `threadline_actor_ref` consistently for LiveViews.
- Align example router, guides, and tests around a real `ActorRef`-returning actor callback.
- Preserve compatibility fallback in `Auth`, but demote it in docs and verification language.
- Add mismatch-precedence proof so downstream work does not accidentally reopen scope-vs-session ambiguity.

</code_context>

<deferred>
## Deferred Ideas

- Full deprecation/removal of `scope.user_id` compatibility fallback can wait until after the repaired default path ships and adopters have a migration story.
- Broader export-runtime, cleanup, and adapter-backed delivery work remains in Phases 83-84.
- Any redesign of saved-view UX beyond ownership reliability is out of scope for this phase.

</deferred>

---

*Phase: 82-saved-views-session-handoff-repair*
*Context gathered: 2026-05-23*
