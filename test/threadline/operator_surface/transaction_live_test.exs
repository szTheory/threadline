if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.TransactionLiveTest.FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

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

  defmodule Threadline.OperatorSurface.TransactionLiveTest.ScopedRouter do
    use Phoenix.Router
    import Ecto.Query
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

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit_scoped",
        authorize_fn: &__MODULE__.auth/1,
        scope_query_fn: &__MODULE__.scope_operator_query/3,
        schemas: %{"users" => Threadline.OperatorSurface.TransactionLiveTest.FakeUser}
      )
    end

    def auth(_socket), do: {:ok, %{source: "support"}}

    def scope_operator_query(query, %{source: source}, %{surface: :transaction_header}) do
      from(at in query, where: at.source == ^source)
    end

    def scope_operator_query(query, %{source: source}, %{surface: :transaction}) do
      where(query, [_ac, at], at.source == ^source)
    end

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

  defmodule Threadline.OperatorSurface.TransactionLiveTest.ScopedEndpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_tx_scoped_key",
      signing_salt: "v8q+QWvj"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.TransactionLiveTest.ScopedRouter)
  end

  defmodule Threadline.OperatorSurface.TransactionLiveTest do
    use ExUnit.Case, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias Threadline.Capture.{AuditChange, AuditTransaction}

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
      Threadline.Test.Repo.delete_all(AuditChange)
      Threadline.Test.Repo.delete_all(AuditTransaction)
      Threadline.Test.Repo.delete_all(Threadline.Semantics.AuditAction)
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    defp assert_single_h1(html, text) do
      assert Regex.scan(~r/<h1\b[^>]*>\s*#{Regex.escape(text)}\s*<\/h1>/, html) |> length() == 1
      assert Regex.scan(~r/<h1\b/, html) |> length() == 1
    end

    test "Case 1: renders explicit not-found state for missing transaction ID", %{conn: conn} do
      uuid = Ecto.UUID.generate()
      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{uuid}")

      assert_single_h1(html, "Transaction")
      assert html =~ "Transaction not found"

      assert html =~
               "This database transaction may not exist, or it may have been pruned by the retention policy."

      assert html =~ "Return to Timeline and check the transaction id."
      assert html =~ ~s|href="/audit/timeline"|
      assert html =~ ~r/<a[^>]*>\s*(?:.|\n)*Open timeline(?:.|\n)*<\/a>/
      refute html =~ "Transaction Not Found"
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
      assert_single_h1(html, "Transaction")
      assert html =~ ~s|class="tl-detail-header|
      assert html =~ "Transaction #{String.slice(txn.id, 0, 12)}"
      assert html =~ ~s|title="#{txn.id}"|
      assert html =~ ~s|data-tl-copy="#{txn.id}"|
    end

    test "Case 3: renders no-row-change state when bundle.changes is empty", %{
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
      assert_single_h1(html, "Transaction")
      assert html =~ ~s|class="tl-detail-header|
      assert html =~ "Transaction #{String.slice(txn.id, 0, 12)}"
      assert html =~ "No row-level changes captured"

      assert html =~
               "A database transaction was found, but row-level changes were not captured."

      assert html =~ "Check audit readiness for this table, then return to Timeline."
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
      assert html =~ "UPDATE"
      assert html =~ "users"
      assert html =~ "test@example.com"
      assert html =~ "old@example.com"

      # Verify dummy event handlers
      render_hook(lv, "prev-page", %{})
      render_hook(lv, "next-page", %{})
    end

    test "transaction row-history links encode slash-containing record ids", %{conn: conn} do
      repo = Threadline.Test.Repo

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          })
        )

      repo.insert!(
        AuditChange.changeset(%{
          transaction_id: txn.id,
          table_schema: "public",
          table_name: "users",
          table_pk: %{"id" => "tenant/row-transaction"},
          op: "update",
          data_after: %{"id" => "tenant/row-transaction", "email" => "test@example.com"},
          changed_fields: ["id", "email"],
          changed_from: %{"email" => "old@example.com"},
          captured_at: DateTime.utc_now()
        })
      )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

      assert html =~
               ~s|href="/audit/transactions/#{txn.id}/history/users/tenant%2Frow-transaction?as_of=|

      refute html =~ "/history/users/tenant/row-transaction"
    end

    test "renders INSERT data_after fields when field_changes is empty", %{conn: conn} do
      repo = Threadline.Test.Repo
      captured_at = ~U[2026-06-04 12:30:00Z]

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: captured_at
          })
        )

      repo.insert!(
        AuditChange.changeset(%{
          transaction_id: txn.id,
          table_schema: "public",
          table_name: "users",
          table_pk: %{"id" => "user-insert-1"},
          op: "insert",
          data_after: %{
            "id" => "user-insert-1",
            "email" => "test@example.com",
            "name" => "Test User"
          },
          changed_fields: nil,
          changed_from: nil,
          captured_at: captured_at
        })
      )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

      assert html =~ "email"
      assert html =~ "test@example.com"
      assert html =~ "name"
      assert html =~ "Test User"
      refute html =~ "No row-level changes recorded"
    end

    test "renders UPDATE values with semantic before and after tokens", %{conn: conn} do
      repo = Threadline.Test.Repo
      captured_at = ~U[2026-06-04 12:30:00Z]

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: captured_at
          })
        )

      repo.insert!(
        AuditChange.changeset(%{
          transaction_id: txn.id,
          table_schema: "public",
          table_name: "users",
          table_pk: %{"id" => "user-update-1"},
          op: "update",
          data_after: %{
            "id" => "user-update-1",
            "closed_at" => nil,
            "email" => "[REDACTED]",
            "updated_at" => "2026-06-04T12:30:00Z"
          },
          changed_fields: ["closed_at", "email", "updated_at"],
          changed_from: %{
            "closed_at" => "2026-06-03T12:30:00Z",
            "email" => "person@example.com",
            "updated_at" => "2026-06-03T12:30:00Z"
          },
          captured_at: captured_at
        })
      )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

      assert html =~ ~s|class="tl-diff__arrow"|
      assert html =~ "-&gt;"
      assert html =~ ~s|class="tl-value tl-value--null"|
      assert html =~ "null"
      assert html =~ ~s|class="tl-value tl-value--redacted"|
      assert html =~ "[REDACTED]"
      assert html =~ ~s|title="2026-06-04T12:30:00Z"|
      assert html =~ "12:30 PM UTC"
      refute html =~ ">nil<"
      refute html =~ "&quot;2026-06-04T12:30:00Z&quot;"
    end

    test "renders diagnostic empty copy when row-level fields are unavailable", %{conn: conn} do
      repo = Threadline.Test.Repo

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          })
        )

      repo.insert!(
        AuditChange.changeset(%{
          transaction_id: txn.id,
          table_schema: "public",
          table_name: "users",
          table_pk: %{"id" => "user-delete-1"},
          op: "delete",
          data_after: nil,
          changed_fields: nil,
          changed_from: nil,
          captured_at: DateTime.utc_now()
        })
      )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

      assert html =~ "No row-level changes captured"

      assert html =~
               "A database transaction was found, but row-level changes were not captured."

      assert html =~ "Check audit readiness for this table, then return to Timeline."
    end

    test "renders verifiable secondary refs and enabled copy affordances", %{conn: conn} do
      repo = Threadline.Test.Repo
      correlation_id = "request-" <> String.duplicate("abcdef", 10)

      action =
        repo.insert!(
          Threadline.Semantics.AuditAction.changeset(%{
            name: "support.reply",
            actor_ref: %{"type" => "user", "id" => "agent-1"},
            status: :ok,
            correlation_id: correlation_id,
            occurred_at: DateTime.utc_now()
          })
        )

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now(),
            action_id: action.id
          })
        )

      repo.insert!(
        AuditChange.changeset(%{
          transaction_id: txn.id,
          table_schema: "public",
          table_name: "users",
          table_pk: %{"id" => "user-ref-1"},
          op: "update",
          data_after: %{"id" => "user-ref-1", "email" => "new@example.com"},
          changed_fields: ["email"],
          changed_from: %{"email" => "old@example.com"},
          captured_at: DateTime.utc_now()
        })
      )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

      alias Threadline.OperatorSurface.Presentation

      txn_visible = Presentation.ref(txn.id, kind: :uuid).visible
      correlation_visible = Presentation.ref(correlation_id, kind: :correlation).visible

      assert html =~ "tl-short-content"
      # UI.ref binds the FULL value to BOTH the <code> title/data-tl-copy and the
      # gated copy button — never the truncated/visible/title face (D-02 footgun fix).
      assert html =~ ~s|title="#{txn.id}"|
      assert html =~ txn_visible
      assert html =~ ~s|data-tl-copy="#{txn.id}"|
      assert html =~ ~s|class="tl-copy tl-button tl-button--compact tl-button--secondary"|
      assert html =~ ~s|title="#{correlation_id}"|
      assert html =~ correlation_visible
      assert html =~ ~s|data-tl-copy="#{correlation_id}"|
      refute html =~ String.slice(txn.id, 0, 14) <> "</code>"
      refute html =~ "tl-copy tl-button--disabled"
    end

    test "transaction copy targets bind the FULL value, never the truncated visible (D-02)", %{
      conn: conn
    } do
      import Threadline.OperatorSurface.RefCopyContract

      repo = Threadline.Test.Repo
      # A long (>40-char) correlation id whose visible truncation != full value.
      correlation_id = "req_" <> String.duplicate("abcdef0123456789", 4)

      action =
        repo.insert!(
          Threadline.Semantics.AuditAction.changeset(%{
            name: "support.reply",
            actor_ref: %{"type" => "user", "id" => "agent-1"},
            status: :ok,
            correlation_id: correlation_id,
            occurred_at: DateTime.utc_now()
          })
        )

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now(),
            action_id: action.id
          })
        )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

      alias Threadline.OperatorSurface.Presentation

      # The transaction id and correlation id both copy the EXACT full value.
      assert_copy_equals_full(html, full: txn.id)
      assert_copy_equals_full(html, full: correlation_id)
      refute_copy_truncated(html, full: correlation_id)

      # The visible (truncated) face is NOT what gets copied.
      correlation_visible = Presentation.ref(correlation_id, kind: :correlation).visible
      assert correlation_visible != correlation_id
      refute html =~ ~s|data-tl-copy="#{correlation_visible}"|

      # Metadata renders as a description list (kv), not the retired tl-param-list.
      assert html =~ ~s|class="tl-kv|
      refute html =~ ~s|class="tl-param-list"|
    end

    test "diff cells truncate long values and expose a gated copy bound to the full value (D-04)",
         %{conn: conn} do
      import Threadline.OperatorSurface.RefCopyContract

      repo = Threadline.Test.Repo
      # A long machine value (>56 chars) that value_token/1 must middle-truncate.
      long_before = "token_" <> String.duplicate("abcdef0123456789", 5)
      long_after = "token_" <> String.duplicate("fedcba9876543210", 5)

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          })
        )

      repo.insert!(
        AuditChange.changeset(%{
          transaction_id: txn.id,
          table_schema: "public",
          table_name: "users",
          table_pk: %{"id" => "user-diff-1"},
          op: "update",
          data_after: %{"id" => "user-diff-1", "token" => long_after},
          changed_fields: ["token"],
          changed_from: %{"token" => long_before},
          captured_at: DateTime.utc_now()
        })
      )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

      alias Threadline.OperatorSurface.Presentation

      # Visible diff text is truncated (max ~56), but the full value is recoverable.
      before_token = Presentation.value_token(long_before)
      after_token = Presentation.value_token(long_after)

      assert before_token.text != long_before
      assert html =~ before_token.text
      assert html =~ after_token.text

      # The diff cell exposes a gated copy affordance bound to the FULL value.
      assert_copy_equals_full(html, full: long_before)
      assert_copy_equals_full(html, full: long_after)
      assert html =~ ~s|aria-label="Copy token before value"|
      assert html =~ ~s|aria-label="Copy token after value"|
    end

    describe "surface header (Phase 66)" do
      test "does not render the surface badge linking to /audit/coverage when coverage is disabled",
           %{
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

        assert html =~ ~s|class="tl-topbar"|
        refute html =~ ~s|href="/audit/coverage"|
      end
    end
  end

  defmodule Threadline.OperatorSurface.TransactionLiveScopedTest do
    use ExUnit.Case, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias Threadline.Capture.{AuditChange, AuditTransaction}

    @endpoint Threadline.OperatorSurface.TransactionLiveTest.ScopedEndpoint

    defp insert_transaction(attrs) do
      defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}

      Threadline.Test.Repo.insert!(AuditTransaction.changeset(Map.merge(defaults, attrs)))
    end

    defp insert_change(transaction, attrs) do
      defaults = %{
        transaction_id: transaction.id,
        table_schema: "public",
        table_name: "users",
        table_pk: %{"id" => "user-1"},
        op: "update",
        data_after: %{"id" => "user-1", "name" => "Scoped Alpha"},
        changed_fields: ["name"],
        changed_from: %{"name" => "Older"},
        captured_at: DateTime.utc_now()
      }

      Threadline.Test.Repo.insert!(AuditChange.changeset(Map.merge(defaults, attrs)))
    end

    setup_all do
      Application.put_env(
        :threadline,
        Threadline.OperatorSurface.TransactionLiveTest.ScopedEndpoint,
        secret_key_base: "q" |> String.duplicate(64),
        live_view: [signing_salt: "q" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.TransactionLiveTest.Layouts]
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

    test "scoped transaction view returns not found for out-of-scope transaction", %{conn: conn} do
      txn = insert_transaction(%{source: "admin"})

      assert {:ok, _lv, html} = live(conn, "/audit_scoped/transactions/#{txn.id}")
      assert html =~ "Transaction not found"
    end

    test "scoped transaction history route hides out-of-scope row history", %{conn: conn} do
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
        "/audit_scoped/transactions/#{support_txn.id}/history/users/row-scoped-live?as_of=#{DateTime.to_iso8601(admin_time)}"

      assert {:ok, _lv, html} = live(conn, path)

      assert html =~ "Row history: users / #{String.slice("row-scoped-live", 0, 14)}"
      assert html =~ "Scoped Alpha"
      refute html =~ "Admin Secret"
    end
  end
end
