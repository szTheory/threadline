# Phase 182: PhoenixStorybook example/dev lane - Research

**Researched:** 2026-06-26  
**Domain:** PhoenixStorybook maintainer tooling for a Phoenix example app  
**Confidence:** HIGH for codebase constraints and route/package boundaries; MEDIUM for PhoenixStorybook integration details because Context7 was unavailable and official docs/Hex pages were used directly.

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for this whole section: `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`

### Locked Decisions

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

### the agent's Discretion

The user selected all gray areas and asked for subagent-backed, research-first, one-shot recommendations rather than piecemeal choices. Downstream agents may choose exact file names, helper module names, and test split, but must preserve the decisions above.

### Deferred Ideas (OUT OF SCOPE)

- Production, hosted, or public Storybook belongs in a future explicit STORY-PUBLIC or private-docs milestone.
- Public component API remains deferred to `COMP-PUBLIC-01`.
- Full visual-regression SaaS adoption remains deferred unless a future milestone explicitly chooses it.
- Replacing `/audit/__stress` with Storybook is rejected for this milestone.
- Shell/Home/Timeline/Coverage/detail/governance/export page polish remains in Phases 183-186.
- Real screen-reader certification remains out of scope unless explicitly run; browser accessibility-tree and keyboard evidence can support later Phase 187.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STORY-01 | The Phoenix example app exposes PhoenixStorybook as a dev/test maintainer component-lab lane without adding a root `threadline` dependency or production route. | Use `phoenix_storybook` only in `examples/threadline_phoenix/mix.exs`, guard router imports/routes with `Application.compile_env(:threadline_phoenix, :dev_routes)`, keep backend module safe when the dependency is absent, and prove root `mix verify.compile_no_optional` remains green. `[VERIFIED: mix.exs]` `[VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]` `[CITED: https://phoenix-storybook.hexdocs.pm/setup.html]` |
| STORY-02 | Storybook stories cover the internal primitive, form, state, overlay, data-display, and recurring group components across dark/light/system and representative ugly data. | Use existing `Threadline.OperatorSurface.UI` functions and selected `StressFixtures` cases through explicit helper/allowlist; use PhoenixStorybook `Variation`, `VariationGroup`, templates, slots, notes, layouts, and source rendering. `[VERIFIED: lib/threadline/operator_surface/ui.ex]` `[VERIFIED: lib/threadline/operator_surface/stress_fixtures.ex]` `[CITED: https://phoenix-storybook.hexdocs.pm/components.html]` |
| STORY-03 | `/audit/__stress` remains the canonical authenticated operator-flow stress harness, and docs explain when to use Storybook versus the stress route. | Preserve existing stress route auth/ledger tests, keep page-flow and full matrix coverage in `/audit/__stress` plus Playwright, and add doc contracts for the Storybook-vs-stress distinction. `[VERIFIED: test/threadline/operator_surface/stress_router_test.exs]` `[VERIFIED: examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts]` |
</phase_requirements>

## Summary

