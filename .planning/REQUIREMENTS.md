# Requirements: Threadline v1.37 Operator Surface Design-System Stress Test & Component System

**Defined:** 2026-06-14
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Source:** User design-system stress-test prompt + approved plan `~/.claude/plans/design-system-stress-test-fancy-gizmo.md`. Locked decisions: internal (private) function components; internal zero-dep `/audit/__stress` route; runtime theme picker included; comprehensive scope.

**Invariants (hold through every requirement):** no public component API; zero new runtime dependencies; inline assets only (no Tailwind, no asset pipeline, no animation libs, no PhoenixStorybook); `brandbook_token_parity_test` stays green; capture & semantics layers untouched; fail-closed auth; brand voice + banned-vocabulary + domain language enforced.

## v1 Requirements

Requirements for milestone v1.37. Each maps to roadmap phases 171–180 (fractal order: foundations → primitives → groups → pages → flows → copy → verify).

### Design-System Harness & Foundations (DS)

- [x] **DS-01**: A dev/test-only `/audit/__stress` route renders every component, component-group, and page-fixture across the full state × theme × viewport matrix; it is prod-gated and never adds an unauthenticated or extra surface in production.
- [x] **DS-02**: A living `DESIGN-SYSTEM.md` v2 inventories every foundation token, primitive, form control, group/meta-component, and page, each with current status.
- [x] **DS-03**: An idempotent audit ledger records a per-item quality score with a documented ratchet rule (reruns may only raise scores) backed by test/screenshot guards that fail CI on regression.
- [x] **DS-04**: A reusable ugly-data fixture library covers the stress matrix (empty, one, many, long IDs/strings, non-ASCII, high/zero counts, null fields, error/warning/mixed severity, permission-denied, stale, reconnecting, timezone + pagination boundaries).
- [x] **DS-05**: Foundations (color, typography, spacing, radius, shadow, z-index, density, motion tokens) are audited against the brand book; off-brand / contrast / scale gaps are fixed; any new token lands in `brandbook/tokens.{json,css}` first and keeps the parity test green.
- [x] **DS-06**: Each significant foundation decision is captured as a compact decision brief (problem / users-JTBD / options / tradeoffs / idiomatic-for-LiveView / recommendation / rejected alternatives / tests to lock it).

### Internal Component System (COMP)

- [x] **COMP-01**: Internal private function components exist for the primitive set (button, icon-button, link, badge/chip/tag/pill, alert/banner/callout, card/panel, stat tile, divider, empty state, error state, spinner/progress/skeleton, code/log/JSON, avatar) with documented attrs/slots — no public/host-facing API.
- [x] **COMP-02**: Overlay & disclosure primitives (modal/dialog, drawer/sheet, toast/flash, tooltip, popover, dropdown/menu, tabs, segmented control, accordion/disclosure) are internal components with correct keyboard, focus-trap/restore, escape, and scrim semantics.
- [x] **COMP-03**: Every primitive renders correctly in all interaction states (default/hover/focus-visible/active/pressed/disabled/loading/selected/current) across dark/light/system; non-interactive elements expose no misleading affordances.
- [x] **COMP-04**: Internal form components exist (text/textarea/select/combobox/checkbox/radio/switch/search/number-date/filter controls/field group/error summary/help/required-optional/disabled-readonly) with visible associated labels, programmatically connected help + errors, non-color validation, and focus preserved across LiveView patches.
- [x] **COMP-05**: The 11 operator-surface LiveView pages consume the components (inline class-soup replaced) and template duplication is materially reduced.
- [x] **COMP-06**: Per-component contract tests lock attrs/slots/states/a11y so a component regression fails CI.

### Navigation, App Shell & Runtime Theme Picker (NAV)

- [x] **NAV-01**: The app shell + navigation (topbar/sidebar/breadcrumbs/page titles/section tabs/toolbar/back-cancel/mobile nav) present a consistent on-brand structure where the operator always knows where they are; active/current state is unmistakable in dark and light.
- [x] **NAV-02**: Pagination is clear when present and de-emphasizes or hides itself when there is one page or zero results; search/filter affordances are clear and space-efficient.
- [x] **NAV-03** (THEME-TOGGLE-01): An in-product theme picker lets each operator choose dark/light/system (system default), implemented as cookie + plug with zero JavaScript and no FOUC; the `theme-toggle` ban is lifted in the style contract and the choice persists per operator.
- [x] **NAV-04**: Mobile navigation works without nested-scroll traps, and sticky elements never cover content.

### Data Display & Operator Patterns (DATA)

