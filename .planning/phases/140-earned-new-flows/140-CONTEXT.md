# Phase 140: earned-new-flows - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning
**Mode:** auto-selected defaults from Phase 139 boundary decisions and Phase 140 roadmap

<domain>
## Phase Boundary

Build the four earned operator flows that Phase 139 deliberately deferred:

- **Record-first lookup from Home:** a support operator can look up one record's history without building Timeline filters.
- **Closed export loop:** a reviewer can carry an active filtered Timeline/Evidence context into a pre-populated export.
- **Correlation-id paste/deep-link from Home:** an incident responder can paste or deep-link a `correlation_id` from Home.
- **First-class row-history entry:** row history is reachable as its own entry point, not only through an already-open transaction.

This phase owns product behavior, route/query wiring, UI controls, validation, and tests required for those four flows. It must not broaden into Phase 141 motion work, Phase 142 responsive matrix work, or speculative new workflows beyond the named Phase 140 flows.
</domain>

<auto_decisions>
## Auto-Selected Discussion Decisions

- **D-01:** Ship only the four roadmap-listed flows. Do not add a general search builder, advanced query DSL, bulk export workflow, or new proof surfaces.
- **D-02:** Keep Home as the entry point for record-first lookup and correlation paste because Phase 139 made it the operator orientation hub. Add actual controls only where they map directly to Phase 140 flows.
- **D-03:** Keep the record-first path cordoned and plain-language. It should ask for a mapped schema/table and record id, then navigate to the existing row-history experience or a dedicated route; it should not expose raw Timeline filter construction.
- **D-04:** Treat correlation paste/deep-link as a Timeline-context shortcut. Use existing `correlation_id` filtering semantics where possible, with validation and error copy for empty/invalid input.
- **D-05:** Treat the closed export loop as context carry-forward, not a new export builder. From filtered Timeline/Evidence, carry allowed filters into the existing Exports surface and make the pre-populated context obvious.
- **D-06:** Treat first-class row-history as a discoverability route for an existing capability. Reuse existing row-history components/query constraints and preserve scope authorization.
- **D-07:** Every flow must trace to a named persona/JTBD and a decision/earned-flow record from the locked IA. If a behavior cannot be tied to that map, defer it.
- **D-08:** Preserve Phase 139 nav/Home IA, scope chip, coverage badge, feature flags, and mobile viewport fixes. Do not regress the Home/nav baseline while adding controls.
- **D-09:** Use existing `Threadline.OperatorSurface` primitives, `.tl-*` styles, `FilterParams`, `Threadline.Query`, export/auth/scoping seams, and example-app E2E patterns before adding abstractions.
- **D-10:** Keep validation tight: each flow needs focused ExUnit coverage and at least one browser UAT path when the behavior crosses Home/Timeline/Evidence/Exports.
</auto_decisions>

<audit_findings>
## Phase 140 Findings To Close

From the v1.31 audit and IA context, Phase 140 owns the earned-flow findings deferred from Phase 139:

- **F-1001 / EF1:** Record-first lookup from Home for support operators.
- **F-1002 / EF2:** First-class row-history entry rather than transaction-only discovery.
- **F-1003 / EF3:** Closed export loop from filtered investigation/proof context into Exports.
- **F-1004 / EF4:** Correlation-id paste/deep-link from Home.
- **EF5 relation:** Exports remains the handoff destination established by Phase 139; Phase 140 may wire context into it but should not redesign the Prove cluster.

Related but explicitly later:

- Phase 141 owns animation/motion rationale.
- Phase 142 owns broad responsive/mobile-first tables, filters, drawers, and breakpoint scale.
- Phase 143 owns final accessibility/consistency/screenshot-diff sweep.
</audit_findings>

<persona_mapping>
## Persona/JTBD Contract

- **P1 Incident Responder:** Needs to paste a correlation id and jump directly to the relevant event chain.
- **P2 Support Agent:** Needs a safe record-first way to answer "what happened to this customer/ticket" without understanding audit filter syntax.
- **P3 Compliance/Security Reviewer:** Needs filtered investigation/proof context to carry into an export handoff without re-entering parameters.
- **P4 Audit Operator/SRE:** Needs new flows to preserve health/scope clarity and not bypass audit coverage/scoping guardrails.
- **P5 Adopter Developer:** Needs the implementation to stay example-backed, schema-map-aware, and unsurprising for host apps.
</persona_mapping>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` — Phase 140 goal and success criteria.
- `.planning/REQUIREMENTS.md` — `POLISH-FLOWS`.
- `.planning/PROJECT.md` — v1.31 earned-flow summary.
- `.planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md` — boundary decisions deferring all four flows to Phase 140.
- `.planning/phases/139-orientation-hub-home-nav/139-VERIFICATION.md` — Home/nav baseline to preserve.
- `lib/threadline/operator_surface/live/start_live.ex` — Home entry point for record-first and correlation flows.
- `lib/threadline/operator_surface/live/timeline_live.ex` — existing Timeline filter behavior and correlation context.
- `lib/threadline/operator_surface/live/transaction_live.ex` — existing row-history route/component integration.
- `lib/threadline/operator_surface/live/export_status_live.ex` and export controller/auth code — existing export surface and authorization constraints.
- `lib/threadline/operator_surface/components/row_history_component.ex` — reusable row-history presentation.
- `lib/threadline/operator_surface/router.ex` — operator LiveView route macro.
- `lib/threadline/operator_surface/style.ex` — scoped UI primitives.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — example `:schemas` mount map and operator auth/scoping.
- `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts`, `operator-find-mobile.spec.ts`, and `operator-prove-mobile.spec.ts` — browser UAT analogs.
</canonical_refs>

<implementation_guidance>
## Planning Guidance

- Prefer separate vertical slices for independent flows, but account for shared Home controls and router/query seams before parallel execution.
- Start with research/pattern mapping around current row-history, correlation filter, export context, and schema-map APIs before designing routes.
- Tests should prove both happy paths and guardrails: feature flags, scope authorization, invalid/missing identifiers, absent schema mappings, no raw SQL/table injection, and no duplicate filter-building UX.
- Browser UAT should use the example app's seeded data and keep assertions focused on the four earned flows.
- Avoid broad CSS redesign. Add only the controls/states needed for the new flows, with token-backed `.tl-*` styles and source/style contracts where useful.
</implementation_guidance>

<deferred>
## Deferred Beyond Phase 140

- Motion and animation refinements.
- Full mobile-first table/filter/drawer redesign.
- Screenshot-diff infrastructure.
- Bulk export lifecycle redesign.
- Advanced saved search/query builder.
- Any new persona flow not named in Phase 140's roadmap goal.
</deferred>

---
*Phase: 140-earned-new-flows*
*Context gathered: 2026-06-04*
