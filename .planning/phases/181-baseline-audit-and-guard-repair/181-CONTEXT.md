# Phase 181: Baseline audit and guard repair - Context

**Gathered:** 2026-06-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 181 establishes current rendered truth for the mounted `/audit` operator surface before page-by-page polish begins. It produces a baseline audit packet, repairs stale or broken verification guards that protect existing invariants, and records the compact operator/JTBD/design-system context that later v1.38 phases must follow.

This phase is not a redesign phase. It may fix broken guardrails and stale tests/selectors when the fix restores an accepted v1.37 or v1.38 invariant. It must not change capture/query/auth semantics, route paths, feature gates, public component API, root dependencies, or page IA/visual hierarchy except for minimal additive hooks needed to make existing guards truthful.

</domain>

<decisions>
## Implementation Decisions

### Baseline Evidence Shape

- **D-181-01:** Phase 181 baseline evidence is an audit packet, not a screenshot dump. Every `/audit` page should be mapped to its operator JTBD, current route/rendering evidence, screenshot coverage, stale selectors/tests, issue taxonomy, and guard disposition.
- **D-181-02:** The audit packet should produce planner-consumable artifacts:
  - `181-BASELINE-AUDIT.md` - page/JTBD matrix, visible issues, risk taxonomy, ownership by later phase.
  - `181-SCREENSHOT-INVENTORY.md` - current screenshot status, viewport/theme coverage, local/CI distinction, stale or missing baselines.
  - `181-GUARD-REPAIR.md` - stale selector/test/source-contract findings and any repairs performed.
  - `181-VERIFICATION.md` - evidence that BASE-01, BASE-02, and BASE-03 are satisfied.
- **D-181-03:** Use a consistent issue taxonomy so findings do not become unowned prose:
  - JTBD/IA drift
  - stale selector or copy contract
  - screenshot or ledger drift
  - accessibility/focus/motion proof gap
  - route/auth/feature-gate invariant gap
  - later-phase polish follow-up

### Guard Repair Boundary

- **D-181-04:** Phase 181 uses a bounded repair-now policy. It should patch broken guardrails immediately when the change restores an existing invariant or accepted v1.37 contract.
- **D-181-05:** Allowed now:
  - update stale E2E selectors to current stable `data-testid`, role, URL, or rendered behavior;
  - retire removed contracts only with rationale and replacement/owner;
  - repair `/audit/__stress` fixtures, ledger rows, `DESIGN-SYSTEM.md`, screenshot allowlist references, and projection freshness without lowering ratchets;
  - add focused source-contract tests for routes, feature gates, stable IDs, optional dependencies, auth/export/stress boundaries, and no-production stress/story exposure;
  - restore missing semantic guard hooks only when additive and non-redesign, such as a missing `data-testid`, `aria-current`, or feature-gated nav assertion.
- **D-181-06:** Deferred to later phases:
  - Shell/Home/Timeline/Coverage visual hierarchy, CTA strategy, IA, copy polish, layout redesign, motion polish, and design-approved screenshot rebaselining;
  - route path changes or `data-testid` renames/removals unless a later phase records and verifies the breaking change;
  - capture/query/auth semantic changes, public component API, root PhoenixStorybook dependency, production Storybook/stress route, Tailwind/shadcn migration, and runtime destructive redaction.

### Audit Matrix Strictness

- **D-181-07:** Use a tiered matrix rather than a full pixel snapshot explosion.
  - **Tier A - source/CI contracts:** enforce full registry/manifest truth for 11 pages x 7 paths, themes `dark|light|system`, viewports `320|375|768|1024|1440`, ledger freshness, story/fixture parity, route/auth gates, feature gates, and no score backslide.
  - **Tier B - rendered CI slices:** run representative Chromium checks, baseline-free where possible, for overflow/nav/header behavior across all real `/audit` pages at 320 and 1440; include Shell/Home/Timeline/Coverage at 375/768/1024 and keep dark plus existing light/system coverage where already supported.
  - **Tier C - local/human packet:** capture/review all 11 real pages at desktop 1280 and mobile 375, plus light desktop for Shell/Home/Timeline/Coverage and selected stress stories for happy/error/permission/boundary states.
