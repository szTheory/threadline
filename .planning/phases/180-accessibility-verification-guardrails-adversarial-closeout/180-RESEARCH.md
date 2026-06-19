# Phase 180: Accessibility Verification, Guardrails & Adversarial Closeout - Research

**Researched:** 2026-06-19  
**Domain:** Phoenix LiveView operator UI accessibility, motion, browser verification, and milestone closeout guardrails  
**Confidence:** HIGH for local code/test inventory, MEDIUM for external standards references

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use a **layered proof model** instead of trying to manually inspect every theoretical state. Tier A is automated and broad: ExUnit/style/component/stress contracts plus axe-like browser checks on representative rendered states. Tier B is real-engine browser coverage: opened overlays, disclosures, keyboard paths, reduced motion, light/dark/system, and stress-route screenshot/geometry guards. Tier C is explicit manual evidence: keyboard and screen-reader notes for the small set of flows automation cannot honestly judge. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- **D-02:** The final Phase 180 report must state exactly what each tier proves. Do not let green automation imply that every page/state/theme/viewport was manually reviewed. Use the Phase 178 honesty pattern: full structural coverage where deterministic, representative browser coverage where high-signal, and small manual assistive-tech records where required by A11Y-01. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- **D-03:** Prefer extending existing specs over creating a parallel audit harness. The primary browser files are `operator-accessibility.spec.ts`, `operator-motion.spec.ts`, `operator-phase-178-uat.spec.ts`, `operator-stress.spec.ts`, `operator-screenshot-regression.spec.ts`, and targeted per-flow specs. The primary ExUnit gates are `style_contract_test.exs`, `component_contract_test.exs`, `ui_test.exs`, `stress_fixtures_test.exs`, `stress_ledger_test.exs`, `stress_router_test.exs`, and the rendered page tests. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- **D-04:** Treat A11Y-01 as a **rendered-state claim**, not a source-only claim. Plans should open the states that matter: modal/dialog, drawer, dropdown/menu, tabs, disclosure/accordion, combobox/select/search controls, error summary, permission/unavailable/alert states, stale/status banners, table/list/data panels, shell nav, mobile nav, and stress-route state stories. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- **D-05:** Manual keyboard and screen-reader evidence is required but bounded. Record deterministic checklists as artifacts: keyboard traversal, focus visibility, focus entry/restore, Escape/click-outside behavior, and a screen-reader smoke pass for landmark/headings/labels/status/alert announcements. Do not require subjective full human UAT unless an automated or manual check finds a gap. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- **D-06:** Fixes must preserve dense operator workflows. If an accessibility issue conflicts with power-user efficiency, resolve by improving semantics/focus/labels rather than hiding controls, removing direct links, or adding novice/expert modes. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- **D-07:** APG checks should map to the actual implementation, not a generic widget list. Dialog/drawer/modal behavior comes from `UI.modal/1`, `UI.drawer/1`, and real retention/row-history overlays. Menus/dropdowns, tabs, segmented controls, accordions/disclosures, combobox/search/date/number fields, and data tables each need targeted assertions or documented non-applicability. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- **D-08:** Motion is allowed only where it communicates state, continuity, or feedback. Audit existing transitions against the Phase 177 rules: transform/opacity only, token durations/easing, origin-aware overlays/drawers/dropdowns, no `scale(0)`, no high-frequency stream-row animations, and immediate collapse under `prefers-reduced-motion`. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- **D-09:** Press feedback belongs on genuinely interactive controls only. Do not add hover/focus affordances to non-interactive elements while closing motion gaps. Disabled controls must look and behave disabled. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- **D-10:** The motion closeout should prefer measurable checks: computed transition properties, reduced-motion duration collapse, overlay origin transforms, responsive pressed/active states, and absence of banned transform patterns in `style.ex`. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- **D-11:** Phase 180 is the final idempotency gate for v1.37. The plan must run or extend the existing guardrails: brand-token parity, style contracts, component contracts, stress ledger/projection parity, stress route auth/prod gates, screenshot allowlist/baseline checks, copy contracts, and touched Playwright matrix. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- **D-12:** The adversarial review is a written artifact, not just a green test suite. It should cover aesthetics-vs-usability, dependency/architecture weight, host integration friction, inaccessible custom behavior, generic-template drift, screenshot-only quality, route/API stability, and whether residual `mix ci.all` failures are in or out of scope. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- **D-13:** Treat the old `coverage-schema-card-declutter` todo as a **regression check only**. Phase 176 already flattened that card shell; Phase 180 should verify no card-in-card or accessibility regression reappeared, not add new coverage-page layout scope. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- **D-14:** If `mix ci.all` still fails, Phase 180 must classify failures explicitly. Failures in Phase 180-owned accessibility, motion, guardrail, stress, copy, component, route, or rendered operator flows block closeout. Inherited charter/demo seed failures already documented in Phase 179 may remain non-blocking only if verified unchanged and still outside Phase 180's requirements. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]

