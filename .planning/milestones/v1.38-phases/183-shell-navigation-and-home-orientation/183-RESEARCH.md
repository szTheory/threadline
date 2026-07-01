# Phase 183: Shell navigation and Home orientation - Research

**Researched:** 2026-06-28
**Domain:** Phoenix LiveView operator shell, Home information architecture, responsive/accessibility browser verification
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Source: `.planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md` [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]

### Locked Decisions

#### Implementation Posture

- **D-183-01:** Preserve and retune the existing `UI.shell/1`, `SurfaceHeader.surface_header/1`, `StartLive`, and scoped `.threadline-ui` CSS substrate. Phase 183 is a shell/Home polish pass over the current private Phoenix LiveView code, not a shell rewrite.
- **D-183-02:** Keep all shell/Home components private. Do not promote a public component API, add `@doc` public-facing component prose, introduce a new LiveComponent only for organization, or split into a new shell component family unless the planner can prove repeated private markup pain and preserve selectors.
- **D-183-03:** Small private extraction is allowed only as an implementation detail if it reduces real duplication without changing visible contracts. Any extraction must remain `@doc false` / private, selector-stable, route-stable, feature-gate-stable, and friendly to root optional Phoenix/LiveView dependencies.
- **D-183-04:** Reject larger shell/Home restructuring unless browser proof shows the current structure cannot satisfy the UI-SPEC perception/accessibility contract. Current code already has the semantic spine: native mobile `<details>`, desktop/tablet rail, topbar, current-state link, theme radios, Home cards, health row, earned launchers, and saved views.
- **D-183-05:** Reject new UI dependencies, Tailwind/shadcn setup, Radix-style widget ports, icon packages, visual-regression SaaS, or a React-style component migration. This is not idiomatic for the current Phoenix LiveView library boundary and conflicts with the root optional dependency posture.

#### Browser And Source Verification

- **D-183-06:** Use layered verification. Extend existing source contracts, LiveView tests, style/copy contracts, and Playwright suites rather than creating a broad new verification lane.
- **D-183-07:** Add a narrow Phase 183 browser supplement only if existing suites do not cover UI-SPEC perception cells. Missing or high-risk cells include 320px mobile nav, 375px mobile nav, 768px tablet rail, 1024px desktop-ish rail, 1280px desktop rail, dark default, existing light/system lane, Home first-viewport task hierarchy, active/current state, theme selected state, focus visibility, route transition, and no horizontal overflow.
- **D-183-08:** Do not create a full route x theme x viewport screenshot matrix. Phase 181 already chose a bounded screenshot posture, Phase 182 rejected broad visual lanes for Storybook, and Phase 183 should avoid flake/rebaseline churn unless a future milestone promotes specific cells with owners.
- **D-183-09:** Browser assertions should be user-perceptible and semantic: nav rail visible without disclosure at 768px+, mobile summary labeled `Audit navigation`, panel exposes enabled destinations and theme controls, active nav item visible with `aria-current="page"` plus a non-color cue, focus is not obscured, Home primary task stays visually primary, and form flows navigate or show local errors.
- **D-183-10:** Source-level tests should keep exact copy and source contracts stable: shell group labels, Home job-card titles, feature-gated group removal, preserved route paths, stable `data-testid`s, theme picker form/CSRF/native radios, mobile `<details>` source, active-state CSS, allowed breakpoint literals, and no checkbox/JS nav hack.

#### Phase Boundary

- **D-183-11:** Representative adjacent page navigation tests are in scope. They may visit Timeline, Coverage, Evidence, Redaction, Retention, Exports, and relevant drill-down routes only to prove global shell/nav consistency, route transition, current state, focus, overflow, feature gates, and theme behavior.
- **D-183-12:** Adjacent page content/workflow polish is out of scope. Timeline investigation hierarchy belongs to Phase 184; Coverage audit-readiness belongs to Phase 185; detail/governance/export surfaces belong to Phase 186; accessibility/motion/docs/adversarial closeout belongs to Phase 187.
- **D-183-13:** Shell-blocker exception: Phase 183 may fix an adjacent page only when that page proves a shell invariant is broken, such as missing/hidden nav, wrong `aria-current`, focus obscured by topbar/nav, horizontal overflow caused by shell chrome, feature-gated shell group mismatch, or theme/topbar state mismatch. The fix must be shell-level or wrapper-level, not page-content polish.
- **D-183-14:** Do not relabel page-specific content taste issues as shell blockers. If a representative page reveals a Timeline/Coverage/detail content problem, record it for the owning later phase rather than fixing it here.

#### Planner Discretion

- **D-183-15:** Use this CONTEXT as a hybrid decision artifact. It locks outcomes, constraints, canonical refs, code surfaces, verification posture, and no-reask decisions. It does not prescribe exact plan count, wave ordering, task split, or helper extraction.
- **D-183-16:** The planner may decide whether to amend existing tests or add a narrow new Phase 183 Playwright spec, but must preserve the verification outcomes in D-183-06 through D-183-10.
- **D-183-17:** The planner may choose exact CSS selectors and private helper names, but must preserve UI-SPEC copy, route paths, `data-testid`s, feature gates, native controls, `data-tl-theme`, and the private component boundary.
- **D-183-18:** Downstream agents should treat `183-UI-SPEC.md` as the authoritative design contract, this CONTEXT as the user decision record, and `gsd-plan-phase` as the place to create executable waves/tasks. Do not turn CONTEXT into a pseudo-plan.

#### UX, JTBD, And Brand Posture

