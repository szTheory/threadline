# Roadmap: Threadline

## Milestones

- ð§ **v1.37 Operator Surface Design-System Stress Test & Component System** â Phases 171-180 (in progress)
- â **v1.36 Operator Surface Light Mode** â Phases 166-170 (shipped 2026-06-14). Archive: `.planning/milestones/v1.36-ROADMAP.md`
- â **v1.35 Unified Logo & Brand Book v2** â Phases 159-165 (shipped 2026-06-12). Archive: `.planning/milestones/v1.35-ROADMAP.md`
- â **v1.34 Local Docker Admin UI DX** â Phases 154-158 (shipped 2026-06-07). Archive: `.planning/milestones/v1.34-ROADMAP.md`
- â **v1.33 Brand Review + Direction Selection** â Phases 150-153 (shipped 2026-06-06). Archive: `.planning/milestones/v1.33-ROADMAP.md`
- â **v1.32 Brand System Foundation** â Phases 145-149 (shipped 2026-06-05). Archive: `.planning/milestones/v1.32-ROADMAP.md`

## ð§ v1.37 Operator Surface Design-System Stress Test & Component System (In Progress)

**Milestone Goal:** Turn the frozen-token / class-soup `/audit` operator surface into a systematically audited, internally-componentized design system â award-winning quality, on-brand across dark/light/system, mobile-first responsive, WCAG 2.2 AA accessible, with meaningful motion and on-brand microcopy â verified fractally (foundations â primitives â groups â pages â flows) and locked **idempotently** so every rerun only ratchets quality up, never regresses.

**Sequence:** Largely linear fractal order. Harness first (171); foundations before components (172 â 173/174); components before data-display and groups (â 176/177); groups before per-page stress (177 â 178); page stress before copy and accessibility (178 â 179/180); adversarial closeout last (180).

**Invariants (every phase):** no public component API; zero new runtime dependencies; inline assets only (no Tailwind, asset pipeline, animation libs, or PhoenixStorybook); `brandbook_token_parity_test` stays green (new tokens land in `brandbook/tokens.{json,css}` first); capture & semantics layers untouched; fail-closed auth (stress route dev/test-gated, never an unauthenticated prod surface); enforced brand voice + banned vocabulary + domain language.

**Plan of record:** `~/.claude/plans/design-system-stress-test-fancy-gizmo.md`

### Phase 171: Audit baseline, stress-lab harness & idempotency ledger

**Goal**: Stand up the idempotency harness that every later phase ratchets against â the canonical render surface, the living inventory, the scored ledger, and the ugly-data fixtures.
**Depends on**: Nothing (first phase of milestone; builds on the frozen v1.36 token/contract foundation)
**Requirements**: DS-01, DS-02, DS-03, DS-04
**Success Criteria** (what must be TRUE):

  1. A dev/test-only `/audit/__stress` route renders every component, group, and page-fixture across the state Ã theme Ã viewport matrix, and is prod-gated so it never adds an unauthenticated or extra surface in production (verified by a router gate test).
  2. `DESIGN-SYSTEM.md` v2 exists and inventories every foundation token, primitive, form control, group/meta-component, and page, each with a current status.
  3. An idempotent audit ledger records a per-item quality score with a documented ratchet rule (reruns may only raise scores), backed by test/screenshot guards that fail CI on a regression.
  4. A reusable ugly-data fixture library covers the full stress matrix (empty, one, many, long IDs/strings, non-ASCII, high/zero counts, null fields, mixed severity, permission-denied, stale, reconnecting, timezone + pagination boundaries).

**Plans**: 4 plans
Plans:
**Wave 1**

- [x] 171-01-PLAN.md â Static stress fixture registry and DS-04 adapter contracts

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 171-02-PLAN.md â JSON ledger, DESIGN-SYSTEM.md projection, and ratchet contracts

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 171-03-PLAN.md â Internal `/audit/__stress` router, LiveView shell, auth/prod gates

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 171-04-PLAN.md â Playwright semantic guards and ledger-owned screenshot allowlist

