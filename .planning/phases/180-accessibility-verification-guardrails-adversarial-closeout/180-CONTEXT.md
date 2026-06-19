# Phase 180: Accessibility verification, guardrails & adversarial closeout - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Verify and close the v1.37 operator-surface design-system milestone after the component, page-stress, and microcopy phases are complete. This phase delivers A11Y-01, A11Y-02, MOTION-01, and MOTION-02: WCAG 2.2 AA verification across rendered states, WAI-ARIA APG checks for custom widgets, motion-token and reduced-motion compliance, idempotency guardrails, and an adversarial regression signoff.

**In scope:** automated accessibility scans against rendered pages and opened overlays/disclosures; manual keyboard and screen-reader check records; focus entry/restore/non-obscured focus proof; WAI-ARIA APG review for dialog, tabs, menu/dropdown, combobox, disclosure, tooltip, table/grid, alert, and nav patterns; touch target and non-color-only checks; motion audit against compositor-safe transform/opacity, origin awareness, no `scale(0)`, press feedback, reduced motion, and token boundaries; expanded Playwright/stress screenshot guardrails; brand-token parity, style/component/copy/stress contracts; adversarial regression review and milestone closeout evidence.

**Out of scope:** new operator capabilities, new visual redesign, new route/API/public component surface, new runtime dependency, copy registry/i18n/CMS, capture/semantics changes, or re-opening already-completed page polish except where a Phase 180 verification gate proves a regression.

This is a verification and hardening phase. It may add tests, docs, verification artifacts, and narrowly-scoped fixes that are required to make the checks true, but it should not become another broad design pass.

</domain>

<decisions>
## Implementation Decisions

### Verification matrix and evidence shape
- **D-01:** Use a **layered proof model** instead of trying to manually inspect every theoretical state. Tier A is automated and broad: ExUnit/style/component/stress contracts plus axe-like browser checks on representative rendered states. Tier B is real-engine browser coverage: opened overlays, disclosures, keyboard paths, reduced motion, light/dark/system, and stress-route screenshot/geometry guards. Tier C is explicit manual evidence: keyboard and screen-reader notes for the small set of flows automation cannot honestly judge.
- **D-02:** The final Phase 180 report must state exactly what each tier proves. Do not let green automation imply that every page/state/theme/viewport was manually reviewed. Use the Phase 178 honesty pattern: full structural coverage where deterministic, representative browser coverage where high-signal, and small manual assistive-tech records where required by A11Y-01.
- **D-03:** Prefer extending existing specs over creating a parallel audit harness. The primary browser files are `operator-accessibility.spec.ts`, `operator-motion.spec.ts`, `operator-phase-178-uat.spec.ts`, `operator-stress.spec.ts`, `operator-screenshot-regression.spec.ts`, and targeted per-flow specs. The primary ExUnit gates are `style_contract_test.exs`, `component_contract_test.exs`, `ui_test.exs`, `stress_fixtures_test.exs`, `stress_ledger_test.exs`, `stress_router_test.exs`, and the rendered page tests.

### Accessibility audit posture
- **D-04:** Treat A11Y-01 as a **rendered-state claim**, not a source-only claim. Plans should open the states that matter: modal/dialog, drawer, dropdown/menu, tabs, disclosure/accordion, combobox/select/search controls, error summary, permission/unavailable/alert states, stale/status banners, table/list/data panels, shell nav, mobile nav, and stress-route state stories.
- **D-05:** Manual keyboard and screen-reader evidence is required but bounded. Record deterministic checklists as artifacts: keyboard traversal, focus visibility, focus entry/restore, Escape/click-outside behavior, and a screen-reader smoke pass for landmark/headings/labels/status/alert announcements. Do not require subjective full human UAT unless an automated or manual check finds a gap.
- **D-06:** Fixes must preserve dense operator workflows. If an accessibility issue conflicts with power-user efficiency, resolve by improving semantics/focus/labels rather than hiding controls, removing direct links, or adding novice/expert modes.
- **D-07:** APG checks should map to the actual implementation, not a generic widget list. Dialog/drawer/modal behavior comes from `UI.modal/1`, `UI.drawer/1`, and real retention/row-history overlays. Menus/dropdowns, tabs, segmented controls, accordions/disclosures, combobox/search/date/number fields, and data tables each need targeted assertions or documented non-applicability.

### Motion audit posture
- **D-08:** Motion is allowed only where it communicates state, continuity, or feedback. Audit existing transitions against the Phase 177 rules: transform/opacity only, token durations/easing, origin-aware overlays/drawers/dropdowns, no `scale(0)`, no high-frequency stream-row animations, and immediate collapse under `prefers-reduced-motion`.
- **D-09:** Press feedback belongs on genuinely interactive controls only. Do not add hover/focus affordances to non-interactive elements while closing motion gaps. Disabled controls must look and behave disabled.
- **D-10:** The motion closeout should prefer measurable checks: computed transition properties, reduced-motion duration collapse, overlay origin transforms, responsive pressed/active states, and absence of banned transform patterns in `style.ex`.

