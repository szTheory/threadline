# Phase 139: orientation-hub-home-nav - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 8
**Analogs found:** 8 / 8

## Likely Files Modified

| File | Reason |
|------|--------|
| `lib/threadline/operator_surface/live/start_live.ex` | Home orientation hub copy/cards, health row, saved-view resume affordance |
| `lib/threadline/operator_surface/components/surface_header.ex` | Shared Find / Verify / Prove nav grouping, active states, Prove/Exports separation, destination reachability |
| `lib/threadline/operator_surface/style.ex` | Scoped `.threadline-ui` / `.tl-*` nav and Home CSS primitives, mobile reachability |
| `test/threadline/operator_surface/live/start_live_test.exs` | New focused StartLive/Home tests; listed in scope but currently missing |
| `test/threadline/operator_surface/live/timeline_live_test.exs` | Existing saved-view and header test analogs; extend only if planner keeps shared header assertions here |
| `test/threadline/operator_surface/style_contract_test.exs` | CSS contract checks for token-backed scoped nav/Home primitives and anti-dependency guards |
| `examples/threadline_phoenix/e2e/tests/operator-orientation-mobile.spec.ts` | New focused mobile browser spec, or equivalent extension to existing mobile specs |
| `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` | Existing 375px/no-overflow helper pattern to copy if extending instead of creating a new spec |
| `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts` | Existing Prove-cluster 375px/no-overflow assertions to copy for destination reachability |

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/live/start_live.ex` | component | request-response | `lib/threadline/operator_surface/live/start_live.ex` | exact-existing |
| `lib/threadline/operator_surface/components/surface_header.ex` | component | request-response | `lib/threadline/operator_surface/components/surface_header.ex` | exact-existing |
| `lib/threadline/operator_surface/style.ex` | utility | transform | `lib/threadline/operator_surface/style.ex` | exact-existing |
| `test/threadline/operator_surface/live/start_live_test.exs` | test | request-response | `test/threadline/operator_surface/live/timeline_live_test.exs` | role-match |
| `test/threadline/operator_surface/style_contract_test.exs` | test | transform | `test/threadline/operator_surface/style_contract_test.exs` | exact-existing |
| `examples/threadline_phoenix/e2e/tests/operator-orientation-mobile.spec.ts` | test | request-response | `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` | role-match |
| `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` | test | request-response | same file | exact-existing |
| `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts` | test | request-response | same file | exact-existing |

## Pattern Assignments

### `lib/threadline/operator_surface/live/start_live.ex` (component, request-response)

**Analog:** `lib/threadline/operator_surface/live/start_live.ex`

**Imports pattern** (lines 5-11):
```elixir
use Phoenix.LiveView
import Ecto.Query

alias Threadline.Governance.ExportJob
alias Threadline.Governance.RetentionRun
alias Threadline.Governance.SavedView
alias Threadline.OperatorSurface.Exports.FilterParams
```

**Mount/params pattern** (lines 30-48):
```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:base_path, nil)
   |> assign(:health, [])
   |> assign(:health_enabled, false)
   |> assign(:saved_views, [])}
end

def handle_params(_params, uri, socket) do
  base_path = URI.parse(uri).path || ""

  {:noreply,
   socket
   |> assign(:base_path, base_path)
   |> assign(:health, health_warnings(socket))
   |> assign(:health_enabled, any_subsystem_enabled?(socket))
   |> assign(:saved_views, fetch_saved_views(socket))}
end
```

**Header integration pattern** (lines 61-72):
```elixir
<div class="threadline-ui">
  <Threadline.OperatorSurface.Style.css />
  <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
    coverage={@threadline_coverage}
    base_path={@base_path}
    error={@threadline_coverage_error}
    coverage_enabled={@threadline_coverage_enabled}
    policy_enabled={@threadline_policy_enabled}
    evidence_enabled={@threadline_evidence_enabled}
    exports_enabled={@threadline_exports_enabled}
    current={:start}
  />