- **D-181-08:** Keep the existing bounded screenshot CI allowlist unless a later page phase promotes specific cells. Full page x path x theme x viewport pixel baselines are too costly and flaky for the baseline phase; CI-allowlist-only is too weak to satisfy BASE-01.

### Operator Context, JTBD, and Design Contract

- **D-181-09:** v1.38 page plans should use a compact operator-context contract, not a new broad research reset. The context contract includes personas/JTBD, who/what/where/when/why, canonical nouns, UI events/verbs, page/JTBD matrix, design pillars, and guardrails.
- **D-181-10:** Primary personas:
  - Incident/support operator - needs to find what changed and explain it under pressure.
  - Audit-readiness/security/platform operator - needs to know whether capture is complete enough to trust.
  - Governance/export operator - needs evidence, retention/redaction posture, and handoff artifacts.
  - Adopting developer/maintainer - needs the mounted UI to be Phoenix-native, debuggable, optional-dependency friendly, and stable across host apps.
- **D-181-11:** Core JTBD:
  - Find what happened.
  - Verify capture readiness.
  - Inspect evidence/governance safely.
  - Export/share current evidence.
  - Maintain the UI without public component or dependency leakage.
- **D-181-12:** Canonical domain language for the UI and planning: Audit Action, Audit Transaction, Audit Change, Actor, Subject, Request, Job, Correlation, Coverage, Evidence, Redaction, Retention, Export, Saved View, Timeline Entry, Diff, Snapshot.
- **D-181-13:** Canonical UI verbs/events: filter, scan, open, copy, compare, refresh, remediate, queue export, download, confirm destructive action, return.
- **D-181-14:** Design pillars for v1.38 page work:
  - task-led orientation;
  - semantic-first raw-on-demand detail;
  - dense but scannable data;
  - explicit trust state;
  - accessible native-first interaction;
  - composed Threadline brand across dark/light/system;
  - purposeful motion and performance;
  - Phoenix/LiveView-native maintainer DX.
- **D-181-15:** Hide backend implementation details from operators unless the detail is necessary for remediation, proof, or performance constraints. Prefer operator language first; expose technical anchors as secondary raw detail, copyable refs, commands, or docs links.
- **D-181-16:** Current brand truth comes from `brandbook/brand-book.md`, not older prompt-era brand text when they conflict. The operator surface remains dark-primary with fully shipped light/system lanes via host config and cookie-based runtime picker, no localStorage, no JS theming, and no decorative consumer-app effects.

### Page/JTBD Matrix

| Surface | Primary JTBD | Phase Owner |
|---------|--------------|-------------|
| Shell/global nav | Know where I am, what destinations exist, and what is currently active | 183 |
| Home `/audit` | Pick the right operator job without reading an info dump | 183 |
| Timeline | Filter, scan, open transaction/row history, and export current view | 184 |
| Coverage | Answer whether one schema is audit-ready and what to fix next | 185 |
| Transaction detail | Explain one transaction and its changed rows | 186 |
| Row history | Reconstruct one row's history/as-of context | 186 |
| Actor detail | Understand what one actor did and where to go next | 186 |
| Evidence | Inspect proof records without implying broader compliance theater | 186 |
| Exports | Prepare or retrieve current-view handoff artifacts safely | 186 |
| Redaction | Understand redaction posture without offering unscoped destructive runtime redaction | 186 |
| Retention | Review retention/prune consequences with type-to-confirm safety | 186 |
| Stress route `/audit/__stress` | Maintainer-only component/page/fixture ratchet evidence | 181, 182, 187 |

### Claude's Discretion

The user explicitly asked for a one-shot, research-backed recommendation set and did not want piecemeal choices. Downstream planning may choose exact file splits and task sequencing, but must preserve the decisions above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Authority

