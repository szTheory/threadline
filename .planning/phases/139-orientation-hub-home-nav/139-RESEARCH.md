# Phase 139: Orientation Hub (Home / Nav) - Research

**Researched:** 2026-06-04 [VERIFIED: gsd-sdk init.phase-op]  
**Domain:** Phoenix LiveView operator-surface Home and shared navigation polish [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]  
**Confidence:** HIGH [VERIFIED: codebase rg + required file reads]

## User Constraints (from CONTEXT.md)

### Locked Decisions

`--auto` selected the recommended defaults from `.planning/milestones/v1.31-PERSONAS-IA.md` and the Phase 139 roadmap scope:

- **D-01:** Keep the `Find / Verify / Prove` IA as the navigation backbone. The grouping maps to P1/P2 investigation, P4 trust/health, and P3 proof/handoff. Do not rename the nav grouping wholesale.
- **D-02:** Keep `Verify` in the nav for consistency. A Home card may use `Trust` language if planning finds it improves first-scan comprehension, but nav labels should stay stable unless a test-backed reason emerges.
- **D-03:** Add a subtle Prove-cluster separation before `Exports`, so Exports reads as the handoff/deliverable destination rather than a sibling proof control. This is EF5/F-105/F-304 scope and belongs in Phase 139.
- **D-04:** Preserve the brand link to Home, skip link, scope chip, coverage badge, feature-flag-aware destinations, and existing auth/coverage/on-mount contracts.
- **D-05:** Mobile nav must preserve every available destination at 375px. It may use an overflow/hamburger/disclosure or a deliberately scrollable grouped nav, but it must not silently drop Retention, Exports, labels, scope, or health affordances.
- **D-06:** Home remains a GDS-style orientation hub, not a dashboard. Keep the headline orientation, quiet health row, job-framed cards, and saved-view resume area; make each persona's next action obvious without turning Home into a new workflow screen.
- **D-07:** Home may show a non-functional orientation/prompt for the Phase 140 record-first path only if it is clearly framed as navigation guidance or future-owned disabled copy. Prefer planning Phase 139 around existing destinations and copy; implement actual record lookup in Phase 140.
- **D-08:** The Home health row stays quiet when healthy and scan-friendly for P4. P1/P2/P3 should be able to ignore it; P4 should be able to use it as the health-sweep on-ramp.
- **D-09:** Saved views are part of Home orientation. Phase 135 seeded them for F-204; Phase 139 should render them as a real "Pick up where you left off" affordance when present and preserve honest empty copy when absent.
- **D-10:** Keep all CSS in `Threadline.OperatorSurface.Style` using scoped `.threadline-ui` / `.tl-*` primitives and existing dark-first tokens. Add narrow nav/Home primitives only when existing classes cannot express the IA contract.

### the agent's Discretion

No separate `## the agent's Discretion` section exists in `139-CONTEXT.md`; implementation split and exact copy are left to planning inside the locked decisions above. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)

- EF1 record-first cordoned path from Home.
- EF2 first-class row-history entry from Home/Timeline.
- EF3 closed export loop carrying active Timeline/Evidence context into Exports.
- EF4 correlation-id paste/deep-link from Home.
- Any new route, query API, backend flow, or product behavior needed to support those flows.

## Summary

Phase 139 should be planned as two tightly scoped UI slices: first `SurfaceHeader` navigation semantics/reachability, then `StartLive` Home orientation. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md] The current header already uses a Phoenix function component, feature-flag-aware destinations, a Home brand link, a skip link, `aria-current="page"` for active nav items, scoped chips, and coverage status. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] The planner should preserve that architecture and add only the IA-specific refinements: consistent active mapping, Prove/Exports separation, and a tested mobile nav pattern that keeps every enabled destination reachable at 375px. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex; CITED: .planning/milestones/v1.31-PERSONAS-IA.md]

Home is already a task launcher with headline, health row, Find/Verify/Prove cards, and saved-view rendering when `@saved_views` is non-empty. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex] The planner should close the audit findings by removing redundant Home eyebrow noise, distinguishing danger/warning health chips, preserving the quiet healthy state, rendering seeded saved views as a real resume affordance, and making each persona's next existing destination obvious without implementing Phase 140 flows. [CITED: .planning/milestones/v1.31-UI-AUDIT.md; VERIFIED: examples/threadline_phoenix/DEMO-MANIFEST.md]