```

**Home card/saved-view pattern** (lines 94-145):
```elixir
<ul class="tl-home__cards">
  <li class="tl-home__card tl-home__card--primary">
    <span class="tl-home__card-kicker">Find</span>
    <h2 class="tl-home__card-title">What changed?</h2>
    <a href={"#{@base_path}/timeline"} class="tl-button tl-button--primary">
      Open the timeline
    </a>
  </li>
  ...
  <section :if={@saved_views != []} class="tl-home__resume" aria-label="Saved searches">
    <h2 class="tl-home__section-title">Pick up where you left off</h2>
    <ul class="tl-home__views">
      <li :for={view <- @saved_views}>
        <.link navigate={saved_view_path(@base_path, view)} class="tl-chip tl-chip--accent tl-home__view">
          <%= view.name %>
        </.link>
      </li>
    </ul>
  </section>
```

**Fail-safe data pattern** (lines 194-263):
```elixir
defp failed_export_count(socket) do
  actor_ref = socket.assigns[:threadline_actor_ref]
  repo = resolve_repo(socket)

  if actor_ref && repo do
    try do
      repo.aggregate(
        from(j in ExportJob, where: j.status == "failed" and j.actor_ref == ^actor_ref),
        :count
      )
    rescue
      _ -> nil
    end
  end
end

defp fetch_saved_views(socket) do
  actor_ref = socket.assigns[:threadline_actor_ref]
  repo = resolve_repo(socket)

  if actor_ref && repo do
    try do
      repo.all(from(v in SavedView, where: v.actor_ref == ^actor_ref, order_by: [desc: v.inserted_at], limit: 6))
    rescue
      _ -> []
    end
  else
    []
  end
end
```

### `lib/threadline/operator_surface/components/surface_header.ex` (component, request-response)

**Analog:** `lib/threadline/operator_surface/components/surface_header.ex`

**Attr/API pattern** (lines 16-26):
```elixir
use Phoenix.Component

attr(:coverage, :map, required: true)
attr(:base_path, :string, required: true)
attr(:error, :string, default: nil)
attr(:coverage_enabled, :boolean, default: false)
attr(:policy_enabled, :boolean, default: false)
attr(:evidence_enabled, :boolean, default: false)
attr(:exports_enabled, :boolean, default: false)
attr(:current, :atom, default: nil)
attr(:scoped, :boolean, default: false)
```

**Nav grouping pattern** (lines 30-52):
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
    <div :if={@evidence_enabled or @policy_enabled or @exports_enabled} class="tl-topbar__nav-group" aria-label="Prove">
      <span class="tl-topbar__nav-label">Prove</span>
      <.nav_link :if={@evidence_enabled} href={"#{@base_path}/evidence"} current={@current} page={:evidence}>Evidence</.nav_link>
      <.nav_link :if={@policy_enabled} href={"#{@base_path}/policy/redaction"} current={@current} page={:policy}>Redaction</.nav_link>
      <.nav_link :if={@policy_enabled} href={"#{@base_path}/policy/retention"} current={@current} page={:retention}>Retention</.nav_link>
      <.nav_link :if={@exports_enabled} href={"#{@base_path}/exports"} current={@current} page={:exports}>Exports</.nav_link>
    </div>
  </nav>
```

**Active-state pattern** (lines 83-93):
```elixir
<a
  href={@href || "#"}
  class={["tl-topbar__nav-item", @current == @page && "tl-topbar__nav-item--active"]}
  aria-current={if @current == @page, do: "page", else: nil}
  data-testid={"operator-nav-#{@page}"}
>
  <%= render_slot(@inner_block) %>
</a>
```

**Existing page current assignments to preserve**:

| Source | Lines | Current |
|--------|-------|---------|
| `lib/threadline/operator_surface/live/coverage_live.ex` | 96-105 | `current={:coverage}` |
| `lib/threadline/operator_surface/live/export_status_live.ex` | 57-65 | `current={:exports}` |
| `lib/threadline/operator_surface/live/timeline_live.ex` | 318-326 | `current={:timeline}` |
| `lib/threadline/operator_surface/live/transaction_live.ex` | 88-96 | `current={:timeline}` |
| `lib/threadline/operator_surface/live/actor_live.ex` | 90-98 | `current={:timeline}` |
| `lib/threadline/operator_surface/live/evidence_live.ex` | 55-63 | `current={:evidence}` |
| `lib/threadline/operator_surface/live/policy_redaction_live.ex` | 46-54 | `current={:policy}` |
| `lib/threadline/operator_surface/live/retention_history_live.ex` | 75-82 | `current={:retention}` |