### Guardrails and adversarial closeout
- **D-11:** Phase 180 is the final idempotency gate for v1.37. The plan must run or extend the existing guardrails: brand-token parity, style contracts, component contracts, stress ledger/projection parity, stress route auth/prod gates, screenshot allowlist/baseline checks, copy contracts, and touched Playwright matrix.
- **D-12:** The adversarial review is a written artifact, not just a green test suite. It should cover aesthetics-vs-usability, dependency/architecture weight, host integration friction, inaccessible custom behavior, generic-template drift, screenshot-only quality, route/API stability, and whether residual `mix ci.all` failures are in or out of scope.
- **D-13:** Treat the old `coverage-schema-card-declutter` todo as a **regression check only**. Phase 176 already flattened that card shell; Phase 180 should verify no card-in-card or accessibility regression reappeared, not add new coverage-page layout scope.
- **D-14:** If `mix ci.all` still fails, Phase 180 must classify failures explicitly. Failures in Phase 180-owned accessibility, motion, guardrail, stress, copy, component, route, or rendered operator flows block closeout. Inherited charter/demo seed failures already documented in Phase 179 may remain non-blocking only if verified unchanged and still outside Phase 180's requirements.

### Claude's Discretion
- Exact plan slicing is open, but a conservative split is: accessibility/browser audit; APG/component semantics; motion/reduced-motion audit; guardrail/screenshot/adversarial closeout. Keep fixes narrow and paired with failing checks.