Phase 182 should be planned as a narrow example-app tooling lane: add PhoenixStorybook inside `examples/threadline_phoenix` only, mount it at `/dev/storybook`, and keep every root package and adopter-facing surface free of Storybook dependency leakage. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` `[VERIFIED: mix.exs]` The current root `mix compile --no-optional-deps --warnings-as-errors` passes before Phase 182 changes, so the planner should preserve that as a hard gate. `[VERIFIED: command run 2026-06-26]`

The best implementation shape is manual PhoenixStorybook setup, not generator-driven setup: add the Hex dependency only in the example app, define a backend module and curated `.story.exs` content, mount `storybook_assets` separately, and mount `live_storybook` from a root `scope "/"` using the full `/dev/storybook` path. `[CITED: https://phoenix-storybook.hexdocs.pm/setup.html]` `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]` PhoenixStorybook's current router docs explicitly say `live_storybook` cannot be used in a scope whose path is different from `/`, which makes D-182-03 a real implementation constraint rather than a style preference. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]`

Story coverage should be curated around the actual private Threadline components, not generated from the ledger or stress registry. `[VERIFIED: lib/threadline/operator_surface/ui.ex]` `[VERIFIED: .planning/design-system-ledger.json]` Use PhoenixStorybook variations, variation groups, templates, slots, and notes to document component states, while `/audit/__stress` remains the authenticated page/flow/ugly-data stress harness. `[CITED: https://phoenix-storybook.hexdocs.pm/components.html]` `[VERIFIED: lib/threadline/operator_surface/stress_router.ex]` `[VERIFIED: examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts]`

**Primary recommendation:** Add `phoenix_storybook` `~> 1.2.0` only to `examples/threadline_phoenix` dev/test, manually mount `/dev/storybook` behind `dev_routes`, build curated story files plus a Threadline wrapper/helper, and verify absence from root and production through source, route, browser, and doc contracts. `[CITED: https://phoenix-storybook.hexdocs.pm/setup.html]` `[VERIFIED: mix hex.info phoenix_storybook 1.2.0]`

## Project Constraints (from CLAUDE.md and AGENTS.md)

| Source | Constraint | Planning Implication |
|--------|------------|----------------------|
| `CLAUDE.md` | Threadline has three separate layers: capture, semantics, and exploration/operations. `[VERIFIED: CLAUDE.md]` | Storybook must stay in the exploration/maintainer tooling lane and must not touch capture or semantics. `[VERIFIED: .planning/REQUIREMENTS.md]` |
| `CLAUDE.md` | Root verification prefers named `mix verify.*` and `mix ci.*` aliases. `[VERIFIED: CLAUDE.md]` | Use existing `mix verify.compile_no_optional`, `mix verify.example`, and bounded browser commands in the plan. `[VERIFIED: mix.exs]` |
| `CLAUDE.md` | Root Phoenix/LiveView dependencies are optional. `[VERIFIED: mix.exs]` | Do not add `phoenix_storybook` to root `mix.exs` or root `mix.lock`. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |
| `examples/threadline_phoenix/AGENTS.md` | Phoenix v1.8 templates should use `<Layouts.app flash={@flash} ...>` and current scope conventions when writing LiveViews. `[VERIFIED: examples/threadline_phoenix/AGENTS.md]` | New example-app LiveViews, if any, must follow Phoenix 1.8 conventions; story files should avoid needing app LiveViews unless PhoenixStorybook requires them. `[VERIFIED: examples/threadline_phoenix/AGENTS.md]` |
| `examples/threadline_phoenix/AGENTS.md` | Use `<.input>` from `core_components.ex` when available and do not call `<.flash_group>` outside layouts. `[VERIFIED: examples/threadline_phoenix/AGENTS.md]` | Example-app wrapper/support code should not invent parallel form primitives or layout flash behavior. `[VERIFIED: examples/threadline_phoenix/AGENTS.md]` |
| `examples/threadline_phoenix/AGENTS.md` | Use `mix precommit` when done with all changes in the example app. `[VERIFIED: examples/threadline_phoenix/AGENTS.md]` | Planner should include targeted compile/test steps and likely finish with `cd examples/threadline_phoenix && mix precommit` if the phase touches example app code. `[VERIFIED: examples/threadline_phoenix/mix.exs]` |
| Project skills | No `.claude/skills/` or `.agents/skills/` project skill files were found. `[VERIFIED: find .claude/skills .agents/skills]` | No additional project-local skill rules need to be loaded for the plan. `[VERIFIED: find .claude/skills .agents/skills]` |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| PhoenixStorybook dependency boundary | Example Phoenix app | Root package source contracts | The dependency belongs only in `examples/threadline_phoenix/mix.exs`, while root tests prove it is absent from root `threadline`. `[VERIFIED: examples/threadline_phoenix/mix.exs]` `[VERIFIED: mix.exs]` |
| `/dev/storybook` route and assets | Frontend server / Phoenix router | Browser | PhoenixStorybook is mounted through LiveView router macros and serves its own static assets path; the browser consumes the resulting Storybook UI. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]` |
| Dev/test gating | Frontend server / Phoenix router | Mix compile environment | The example app already uses `Application.compile_env(:threadline_phoenix, :dev_routes)` for `/dev` tooling, so Storybook should join that compile-time boundary. `[VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]` |
| Story content and navigation | PhoenixStorybook backend/content tree | Story files | PhoenixStorybook discovers `.story.exs` content under `content_path` and builds sidebar structure from folders/indexes. `[CITED: https://phoenix-storybook.hexdocs.pm/setup.html]` `[CITED: https://hexdocs.pm/phoenix_storybook/PhoenixStorybook.Index.html]` |
| Component rendering | PhoenixStorybook LiveView renderer | Threadline private component modules | Stories should call `Threadline.OperatorSurface.UI` functions and components without creating public component APIs. `[VERIFIED: lib/threadline/operator_surface/ui.ex]` `[CITED: https://phoenix-storybook.hexdocs.pm/components.html]` |
| Theme wrapper | Component/story helper | CSS contract | The wrapper must render `.threadline-ui`, `Threadline.OperatorSurface.Style.css`, and `data-tl-theme` so Storybook uses Threadline's actual CSS/theme contract. `[VERIFIED: lib/threadline/operator_surface/style.ex]` `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |
| Ugly data sampling | Root stress fixture module | Story helper allowlist | `StressFixtures` remains canonical for stress route data, while Storybook may sample through explicit read-only helpers. `[VERIFIED: lib/threadline/operator_surface/stress_fixtures.ex]` `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |
| Storybook-vs-stress documentation | Docs/tests | Example README | Docs must explain Storybook as component documentation and `/audit/__stress` as authenticated operator-flow stress testing. `[VERIFIED: .planning/REQUIREMENTS.md]` |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_storybook` | `1.2.0` | Phoenix component Storybook UI and story routing. `[VERIFIED: mix hex.info phoenix_storybook 1.2.0]` | Official PhoenixStorybook setup docs prescribe `{:phoenix_storybook, "~> 1.2.0"}` and the package was last updated on 2026-06-11. `[CITED: https://phoenix-storybook.hexdocs.pm/setup.html]` `[CITED: https://hex.pm/packages/phoenix_storybook]` |
| `phoenix` | example app currently `1.8.5`; latest registry `1.8.8` | Existing Phoenix server/router/LiveView host for the example app. `[VERIFIED: examples/threadline_phoenix/mix.lock]` `[VERIFIED: mix hex.info phoenix]` | PhoenixStorybook 1.2.0 requires `phoenix ~> 1.8.1`, and the example app already satisfies that family. `[VERIFIED: mix hex.info phoenix_storybook 1.2.0]` `[VERIFIED: examples/threadline_phoenix/mix.lock]` |
| `phoenix_live_view` | example app currently `1.1.28`; latest registry `1.2.3` | Existing LiveView runtime used by the operator surface and Storybook. `[VERIFIED: examples/threadline_phoenix/mix.lock]` `[VERIFIED: mix hex.info phoenix_live_view]` | PhoenixStorybook 1.2.0 requires `phoenix_live_view ~> 1.1.0`, and the example app already locks a compatible 1.1.x version. `[VERIFIED: mix hex.info phoenix_storybook 1.2.0]` `[VERIFIED: examples/threadline_phoenix/mix.lock]` |

### Supporting

| Library/Tool | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| ExUnit + `Phoenix.LiveViewTest` | from current Mix/Phoenix stack | Route presence/absence, rendered Storybook smoke, and source-contract tests. `[VERIFIED: test/threadline/operator_surface/stress_router_test.exs]` | Use for fast route/source/doc contracts before browser E2E. `[VERIFIED: test/threadline/operator_surface/stress_router_test.exs]` |
| Playwright | package installed `1.60.0`; package.json range `^1.52.0` | Bounded browser smoke for Storybook index and representative stories. `[VERIFIED: npm --prefix examples/threadline_phoenix/e2e ls @playwright/test]` `[VERIFIED: examples/threadline_phoenix/e2e/package.json]` | Use after route/story implementation to prove assets and theme wrapper render in a real browser. `[VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh]` |
| `Threadline.OperatorSurface.StressFixtures` | in-repo module | Canonical ugly-data vocabulary and fixture data for stress route. `[VERIFIED: lib/threadline/operator_surface/stress_fixtures.ex]` | Sample through explicit helpers/allowlists only; do not convert it into Storybook navigation. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |
| `Threadline.OperatorSurface.Style.css/1` | in-repo module | Inline CSS/style contract for `.threadline-ui` and dark/light/system lanes. `[VERIFIED: lib/threadline/operator_surface/style.ex]` | Render inside the Storybook wrapper so stories use product CSS rather than a parallel asset theme. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual PhoenixStorybook setup | `mix phx.gen.storybook` | The generator may add asset/Docker/router defaults that conflict with the locked `/dev/storybook`, no-production, no-root-dependency boundary. `[CITED: https://phoenix-storybook.hexdocs.pm/setup.html]` `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |
| Curated stories | Generated mirror from `.planning/design-system-ledger.json` or full `StressFixtures` | Generated mirrors would blur Storybook component docs with `/audit/__stress` flow stress coverage. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |
| Bounded Playwright smoke | Percy/Chromatic/Applitools-style visual matrix | PhoenixStorybook docs mention dedicated visual-regression tooling, but the phase explicitly rejects external visual-regression SaaS and a large screenshot matrix. `[CITED: https://phoenix-storybook.hexdocs.pm/testing.html]` `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |

**Installation:**

```elixir
# examples/threadline_phoenix/mix.exs
{:phoenix_storybook, "~> 1.2.0", only: [:dev, :test]}
```

Run dependency resolution from the example app only:

```bash
cd examples/threadline_phoenix
mix deps.get
```

Do not add a root install command or root dependency. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`

**Version verification:** `mix hex.info phoenix_storybook 1.2.0` returned release date 2026-06-11, dependencies, downloads, and publisher metadata. `[VERIFIED: mix hex.info phoenix_storybook 1.2.0]`

## Package Legitimacy Audit

> The standard GSD package-legitimacy seam supports npm, PyPI, and crates only, and returned a usage error for `--ecosystem hex`; this audit therefore uses Hex registry metadata, official docs, and the Hex advisory page. `[VERIFIED: gsd-tools package-legitimacy check --ecosystem hex phoenix_storybook]` `[CITED: https://hex.pm/packages/phoenix_storybook]`

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `phoenix_storybook` | Hex | First visible Hex version `0.5.0` on 2023-02-27; latest `1.2.0` on 2026-06-11. `[CITED: https://hex.pm/packages/phoenix_storybook/versions]` | 1,592,791 all time; 7,677 last 7 days; 3,349 for version 1.2.0 at research time. `[CITED: https://hex.pm/packages/phoenix_storybook]` | `github.com/phenixdigital/phoenix_storybook` `[CITED: https://hex.pm/packages/phoenix_storybook]` | OK with security floor | Approved only as `~> 1.2.0` in example dev/test; do not use versions `< 1.1.0` because Hex lists recent advisories affecting those older ranges. `[CITED: https://hex.pm/packages/phoenix_storybook/advisories]` |

**Packages removed due to [SLOP] verdict:** none. `[VERIFIED: gsd-tools package-legitimacy gate unsupported for Hex; no SLOP verdict emitted]`

**Packages flagged as suspicious [SUS]:** none by the unsupported seam; the planner must still preserve the explicit security floor because Hex lists critical/high advisories for versions `< 1.1.0`. `[CITED: https://hex.pm/packages/phoenix_storybook/advisories]`

**Transitive dependencies:** Hex lists `makeup_eex`, `makeup_html`, `mdex`, `phoenix`, `phoenix_live_view`, and optional `jason` for `phoenix_storybook` 1.2.0. `[CITED: https://hex.pm/packages/phoenix_storybook/dependencies]` Let Mix resolve these from the example app, and do not mirror them into the root package. `[VERIFIED: examples/threadline_phoenix/mix.exs]`

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer opens /dev/storybook
  -> Phoenix example router checks dev_routes compile boundary
    -> if dev/test enabled:
         storybook_assets("/dev/storybook/assets") serves PhoenixStorybook static assets
         live_storybook("/dev/storybook", backend_module: ThreadlinePhoenixWeb.Storybook)
           -> PhoenixStorybook backend discovers curated .story.exs files
           -> Story helper wraps each preview in:
                Threadline.OperatorSurface.Style.css()
                <div class="threadline-ui" data-tl-theme="dark|light|system">
           -> Story variations render private Threadline.OperatorSurface.UI components
           -> selected helper fixtures sample StressFixtures through explicit allowlists
       if prod / dev_routes false:
         no Storybook route, no Storybook asset route, no backend dependency usage

Separate existing lane:
Authenticated operator -> /audit/__stress
  -> Threadline.OperatorSurface.StressRouter
  -> StressFixtures full ugly-data/page-flow matrix
  -> Playwright stress semantics and screenshot guard
```

The diagram reflects the existing stress route and the PhoenixStorybook router shape. `[VERIFIED: lib/threadline/operator_surface/stress_router.ex]` `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]`

### Recommended Project Structure

```text
examples/threadline_phoenix/
├── lib/threadline_phoenix_web/storybook.ex        # backend module guarded for dev/test dependency absence
├── lib/threadline_phoenix_web/storybook/          # wrapper/helpers, small and explicit
├── storybook/
│   ├── foundations/
│   ├── primitives/
│   ├── forms/
│   ├── states/
│   ├── overlays/
│   ├── data_display/
│   ├── groups/
│   └── patterns/
├── test/threadline_phoenix_web/storybook_route_test.exs
└── e2e/tests/operator-storybook.spec.ts
```

This structure keeps Storybook files inside the example app and away from root `lib/`. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`

### Pattern 1: Dev/Test Root-Scope Router Mount

**What:** Mount Storybook through the example app's existing `dev_routes` compile-time boundary, but use `scope "/"` with full `/dev/storybook` paths. `[VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]` `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]`

**When to use:** Use this for all Storybook route and asset mounting in Phase 182. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`

**Example:**

```elixir
# Source: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html
if Application.compile_env(:threadline_phoenix, :dev_routes) do
  import PhoenixStorybook.Router

  scope "/" do
    storybook_assets("/dev/storybook/assets")
  end

  scope "/", ThreadlinePhoenixWeb do
    pipe_through(:browser)

    live_storybook("/dev/storybook",
      backend_module: ThreadlinePhoenixWeb.Storybook,
      assets_path: "/dev/storybook/assets"
    )
  end
end
```

Do not place `live_storybook` inside `scope "/dev"` because PhoenixStorybook documents that the macro cannot be used in a non-root path scope. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]`

### Pattern 2: Backend Module Safe When Dependency Is Absent

**What:** Ensure production compilation does not need `PhoenixStorybook` when the dependency is dev/test-only. `[VERIFIED: examples/threadline_phoenix/mix.exs]`

**When to use:** Use this when the backend module is under `lib/`, because example app `elixirc_paths/1` currently compiles `lib` in all environments. `[VERIFIED: examples/threadline_phoenix/mix.exs]`

**Example:**

```elixir
# Source: https://phoenix-storybook.hexdocs.pm/setup.html
if Code.ensure_loaded?(PhoenixStorybook) do
  defmodule ThreadlinePhoenixWeb.Storybook do
    use PhoenixStorybook,
      otp_app: :threadline_phoenix,
      content_path: Path.expand("../../../storybook", __DIR__),
      sandbox_class: "threadline-ui",
      color_mode: true
  end
end
```

If the implementation prefers environment-specific compile paths instead, it must update `elixirc_paths/1` deliberately and prove prod route absence. `[VERIFIED: examples/threadline_phoenix/mix.exs]`

### Pattern 3: Threadline Theme Wrapper

**What:** Render every story preview inside the real Threadline CSS and theme scope. `[VERIFIED: lib/threadline/operator_surface/style.ex]`

**When to use:** Use for each component story or through a shared story template/helper. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`

**Example:**

```elixir
# Source: lib/threadline/operator_surface/style.ex and PhoenixStorybook templates docs
def threadline_template(theme) when theme in ["dark", "light", "system"] do
  """
  <style data-threadline-storybook>
    /* render Threadline.OperatorSurface.Style.css/1 through helper, not duplicated CSS */
  </style>
  <div class="threadline-ui" data-tl-theme="#{theme}">
    <.psb-variation/>
  </div>
  """
end
```

Planner note: implement the CSS injection with real HEEx/component rendering if possible; the example above shows shape, not final code. `[VERIFIED: lib/threadline/operator_surface/style.ex]` `[CITED: https://phoenix-storybook.hexdocs.pm/components.html]`

### Pattern 4: Curated Variation Groups

**What:** Use PhoenixStorybook `Variation` and `VariationGroup` for representative states. `[CITED: https://phoenix-storybook.hexdocs.pm/components.html]`

**When to use:** Use variation groups for theme triplets, ugly-data clusters, and state families where seeing variants together aids maintainer review. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`

**Example:**

```elixir
# Source: https://phoenix-storybook.hexdocs.pm/components.html
def variations do
  [
    %VariationGroup{
      id: :theme_triplet,
      description: "Theme wrapper smoke",
      variations: [
        %Variation{id: :dark, attributes: %{theme: "dark"}},
        %Variation{id: :light, attributes: %{theme: "light"}},
        %Variation{id: :system, attributes: %{theme: "system"}}
      ]
    }
  ]
end
```

### Anti-Patterns To Avoid

- **Root dependency leakage:** Do not add `phoenix_storybook` to root `mix.exs`, root `mix.lock`, root public router macros, or root docs that tell adopters to install it. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`
- **Nested `/dev` scope mount:** Do not mount `live_storybook` inside `scope "/dev"`; use a root scope with the full `/dev/storybook` path. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]`
- **Public component docs via `@doc`:** Do not add public-facing docs to private operator components just to feed PhoenixStorybook's doc extraction. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` `[CITED: https://phoenix-storybook.hexdocs.pm/components.html]`
- **Generated full fixture mirror:** Do not generate a Storybook tree from the ledger or all `StressFixtures`; use allowlisted samples. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`
- **Replacing `/audit/__stress`:** Do not move auth/page-flow/footgun coverage from stress route into Storybook. `[VERIFIED: .planning/REQUIREMENTS.md]`
- **External visual-regression SaaS:** Do not introduce Percy, Chromatic, Applitools, or a large screenshot matrix in this phase. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` `[CITED: https://phoenix-storybook.hexdocs.pm/testing.html]`

## Route And Gating Implications

| Concern | Required Handling |
|---------|-------------------|
| `storybook_assets` | Mount separately from `live_storybook`, because PhoenixStorybook documents that static assets should not be CSRF protected. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]` |
| `live_storybook` path | Use `/dev/storybook` as the macro path in a root `scope "/"`, because the macro cannot be used inside a non-root path scope. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]` |
| Production | With `dev_routes` false/absent, production must have no `/dev/storybook`, no `/dev/storybook/assets`, and no dependency requirement at compile/runtime. `[VERIFIED: examples/threadline_phoenix/config/prod.exs]` |
| Test | `config/test.exs` already sets `config :threadline_phoenix, dev_routes: true`, so route tests can verify Storybook presence in MIX_ENV=test. `[VERIFIED: examples/threadline_phoenix/config/test.exs]` |
| Dev | `config/dev.exs` already sets `config :threadline_phoenix, dev_routes: true`, so local maintainers get the route when running the example app. `[VERIFIED: examples/threadline_phoenix/config/dev.exs]` |
| Auth | Phase context says normal operator login is not required for the local component lab unless implementation discovers exposure beyond local/dev use. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |
| Links | Do not add Storybook to normal operator nav or adopter docs; if a dev-only link is added, it must be under dev/test tooling and not demo/production docs. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Story routing/sidebar/content discovery | Custom LiveView story browser | PhoenixStorybook backend/content tree | PhoenixStorybook already discovers `.story.exs` content and provides navigation. `[CITED: https://phoenix-storybook.hexdocs.pm/setup.html]` |
| Component variation rendering | Ad hoc component preview pages | PhoenixStorybook `Variation` and `VariationGroup` | The library provides typed variations, grouped previews, notes, slots, templates, layouts, and source rendering. `[CITED: https://phoenix-storybook.hexdocs.pm/components.html]` |
| Theme preview mechanism | Parallel CSS/theme implementation | Shared Threadline wrapper around real `Style.css/1` and `data-tl-theme` | Threadline's theme contract already lives in `.threadline-ui[data-tl-theme=...]`; duplicating it creates drift. `[VERIFIED: lib/threadline/operator_surface/style.ex]` |
| Ugly data generator | New random faker/data factory | Explicit `StressFixtures` helper/allowlist | Existing stress fixtures already encode the project's ugly-data vocabulary and must remain canonical for stress route. `[VERIFIED: lib/threadline/operator_surface/stress_fixtures.ex]` |
| Production exclusion | Runtime-only hiding or nav omission | Compile-time `dev_routes` branch plus route/source tests | Production must have no route or assets route, not merely no visible link. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |
| Browser smoke harness | New browser framework | Existing Playwright E2E harness | The example app already has Playwright setup and a dynamic local server runner. `[VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh]` |
| Documentation drift checks | Manual README review only | Existing doc-contract test pattern | Root docs already use ExUnit doc-contract tests to lock wording and snippets. `[VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]` |

**Key insight:** PhoenixStorybook should own component documentation mechanics, while Threadline owns the wrapper, fixture boundaries, route gating, and verification contracts. `[CITED: https://phoenix-storybook.hexdocs.pm/components.html]` `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`

## Common Pitfalls

### Pitfall 1: Mounting In The Wrong Scope

**What goes wrong:** `live_storybook` is nested under `scope "/dev"` and fails or generates incorrect paths. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]`

**Why it happens:** PhoenixStorybook's router macro expects use from a root path scope. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]`

