# Phase 187: Accessibility, motion, docs, and adversarial closeout - Context

**Gathered:** 2026-06-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 187 verifies and closes the completed v1.38 operator UI pass. It owns keyboard/focus and APG proof across the primary investigation, readiness, export, and retention workflows; motion and reduced-motion verification; operator documentation alignment; bounded visual QA/screenshot guard status; residual failure ownership; and an adversarial closeout review.

This phase is a closeout, documentation, and verification phase. It may add or repair focused source, LiveView, Playwright, doc-contract, verification, and planning artifacts needed to prove `A11Y-01`, `A11Y-02`, `MOTION-01`, `DOC-01`, and `CLOSE-01`.

This phase does not add new operator capabilities, redesign pages, change route paths, rename stable `data-testid`s, alter capture/query/auth/export semantics, expand the root optional Phoenix/LiveView dependency posture, create a public component API, add Tailwind/shadcn or UI dependencies, create production Storybook/stress routes, claim real screen-reader certification, or expand broad screenshot ownership.

The user invoked `--auto`, so all gray areas were auto-selected and resolved to recommended defaults.

</domain>

<decisions>
## Implementation Decisions

### Contract Authority And Scope

- **D-187-01:** Treat Phase 187 as a proof and closeout phase over the already-polished v1.38 surfaces, not as another design or product feature phase.
- **D-187-02:** Preserve route paths, stable `data-testid`s, host-owned auth/export gates, feature gates, optional Phoenix/LiveView boundaries, scoped `data-tl-theme`, CSP-friendly behavior, private component boundaries, and all capture/query/auth semantics.
- **D-187-03:** Use targeted evidence for the exact pending requirements: `A11Y-01`, `A11Y-02`, `MOTION-01`, `DOC-01`, and `CLOSE-01`. Do not inflate scope with broad route matrices, new fixtures, or generic audits that are not tied to those requirements.

### Keyboard And APG Proof Envelope

- **D-187-04:** Primary keyboard proof must cover the investigation, readiness, export, and retention workflows end to end: Home launchers, shell nav and skip link, Timeline filters/drawers/rows/pivots, transaction and row-history paths, Coverage schema/remediation, Exports/download affordances, Evidence/Redaction/Retention navigation, and the retention destructive modal.
- **D-187-05:** Focus proof must assert visible, non-obscured focus and focus restoration where relevant, especially skip link to `#tl-main`, mobile shell navigation, Timeline filter/drawer triggers, row-history drawer, export controls, copy controls, and retention modal open/close/Escape paths.
- **D-187-06:** Custom widget proof should be representative and APG-shaped, not exhaustive for its own sake. Dialogs, drawers, dropdown/menu, popover/tooltip, tabs, segmented controls, accordion/disclosure, combobox/listbox, tooltips/popovers, and copy controls should be covered through source contracts and rendered Playwright checks where the current UI actually uses them.
- **D-187-07:** Native controls stay native. Do not role-inflate native `<select>`, `<input>`, `<table>`, links, buttons, details/summary, or forms into custom ARIA widgets.
- **D-187-08:** Accessibility-tree snapshots, role/name assertions, keyboard operation, focus visibility, non-color cues, and source contracts are sufficient proof for this phase. Do not claim real screen-reader certification unless real assistive-technology UAT is explicitly run and recorded.

### Motion Governance And Reduced Motion

- **D-187-09:** `test/threadline/operator_surface/style_contract_test.exs` and the existing motion inventory remain the source-level authority for token-backed motion, approved keyframes, `transition: all` rejection, reduced-motion blanket behavior, and dependency bans.
- **D-187-10:** `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` is the browser authority for computed motion behavior. It should continue to prove default motion and reduced-motion behavior for Home, overlays, dropdowns, popovers, accordions/details, toasts, press feedback, and row-history drawers.
- **D-187-11:** Any Phase 187 motion touch must stay inside existing tokens, keyframes, opacity/transform utilities, and reduced-motion rules. No decorative animation, new keyframes, transition-all, animation libraries, row/card entrance churn, or per-page motion experiments.
- **D-187-12:** Reduced motion should collapse positional transforms and durations while keeping UI visible and usable. Do not use motion proof that only checks source text if a current browser-computed behavior changed.

### Operator Docs Truth Source

