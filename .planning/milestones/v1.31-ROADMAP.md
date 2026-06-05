# Roadmap: v1.31 — Operator Surface: Insane Polish

**Status:** complete
**Opened:** 2026-06-03
**Goal:** A systematic second pass over the entire `/audit` operator surface (the adopter-mounted admin UI, not the demo app) — bring every screen to one consistent, brand-aligned, mobile-first baseline on a hardened BEM + `--tl-*` token design system, align IA to real personas/JTBD with a few earned new flows, add restrained purposeful micro-animation, and enrich seed data so every screen demonstrates itself — captured durably and screenshot-/decision-recorded so a context clear loses nothing.

## Non-goals

- CSS-architecture switch (Tailwind / CSS-in-JS / build step) — BEM `.tl-*` + `--tl-*` tokens in `lib/threadline/operator_surface/style.ex` is settled; double down, don't churn
- Light mode / theme toggle — dark-first brand is locked ("night infrastructure with luminous signal lines")
- Demo-app redesign (new tables/routes/business logic) — seed *enrichment* only; the demo exists to exercise the surface
- New backend features / new queries / new screens — polish the 10 existing LiveViews; no product-surface expansion
- Speculative UX flows — every new flow must trace to a persona JTBD + a decision record
- v1.28 External Pilot work — still signal-gated; this milestone is independent

## Phases

| Phase | Name | Requirement | Status |
|-------|------|-------------|--------|
| 134 | Baseline Audit & Screenshot Inventory | Complete | 2026-06-03 |
| 135 | 4/4 | Complete    | 2026-06-04 |
| 136 | 1/1 | Complete    | 2026-06-04 |
| 137 | 4/4 | Complete    | 2026-06-04 |
| 138 | 4/4 | Complete    | 2026-06-04 |
| 139 | 3/3 | Complete    | 2026-06-04 |
| 140 | 5/5 | Complete    | 2026-06-04 |
| 141 | 3/3 | Complete    | 2026-06-04 |
| 142 | 3/3 | Complete    | 2026-06-04 |
| 143 | 4/4 | Complete    | 2026-06-04 |
| 144 | 4/4 | Complete    | 2026-06-04 |

**Ordering rationale:** measure → enrich → systematize → apply (least-iterated first) → hub → flows → motion → responsive → sweep. Foundations (audit, seed, design-system) precede per-screen work so screens aren't redone when tokens change.

## Phase Details

### Phase 134: Baseline Audit & Screenshot Inventory

**Goal**: Produce an objective current-state snapshot — a screenshot set (every screen × every meaningful state, 375 + 1280, N/A cells marked with reason) plus `v1.31-UI-AUDIT.md` (state matrix + touchpoint inventory + ranked findings, each with ID / severity / proposed resolution / owning phase). This is the reference artifact every later phase cites.
**Depends on**: Nothing (first phase of milestone)
**Requirements**: POLISH-AUDIT
**Success Criteria** (what must be TRUE):

  1. An operator can open a screenshot set covering every `/audit` screen at both 375 and 1280, with every meaningful state (empty / sparse / dense / error / scoped) present or explicitly marked N/A with a reason.
  2. `v1.31-UI-AUDIT.md` exists and contains a state matrix (screen × state) and a touchpoint inventory of the existing surface.
  3. Every consistency finding in the audit doc carries a stable ID, a severity, a proposed resolution, and an owning phase (134–143).
  4. A reader can trace any later phase's per-screen work back to a specific audit finding ID.

**Plans**: TBD

### Phase 135: Seed Enrichment & IA Lock-In

**Goal**: Enrich the demo seed so every screen demonstrates itself (empty / long-list / status-variety / edge cases all reachable), update DEMO-MANIFEST.md as SSOT, and lock the persona/JTBD IA decisions into the audit doc. Seed only — no schema, route, or business-logic changes.
**Depends on**: Phase 134
**Requirements**: POLISH-SEED
**Success Criteria** (what must be TRUE):

  1. After `mix demo.reset && mix demo.seed`, every operator-surface screen can be driven to empty, long/paginated, status-variety, and permission/edge-case states without code changes.
  2. DEMO-MANIFEST.md is updated and matches the enriched seed as the single source of truth for what the seed demonstrates.
  3. No demo-app schema, route, or business-logic changes were introduced (seed-only diff).
  4. The locked persona/JTBD IA decisions are recorded in the audit doc and referenced by later phases.

**Plans**: 4 plans

