# Phase 183: Shell navigation and Home orientation - Context

**Gathered:** 2026-06-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 183 makes the mounted `/audit` operator shell and Home page unmistakably navigable and task-led. It polishes the existing Phoenix LiveView operator surface so users can understand where they are, see enabled destinations, launch the primary investigation/readiness/proof jobs, use the native mobile nav, and complete Home entry flows across dark/light/system and 320-1440px viewports.

This phase does not add routes, change auth/capture/query semantics, replace `/audit/__stress`, introduce public components, add Tailwind/shadcn or another UI dependency, redesign Timeline/Coverage/detail/governance/export page content, or make Storybook part of the operator surface.

The user selected all gray areas and requested one-shot, research-backed recommendations using subagents. The recommendations below are locked for planning.

</domain>

<spec_lock>
## UI Design Contract (locked via UI-SPEC.md)

`183-UI-SPEC.md` is approved and is the primary visual, copy, responsive, accessibility, and verification contract for this phase.

Downstream agents MUST read `.planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md` before planning or implementing. Do not duplicate or reinterpret its detailed requirements in plans; cite it and implement against it.

**In scope from UI-SPEC:** existing `/audit` shell navigation, Home orientation, Home task launcher hierarchy, topbar status, active nav state, feature-gated groups, theme picker, skip link, saved-view resume, EF1 row-history launcher, EF4 correlation launcher, dark/light/system behavior, and browser/source verification for shell/Home perception and flows.

**Out of scope from UI-SPEC:** new routes, public component APIs, root Tailwind/shadcn/design-system migration, root PhoenixStorybook dependency, production Storybook/stress routes, auth/capture/query semantic changes, runtime destructive redaction, generic builders, and adjacent page workflow redesign.

</spec_lock>

<decisions>
## Implementation Decisions

### Implementation Posture

- **D-183-01:** Preserve and retune the existing `UI.shell/1`, `SurfaceHeader.surface_header/1`, `StartLive`, and scoped `.threadline-ui` CSS substrate. Phase 183 is a shell/Home polish pass over the current private Phoenix LiveView code, not a shell rewrite.
- **D-183-02:** Keep all shell/Home components private. Do not promote a public component API, add `@doc` public-facing component prose, introduce a new LiveComponent only for organization, or split into a new shell component family unless the planner can prove repeated private markup pain and preserve selectors.
- **D-183-03:** Small private extraction is allowed only as an implementation detail if it reduces real duplication without changing visible contracts. Any extraction must remain `@doc false` / private, selector-stable, route-stable, feature-gate-stable, and friendly to root optional Phoenix/LiveView dependencies.
- **D-183-04:** Reject larger shell/Home restructuring unless browser proof shows the current structure cannot satisfy the UI-SPEC perception/accessibility contract. Current code already has the semantic spine: native mobile `<details>`, desktop/tablet rail, topbar, current-state link, theme radios, Home cards, health row, earned launchers, and saved views.
- **D-183-05:** Reject new UI dependencies, Tailwind/shadcn setup, Radix-style widget ports, icon packages, visual-regression SaaS, or a React-style component migration. This is not idiomatic for the current Phoenix LiveView library boundary and conflicts with the root optional dependency posture.

### Browser And Source Verification

- **D-183-06:** Use layered verification. Extend existing source contracts, LiveView tests, style/copy contracts, and Playwright suites rather than creating a broad new verification lane.
- **D-183-07:** Add a narrow Phase 183 browser supplement only if existing suites do not cover UI-SPEC perception cells. Missing or high-risk cells include 320px mobile nav, 375px mobile nav, 768px tablet rail, 1024px desktop-ish rail, 1280px desktop rail, dark default, existing light/system lane, Home first-viewport task hierarchy, active/current state, theme selected state, focus visibility, route transition, and no horizontal overflow.
- **D-183-08:** Do not create a full route x theme x viewport screenshot matrix. Phase 181 already chose a bounded screenshot posture, Phase 182 rejected broad visual lanes for Storybook, and Phase 183 should avoid flake/rebaseline churn unless a future milestone promotes specific cells with owners.
- **D-183-09:** Browser assertions should be user-perceptible and semantic: nav rail visible without disclosure at 768px+, mobile summary labeled `Audit navigation`, panel exposes enabled destinations and theme controls, active nav item visible with `aria-current="page"` plus a non-color cue, focus is not obscured, Home primary task stays visually primary, and form flows navigate or show local errors.
- **D-183-10:** Source-level tests should keep exact copy and source contracts stable: shell group labels, Home job-card titles, feature-gated group removal, preserved route paths, stable `data-testid`s, theme picker form/CSRF/native radios, mobile `<details>` source, active-state CSS, allowed breakpoint literals, and no checkbox/JS nav hack.

