# Phase 142: responsive-mobile-first - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 9 anticipated new/modified files
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/style.ex` | utility/config | transform | `lib/threadline/operator_surface/style.ex` | exact |
| `test/threadline/operator_surface/style_contract_test.exs` | test | transform | `test/threadline/operator_surface/style_contract_test.exs` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` | test | request-response | `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts` | exact |
| `lib/threadline/operator_surface/components/surface_header.ex` | component | request-response | `lib/threadline/operator_surface/components/surface_header.ex` | exact |
| `lib/threadline/operator_surface/live/timeline_live.ex` | component | request-response | `lib/threadline/operator_surface/live/timeline_live.ex` | exact |
| `lib/threadline/operator_surface/live/row_history_component.ex` | component | request-response | `lib/threadline/operator_surface/live/row_history_component.ex` | exact |
| `lib/threadline/operator_surface/live/coverage_live.ex` | component | CRUD | `lib/threadline/operator_surface/live/coverage_live.ex` | exact |
| `lib/threadline/operator_surface/live/retention_history_live.ex` | component | CRUD | `lib/threadline/operator_surface/live/retention_history_live.ex` | exact |
| `lib/threadline/operator_surface/live/policy_redaction_live.ex` | component | transform | `lib/threadline/operator_surface/live/policy_redaction_live.ex` | exact |

## Pattern Assignments

### `lib/threadline/operator_surface/style.ex` (utility/config, transform)

**Analog:** `lib/threadline/operator_surface/style.ex`