- [x] 135-01-PLAN.md — Generalize Support actor helpers (D-07) + fix D-05 persona/setup actor attribution + named actor literals
- [x] 135-02-PLAN.md — Lock PERSONAS-IA.md (status header, EF1–EF5, J1–J11) + UI-AUDIT pointer + IA doc-contract test
- [x] 135-03-PLAN.md — In-window variety pack (5/4/2 op + multi-kind actors, reply-edit [REDACTED] diff, D-13) + filler DELETE branch + SavedView seed
- [x] 135-04-PLAN.md — DEMO-MANIFEST.md per-state recipe table + named actor literals + recipe doc-contract test

### Phase 136: Design-System Hardening

**Goal**: Dedupe and formalize the token scales (spacing, control-size, radius, shadow, typography, canonical status-color map, z-index, motion — including the currently-missing control-size scale and a canonical status-color map); document the `.tl-*` class catalog in `v1.31-DESIGN-SYSTEM.md` (each canonical / deprecated / consolidated with usage rules + antipatterns); unify shared primitives (badge, button, panel, empty-state, table, toast, drawer, copy-affordance). Freeze the token scale at end of phase.
**Depends on**: Phase 135
**Requirements**: POLISH-DS
**Success Criteria** (what must be TRUE):

  1. The `--tl-*` token scales are deduplicated and formalized, including a control-size scale and a canonical status-color map.
  2. `v1.31-DESIGN-SYSTEM.md` documents the `.tl-*` catalog with each class marked canonical / deprecated / consolidated plus usage rules and antipatterns.
  3. Shared primitives (badge, button, panel, empty-state, table, toast, drawer, copy-affordance) render from one unified definition rather than per-screen variants.
  4. The token scale is explicitly frozen at end of phase so downstream per-screen work builds on a stable foundation.

**Plans**: 1 plan

- [x] 136-01-PLAN.md — Dark token and interaction contrast foundation

**UI hint**: yes

### Phase 137: "Prove" Cluster Polish

**Goal**: Bring Evidence, Policy·Redaction, Retention, and Exports (the least-iterated screens, taken first for highest marginal return) to the consistent baseline — apply canonical primitives, close their audit findings, ship quality empty/error/dense states, and align actions/filters/status for least surprise. Record per-touchpoint decisions.
**Depends on**: Phase 136
**Requirements**: POLISH-PROVE
**Success Criteria** (what must be TRUE):

  1. Evidence, Policy·Redaction, Retention, and Exports each render with the canonical primitives and tokens from Phase 136.
  2. Each of the four screens shows quality empty, error, and dense states, with actions/filters/status aligned for least surprise.
  3. Every Phase-134 audit finding owned by these four screens is closed, with a per-touchpoint decision recorded.

**Plans**: 4 plans

- [x] 137-01-PLAN.md — Shared Prove presentation primitives
- [x] 137-02-PLAN.md — Exports readiness polish
- [x] 137-03-PLAN.md — Retention safety polish
- [x] 137-04-PLAN.md — Evidence hierarchy polish and Redaction alignment

**UI hint**: yes

### Phase 138: "Find" Cluster Polish

**Goal**: Bring Timeline, Transaction, Row-history, and Actor to the consistent baseline — focus on the less-iterated Transaction / Row-history / Actor screens plus Timeline's unaddressed states (dense / error / mobile); make filter / diff / correlation interactions consistent.
**Depends on**: Phase 137
**Requirements**: POLISH-FIND
**Success Criteria** (what must be TRUE):

  1. Timeline, Transaction, Row-history, and Actor each render with canonical primitives and tokens.
  2. Timeline's previously-unaddressed dense, error, and mobile states are correct.
  3. Filter, diff, and correlation interactions behave consistently across all four screens.
  4. Every Phase-134 audit finding owned by these four screens is closed.

**Plans**: 4 plans

- [x] 138-01-PLAN.md — Shared Find presentation primitives
- [x] 138-02-PLAN.md — Transaction and Row-history value convergence
- [x] 138-03-PLAN.md — Timeline dense/error/mobile and refs
- [x] 138-04-PLAN.md — Actor blast-radius and Coverage remediation closure

**UI hint**: yes

### Phase 139: Orientation Hub (Home / Nav)

**Goal**: Make the Home start page and `surface_header` nav reflect the locked persona/JTBD IA — consistent active states, grouping, and a mobile nav pattern; Home orients each persona to an obvious next action (GDS start-page philosophy).
**Depends on**: Phase 138
**Requirements**: POLISH-HOME
**Success Criteria** (what must be TRUE):

  1. The `surface_header` nav shows consistent active states and grouping that match the locked IA across every screen.
  2. A mobile nav pattern works at 375 and is reachable on every screen.
  3. The Home start page orients each defined persona to an obvious next action.