### `lib/threadline/operator_surface/style.ex` (utility, transform)

**Analog:** `lib/threadline/operator_surface/style.ex`

**Scoped token/root pattern** (lines 161-210):
```css
.threadline-ui {
  min-height: 100%;
  color-scheme: dark;
  font-family: var(--tl-font-family);
  color: var(--tl-color-text);
  background: var(--tl-color-bg);
}

.threadline-ui *,
.threadline-ui *::before,
.threadline-ui *::after {
  box-sizing: border-box;
}

.threadline-ui a:focus-visible,
.threadline-ui summary:focus-visible {
  box-shadow: var(--tl-focus-ring);
}
```

**Mobile-first nav reachability pattern** (lines 250-350):
```css
.tl-topbar {
  position: sticky;
  top: 0;
  z-index: var(--tl-z-header);
  min-height: var(--tl-header-height-mobile);
  display: flex;
  flex-wrap: wrap;
  gap: var(--tl-space-2);
}

.tl-topbar__nav {
  display: flex;
  order: 2;
  flex: 1 1 auto;
  min-width: 0;
  overflow-x: auto;
  scrollbar-width: none;
}

.tl-topbar__nav-group {
  display: inline-flex;
  min-width: max-content;
}

.tl-topbar .tl-topbar__nav-item[aria-current="page"] {
  background: var(--tl-color-accent-soft);
  color: var(--tl-color-accent-strong);
  border-color: var(--tl-color-accent-border);
}
```

**Home primitives pattern** (lines 385-556):
```css
.tl-home {
  max-width: 1000px;
  margin: 0 auto;
}

.tl-home__cards {
  list-style: none;
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--tl-space-4);
}

.tl-home__card {
  display: flex;
  flex-direction: column;
  gap: var(--tl-space-3);
  padding: var(--tl-space-5);
  background: var(--tl-color-surface);
  border: 1px solid var(--tl-color-border);
  border-radius: var(--tl-radius-lg);
}

.tl-home__views {
  list-style: none;
  display: flex;
  flex-wrap: wrap;
  gap: var(--tl-space-2);
}
```

**Responsive layering pattern** (lines 2536-2654):
```css
@media (min-width: 481px) {
  .tl-page {
    padding: var(--tl-space-3);
  }

  .tl-topbar .tl-topbar__nav-item {
    min-height: var(--tl-control-height-compact);
  }
}

@media (min-width: 721px) {
  .tl-home__cards {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .tl-topbar {
    min-height: var(--tl-header-height);
    flex-wrap: nowrap;
  }

  .tl-topbar__nav-label {
    display: inline;
  }
}
```

### `test/threadline/operator_surface/live/start_live_test.exs` (test, request-response)

**Analog:** `test/threadline/operator_surface/live/timeline_live_test.exs`

**Test harness pattern** (lines 21-40, 83-98, 243-275):
```elixir
defmodule Threadline.OperatorSurface.TimelineLiveTest.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  require Threadline.OperatorSurface.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {Threadline.OperatorSurface.TimelineLiveTest.Layouts, :root})
  end

  scope "/" do
    pipe_through(:browser)
    Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
  end
end

@endpoint Threadline.OperatorSurface.TimelineLiveTest.Endpoint

setup do
  Threadline.Test.Repo.delete_all(Threadline.Governance.SavedView)
  Threadline.Test.Repo.delete_all(Threadline.Governance.ExportJob)
  {:ok, conn: Phoenix.ConnTest.build_conn()}
end
```

**Home route analog:** `lib/threadline/operator_surface/router.ex` lines 99-105 prove `/audit` is `StartLive`, with sibling nav destinations:
```elixir
live("/", StartLive, :index)
live("/timeline", TimelineLive, :index)
live("/evidence", EvidenceLive, :index)
live("/coverage", CoverageLive, :index)
live("/exports", ExportStatusLive, :index)
live("/policy/redaction", PolicyRedactionLive, :index)
live("/policy/retention", RetentionHistoryLive, :index)
```