### the agent's Discretion
- Exact plan slicing is open, but a conservative split is: accessibility/browser audit; APG/component semantics; motion/reduced-motion audit; guardrail/screenshot/adversarial closeout. Keep fixes narrow and paired with failing checks. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
- **Coverage "schema: public" card de-clutter** (`coverage-schema-card-declutter.md`) — fold only as an adversarial regression check. Do not reopen layout polish unless Phase 180 verification proves a current accessibility/card-nesting regression. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- New operator capabilities, new filters, new exports, novice/expert mode, and full i18n/copy registries remain out of scope. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- Coverage schema card declutter is not reopened as design scope; it is only a regression check because Phase 176 already flattened that surface. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- Broad visual redesign and marketing-polish review are out of scope unless an accessibility or guardrail test proves a current blocking defect. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
</user_constraints>

## Summary

Phase 180 should be a verification and closeout phase, not a redesign phase: the operator UI already has reusable semantic primitives, style contracts, stress routes, screenshot guardrails, and Playwright flows that should be extended rather than replaced. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts] [VERIFIED: test/threadline/operator_surface/component_contract_test.exs]

The strongest plan is a layered proof model: broad contracts catch source and component drift; browser tests open real rendered states and verify focus, keyboard, names, geometry, reduced motion, and computed motion values; final written evidence separates automated proof from bounded manual keyboard/screen-reader judgement. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md] [CITED: https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/] [CITED: https://playwright.dev/docs/api/class-page]

**Primary recommendation:** extend `operator-accessibility.spec.ts`, `operator-motion.spec.ts`, `component_contract_test.exs`, and `style_contract_test.exs`; close with a written adversarial review and residual `mix ci.all` ownership classification, without adding new runtime dependencies or a separate harness. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md] [VERIFIED: mix.exs]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| A11Y-01 | WCAG 2.2 AA verification with automated scans on rendered states and bounded manual keyboard/screen-reader evidence. | Use existing Playwright role, keyboard, focus, geometry, and rendered overlay helpers in `operator-accessibility.spec.ts` plus manual evidence in the final verification artifact. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts] |
| A11Y-02 | Custom widgets follow APG where applicable; color is not the only signal; touch targets are comfortable. | Map APG patterns only to actual Threadline widgets and verify native alternatives as non-applicable; reuse `component_contract_test.exs`, `style_contract_test.exs`, `surface_header.ex`, and UI component contracts. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: test/threadline/operator_surface/component_contract_test.exs] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/] |
| MOTION-01 | Motion communicates state/continuity/feedback, uses safe transforms, avoids `scale(0)`, respects reduced motion, and stays within token contracts. | Extend computed-style assertions in `operator-motion.spec.ts` and source-token contracts in `style_contract_test.exs`; keep `scale(0.96)` press feedback allowed under no-preference and verify reduced-motion collapse. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts] [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] |
| MOTION-02 | Guardrails green and adversarial regression review signed off. | Run existing style/component/stress/screenshot/copy/browser guardrails, classify residual `mix ci.all` failures, and write closeout evidence that separates inherited failures from Phase 180 regressions. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/179-microcopy-information-architecture-sweep/179-VERIFICATION.md] |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Visible names, landmarks, headings, skip link, native form semantics | Phoenix LiveView rendered markup | Browser / Client verification | `UI.page_header`, `UI.field`, `SurfaceHeader`, and rendered templates own markup; Playwright verifies the accessible surface after LiveView renders it. [VERIFIED: lib/threadline/operator_surface/ui.ex] [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] |
| Modal, drawer, dropdown, disclosure, tabs, tooltip behavior | Phoenix LiveView UI components | Browser / Client verification | Components emit roles, ARIA, JS focus commands, and open/close hooks; Playwright must verify opened states, keyboard behavior, and focus restoration in a real browser. [VERIFIED: lib/threadline/operator_surface/ui.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html] |
| Motion tokens, reduced-motion collapse, transform safety | CSS / style layer | Browser computed-style checks | `style.ex` and `style_contract_test.exs` own source/token policy; Playwright verifies computed duration, delay, easing, transform, and reduced-motion behavior. [VERIFIED: lib/threadline/operator_surface/style.ex] [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] |
| Stress routes and screenshot guardrails | Test harness / planning artifacts | Browser / Client verification | Stress ledger and screenshot specs already define edge-state fixtures and bounded screenshot coverage; Phase 180 should reuse them for regression proof. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts] |
| Closeout classification | Planning / verification artifacts | Mix and Playwright commands | Phase 179 documents inherited `ci.all` failures; Phase 180 must rerun and classify only new/owned failures as blocking. [VERIFIED: .planning/phases/179-microcopy-information-architecture-sweep/179-VERIFICATION.md] [VERIFIED: .planning/phases/179-microcopy-information-architecture-sweep/deferred-items.md] |

