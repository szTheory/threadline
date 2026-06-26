# Phase 182: PhoenixStorybook example/dev lane - Context

**Gathered:** 2026-06-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 182 adds PhoenixStorybook as example-app maintainer tooling for reviewing Threadline's private operator-surface components and representative states. The lane exists inside `examples/threadline_phoenix` only, is dev/test only, and is not a root `threadline` dependency, a production route, a public component API, or a replacement for `/audit/__stress`.

The phase should improve maintainer DX and design review confidence before the page-by-page polish phases. It must preserve root optional Phoenix/LiveView boundaries, route stability, auth boundaries, `data-testid` stability, the v1.37 design-system ratchet, and the Phase 181 finding that `/audit/__stress` remains the authenticated operator-flow stress harness.

</domain>

<decisions>
## Implementation Decisions

### Storybook Mounting Boundary

- **D-182-01:** Mount PhoenixStorybook only in `examples/threadline_phoenix`, not in root `mix.exs`, root `lib/`, or the public `threadline_operator_surface/2` macro.
- **D-182-02:** Use `/dev/storybook` as the maintainer route. Keep it outside `/audit` so maintainers do not mistake Storybook for an operator/adopter route or for `/audit/__stress`.
- **D-182-03:** Follow PhoenixStorybook's router shape: use a root `scope "/"` with full `/dev/storybook` path and `storybook_assets`, rather than trying to nest `live_storybook` inside a non-root path scope.
- **D-182-04:** Gate the route to dev/test only with the existing example-app `dev_routes` style and compile/runtime checks. Production must have no live Storybook route, no Storybook assets route, and no demo exposure.
- **D-182-05:** Do not require normal operator login for the local maintainer component lab unless implementation discovers that the route is exposed beyond local/dev use. If auth is added, it must be a dev/test maintainer guard and must not imply Storybook is part of the mounted operator surface.

### Story Source Of Truth

- **D-182-06:** Use curated PhoenixStorybook stories plus small shared fixture helpers. Do not hand-author every state from scratch, and do not generate a full Storybook mirror from `.planning/design-system-ledger.json` or `StressFixtures`.
- **D-182-07:** `Threadline.OperatorSurface.StressFixtures` remains the canonical ugly-data and flow-state registry for `/audit/__stress`. Storybook may sample from it through explicit, read-only helpers and allowlists, but the ledger is not a Storybook navigation API.
- **D-182-08:** Storybook examples should be maintainer-readable component documentation: focused variations, clear notes, slots/templates where useful, and code previews. They should not become page-flow tests.
- **D-182-09:** Do not add public-facing `@doc` prose to private operator components just to feed Storybook. Use story notes, pages, and index files for maintainer documentation so the private component boundary stays clear.

### Component Catalog Shape

- **D-182-10:** Use a hybrid catalog with component categories as the primary spine:
  - `Foundations`
  - `Primitives`
  - `Forms`
  - `States`
  - `Overlays`
  - `Data Display`
  - `Groups`
- **D-182-11:** Add a small `Patterns` branch only for recurring operator assemblies that help maintainers understand component composition, such as toolbar plus filters, detail header plus metadata, data panel plus empty/loading/pager, modal destructive action, offline/reconnect group, and permission-denied group.
- **D-182-12:** Keep page-level flows, full page x path matrices, auth behavior, navigation flows, and stress footguns in `/audit/__stress` and Playwright, not in Storybook.
- **D-182-13:** Story status, maturity, fixture provenance, accessibility notes, theme support, and ugly-data coverage should appear as story notes/index metadata, not as the top-level navigation taxonomy.

### Theme And Ugly-Data Review Model

- **D-182-14:** Storybook stories must render through a shared Threadline wrapper that applies the real `.threadline-ui` context, includes `Threadline.OperatorSurface.Style.css`, and sets `data-tl-theme="dark" | "light" | "system"`. PhoenixStorybook's own color-mode class model may support Storybook chrome, but it must not replace Threadline's server-resolved `data-tl-theme` contract.
- **D-182-15:** Use PhoenixStorybook variations and variation groups for "interesting states" of each component. Prefer representative states over combinatorial explosion.
- **D-182-16:** Every covered category should include representative ugly data from the existing vocabulary: long IDs, long strings, non-ASCII, null fields, mixed severity, permission denied, stale/reconnecting, pagination boundary, timezone boundary, disabled, error, and empty/zero states where relevant.
- **D-182-17:** Use fixed, named dark/light/system examples for the components most likely to regress visually. Do not duplicate every story per theme or create a full pixel baseline matrix inside Storybook.
- **D-182-18:** Preserve the brand and UI posture from `brandbook/brand-book.md`: dark-primary product UI, shipped light/system lanes, no localStorage theming, no decorative motion, dense but scannable data, color as signal rather than decoration, 8px-or-less radius, and accessible focus/hover/disabled states.

