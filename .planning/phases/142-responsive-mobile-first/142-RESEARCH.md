# Phase 142: Responsive / Mobile-First - Research

**Researched:** 2026-06-04
**Domain:** Phoenix LiveView operator-surface CSS, responsive browser UAT, source-contract tests
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Phase 142 owns genuine mobile-first responsiveness across the operator surface:

- Tokenize a breakpoint scale and use it consistently instead of scattered literal media query widths.
- Give tables, filters/toolbars, drawers/subviews, and top navigation mobile-first layouts.
- Verify every operator-surface screen at 375, 768, and 1280 viewport widths.
- Eliminate document-level horizontal overflow regressions while preserving intentional internal scroll containers where they are the right interaction.

This phase must not broaden into Phase 143 final accessibility/screenshot-diff infrastructure or new product workflows. It may add focused browser UAT, source-contract tests, and narrowly scoped CSS/layout changes.

### the agent's Discretion

- **D-01:** Treat `375 / 768 / 1280` as the acceptance viewport matrix because it is explicit in the roadmap and requirement.
- **D-02:** Preserve the existing operator-console visual language and IA. Responsive work should improve layout behavior, density, wrapping, and scroll ownership without redesigning the surface.
- **D-03:** Tokenize breakpoints in `Style.css` as source-level custom properties/documented constants where CSS supports them, but keep actual `@media` queries standards-compliant. If CSS custom properties cannot be used directly in media queries, pair variables with source-contract tests that lock literal media widths to named tokens.
- **D-04:** Keep the topbar navigation reachable on mobile. Internal nav horizontal scroll is acceptable only when explicitly owned by `.tl-topbar__nav`; document/root horizontal overflow is not acceptable.
- **D-05:** Tables should be mobile-first labelled cards at narrow widths and restore true table semantics at desktop widths. Each table-like surface must use a shared responsive pattern rather than bespoke ad-hoc overflow.
- **D-06:** Filters and toolbar controls should stack on phones, wrap at tablet, and align as a compact toolbar on desktop.
- **D-07:** Drawers/subviews should fit 375px without clipping primary controls or values; desktop may keep the right-side drawer width.
- **D-08:** Browser verification must cover representative operator routes in one responsive matrix, using computed document overflow and key reachability checks rather than screenshot baselines.
- **D-09:** Keep Phase 142 independent of Phase 143: do not build screenshot-diff CI, final visual diff baselines, or broad ARIA/focus audits here.

### Deferred Ideas (OUT OF SCOPE)

- Final accessibility sweep, focus-order audit, and ARIA baseline.
- Screenshot-diff infrastructure and baseline explanation.
- New routes, new workflows, or semantic changes to exports, row history, policy, evidence, or coverage.
- Broad visual redesign or theme changes.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POLISH-RESPONSIVE | Every operator-surface screen is usable and correct at 375 / 768 / 1280; breakpoint scale is tokenized; tables, filters, drawers, and nav have mobile-first layouts; no horizontal-scroll regressions. [VERIFIED: `.planning/REQUIREMENTS.md`] | Use source-contract tests for breakpoint literals, shared CSS primitives for tables/toolbars/drawers/nav, and one Playwright responsive matrix covering all operator routes and root overflow at 375, 768, and 1280. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 142 should keep the existing CSS architecture: a single Phoenix-rendered stylesheet in `lib/threadline/operator_surface/style.ex`, scoped `.tl-*` classes, and `--tl-*` design tokens. [VERIFIED: codebase grep] The current surface is already mobile-first in important places: `.tl-topbar__nav` owns internal horizontal scroll, `.tl-toolbar__form` stacks on phones, `.tl-subview` is full-width on phones, and `.tl-table--responsive` renders rows as labelled cards before restoring table display in the wider media layer. [VERIFIED: codebase grep]

The planning risk is not framework choice; it is contract drift. [ASSUMED] Current breakpoints are literal `481px` and `721px`, while acceptance is `375 / 768 / 1280`. [VERIFIED: codebase grep] CSS custom properties cannot be used directly inside media queries, so the correct contract is: define readable breakpoint token comments or module attributes, keep standards-compliant literal `@media` values, and add ExUnit source-contract tests that tie each literal to a named semantic token. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Cascading_variables/Using_custom_properties]

