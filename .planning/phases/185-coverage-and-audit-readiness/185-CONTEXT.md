# Phase 185: Coverage and audit readiness - Context

**Gathered:** 2026-06-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 185 makes `/audit/coverage` answer one selected-schema readiness question: can an operator rely on Threadline audit history for this schema right now, and if not, what exact capture gap should be fixed next?

This phase is a Coverage page polish and audit-readiness workflow pass. It may change Coverage hierarchy, selected-schema controls, selected-schema metadata, readiness verdict copy, row-level remediation affordances, refresh/stale/error handling, public and non-public schema URL behavior, docs, and focused regression proof.

This phase does not change capture semantics, trigger generation semantics, `Threadline.Health.trigger_coverage/1`'s programmatic contract, auth boundaries, route paths, stable `data-testid`s, the root optional Phoenix/LiveView dependency posture, public component API, Timeline workflow polish, governance/export/detail page polish, runtime destructive redaction, or broad screenshot ownership.

The user selected all gray areas and requested one-shot, subagent-backed recommendations through product, architecture, Elixir/Phoenix/Ecto, OSS library DX, SRE/operator, accessibility, UI/UX, brand, and JTBD lenses. The recommendations below are locked for planning.

</domain>

<decisions>
## Implementation Decisions

### Readiness Hierarchy

- **D-185-01:** Coverage should render one primary selected-schema readiness verdict immediately after the page header. The verdict answers: "Can I rely on audit history for this schema right now?"
- **D-185-02:** Replace the current competing page-level readiness structures - separate trust rail, metric grid, and standalone remediation section - with one consolidated verdict summary. The page should not repeat "needs capture" across multiple page-level blocks.
- **D-185-03:** The verdict summary must include selected schema, checked-at metadata for that schema, covered count, missing/needs-capture count, expected-gap count, and the next action in one scannable unit.
- **D-185-04:** Use status semantics that avoid overclaiming. A schema with expected gaps and zero missing triggers may be "ready for tracked tables" or equivalent, not "all tables complete." A schema with missing triggers is "not ready" or equivalent for audit history reliance.
- **D-185-05:** Keep the table below the verdict as the row comparison and action surface. Tables are appropriate for comparing table name, status, source, and contextual actions; they should not carry the only primary page verdict.
- **D-185-06:** Do not build a dashboard-like metric surface in Phase 185. Trend/SLO dashboards may be useful later, but this phase is about one readiness answer, not metric inflation.
- **D-185-07:** Do not make Coverage table-first. Operators need the selected-schema verdict before they start row triage, especially on 320px/375px viewports.

### Remediation Actions

- **D-185-08:** Use a hybrid remediation model. The verdict summary gives one schema-level next step: fix rows marked `Needs capture`, apply the migration, run the coverage verifier, then refresh.
- **D-185-09:** Keep row-level `Add capture` disclosures for uncovered rows. Row-level placement is the safest place for table-specific command copy and avoids unsafe all-table commands.
- **D-185-10:** Row remediation copy should be CLI-first and exact for Elixir maintainer DX. It should prefer existing Threadline commands such as `mix threadline.gen.triggers --tables ...` and `mix threadline.verify_coverage`, with `--schema=NAME` when relevant.
- **D-185-11:** Command generation must stay conservative. If a table/schema identifier is unsafe, ambiguous, or non-public behavior cannot be expressed safely in the current command helper, show the precise follow-up guidance rather than fabricating a copyable command.
- **D-185-12:** Keep `View activity` only on covered rows as a contextual Timeline pivot. It should preserve non-public schema context with `table_schema=NAME&table=TABLE`; public schema links may omit `table_schema`.
- **D-185-13:** Do not render generic page-level Timeline CTAs from Coverage. Timeline handoff is contextual to covered rows; generic CTAs compete with the readiness/remediation job and can imply incomplete data is reliable.
- **D-185-14:** Expected-gap rows should be marked as intentionally excluded from readiness and should not render `Add capture`.

### Schema Workflow