### Folded Todos
- **Coverage "schema: public" card de-clutter** (`coverage-schema-card-declutter.md`) — fold only as an adversarial regression check. Do not reopen layout polish unless Phase 180 verification proves a current accessibility/card-nesting regression.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/REQUIREMENTS.md` — A11Y-01, A11Y-02, MOTION-01, MOTION-02; v1.37 invariants around zero runtime deps, inline assets, private components, brand-token parity, fail-closed auth, and capture/semantics freeze.
- `.planning/ROADMAP.md` — Phase 180 goal, dependency on Phase 179, and closeout success criteria.
- `.planning/PROJECT.md` — current v1.37 status, core value, validated Phase 179 requirements, and milestone posture.
- `.planning/STATE.md` — current Phase 180 position and accumulated decisions from Phases 171-179.

### Prior phase context
- `.planning/phases/177-component-groups-meta-components/177-CONTEXT.md` — group/meta-component motion rules, reduced-motion blanket, overlay/disclosure constraints, state coordination, and original reconnect/offline decisions.
- `.planning/phases/178-per-page-flow-stress-pass-all-11-pages/178-CONTEXT.md` — Tier A/Tier B verification honesty, page-stress matrix, footgun detectors, real socket-drop proof, and corrected `[data-phx-main].phx-* .threadline-ui` lifecycle anchor.
- `.planning/phases/179-microcopy-information-architecture-sweep/179-CONTEXT.md` — copy/state/ARIA role rules, full-value copy affordances, and scope boundary that leaves formal accessibility/motion/adversarial closeout to Phase 180.
- `.planning/phases/179-microcopy-information-architecture-sweep/179-VERIFICATION.md` — completed Phase 179 evidence, residual CI classification, and 30/30 must-have verification.

### Stress, ledger, and design-system guardrails
- `.planning/design-system-ledger.json` — scored idempotency ledger and screenshot allowlist.
- `DESIGN-SYSTEM.md` — projection that must remain in sync with the ledger and stress fixtures.
- `lib/threadline/operator_surface/stress_fixtures.ex` — component, group, page, copy-state, and screenshot story fixtures.
- `lib/threadline/operator_surface/live/stress_live.ex` — `/audit/__stress` rendering surface and browser target for stress-route checks.
- `lib/threadline/operator_surface/stress_router.ex` and `test/threadline/operator_surface/stress_router_test.exs` — dev/test-only stress route and prod gate.

### Operator surface implementation
- `lib/threadline/operator_surface/ui.ex` — internal components: shell, page_header, field/input/error_summary, modal/drawer/toast/dropdown/tabs/segmented/accordion, data_state, data_panel, toolbar, detail_header, pager, ref, stack, cluster.
- `lib/threadline/operator_surface/style.ex` — tokenized CSS, focus/contrast/motion/reduced-motion rules, z-index, disabled states, overlay transitions, shell/reconnect classes.
- `lib/threadline/operator_surface/components/surface_header.ex` — shell nav, skip link, theme picker, and mobile nav.
- `lib/threadline/operator_surface/live/*.ex` — rendered operator pages and real overlay/forms/actions used for browser checks.

### Tests and browser specs
- `test/threadline/operator_surface/style_contract_test.exs` — style source governance, contrast helpers, token/motion contracts.
- `test/threadline/operator_surface/component_contract_test.exs` — component semantics, z-index, overlay/reconnect/source-level contracts.
- `test/threadline/operator_surface/ui_test.exs` and `test/threadline/operator_surface/*_test.exs` — internal component and rendered page contracts.
- `test/threadline/operator_surface/stress_fixtures_test.exs`, `stress_ledger_test.exs`, `stress_router_test.exs`, `ui_stress_test.exs` — stress fixture, ledger/projection, route, and render parity.
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` — current keyboard/focus/accessibility browser baseline.
- `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` — motion and reduced-motion browser contracts.
- `examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts` — representative page-stress, overlay, keyboard, reduced-motion, and reconnect checks.
- `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` — stress-route semantics and screenshot allowlist/baseline checks.
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` and `operator-screenshots.spec.ts` — screenshot guard behavior and local screenshot lane.
- `examples/threadline_phoenix/e2e/playwright.config.ts` — browser projects, light/system lane inclusion, screenshot settings, and reduced-motion neutralization.

### External standards and project references
- `brandbook/brand-book.md` — non-color-alone rule, focus/hover guidance, restrained motion/brand posture, and UI language expectations.
- `prompts/audit-lib-domain-model-reference.md` — operator workflows and domain surfaces to preserve while fixing accessibility/motion issues.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — LiveView JS transitions, connection lifecycle, streams/forms, and function-component conventions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `operator-accessibility.spec.ts` already proves skip link, nav state, Home form names, Timeline focus, Retention modal focus, and row-history drawer semantics; extend it for missing opened states rather than starting over.
- `operator-motion.spec.ts`, `operator-phase-177-uat.spec.ts`, and `operator-phase-178-uat.spec.ts` already measure reduced-motion collapse and overlay geometry; reuse their helpers and assertions for MOTION-01.
- `style_contract_test.exs` already contains contrast and style-source governance helpers. Add source-level bans for motion/focus/disabled/accessibility footguns here when browser tests are too slow.
- `component_contract_test.exs` is the right home for APG-like structural checks on internal function components.
- `operator-stress.spec.ts` and the stress fixture tests already know the ledger/screenshot story set; extend the existing allowlist carefully instead of broadening screenshot churn.

### Established Patterns
- Guard-first remains the default: write the failing accessibility/motion/guardrail assertion, then fix narrowly.
- The project prefers deterministic structural and browser evidence over screenshot-only quality claims.
- Internal function components are private and strict; no public component API or new dependency should appear in this closeout phase.
- Reduced motion is centralized through the existing CSS blanket and token contracts. New motion checks should prove that lane still works rather than adding per-widget JS.

### Integration Points
- Overlay/disclosure/focus work connects `ui.ex`, `style.ex`, real LiveViews, `component_contract_test.exs`, and Playwright specs.
- Stress-route screenshot/ledger work connects `stress_fixtures.ex`, `stress_live.ex`, `.planning/design-system-ledger.json`, `DESIGN-SYSTEM.md`, `stress_ledger_test.exs`, and `operator-stress.spec.ts`.
- Manual evidence should live in the Phase 180 planning/verification artifacts, not in runtime code.

</code_context>

<specifics>
## Specific Ideas

- Use the Phase 178 wording: "Tier A proves the full structural matrix; Tier B proves representative real-engine cells; manual checks cover assistive-tech judgment." This keeps closeout honest.
- The final adversarial review should be phase-local, probably `180-ADVERSARIAL-REVIEW.md` or a section in `180-VERIFICATION.md`, and should explicitly classify residual CI failures.
- Treat opened dialogs/menus/popovers as first-class axe/browser targets; closed overlay markup is not enough for A11Y-01.
- The last phase should prefer removing architecture weight over adding it. Any accessibility fix that wants a new dependency, new API, or new route needs a very high bar and should usually be rejected.

</specifics>

<deferred>
## Deferred Ideas

- New operator capabilities, new filters, new exports, novice/expert mode, and full i18n/copy registries remain out of scope.
- Coverage schema card declutter is not reopened as design scope; it is only a regression check because Phase 176 already flattened that surface.
- Broad visual redesign and marketing-polish review are out of scope unless an accessibility or guardrail test proves a current blocking defect.

</deferred>

---

*Phase: 180-Accessibility verification, guardrails & adversarial closeout*
*Context gathered: 2026-06-19*