**Header assertion analog** (coverage test lines 181-189):
```elixir
test "renders the surface header above the page content", %{conn: conn} do
  {:ok, _view, html} = live(conn, "/audit/coverage")

  assert html =~ ~s|class="tl-topbar"|
  assert html =~ ~s|href="/audit/coverage"|
end
```

**Saved-view test analog** (timeline test lines 949-968):
```elixir
test "default actor_fn mount path exposes actor-owned saved views", %{conn: conn} do
  {:ok, lv, _html} = mount_actor_audit(conn, "/audit_actor/timeline?table=posts")

  assert render(lv) =~ "Save View"

  lv
  |> form("#save-view-form", %{name: "Actor View"})
  |> render_submit()

  assert render(lv) =~ "Actor View"

  view = Threadline.Test.Repo.get_by!(Threadline.Governance.SavedView, name: "Actor View")
  assert view.filters["table"] == "posts"
  assert view.actor_ref == %Threadline.Semantics.ActorRef{type: :user, id: "actor-1"}
end
```

**Recommended Phase 139 assertions:**

- `live(conn, "/audit")` renders Threadline/Home headline, Find card, Verify card when coverage enabled, Prove links when feature flags allow them.
- SavedView rows for the current actor render "Pick up where you left off" and link to `/audit/timeline?...`.
- SavedView rows for other actors do not render.
- Header contains all enabled destinations: Timeline, Coverage, Evidence, Redaction, Retention, Exports.
- Exactly one active nav item has `aria-current="page"` on destination pages; Home should not mark Timeline active unless the component intentionally adds a Home nav item.

### `test/threadline/operator_surface/style_contract_test.exs` (test, transform)

**Analog:** `test/threadline/operator_surface/style_contract_test.exs`

**String contract pattern** (lines 7-24):
```elixir
test "operator surface stays dark-only and token-driven" do
  src = File.read!(@style_path)

  assert String.contains?(src, "color-scheme: dark;")
  refute String.contains?(src, "prefers-color-scheme")
  refute String.contains?(src, "color-scheme: light")
end
```

**Scoped-section contract pattern** (lines 73-86):
```elixir
find_section =
  src
  |> String.split("/* Find cluster primitives")
  |> List.last()
  |> String.split("/* End Find cluster primitives */")
  |> List.first()

assert String.contains?(find_section, "var(--tl-")
refute String.contains?(find_section, "prefers-color-scheme")
refute String.contains?(find_section, "color-scheme: light")
refute String.contains?(find_section, "@tailwind")
refute String.contains?(find_section, "from shadcn")
refute Regex.match?(~r/#[0-9a-fA-F]{6}/, find_section)
```

**Recommended Phase 139 contract additions:**

- Assert `.tl-topbar__nav`, `.tl-topbar__nav-group`, `.tl-topbar__nav-label`, `.tl-topbar__nav-item[aria-current="page"]`, and any Prove/Exports separator class are present.
- Assert Home classes remain token-backed: `.tl-home__cards`, `.tl-home__card`, `.tl-home__resume`, `.tl-home__views`.
- Refute `@tailwind`, `from shadcn`, `prefers-color-scheme`, `color-scheme: light`, and raw hex colors in any new Phase 139 section.

### `examples/threadline_phoenix/e2e/tests/operator-orientation-mobile.spec.ts` (test, request-response)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` and `operator-prove-mobile.spec.ts`

**Mobile setup/no-overflow helper** (find spec lines 1-25):
```typescript
import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

test.use({ viewport: { width: 375, height: 812 }, isMobile: true });

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}
```

**Visible hierarchy + no-overflow pattern** (prove spec lines 38-68):
```typescript
await page.goto("/audit/exports");
await expect(page.getByText("What's ready to hand off?")).toBeVisible();

const exportJobs = page.getByTestId("export-jobs");
for (const heading of ["Ready to hand off", "Preparing", "Needs attention", "Unavailable"]) {
  await expect(exportJobs.getByRole("heading", { name: heading, exact: true })).toBeVisible();
}

await expect(page.getByRole("link", { name: "Reopen source search" }).first()).toBeVisible();
await expectNoHorizontalOverflow(page);
```