**Plans**: 3 plans

- [x] 139-01-PLAN.md — SurfaceHeader grouped nav, active states, Exports handoff, and mobile-reachable primitives
- [x] 139-02-PLAN.md — Home orientation, health severity, saved-view resume, and Phase 140 non-leakage guards
- [x] 139-03-PLAN.md — Focused 375px Home/nav Playwright UAT

**UI hint**: yes

### Phase 140: Earned New Flows

**Goal**: Build the JTBD-traced new flows: record-first lookup from Home (cordoned path, no filter-building), a closed export loop (filtered Timeline/Evidence view → pre-populated export), correlation-id paste/deep-link from Home, and first-class row-history entry (not only from inside a transaction). Each flow traces to a persona JTBD + a decision record. Done after the hub and screens exist.
**Depends on**: Phase 139
**Requirements**: POLISH-FLOWS
**Success Criteria** (what must be TRUE):

  1. A support operator can look up one record's history from Home without building filters.
  2. A reviewer can carry a filtered Timeline/Evidence view into a pre-populated export (closed loop).
  3. An incident responder can paste or deep-link a correlation_id from Home.
  4. Row history is reachable as a first-class entry, not only from inside a transaction.
  5. Each new flow traces to a named persona JTBD and a recorded decision; no speculative flows shipped.

**Plans**: 5 plans

- [x] 140-01-PLAN.md — First-class row-history route and safe route-aware component paths
- [x] 140-02-PLAN.md — Home record-first lookup and correlation paste/deep-link
- [x] 140-03-PLAN.md — Timeline filtered context carried into Exports
- [x] 140-04-PLAN.md — Evidence proof context carried into Exports
- [x] 140-05-PLAN.md — Focused browser UAT for earned flows

**UI hint**: yes

### Phase 141: Motion & Micro-animation

**Goal**: Add restrained, research-backed micro-animation: a motion inventory mapping each animation → trigger → JTBD → token; reuse the existing 120/180/240ms timings and the signature thread-draw; honor `prefers-reduced-motion`; nothing gratuitous.
**Depends on**: Phase 140
**Requirements**: POLISH-MOTION
**Success Criteria** (what must be TRUE):

  1. A documented motion inventory maps each animation to its trigger, JTBD, and motion token.
  2. Animations reuse the existing 120/180/240ms timings and the signature thread-draw rather than introducing ad-hoc motion.
  3. `prefers-reduced-motion` is honored on every animated surface.
  4. Each shipped animation has a research-backed rationale; no gratuitous motion remains.

**Plans**: 3 plans
Plans:

- [x] 141-01-PLAN.md — Motion inventory and source-contract tests
- [x] 141-02-PLAN.md — Contract-driven CSS/inventory alignment
- [x] 141-03-PLAN.md — Focused browser motion/reduced-motion UAT

**UI hint**: yes

### Phase 142: Responsive / Mobile-First

**Goal**: Achieve genuine mobile-first responsiveness (today the surface has only 3 `@media` queries): tokenize a breakpoint scale; give tables, filters, drawers, and nav mobile-first layouts; ensure every screen is correct at 375 / 768 / 1280 with no horizontal-scroll regressions.
**Depends on**: Phase 141
**Requirements**: POLISH-RESPONSIVE
**Success Criteria** (what must be TRUE):

  1. A breakpoint scale is tokenized and used consistently across the surface.
  2. Tables, filters, drawers, and nav have mobile-first layouts.
  3. Every operator-surface screen is usable and correct at 375, 768, and 1280.
  4. No horizontal-scroll regressions exist at any breakpoint.

**Plans**: 3 plans
Plans:

- [x] 142-01-PLAN.md — Breakpoint token and source-contract foundation
- [x] 142-02-PLAN.md — Shared responsive CSS primitive alignment
- [x] 142-03-PLAN.md — Responsive browser matrix UAT

**UI hint**: yes

### Phase 143: Accessibility + Consistency Sweep + Regression

**Goal**: Establish an accessibility baseline on the primitives (focus order, focus-visible, contrast, ARIA); run a final cross-surface consistency sweep that closes all remaining audit findings; diff a final screenshot set against the Phase-134 baseline (every delta explained); and wire a lightweight screenshot-diff guard into the Playwright/CI lane so future PRs can't silently degrade the polished baseline.
**Depends on**: Phase 142
**Requirements**: POLISH-A11Y
**Success Criteria** (what must be TRUE):

  1. Interactive primitives meet an accessibility baseline — focus order, focus-visible, contrast, and ARIA.
  2. A final cross-surface consistency sweep closes all remaining Phase-134 audit findings.
  3. A final screenshot set is diffed against the baseline, with every delta explained.
  4. A screenshot-diff guard runs in the Playwright/CI lane so future PRs can't silently degrade the polished baseline.