- **D-185-15:** Use a native select/dropdown as the Phase 185 default schema control, populated from available non-system schemas. Include `public` and the current valid selected schema. Keep the current URL state contract: `/audit/coverage?schema=NAME`.
- **D-185-16:** Reject schema tabs. Tabs imply a small fixed set of panels, add APG/keyboard complexity, risk mobile overflow, and do not match dynamic tenant schemas.
- **D-185-17:** Reject a route-level schema inventory or `/coverage/:schema` route in Phase 185. Route paths are a stable operator contract, and the phase goal is one selected-schema readiness answer, not a schema catalog.
- **D-185-18:** Free-text schema entry with `<datalist>` is not the default. It may be revisited only if real adopter schemas are too numerous for a native select; the current phase should prefer constrained, accessible selection with pasted invalid URLs still handled robustly.
- **D-185-19:** Validation stays at the user-facing LiveView/Mix-task edge via `Threadline.Health.CoverageSchemas`, not inside `Threadline.Health.trigger_coverage/1`. Programmatic callers remain trusted; UI/CLI surfaces validate untrusted schema names.
- **D-185-20:** Invalid schema URLs preserve the rejected URL, show a clear page alert, keep the schema picker usable, and offer an explicit path back to `public`. They must not render stale `public` data as though it belongs to the invalid schema.
- **D-185-21:** `checked_at` means the selected schema's last successful coverage check. Manual refresh re-fetches that selected schema. If refresh fails after a prior success, keep last-good data visible, mark it stale, and do not overwrite the last-success timestamp with a failed-check timestamp.
- **D-185-22:** The surface header badge may continue to query `"public"` only, as currently documented. Multi-schema readiness is explicit on `/audit/coverage` and encoded in that page URL.

### Proof And Regression Scope

- **D-185-23:** Use a targeted Coverage state lattice for Phase 185 proof. The phase must prove COV-01 through COV-03 directly, not rely only on synthetic stress fixtures.
- **D-185-24:** Source/LiveView/doc proof should cover: default `?schema=public`; valid non-public schema; invalid schema; schema selection patch; selected-schema refresh; stale last-good warning; all-empty schema; covered rows with contextual `View activity`; uncovered rows with `Add capture`; expected-gap rows without remediation; and docs for schema selection, refresh, and non-public row links.
- **D-185-25:** Browser proof should stay narrow and user-observable: mobile readability/no horizontal overflow, native schema control reachability, row disclosure/copy layout, focus visibility, and non-public/public link behavior where browser proof adds confidence over LiveView tests.
- **D-185-26:** Do not create a broad route x theme x viewport screenshot matrix. Prior v1.38 decisions rejected broad screenshot churn; Playwright should assert behavior and layout affordances, not become a pixel-baseline expansion.
- **D-185-27:** Existing `/audit/__stress`, `StressFixtures`, `DESIGN-SYSTEM.md`, `.planning/design-system-ledger.json`, style contracts, and Phase 187 closeout remain the place for generic loading/error/permission/unavailable/theme/motion proof unless Phase 185 changes Coverage-specific CSS or state semantics.
- **D-185-28:** Tests should prefer behavior and user-facing contracts. Use role/name/test-id locators in browser tests, LiveView tests for URL/event/state behavior, and source/doc contracts for stable copy and docs anchors.

### Product, JTBD, And UX Posture

- **D-185-29:** Optimize Coverage for P1 incident responders, P2 support agents, P3 compliance/security reviewers, P4 audit/SRE operators, and P5 adopter developers. The common job is not "view coverage metrics"; it is "know whether audit history for this schema can be relied on, and fix the gap if it cannot."
- **D-185-30:** Apply the who/what/where/when/why lens:
  - Who: operators and maintainers with access to the mounted Coverage surface.
  - What: choose a schema, read the readiness verdict, inspect missing/covered/expected rows, copy or follow remediation, refresh, and pivot to Timeline only when coverage exists.
  - Where: `/audit/coverage`, with row-level handoff to `/audit/timeline`.
  - When: after deploys, before relying on Timeline during incidents, during support triage, during audit-readiness sweeps, and while validating a tenant/non-public schema.
  - Why: make capture drift impossible to miss without forcing operators to understand trigger internals first.
