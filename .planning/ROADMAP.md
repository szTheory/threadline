# Roadmap: Threadline

## Milestones

- [ ] **v1.38 Operator UI Page-by-Page IA & Design-System Polish** - Phases 181-187 (active, started 2026-06-26)
- [x] **v1.37 Operator Surface Design-System Stress Test & Component System** - Phases 171-180 (shipped 2026-06-20). Archive: `.planning/milestones/v1.37-ROADMAP.md`
- [x] **v1.36 Operator Surface Light Mode** - Phases 166-170 (shipped 2026-06-14). Archive: `.planning/milestones/v1.36-ROADMAP.md`
- [x] **v1.35 Unified Logo & Brand Book v2** - Phases 159-165 (shipped 2026-06-12). Archive: `.planning/milestones/v1.35-ROADMAP.md`
- [x] **v1.34 Local Docker Admin UI DX** - Phases 154-158 (shipped 2026-06-07). Archive: `.planning/milestones/v1.34-ROADMAP.md`

## Active Milestone

### v1.38 Operator UI Page-by-Page IA & Design-System Polish

**Status:** Planning complete, ready for Phase 181 discussion/planning.

**Milestone Goal:** Make the mounted `/audit` operator UI obvious, task-led, coherent, and highly polished page by page, while preserving v1.37's private component system, route stability, auth boundaries, stress harness, and regression guardrails.

**Sequence:** Baseline and stale-guard repair first; Storybook dev lane second; Shell/Home/Timeline as the reference cleanup; Coverage next; remaining detail/governance pages after the reference patterns settle; accessibility/motion/docs/adversarial closeout last.

**Invariants:** root `threadline` keeps Phoenix/LiveView optional; PhoenixStorybook is example/dev-only; no capture/query/auth semantic changes; no public component API; no production stress/story route; no route or `data-testid` churn without explicit phase evidence.

### Phase 181: Baseline audit and guard repair

**Goal:** Establish current rendered truth before polish begins, repair stale verification, and preserve the v1.37 ratchet.

**Requirements:** BASE-01, BASE-02, BASE-03

**Success criteria:**

1. Current rendered `/audit` pages are audited against the page/JTBD matrix, including nav discoverability, stale selectors, and obvious info-dump risks.
2. E2E/source tests no longer reference removed contracts unless intentionally retired with rationale.
3. `DESIGN-SYSTEM.md`, `.planning/design-system-ledger.json`, screenshots, and stress fixtures stay fresh without lowering ratchet scores.
4. Research and decision context for Storybook, `/audit/__stress`, nav IA, a11y, motion, and operator personas is linked from the phase plan.

**Plans:** 11 plans

Plans:
**Wave 1**

- [x] 181-01-PLAN.md - Rendered baseline audit and screenshot inventory
- [x] 181-02-PLAN.md - Stale guard finding ledger

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 181-03-PLAN.md - Stale E2E selector repair

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 181-04-PLAN.md - Active source-test prose repair

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 181-05-PLAN.md - Route, auth, feature-gate, and optional-dependency source contracts

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 181-06-PLAN.md - Design-system ledger, projection, and stress source ratchet repair

**Wave 6** *(blocked on Wave 5 completion)*

- [ ] 181-07-PLAN.md - Bounded stress screenshot guard freshness

**Wave 7** *(blocked on Wave 6 completion)*

- [ ] 181-08-PLAN.md - Local screenshot-regression verification and classification

**Wave 8** *(blocked on Wave 7 completion)*

- [ ] 181-09-PLAN.md - Accepted Home and dense Timeline local PNG baselines

**Wave 9** *(blocked on Wave 8 completion)*

- [ ] 181-10-PLAN.md - Accepted Row-history, Exports, and Retention local PNG baselines

**Wave 10** *(blocked on Wave 9 completion)*

- [ ] 181-11-PLAN.md - Verification closeout and source coverage audit

**Cross-cutting constraints:**

- D-181-07 and D-181-08: Tier C local baseline updates remain bounded and inventory-backed.

### Phase 182: PhoenixStorybook example/dev lane

**Goal:** Add PhoenixStorybook as maintainer tooling in the Phoenix example app without changing the root package or production host surface.

**Requirements:** STORY-01, STORY-02, STORY-03

**Success criteria:**

1. PhoenixStorybook exists only in `examples/threadline_phoenix` dev/test setup and is excluded from production/demo routes unless explicitly enabled for maintainers.
2. Stories cover internal primitives, forms, states, overlays, data display, and recurring groups across dark/light/system and representative ugly data.
3. Root `mix compile --no-optional-deps` and host-facing docs prove Storybook is not a `threadline` dependency.
4. Docs explain Storybook as component documentation and `/audit/__stress` as authenticated operator-flow stress testing.

