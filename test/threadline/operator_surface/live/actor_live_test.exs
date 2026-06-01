if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.ActorLiveTest.Layouts do
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

  defmodule Threadline.OperatorSurface.ActorLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.ActorLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.ActorLiveTest.ScopedRouter do
    use Phoenix.Router
    import Ecto.Query
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.ActorLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit_scoped",
        authorize_fn: &__MODULE__.auth/1,
        scope_query_fn: &__MODULE__.scope_operator_query/3
      )
    end

    def auth(_socket), do: {:ok, %{source: "support"}}

    def scope_operator_query(query, %{source: source}, %{surface: :actor_history}) do
      where(query, [at], at.source == ^source)
    end

    def scope_operator_query(query, _scope, _context), do: query
  end

  defmodule Threadline.OperatorSurface.ActorLiveTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_key",
      signing_salt: "v8q+QWvj"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.ActorLiveTest.Router)
  end

  defmodule Threadline.OperatorSurface.ActorLiveTest.ScopedEndpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_actor_scoped_key",
      signing_salt: "v8q+QWvj"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.ActorLiveTest.ScopedRouter)
  end

  defmodule Threadline.OperatorSurface.Live.ActorLiveTest do
    use ExUnit.Case, async: true
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.ActorLiveTest.Endpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.ActorLiveTest.Endpoint,
        secret_key_base: "x" |> String.duplicate(64),
        live_view: [signing_salt: "x" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.ActorLiveTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    test "Case 1: Renders invalid actor reference for invalid kind", %{conn: conn} do
      assert {:ok, _lv, html} = live(conn, "/audit/actors/non_existent_kind_xyz/123")
      assert html =~ "Invalid Actor Reference"
    end

    test "Case 2: Renders distinct empty state if actor has NEVER recorded an event", %{
      conn: conn
    } do
      assert {:ok, _lv, html} = live(conn, "/audit/actors/user/no_events_ever")
      assert html =~ "This actor has never recorded any events."
    end

    test "Case 3: Renders window empty state if actor has events but none in window", %{
      conn: conn
    } do
      repo = Threadline.Test.Repo

      # Insert an event older than 24h (the default window)
      repo.insert!(
        Threadline.Capture.AuditTransaction.changeset(%{
          txid: :rand.uniform(1_000_000_000),
          occurred_at: DateTime.utc_now() |> DateTime.add(-48, :hour),
          actor_ref: %{"type" => "user", "id" => "window_test"}
        })
      )

      assert {:ok, _lv, html} = live(conn, "/audit/actors/user/window_test")
      assert html =~ "No events found in the selected time window."
    end

    test "Case 4: Renders transactions and deep links to incident drill-down", %{conn: conn} do
      repo = Threadline.Test.Repo

      txn =
        repo.insert!(
          Threadline.Capture.AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now(),
            actor_ref: %{"type" => "user", "id" => "tx_test"}
          })
        )

      assert {:ok, lv, html} = live(conn, "/audit/actors/user/tx_test")
      assert html =~ "Actor: user / tx_test"
      assert html =~ "phx-viewport-top"
      assert html =~ "phx-viewport-bottom"
      assert html =~ txn.id
      assert html =~ "/audit/transactions/#{txn.id}"

      # Test time window change
      html_7d = render_click(lv, "set-window", %{"hours" => "168"})
      assert html_7d =~ "active"

      # Verify dummy event handlers for pagination
      render_hook(lv, "prev-page", %{})
      render_hook(lv, "next-page", %{})
    end

    describe "surface header (Phase 66)" do
      test "does not render the surface badge linking to /audit/coverage when coverage is disabled",
           %{
             conn: conn
           } do
        {:ok, _lv, html} = live(conn, "/audit/actors/user/surface_header_test")

        # Surface header tl-topbar (BEM operator surface component)
        assert html =~ ~s|class="tl-topbar"|

        # Badge link to /audit/coverage (D-31d) should be hidden
        refute html =~ ~s|href="/audit/coverage"|
      end
    end
  end

  defmodule Threadline.OperatorSurface.Live.ActorLiveScopedTest do
    use ExUnit.Case, async: true
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.ActorLiveTest.ScopedEndpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.ActorLiveTest.ScopedEndpoint,
        secret_key_base: "z" |> String.duplicate(64),
        live_view: [signing_salt: "z" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.ActorLiveTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    test "scoped actor history hides out-of-scope actor events", %{conn: conn} do
      repo = Threadline.Test.Repo

      repo.insert!(
        Threadline.Capture.AuditTransaction.changeset(%{
          txid: :rand.uniform(1_000_000_000),
          occurred_at: DateTime.utc_now(),
          actor_ref: %{"type" => "user", "id" => "scoped_actor"},
          source: "admin"
        })
      )

      assert {:ok, _lv, html} = live(conn, "/audit_scoped/actors/user/scoped_actor")
      assert html =~ "This actor has never recorded any events."
      refute html =~ "View Incident"
    end
  end
end