**Primary recommendation:** Use `375px` as the phone proof width, `768px` as the tablet enhancement threshold, and `1280px` as the desktop proof width; replace/retire the current `481px` and `721px` literals behind named source contracts, then add one focused Playwright matrix spec that visits every operator route and asserts root `scrollWidth - clientWidth <= 1`. [VERIFIED: `.planning/phases/142-responsive-mobile-first/142-CONTEXT.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Breakpoint scale contract | Frontend Server / CSS source | Browser / Client | `style.ex` emits the operator stylesheet, while browser tests prove computed behavior at acceptance widths. [VERIFIED: codebase grep] |
| Top navigation reachability | Browser / Client | Frontend Server / CSS source | CSS owns wrapping and internal nav scroll; Playwright proves nav links remain reachable. [VERIFIED: codebase grep] |
| Table mobile cards and desktop tables | Frontend Server / CSS source | Browser / Client | Markup provides `data-label` cells and CSS switches display behavior; browser proof catches overflow regressions. [VERIFIED: codebase grep] |
| Toolbar/filter layout | Frontend Server / CSS source | Browser / Client | CSS flex direction/wrapping owns phone/tablet/desktop layout; tests should assert visible controls and no root overflow. [VERIFIED: codebase grep] |
| Drawer/subview fit | Frontend Server / CSS source | Browser / Client | `.tl-subview` width/top/min-height rules are CSS-owned, and Playwright can inspect bounding boxes and primary controls. [VERIFIED: codebase grep] |
| No-horizontal-overflow proof | Browser / Client | Frontend Server / CSS source | Runtime document dimensions are the authoritative acceptance check; CSS changes are the remediation mechanism. [VERIFIED: codebase grep] |

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists in `/Users/jon/projects/threadline`, verified with `test -f AGENTS.md`. [VERIFIED: shell]

## Standard Stack

### Core

| Library / Layer | Version | Purpose | Why Standard |
|-----------------|---------|---------|--------------|
| Phoenix LiveView component CSS in `Threadline.OperatorSurface.Style` | Existing project layer | Emits isolated operator-surface CSS inside the LiveView surface. [VERIFIED: codebase grep] | Matches current architecture and avoids the roadmap's explicit non-goal of switching CSS architecture. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| ExUnit source-contract tests | Mix 1.19.5 / Elixir 1.19.5 available locally | Locks CSS source invariants such as tokens, forbidden patterns, and exact selectors. [VERIFIED: shell] | Existing `style_contract_test.exs` already enforces dark-only, token-backed, nav, and motion contracts. [VERIFIED: codebase grep] |
| Playwright Test | `@playwright/test` 1.60.0 in `package-lock.json`; registry latest checked as 1.60.0 on 2026-06-04. [VERIFIED: npm registry] | Browser UAT for route reachability, viewports, computed overflow, bounding boxes, and selectors. [VERIFIED: codebase grep] | Playwright officially supports viewport/device emulation and projects for running tests in different configurations. [CITED: https://playwright.dev/docs/next/emulation] |

### Supporting

| Library / Layer | Version | Purpose | When to Use |
|-----------------|---------|---------|-------------|
| `mix verify.example_browser` | Existing Mix alias/task | Runs the example Phoenix app and e2e suite through `examples/threadline_phoenix/e2e/run-e2e.sh`. [VERIFIED: codebase grep] | Use as the phase gate after focused specs pass. [VERIFIED: codebase grep] |
| Existing seeded demo data | Existing example seed contract | Provides deterministic transaction, row-history, actor, evidence, retention, and export states for browser specs. [VERIFIED: codebase grep] | Use seeded constants `walk-acme-4521-close` and `ticket_replies` for transaction and row-history routes. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `.tl-*` CSS in `style.ex` | Tailwind, CSS-in-JS, component library | Explicitly out of scope; would create broad churn unrelated to POLISH-RESPONSIVE. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| Computed overflow and reachability checks | Screenshot baselines | Screenshot-diff infrastructure is deferred to Phase 143. [VERIFIED: `.planning/phases/142-responsive-mobile-first/142-CONTEXT.md`] |
| Source-contract tests for breakpoint literals | Runtime-only browser assertions | Runtime assertions prove behavior but do not prevent future source drift back to ad-hoc media query widths. [ASSUMED] |

**Installation:** No new packages should be installed for Phase 142. [VERIFIED: codebase grep]

```bash
# Existing project commands only
mix test test/threadline/operator_surface/style_contract_test.exs
cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-responsive-matrix.spec.ts
mix verify.example_browser
```

## Package Legitimacy Audit

No new external packages are recommended for this phase, so the package legitimacy gate is not required. [VERIFIED: codebase grep]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `@playwright/test` | npm | Existing dependency | Not audited because no install is recommended | Official Playwright project | Not run | Existing only |

**Packages removed due to slopcheck [SLOP] verdict:** none. [VERIFIED: codebase grep]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 142 input
  |
  v
Breakpoint/source contracts in style_contract_test.exs
  |        \
  |         -> fail if literal media widths drift from named responsive tokens
  v
Shared CSS primitives in style.ex
  |
  +-> .tl-topbar / .tl-topbar__nav owns mobile nav scroll
  +-> .tl-toolbar / .tl-toolbar__form stacks, wraps, then aligns
  +-> .tl-table--responsive cards on narrow widths, real table on desktop
  +-> .tl-subview full-width mobile drawer, bounded desktop drawer
  |
  v
Example Phoenix app with seeded demo data
  |
  v
Playwright responsive matrix at 375, 768, 1280
  |
  +-> route loads and key selectors visible
  +-> root document overflow <= 1px
  +-> only explicit internal scroll owners may overflow
  |
  v
mix verify.example_browser phase gate
```

### Recommended Project Structure

```text
lib/threadline/operator_surface/
+-- style.ex                         # breakpoint tokens and responsive primitive CSS
test/threadline/operator_surface/
+-- style_contract_test.exs          # source-level responsive token/literal contracts
examples/threadline_phoenix/e2e/tests/
+-- operator-responsive-matrix.spec.ts # 375/768/1280 route and overflow proof
```

### Pattern 1: Breakpoint Token Source Contract

**What:** Put named breakpoint declarations near the existing token block and test for both the token declaration and the exact standards-compliant media queries. [VERIFIED: codebase grep]

**When to use:** Use for every responsive breakpoint because `var()` cannot be used inside media queries. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Cascading_variables/Using_custom_properties]

