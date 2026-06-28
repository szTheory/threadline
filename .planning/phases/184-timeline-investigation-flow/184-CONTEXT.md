# Phase 184: Timeline investigation flow - Context

**Gathered:** 2026-06-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 184 makes Timeline the clean reference workflow for investigating audit history in the mounted `/audit` operator surface. The workflow is: set or review filters, scan matching audit changes, open the right transaction or row history, and hand off the current view through exports when needed.

This phase is a Timeline page polish and workflow pass. It may refine Timeline hierarchy, filters, rows, pivots, saved-view affordances, export handoff, empty/error/stale/loading states, long-value handling, mobile layout, keyboard behavior, copy, and bounded proof for the Timeline page.

This phase does not add new capture/query/auth semantics, change route paths, rename stable `data-testid`s, make a public component API, replace the private Phoenix function-component system, add a UI dependency, redesign Coverage/detail/governance/export pages, create a broad screenshot matrix, or move destructive redaction/runtime policy work forward.

The user selected all gray areas and requested one-shot, research-backed recommendations using subagents. The recommendations below are locked for planning.

</domain>

<decisions>
## Implementation Decisions

### Investigation Command Shape

- **D-184-01:** Use a row-first Timeline command surface. The first viewport should expose only the investigation starters: `from`, `to`, `table`, and `correlation_id`, plus current result facts, active filter chips, one primary `Apply`, and one explicit reset to the default last-24h window.
- **D-184-02:** Keep schema and actor filters in the existing filter drawer. They are important but secondary; putting every filter inline would push rows down, crowd mobile keyboards, and make the page feel like a filter console instead of an investigation workflow.
- **D-184-03:** Keep batch Apply semantics. Do not introduce per-keystroke `phx-change` filtering for Timeline. The current explicit `phx-submit` model preserves URL/back-button behavior and avoids expensive scan churn while operators compose filters.
- **D-184-04:** Keep Timeline state shareable and recoverable through URL params. Filters that affect investigation results stay in the query string and flow through `handle_params/3` / `push_patch`.
- **D-184-05:** Reject a query-language command bar for Phase 184. It may be useful for future power-user search, but qualifier syntax like `table:` / `actor:` / `correlation:` adds grammar burden under incident pressure and exposes backend concepts too early.
- **D-184-06:** Reject a persistent desktop filter side rail for Phase 184. It competes with the existing shell rail, reduces row width, increases 320px reflow risk, and is not needed to satisfy TIME-01 through TIME-03.
- **D-184-07:** The result facts should be useful but not repetitive: window, matching changes, and audit-readiness posture are enough. Avoid duplicated status lines that repeat the same count/window in multiple places unless tests or assistive-tech proof require a specific live region.

### Row Scan And Pivots

- **D-184-08:** Use a hybrid Timeline row. Each row should stay scan-first while exposing visible pivots: operation, table, exact/human time, actor when known, correlation when present, primary transaction link, and direct row-history link when the row has a safe routeable row identity.
- **D-184-09:** `Open transaction` remains the primary row action because transaction is the canonical DB grouping for one or more changes.
- **D-184-10:** Add or preserve direct row-history access from Timeline only when the route can be built safely from the row data. If the row has composite/unsupported/ambiguous identity, omit the direct row-history action and leave transaction as the safe pivot.
- **D-184-11:** Keep actor and correlation as visible URL-backed pivots. Actor pivots answer "what else did this actor do?", and correlation pivots answer "what else happened in this request/job/integration chain?".
- **D-184-12:** Use copy controls sparingly. Copy affordances should be attached only to values operators plausibly paste into another tool or ticket: correlation id, row/table identity where useful, transaction id where visible, and other full refs. Every copy control needs a specific accessible label and must copy the full value, not the truncated label.
- **D-184-13:** Do not convert Timeline to a dense fixed-column table in Phase 184. It would improve desktop alignment but invites horizontal scroll and raw-ID overload on 320px/375px screens.
- **D-184-14:** Do not hide primary pivots behind overflow menus or expandable rows in Phase 184. Menus add focus/state complexity, hide the actions operators need under pressure, and are harder to keep stable in streamed rows.
- **D-184-15:** Timeline rows remain visually calm and static. Use hover/focus state and status stripes; do not add row entrance animations or decorative motion to high-frequency streams.

