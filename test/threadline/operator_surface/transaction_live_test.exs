if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.TransactionLiveTest.FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

  defmodule Threadline.OperatorSurface.TransactionLiveTest.Router do
    use Threadline.OperatorSurfaceTest.Router

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.TransactionLiveTest.ScopedRouter do
    use Threadline.OperatorSurfaceTest.Router

    import Ecto.Query

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
    use Threadline.OperatorSurfaceTest.Endpoint,
      router: Threadline.OperatorSurface.TransactionLiveTest.Router
  end

  defmodule Threadline.OperatorSurface.TransactionLiveTest.FailedRouter do
    use Threadline.OperatorSurfaceTest.Router

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit_failed",
        authorize_fn: &__MODULE__.auth/1,
        scope_query_fn: &__MODULE__.fail_scope/3
      )
    end

    def auth(_socket), do: {:ok, %{source: "test"}}

    def fail_scope(_query, _scope, _context),
      do: raise(DBConnection.ConnectionError, "synthetic transaction read failure")
  end

  defmodule Threadline.OperatorSurface.TransactionLiveTest.FailedEndpoint do
    use Threadline.OperatorSurfaceTest.Endpoint,
      router: Threadline.OperatorSurface.TransactionLiveTest.FailedRouter
  end

  defmodule Threadline.OperatorSurface.TransactionLiveTest.ScopedEndpoint do
    use Threadline.OperatorSurfaceTest.Endpoint,
      router: Threadline.OperatorSurface.TransactionLiveTest.ScopedRouter
  end

  defmodule Threadline.OperatorSurface.TransactionLiveTest do
    use ExUnit.Case, async: false

    use Threadline.OperatorSurfaceCase,
      endpoint: Threadline.OperatorSurface.TransactionLiveTest.Endpoint

    import Threadline.StorageSchemaCase

    alias Threadline.Capture.{AuditChange, AuditTransaction}
    alias Threadline.Semantics.AuditAction
    alias Threadline.Test.Repo

    setup_all do
      start_endpoint!(@endpoint)
      :ok
    end

    setup do
      Repo.delete_all(AuditChange, repo_opts())
      Repo.delete_all(AuditTransaction, repo_opts())
      Repo.delete_all(Threadline.Semantics.AuditAction, repo_opts())
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
               "No transaction is available at this ID. It may not exist or may be outside the records available to your current scope."

      assert html =~ "Return to Timeline and check the transaction id."
      assert html =~ ~s|href="/audit/timeline"|
      assert html =~ ~r/<a[^>]*>\s*(?:.|\n)*Open timeline(?:.|\n)*<\/a>/
      refute html =~ "Transaction Not Found"
    end

    test "renders the not-found state for a malformed transaction id", %{conn: conn} do
      assert {:ok, _lv, html} = live(conn, "/audit/transactions/not-a-uuid")

      assert_single_h1(html, "Transaction")
      assert html =~ "Transaction not found"
    end

    test "Case 2: Renders bundle header details (actor, action) for valid transaction ID", %{
      conn: conn
    } do
      # Insert dummy data to satisfy `Threadline.incident_bundle`
      repo = Threadline.Test.Repo

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          }),
          repo_opts()
        )

      # For now just checking if the header renders, we can test more specifically when we add actor/action data.
      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")
      assert_single_h1(html, "Transaction")
      assert html =~ ~s|class="tl-detail-header|
      assert html =~ "Transaction #{String.slice(txn.id, 0, 12)}"
      assert html =~ ~s|title="#{txn.id}"|
      assert html =~ ~s|data-tl-copy="#{txn.id}"|
    end

    test "keeps transaction and linked action actors and recorded context distinct", %{conn: conn} do
      transaction_actor = %{"type" => "admin", "id" => "transaction-admin-42"}
      action_actor = %{"type" => "user", "id" => "action-user-19"}

      action =
        Repo.insert!(
          AuditAction.changeset(%{
            name: "ticket.status_changed",
            actor_ref: action_actor,
            status: :ok,
            request_id: "request-context-239",
            job_id: "job-context-239"
          }),
          repo_opts()
        )

      txn =
        Repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now(),
            actor_ref: transaction_actor,
            action_id: action.id
          }),
          repo_opts()
        )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

      assert html =~ "Actor"
      assert html =~ "admin/transaction-admin-42"
      assert html =~ "Action"
      assert html =~ "ticket.status_changed"
      assert html =~ "Action actor"
      assert html =~ "user/action-user-19"
      assert html =~ "Request ID"
      assert html =~ "request-context-239"
      assert html =~ "Job ID"
      assert html =~ "job-context-239"
      refute html =~ "admin/action-user-19"
      refute html =~ "user/transaction-admin-42"
    end

    test "labels the before and after sides of each field change", %{conn: conn} do
      txn =
        Repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          }),
          repo_opts()
        )

      Repo.insert!(
        AuditChange.changeset(%{
          transaction_id: txn.id,
          table_schema: "public",
          table_name: "users",
          table_pk: %{"id" => "labelled-row"},
          op: "update",
          data_after: %{"email" => "new@example.com"},
          changed_fields: ["email"],
          changed_from: %{"email" => "old@example.com"},
          captured_at: DateTime.utc_now()
        }),
        repo_opts()
      )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")
      assert html =~ "Before"
      assert html =~ "After"
      assert html =~ "old@example.com"
      assert html =~ "new@example.com"
      assert html =~ "users"
      assert html =~ "labelled-row"
    end

    test "Case 3: renders no-row-change state when bundle.changes is empty", %{
      conn: conn
    } do
      repo = Threadline.Test.Repo

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          }),
          repo_opts()
        )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")
      assert_single_h1(html, "Transaction")
      assert html =~ ~s|class="tl-detail-header|
      assert html =~ "Transaction #{String.slice(txn.id, 0, 12)}"
      assert html =~ "No row-level changes captured"
      assert html =~ "0 changes"

      assert html =~
               "A database transaction was found, but row-level changes were not captured."

      assert html =~ "Check audit readiness for this table, then return to Timeline."
    end

    test "reports shared actions while keeping each transaction's changes separate", %{conn: conn} do
      action =
        Repo.insert!(
          AuditAction.changeset(%{
            name: "member.role_changed",
            actor_ref: %{"type" => "admin", "id" => "shared-action-admin"},
            status: :ok,
            request_id: "shared-action-request"
          }),
          repo_opts()
        )

      first =
        Repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now(),
            action_id: action.id
          }),
          repo_opts()
        )

      second =
        Repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now(),
            action_id: action.id
          }),
          repo_opts()
        )

      for {transaction, row_id, name, before} <- [
            {first, "member-one", "First member", "Before first"},
            {second, "member-two", "Second member", "Before second"}
          ] do
        Repo.insert!(
          AuditChange.changeset(%{
            transaction_id: transaction.id,
            table_schema: "public",
            table_name: "members",
            table_pk: %{"id" => row_id},
            op: "update",
            data_after: %{"name" => name},
            changed_fields: ["name"],
            changed_from: %{"name" => before},
            captured_at: DateTime.utc_now()
          }),
          repo_opts()
        )
      end

      Repo.insert!(
        AuditChange.changeset(%{
          transaction_id: first.id,
          table_schema: "public",
          table_name: "members",
          table_pk: %{"id" => "member-three"},
          op: "update",
          data_after: %{"name" => "Another first member"},
          changed_fields: ["name"],
          changed_from: %{"name" => "Before another first"},
          captured_at: DateTime.utc_now()
        }),
        repo_opts()
      )

      assert {:ok, _first_lv, first_html} = live(conn, "/audit/transactions/#{first.id}")
      assert first_html =~ "member.role_changed"
      assert first_html =~ "admin/shared-action-admin"
      assert first_html =~ "shared-action-request"
      assert first_html =~ "2 changes"
      assert first_html =~ "member-one"
      assert first_html =~ "First member"
      assert first_html =~ "member-three"
      assert first_html =~ "Another first member"
      refute first_html =~ "member-two"
      refute first_html =~ "Second member"

      assert {:ok, _second_lv, second_html} = live(conn, "/audit/transactions/#{second.id}")
      assert second_html =~ "member.role_changed"
      assert second_html =~ "admin/shared-action-admin"
      assert second_html =~ "shared-action-request"
      assert second_html =~ "1 change"
      assert second_html =~ "member-two"
      assert second_html =~ "Second member"
      refute second_html =~ "member-one"
      refute second_html =~ "First member"
    end

    test "Case 4: Renders change row with DOM virtualization", %{conn: conn} do
      repo = Threadline.Test.Repo

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          }),
          repo_opts()
        )

      _change =
        repo.insert!(
          AuditChange.changeset(%{
            transaction_id: txn.id,
            table_schema: "public",
            table_name: "users",
            table_pk: %{"id" => 1},
            op: "update",
            data_after: %{"id" => 1, "email" => "test@example.com"},
            changed_fields: ["email"],
            changed_from: %{"email" => "old@example.com"},
            captured_at: DateTime.utc_now()
          }),
          repo_opts()
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
          }),
          repo_opts()
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
        }),
        repo_opts()
      )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

      assert html =~
               ~s|href="/audit/transactions/#{txn.id}/history/users/tenant%2Frow-transaction?as_of=|

      refute html =~ "/history/users/tenant/row-transaction"
    end

    test "renders a row-history link only for the single-key change (READ-04)", %{conn: conn} do
      repo = Threadline.Test.Repo

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          }),
          repo_opts()
        )

      for table_pk <- [
            %{"id" => "row-one"},
            %{"tenant_id" => "1", "id" => "5"},
            %{},
            %{"id" => nil}
          ] do
        repo.insert!(
          AuditChange.changeset(%{
            transaction_id: txn.id,
            table_schema: "public",
            table_name: "users",
            table_pk: table_pk,
            op: "update",
            data_after: %{"email" => "test@example.com"},
            changed_fields: ["email"],
            changed_from: %{"email" => "old@example.com"},
            captured_at: DateTime.utc_now()
          }),
          repo_opts()
        )
      end

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

      assert Regex.scan(~r/data-testid="row-history-link"/, html) |> length() == 1
      assert html =~ ~s|href="/audit/transactions/#{txn.id}/history/users/row-one|
      refute html =~ "/history/users/5"
      refute html =~ "/history/users/1"
    end

    test "renders INSERT data_after fields when field_changes is empty", %{conn: conn} do
      repo = Threadline.Test.Repo
      captured_at = ~U[2026-06-04 12:30:00Z]

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: captured_at
          }),
          repo_opts()
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
        }),
        repo_opts()
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
          }),
          repo_opts()
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
            "updated_at" => "2026-06-04T12:30:00Z",
            "after_only" => "now present"
          },
          changed_fields: ["closed_at", "email", "updated_at", "before_only", "after_only"],
          changed_from: %{
            "closed_at" => "2026-06-03T12:30:00Z",
            "email" => "person@example.com",
            "updated_at" => "2026-06-03T12:30:00Z",
            "before_only" => "was present"
          },
          captured_at: captured_at
        }),
        repo_opts()
      )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

      assert html =~ ~s|class="tl-diff__arrow"|
      assert html =~ "-&gt;"
      assert html =~ ~s|class="tl-value tl-value--null"|
      assert html =~ "null"
      assert html =~ ~s|class="tl-value tl-value--redacted"|
      assert html =~ "[REDACTED]"
      assert html =~ "(omitted)"
      assert html =~ "(absent)"
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
          }),
          repo_opts()
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
        }),
        repo_opts()
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
          AuditAction.changeset(%{
            name: "support.reply",
            actor_ref: %{"type" => "user", "id" => "agent-1"},
            status: :ok,
            correlation_id: correlation_id,
            occurred_at: DateTime.utc_now()
          }),
          repo_opts()
        )

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now(),
            action_id: action.id
          }),
          repo_opts()
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
        }),
        repo_opts()
      )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

      alias Threadline.OperatorSurface.Presentation

      txn_visible = Presentation.ref(txn.id, kind: :uuid).visible
      correlation_visible = Presentation.ref(correlation_id, kind: :correlation).visible

      assert html =~ "tl-short-content"
      # UI.Display.ref binds the FULL value to BOTH the <code> title/data-tl-copy and the
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
          AuditAction.changeset(%{
            name: "support.reply",
            actor_ref: %{"type" => "user", "id" => "agent-1"},
            status: :ok,
            correlation_id: correlation_id,
            occurred_at: DateTime.utc_now()
          }),
          repo_opts()
        )

      txn =
        repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now(),
            action_id: action.id
          }),
          repo_opts()
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
          }),
          repo_opts()
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
        }),
        repo_opts()
      )

      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

      alias Threadline.OperatorSurface.Presentation

      # Visible diff text is truncated (max ~56), but the full value is recoverable.
      before_token = Presentation.value_token(long_before)
      after_token = Presentation.value_token(long_after)

      assert before_token.text != long_before
      assert html =~ before_token.text
      assert html =~ after_token.text
      assert html =~ "<summary>Show full token before value</summary>"
      assert html =~ "<summary>Show full token after value</summary>"
      assert html =~ ~s|<code class="tl-value__full">#{long_before}</code>|
      assert html =~ ~s|<code class="tl-value__full">#{long_after}</code>|

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
            AuditTransaction.changeset(%{
              txid: :rand.uniform(1_000_000_000),
              occurred_at: DateTime.utc_now()
            }),
            repo_opts()
          )

        {:ok, _lv, html} = live(conn, "/audit/transactions/#{txn.id}")

        assert html =~ ~s|class="tl-topbar"|
        refute html =~ ~s|href="/audit/coverage"|
      end
    end
  end

  defmodule Threadline.OperatorSurface.TransactionLiveFailureTest do
    use ExUnit.Case, async: false

    use Threadline.OperatorSurfaceCase,
      endpoint: Threadline.OperatorSurface.TransactionLiveTest.FailedEndpoint

    setup_all do
      start_endpoint!(@endpoint)
      :ok
    end

    test "renders a recoverable unavailable state when transaction reads fail" do
      uuid = Ecto.UUID.generate()
      conn = Phoenix.ConnTest.build_conn()

      assert {:ok, _lv, html} = live(conn, "/audit_failed/transactions/#{uuid}")
      assert html =~ "Transaction details unavailable"
      assert html =~ "The transaction could not be loaded. Retry or return to Timeline."
      assert html =~ ~s|href="/audit_failed/transactions/#{uuid}"|
      assert html =~ ~s|href="/audit_failed/timeline"|
      refute html =~ "Transaction not found"
      refute html =~ "pruned by the retention policy"
    end
  end

  defmodule Threadline.OperatorSurface.TransactionLiveScopedTest do
    use ExUnit.Case, async: false

    use Threadline.OperatorSurfaceCase,
      endpoint: Threadline.OperatorSurface.TransactionLiveTest.ScopedEndpoint

    import Threadline.StorageSchemaCase

    alias Threadline.Capture.{AuditChange, AuditTransaction}
    alias Threadline.Test.Repo

    defp insert_transaction(attrs) do
      defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}

      Repo.insert!(
        AuditTransaction.changeset(Map.merge(defaults, attrs)),
        repo_opts()
      )
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

      Repo.insert!(AuditChange.changeset(Map.merge(defaults, attrs)), repo_opts())
    end

    setup_all do
      start_endpoint!(@endpoint)
      :ok
    end

    setup do
      Repo.delete_all(AuditChange, repo_opts())
      Repo.delete_all(AuditTransaction, repo_opts())
      Repo.delete_all(Threadline.Semantics.AuditAction, repo_opts())
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
