if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.StressRouterTest.Layouts do
    use Phoenix.Component

    def root(assigns) do
      ~H"""
      <html>
        <head><title>Stress Router Test</title></head>
        <body><%= @inner_content %></body>
      </html>
      """
    end
  end

  defmodule Threadline.OperatorSurface.StressRouterTest.Auth do
    def authorize(_), do: Application.get_env(:threadline, :stress_router_authorized, true)
    def coverage_authorize(_), do: true
  end

  defmodule Threadline.OperatorSurface.StressRouterTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.StressRouter

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.StressRouterTest.Layouts, :root}
      )
    end

    scope "/audit" do
      pipe_through(:browser)

      Threadline.OperatorSurface.StressRouter.threadline_operator_surface_stress("/__stress",
        authorize_fn: &Threadline.OperatorSurface.StressRouterTest.Auth.authorize/1,
        coverage_authorize_fn:
          &Threadline.OperatorSurface.StressRouterTest.Auth.coverage_authorize/1,
        theme: :system
      )
    end
  end

  defmodule Threadline.OperatorSurface.StressRouterTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_stress_router_key",
      signing_salt: "stress-router"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.StressRouterTest.Router)
  end

  defmodule Threadline.OperatorSurface.StressRouterTest.AlternateRouter do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.StressRouter

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.StressRouterTest.Layouts, :root}
      )
    end

    scope "/ops" do
      pipe_through(:browser)

      Threadline.OperatorSurface.StressRouter.threadline_operator_surface_stress("/__stress",
        authorize_fn: &Threadline.OperatorSurface.StressRouterTest.Auth.authorize/1,
        coverage_authorize_fn:
          &Threadline.OperatorSurface.StressRouterTest.Auth.coverage_authorize/1,
        theme: :dark
      )
    end
  end

  defmodule Threadline.OperatorSurface.StressRouterTest.AlternateEndpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_stress_router_alt_key",
      signing_salt: "stress-router-alt"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.StressRouterTest.AlternateRouter)
  end

  defmodule Threadline.OperatorSurface.StressRouterTest do
    use ExUnit.Case, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias Threadline.OperatorSurface.StressFixtures

    @endpoint Threadline.OperatorSurface.StressRouterTest.Endpoint
    @ledger_path ".planning/design-system-ledger.json"
    @router_source "lib/threadline/operator_surface/router.ex"
    @example_router_source "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex"
    @stress_router_source "lib/threadline/operator_surface/stress_router.ex"
    @stress_live_source "lib/threadline/operator_surface/live/stress_live.ex"
    @style_source "lib/threadline/operator_surface/style.ex"

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.StressRouterTest.Endpoint,
        secret_key_base: String.duplicate("s", 64),
        live_view: [signing_salt: String.duplicate("s", 8)],
        render_errors: [view: Threadline.OperatorSurface.StressRouterTest.Layouts]
      )

      original_authorized = Application.get_env(:threadline, :stress_router_authorized)
      original_interval = Application.get_env(:threadline, :coverage_poll_ms)
      Application.put_env(:threadline, :stress_router_authorized, true)
      Application.put_env(:threadline, :coverage_poll_ms, 5_000)

      on_exit(fn ->
        restore_env(:stress_router_authorized, original_authorized)
        restore_env(:coverage_poll_ms, original_interval)
      end)

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      Application.put_env(:threadline, :stress_router_authorized, true)
      {:ok, conn: build_conn()}
    end

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
               route.path == "/__stress" and route.plug == Phoenix.LiveView.Plug and
                 match?(
                   {Threadline.OperatorSurface.Live.StressLive, :index, _,
                    %{name: :threadline_stress}},
                   route.metadata.phoenix_live_view
                 )
             end)

      purge_modules(modules)
    end

    test "private prod stress_env hook raises at compile time and normal hook compiles" do
      assert_raise CompileError,
                   ~r/Threadline stress surface is dev\/test-only/,
                   fn ->
                     Code.compile_quoted(
                       quote do
                         defmodule Threadline.OperatorSurface.StressRouterTest.ProdHookRouter do
                           use Phoenix.Router
                           require Threadline.OperatorSurface.StressRouter

                           pipeline :browser do
                             plug(:accepts, ["html"])
                           end

                           scope "/" do
                             pipe_through(:browser)

                             Threadline.OperatorSurface.StressRouter.threadline_operator_surface_stress(
                               "/__stress",
                               stress_env: :prod,
                               authorize_fn: &__MODULE__.authorize/1
                             )
                           end

                           def authorize(_), do: true
                         end
                       end
                     )
                   end

      modules =
        Code.compile_quoted(
          quote do
            defmodule Threadline.OperatorSurface.StressRouterTest.TestHookRouter do
              use Phoenix.Router
              require Threadline.OperatorSurface.StressRouter

              pipeline :browser do
                plug(:accepts, ["html"])
              end

              scope "/" do
                pipe_through(:browser)

                Threadline.OperatorSurface.StressRouter.threadline_operator_surface_stress(
                  "/__stress",
                  stress_env: :test,
                  authorize_fn: &__MODULE__.authorize/1
                )
              end

              def authorize(_), do: true
            end
          end
        )

      purge_modules(modules)
    end

    test "real prod Mix.env macro path fails closed without the stress_env hook" do
      {output, status} =
        System.cmd(
          "bash",
          ["-lc", "MIX_ENV=prod mix run --no-start test/support/stress_router_prod_compile.exs"],
          stderr_to_stdout: true
        )

      assert status != 0
      assert output =~ "Threadline stress surface is dev/test-only"
    end

    test "source keeps stress routing off the public operator macro option surface" do
      forbidden = "stress" <> ": true"

      refute File.read!(@router_source) =~ forbidden
      refute File.read!(@example_router_source) =~ forbidden
    end

    test "example app mounts audit and stress routes with a distinct live session" do
      source = File.read!(@example_router_source)

      assert Regex.scan(~r/threadline_operator_surface_stress\("\/__stress"/, source) |> length() ==
               2

      {output, status} =
        System.cmd(
          "bash",
          [
            "-lc",
            "cd examples/threadline_phoenix && MIX_ENV=test mix run --no-start -e 'routes = Phoenix.Router.routes(ThreadlinePhoenixWeb.Router); IO.puts(Enum.map(routes, & &1.path)); IO.puts(File.read!(\"../../lib/threadline/operator_surface/stress_router.ex\"))'"
          ],
          stderr_to_stdout: true
        )

      assert status == 0, output
      assert output =~ "/audit"
      assert output =~ "/audit/__stress"
      assert output =~ "live_session :threadline_stress"
      refute output =~ "stress" <> ": true"
    end

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
      assert html =~ ~s|data-testid="stress-ledger-score"|
      assert html =~ ~s|data-testid="stress-target-score"|
      assert html =~ ~s|data-testid="stress-screenshot-status"|
    end

    test "selected theme query drives the stress root theme instead of mount default",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, "/audit/__stress?theme=light")

      assert html =~ ~s|data-tl-theme="light"|
      assert html =~ "light / 1024px"
    end

    test "direct story params must remain inside the active category filter", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/audit/__stress?category=foundation&story=page.timeline.empty")

      assert html =~ ~s|aria-current="page"|
      refute html =~ ~s|data-testid="stress-story-id">page.timeline.empty|
      assert html =~ "foundation"
    end

    test "unknown route params are allowlist-normalized and never crash", %{conn: conn} do
      {:ok, _view, html} =
        live(
          conn,
          "/audit/__stress?story=missing&category=bad&status=bad&theme=bad&viewport=999999"
        )

      assert html =~ ~s|data-testid="stress-lab"|
      assert html =~ ~s|data-testid="stress-preview"|
      assert html =~ ~s|data-testid="stress-story-id"|
      refute html =~ "missing"
      refute html =~ "999999"
    end

    test "unauthenticated stress LiveView access follows the operator auth path", %{conn: conn} do
      Application.put_env(:threadline, :stress_router_authorized, false)

      assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/audit/__stress")

      conn = get(conn, "/audit/__stress")
      assert redirected_to(conn) == "/"
      refute response(conn, 302) =~ ~s|data-testid="stress-lab"|
    end

    test "every ledger story is listed and direct navigation renders preview or reserved placeholder",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, "/audit/__stress")

      story_list = story_list_fragment(html)

      for entry <- ledger_entries(), fixture_backed_entry?(entry) do
        story_id = entry["story_id"]
        assert {:ok, _story} = StressFixtures.by_id(story_id)
        assert story_list =~ story_id

        {:ok, _view, story_html} = live(conn, "/audit/__stress?story=#{URI.encode(story_id)}")
        assert story_html =~ ~s|data-testid="stress-preview"|

        assert story_html =~ entry["fixture_key"] or
                 story_html =~ "Reserved for Phase #{entry["reserved_for_phase"]}"
      end
    end

    @group_story_ids ~w(
      group.data-panel.current
      group.detail-header.current
      group.drawer-form.reference
      group.empty-cta.current
      group.modal-destructive.current
      group.offline.current
      group.page-header.current
      group.permission-denied.current
      group.stats-chart-table.current
      group.tabs-subviews.reference
      group.toast-update.current
      group.toolbar.current
    )

    test "all 12 GROUP-01 group stories render without error across the matrix", %{conn: conn} do
      assert length(@group_story_ids) == 12

      for story_id <- @group_story_ids do
        assert {:ok, _story} = StressFixtures.by_id(story_id),
               "#{story_id} must resolve in StressFixtures"

        for theme <- StressFixtures.theme_modes(),
            viewport <- StressFixtures.viewports() do
          {:ok, _view, html} =
            live(
              conn,
              "/audit/__stress?story=#{URI.encode(story_id)}&category=group&theme=#{theme}&viewport=#{viewport}"
            )

          assert html =~ ~s|data-testid="stress-preview"|,
                 "#{story_id} failed to render at #{theme}/#{viewport}"

          assert html =~ ~s|data-testid="stress-story-id">#{story_id}|,
                 "#{story_id} was not the selected story at #{theme}/#{viewport}"

          assert html =~ ~s|data-tl-theme="#{theme}"|
        end
      end
    end

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

    test "StressLive source exposes required stable test IDs" do
      source = File.read!(@stress_live_source)

      for test_id <- [
            "stress-story-id",
            "stress-preview",
            "stress-ledger-score",
            "stress-target-score",
            "stress-screenshot-status"
          ] do
        assert source =~ ~s|data-testid="#{test_id}"|
      end
    end

    defp ledger_entries do
      @ledger_path
      |> File.read!()
      |> Jason.decode!()
      |> Map.fetch!("entries")
    end

    defp fixture_backed_entry?(entry) do
      entry["story_id"] != "" or entry["fixture_key"] != "" or entry["stress_path"] != ""
    end

    defp story_list_fragment(html) do
      html
      |> String.split(~s|data-testid="stress-story-list"|)
      |> Enum.at(1, "")
      |> String.split(~s|data-testid="stress-preview"|)
      |> List.first()
    end

    defp purge_modules(modules) do
      for {module, _} <- modules do
        :code.delete(module)
        :code.purge(module)
      end
    end

    defp restore_env(key, nil), do: Application.delete_env(:threadline, key)
    defp restore_env(key, value), do: Application.put_env(:threadline, key, value)
  end

  defmodule Threadline.OperatorSurface.StressRouterAlternatePathTest do
    use ExUnit.Case, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.StressRouterTest.AlternateEndpoint

    setup_all do
      Application.put_env(
        :threadline,
        Threadline.OperatorSurface.StressRouterTest.AlternateEndpoint,
        secret_key_base: String.duplicate("a", 64),
        live_view: [signing_salt: String.duplicate("a", 8)],
        render_errors: [view: Threadline.OperatorSurface.StressRouterTest.Layouts]
      )

      original_authorized = Application.get_env(:threadline, :stress_router_authorized)
      original_interval = Application.get_env(:threadline, :coverage_poll_ms)
      Application.put_env(:threadline, :stress_router_authorized, true)
      Application.put_env(:threadline, :coverage_poll_ms, 5_000)

      on_exit(fn ->
        restore_env(:stress_router_authorized, original_authorized)
        restore_env(:coverage_poll_ms, original_interval)
      end)

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      Application.put_env(:threadline, :stress_router_authorized, true)
      {:ok, conn: build_conn()}
    end

    test "stress navigation preserves a non-audit mount path", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/ops/__stress?story=page.timeline.empty&category=page&theme=light")

      assert html =~ ~s|data-tl-theme="light"|
      assert html =~ ~s|href="/ops/__stress"|
      assert html =~ ~s|href="/ops/__stress?category=foundation"|
      assert html =~ ~s|/ops/__stress?category=page&amp;story=page.home.happy&amp;theme=light|
      refute html =~ ~s|href="/audit/__stress|
    end

    defp restore_env(key, nil), do: Application.delete_env(:threadline, key)
    defp restore_env(key, value), do: Application.put_env(:threadline, key, value)
  end
end