- **D-185-31:** Use canonical domain language: Coverage, audit readiness, selected schema, checked, tracked tables, covered, needs capture, expected gap, Add capture, verify coverage, refresh, View activity, Timeline, public schema, non-public schema.
- **D-185-32:** Hide backend implementation details unless they affect trust or next action. It is acceptable to mention missing triggers, schema scope, `mix threadline.gen.triggers`, `mix threadline.verify_coverage`, and stale last-good data. Avoid exposing raw catalog-query details, `pg_namespace`, internal polling implementation, or trigger SQL internals in primary UI copy.
- **D-185-33:** Preserve Threadline brand posture: calm in tense moments, exact without being cold, useful over impressive, dense but scannable, color as signal not decoration, accessible focus/hover/disabled states, dark/light/system support, and no decorative motion or gradient/orb treatment.
- **D-185-34:** Empty/error copy must state what happened, why if known, and the next action. Distinguish "schema not found," "no audited tables found for this schema," "coverage refresh failed but last-good data remains," and "coverage unavailable in this support lane."

### Architecture And Implementation Posture

- **D-185-35:** Stay inside the existing private Phoenix LiveView component system. Prefer private function components/helpers and `attr`/slot contracts where they reduce duplication; do not introduce LiveComponents for organization.
- **D-185-36:** Keep LiveView as orchestration/presentation. Validation of user-provided schema names belongs at the UI/CLI edge; `Threadline.Health.trigger_coverage/1`, `Coverage.Snapshot`, `Coverage.OnMount`, and existing health modules remain the domain/integration authority.
- **D-185-37:** Preserve existing route paths, `data-testid`s, feature gates, auth posture, optional Phoenix/LiveView dependency boundaries, theme contract, native controls, and CSP-friendly no-inline-handler posture.
- **D-185-38:** Do not add a dependency, Tailwind/shadcn migration, client-side router, custom select widget, custom command palette, localStorage behavior, visual-regression SaaS, or new public API for this phase.
- **D-185-39:** Use current assets before inventing new abstractions: `CoverageLive`, `Coverage.Snapshot`, `Coverage.OnMount`, `CoverageSchemas`, `Presentation.coverage_remediation/2`, `UI.page_header`, `UI.ref`/copy patterns if needed, `UI.empty_state`/alert patterns if suitable, `style.ex`, `coverage_live_test`, `coverage_doc_contract_test`, existing Playwright suites, and `/audit/__stress`.

### Claude's Discretion

The user explicitly asked for all gray areas to be considered with research-backed, cohesive recommendations. Downstream agents may choose exact helper names, CSS selectors, component extraction, plan count, task slicing, and test organization if they preserve the decisions above and keep Phase 185 scoped to Coverage audit readiness.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Authority

- `.planning/ROADMAP.md` - Phase 185 goal, success criteria, and ownership boundary with Phases 184, 186, and 187.
- `.planning/REQUIREMENTS.md` - COV-01, COV-02, COV-03, milestone invariants, traceability, and out-of-scope constraints.
- `.planning/PROJECT.md` - active v1.38 posture, shipped context, optional-dependency boundary, and standing no-regression rules.
- `.planning/research/v1.38-operator-ui-page-polish.md` - accepted page order, Storybook/stress boundary, motion posture, and page-by-page cleanup rationale.

### Prior Phase Context

- `.planning/phases/184-timeline-investigation-flow/184-CONTEXT.md` - Timeline decisions for row-first workflow, contextual handoff, URL-backed filters, state lattice, copy posture, and proof strategy.
- `.planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md` - shell/Home decisions, native controls, route/test-id stability, verification posture, JTBD language, and page-boundary rules.
- `.planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md` - Storybook versus `/audit/__stress` boundary, private component catalog posture, and bounded browser proof lesson.

### Brand, Product, And Prompt Corpus

- `brandbook/brand-book.md` - current Threadline brand source of truth, voice, visual principles, UI theming posture, component rules, and microcopy guidance. This supersedes older prompt-era brand details if they conflict.
- `brandbook/README.md` - brand artifact roles and warning that `lib/threadline/operator_surface/style.ex` is the product UI contract.
- `prompts/audit-lib-domain-model-reference.md` - capture/semantics/exploration/operations split, Coverage as operational confidence, canonical nouns, and "hardest to get wrong, easiest to understand, easiest to operate" principle.
- `prompts/threadline-elixir-oss-dna.md` - verification-as-product, named `mix verify.*` commands, docs/contracts, optional dependency hygiene, and OSS library habits.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` - audit ecosystem lessons: trigger-backed capture, action context, operator tooling, coverage checks, and footguns from missed writes/opaque storage/context loss.
- `prompts/prior-art/SOURCE-CANONICAL.md` - prompt corpus provenance and which prior-art files are canonical.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` - LiveView contexts/components/URL state/forms/security/testing guidance.
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md` - Phoenix structure, contexts, function components, forms, and LiveView boundary guidance.
- `prompts/prior-art/oss-deep-research/ecto-best-practices-deep-research.md` - Ecto boundary, query, transaction, constraint, and context guidance.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - Plug/Phoenix/Ecto production guidance, state placement, telemetry, and BEAM/Phoenix footguns.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` - Elixir OSS library API/DX, explicit boundaries, runtime options, docs, and anti-patterns.
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - layered CI, docs-as-product, coverage as signal, and release/verification hygiene.