- **D-183-19:** Orient by operator job and arrival context, not backend architecture. The shell/Home should serve P1 incident responders, P2 support agents, P3 compliance/security reviewers, P4 audit/SRE operators, and P5 adopter developers without forcing every persona through a dense Timeline-first mental model.
- **D-183-20:** Preserve the Home hierarchy locked by UI-SPEC: H1 `Follow what happened.`, lede, system health when enabled, primary Timeline job card, secondary Coverage job card when enabled, specific Evidence/Redaction/Retention/Exports links when enabled, EF1 row-history launcher, EF4 correlation launcher, and saved-view resume/empty state.
- **D-183-21:** Hide backend implementation details unless they are necessary for remediation, proof, scoping, or performance constraints. Use operator nouns and verbs: Timeline, Coverage, Evidence, Redaction, Retention, Exports, row history, correlation id, saved timeline search, system health, scoped view, filter, scan, open, copy, compare, refresh, remediate, download.
- **D-183-22:** Copy must stay calm, exact, and useful under pressure. Avoid marketing copy, exclamation marks, generic "Get started" CTAs, "Prove/proof" as broad marketing language, CamelCase model names in primary UI, and implementation jargon.
- **D-183-23:** Preserve Threadline brand posture from the current brandbook: dark-primary but fully supported light/system, color as signal, no decorative blobs/orbs/broad gradients, route/line motifs only when meaningful, dense but scannable operator UI, accessible focus/hover/disabled states, and cards only for repeated items/tools rather than nested page sections.

#### Lessons From Ecosystem And Prior Art

- **D-183-24:** Follow idiomatic Phoenix LiveView: function components for reusable markup, attrs/slots where useful, native HTML controls where possible, LiveComponents only when local state/event ownership is genuinely needed, URL/navigation state for shareable flows, expected validation failures rendered near forms, and behavior-focused tests.
- **D-183-25:** Follow host-mounted dashboard precedents from LiveDashboard and Oban Web: explicit router/auth boundaries, host app ownership of access control, mounted operational surfaces, and no accidental public/production development lanes.
- **D-183-26:** Follow GOV.UK-style service design where applicable: start with user needs, do less, make complex things simple, give the start surface just enough information to choose the next action, and let users resume relevant work.
- **D-183-27:** Follow mature product-design-system lessons from Carbon/Primer-style systems without importing their dependencies: token-backed components, accessibility testing as part of the component contract, dense data surfaces with clear action hierarchy, and consistency through primitives rather than decorative novelty.
- **D-183-28:** Avoid known audit/operator UI footguns from prior milestones and prompt research: opaque backend language in the UI, repeated status echoes, color-only state, false CTAs, generic info dumps, hard-to-scan dense cards, route/test-id churn, optional-dependency leakage, and broad screenshot matrices that create maintenance noise.

### the agent's Discretion

The user explicitly asked for subagent-backed, research-first, one-shot recommendations so they do not have to make piecemeal choices. Downstream agents may choose exact file boundaries, helper names, test organization, and plan sequencing if they preserve the decisions above.

### Deferred Ideas (OUT OF SCOPE)

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
</user_constraints>

## Summary

Phase 183 should be planned as a focused retune of the existing private Phoenix LiveView shell/Home implementation, not as a shell rewrite or design-system migration. The current code already owns the core semantic spine: `UI.shell/1` renders the scoped root, theme attribute, header/nav, reconnect banner, and `#tl-main`; `SurfaceHeader.surface_header/1` renders the skip link, topbar, grouped navigation, current state, feature gates, native mobile disclosure, and theme form; `StartLive` renders the Home task launcher, health states, EF1/EF4 launchers, and saved views. [VERIFIED: lib/threadline/operator_surface/ui.ex] [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] [VERIFIED: lib/threadline/operator_surface/live/start_live.ex]

The main gaps are validation gaps, plus likely CSS/hierarchy retuning that should be driven by browser evidence. Existing source tests already cover much of the copy, route, feature-gate, theme, skip-link, and style contract surface, while existing Playwright suites cover mobile Home/nav at 375px, accessibility/focus, earned flows, responsive route matrices, motion, and bounded screenshot regression. Phase 183 still needs stricter perception proof for 320px mobile, 768px tablet rail, 1024/1280 desktop rail, 1440 floor/ceiling confidence, Home first-viewport task hierarchy, selected theme state, visible current-state non-color cue, and light/system lane assertions. [VERIFIED: test/threadline/operator_surface/surface_header_test.exs] [VERIFIED: test/threadline/operator_surface/live/start_live_test.exs] [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts]