- `.planning/ROADMAP.md` - v1.38 phase sequence, Phase 181 goal, and success criteria.
- `.planning/REQUIREMENTS.md` - BASE-01, BASE-02, BASE-03, milestone invariants, and traceability.
- `.planning/PROJECT.md` - current product posture, decisions, prior milestones, and v1.38 context.
- `.planning/research/v1.38-operator-ui-page-polish.md` - accepted v1.38 research summary and decisions.

### Current Brand Truth

- `brandbook/brand-book.md` - source-of-truth brand guide, voice, visual principles, current theming posture.
- `brandbook/pressure-test.md` - brand QA and pressure-test guidance.
- `brandbook/tokens.json` - source brand token inventory.
- `brandbook/README.md` - artifact roles and warning to treat `style.ex` as the product UI contract.

### Prompt Corpus Considered

- `prompts/THREADLINE-GSD-IDEA.md` - original product principles and Threadline vision.
- `prompts/threadline-elixir-oss-dna.md` - verification-as-product, examples/host proof, docs/contracts, CI hygiene.
- `prompts/audit-lib-domain-model-reference.md` - capture/semantics/exploration layers and canonical domain nouns.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` - ecosystem lessons and audit-library footguns.
- `prompts/prior-art/SOURCE-CANONICAL.md` - prompt corpus provenance map.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` - Elixir OSS library API/DX principles.
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - CI/CD and verification hygiene.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - Phoenix/Plug/Ecto architecture and operations patterns.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` - LiveView contexts/components/URL state/streams/security/testing guidance.
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md` - Phoenix structure and operational guidance.
- `prompts/prior-art/oss-deep-research/ecto-best-practices-deep-research.md` - Ecto correctness and query/data boundary guidance.
- `prompts/prior-art/from-sigra/Phoenix Auth Library — Jobs to Be Done, Personas & User Flows.md` - persona/JTBD structure reference; concepts adapted, scope not imported.

### Existing Code and Guardrails

- `DESIGN-SYSTEM.md` - current projection of the design-system ledger.
- `.planning/design-system-ledger.json` - ratchet, entries, screenshot allowlist, required inventory.
- `lib/threadline/operator_surface/stress_fixtures.ex` - canonical stress story registry, page/path/theme/viewport manifest.
- `lib/threadline/operator_surface/live/stress_live.ex` - stress route rendering and ledger presentation.
- `lib/threadline/operator_surface/components/surface_header.ex` - global shell/nav/theme/coverage/status affordances.
- `lib/threadline/operator_surface/ui.ex` - private function component system and reusable patterns.
- `lib/threadline/operator_surface/style.ex` - product UI CSS contract and theme/motion/interaction rules.
- `lib/threadline/operator_surface/router.ex` - mounted operator routes, auth/export/theme/stress boundary.
- `lib/threadline/operator_surface/live/start_live.ex` - Home task launcher and earned flows.
- `lib/threadline/operator_surface/live/timeline_live.ex` - primary investigation workflow.
- `lib/threadline/operator_surface/live/coverage_live.ex` - audit-readiness workflow.
- `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` - stress route browser semantics and bounded screenshot allowlist.
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` - local screenshot regression guard.
- `test/threadline/operator_surface/stress_ledger_test.exs` - ledger/story/projection ratchet contract.
- `test/threadline/operator_surface/stress_router_test.exs` - stress route story availability contract.
- `test/threadline/operator_surface/stress_fixtures_test.exs` - fixture and matrix contracts.
- `test/threadline/operator_surface/style_contract_test.exs` - source CSS/theming/a11y/motion contracts.
- `test/threadline/operator_surface/surface_header_test.exs` - shell/nav/header contract tests.

### External References Used For Research

- PhoenixStorybook docs and package pages - component/story lane shape, variations, dev tooling.
- Phoenix LiveView `Phoenix.Component` docs - attrs/slots and function component idioms.
- Phoenix LiveView routing/navigation/security docs - `live_session`, `on_mount`, URL state, patch/navigate.
- Phoenix LiveDashboard docs - mounted operator/admin surface precedent.
- Oban Web installation docs - host-mounted LiveView dashboard precedent and auth/route ownership.
- Sentry Elixir Plug/Phoenix docs - Phoenix/Plug integration without over-coupling.
- WAI-ARIA Authoring Practices Guide and WCAG 2.2 - keyboard/focus/widget expectations.
- GOV.UK Design System and Service Manual - user-needs, error handling, plain-language service design.
- Carbon Design System data table and empty state guidance - dense data, status, empty-state patterns.
- Primer color/theming guidance - multi-theme design-system discipline.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Threadline.OperatorSurface.UI.shell/1` and `SurfaceHeader.surface_header/1`: existing shell/nav/status/theme structure; Phase 181 should audit and contract it, not redesign it.
- `Threadline.OperatorSurface.UI.page_header/1`, `data_panel/1`, `toolbar/1`, `detail_header/1`, `empty_state/1`, `loading_state/1`, `stale_banner/1`, `ref/1`, `kv/1`, `data_table/1`: private component substrate for later page phases.
- `Threadline.OperatorSurface.StressFixtures`: current registry for foundation, primitive, form, group, state, page, footgun, and future-reserved stories.
- `.planning/design-system-ledger.json` + `DESIGN-SYSTEM.md`: existing ratchet and projection mechanism; Phase 181 must keep them fresh and must not lower scores silently.
- Playwright E2E suite under `examples/threadline_phoenix/e2e/tests/`: rendered browser coverage, screenshot guard, stress route semantics, accessibility/motion/responsive checks.