### Verification And Docs Bar

- **D-182-19:** Treat verification as layered, not as one browser smoke test:
  - root `mix verify.compile_no_optional` stays green;
  - root source/dependency contracts prove `PhoenixStorybook`, `phoenix_storybook`, and `live_storybook` do not enter root `mix.exs`, public router macro source, or root package surface;
  - example compile/test proves the dev lane compiles where it is allowed;
  - compiled-route or source-contract tests prove dev/test route presence and production route absence;
  - bounded browser smoke proves the Storybook index and representative stories render with assets and theme wrapper;
  - doc-contract tests preserve the Storybook-vs-stress distinction.
- **D-182-20:** Keep browser coverage bounded: smoke the index plus representative primitive/form/state/overlay/data-display/group stories across the theme wrapper. Do not add a large screenshot matrix or external visual-regression SaaS in this phase.
- **D-182-21:** Docs must say: Storybook is component documentation and design review for maintainers; `/audit/__stress` is authenticated operator-flow stress testing; neither is a production route; Storybook is not installed by adopters and not required by root `threadline`.
- **D-182-22:** The example app README and any operator docs touched by this phase must not teach adopters to install PhoenixStorybook in their host app. If docs mention Storybook, they should anchor it to local maintainer workflow under `examples/threadline_phoenix`.

### Product, JTBD, And Architecture Coherence

- **D-182-23:** Optimize first for the adopting developer/maintainer persona. The lane should help maintainers safely evolve private components that support operator JTBD: find what happened, verify capture readiness, inspect governance, export/share evidence, and maintain UI without API/dependency leakage.
- **D-182-24:** Keep operator-facing language focused on domain nouns and verbs from Phase 181: Audit Action, Audit Transaction, Audit Change, Actor, Subject, Coverage, Evidence, Redaction, Retention, Export, Timeline Entry, filter, scan, open, copy, compare, refresh, remediate, download, confirm, return.
- **D-182-25:** Hide backend implementation details from Storybook examples unless the detail is necessary to understand a component contract. Stories should show how the component behaves, not expose capture internals as UI explanation.
- **D-182-26:** No scope from later phases moves into Phase 182. Shell/Home/Timeline/Coverage/detail/governance/export polish remains owned by Phases 183-186; accessibility/motion/docs/adversarial closeout remains owned by Phase 187.

### Claude's Discretion

The user selected all gray areas and asked for subagent-backed, research-first, one-shot recommendations rather than piecemeal choices. Downstream agents may choose exact file names, helper module names, and test split, but must preserve the decisions above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Authority

- `.planning/ROADMAP.md` - Phase 182 goal, success criteria, and active milestone invariants.
- `.planning/REQUIREMENTS.md` - STORY-01, STORY-02, STORY-03, milestone invariants, future requirements, and out-of-scope boundaries.
- `.planning/PROJECT.md` - current product posture, key decisions, and v1.38 active context.
- `.planning/phases/181-baseline-audit-and-guard-repair/181-CONTEXT.md` - prior locked guardrails, page/JTBD matrix, design pillars, and Storybook/stress boundary.
- `.planning/research/v1.38-operator-ui-page-polish.md` - accepted v1.38 research summary and PhoenixStorybook-vs-stress decision brief.

### Brand, UX, And Prompt Corpus

