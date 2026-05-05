# Phase 51: Authenticated Incident Drill-down - Research

**Researched:** 2026-05-05
**Domain:** Authenticated incident drill-down baseline in the Phoenix example app
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
- A dedicated example auth plug or router pipeline for incident drill-down if a future phase adds multiple protected incident endpoints.
- Example-app role matrices, org-membership authorization, or tenant-aware query scoping examples.
- Concealment-oriented `404` behavior or explicit `403` policy handling for authenticated callers.
- Any library-owned authorization abstraction that would imply Threadline ships production policy rather than an example baseline.
</user_constraints>

## Project Constraints (from CLAUDE.md)

- Keep capture, semantics, and exploration responsibilities separate; do not turn this phase into capture or retention work. [VERIFIED: CLAUDE.md]
- Use Threadline domain terms consistently: `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and correlation. [VERIFIED: CLAUDE.md]
- Prefer named verification entrypoints and existing test files over ad-hoc verification stories. [VERIFIED: CLAUDE.md]
- Treat docs and example README literals as contract surfaces that should not drift silently. [VERIFIED: CLAUDE.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INCIDENT-03 | The example incident drill-down endpoint requires an authenticated actor before returning transaction changes. | The in-flight controller and request test already implement the intended `401`/`200` split around `conn.assigns.audit_context.actor_ref`, so planning should tighten that exact runtime contract rather than inventing a router-level auth abstraction. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs] |
| INCIDENT-04 | Incident drill-down docs distinguish the shipped auth baseline from host-owned tenancy and richer authorization rules, so adopters do not mistake the example for a full security model. | The example README, domain reference, incident playbook, SaaS quickstart, and adoption backlog already carry that boundary language in the dirty worktree, so Phase 51 should align those incident-specific surfaces and avoid broad host-wiring doc scope that belongs to Phase 52. [VERIFIED: examples/threadline_phoenix/README.md] [VERIFIED: guides/domain-reference.md] [VERIFIED: guides/incident-playbook.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/adoption-pilot-backlog.md] |
</phase_requirements>

## Summary

Phase 51 is already materially present in the dirty worktree: the endpoint-local auth check, the anonymous `401` test, and the incident-facing doc wording are in place, but they still need to be treated as the formal baseline for planning and verification instead of incidental edits. [VERIFIED: git status] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs]

The smallest coherent implementation remains a two-plan phase: one runtime plan for the controller and request-path proofs, then one incident-docs plan for the shipped-auth-versus-host-policy boundary with only narrow drift guards if needed. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs] [VERIFIED: examples/threadline_phoenix/README.md] [VERIFIED: guides/domain-reference.md] [VERIFIED: guides/incident-playbook.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/adoption-pilot-backlog.md]

**Primary recommendation:** Plan 51 as `51-01` runtime auth boundary + request tests and `51-02` incident-facing docs + minimal drift guards; keep tenancy, richer authorization, reusable auth plugs, and Sigra-private predicate checks out of scope. [VERIFIED: .planning/milestones/v1.15-phases/51-authenticated-incident-drill-down/51-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix/authn_authz.html] [CITED: https://hexdocs.pm/sigra/multi-tenant.html]

## Findings

1. The real implementation point is the controller, not the router: `GET /api/audit_transactions/:id/changes` is still routed through the existing `:api` pipeline, while the authentication decision is made inside `AuditTransactionController.changes/2` by reading `conn.assigns.audit_context.actor_ref`. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex]
2. The normalized actor predicate is already available before the controller runs because `Threadline.Plug` populates `audit_context` from the direct Sigra callback pair in the router, and test requests establish the example auth state through `sigra_conn/2`. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] [VERIFIED: examples/threadline_phoenix/test/support/conn_case.ex]
3. The main request-path proof file already covers both required behaviors for INCIDENT-03: authenticated `POST` + authenticated drill-down success, and anonymous drill-down rejection with the locked JSON error body. [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs]
4. The successful drill-down response shape is already the established contract: `audit_transaction_id`, stable ordered `changes`, `audit_change_id`, and `change_diff` maps built from `Threadline.audit_changes_for_transaction/2` plus `Threadline.change_diff/2`. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs]
5. Incident-boundary wording is already distributed across five user-facing surfaces, which justifies one docs-focused plan rather than sprinkling doc edits into the runtime plan. [VERIFIED: examples/threadline_phoenix/README.md] [VERIFIED: guides/domain-reference.md] [VERIFIED: guides/incident-playbook.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/adoption-pilot-backlog.md]
6. Current contract tests only partially cover the new incident-auth wording: the playbook test checks structure and API names, the quickstart test checks host-wiring language, and the example README test currently locks only the direct Sigra callback pair. That means broad doc-contract alignment still belongs mostly to Phase 52, with only narrow incident wording assertions justified here if a planner wants an immediate drift guard. [VERIFIED: test/threadline/incident_playbook_doc_contract_test.exs] [VERIFIED: test/threadline/getting_started_saas_doc_contract_test.exs] [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]
7. The repo state is intentionally dirty and already includes Phase 51-adjacent edits, so planners should treat these files as in-flight baseline evidence instead of assuming the work starts from the pre-auth endpoint. [VERIFIED: git status] [VERIFIED: .planning/STATE.md]
8. The external framework guidance matches the locked phase posture: Phoenix documents authentication and authorization as separate concerns, and Sigra documents membership/role checks separately from org-scoped data isolation. That supports keeping Phase 51 at `401` authenticated-baseline scope and leaving `403`/tenancy decisions host-owned. [CITED: https://hexdocs.pm/phoenix/authn_authz.html] [CITED: https://hexdocs.pm/sigra/multi-tenant.html] [CITED: https://hexdocs.pm/sigra/api-authentication.html]

## Real Implementation Clusters

### Cluster A: Runtime auth boundary and payload contract

- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` owns the actual `401` gate, UUID validation, and unchanged response body for authenticated callers. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex]
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` is adjacent context only; it provides normalized `audit_context` but should not gain a new Phase 51-specific auth pipeline unless scope expands later. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] [CITED: https://hexdocs.pm/phoenix/authn_authz.html]
- `examples/threadline_phoenix/test/support/conn_case.ex` is the test helper seam for authenticated request setup through `sigra_conn/2`. [VERIFIED: examples/threadline_phoenix/test/support/conn_case.ex]
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` is the golden-path proof file for INCIDENT-03. [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs]