### Existing Coverage Code And Guardrails

- `lib/threadline/operator_surface/live/coverage_live.ex` - Coverage page owner: schema URL state, schema form, selected-schema fetch, readiness copy, row remediation, Timeline row links, invalid schema, refresh, and rendering hierarchy.
- `lib/threadline/operator_surface/coverage/snapshot.ex` - coverage snapshot counts, last checked metadata, buckets, and empty snapshot contract.
- `lib/threadline/operator_surface/coverage/on_mount.ex` - surface-header public-schema polling, timer refresh, last-good error policy, telemetry on failure, and polling interval floor.
- `lib/threadline/health/coverage_schemas.ex` - user-facing schema validation and available schema listing.
- `lib/threadline/operator_surface/presentation.ex` - remediation/copy helpers and presentation vocabulary for coverage actions.
- `lib/threadline/operator_surface/style.ex` - product UI CSS contract for page header, schema picker, tables, trust rail, remediation, responsive behavior, focus, theme, and motion.
- `lib/threadline/operator_surface/components/surface_header.ex` - public-schema coverage badge behavior and shell/topbar integration.
- `lib/threadline/operator_surface/ui.ex` - private component primitives and state components to reuse before inventing new abstractions.
- `lib/threadline/operator_surface/router.ex` - mounted operator routes, live_session on_mount order, optional LiveView boundary, and route stability.
- `lib/threadline/operator_surface/auth.ex` - host-owned auth, theme assignment, scope/actor assigns, and surface context.
- `lib/threadline/operator_surface/stress_fixtures.ex` - generic Coverage stress fixtures and page-state registry.
- `DESIGN-SYSTEM.md` - current design-system ledger projection, including Coverage page stress cells.
- `.planning/design-system-ledger.json` - ratchet, stress entries, screenshot allowlist, current/reserved inventory, and Coverage page entries.

### Existing Tests To Build On