## Project Constraints

- No top-level `AGENTS.md` was found in `/Users/jon/projects/threadline`; a nested Phoenix example `AGENTS.md` exists under `examples/threadline_phoenix` and is contextual guidance for that example app. [VERIFIED: AGENTS.md absence via filesystem audit] [VERIFIED: examples/threadline_phoenix/AGENTS.md]
- Phase 180 must not add public component API surface, new runtime dependencies, or theme architecture changes because the v1.37 milestone locks those invariants. [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/PROJECT.md]
- The existing Phoenix example harness uses Mix aliases and Playwright scripts rather than a separate browser runner; `mix.exs` exposes `verify.example_browser`, `verify.example_browser_light`, `verify.operator_stress`, and `ci.all`. [VERIFIED: mix.exs]
- Threadline brand guidance requires calm, non-hype copy and non-color-only signals for UI status; Phase 180 should verify those properties rather than rewriting copy. [VERIFIED: brandbook/brand-book.md]

## Existing Assets And Reuse Map

| Asset | Reuse For | Why It Matters |
|-------|-----------|----------------|
| `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` | A11Y rendered-state, names, focus, skip link, modal/drawer checks. | Already has `login`, `expectFocused`, overflow checks, mobile nav, advanced filters, retention modal, row-history drawer, status/verdict non-color checks. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts] |
| `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` | MOTION-01 computed-style proof. | Already asserts default and reduced-motion durations, delays, drawer transform safety, and policy details motion collapse. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts] |
| `examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts` | Guardrail continuity and honest proof model. | Encodes Tier A/Tier B wording, overlay footgun checks, keyboard-only sample, reduced-motion sample, real socket-drop proof, and reconnect banner behavior. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts] |
| `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` | Stress route edge-state coverage and screenshot allowlist guardrails. | Verifies auth, route resilience, metadata, responsive widths, future reserved cases, CI screenshot allowlist, and `footgun.coverage-schema-card-declutter` as reserved regression coverage. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts] |
| `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` | Local visual regression evidence. | Provides local-only screenshots for Home, dense Timeline, row-history drawer, exports, and retention with masks; useful as closeout evidence but not as the only quality proof. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts] |
| `test/threadline/operator_surface/style_contract_test.exs` | Source-level motion, contrast, theme, focus, token, and anti-pattern guardrails. | Locks motion tokens, keyframes, reduced-motion block, contrast ratios, focus ring contrast, disabled/active states, and card-declutter source guard. [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] |
| `test/threadline/operator_surface/component_contract_test.exs` | Component semantics, data states, overlay and reconnect contracts. | Covers loading/status/alert/data-state semantics, toolbar disabled affordances, overlay z-index, Escape/click-away markers, reconnect selectors, active nav non-color cues, and pager behavior. [VERIFIED: test/threadline/operator_surface/component_contract_test.exs] |
| `test/threadline/operator_surface/ui_test.exs` | Rendered component unit contracts. | Should remain the first stop for component-level semantic regressions before adding browser coverage. [VERIFIED: test/threadline/operator_surface/ui_test.exs] |
| `test/threadline/operator_surface/card_nesting_regression_test.exs` | Regression-only proof for `coverage-schema-card-declutter`. | Renders operator pages and prevents nested card-family classes; Phase 180 should keep this as a regression check rather than reopening layout design. [VERIFIED: test/threadline/operator_surface/card_nesting_regression_test.exs] |
| `lib/threadline/operator_surface/ui.ex` | Component source of truth. | Provides internal UI primitives for buttons, tables, alerts, data panels, modals, drawers, dropdowns, tabs, accordion, tooltip, popover, forms, shell, and reconnect banner. [VERIFIED: lib/threadline/operator_surface/ui.ex] |
| `lib/threadline/operator_surface/components/surface_header.ex` | Shell navigation, skip link, theme picker, mobile nav. | Uses skip link, labelled banner/nav, `aria-current`, grouped nav headings, and native radio theme picker controls. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] |
| `lib/threadline/operator_surface/style.ex` | CSS tokens and runtime styles. | Owns focus-visible treatment, hit area, button press feedback, overlay motion classes, reconnect selectors, and reduced-motion collapse. [VERIFIED: lib/threadline/operator_surface/style.ex] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | Elixir 1.19.5, Mix 1.19.5 | ExUnit contracts, Phoenix example verification, `ci.all`. | Already installed and wired into project aliases. [VERIFIED: local environment probe] [VERIFIED: mix.exs] |
| Phoenix LiveView / `Phoenix.LiveView.JS` | Project dependency, version resolved by Mix | DOM-patch-aware JS commands, transitions, focus helpers, LiveView rendered components. | Existing UI components use `JS.show`, `JS.hide`, `JS.focus_first`, and `JS.pop_focus`; LiveView docs define these as composable JS commands. [VERIFIED: lib/threadline/operator_surface/ui.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html] |
| Playwright | 1.60.0 installed in e2e workspace | Browser role locators, keyboard paths, screenshots, computed styles, reduced-motion emulation. | Existing e2e harness and specs already use Playwright projects and reduced-motion defaults. [VERIFIED: local environment probe] [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts] |
| WAI-ARIA APG + WCAG 2.2 | Current W3C references | Pattern and success-criteria reference for manual and automated checks. | Dialog, tabs, disclosure, keyboard, focus, and target-size guidance should map to actual widgets rather than generic checklists. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/] [CITED: https://www.w3.org/TR/WCAG22/] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Existing stress ledger and stress route | Project-owned | Render edge states and fixture-backed screenshots. | Use for status banners, empty/error/permission/unavailable states, responsive edge cases, and `coverage-schema-card-declutter` regression. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts] |
| Existing screenshot regression spec | Project-owned | Local visual evidence. | Use after semantic/motion checks pass; do not treat screenshots as accessibility proof. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts] |
| Brand token/style contracts | Project-owned | Theme, contrast, focus, motion, and copy style guardrails. | Run before final closeout and whenever style assertions change. [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] [VERIFIED: brandbook/brand-book.md] |

