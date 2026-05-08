# Phase 71: Mount Recipes & Access Tiers - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship canonical, host-owned recipes for mounting Threadline's operator surface in two secure access tiers: `admin` and `support-read-only`. The phase should show where router pipeline checks, LiveView mount checks, export-route checks, and scoped investigation visibility fit together, while preserving Threadline's auth-agnostic posture and explicit capture-only fallback story. This phase does not invent a Threadline-owned role model, a page-level permission DSL, a second support-specific route tree, or new feature work solely to manufacture UI/CLI symmetry.

</domain>

<decisions>
## Implementation Decisions

### Access-Tier Model

- **D-123: Ship one canonical mount topology and two host-owned recipes, not two products.** Threadline should document one `/audit` mount story that can be adapted for `admin` and `support-read-only`, rather than separate route trees, separate products, or separate top-level doc narratives.
- **D-124: `admin` means the full mounted surface behind the host's authenticated browser/admin boundary plus host `authorize_fn`.** This is the strongest and least surprising recipe for the primary operator audience.
- **D-125: `support-read-only` should reuse the same mounted surface, not a narrower default route tree.** The distinction is narrower effective visibility and stricter data-egress posture, not a second UI shape maintained by Threadline.
- **D-126: `support-read-only` access should flow through host-owned scope, not Threadline-owned roles.** The canonical support recipe should return `{:ok, scope}` from `authorize_fn`, with an explicit example like `%{access: :support_read_only, organization_id: org_id}`. Threadline carries that scope; the host owns what it means.
- **D-127: Exports are the primary read-only footgun and should be stricter than page access in the support recipe.** The canonical `support-read-only` recipe should disable exports by default with `exports: false`. If a host deliberately wants support exports, that is an explicit opt-in and should use `export_authorize_fn`.
- **D-128: Do not teach separate support route trees as the default recipe.** Support-only route subsets, page removal, or alternate mount paths are custom/unclaimed host integrations unless later phases explicitly standardize them.

### Mount / Auth Shape

- **D-129: The canonical docs should recommend `pipe_through [:browser, :admin_auth]` plus `authorize_fn`; not either/or as equal first-class patterns.** Phoenix router auth and Threadline surface auth are complementary layers and should be documented that way.
- **D-130: Publish one shared assigns-shaped `authorize_fn` as the default teaching shape.** The canonical host callback should accept `%{assigns: assigns}` so it works for both LiveView sockets and the export fallback mirror without separate default examples.
- **D-131: Keep `export_authorize_fn` as an advanced override, not the baseline recipe.** It exists for HTTP-specific needs like stricter download policy, signed-request checks, or explicit support-export opt-in, but most adopters should start with one shared callback.
- **D-132: Keep `{:ok, scope}` explicitly opaque and host-owned.** Threadline should not define a role vocabulary, permission enum, or tenancy DSL around it. It is only the scope carrier.
- **D-133: Docs must state that HTTP exports have their own Plug auth boundary because `live_session` / `on_mount` does not cover controller routes.** This is an intentional transport split, not an incidental implementation detail.
- **D-134: Export denials remain HTTP-native (`403` + halt), not LiveView-style redirects.** This preserves least surprise for download endpoints and matches the current `ExportAuthPlug` contract.
- **D-135: The current split example-app `my_authorize_fn/1` pattern should not be the canonical recipe.** It invites silent drift between `%Plug.Conn{}` and `%Phoenix.LiveView.Socket{}` paths and is weaker DX than a shared assigns-shaped callback.

### Scoped Visibility Promise

- **D-136: Keep the support-visibility promise narrow and honest.** Phase 71 should promise that `support-read-only` can carry host-owned scope into investigation flows; it should not promise automatic narrowing everywhere unless the specific screen/query path is explicitly implemented and tested for that scope.
- **D-137: The strongest default is “same surface, narrower effective visibility,” not “hide a few pages.”** This best matches the current architecture, lessons from Oban Web / Ash / Datadog / GitHub-style operator surfaces, and the milestone's host-owns-auth boundary.
- **D-138: Reopen the design only if the phase intends to standardize page-level blocking for support users.** Blocking access to specific pages like `/audit/coverage` or `/audit/policy/redaction` would require a new route-shaping or route-aware authorization contract and is outside the default recipe.

### Fallback Parity Story

- **D-139: Promise parity for core operator questions, not exact UI-to-CLI feature parity.** The phase should keep the mounted surface as the canonical operator story while respecting capture-only adopters through explicit fallback equivalents.
- **D-140: Every canonical mounted workflow should name its best fallback transport inline.** This should happen where the workflow is introduced, not only in a separate appendix or sidebar.
- **D-141: Use dedicated Mix tasks inline only where Threadline already ships them.**
  - incident drill-down -> `mix threadline.incident`
  - current-view export -> `mix threadline.export`
  - coverage -> `mix threadline.health.coverage`
  - policy drift -> `mix threadline.policy.show`