- `brandbook/brand-book.md` - current brand, voice, UI theming posture, color rules, component guidance, and microcopy principles. This supersedes older prompt-era brand details if they conflict.
- `brandbook/README.md` - brand artifact roles and warning that `lib/threadline/operator_surface/style.ex` is the product UI contract.
- `prompts/audit-lib-domain-model-reference.md` - audit product thesis, capture/semantics/exploration split, operator nouns, and "hardest to get wrong, easiest to understand, easiest to operate" principle.
- `prompts/threadline-elixir-oss-dna.md` - verification-as-product, example app as adoption proof, docs/contracts, optional dependency hygiene, and CI habits.
- `prompts/prior-art/SOURCE-CANONICAL.md` - prompt corpus provenance and which prior-art files are relevant.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` - OSS library API/DX and optional dependency guidance.
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - CI/docs/release verification bar.
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md` - Phoenix router/component/testing patterns.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` - LiveView/component/router/state guidance.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - Phoenix/Plug/Ecto architecture and operational constraints.

### Existing Code And Guardrails

- `mix.exs` - root optional Phoenix/LiveView dependency posture and `mix verify.compile_no_optional`.
- `examples/threadline_phoenix/mix.exs` - only allowed location for the PhoenixStorybook dependency.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` - existing example operator mount, `/audit/__stress` route, theme branch, and `dev_routes` context.
- `examples/threadline_phoenix/config/dev.exs` - dev route flag and local maintainer environment.
- `examples/threadline_phoenix/config/test.exs` - test route flag and E2E environment.
- `examples/threadline_phoenix/config/prod.exs` - production environment where Storybook must remain absent.
- `examples/threadline_phoenix/README.md` - example app maintainer/adopter docs likely touched for Storybook-vs-stress guidance.
- `examples/threadline_phoenix/AGENTS.md` - Phoenix 1.8 app conventions and component guidance for example-app code.
- `DESIGN-SYSTEM.md` - current design-system ledger projection and story categories.
- `.planning/design-system-ledger.json` - ratchet, current/reserved entries, screenshot allowlist, and required inventory.
- `lib/threadline/operator_surface/stress_fixtures.ex` - canonical stress story registry, ugly-data vocabulary, themes, and viewports.
- `lib/threadline/operator_surface/stress_router.ex` - dev/test-only stress router macro and production fail-closed behavior to preserve.
- `lib/threadline/operator_surface/live/stress_live.ex` - existing stress route UI and fixture renderer.
- `lib/threadline/operator_surface/ui.ex` - private operator component substrate to document through Storybook.
- `lib/threadline/operator_surface/style.ex` - product UI CSS, theme, motion, and interaction contract.
- `lib/threadline/operator_surface/components/surface_header.ex` - shell/header primitive already represented in stress fixtures.
- `test/threadline/operator_surface/stress_router_test.exs` - source contracts for root macro, stress routing, prod exclusion, and banned Storybook terms in root/stress source.
- `test/threadline/operator_surface/stress_fixtures_test.exs` - fixture registry synthetic/package-free contracts and adapter rendering checks.
- `test/threadline/operator_surface/stress_ledger_test.exs` - design-system ledger ratchet and forbidden dependency/tooling terms.
- `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` - canonical browser stress-route semantics and bounded screenshot guard.

### External References Used For Research

