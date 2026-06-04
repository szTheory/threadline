# Requirements: v1.31 — Operator Surface: Insane Polish

**Milestone goal:** A systematic second pass over the entire `/audit` operator surface (adopter-mounted admin UI, not the demo app): bring every screen to one consistent, brand-aligned, mobile-first baseline on a hardened BEM + `--tl-*` token design system, align IA to real personas/JTBD with a few earned new flows, add restrained purposeful micro-animation, and enrich seed data — screenshot-/decision-recorded so a context clear loses nothing.

**Source of truth:** Persona/IA model, methodology, and full Phase 0–8 breakdown live in the approved plan `~/.claude/plans/recap-goal-was-shipping-robust-lark.md`.

## Requirements

### Baseline & evidence

- [x] **POLISH-AUDIT**: An operator can review an objective current-state baseline — a screenshot set covering every screen × every meaningful state (empty/sparse/dense/error/scoped, mobile-375 + desktop-1280, N/A cells marked with reason) plus `v1.31-UI-AUDIT.md` (state matrix + touchpoint inventory + ranked consistency findings, each with ID/severity/proposed resolution/owning phase). Closed by Phase 144 errata verification in `.planning/phases/144-close-gap-polish-audit-and-polish-ds/144-AUDIT-ERRATA.md`.

### Seed enrichment

- [x] **POLISH-SEED**: Every operator-surface screen demonstrates itself from seed — empty states, long/paginated lists, status variety, and permission/edge cases are all reachable via `mix demo.reset && mix demo.seed`; DEMO-MANIFEST.md updated as SSOT. Seed only — no schema/route/business-logic changes to the demo app.

### Design system

- [ ] **POLISH-DS**: The design system pays reuse dividends — token scales (spacing, control-size, radius, shadow, typography, canonical status-color map, z-index, motion) are deduplicated and formalized; the `.tl-*` class catalog is documented in `v1.31-DESIGN-SYSTEM.md` (each canonical/deprecated/consolidated with usage rules + antipatterns); shared primitives (badge, button, panel, empty-state, table, toast, drawer, copy-affordance) are unified. Token scale frozen at end of phase.

### Per-screen polish (least-iterated first)

- [x] **POLISH-PROVE**: Each of Evidence, Policy·Redaction, Retention, and Exports is brought to the consistent baseline — canonical primitives applied, audit findings closed, quality empty/error/dense states, least-surprise alignment of actions/filters/status.
- [x] **POLISH-FIND**: Each of Timeline, Transaction, Row-history, and Actor is brought to the consistent baseline — focus on the less-iterated screens and Timeline's unaddressed states (dense/error/mobile); filter/diff/correlation interactions made consistent.
- [x] **POLISH-HOME**: The Home start page and `surface_header` nav reflect the locked persona/JTBD IA — consistent active states, grouping, and a mobile nav pattern; Home orients each persona to an obvious next action (GDS start-page philosophy).

### Earned new flows (each traces to a JTBD + decision record)

- [x] **POLISH-FLOWS**: A support operator can look up one record's history from Home without building filters (record-first cordoned path); a reviewer can carry a filtered Timeline/Evidence view into a pre-populated export (closed export loop); an incident responder can paste/deep-link a correlation_id from Home; and row history is reachable as a first-class entry, not only from inside a transaction.

### Motion

- [x] **POLISH-MOTION**: Micro-animation is restrained and purposeful — a documented motion inventory maps each animation → trigger → JTBD → token; every animation has a research-backed rationale; `prefers-reduced-motion` is honored; no gratuitous motion.

### Responsive

- [x] **POLISH-RESPONSIVE**: Every operator-surface screen is usable and correct at 375 / 768 / 1280 — a breakpoint scale is tokenized; tables, filters, drawers, and nav have mobile-first layouts; no horizontal-scroll regressions.

### Accessibility & regression

- [x] **POLISH-A11Y**: Interactive primitives meet an accessibility baseline (focus order, focus-visible, contrast, ARIA); a final cross-surface consistency sweep closes all remaining audit findings; a final screenshot set is diffed against baseline with every delta explained; a lightweight screenshot-diff guard is wired into the Playwright/CI lane so future PRs can't silently degrade the polished baseline.

## Explicit non-goals

| Item | Rationale |
|------|-----------|
| CSS-architecture switch (Tailwind / CSS-in-JS / build step) | BEM `.tl-*` + `--tl-*` tokens in `style.ex` is settled; double down, don't churn |
| Light mode / theme toggle | Dark-first brand is locked ("night infrastructure with luminous signal lines") |
| Demo-app redesign (new tables/routes/business logic) | Seed *enrichment* only; the demo exists to exercise the surface |
| New backend features / new queries / new screens | Polish the 10 existing LiveViews; no product-surface expansion |
| v1.28 External Pilot work | Still signal-gated; this milestone is independent |
| Speculative UX flows | Every new flow must trace to a persona JTBD + a decision record |

## Traceability

Every v1.31 requirement maps to exactly one phase (1:1). Phase numbering continues from the prior milestone's last phase (133).

| Requirement | Phase | Status |
|-------------|-------|--------|
| POLISH-AUDIT | Phase 134 — Baseline Audit & Screenshot Inventory | Complete via Phase 144 errata verification |
| POLISH-SEED | Phase 135 — Seed Enrichment & IA Lock-In | Complete |
| POLISH-DS | Phase 136 — Design-System Hardening | Pending |
| POLISH-PROVE | Phase 137 — "Prove" Cluster Polish | Complete |
| POLISH-FIND | Phase 138 — "Find" Cluster Polish | Complete |
| POLISH-HOME | Phase 139 — Orientation Hub (Home / Nav) | Complete |
| POLISH-FLOWS | Phase 140 — Earned New Flows | Complete |
| POLISH-MOTION | Phase 141 — Motion & Micro-animation | Complete |
| POLISH-RESPONSIVE | Phase 142 — Responsive / Mobile-First | Complete |
| POLISH-A11Y | Phase 143 — Accessibility + Consistency Sweep + Regression | Complete |

**Coverage:** 10/10 requirements mapped — no orphans, no duplicates.