**Primary recommendation:** keep implementation changes in `SurfaceHeader`, `StartLive`, `UI.shell`, and `Style.css`; add or extend a narrow Phase 183 browser supplement for the missing perception cells; preserve routes, test IDs, feature gates, private component boundaries, native controls, and optional Phoenix/LiveView dependency hygiene. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Global shell composition | Frontend Server / Phoenix LiveView | Browser native HTML/CSS | `UI.shell/1` composes the root, header, nav, reconnect banner, and main landmark server-side; the browser executes native focus, sticky layout, details disclosure, and CSS state. [VERIFIED: lib/threadline/operator_surface/ui.ex] [VERIFIED: lib/threadline/operator_surface/style.ex] |
| Shell navigation and current state | Frontend Server / Phoenix components | Browser accessibility tree | `SurfaceHeader.surface_header/1` receives current page/feature gates and renders one nav with `aria-current`; browser tests should prove perceivable state and keyboard reachability. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html] |
| Mobile disclosure | Browser native HTML/CSS | Frontend Server markup | The current shell uses native `<details>/<summary>` and CSS `[open]` styling; Phase 183 should not replace this with JS or a dependency. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] [VERIFIED: lib/threadline/operator_surface/style.ex] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/] |
| Theme picker | Frontend Server / route + session | Browser native radio form | `SurfaceHeader` renders native radios and a POST form, `router.ex` owns `/theme`, and `auth.ex` assigns `threadline_theme`; browser proof should cover selected state in dark and light/system lanes. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] |
| Home task launcher | Frontend Server / StartLive | API/Storage read models | `StartLive` owns Home hierarchy, health state rendering, saved views, and EF1/EF4 form events; underlying queries/fixtures supply status and saved-view data without changing capture/query semantics. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md] |
| Feature-gated destinations | Frontend Server / auth assigns | Router/auth boundary | `auth.ex` computes page availability and `router.ex` preserves mounted route/auth behavior; unavailable groups should be absent rather than disabled client controls. [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/router.ex] |
| Browser verification | Example app Playwright harness | ExUnit source contracts | Playwright proves user-perceptible behavior in the mounted example app, while ExUnit/source tests lock private component contracts, copy, CSS selectors, routes, and feature gates. [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts] [VERIFIED: test/threadline/operator_surface/surface_header_test.exs] |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SHELL-01 | Every `/audit` page has one obvious global operator navigation surface that is visible on desktop/tablet and clearly labeled on mobile. [VERIFIED: .planning/REQUIREMENTS.md] | Build on `SurfaceHeader.surface_header/1`, the existing nav `data-testid="operator-nav-shell"`, native `<details>/<summary>`, and source/browser nav tests; add strict browser assertions for 320 mobile and 768+/desktop rail visibility without disclosure. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts] |
| SHELL-02 | Home is a focused task launcher, not an info dump: it exposes the top operator jobs, system status, and direct investigation entrypoints with deliberate hierarchy and no redundant generic CTAs. [VERIFIED: .planning/REQUIREMENTS.md] | Build on `StartLive` Home cards, system health, EF1/EF4 launchers, saved views, and copy/source tests; add browser proof for first-viewport hierarchy and primary Timeline dominance at required breakpoints. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex] [VERIFIED: test/threadline/operator_surface/live/start_live_test.exs] |
| SHELL-03 | Active nav state, feature-gated destinations, skip link, theme picker, and topbar status are discoverable, accessible, and stable across dark/light/system and 320-1440px viewports. [VERIFIED: .planning/REQUIREMENTS.md] | Build on existing active-state, feature-gate, skip-link, CSP/theme, and style contracts; add targeted Playwright checks for current state, selected theme option, topbar status, focus visibility, and no overflow in dark default plus the existing light/system lane. [VERIFIED: test/threadline/operator_surface/surface_header_test.exs] [VERIFIED: test/threadline/operator_surface/skip_link_test.exs] [VERIFIED: test/threadline/operator_surface/surface_header_csp_test.exs] [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] |
</phase_requirements>

## Project Constraints

No root `./AGENTS.md` was present in `/Users/jon/projects/threadline`; the Phoenix example app has `examples/threadline_phoenix/AGENTS.md`, which applies when modifying files under that app. [VERIFIED: rg --files -g 'AGENTS.md'] [VERIFIED: examples/threadline_phoenix/AGENTS.md]

Root project constraints from `CLAUDE.md` require preserving Threadline's capture/semantics/exploration split, optional Phoenix/LiveView posture, layered verification commands, and avoidance of dependency/API drift while keeping the example app as adoption proof. [VERIFIED: CLAUDE.md] [VERIFIED: prompts/threadline-elixir-oss-dna.md]

Example Phoenix app constraints include using `mix precommit` after app changes, preferring included `Req` over `httpoison`, `tesla`, or `httpc`, avoiding extra dependencies for standard date/time work, avoiding `String.to_atom/1` on user input, using specific file tests for failures, and avoiding `Process.sleep/1` in tests. [VERIFIED: examples/threadline_phoenix/AGENTS.md]

Phase-specific constraints prohibit new UI dependencies, Tailwind/shadcn, root PhoenixStorybook dependency, route churn, data-testid churn, public component APIs, broad screenshot matrices, capture/query/auth semantic changes, and adjacent page content polish beyond shell invariants. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md]

## Implementation Gap Audit

| Gap | Current Evidence | Planning Action |
|-----|------------------|-----------------|
| 320px mobile nav perception | Existing `operator-home-nav-mobile.spec.ts` uses a 375x812 mobile viewport, while UI-SPEC requires 320px and 375px mobile proof. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] | Add or extend a narrow browser test that opens the native summary by keyboard and pointer at 320px, checks enabled destinations/theme controls, focus visibility, and no horizontal overflow. |
| Tablet/desktop rail strictness | Existing responsive helpers cover 768/1024/1280 route matrices, but permissive nav helpers can open navigation when hidden; UI-SPEC requires rail visibility without disclosure at 768px and above. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] | Add strict assertions that the rail/panel is visible, readable, and usable without opening the mobile disclosure at 768, 1024, and 1280px. |
| 1440px Phase 183 perception | Phase 178 UAT sweeps 320/1440 for viewport containment, but Phase 183 needs Home/shell perception and task hierarchy proof, not only route bounds. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] | Reuse the Phase 178 floor/ceiling pattern for a narrow Home/shell check at 1440px rather than broadening screenshots. |
| Home first-viewport hierarchy | `StartLive` already renders the required H1, lede, health, Timeline/Coverage/proof cards, EF1/EF4, and saved views, but only browser rendering can prove the primary task stays visually dominant across breakpoints. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] | Keep markup mostly stable; tune CSS only where browser evidence shows hierarchy, spacing, overflow, or primary/secondary contrast failures. |
| Theme selected state in browser | Source/CSP tests cover native theme radios/form/CSRF and style contracts cover `:has(:checked)`, while UI-SPEC requires browser assertions in dark default plus existing light/system lane. [VERIFIED: test/threadline/operator_surface/surface_header_csp_test.exs] [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] | Add browser assertions for the checked theme option and selected visual cue in the default dark lane and `mix verify.example_browser_light` lane. |
| Current-state non-color cue | Source tests and CSS include active state classes, borders/inset/weight, and `aria-current`, but UI-SPEC requires user-perceptible browser proof. [VERIFIED: test/threadline/operator_surface/surface_header_test.exs] [VERIFIED: lib/threadline/operator_surface/style.ex] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] | Add targeted computed-style/visibility assertions for one active nav item per representative state without coupling the test to full visual snapshots. |