### Established Patterns

- Private component system only; no public component API.
- Root `threadline` keeps Phoenix/LiveView optional and uses `Code.ensure_loaded?` boundaries.
- Operator route stability matters; routes and `data-testid`s are part of the power-user/test contract.
- Theme is server-resolved and CSS-scoped (`dark|light|system`), with no localStorage and no JS theme flash.
- LiveView state that users should share or recover belongs in URL params where practical.
- Large/dense result surfaces use streams or bounded data panels rather than ad hoc page-specific markup.
- Motion must be token-backed, transform/opacity oriented, reduced-motion aware, and never `transition: all`.

### Integration Points

- Phase 181 plans should inspect and repair contracts around `router.ex`, `surface_header.ex`, `stress_fixtures.ex`, `stress_live.ex`, `style.ex`, ledger/projection docs, and E2E tests.
- Phase 182 will add PhoenixStorybook only in `examples/threadline_phoenix` dev/test; Phase 181 should document the current stress route boundary so Storybook does not replace it.
- Phases 183-187 consume the baseline packet and issue taxonomy to avoid re-auditing from scratch.

</code_context>

<specifics>
## Specific Ideas

The user asked to discuss all gray areas with research-first subagents and wanted one coherent recommendation set. The synthesis emphasized:

- Elixir/Phoenix idioms: explicit boundaries, optional dependencies, host-owned auth, LiveView `on_mount` checks, function components with attrs/slots, URL state, source contracts, named verification commands.
- OSS DX: verification as a product surface, flat runnable commands, stable CI/job/test IDs, docs/contract tests, example-app proof, no hidden skips.
- Operator UX: task-led surfaces, calm precise copy, raw technical detail only when needed for remediation/proof, dense scannable data, strong trust states, native controls where possible, accessible focus/keyboard behavior.
- Brand: current `brandbook/brand-book.md` wins over older prompt brandbook text where they conflict; Threadline should feel composed, exact, inspectable, and useful over impressive.

</specifics>

<deferred>
## Deferred Ideas

- PhoenixStorybook implementation belongs to Phase 182.
- Shell/Home orientation and nav polish belong to Phase 183.
- Timeline workflow polish belongs to Phase 184.
- Coverage audit-readiness polish belongs to Phase 185.
- Detail/governance/export page polish belongs to Phase 186.
- Accessibility/motion/docs/adversarial closeout belongs to Phase 187.
- Public component API, root Storybook dependency, runtime destructive redaction, Tailwind/shadcn migration, and production stress/story routes remain out of scope for v1.38 unless a later milestone explicitly reopens them.

</deferred>

---

*Phase: 181-Baseline audit and guard repair*
*Context gathered: 2026-06-26*