### Handoff Utilities

- **D-184-16:** Keep saved views, Coverage/Evidence checks, Queue export, Carry to Exports, and direct CSV/JSON/NDJSON downloads in a drawer or equivalent utility sheet. The main Timeline command area should have at most one low-noise handoff entry.
- **D-184-17:** Saved views stay near filters because they mutate and restore URL filter state. Saved views remain actor-owned; do not expose save/apply/delete affordances when no actor is available.
- **D-184-18:** `Carry to Exports` is the safest primary handoff because it takes the current filter context to the Exports surface where context and status can be reviewed.
- **D-184-19:** `Queue export` remains a faster secondary path for operators who already trust the current filter. It must keep clear feedback and route to export status on success.
- **D-184-20:** Direct CSV/JSON/NDJSON links remain real HTTP download links, but they should be visually secondary and grouped under "Download now" or equivalent. They must not imply LiveView UI checks are authoritative; `ExportAuthPlug`, direct controller auth, and `FilterParams` remain the security and filter-parity boundary.
- **D-184-21:** Coverage and Evidence links are secondary checks, not the main Timeline job. Keep them accessible from the handoff/refinement utility area without turning Timeline into a generic command center.
- **D-184-22:** Do not move Exports page IA or export-status workflow polish into Phase 184. Timeline may carry context into Exports, but Exports surface cleanup belongs to Phase 186 unless a strict Timeline blocker is found.

### Ugly-Data States And Proof Bar

- **D-184-23:** Use a Timeline-critical state lattice, not an exhaustive screenshot matrix. First-class design/proof should cover states that change an operator's investigation decision or can break the workflow.
- **D-184-24:** Timeline-specific states to design and verify: first-run empty, filtered no-data, future-window empty, unknown table, invalid filter, scoped/authorized-record caveat, export hidden/denied/unavailable affordance, background export failure, capped/large result warning, long table/correlation/actor refs, dense pagination, drawer focus/escape/return, mobile keyboard layout, reduced motion, and dark/light/system rendering.
- **D-184-25:** Generic permission/unavailable/redacted/pruned states stay in shared state/stress/detail proof unless Timeline renders them directly. Do not duplicate generic component proof just to inflate Phase 184 coverage.
- **D-184-26:** Empty and error copy must state what happened, why if known, and the next action. Preserve distinct meanings: "no captured changes", "no matches for this filter", "future window", "unknown table", and "scoped view" are not interchangeable.
- **D-184-27:** Loading/reconnecting/stale trust states must not replace last-good data unless there is no safe data to show. If stale data is shown, label it clearly and offer a retry/refresh path.
- **D-184-28:** Verification should be layered: focused LiveView/source tests for URL/filter/query/export branches and copy contracts; narrow Playwright proof for mobile/no-overflow/focus/keyboard/drawer/theme/reduced-motion; existing stress/ledger contracts for shared component states. Do not promote broad new screenshot baselines unless a specific stable cell is worth owning.

### Product, JTBD, And UX Posture

- **D-184-29:** Optimize Timeline for P1 incident responders and P2 support agents first, with P3 compliance/security reviewers and P4 audit/SRE operators served by accurate filters, export handoff, and trust states. P5 adopter developers benefit from route stability, source contracts, and Phoenix-native implementation.
- **D-184-30:** Apply the who/what/where/when/why lens:
  - Who: incident/support/audit operators using a mounted host-owned admin surface.
  - What: find matching changes, scan the sequence, open a transaction or row history, copy/pivot refs, and export current context.
  - Where: `/audit/timeline`, with handoff to `/audit/transactions/:id`, `/audit/rows/:table/:id`, `/audit/actors/:kind/:id`, and `/audit/exports`.
  - When: incident pressure, customer support triage, readiness/proof review, or handoff to another operator.
  - Why: make system history followable without forcing operators to understand Threadline's backend storage model.
