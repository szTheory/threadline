# Phase 141: motion-micro-animation - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 4 target files/artifacts
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/141-motion-micro-animation/141-MOTION-INVENTORY.md` | documentation / contract artifact | transform, source inventory | `.planning/phases/140-earned-new-flows/140-PATTERNS.md` + motion comments in `style.ex` | role-match |
| `lib/threadline/operator_surface/style.ex` | style / design-system module | request-response render, CSS transform | `lib/threadline/operator_surface/style.ex` | exact |
| `test/threadline/operator_surface/style_contract_test.exs` | source-contract test | file-I/O, transform | `test/threadline/operator_surface/style_contract_test.exs` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` | browser E2E test | request-response, reduced-motion assertions | `operator-earned-flows.spec.ts`, `operator-home-nav-mobile.spec.ts`, `playwright.config.ts` | role-match |

## Pattern Assignments

### `.planning/phases/141-motion-micro-animation/141-MOTION-INVENTORY.md` (documentation / contract artifact, transform)

**Analog:** `.planning/phases/141-motion-micro-animation/141-CONTEXT.md` + existing motion comments in `lib/threadline/operator_surface/style.ex`

**Inventory inputs** (`141-CONTEXT.md` lines 10-17, 23-31):
```markdown
Phase 141 owns the operator-surface motion layer only:
- Document a motion inventory that maps each shipped animation to trigger, JTBD, and token.
- Reuse the existing `120ms`, `180ms`, and `240ms` timing tokens plus the signature thread-draw pattern.
- Ensure every animated surface honors `prefers-reduced-motion`.
```

**Current motion surface to inventory** (`141-CONTEXT.md` lines 37-47):
```markdown
- Tokens in `lib/threadline/operator_surface/style.ex`: `--tl-motion-fast`, `--tl-motion-base`, `--tl-motion-slow`, `--tl-motion-stagger`, `--tl-motion-distance-sm`, `--tl-motion-distance-md`, `--tl-ease-standard`, `--tl-ease-out`, and `--tl-transition-fast`.
- Home launcher card entrance via `tl-rise-in` and staggered delays.
- Home primary card signature thread via `tl-thread-draw`.
- Subview/drawer entrance via `tl-drawer-in` and row-history panel rise/fade sequencing.
- Collapsible sections using tokenized `block-size` / `content-visibility` transition.
- Copy feedback via `tl-copy-pulse`.
- Journey/proof thread-draw and redaction-success thread-draw moments.
```

**Copy the local justification style** (`style.ex` lines 2160-2169):
```css
/*
 * Motion — purposeful, brand-coherent micro-interactions.
 * Pure CSS, GPU-only (transform/opacity), reusing the motion tokens.
 * Each fires on element mount; LiveView streams replay them only for
 * newly inserted/changed rows, so a freshly prune-run row or a
 * just-opened drawer animates while unchanged rows stay put. All
 * auto-degrade via the prefers-reduced-motion blanket below. The
 * high-traffic timeline stream is deliberately NOT animated — snappy
 * paging beats an entrance flourish (never animate high-frequency
 * actions).
 */
```

**Recommended inventory table columns:** selector/keyframe, trigger, JTBD/persona, token(s), motion properties, reduced-motion behavior, source line(s), keep/remove/justify.

### `lib/threadline/operator_surface/style.ex` (style / design-system module, request-response CSS transform)

**Analog:** `lib/threadline/operator_surface/style.ex`