**How to avoid:** Use `scope "/"` and pass the full `/dev/storybook` path to `live_storybook`; pass matching `/dev/storybook/assets` to `storybook_assets` and `assets_path`. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]`

**Warning signs:** Route tests show `/storybook` instead of `/dev/storybook`, or assets resolve under `/storybook/assets`. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]`

### Pitfall 2: Dev/Test Dependency Compiles In Prod

**What goes wrong:** A production compile references `PhoenixStorybook` even though the dependency is `only: [:dev, :test]`. `[VERIFIED: examples/threadline_phoenix/mix.exs]`

**Why it happens:** The example app compiles `lib` in all environments, and an unguarded backend module under `lib` would call `use PhoenixStorybook` when the dependency is absent. `[VERIFIED: examples/threadline_phoenix/mix.exs]`

**How to avoid:** Guard backend module definition with `Code.ensure_loaded?(PhoenixStorybook)` or move Storybook-only modules to an environment-specific compile path with tests. `[VERIFIED: examples/threadline_phoenix/mix.exs]`

**Warning signs:** `MIX_ENV=prod mix compile` fails with missing `PhoenixStorybook` module or route macro. `[VERIFIED: examples/threadline_phoenix/config/prod.exs]`

### Pitfall 3: Storybook Becomes A Public API