- [ ] **DATA-01**: Tables/data-grids stay readable under real data (long IDs/paths/atoms/emails/URLs/timestamps middle-truncate with copy + title); important columns never squish unreadably; card/list layout is used where tables don't fit (mobile / non-tabular data).
- [ ] **DATA-02**: KV/metadata, timeline/event log, detail views, status summaries, and metrics/charts read clearly, never rely on color alone, and present time as relative + absolute with timezone made clear.
- [ ] **DATA-03**: Empty/zero, loading, error, and stale states are visually distinct and explain the next action; permission-denied is distinguished from no-data and from unavailable-data.
- [x] **DATA-04**: Row actions and bulk actions are discoverable but not accidentally triggerable; destructive actions are separated and confirmed by naming the object and consequence.
- [x] **DATA-05**: The coverage "schema" section card-in-card nesting is flattened (resolves `coverage-schema-card-declutter`), and accidental nesting / table-overuse is removed system-wide.

### Component Groups / Meta-Components (GROUP)

- [x] **GROUP-01**: Recurring configurations (page-header+actions+breadcrumbs; toolbar+search+filters+sort; table+empty+loading+pagination; stat-cards+chart+table; detail-header+metadata+actions; modal-confirm+destructive; drawer+form; toast+state-update; tabs+subviews; empty+CTA; permission-denied; reconnect/offline-banner+disabled-actions) are audited as units with intentional spacing and hierarchy.
- [x] **GROUP-02**: Each group holds together across narrow and wide layouts, with states aligned across its children, and motion clarifies state transitions.

### Per-Page & Flow Stress (PAGE)

- [x] **PAGE-01**: Each of the 11 pages (Home, Timeline, Transaction, Row history, Actor, Coverage, Evidence, Redaction, Retention, Exports, plus shell) is audited against happy/empty/loading/error/permission-denied/boundary/advanced paths × dark/light/system × 320/375/768/1024/1440 × keyboard-only × reduced-motion × LiveView reconnect, with findings recorded in the ledger.
- [x] **PAGE-02**: The named footgun classes are eliminated: scroll traps, modal/drawer hidden behind scrim or floating wrong, focus not entering/restoring from overlays, escape/click-outside inconsistency, hover/focus on non-interactive elements, misalignment / chopped padding / inconsistent spacing, disabled-looks-enabled (and enabled-looks-disabled), missing tab active-state, weird pagination, unreadable dark/light text, and same-color text-on-background.
- [x] **PAGE-03**: The transaction page centers correctly at desktop widths (resolves `transaction-page-left-push-desktop`).

### Microcopy & Information Architecture (COPY)

- [ ] **COPY-01**: All UI copy follows the brand voice and avoids banned vocabulary; error/empty/success/warning/destructive copy follows the documented patterns (say what happened + how to fix; name the object + consequence; no blame).
- [ ] **COPY-02**: Domain language is used consistently across headings/tabs/filters/buttons/alerts (AuditTransaction, AuditChange, AuditAction, ActorRef, Correlation; covered/uncovered, drift detected, redaction policy, retention window, evidence, incident drill-down, actor window, row history / as-of).
- [ ] **COPY-03**: Information architecture follows least-surprise and progressive disclosure (GOV.UK lens) while preserving power-user efficiency (keyboard support, dense views, stable URLs, copyable IDs, direct links).

### Accessibility Verification (A11Y)

- [ ] **A11Y-01**: The surface meets WCAG 2.2 AA, verified by automated scans on rendered states including opened dialogs/menus/popovers AND manual keyboard + screen-reader checks; every flow is keyboard-operable with visible, non-obscured, restored focus.
- [ ] **A11Y-02**: Custom widgets follow WAI-ARIA APG patterns (dialog, tabs, menu, combobox, disclosure, tooltip, table/grid, alert, nav); color is never the only signal; touch target sizes are comfortable.

### Motion & Guardrails (MOTION)

- [ ] **MOTION-01**: Motion communicates state/continuity/feedback only, uses compositor-friendly properties, is origin-aware where applicable, avoids animating from `scale(0)`, gives responsive press feedback, and respects `prefers-reduced-motion`; extensions stay within the motion-token contract.
- [ ] **MOTION-02**: Idempotency guardrails are in place and green (expanded Playwright matrix + stress-route screenshot regression, per-component + style contract tests, brand-token parity), and an adversarial regression review is signed off (aesthetics-vs-usability, dependency/architecture weight, host-integration friction, inaccessible custom behavior, generic-template drift, screenshot-only quality).

## Future Requirements