### Phase Boundary

- **D-183-11:** Representative adjacent page navigation tests are in scope. They may visit Timeline, Coverage, Evidence, Redaction, Retention, Exports, and relevant drill-down routes only to prove global shell/nav consistency, route transition, current state, focus, overflow, feature gates, and theme behavior.
- **D-183-12:** Adjacent page content/workflow polish is out of scope. Timeline investigation hierarchy belongs to Phase 184; Coverage audit-readiness belongs to Phase 185; detail/governance/export surfaces belong to Phase 186; accessibility/motion/docs/adversarial closeout belongs to Phase 187.
- **D-183-13:** Shell-blocker exception: Phase 183 may fix an adjacent page only when that page proves a shell invariant is broken, such as missing/hidden nav, wrong `aria-current`, focus obscured by topbar/nav, horizontal overflow caused by shell chrome, feature-gated shell group mismatch, or theme/topbar state mismatch. The fix must be shell-level or wrapper-level, not page-content polish.
- **D-183-14:** Do not relabel page-specific content taste issues as shell blockers. If a representative page reveals a Timeline/Coverage/detail content problem, record it for the owning later phase rather than fixing it here.

### Planner Discretion

- **D-183-15:** Use this CONTEXT as a hybrid decision artifact. It locks outcomes, constraints, canonical refs, code surfaces, verification posture, and no-reask decisions. It does not prescribe exact plan count, wave ordering, task split, or helper extraction.
- **D-183-16:** The planner may decide whether to amend existing tests or add a narrow new Phase 183 Playwright spec, but must preserve the verification outcomes in D-183-06 through D-183-10.
- **D-183-17:** The planner may choose exact CSS selectors and private helper names, but must preserve UI-SPEC copy, route paths, `data-testid`s, feature gates, native controls, `data-tl-theme`, and the private component boundary.
- **D-183-18:** Downstream agents should treat `183-UI-SPEC.md` as the authoritative design contract, this CONTEXT as the user decision record, and `gsd-plan-phase` as the place to create executable waves/tasks. Do not turn CONTEXT into a pseudo-plan.

### UX, JTBD, And Brand Posture

- **D-183-19:** Orient by operator job and arrival context, not backend architecture. The shell/Home should serve P1 incident responders, P2 support agents, P3 compliance/security reviewers, P4 audit/SRE operators, and P5 adopter developers without forcing every persona through a dense Timeline-first mental model.
- **D-183-20:** Preserve the Home hierarchy locked by UI-SPEC: H1 `Follow what happened.`, lede, system health when enabled, primary Timeline job card, secondary Coverage job card when enabled, specific Evidence/Redaction/Retention/Exports links when enabled, EF1 row-history launcher, EF4 correlation launcher, and saved-view resume/empty state.
- **D-183-21:** Hide backend implementation details unless they are necessary for remediation, proof, scoping, or performance constraints. Use operator nouns and verbs: Timeline, Coverage, Evidence, Redaction, Retention, Exports, row history, correlation id, saved timeline search, system health, scoped view, filter, scan, open, copy, compare, refresh, remediate, download.
- **D-183-22:** Copy must stay calm, exact, and useful under pressure. Avoid marketing copy, exclamation marks, generic "Get started" CTAs, "Prove/proof" as broad marketing language, CamelCase model names in primary UI, and implementation jargon.
- **D-183-23:** Preserve Threadline brand posture from the current brandbook: dark-primary but fully supported light/system, color as signal, no decorative blobs/orbs/broad gradients, route/line motifs only when meaningful, dense but scannable operator UI, accessible focus/hover/disabled states, and cards only for repeated items/tools rather than nested page sections.

### Lessons From Ecosystem And Prior Art