- **D-142: Where no dedicated task exists, document the canonical API equivalent inline instead of implying a missing task should exist.**
  - timeline browse/filter -> `Threadline.timeline/2`, `Threadline.timeline_page/2`
  - actor window -> `Threadline.actor_history/2` plus transaction drill-down helpers
  - row history / as-of -> `Threadline.history/3`, `Threadline.as_of/4`
- **D-143: Add one compact parity table to the operator-surface docs or the new mount/runbook doc.** It should map mounted workflow -> operator question -> fallback path -> guarantee level, while keeping the main narrative surface-first.
- **D-144: Do not create new Phase 71 tasks or features solely to make the fallback story look more symmetrical.** Shared vocabulary and explicit mapping are the goal; fake “full parity” claims are not.

### Documentation Posture

- **D-145: Preserve the surface-first canonical narrative from Phases 68 and 70.** Capture-only stays a respected subordinate path, not a co-equal top-level onboarding or operator track.
- **D-146: Keep one obvious doc path.** Phase 71 should favor one primary mount/runbook story that shows the admin recipe first, then the support-read-only variation, then the fallback equivalents.
- **D-147: Bias toward least surprise and strongest defaults.** For this phase, downstream agents should treat the cohesive researched recommendations below as locked unless they uncover a true high-impact conflict in `security_model`, `semver`, `breaking_public_api`, or `scope_cut`.

### the agent's Discretion

- Exact doc layout across `guides/operator-surface.md`, `guides/getting-started-saas.md`, `guides/integration-contracts.md`, or a new Phase 71 mount/runbook guide, as long as there is one clear canonical source and cross-links stay coherent.
- Exact names used for the two recipes (`admin` / `support-read-only` vs slightly different phrasing), as long as the semantics above remain unchanged.
- Exact shape of the compact parity table, as long as it clearly maps mounted workflow, fallback transport, and guarantee level.
- Exact host example names and snippet wording, as long as the shared assigns-shaped `authorize_fn` pattern and support `exports: false` default remain explicit.

</decisions>

<specifics>
## Specific Ideas

- The strongest canonical Phoenix recipe is:
  - `scope "/audit"` behind `pipe_through [:browser, :admin_auth]`
  - `threadline_operator_surface "/"` with `repo`, `actor_fn`, and one shared `authorize_fn`
  - `admin` leaves exports enabled
  - `support-read-only` uses the same mount shape but sets `exports: false`
- The strongest default host authorization example is:
  - `:ok` for full admins
  - `{:ok, %{access: :support_read_only, organization_id: org_id}}` for support
  - `false` or equivalent deny for everyone else
- The docs should explicitly warn that a callback pattern-matching on `%Phoenix.LiveView.Socket{}` only is the wrong default because export fallback uses a synthetic `%{assigns: conn.assigns}` mirror.
- The strongest parity wording is:
  - “Mounted recipes are canonical.”
  - “Capture-only adopters are first-class for the core operator questions Threadline already supports.”
  - “Parity means answering the same question, not reproducing every screen as a task.”
- The local GSD project config already reflects the user's standing workflow preference:
  - research first
  - discuss all gray areas by default
  - synthesize one cohesive recommendation set
  - interrupt only on truly high-impact categories
  No further config change is required for this phase.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone contract
- `.planning/ROADMAP.md` §"Phase 71: Mount Recipes & Access Tiers" — goal, requirements, success criteria, and sequencing rationale.
- `.planning/REQUIREMENTS.md` lines for `INTEG-03` and `ADOPT-08` — the requirement contract this phase must satisfy.
- `.planning/PROJECT.md` §"Current Milestone: v1.19 — Integration Breadth" — milestone intent, optional-deps posture, and host-owns-auth boundary.
- `.planning/STATE.md` current-focus and session-continuity entries for Phase 71 — current sequencing and explicit next-step framing.

### Prior locked context
- `.planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md` — canonical surface-first story and “one obvious path” rule.
- `.planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md` — locked support-lane, auth-boundary, and proof-bar policy.
- `.planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md` — current Sigra/Phoenix reference-path posture and fallback-parity framing.

### Current surface, auth, and example seams
- `guides/operator-surface.md` — current mount/auth/screens guide and existing parity mentions.
- `guides/getting-started-saas.md` — canonical surface-first walkthrough that already reaches `/audit`.
- `guides/integration-contracts.md` — canonical `authorize_fn` / `export_authorize_fn` and mount-boundary contract.
- `guides/upgrade-path.md` — support-lane and optional-dependency posture.
- `guides/integrations/sigra.md` — current reference-path auth boundary wording.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — current example mount and auth shape.
- `lib/threadline/operator_surface/router.ex` — secure-by-default mount contract and `exports:` option.
- `lib/threadline/operator_surface/auth.ex` — LiveView-side authorization contract and `{:ok, scope}` behavior.
- `lib/threadline/operator_surface/export_auth_plug.ex` — export-side authorization contract and fallback mirror semantics.