## Standard Stack

### Core

| Library / Surface | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| Phoenix | 1.8.7 | Host/example Phoenix framework for the mounted operator surface. [VERIFIED: mix deps] | This is already the repo's Phoenix dependency; Phase 183 must preserve optional root dependency hygiene instead of adding a parallel UI stack. [VERIFIED: mix deps] [VERIFIED: CLAUDE.md] |
| Phoenix LiveView | 1.1.30 | Private LiveViews and HEEx function components for the operator surface. [VERIFIED: mix deps] | Phoenix docs define reusable function components with HEEx functions and compile-time attrs, matching Threadline's existing private component pattern. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] [VERIFIED: lib/threadline/operator_surface/ui.ex] |
| Phoenix.LiveViewTest / ExUnit | LiveView 1.1.30 / Elixir 1.19.5 | Source-level LiveView/component behavior tests. [VERIFIED: mix deps] [VERIFIED: elixir --version] | LiveViewTest provides selector/text assertions for rendered LiveViews, matching existing shell/Home contract tests. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] [VERIFIED: test/threadline/operator_surface/surface_header_test.exs] |
| Scoped `Style.css/1` | local | Product UI contract for shell/Home tokens, breakpoints, focus, nav, theme, and responsive layout. [VERIFIED: lib/threadline/operator_surface/style.ex] | The brandbook identifies `style.ex` as the product UI contract and Phase 183 prohibits importing an external UI system. [VERIFIED: brandbook/README.md] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] |
| Playwright Test | 1.60.0 installed, package range `^1.52.0` | Browser verification in the example app. [VERIFIED: npm ls @playwright/test] [VERIFIED: examples/threadline_phoenix/e2e/package.json] | Playwright guidance favors user-facing locators, auto-waiting, actionability, and web-first assertions, which fits Phase 183's semantic browser supplement. [CITED: https://playwright.dev/docs/best-practices] |

### Supporting

| Library / Surface | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| Phoenix HTML | 4.3.0 | HTML helpers and escaping in Phoenix-rendered UI. [VERIFIED: mix deps] | Use through existing Phoenix/HEEx rendering; do not introduce manual string HTML for shell/Home markup. [VERIFIED: mix deps] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] |
| Plug | 1.19.1 | CSRF/session/router plumbing used by mounted Phoenix surface. [VERIFIED: mix deps] | Preserve the existing theme POST/CSRF and auth plug boundaries; do not move theme behavior to inline JS. [VERIFIED: mix deps] [VERIFIED: lib/threadline/operator_surface/router.ex] |
| PostgreSQL | psql 14.17, server accepting connections | Example app storage for browser harness. [VERIFIED: psql --version] [VERIFIED: pg_isready] | Required by existing example app/browser verification; no new database behavior should be introduced in Phase 183. [VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh] |
| Chromium | `/opt/homebrew/bin/chromium` | Local browser for Playwright/verification. [VERIFIED: command -v chromium] | Use existing Playwright harness; the run script can install Chromium if missing. [VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Private Phoenix function components | LiveComponent shell/navigation family | Phoenix LiveComponent docs recommend function components generally and LiveComponents only when encapsulated state plus events are needed; Phase 183 shell organization does not require new component state. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md] |
| Native `<details>/<summary>` mobile nav | Custom JS drawer, checkbox hack, Radix/menu dependency | Phase 183 explicitly preserves native controls and forbids new UI dependencies or checkbox/JS nav hacks. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] |
| Narrow semantic browser supplement | Full screenshot route x theme x viewport matrix | Phase 183 rejects broad screenshot churn and already has bounded screenshot coverage in the example app. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts] |
| Server POST theme picker | `localStorage`, inline `onchange`, or client-only theme mutation | Existing router/auth/theme form contracts use server-resolved theme and CSRF; source tests forbid inline handlers. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: test/threadline/operator_surface/surface_header_csp_test.exs] |

**Installation:**

No new package installation is recommended for Phase 183. Existing project dependencies are sufficient. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md] [VERIFIED: mix deps] [VERIFIED: npm ls @playwright/test]

## Package Legitimacy Audit

Phase 183 does not recommend installing external packages, so the package legitimacy gate is not applicable. Existing packages observed for planning are already present in the repo lockfiles/dependency graph: Phoenix 1.8.7, Phoenix LiveView 1.1.30, Phoenix HTML 4.3.0, Plug 1.19.1, and `@playwright/test` 1.60.0 installed under the example app. [VERIFIED: mix deps] [VERIFIED: npm ls @playwright/test]

**Packages removed due to [SLOP] verdict:** none - no new packages proposed. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]
**Packages flagged as suspicious [SUS]:** none - no new packages proposed. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Operator request to /audit...
  -> threadline_operator_surface router macro
     -> optional Phoenix/LiveView gate and host auth boundary
     -> Auth on_mount assigns scope, actor, theme, and feature gates
     -> UI.shell/1 renders scoped product shell
        -> SurfaceHeader renders skip link, topbar, nav, feature groups, theme form
        -> StartLive or adjacent LiveView renders page task content
           -> Browser native behavior handles details disclosure, radios, focus, forms
              -> Playwright/ExUnit verify route, state, focus, overflow, and hierarchy contracts
```

The flow above maps the existing router/auth/shell/component/browser boundary and should remain the implementation shape for Phase 183. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/ui.ex] [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex]

### Recommended Project Structure

```text
lib/threadline/operator_surface/
├── ui.ex                         # private shell composition and main landmark
├── components/surface_header.ex  # shell skip link, topbar, nav, feature gates, theme form
├── live/start_live.ex            # Home task launcher, health, EF1/EF4, saved views
├── style.ex                      # scoped shell/Home CSS contract
├── router.ex                     # mounted route/theme/auth boundary
└── auth.ex                       # theme/scope/feature-gate assigns

