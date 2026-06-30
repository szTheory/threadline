# Phase 186: detail-governance-and-export-surfaces - Context

**Gathered:** 2026-06-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 186 applies the cleaned v1.38 operator IA and private component patterns to the remaining detail, governance, and export surfaces in the mounted `/audit` Phoenix LiveView operator UI.

The phase owns the Transaction, Row history, Actor activity, Evidence, Exports, Redaction policy, and Retention window pages. It may retune their page anatomy, detail headers, metadata, refs, row-history drawer behavior, workflow summaries, export/download affordances, feature-gated controls, destructive retention modal, state handling, copy, responsive behavior, accessibility affordances, and focused regression proof.

This phase does not change capture/query/auth semantics, route paths, stable `data-testid`s, root optional Phoenix/LiveView dependency posture, public component API, Tailwind/shadcn posture, or runtime redaction destructive semantics. The runtime redaction destructive flow remains deferred.

No additional user-facing gray areas were discussed in this run. The existing Phase 186 UI-SPEC plus prior Phase 183-185 context already lock the decisions a user would care about; the remaining choices are planner/executor mechanics.

</domain>

<spec_lock>
## UI Design Contract (locked via UI-SPEC.md)

The active design contract is `.planning/phases/186-detail-governance-and-export-surfaces/186-UI-SPEC.md`.

Downstream agents MUST read `186-UI-SPEC.md` before planning or implementing. Do not duplicate or reinterpret its detailed page labels, copy, control-state, responsive, accessibility, motion, destructive-flow, and verification contracts in plans; cite it and implement against it.

**Requirements locked for this phase:** `DETAIL-01`, `GOV-01`, `GOV-02`, and `GOV-03`.

**In scope from UI-SPEC:** detail page anatomy for Transaction, Row history, and Actor activity; governance workflow anatomy for Evidence, Exports, Redaction, and Retention; export/download and feature-gate control states; retention type-to-confirm destructive flow; state lattice; responsive and accessibility contracts; targeted verification hooks.

**Out of scope from UI-SPEC:** new route paths, route meaning changes, capture/query/auth semantic changes, public component exports, root dependency expansion, Tailwind/shadcn, broad screenshot matrix expansion, runtime redaction destructive flow, decorative motion, and card-inside-card layouts.

**Metadata note:** `STATE.md` records "Phase 186 UI-SPEC approved", while the file frontmatter/checker checklist still says draft/pending. Treat the UI-SPEC as the active planning authority unless the user explicitly reopens it; planner may normalize stale metadata only if the owning workflow requires it.

</spec_lock>

<decisions>
## Implementation Decisions

### Contract Authority And Scope

- **D-186-01:** `186-UI-SPEC.md` is the primary Phase 186 contract. Planning should start by diffing current target pages against it, not by asking new product/design questions.
- **D-186-02:** The phase should normalize existing pages to the private Threadline operator component system, not redesign the operator surface or create a new component family.
- **D-186-03:** Preserve route paths, stable `data-testid`s, feature gates, auth/export auth boundaries, optional Phoenix/LiveView dependency posture, scoped `data-tl-theme`, CSP-friendly behavior, and host-app-friendly library boundaries.
- **D-186-04:** Avoid new dependencies, Tailwind/shadcn, public component API, external icon packages, custom JS widgets, client-side routing, broad visual-regression expansion, and decorative animation.

### Detail Surfaces

- **D-186-05:** Transaction, Row history, and Actor activity must share the same detail-page anatomy: `UI.shell/1`, compact `UI.page_header/1`, one object summary via `UI.detail_header/1` or equivalent, metadata through `UI.kv/1`, full-value refs via `UI.ref/1`, and scan-first row/action lists.
- **D-186-06:** Detail pages keep Timeline as the investigation nav context (`current={:timeline}`) and use breadcrumbs back to Timeline. Breadcrumbs must not create duplicate conflicting `aria-current="page"` state.
- **D-186-07:** Primary detail actions are investigation pivots only: `Open transaction`, `Open row history`, `Open timeline`, and `Review evidence` when feature-enabled and contextual.
- **D-186-08:** Row-history subviews should use `UI.drawer/1` where feasible. If existing subview markup remains, it must meet the same dialog, Escape/close, visible close, focus-in, and focus-return contract.
- **D-186-09:** Dense raw maps belong inside row-local details, drawers, or rows. Above the fold should show only useful object facts such as actor, correlation id, table, record id, selected/as-of time, window, count, and status.

### Governance And Export Workflows