**UI hint**: yes

### Phase 172: Foundations audit & hardening (tokens)

**Goal**: Audit the design foundations against the brand book and fix off-brand / contrast / scale gaps, adding tokens only when the audit demands and only parity-first.
**Depends on**: Phase 171 (audits and scores are recorded in the ledger / inventory)
**Requirements**: DS-05, DS-06
**Success Criteria** (what must be TRUE):

  1. Color, typography, spacing, radius, shadow, z-index, density, and motion tokens are audited against the brand book and any off-brand / contrast / scale gaps are fixed.
  2. Any new token lands in `brandbook/tokens.{json,css}` first and the `brandbook_token_parity_test` stays green (no drift in either direction).
  3. Each significant foundation decision is captured as a compact decision brief (problem / users-JTBD / options / tradeoffs / idiomatic-for-LiveView / recommendation / rejected alternatives / tests to lock it).

**Plans**: 2 plans
Plans:
**Wave 1**

- [x] 174-01-PLAN.md â Form Primitives & Field Component

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 174-02-PLAN.md â Operator Page Adoption

**UI hint**: yes

### Phase 173: Primitive components (extract + audit each in isolation)

**Goal**: Extract the class-soup primitive and overlay/disclosure set into internal private function components, each audited in isolation with a full interaction-state matrix and correct a11y semantics.
**Depends on**: Phase 172 (components consume the hardened tokens) and Phase 171 (each primitive gets a stress-lab story)
**Requirements**: COMP-01, COMP-02, COMP-03
**Success Criteria** (what must be TRUE):

  1. Internal private function components exist for the primitive set (button, icon-button, link, badge/chip/tag/pill, alert/banner/callout, card/panel, stat tile, divider, empty state, error state, spinner/progress/skeleton, code/log/JSON, avatar) with documented attrs/slots and no public/host-facing API.
  2. Overlay & disclosure primitives (modal/dialog, drawer/sheet, toast/flash, tooltip, popover, dropdown/menu, tabs, segmented control, accordion/disclosure) are internal components with correct keyboard, focus-trap/restore, escape, and scrim semantics.
  3. Every primitive renders correctly in all interaction states (default/hover/focus-visible/active/pressed/disabled/loading/selected/current) across dark/light/system, and non-interactive elements expose no misleading affordances â visible on the stress route.

**Plans**: 4 plans
Plans:
**Wave 1**

- [x] 173-01-PLAN.md â Core UI Foundation & Atoms

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 173-02-PLAN.md â Container & Layout Primitives

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 173-03-PLAN.md â JS-Driven Overlays & Disclosures

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 173-04-PLAN.md â Full Interaction-State Matrix & Stress Audit

**UI hint**: yes

### Phase 174: Form components

**Goal**: Build the internal form-component set and adopt it across the operator pages so inline class-soup is replaced and template duplication is materially reduced.
**Depends on**: Phase 173 (forms compose primitives like button, field, error/help slots)
**Requirements**: COMP-04, COMP-05, COMP-06
**Success Criteria** (what must be TRUE):

  1. Internal form components exist (text/textarea/select/combobox/checkbox/radio/switch/search/number-date/filter controls/field group/error summary/help/required-optional/disabled-readonly) with visible associated labels, programmatically connected help + errors, non-color validation, and focus preserved across LiveView patches.
  2. The 11 operator-surface LiveView pages consume the components (inline class-soup replaced) and template duplication is materially reduced.
  3. Per-component contract tests lock attrs/slots/states/a11y so a component regression fails CI.

**Plans**: 6 plans (174-01..04 shipped; 174-05..06 gap closure)
Plans:

**Wave 1**

