# Phase 139: orientation-hub-home-nav - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning
**Mode:** auto-selected defaults from locked IA and prior phase context

<domain>
## Phase Boundary

Polish the existing Home start page (`StartLive`) and shared operator-surface header/nav (`SurfaceHeader`) so they reflect the locked persona/JTBD IA. The phase owns Home/nav orientation, active states, grouping, mobile navigation reachability, and the Home start-page affordances that orient each persona to an obvious next action.

This is a UI polish/orientation phase only. It must not ship Phase 140 earned flows: no record-first lookup implementation, no correlation-id paste/deep-link flow, no closed export loop, no first-class row-history route, no backend query/schema/route expansion, no Tailwind/shadcn/icon dependency, and no demo-app redesign.
</domain>

<auto_decisions>
## Auto-Selected Discussion Decisions

`--auto` selected the recommended defaults from `.planning/milestones/v1.31-PERSONAS-IA.md` and the Phase 139 roadmap scope:

- **D-01:** Keep the `Find / Verify / Prove` IA as the navigation backbone. The grouping maps to P1/P2 investigation, P4 trust/health, and P3 proof/handoff. Do not rename the nav grouping wholesale.
- **D-02:** Keep `Verify` in the nav for consistency. A Home card may use `Trust` language if planning finds it improves first-scan comprehension, but nav labels should stay stable unless a test-backed reason emerges.
- **D-03:** Add a subtle Prove-cluster separation before `Exports`, so Exports reads as the handoff/deliverable destination rather than a sibling proof control. This is EF5/F-105/F-304 scope and belongs in Phase 139.
- **D-04:** Preserve the brand link to Home, skip link, scope chip, coverage badge, feature-flag-aware destinations, and existing auth/coverage/on-mount contracts.
- **D-05:** Mobile nav must preserve every available destination at 375px. It may use an overflow/hamburger/disclosure or a deliberately scrollable grouped nav, but it must not silently drop Retention, Exports, labels, scope, or health affordances.
- **D-06:** Home remains a GDS-style orientation hub, not a dashboard. Keep the headline orientation, quiet health row, job-framed cards, and saved-view resume area; make each persona's next action obvious without turning Home into a new workflow screen.
- **D-07:** Home may show a non-functional orientation/prompt for the Phase 140 record-first path only if it is clearly framed as navigation guidance or future-owned disabled copy. Prefer planning Phase 139 around existing destinations and copy; implement actual record lookup in Phase 140.
- **D-08:** The Home health row stays quiet when healthy and scan-friendly for P4. P1/P2/P3 should be able to ignore it; P4 should be able to use it as the health-sweep on-ramp.
- **D-09:** Saved views are part of Home orientation. Phase 135 seeded them for F-204; Phase 139 should render them as a real "Pick up where you left off" affordance when present and preserve honest empty copy when absent.
- **D-10:** Keep all CSS in `Threadline.OperatorSurface.Style` using scoped `.threadline-ui` / `.tl-*` primitives and existing dark-first tokens. Add narrow nav/Home primitives only when existing classes cannot express the IA contract.
</auto_decisions>

<audit_findings>
## Phase 139 Findings To Close

From `.planning/milestones/v1.31-UI-AUDIT.md`, Phase 139 owns:

- **F-204(render):** Home saved views/resume row should render now that Phase 135 seeded saved views.
- **F-301:** Home/nav IA needs to reflect the locked persona/JTBD model.
- **F-302:** Nav active states and grouping must be consistent across screens.
- **F-303:** Mobile nav must preserve all destinations and grouping at 375px.
- **F-304:** Prove grouping should distinguish Exports as the handoff/deliverable destination.

Related but explicitly later:

- **F-1001, F-1002, F-1003, F-1004** are Phase 140 flow work. Phase 139 may orient toward them but must not implement them.
- **F-801** broader responsive/mobile sweep is Phase 142, except the local mobile nav reachability required by Phase 139.
</audit_findings>

<persona_mapping>
## Persona/JTBD Orientation Contract

- **P1 Incident Responder:** Needs the fastest route to Timeline and existing investigation pivots. Home copy should point to "what changed" without burying Timeline.
- **P2 Support Agent:** Needs guardrails and plain-language orientation. Phase 139 should acknowledge the record-first need without implementing the Phase 140 flow.
- **P3 Compliance/Security Reviewer:** Needs Evidence, Redaction, Retention, and Exports to read as a proof/handoff sequence. Exports should visually feel like "take it with you."
- **P4 Audit Operator/SRE:** Needs Coverage/Retention/Exports/Policy health cues. The Home health row and Verify/Prove grouping should stay scan-friendly.
- **P5 Adopter Developer:** Needs diagnostic empty/microcopy and scope confirmation. Preserve scoped chip and setup-oriented empty-state tone.
</persona_mapping>

<canonical_refs>
## Canonical References

- `.planning/milestones/v1.31-PERSONAS-IA.md` — locked personas P1-P5, jobs J1-J11, earned flows EF1-EF5, and Home/nav recommendations.
- `.planning/milestones/v1.31-UI-AUDIT.md` — Phase 139 findings F-204(render), F-301, F-302, F-303, F-304.
- `.planning/phases/135-seed-enrichment-ia-lock-in/135-CONTEXT.md` and Phase 135 summaries — saved-view seed and IA lock-in context.
- `.planning/phases/136-design-system-hardening/136-CONTEXT.md` and summary — dark-only token and nav primitive constraints.
- `.planning/phases/137-prove-cluster-polish/137-CONTEXT.md` and summaries — Prove cluster ordering, proof/handoff language, and Export readiness model.
- `.planning/phases/138-find-cluster-polish/138-CONTEXT.md` and summaries — Find cluster orientation, Timeline/Transaction/Row-history/Actor polish, and mobile Find UAT.
- `lib/threadline/operator_surface/live/start_live.ex` — Home start page/orientation hub.
- `lib/threadline/operator_surface/components/surface_header.ex` — shared nav/header.
- `lib/threadline/operator_surface/style.ex` — scoped `.tl-*` CSS and responsive nav styles.
- `test/threadline/operator_surface/live/start_live_test.exs` and existing surface-header/nav tests if present — primary test surface to extend.
- `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts` and `operator-find-mobile.spec.ts` — mobile UAT patterns to reuse.
</canonical_refs>

<implementation_guidance>
## Planning Guidance

- Prefer one foundation plan for `SurfaceHeader` nav grouping, active state, and mobile reachability before Home-specific changes.
- Prefer one Home plan for persona-oriented cards, health row, saved-view resume, and copy hierarchy.
- Add a focused mobile browser spec or extend an existing operator mobile spec to assert all nav destinations remain reachable at 375px.
- Tests should assert active nav state per destination, feature-flag-aware destination visibility, Prove/Exports separation, saved-view rendering, and no horizontal overflow.
- Do not modify `Threadline.Query`, `Threadline.Export`, routes, schemas, or demo seed in this phase unless planning proves a narrow test fixture update is required.
</implementation_guidance>

<deferred>
## Deferred To Phase 140

- EF1 record-first cordoned path from Home.
- EF2 first-class row-history entry from Home/Timeline.
- EF3 closed export loop carrying active Timeline/Evidence context into Exports.
- EF4 correlation-id paste/deep-link from Home.
- Any new route, query API, backend flow, or product behavior needed to support those flows.
</deferred>

---
*Phase: 139-orientation-hub-home-nav*
*Context gathered: 2026-06-04*