- **D-186-10:** Evidence, Exports, Redaction, and Retention must read as focused workflows, not dashboards or dense metadata dumps. Each page gets one summary/decision unit directly below the header that answers the page's main question.
- **D-186-11:** Avoid duplicate generic trust rails, repeated metric grids, and repeated cross-page CTAs. Coverage/Evidence/Timeline/Exports links are contextual and feature-gated.
- **D-186-12:** Exports answers what can be downloaded, what is processing, and how to reopen the source search. Jobs should be grouped by readiness/status and use honest recent-only captions.
- **D-186-13:** Evidence records remain grouped by subject with verdict chip, proof label, subject, copyable subject ref, recorded time, and only relevant actions. `Carry to Exports` appears only when exports are enabled and the Evidence request shape is valid.
- **D-186-14:** Redaction answers whether deployed trigger redaction matches configured policy. Do not add a runtime redaction destructive button or modal.
- **D-186-15:** Retention answers whether the retention window is healthy and what happens if an operator prunes now. A single visible page-level destructive action is enough; any row-menu prune must open the same policy-level modal and must not imply row-specific deletion.

### Controls, Downloads, And Feature Gates

- **D-186-16:** Completed export downloads render as real focusable HTTP links. They must not have `aria-disabled="true"`, `tabindex="-1"`, or LiveView reconnect/mutating dimming when the controller can serve them while LiveView reconnects.
- **D-186-17:** Pending, running, failed, expired, unauthorized, or feature-gated jobs must not expose active fake download links. Use visible status text such as `Queued`, `Processing`, `Expired`, or `Failed`.
- **D-186-18:** `Queue Timeline export` is a native LiveView button visible only for valid context and exports-enabled state. It needs real unavailable/mutating affordances plus server-side enforcement.
- **D-186-19:** Feature-disabled routes render the existing unsupported view and remove the disabled nav/action surface through shell gates. Prefer omitting disabled feature links over showing inert links unless an explanation is needed.
- **D-186-20:** CSS dimming and `pointer-events: none` are affordance only. Disabled/unavailable behavior must use native `disabled`, removed `href`, `aria-disabled`, `tabindex="-1"`, and server/controller enforcement as appropriate for the element type.

### Retention Destructive Flow

- **D-186-21:** Retention prune is the only destructive action in Phase 186. It must use the UI-SPEC labels and copy, including `Run retention prune`, `Prune retention window permanently?`, `Keep retention window`, and `Prune records permanently`.
- **D-186-22:** The destructive flow keeps server-side auth re-check, server-derived canonical policy name `default`, `Plug.Crypto.secure_compare/2`, audit-before-prune, fail-closed mismatch handling, runtime-unavailable handling, reconnect-safe mutating control affordance, and focus restoration.
- **D-186-23:** The mismatch flash copy is locked by UI-SPEC as `Could not prune - confirmation did not match.` If existing code uses different punctuation, planning should reconcile source and tests to the UI-SPEC.
- **D-186-24:** Runtime redaction destructive UI remains deferred; do not use the retention destructive pattern to sneak in a Redaction destructive flow.

### State, Copy, Responsive, And Motion

- **D-186-25:** Use the UI-SPEC state lattice. Permission, source-down, redacted, pruned, stale, invalid context, failed export, and reconnecting states must not collapse into a generic empty or error message.
- **D-186-26:** Page copy must use Threadline nouns exactly: Timeline, transaction, row history, actor, correlation id, Evidence, Exports, Redaction, Retention, export job, retention run, policy name, and audit readiness.
- **D-186-27:** Color never carries status alone. Pair colors with text, icons, chips, status stripes, or role-specific copy.
- **D-186-28:** Responsive proof must cover the targeted Phase 186 surfaces at 320, 375, 768, 1024, and 1440 where the UI-SPEC calls it out, especially long refs, job cards, tables, drawers, and the retention modal.
- **D-186-29:** Motion stays inside existing 180ms modal/drawer opacity/transform utilities, copy success treatment, button active feedback, data-panel fade, and existing reduced-motion behavior. No new row/card keyframes or `transition: all`.

### Verification Posture

- **D-186-30:** Verification should be targeted to Phase 186 contracts. Preserve or add focused source, LiveView, and Playwright proof for detail alignment, export/download links, feature gates, retention destructive flow, responsive behavior, and keyboard/accessibility paths.
- **D-186-31:** Do not expand the broad screenshot matrix. Use existing example browser lanes and classify unrelated broad-suite residuals honestly.
- **D-186-32:** Tests should prefer role/name/test-id locators, source/doc contracts, LiveView behavior assertions, direct controller/auth proof for downloads, and browser checks for focus, overflow, and reachable controls.