- **D-187-13:** Documentation must align to current implementation, not older milestone prose. When docs and source conflict, treat current source plus active tests as the truth and repair docs/contracts.
- **D-187-14:** `guides/operator-surface.md` currently conflicts with source on theme behavior: it says there is no runtime theme toggle, while `lib/threadline/operator_surface/router.ex` and `lib/threadline/operator_surface/components/surface_header.ex` show a runtime server-posted dark/light/system theme picker via `POST {base_path}/theme`, native radios, CSRF, cookie/plug resolution, no JavaScript, and no localStorage. Phase 187 should repair the guide and any pinned doc contracts to describe the implemented runtime theme picker accurately.
- **D-187-15:** Operator docs must also align with the PhoenixStorybook dev lane, `/audit/__stress` authenticated stress route, auth/export gates, Coverage selected-schema behavior, CSP/asset opt-outs, production exclusions, and direct export route authorization boundaries.
- **D-187-16:** Do not broaden docs into marketing or a public component API. Keep docs focused on mount, auth, operator screens, verification, Storybook/stress boundaries, and adopter-safe production guidance.

### Visual QA And Screenshot Boundary

- **D-187-17:** Final visual QA should report the status of existing bounded guards, not create a broad screenshot matrix. The local-only screenshot regression guard currently owns Home, dense Timeline, row-history drawer, Exports, and Retention snapshots.
- **D-187-18:** `/audit/__stress` screenshot status remains ledger/allowlist-driven. Do not silently add screenshot baselines outside `.planning/design-system-ledger.json` ownership.
- **D-187-19:** Use behavioral Playwright assertions for keyboard, focus, overflow, themes, reduced motion, route transitions, and accessible names. Use screenshots only for already-owned stable visual cells or explicitly approved new baselines.
- **D-187-20:** If screenshot or Playwright commands fail, classify each failure with owner and impact. Do not delete baselines, weaken masks, skip tests, or mark broad gates green just to close the milestone.

### Adversarial Closeout

- **D-187-21:** Closeout must record concrete verification evidence: exact commands, pass/fail status, Playwright/screenshot guard status, any residual failure ownership, and why residuals are in or out of phase scope.
- **D-187-22:** Adversarial review should use four lenses: operator under incident pressure, keyboard/assistive-technology user, OSS maintainer/library boundary, and host-app DX/security boundary.
- **D-187-23:** The adversarial review must actively look for regressions in route stability, auth/export gates, CSP posture, optional dependency hygiene, docs truth, focus traps, obscured focus, color-only state, reduced-motion behavior, screenshot churn, and overclaiming accessibility.
- **D-187-24:** Requirements should only be marked complete after evidence exists. Do not close `A11Y-01`, `A11Y-02`, `MOTION-01`, `DOC-01`, or `CLOSE-01` by assertion alone.

### Claude's Discretion

Downstream agents may choose the exact plan count, task slicing, helper names, test grouping, verification commands, and closeout artifact names. They should prefer amending existing source/doc/browser contracts over creating parallel test lanes, as long as the decisions above and the phase boundary are preserved.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Authority

- `.planning/ROADMAP.md` - Phase 187 goal, success criteria, and relationship to completed Phases 181-186.
- `.planning/REQUIREMENTS.md` - `A11Y-01`, `A11Y-02`, `MOTION-01`, `DOC-01`, `CLOSE-01`, milestone invariants, traceability, and out-of-scope constraints.
- `.planning/PROJECT.md` - active v1.38 posture, optional-dependency boundary, no-regression rules, and current milestone state.
- `.planning/STATE.md` - current workflow state and accumulated residual/failure context.

### Prior Phase Context

- `.planning/phases/186-detail-governance-and-export-surfaces/186-CONTEXT.md` - detail/governance/export decisions, feature-gate/download/retention contracts, and Phase 186 browser proof posture.
- `.planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md` - Coverage selected-schema readiness workflow, schema selection, stale data, remediation, and proof posture.
- `.planning/phases/184-timeline-investigation-flow/184-CONTEXT.md` - Timeline investigation workflow, filter/export handoff, row pivots, state lattice, motion, and proof posture.
- `.planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md` - shell/Home, skip link, active nav, runtime theme picker, feature-gated groups, native controls, and dark/light/system behavior.
- `.planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md` - PhoenixStorybook as maintainer-only example-app dev lane and `/audit/__stress` as canonical authenticated flow stress harness.
- `.planning/phases/181-baseline-audit-and-guard-repair/181-CONTEXT.md` - v1.38 baseline audit, guard repair, screenshot/status evidence, and residual classification posture.

### Existing Browser Proof

- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` - keyboard/focus, APG rendered-state matrix, accessibility-tree snapshots, non-obscured focus, and non-color status proof.
- `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` - computed default-motion and reduced-motion proof for Home, overlays, details, toasts, press feedback, and row-history drawer.
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` - local-only bounded screenshot regression guard for Home, Timeline, row-history, Exports, and Retention.
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` - responsive/no-overflow proof lane for route matrix behavior.
- `examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts` - Storybook smoke and theme-preview boundary.
- `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` - `/audit/__stress` behavior, ledger status, and stress screenshot allowlist behavior.
- `examples/threadline_phoenix/e2e/tests/operator-shell-home-phase183.spec.ts` - shell/Home theme picker, nav, topbar, skip-link, and dark/system proof.
- `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts` - Timeline workflow proof and theme lane behavior.
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` - Timeline/detail/export earned-flow handoffs.
- `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts` - Evidence/Exports/Retention mobile proof.

### Source Contracts And Components

- `test/threadline/operator_surface/style_contract_test.exs` - CSS, theme, focus, motion, reduced-motion, responsive, screenshot-boundary, and no-transition-all source contracts.
- `test/threadline/operator_surface/component_contract_test.exs` - data-panel state matrix, reconnect/mutating control contract, APG/native semantics map, shell/reconnect structure, and overlay dismiss markers.
- `test/threadline/operator_surface/surface_header_csp_test.exs` - CSP-proof shell and theme picker POST/CSRF contract.
- `test/threadline/operator_surface/surface_header_test.exs` - shell navigation, theme picker rendering, and header behavior.
- `test/threadline/operator_surface/copy_contract_test.exs` - copy vocabulary, nav group labels, unsafe terms, and visible language contracts.
- `test/threadline/operator_surface/storybook_boundary_test.exs` - root optional-dependency and Storybook boundary protection.
- `test/threadline/operator_surface/stress_ledger_test.exs` - design-system ledger and stress ratchet contract.
- `test/threadline/operator_surface/stress_router_test.exs` - stress route rendering, theme behavior, and production boundary.
- `test/threadline/operator_surface/stress_fixtures_test.exs` - stress fixture registry and reserved/current ownership.
- `lib/threadline/operator_surface/ui.ex` - private UI shell, skip/focus targets, APG widgets, modals/drawers/dropdowns/popovers, copy controls, states, reconnect banner, and `data-tl-theme` root.
- `lib/threadline/operator_surface/style.ex` - scoped CSS token, focus, motion, reduced-motion, responsive, theme, screenshot, and reconnect/mutating behavior contract.
- `lib/threadline/operator_surface/components/surface_header.ex` - shell nav, feature-gated groups, native runtime theme picker, `Apply theme`, and topbar status.
- `lib/threadline/operator_surface/router.ex` - mount macro, routes, auth/export gates, `POST /theme`, direct export routes, and runtime theme picker docs in module source.
- `lib/threadline/operator_surface/live/stress_live.ex` - authenticated stress harness rendering representative states/widgets and screenshot status.
- `lib/threadline/operator_surface/stress_fixtures.ex` - current/reserved stress story registry.

### Docs And Ledgers To Align

- `guides/operator-surface.md` - primary operator docs; currently needs theme-picker truth repair and final DOC-01 alignment check.
- `guides/production-checklist.md` - production guidance if Coverage, policy, CSP, or verification claims are touched.
- `guides/adoption-evidence-playbook.md` - Evidence/export handoff guidance if touched.
- `guides/upgrade-path.md` - optional dependency/version/mount compatibility context if docs touch Phoenix/LiveView support boundaries.
- `DESIGN-SYSTEM.md` - design-system projection including motion and stress/screenshot posture.
- `.planning/design-system-ledger.json` - stress entries, current/reserved ownership, screenshot allowlist, and ratchet metadata.
- `.planning/milestones/v1.31-phases/141-motion-micro-animation/141-MOTION-INVENTORY.md` - motion inventory and reduced-motion rationale referenced by source contracts.
- `brandbook/brand-book.md` - current Threadline brand source of truth, voice, visual principles, theming posture, and microcopy guidance.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `operator-accessibility.spec.ts` already has reusable helpers for login, non-obscured focus, no horizontal overflow, opening the shell nav, opening Timeline filters, discovering transaction/row-history paths, and attaching accessibility-tree snapshots.
- `operator-motion.spec.ts` already reads computed styles and validates transition properties, durations, easing, transform origin, reduced-motion collapse, disabled-control stillness, and tokenized motion behavior.
- `operator-screenshot-regression.spec.ts` already bounds local screenshot coverage to the stable Home, Timeline, row-history, Exports, and Retention cells with dynamic masks.
- `style_contract_test.exs` already rejects `transition: all`, unapproved keyframes, motion libraries, ungoverned duration literals, bad LiveView lifecycle anchors, and Retention-specific keyframes.
- `component_contract_test.exs` already locks APG/native semantics, overlay Escape/click-outside markers, reconnect/mutating controls, and state-family semantics without requiring browser setup.
- `SurfaceHeader.surface_header/1` already renders a native theme picker form with `theme=system|light|dark`, `_csrf_token`, and `Apply theme`.
- `Router.threadline_operator_surface/2` already emits `POST /theme` and documents the runtime dark/light/system picker as cookie/plug resolved, server-side, no JS/localStorage.
- `/audit/__stress`, `StressLive`, stress fixtures, `DESIGN-SYSTEM.md`, and `.planning/design-system-ledger.json` provide the bounded stress/screenshot status substrate for final closeout.

