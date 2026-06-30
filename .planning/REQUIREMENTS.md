# Requirements: Threadline v1.38 Operator UI Page-by-Page IA & Design-System Polish

**Defined:** 2026-06-26
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Source:** User design-system stress-test follow-up, accepted v1.38 plan, and repository/subagent audit of the v1.37 operator surface.

**Milestone goal:** Make the mounted `/audit` operator UI feel obvious, task-led, coherent, and highly polished page by page, while preserving the v1.37 internal component system, route stability, auth boundaries, and regression guardrails.

**Invariants:** root `threadline` keeps Phoenix/LiveView optional; no capture/query/auth semantic changes; no public component API; no root Tailwind/shadcn migration; no production stress/story route; route paths, `data-testid`s, and feature gates stay stable unless a phase explicitly records and verifies a change.

## v1 Requirements

### Baseline, Research, and Guardrails

- [x] **BASE-01**: Maintainers can see a current rendered audit of every `/audit` page, with stale tests and stale selectors identified before page polish begins.
- [x] **BASE-02**: The design-system ledger, `DESIGN-SYSTEM.md`, screenshot allowlist, and E2E suites continue to ratchet upward without lowering scores or silently dropping stories.
- [x] **BASE-03**: The milestone preserves a compact research/decision record for PhoenixStorybook, `/audit/__stress`, nav IA, motion, accessibility, and operator JTBD tradeoffs.

### Storybook Dev Lane

- [x] **STORY-01**: The Phoenix example app exposes PhoenixStorybook as a dev/test maintainer component-lab lane without adding a root `threadline` dependency or production route.
- [x] **STORY-02**: Storybook stories cover the internal primitive, form, state, overlay, data-display, and recurring group components across dark/light/system and representative ugly data.
- [x] **STORY-03**: `/audit/__stress` remains the canonical authenticated operator-flow stress harness, and docs explain when to use Storybook versus the stress route.

### Shell, Navigation, and Home

- [x] **SHELL-01**: Every `/audit` page has one obvious global operator navigation surface that is visible on desktop/tablet and clearly labeled on mobile.
- [x] **SHELL-02**: Home is a focused task launcher, not an info dump: it exposes the top operator jobs, system status, and direct investigation entrypoints with deliberate hierarchy and no redundant generic CTAs.
- [x] **SHELL-03**: Active nav state, feature-gated destinations, skip link, theme picker, and topbar status are discoverable, accessible, and stable across dark/light/system and 320-1440px viewports.

### Timeline Investigation Flow

- [x] **TIME-01**: Timeline presents one clear investigation workflow: filter, scan, open transaction or row history, and export the current view.
- [x] **TIME-02**: Timeline controls, pager, saved-view affordances, empty/loading/error/stale states, long values, and mobile layouts remain readable and keyboard-operable under ugly real data.
- [x] **TIME-03**: Timeline copy and micro-interactions are concise, on-brand, and useful under incident pressure without creating decorative motion or layout jumps.

### Coverage and Audit Readiness

- [x] **COV-01**: Coverage renders one primary readiness verdict for the selected schema, with schema scope and checked-at metadata visible and URL-addressable.
- [x] **COV-02**: Coverage removes repeated readiness copy and duplicate cross-surface CTAs, leaving contextual row actions and one clear remediation path.
- [x] **COV-03**: Coverage schema selection, invalid-schema errors, non-public schema row links, refresh behavior, and docs remain correct and regression-guarded.

### Detail, Governance, and Export Surfaces

- [x] **DETAIL-01**: Transaction, row-history, and actor pages use the same detail-header, metadata, copy/ref, drawer, and state patterns as the cleaned Timeline flow.
- [x] **GOV-01**: Evidence, Exports, Redaction, and Retention pages read as focused operator workflows rather than dense metadata dumps.
- [x] **GOV-02**: Export/download affordances, feature-gated controls, and disabled states are correct for pointer, keyboard, and assistive-technology users.
- [x] **GOV-03**: Retention destructive actions keep the type-to-confirm, auth re-check, audit-the-action, reconnect-safe disabled state, focus restore, and object/consequence copy; the runtime redaction destructive flow remains deferred unless explicitly rescoped.