- **D-183-24:** Follow idiomatic Phoenix LiveView: function components for reusable markup, attrs/slots where useful, native HTML controls where possible, LiveComponents only when local state/event ownership is genuinely needed, URL/navigation state for shareable flows, expected validation failures rendered near forms, and behavior-focused tests.
- **D-183-25:** Follow host-mounted dashboard precedents from LiveDashboard and Oban Web: explicit router/auth boundaries, host app ownership of access control, mounted operational surfaces, and no accidental public/production development lanes.
- **D-183-26:** Follow GOV.UK-style service design where applicable: start with user needs, do less, make complex things simple, give the start surface just enough information to choose the next action, and let users resume relevant work.
- **D-183-27:** Follow mature product-design-system lessons from Carbon/Primer-style systems without importing their dependencies: token-backed components, accessibility testing as part of the component contract, dense data surfaces with clear action hierarchy, and consistency through primitives rather than decorative novelty.
- **D-183-28:** Avoid known audit/operator UI footguns from prior milestones and prompt research: opaque backend language in the UI, repeated status echoes, color-only state, false CTAs, generic info dumps, hard-to-scan dense cards, route/test-id churn, optional-dependency leakage, and broad screenshot matrices that create maintenance noise.

### Claude's Discretion

The user explicitly asked for subagent-backed, research-first, one-shot recommendations so they do not have to make piecemeal choices. Downstream agents may choose exact file boundaries, helper names, test organization, and plan sequencing if they preserve the decisions above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Authority

- `.planning/ROADMAP.md` - Phase 183 goal, success criteria, and the Phase 184-187 ownership boundary.
- `.planning/REQUIREMENTS.md` - SHELL-01, SHELL-02, SHELL-03, milestone invariants, traceability, and out-of-scope constraints.
- `.planning/PROJECT.md` - current v1.38 posture, key decisions, optional-dependency boundary, and operator UI milestone context.
- `.planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md` - approved UI design contract; MUST read before planning.
- `.planning/research/v1.38-operator-ui-page-polish.md` - accepted research summary and page-order/motion/storybook decisions.

### Prior Context

- `.planning/phases/181-baseline-audit-and-guard-repair/181-CONTEXT.md` - baseline evidence posture, page/JTBD ownership matrix, tiered verification model, design pillars, and guard repair boundary.
- `.planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md` - Storybook versus `/audit/__stress` boundary, private component catalog posture, bounded browser proof lesson, and no public component API.
- `.planning/milestones/v1.31-PERSONAS-IA.md` - locked P1-P5 personas, J1-J11 JTBDs, EF1-EF5 earned-flow provenance. Use as historical JTBD source; newer UI-SPEC decisions supersede old layout details if they conflict.
- `.planning/milestones/v1.31-UI-AUDIT.md` - Home/Nav baseline findings and prior design-system footguns. Use as provenance; do not reopen closed findings unless current code still shows them.

### Brand, Product, And Prompt Corpus

- `brandbook/brand-book.md` - current brand source of truth; supersedes older prompt-era brand details.
- `brandbook/README.md` - brand artifact roles and warning that `lib/threadline/operator_surface/style.ex` is the product UI contract.
- `prompts/audit-lib-domain-model-reference.md` - product thesis, capture/semantics/exploration split, operator personas, JTBDs, and canonical nouns/events.
- `prompts/threadline-elixir-oss-dna.md` - verification-as-product, example app as adoption proof, docs/contracts, optional dependency hygiene, and CI habits.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` - audit ecosystem lessons and footguns: opt-in capture, fragile context propagation, opaque storage, delete semantics, ops burden, and operator experience.
- `prompts/prior-art/SOURCE-CANONICAL.md` - provenance map for prompt prior-art files.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` - LiveView function components, URL state, forms, JS posture, testing, observability, and avoid-LiveComponents-for-organization guidance.
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md` - Phoenix structure and operational guidance.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - Phoenix/Plug/Ecto system guidance and LiveView/runtime footguns.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` - Elixir OSS library API/DX, optional dependencies, observability, compatibility, and anti-patterns.
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - layered CI, docs-as-product, optional-dep compile gates, and release/verification hygiene.

### Existing Code And Guardrails

- `lib/threadline/operator_surface/ui.ex` - private `UI.shell/1`, reconnect banner, root `data-tl-theme`, `#tl-main`, and shell composition.
- `lib/threadline/operator_surface/components/surface_header.ex` - topbar, skip link, global nav, grouped IA, active nav source, feature-gated destinations, native mobile disclosure, and theme picker form.
- `lib/threadline/operator_surface/live/start_live.ex` - Home task launcher, health row, Timeline/Coverage/Evidence cards, EF1 row-history launcher, EF4 correlation launcher, saved views, and validation copy.
- `lib/threadline/operator_surface/style.ex` - scoped shell/Home CSS, dark/light/system tokens, responsive breakpoints, native nav/details styling, active-state CSS, focus/motion/overflow contracts.
- `lib/threadline/operator_surface/router.ex` - mounted route paths, theme POST route, optional LiveView dependency boundary, auth/export/stress routing.
- `lib/threadline/operator_surface/auth.ex` - threadline theme assignment, session theme handling, scope/actor assigns, and mount-time operator context.
- `lib/threadline/operator_surface/stress_fixtures.ex` - page/theme/viewport manifest and stress fixture vocabulary.
- `DESIGN-SYSTEM.md` - current design-system ledger projection.
- `.planning/design-system-ledger.json` - ratchet, stress entries, current/reserved inventory, and screenshot allowlist.