**Example:**

```elixir
# Source: existing ExUnit source-contract pattern in test/threadline/operator_surface/style_contract_test.exs
test "phase 142 breakpoint literals stay tied to named responsive tokens" do
  src = File.read!(@style_path)

  assert String.contains?(src, "--tl-breakpoint-phone-proof: 375px;")
  assert String.contains?(src, "--tl-breakpoint-tablet: 768px;")
  assert String.contains?(src, "--tl-breakpoint-desktop-proof: 1280px;")
  assert String.contains?(src, "@media (min-width: 768px)")
  refute String.contains?(src, "@media (min-width: 481px)")
  refute String.contains?(src, "@media (min-width: 721px)")
end
```

### Pattern 2: Shared Responsive Table Contract

**What:** Keep `.tl-table--responsive` as the shared table pattern: hidden `<thead>` plus block rows/cards at narrow widths; table display restored at desktop. [VERIFIED: codebase grep]

**When to use:** Use for Coverage, Retention runs, Evidence table-like lists where semantics or dense row scanning matter. [VERIFIED: codebase grep]

**Example:**

```css
/* Source: lib/threadline/operator_surface/style.ex existing pattern */
.tl-table--responsive td {
  display: grid;
  grid-template-columns: minmax(96px, 30%) minmax(0, 1fr);
}

.tl-table--responsive td::before {
  content: attr(data-label);
}
```

### Pattern 3: Browser Matrix Overflow Proof

**What:** Loop over viewports and routes in one spec, set viewport size, navigate, assert key selectors, and compute root overflow. [VERIFIED: codebase grep]