Acknowledged but deferred; not in the v1.37 roadmap.

### Distribution / Assets

- **SOCIAL-PNG-01**: Social-card raster export — when a downstream channel requires it.

### Components

- **COMP-PUBLIC-01**: Promote the internal component set to a public, documented, host-extensible API — only on sustained adopter demand; would formally reopen the v1.31 freeze.

## Out of Scope

Explicitly excluded for v1.37. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Public / host-facing component API | Locked to **internal** components this milestone; v1.31 "no public Phoenix component API" freeze intent preserved (see COMP-PUBLIC-01 for the future path). |
| New runtime dependencies (Tailwind, PhoenixStorybook, animation libraries, asset pipeline) | The surface ships inline-only assets, CSP-safe, zero-dep; the internal stress route replaces Storybook. |
| localStorage / `<head>`-script theming | Structurally wrong for a mounted library (FOUC on dead render, dies under CSP) — rejected in 165 research; the picker is cookie + plug only. |
| Changes to the capture or semantics layers | This milestone is exploration/operations UI only; canonical persistence and action semantics are untouched. |
| Marketing / docs-site / HexDocs light themes | Handled by the brand book; HexDocs/landing remain HEXDOCS-BRAND-01 / LANDING-01 (deferred). |
| Re-recoloring or redesigning the brand identity | The v1.35 logo + v1.36 light lane are settled truth; this milestone applies the brand, it does not re-decide it. |

## Traceability

Pre-mapped to the planned phase breakdown; confirmed/finalized by the roadmapper.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DS-01 | Phase 171 | Complete |
| DS-02 | Phase 171 | Complete |
| DS-03 | Phase 171 | Complete |
| DS-04 | Phase 171 | Complete |
| DS-05 | Phase 172 | Complete |
| DS-06 | Phase 172 | Complete |
| COMP-01 | Phase 173 | Complete |
| COMP-02 | Phase 173 | Complete |
| COMP-03 | Phase 173 | Complete |
| COMP-04 | Phase 174 | Complete |
| COMP-05 | Phase 174 | Complete |
| COMP-06 | Phase 174 | Complete |
| NAV-01 | Phase 175 | Complete |
| NAV-02 | Phase 175 | Complete |
| NAV-03 | Phase 175 | Complete |
| NAV-04 | Phase 175 | Complete |
| DATA-01 | Phase 176 | In progress (176-03: display pages middle-truncate+copy; coverage/responsive in 176-04) |
| DATA-02 | Phase 176 | In progress (176-03: KV/detail/timeline + semantic <time> UTC; charts/metrics remainder later) |
| DATA-03 | Phase 176 | In progress (176-03: display-page empty/no_data/error distinct; retention states in 176-05) |
| DATA-04 | Phase 176 | Complete (176-05: T3 server-enforced prune — secure_compare + authz re-check + audit-the-action + fail-closed; kebab w/ destructive-last; no bulk multi-select; redact deferred per checkpoint) |
| DATA-05 | Phase 176 | Complete (176-04) |
| GROUP-01 | Phase 177 | Complete (177-05: 12 configs as group stress stories tagged live/reference, ledger↔fixtures↔projection parity, render across 320–1440 × dark/light/system) |
| GROUP-02 | Phase 177 | Complete (177-02 layout primitives, 177-03 data_panel/toolbar/detail_header + cross-child state coordination, 177-04 group motion + reconnect/offline) |
| PAGE-01 | Phase 178 | Complete (178-04: 11×7 fixture-backed page stories + ledger parity; 178-05: Tier B sample; 178-06: real socket-drop banner/dimming proof on `[data-phx-main]`) |
| PAGE-02 | Phase 178 | Complete |
| PAGE-03 | Phase 178 | Complete (178-03: `.tl-container` + `.tl-home` `justify-self:center`; 178-05/178-06 preservation via operator-surface suite) |
| COPY-01 | Phase 179 | Pending |
| COPY-02 | Phase 179 | Pending |
| COPY-03 | Phase 179 | Pending |
| A11Y-01 | Phase 180 | Pending |
| A11Y-02 | Phase 180 | Pending |
| MOTION-01 | Phase 180 | Pending |
| MOTION-02 | Phase 180 | Pending |

**Coverage:**

- v1 requirements: 33 total
- Mapped to phases: 33
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-14*
*Last updated: 2026-06-18 — PAGE-01/PAGE-03 closed by Phase 178 gap-closure evidence; traceability confirmed by gsd-roadmapper (ROADMAP.md created, phases 171-180, 33/33 mapped 1:1)*