**Installation:** none. Phase 180 should not install external packages because the existing harness already has Playwright and Mix contracts, and v1.37 locks zero new runtime dependencies. [VERIFIED: examples/threadline_phoenix/e2e/package.json] [VERIFIED: .planning/STATE.md]

## Package Legitimacy Audit

No new external package is recommended for Phase 180. [VERIFIED: examples/threadline_phoenix/e2e/package.json] If execution later proposes `axe-core` or a Playwright axe wrapper, planner should add a human checkpoint because no such package is currently present and the phase can satisfy its requirements with existing browser and contract checks. [VERIFIED: examples/threadline_phoenix/e2e/package.json]

## Accessibility/APG Strategy

### Layered Proof

| Tier | Proof Type | Concrete Coverage |
|------|------------|-------------------|
| Tier A | Broad automated contracts | Run `style_contract_test.exs`, `component_contract_test.exs`, `ui_test.exs`, stress fixture/ledger/router tests, and targeted rendered page tests to catch source, semantics, contrast, motion-token, and fixture drift. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md] |
| Tier B | Real rendered browser checks | Extend Playwright specs to open overlays/disclosures/widgets, assert role/name/focus/keyboard/geometry/reduced-motion/computed-style behavior across representative routes and themes. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts] [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts] |
| Tier C | Bounded manual judgement | Record keyboard and screen-reader smoke evidence for representative flows, with pass/fail/notes and explicit limits on what was not manually reviewed. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md] |

### APG Mapping To Actual Threadline Widgets

| Pattern | Threadline Implementation | Phase 180 Check |
|---------|---------------------------|-----------------|
| Dialog / modal / drawer | `UI.modal`, `UI.drawer`, retention/prune modal, row-history drawer. [VERIFIED: lib/threadline/operator_surface/ui.ex] | Verify `role="dialog"`, accessible name, modal state where applicable, initial focus, trapped/reachable tab sequence for modal flows, Escape close, click-away/scrim close, and focus restoration. APG modal dialogs expect focus to stay inside the dialog and Escape to close. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] |
| Disclosure / accordion | Timeline advanced filters, policy details, `UI.accordion`, native shell `details`. [VERIFIED: lib/threadline/operator_surface/ui.ex] [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] | Verify button/summary names, expanded/collapsed state, keyboard activation, and content visibility; prefer native `details` semantics where already used. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/] |
| Tabs / segmented controls | `UI.tabs` and `UI.segmented_control`. [VERIFIED: lib/threadline/operator_surface/ui.ex] | Test only where rendered in actual operator flows; verify selected state, panel linkage, and keyboard behavior or document non-applicability if used as static reference. APG tabs define focus movement and arrow-key behavior for custom tablists. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/] |
| Dropdown / menu | `UI.dropdown` and any rendered operator menu usage. [VERIFIED: lib/threadline/operator_surface/ui.ex] | Verify menu trigger name/state and item roles only where the dropdown behaves as a menu; if it renders ordinary links/buttons, document the actual native interaction instead of forcing menu semantics. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/] |
| Combobox / select / search | Native form fields, select/search/date/number controls. [VERIFIED: lib/threadline/operator_surface/ui.ex] | Verify labels, descriptions, errors, and keyboard operation; document custom combobox as non-applicable unless a custom combobox exists in rendered UI. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/] |
| Tooltip / popover | `UI.tooltip`, `UI.popover`. [VERIFIED: lib/threadline/operator_surface/ui.ex] | Verify `aria-describedby`/role linkage for tooltips, ensure no critical action is hover-only, and verify popover name/focus behavior based on whether it is modal or non-modal. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/] |
| Table / grid | `UI.data_table` uses native table semantics. [VERIFIED: lib/threadline/operator_surface/ui.ex] | Verify table captions/headers and keyboard reachability; do not add `role="grid"` unless the table becomes an interactive grid. [VERIFIED: lib/threadline/operator_surface/ui.ex] |
| Alert / status / stale / loading | `UI.alert`, `UI.loading_state`, `UI.error_state`, `UI.stale_banner`, `UI.reconnect_banner`, `UI.data_state`. [VERIFIED: lib/threadline/operator_surface/ui.ex] | Verify `role="alert"` or `role="status"` as appropriate, visible text labels, non-color-only signal, and no focus theft except intentional error-summary focus rescue. [VERIFIED: test/threadline/operator_surface/component_contract_test.exs] |
| Navigation / headings / landmarks | `SurfaceHeader`, `UI.page_header`, shell `<main id="tl-main">`. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] [VERIFIED: lib/threadline/operator_surface/ui.ex] | Verify skip link target, one useful page H1, labelled nav regions, `aria-current`, mobile nav keyboard path, and focus not obscured after route changes or overlay close. WCAG 2.2 includes focus visibility and focus-not-obscured criteria. [CITED: https://www.w3.org/TR/WCAG22/] |

### Acceptance Evidence

- A11Y-01 should produce automated browser evidence for every rendered-state category listed in D-04, with each category either checked by a named spec assertion or documented as non-applicable to current rendered UI. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- A11Y-01 manual evidence should be bounded to representative keyboard and screen-reader smoke flows and should explicitly state what automation covered versus what human judgement covered. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- A11Y-02 should prefer component/source contracts for static semantics and Playwright for behavior that only exists after opening or interacting with rendered widgets. [VERIFIED: test/threadline/operator_surface/component_contract_test.exs] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts]

