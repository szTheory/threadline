if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.TransactionLiveTest.Layouts do
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

  defmodule Threadline.OperatorSurface.TransactionLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.TransactionLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.TransactionLiveTest.Endpoint do
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
    plug(Threadline.OperatorSurface.TransactionLiveTest.Router)
  end

  defmodule Threadline.OperatorSurface.TransactionLiveTest do
    use ExUnit.Case, async: true
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.TransactionLiveTest.Endpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.TransactionLiveTest.Endpoint,
        secret_key_base: "x" |> String.duplicate(64),
        live_view: [signing_salt: "x" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.TransactionLiveTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    test "Case 1: Renders explicit not-found state for missing transaction ID", %{conn: conn} do
      uuid = Ecto.UUID.generate()
      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{uuid}")

      assert html =~
               "Transaction Not Found - The requested transaction ID does not exist or has been purged by the retention policy."
    end

    test "Case 2: Renders bundle header details (actor, action) for valid transaction ID", %{
      conn: conn
    } do
      # Insert dummy data to satisfy `Threadline.incident_bundle`
      repo = Threadline.Test.Repo

      txn =
        repo.insert!(
          Threadline.Capture.AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          })
        )

      # For now just checking if the header renders, we can test more specifically when we add actor/action data.
      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")
      assert html =~ "Transaction:"
      assert html =~ txn.id
    end

    test "Case 3: Renders 'No Changes Recorded' empty state when bundle.changes is empty", %{
      conn: conn
    } do
      repo = Threadline.Test.Repo

      txn =
        repo.insert!(
          Threadline.Capture.AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          })
        )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")
      assert html =~ "No Changes Recorded"
    end

    test "Case 4: Renders change row with DOM virtualization", %{conn: conn} do
      repo = Threadline.Test.Repo

      txn =
        repo.insert!(
          Threadline.Capture.AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          })
        )

      _change =
        repo.insert!(
          Threadline.Capture.AuditChange.changeset(%{
            transaction_id: txn.id,
            table_schema: "public",
            table_name: "users",
            table_pk: %{"id" => 1},
            op: "update",
            data_after: %{"id" => 1, "email" => "test@example.com"},
            changed_fields: ["email"],
            changed_from: %{"email" => "old@example.com"},
            captured_at: DateTime.utc_now()
          })
        )

      assert {:ok, lv, html} = live(conn, "/audit/transactions/#{txn.id}")
      assert html =~ "phx-viewport-top"
      assert html =~ "phx-viewport-bottom"
      assert html =~ "UPDATE"
      assert html =~ "users"
      assert html =~ "test@example.com"
      assert html =~ "old@example.com"

      # Verify dummy event handlers
      render_hook(lv, "prev-page", %{})
      render_hook(lv, "next-page", %{})
    end

    describe "surface header (Phase 66)" do
      test "renders the surface badge linking to /audit/coverage with locked literals", %{
        conn: conn
      } do
        repo = Threadline.Test.Repo

        txn =
          repo.insert!(
            Threadline.Capture.AuditTransaction.changeset(%{
              txid: :rand.uniform(1_000_000_000),
              occurred_at: DateTime.utc_now()
            })
          )

        {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

        # Surface header threadline-ui-header (Plan 03 component + style.ex rule)
        assert html =~ ~s|class="threadline-ui-header"|

        # Badge link to /audit/coverage (D-31d — plain anchor, not live_patch)
        assert html =~ ~s|href="/audit/coverage"|

        # One of the two locked literals is present (D-31a — never hidden).
        # Combined regex avoids Elixir's strict-boolean `or` gotcha.
        assert html =~ ~r/(All covered|\d+ uncovered)/
      end
    end
  end
end