**Plans**: 4 plans
Plans:

- [x] 143-01-PLAN.md — Accessibility primitive baseline
- [x] 143-02-PLAN.md — Consistency sweep and browser suite repair
- [x] 143-03-PLAN.md — Final screenshot diff and audit closure
- [x] 143-04-PLAN.md — Screenshot regression guard

**UI hint**: yes

### Phase 144: Close gap: POLISH-AUDIT and POLISH-DS

**Goal:** Close the two remaining v1.31 audit blockers by verifying the existing Phase 134-labeled baseline evidence through explicit Phase 144 errata, completing the source-first design-system consolidation/catalog/freeze for POLISH-DS, and rerunning final traceability/milestone audit checks without adding product scope.
**Requirements**: POLISH-AUDIT, POLISH-DS
**Depends on:** Phase 143
**Plans:** 4/4 plans complete

Plans:
**Wave 1**

- [x] 144-01-PLAN.md — Phase 144 audit errata closure for POLISH-AUDIT
- [x] 144-02-PLAN.md — Source-first operation primitive consolidation for POLISH-DS

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 144-03-PLAN.md — Design-system catalog and token/class freeze contracts for POLISH-DS

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 144-04-PLAN.md — Final verification, traceability updates, and milestone audit rerun

## Shipped milestones (index)

- ✅ **v1.22 Policy / Evidence Plane** — Phases 95-103, shipped 2026-05-27. Archive: `.planning/milestones/v1.22-ROADMAP.md`
- ✅ **v1.23 Realistic-Demo Walkthrough** — Phases 104-110, shipped 2026-05-27. Archive: `.planning/milestones/v1.23-ROADMAP.md`
- ✅ **v1.24 Audited Write Path & Adopter Truth** — Phases 111-113, shipped 2026-05-27. Archive: `.planning/milestones/v1.24-ROADMAP.md`
- ✅ **v1.25 Adopter-Ready Release & First-Hour Truth** — Phases 114-118, shipped 2026-05-28. Archive: `.planning/milestones/v1.25-ROADMAP.md`
- ✅ **v1.26 Auth Lane Breadth** — Phases 119-121, shipped 2026-05-28. Archive: `.planning/milestones/v1.26-ROADMAP.md`
- ✅ **v1.27 Distribution & First-Hour Finish** — Phases 122-127, shipped 2026-05-28. Archive: `.planning/milestones/v1.27-ROADMAP.md`
- ✅ **v1.29 First-Hour Parity** — Phases 128-130.1, shipped 2026-05-29. Archive: `.planning/milestones/v1.29-ROADMAP.md`
- ✅ **v1.30 Adoption Evidence Automation** — Phases 131-133, shipped 2026-05-29. Archive: `.planning/milestones/v1.30-ROADMAP.md`
- 🚧 **v1.31 Operator Surface: Insane Polish** — Phases 134-143, in progress (opened 2026-06-03)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | --------- |
| 131 ConnCase §5 + walkthrough tighten | v1.30 | - | Complete | 2026-05-29 |
| 132 Playwright gap suite + CI job | v1.30 | - | Complete | 2026-05-29 |
| 133 Evaluator playbook + doc contracts | v1.30 | - | Complete | 2026-05-29 |
| 134 Baseline Audit & Screenshot Inventory | v1.31 | 0/0 | Not started | - |
| 135 Seed Enrichment & IA Lock-In | v1.31 | 0/4 | Planned | - |
| 136 Design-System Hardening | v1.31 | 1/1 | In progress | - |
| 137 "Prove" Cluster Polish | v1.31 | 4/4 | Complete | 2026-06-04 |
| 138 "Find" Cluster Polish | v1.31 | 0/4 | Planned | - |
| 139 Orientation Hub (Home / Nav) | v1.31 | 0/0 | Not started | - |
| 140 Earned New Flows | v1.31 | 0/0 | Not started | - |
| 141 Motion & Micro-animation | v1.31 | 0/0 | Not started | - |
| 142 Responsive / Mobile-First | v1.31 | 0/0 | Not started | - |
| 143 Accessibility + Consistency Sweep + Regression | v1.31 | 0/0 | Not started | - |
| 144 Close gap: POLISH-AUDIT and POLISH-DS | v1.31 | 4/4 | Complete | 2026-06-04 |
