# Phase 51: authenticated-incident-drill-down - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn the example incident JSON drill-down path into a host-safe reference
pattern by requiring authentication before serving transaction changes, while
keeping tenancy and richer authorization explicitly outside Threadline's shipped
security model.

This phase hardens the existing reference path:

- `POST /api/posts` returns `audit_transaction_id`
- `GET /api/audit_transactions/:id/changes` returns stable JSON drill-down only
  to authenticated callers

It does **not** add a general-purpose authorization framework, tenant scoping
policy, or a broader example-app role matrix.

</domain>

<decisions>
## Implementation Decisions

### Auth boundary shape
- **D-01:** Keep the authentication gate in the example endpoint itself for this phase rather than introducing a new library abstraction or example-local reusable auth plug.
- **D-02:** Although Phoenix commonly uses route/pipeline plugs for authentication, the Phase 51 reference path should prefer the smallest honest implementation because only one endpoint is in scope and recent phases intentionally removed extra seams.
- **D-03:** If future phases add multiple protected incident endpoints, that is the point to factor the guard into a dedicated example plug or pipeline. Do not pre-abstract it in Phase 51.

### Authentication predicate
- **D-04:** Treat the reference endpoint as authenticated when `conn.assigns.audit_context.actor_ref` is present after normal request processing.
- **D-05:** Keep `actor_fn` as the sole actor-authority path established in Phase 49. Do not gate on Sigra-specific structs or request-private fields when the normalized Threadline surface already expresses the needed contract.
- **D-06:** The example should prove only "an authenticated actor exists," not tenancy membership, org ownership, or support-role permissions.

### Failure semantics
- **D-07:** Anonymous or otherwise unauthenticated requests should receive `401 Unauthorized`.
- **D-08:** Keep the JSON error body stable and explicit: `authentication required for incident drill-down`.
- **D-09:** Keep `400 Bad Request` for malformed `audit_transaction_id` values.
- **D-10:** Do not introduce `403` or `404` paths in the example app for this phase. Those are host-policy choices for authenticated-but-not-authorized access and would overstate the shipped security model.

### Docs and adopter framing
- **D-11:** The example README, domain reference, incident playbook, and onboarding guides should all repeat the same honesty line: authenticated baseline shipped; tenancy and richer authorization remain host-owned.
- **D-12:** Phrase the contract in normalized Threadline terms first, not adapter-internal Sigra vocabulary. The endpoint depends on an authenticated actor in `audit_context`, not on adopters copying a Sigra-specific assign check.
- **D-13:** Documentation must not imply that any authenticated actor should see all drill-down data in production. Hosts still own query scoping, membership checks, and concealment choices such as `403` versus `404`.

### Operator ergonomics / DX
- **D-14:** Preserve the existing successful response shape for authenticated callers. Incident tools should continue to rely on stable `audit_transaction_id`, ordered `changes`, and JSON-ready `change_diff`.
- **D-15:** Favor copy-pasteable clarity over framework purity. For one endpoint, an explicit controller guard is easier for adopters to inspect than an extra plug module that exists only to wrap the same `401` check.
- **D-16:** Keep the recommendation bundle cohesive with prior phases: direct host wiring, normalized request context, narrow public contracts, and no hidden policy magic.

### Planning preference
- **D-17:** For low- and medium-impact discuss decisions, prefer research-first cohesive recommendations and escalate interactively only for materially higher-impact choices such as semver, security-model expansion, breaking public API, or scope cuts.

### the agent's Discretion
- Exact helper naming and placement for the authenticated-actor check, provided the contract remains endpoint-local and normalized around `audit_context.actor_ref`.
- Exact prose wording across docs, provided all surfaces preserve the same shipped-baseline versus host-owned-boundary story.
- Exact test naming and organization, provided both authenticated success and anonymous rejection remain locked.

</decisions>

<specifics>
## Specific Ideas