**When to use:** Use for Phase 142 acceptance because Playwright supports viewport emulation and projects/configuration for different devices. [CITED: https://playwright.dev/docs/next/emulation]

**Example:**

```typescript
// Source: existing overflow helper from operator-home-nav-mobile.spec.ts
async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}
```

### Anti-Patterns to Avoid

- **Using `var(--tl-breakpoint-*)` inside `@media`:** CSS custom properties do not work inside media queries, so this would silently fail or be invalid depending on browser handling. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Cascading_variables/Using_custom_properties]
- **Blanket `overflow-x: hidden` on root/body:** It can hide layout defects and make off-screen controls unreachable; prove and fix the offending component instead. [ASSUMED]
- **One-off table wrappers per screen:** The roadmap calls for shared responsive patterns, and the current CSS already has `.tl-table--responsive`. [VERIFIED: `.planning/phases/142-responsive-mobile-first/142-CONTEXT.md`]
- **Screenshot baselines in this phase:** Phase 143 owns screenshot-diff infrastructure. [VERIFIED: `.planning/phases/142-responsive-mobile-first/142-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser viewport matrix | Custom browser runner | Playwright Test | Existing e2e suite and official Playwright viewport/project support already fit the requirement. [CITED: https://playwright.dev/docs/test-projects] |
| CSS source governance | Ad-hoc script parser | Existing ExUnit source-contract tests | `style_contract_test.exs` already reads source files and asserts contract strings/patterns. [VERIFIED: codebase grep] |
| Responsive tables | Bespoke per-LiveView mobile markup | `.tl-table--responsive` plus `data-label` cells | Shared CSS avoids drift and matches the locked decision for labelled mobile cards. [VERIFIED: codebase grep] |
| Drawer responsive fit | JavaScript resize calculations | CSS `width`, `min()`, `100vw`, `100dvh`, and Playwright bounding boxes | Current drawer is CSS-owned and already uses full-width phone / bounded desktop rules. [VERIFIED: codebase grep] |

**Key insight:** The hard part is not new capability; it is proving the whole surface stays inside root viewport width while allowing only named internal scroll containers. [VERIFIED: `.planning/phases/142-responsive-mobile-first/142-CONTEXT.md`]

## Common Pitfalls

### Pitfall 1: Treating Breakpoint Tokens As Runtime CSS Variables

**What goes wrong:** A planner asks implementation to write `@media (min-width: var(--tl-breakpoint-tablet))`. [ASSUMED]
**Why it happens:** CSS custom properties look like reusable tokens, but MDN documents that variables do not work inside media/container queries. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Cascading_variables/Using_custom_properties]
**How to avoid:** Use named token declarations for documentation and source contracts, but keep literal media query widths. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Media_queries/Using]
**Warning signs:** `var(--tl-breakpoint` appears inside an `@media` rule. [ASSUMED]

### Pitfall 2: Collapsing All Overflow Instead Of Assigning Scroll Ownership

**What goes wrong:** A global overflow rule hides off-canvas controls or masks a too-wide component. [ASSUMED]
**Why it happens:** Root overflow checks fail and the fastest apparent fix is broad clipping. [ASSUMED]
**How to avoid:** Treat `.tl-topbar__nav` and `.tl-table-wrap` as explicit internal scroll owners and keep `documentElement.scrollWidth - clientWidth <= 1`. [VERIFIED: codebase grep]
**Warning signs:** Root overflow passes but nav links/table cells are not reachable with `scrollIntoViewIfNeeded()`. [VERIFIED: codebase grep]

### Pitfall 3: Desktop Table Semantics Restored Too Early

**What goes wrong:** Tablet width still behaves like a desktop table and causes horizontal scroll at 768. [ASSUMED]
**Why it happens:** Current desktop layer is `721px`, below the accepted tablet proof width. [VERIFIED: codebase grep]
**How to avoid:** Align the table restore threshold to the Phase 142 breakpoint contract and explicitly test `.tl-table--responsive thead`/row display at 375, 768, and 1280. [ASSUMED]
**Warning signs:** `@media (min-width: 721px)` remains after tokenization. [VERIFIED: codebase grep]

### Pitfall 4: Mobile Matrix Misses Dynamic Routes

**What goes wrong:** Static routes pass, but transaction, row-history, and actor routes overflow because IDs or dense values are wider. [ASSUMED]
**Why it happens:** Existing Home/nav representative screens omit `/audit/transactions/:id`, `/audit/rows/:table/:record_id`, and `/audit/actors/:type/:id`. [VERIFIED: codebase grep]
**How to avoid:** Reuse seeded discovery from `operator-earned-flows.spec.ts` and `operator-motion.spec.ts` to resolve transaction and row-history routes. [VERIFIED: codebase grep]
**Warning signs:** Responsive matrix only visits `/audit`, `/audit/timeline`, `/audit/coverage`, `/audit/evidence`, policy, and exports. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from existing sources:

### Route Matrix Skeleton

```typescript
// Source: examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts and Phase 142 context
const viewports = [
  { label: "phone", width: 375, height: 812, isMobile: true },
  { label: "tablet", width: 768, height: 900, isMobile: false },
  { label: "desktop", width: 1280, height: 900, isMobile: false },
];

const routes = [
  "/audit",
  "/audit/timeline",
  "/audit/coverage",
  "/audit/evidence",
  "/audit/policy/redaction",
  "/audit/policy/retention",
  "/audit/exports",
];
```

### Internal Scroll Owner Check

```typescript
// Source: existing .tl-topbar__nav reachability pattern
async function expectTopbarNavReachable(page: Page) {
  const nav = page.locator(".tl-topbar__nav");
  await expect(nav).toBeVisible();
  for (const id of ["operator-nav-timeline", "operator-nav-coverage", "operator-nav-exports"]) {
    const link = page.getByTestId(id);
    await link.scrollIntoViewIfNeeded();
    await expect(link).toBeVisible();
  }
}
```

### Drawer Fit Check

```typescript
// Source: existing boundingBox helper pattern in operator-find-mobile.spec.ts
async function expectFitsViewport(locator: Locator, width: number) {
  await expect(locator).toBeVisible();
  const rect = await locator.boundingBox();
  expect(rect).not.toBeNull();
  expect(rect!.x).toBeGreaterThanOrEqual(0);
  expect(rect!.width).toBeLessThanOrEqual(width);
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Literal `481px` and `721px` media layers | Named responsive source contract tied to `375 / 768 / 1280` proof matrix | Phase 142 target [VERIFIED: `.planning/ROADMAP.md`] | Planner should create an early source-contract task before layout fixes. [ASSUMED] |
| Per-spec 375px mobile checks | One cross-route, cross-width responsive matrix | Phase 142 target [VERIFIED: `.planning/phases/142-responsive-mobile-first/142-CONTEXT.md`] | Avoids scattered coverage gaps. [ASSUMED] |
| Screenshot-based confidence | Computed overflow, visibility, reachability, and bounding boxes | Phase 142 target [VERIFIED: `.planning/phases/142-responsive-mobile-first/142-CONTEXT.md`] | Keeps Phase 142 independent from Phase 143 screenshot-diff work. [VERIFIED: `.planning/phases/142-responsive-mobile-first/142-CONTEXT.md`] |

**Deprecated/outdated:**
- Current `481px` / `721px` breakpoints are outdated for Phase 142 because the accepted matrix is `375 / 768 / 1280`. [VERIFIED: codebase grep]
- Runtime-only 375px mobile UAT is insufficient for Phase 142 because the requirement explicitly includes 768 and 1280. [VERIFIED: `.planning/REQUIREMENTS.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Contract drift is the primary planning risk. | Summary | Planner may over-focus on new CSS instead of tests that prevent regressions. |
| A2 | Runtime assertions alone are weaker than source contracts for breakpoint governance. | Alternatives Considered | Future work could reintroduce ad-hoc media widths. |
| A3 | Blanket root overflow clipping can hide unreachable controls. | Anti-Patterns / Pitfalls | Planner might accept a visually passing but unusable layout. |
| A4 | Tablet can overflow if desktop table semantics restore below 768. | Pitfalls | Planner may keep the current `721px` restore point and miss tablet failures. |

## Open Questions

1. **Should desktop table semantics restore exactly at 768 or later?**
   - What we know: Acceptance includes 768 as a required viewport and current restore is 721. [VERIFIED: codebase grep]
   - What's unclear: Whether 768 should show tablet wrapped/card layout or desktop table layout for every table. [ASSUMED]
   - Recommendation: Make 768 the tablet proof point and only restore true desktop table behavior where Playwright proves no root overflow and controls remain reachable. [ASSUMED]

2. **Should the matrix run in all Playwright projects or a focused Chromium-only spec?**
   - What we know: Existing config has `chromium`, `desktop-chromium`, and `mobile-chromium` projects. [VERIFIED: codebase grep]
   - What's unclear: Whether full-project multiplication is worth the runtime for every route/viewport pair. [ASSUMED]
   - Recommendation: Keep the Phase 142 matrix as one focused spec that sets viewport sizes directly, then let `mix verify.example_browser` run the full configured suite as the gate. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | ExUnit source contracts and example app | yes | Elixir 1.19.5 / Mix 1.19.5 [VERIFIED: shell] | none |
| Erlang/OTP | Mix/Phoenix runtime | yes | OTP 28 [VERIFIED: shell] | none |
| Node.js | Playwright e2e | yes | v22.14.0 [VERIFIED: shell] | none |
| npm | Playwright dependency install/run | yes | 11.1.0 [VERIFIED: shell] | none |
| Playwright Test | Browser matrix | yes | lockfile 1.60.0 [VERIFIED: codebase grep] | none |
| `ctx7` docs CLI | Documentation lookup | no | unavailable [VERIFIED: shell] | Official docs via web search/open |

**Missing dependencies with no fallback:** none found for research/planning. [VERIFIED: shell]

**Missing dependencies with fallback:** `ctx7` unavailable; official MDN and Playwright docs were used directly. [VERIFIED: shell]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit for source contracts; Playwright Test for browser UAT. [VERIFIED: codebase grep] |
| Config file | `examples/threadline_phoenix/e2e/playwright.config.ts`; ExUnit via standard Mix test setup. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/threadline/operator_surface/style_contract_test.exs` [VERIFIED: codebase grep] |
| Focused browser command | `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-responsive-matrix.spec.ts` [VERIFIED: codebase grep] |
| Full suite command | `mix verify.example_browser` [VERIFIED: codebase grep] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| POLISH-RESPONSIVE | Breakpoint scale tokenized and literal media widths locked | ExUnit source contract | `mix test test/threadline/operator_surface/style_contract_test.exs` | Exists; needs new Phase 142 cases. [VERIFIED: codebase grep] |
| POLISH-RESPONSIVE | Tables use labelled cards below desktop and true table layout only at accepted wider layer | ExUnit + Playwright | `mix test test/threadline/operator_surface/style_contract_test.exs`; focused responsive spec | CSS exists; browser matrix file missing. [VERIFIED: codebase grep] |
| POLISH-RESPONSIVE | Filters/toolbars stack/wrap/align across 375/768/1280 | Playwright | focused responsive spec | Missing. [VERIFIED: codebase grep] |
| POLISH-RESPONSIVE | Drawers/subviews fit 375 and keep primary controls visible | Playwright | focused responsive spec | Missing. [VERIFIED: codebase grep] |
| POLISH-RESPONSIVE | All operator routes have root overflow <= 1px at 375/768/1280 | Playwright | focused responsive spec | Missing. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** `mix test test/threadline/operator_surface/style_contract_test.exs` for CSS/source contract changes. [VERIFIED: codebase grep]
- **Per wave merge:** focused `operator-responsive-matrix.spec.ts` against a running example app. [ASSUMED]
- **Phase gate:** `mix verify.example_browser` plus focused source-contract test. [VERIFIED: codebase grep]

### Wave 0 Gaps

- [ ] `test/threadline/operator_surface/style_contract_test.exs` - add Phase 142 breakpoint/source-contract cases. [VERIFIED: codebase grep]
- [ ] `examples/threadline_phoenix/e2e/tests/operator-responsive-matrix.spec.ts` - create 375/768/1280 route matrix. [VERIFIED: codebase grep]
- [ ] Shared e2e helper extraction is optional; existing specs duplicate `login` and overflow helpers. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no new auth behavior | Existing login path only; browser specs authenticate through seeded demo user. [VERIFIED: codebase grep] |
| V3 Session Management | no new session behavior | No phase-owned session changes. [VERIFIED: `.planning/phases/142-responsive-mobile-first/142-CONTEXT.md`] |
| V4 Access Control | no new access-control behavior | Do not add routes or product workflows. [VERIFIED: `.planning/phases/142-responsive-mobile-first/142-CONTEXT.md`] |
| V5 Input Validation | yes, limited to existing filters/forms | Preserve existing LiveView forms; test visibility/reachability rather than changing validation semantics. [VERIFIED: codebase grep] |
| V6 Cryptography | no | No cryptography changes. [VERIFIED: `.planning/phases/142-responsive-mobile-first/142-CONTEXT.md`] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Hidden destructive controls on mobile | Tampering / Elevation of privilege | Assert retention prune context and button ordering remains visible at 375/768/1280. [VERIFIED: codebase grep] |
| Off-screen policy/export controls due to overflow | Denial of service | Root overflow assertions plus reachability checks for primary controls. [VERIFIED: codebase grep] |
| Broad CSS clipping hides security-relevant warnings | Information disclosure / Denial of service | Avoid global `overflow-x: hidden`; fix component widths and use explicit internal scroll owners. [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/142-responsive-mobile-first/142-CONTEXT.md` - locked phase scope, route matrix, viewport matrix, and deferred work. [VERIFIED: codebase grep]
- `.planning/ROADMAP.md` - Phase 142 goal and success criteria. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - POLISH-RESPONSIVE requirement and explicit non-goals. [VERIFIED: codebase grep]
- `lib/threadline/operator_surface/style.ex` - current responsive CSS primitives, breakpoints, tables, toolbars, drawers, and nav. [VERIFIED: codebase grep]
- `test/threadline/operator_surface/style_contract_test.exs` - existing source-contract pattern. [VERIFIED: codebase grep]
- `examples/threadline_phoenix/e2e/tests/operator-*.spec.ts` - existing Playwright login, overflow, reachability, seeded route, and bounding-box patterns. [VERIFIED: codebase grep]
- MDN custom properties - `var()` cannot be used inside media/container queries. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Cascading_variables/Using_custom_properties]
- MDN media queries - `min-width`/`max-width` and range features are standard media query mechanisms. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Media_queries/Using]
- Playwright emulation docs - viewport/device emulation support. [CITED: https://playwright.dev/docs/next/emulation]
- Playwright projects docs - projects can run tests with different browsers/devices/configurations. [CITED: https://playwright.dev/docs/test-projects]

### Secondary (MEDIUM confidence)

- `.planning/phases/139-orientation-hub-home-nav/139-03-SUMMARY.md` - established `.tl-topbar__nav` as intentional scroll owner and Home/nav 375px proof. [VERIFIED: codebase grep]
- `.planning/phases/138-find-cluster-polish/138-04-SUMMARY.md` - Find mobile seeded route proof and overflow pattern. [VERIFIED: codebase grep]
- `.planning/phases/137-prove-cluster-polish/137-VERIFICATION.md` - Prove dense-state mobile assertions. [VERIFIED: codebase grep]
- `.planning/phases/141-motion-micro-animation/141-VERIFICATION.md` - motion baseline to preserve and computed-style Playwright pattern. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)

- Assumptions in the Assumptions Log about planning risk, overflow clipping risk, and exact tablet restore behavior. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing stack is verified in repo and official Playwright/MDN docs. [VERIFIED: codebase grep]
- Architecture: HIGH - phase maps to existing CSS source, ExUnit contracts, and Playwright e2e. [VERIFIED: codebase grep]
- Pitfalls: MEDIUM - CSS custom-property limitation is cited; overflow/table restore risk is partly inferred from current source and acceptance matrix. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Cascading_variables/Using_custom_properties]

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 for local architecture; 2026-06-11 for Playwright version/current-doc claims.