- `test/threadline/operator_surface/live/coverage_live_test.exs` - Coverage URL/schema/row/action/refresh/header contracts and current source-of-truth tests.
- `test/threadline/operator_surface/coverage_doc_contract_test.exs` - docs/source contracts for Coverage dashboard, schema behavior, Mix-task parity, and route literals.
- `test/threadline/operator_surface/coverage/on_mount_test.exs` - Coverage on_mount polling and error behavior.
- `test/threadline/operator_surface/coverage_mix_test.exs` - Mix-task coverage behavior and CLI surface.
- `test/threadline/verify_coverage_task_test.exs` - verifier task behavior.
- `test/threadline/verify_coverage_policy_test.exs` - coverage policy behavior.
- `test/threadline/operator_surface/style_contract_test.exs` - Coverage CSS, responsive table, command-copy layout, and retired command-shell contracts.
- `test/threadline/operator_surface/card_nesting_regression_test.exs` - regression guard for the prior Coverage card-in-card footgun.
- `test/threadline/operator_surface/stress_fixtures_test.exs` - Coverage stress fixture registry and ledger parity.
- `test/threadline/operator_surface/copy_contract_test.exs` - shell group labels, unsupported copy, and unsafe vocabulary refutes.
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` - route matrix, Coverage mobile/readability/table/action checks, and no-overflow proof.
- `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` - Coverage mobile Add capture remediation and overflow proof.
- `examples/threadline_phoenix/e2e/tests/operator-features.spec.ts` - Coverage row/header badge behavior.
- `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` - existing bounded screenshot captures; do not expand casually.
- `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` - `/audit/__stress` behavior and stress-route semantics.

### Docs To Keep Aligned

- `guides/operator-surface.md` - Coverage dashboard, multi-schema behavior, row-history/schema map, Mix-task parity, auth/export/scope docs, and route/function contracts.
- `guides/production-checklist.md` - production trigger coverage and coverage drift guidance.
- `guides/how-threadline-works.md` - Coverage as operational confidence in the broader Threadline model.
- `guides/adoption-evidence-playbook.md` - audit-readiness and evidence handoff references.
- `README.md` - high-level operator surface and verification claims if touched by planning.

### External References Used For Research

- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html` - function components, attrs, slots, and compile-time component contracts.
- `https://hexdocs.pm/phoenix_live_view/live-navigation.html` - patch/navigation and URL-backed LiveView state.
- `https://hexdocs.pm/phoenix_live_view/form-bindings.html` - LiveView form submit/change behavior.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html` - behavior-focused LiveView testing APIs.
- `https://hexdocs.pm/phoenix/scopes.html` - Phoenix scope/security model and scoped context patterns.
- `https://hexdocs.pm/phoenix/security.html` - Phoenix security guidance.
- `https://hexdocs.pm/ecto/Ecto.Repo.html` - Ecto transaction/Multi behavior and repo guidance.
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.html` - host-mounted operational dashboard precedent and production auth guidance.
- `https://oban.pro/docs/web/installation.html` - mounted operational dashboard precedent, resolver customization, access control, query limits, and refresh posture.
- `https://github.com/bitcrowd/carbonite` - trigger-backed audit capture precedent and database transaction as auditing unit.
- `https://github.com/paper-trail-gem/paper_trail` - audit/versioning UI and reification precedent.
- `https://django-auditlog.readthedocs.io/` - simple reusable audit app precedent with actor/correlation/masking lessons.
- `https://django-simple-history.readthedocs.io/` - history/as-of/operator docs and bulk-operation footguns.
- `https://docs.cloud.google.com/logging/docs/audit` - audit-log concept precedent and volume/enablement caution.
- `https://carbondesignsystem.com/components/data-table/usage/` - data-table hierarchy, row actions, toolbar scope, and data density guidance.
- `https://carbondesignsystem.com/patterns/filtering/` - filtering/selection patterns for large data sets.
- `https://carbondesignsystem.com/patterns/empty-states-pattern/` - empty-state specificity and next-action guidance.
- `https://primer.style/components/data-table` - mature product data-table precedent.
- `https://design-system.service.gov.uk/components/table/` - accessible table/header guidance.
- `https://design-system.service.gov.uk/components/summary-list/` - key fact / metadata summary pattern.
- `https://www.w3.org/TR/WCAG22/` - WCAG 2.2 use of color, contrast, focus order, labels, and input assistance.
- `https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html` - visible focus requirements.
- `https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/` - disclosure/show-hide pattern for row remediation.
- `https://playwright.dev/docs/best-practices` - user-visible behavior, locator, and test isolation guidance.
- `https://testing-library.com/docs/guiding-principles/` - user-like testing principle.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Threadline.OperatorSurface.Live.CoverageLive` already owns the selected-schema URL state, schema validation call, refresh event, row buckets, remediation disclosures, and public/non-public Timeline links.
- `Threadline.OperatorSurface.Coverage.Snapshot` already gives counts, buckets, `last_checked_at`, and an `error` field; it can support a consolidated readiness verdict without new domain storage.
- `Threadline.OperatorSurface.Coverage.OnMount` already polls `"public"` for the surface header and preserves last-good public coverage on failure. Phase 185 should keep that header behavior distinct from selected-schema page behavior.
- `Threadline.Health.CoverageSchemas` already provides conservative schema validation and available schema listing for UI/Mix surfaces.
- `Threadline.OperatorSurface.Presentation.coverage_remediation/2` is the likely place to keep row remediation labels, commands, and follow-up copy centralized.
- `Threadline.OperatorSurface.UI.page_header/1` already supports the Coverage header actions/meta shape.
- Existing native controls (`form`, submit button, select/input, details/summary) are preferred over custom widgets.
- `Threadline.OperatorSurface.Style.css/1` has Coverage-specific table/action/remediation responsive rules; modify in place and keep style contracts paired with CSS changes.
- Existing Playwright route matrix and mobile Coverage assertions can be extended narrowly instead of adding a new broad lane.
- `/audit/__stress`, `StressFixtures`, `DESIGN-SYSTEM.md`, and `.planning/design-system-ledger.json` already cover generic Coverage page-state cells and should remain generic proof, not a substitute for live schema behavior.

### Established Patterns

- Root `threadline` keeps Phoenix/LiveView optional and uses `Code.ensure_loaded?` gates.
- Operator UI components are private Phoenix function components, not public API.
- URL state is durable state for shareable/recoverable operator workflows.
- Native HTML controls are preferred for forms, schema selection, disclosures, links, and buttons.
- Host-owned auth, feature gates, `coverage_authorize_fn`, and surface scope boundaries remain the authority for access.
- Route paths and `data-testid`s are stable operator/test contracts.
- Theme is server-resolved and scoped through `data-tl-theme`, with no localStorage or client-only theme behavior.
- Motion is token-backed, reduced-motion aware, and never decorative.
- Browser tests should assert user-visible behavior, accessible names, focus, overflow, and route transitions rather than implementation internals or broad screenshots.
- Docs and source contracts are treated as product surfaces; if operator docs change, doc-contract tests should change with them.

### Integration Points

- `CoverageLive.handle_params/3` is the integration point for `?schema=NAME` URL state and invalid schema behavior.
- `CoverageLive.handle_event("select-schema", ...)` should remain the explicit user-request path for schema switching. Avoid automatic context change on input focus/change.
- `CoverageLive.handle_event("refresh", ...)` should refresh the selected schema and preserve last-good semantics.
- `timeline_table_path/3` must keep public/non-public row links correct.
- `Coverage.OnMount` still feeds `@threadline_coverage` for the shell/header public-schema badge; do not conflate it with selected-schema `@coverage_for_schema`.
- `guides/operator-surface.md` and `coverage_doc_contract_test.exs` must stay aligned with any schema picker, stale refresh, and remediation wording changes.
- Existing E2E tests under `examples/threadline_phoenix/e2e/tests/` are the right browser proof lane for live Coverage behavior.

</code_context>

<specifics>
## Specific Ideas

- Primary verdict example shape: "Not ready for `tenant_demo`: 3 tables need capture. Checked 14:32 UTC." The exact copy may vary, but it must answer readiness before table triage.
- Ready-state copy should avoid "complete timeline answers" or "capture is complete"; use precise wording such as ready for tracked tables, all tracked tables covered, or expected gaps excluded from readiness.
- The verdict summary should carry the only page-level remediation sentence. Row-level disclosures carry exact per-table commands and follow-up.
- Keep `Add capture` as a native disclosure because it is compact, keyboard-operable, and already aligned with the current table action model.
- Use `mix threadline.verify_coverage --schema=NAME` for non-public selected schemas in remediation/docs where the command exists.
- Preserve `View activity` for covered rows only; it should not appear as a generic top-level "Open Timeline" action.
- Use constrained schema selection by default. Pasted invalid URLs are still supported through validation and recovery, but normal users should not be led into invalid input.
- The strongest proof shape is a Coverage-specific state lattice plus one narrow browser path, not screenshots.

</specifics>

<deferred>
## Deferred Ideas

- Coverage trend/SLO dashboard, historical drift charts, or readiness over time are deferred. They would be a new monitoring capability, not Phase 185 page polish.
- Schema tabs are rejected for Phase 185 and deferred unless a future fixed-small-schema UX is explicitly scoped.
- A route-level schema inventory or `/coverage/:schema` route is deferred/rejected for Phase 185 because route paths are stable operator contracts.
- Free-text schema search/datalist remains a fallback idea only if real adopter schema counts make native select untenable.
- Broad visual screenshot matrix remains deferred; promoted screenshot cells need explicit future ownership.
- Generic page-level Timeline CTAs from Coverage are rejected. Timeline links remain contextual row actions.
- Timeline workflow polish remains Phase 184 and is already complete.
- Transaction, actor, row-history, Evidence, Exports, Redaction, and Retention workflow polish remains Phase 186.
- Accessibility/motion/docs/adversarial closeout remains Phase 187, though Phase 185 must preserve the relevant Coverage accessibility and docs contracts.
- Public component API, root Tailwind/shadcn migration, root PhoenixStorybook dependency, production Storybook/stress route, and runtime destructive redaction remain out of scope.
- No matching todo artifacts were found for Phase 185.

</deferred>

---

*Phase: 185-coverage-and-audit-readiness*
*Context gathered: 2026-06-29*
