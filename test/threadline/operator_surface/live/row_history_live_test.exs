if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.RowHistoryLiveTest.FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

  defmodule Threadline.OperatorSurface.RowHistoryLiveTest.FakeTicketReply do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "ticket_replies" do
      field(:body, :string)
    end
  end

  defmodule Threadline.OperatorSurface.RowHistoryLiveTest.Layouts do
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

  defmodule Threadline.OperatorSurface.RowHistoryLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.RowHistoryLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit",
        schemas: %{
          "ticket_replies" => Threadline.OperatorSurface.RowHistoryLiveTest.FakeTicketReply,
          "users" => Threadline.OperatorSurface.RowHistoryLiveTest.FakeUser
        }
      )
    end
  end

  defmodule Threadline.OperatorSurface.RowHistoryLiveTest.ScopedRouter do
    use Phoenix.Router
    import Ecto.Query
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.RowHistoryLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit_scoped",
        authorize_fn: &__MODULE__.auth/1,
        scope_query_fn: &__MODULE__.scope_operator_query/3,
        schemas: %{"users" => Threadline.OperatorSurface.RowHistoryLiveTest.FakeUser}
      )
    end

    def auth(_socket), do: {:ok, %{source: "support"}}

    def scope_operator_query(query, %{source: source}, %{surface: :row_history}) do
      source_txn_ids =
        from(at in Threadline.Capture.AuditTransaction,
          where: at.source == ^source,
          select: at.id
        )

      from(ac in query, where: ac.transaction_id in subquery(source_txn_ids))
    end

    def scope_operator_query(query, _scope, _context), do: query
  end

  defmodule Threadline.OperatorSurface.RowHistoryLiveTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_row_history_key",
      signing_salt: "v8q+QWvj"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.RowHistoryLiveTest.Router)
  end

  defmodule Threadline.OperatorSurface.RowHistoryLiveTest.ScopedEndpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_row_history_scoped_key",
      signing_salt: "v8q+QWvj"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.RowHistoryLiveTest.ScopedRouter)
  end

  defmodule Threadline.OperatorSurface.RowHistoryLiveTest do
    use ExUnit.Case, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias Threadline.Capture.{AuditChange, AuditTransaction}

    @endpoint Threadline.OperatorSurface.RowHistoryLiveTest.Endpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.RowHistoryLiveTest.Endpoint,
        secret_key_base: "r" |> String.duplicate(64),
        live_view: [signing_salt: "r" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.RowHistoryLiveTest.Layouts]
      )

      Application.put_env(:threadline, Threadline.OperatorSurface.RowHistoryLiveTest.ScopedEndpoint,
        secret_key_base: "s" |> String.duplicate(64),
        live_view: [signing_salt: "s" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.RowHistoryLiveTest.Layouts]
      )

      start_supervised!(@endpoint)
      start_supervised!(Threadline.OperatorSurface.RowHistoryLiveTest.ScopedEndpoint)
      :ok
    end

    setup do
      Threadline.Test.Repo.delete_all(AuditChange)
      Threadline.Test.Repo.delete_all(AuditTransaction)
      Threadline.Test.Repo.delete_all(Threadline.Semantics.AuditAction)
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    test "first-class row-history route renders EF2 shell without a transaction id", %{conn: conn} do
      captured_at = ~U[2026-10-03 12:00:00.000000Z]
      txn = insert_transaction(%{occurred_at: captured_at})

      insert_change(txn, %{
        table_name: "ticket_replies",
        table_pk: %{"id" => "reply-1"},
        data_after: %{"id" => "reply-1", "body" => "Customer-visible answer"},
        changed_fields: ["id", "body"],
        captured_at: captured_at
      })

      assert {:ok, _lv, html} = live(conn, "/audit/rows/ticket_replies/reply-1")

      assert html =~ ~s|data-testid="row-history-drawer"|
      assert html =~ ~s|data-earned-flow="EF2"|
      assert html =~ ~s|data-persona="P1"|
      assert html =~ ~s|data-jtbd="J2"|
      assert html =~ "Row history: ticket_replies / reply-1"
      assert html =~ "Customer-visible answer"
      refute html =~ "/transactions/"
    end

    test "unmapped table renders mapped-schema error without raising", %{conn: conn} do
      assert {:ok, _lv, html} = live(conn, "/audit/rows/not_mapped/row-1")

      assert html =~ "Table &#39;not_mapped&#39; is not mapped to an Ecto schema"
    end

    test "row-history component does not create atoms from untrusted route input" do
      source = File.read!("lib/threadline/operator_surface/live/row_history_component.ex")

      refute source =~ "String.to_atom("
      refute source =~ "String.to_existing_atom(assigns.table)"
      refute source =~ "String.to_existing_atom(table)"
    end

    test "first-class as_of changes patch under /rows and close returns to timeline", %{conn: conn} do
      captured_at = ~U[2026-10-03 12:00:00.000000Z]
      txn = insert_transaction(%{occurred_at: captured_at})

      insert_change(txn, %{
        table_name: "users",
        table_pk: %{"id" => "row-path-1"},
        data_after: %{"id" => "row-path-1", "name" => "Path Value"},
        changed_fields: ["id", "name"],
        captured_at: captured_at
      })

      assert {:ok, lv, html} = live(conn, "/audit/rows/users/row-path-1")
      assert html =~ ~s|href="/audit/timeline"|

      render_change(element(lv, "form"), %{"as_of" => "2026-10-03T12:00"})

      assert_patch(lv, "/audit/rows/users/row-path-1?as_of=2026-10-03T12%3A00%3A00Z")
    end

    defp insert_transaction(attrs) do
      defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}

      Threadline.Test.Repo.insert!(AuditTransaction.changeset(Map.merge(defaults, attrs)))
    end

    defp insert_change(transaction, attrs) do
      defaults = %{
        transaction_id: transaction.id,
        table_schema: "public",
        table_name: "users",
        table_pk: %{"id" => "row-1"},
        op: "update",
        data_after: %{"id" => "row-1", "name" => "Value"},
        changed_fields: ["name"],
        changed_from: %{"name" => "Old Value"},
        captured_at: DateTime.utc_now()
      }

      Threadline.Test.Repo.insert!(AuditChange.changeset(Map.merge(defaults, attrs)))
    end
  end

  defmodule Threadline.OperatorSurface.RowHistoryLiveScopedTest do
    use ExUnit.Case, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias Threadline.Capture.{AuditChange, AuditTransaction}

    @endpoint Threadline.OperatorSurface.RowHistoryLiveTest.ScopedEndpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.RowHistoryLiveTest.ScopedEndpoint,
        secret_key_base: "s" |> String.duplicate(64),
        live_view: [signing_salt: "s" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.RowHistoryLiveTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      Threadline.Test.Repo.delete_all(AuditChange)
      Threadline.Test.Repo.delete_all(AuditTransaction)
      Threadline.Test.Repo.delete_all(Threadline.Semantics.AuditAction)
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    test "scoped first-class row history hides out-of-scope changes", %{conn: conn} do
      support_time = ~U[2026-10-03 12:00:00.000000Z]
      admin_time = DateTime.add(support_time, 60, :second)

      support_txn = insert_transaction(%{occurred_at: support_time, source: "support"})
      admin_txn = insert_transaction(%{occurred_at: admin_time, source: "admin"})

      insert_change(support_txn, %{
        table_pk: %{"id" => "row-scoped-live"},
        data_after: %{"id" => "row-scoped-live", "name" => "Scoped Alpha"},
        changed_fields: ["id", "name"],
        captured_at: support_time
      })

      insert_change(admin_txn, %{
        table_pk: %{"id" => "row-scoped-live"},
        data_after: %{"id" => "row-scoped-live", "name" => "Admin Secret"},
        changed_fields: ["name"],
        changed_from: %{"name" => "Scoped Alpha"},
        captured_at: admin_time
      })

      path =
        "/audit_scoped/rows/users/row-scoped-live?as_of=#{DateTime.to_iso8601(admin_time)}"

      assert {:ok, _lv, html} = live(conn, path)

      assert html =~ "Row history: users / #{String.slice("row-scoped-live", 0, 14)}"
      assert html =~ "Scoped Alpha"
      refute html =~ "Admin Secret"
    end

    defp insert_transaction(attrs) do
      defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}

      Threadline.Test.Repo.insert!(AuditTransaction.changeset(Map.merge(defaults, attrs)))
    end

    defp insert_change(transaction, attrs) do
      defaults = %{
        transaction_id: transaction.id,
        table_schema: "public",
        table_name: "users",
        table_pk: %{"id" => "row-1"},
        op: "update",
        data_after: %{"id" => "row-1", "name" => "Value"},
        changed_fields: ["name"],
        changed_from: %{"name" => "Old Value"},
        captured_at: DateTime.utc_now()
      }

      Threadline.Test.Repo.insert!(AuditChange.changeset(Map.merge(defaults, attrs)))
    end
  end
end