### Claude's Discretion

Downstream agents may choose exact plan count, wave ordering, helper names, private extraction boundaries, CSS selectors, test organization, and whether to amend existing tests or add a narrow Phase 186 spec, as long as they preserve the decisions above and implement the UI-SPEC faithfully.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Authority

- `.planning/ROADMAP.md` - Phase 186 goal, requirements, success criteria, and boundary with Phases 185 and 187.
- `.planning/REQUIREMENTS.md` - `DETAIL-01`, `GOV-01`, `GOV-02`, `GOV-03`, milestone invariants, traceability, and out-of-scope constraints.
- `.planning/PROJECT.md` - active v1.38 posture, shipped context, optional-dependency boundary, and standing no-regression rules.
- `.planning/STATE.md` - current workflow state and note that Phase 186 UI-SPEC was approved.
- `.planning/phases/186-detail-governance-and-export-surfaces/186-UI-SPEC.md` - primary Phase 186 design, copy, interaction, responsive, accessibility, motion, and verification contract.
- `.planning/research/v1.38-operator-ui-page-polish.md` - accepted page order, operator JTBD posture, Storybook/stress boundary, and page-by-page cleanup rationale.

### Prior Phase Context

- `.planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md` - Coverage readiness workflow, selected-schema verdict, contextual row actions, state/proof posture, and no broad screenshot expansion.
- `.planning/phases/184-timeline-investigation-flow/184-CONTEXT.md` - Timeline row-first investigation flow, URL-backed filters, contextual handoff, export boundary, state lattice, and proof strategy.
- `.planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md` - shell/Home IA, private component posture, route/test-id stability, native controls, brand posture, and adjacent-page boundary rules.
- `.planning/phases/185-coverage-and-audit-readiness/185-UI-SPEC.md` - nearest workflow-page UI contract to carry into governance/export pages where patterns overlap.
- `.planning/phases/184-timeline-investigation-flow/184-UI-SPEC.md` - Timeline source workflow and export handoff context that Phase 186 must receive correctly.
- `.planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md` - shell/page-header/nav/theme contracts every target page must preserve.

### Brand, Product, And Prompt Corpus