test/threadline/operator_surface/
├── surface_header_test.exs
├── live/start_live_test.exs
├── style_contract_test.exs
├── copy_contract_test.exs
├── skip_link_test.exs
├── surface_header_csp_test.exs
└── router_test.exs

examples/threadline_phoenix/e2e/tests/
├── operator-home-nav-mobile.spec.ts
├── operator-responsive-mobile-first.spec.ts
├── operator-accessibility.spec.ts
├── operator-earned-flows.spec.ts
└── optional narrow phase-183 shell/home spec if extension would make existing specs noisy
```

This structure is already present except for the optional narrow Phase 183 browser spec. [VERIFIED: rg --files] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts]

### Pattern 1: Private Function Component Contracts

**What:** Keep shell markup in private Phoenix function components with explicit attrs and stable selectors. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] [VERIFIED: lib/threadline/operator_surface/ui.ex]

**When to use:** Use for shell/header/nav markup that is rendered from assigns and does not own independent LiveView state. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html] [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex]

**Example:**

```elixir
# Source: lib/threadline/operator_surface/ui.ex
@doc false
attr :current, :atom, default: nil
attr :theme, :atom, default: :dark
slot :inner_block, required: true
def shell(assigns) do
  ~H"""
  <div class="threadline-ui" data-tl-theme={@theme}>
    <main id="tl-main" tabindex="-1">
      {render_slot(@inner_block)}
    </main>
  </div>
  """
end
```

The example shows the pattern, not an exact replacement patch; the planner should preserve the current full shell assigns and header composition. [VERIFIED: lib/threadline/operator_surface/ui.ex]

### Pattern 2: Native Controls With Server-Owned Semantics

**What:** Use native `<details>/<summary>` for mobile navigation and native radio inputs plus a POST form for theme. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] [VERIFIED: lib/threadline/operator_surface/style.ex]

**When to use:** Use when the control is a disclosure, form, link, or button and Phoenix/server state already owns the result. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md]

**Example:**

```heex
<details class="tl-shell-nav__disclosure">
  <summary class="tl-shell-nav__toggle" aria-controls="tl-shell-nav-panel">
    Audit navigation
  </summary>
  <div id="tl-shell-nav-panel" class="tl-shell-nav__panel">
    ...
  </div>
