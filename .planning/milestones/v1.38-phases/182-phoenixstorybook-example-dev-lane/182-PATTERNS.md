# Phase 182: phoenixstorybook-example-dev-lane - Pattern Map

**Mapped:** 2026-06-26
**Files analyzed:** 24
**Analogs found:** 21 / 24

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/threadline_phoenix/mix.exs` | config | batch/config | `examples/threadline_phoenix/mix.exs` | exact |
| `examples/threadline_phoenix/mix.lock` | config | batch/config | `examples/threadline_phoenix/mix.exs` | role-match |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | route | request-response | `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook.ex` | provider/config | request-response | `lib/threadline/operator_surface/stress_router.ex` | partial |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/wrapper.ex` | component/provider | transform | `lib/threadline/operator_surface/ui.ex` | role-match |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex` | utility | transform | `lib/threadline/operator_surface/stress_fixtures.ex` | exact |
| `examples/threadline_phoenix/storybook/*/index.exs` | config/docs | transform | `test/threadline/operator_surface/stress_ledger_test.exs` | partial |
| `examples/threadline_phoenix/storybook/foundations/index.story.exs` | component/docs | transform | `lib/threadline/operator_surface/style.ex` | role-match |
| `examples/threadline_phoenix/storybook/primitives/button.story.exs` | component/docs | transform | `lib/threadline/operator_surface/ui.ex` | partial |
| `examples/threadline_phoenix/storybook/forms/field.story.exs` | component/docs | transform | `lib/threadline/operator_surface/ui.ex` | partial |
| `examples/threadline_phoenix/storybook/states/data_state.story.exs` | component/docs | transform | `lib/threadline/operator_surface/ui.ex` | partial |
| `examples/threadline_phoenix/storybook/overlays/modal.story.exs` | component/docs | event-driven | `lib/threadline/operator_surface/ui.ex` | partial |
| `examples/threadline_phoenix/storybook/data_display/data_table.story.exs` | component/docs | transform | `lib/threadline/operator_surface/ui.ex` | partial |
| `examples/threadline_phoenix/storybook/groups/operator_groups.story.exs` | component/docs | transform | `lib/threadline/operator_surface/stress_fixtures.ex` | role-match |
| `examples/threadline_phoenix/storybook/patterns/operator_patterns.story.exs` | component/docs | transform | `lib/threadline/operator_surface/stress_fixtures.ex` | role-match |
| `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_route_test.exs` | test | request-response | `test/threadline/operator_surface/stress_router_test.exs` | exact |
| `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs` | test | transform/request-response | `test/threadline/operator_surface/stress_fixtures_test.exs` | role-match |
| `test/threadline/operator_surface/storybook_boundary_test.exs` | test | file-I/O/source-contract | `test/threadline/operator_surface/stress_router_test.exs` | exact |
| `test/threadline/example_phoenix_readme_contract_test.exs` | test | file-I/O/source-contract | `test/threadline/example_phoenix_readme_contract_test.exs` | exact |
| `test/threadline/operator_surface_doc_contract_test.exs` | test | file-I/O/source-contract | `test/threadline/operator_surface_doc_contract_test.exs` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts` | test | browser request-response | `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` | exact |
| `examples/threadline_phoenix/e2e/playwright.config.ts` | config | batch/config | `examples/threadline_phoenix/e2e/playwright.config.ts` | exact |
| `examples/threadline_phoenix/README.md` | docs | file-I/O | `examples/threadline_phoenix/README.md` | exact |
| `guides/operator-surface.md` | docs | file-I/O | `guides/operator-surface.md` | exact |

## Pattern Assignments

### `examples/threadline_phoenix/mix.exs` (config, batch/config)

**Analog:** `examples/threadline_phoenix/mix.exs`

**Existing dependency boundary** (lines 33-60):
```elixir
defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(_), do: ["lib"]

defp deps do
  [
    {:threadline, path: "../.."},
    {:phoenix, "~> 1.8.5"},
    {:phoenix_ecto, "~> 4.5"},
    {:phoenix_html, "~> 4.0"},
    {:phoenix_live_view, "~> 1.0"},
    {:ecto_sql, "~> 3.13"},
    {:postgrex, ">= 0.0.0"},
    {:telemetry_metrics, "~> 1.0"},
    {:telemetry_poller, "~> 1.0"},
    {:jason, "~> 1.2"},
    {:dns_cluster, "~> 0.2.0"},
    {:bandit, "~> 1.5"},
    {:oban, "~> 2.19"},
    {:gettext, "~> 0.26"},
    {:swoosh, "~> 1.16"},
    {:heroicons, "~> 0.5"},
    {:sigra, "~> 0.2"}
  ]
end
```

**Apply:** add `{:phoenix_storybook, "~> 1.2.0", only: [:dev, :test]}` only here. Do not add it to root `mix.exs` or root `mix.lock`.

**Verification alias pattern** (lines 68-75):
```elixir
defp aliases do
  [
    setup: ["deps.get", "compile", "ecto.setup"],
    "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
    "ecto.reset": ["ecto.drop", "ecto.setup"],
    test: ["test"],
    precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
  ]
end
```

### `examples/threadline_phoenix/mix.lock` (config, batch/config)

**Analog:** `examples/threadline_phoenix/mix.exs`

**Apply:** let `cd examples/threadline_phoenix && mix deps.get` update the lockfile. The lockfile is generated output; planner should not hand-edit it. The root lockfile is out of scope.

### `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (route, request-response)

**Analog:** `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`

**Imports and browser pipeline** (lines 1-19):
```elixir
defmodule ThreadlinePhoenixWeb.Router do
  use ThreadlinePhoenixWeb, :router

  import ThreadlinePhoenixWeb.UserAuth
  import Ecto.Query, only: [where: 3]
  import Threadline.OperatorSurface.Router
  import Threadline.OperatorSurface.StressRouter
  alias Threadline.Semantics.ActorRef

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: false)
    plug(:put_layout, html: {ThreadlinePhoenixWeb.Layouts, :app})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug :fetch_current_scope
  end
```

**Operator route/stress boundary to preserve** (lines 212-245):
```elixir
scope "/audit" do
  pipe_through([:browser, :operator_browser, :operator_auth])

  threadline_operator_surface("/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
    evidence_authorize_fn: &ThreadlinePhoenixWeb.Router.my_evidence_authorize_fn/1,
    coverage_authorize_fn: &ThreadlinePhoenixWeb.Router.my_coverage_authorize_fn/1,
    policy_authorize_fn: &ThreadlinePhoenixWeb.Router.my_policy_authorize_fn/1,
    scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
    schemas: %{
      "tickets" => ThreadlinePhoenix.HelpDesk.Ticket,
      "ticket_replies" => ThreadlinePhoenix.HelpDesk.TicketReply
    },
    repo: ThreadlinePhoenix.Repo
  )

  # Internal dev/test stress route. Keep it outside the public mount snippet.
  threadline_operator_surface_stress("/__stress",
    stress_env: if(Mix.env() == :prod, do: :omit, else: Mix.env()),
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    coverage_authorize_fn: &ThreadlinePhoenixWeb.Router.my_coverage_authorize_fn/1,
    scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
    schemas: %{
      "tickets" => ThreadlinePhoenix.HelpDesk.Ticket,
      "ticket_replies" => ThreadlinePhoenix.HelpDesk.TicketReply
    },
    repo: ThreadlinePhoenix.Repo
  )
end
```

**Dev routes boundary to extend** (lines 332-344):
```elixir
if Application.compile_env(:threadline_phoenix, :dev_routes) do
  scope "/dev", ThreadlinePhoenixWeb do
    pipe_through [:browser, :operator_browser]

    post "/help_desk/ticket_reply", HelpDeskDevController, :ticket_reply
  end

  scope "/dev" do
    pipe_through :browser

    forward "/mailbox", Plug.Swoosh.MailboxPreview
  end
end
```

**Apply:** put PhoenixStorybook route/assets in this same compile-time branch, but follow researched PhoenixStorybook shape: import `PhoenixStorybook.Router`, use root `scope "/"`, and pass full `/dev/storybook` paths.

### `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook.ex` (provider/config, request-response)

**Analog:** `lib/threadline/operator_surface/stress_router.ex`

**Optional dependency guard pattern** (lines 1-3):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.StressRouter do
    @moduledoc false
```

**Fail-closed route macro pattern to preserve as mindset** (lines 11-24):
```elixir
cond do
  stress_env == :omit ->
    quote do
      nil
    end

  stress_env == :prod ->
    raise CompileError,
      file: caller_file,
      line: caller_line,
      description: "Threadline stress surface is dev/test-only"

  true ->
    quote do
```

**Apply:** backend module should be guarded so production compilation does not require `PhoenixStorybook` when the dependency is `only: [:dev, :test]`.

### `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/wrapper.ex` (component/provider, transform)

**Analog:** `lib/threadline/operator_surface/ui.ex`

**Wrapper shell pattern** (lines 1158-1183):
```elixir
def shell(assigns) do
  assigns = assign_new(assigns, :header_theme, fn -> assigns[:theme] end)

  ~H"""
  <div class="threadline-ui" data-tl-theme={@theme}>
    <Threadline.OperatorSurface.Style.css />
    <Script.js :if={@script} />
    <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
      :if={@base_path}
      theme={@header_theme || @theme}
      coverage={@coverage}
      base_path={@base_path}
      error={@error}
      coverage_enabled={@coverage_enabled}
      policy_enabled={@policy_enabled}
      evidence_enabled={@evidence_enabled}
      exports_enabled={@exports_enabled}
      current={@current}
      scoped={@scoped}
    />
    <.reconnect_banner />
    <main id="tl-main" class={@main_class} tabindex="-1" {@main_rest}>
      <%= render_slot(@inner_block) %>
    </main>
  </div>
  """
end
```

**Style injection pattern** (lines 9-18):
```elixir
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

**Theme contract** (lines 19-24, 206-258):
```elixir
.threadline-ui {
  --tl-space-1: 4px;
  --tl-space-2: 8px;
  --tl-space-3: 12px;
}

.threadline-ui[data-tl-theme="light"] {
  color-scheme: light;
}

@media (prefers-color-scheme: light) {
  .threadline-ui[data-tl-theme="system"] {
    color-scheme: light;
```

**Apply:** render stories through `.threadline-ui`, `data-tl-theme`, and real `Threadline.OperatorSurface.Style.css`; do not duplicate CSS tokens.

### `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex` (utility, transform)

**Analog:** `lib/threadline/operator_surface/stress_fixtures.ex`

**Ugly-data vocabulary** (lines 4-25):
```elixir
@required_cases ~w(
  empty
  error
  high_count
  long_id
  long_string
  many
  mixed_severity
  non_ascii
  null_fields
  one
  pagination_boundary
  permission_denied
  reconnecting
  stale
  timezone_boundary
  warning
  zero_count
)

@theme_modes ["dark", "light", "system"]
@viewports [320, 375, 768, 1024, 1440]
```

**Read-only public helpers** (lines 213-220):
```elixir
def required_cases, do: @required_cases
def theme_modes, do: @theme_modes
def viewports, do: @viewports

@doc """
Returns component-ready assigns for a story or story ID.
"""
def assigns_for(id) when is_binary(id) do
```

**Representative values** (lines 602-610):
```elixir
defp synthetic_values(cases) do
  %{
    long_id:
      "chg_00000000-0000-4000-8000-171171171171/correlation/" <> String.duplicate("a", 72),
    long_string:
      "support.operator@example.invalid requested retention evidence for " <>
        String.duplicate("transaction boundary ", 8),
    non_ascii: "Zoë Ångström reviewed 東京 retention proof",
    cases: cases
  }
end
```

**Apply:** expose a small allowlist for Storybook stories. Do not expose `StressFixtures.all/0` as Storybook navigation and do not add DB/app dependencies to fixture helpers.

### Story Files Under `examples/threadline_phoenix/storybook/` (component/docs, transform)

**No same-role in-repo analog:** there are no existing PhoenixStorybook `.story.exs` files. Use the researched PhoenixStorybook `Variation` / `VariationGroup` API, and copy component contracts from the private UI module.

**Imports to use in story modules** (from `lib/threadline/operator_surface/ui.ex` lines 1-8):
```elixir
defmodule Threadline.OperatorSurface.UI do
  @moduledoc false
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]
  alias Phoenix.LiveView.JS
  alias Threadline.OperatorSurface.Components.Icon
  alias Threadline.OperatorSurface.Presentation
  alias Threadline.OperatorSurface.Script
```

**Primitive story source** (lines 10-37):
```elixir
attr(:type, :string, default: "button")
attr(:class, :any, default: nil)

attr(:variant, :string,
  default: "secondary",
  values: ~w(primary secondary quiet-primary danger ghost icon)
)

attr(:compact, :boolean, default: false)
attr(:rest, :global, include: ~w(disabled form name value phx-disable-with))
slot(:inner_block, required: true)

def button(assigns) do
  ~H"""
  <button
    type={@type}
    class={[
      "tl-button",
      @variant != "secondary" && "tl-button--#{@variant}",
      @compact && "tl-button--compact",
      @class
    ]}
    {@rest}
  >
    <%= render_slot(@inner_block) %>
  </button>
  """
end
```

**Form story source** (lines 1428-1525):
```elixir
attr(:id, :string, required: true)
attr(:name, :string, required: true)
attr(:value, :any, default: nil)
attr(:type, :string, default: "text")
attr(:class, :any, default: nil)
attr(:options, :list, default: [])
attr(:checked, :boolean, default: false)
attr(:rest, :global)

def input(%{type: "checkbox"} = assigns) do
  assigns = assign(assigns, :checked, assigns.value == true || assigns.value == "true")

  ~H"""
  <input
    type="checkbox"
    id={@id}
    name={@name}
    value="true"
    checked={@checked}
    class={["tl-checkbox", @class]}
    {@rest}
  />
  """
end
```

**State story source** (lines 610-697):
```elixir
attr(:reason, :atom, required: true)
attr(:as_of, :string, default: nil, doc: "Timestamp for the pruned (retention) sub-case")

attr(:capability, :string,
  default: "audit:read",
  doc: "Required capability for permission states"
)

def data_state(%{reason: :unauthorized} = assigns) do
  ~H"""
  <.empty_state
    variant="permission"
    role="alert"
    icon={:lock}
    focus_heading
    class={@class}
    {@rest}
  >
    <:title>You do not have access to this audit data</:title>
    The audit data exists; your account needs <code><%= @capability %></code>.
  </.empty_state>
  """
end
```

**Data-display story source** (lines 450-495):
```elixir
attr(:rows, :list, default: nil)
attr(:stream, :any, default: nil)
attr(:row_id, :any, default: nil, doc: "Fn returning a DOM id for the <tr>")
attr(:tbody_id, :string, default: nil)
attr(:class, :any, default: nil)
attr(:rest, :global)

slot :col, required: true do
  attr(:label, :string, required: true)
end

slot(:action)

def data_table(assigns) do
  assigns = assign_new(assigns, :data_rows, fn -> assigns.stream || assigns.rows || [] end)

  ~H"""
  <table class={["tl-table", "tl-table--responsive", @class]} {@rest}>
```

**Overlay story source** (lines 947-1055):
```elixir
attr(:id, :string, required: true)
attr(:show, :boolean, default: false)
attr(:on_cancel, JS, default: %JS{})
attr(:class, :any, default: nil)
attr(:rest, :global)
slot(:inner_block, required: true)

def drawer(assigns) do
  ~H"""
  <div
  id={@id}
  phx-mounted={@show && show_drawer(@id)}
  phx-remove={hide_drawer(@id)}
  class={["tl-drawer-container", if(!@show, do: "hidden")]}
  {@rest}
  >
```

**Group/pattern story source** (from `lib/threadline/operator_surface/stress_fixtures.ex` lines 65-96):
```elixir
@group_stories [
  {"group.page-header.current", "group.page_header.current",
   "Page header + actions + breadcrumbs", :live},
  {"group.toolbar.current", "group.toolbar.current",
   "Toolbar + search + filters + sort (absorbs filter-bar)", :live},
  {"group.data-panel.current", "group.data_panel.current",
   "Table + empty + loading + pagination (absorbs pagination, timeline-list)", :live},
  {"group.detail-header.current", "group.detail_header.current",
   "Detail header + metadata + actions (absorbs kv-list)", :live},
  {"group.modal-destructive.current", "group.modal_destructive.current",
   "Modal confirm + destructive action", :live},
  {"group.permission-denied.current", "group.permission_denied.current",
   "Permission denied group", :live},
  {"group.offline.current", "group.offline.current",
   "Reconnect / offline banner + disabled actions", :live}
]
```

### `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_route_test.exs` (test, request-response)

**Analog:** `test/threadline/operator_surface/stress_router_test.exs`

**Compiled route-list pattern** (lines 149-186):
```elixir
test "compiling a secure throwaway stress router registers the stress LiveView route" do
  modules =
    Code.compile_quoted(
      quote do
        defmodule Threadline.OperatorSurface.StressRouterTest.ThrowawayRouter do
          use Phoenix.Router
          require Threadline.OperatorSurface.StressRouter

          pipeline :browser do
            plug(:accepts, ["html"])
          end

          scope "/" do
            pipe_through(:browser)

            Threadline.OperatorSurface.StressRouter.threadline_operator_surface_stress(
              "/__stress",
              authorize_fn: &__MODULE__.authorize/1
            )
          end

          def authorize(_), do: true
        end
      end
    )

  routes = Phoenix.Router.routes(Threadline.OperatorSurface.StressRouterTest.ThrowawayRouter)

  assert Enum.any?(routes, fn route ->
           route.path == "/__stress" and route.plug == Phoenix.LiveView.Plug
         end)

  purge_modules(modules)
end
```

**Route render smoke pattern** (lines 317-330):
```elixir
test "authenticated stress route renders the operator shell, theme, selected story, and preview",
     %{conn: conn} do
  {:ok, _view, html} = live(conn, "/audit/__stress")

  assert html =~ ~s|class="threadline-ui"|
  assert html =~ ~s|data-tl-theme="system"|
  assert html =~ ~s|data-testid="operator-header"|
  assert html =~ ~s|id="tl-main"|
  assert html =~ ~s|data-testid="stress-lab"|
  assert html =~ ~s|data-testid="stress-story-id"|
  assert html =~ ~s|data-testid="stress-preview"|
end
```

**Apply:** assert `/dev/storybook` and `/dev/storybook/assets` are present in test/dev route tables and absent when `dev_routes` is false/prod.

### `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs` (test, transform/request-response)

**Analog:** `test/threadline/operator_surface/stress_fixtures_test.exs`

**Component render smoke** (lines 244-250):
```elixir
test "representative adapters render existing component shapes" do
  assert {:ok, header_assigns} =
           StressFixtures.assigns_for("primitive.surface-header.current")

  header_html = render_component(&SurfaceHeader.surface_header/1, header_assigns)

  assert header_html =~ ~s|data-testid="operator-header"|
```

**Fixture source contract** (lines 220-242):
```elixir
test "fixture registry source stays synthetic and package-free" do
  source = File.read!(@source_path)

  forbidden = [
    "ThreadlinePhoenix",
    "Repo.",
    "Ecto.Query",
    "String.to_atom",
    "PhoenixStorybook",
    "Tailwind"
  ]

  for term <- forbidden do
    refute source =~ term, "stress fixture source must not reference #{term}"
  end

  refute source =~ "npmjs.com", "stress fixture source must not reference package registries"
end
```

**Apply:** for Storybook helper tests, invert the PhoenixStorybook ban only where dependency use is expected. Keep bans for DB access, `String.to_atom`, Tailwind, visual SaaS terms, and generated full fixture mirrors.

### `test/threadline/operator_surface/storybook_boundary_test.exs` (test, file-I/O/source-contract)

**Analog:** `test/threadline/operator_surface/stress_router_test.exs`

**Root source absence pattern** (lines 267-276):
```elixir
test "root operator macro source does not expose stress or story routes" do
  source = File.read!(@router_source)

  refute source =~ "threadline_operator_surface_stress"
  refute source =~ ~s|"/__stress"|
  refute source =~ ~s|"/stories"|
  refute source =~ "PhoenixStorybook"
  refute source =~ "phoenix_storybook"
  refute source =~ "Storybook"
end
```

**Stress source forbidden dependency pattern** (lines 434-452):
```elixir
test "stress source avoids unsafe param conversion and banned visual dependencies" do
  source =
    [
      File.read!(@stress_router_source),
      File.read!(@stress_live_source),
      File.read!(@style_source)
    ]
    |> Enum.join("\n")

  for forbidden <- [
        "String.to_atom",
        "PhoenixStorybook",
        "Tailwind",
        "Chromatic",
        "Percy",
        "Applitools"
      ] do
    refute source =~ forbidden, "stress source must not reference #{forbidden}"
  end
end
```

**Root optional dependency pattern** (from `mix.exs` lines 52-72):
```elixir
defp deps do
  [
    {:ecto_sql, "~> 3.10"},
    {:postgrex, "~> 0.17"},
    {:jason, "~> 1.4"},
    {:nimble_csv, "~> 1.2"},
    {:plug, "~> 1.15"},
    {:telemetry, "~> 1.2"},
    {:phoenix, "~> 1.7", optional: true},
    {:phoenix_live_view, "~> 1.0", optional: true},
    {:phoenix_html, "~> 4.0", optional: true},
    {:phoenix_pubsub, "~> 2.1", optional: true},
```

**Apply:** scan root `mix.exs`, root `mix.lock`, root `lib/`, `lib/threadline/operator_surface/router.ex`, and public docs for forbidden dependency/mount terms: `PhoenixStorybook`, `phoenix_storybook`, `live_storybook`.

### `test/threadline/example_phoenix_readme_contract_test.exs` (test, file-I/O/source-contract)

**Analog:** `test/threadline/example_phoenix_readme_contract_test.exs`

**Doc contract pattern** (lines 50-84):
```elixir
test "example README locks the mounted operator-surface story to the router source" do
  doc = read_rel!(@readme_path)

  assert String.contains?(doc, "secured `/audit` path")
  assert String.contains?(doc, "treat this as a `sigra-reference` example layered on top")
  assert String.contains?(doc, "root library's broader `phoenix-surface` lane")
  assert String.contains?(doc, "/audit/evidence")
  assert String.contains?(doc, "Sigra `0.2.5`, Phoenix `1.8.5`")
  assert String.contains?(doc, "scope and pipeline")
  assert contains_normalized?(doc, router_mount_block())
  assert String.contains?(doc, "pipeline :operator_auth")
  assert String.contains?(doc, "authenticated operator user")
end
```

**Normalized snippet extraction** (lines 148-163):
```elixir
defp router_mount_block do
  GettingStartedFixtures.extract!(
    "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex",
    "operator-surface-mount"
  )
end

defp contains_normalized?(doc, snippet) do
  String.contains?(normalize(doc), normalize(snippet))
end
```

**Apply:** add README assertions that Storybook is local maintainer component docs/design review, is not installed by adopters, is not a production route, and does not replace `/audit/__stress`.

### `test/threadline/operator_surface_doc_contract_test.exs` (test, file-I/O/source-contract)

**Analog:** `test/threadline/operator_surface_doc_contract_test.exs`

**Guide assertion pattern** (lines 16-30):
```elixir
test "operator surface guide declares route literals" do
  guide = File.read!("guides/operator-surface.md")

  assert String.contains?(guide, "/audit/transactions/:id")
  assert String.contains?(guide, "/audit/actors/:kind/:id")
  assert String.contains?(guide, "/audit/rows/:table/:pk")
end

test "operator surface guide details fail-closed security and auth options" do
  guide = File.read!("guides/operator-surface.md")

  assert String.contains?(guide, "fail-closed")
  assert String.contains?(guide, ":authorize_fn")
  assert String.contains?(guide, ":adopter_acknowledges_unauthenticated: true")
end
```

**Apply:** if `guides/operator-surface.md` mentions Storybook, assert it only explains the Storybook-vs-stress boundary and does not instruct adopters to install PhoenixStorybook.

### `examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts` (test, browser request-response)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts`

**Imports and helpers** (lines 1-19, 77-84):
```typescript
import { expect, Page, test } from "@playwright/test";
import { existsSync, mkdirSync, readFileSync } from "node:fs";
import { join, resolve } from "node:path";

const viewportWidths = [320, 375, 768, 1024, 1440];

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}
```

**Render smoke pattern** (lines 101-117):
```typescript
test("renders the real operator shell, theme scope, story metadata, and preview", async ({
  page,
}) => {
  await page.goto("/audit/__stress?story=page.timeline.empty");

  await expect(page.getByTestId("operator-header")).toBeVisible();
  const shell = page.locator(".threadline-ui").first();
  await expect(shell).toBeVisible();
  await expect(shell).toHaveAttribute("data-tl-theme", /^(dark|light|system)$/);
  await expect(page.locator("#tl-main")).toBeVisible();
  await expect(page.getByTestId("stress-story-id")).toHaveText(
    "page.timeline.empty",
  );
  await expect(page.getByTestId("stress-preview")).toBeVisible();
});
```

**Bounded viewport pattern** (lines 148-157):
```typescript
for (const width of viewportWidths) {
  test(`keeps the stress route within the ${width}px viewport`, async ({
    page,
  }) => {
    await page.setViewportSize({ width, height: 900 });
    await page.goto("/audit/__stress?story=page.timeline.empty");

    await expect(page.getByTestId("stress-preview")).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });
}
```

**Apply:** Storybook smoke should cover index plus representative primitive/form/state/overlay/data-display/group stories and assert assets plus `.threadline-ui[data-tl-theme]`. No broad screenshot matrix.

### `examples/threadline_phoenix/e2e/playwright.config.ts` (config, batch/config)

**Analog:** `examples/threadline_phoenix/e2e/playwright.config.ts`

**Project scoping pattern** (lines 15-35):
```typescript
const projects = [
  { name: "chromium", use: { ...devices["Desktop Chrome"] } },
  { name: "desktop-chromium", use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } } },
  { name: "mobile-chromium", use: { ...devices["Pixel 5"] } },
  ...(lightLane
    ? [
        {
          name: "desktop-chromium-light",
          testMatch: [
            /operator-(accessibility|motion|screenshots|screenshot-regression|stress)\.spec\.ts/,
            /operator-phase-177-uat\.spec\.ts/,
            /operator-phase-178-uat\.spec\.ts/,
          ],
          use: {
            ...devices["Desktop Chrome"],
            viewport: { width: 1280, height: 900 },
            colorScheme: "light" as const,
          },
        },
      ]
    : []),
];
```

**Apply:** if Storybook needs light/system smoke, add `operator-storybook.spec.ts` to the bounded testMatch rather than broadening all specs.

### `examples/threadline_phoenix/README.md` (docs, file-I/O)

**Analog:** `examples/threadline_phoenix/README.md`

**Maintainer/adopter split** (lines 75-79):
```markdown
For the **reference-app maintainer walk**, start with
[`./WALKTHROUGH.md`](./WALKTHROUGH.md). Integrators wiring Threadline into their
own app should still use
[`../../guides/getting-started-saas.md`](../../guides/getting-started-saas.md).
Treat this README as the runnable proof artifact behind both paths.
```

**Dev URL table pattern** (lines 256-267):
```markdown
## Sigra walkthrough URLs

After `mix phx.server` (see below), use these browser paths:

| Action | URL |
|--------|-----|
| Home (links when logged out) | `http://localhost:4000/` |
| Register | `http://localhost:4000/users/register` |
| Log in | `http://localhost:4000/users/log_in` |
| Log out | `POST` `http://localhost:4000/users/log_out` (while authenticated) |
| Dev email mailbox (confirmation) | `http://localhost:4000/dev/mailbox` |
```

**Apply:** add `/dev/storybook` as local maintainer component documentation only. Do not tell adopters to install PhoenixStorybook in their host app.

### `guides/operator-surface.md` (docs, file-I/O)

**Analog:** `guides/operator-surface.md`

**Optional dependency posture** (lines 1-7):
```markdown
# Operator Surface

The Threadline Operator Surface provides a suite of mountable, drop-in LiveView screens to investigate row mutations, actor histories, and transaction contexts directly in your host application.

It is designed to be fully optional: `phoenix`, `phoenix_live_view`, `phoenix_html`, and `phoenix_pubsub` are optional dependencies, so capture-only integrations aren't forced to bring in UI code.

For compatibility, support boundaries, and deprecation policy, see `guides/upgrade-path.md`. This guide stays focused on mount, auth, and screens.
```

**Theme contract docs** (lines 57-71):
```markdown
The operator surface renders in one of three host-selected lanes via the
optional `theme:` mount option, validated at compile time to one of
`:dark | :light | :system` (default `:dark`):

- `:dark` (default) — the brand-primary surface. Omit `theme:` entirely to get
  it; the canonical mount above stays dark with no extra configuration.
- `:light` — forces the light token lane regardless of the visitor's OS
  setting.
- `:system` — auto-follows the visitor's OS preference through scoped CSS only
  (a `@media (prefers-color-scheme: light)` lane keyed on the rendered
  `data-tl-theme` attribute). It is correct on the first paint / dead render —
  there is no JavaScript, no `localStorage`, and no runtime theme toggle, so
  there is no flash of the wrong theme.
```

**Apply:** preserve optional root dependency language. If mentioning Storybook, anchor it as example-app maintainer tooling and explicitly keep `/audit/__stress` as the authenticated operator-flow stress harness.

## Shared Patterns

### Dev/Test Route Gating

**Source:** `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`
**Apply to:** router mount and route tests

```elixir
if Application.compile_env(:threadline_phoenix, :dev_routes) do
  scope "/dev", ThreadlinePhoenixWeb do
    pipe_through [:browser, :operator_browser]

    post "/help_desk/ticket_reply", HelpDeskDevController, :ticket_reply
  end

  scope "/dev" do
    pipe_through :browser

    forward "/mailbox", Plug.Swoosh.MailboxPreview
  end
end
```

### Theme Wrapper

**Source:** `lib/threadline/operator_surface/ui.ex`
**Apply to:** Storybook wrapper/helpers and browser smoke

```elixir
<div class="threadline-ui" data-tl-theme={@theme}>
  <Threadline.OperatorSurface.Style.css />
  <Script.js :if={@script} />
  <.reconnect_banner />
  <main id="tl-main" class={@main_class} tabindex="-1" {@main_rest}>
    <%= render_slot(@inner_block) %>
  </main>
</div>
```

### Source Contracts

**Source:** `test/threadline/operator_surface/stress_router_test.exs`
**Apply to:** root boundary, stress boundary, docs boundary

```elixir
for forbidden <- [
      "String.to_atom",
      "PhoenixStorybook",
      "Tailwind",
      "Chromatic",
      "Percy",
      "Applitools"
    ] do
  refute source =~ forbidden, "stress source must not reference #{forbidden}"
end
```

For Phase 182, allow PhoenixStorybook terms only inside `examples/threadline_phoenix` Storybook files and example app dependency/lockfile. Root package source and public operator macro source should still reject `PhoenixStorybook`, `phoenix_storybook`, and `live_storybook`.

### Verification Entry Points

**Source:** `mix.exs`
**Apply to:** plan verification

```elixir
"verify.compile_no_optional": ["compile --no-optional-deps --warnings-as-errors"],
"ci.all": [
  "verify.format",
  "verify.credo",
  "compile --warnings-as-errors",
  "verify.compile_no_optional",
  "verify.test",
  "verify.threadline",
  "verify.example",
  "verify.doc_contract",
  "verify.example_browser"
]
```

**Example browser harness source:** `examples/threadline_phoenix/e2e/run-e2e.sh`

```bash
PORT="$(choose_free_port)"
BASE_URL="${E2E_BASE_URL:-http://${HOST}:${PORT}}"
export PORT
export E2E_BASE_URL="$BASE_URL"

cd "$EXAMPLE"
mix deps.get --only test
touch lib/threadline_phoenix_web/router.ex
mix compile
mix ecto.create --quiet -r ThreadlinePhoenix.Repo 2>/dev/null || true
mix ecto.migrate --quiet
mix demo.reset
mix demo.seed
```

## No Analog Found

Files with no same-role close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook.ex` | provider/config | request-response | No existing PhoenixStorybook backend module exists. Use researched PhoenixStorybook setup plus local `Code.ensure_loaded?` guard pattern. |
| `examples/threadline_phoenix/storybook/**/*.story.exs` | component/docs | transform/event-driven | No PhoenixStorybook story files exist. Copy component contracts from `UI` and fixture vocabulary from `StressFixtures`, but story module shape must come from PhoenixStorybook docs/research. |
| `examples/threadline_phoenix/storybook/*/index.exs` | config/docs | transform | No in-repo Storybook navigation/index files exist. Use category names from context/research, not generated ledger navigation. |

## Metadata

**Analog search scope:** `examples/threadline_phoenix`, `lib/threadline/operator_surface`, `test/threadline`, `guides`

**Files scanned:** router, mix configs, example configs, stress router, stress live, stress fixtures, UI/style modules, doc-contract tests, stress fixture tests, stress router tests, example ConnCase tests, Playwright stress spec/config/runner, example README, operator guide.

**Pattern extraction date:** 2026-06-26