### Accessibility, Motion, Docs, and Closeout

- [x] **A11Y-01**: Custom controls follow the relevant APG behavior, including keyboard support for menus, tabs, segmented controls, dialogs, drawers, disclosures, tooltips, and copy controls.
- [x] **A11Y-02**: Keyboard-only users can complete the primary investigation, readiness, export, and retention flows with visible non-obscured focus and correct focus restoration.
- [x] **MOTION-01**: Motion remains token-backed, fast, transform/opacity-oriented, purposeful, and reduced-motion aware; no new decorative animation or `transition: all` enters the operator surface.
- [x] **DOC-01**: Operator docs match the implementation for runtime theme picker, Storybook dev lane, stress route, mount/auth/export gates, schema selection, CSP expectations, and production exclusions.
- [x] **CLOSE-01**: Final closeout includes current verification evidence, screenshot/Playwright guard status, residual failure ownership if any, and adversarial review across operator, accessibility, OSS maintainer, and host-app DX lenses.

## Future Requirements

Deferred to future milestones unless explicit adopter or maintainer demand appears.

### Public Component API

- **COMP-PUBLIC-01**: Promote internal operator components to a public documented API.

### Storybook Distribution

- **STORY-PUBLIC-01**: Publish a standalone component-docs package or public Storybook deployment.

### Runtime Destructive Redaction

- **REDACT-RUNTIME-01**: Add an audited runtime redaction destructive flow after capture/storage semantics are explicitly scoped.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Root `threadline` dependency on PhoenixStorybook | Would narrow the optional Phoenix/LiveView matrix and make component docs part of the host-facing dependency graph. |
| Public component API | v1.38 improves the private operator system and maintainer examples only. |
| Capture/query/auth semantics changes | This milestone is UI/IA/design-system work over the existing operator surface. |
| Route churn for `/audit` pages | Stable URLs, direct links, and tests are part of the operator power-user contract. |
| Marketing site, HexDocs theme, or brand identity redesign | Brand identity is settled; this milestone applies it to the product UI. |
| Real screen-reader certification claim | Browser accessibility-tree and keyboard evidence are useful, but real assistive-technology UAT must be explicitly run before claiming it. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BASE-01 | Phase 181 | Complete |
| BASE-02 | Phase 181 | Complete |
| BASE-03 | Phase 181 | Complete |
| STORY-01 | Phase 182 | Complete |
| STORY-02 | Phase 182 | Complete |
| STORY-03 | Phase 182 | Complete |
| SHELL-01 | Phase 183 | Complete |
| SHELL-02 | Phase 183 | Complete |
| SHELL-03 | Phase 183 | Complete |
| TIME-01 | Phase 184 | Complete |
| TIME-02 | Phase 184 | Complete |
| TIME-03 | Phase 184 | Complete |
| COV-01 | Phase 185 | Complete |
| COV-02 | Phase 185 | Complete |
| COV-03 | Phase 185 | Complete |
| DETAIL-01 | Phase 186 | Complete |
| GOV-01 | Phase 186 | Complete |
| GOV-02 | Phase 186 | Complete |
| GOV-03 | Phase 186 | Complete |
| A11Y-01 | Phase 187 | Complete |
| A11Y-02 | Phase 187 | Complete |
| MOTION-01 | Phase 187 | Complete |
| DOC-01 | Phase 187 | Complete |
| CLOSE-01 | Phase 187 | Complete |

**Coverage:**

- v1 requirements: 24 total
- Mapped to phases: 24
- Unmapped: 0

---
*Requirements defined: 2026-06-26*
*Last updated: 2026-06-26 after v1.38 milestone initialization*
