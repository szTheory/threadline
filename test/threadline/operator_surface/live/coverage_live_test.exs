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
        assert html =~ "Coverage unavailable"
        assert html =~ "Coverage is unavailable in this support lane"
        assert html =~ "This is not a permissions issue."
        assert html =~ "mix threadline.health.coverage"
      end

      test "renders three-bucket coverage table with operator-facing badge labels", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage")

        assert html =~ "Audit coverage"
        assert html =~ "Schema: public"
        assert html =~ ~s|aria-label="Coverage schema"|
        assert html =~ ~s|name="schema"|
        assert html =~ "Apply schema"

        # The table headers (D-32d locked literals)
        assert html =~ "<th>TABLE</th>"
        assert html =~ "<th>STATUS</th>"
        assert html =~ "<th>SOURCE</th>"

        assert html =~
                 "Audit readiness by table: table coverage status shows which tracked tables are covered, need capture, or are expected gaps."

        # The three coverage buckets still render; schema_migrations is the
        # baseline `:expected_uncovered` table — its source label "baseline" appears
        # in the third column. The STATUS column uses operator-facing labels.
        assert html =~ ">Expected gap<"
        assert html =~ ">Covered<"
        assert html =~ "schema_migrations"
        assert html =~ "baseline"
        refute html =~ "capture is complete"
        refute html =~ "complete timeline answers"
        refute html =~ "Open timeline"
      end

      test "uncovered rows render Add capture disclosure with command and verify follow-up",
           %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage")

        assert html =~ "Add capture"
        assert html =~ ~s|<details class="tl-row-action tl-row-action--capture">|
        assert html =~ ~s|<summary class="tl-row-action__summary">|
        assert html =~ ~s|class="tl-command-copy"|
        assert html =~ "mix threadline.gen.triggers --tables"
        assert html =~ "Run mix threadline.verify_coverage after applying the migration."
        assert html =~ ~s|data-tl-copy="mix threadline.gen.triggers --tables|
        refute html =~ ~s|<span class="tl-remediation__action">Add capture</span>|

        assert html =~ "Timeline results may be incomplete for these tables."
        assert html =~ "Add capture, verify coverage, then rerun the timeline search."

        row_actions =
          Regex.scan(~r/<td data-label="Actions" class="tl-table__actions">(.*?)<\/td>/s, html)
          |> Enum.map(fn [_, action_html] -> action_html end)

        assert row_actions != []
        refute Enum.any?(row_actions, &String.contains?(&1, "Timeline may be incomplete"))
      end

      test "expected-gap rows use expected styling and do not render Add capture", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage")

        expected_row =
          Regex.run(~r/<tr class="tl-table__row--expected".*?<\/tr>/s, html)
          |> List.first()

        assert expected_row =~ "Expected gap"
        assert expected_row =~ "tl-chip--warning"
        refute expected_row =~ "Add capture"
        refute expected_row =~ "tl-row-action--capture"
        refute expected_row =~ "mix threadline.gen.triggers --tables"
      end

      test "expected-gap metric remains present without footer repetition", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage")

        assert html =~ ">Expected gaps<"
        refute html =~ ~r/Coverage: \d+ covered, \d+ need capture/
      end

      test "shows 'Refresh' link with phx-click=refresh", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage")

        assert html =~ "Refresh"
        assert html =~ ~s|phx-click="refresh"|
      end

      test "success branch renders the header via UI.page_header and drops the command shell (D-12)",
           %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage")

        # The hand-rolled synthetic command shell is gone — both the markup class
        # and the dead BEM children must not appear anywhere in the rendered page.
        refute html =~ "tl-coverage-command"

        # page_header emits the canonical page chrome: a single <h1 class="tl-page__title">
        # with the title, the lede, the last-checked meta line, and the Refresh action.
        assert html =~ ~s|<header class="tl-page__header">|
        assert html =~ ~s|class="tl-page__title"|
        assert html =~ "Audit coverage"
        assert html =~ ~s|class="tl-page__lede"|
        assert html =~ ~s|class="tl-page__meta"|
        assert html =~ "Schema: public"

        # Exactly one <h1> on the page (no hand-rolled second heading).
        assert html |> String.split("<h1") |> length() == 2

        # The legit repeated-item metric tiles survive the flatten.
        assert html =~ ~s|class="tl-card--metric"|
        assert html =~ ">Covered<"
        assert html =~ ">Needs capture<"
        assert html =~ ">Expected gaps<"

        # The metric grid keeps its generic summary-grid boundary (not the removed
        # tl-coverage-command__metrics modifier).
        assert html =~ ~s|class="tl-summary-grid"|
        assert html =~ "table coverage status shows which tracked tables are covered"
        refute html =~ "complete timeline answers"
      end

      test "form-error branch renders the header via UI.page_header", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage?schema=Public")

        refute html =~ "tl-coverage-command"
        assert html =~ ~s|<header class="tl-page__header">|
        assert html =~ ~s|class="tl-page__title"|
        assert html =~ "Audit coverage"
        assert html =~ "Schema: Public"
        assert html |> String.split("<h1") |> length() == 2
      end

      test "renders the surface header above the page content", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage")

        # Surface header is the tl-topbar element.
        assert html =~ ~s|class="tl-topbar"|

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
        assert new_html =~ "Audit coverage"
        assert new_html =~ "Schema: public"
      end
    end

    describe "?schema=NAME validation" do
      test "?schema=public renders coverage normally", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage?schema=public")

        assert html =~ "Audit coverage"
        assert html =~ "Schema: public"
        # The error message would render with HEEx-escaped single-quotes; refute
        # both forms (raw + escaped) defensively.
        refute html =~ "Schema 'public' not found."
        refute html =~ "Schema &#39;public&#39; not found."
      end

      test "?schema=Public fails the regex (uppercase rejected)", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage?schema=Public")

        # Renders the error alert with locked copy (D-33a). The source-level
        # literal `Schema 'Public' not found.` is HEEx-escaped to use `&#39;` in
        # the rendered HTML, so the runtime assertion uses the escaped form while
        # this comment preserves the source-side literal for doc-contract greps.
        assert html =~ ~s|tl-alert--error|
        assert html =~ "Schema &#39;Public&#39; not found."
      end

      test "?schema=nonexistent_xyz fails the pg_namespace lookup", %{conn: conn} do
        {:ok, _view, html} =
          live(conn, "/audit/coverage?schema=nonexistent_xyz_definitely_not_present")

        assert html =~ ~s|tl-alert--error|
        # HEEx-escaped form (single-quotes → &#39;).
        assert html =~ "Schema &#39;nonexistent_xyz_definitely_not_present&#39; not found."
      end

      test "?schema with semicolon (SQL-injection probe) fails the regex", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/coverage?schema=public;DROP")

        assert html =~ ~s|tl-alert--error|
        # Don't assert the exact message body — the schema string with a semicolon
        # would break HTML escaping if rendered raw; the error alert must appear.
      end

      test "schema picker patches to the selected schema", %{conn: conn} do
        {:ok, view, _html} = live(conn, "/audit/coverage")

        render_submit(view, "select-schema", %{"schema" => "public"})

        assert_patch(view, "/audit/coverage?schema=public")
      end

      test "non-public schema row activity links include table_schema", %{conn: conn} do
        Ecto.Adapters.SQL.query!(
          Threadline.Test.Repo,
          "CREATE SCHEMA IF NOT EXISTS tenant_demo",
          []
        )

        Ecto.Adapters.SQL.query!(
          Threadline.Test.Repo,
          "CREATE TABLE IF NOT EXISTS tenant_demo.coverage_link_target (id bigint PRIMARY KEY)",
          []
        )

        Ecto.Adapters.SQL.query!(
          Threadline.Test.Repo,
          Threadline.Capture.TriggerSQL.create_trigger("tenant_demo.coverage_link_target")
        )

        on_exit(fn ->
          Ecto.Adapters.SQL.query!(
            Threadline.Test.Repo,
            "DROP TABLE IF EXISTS tenant_demo.coverage_link_target CASCADE",
            []
          )

          Ecto.Adapters.SQL.query!(Threadline.Test.Repo, "DROP SCHEMA IF EXISTS tenant_demo", [])
        end)

        {:ok, _view, html} = live(conn, "/audit/coverage?schema=tenant_demo")

        assert html =~ "Schema: tenant_demo"
        assert html =~ "coverage_link_target"
        assert html =~ "table_schema=tenant_demo"
        assert html =~ "table=coverage_link_target"
      end
    end
  end
end
