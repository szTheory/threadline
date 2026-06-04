if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.RowHistoryComponentTest.FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:email, :string)
      field(:name, :string)
      field(:closed_at, :utc_datetime_usec)
      field(:updated_at, :utc_datetime_usec)
    end
  end

  defmodule Threadline.OperatorSurface.RowHistoryComponentTest do
    use ExUnit.Case, async: false
    import Phoenix.LiveViewTest
    import Ecto.Query

    alias Threadline.Capture.{AuditChange, AuditTransaction}
    alias Threadline.OperatorSurface.RowHistoryComponentTest.FakeUser

    # We test it using render_component/2

    setup_all do
      :ok
    end

    setup do
      Threadline.Test.Repo.delete_all(AuditChange)
      Threadline.Test.Repo.delete_all(AuditTransaction)
      Threadline.Test.Repo.delete_all(Threadline.Semantics.AuditAction)
      {:ok, %{}}
    end

    test "renders error when schema is missing" do
      html =
        render_component(Threadline.OperatorSurface.Live.RowHistoryComponent, %{
          id: "test-history",
          table: "unknown_table",
          record_id: "1",
          base_path: "/audit/transactions/123",
          threadline_schemas: %{},
          repo: Threadline.Test.Repo,
          as_of: nil
        })

      assert html =~ "Row history:"
      assert html =~ "is not mapped to an Ecto schema"
    end

    test "renders sorted snapshot rows with shared semantic value tokens" do
      captured_at = ~U[2026-06-04 12:30:00Z]
      txn = insert_transaction(%{occurred_at: captured_at})

      insert_change(txn, %{
        table_pk: %{"id" => "row-semantic-1"},
        data_after: %{
          "id" => "row-semantic-1",
          "closed_at" => nil,
          "email" => "[REDACTED]",
          "name" => "<script>alert(1)</script>",
          "updated_at" => "2026-06-04T12:30:00Z"
        },
        changed_fields: ["id", "closed_at", "email", "name", "updated_at"],
        captured_at: captured_at
      })

      html =
        render_component(Threadline.OperatorSurface.Live.RowHistoryComponent, %{
          id: "test-history",
          table: "users",
          record_id: "row-semantic-1",
          base_path: "/audit/transactions/#{txn.id}",
          threadline_schemas: %{"users" => FakeUser},
          repo: Threadline.Test.Repo,
          as_of: captured_at
        })

      assert html =~ ~s|class="tl-value tl-value--null"|
      assert Regex.match?(~r/>\s*null\s*</, html)
      assert html =~ ~s|class="tl-value tl-value--redacted"|
      assert html =~ "[REDACTED]"
      assert html =~ ~s|title="2026-06-04T12:30:00Z"|
      assert html =~ "12:30 PM UTC"
      assert html =~ "&lt;script&gt;alert(1)&lt;/script&gt;"
      refute html =~ "<script>alert(1)</script>"
      refute html =~ ">nil<"
      refute html =~ "&quot;2026-06-04T12:30:00Z&quot;"
      refute html =~ ~s|tl-diff__arrow|
      refute html =~ "-&gt;"

      assert Regex.run(
               ~r/<dt class="tl-kv__key">closed_at<\/dt>.*<dt class="tl-kv__key">email<\/dt>.*<dt class="tl-kv__key">id<\/dt>.*<dt class="tl-kv__key">name<\/dt>.*<dt class="tl-kv__key">updated_at<\/dt>/s,
               html
             )
    end

    test "keeps row-history scope_query_fn applied to history and snapshot lookup" do
      scoped_time = ~U[2026-06-04 12:30:00Z]
      hidden_time = DateTime.add(scoped_time, 60, :second)
      scoped_txn = insert_transaction(%{occurred_at: scoped_time, source: "support"})
      hidden_txn = insert_transaction(%{occurred_at: hidden_time, source: "admin"})

      insert_change(scoped_txn, %{
        table_pk: %{"id" => "row-scoped-1"},
        data_after: %{"id" => "row-scoped-1", "name" => "Scoped Value"},
        changed_fields: ["id", "name"],
        captured_at: scoped_time
      })

      insert_change(hidden_txn, %{
        table_pk: %{"id" => "row-scoped-1"},
        data_after: %{"id" => "row-scoped-1", "name" => "Admin Secret"},
        changed_fields: ["name"],
        changed_from: %{"name" => "Scoped Value"},
        captured_at: hidden_time
      })

      html =
        render_component(Threadline.OperatorSurface.Live.RowHistoryComponent, %{
          id: "test-history",
          table: "users",
          record_id: "row-scoped-1",
          base_path: "/audit/transactions/#{scoped_txn.id}",
          threadline_schemas: %{"users" => FakeUser},
          repo: Threadline.Test.Repo,
          scope: %{source: "support"},
          scope_query_fn: &scope_operator_query/3,
          as_of: scoped_time
        })

      assert html =~ "Scoped Value"
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

    defp scope_operator_query(query, %{source: source}, %{surface: :row_history}) do
      source_txn_ids =
        from(at in AuditTransaction,
          where: at.source == ^source,
          select: at.id
        )

      from(ac in query, where: ac.transaction_id in subquery(source_txn_ids))
    end

    defp scope_operator_query(query, _scope, _context), do: query
  end
end