### Cluster B: Neighboring request-path non-regression surface

- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs` and `posts_correlation_path_test.exs` prove the surrounding request wiring and should stay green because Phase 51 depends on the same `audit_context` population path. [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs] [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs]
- `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` and `post_controller.ex` are upstream producers of the `audit_transaction_id` returned by `POST /api/posts`, so they are verification neighbors rather than primary Phase 51 implementation targets. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix/blog.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_controller.ex]

### Cluster C: Incident-facing docs boundary

- `examples/threadline_phoenix/README.md`, `guides/domain-reference.md`, `guides/incident-playbook.md`, `guides/getting-started-saas.md`, and `guides/adoption-pilot-backlog.md` already carry the “authenticated baseline shipped; tenancy and richer authorization remain host-owned” story and should move together. [VERIFIED: examples/threadline_phoenix/README.md] [VERIFIED: guides/domain-reference.md] [VERIFIED: guides/incident-playbook.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/adoption-pilot-backlog.md]

### Cluster D: Narrow drift guards only if needed

- `test/threadline/incident_playbook_doc_contract_test.exs`, `test/threadline/getting_started_saas_doc_contract_test.exs`, and `test/threadline/example_phoenix_readme_contract_test.exs` are the nearest contract-test anchors, but most broad docs-alignment work is still reserved for Phase 52 (`ADOPT-03`). [VERIFIED: test/threadline/incident_playbook_doc_contract_test.exs] [VERIFIED: test/threadline/getting_started_saas_doc_contract_test.exs] [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs] [VERIFIED: .planning/ROADMAP.md]

## Recommended Plan Decomposition

### Plan 51-01: Lock the authenticated drill-down runtime contract

**File cluster**
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex`
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs`
- `examples/threadline_phoenix/test/support/conn_case.ex`
- Verification neighbors: `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs`, `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs` [VERIFIED: repo grep]

**Why this is one plan**
- These files own the authenticated-vs-anonymous behavior, the locked `401` body, and the endpoint’s unchanged success payload. They form one runtime contract and should be planned together. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs]

**Required assertions**
- Authenticated request succeeds with the existing JSON shape. [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs]
- Anonymous request returns `401` with `authentication required for incident drill-down`. [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs]
- Malformed UUID still returns `400`, not `401`-specific parsing noise or a new status family. [VERIFIED: .planning/milestones/v1.15-phases/51-authenticated-incident-drill-down/51-CONTEXT.md]

**Verification**
- `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_incident_json_path_test.exs` [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs]
- `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_audit_path_test.exs test/threadline_phoenix_web/posts_correlation_path_test.exs` [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs] [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs]

### Plan 51-02: Align incident-facing docs on the shipped auth baseline

**File cluster**
- `examples/threadline_phoenix/README.md`
- `guides/domain-reference.md`
- `guides/incident-playbook.md`
- `guides/getting-started-saas.md`
- `guides/adoption-pilot-backlog.md`
- Optional narrow guards only if needed: `test/threadline/incident_playbook_doc_contract_test.exs`, `test/threadline/getting_started_saas_doc_contract_test.exs`, `test/threadline/example_phoenix_readme_contract_test.exs` [VERIFIED: repo grep]

**Why this is one plan**
- INCIDENT-04 is not generic docs cleanup; it is one boundary statement repeated across the incident/adoption narrative. These surfaces should be aligned together so adopters do not get conflicting security claims. [VERIFIED: examples/threadline_phoenix/README.md] [VERIFIED: guides/domain-reference.md] [VERIFIED: guides/incident-playbook.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/adoption-pilot-backlog.md]

**Planner note**
- Keep this plan narrowly incident-scoped. Do not absorb the broader host-wiring/doc-contract alignment reserved for Phase 52 unless a missing guard would leave Phase 51’s new promise completely untested. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: test/threadline/incident_playbook_doc_contract_test.exs] [VERIFIED: test/threadline/getting_started_saas_doc_contract_test.exs] [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]

**Verification**
- `mix test test/threadline/incident_playbook_doc_contract_test.exs` if playbook wording or API examples change. [VERIFIED: test/threadline/incident_playbook_doc_contract_test.exs]
- `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs` only if Phase 51 explicitly modifies those literals. [VERIFIED: test/threadline/getting_started_saas_doc_contract_test.exs] [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]

## Scope Guards

- Keep tenancy, membership checks, org scoping, and richer authorization host-owned; Phase 51 stops at “authenticated actor exists.” [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.15-phases/51-authenticated-incident-drill-down/51-CONTEXT.md] [CITED: https://hexdocs.pm/sigra/multi-tenant.html]
- Do not add a reusable example auth plug or router pipeline for one endpoint. The controller-local guard is the locked recommendation until there is more than one protected incident surface. [VERIFIED: .planning/milestones/v1.15-phases/51-authenticated-incident-drill-down/51-CONTEXT.md]
- Do not gate on `conn.private[:sigra_session]`, `:current_scope`, or any Sigra-specific struct shape when `audit_context.actor_ref` already expresses the normalized requirement. [VERIFIED: .planning/milestones/v1.15-phases/51-authenticated-incident-drill-down/51-CONTEXT.md] [VERIFIED: examples/threadline_phoenix/test/support/conn_case.ex]
- Do not introduce `403` or concealment-oriented `404` responses in this phase. Sigra’s API-auth docs use `401` for missing/invalid auth and `403` for scope denial, which reinforces that those are separate policy layers. [VERIFIED: .planning/milestones/v1.15-phases/51-authenticated-incident-drill-down/51-CONTEXT.md] [CITED: https://hexdocs.pm/sigra/api-authentication.html]
- Do not broaden Phase 51 into full docs alignment for direct host wiring; that is already the purpose of Phase 52 (`ADOPT-03`). [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]

## Risks and Mitigations

| Risk | Why it matters | Mitigation |
|------|----------------|------------|
| Planning against a clean baseline instead of the dirty in-flight tree | The planner could re-open decisions that are already embodied in local controller, test, and docs edits. [VERIFIED: git status] | Treat the current Phase 51-adjacent edits as baseline evidence and plan convergence/verification, not greenfield implementation. [VERIFIED: git status] |
| Using Sigra-private auth checks instead of normalized `audit_context.actor_ref` | That would contradict Phase 49/50’s normalized host-wiring story and make the example less portable. [VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md] [VERIFIED: .planning/milestones/v1.15-phases/50-direct-sigra-host-wiring/50-CONTEXT.md] | Keep the predicate on `conn.assigns.audit_context.actor_ref` only. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] |
| Over-abstracting into a plug or pipeline because Phoenix often teaches auth that way | For one endpoint, that adds a seam Phase 51 explicitly does not want. Phoenix’s auth docs describe authn/authz concepts, but they do not require a reusable plug for every single protected handler. [VERIFIED: .planning/milestones/v1.15-phases/51-authenticated-incident-drill-down/51-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix/authn_authz.html] | Keep the guard local until multiple protected incident endpoints exist. [VERIFIED: .planning/milestones/v1.15-phases/51-authenticated-incident-drill-down/51-CONTEXT.md] |
| Letting docs imply authenticated access is production-ready authorization | That would blur Phase 51’s host-owned boundary and conflict with Sigra’s separation of authorization from data isolation. [VERIFIED: guides/domain-reference.md] [VERIFIED: guides/incident-playbook.md] [CITED: https://hexdocs.pm/sigra/multi-tenant.html] | Repeat the same honesty line across all incident-facing docs: auth baseline shipped; tenancy and richer authorization remain host-owned. [VERIFIED: examples/threadline_phoenix/README.md] [VERIFIED: guides/domain-reference.md] [VERIFIED: guides/incident-playbook.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/adoption-pilot-backlog.md] |
| Pulling broad contract-test work into Phase 51 | That would blur the boundary with Phase 52 and inflate plan count. [VERIFIED: .planning/ROADMAP.md] | Add only narrow incident-specific guards if the planner judges them necessary; otherwise leave broad docs-alignment assertions for Phase 52. [VERIFIED: test/threadline/incident_playbook_doc_contract_test.exs] [VERIFIED: test/threadline/getting_started_saas_doc_contract_test.exs] [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs] |

## Planner Guidance

- Use two plans unless the planner discovers a genuinely separate drift-test cluster that cannot stay attached to the docs work. The current repo evidence does not justify a third plan. [VERIFIED: repo grep]
- Make `AuditTransactionController` the primary code owner for Phase 51. The router is supporting context, not the center of change. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]
- Keep the auth predicate normalized and host-agnostic: check for `audit_context.actor_ref`, not Sigra internals. [VERIFIED: .planning/milestones/v1.15-phases/51-authenticated-incident-drill-down/51-CONTEXT.md]
- Preserve the existing JSON success shape for authenticated callers and lock the anonymous rejection body exactly. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex] [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs]
- Treat `posts_incident_json_path_test.exs` as the golden Phase 51 proof and `posts_audit_path_test.exs` plus `posts_correlation_path_test.exs` as non-regression coverage for the same request-context pipeline. [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs] [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs] [VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs]
- Keep docs work incident-specific. If a planner wants new contract assertions, prefer extending existing nearby tests rather than creating a new Phase 51-only doc-contract suite. [VERIFIED: test/threadline/incident_playbook_doc_contract_test.exs] [VERIFIED: test/threadline/getting_started_saas_doc_contract_test.exs] [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]

## Sources

### Primary
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` — runtime auth gate and response contract. [VERIFIED: file read]
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` — authenticated success and anonymous rejection proof. [VERIFIED: file read]
- `examples/threadline_phoenix/test/support/conn_case.ex` — request-auth helper setup. [VERIFIED: file read]
- `examples/threadline_phoenix/README.md`, `guides/domain-reference.md`, `guides/incident-playbook.md`, `guides/getting-started-saas.md`, `guides/adoption-pilot-backlog.md` — incident/adopter boundary wording. [VERIFIED: file read]
- `.planning/milestones/v1.15-phases/51-authenticated-incident-drill-down/51-CONTEXT.md` — locked decisions and scope. [VERIFIED: file read]
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `CLAUDE.md`, `git status --short` — phase ownership, requirements, project constraints, dirty-worktree status. [VERIFIED: file read] [VERIFIED: git status]

### External
- Phoenix Introduction to Auth — `https://hexdocs.pm/phoenix/authn_authz.html` — authn/authz separation. [CITED: https://hexdocs.pm/phoenix/authn_authz.html]
- Sigra Multi-Tenant Apps — `https://hexdocs.pm/sigra/multi-tenant.html` — membership/authorization separated from query scoping and tenancy isolation. [CITED: https://hexdocs.pm/sigra/multi-tenant.html]
- Sigra API Authentication — `https://hexdocs.pm/sigra/api-authentication.html` — `401` for missing/invalid auth and `403` for scope denial. [CITED: https://hexdocs.pm/sigra/api-authentication.html]

## RESEARCH COMPLETE