- **D-184-31:** Use canonical domain language: Timeline, Audit Change, Audit Transaction, Actor, Correlation, row history, current view, filter, scan, open, copy, carry, queue export, download, widen, clear, refresh.
- **D-184-32:** Hide backend implementation details unless they explain trust, scope, or performance. It is acceptable to mention capped counts, scoped views, audited tables, and export auth boundaries when they affect what the operator can rely on. Avoid exposing query internals, trigger implementation, or raw storage jargon in primary copy.
- **D-184-33:** Preserve Threadline brand posture: calm under pressure, exact, useful over impressive, dense but scannable, color as signal not decoration, accessible focus/hover/disabled states, no decorative gradients/blobs, and cards only for repeated items or tools.

### Architecture And Implementation Posture

- **D-184-34:** Stay inside the existing private Phoenix LiveView component system. Prefer function components and focused helper extraction over new LiveComponents or public APIs unless a planner proves local state/event ownership needs it.
- **D-184-35:** Keep LiveView as orchestration/presentation. Do not move query authorization, export authorization, or durable semantics into the view. Existing context/controller/filter modules remain the authority for their boundaries.
- **D-184-36:** Preserve existing route paths, `data-testid`s, URL filter keys, feature gates, optional Phoenix/LiveView dependency boundaries, theme contract, and host-owned auth/export auth posture.
- **D-184-37:** Use current assets before inventing new abstractions: `TimelineLive`, `UI.field`, `UI.drawer`, `UI.pager`, `UI.ref`, `UI.empty_state`, `UI.loading_state`, `UI.stale_banner`, `Presentation`, `FilterParams`, existing Playwright suites, `style_contract_test`, and `/audit/__stress`.
- **D-184-38:** Do not introduce a new dependency, Tailwind/shadcn migration, client-side router, localStorage theme behavior, custom date picker, custom select, or visual regression SaaS for this phase.

### Claude's Discretion

The user explicitly asked for all gray areas to be considered with research-backed, cohesive recommendations. Downstream agents may choose exact plan count, task slicing, helper names, CSS selectors, and test organization if they preserve the decisions above and keep Phase 184 scoped to Timeline.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Authority

- `.planning/ROADMAP.md` - Phase 184 goal, success criteria, and ownership boundary with Phases 185-187.
- `.planning/REQUIREMENTS.md` - TIME-01, TIME-02, TIME-03, milestone invariants, traceability, and out-of-scope constraints.
- `.planning/PROJECT.md` - active v1.38 posture, shipped context, optional-dependency boundary, and standing no-regression rules.
- `.planning/research/v1.38-operator-ui-page-polish.md` - accepted page-order, motion, Storybook/stress, and design-system posture.

### Prior Phase Context

- `.planning/phases/181-baseline-audit-and-guard-repair/181-CONTEXT.md` - baseline evidence posture, page/JTBD matrix, tiered verification model, design pillars, and guard repair boundary.
- `.planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md` - Storybook versus `/audit/__stress` boundary, private component catalog posture, and bounded browser proof lesson.
- `.planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md` - shell/Home decisions, adjacent-page boundary, verification posture, operator language, brand posture, and route/test-id stability.

### Product, Brand, And Prompt Corpus

- `brandbook/brand-book.md` - current brand source of truth, voice, visual principles, UI theming posture, component rules, and microcopy guidance.
- `brandbook/README.md` - brand artifact roles and warning that `lib/threadline/operator_surface/style.ex` is the product UI contract.
- `prompts/audit-lib-domain-model-reference.md` - capture/semantics/exploration split, canonical nouns, operator commands, Timeline Entry concept, and SavedView/Export concepts.
- `prompts/threadline-elixir-oss-dna.md` - verification-as-product, example app proof, docs/contracts, optional dependency hygiene, and OSS library habits.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` - cross-ecosystem audit lessons: separate capture from meaning, queryable metadata, operator UX, context propagation, export/retention/coverage, and common audit footguns.
- `prompts/prior-art/SOURCE-CANONICAL.md` - prompt corpus provenance and which prior-art files are canonical.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` - LiveView contexts/components/URL state/streams/async/forms/security/testing guidance.
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md` - Phoenix structure and operational guidance.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - Plug/Phoenix/Ecto production guidance and LiveView/runtime footguns.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` - Elixir OSS library API/DX, explicit boundaries, options, supervision, and anti-patterns.
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - layered CI, docs-as-product, optional-dep compile gates, and release/verification hygiene.