### Established Patterns

- Operator UI remains Phoenix LiveView with private function components and scoped CSS. Do not introduce LiveComponents, public APIs, or frontend dependencies unless a planner proves they are unavoidable.
- Source contracts carry fast CI proof for route, CSS, motion, APG, native-control, CSP, feature-gate, and docs invariants; Playwright adds user-observable keyboard, focus, viewport, theme, and computed-style proof.
- Browser proof should use role/name/test-id locators, accessible names, keyboard operation, focus, overflow, and computed styles rather than broad screenshots.
- Screenshot baselines are platform-sensitive and local-only unless explicitly admitted to the stress ledger/allowlist.
- Theme is server-resolved through `data-tl-theme` and a server-posted picker. The picker is runtime, but it remains CSP-clean and avoids JavaScript/localStorage.
- Direct export downloads and feature gates must remain secured by controller/auth-plug/server behavior, not by LiveView affordance visibility alone.
- Existing broad-suite residuals are classified honestly in planning/verification artifacts rather than hidden or relabeled.

### Integration Points

- Docs alignment likely starts in `guides/operator-surface.md`, with paired doc-contract test updates where literals are pinned.
- `DOC-01` should check `guides/operator-surface.md` against source for runtime theme picker, Storybook dev lane, stress route, auth/export gates, selected-schema Coverage, CSP opt-outs, production exclusions, and optional dependency boundaries.
- `A11Y-01` and `A11Y-02` should extend existing `operator-accessibility.spec.ts`, source contracts, or narrow LiveView tests only where current proof misses a Phase 187 success criterion.
- `MOTION-01` should extend `operator-motion.spec.ts` or `style_contract_test.exs` only if the current motion proof misses a required surface or Phase 186 changed behavior after prior proof.
- `CLOSE-01` needs a durable verification/closeout artifact that records command output, screenshot/Playwright status, residual ownership, and adversarial review.

</code_context>

<specifics>
## Specific Ideas

- `[auto] Keyboard and APG proof envelope` selected targeted keyboard/APG/accessibility-tree proof with existing specs over adding axe, a new dependency, or claiming screen-reader certification.
- `[auto] Motion governance and reduced-motion proof` selected existing token/source contracts plus computed-style Playwright reduced-motion proof over manual visual review or new motion patterns.
- `[auto] Operator docs truth source` selected repairing docs to current source truth. The known drift is `guides/operator-surface.md` saying no runtime theme toggle while source implements a runtime server-posted theme picker.
- `[auto] Visual QA and screenshot boundary` selected bounded screenshot/status reporting plus behavior proof over expanding route x theme x viewport screenshot baselines.
- `[auto] Adversarial closeout evidence` selected targeted verification plus residual ownership and adversarial review over requiring every broad inherited suite to be green or writing context-only closeout.
- No pending todo artifacts matched Phase 187.

</specifics>

<deferred>
## Deferred Ideas

- Real assistive-technology UAT remains deferred unless explicitly run. Phase 187 can record accessibility-tree and keyboard evidence, but should not claim screen-reader certification.
- Broad route x theme x viewport screenshot expansion remains deferred unless a future phase explicitly accepts new stable cells and owners.
- New public component API remains deferred to `COMP-PUBLIC-01` or a future explicit milestone.
- Public Storybook distribution remains deferred to `STORY-PUBLIC-01` or a future explicit milestone.
- Runtime destructive redaction remains deferred unless capture/storage semantics are explicitly scoped.
- New UI dependencies, Tailwind/shadcn, animation libraries, and capture/query/auth semantic changes remain out of scope.

</deferred>

---

*Phase: 187-accessibility-motion-docs-and-adversarial-closeout*
*Context gathered: 2026-06-30*