### Phase 183: Shell navigation and Home orientation

**Goal:** Make the operator shell and `/audit` Home unmistakably navigable and task-led.

**Requirements:** SHELL-01, SHELL-02, SHELL-03

**Success criteria:**

1. Desktop/tablet nav is visually present without overpowering the task; mobile nav remains native, clear, keyboard reachable, and labeled.
2. Home exposes the top jobs with one primary path into investigation and one into readiness/proof, without redundant generic cross-page CTAs.
3. Active/current state, scope/coverage status, theme picker, skip link, and feature-gated groups are accessible and consistent across dark/light/system.
4. Browser tests cover desktop/tablet/mobile nav perception and Home task-launch flows.

### Phase 184: Timeline investigation flow

**Goal:** Make Timeline the clean reference workflow for investigating audit history.

**Requirements:** TIME-01, TIME-02, TIME-03

**Success criteria:**

1. Timeline hierarchy clearly supports filter -> scan -> open transaction/row history -> export current view.
2. Toolbar, filters, saved views, pager, row actions, long refs, and empty/error/stale states work at 320, 375, 768, 1024, and 1440 px.
3. Keyboard-only operation covers filters, result rows, copy controls, pagination, and route transitions.
4. Copy is concise, exact, and useful under incident pressure.

### Phase 185: Coverage and audit readiness

**Goal:** Make Coverage answer one readiness question for one schema without repeated signals or compensating CTAs.

**Requirements:** COV-01, COV-02, COV-03

**Success criteria:**

1. Coverage shows one primary readiness verdict, selected schema, checked-at metadata, and a clear remediation path.
2. Repeated "needs capture" copy is collapsed; page-level generic Timeline CTAs are removed unless contextual to a row.
3. Schema switch, invalid schema, non-public row links, refresh, page-specific errors, and docs stay correct.
4. Regression tests cover public and non-public schema URL state plus mobile readability.

### Phase 186: Detail, governance, and export surfaces

**Goal:** Apply the cleaned IA/component patterns to remaining operator pages.

**Requirements:** DETAIL-01, GOV-01, GOV-02, GOV-03

**Success criteria:**

1. Transaction, row-history, and actor pages align on detail header, metadata, refs, drawers, copy, and state handling.
2. Evidence, Exports, Redaction, and Retention become focused workflows rather than dense metadata dumps.
3. Export/download links and feature-gated controls are enabled/disabled correctly for pointer, keyboard, and assistive tech users.
4. Retention destructive flow keeps type-to-confirm, auth re-check, audit-the-action, reconnect-safe disabled state, object/consequence copy, and focus restoration.

### Phase 187: Accessibility, motion, docs, and adversarial closeout

**Goal:** Verify the full pass, update docs, and close with an adversarial review.

**Requirements:** A11Y-01, A11Y-02, MOTION-01, DOC-01, CLOSE-01

**Success criteria:**

1. Primary investigation, readiness, export, and retention flows are keyboard-operable with visible, non-obscured focus and focus restoration.
2. Custom widgets follow APG expectations where applicable; native controls remain native where possible.
3. Motion stays token-backed, transform/opacity-oriented, purposeful, and reduced-motion aware.
4. Operator docs match implementation for theme picker, Storybook dev lane, stress route, auth/export gates, schema selection, CSP, and production exclusions.
5. Closeout records verification evidence, residual failure ownership if any, screenshot/Playwright status, and adversarial review.

## Current Planning State

v1.38 requirements are defined in `.planning/REQUIREMENTS.md`; Phase 181 is next.

## Prior Milestones

<details>
<summary>v1.37 Operator Surface Design-System Stress Test & Component System (Phases 171-180) - SHIPPED 2026-06-20</summary>

Internal component system, `/audit/__stress`, design-system ledger, shell/navigation/theme picker, page stress coverage, microcopy/IA normalization, WCAG/APG/motion guardrails, accessibility-tree evidence, and adversarial closeout. Archive: `.planning/milestones/v1.37-ROADMAP.md`.

</details>

<details>
<summary>v1.36 Operator Surface Light Mode (Phases 166-170) - SHIPPED 2026-06-14</summary>

`theme: :dark | :light | :system` host config and pure-CSS light/system lanes. Archive: `.planning/milestones/v1.36-ROADMAP.md`.

</details>