### Existing Tests To Build On

- `test/threadline/operator_surface/surface_header_test.exs` - grouped shell IA, single `aria-current`, feature-gated groups, stable route/test IDs, brand/home affordance.
- `test/threadline/operator_surface/live/start_live_test.exs` - Home orientation, health states, actor-owned saved views, EF1/EF4 launchers, validation copy, theme root, scoped affordance.
- `test/threadline/operator_surface/style_contract_test.exs` - native mobile nav, token-backed CSS, breakpoint governance, active-state styling, Home/shell selectors, motion and responsive source contracts.
- `test/threadline/operator_surface/copy_contract_test.exs` - shell group labels, Home job-card titles, copy vocabulary, unsafe-word refutes.
- `test/threadline/operator_surface/component_contract_test.exs` - shell composition and active-state non-color cue.
- `test/threadline/operator_surface/skip_link_test.exs` - skip-link and `#tl-main` behavior.
- `test/threadline/operator_surface/surface_header_csp_test.exs` - no inline handlers and theme form CSRF/action contract.
- `test/threadline/operator_surface/router_test.exs` - operator route and theme config contracts.
- `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts` - mobile Home/nav UAT, enabled destinations, no horizontal overflow, Home orientation and launchers.
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` - skip link, focus, nav state, Home form names, mobile nav keyboard reachability.
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` - EF1 row-history and EF4 correlation browser flows.
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` - responsive route matrix, nav visibility/reachability, overflow checks.
- `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` - Home/shell motion and reduced-motion checks.
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` - bounded local screenshot-regression coverage; do not expand casually.

### External References Used For Research

- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html` - Phoenix function components, `attr/3`, slots/global attributes, compile-time component contracts.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html` - prefer function components over LiveComponents unless encapsulated state plus event handling is needed.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html` - LiveView behavior testing APIs.
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.html` - host-mounted LiveView dashboard precedent and production auth guidance.
- `https://oban-web.hexdocs.pm/installation.html` - host-mounted operational dashboard precedent, access controls, query limits, telemetry, and notifier caveats.
- `https://www.gov.uk/guidance/government-design-principles` - user-needs-first, do less, make complex things simple, design with data.
- `https://design-system.service.gov.uk/patterns/start-using-a-service/` - start surface should give enough context, clear primary action, resume affordance when relevant, and avoid overloading the start point.
- `https://www.w3.org/WAI/ARIA/apg/` - native/disclosure/widget accessibility patterns.
- `https://www.w3.org/WAI/WCAG22/Understanding/reflow.html` - no two-dimensional scrolling at narrow widths.
- `https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html` - visible keyboard focus.
- `https://carbondesignsystem.com/components/data-table/usage/` - dense data surfaces, action hierarchy, and accessibility testing status model.
- `https://carbondesignsystem.com/patterns/empty-states-pattern/` - empty states as learnability/status/recovery moments.
- `https://primer.style/` - mature product design-system precedent for tokenized components, accessibility, and multi-surface consistency.
- `https://playwright.dev/docs/best-practices` - behavior-oriented browser test guidance.
- `https://testing-library.com/docs/guiding-principles/` - test user-observable behavior rather than implementation details.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Threadline.OperatorSurface.UI.shell/1` - the shared private shell already renders scoped CSS, theme root, optional header/nav, reconnect banner, and `#tl-main`. Phase 183 should preserve this composition.
- `Threadline.OperatorSurface.Components.SurfaceHeader.surface_header/1` - owns the topbar, skip link, global nav, grouped destinations, active state, feature-gated groups, and theme picker. It is the main shell integration point.
- `Threadline.OperatorSurface.Live.StartLive` - already has Home as a task launcher with health, job cards, EF1/EF4, validation, saved views, and feature-gated proof/governance cards.
- `Threadline.OperatorSurface.Style.css/1` - contains the actual product UI contract: shell rail/mobile disclosure, Home layout, dark/light/system colors, responsive breakpoints, motion, focus, and active-state styling.
- `Threadline.OperatorSurface.Components.Icon` - internal inline SVG icons already used in buttons; no icon package is needed.
- Existing source/LiveView/Playwright tests - already cover most shell/Home contracts and should be extended rather than replaced.