- `brandbook/brand-book.md` - current Threadline brand source of truth, voice, visual principles, UI theming posture, component rules, and microcopy guidance.
- `brandbook/README.md` - brand artifact roles and warning that `lib/threadline/operator_surface/style.ex` is the product UI contract.
- `prompts/audit-lib-domain-model-reference.md` - audit capture/semantics/exploration/operations split, canonical nouns, and operator workflow model.
- `prompts/threadline-elixir-oss-dna.md` - verification-as-product, docs/contracts, optional dependency hygiene, and OSS library habits.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` - audit ecosystem lessons around trigger-backed capture, action context, operator tooling, export/retention, and common footguns.
- `prompts/prior-art/SOURCE-CANONICAL.md` - prompt corpus provenance and canonical prior-art map.

### Target LiveViews, Components, And Controllers

- `lib/threadline/operator_surface/ui.ex` - private component primitives: `shell`, `page_header`, `detail_header`, `kv`, `ref`, `data_panel`, `data_table`, `empty_state`, `error_state`, `loading_state`, `stale_banner`, `drawer`, `modal`, `dropdown`, `button`, fields, and motion/focus helpers.
- `lib/threadline/operator_surface/style.ex` - scoped product CSS contract for `.tl-change`, `.tl-job`, `.tl-record-card`, `.tl-summary-grid`, modal/drawer, responsive behavior, focus, reconnect/mutating controls, theme, and motion.
- `lib/threadline/operator_surface/presentation.ex` - presentation helpers for refs, value tokens, statuses, operation labels, export action/readiness labels, query pairs, and truncation.
- `lib/threadline/operator_surface/components/icon.ex` - internal inline SVG icon source; no external icon package.
- `lib/threadline/operator_surface/components/surface_header.ex` - shell nav/current-state/feature-gate/theme picker integration.
- `lib/threadline/operator_surface/components/unsupported_view.ex` - unsupported feature route rendering.
- `lib/threadline/operator_surface/router.ex` - mounted routes, live sessions, theme/export route boundaries, and route stability.
- `lib/threadline/operator_surface/auth.ex` - host-owned auth, theme assignment, actor/scope assigns, and surface context.
- `lib/threadline/operator_surface/export_auth_plug.ex` - direct download authorization boundary for completed exports.
- `lib/threadline/operator_surface/controllers/export_controller.ex` - direct HTTP CSV/JSON/NDJSON download boundary.
- `lib/threadline/operator_surface/exports/filter_params.ex` - canonical Timeline/export filter parsing and context validation.

### Target Detail And Governance Pages

- `lib/threadline/operator_surface/live/transaction_live.ex` - Transaction detail owner; current code already has Timeline context, row changes, row-history subview, and copyable refs but must align with UI-SPEC detail-header/state patterns.
- `lib/threadline/operator_surface/live/row_history_live.ex` - standalone Row history page owner.
- `lib/threadline/operator_surface/live/row_history_component.ex` - row-history subview/drawer candidate used from transaction flows.
- `lib/threadline/operator_surface/live/actor_live.ex` - Actor activity page owner.
- `lib/threadline/operator_surface/live/evidence_live.ex` - Evidence workflow owner with subject grouping and handoff context.
- `lib/threadline/operator_surface/live/export_status_live.ex` - Exports page owner; key target for real download link vs unavailable status, context panels, and recent-only job groups.
- `lib/threadline/operator_surface/live/policy_redaction_live.ex` - Redaction policy page owner and runtime-redaction non-goal.
- `lib/threadline/operator_surface/live/retention_history_live.ex` - Retention window page owner; existing server-side prune enforcement is reusable but copy/focus/control-state must align to UI-SPEC.

### Existing Tests To Build On

- `test/threadline/operator_surface/transaction_live_test.exs` - Transaction page behavior.
- `test/threadline/operator_surface/live/row_history_live_test.exs` - Row history page behavior.
- `test/threadline/operator_surface/row_history_component_test.exs` - Row-history component behavior.
- `test/threadline/operator_surface/live/actor_live_test.exs` - Actor activity behavior.
- `test/threadline/operator_surface/live/evidence_live_test.exs` - Evidence behavior and context handling.
- `test/threadline/operator_surface/live/export_status_live_test.exs` - Export status, queue, and download affordance behavior.
- `test/threadline/operator_surface/controllers/export_controller_test.exs` - Direct export controller/download behavior.
- `test/threadline/operator_surface/export_auth_plug_test.exs` - Export auth boundary.
- `test/threadline/operator_surface/exports/filter_params_test.exs` - Timeline/export filter parity.
- `test/threadline/operator_surface/exports_doc_contract_test.exs` - export docs/source contract.
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs` - Redaction policy behavior.
- `test/threadline/operator_surface/policy_show_doc_contract_test.exs` - policy/redaction docs contract.
- `test/threadline/operator_surface/live/retention_history_live_test.exs` - Retention run and prune flow behavior.
- `test/threadline/operator_surface/style_contract_test.exs` - CSS, responsive, motion, focus, data-state, reconnect/mutating, row/job/card contracts.
- `test/threadline/operator_surface/component_contract_test.exs` - shared component and reconnect/mutating contracts.
- `test/threadline/operator_surface/copy_contract_test.exs` - domain copy and unsafe vocabulary refutes.
- `test/threadline/operator_surface/gating_test.exs` - feature-gated route/action behavior.
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` - keyboard/focus/accessibility-tree proof lane.
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` - responsive/no-overflow proof lane.
- `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts` - Evidence/Exports/Retention mobile proof.
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` - Timeline-to-detail/export earned flows.
- `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts` - Timeline/export handoff boundary.
- `examples/threadline_phoenix/e2e/tests/operator-features.spec.ts` - feature-gate behavior.
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` - bounded screenshot lane; do not expand casually.

### Docs To Keep Aligned