**Primary recommendation:** Use existing Phoenix LiveView/function-component/CSS patterns; add focused ExUnit coverage for Home/header semantics and one Playwright mobile spec that proves all enabled nav destinations are reachable at 375px on representative screens. [VERIFIED: test/threadline/operator_surface/live/timeline_live_test.exs; VERIFIED: examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts]

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POLISH-HOME | Home and `surface_header` reflect locked persona/JTBD IA: active states, grouping, mobile nav pattern, and persona next actions. [CITED: .planning/REQUIREMENTS.md] | Header owns nav semantics; StartLive owns Home orientation; Playwright mobile specs already provide the no-overflow/reachability pattern to extend. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex; VERIFIED: lib/threadline/operator_surface/live/start_live.ex; VERIFIED: examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts] |

</phase_requirements>

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists at the repository root, so there are no additional project-specific agent directives to enforce. [VERIFIED: shell test -f AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Shared nav grouping, active state, feature-flag destination visibility | Frontend Server (Phoenix LiveView render/component) | Browser / Client CSS | `SurfaceHeader.surface_header/1` renders nav groups, feature flags, active classes, and `aria-current`; CSS controls mobile layout and reachability. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex; VERIFIED: lib/threadline/operator_surface/style.ex] |
| Home persona orientation and next actions | Frontend Server (StartLive render) | Database / Storage for saved views and health counts | `StartLive` renders cards/health/resume links, reads saved views/export/retention counts via existing queries, and degrades fail-safe. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex] |
| 375px nav reachability | Browser / Client CSS + Playwright validation | Frontend Server DOM semantics | Current `.tl-topbar__nav` is horizontal-scroll capable on mobile; Playwright can assert all enabled destinations are visible or reachable and no horizontal page overflow exists. [VERIFIED: lib/threadline/operator_surface/style.ex; VERIFIED: examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts] |
| Phase 140 earned flows | Out of scope | API / Backend later | Record lookup, correlation paste/deep-link, export loop, first-class row-history route, and backend expansion are deferred. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | 1.1.30 [VERIFIED: mix.lock] | Server-rendered LiveViews and HEEx function components for the operator surface. [VERIFIED: mix.lock; VERIFIED: lib/threadline/operator_surface/live/start_live.ex] | Existing `/audit` screens already use LiveView and `Phoenix.Component` with small components rather than a new frontend stack. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex; VERIFIED: lib/threadline/operator_surface/live/*.ex rg] |
| Phoenix | 1.8.7 [VERIFIED: mix.lock] | Router, LiveView mount, and optional Phoenix integration surface. [VERIFIED: mix.lock; VERIFIED: lib/threadline/operator_surface/router.ex] | The operator surface is mounted through Phoenix routes and LiveView sessions. [VERIFIED: lib/threadline/operator_surface/router.ex] |
| Ecto SQL | 3.13.5 [VERIFIED: mix.lock] | Existing read-only Home health/saved-view queries. [VERIFIED: mix.lock; VERIFIED: lib/threadline/operator_surface/live/start_live.ex] | `StartLive` already uses Ecto queries for `ExportJob`, `RetentionRun`, and `SavedView`; no backend API expansion is needed. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex] |
| Playwright `@playwright/test` | 1.60.0 [VERIFIED: npm registry; VERIFIED: package-lock] | Focused browser verification at 375px. [VERIFIED: examples/threadline_phoenix/e2e/package-lock.json] | Existing Find/Prove mobile UAT specs use Playwright viewport assertions and `expectNoHorizontalOverflow`. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts; VERIFIED: examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit / Phoenix LiveViewTest | bundled with Elixir/Phoenix test setup [VERIFIED: mix --version; VERIFIED: test/threadline/operator_surface/live/timeline_live_test.exs] | Fast semantic tests for rendered Home/header HTML, feature flags, active state, saved-view links, and health chip severity. [VERIFIED: test/threadline/operator_surface/live/timeline_live_test.exs] | Use for deterministic markup/state assertions before browser testing. [VERIFIED: test/threadline/operator_surface/live/timeline_live_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing horizontal-scroll/grouped mobile nav | Hamburger/disclosure nav | Allowed by D-05, but higher churn and more ARIA/state behavior; use only if scroll reachability cannot satisfy 375px tests. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md] |
| Existing HEEx/function component structure | New JS/component library, Tailwind, shadcn, icon deps | Explicitly out of scope for v1.31 and Phase 139. [CITED: .planning/REQUIREMENTS.md; CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md] |

**Installation:**

No new packages should be installed for Phase 139. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]

## Package Legitimacy Audit

No external packages are recommended or installed by this phase. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| None | — | — | — | — | Not run | No install surface. [VERIFIED: research scope] |

**Packages removed due to slopcheck [SLOP] verdict:** none. [VERIFIED: no packages recommended]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no packages recommended]

## Architecture Patterns

### System Architecture Diagram

```text
Operator request to /audit/*
  -> Phoenix router live_session :threadline
  -> Auth.OnMount + Coverage.OnMount assigns
  -> LiveView render
       -> SurfaceHeader(nav groups, active state, scope chip, coverage badge)
       -> Screen content
            -> StartLive(Home cards, health row, saved-view resume)
            -> Other LiveViews(existing screen body)
  -> Threadline.OperatorSurface.Style scoped CSS
       -> desktop grouped nav
       -> 375px reachable nav pattern
  -> Playwright mobile specs + ExUnit semantic tests
```

The router mounts `StartLive`, Timeline, Evidence, Coverage, Exports, Policy Redaction, Retention, Transaction, and Actor under one `live_session`. [VERIFIED: lib/threadline/operator_surface/router.ex]

### Recommended Project Structure

```text
lib/threadline/operator_surface/
├── components/surface_header.ex      # shared nav/header semantics [VERIFIED: codebase]
├── live/start_live.ex                # Home orientation hub [VERIFIED: codebase]
└── style.ex                          # scoped .threadline-ui / .tl-* CSS [VERIFIED: codebase]

test/threadline/operator_surface/
├── live/start_live_test.exs          # Wave 0 gap: Home semantics and saved views [VERIFIED: test inventory]
└── surface_header_test.exs           # Optional focused component tests if planner prefers isolated header checks [VERIFIED: no existing dedicated file]

examples/threadline_phoenix/e2e/tests/
└── operator-home-nav-mobile.spec.ts  # Wave 0 gap: 375px nav reachability + Home orientation [VERIFIED: existing e2e pattern]
```

### Pattern 1: Active State Is ARIA-Led

**What:** Keep `aria-current="page"` and `.tl-topbar__nav-item--active` generated from the `current` atom. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex]  
**When to use:** Every destination that represents the current screen or screen family. [VERIFIED: lib/threadline/operator_surface/live/*.ex rg]  
**Example:**

```elixir
# Source: lib/threadline/operator_surface/components/surface_header.ex [VERIFIED: codebase]
class={["tl-topbar__nav-item", @current == @page && "tl-topbar__nav-item--active"]}
aria-current={if @current == @page, do: "page", else: nil}
```

### Pattern 2: Feature Flags Decide Destination Visibility

**What:** Header and Home destinations are rendered only when their feature assigns are enabled. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex; VERIFIED: lib/threadline/operator_surface/live/start_live.ex]  
**When to use:** Coverage, Evidence, Policy Redaction/Retention, Exports, and Prove card composition. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex]  
**Example:**

```elixir
# Source: lib/threadline/operator_surface/components/surface_header.ex [VERIFIED: codebase]
<.nav_link :if={@exports_enabled} href={"#{@base_path}/exports"} current={@current} page={:exports}>
  Exports
</.nav_link>
```

### Pattern 3: Home Saved Views Reuse Canonical Timeline Query Encoding

**What:** `StartLive.saved_view_path/2` uses `FilterParams.canonical_query/1` to build byte-stable Timeline URLs from saved-view filters. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex; VERIFIED: lib/threadline/operator_surface/exports/filter_params.ex]  
**When to use:** Home resume links only; do not invent a second saved-view URL dialect. [VERIFIED: lib/threadline/operator_surface/exports/filter_params.ex]  

### Anti-Patterns to Avoid

- **Phase 140 leakage:** Do not add record lookup forms, correlation paste handlers, export-job creation, new routes, query APIs, schemas, or row-history entry routes. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]
- **Dropped mobile destinations:** Do not hide Retention, Exports, labels, scope, or health affordances at 375px without another reachable path. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]
- **Status color collapse:** Do not render failed exports and coverage gaps with the same warning-only severity in Home health; failed exports are danger and coverage gaps are warning. [CITED: .planning/milestones/v1.31-UI-AUDIT.md]
- **Navigation churn:** Do not rename the top-level nav groups away from `Find / Verify / Prove`; optional `Trust` language is Home-card-level only. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Navigation state | A page-local nav implementation per LiveView | `SurfaceHeader.surface_header/1` with `current` atoms | All current screens already call the shared header, and Phase 139 requires cross-screen consistency. [VERIFIED: lib/threadline/operator_surface/live/*.ex rg] |
| Saved-view URL encoding | String concatenation or alternate query-key order | `FilterParams.canonical_query/1` | Timeline and StartLive already share canonical query ordering for saved-view links. [VERIFIED: lib/threadline/operator_surface/exports/filter_params.ex] |
| Mobile validation | Manual screenshot-only review | Existing Playwright pattern with 375 viewport and no-overflow assertion | Find and Prove mobile specs already run deterministic DOM/layout assertions. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts; VERIFIED: examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts] |
| Styling system | Tailwind, shadcn, icon package, CSS-in-JS | Scoped `.threadline-ui` / `.tl-*` in `Style.css/1` | CSS architecture switch and new UI deps are out of scope. [CITED: .planning/REQUIREMENTS.md] |

**Key insight:** Phase 139 is an IA and reachability polish pass over existing surfaces, not a new workflow/product expansion pass. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Mobile Scroll Nav That Exists But Is Not Provably Reachable

**What goes wrong:** CSS allows horizontal nav scrolling, but tests only assert no page overflow and miss off-screen Retention/Exports. [VERIFIED: lib/threadline/operator_surface/style.ex; VERIFIED: examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts]  
**Why it happens:** Existing mobile tests focus screen content, not all header destinations. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts]  
**How to avoid:** Add a nav-specific Playwright test that starts at 375px and proves every enabled nav link can be reached and activated or at least scrolled into view from Home, Timeline, Coverage, Evidence, Retention, and Exports. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts]  
**Warning signs:** `operator-nav-retention` or `operator-nav-exports` is not visible/reachable at 375px. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex]

### Pitfall 2: Home Copy Implies Unbuilt Flows

**What goes wrong:** A "Look up one record" or "Paste correlation id" prompt becomes an actual form/event or route. [CITED: .planning/milestones/v1.31-PERSONAS-IA.md; CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]  
**Why it happens:** The IA doc recommends record-first and correlation on-ramps, but Phase 139 context defers implementations to Phase 140. [CITED: .planning/milestones/v1.31-PERSONAS-IA.md; CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]  
**How to avoid:** Use existing destination links and optional disabled/future-owned guidance only; tests should refute new route/API/schema/query changes. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]  
**Warning signs:** Changes in `router.ex`, `Threadline.Query`, migrations, schemas, or export creation code. [VERIFIED: lib/threadline/operator_surface/router.ex]

### Pitfall 3: Duplicate Health Signals Compete With Orientation

**What goes wrong:** Coverage appears as both topbar badge and equally strong first Home health chip, while failed exports use the same warning chip. [CITED: .planning/milestones/v1.31-UI-AUDIT.md]  
**Why it happens:** Current `health_warnings/1` returns labels only, and render maps every warning to `.tl-chip--warning`. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex]  
**How to avoid:** Model health items with severity (`:warning`, `:danger`) and render the healthy state quietly with `.tl-chip--success`. [VERIFIED: lib/threadline/operator_surface/style.ex; CITED: .planning/milestones/v1.31-UI-AUDIT.md]  
**Warning signs:** `2 failed exports` still renders with `.tl-chip--warning`. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex]

## Code Examples

### Header Component Invocation Pattern

```elixir
# Source: lib/threadline/operator_surface/live/timeline_live.ex [VERIFIED: codebase]
<Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
  coverage={@threadline_coverage}
  base_path={@base_path}
  coverage_enabled={@threadline_coverage_enabled}
  policy_enabled={@threadline_policy_enabled}
  evidence_enabled={@threadline_evidence_enabled}
  exports_enabled={@threadline_exports_enabled}
  current={:timeline}
  scoped={not is_nil(assigns[:threadline_scope])}
/>
```

### Mobile Browser Assertion Pattern

```ts
// Source: examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts [VERIFIED: codebase]
test.use({ viewport: { width: 375, height: 812 }, isMobile: true });

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Per-page header/badge links from earlier operator-surface phases | Shared `SurfaceHeader` with nav groups, active state, feature-flag visibility, scope chip, and coverage badge | Current codebase as of 2026-06-04 [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] | Planner should refine one shared component, not patch each screen separately. [VERIFIED: lib/threadline/operator_surface/live/*.ex rg] |
| Home resume row empty because seed lacked saved views | Phase 135 seed provides two admin saved views, while `StartLive` already renders saved views when present | Seed manifest and seed code as of 2026-06-04 [VERIFIED: examples/threadline_phoenix/DEMO-MANIFEST.md; VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/exports.ex] | Phase 139 should add tests and polish render/copy rather than invent saved-view storage. [VERIFIED: lib/threadline/governance/saved_view.ex] |
| Mobile nav finding deferred broadly to responsive phase | Phase 139 has a local 375px nav reachability obligation before Phase 142's full responsive sweep | Locked Phase 139 context [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md] | Keep validation focused on header reachability and Home orientation, not every table/drawer/filter layout. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md] |

**Deprecated/outdated:**

- Treating Home as a dashboard is out of date for this milestone; Home is locked as a GDS-style orientation hub. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]
- Treating Exports as an undifferentiated Prove sibling is out of date; Phase 139 owns a subtle separator before Exports. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | No `[ASSUMED]` claims are required; recommendations are constrained to locked planning docs, local code, local tests, registry version checks, and local environment probes. [VERIFIED: research process] | — | — |

## Open Questions (RESOLVED)

1. **Should mobile nav remain scrollable or become a disclosure?**
   - What we know: D-05 allows either a deliberately scrollable grouped nav or overflow/hamburger/disclosure. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]
   - Resolution: Use the existing CSS-only scrollable grouped nav pattern first. Keep `Find`, `Verify`, and `Prove` labels in the mobile nav DOM and make every enabled destination reachable at 375px through the nav scroll container. Do not add hamburger/disclosure JavaScript unless execution proves the scrollable grouped pattern cannot pass the Phase 139 Playwright reachability UAT. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md; VERIFIED: lib/threadline/operator_surface/style.ex]
   - Planning impact: Plan 01 owns the CSS/mobile nav primitive and Plan 03 owns browser proof; disclosure/hamburger behavior is not planned unless the executor records failed scroll reachability evidence. [CITED: .planning/phases/139-orientation-hub-home-nav/139-01-PLAN.md; CITED: .planning/phases/139-orientation-hub-home-nav/139-03-PLAN.md]

2. **Should Home card copy use `Trust` while nav stays `Verify`?**
   - What we know: D-02 permits card-level `Trust` language while keeping nav `Verify`. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md]
   - Resolution: Keep `Find`, `Verify`, and `Prove` as the Home card families to match the navigation backbone. Card copy should orient P1/P2/P3/P4/P5 personas to existing destinations only, with wording that describes investigation, capture health, proof controls, and handoff readiness without implying Phase 140 record-first lookup, correlation paste/deep-link, export loop, or row-history entry flows. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md; CITED: .planning/milestones/v1.31-UI-AUDIT.md]
   - Planning impact: Plan 02 tests and implements only existing-destination card links; any Phase 140-oriented copy must remain navigation guidance and must not introduce forms, events, routes, query APIs, schemas, or backend behavior. [CITED: .planning/phases/139-orientation-hub-home-nav/139-02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | ExUnit and Phoenix code tests | ✓ | Elixir 1.19.5, Mix 1.19.5 [VERIFIED: elixir --version; mix --version] | — |
| Node.js / npm | Playwright mobile specs | ✓ | Node v22.14.0, npm 11.1.0 [VERIFIED: node --version; npm --version] | ExUnit-only semantic coverage, but browser reachability would remain unproven. [VERIFIED: local environment] |
| PostgreSQL | Example app/demo seed and LiveView tests | ✓ | psql 14.17; localhost:5432 accepting connections [VERIFIED: psql --version; pg_isready] | None for full example UAT. [VERIFIED: local environment] |
| Docker | Optional example environment support | ✓ | Docker 29.5.2 [VERIFIED: docker --version] | Local Postgres is already available. [VERIFIED: pg_isready] |
| Context7 CLI fallback | External framework docs lookup | ✗ | `ctx7 not found` [VERIFIED: command -v ctx7] | Use codebase-verified patterns; no new framework API claims are needed. [VERIFIED: research scope] |

**Missing dependencies with no fallback:**
- None blocking Phase 139 planning. [VERIFIED: local environment probes]

**Missing dependencies with fallback:**
- Context7 CLI is unavailable; research avoids unsupported framework claims and relies on local code/tests. [VERIFIED: command -v ctx7]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit / Phoenix LiveViewTest via Mix; Playwright `@playwright/test` 1.60.0 for browser UAT. [VERIFIED: mix.lock; VERIFIED: examples/threadline_phoenix/e2e/package-lock.json] |
| Config file | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts`. [VERIFIED: mix.exs; VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts] |
| Quick run command | `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/style_contract_test.exs` [VERIFIED: test inventory + existing convention] |
| Full suite command | `mix test` plus `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-home-nav-mobile.spec.ts` after starting the example app. [VERIFIED: mix.exs; VERIFIED: examples/threadline_phoenix/e2e/package.json] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| POLISH-HOME | Header active state matches current screen/family for Timeline, Transaction, Actor, Coverage, Evidence, Redaction, Retention, Exports, and Home. [CITED: .planning/ROADMAP.md] | unit/component or LiveView render | `mix test test/threadline/operator_surface/live/start_live_test.exs` plus existing screen tests as needed [VERIFIED: test inventory] | ❌ Wave 0 |
| POLISH-HOME | Header preserves feature-flag visibility, brand Home link, skip link, scoped chip, and coverage badge. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md] | unit/component + LiveView render | `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs` [VERIFIED: existing coverage doc tests] | ❌ Wave 0 for StartLive/header specifics |
| POLISH-HOME | Home renders persona next-action cards, quiet health row, severity-specific unhealthy chips, and saved-view resume links. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md] | LiveView render | `mix test test/threadline/operator_surface/live/start_live_test.exs` [VERIFIED: no existing StartLive test file] | ❌ Wave 0 |
| POLISH-HOME | 375px nav preserves all enabled destinations and grouping from every representative screen without horizontal page overflow. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md] | Playwright mobile UAT | `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-home-nav-mobile.spec.ts` [VERIFIED: existing e2e package scripts] | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run focused ExUnit for touched Home/header/style tests. [VERIFIED: mix.exs]
- **Per wave merge:** Run focused ExUnit plus `operator-home-nav-mobile.spec.ts`. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts]
- **Phase gate:** Focused ExUnit and Home/nav mobile browser spec green before `$gsd-verify-work`. [CITED: .planning/config.json]

### Wave 0 Gaps

- [ ] `test/threadline/operator_surface/live/start_live_test.exs` — covers Home health, saved views, feature flags, persona copy, and no Phase 140 form/event. [VERIFIED: test inventory]
- [ ] `test/threadline/operator_surface/surface_header_test.exs` or equivalent LiveView assertions — covers active state, grouping, separator before Exports, and feature-flag visibility. [VERIFIED: test inventory]
- [ ] `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts` — covers Home orientation and 375px nav reachability across representative screens. [VERIFIED: existing e2e pattern]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Preserve existing `Threadline.OperatorSurface.Auth` on-mount/session behavior; do not bypass `threadline_actor_ref` handling. [VERIFIED: lib/threadline/operator_surface/auth.ex; VERIFIED: lib/threadline/operator_surface/router.ex] |
| V3 Session Management | yes | Preserve `SessionPlug` actor-ref serialization and existing LiveView session mount path. [VERIFIED: lib/threadline/operator_surface/session_plug.ex; VERIFIED: test/threadline/operator_surface/session_plug_test.exs] |
| V4 Access Control | yes | Preserve feature flags, scoped chip, and authorization/on-mount contracts. [VERIFIED: lib/threadline/operator_surface/router.ex; VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] |
| V5 Input Validation | limited | Do not add new input flows in Phase 139; existing saved-view filters are canonicalized before Timeline links. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md; VERIFIED: lib/threadline/operator_surface/exports/filter_params.ex] |
| V6 Cryptography | no new crypto | No cryptographic changes are in scope. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView Operator Surface

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized destinations exposed through Home/header polish | Elevation of privilege | Keep feature-flag-aware destination rendering and existing auth/on-mount contracts. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex; VERIFIED: lib/threadline/operator_surface/router.ex] |
| Scoped user loses scope warning on mobile | Information disclosure | Preserve `operator-scope` chip and prove mobile reachability/visibility where scoped. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex; VERIFIED: examples/threadline_phoenix/e2e/tests/operator-features.spec.ts] |
| New record/correlation input bypasses validation | Tampering / Information disclosure | Do not add Phase 140 input flows in Phase 139. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md` — locked phase decisions, findings, scope, deferred Phase 140 items. [CITED]
- `.planning/milestones/v1.31-PERSONAS-IA.md` — locked personas, JTBD, IA, EF1-EF5, Home/nav recommendations. [CITED]
- `.planning/milestones/v1.31-UI-AUDIT.md` — F-204, F-301, F-302, F-303, F-304, F-801 boundaries. [CITED]
- `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` — POLISH-HOME requirement and success criteria. [CITED]
- `lib/threadline/operator_surface/live/start_live.ex` — Home implementation, health row, saved views. [VERIFIED]
- `lib/threadline/operator_surface/components/surface_header.ex` — nav implementation, active states, feature flags, scope and coverage affordances. [VERIFIED]
- `lib/threadline/operator_surface/style.ex` — scoped CSS, mobile-first topbar/nav, tokens, chips, buttons. [VERIFIED]
- `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` and `operator-prove-mobile.spec.ts` — browser mobile UAT pattern. [VERIFIED]

### Secondary (MEDIUM confidence)

- `npm view @playwright/test version time.modified` — current registry version and modified date for installed Playwright package. [VERIFIED: npm registry]
- Local environment probes for Elixir/Mix, Node/npm, PostgreSQL, Docker. [VERIFIED: shell]

### Tertiary (LOW confidence)

- None. [VERIFIED: research process]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — versions verified from `mix.lock`, package lock, registry, and local runtime probes. [VERIFIED: mix.lock; VERIFIED: npm registry; VERIFIED: shell]
- Architecture: HIGH — implementation surface is narrow and directly verified in `StartLive`, `SurfaceHeader`, router, style, and mobile specs. [VERIFIED: codebase rg]
- Pitfalls: HIGH — scope fences and audit findings are explicit in Phase 139 context and milestone audit/IA docs. [CITED: .planning/phases/139-orientation-hub-home-nav/139-CONTEXT.md; CITED: .planning/milestones/v1.31-UI-AUDIT.md]

**Graph context:** Graphify is disabled, so semantic graph relationships were not used. [VERIFIED: gsd-tools graphify status]  
**Research date:** 2026-06-04 [VERIFIED: current_date]  
**Valid until:** 2026-07-04 for codebase-local planning guidance; re-check package/runtime versions before changing browser test infrastructure. [VERIFIED: research process]

## RESEARCH COMPLETE

**Research artifact:** `.planning/phases/139-orientation-hub-home-nav/139-RESEARCH.md`