- [x] 174-01-PLAN.md — Internal <.field>/<.input>/<.label>/<.error>/<.help> form components
- [x] 174-02-PLAN.md — Adopt components in core pages (start, timeline, row_history, surface_header)
- [x] 174-03-PLAN.md — Adopt components in detail LiveViews (actor, transaction, coverage, evidence)
- [x] 174-04-PLAN.md — Final sweep + stress_live form matrices; confirm auxiliary pages formless
- [x] 174-05-PLAN.md — Add missing components (error_summary, combobox, field_group, radio, switch, search/date/number) + contract tests (COMP-04, COMP-06)

**Wave 2** *(blocked on 174-05)*

- [x] 174-06-PLAN.md — Migrate timeline raw <fieldset> to field_group + lock 8 formless pages (COMP-05)

**UI hint**: yes

### Phase 175: Navigation, app shell & runtime theme picker

**Goal**: Bring the app shell and navigation to a consistent on-brand structure and ship the in-product dark/light/system theme picker (THEME-TOGGLE-01).
**Depends on**: Phase 174 (shell/nav built on the component system; theme picker uses form/control components)
**Requirements**: NAV-01, NAV-02, NAV-03, NAV-04
**Success Criteria** (what must be TRUE):

  1. The app shell + navigation (topbar/sidebar/breadcrumbs/page titles/section tabs/toolbar/back-cancel/mobile nav) present a consistent on-brand structure where the operator always knows where they are; active/current state is unmistakable in dark and light.
  2. Pagination is clear when present and de-emphasizes or hides itself with one page or zero results; search/filter affordances are clear and space-efficient.
  3. An in-product theme picker lets each operator choose dark/light/system (system default), implemented as cookie + plug with zero JavaScript and no FOUC; the `theme-toggle` ban is lifted in the style contract and the choice persists per operator (resolves `theme-picker-idiomatic-ui`).
  4. Mobile navigation works without nested-scroll traps, and sticky elements never cover content.

**Plans**: 4 plans
Plans:

**Wave 1**

- [x] 175-01-PLAN.md — Wave 0 test scaffolds (CSP guard, page_header, breadcrumb, pager, skip-link)

**Wave 2** *(blocked on 175-01)*

- [x] 175-02-PLAN.md — Theme picker fix + CSP hardening + native <details> nav + sticky/scroll + ban lift

**Wave 3** *(blocked on 175-01)*

- [x] 175-03-PLAN.md — Internal page_header + breadcrumb component, adopted across all 11 pages

**Wave 4** *(blocked on 175-01, 175-02, 175-03)*

- [x] 175-04-PLAN.md — Accessible pager over the existing keyset engine + cap captions + keyset perf-debt note

**UI hint**: yes

### Phase 176: Data display & operator patterns

**Goal**: Make tables/lists/timeline/KV/charts/status/actions read clearly under real (ugly) data, distinguish all empty/loading/error/stale/permission states, and flatten accidental nesting / table overuse system-wide.
**Depends on**: Phase 175 (data surfaces live inside the finalized shell/nav and component system)
**Requirements**: DATA-01, DATA-02, DATA-03, DATA-04, DATA-05
**Success Criteria** (what must be TRUE):

  1. Tables/data-grids stay readable under real data (long IDs/paths/atoms/emails/URLs/timestamps middle-truncate with copy + title), important columns never squish unreadably, and card/list layout is used where tables don't fit (mobile / non-tabular data).
  2. KV/metadata, timeline/event log, detail views, status summaries, and metrics/charts read clearly, never rely on color alone, and present time as relative + absolute with timezone made clear.
  3. Empty/zero, loading, error, and stale states are visually distinct and explain the next action; permission-denied is distinguished from no-data and from unavailable-data.
  4. Row actions and bulk actions are discoverable but not accidentally triggerable; destructive actions are separated and confirmed by naming the object and consequence.
  5. The coverage "schema" section card-in-card nesting is flattened (resolves `coverage-schema-card-declutter`), and accidental nesting / table-overuse is removed system-wide.

**Plans**: 5 plans
Plans:

**Wave 1**

- [x] 176-01-PLAN.md — Wave-0 test scaffolds + Presentation.ref/2 core + tail-safe truncation + missing icons

**Wave 2** *(blocked on 176-01)*