**What goes wrong:** Private operator components gain public docs or adopter instructions because Storybook docs are convenient. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`

**Why it happens:** PhoenixStorybook fetches function component docs from `@doc` tags by default. `[CITED: https://phoenix-storybook.hexdocs.pm/components.html]`

**How to avoid:** Put maintainer prose in story notes, page stories, and index files, and keep `Threadline.OperatorSurface.UI` private. `[VERIFIED: lib/threadline/operator_surface/ui.ex]` `[CITED: https://phoenix-storybook.hexdocs.pm/components.html]`

**Warning signs:** Root HexDocs or README content tells adopters to install PhoenixStorybook or consume private UI functions. `[VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]`

### Pitfall 4: Theme Drift

**What goes wrong:** Storybook's dark/light/system selector changes Storybook chrome but not Threadline's real `data-tl-theme` contract. `[CITED: https://phoenix-storybook.hexdocs.pm/color_modes.html]` `[VERIFIED: lib/threadline/operator_surface/style.ex]`

**Why it happens:** PhoenixStorybook color modes use sandbox classes by default, while Threadline uses `.threadline-ui[data-tl-theme=...]`. `[CITED: https://phoenix-storybook.hexdocs.pm/color_modes.html]` `[VERIFIED: lib/threadline/operator_surface/style.ex]`

**How to avoid:** Use PhoenixStorybook color mode only as optional chrome support, and render named story variations through a wrapper that sets `data-tl-theme`. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`

**Warning signs:** Story previews look correct in Storybook chrome but do not include `class="threadline-ui"` or `data-tl-theme`. `[VERIFIED: test/threadline/operator_surface/stress_router_test.exs]`

### Pitfall 5: Overbroad Story Matrix

**What goes wrong:** The phase creates every component x theme x viewport x ugly-data combination and becomes a visual-regression milestone. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`

**Why it happens:** Storybook makes state combinations easy to add, but Phase 182 requires representative coverage rather than exhaustive coverage. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`

**How to avoid:** Use representative variations and a bounded browser smoke list covering primitive/form/state/overlay/data-display/group. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`

**Warning signs:** Plans propose Percy/Chromatic/Applitools or full screenshot baselines for all stories. `[VERIFIED: test/threadline/operator_surface/stress_router_test.exs]`

### Pitfall 6: Old PhoenixStorybook Version

**What goes wrong:** The example app resolves a `phoenix_storybook` version affected by recent advisories. `[CITED: https://hex.pm/packages/phoenix_storybook/advisories]`

**Why it happens:** Advisories listed on Hex affect ranges below `1.1.0`, including a critical playground HEEx injection advisory. `[CITED: https://hex.pm/packages/phoenix_storybook/advisories]`

**How to avoid:** Use `~> 1.2.0`, verify `mix.lock`, and keep Storybook dev/test-only with no production route. `[VERIFIED: mix hex.info phoenix_storybook 1.2.0]` `[CITED: https://hex.pm/packages/phoenix_storybook/advisories]`

**Warning signs:** `mix.lock` shows `phoenix_storybook` `< 1.1.0`, or production routes include `/dev/storybook`. `[CITED: https://hex.pm/packages/phoenix_storybook/advisories]`

## Code Examples

Verified patterns from official sources and current code:

### Router Mount

```elixir
# Source: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html
if Application.compile_env(:threadline_phoenix, :dev_routes) do
  import PhoenixStorybook.Router

  scope "/" do
    storybook_assets("/dev/storybook/assets")
  end

  scope "/", ThreadlinePhoenixWeb do
    pipe_through(:browser)

    live_storybook("/dev/storybook",
      backend_module: ThreadlinePhoenixWeb.Storybook,
      assets_path: "/dev/storybook/assets"
    )
  end
end
```

### Story Variation With Slots

```elixir
# Source: https://phoenix-storybook.hexdocs.pm/components.html
defmodule ThreadlinePhoenixWeb.Storybook.DataDisplay.DataTable do
  use PhoenixStorybook.Story, :component

  alias PhoenixStorybook.Stories.Variation
  alias Threadline.OperatorSurface.UI

  def function, do: &UI.data_table/1
  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :mixed_severity,
        attributes: %{rows: ThreadlinePhoenixWeb.Storybook.Fixtures.rows(:mixed_severity)},
        slots: [
          ~S|<:col :let={row} label="Subject"><%= row.subject %></:col>|,
          ~S|<:col :let={row} label="Action"><%= row.action %></:col>|
        ],
        note: "Uses representative ugly data from the explicit Storybook allowlist."
      }
    ]
  end
end
```

### Route Contract Shape

```elixir
# Source: test/threadline/operator_surface/stress_router_test.exs pattern
test "example Storybook route is test/dev only" do
  routes = Phoenix.Router.routes(ThreadlinePhoenixWeb.Router)
  paths = Enum.map(routes, & &1.path)

  assert "/dev/storybook" in paths
  assert Enum.any?(paths, &String.starts_with?(&1, "/dev/storybook/assets"))
end
```

### Root Source Boundary Contract

```elixir
# Source: existing root source-contract style in stress_router_test.exs
test "root package does not depend on Storybook" do
  root_sources =
    ["mix.exs", "lib/threadline/operator_surface/router.ex"]
    |> Enum.map(&File.read!/1)
    |> Enum.join("\n")

  refute root_sources =~ "phoenix_storybook"
  refute root_sources =~ "PhoenixStorybook"
  refute root_sources =~ "live_storybook"
end
```

## Existing Code Patterns To Reuse

| Existing Pattern | Evidence | Reuse In Phase 182 |
|------------------|----------|--------------------|
| `dev_routes` compile boundary | Example router wraps `/dev/help_desk/ticket_reply` and `/dev/mailbox` in `if Application.compile_env(:threadline_phoenix, :dev_routes)`. `[VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]` | Put Storybook route/assets in the same boundary. `[VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]` |
| Stress route fail-closed macro | `StressRouter.threadline_operator_surface_stress/2` omits or raises for production stress env. `[VERIFIED: lib/threadline/operator_surface/stress_router.ex]` | Use route/source contracts with the same fail-closed mindset, but keep Storybook implementation example-app-local. `[VERIFIED: test/threadline/operator_surface/stress_router_test.exs]` |
| Stable test IDs and source contracts | Stress tests assert `data-testid` values and source terms. `[VERIFIED: test/threadline/operator_surface/stress_router_test.exs]` | Add Storybook smoke IDs only where needed and assert Storybook absence from root source. `[VERIFIED: test/threadline/operator_surface/stress_router_test.exs]` |
| Design-system ledger projection | Ledger and `DESIGN-SYSTEM.md` are coupled by tests. `[VERIFIED: test/threadline/operator_surface/stress_ledger_test.exs]` | Use ledger categories as reference, but do not make ledger a Storybook source of truth. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |
| Example browser runner | `run-e2e.sh` chooses a port, compiles example app, seeds data, starts server, and runs Playwright. `[VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh]` | Add a bounded `operator-storybook.spec.ts` and run it through the existing harness. `[VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh]` |
| Example README contracts | Root tests assert exact example README content and router snippets. `[VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]` | Add doc-contract assertions for Storybook-vs-stress and no adopter install guidance. `[VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]` |

## Story Coverage Model

| Category | Existing Source | Minimum Storybook Coverage |
|----------|-----------------|----------------------------|
| Foundations | `Style.css/1`, `DESIGN-SYSTEM.md` | One page/story for tokens, theme lanes, typography/density/radius/focus rules. `[VERIFIED: lib/threadline/operator_surface/style.ex]` `[VERIFIED: DESIGN-SYSTEM.md]` |
| Primitives | `button`, `icon_button`, `link`, `badge`, `alert`, `divider`, `spinner`, `avatar`, `card`, `stack`, `cluster`, `page_header`, `pager`, `stat_tile`. `[VERIFIED: rg '^  def ' lib/threadline/operator_surface/ui.ex]` | Representative variations for normal/disabled/focus/error/long-label states where relevant. `[VERIFIED: lib/threadline/operator_surface/ui.ex]` |
| Forms | `label`, `error`, `help`, `input`, `field`, `error_summary`, `field_group`, `radio`, `switch`, `combobox`. `[VERIFIED: lib/threadline/operator_surface/ui.ex]` | Inputs, select, textarea, checkbox/radio/switch, error summary, disabled, long text, non-ASCII, and invalid states. `[VERIFIED: lib/threadline/operator_surface/ui.ex]` |
| States | `empty_state`, `error_state`, `loading_state`, `stale_banner`, `data_state`. `[VERIFIED: lib/threadline/operator_surface/ui.ex]` | Empty, no-data, permission, source-down, redacted, pruned, stale, loading, error, pagination/timezone boundary. `[VERIFIED: lib/threadline/operator_surface/stress_fixtures.ex]` |
| Overlays | `modal`, `drawer`, `toast`, `tooltip`, `popover`, `dropdown`, `accordion`, `tabs`, `segmented_control`. `[VERIFIED: lib/threadline/operator_surface/ui.ex]` | Templated stories with open buttons or `psb-assign` where needed, plus notes about keyboard/focus expectations. `[CITED: https://phoenix-storybook.hexdocs.pm/components.html]` |
| Data Display | `ref`, `kv`, `data_table`, `data_panel`, `code_block`, `detail_header`, `toolbar`. `[VERIFIED: lib/threadline/operator_surface/ui.ex]` | Long refs, null fields, mixed severity rows, responsive table labels, copy affordance, loading/empty/pager group. `[VERIFIED: lib/threadline/operator_surface/stress_fixtures.ex]` |
| Groups/Patterns | Existing group stories in `StressFixtures`. `[VERIFIED: lib/threadline/operator_surface/stress_fixtures.ex]` | Toolbar+filters, detail header+metadata, data panel states, destructive modal, offline/reconnect, permission denied. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |

## Documentation Contracts

| Doc Surface | Required Contract |
|-------------|-------------------|
| `examples/threadline_phoenix/README.md` | Say Storybook is local maintainer component documentation/design review under `examples/threadline_phoenix`; do not teach adopters to install PhoenixStorybook in their apps. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |
| `guides/operator-surface.md` or touched operator docs | Say `/audit/__stress` remains authenticated operator-flow stress testing and is not replaced by Storybook. `[VERIFIED: .planning/REQUIREMENTS.md]` |
| Root README or upgrade docs if touched | Preserve root optional dependency posture and `mix verify.compile_no_optional` proof. `[VERIFIED: guides/upgrade-path.md]` `[VERIFIED: README.md]` |
| Doc-contract tests | Add assertions for "Storybook is not installed by adopters", "Storybook is not a production route", and "`/audit/__stress` is the authenticated operator-flow stress harness". `[VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]` |

## Risk Register

| Risk | Severity | Mitigation |
|------|----------|------------|
| Storybook route exposed in production | High | Compile-time `dev_routes` branch, production route absence test, and no prod dependency. `[VERIFIED: examples/threadline_phoenix/config/prod.exs]` |
| Root package gains Storybook dependency | High | Source tests over root `mix.exs`, root `lib/`, and public router macro; run `mix verify.compile_no_optional`. `[VERIFIED: mix.exs]` |
| Old vulnerable PhoenixStorybook version resolves | High | Pin `~> 1.2.0`; assert lock version is `>= 1.2.0`; Hex advisories affect `< 1.1.0`. `[CITED: https://hex.pm/packages/phoenix_storybook/advisories]` |
| Storybook duplicates `/audit/__stress` scope | Medium | Keep page-flow matrix, auth behavior, and stress footguns in stress route/Playwright; Storybook stays component documentation. `[VERIFIED: .planning/REQUIREMENTS.md]` |
| Theme wrapper fails to apply real CSS | Medium | Browser smoke asserts `.threadline-ui`, `data-tl-theme`, visible styles/assets, and representative stories. `[VERIFIED: lib/threadline/operator_surface/style.ex]` |
| Story count becomes unbounded | Medium | Use category minimums and representative ugly-data allowlist; no full combinatorial matrix. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |
| Docs imply adopter/public component API | Medium | Doc-contract tests forbid adopter install instructions and preserve private component language. `[VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]` |
| Example app has no asset pipeline | Medium | Prefer inline `Style.css/1` wrapper and only add Storybook CSS/JS assets if needed for Storybook mechanics or hooks. `[VERIFIED: examples/threadline_phoenix/README.md]` `[CITED: https://phoenix-storybook.hexdocs.pm/sandboxing.html]` |

## State Of The Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic Storybook-like Phoenix setup with older versions | PhoenixStorybook `1.2.0` for Phoenix `~> 1.8.1` and LiveView `~> 1.1.0` | `1.2.0` released 2026-06-11. `[VERIFIED: mix hex.info phoenix_storybook 1.2.0]` | Use the current package and do not copy older tutorials using `0.5.x`. `[CITED: https://hex.pm/packages/phoenix_storybook]` |
| Storybook as possible public docs surface | Example-local maintainer component documentation | v1.38 decision on 2026-06-26. `[VERIFIED: .planning/PROJECT.md]` | Keeps private component API and root optional dependency boundary intact. `[VERIFIED: .planning/REQUIREMENTS.md]` |
| Full visual-regression SaaS for stories | Bounded Playwright smoke in existing harness | Phase 182 locked decision. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` | Avoids screenshot matrix cost while still proving representative rendering. `[VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh]` |
| Dark-only operator UI | Dark default plus light/system lanes via `data-tl-theme` | v1.36 shipped before v1.38. `[VERIFIED: .planning/PROJECT.md]` | Storybook must render all three Threadline theme lanes through the real wrapper. `[VERIFIED: lib/threadline/operator_surface/style.ex]` |

**Deprecated/outdated:**

- PhoenixStorybook versions `< 1.1.0`: Hex lists recent advisories affecting those ranges, including high/critical issues. `[CITED: https://hex.pm/packages/phoenix_storybook/advisories]`
- Tutorials that mount at `/storybook` without the locked `/dev/storybook` boundary: this phase requires `/dev/storybook`. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`
- Any plan that asks adopters to install PhoenixStorybook in their host app: out of scope and contrary to STORY-01/STORY-03. `[VERIFIED: .planning/REQUIREMENTS.md]`

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A guarded backend module under `lib/` is sufficient to avoid production compile failure when `phoenix_storybook` is dev/test-only. `[ASSUMED]` | Architecture Patterns | If wrong, planner must use environment-specific `elixirc_paths/1` or another compile boundary. |
| A2 | The Storybook wrapper can inject `Threadline.OperatorSurface.Style.css/1` cleanly without a separate CSS asset bundle. `[ASSUMED]` | Architecture Patterns | If wrong, planner must add a minimal example-app Storybook CSS asset while still avoiding root/package leakage. |
| A3 | No normal operator login is acceptable for local Storybook because it remains dev/test-only and not exposed in production. `[ASSUMED]` | Security Domain | If deployment or demo exposure changes, planner must add a maintainer auth guard. |

## Open Questions

1. **Should Storybook be linked from the example home page?**
   - What we know: The route is `/dev/storybook` and must not become a production/demo route. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]`
   - What's unclear: Whether a dev-only visible link is helpful or too close to demo exposure. `[ASSUMED]`
   - Recommendation: Do not add a normal home/operator nav link in Phase 182; document the URL in maintainer docs instead. `[ASSUMED]`

2. **Do any overlay stories need Storybook JS hooks?**
   - What we know: PhoenixStorybook supports templates and JS commands, and the example app has no conventional assets directory. `[CITED: https://phoenix-storybook.hexdocs.pm/components.html]` `[VERIFIED: find examples/threadline_phoenix/assets]`
   - What's unclear: Whether Threadline overlay stories can be shown with static open-state assigns/templates only. `[ASSUMED]`
   - Recommendation: Start with static/templated examples; add `js_path` only if a representative overlay story needs it. `[ASSUMED]`

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix compile/test | yes | 1.19.5 with Erlang/OTP 28 | None needed. `[VERIFIED: elixir --version]` |
| Mix | Dependency resolution and tests | yes | 1.19.5 | None needed. `[VERIFIED: mix --version]` |
| Hex registry access | `phoenix_storybook` version check and deps | yes | `mix hex.info` worked; `mix hex.search` printed a token refresh warning but returned results | Use Hex web package page if local auth token is stale. `[VERIFIED: mix hex.info phoenix_storybook]` |
| PostgreSQL | Example app tests and E2E seed | yes | `psql` 14.17; `pg_isready` accepting on `/tmp:5432` | Use documented Docker Postgres on `DB_PORT=5433` if local service differs. `[VERIFIED: pg_isready]` `[VERIFIED: examples/threadline_phoenix/README.md]` |
| Node.js | Playwright E2E | yes | v22.14.0 | None needed. `[VERIFIED: node --version]` |
| npm | Playwright E2E | yes | 11.1.0 | None needed. `[VERIFIED: npm --version]` |
| `@playwright/test` | Browser smoke | yes | installed 1.60.0 | `run-e2e.sh` runs `npm ci`/`npm install` if needed. `[VERIFIED: npm --prefix examples/threadline_phoenix/e2e ls @playwright/test]` `[VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh]` |
| Chromium browser | Browser smoke | partial | Playwright cached headless Chromium exists; system `/opt/homebrew/bin/chromium` is broken | Use Playwright-managed browser cache via `npx playwright install chromium`. `[VERIFIED: ls ~/Library/Caches/ms-playwright/chromium*]` `[VERIFIED: chromium --version]` |

**Missing dependencies with no fallback:** none identified. `[VERIFIED: environment probes 2026-06-26]`

**Missing dependencies with fallback:** system Chromium launcher is broken, but Playwright-managed Chromium is cached and the E2E runner installs Chromium. `[VERIFIED: chromium --version]` `[VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh]`

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit/Mix for source, route, docs, and component contracts; Playwright for browser smoke. `[VERIFIED: mix.exs]` `[VERIFIED: examples/threadline_phoenix/e2e/package.json]` |
| Config file | ExUnit uses Mix project config; Playwright uses `examples/threadline_phoenix/e2e/playwright.config.ts`. `[VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts]` |
| Quick run command | `mix verify.compile_no_optional && cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_route_test.exs` `[VERIFIED: mix.exs]` |
| Full suite command | `mix ci.all` plus targeted Storybook browser smoke through `cd examples/threadline_phoenix/e2e && npm test -- operator-storybook.spec.ts` after the server harness is available. `[VERIFIED: mix.exs]` `[VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh]` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| STORY-01 | Storybook route/assets exist in dev/test and are absent from production/root. | ExUnit route/source contract | `mix test test/threadline/operator_surface/storybook_boundary_test.exs && cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_route_test.exs` | No - Wave 0 gap. `[VERIFIED: find test examples/threadline_phoenix/test]` |
| STORY-02 | Representative component stories render across categories and theme wrapper. | ExUnit render smoke + Playwright smoke | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_stories_test.exs` and bounded E2E spec | No - Wave 0 gap. `[VERIFIED: find examples/threadline_phoenix/test]` |
| STORY-03 | Docs preserve Storybook-vs-stress distinction and stress route remains canonical/authenticated. | Doc contract + existing stress route tests | `mix test test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface/stress_router_test.exs` | Existing files yes; new assertions needed. `[VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]` |

### Sampling Rate

- **Per task commit:** `mix verify.compile_no_optional` plus the relevant new route/source/story test. `[VERIFIED: mix.exs]`
- **Per wave merge:** `mix verify.example` and targeted `operator-storybook.spec.ts` through the example E2E harness. `[VERIFIED: mix.exs]` `[VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh]`
- **Phase gate:** `mix ci.all` plus Storybook browser smoke and `cd examples/threadline_phoenix && mix precommit` if example app files changed. `[VERIFIED: mix.exs]` `[VERIFIED: examples/threadline_phoenix/AGENTS.md]`

### Wave 0 Gaps

- [ ] `test/threadline/operator_surface/storybook_boundary_test.exs` - root absence and source/dependency contract for STORY-01. `[VERIFIED: test/threadline/operator_surface/stress_router_test.exs]`
- [ ] `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_route_test.exs` - dev/test route and production absence for STORY-01. `[VERIFIED: examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs]`
- [ ] `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs` - story/backend smoke for STORY-02. `[VERIFIED: find examples/threadline_phoenix/test]`
- [ ] `examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts` - bounded browser smoke for STORY-02/STORY-03. `[VERIFIED: examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts]`
- [ ] Additional assertions in `test/threadline/example_phoenix_readme_contract_test.exs` and possibly `test/threadline/operator_surface_doc_contract_test.exs` for STORY-03. `[VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]`

## Security Domain

### Applicable ASVS Categories

OWASP ASVS latest stable is 5.0.0 according to the OWASP project page, and ASVS is a basis for testing web application technical controls. `[CITED: https://owasp.org/www-project-application-security-verification-standard/]`

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | Conditional | No normal operator login for local dev/test Storybook unless exposed beyond local/dev; if exposure changes, add a dev/test maintainer auth guard. `[VERIFIED: .planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md]` |
| V3 Session Management | Yes | Let PhoenixStorybook manage its LiveView session and link with `href`, not `patch`/`navigate`, because the router docs require its own first-render session. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]` |
| V4 Access Control | Yes | Compile-time route absence in production plus no public operator mount inclusion; this is the primary access-control boundary for Phase 182. `[VERIFIED: examples/threadline_phoenix/config/prod.exs]` |
| V5 Validation, Sanitization, and Encoding | Yes | Do not pipe user-controlled params into atoms or generated story module names; existing stress tests already ban `String.to_atom` in stress sources. `[VERIFIED: test/threadline/operator_surface/stress_router_test.exs]` |
| V6 Stored Cryptography | No direct new cryptography | No new crypto is required; preserve existing Phoenix session/CSRF mechanisms and do not add custom crypto. `[VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]` |
| V14 Configuration | Yes | Keep `dev_routes` false/absent in production and verify production route absence. `[VERIFIED: examples/threadline_phoenix/config/prod.exs]` |

### Known Threat Patterns For This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Production exposure of dev component lab | Information Disclosure / Elevation of Privilege | Compile-time `dev_routes` branch, route absence test, no production dependency. `[VERIFIED: examples/threadline_phoenix/config/prod.exs]` |
| Vulnerable old Storybook version | Elevation of Privilege / Denial of Service | Pin `~> 1.2.0` and assert lock is outside Hex advisory affected ranges `< 1.1.0`. `[CITED: https://hex.pm/packages/phoenix_storybook/advisories]` |
| Cross-session route/session behavior | Tampering | Use PhoenixStorybook's documented `href` linking and LiveView session setup. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]` |
| Atom exhaustion or dynamic atom creation | Denial of Service | Keep existing no-`String.to_atom` pattern for route/story params and helpers. `[VERIFIED: test/threadline/operator_surface/stress_router_test.exs]` |
| CSS/JS context bleed between Storybook and components | Tampering / Information Disclosure | Use `.threadline-ui` wrapper and PhoenixStorybook sandbox class/asset model; iframe only for cases that require isolation. `[CITED: https://phoenix-storybook.hexdocs.pm/sandboxing.html]` |

## Sources

### Primary (HIGH confidence)

- Codebase grep/read: `mix.exs`, `examples/threadline_phoenix/mix.exs`, example router/configs, `StressRouter`, `StressFixtures`, `UI`, `Style`, stress tests, E2E harness. `[VERIFIED: codebase grep]`
- Current-tree commands: `mix compile --no-optional-deps --warnings-as-errors`, `cd examples/threadline_phoenix && MIX_ENV=test mix compile --warnings-as-errors`, route listing, environment probes. `[VERIFIED: command run 2026-06-26]`
- Phase context and requirements: `.planning/phases/182-phoenixstorybook-example-dev-lane/182-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/ROADMAP.md`. `[VERIFIED: codebase read]`

### Secondary (MEDIUM confidence)

- PhoenixStorybook setup docs: https://phoenix-storybook.hexdocs.pm/setup.html `[CITED: phoenix-storybook.hexdocs.pm]`
- PhoenixStorybook router docs: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html `[CITED: phoenix-storybook.hexdocs.pm]`
- PhoenixStorybook component docs: https://phoenix-storybook.hexdocs.pm/components.html `[CITED: phoenix-storybook.hexdocs.pm]`
- PhoenixStorybook color modes: https://phoenix-storybook.hexdocs.pm/color_modes.html `[CITED: phoenix-storybook.hexdocs.pm]`
- PhoenixStorybook sandboxing: https://phoenix-storybook.hexdocs.pm/sandboxing.html `[CITED: phoenix-storybook.hexdocs.pm]`
- PhoenixStorybook testing docs: https://phoenix-storybook.hexdocs.pm/testing.html `[CITED: phoenix-storybook.hexdocs.pm]`
- Hex package/advisories/dependencies: https://hex.pm/packages/phoenix_storybook, https://hex.pm/packages/phoenix_storybook/advisories, https://hex.pm/packages/phoenix_storybook/dependencies `[CITED: hex.pm]`
- Phoenix.Component docs: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html `[CITED: phoenix-live-view.hexdocs.pm]`
- OWASP ASVS project page: https://owasp.org/www-project-application-security-verification-standard/ `[CITED: owasp.org]`

### Tertiary (LOW confidence)

- No training-only package recommendations were used. `[VERIFIED: research log]`
- Assumptions A1-A3 need implementation confirmation. `[ASSUMED]`

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH for package/version/dependency facts from Hex and codebase; MEDIUM for exact final Mix dependency options because implementation must confirm runtime behavior. `[VERIFIED: mix hex.info phoenix_storybook 1.2.0]` `[ASSUMED]`
- Architecture: HIGH for route boundary and codebase constraints; MEDIUM for wrapper asset strategy until implemented. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]` `[ASSUMED]`
- Pitfalls: HIGH for wrong-scope mount, root leakage, and advisory floor; MEDIUM for asset/wrapper caveats. `[CITED: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Router.html]` `[CITED: https://hex.pm/packages/phoenix_storybook/advisories]`

**Research date:** 2026-06-26  
**Valid until:** 2026-07-03 for PhoenixStorybook/advisory/package details; 2026-07-26 for codebase-local constraints if no intervening phase changes the example app.