## Motion Strategy

| Motion Property | Concrete Check | Acceptance Evidence |
|-----------------|----------------|---------------------|
| Duration and delay tokens | Use `operator-motion.spec.ts` computed-style helpers to verify expected 0.12s, 0.18s, 0.24s, and reduced 0.001s/0s values where classes render. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts] | Browser assertions name the selector, route, viewport, and reduced-motion state. |
| Easing and transition properties | Assert overlay/feedback transitions stay on transform/opacity/background/border/box-shadow as appropriate, not layout-affecting properties or `transition: all`. [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] | Source contract plus representative computed-style assertion. |
| Reduced-motion collapse | Verify `prefers-reduced-motion: reduce` collapses animation/transition duration and removes active button transforms. [VERIFIED: lib/threadline/operator_surface/style.ex] [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] | Existing reduced-motion Playwright project defaults plus explicit spec checks. [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts] |
| No `scale(0)` | Add a source-level banned-pattern check for `scale(0)` while preserving existing allowed `scale(0.96)` press feedback under no-preference. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md] [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] | Style contract proves no zero-scale disappear/reappear pattern. |
| Press feedback | Verify active controls have perceptible pressed/active feedback and disabled controls do not animate or imply clickability. [VERIFIED: lib/threadline/operator_surface/style.ex] [VERIFIED: test/threadline/operator_surface/component_contract_test.exs] | Source contract plus browser check on at least one enabled button and one disabled control. |
| High-frequency rows | Verify stream/list/table rows do not animate repeatedly during dense updates. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md] | Source grep/contract plus stress-route browser sample. |

## Guardrail And Adversarial Closeout Strategy

- Run existing guardrails instead of inventing new gates: style contracts, component contracts, UI tests, stress fixture/ledger/router tests, browser accessibility, browser motion, Phase 178 UAT continuity, stress route, screenshot regression where appropriate, and `mix ci.all`. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md] [VERIFIED: mix.exs]
- Treat `coverage-schema-card-declutter` as regression-only: keep `card_nesting_regression_test.exs` and stress reserved-case proof, but do not reopen design work unless those checks fail. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md] [VERIFIED: test/threadline/operator_surface/card_nesting_regression_test.exs]
- Final closeout must include an adversarial review artifact or verification section covering aesthetics-vs-usability, architecture/dependency weight, host integration friction, custom-widget accessibility, generic-template drift, screenshot-only quality risk, route/API stability, and residual CI classification. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- Residual `mix ci.all` failures inherited from Phase 179 are known: one root charter doc-contract failure and seven example/demo seed or walkthrough failures; they remain non-blocking only if unchanged and outside A11Y-01/A11Y-02/MOTION-01/MOTION-02. [VERIFIED: .planning/phases/179-microcopy-information-architecture-sweep/179-VERIFICATION.md] [VERIFIED: .planning/phases/179-microcopy-information-architecture-sweep/deferred-items.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Accessibility browser harness | A second test runner or standalone crawler. | Existing Playwright specs and Mix aliases. | Current harness already manages DB, server, browser projects, reduced motion, screenshots, and route login. [VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh] [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts] |
| APG widget checklist | Generic checklist detached from implementation. | Actual widget map from `ui.ex` and rendered flows. | Context requires testing real implementation and documenting non-applicability for native/non-custom controls. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md] |
| Motion engine | New animation library or bespoke runtime. | CSS tokens, LiveView JS transition commands, computed-style checks. | Existing contracts reject animation libraries and ungoverned durations. [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] |
| Contrast parser | A new parser. | Existing `style_contract_test.exs` contrast helpers. | Existing tests already parse tokens, rgba, compositing, and focus-ring contrast. [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] |
| Screenshot-only quality gate | Visual snapshots as the only proof. | Semantic/contracts/browser behavior plus screenshots. | Phase 180 requires WCAG/APG/keyboard/motion evidence that screenshots cannot prove. [VERIFIED: .planning/REQUIREMENTS.md] |