- [x] 176-02-PLAN.md — UI components: ref/1, kv/1, data_table/1, loading_state/1, stale_banner/1 + empty_state variants + data_state/1 + stress stories

**Wave 3** *(blocked on 176-02)*

- [x] 176-03-PLAN.md — DATA-01/03 consumer migration (copy-footgun fix, kv/diff cells, CSS double-trunc kill, data-state taxonomy)

**Wave 4** *(blocked on 176-03 / 176-02)*

- [x] 176-04-PLAN.md — DATA-05 coverage flatten + system-wide card-nesting sweep + regression test
- [x] 176-05-PLAN.md — DATA-04 destructive actions: T3 server-enforced prune (security core) + kebab + redaction collapse fix (redact gated by checkpoint)

**UI hint**: yes

### Phase 177: Component groups / meta-components

**Goal**: Audit the recurring component configurations as cohesive units with intentional spacing/hierarchy and aligned states, holding together across narrow and wide layouts.
**Depends on**: Phase 176 (groups assemble the audited primitives, forms, and data-display patterns)
**Requirements**: GROUP-01, GROUP-02
**Success Criteria** (what must be TRUE):

  1. Recurring configurations (page-header+actions+breadcrumbs; toolbar+search+filters+sort; table+empty+loading+pagination; stat-cards+chart+table; detail-header+metadata+actions; modal-confirm+destructive; drawer+form; toast+state-update; tabs+subviews; empty+CTA; permission-denied; reconnect/offline-banner+disabled-actions) are audited as units with intentional spacing and hierarchy.
  2. Each group holds together across narrow and wide layouts, with states aligned across its children, and motion clarifies state transitions â verifiable on the stress route at multiple viewports.

**Plans**: 5 plans

Plans:

- [x] 177-01-PLAN.md — Wave 0: resolve the two locked-decision conflicts (LiveView-root offline anchor; breadcrumbs attr-keep) + RED scaffolds (tokens/components/offline/overlay)
- [x] 177-02-PLAN.md — Semantic gap tokens + UI.stack/1 + UI.cluster/1 layout primitives
- [x] 177-03-PLAN.md — UI.data_panel/1 + UI.toolbar/1 + UI.detail_header/1 + page_header breadcrumb truncation
- [x] 177-04-PLAN.md — Overlay JS-transition CSS completion + time-sync + reconnect/offline group on `.threadline-ui.phx-*`
- [x] 177-05-PLAN.md — Map 12 group configs to stress stories (live/reference tag) + ledger/DESIGN-SYSTEM parity + audit

**UI hint**: yes

### Phase 178: Per-page & flow stress pass (all 11 pages)

**Goal**: Stress every operator page across all paths, themes, viewports, keyboard, reduced-motion, and reconnect; eliminate the named footgun classes and fix the desktop centering bug.
**Depends on**: Phase 177 (pages are now assembled from audited components and groups; per-page stress is the integration pass)
**Requirements**: PAGE-01, PAGE-02, PAGE-03
**Success Criteria** (what must be TRUE):

  1. Each of the 11 pages (Home, Timeline, Transaction, Row history, Actor, Coverage, Evidence, Redaction, Retention, Exports, plus shell) is audited against happy/empty/loading/error/permission-denied/boundary/advanced paths Ã dark/light/system Ã 320/375/768/1024/1440 Ã keyboard-only Ã reduced-motion Ã LiveView reconnect, with findings recorded in the ledger.
  2. The named footgun classes are eliminated: scroll traps, modal/drawer hidden behind scrim or floating wrong, focus not entering/restoring from overlays, escape/click-outside inconsistency, hover/focus on non-interactive elements, misalignment / chopped padding / inconsistent spacing, disabled-looks-enabled (and enabled-looks-disabled), missing tab active-state, weird pagination, unreadable dark/light text, and same-color text-on-background.
  3. The transaction page centers correctly at desktop widths (resolves `transaction-page-left-push-desktop`).