</details>
```

This pattern is already used in `SurfaceHeader` and should be preserved. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex]

### Pattern 3: Browser Tests Assert Perception, Source Tests Assert Contracts

**What:** Let source tests lock exact copy, selectors, route paths, feature gates, and CSS governance; let Playwright prove that the user can see/use the shell and Home across required breakpoints and themes. [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts] [CITED: https://playwright.dev/docs/best-practices]

**When to use:** Use this split for Phase 183 because broad visual screenshots are out of scope but user-perceptible shell/Home behavior is required. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md]

**Example:**

```ts
// Source pattern: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
await expect(page.getByTestId("operator-nav-shell")).toBeVisible();
await expect(page.getByRole("link", { name: "Overview" })).toHaveAttribute("aria-current", "page");
await expect(page.locator("body")).toHaveJSProperty("scrollWidth", await page.locator("body").evaluate((body) => body.clientWidth));
```

The planner should prefer role/name/testid assertions, with computed style checks only for current-state and overflow cells that cannot be expressed semantically. [CITED: https://playwright.dev/docs/best-practices] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts]

### Anti-Patterns to Avoid

- **New public shell component API:** Phase 183 explicitly keeps shell/Home components private and selector-stable. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]
- **LiveComponent for organization:** Phoenix LiveComponent docs distinguish stateful/event-owning components from generally preferred function components; this phase does not need a new state owner for shell polish. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html]
- **Custom mobile nav widget:** Native details/summary is already implemented and source-tested; a JS drawer or checkbox hack would violate UI-SPEC. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] [VERIFIED: test/threadline/operator_surface/style_contract_test.exs]
- **Color-only selected state:** UI-SPEC requires non-color cues for current nav and theme selected state; CSS/source tests already point to border/inset/weight patterns. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] [VERIFIED: lib/threadline/operator_surface/style.ex]
- **Horizontal overflow masking:** UI-SPEC and style contracts require proving no overflow rather than hiding the document with broad `overflow-x: hidden`. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] [VERIFIED: test/threadline/operator_surface/style_contract_test.exs]
- **Broad screenshot expansion:** Existing screenshot regression is bounded and local; Phase 183 should add semantic assertions instead of widening snapshot cells. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Mobile nav disclosure | Custom JS drawer, checkbox menu, hidden input state | Native `<details>/<summary>` already in `SurfaceHeader` | Native control preserves keyboard/disclosure semantics and matches UI-SPEC/source tests. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] |
| Theme switching | Client-only localStorage theme system or inline `onchange` | Existing server POST theme route, CSRF token, native radios | The current theme path is route/session/auth owned and CSP-tested. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: test/threadline/operator_surface/surface_header_csp_test.exs] |
| Component catalog / Storybook shell | Production Storybook, root PhoenixStorybook dependency, `/audit/__stress` replacement | Existing operator Home plus dev-only stress/Storybook lanes | Phase 182 and Phase 183 keep Storybook/stress as verification/dev lanes, not the operator surface. [VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md] |
| Accessibility/focus rules | Ad hoc focus suppression or visual-only active styles | Existing `--tl-focus-ring`, `aria-current`, visible border/inset/weight cues | WCAG Focus Visible requires visible keyboard focus, and UI-SPEC requires non-color cues. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html] [VERIFIED: lib/threadline/operator_surface/style.ex] |
| Browser verification matrix | Full route x theme x viewport screenshot grid | Narrow semantic Playwright assertions plus existing screenshot allowlist | Phase 183 needs perception proof without flake/rebaseline churn. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts] |
| Row/correlation entry flows | Generic builders, pseudo-routes, speculative filters | Existing EF1 row-history launcher and EF4 correlation launcher | UI-SPEC locks direct Home shortcuts and forbids speculative builders. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] |

**Key insight:** The hard part in Phase 183 is not inventing shell mechanics; it is proving the existing mechanics are unmistakable under operator pressure at the required widths/themes and retuning only the markup/CSS that fails that proof. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] [VERIFIED: lib/threadline/operator_surface/style.ex]

## Common Pitfalls

### Pitfall 1: Treating Phase 183 as a Shell Rewrite

**What goes wrong:** The plan introduces new components, public APIs, dependencies, routes, or nav architecture while the existing code already has the required semantic shell pieces. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md] [VERIFIED: lib/threadline/operator_surface/ui.ex]

**Why it happens:** Browser perception gaps can look like architecture gaps when they are usually CSS hierarchy, responsive, or test-coverage gaps. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md]

**How to avoid:** Start with source/browser gap tests, then retune `SurfaceHeader`, `StartLive`, `UI.shell`, and `Style.css` only where evidence requires. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]

**Warning signs:** A task adds a new LiveComponent family, new public docs, Tailwind/shadcn, JS nav state, route changes, or broad screenshot matrices. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]

### Pitfall 2: Letting Browser Tests Stay Too Permissive

**What goes wrong:** Tests pass because they open a hidden nav or only check route containment, while UI-SPEC requires the rail to be visibly present at 768px+ and mobile nav to be discoverable at 320px/375px. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md]

**Why it happens:** Existing responsive tests were written to protect mobile-first regressions broadly, not to prove Phase 183 nav perception. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts]

**How to avoid:** Add explicit breakpoint cells for 320, 375, 768, 1024, 1280, and 1440, with strict expectations for summary vs rail behavior. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md]

**Warning signs:** A test helper says "if hidden, open it" for a desktop/tablet perception assertion. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts]

### Pitfall 3: Mistaking Adjacent Page Taste for Shell Invariants

**What goes wrong:** Phase 183 expands into Timeline, Coverage, detail, Evidence, Exports, Redaction, or Retention workflow redesign. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md]

**Why it happens:** Representative adjacent routes are valid browser-test targets, but their page content belongs to later phases unless shell invariants fail. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]

**How to avoid:** Fix only missing nav, wrong current state, focus obstruction, overflow from shell chrome, feature-gate mismatch, or theme/topbar mismatch; defer content polish to Phases 184-186. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]

**Warning signs:** A task changes Timeline/Coverage copy, workflow hierarchy, export content, or retention policy flows to satisfy a shell test. [VERIFIED: .planning/ROADMAP.md]

### Pitfall 4: Theme and Feature Gates Becoming Client-Only

**What goes wrong:** Theme selection or destination visibility moves into client-only JS, making auth/session state and tests inconsistent. [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/router.ex]

**Why it happens:** It can seem faster to add localStorage, inline handlers, or disabled links than to preserve the existing server route and assigns. [VERIFIED: test/threadline/operator_surface/surface_header_csp_test.exs]

**How to avoid:** Keep server POST theme form, CSRF, `data-tl-theme`, and feature-gated group omission as the only shell behavior path. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex]

**Warning signs:** New `onchange`, inline event handlers, localStorage theme state, disabled nav links for unavailable pages, or client-side feature filtering. [VERIFIED: test/threadline/operator_surface/surface_header_csp_test.exs] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md]

## Code Examples

### LiveViewTest Contract Assertion

```elixir
# Source: Phoenix.LiveViewTest docs and existing test/threadline/operator_surface tests
assert has_element?(view, ~s(nav[data-testid="operator-nav-shell"][aria-label="Audit navigation"]))
assert has_element?(view, ~s(a[aria-current="page"]), "Overview")
```

Use selector/text assertions for source-level shell contracts and keep browser-only perception checks in Playwright. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] [VERIFIED: test/threadline/operator_surface/surface_header_test.exs]

### Playwright Breakpoint Perception Pattern

```ts
// Source: Playwright best-practice guidance plus existing e2e tests
await page.setViewportSize({ width: 768, height: 900 });
await page.goto("/audit");
await expect(page.getByTestId("operator-nav-shell")).toBeVisible();
await expect(page.getByRole("link", { name: "Overview" })).toHaveAttribute("aria-current", "page");
await expect(page.getByRole("heading", { name: "Follow what happened." })).toBeVisible();
```

Use role/name/testid locators for stable user-observable assertions and reserve computed-style checks for non-color current-state proof. [CITED: https://playwright.dev/docs/best-practices] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts]

### CSS Contract Pattern

```css
/* Source: lib/threadline/operator_surface/style.ex */
.tl-shell-nav__item[aria-current="page"] {
  font-weight: var(--tl-weight-semibold);
  border-color: var(--tl-color-accent);
  box-shadow: inset 3px 0 0 var(--tl-color-accent);
}
```

This is the kind of non-color cue Phase 183 browser tests should confirm without turning the whole UI into snapshot testing. [VERIFIED: lib/threadline/operator_surface/style.ex] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md]

## State of the Art

| Old Approach | Current Approach | When Changed / Confirmed | Impact |
|--------------|------------------|--------------------------|--------|
| Custom JavaScript navigation drawers | Native disclosure plus responsive rail | Confirmed in current Phase 183 code and UI-SPEC. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] | Fewer dependencies, better source-testability, and simpler accessibility proof. |
| LiveComponents for markup organization | Function components for reusable markup, LiveComponents only for state/event ownership | Phoenix LiveComponent docs recommend function components generally. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html] | Prevents accidental stateful component complexity in shell polish. |
| Broad screenshot matrices for UI confidence | Narrow semantic browser checks plus bounded screenshots | Phase 181/183 context and current screenshot spec keep screenshots bounded. [VERIFIED: .planning/phases/181-baseline-audit-and-guard-repair/181-CONTEXT.md] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts] | Reduces rebaseline churn while still proving critical perception cells. |
| Generic Home "start" pages | Task-led Home with Timeline, Coverage, proof/governance links, EF1, EF4, and saved-view resume | UI-SPEC locks the Home task-launch hierarchy for Phase 183. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] | Keeps `/audit` useful for multiple operator personas without turning it into an info dump. |

**Deprecated/outdated:**

- Public component API work is deferred to `COMP-PUBLIC-01` or a future explicit milestone. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]
- Production/public Storybook is deferred to `STORY-PUBLIC-01` or a future explicit milestone. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]
- Tailwind/shadcn/root external UI dependency migration is rejected for Phase 183. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Research validity estimate is 30 days for local-code planning and should be rechecked before dependency upgrades. [ASSUMED] | Metadata | Low; affects future planning freshness only, not Phase 183 implementation. |

## Open Questions (RESOLVED)

1. **RESOLVED:** Plan 183-01 adds `examples/threadline_phoenix/e2e/tests/operator-shell-home-phase183.spec.ts` as the narrow Phase 183 browser supplement; no blocking open questions remain.
   - Resolution basis: D-183-16 allowed the planner to choose exact browser spec organization, and Plan 183-01 selected a dedicated semantic Playwright supplement to keep Phase 183 assertions readable without duplicating existing Home/nav/earned-flow coverage. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-01-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Source tests and Mix aliases | yes | 1.19.5, Erlang/OTP 28 | none needed [VERIFIED: elixir --version] |
| Mix | Source tests and verification aliases | yes | 1.19.5 | none needed [VERIFIED: mix --version] |
| Phoenix | Operator surface/example app | yes | 1.8.7 | none needed [VERIFIED: mix deps] |
| Phoenix LiveView | Operator LiveViews/components | yes | 1.1.30 | none needed [VERIFIED: mix deps] |
| Node.js | Playwright harness | yes | 22.14.0 | none needed [VERIFIED: node --version] |
| npm | Playwright harness package scripts | yes | 11.1.0 | none needed [VERIFIED: npm --version] |
| `@playwright/test` | Browser verification | yes | 1.60.0 installed | none needed [VERIFIED: npm ls @playwright/test] |
| Chromium | Local browser execution | yes | `/opt/homebrew/bin/chromium` | Playwright run script can install Chromium if missing. [VERIFIED: command -v chromium] [VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh] |
| PostgreSQL | Example app/browser data | yes | psql 14.17, server accepting connections | none needed [VERIFIED: psql --version] [VERIFIED: pg_isready] |
| Docker | Optional local infra support | yes | CLI present at `/usr/local/bin/docker` | not required for Phase 183 plan [VERIFIED: command -v docker] |

**Missing dependencies with no fallback:** none found. [VERIFIED: elixir --version] [VERIFIED: mix --version] [VERIFIED: npm ls @playwright/test] [VERIFIED: pg_isready]

**Missing dependencies with fallback:** Google Chrome CLI was not found, but Chromium is available and Playwright uses its managed/Chromium browser path. [VERIFIED: command -v google-chrome] [VERIFIED: command -v chromium] [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit/Phoenix.LiveViewTest for source/LiveView contracts; Playwright Test 1.60.0 for browser verification. [VERIFIED: mix deps] [VERIFIED: npm ls @playwright/test] |
| Config file | `mix.exs`, `examples/threadline_phoenix/e2e/playwright.config.ts`, and `examples/threadline_phoenix/e2e/run-e2e.sh`. [VERIFIED: mix.exs] [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts] [VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh] |
| Quick run command | `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/skip_link_test.exs test/threadline/operator_surface/surface_header_csp_test.exs` [VERIFIED: test/threadline/operator_surface/surface_header_test.exs] |
| Browser dark command | `mix verify.example_browser` [VERIFIED: mix.exs] |
| Browser light/system command | `mix verify.example_browser_light` [VERIFIED: mix.exs] |
| Full suite command | `mix ci.all` plus `mix verify.example_browser_light` for Phase 183 theme coverage if `ci.all` does not include the light/system lane. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SHELL-01 | One global nav surface is visible at 768px+ and clearly labeled/openable below 768px. [VERIFIED: .planning/REQUIREMENTS.md] | Source + browser | `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/style_contract_test.exs`; `mix verify.example_browser` with Phase 183 breakpoint assertions. [VERIFIED: mix.exs] | Existing source/browser files yes; strict Phase 183 browser supplement may be Wave 0. [VERIFIED: test/threadline/operator_surface/surface_header_test.exs] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts] |
| SHELL-02 | Home is task-led with primary Timeline, Coverage readiness, proof/governance links, health, EF1, EF4, and saved-view resume. [VERIFIED: .planning/REQUIREMENTS.md] | LiveView + browser | `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/copy_contract_test.exs`; `mix verify.example_browser` with Home hierarchy/flow assertions. [VERIFIED: mix.exs] | Existing source/browser files yes; hierarchy-specific browser checks need tightening. [VERIFIED: test/threadline/operator_surface/live/start_live_test.exs] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts] |
| SHELL-03 | Active state, feature gates, skip link, theme picker, and topbar status are accessible across dark/light/system and 320-1440px. [VERIFIED: .planning/REQUIREMENTS.md] | Source + browser + accessibility | `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/skip_link_test.exs test/threadline/operator_surface/surface_header_csp_test.exs`; `mix verify.example_browser`; `mix verify.example_browser_light`. [VERIFIED: mix.exs] | Existing source/browser files yes; selected-theme/current-state light/system checks need targeted additions. [VERIFIED: test/threadline/operator_surface/skip_link_test.exs] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts] |

### Sampling Rate

- **Per task commit:** run the quick source command for touched shell/Home files; run the targeted Playwright spec when browser-facing layout or interaction changes. [VERIFIED: mix.exs] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts]
- **Per wave merge:** run `mix verify.threadline` plus the targeted browser lane affected by the wave. [VERIFIED: mix.exs]
- **Phase gate:** run `mix ci.all`, `mix verify.example_browser`, and `mix verify.example_browser_light` or document any environment failure with the failing command and artifact. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md]

### Wave 0 Gaps

- [ ] Decide whether to extend existing Playwright specs or add `examples/threadline_phoenix/e2e/tests/operator-shell-home-phase183.spec.ts`; current files do not contain all Phase 183 perception cells. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md]
- [ ] Add strict browser assertions for 320, 375, 768, 1024, 1280, and 1440 widths without creating a broad screenshot matrix. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md]
- [ ] Add dark default plus light/system selected-theme/current-state/Home-error assertions through the existing browser lanes. [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts] [VERIFIED: mix.exs]
- [ ] No source test framework gap was found; source tests already exist for shell, Home, style, copy, skip link, CSP/theme, and router contracts. [VERIFIED: test/threadline/operator_surface/surface_header_test.exs] [VERIFIED: test/threadline/operator_surface/live/start_live_test.exs] [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] [VERIFIED: test/threadline/operator_surface/router_test.exs]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not explicitly set `security_enforcement` to `false`. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes, indirectly | Preserve host-owned router/auth boundary and do not make unauthenticated shell routes public. [VERIFIED: lib/threadline/operator_surface/router.ex] |
| V3 Session Management | yes | Preserve server-resolved theme/session handling and CSRF-protected POST behavior; do not add localStorage-only security state. [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: test/threadline/operator_surface/surface_header_csp_test.exs] |
| V4 Access Control | yes | Keep feature-gated groups absent when disabled and preserve fail-closed route/auth behavior. [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/router.ex] |
| V5 Input Validation | yes | Keep EF1 mapped-table validation, record id validation, EF4 correlation id validation, and local `role="alert"` errors. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex] [VERIFIED: test/threadline/operator_surface/live/start_live_test.exs] |
| V6 Cryptography | limited | Do not hand-roll cryptography; preserve Phoenix/Plug CSRF/session mechanisms for theme POST. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: test/threadline/operator_surface/surface_header_csp_test.exs] |

### Known Threat Patterns for Phoenix LiveView Operator Shell

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized destination exposure through client-only feature hiding | Information Disclosure / Elevation of Privilege | Render feature-gated groups server-side from `auth.ex` assigns and preserve router/auth gates. [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/router.ex] |
| CSRF or inline-handler theme mutation | Tampering | Keep native POST form with CSRF token and source tests that forbid inline handlers. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] [VERIFIED: test/threadline/operator_surface/surface_header_csp_test.exs] |
| Open-ended row/correlation launcher paths | Tampering | Keep mapped-table selection, record/correlation validation, and canonical route construction in `StartLive`. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex] [VERIFIED: test/threadline/operator_surface/live/start_live_test.exs] |
| Hidden focus or overflow blocks keyboard/mobile operators | Denial of Service / Usability failure | Keep skip link, `#tl-main`, visible focus rings, and 320px no-overflow browser checks. [VERIFIED: test/threadline/operator_surface/skip_link_test.exs] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/reflow.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html] |
| XSS through shell/Home text changes | Tampering | Stay in HEEx/function components and avoid manual HTML string concatenation. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] [VERIFIED: lib/threadline/operator_surface/ui.ex] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md` - locked decisions, boundaries, canonical refs, deferred ideas. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]
- `.planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md` - visual, copy, responsive, accessibility, and verification contract. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md]
- `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` - SHELL-01 through SHELL-03 and phase ownership boundaries. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md]
- `lib/threadline/operator_surface/ui.ex`, `components/surface_header.ex`, `live/start_live.ex`, `style.ex`, `router.ex`, and `auth.ex` - current implementation substrate. [VERIFIED: lib/threadline/operator_surface/ui.ex] [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] [VERIFIED: lib/threadline/operator_surface/live/start_live.ex] [VERIFIED: lib/threadline/operator_surface/style.ex] [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex]
- Existing ExUnit and Playwright tests named in Phase 183 CONTEXT - current verification substrate and gaps. [VERIFIED: test/threadline/operator_surface/surface_header_test.exs] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts]

### Secondary (MEDIUM confidence)

- Phoenix Component docs - function components, attrs, slots, and global attrs. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html]
- Phoenix LiveComponent docs - LiveComponent state/event boundary and function-component preference. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html]
- Phoenix LiveViewTest docs - selector/render test APIs. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
- Playwright best practices - locator/actionability/web-first guidance. [CITED: https://playwright.dev/docs/best-practices]
- W3C WCAG 2.2 Reflow and Focus Visible - 320px/no two-dimensional scrolling and visible keyboard focus. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/reflow.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html]
- WAI-ARIA APG Disclosure pattern - disclosure control expectations for expandable panels. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/]

### Tertiary (LOW confidence)

- None used for implementation decisions. [VERIFIED: /tmp/research-plan-input-183.json]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - versions and dependency posture were verified from `mix deps`, `npm ls`, local package files, and project docs. [VERIFIED: mix deps] [VERIFIED: npm ls @playwright/test] [VERIFIED: CLAUDE.md]
- Architecture: HIGH - responsibility mapping follows current local router/auth/shell/Home/CSS code and locked Phase 183 decisions. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-CONTEXT.md]
- Pitfalls: HIGH - pitfalls are drawn from locked Phase 183 decisions, UI-SPEC prohibitions, and existing source/browser test contracts. [VERIFIED: .planning/phases/183-shell-navigation-and-home-orientation/183-UI-SPEC.md] [VERIFIED: test/threadline/operator_surface/style_contract_test.exs]
- External framework guidance: MEDIUM - official docs were fetched through web search/open and cached through the GSD research store, but local code remains the controlling source for this phase. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] [CITED: https://playwright.dev/docs/best-practices]

**Research date:** 2026-06-28
**Valid until:** 2026-07-28 for local-code planning; re-check external framework docs before dependency upgrades. [ASSUMED]