### Established Patterns

- Root `threadline` keeps Phoenix/LiveView optional and uses `Code.ensure_loaded?` gates.
- Operator UI components are private Phoenix function components; no public component API.
- Native controls are preferred: `<details>/<summary>` for mobile nav, radios plus POST form for theme, links/buttons/forms for commands.
- Route paths and `data-testid`s are stable operator/test contracts.
- Theme is server-resolved and scoped through `data-tl-theme="dark" | "light" | "system"`, with no localStorage or client-only theme mutation.
- Browser tests should use user-visible behavior, role/name/test IDs where appropriate, computed visibility/overflow/focus checks, and stable route assertions.
- CSS governance limits breakpoint literals to the existing mobile-first, 768px, and 1280px layers unless source-contract tests intentionally change.

### Integration Points

- `SurfaceHeader.surface_header/1` receives `coverage`, `base_path`, `coverage_enabled`, `policy_enabled`, `evidence_enabled`, `exports_enabled`, `current`, `scoped`, and `theme` from `UI.shell/1`.
- `StartLive` mounts at the operator base path and passes `current={:start}` into `UI.shell/1`.
- Other operator LiveViews pass their own `current` atoms into `UI.shell/1`; adjacent route tests can verify shared nav behavior without editing page content.
- The theme picker posts to `{base_path}/theme`; do not convert it to inline JS or onchange behavior.
- Home earned flows use `phx-submit` events and canonical route construction; validation copy should stay near each form as `role="alert"`.

</code_context>

<specifics>
## Specific Ideas

- Recommendation synthesis: preserve/retune current shell/Home implementation; add only private extraction if it removes real duplication; reject broad rewrite and new UI dependencies.
- Verification synthesis: extend existing layered source/LiveView/Playwright contracts; add a narrow Phase 183 browser supplement only for missing perception cells; reject broad screenshots.
- Boundary synthesis: adjacent pages can be visited to prove shell consistency; page content polish stays in Phases 184-186 except strict shell blockers.
- Planning synthesis: lock decisions/outcomes/refs in CONTEXT; leave exact plan waves, file split, and test split to `gsd-plan-phase`.
- Current code already implements many UI-SPEC decisions; planning should identify gaps against the UI-SPEC and not re-ask whether those contracts are desired.
- Use the who/what/where/when/why lens in planning:
  - Who: P1 incident responder, P2 support agent, P3 compliance/security reviewer, P4 audit/SRE operator, P5 adopter developer.
  - What: know current location, pick a job, open Timeline/Coverage/proof destinations, launch row history/correlation lookup, resume saved views, understand health/scope/theme state.
  - Where: mounted `/audit` shell and Home, plus representative adjacent routes for nav consistency.
  - When: first arrival, high-pressure incident lookup, support record check, periodic audit-readiness sweep, handoff/proof review, first mount/debug by adopter.
  - Why: reduce anxiety and cognitive load by making the audit system followable, inspectable, and trustworthy.

</specifics>

<deferred>
## Deferred Ideas

- Timeline investigation workflow polish remains Phase 184.
- Coverage audit-readiness workflow polish remains Phase 185.
- Transaction, actor, row-history, Evidence, Exports, Redaction, and Retention workflow polish remains Phase 186.
- Accessibility/motion/docs/adversarial closeout remains Phase 187, though Phase 183 must preserve required shell/Home accessibility and motion contracts.
- Public component API remains deferred to `COMP-PUBLIC-01` or a future explicit milestone.
- Production/public Storybook remains deferred to `STORY-PUBLIC-01` or a future explicit milestone.
- Broad visual-regression service or full screenshot matrix remains deferred unless a future milestone explicitly scopes stable cells and owners.
- Root Tailwind/shadcn or external UI dependency migration remains rejected for Phase 183 and should only be revisited in a future public design-system/API milestone.
- Runtime destructive redaction remains out of scope.
- No matching todo artifacts were found for Phase 183.

</deferred>

---

*Phase: 183-shell-navigation-and-home-orientation*
*Context gathered: 2026-06-28*