## Common Pitfalls

### Pitfall 1: Source-Only Accessibility Claims
**What goes wrong:** source contracts pass while opened dialogs, drawers, filters, or mobile nav have broken focus or names.  
**Mitigation:** every D-04 rendered state needs either a Playwright assertion or a documented non-applicability note. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]

### Pitfall 2: Generic APG Enforcement
**What goes wrong:** tests require combobox/menu/grid behavior where Threadline uses native select, links, or tables.  
**Mitigation:** map APG only to custom widgets and document native/non-applicable cases. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/]

### Pitfall 3: Banning All Scale Instead Of `scale(0)`
**What goes wrong:** a broad transform ban removes existing button press feedback that the style contract intentionally preserves.  
**Mitigation:** ban `scale(0)` specifically; keep `scale(0.96)` under no-preference and verify reduced-motion resets active transforms. [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] [VERIFIED: lib/threadline/operator_surface/style.ex]

### Pitfall 4: Reduced-Motion False Confidence
**What goes wrong:** Playwright defaults to reduced motion, so default animation behavior is under-tested.  
**Mitigation:** run explicit no-preference/default computed-style checks and explicit reduced-motion checks in `operator-motion.spec.ts`. [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts]

### Pitfall 5: Residual CI Ownership Drift
**What goes wrong:** inherited Phase 179 failures are treated as Phase 180 blockers, or new Phase 180 failures are dismissed as inherited.  
**Mitigation:** capture exact residual failure file/test names and compare against the Phase 179 baseline. [VERIFIED: .planning/phases/179-microcopy-information-architecture-sweep/179-VERIFICATION.md]

### Pitfall 6: Reopening Closed Layout Work
**What goes wrong:** `coverage-schema-card-declutter` becomes new design scope rather than regression verification.  
**Mitigation:** rely on `card_nesting_regression_test.exs` and stress reserved-case checks unless they fail. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md] [VERIFIED: test/threadline/operator_surface/card_nesting_regression_test.exs]

## Recommended Plan Slicing

1. **Plan 180-01: Accessibility Rendered-State Audit (A11Y-01)**  
   Extend `operator-accessibility.spec.ts` around existing helpers; open D-04 states; assert roles, names, keyboard reachability, focus visibility/restoration, no horizontal overflow, landmarks, headings, mobile nav, and status/error states. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts]

2. **Plan 180-02: APG Component Semantics And Non-Color Guardrails (A11Y-02)**  
   Extend `component_contract_test.exs`, `ui_test.exs`, and targeted Playwright checks only where behavior is rendered; document native/non-applicable widgets; verify touch target and non-color-only signals. [VERIFIED: test/threadline/operator_surface/component_contract_test.exs] [VERIFIED: brandbook/brand-book.md]

3. **Plan 180-03: Motion And Reduced-Motion Contract (MOTION-01)**  
   Extend `style_contract_test.exs` and `operator-motion.spec.ts`; assert token durations/easing, reduced-motion collapse, no `scale(0)`, disabled-control stillness, enabled press feedback, and no high-frequency row animation. [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts]

4. **Plan 180-04: Guardrail Matrix, Residual CI Classification, And Adversarial Closeout (MOTION-02)**  
   Run the targeted matrix, local screenshot regression where useful, stress route, light/system lane, and `mix ci.all`; classify inherited failures against Phase 179 and write closeout/adversarial evidence. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/179-microcopy-information-architecture-sweep/179-VERIFICATION.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit contracts and Mix aliases | Yes | 1.19.5 | None needed. [VERIFIED: local environment probe] |