### Fallback-parity surfaces
- `lib/mix/tasks/threadline.incident.ex` — exact transaction drill-down Mix-task parity.
- `lib/mix/tasks/threadline.export.ex` — current-view export fallback surface.
- `lib/mix/tasks/threadline.health.coverage.ex` — coverage viewer fallback surface.
- `lib/mix/tasks/threadline.policy.show.ex` — policy-drift fallback surface.
- `guides/incident-playbook.md` — API / SQL incident-response recipes for deeper fallback flows.
- `README.md` and `examples/threadline_phoenix/README.md` — user-facing discovery and example-proof wording that may need alignment.

### Existing public-contract tests
- `test/threadline/operator_surface_doc_contract_test.exs` — operator-surface guide and README contract.
- `test/threadline/integration_contracts_doc_contract_test.exs` — integration-contract wording anchors.
- `test/threadline/getting_started_saas_doc_contract_test.exs` — mounted surface-first walkthrough contract.
- `test/threadline/example_phoenix_readme_contract_test.exs` — example README proof path contract.
- `test/threadline/operator_surface/auth_test.exs` — LiveView auth behavior contract.
- `test/threadline/operator_surface/export_auth_plug_test.exs` — export auth parity and fallback behavior contract.

### External ecosystem references
- Phoenix LiveView security model — mount-time auth guidance and transport-boundary discipline: https://hexdocs.pm/phoenix_live_view/security-model.html
- Phoenix LiveDashboard router docs — idiomatic mount + extra auth hook posture: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html
- Oban Web access control / router docs — host-owned access resolver and read-only lessons: https://hexdocs.pm/oban_web/limiting_access.html and https://hexdocs.pm/oban_web/Oban.Web.Router.html
- Ash actors and policies — host/domain-scoped reads without library-owned auth vocabulary: https://hexdocs.pm/ash/actors-and-authorization.html and https://hexdocs.pm/ash/policies.html
- Hangfire dashboard auth / read-only mode — host middleware plus explicit read-only transport posture: https://docs.hangfire.io/en/latest/configuration/using-dashboard.html
- Sidekiq monitoring — host-mounted operator surface behind app auth constraints: https://github.com/sidekiq/sidekiq/wiki/Monitoring

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `threadline_operator_surface/2` already has the right compile-time secure-mount contract and `exports:` option for the support recipe.
- `Threadline.OperatorSurface.Auth` already carries `{:ok, scope}` into `:threadline_scope`, which is the correct seam for host-owned support narrowing.
- `Threadline.OperatorSurface.ExportAuthPlug` already models the transport split cleanly and preserves a shared-callback fallback through `%{assigns: conn.assigns}`.
- Threadline already ships strong fallback surfaces for incident drill-down, export, coverage, and policy drift, so Phase 71 can emphasize parity without creating new features.

### Established Patterns
- Threadline prefers one canonical doc path with subordinate branches rather than dual-track equal narratives.
- The project already treats auth, roles, and tenancy as host-owned and refuses to invent a Threadline-owned auth model.
- Public prose is increasingly locked by doc-contract tests; Phase 71 should follow that same posture for mount recipes and parity wording.
- The support matrix and example-path docs already favor narrow, evidence-backed promises over broad compatibility or policy claims.

### Integration Points
- Refresh the example router snippet and surrounding docs so the canonical recipe uses a shared assigns-shaped `authorize_fn`.
- Add an explicit `support-read-only` recipe that reuses the same mount but demonstrates `exports: false` and scoped `{:ok, scope}`.
- Add the compact parity table plus inline “capture-only equivalent” callouts in the relevant operator-surface / runbook docs.
- Extend doc-contract coverage to lock the new recipe wording, support export-default posture, and parity mapping literals.
- Keep scope promises narrow unless planner/executor explicitly adds tested scope application to the relevant screens and queries.

</code_context>

<deferred>
## Deferred Ideas

- Separate support route trees or support-only page subsets — custom host integrations unless a future phase explicitly standardizes them.
- A Threadline-owned role or permission vocabulary — out of scope for v1.19 and contrary to the host-owns-auth boundary.
- Page-level or route-aware authorization DSL inside Threadline — only revisit if a future phase explicitly scopes that work.
- New Mix tasks or new UI features created solely to claim tighter parity.
- Stronger promises that every screen/query path automatically enforces support scope — defer unless the implementation and tests land in this phase.

</deferred>

---

*Phase: 71-mount-recipes-and-access-tiers*
*Context gathered: 2026-05-08*
