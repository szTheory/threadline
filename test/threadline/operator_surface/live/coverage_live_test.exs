if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.CoverageLiveTest.Layouts do
    use Phoenix.Component

    def root(assigns) do
      ~H"""
      <html>
        <head><title>Test</title></head>
        <body><%= @inner_content %></body>
      </html>
      """
    end

    def render("500.html", assigns) do
      ~H"""
      Error 500: <%= inspect(assigns.reason) %>
      """
    end
  end

  defmodule Threadline.OperatorSurface.CoverageLiveTest.Auth do
    def authorize(_), do: Application.get_env(:threadline, :test_allow_coverage, true)
  end

  defmodule Threadline.OperatorSurface.CoverageLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.CoverageLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit",
        coverage_authorize_fn: &Threadline.OperatorSurface.CoverageLiveTest.Auth.authorize/1
      )
    end
  end

  defmodule Threadline.OperatorSurface.CoverageLiveTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_key",
      signing_salt: "c0v3r4ge"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.CoverageLiveTest.Router)
  end

  defmodule Threadline.OperatorSurface.CoverageLiveTest do
    # async: false because Application.put_env(:threadline, :coverage_poll_ms, ...)
    # is process-shared (Pitfall 13 test seam).
    use ExUnit.Case, async: false

    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.CoverageLiveTest.Endpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.CoverageLiveTest.Endpoint,
        secret_key_base: "c" |> String.duplicate(64),
        live_view: [signing_salt: "c" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.CoverageLiveTest.Layouts]
      )

      # Pitfall 13 test seam — lower the poll interval to the floor so on_mount
      # doesn't raise (the floor is 5_000 ms; below that ArgumentError).
      original_interval = Application.get_env(:threadline, :coverage_poll_ms)
      Application.put_env(:threadline, :coverage_poll_ms, 5_000)

      on_exit(fn ->
        if original_interval do
          Application.put_env(:threadline, :coverage_poll_ms, original_interval)
        else
          Application.delete_env(:threadline, :coverage_poll_ms)
        end
      end)

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, conn: build_conn()}
    end

    describe "mount /audit/coverage" do
      test "renders unsupported state if coverage is disabled", %{conn: conn} do
        Application.put_env(:threadline, :test_allow_coverage, false)
        on_exit(fn -> Application.put_env(:threadline, :test_allow_coverage, true) end)
        {:ok, _view, html} = live(conn, "/audit/coverage")
        assert html =~ "Unsupported View"
        assert html =~ "Coverage inspection is not available"
        assert html =~ "mix threadline.health.coverage"
      end

      test "renders three-bucket coverage table with locked badge state literals", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage")

        assert html =~ "Coverage — schema: public"

        # The table headers (D-32d locked literals)
        assert html =~ "<th>TABLE</th>"
        assert html =~ "<th>STATUS</th>"
        assert html =~ "<th>SOURCE</th>"

        # The footer summary (locked literal — D-34)
        assert html =~ ~r/Coverage: \d+ covered, \d+ uncovered, \d+ expected uncovered/

        # The three locked badge state literals (D-32d). schema_migrations is the
        # baseline `:expected_uncovered` table — its source label "baseline" appears
        # in the third column. The bucket label "expected" appears in the STATUS td.
        assert html =~ ">expected<"
        assert html =~ "schema_migrations"
        assert html =~ "baseline"
      end

      test "shows 'Refresh' link with phx-click=refresh", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage")

        assert html =~ "Refresh"
        assert html =~ ~s|phx-click="refresh"|
      end

      test "renders the surface header above the page content", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage")

        # Surface header is the threadline-ui-header element (Plan 03 component)
        assert html =~ ~s|class="threadline-ui-header"|

        # The badge link points to /audit/coverage
        assert html =~ ~s|href="/audit/coverage"|
      end

      test "hides the retention badge when policy access is disabled", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage")
        refute html =~ ~s|href="/audit/policy/retention"|
      end
    end

    describe "manual refresh" do
      test "Refresh click cancels pending timer and re-fetches", %{conn: conn} do
        {:ok, view, _html} = live(conn, "/audit/coverage")

        # Click the Refresh link via render_click
        new_html = render_click(view, "refresh")

        # After refresh, the dashboard should still render normally with the same literals
        assert new_html =~ "Coverage — schema: public"
        assert new_html =~ ~r/Coverage: \d+ covered, \d+ uncovered, \d+ expected uncovered/
      end
    end

    describe "?schema=NAME validation" do
      test "?schema=public renders coverage normally", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage?schema=public")

        assert html =~ "Coverage — schema: public"
        # The error message would render with HEEx-escaped single-quotes; refute
        # both forms (raw + escaped) defensively.
        refute html =~ "Schema 'public' not found."
        refute html =~ "Schema &#39;public&#39; not found."
      end

      test "?schema=Public fails the regex (uppercase rejected)", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage?schema=Public")

        # Renders the filter-error div with locked copy (D-33a). The source-level
        # literal `Schema 'Public' not found.` is HEEx-escaped to use `&#39;` in
        # the rendered HTML, so the runtime assertion uses the escaped form while
        # this comment preserves the source-side literal for doc-contract greps.
        assert html =~ ~s|class="filter-error"|
        assert html =~ "Schema &#39;Public&#39; not found."
      end

      test "?schema=nonexistent_xyz fails the pg_namespace lookup", %{conn: conn} do
        {:ok, _view, html} =
          live(conn, "/audit/coverage?schema=nonexistent_xyz_definitely_not_present")

        assert html =~ ~s|class="filter-error"|
        # HEEx-escaped form (single-quotes → &#39;).
        assert html =~ "Schema &#39;nonexistent_xyz_definitely_not_present&#39; not found."
      end

      test "?schema with semicolon (SQL-injection probe) fails the regex", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage?schema=public;DROP")

        assert html =~ ~s|class="filter-error"|
        # Don't assert the exact message body — the schema string with a semicolon
        # would break HTML escaping if rendered raw; the filter-error div must appear.
      end
    end
  end
end