| Mix | Project verification aliases | Yes | 1.19.5 | None needed. [VERIFIED: local environment probe] |
| Node.js | Playwright e2e workspace | Yes | v22.14.0 | None needed. [VERIFIED: local environment probe] |
| npm | Playwright dependency runner | Yes | 11.1.0 | None needed. [VERIFIED: local environment probe] |
| Playwright | Browser accessibility/motion checks | Yes | 1.60.0 via `npx playwright --version` in e2e workspace | None needed. [VERIFIED: local environment probe] |
| PostgreSQL | Phoenix example DB-backed browser flows | Yes | `pg_isready` accepted `/tmp:5432` | Existing e2e script creates/resets/migrates DB. [VERIFIED: local environment probe] [VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh] |

**Missing dependencies with no fallback:** none found. [VERIFIED: local environment probe]

**Missing dependencies with fallback:** none found. [VERIFIED: local environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Frameworks | ExUnit via Mix; Playwright browser specs via `examples/threadline_phoenix/e2e`. [VERIFIED: mix.exs] [VERIFIED: examples/threadline_phoenix/e2e/package.json] |
| Config files | `mix.exs`, `examples/threadline_phoenix/e2e/playwright.config.ts`. [VERIFIED: mix.exs] [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts] |
| Quick contract command | `mix test test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/card_nesting_regression_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/stress_router_test.exs` [VERIFIED: test/threadline/operator_surface] |
| Browser A11Y command | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts` [VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh] |
| Browser motion command | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-motion.spec.ts` [VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh] |
| Guardrail continuity command | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-phase-178-uat.spec.ts tests/operator-stress.spec.ts` [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts] |
| Light/system browser lane | `THREADLINE_E2E_THEME=system ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts tests/operator-motion.spec.ts tests/operator-stress.spec.ts` [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts] |
| Local screenshot evidence | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshot-regression.spec.ts` because that spec is local-only and skips CI. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts] |
| Full suite command | `mix ci.all`, followed by residual failure classification against Phase 179. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/179-microcopy-information-architecture-sweep/179-VERIFICATION.md] |

### Phase Requirements To Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| A11Y-01 | Rendered states, keyboard operation, visible/non-obscured/restored focus, landmarks/headings, names, manual keyboard/SR evidence. | Playwright + manual closeout evidence | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts` plus final manual evidence section/artifact. | Yes for automation; manual evidence created during execution. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts] |
| A11Y-02 | APG-aligned custom widgets, native/non-applicable mapping, non-color-only status, touch targets. | ExUnit component/style + Playwright behavior | `mix test test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/style_contract_test.exs` and targeted `operator-accessibility.spec.ts`. | Yes. [VERIFIED: test/threadline/operator_surface/component_contract_test.exs] |
| MOTION-01 | Tokened durations/easing, compositor-friendly properties, no `scale(0)`, reduced-motion collapse, enabled/disabled press feedback. | ExUnit style contract + Playwright computed style | `mix test test/threadline/operator_surface/style_contract_test.exs` and `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-motion.spec.ts`. | Yes. [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts] |
| MOTION-02 | Existing guardrails green, screenshot/stress/copy contracts intact, adversarial review, residual `ci.all` ownership classification. | Mix full suite + targeted browser + written closeout | `mix ci.all`, `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-phase-178-uat.spec.ts tests/operator-stress.spec.ts`, optional local screenshot spec. | Yes for automation; closeout evidence created during execution. [VERIFIED: mix.exs] |

### Sampling Rate

- **Per implementation task:** run the smallest affected contract/spec command above and keep failure output tied to the plan slice. [VERIFIED: .planning/config.json]
- **Per wave merge:** run the quick contract command plus the affected browser spec. [VERIFIED: mix.exs]
- **Phase gate:** run the full targeted matrix, light/system lane for changed browser specs, optional local screenshot evidence, then `mix ci.all` with residual classification. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]

### Wave 0 Gaps

- No new test framework is needed. [VERIFIED: examples/threadline_phoenix/e2e/package.json]  
- `operator-accessibility.spec.ts` needs additional rendered-state coverage for tabs/dropdowns/disclosures/error-summary/status/mobile/stress states as applicable. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts]  
- `operator-motion.spec.ts` needs additional checks for easing/transition properties, `scale(0)` absence, enabled/disabled press feedback, and high-frequency row animation absence. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts]  
- Final execution should create verification/adversarial/manual evidence artifacts, but this research phase writes only this `180-RESEARCH.md` artifact per user constraint. [VERIFIED: user request]

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No new auth behavior | Preserve fail-closed operator auth and do not turn client-visible states into authorization checks. [VERIFIED: .planning/STATE.md] |
| V3 Session Management | No new session behavior | Browser tests should use existing login helpers and not alter session architecture. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts] |
| V4 Access Control | Yes for operator stress and routes | Keep stress route auth/prod gates in existing stress tests. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts] |
| V5 Input Validation | Yes for filters/forms | Verify labels/errors/help text while preserving existing server-side validation behavior. [VERIFIED: lib/threadline/operator_surface/ui.ex] |
| V6 Cryptography | No | No crypto changes are in Phase 180 scope. [VERIFIED: .planning/REQUIREMENTS.md] |