**Plans**: 6 plans
- [x] 178-01-PLAN.md — Wave 1: guard-first RED detectors (11 footguns + centering + Home twin + reconnect-mount + page-story conversion) + Tier B spec scaffold
- [x] 178-02-PLAN.md — Wave 2 (SEED-005): extract shared shell, mount reconnect_banner once, wire data-tl-mutating on real state-changers
- [x] 178-03-PLAN.md — Wave 3 (PAGE-03): justify-self:center on .tl-container + latent-twin .tl-home; Tier B centering geometry
- [x] 178-04-PLAN.md — Wave 3 (PAGE-01): 11 reserved page entries → fixture-backed 7-path stories, ledger ratchet, DESIGN-SYSTEM.md projection
- [x] 178-05-PLAN.md — Wave 4 (PAGE-02): fix all 11 footgun classes to green (Tier A + Tier B) + representative ~66-cell sample
- [ ] 178-06-PLAN.md — Wave 5 (gap closure): re-anchor reconnect selectors to [data-phx-main], strengthen Tier A guard, prove real socket-drop banner/dimming behavior
**UI hint**: yes

### Phase 179: Microcopy & information-architecture sweep

**Goal**: Sweep all UI copy and information architecture to brand voice, banned-vocabulary, and domain-language standards with a GOV.UK least-surprise / progressive-disclosure lens that preserves power-user efficiency.
**Depends on**: Phase 178 (copy and IA are finalized once page structure and flows are stable)
**Requirements**: COPY-01, COPY-02, COPY-03
**Success Criteria** (what must be TRUE):

  1. All UI copy follows the brand voice and avoids banned vocabulary; error/empty/success/warning/destructive copy follows the documented patterns (say what happened + how to fix; name the object + consequence; no blame).
  2. Domain language is used consistently across headings/tabs/filters/buttons/alerts (AuditTransaction, AuditChange, AuditAction, ActorRef, Correlation; covered/uncovered, drift detected, redaction policy, retention window, evidence, incident drill-down, actor window, row history / as-of).
  3. Information architecture follows least-surprise and progressive disclosure (GOV.UK lens) while preserving power-user efficiency (keyboard support, dense views, stable URLs, copyable IDs, direct links).

**Plans**: TBD
**UI hint**: yes

### Phase 180: Accessibility verification, guardrails & adversarial closeout

**Goal**: Verify WCAG 2.2 AA across rendered states, confirm motion compliance, ensure all idempotency guardrails are green, and sign off the adversarial regression review that closes the milestone.
**Depends on**: Phase 179 (final accessibility, motion, and adversarial verification run against the completed surface)
**Requirements**: A11Y-01, A11Y-02, MOTION-01, MOTION-02
**Success Criteria** (what must be TRUE):

  1. The surface meets WCAG 2.2 AA, verified by automated scans on rendered states including opened dialogs/menus/popovers AND manual keyboard + screen-reader checks; every flow is keyboard-operable with visible, non-obscured, restored focus.
  2. Custom widgets follow WAI-ARIA APG patterns (dialog, tabs, menu, combobox, disclosure, tooltip, table/grid, alert, nav); color is never the only signal; touch target sizes are comfortable.
  3. Motion communicates state/continuity/feedback only, uses compositor-friendly properties, is origin-aware where applicable, avoids animating from `scale(0)`, gives responsive press feedback, respects `prefers-reduced-motion`, and stays within the motion-token contract.
  4. Idempotency guardrails are in place and green (expanded Playwright matrix + stress-route screenshot regression, per-component + style contract tests, brand-token parity), and an adversarial regression review is signed off (aesthetics-vs-usability, dependency/architecture weight, host-integration friction, inaccessible custom behavior, generic-template drift, screenshot-only quality).

**Plans**: TBD
**UI hint**: yes

## Phases

<details>
<summary>â v1.36 Operator Surface Light Mode (Phases 166-170) â SHIPPED 2026-06-14</summary>