### Existing Timeline Code And Guardrails

- `lib/threadline/operator_surface/live/timeline_live.ex` - Timeline command surface, URL-backed filters, filter drawer, saved views, export handoff, streamed rows, row pivots, empty states, count/cap copy, and pagination integration.
- `lib/threadline/operator_surface/live/transaction_live.ex` - transaction detail pivot and Timeline breadcrumb escape hatch.
- `lib/threadline/operator_surface/live/row_history_live.ex` - direct row-history route behavior.
- `lib/threadline/operator_surface/live/row_history_component.ex` - row-history drawer/state pattern used after transaction/row pivots.
- `lib/threadline/operator_surface/live/actor_live.ex` - actor pivot destination and Timeline breadcrumb pattern.
- `lib/threadline/operator_surface/live/export_status_live.ex` - export status destination for queued exports and EF3 handoff context.
- `lib/threadline/operator_surface/controllers/export_controller.ex` - direct HTTP CSV/JSON/NDJSON export boundary.
- `lib/threadline/operator_surface/exports/filter_params.ex` - canonical URL/filter parsing and export filter parity.
- `lib/threadline/operator_surface/router.ex` - mounted operator routes and export/theme/stress boundaries.
- `lib/threadline/operator_surface/auth.ex` - host-owned auth, theme assignment, actor/scope assigns, and surface context.
- `lib/threadline/operator_surface/ui.ex` - private UI components to reuse: drawer, field, field_group, pager, ref, empty/loading/stale states, data_panel, toolbar, etc.
- `lib/threadline/operator_surface/presentation.ex` - truncation, ref, operation, and human-readable presentation helpers.
- `lib/threadline/operator_surface/style.ex` - product UI CSS contract, Timeline command/row/drawer/pager classes, theme/motion/focus/overflow rules.
- `lib/threadline/operator_surface/stress_fixtures.ex` - shared ugly-data/stress registry; use for generic state proof, not as a replacement for Timeline workflow proof.
- `DESIGN-SYSTEM.md` - current design-system ledger projection.
- `.planning/design-system-ledger.json` - ratchet, stress entries, screenshot allowlist, and current/reserved inventory.
- `guides/operator-surface.md` - operator surface auth/export/scope docs and route/function contracts.

### Existing Tests To Build On

- `test/threadline/operator_surface/live/timeline_live_test.exs` - Timeline URL/filter/query/count/export/saved-view/empty/long-value source-of-truth tests.
- `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` - route/filter/form/native-widget/URL-state contracts.
- `test/threadline/operator_surface/pager_test.exs` - `UI.pager/1` contract.
- `test/threadline/operator_surface/style_contract_test.exs` - theme, motion, responsive, Timeline command, row, and no-row-animation source contracts.
- `test/threadline/operator_surface/presentation_test.exs` - ref/truncation/value presentation helpers.
- `test/threadline/operator_surface/controllers/export_controller_test.exs` - direct export controller behavior and auth posture.
- `test/threadline/operator_surface/exports/filter_params_test.exs` - canonical export/timeline filter params.
- `test/threadline/operator_surface/exports_doc_contract_test.exs` - export docs/contracts.
- `test/threadline/operator_surface/copy_contract_test.exs` - UI copy vocabulary and unsafe-word refutes.
- `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` - Timeline mobile flow, rows before journey legend, transaction/row-history pivots, and no overflow.
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` - EF1/EF2/EF3/EF4 earned flows, Timeline-to-Exports context, direct row history, and correlation entry.
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` - viewport matrix, Timeline command first viewport, drawer, readable scale, no overflow.
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` - skip link, nav/current state, Timeline copy, focus, and accessibility-tree checks.
- `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` - reduced-motion and motion-governance checks.
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` - bounded promoted screenshot cells; do not expand casually.
- `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` - `/audit/__stress` behavior and bounded stress-route semantics.

### External References Used For Research

- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html` - Phoenix function component attrs/slots and compile-time component contracts.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html` - prefer function components unless encapsulated state/event handling is needed.
- `https://hexdocs.pm/phoenix_live_view/live-navigation.html` - `patch`/`navigate`, URL-backed state, and LiveView navigation semantics.
- `https://hexdocs.pm/phoenix_live_view/form-bindings.html` - LiveView form submit/change behavior and form ergonomics.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html` - behavior-focused LiveView testing APIs.
- `https://phoenix-live-dashboard.hexdocs.pm/Phoenix.LiveDashboard.html` - host-mounted LiveView dashboard precedent and production auth guidance.
- `https://oban.pro/docs/web/installation.html` - mounted operational dashboard precedent and access-control posture.
- `https://oban.pro/docs/web/filtering.html` - mature operational filtering precedent.
- `https://plug.hexdocs.pm/Plug.Conn.html` - HTTP response/download/chunking primitives and Plug boundary.
- `https://www.w3.org/WAI/ARIA/apg/` - APG widget and dialog/disclosure keyboard guidance.
- `https://www.w3.org/WAI/WCAG22/Understanding/reflow.html` - no two-dimensional scrolling at narrow widths.
- `https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html` - visible focus requirements.
- `https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html` - do not rely on color alone.
- `https://www.w3.org/WAI/WCAG22/Understanding/reduced-motion.html` - reduced-motion considerations.
- `https://carbondesignsystem.com/components/data-table/usage/` - dense data surfaces, toolbar hierarchy, and action placement.
- `https://carbondesignsystem.com/patterns/filtering/` - filtering patterns and applied-state clarity.
- `https://carbondesignsystem.com/patterns/empty-states-pattern/` - empty-state specificity and recovery guidance.
- `https://primer.style/components/data-table` - mature product table/data scanning precedent.
- `https://design-system.service.gov.uk/components/table/` - GOV.UK table guidance.
- `https://design-system.service.gov.uk/components/summary-list/` - key/value summary pattern precedent.
- `https://design-system.service.gov.uk/components/details/` - disclosure/details guidance for secondary detail.
- `https://design-patterns.service.justice.gov.uk/components/filter/` - MOJ filter component precedent for applied filters and result narrowing.
- `https://www.gov.uk/guidance/government-design-principles` - user-needs-first, do less, make complex things simple, design with data.
- `https://playwright.dev/docs/best-practices` - behavior-oriented browser test guidance and snapshot caution.
- `https://testing-library.com/docs/guiding-principles/` - test user-observable behavior rather than implementation details.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Threadline.OperatorSurface.Live.TimelineLive` already has the right spine: URL-backed filters, `handle_params/3`, canonical `FilterParams`, explicit Apply, saved views, export handoff, streamed rows, keyset pagination, empty-state variants, count caps, long-value refs, and direct row/action/correlation pivots.
- `Threadline.OperatorSurface.UI.drawer/1` should remain the advanced filter and handoff container. Its focus/escape/return behavior is a key proof point for Phase 184.
- `Threadline.OperatorSurface.UI.pager/1` gives explicit Older/Newer controls and honest count copy over the existing keyset engine. Timeline remains next-only unless the implementation deliberately adds a newer cursor.
- `Threadline.OperatorSurface.UI.ref/1` is the canonical full-value copy affordance. It copies the full value and renders the full value when the delegated copy script is disabled.
- `Threadline.OperatorSurface.UI.empty_state/1`, `loading_state/1`, and `stale_banner/1` are the shared state primitives. Timeline should use them for page-specific states rather than inventing a parallel state family.
- `Threadline.OperatorSurface.Presentation` owns truncation/ref display and operation labels; it should stay the presentation helper rather than duplicating string manipulation in the LiveView.
- `Threadline.OperatorSurface.Exports.FilterParams` is the canonical filter dialect for Timeline and export handoff. Do not create a second export filter vocabulary.
- `Threadline.OperatorSurface.Style.css/1` already contains Timeline command, drawer, row, pager, motion, theme, focus, and responsive contracts.
- `/audit/__stress`, `StressFixtures`, `DESIGN-SYSTEM.md`, and `.planning/design-system-ledger.json` cover generic component/ugly-data proof and should be extended only when Phase 184 adds a genuinely new state/cell.

### Established Patterns

- Root `threadline` keeps Phoenix/LiveView optional and uses `Code.ensure_loaded?` gates.
- Operator UI components are private Phoenix function components, not public API.
- URL state is the durable state for shareable Timeline filters and handoffs.
- Native HTML controls are preferred for date, table, select, buttons, links, and form submission.
- Export routes use direct HTTP controller paths and host-owned export auth; LiveView affordance visibility is not the security boundary.
- Route paths and `data-testid`s are stable operator/test contracts.
- Theme is server-resolved and scoped through `data-tl-theme="dark" | "light" | "system"`, with no localStorage or client-only theme mutation.
- Motion is token-backed, reduced-motion aware, and never decorative. High-frequency Timeline rows must not animate on stream updates.
- Browser tests should assert user-observable behavior, focus, overflow, route transitions, and accessible names rather than snapshotting every visual combination.

### Integration Points

- `TimelineLive` passes `current={:timeline}` into `UI.shell/1`; Phase 184 should not change shell ownership.
- `TimelineLive` builds row links into transaction, actor, correlation, row-history, and export destinations. Keep those route relationships stable.
- `TimelineLive` uses `scope_aware_opts/1` and `scope_query_fn` for scoped reads; do not bypass host scoping in new row or export affordances.
- `TimelineLive` uses `threadline_exports_enabled` and export queue adapter behavior; keep disabled/unavailable export states distinct from empty result states.
- `StartLive` already launches Timeline through Home row-history/correlation earned flows; Phase 184 may strengthen Timeline landing behavior but should not retune Home.
- `ExportStatusLive` owns deeper export status and handoff page polish; Timeline only carries context and queue/download affordances.

</code_context>

<specifics>
## Specific Ideas

- Research-backed synthesis selected a cohesive row-first Timeline: visible starter filters, active filter chips, current facts, rows visible early, advanced filters and handoff in the drawer.
- Recommended visible filters: `from`, `to`, `table`, `correlation_id`.
- Recommended drawer content: `table_schema`, `actor_kind`, `actor_id`, saved views, Coverage/Evidence checks, Carry to Exports, Queue export, and grouped direct downloads.
- Recommended row shape: operation/table/time first; actor and correlation as visible pivots; transaction primary; row history direct only when routeable; copy controls only for full refs that operators actually need.
- Recommended proof shape: Timeline-critical state lattice plus layered source/LiveView/Playwright proof, not exhaustive visual snapshots.
- Recommended copy posture: use Threadline brand voice - calm, exact, useful under incident pressure. Errors name the failed filter/object and next action. Empty states distinguish no-data causes.
- Expert lenses considered: Elixir/Phoenix/LiveView idioms, Plug/export auth boundaries, Ecto/query scoping, OSS library DX, SRE/operator trust states, WCAG/APG accessibility, GOV.UK/Carbon/Primer data UI, Playwright verification, and Threadline brand/JTBD/persona fit.

</specifics>

<deferred>
## Deferred Ideas

- Query-language power-user search (`table:`, `actor:`, `correlation:` qualifiers) is deferred. It may belong in a future search/power-user phase if operator demand appears.
- Persistent desktop filter side rail is deferred. It may be revisited if Timeline becomes a desktop analyst workspace rather than the mounted operator reference workflow.
- Dense fixed-column Timeline table is deferred. It may be useful for future sortable/comparable audit data, but it is not the right mobile-first investigation shape for Phase 184.
- Expandable row raw diff previews are deferred. Transaction/detail pages remain the right place for deeper raw change inspection in this milestone.
- Exports page IA and export-status workflow polish remain Phase 186.
- Coverage audit-readiness workflow polish remains Phase 185.
- Transaction, actor, standalone row-history, Evidence, Redaction, Retention, and Exports page polish remains Phase 186.
- Accessibility/motion/docs/adversarial closeout remains Phase 187, though Phase 184 must preserve Timeline accessibility and motion contracts.
- Broad visual-regression matrix or screenshot SaaS remains deferred unless a future milestone explicitly scopes stable cells and owners.
- Public component API, root Tailwind/shadcn migration, root PhoenixStorybook dependency, production Storybook/stress route, and runtime destructive redaction remain out of scope.
- No matching todo artifacts were found for Phase 184.

</deferred>

---

*Phase: 184-timeline-investigation-flow*
*Context gathered: 2026-06-28*