## State Of The Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Closed-state-only accessibility checks | Opened rendered-state checks for overlays, disclosures, mobile nav, status/error states, and stress states. | Prevents false confidence from markup that only works before interaction. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md] |
| Pixel screenshots as primary quality proof | Semantic, keyboard, computed-style, contract, and screenshot evidence together. | Screenshots catch layout drift but do not prove accessible names, focus, keyboard behavior, or reduced motion. [VERIFIED: .planning/REQUIREMENTS.md] |
| Subjective animation review | Measurable computed-style and source-token checks. | Duration, delay, transition property, transform, and reduced-motion behavior become regression-testable. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts] |

## Assumptions Log

All recommendations above are based on local project files or cited external standards/docs inspected during this research pass. No `[ASSUMED]` claims are required for planning. [VERIFIED: local research inventory]

## Open Questions

1. **Should Phase 180 add axe-based package scanning?**  
   What we know: no axe package is currently present in `examples/threadline_phoenix/e2e/package.json`, and the phase can satisfy its stated requirements with existing Playwright role/keyboard/computed-style checks plus manual evidence. [VERIFIED: examples/threadline_phoenix/e2e/package.json]  
   Recommendation: do not add axe unless the user explicitly approves a dev-only dependency and a package legitimacy gate is run. [VERIFIED: .planning/STATE.md]

2. **Where should final manual evidence live?**  
   What we know: Phase 180 requires bounded manual keyboard/screen-reader evidence and an adversarial closeout artifact, while this research turn is limited to one artifact. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md] [VERIFIED: user request]  
   Recommendation: execution should write manual evidence into Phase 180 verification/closeout artifacts, not this research artifact. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]

## Sources

### Primary Local Sources
- `.planning/STATE.md` - current phase, v1.37 invariants, deferred item status, Phase 179 residual context. [VERIFIED: .planning/STATE.md]
- `.planning/ROADMAP.md` - Phase 180 goal and success criteria. [VERIFIED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - A11Y-01, A11Y-02, MOTION-01, MOTION-02 requirement text. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/PROJECT.md` - milestone state and architecture invariants. [VERIFIED: .planning/PROJECT.md]
- `.planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md` - locked decisions and discretion. [VERIFIED: .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-CONTEXT.md]
- `.planning/phases/179-microcopy-information-architecture-sweep/179-VERIFICATION.md` and `deferred-items.md` - inherited residual CI baseline. [VERIFIED: .planning/phases/179-microcopy-information-architecture-sweep/179-VERIFICATION.md]
- `brandbook/brand-book.md` - brand, non-color-only, copy tone constraints. [VERIFIED: brandbook/brand-book.md]
- `lib/threadline/operator_surface/ui.ex`, `lib/threadline/operator_surface/components/surface_header.ex`, `lib/threadline/operator_surface/style.ex` - LiveView component and style source. [VERIFIED: lib/threadline/operator_surface/ui.ex]
- `test/threadline/operator_surface/*.exs` - component/style/UI/stress/card guardrails. [VERIFIED: test/threadline/operator_surface]
- `examples/threadline_phoenix/e2e/tests/*.spec.ts` - Playwright accessibility, motion, stress, screenshot, and Phase 178 guardrail specs. [VERIFIED: examples/threadline_phoenix/e2e/tests]

### External Standards And Docs
- WAI-ARIA APG Patterns and dialog/tabs/disclosure/keyboard references. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/] [CITED: https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/]
- WCAG 2.2 and Quick Reference for focus, target size, and AA criteria framing. [CITED: https://www.w3.org/TR/WCAG22/] [CITED: https://www.w3.org/WAI/WCAG22/quickref/]
- Phoenix LiveView JS docs for transition and focus command behavior. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html]
- Playwright API docs for page/keyboard/media/screenshot capabilities used by existing specs. [CITED: https://playwright.dev/docs/api/class-page]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all tools and harnesses were verified locally; no new package recommendation. [VERIFIED: local environment probe] [VERIFIED: examples/threadline_phoenix/e2e/package.json]
- Architecture: HIGH - tier ownership is derived from local Phoenix components, style contracts, and Playwright specs. [VERIFIED: lib/threadline/operator_surface/ui.ex] [VERIFIED: test/threadline/operator_surface/component_contract_test.exs]
- Pitfalls: HIGH for local residual/guardrail risks and MEDIUM for external APG/WCAG interpretation. [VERIFIED: .planning/phases/179-microcopy-information-architecture-sweep/179-VERIFICATION.md] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/]

**Research date:** 2026-06-19  
**Valid until:** 2026-07-19 for local project inventory, or earlier if Phase 180 source/tests change before planning.