`theme: :dark | :light | :system` host config rendered server-side as `data-tl-theme` over a pure-CSS 45-token light lane (no JS/FOUC, CSP-proof). Dark stays the default and the brand; `:system` is the documented daytime-use recommendation. 15/15 requirements; audit passed.

- [x] Phase 166: unfreeze-token-lane-mechanism (1/1 plans) â completed 2026-06-13 â 45-token light lane, `data-tl-theme` mechanism, compile-validated `theme:` option, source-first contract amendment
- [x] Phase 167: component-retune (2/2 plans) â completed 2026-06-14 â ~9 dark-effect families + data-viz surfaces explicitly retuned for light (the Grafana lesson)
- [x] Phase 168: accessibility-verification (2/2 plans) â completed 2026-06-14 â light/system AA contrast mirror (alpha-aware parser) + per-mode focus/interaction contracts
- [x] Phase 169: screenshots-example-docs (2/2 plans) â completed 2026-06-14 â `__light__` screenshot lane, example app `theme: :system`, `theme:` docs under doc-contract
- [x] Phase 170: brand-alignment-closeout (2/2 plans) â completed 2026-06-14 â tokens.json/css 45-token parity, dual-mode pressure-test, milestone audit

**Deferred at close:** end-of-milestone human UAT (`169`/`170-HUMAN-UAT.md`), `170-VERIFICATION.md` (human-needed), and 3 operator-surface todos â see STATE.md Deferred Items.

</details>

## Progress

**Execution Order (v1.37):** Phases execute in numeric order: 171 â 172 â 173 â 174 â 175 â 176 â 177 â 178 â 179 â 180.

| Phase | Milestone | Plans Complete | Status | Completed |
|---|---|---:|---|---|
| 171. Audit baseline, stress-lab harness & idempotency ledger | v1.37 | 4/4 | Complete    | 2026-06-14 |
| 172. Foundations audit & hardening (tokens) | v1.37 | 2/2 | Complete    | 2026-06-15 |
| 173. Primitive components | v1.37 | 4/4 | Complete    | 2026-06-16 |
| 174. Form components | v1.37 | 6/6 | Complete    | 2026-06-17 |
| 175. Navigation, app shell & runtime theme picker | v1.37 | 4/4 | Complete    | 2026-06-17 |
| 176. Data display & operator patterns | v1.37 | 5/5 | Complete    | 2026-06-18 |
| 177. Component groups / meta-components | v1.37 | 5/5 | Complete   | 2026-06-18 |
| 178. Per-page & flow stress pass (all 11 pages) | v1.37 | 5/5 | Complete   | 2026-06-18 |
| 179. Microcopy & information-architecture sweep | v1.37 | 0/TBD | Not started | - |
| 180. Accessibility verification, guardrails & adversarial closeout | v1.37 | 0/TBD | Not started | - |
| 166. unfreeze-token-lane-mechanism | v1.36 | 1/1 | Complete | 2026-06-13 |
| 167. component-retune | v1.36 | 2/2 | Complete | 2026-06-14 |
| 168. accessibility-verification | v1.36 | 2/2 | Complete | 2026-06-14 |
| 169. screenshots-example-docs | v1.36 | 2/2 | Complete | 2026-06-14 |
| 170. brand-alignment-closeout | v1.36 | 2/2 | Complete | 2026-06-14 |

## Prior Milestones

- â **v1.35 Unified Logo & Brand Book v2** â Phases 159-165 (shipped 2026-06-12). Archive: `.planning/milestones/v1.35-ROADMAP.md`
- â **v1.34 Local Docker Admin UI DX** â Phases 154-158 (shipped 2026-06-07). Archive: `.planning/milestones/v1.34-ROADMAP.md`
- â **v1.33 Brand Review + Direction Selection** â Phases 150-153 (shipped 2026-06-06). Archive: `.planning/milestones/v1.33-ROADMAP.md`
- â **v1.32 Brand System Foundation** â Phases 145-149 (shipped 2026-06-05). Archive: `.planning/milestones/v1.32-ROADMAP.md`
