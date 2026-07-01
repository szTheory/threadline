# Phase 182: PhoenixStorybook example/dev lane - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-26
**Phase:** 182-PhoenixStorybook example/dev lane
**Areas discussed:** Storybook mounting boundary, story source of truth, component catalog shape, theme and ugly-data review model, verification and docs bar, cross-cutting product and architecture coherence

---

## User Direction

The user selected all gray areas and asked for one coherent, research-backed recommendation set using subagents. The user explicitly asked not to force piecemeal choices, and requested pros/cons/tradeoffs, Elixir/Phoenix/Plug/Ecto idioms, lessons from successful libraries/apps and other ecosystems, developer ergonomics, product vision, JTBD, UI/UX/design-system lenses where applicable, prompt corpus consideration, and current brandbook precedence over older prompt-era brand details.

Research was gathered by six `gsd-advisor-researcher` subagents plus main-thread source and web research.

---

## Storybook Mounting Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Dev/test `/dev/storybook` | Clean separation from `/audit`, fits component-isolation model, keeps root package untouched, and aligns with dev/test maintainer tooling. Requires explicit prod absence and route/source tests. | yes |
| Dev/test `/audit/__storybook` | Reuses audit-adjacent namespace and could share operator auth, but blurs Storybook with the canonical operator surface and `/audit/__stress`. | |
| Production-capable or hosted Storybook | Enables remote review, but violates the no-production-story-route constraint and risks exposing private components and internal states. | |

**User's choice:** User delegated to research-backed Claude discretion for all areas.
**Notes:** Recommendation is `/dev/storybook` in `examples/threadline_phoenix` only, mounted from a root scope with full path and guarded to dev/test. Keep it outside `/audit`.

---

## Story Source Of Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Hand-authored stories | Most idiomatic PhoenixStorybook story shape and best narrative DX, but high drift risk against `StressFixtures` and ledger. | |
| Generated stories from `StressFixtures` and ledger | Strong parity with the stress route, but produces stress-matrix docs rather than component docs and couples Storybook to planning ledger internals. | |
| Curated stories plus shared fixture helpers | Keeps Storybook useful and idiomatic while sampling canonical ugly data and preserving `/audit/__stress` as flow harness. | yes |

**User's choice:** User delegated to research-backed Claude discretion.
**Notes:** Recommendation is curated `.story.exs` files with a small explicit allowlist/helper layer over `StressFixtures.assigns_for/1`. Do not generate a full Storybook mirror.

---

## Component Catalog Shape

| Option | Description | Selected |
|--------|-------------|----------|
| By component type | Mirrors `DESIGN-SYSTEM.md`, `StressFixtures`, and `UI` component families; best for maintainer lookup. | partial |
| By operator JTBD/domain | Task-led and useful for recurring assemblies, but can blur into `/audit/__stress` and weaken component discoverability. | partial |
| By maturity/status | Useful metadata, but poor top-level navigation and too noisy as the primary structure. | |
| By stress fixture categories | Good ugly-data coverage, but risks duplicating `/audit/__stress`. | |
| Hybrid | Component categories as primary spine, small patterns branch for recurring operator assemblies, metadata inside stories/indexes. | yes |

**User's choice:** User delegated to research-backed Claude discretion.
**Notes:** Recommendation is a hybrid catalog: `Foundations`, `Primitives`, `Forms`, `States`, `Overlays`, `Data Display`, `Groups`, plus a small `Patterns` branch. Status/theme/a11y/fixture provenance belongs inside stories or index pages.

---

## Theme And Ugly-Data Review Model

| Option | Description | Selected |
|--------|-------------|----------|
| Duplicate stories per theme/state | Explicit URLs but too much story sprawl and high drift risk. | |
| PhoenixStorybook variations/controls | Idiomatic and useful for interesting component states, but controls are exploratory and PhoenixStorybook color mode is not Threadline's `data-tl-theme` contract. | partial |
| Shared Threadline wrapper | Preserves real `.threadline-ui`, `Style.css`, and `data-tl-theme`; best fit for dark/light/system truth. | yes |
| Generated scenario matrices | Strong fixture parity but unreadable if exhaustive and too close to `/audit/__stress`. | partial |
| Minimal examples plus `/audit/__stress` deep matrix | Clean responsibility split but needs explicit representative coverage to avoid under-documentation. | partial |

**User's choice:** User delegated to research-backed Claude discretion.
**Notes:** Recommendation is a hybrid: PhoenixStorybook variations inside a shared Threadline wrapper, with helper-backed representative ugly data. Keep the deep authenticated matrix in `/audit/__stress`.

---

## Verification And Docs Bar

| Option | Description | Selected |
|--------|-------------|----------|
| Root compile/no-optional and dependency assertions | Protects the Hex/root package boundary but must be paired with source/dependency checks. | yes |
| Example compile/test/dev smoke | Proves the dev lane works where allowed. | yes |
| Prod route exclusion tests | Hard proof of no production/demo story route. | yes |
| Docs contract | Prevents docs from teaching root/prod Storybook or confusing Storybook with stress. | yes |
| Browser story smoke | Proves the Storybook UI and representative stories actually render without expanding to a screenshot matrix. | yes |

**User's choice:** User delegated to research-backed Claude discretion.
**Notes:** Recommendation is layered verification: root boundary, example compile/test, dev/test route presence, production absence, bounded browser smoke, and docs contract.

---

## Cross-Cutting Product And Architecture Coherence

| Option | Description | Selected |
|--------|-------------|----------|
| Treat Storybook as maintainer DX only | Supports private components and design review without widening adopter-facing scope. | yes |
| Treat Storybook as operator/product surface | Would confuse users and violate no-production-route and no-public-component-API boundaries. | |
| Treat Storybook as public component docs | Future possibility only after an explicit public component API milestone. | |

**User's choice:** User delegated to research-backed Claude discretion.
**Notes:** Storybook should serve maintainers who evolve private components for operator JTBD. It should not expose backend internals, imply adopter install steps, or absorb later page-polish work.

---

## Claude's Discretion

- Exact file/module names for Storybook backend, story helpers, and tests are left to the planner.
- Exact story allowlist can be chosen by the planner, but it must cover the categories and representative ugly-data/theme states locked in CONTEXT.md.
- Exact browser smoke command can reuse the existing example E2E harness or a smaller example-app test path, as long as it proves rendered Storybook usability without expanding the screenshot matrix.

## Deferred Ideas

- Production or hosted Storybook.
- Public component API or public component documentation site.
- Replacing `/audit/__stress` with Storybook.
- Full visual-regression SaaS matrix such as Percy, Chromatic, or Applitools.
- Shell/Home/Timeline/Coverage/detail/governance/export page polish.