**Imports / LiveView style wrapper pattern** (lines 1-18):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Style do
    @moduledoc """
    Provides isolated CSS for the Threadline Operator Surface.
    """

    import Phoenix.Component

    def css(assigns) do
      assigns =
        assign(
          assigns,
          :fonts_html,
          Phoenix.HTML.raw(font_face_style())
        )

      ~H"""
      {@fonts_html}<style>
```

**Token block pattern to extend for breakpoints** (lines 126-160):
```css
--tl-header-height: 44px;
--tl-header-height-mobile: 52px;
--tl-control-height: 40px;
--tl-table-min-width: 720px;
--tl-drawer-width: 760px;
--tl-viewport-max-height: 600px;
--tl-hit-area: 40px;
--tl-motion-fast: 120ms;
--tl-motion-base: 180ms;
--tl-motion-slow: 240ms;
--tl-transition-fast: var(--tl-motion-fast) var(--tl-ease-standard);
```

**Mobile-first base pattern** (lines 386-390):
```css
/* Mobile-first base: phone layout. Tablet (min-width: 481px) and desktop
   (min-width: 721px) layers progressively enhance below the keyframes. */
.tl-page {
  padding: var(--tl-space-2);
}
```

**Topbar internal scroll owner pattern** (lines 283-291):
```css
.tl-topbar__nav {
  display: flex;
  order: 2;
  flex: 1 1 auto;
  align-items: center;
  gap: var(--tl-space-2);
  min-width: 0;
  overflow-x: auto;
  scrollbar-width: none;
}
```

**Toolbar stack/wrap/desktop pattern** (lines 761-766, 2628-2637, 2670-2676):
```css
.tl-toolbar__form {
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: var(--tl-space-3);
}

@media (min-width: 481px) {
  .tl-toolbar__field,
  .tl-toolbar__control {
    width: auto;
  }

  .tl-toolbar__form {
    flex-direction: row;
    flex-wrap: wrap;
    align-items: flex-end;
  }
}

@media (min-width: 721px) {
  .tl-toolbar {
    position: sticky;
    padding: var(--tl-space-4);
  }

  .tl-toolbar__actions {
    justify-content: flex-end;
  }
}
```

**Responsive table card-to-table pattern** (lines 2505-2542, 2770-2811):
```css
/* Mobile-first base: responsive tables stack into labelled cards.
   The desktop layer (min-width: 721px) restores the real table. */
.tl-table-wrap .tl-table--responsive {
  min-width: 0;
}

.tl-table--responsive thead {
  display: none;
}

.tl-table--responsive,
.tl-table--responsive tbody,
.tl-table--responsive tr,
.tl-table--responsive td {
  display: block;
  width: 100%;
}

.tl-table--responsive td {
  display: grid;
  grid-template-columns: minmax(96px, 30%) minmax(0, 1fr);
  gap: var(--tl-space-2);
  padding: var(--tl-space-1) 0;
  border-bottom: 0;
}

.tl-table--responsive td::before {
  content: attr(data-label);
  color: var(--tl-color-muted);
  font-size: var(--tl-font-size-label);
  line-height: var(--tl-line-label);
  font-weight: var(--tl-weight-strong);
}

@media (min-width: 721px) {
  .tl-table-wrap .tl-table--responsive {
    min-width: var(--tl-table-min-width);
  }

  .tl-table--responsive thead {
    display: table-header-group;
  }

  .tl-table--responsive td {
    display: table-cell;
    width: auto;
    grid-template-columns: none;
    gap: 0;
    padding: var(--tl-space-2) var(--tl-space-4);
    border-bottom: 1px solid var(--tl-color-border);
  }

  .tl-table--responsive td::before {
    content: none;
  }
}
```

**Drawer phone-first/desktop-side pattern** (lines 2084-2095, 2124-2129, 2747-2750):
```css
.tl-subview {
  position: fixed;
  top: 0;
  right: 0;
  bottom: 0;
  z-index: var(--tl-z-subview);
  width: 100vw;
  min-height: 100dvh;
  overflow: auto;
  background: var(--tl-color-bg);
  box-shadow: var(--tl-shadow-raised);
  animation: tl-drawer-in var(--tl-motion-base) var(--tl-ease-standard);
}

.tl-subview__content {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--tl-space-4);
  padding: var(--tl-space-4);
}

@media (min-width: 721px) {
  .tl-subview {
    top: var(--tl-header-height);
    width: min(var(--tl-drawer-width), 100vw);
    min-height: auto;
  }
}
```

**Recommended Phase 142 edits:**
- Add named breakpoint tokens/comments near existing sizing tokens. CSS custom properties cannot be used directly in `@media`, so keep literal media queries and lock them with source-contract tests.
- Replace the current `481px` and `721px` layer comments/literals only if the plan intentionally moves to Phase 142's accepted scale. Do this once, then update every matching `@media` and contract together.
- Preserve `.tl-topbar__nav` and `.tl-table-wrap` as intentional internal overflow owners. The document root must not own horizontal overflow.

---

### `test/threadline/operator_surface/style_contract_test.exs` (test, transform)

**Analog:** `test/threadline/operator_surface/style_contract_test.exs`

**Source-contract file-read pattern** (lines 5-13):
```elixir
@style_path "lib/threadline/operator_surface/style.ex"

test "operator surface stays dark-only and token-driven" do
  src = File.read!(@style_path)

  assert String.contains?(src, "color-scheme: dark;")
  refute String.contains?(src, "prefers-color-scheme")
  refute String.contains?(src, "color-scheme: light")
end
```

**Scoped section extraction pattern** (lines 93-117):
```elixir
topbar_section =
  src
  |> String.split(".tl-topbar {")
  |> Enum.at(1)
  |> String.split("/* Mobile-first base:")
  |> List.first()

for selector <- [
      ".tl-topbar__nav",
      ".tl-topbar__nav-group",
      ".tl-topbar__nav-label",
      ".tl-topbar__nav-handoff",
      ~s|.tl-topbar .tl-topbar__nav-item[aria-current="page"]|
    ] do
  assert String.contains?(topbar_section, selector)
end

assert String.contains?(topbar_section, "var(--tl-")
refute String.contains?(topbar_section, "@tailwind")
refute Regex.match?(~r/#[0-9a-fA-F]{6}/, topbar_section)
```

**Regex helper pattern for CSS contracts** (lines 383-399):
```elixir
defp assert_selector_uses_animation(src, selector, keyframe) do
  pattern =
    ~r/#{Regex.escape(selector)}[^}]*animation:\s*#{Regex.escape(keyframe)}\s+var\(--tl-motion-[a-z-]+\)\s+var\(--tl-ease-[a-z-]+\)(?:\s+120ms)?(?:\s+both)?\s*;/s

  assert Regex.match?(pattern, src),
         "#{selector} must use #{keyframe} with var(--tl-motion-*) duration and named easing token"
end
```

**Recommended Phase 142 contract tests:**
- Assert breakpoint token declarations exist, for example `--tl-breakpoint-phone: 375px;`, `--tl-breakpoint-tablet: 768px;`, `--tl-breakpoint-desktop: 1280px;` or the exact names selected by the plan.
- Assert `@media (min-width: ...)` literals match the named scale. Prefer a single helper that extracts `Regex.scan(~r/@media \(min-width: (\d+)px\)/, src)`.
- Assert responsive primitives still exist: `.tl-table--responsive td::before`, `content: attr(data-label)`, `.tl-topbar__nav { ... overflow-x: auto`, `.tl-subview { ... width: 100vw`, and desktop restoration for responsive tables.

---

### `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` (test, request-response)

**Analogs:** `operator-home-nav-mobile.spec.ts`, `operator-find-mobile.spec.ts`, `operator-earned-flows.spec.ts`, `operator-motion.spec.ts`

**Imports and credentials pattern** (`operator-home-nav-mobile.spec.ts` lines 1-6):
```typescript
import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

test.use({ viewport: { width: 375, height: 812 }, isMobile: true });
```

For Phase 142, do not use a file-level fixed viewport. Use the same import/login style, but iterate the matrix:
```typescript
const viewports = [
  { name: "phone", width: 375, height: 812, isMobile: true },
  { name: "tablet", width: 768, height: 900, isMobile: false },
  { name: "desktop", width: 1280, height: 900, isMobile: false },
];
```

**Login pattern** (`operator-home-nav-mobile.spec.ts` lines 27-34):
```typescript
async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}
```

**No document overflow pattern** (`operator-home-nav-mobile.spec.ts` lines 36-43):
```typescript
async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}
```

**Reachability pattern** (`operator-home-nav-mobile.spec.ts` lines 57-74):
```typescript
async function expectReachable(locator: Locator) {
  await locator.scrollIntoViewIfNeeded();
  await expect(locator).toBeVisible();
}

async function expectHeaderDestinationsReachable(page: Page) {
  const nav = page.locator(".tl-topbar__nav");
  await expect(nav).toBeVisible();

  for (const group of ["Find", "Verify", "Prove"]) {
    await expectReachable(nav.locator(`.tl-topbar__nav-group[aria-label="${group}"] .tl-topbar__nav-label`));
  }
}
```

**Seeded route discovery pattern** (`operator-earned-flows.spec.ts` lines 39-58):
```typescript
async function discoverTicketReplyRecordId(page: Page) {
  await page.goto(`/audit/timeline?correlation_id=${encodeURIComponent(closeCorrelation)}`);
  await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);
  await page.getByTestId("transaction-link").first().click();
  await expect(page).toHaveURL(/\/audit\/transactions\/[^/]+$/);

  const rowHistoryLink = page
    .getByTestId("transaction-change-row")
    .filter({ hasText: rowTable })
    .getByTestId("row-history-link")
    .first();

  await expect(rowHistoryLink).toBeVisible();
  const href = await rowHistoryLink.getAttribute("href");
  expect(href).not.toBeNull();

  const match = href!.match(new RegExp(`/history/${rowTable}/([^?#/]+)`));
  expect(match, `expected ${rowTable} row-history href, got ${href}`).not.toBeNull();
  return decodeURIComponent(match![1]);
}
```

**Computed-style helper pattern if needed** (`operator-motion.spec.ts` lines 46-62):
```typescript
async function computedStyle(locator: Locator, pseudoElement?: string): Promise<StyleSnapshot> {
  await expect(locator).toBeVisible();

  return locator.evaluate(
    (element, pseudo) => {
      const style = getComputedStyle(element, pseudo || undefined);

      return {
        animationName: style.animationName,
        animationDuration: style.animationDuration,
        animationDelay: style.animationDelay,
        transform: style.transform,
        transitionDuration: style.transitionDuration,
      };
    },
    pseudoElement,
  );
}
```

**Recommended Phase 142 E2E shape:**
- Log in once per test or per viewport group using the existing `beforeEach` style. Avoid storage-state infrastructure churn.
- For each viewport, call `page.setViewportSize({ width, height })` after login or create nested `test.describe` groups with `test.use`.
- Visit the Phase 142 route matrix from `142-CONTEXT.md`: `/audit`, `/audit/timeline`, `/audit/coverage`, seeded transaction route, seeded row route, seeded actor route, `/audit/evidence`, `/audit/policy/redaction`, `/audit/policy/retention`, `/audit/exports`.
- Assert `expectNoHorizontalOverflow(page)` on every route at 375, 768, and 1280.
- Add key reachability checks per screen: nav links, Timeline filters/apply, first transaction link, row-history drawer close/snapshot input, coverage remediation command, evidence proof action, redaction details, retention prune, exports download/reopen source search.
- Do not add screenshot baselines; Phase 142 context defers screenshot-diff infrastructure to Phase 143.

---

### `lib/threadline/operator_surface/components/surface_header.ex` (component, request-response)

**Analog:** `lib/threadline/operator_surface/components/surface_header.ex`

**Header/nav markup pattern** (lines 30-55):
```elixir
<a class="tl-skip-link" href="#tl-main">Skip to main content</a>
<header class="tl-topbar" data-testid="operator-header">
  <a class="tl-topbar__brand" href={@base_path || "#"}>Threadline</a>
  <nav class="tl-topbar__nav" aria-label="Operator surface">
    <div class="tl-topbar__nav-group" aria-label="Find">
      <span class="tl-topbar__nav-label">Find</span>
      <.nav_link href={timeline_path(@base_path)} current={@current} page={:timeline}>Timeline</.nav_link>
    </div>
    <div :if={@coverage_enabled} class="tl-topbar__nav-group" aria-label="Verify">
      <span class="tl-topbar__nav-label">Verify</span>
      <.nav_link href={"#{@base_path}/coverage"} current={@current} page={:coverage}>Coverage</.nav_link>
    </div>
  </nav>
</header>
```

**Stable nav test ID pattern** (lines 85-95):
```elixir
defp nav_link(assigns) do
  ~H"""
  <a
    href={@href || "#"}
    class={["tl-topbar__nav-item", @current == @page && "tl-topbar__nav-item--active"]}
    aria-current={if @current == @page, do: "page", else: nil}
    data-testid={"operator-nav-#{@page}"}
  >
    <%= render_slot(@inner_block) %>
  </a>
  """
end
```

**Phase 142 guidance:** preserve the scrollable grouped nav contract. If CSS changes touch topbar sizing, keep `operator-nav-*` test IDs and `aria-current="page"` as the browser-test hooks.

---

### `lib/threadline/operator_surface/live/timeline_live.ex` (component, request-response)

**Analog:** `lib/threadline/operator_surface/live/timeline_live.ex`

**Toolbar/filter markup pattern** (lines 373-435):
```elixir
<header class="tl-toolbar">
  <form id="timeline-filters" phx-submit="apply" role="search" class="tl-toolbar__form">
    <label class="tl-toolbar__field">From
      <input type="datetime-local" name="filter[from]" id="filter-from"
             aria-label="from" value={@filters_raw["from"] || ""} phx-debounce="blur" class="tl-toolbar__control" />
    </label>
    <label class="tl-toolbar__field tl-toolbar__field--wide">Correlation id
      <input type="text" name="filter[correlation_id]" id="filter-correlation-id"
             aria-label="correlation id"
             value={@filters_raw["correlation_id"] || ""}
             maxlength="256" phx-debounce="300" class="tl-toolbar__control" />
      <small class="tl-toolbar__hint">request_id, job_id, or integration token. Up to 256 chars.</small>
    </label>
    <div class="tl-toolbar__actions">
      <div class="tl-action-group">
        <.link patch={@timeline_path} class="tl-button tl-button--ghost">Clear all</.link>
        <button type="submit" class="tl-button tl-button--primary">Apply</button>
      </div>
    </div>
  </form>
</header>
```

**Phase 142 guidance:** toolbar controls should stack on phone, wrap at tablet, and align compactly on desktop by CSS. Avoid per-field bespoke widths unless a measured overflow failure proves it.

---

### Responsive table LiveViews (components, CRUD/transform)

**Analogs:** `coverage_live.ex`, `retention_history_live.ex`, `policy_redaction_live.ex`

**Coverage responsive table/data-label pattern** (`coverage_live.ex` lines 176-216):
```elixir
<div class="tl-table-wrap" data-testid="coverage-table">
  <table class="tl-table tl-table--coverage tl-table--compact tl-table--sticky tl-table--actionable tl-table--responsive">
    <thead>
      <tr><th>TABLE</th><th>STATUS</th><th>SOURCE</th><th>Actions</th></tr>
    </thead>
    <tbody>
      <tr class="tl-table__row--uncovered">
        <td data-label="TABLE"><code><%= table %></code></td>
        <td data-label="STATUS"><span class="tl-chip tl-chip--danger">Needs capture</span></td>
        <td data-label="SOURCE">missing trigger</td>
        <td data-label="Actions" class="tl-table__actions">
          <span class="tl-remediation__action"><%= remediation.label %></span>
          <code :if={remediation.command} class="tl-remediation__command"><%= remediation.command %></code>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

**Retention stream table/data-label pattern** (`retention_history_live.ex` lines 151-181):
```elixir
<div class="tl-table-wrap" data-testid="retention-runs-table">
  <table class="tl-table tl-table--retention tl-table--compact tl-table--sticky tl-table--responsive">
    <thead>
      <tr>
        <th>Status</th>
        <th>Deleted Rows</th>
        <th>Duration</th>
        <th>Date</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody id="retention-runs" phx-update="stream" data-testid="retention-runs">
      <tr :for={{dom_id, run} <- @streams.runs} id={dom_id} class={["tl-table__row--" <> run.status, if(run.status == "failed", do: "tl-target-row")]}>
        <td data-label="Status"><span class={["tl-chip", Presentation.status_modifier(run.status)]}><%= Presentation.status_label(run.status) %></span></td>
        <td data-label="Deleted Rows" class="tl-table__number"><%= count_label(run.deleted_count) %></td>
        <td data-label="Duration" class="tl-table__number"><%= duration_label(run.duration_ms) %></td>
      </tr>
    </tbody>
  </table>
</div>
```

**Phase 142 guidance:** if a table-like surface fails at 375px, first add/repair `tl-table--responsive` and `data-label` in markup, then tune the shared CSS. Do not introduce one-off horizontal document overflow.

---

### `lib/threadline/operator_surface/live/row_history_component.ex` (component, request-response)

**Analog:** `lib/threadline/operator_surface/live/row_history_component.ex`

**Subview/drawer markup pattern** (lines 70-123):
```elixir
<div class="tl-subview-shell" id={"#{@id}-shell"}>
  <div class="tl-subview-backdrop" aria-hidden="true"></div>
  <div
    class="tl-subview"
    id={@id}
    role="dialog"
    aria-modal="true"
    aria-labelledby={"#{@id}-title"}
    tabindex="-1"
    data-testid="row-history-drawer"
  >
    <div class="tl-subview__header">
      <div>
        <h3 class="tl-subview__title" id={"#{@id}-title"} title={"#{@table} / #{@record_id}"}>
          Row history: <%= @table %> / <%= Presentation.short_id(@record_id, 14) %>
        </h3>
      </div>
      <.link patch={@close_path} class="tl-button tl-button--secondary">Close</.link>
    </div>

    <div class="tl-subview__content">
      <div class="tl-subview__panel">
        <h4 class="tl-subview__panel-title">Row timeline</h4>
        <form phx-change="update-as-of" phx-target={@myself}>
          <label class="tl-toolbar__field">View snapshot at
            <input type="datetime-local" name="as_of" value={format_dt(@as_of_dt)} class="tl-control" />
          </label>
        </form>
      </div>
    </div>
  </div>
</div>
```

**Phase 142 guidance:** test drawer fit at 375px using `row-history-drawer`, the Close button, snapshot input, and visible redacted/long values. Keep desktop side-drawer width controlled by `--tl-drawer-width`.

## Shared Patterns

### Breakpoint Governance

**Source:** `style.ex` lines 126-160 and `style_contract_test.exs` lines 5-13.

Apply to: `style.ex`, `style_contract_test.exs`, responsive E2E spec.

Rules:
- Put responsive scale names in the root token area.
- Keep `@media (min-width: Npx)` literal and standards-compliant.
- Add source-contract tests that prove literals and named tokens stay aligned.
- Phase 142 accepted viewport matrix is `375 / 768 / 1280`.

### Root Overflow

**Source:** `operator-home-nav-mobile.spec.ts` lines 36-43; same helper appears in Find/Prove/Earned specs.

Apply to: all responsive matrix route checks.

```typescript
async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}
```

### Intentional Internal Scroll Exceptions

**Source:** `style.ex` lines 283-291 and 1517-1527.

Apply to: topbar and table wrappers only.

```css
.tl-topbar__nav {
  min-width: 0;
  overflow-x: auto;
}

.tl-table-wrap {
  overflow-x: auto;
}

.tl-table-wrap .tl-table {
  min-width: var(--tl-table-min-width);
}
```

### Selector Precision

**Source:** `139-03-SUMMARY.md` lines 87-100.

Pitfall:
- Ambiguous Home text selectors caused failures. Use `exact: true`, scoped locators, `data-testid`, and role selectors with exact names where there are repeated labels such as `Exports`, `Prove`, or redacted values.

### Deterministic Seeded Routes

**Source:** `operator-find-mobile.spec.ts` lines 83-91 and `operator-earned-flows.spec.ts` lines 39-58.

Apply to: transaction, row-history, actor, and exports context checks.

Rules:
- Use `walk-acme-4521-close` and `ticket_replies` when a row-history route is needed.
- Discover dynamic transaction/record IDs from links instead of hard-coding generated IDs.
- Assert the URL shape before continuing.

### Motion Preservation

**Source:** `style_contract_test.exs` lines 208-232 and `operator-motion.spec.ts` lines 97-144.

Apply to: any responsive CSS that touches animated selectors.

Rules:
- Do not change motion tokens/keyframes as part of responsive work.
- Keep `prefers-reduced-motion` blanket intact.
- If responsive changes affect `.tl-subview`, verify reduced-motion drawer transform remains non-offscreen.

## Pitfalls To Avoid

| Pitfall | Why It Matters | Pattern To Use Instead |
|---------|----------------|------------------------|
| Replacing scrollable nav with hidden/dropped destinations | Phase 139 locked every destination and group label as reachable at 375px | Keep `.tl-topbar__nav` as explicit scroll owner and test `operator-nav-*` links |
| Adding CSS custom properties directly inside media queries | CSS variables are not valid in standard media query conditions | Pair named tokens/comments with literal `@media (min-width: Npx)` and source-contract tests |
| Testing only 375px mobile specs | Phase 142 acceptance is 375, 768, and 1280 | Use one matrix spec over all routes and widths |
| Allowing `.tl-table-wrap` scroll to become document scroll | Internal table scroll is acceptable; root overflow is not | Assert root overflow after every route and keep wrappers scoped |
| Screenshot baselines | Phase 143 owns screenshot-diff infrastructure | Use computed overflow, visibility, reachability, and source contracts |
| Broad redesign | Phase 142 preserves visual language and IA | Adjust layout primitives, wrapping, labels, and scroll ownership only |
| Broad `mix verify.example_browser` failure confusion | Prior Phase 138 saw unrelated legacy browser failures | Report focused responsive spec result separately from broad suite noise |

## Recommended Test Patterns

### ExUnit

- Add one or more tests to `style_contract_test.exs`.
- Read `@style_path` once per test, following existing convention.
- Use scoped extraction for topbar/table/subview sections.
- Lock:
  - breakpoint token names and values;
  - media query literals;
  - responsive table mobile labels and desktop restoration;
  - allowed internal overflow owners;
  - no new `@tailwind`, shadcn markers, light color-scheme, or raw hex in new scoped sections.

### Playwright

- Create `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts`.
- Reuse login, `expectNoHorizontalOverflow`, `expectReachable`, seeded discovery, and path polling helpers from existing specs.
- Matrix routes:
  - `/audit`
  - `/audit/timeline`
  - `/audit/coverage`
  - discovered `/audit/transactions/:id`
  - discovered `/audit/rows/ticket_replies/:record_id`
  - `/audit/actors/service_account/zendesk-sync`
  - `/audit/evidence`
  - `/audit/policy/redaction`
  - `/audit/policy/retention`
  - `/audit/exports`
- Matrix widths: `375`, `768`, `1280`.
- At 375, use `height: 812`; at 768/1280 use stable `height: 900` unless the plan chooses another single height.
- Assertions should be DOM/layout contracts: root overflow, visible main heading/key controls, nav reachability, table/card labels at narrow width, desktop table restoration where applicable.

## No Analog Found

None. Phase 142 can be implemented by extending existing operator-surface CSS, LiveView markup, source-contract tests, and Playwright UAT patterns.

## Metadata

**Analog search scope:** `lib/threadline/operator_surface`, `test/threadline/operator_surface`, `examples/threadline_phoenix/e2e/tests`, prior Phase 137/138/139 summaries.
**Files scanned:** 15 primary files plus targeted `rg` hits.
**Pattern extraction date:** 2026-06-04