- `https://phoenix-storybook.hexdocs.pm/setup.html` - PhoenixStorybook manual setup: dependency, backend module, router mount, assets, Docker, and content.
- `https://phoenix-storybook.hexdocs.pm/components.html` - PhoenixStorybook component stories, variations, templates, slots, containers, source rendering, and notes.
- `https://phoenix-storybook.hexdocs.pm/color_modes.html` - PhoenixStorybook color modes; useful but not a replacement for Threadline's `data-tl-theme`.
- `https://phoenix-storybook.hexdocs.pm/sandboxing.html` - PhoenixStorybook sandboxing, JS/CSS context, asset paths, and iframe fallback.
- `https://phoenix-storybook.hexdocs.pm/theming.html` - PhoenixStorybook theming strategies.
- `https://phoenix-storybook.hexdocs.pm/testing.html` - PhoenixStorybook visual-test endpoints and visual regression posture.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html` - Phoenix function component attrs/slots compile-time contract model.
- `https://phoenix-live-dashboard.hexdocs.pm/Phoenix.LiveDashboard.html` - mounted dev/admin LiveView tooling precedent and auth guidance.
- `https://github.com/phoenixframework/phoenix_live_dashboard` - LiveDashboard dev-only mount and production authentication examples.
- `https://oban.pro/docs/web/2.9.6/installation.html` - Oban Web mounted dashboard precedent and authentication recommendation.
- `https://storybook.js.org/docs` - Storybook component-isolation concept and docs/testing workflow.
- `https://storybook.js.org/docs/writing-stories` - Storybook story state and args/reuse pattern.
- `https://storybook.js.org/docs/api/csf` - Component Story Format principles, metadata, title hierarchy, and story objects.
- `https://carbondesignsystem.com/components/select/usage/` - mature design-system state coverage, accessibility status, and interaction documentation pattern.
- `https://design-system.service.gov.uk/` - GOV.UK service design system principle: reusable, researched components and patterns.
- `https://design-system.service.gov.uk/components/` - component guidance with coded examples and public reusable component framing.
- `https://primer.style/` - GitHub Primer product UI, shared foundations, accessibility, icons, and primitives.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Threadline.OperatorSurface.UI` - private function component module with buttons, icon buttons, badges, alerts, cards, page headers, refs, key/value, data tables, empty/error/loading/stale/data states, toolbars, detail headers, data panels, modals, drawers, toasts, tooltips, popovers, dropdowns, tabs, segmented controls, accordions, fields, error summaries, field groups, and comboboxes.
- `Threadline.OperatorSurface.Style.css/1` - should be included by the Storybook wrapper so stories render with real product tokens, theme, motion, focus, hover, and disabled behavior.
- `Threadline.OperatorSurface.StressFixtures` - provides canonical ugly-data cases, theme modes, viewports, story IDs, and component-ready assigns for selected existing shapes.
- `DESIGN-SYSTEM.md` and `.planning/design-system-ledger.json` - provide category names and current/reserved/ratchet status, but should not become generated Storybook navigation.
- `examples/threadline_phoenix` - existing Phoenix 1.8 example app with `dev_routes`, E2E harness, `/audit` mount, `/audit/__stress`, and docs.

### Established Patterns

- Root `threadline` keeps Phoenix/LiveView optional and validates this with `mix verify.compile_no_optional`.
- Mounted operator tools use explicit router macros, fail-closed production behavior, and source contracts.
- The project favors named `mix verify.*` / `mix ci.*` entrypoints and doc-contract tests over folklore setup.
- Private component system only; no public component API and no adopter-facing component docs.
- Theme is server-resolved and CSS-scoped through `data-tl-theme`, with no localStorage and no JS theme flash.
- Dense operator UI should be calm, exact, accessible, and useful under incident pressure.

### Integration Points

- Add dependency and story setup only in `examples/threadline_phoenix/mix.exs` and example app files.
- Add PhoenixStorybook backend module and story files under the example app namespace/path.
- Add router mount and assets only through dev/test guarded example routes.
- Add a small story helper/wrapper module in the example app to apply `.threadline-ui`, `data-tl-theme`, and `Style.css`.
- Add tests near existing root stress/source contracts and example-app tests to prove boundary, route, docs, and smoke behavior.

</code_context>

<specifics>
## Specific Ideas

- Recommended route: `/dev/storybook`.
- Recommended source model: curated `.story.exs` stories plus explicit fixture helper/allowlist.
- Recommended taxonomy: component categories first, small `Patterns` branch second.
- Recommended story wrapper: real `.threadline-ui` plus `data-tl-theme` and `Threadline.OperatorSurface.Style.css`, not a parallel theme implementation.
- Recommended visual scope: representative Storybook browser smoke, not a full screenshot matrix and not Percy/Chromatic/Applitools.
- Recommended docs posture: "Storybook documents private components for maintainers; `/audit/__stress` stress-tests authenticated operator flows."

</specifics>

<deferred>
## Deferred Ideas

- Production, hosted, or public Storybook belongs in a future explicit STORY-PUBLIC or private-docs milestone.
- Public component API remains deferred to `COMP-PUBLIC-01`.
- Full visual-regression SaaS adoption remains deferred unless a future milestone explicitly chooses it.
- Replacing `/audit/__stress` with Storybook is rejected for this milestone.
- Shell/Home/Timeline/Coverage/detail/governance/export page polish remains in Phases 183-186.
- Real screen-reader certification remains out of scope unless explicitly run; browser accessibility-tree and keyboard evidence can support later Phase 187.

</deferred>

---

*Phase: 182-PhoenixStorybook example/dev lane*
*Context gathered: 2026-06-26*
