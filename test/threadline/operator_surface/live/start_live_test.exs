if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.StartLiveTest.Layouts do
    use Phoenix.Component

    def root(assigns) do
      ~H"""
      <html>
        <head><title>Test</title></head>
        <body><%= @inner_content %></body>
      </html>
      """
    end
  end

  defmodule Threadline.OperatorSurface.StartLiveTest.Auth do
    def authorize(_), do: true

    def coverage_authorize(_),
      do: Application.get_env(:threadline, :test_start_live_coverage, true)

    def scoped_authorize(_), do: {:ok, %{tenant_id: "support"}}
  end

  defmodule Threadline.OperatorSurface.StartLiveTest.FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

  defmodule Threadline.OperatorSurface.StartLiveTest.FakeTicketReply do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "ticket_replies" do
      field(:body, :string)
    end
  end

  defmodule Threadline.OperatorSurface.StartLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.StartLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit",
        repo: Threadline.Test.Repo,
        schemas: %{
          "ticket_replies" => Threadline.OperatorSurface.StartLiveTest.FakeTicketReply,
          "users" => Threadline.OperatorSurface.StartLiveTest.FakeUser
        },
        coverage_authorize_fn:
          &Threadline.OperatorSurface.StartLiveTest.Auth.coverage_authorize/1,
        policy_authorize_fn: &Threadline.OperatorSurface.StartLiveTest.Auth.authorize/1,
        evidence_authorize_fn: &Threadline.OperatorSurface.StartLiveTest.Auth.authorize/1,
        export_authorize_fn: &Threadline.OperatorSurface.StartLiveTest.Auth.authorize/1
      )
    end
  end

  defmodule Threadline.OperatorSurface.StartLiveTest.ScopedRouter do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.StartLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit_scoped",
        repo: Threadline.Test.Repo,
        schemas: %{
          "ticket_replies" => Threadline.OperatorSurface.StartLiveTest.FakeTicketReply,
          "users" => Threadline.OperatorSurface.StartLiveTest.FakeUser
        },
        authorize_fn: &Threadline.OperatorSurface.StartLiveTest.Auth.scoped_authorize/1,
        coverage_authorize_fn:
          &Threadline.OperatorSurface.StartLiveTest.Auth.coverage_authorize/1,
        policy_authorize_fn: &Threadline.OperatorSurface.StartLiveTest.Auth.authorize/1,
        evidence_authorize_fn: &Threadline.OperatorSurface.StartLiveTest.Auth.authorize/1,
        export_authorize_fn: &Threadline.OperatorSurface.StartLiveTest.Auth.authorize/1
      )
    end
  end

  defmodule Threadline.OperatorSurface.StartLiveTest.SystemRouter do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.StartLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit_system",
        repo: Threadline.Test.Repo,
        schemas: %{
          "ticket_replies" => Threadline.OperatorSurface.StartLiveTest.FakeTicketReply,
          "users" => Threadline.OperatorSurface.StartLiveTest.FakeUser
        },
        theme: :system,
        coverage_authorize_fn:
          &Threadline.OperatorSurface.StartLiveTest.Auth.coverage_authorize/1,
        policy_authorize_fn: &Threadline.OperatorSurface.StartLiveTest.Auth.authorize/1,
        evidence_authorize_fn: &Threadline.OperatorSurface.StartLiveTest.Auth.authorize/1,
        export_authorize_fn: &Threadline.OperatorSurface.StartLiveTest.Auth.authorize/1
      )
    end
  end

  defmodule Threadline.OperatorSurface.StartLiveTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_start_key",
      signing_salt: "start-home"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.StartLiveTest.Router)
  end

  defmodule Threadline.OperatorSurface.StartLiveTest.ScopedEndpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_start_scoped_key",
      signing_salt: "start-scoped"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.StartLiveTest.ScopedRouter)
  end

  defmodule Threadline.OperatorSurface.StartLiveTest.SystemEndpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_start_system_key",
      signing_salt: "start-system"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.StartLiveTest.SystemRouter)
  end

  defmodule Threadline.OperatorSurface.Live.StartLiveTest do
    use Threadline.DataCase, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias Threadline.Governance.ExportJob
    alias Threadline.Governance.RetentionRun
    alias Threadline.Governance.SavedView
    alias Threadline.Semantics.ActorRef

    @endpoint Threadline.OperatorSurface.StartLiveTest.Endpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.StartLiveTest.Endpoint,
        secret_key_base: "s" |> String.duplicate(64),
        live_view: [signing_salt: "s" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.StartLiveTest.Layouts]
      )

      original_interval = Application.get_env(:threadline, :coverage_poll_ms)
      original_start_live_coverage = Application.get_env(:threadline, :test_start_live_coverage)
      Application.put_env(:threadline, :coverage_poll_ms, 5_000)
      Application.put_env(:threadline, :test_start_live_coverage, true)

      on_exit(fn ->
        if original_interval do
          Application.put_env(:threadline, :coverage_poll_ms, original_interval)
        else
          Application.delete_env(:threadline, :coverage_poll_ms)
        end

        if is_nil(original_start_live_coverage) do
          Application.delete_env(:threadline, :test_start_live_coverage)
        else
          Application.put_env(
            :threadline,
            :test_start_live_coverage,
            original_start_live_coverage
          )
        end
      end)

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      Threadline.Test.Repo.delete_all(SavedView)
      Threadline.Test.Repo.delete_all(ExportJob)
      Threadline.Test.Repo.delete_all(RetentionRun)

      {:ok, actor_ref} = ActorRef.new(:user, "home-operator")

      conn =
        build_conn()
        |> Plug.Test.init_test_session(
          threadline_actor_ref: Jason.encode!(ActorRef.to_map(actor_ref))
        )

      {:ok, conn: conn, actor_ref: actor_ref}
    end

    test "renders Home as an orientation hub with existing destinations", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/audit")

      assert html =~ "Follow what happened."
      refute html =~ ~s|class="tl-home__eyebrow">Threadline</p>|

      assert html =~ "Find"
      assert html =~ "What changed?"
      assert html =~ ~s|href="/audit/timeline"|

      assert html =~ "Verify"
      assert html =~ "Is everything captured?"
      assert html =~ ~s|href="/audit/coverage"|

      assert html =~ "Prove"
      assert html =~ "Prove and export"
      assert html =~ ~s|href="/audit/evidence"|
      assert html =~ ~s|href="/audit/policy/redaction"|
      assert html =~ ~s|href="/audit/policy/retention"|
      assert html =~ ~s|href="/audit/exports"|
      assert html =~ "tl-home__prove-handoff"

      refute html =~ ~s|href="/audit/records"|
      refute html =~ ~s|href="/audit/correlations"|
      refute html =~ ~s|href="/audit/row-history"|
    end

    test "renders dark theme by default on the surface root", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/audit")

      assert html =~ ~s|data-tl-theme="dark"|
    end

    test "renders all-clear health as a quiet success", %{conn: conn} do
      Application.put_env(:threadline, :test_start_live_coverage, false)
      on_exit(fn -> Application.put_env(:threadline, :test_start_live_coverage, true) end)

      {:ok, _view, html} = live(conn, "/audit")

      assert html =~ "All systems healthy"
      assert html =~ "tl-chip tl-chip--success"
    end

    test "renders coverage gaps as an action narrative distinct from topbar count", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/audit")

      assert html =~ ~s|href="/audit/coverage"|
      assert html =~ "tl-chip tl-chip--warning"
      assert html =~ "Close coverage gaps before trusting Timeline answers"

      refute home_health(html) =~
               ~r/class="tl-chip tl-chip--warning"[^>]*>\s*\d+ tables need audit coverage\s*</
    end

    test "renders current actor failed exports as danger without leaking other actors", %{
      conn: conn,
      actor_ref: actor_ref
    } do
      {:ok, other_actor} = ActorRef.new(:user, "other-operator")
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      insert_export!(actor_ref, "failed", now)
      insert_export!(other_actor, "failed", now)

      {:ok, _view, html} = live(conn, "/audit")

      assert html =~ ~s|href="/audit/exports"|
      assert html =~ "tl-chip tl-chip--danger"
      assert html =~ "1 failed export needs attention"
      refute html =~ "2 failed exports"
    end

    test "renders latest failed retention run as danger", %{conn: conn} do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      %RetentionRun{}
      |> RetentionRun.changeset(%{
        status: "failed",
        started_at: now,
        completed_at: now,
        deleted_count: 0
      })
      |> Threadline.Test.Repo.insert!()

      {:ok, _view, html} = live(conn, "/audit")

      assert html =~ ~s|href="/audit/policy/retention"|
      assert html =~ "Latest retention run failed"
      assert html =~ "tl-chip tl-chip--danger"
    end

    test "renders actor-owned saved view resume links with canonical timeline URLs", %{
      conn: conn,
      actor_ref: actor_ref
    } do
      {:ok, other_actor} = ActorRef.new(:user, "other-operator")

      insert_view!(actor_ref, "Recent deletes", %{
        "table" => "posts",
        "actor_kind" => "",
        "actor_id" => ""
      })

      insert_view!(actor_ref, "Closed this week", %{
        "table" => "tickets",
        "from" => "2026-06-01T00:00",
        "to" => "2026-06-07T23:59"
      })

      insert_view!(other_actor, "Other actor scope", %{"table" => "secrets"})

      {:ok, view, html} = live(conn, "/audit")

      assert html =~ "Pick up where you left off"
      assert html =~ "Recent deletes"
      assert has_element?(view, ~s|a[href="/audit/timeline?table=posts"]|, "Recent deletes")
      assert html =~ "Closed this week"

      assert has_element?(
               view,
               ~s|a[href="/audit/timeline?from=2026-06-01T00%3A00&to=2026-06-07T23%3A59&table=tickets"]|,
               "Closed this week"
             )

      refute html =~ "Other actor scope"
      refute html =~ "secrets"
    end

    test "renders earned record-first lookup without Timeline filter builder controls", %{
      conn: conn
    } do
      {:ok, view, html} = live(conn, "/audit")

      assert html =~ ~s|data-earned-flow="EF1"|
      assert html =~ ~s|data-persona="P2"|
      assert html =~ ~s|data-jtbd="J4"|
      assert html =~ ~s|name="record_lookup[table]"|
      assert html =~ ~s|name="record_lookup[record_id]"|

      assert has_element?(
               view,
               ~s|select[name="record_lookup[table]"] option[value="ticket_replies"]|
             )

      assert has_element?(view, ~s|select[name="record_lookup[table]"] option[value="users"]|)

      record_form = form_html(html, "open-row-history")

      for forbidden <- [
            ~s|name="filter[from]"|,
            ~s|name="filter[to]"|,
            ~s|name="filter[actor_kind]"|,
            ~s|name="filter[actor_id]"|,
            "query_dsl",
            "saved_search_builder"
          ] do
        refute record_form =~ forbidden
      end
    end

    test "record-first lookup navigates to first-class row history", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/audit")

      view
      |> form("#tl-record-lookup", %{
        "record_lookup" => %{"table" => "ticket_replies", "record_id" => " reply-123 "}
      })
      |> render_submit()

      assert_redirect(view, "/audit/rows/ticket_replies/reply-123")
    end

    test "record-first lookup validates blank and unmapped input without navigating", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/audit")

      assert view
             |> form("#tl-record-lookup", %{
               "record_lookup" => %{"table" => "", "record_id" => "row-1"}
             })
             |> render_submit() =~ "Choose a table to open row history."

      assert render_submit(view, "open-row-history", %{
               "record_lookup" => %{"table" => "secrets", "record_id" => "row-1"}
             }) =~ "Choose a mapped table from the list."

      assert view
             |> form("#tl-record-lookup", %{
               "record_lookup" => %{"table" => "ticket_replies", "record_id" => "   "}
             })
             |> render_submit() =~ "Enter a record id to open row history."
    end

    test "renders earned correlation shortcut and navigates with canonical query", %{conn: conn} do
      {:ok, view, html} = live(conn, "/audit")

      assert html =~ ~s|data-earned-flow="EF4"|
      assert html =~ ~s|data-persona="P1"|
      assert html =~ ~s|data-jtbd="J1"|
      assert html =~ ~s|name="correlation[correlation_id]"|

      view
      |> form("#tl-correlation-lookup", %{
        "correlation" => %{"correlation_id" => " incident 42/alpha "}
      })
      |> render_submit()

      assert_redirect(view, "/audit/timeline?correlation_id=incident+42%2Falpha")
    end

    test "correlation shortcut validates blank and overlong ids without navigating", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/audit")

      assert view
             |> form("#tl-correlation-lookup", %{
               "correlation" => %{"correlation_id" => "   "}
             })
             |> render_submit() =~ "Paste a correlation id to open Timeline."

      too_long = String.duplicate("a", 257)

      assert view
             |> form("#tl-correlation-lookup", %{
               "correlation" => %{"correlation_id" => too_long}
             })
             |> render_submit() =~ "Correlation ids must be 256 bytes or fewer."
    end

    test "renders honest resume empty state when the actor has no saved views", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/audit")

      assert html =~ "Pick up where you left off"
      assert html =~ "No saved timeline searches yet."
      refute html =~ ~s|class="tl-chip tl-chip--accent tl-home__view"|
    end

    test "Home source only includes earned flow shortcuts and no speculative builders" do
      src = File.read!("lib/threadline/operator_surface/live/start_live.ex")

      for forbidden <- [
            "advanced",
            "query_dsl",
            "bulk_export",
            "saved_search_builder",
            "export builder",
            "push_patch",
            ~s|href={"#\{@base_path}/records"}|,
            ~s|href={"#\{@base_path}/correlations"}|,
            ~s|href={"#\{@base_path}/row-history"}|
          ] do
        refute String.contains?(src, forbidden)
      end
    end

    defp insert_export!(actor_ref, status, started_at) do
      %ExportJob{}
      |> ExportJob.changeset(%{
        status: status,
        query_params: %{"table" => "tickets"},
        actor_ref: actor_ref,
        started_at: started_at
      })
      |> Threadline.Test.Repo.insert!()
    end

    defp insert_view!(actor_ref, name, filters) do
      %SavedView{}
      |> SavedView.changeset(%{
        name: name,
        actor_ref: actor_ref,
        filters: filters
      })
      |> Threadline.Test.Repo.insert!()
    end

    defp home_health(html) do
      Regex.run(~r/<div class="tl-home__health".*?<\/div>/s, html)
      |> List.first()
    end

    defp form_html(html, event) do
      Regex.run(~r/<form[^>]*phx-submit="#{event}".*?<\/form>/s, html)
      |> List.first()
    end
  end

  defmodule Threadline.OperatorSurface.Live.StartLiveScopedTest do
    use Threadline.DataCase, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias Threadline.Semantics.ActorRef

    @endpoint Threadline.OperatorSurface.StartLiveTest.ScopedEndpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.StartLiveTest.ScopedEndpoint,
        secret_key_base: "z" |> String.duplicate(64),
        live_view: [signing_salt: "z" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.StartLiveTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, actor_ref} = ActorRef.new(:user, "home-operator")

      conn =
        build_conn()
        |> Plug.Test.init_test_session(
          threadline_actor_ref: Jason.encode!(ActorRef.to_map(actor_ref))
        )

      {:ok, conn: conn}
    end

    test "renders scoped affordance when Home is mounted with an operator scope", %{conn: conn} do
      {:ok, view, html} = live(conn, "/audit_scoped")

      assert html =~ "Scoped view"
      assert has_element?(view, ~s|[data-testid="operator-scope"]|, "Scoped view")
      assert has_element?(view, ~s|a[href="/audit_scoped/timeline"]|, "Timeline")
      assert has_element?(view, ~s|a[href="/audit_scoped/coverage"]|)
    end
  end

  defmodule Threadline.OperatorSurface.Live.StartLiveThemeTest do
    use Threadline.DataCase, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias Threadline.Semantics.ActorRef

    @endpoint Threadline.OperatorSurface.StartLiveTest.SystemEndpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.StartLiveTest.SystemEndpoint,
        secret_key_base: "y" |> String.duplicate(64),
        live_view: [signing_salt: "y" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.StartLiveTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, actor_ref} = ActorRef.new(:user, "home-operator")

      conn =
        build_conn()
        |> Plug.Test.init_test_session(
          threadline_actor_ref: Jason.encode!(ActorRef.to_map(actor_ref))
        )

      {:ok, conn: conn}
    end

    test "renders system theme from router config on the surface root", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/audit_system")

      assert html =~ ~s|data-tl-theme="system"|
    end
  end
end