- Preferred mental model: Threadline ships a safe baseline for authenticated incident drill-down, then gets out of the way so the host can layer real authorization and tenancy.
- Phoenix ecosystem guidance would normally favor a route/pipeline plug for auth, but this phase should not add a new seam just to satisfy framework aesthetics for a single endpoint.
- Good wording for downstream docs: "The reference app requires an authenticated actor before it serves incident drill-down. Production hosts still own tenancy scoping and any richer authorization policy."
- If a host wants authenticated denials to become `403` or hidden `404`, that belongs in host policy code, not the library example baseline.
- Keep the support/operator path cheap to reason about: request auth at the edge, actor/correlation captured durably, stable JSON drill-down when allowed.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone context
- `.planning/ROADMAP.md` — Phase 51 goal, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` — `INCIDENT-03` and `INCIDENT-04` define the authenticated drill-down baseline and docs boundary.
- `.planning/PROJECT.md` — active milestone framing and current host-integration goals.
- `.planning/STATE.md` — current sequencing and dirty-worktree note for v1.15.

### Prior phase decisions that constrain this phase
- `.planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md` — locks `actor_fn` as the sole actor-authority path and keeps additive request metadata separate from actor identity.
- `.planning/milestones/v1.15-phases/50-direct-sigra-host-wiring/50-CONTEXT.md` — locks direct host wiring, removes the example-local delegate seam, and keeps the example app honest about host-owned boundaries.

### Code and docs already expressing the in-flight Phase 51 direction
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` — current controller-level auth gate, UUID validation, and drill-down payload.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — direct `Threadline.Plug` host wiring via Sigra callbacks.
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` — authenticated success path and anonymous `401` rejection proof.
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs` — neighboring request-path proof surface that should remain consistent with the direct host-wiring story.
- `examples/threadline_phoenix/test/support/conn_case.ex` — request-auth test helpers and example request-state setup.
- `examples/threadline_phoenix/README.md` — example-app adopter narrative.
- `guides/domain-reference.md` — incident JSON reference path and public support-query framing.
- `guides/incident-playbook.md` — operator-facing incident guidance.
- `guides/getting-started-saas.md` — adopter onboarding story that must align with the incident auth baseline.
- `guides/adoption-pilot-backlog.md` — adopter evidence framing for the example path.

### External ecosystem references that informed the recommendation
- `https://hexdocs.pm/phoenix/api_authentication.html` — Phoenix shows `401` + halt as the standard missing-auth API pattern.
- `https://hexdocs.pm/phoenix/mix_phx_gen_auth.html` — generated auth guidance, developer-responsibility framing, and explicit `require_authenticated_user` posture.
- `https://hexdocs.pm/phoenix/authn_authz.html` — authn/authz separation as first principles.
- `https://hexdocs.pm/phoenix_live_view/security-model.html` — repeated reminder that authentication and authorization are separate concerns.
- `https://hexdocs.pm/phoenix/scopes.html` — current-scope pattern for passing identity and visibility context into app code.
- `https://hexdocs.pm/sigra/multi-tenant.html` — membership/authorization versus query scoping separation in the Sigra ecosystem.
- `https://hexdocs.pm/bodyguard/readme.html` — idiomatic `403` versus `404` tradeoff for authenticated authorization failures.
- `https://django-auditlog.readthedocs.io/en/latest/usage.html` — actor capture at request edge, middleware ordering, and masking guidance.
- `https://www.rubydoc.info/gems/paper_trail/11.0.0/PaperTrail%2FRequest.controller_info` — request metadata kept separate from actor attribution in a mature audit library.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The example app already has the exact endpoint and tests Phase 51 needs to formalize; planning should tighten and align them rather than inventing a different surface.
- `Threadline.Plug` plus `Threadline.Integrations.Sigra.*` already establish a normalized request context before the controller runs, so the endpoint can key off `audit_context.actor_ref` without re-reading adapter internals.
- Existing doc-contract discipline across the repo means the final Phase 51 implementation should likely lock the incident auth wording against future drift.

### Established Patterns
- Recent phases deliberately removed unnecessary app-local seams in favor of direct, explicit host wiring.
- Threadline prefers narrow, deterministic public contracts and loud boundaries about what remains host-owned.
- The repo's planning config already biases discuss/planning toward research-first cohesive recommendations and only escalates interactively for high-impact decisions.

### Integration Points
- `AuditTransactionController` is the primary implementation point for the auth baseline and the stable drill-down payload.
- Example request tests are the main proof surface for the `401`/`200` contract.
- Example README plus incident/domain guides are the main user-facing surfaces where the host-owned tenancy/authorization boundary must stay aligned.

</code_context>

<deferred>
## Deferred Ideas

- A dedicated example auth plug or router pipeline for incident drill-down if a future phase adds multiple protected incident endpoints.
- Example-app role matrices, org-membership authorization, or tenant-aware query scoping examples.
- Concealment-oriented `404` behavior or explicit `403` policy handling for authenticated callers.
- Any library-owned authorization abstraction that would imply Threadline ships production policy rather than an example baseline.

</deferred>

---

*Phase: 51-authenticated-incident-drill-down*
*Context gathered: 2026-05-05*
