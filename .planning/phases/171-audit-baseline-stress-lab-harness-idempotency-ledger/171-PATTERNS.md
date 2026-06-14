# Phase 171: Audit Baseline, Stress-Lab Harness & Idempotency Ledger - Pattern Map

**Mapped:** 2026-06-14  
**Files analyzed:** 17 target groups  
**Analogs found:** 17 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/operator_surface/stress_router.ex` | route | request-response | `lib/threadline/operator_surface/router.ex` | exact |
| `lib/threadline/operator_surface/auth.ex` | middleware | request-response | existing file | exact |
| `lib/threadline/operator_surface/live/stress_live.ex` | component | request-response | `lib/threadline/operator_surface/live/start_live.ex` | exact |
| `lib/threadline/operator_surface/stress_fixtures.ex` | service | transform | `lib/threadline/operator_surface/presentation.ex`; `start_live.ex` helper style | role-match |
| `lib/threadline/operator_surface/stress_ledger.ex` or Mix helper | utility | file-I/O, transform | `test/threadline/brandbook_token_parity_test.exs` | partial |
| `lib/threadline/operator_surface/components/*.ex` | component | request-response | `surface_header.ex`, `icon.ex`, `unsupported_view.ex` | exact |
| `DESIGN-SYSTEM.md` | docs | transform | `.planning/milestones/v1.31-phases/141-motion-micro-animation/141-MOTION-INVENTORY.md`; `brandbook/pressure-test.md` gates | role-match |
| `.planning/design-system-ledger.json` or grouped ledger path | config | file-I/O | `brandbook/tokens.json` + parity tests | role-match |
| `test/threadline/operator_surface/stress_router_test.exs` | test | request-response | `test/threadline/operator_surface/router_test.exs` | exact |
| `test/threadline/operator_surface/stress_fixtures_test.exs` | test | transform | `test/threadline/operator_surface/surface_header_test.exs` | role-match |
| `test/threadline/operator_surface/stress_ledger_test.exs` | test | file-I/O, transform | `test/threadline/brandbook_token_parity_test.exs`; `style_contract_test.exs` | exact |
| `test/threadline/operator_surface/*_test.exs` | test | request-response | `auth_test.exs`, `live/start_live_test.exs` | exact |
| `test/threadline/brandbook_token_parity_test.exs` | test | file-I/O, transform | existing file | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | route | request-response | existing `/audit` mount | exact |
| `examples/threadline_phoenix/e2e/playwright.config.ts` | config | request-response | existing config | exact |
| `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` | test | request-response, file-I/O screenshots | `operator-accessibility.spec.ts`, `operator-screenshot-regression.spec.ts` | exact |
| `mix.exs` optional alias | config | batch | existing `verify.example_browser*` aliases | exact |

## Pattern Assignments

### `lib/threadline/operator_surface/stress_router.ex` (route, request-response)

**Analog:** `lib/threadline/operator_surface/router.ex`

**Imports and compile guard pattern** (lines 1-2, 58-74):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Router do
    defmacro threadline_operator_surface(path, opts \\ []) do
      theme = Keyword.get(opts, :theme, :dark)
      caller_file = __CALLER__.file
      caller_line = __CALLER__.line

      unless theme in [:dark, :light, :system] do
        raise CompileError,
          file: caller_file,
          line: caller_line,
          description: "Threadline Operator Surface theme must be one of :dark | :light | :system"
      end
```

**Core route macro pattern** (lines 93-123):
```elixir
import Phoenix.LiveView.Router, only: [live_session: 3, live: 3]

live_session :threadline,
  on_mount: [
    {Threadline.OperatorSurface.Auth, unquote(opts)},
    {Threadline.OperatorSurface.Coverage.OnMount, unquote(opts)}
  ] do
  scope unquote(path), alias: Threadline.OperatorSurface.Live do
    live("/", StartLive, :index)
    live("/timeline", TimelineLive, :index)
  end
end
```

Copy this shape but use a separate module/name, `live_session :threadline_stress`, and a stress scope mounted at `/audit/__stress`. Preserve the alias hygiene comment pattern from lines 136-151 and use `as: false` where the stress scope would otherwise leak helpers or collide.

### `lib/threadline/operator_surface/auth.ex` (middleware, request-response)

**Analog:** existing `lib/threadline/operator_surface/auth.ex`

**Assign/auth pattern** (lines 9-24):
```elixir
def on_mount(opts, _params, session, socket) do
  authorize_fn = Keyword.get(opts, :authorize_fn, fn _socket -> true end)
  scope_query_fn = Keyword.get(opts, :scope_query_fn)
  repo = Keyword.get(opts, :repo)
  schemas = Keyword.get(opts, :schemas, %{})
  theme = Keyword.get(opts, :theme, :dark) |> normalize_theme()

  socket =
    socket
    |> maybe_assign_session_user(session)
    |> maybe_assign_session_actor(session)
    |> Phoenix.Component.assign(:threadline_theme, theme)
    |> Phoenix.Component.assign(:threadline_repo, repo)
    |> Phoenix.Component.assign(:threadline_schemas, schemas)
    |> Phoenix.Component.assign(:threadline_scope_query_fn, scope_query_fn)
```

**Fail-closed feature gates** (lines 209-233, 235-285):
```elixir
coverage_authorize_fn = Keyword.get(opts, :coverage_authorize_fn, fn _ -> false end)

case coverage_authorize_fn.(mirror) do
  :ok -> true
  true -> true
  {:ok, _scope} -> true
  _ -> false
end
rescue
  _ -> false
```

Stress route must reuse this hook; add new assigns only if the stress LiveView needs them, and keep defaults fail-closed.

### `lib/threadline/operator_surface/live/stress_live.ex` (component, request-response)

**Analog:** `lib/threadline/operator_surface/live/start_live.ex`

**Mount/params pattern** (lines 31-53):
```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:base_path, nil)
   |> assign(:health, [])
   |> assign(:health_enabled, false)}
end

def handle_params(_params, uri, socket) do
  base_path = URI.parse(uri).path || ""

  {:noreply,
   socket
   |> assign(:base_path, base_path)
   |> assign(:health, health_warnings(socket))}
end
```

For stress selection, validate `params["story"]`, `category`, `theme`, and viewport against `StressFixtures` allowlists in `handle_params/3`; never convert user params to atoms.

**Shell/theme render pattern** (lines 116-131):
```elixir
~H"""
<div class="threadline-ui" data-tl-theme={@threadline_theme}>
  <Threadline.OperatorSurface.Style.css />
  <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
    coverage={@threadline_coverage}
    base_path={@base_path}
    current={:start}
    scoped={not is_nil(assigns[:threadline_scope])}
  />

  <main id="tl-main" class="tl-page tl-home" tabindex="-1">
"""
```

Stress Live should use the same wrapper, style component, header, `#tl-main`, and `data-tl-theme`.

**Fail-safe read pattern** (lines 365-429):
```elixir
if actor_ref && repo do
  try do
    repo.all(query, StorageSchema.repo_opts())
  rescue
    _ -> []
  end
else
  []
end
```

Use static fixtures as primary truth; if the stress lab reads optional runtime metadata, degrade to empty/error fixture states instead of crashing the lab.

### `lib/threadline/operator_surface/components/*.ex` (component, request-response)

**Analog:** `surface_header.ex`

**Component attrs and semantic nav pattern** (lines 16-29, 67-81, 108-124):
```elixir
use Phoenix.Component

attr(:coverage, :map, required: true)
attr(:base_path, :string, required: true)
attr(:current, :atom, default: nil)

def surface_header(assigns) do
  ~H"""
  <nav class="tl-shell-nav" data-testid="operator-nav-shell" aria-label="Operator surface">
    <.nav_link href={home_path(@base_path)} current={@current} page={:start}>
      Overview
    </.nav_link>
  </nav>
  """
end
```

**Private slot/link pattern** (lines 108-124):
```elixir
attr(:href, :string, required: true)
attr(:current, :atom, default: nil)
attr(:page, :atom, required: true)
slot(:inner_block, required: true)

defp nav_link(assigns) do
  ~H"""
  <a class={["tl-shell-nav__item", @current == @page && "tl-shell-nav__item--active"]}
     aria-current={if @current == @page, do: "page", else: nil}>
    <%= render_slot(@inner_block) %>
  </a>
  """
end
```

**Icon pattern:** `icon.ex` lines 7-24 uses `attr(:name, :atom)`, `attr(:rest, :global)`, `aria-hidden="true"`, `focusable="false"`, and path lookup. Add stress icons there only if needed.

**Empty/error state pattern:** `unsupported_view.ex` lines 20-45 merges descriptor defaults then renders `role="status"`, a title/body, optional code value, and a back action. Reuse for missing story, permission-denied, stale, and fixture-shape failure states.

### `lib/threadline/operator_surface/stress_fixtures.ex` (service, transform)

**Analog:** `start_live.ex` helper style plus component tests.

Use pure functions returning sorted maps/lists. Follow the deterministic sorting pattern from `start_live.ex` lines 442-459:
```elixir
socket.assigns[:threadline_schemas]
|> table_keys()
|> Enum.sort()
```

Expose stable fixture/story IDs as strings, not atoms from user input. Tests should render components using `Phoenix.LiveViewTest.render_component/2` like `surface_header_test.exs` lines 114-130.

### `lib/threadline/operator_surface/stress_ledger.ex`, `DESIGN-SYSTEM.md`, ledger JSON (utility/docs/config, file-I/O)

**Analog:** `test/threadline/brandbook_token_parity_test.exs`

**File paths and Jason decode pattern** (lines 22-26, 94):
```elixir
@style_path "lib/threadline/operator_surface/style.ex"
@tokens_json_path "brandbook/tokens.json"
@tokens_css_path "brandbook/tokens.css"

defp tokens_json, do: @tokens_json_path |> File.read!() |> Jason.decode!()
```

**Custom failure-message style** (lines 117-125, 138-146):
```elixir
assert style_val != nil,
       "dark --tl-color-#{name} missing from style.ex - @parity_intersection is stale"

assert style_val == brand_val,
       "dark --tl-color-#{name}: style.ex=#{inspect(style_val)}, brandbook=#{inspect(brand_val)}"
```

Ledger tests should assert required keys, sorted IDs, score ratchet, no silent deletion, screenshot allowlist refs, and markdown freshness with this same direct message style.

**Style/source-contract pattern:** `style_contract_test.exs` lines 8-30 checks exact selectors/tokens and refutes forbidden strings. Use this for `DESIGN-SYSTEM.md` freshness and "no Storybook/Tailwind/new dependency" invariants.

### `test/threadline/operator_surface/stress_router_test.exs` (test, request-response)

**Analog:** `test/threadline/operator_surface/router_test.exs`

**Compile-error test pattern** (lines 6-22):
```elixir
assert_raise CompileError, ~r/Threadline Operator Surface must be mounted/, fn ->
  Code.compile_quoted(
    quote do
      defmodule Threadline.OperatorSurface.RouterTest.UnsafeMount do
        use Phoenix.Router
        require Threadline.OperatorSurface.Router
        Threadline.OperatorSurface.Router.threadline_operator_surface("/threadline")
      end
    end
  )
end
```

**Successful compile and cleanup pattern** (lines 25-49):
```elixir
modules = Code.compile_quoted(quote do
  defmodule Threadline.OperatorSurface.RouterTest.PipedMount do
    use Phoenix.Router
    require Threadline.OperatorSurface.Router
    pipeline :browser do
      plug(:accepts, ["html"])
    end
    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/threadline")
    end
  end
end)

for {module, _} <- modules do
  :code.delete(module)
  :code.purge(module)
end
```

Add cases for dev/test presence, prod raise/omission, stress `live_session :threadline_stress`, auth-required behavior, and no `stress: true` option on the public macro.

### `test/threadline/operator_surface/stress_fixtures_test.exs` (test, transform)

**Analog:** `test/threadline/operator_surface/surface_header_test.exs`

**Rendered component contract pattern** (lines 10-40, 114-130):
```elixir
html = render_header()

assert html =~ ~s|data-testid="operator-nav-overview"|
assert html =~ "Scoped view"
refute html =~ ~s|role="img"|

defp render_header(overrides \\ %{}) do
  assigns = Map.merge(%{coverage: @coverage, base_path: "/audit"}, overrides)
  render_component(&SurfaceHeader.surface_header/1, assigns)
end
```

Fixture tests should enumerate DS-04 required cases and render representative story/components to prove assign-shape drift is caught.

### `test/threadline/operator_surface/stress_ledger_test.exs` (test, file-I/O, transform)

**Analog:** `test/threadline/brandbook_token_parity_test.exs` and `style_contract_test.exs`

Use `File.read!`, `Jason.decode!`, exact key assertions, and custom messages. For CSS/design tokens, copy `style_contract_test.exs` lines 32-52 style:
```elixir
src = File.read!(@style_path)
assert String.contains?(src, "--tl-color-border-focus:")
assert String.contains?(src, ".tl-alert--error")
assert String.contains?(src, ".tl-chip--danger")
```

For motion and tokenized UI checks, copy `style_contract_test.exs` lines 1253-1269 helper shape for regex assertions against named tokens.

### `test/threadline/operator_surface/*_test.exs` (test, request-response)

**Analog:** `test/threadline/operator_surface/auth_test.exs`

**Auth hook unit pattern** (lines 57-80, 190-221):
```elixir
opts = [authorize_fn: fn _socket -> false end]
socket = mock_socket()

assert {:halt, returned_socket} = Auth.on_mount(opts, %{}, %{}, socket)
assert {:redirect, %{to: "/"}} = returned_socket.redirected

assert_receive {:telemetry_event, [:threadline, :operator_surface, :authorize],
                %{result: :denied}, _metadata}
```

If stress-specific auth behavior is tested at unit level, use this pattern and keep telemetry tests `async: false`.

**LiveView route test pattern:** `test/threadline/operator_surface/live/start_live_test.exs` lines 42-72 defines a throwaway router with `threadline_operator_surface/2`; lines 143-191 define endpoint wrappers; lines 256-260 calls `live(conn, "/audit")` and asserts rendered HTML. Use this for stress LiveView route rendering.

### `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (route, request-response)

**Analog:** existing `/audit` mount in same file.

**Pipeline and auth pattern** (lines 24-31, 33-49):
```elixir
pipeline :operator_browser do
  plug(:put_root_layout, html: {ThreadlinePhoenixWeb.Layouts, :app})
  plug(ThreadlinePhoenixWeb.Plugs.AssignOperatorUser)
end

pipeline :operator_auth do
  plug(:require_authenticated_operator)
end
```

**Current mount pattern** (lines 198-215):
```elixir
scope "/audit" do
  pipe_through([:browser, :operator_browser, :operator_auth])

  threadline_operator_surface("/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    coverage_authorize_fn: &ThreadlinePhoenixWeb.Router.my_coverage_authorize_fn/1,
    scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
    repo: ThreadlinePhoenix.Repo
  )
end
```

Mount stress adjacent inside the same authenticated `/audit` scope. If the `THREADLINE_E2E_THEME=system` branch is touched, duplicate the stress mount in both branches and pass the same `theme:` lane as the operator surface.

### `examples/threadline_phoenix/e2e/playwright.config.ts` (config, request-response)

**Analog:** existing config.

**Projects and deterministic defaults** (lines 15-24, 34-50):
```typescript
const projects = [
  { name: "chromium", use: { ...devices["Desktop Chrome"] } },
  { name: "desktop-chromium", use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } } },
  { name: "mobile-chromium", use: { ...devices["Pixel 5"] } },
];

export default defineConfig({
  snapshotPathTemplate: "{testDir}/{testFilePath}-snapshots/{arg}-{projectName}{ext}",
  workers: 1,
  use: {
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    reducedMotion: "reduce",
  },
});
```

Add stress spec to the light-lane `testMatch` if light/system stress coverage is required in Phase 171.

### `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` (test, request-response + screenshots)

**Analogs:** `operator-accessibility.spec.ts`, `operator-responsive-mobile-first.spec.ts`, `operator-screenshot-regression.spec.ts`, `operator-screenshots.spec.ts`

**Login helper** (accessibility spec lines 9-16):
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

**Semantic/focus/overflow guards** (accessibility spec lines 18-33, 82-136):
```typescript
async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });
  expect(overflow).toBeLessThanOrEqual(1);
}

await expect(page.getByTestId("operator-nav-overview")).toHaveAttribute("aria-current", "page");
```

**Viewport/chrome matrix pattern** (responsive spec lines 7-11, 207-238):
```typescript
const viewports = [
  { name: "phone", width: 375, height: 812, isMobile: true },
  { name: "tablet", width: 768, height: 900, isMobile: false },
  { name: "desktop", width: 1280, height: 900, isMobile: false },
];

await expect(page.locator("#tl-main")).toHaveCount(1);
await expect(page.getByTestId("operator-header")).toBeVisible();
```

**Screenshot mask pattern** (screenshot-regression spec lines 42-75, 77-81):
```typescript
await expect(page).toHaveScreenshot(`${name}.png`, {
  fullPage: options.fullPage ?? true,
  maxDiffPixelRatio: options.maxDiffPixelRatio ?? 0.01,
  mask: dynamicMasks(page),
});

test.skip(!!process.env.CI, "visual screenshot baselines are platform-sensitive");
```

Phase 171 changes this policy only for a narrow, ledger-owned CI allowlist. Keep broad screenshots local/durable like `operator-screenshots.spec.ts` lines 34-54 and use explicit story IDs in screenshot names.

### `mix.exs` optional alias (config, batch)

**Analog:** existing aliases in `mix.exs`.

**Named verification pattern** (lines 75-108, 145-160):
```elixir
"verify.example_browser": &verify_example_browser/1,
"verify.example_browser_light": &verify_example_browser_light/1,
"ci.all": [
  "verify.format",
  "verify.credo",
  "compile --warnings-as-errors",
  "verify.test",
  "verify.example_browser"
]

defp verify_example_browser(args) do
  script = Path.expand("examples/threadline_phoenix/e2e/run-e2e.sh")
  case System.cmd("bash", [script | args], env: env, into: IO.stream(:stdio, :line)) do
    {_output, 0} -> :ok
    {_output, status} -> Mix.raise("verify.example_browser failed (#{status})")
  end
end
```

If adding `verify.operator_stress`, keep it as a named alias that delegates to the existing example browser harness or focused ExUnit files.

## Shared Patterns

### Authentication And Fail-Closed Routing
**Source:** `router.ex` lines 74-91; `auth.ex` lines 25-80  
**Apply to:** `stress_router.ex`, example router mount, stress LiveView tests

Use compile-time `CompileError` for invalid mount/config, host-owned `pipe_through`, LiveView `on_mount`, and auth callbacks that halt/redirect on denial or exception.

### Operator Shell And Theme
**Source:** `start_live.ex` lines 116-131; `surface_header.ex` lines 30-105  
**Apply to:** `stress_live.ex`, stress components, Playwright semantic tests

Always render `.threadline-ui`, `data-tl-theme={@threadline_theme}`, `Threadline.OperatorSurface.Style.css`, `SurfaceHeader.surface_header`, skip link, `#tl-main`, and `data-testid="operator-header"`.

### Source-Contract Tests
**Source:** `brandbook_token_parity_test.exs` lines 17-20, 94-146; `style_contract_test.exs` lines 8-52  
**Apply to:** ledger schema, markdown freshness, no-regression ratchet, token/style invariants

Use async file-reading tests with exact path module attributes, `Jason.decode!`, one concern per test, and custom failure messages that name the stale source and expected correction.

### Browser Guards
**Source:** `operator-accessibility.spec.ts`, `operator-responsive-mobile-first.spec.ts`, `operator-screenshot-regression.spec.ts`  
**Apply to:** `operator-stress.spec.ts`

Reuse login helpers, `getByTestId("operator-header")`, `#tl-main`, `aria-current`, no-overflow measurement, fixed viewports, reduced motion, and masked screenshots.

## No Analog Found

None. Every Phase 171 target has a local role or data-flow analog. The weakest analog is the new JSON ledger ratchet helper because no existing ratchet module exists; use the brandbook JSON parity and style source-contract tests as the copy source.

## Warnings

- No root `AGENTS.md` exists. `examples/threadline_phoenix/AGENTS.md` exists and applies to example-app files.
- No project-local `.codex/skills/` or `.agents/skills/` directories were found from the repository root.
- The exact ledger JSON path is not locked by context; planner should choose one repo-local path and keep all tests/docs pointed at that path.

## Metadata

**Analog search scope:** `lib/threadline/operator_surface`, `test/threadline/operator_surface`, `test/threadline/brandbook_token_parity_test.exs`, `examples/threadline_phoenix/lib`, `examples/threadline_phoenix/e2e`, `mix.exs`  
**Files scanned:** 60+ focused paths from operator surface, tests, example router, and Playwright harness  
**Pattern extraction date:** 2026-06-14