- `guides/operator-surface.md` - operator surface routes, auth/export/scope, Timeline/Exports/Evidence/Retention behavior, and component-facing docs.
- `guides/production-checklist.md` - production coverage/redaction/retention guidance if touched.
- `guides/adoption-evidence-playbook.md` - Evidence/export handoff references if touched.
- `README.md` - high-level operator surface claims if touched.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Threadline.OperatorSurface.UI` already provides the exact private primitives Phase 186 should standardize on: shell, page header, detail header, key/value metadata, refs, data panels, responsive tables, state family, modal, drawer, dropdown, native fields, and buttons.
- `Threadline.OperatorSurface.Style.css/1` already defines `.tl-change`, `.tl-job`, `.tl-record-card`, `.tl-summary-grid`, modal/drawer, reconnect/mutating control, focus, responsive, theme, and motion contracts.
- `Threadline.OperatorSurface.Presentation` already owns status/action labels, operation labels, refs, truncation, value tokens, export readiness/action labels, and query-pair formatting.
- `Threadline.OperatorSurface.Components.Icon` is the internal icon source. Phase 186 should reuse it rather than add an icon package.
- Existing LiveViews already cover every target surface; this is a retune/normalization pass, not a new page build.
- Existing test lanes cover most target pages and browser proof categories; Phase 186 should amend/extend them narrowly.

### Established Patterns

- Operator UI code is Phoenix LiveView with private function components and scoped CSS, not Tailwind/shadcn, React, or a public component API.
- URL state remains the durable state for Timeline filters, row-history as-of state, actor windows, Evidence context, and export handoffs.
- Feature gates and unsupported routes are existing shell/router/view contracts; do not replace them with inert controls inside disabled pages.
- Direct export downloads are controller/auth-plug territory. LiveView affordance visibility is not the security boundary.
- Mutating LiveView actions use native buttons, `data-tl-mutating`, visible disabled/loading affordance, and server-side enforcement. Normal HTTP download links should not inherit that mutating pattern.
- The state family distinguishes loading, first-run empty, filtered no-data, not found, permission, source down, redacted, pruned, stale, invalid context, failed export, and reconnecting.
- Browser proof should assert user-observable behavior, accessible names, focus, keyboard reachability, overflow, and route transitions rather than implementation internals or broad screenshots.

### Integration Points And Current Gaps

- `transaction_live.ex` already uses `UI.shell`, Timeline breadcrumbs, copyable transaction/correlation refs, row changes, and a row-history subview. It still needs to align the object summary with `UI.detail_header/1` or the UI-SPEC equivalent and replace hand-rolled state blocks where appropriate.
- `export_status_live.ex` already groups jobs and parses Timeline/Evidence context. Current downloadable export markup uses `data-tl-mutating`, `aria-disabled="true"`, and `tabindex="-1"` even when `Presentation.export_downloadable?/1` is true; Phase 186 should correct this to the UI-SPEC real-link contract.
- `export_status_live.ex` has repeated "Open timeline" affordances and a trust rail; Phase 186 should collapse this into the UI-SPEC workflow summary/context model.
- `retention_history_live.ex` already has strong server-side prune enforcement: auth re-check, canonical policy name, secure compare, audit-before-prune, fail-closed behavior, runtime-unavailable handling, and `Pruner.trigger/0`. The UI layer still needs exact UI-SPEC copy, cancel label, state components, focus/restore behavior, and control-state polish.
- `retention_history_live.ex` currently lets a row menu open the policy-level prune modal. If this remains, copy must make clear it is policy-level deletion, not row-specific deletion.
- `policy_redaction_live.ex` currently uses a summary-grid pattern. Planning should check it against the UI-SPEC Redaction workflow summary and section rules.
- Evidence uses `.tl-record-card`; Exports/Retention use `.tl-job`; detail surfaces use `.tl-change`. These existing visual families are the right substrate when aligned to the UI-SPEC hierarchy and copy.

</code_context>

<specifics>
## Specific Ideas

- Treat Phase 186 as an implementation contract pass, not a discovery pass. The UI-SPEC already specifies page H1s, empty/error copy, CTAs, state behavior, feature-gate behavior, destructive copy, responsive requirements, and verification hooks.
- Highest-risk current-code deltas from the scout are export downloadable-link semantics, retention modal copy/focus exactness, duplicate trust rails/summary grids on governance pages, and detail-page summary normalization.
- The planner should use the UI-SPEC's page-by-page contracts as the acceptance checklist and keep plan tasks vertical by surface or workflow so tests can prove each user-visible contract.
- No pending todo artifacts matched Phase 186.

</specifics>

<deferred>
## Deferred Ideas

- Runtime redaction destructive flow remains deferred to a future phase that explicitly scopes capture/storage semantics.
- Public component API remains deferred to `COMP-PUBLIC-01` or a future explicit milestone.
- Public Storybook/distribution remains deferred to `STORY-PUBLIC-01` or a future explicit milestone.
- Broad screenshot matrix expansion remains deferred; Phase 186 owns targeted proof only.
- Route churn, stable `data-testid` renames, auth/capture/query semantic changes, Tailwind/shadcn, and new UI dependencies remain out of scope.

</deferred>

---

*Phase: 186-detail-governance-and-export-surfaces*
*Context gathered: 2026-06-30*