**Recommended Phase 139 mobile assertions:**

- At 375px, after `page.goto("/audit")`, Home headline, Find, Verify, Prove, and saved-view resume content are visible or reachable without horizontal document overflow.
- At 375px, header/nav keeps every enabled destination reachable: Timeline, Coverage, Evidence, Redaction, Retention, Exports.
- If nav remains horizontally scrollable, assert the nav element is the scroll container and document root has no horizontal overflow.
- Assert Exports remains visible/reachable as the Prove handoff destination and is not dropped when Retention is present.

## Shared Patterns

### Authentication / Route Mounting

**Source:** `lib/threadline/operator_surface/router.ex` lines 90-105
**Apply to:** LiveView tests and mobile specs

The operator surface routes are mounted under one `live_session :threadline` with `Auth` and `Coverage.OnMount`; Phase 139 should not add new routes for Home orientation.

```elixir
live_session :threadline,
  on_mount: [
    {Threadline.OperatorSurface.Auth, unquote(opts)},
    {Threadline.OperatorSurface.Coverage.OnMount, unquote(opts)}
  ] do
  scope unquote(path), alias: Threadline.OperatorSurface.Live do
    live("/", StartLive, :index)
    live("/timeline", TimelineLive, :index)
    live("/evidence", EvidenceLive, :index)
    live("/coverage", CoverageLive, :index)
    live("/exports", ExportStatusLive, :index)
    live("/policy/redaction", PolicyRedactionLive, :index)
    live("/policy/retention", RetentionHistoryLive, :index)
  end
end
```

### Feature-Flag-Aware Destinations

**Source:** `surface_header.ex` lines 38-51 and `start_live.ex` lines 107-130
**Apply to:** Header and Home tests

Use existing `coverage_enabled`, `policy_enabled`, `evidence_enabled`, and `exports_enabled` assigns to decide visibility. Tests should verify destinations are preserved when enabled, not hard-code unavailable links.

### CSS Scoping

**Source:** `style.ex` lines 161-210 and `style_contract_test.exs` lines 73-86
**Apply to:** All CSS changes

Keep CSS inside `Threadline.OperatorSurface.Style`, scoped under `.threadline-ui` or `.tl-*`, token-backed via `var(--tl-*)`, dark-only, and dependency-free.

## Anti-Patterns To Avoid

| Anti-Pattern | Why It Is Out Of Scope |
|--------------|------------------------|
| Dropping nav destinations on mobile | Violates D-05/F-303; Retention, Exports, labels, scope, and health affordances must remain reachable at 375px |
| Implementing Phase 140 flows | Record-first lookup, correlation-id paste/deep-link, closed export loop, and first-class row-history route are deferred |
| Broad responsive redesign | Phase 139 only owns local Home/nav reachability; broader mobile sweep is Phase 142 |
| New dependencies | No Tailwind, shadcn, icon package, or browser/CSS dependency additions; use existing Phoenix/LiveView/Playwright setup |
| Backend/query/schema/route expansion | Context forbids modifying `Threadline.Query`, export schemas, routes, or backend APIs for this phase |
| Unscoped CSS or raw colors | Violates dark-first scoped style contract; use `.threadline-ui` / `.tl-*` and tokens |
| Renaming IA wholesale | Keep Find / Verify / Prove nav labels stable; Home copy may clarify persona jobs without replacing IA |

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `test/threadline/operator_surface/live/start_live_test.exs` | test | request-response | File is referenced by scope but does not exist yet; use `TimelineLiveTest` harness and saved-view tests as analog |
| `examples/threadline_phoenix/e2e/tests/operator-orientation-mobile.spec.ts` | test | request-response | No dedicated Home/nav mobile spec yet; copy helpers/assertion style from existing Find/Prove mobile specs |

## Metadata

**Analog search scope:** `lib/threadline/operator_surface`, `test/threadline/operator_surface`, `examples/threadline_phoenix/test`, `examples/threadline_phoenix/e2e/tests`
**Files scanned:** 40+
**Pattern extraction date:** 2026-06-04