**Imports/rendering pattern** (lines 1-18):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Style do
    @moduledoc """
    Provides isolated CSS for the Threadline Operator Surface.
    """

    import Phoenix.Component

    def css(assigns) do
      assigns =
        assign(assigns, :fonts_html, Phoenix.HTML.raw(font_face_style()))

      ~H"""
      {@fonts_html}<style>
```

Keep all motion CSS inside the existing embedded `.threadline-ui` style module. Do not add asset-pipeline files, JS animation libraries, or dependencies.

**Motion token pattern** (lines 147-159):
```css
--tl-motion-fast: 120ms;
--tl-motion-base: 180ms;
--tl-motion-slow: 240ms;
--tl-motion-distance-sm: 8px;
--tl-motion-distance-md: 16px;
--tl-motion-stagger: 40ms;
--tl-ease-standard: cubic-bezier(0.2, 0, 0, 1);
--tl-ease-out: cubic-bezier(0.16, 1, 0.3, 1);
--tl-transition-fast: var(--tl-motion-fast) var(--tl-ease-standard);
```

Use these names as the authoritative scale. Tests should reject new literal timing values except the existing delayed `120ms` thread-draw offset, unless the plan explicitly removes or tokenizes that offset.

**Generic transition pattern** (lines 178-183, 340-343):
```css
.threadline-ui a {
  transition-property: color, background-color, border-color, box-shadow, transform;
  transition-duration: var(--tl-transition-fast);
}

.tl-topbar .tl-topbar__nav-item {
  transition: color var(--tl-transition-fast), background-color var(--tl-transition-fast), border-color var(--tl-transition-fast), box-shadow var(--tl-transition-fast);
}
```

Prefer explicit transition properties and `var(--tl-transition-fast)` over catch-all `transition: all`.

**Home entrance and signature thread pattern** (lines 448-488):
```css
.tl-home__card {
  animation: tl-rise-in var(--tl-motion-base) var(--tl-ease-out) both;
}

.tl-home__cards > .tl-home__card:nth-child(2) {
  animation-delay: var(--tl-motion-stagger);
}

.tl-home__card--primary::before {
  transform: scaleX(0);
  transform-origin: left center;
  animation: tl-thread-draw var(--tl-motion-slow) var(--tl-ease-out) 120ms both;
}
```

**Subview, keyframe, and row-history pattern** (lines 2079-2090, 2126-2158, 2172-2206):
```css
.tl-subview {
  animation: tl-drawer-in var(--tl-motion-base) var(--tl-ease-standard);
}

@keyframes tl-drawer-in {
  from { opacity: 0; transform: translateX(var(--tl-motion-distance-md)); }
  to { opacity: 1; transform: translateX(0); }
}

@keyframes tl-rise-in {
  from { opacity: 0; transform: translateY(var(--tl-motion-distance-sm)); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes tl-thread-draw {
  to { transform: scaleX(1); }
}

@keyframes tl-fade-in {
  from { opacity: 0; }
}
```

Keep animations GPU-friendly: opacity, transform, box-shadow pulse only. The existing `block-size` details transition is a documented exception and must stay covered by reduced-motion.

**Copy feedback pattern** (lines 2208-2237, 2255-2260):
```css
.tl-copy.is-copied {
  color: var(--tl-color-signal);
  border-color: var(--tl-color-signal-border);
  animation: tl-copy-pulse var(--tl-motion-base) var(--tl-ease-out);
}

@keyframes tl-copy-pulse {
  from { box-shadow: 0 0 0 0 var(--tl-color-signal-border); }
  to { box-shadow: 0 0 0 6px transparent; }
}
```

Static copied feedback lives in `::after`, while only the pulse animates. Preserve that reduced-motion-friendly confirmation pattern.

**Signature thread pattern** (lines 2330-2343, 2568-2592):
```css
.tl-journey-rail::before {
  transform: scaleX(0);
  transform-origin: left center;
  animation: tl-thread-draw var(--tl-motion-slow) var(--tl-ease-out) 120ms both;
}

.tl-policy__success::after {
  transform: scaleX(0);
  transform-origin: left center;
  animation: tl-thread-draw var(--tl-motion-slow) var(--tl-ease-out) 120ms both;
}
```

The Signal Cyan thread-draw is the branded motif. Apply it only to completed path, primary entry, or evidence/proof progression moments.

**Reduced-motion blanket** (lines 2809-2823):
```css
@media (prefers-reduced-motion: reduce) {
  .threadline-ui *,
  .threadline-ui *::before,
  .threadline-ui *::after,
  .tl-policy__row::details-content {
    transition-duration: 1ms !important;
    animation-duration: 1ms !important;
    animation-delay: 0ms !important;
    animation-iteration-count: 1 !important;
    scroll-behavior: auto !important;
  }

  .tl-button:active {
    transform: none;
  }
}
```

Add targeted resets here only when a reduced-motion user would otherwise see a transformed or visually ambiguous final state.

### `test/threadline/operator_surface/style_contract_test.exs` (source-contract test, file-I/O transform)

**Analog:** `test/threadline/operator_surface/style_contract_test.exs`

**File-read source contract pattern** (lines 1-12):
```elixir
defmodule Threadline.OperatorSurface.StyleContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @style_path "lib/threadline/operator_surface/style.ex"

  test "operator surface stays dark-only and token-driven" do
    src = File.read!(@style_path)
```

Add Phase 141 tests here rather than creating a parser unless needed. This file already treats `style.ex` as the design-system source of truth.

**Scoped section extraction pattern** (lines 73-86, 149-171):
```elixir
home_section =
  src
  |> String.split("/* Operator Home")
  |> Enum.at(1)
  |> String.split(".tl-page__header")
  |> List.first()

assert String.contains?(home_section, "var(--tl-")
refute String.contains?(home_section, "@tailwind")
refute String.contains?(home_section, "from shadcn")
refute String.contains?(home_section, "prefers-color-scheme")
refute Regex.match?(~r/#[0-9a-fA-F]{6}/, home_section)
```

Copy this style for motion sections: split around `/* Motion`, `@keyframes`, and `@media (prefers-reduced-motion: reduce)`; assert token usage and refute disallowed ad-hoc values.

**Selector loop pattern** (lines 54-71, 156-164):
```elixir
for selector <- [
      ".tl-home__earned-flow",
      ".tl-home__earned-panel",
      ".tl-home__earned-copy"
    ] do
  assert String.contains?(home_section, selector)
end
```

Use loops for inventory-backed selectors and keyframes so the test reads like a checklist. Good candidates: `tl-rise-in`, `tl-thread-draw`, `tl-drawer-in`, `tl-fade-in`, `tl-copy-pulse`, `.tl-home__card`, `.tl-subview`, `.tl-copy.is-copied`, `.tl-journey-rail::before`, `.tl-policy__success::after`.

**Recommended Phase 141 source contracts:**
- Motion token values equal the locked scale from `141-CONTEXT.md` lines 23-25.
- Every `animation:` uses an approved keyframe and `var(--tl-motion-*)` duration.
- Every `transition` uses `var(--tl-transition-fast)` or named motion/ease tokens.
- `@media (prefers-reduced-motion: reduce)` includes universal scoped selectors and `::before` / `::after`.
- Inventory entries mention every keyframe and every `animation:` consumer found in `style.ex`.
- No `transition: all`, no new one-off `@keyframes`, no JavaScript animation library markers.

### `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` (browser E2E, request-response reduced-motion assertions)

**Analogs:** `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts`, `operator-home-nav-mobile.spec.ts`, `examples/threadline_phoenix/e2e/playwright.config.ts`

**Playwright config baseline** (`playwright.config.ts` lines 3-20):
```typescript
const baseURL = process.env.E2E_BASE_URL ?? "http://127.0.0.1:4002";

export default defineConfig({
  testDir: "./tests",
  timeout: 120_000,
  expect: { timeout: 15_000 },
  workers: 1,
  use: {
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    reducedMotion: "reduce",
  },
});
```

The default E2E environment already forces reduced motion. For normal-motion assertions, use a narrow per-test override such as `test.use({ reducedMotion: "no-preference" })` in a dedicated describe block. Keep default reduced-motion assertions in the main spec path.

**Login and helper pattern** (`operator-earned-flows.spec.ts` lines 1-33):
```typescript
import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}
```

**Focused browser assertion pattern** (`operator-earned-flows.spec.ts` lines 60-84):
```typescript
test.describe("operator earned-flow browser UAT", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("EF1 Home record-first lookup reaches first-class row history", async ({ page }) => {
    await page.goto("/audit");
    const earnedFlow = page.locator('[data-earned-flow="EF1"]');
    await expect(earnedFlow).toBeVisible();
    await expect(earnedFlow).toHaveAttribute("data-earned-flow", "EF1");
  });
});
```

Copy the narrow route/selector style, but assert computed motion behavior instead of screenshots. Useful assertions:
- Under default reduced motion, `getComputedStyle(el).animationDuration` and `transitionDuration` resolve to `0.001s` or an equivalent 1ms value for animated surfaces.
- Under `no-preference`, named surfaces report expected animation names such as `tl-rise-in`, `tl-thread-draw`, `tl-drawer-in`, or `tl-copy-pulse`.
- Assert static state remains visible under reduced motion, such as copy confirmation text from `.tl-copy.is-copied::after`.

**Mobile/no-overflow helper pattern** (`operator-home-nav-mobile.spec.ts` lines 36-43):
```typescript
async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}
```

Use only as a smoke guard if the motion assertion opens drawers or policy details. Do not broaden into Phase 142 responsive matrix work.

## Shared Patterns

### Motion Tokens

**Source:** `lib/threadline/operator_surface/style.ex` lines 147-159.

Apply to all animation and transition code. Approved durations are `--tl-motion-fast`, `--tl-motion-base`, `--tl-motion-slow`, and approved spacing offsets are `--tl-motion-distance-sm`, `--tl-motion-distance-md`, `--tl-motion-stagger`.

### Reduced Motion

**Source:** `lib/threadline/operator_surface/style.ex` lines 2809-2823 and `playwright.config.ts` lines 16-20.

Every animation and transition must be covered by the scoped reduced-motion blanket. Browser tests should remember the default Playwright project is already reduced-motion, so normal-motion probes need explicit `reducedMotion: "no-preference"`.

### Test Style

**Source:** `test/threadline/operator_surface/style_contract_test.exs` lines 5-8, 73-86, 149-171.

Prefer source-contract checks for design-system invariants. Use Playwright only for computed browser behavior that source contracts cannot prove.

### Phase Boundaries

**Source:** `141-CONTEXT.md` lines 17, 29-31, 76-80; `140-VERIFICATION.md` lines 41 and 76.

No route behavior changes, no broad responsive layout work, no screenshot baselines, no visual redesign, no external animation dependency. Preserve Phase 140 earned-flow selectors and UAT surfaces.

## Pitfalls

| Pitfall | Source | Recommendation |
|---|---|---|
| Literal-duration drift | `style.ex` lines 147-159, 488, 2343, 2592 | Prefer tokens. If keeping the existing `120ms` thread delay, document it as the signature offset or introduce a token with a source-contract update. |
| Motion inventory can go stale | `141-CONTEXT.md` lines 23-29 | Add a source-contract test that cross-checks keyframes / `animation:` consumers against inventory text. |
| Reduced-motion browser specs may accidentally test only reduced mode | `playwright.config.ts` lines 16-20 | Use explicit per-test `reducedMotion: "no-preference"` for normal motion checks; keep default reduced checks separate. |
| High-frequency Timeline animation | `style.ex` lines 2166-2169 | Keep Timeline stream rows unanimated unless a narrow JTBD justifies it. |
| Layout-affecting motion | `style.ex` lines 2052-2068 | The details `block-size` transition is an exception; keep it covered by reduced-motion and avoid adding more layout motion. |
| Phase creep into 142/143 | `141-CONTEXT.md` lines 17, 83-90 | Do not add screenshot-diff infrastructure, breakpoint matrix tests, or broad mobile layout changes. |

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | - | - | Existing embedded CSS, style-contract tests, and focused Playwright specs cover Phase 141's expected implementation surface. |

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/style.ex`, `test/threadline/operator_surface/style_contract_test.exs`, `examples/threadline_phoenix/e2e`, `.planning/phases/138-*`, `.planning/phases/139-*`, `.planning/phases/140-*`
**Files scanned:** 15+ focused files/artifacts
**Pattern extraction date:** 2026-06-04
