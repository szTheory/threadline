defmodule Threadline.InvestigationTest do
  use Threadline.DataCase
  import Ecto.Query

  alias Threadline.Capture.{AuditChange, AuditTransaction}

  alias Threadline.Investigation.{
    IncidentBundle,
    IncidentChange,
    LinkedChange,
    LinkedTransaction
  }

  alias Threadline.Query.TimelinePage
  alias Threadline.Semantics.{ActorRef, AuditAction}

  @repo Threadline.Test.Repo

  defmodule FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

  defp insert_transaction(attrs \\ %{}, storage_schema \\ "threadline") do
    defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}

    @repo.insert!(
      AuditTransaction.changeset(Map.merge(defaults, attrs)),
      repo_opts(storage_schema)
    )
  end

  defp insert_change(transaction, attrs, storage_schema \\ "threadline") do
    defaults = %{
      table_schema: "public",
      table_name: "users",
      table_pk: %{"id" => "user-1"},
      op: "insert",
      data_after: %{"name" => "Alice"},
      changed_fields: ["name"],
      captured_at: DateTime.utc_now(),
      transaction_id: transaction.id
    }

    @repo.insert!(
      AuditChange.changeset(Map.merge(defaults, Map.new(attrs))),
      repo_opts(storage_schema)
    )
  end

  defp insert_action(attrs, storage_schema \\ "threadline") do
    actor = actor!(:user, "investigator")

    defaults = %{
      name: "investigation.test",
      actor_ref: ActorRef.to_map(actor),
      status: :ok,
      correlation_id: "corr-default"
    }

    @repo.insert!(
      AuditAction.changeset(%AuditAction{}, Map.merge(defaults, attrs)),
      repo_opts(storage_schema)
    )
  end

  defp actor!(type, id) do
    {:ok, ref} = ActorRef.new(type, id)
    ref
  end

  defp support_scope_query(query, %{source: source}, %{surface: :row_history}) do
    source_txn_ids =
      from(at in AuditTransaction, where: at.source == ^source, select: at.id)

    from(ac in query, where: ac.transaction_id in subquery(source_txn_ids))
  end

  defp support_scope_query(query, _scope, _context), do: query

  defp page_entry_ids(%TimelinePage{entries: entries}),
    do: Enum.map(entries, & &1.audit_change.id)

  describe "row_history/4 and row_history_page/4" do
    test "constrains history to one row instead of all rows from the table" do
      txn = insert_transaction()
      older = ~U[2026-08-01 10:00:00.000000Z]
      newer = DateTime.add(older, 60, :second)

      insert_change(txn, %{table_name: "users", table_pk: %{"id" => "row-1"}, captured_at: older})
      insert_change(txn, %{table_name: "users", table_pk: %{"id" => "row-1"}, captured_at: newer})
      insert_change(txn, %{table_name: "users", table_pk: %{"id" => "row-2"}, captured_at: newer})
      insert_change(txn, %{table_name: "posts", table_pk: %{"id" => "row-1"}, captured_at: newer})

      results = Threadline.row_history(FakeUser, "row-1", [], repo: @repo)

      assert Enum.map(results, & &1.audit_change.table_pk["id"]) == ["row-1", "row-1"]
      assert Enum.all?(results, &match?(%LinkedChange{}, &1))
      assert Enum.all?(results, &(&1.audit_change.table_name == "users"))
      assert Enum.map(results, & &1.audit_change.captured_at) == [newer, older]
      assert Enum.all?(results, &match?(%AuditTransaction{}, &1.transaction))
      assert Enum.all?(results, &is_nil(&1.action))
    end

    test "paged row history concatenates back to eager order and keeps next_cursor semantics" do
      txn = insert_transaction()
      t1 = ~U[2026-08-01 10:00:00.000000Z]
      t2 = DateTime.add(t1, 60, :second)
      t3 = DateTime.add(t2, 60, :second)

      insert_change(txn, %{table_name: "users", table_pk: %{"id" => "row-paged"}, captured_at: t1})

      insert_change(txn, %{table_name: "users", table_pk: %{"id" => "row-paged"}, captured_at: t2})

      insert_change(txn, %{table_name: "users", table_pk: %{"id" => "row-paged"}, captured_at: t3})

      eager_ids =
        Threadline.row_history(FakeUser, "row-paged", [], repo: @repo)
        |> Enum.map(& &1.audit_change.id)

      first_page =
        Threadline.row_history_page(FakeUser, "row-paged", [], repo: @repo, page_size: 2)

      second_page =
        Threadline.row_history_page(
          FakeUser,
          "row-paged",
          [],
          repo: @repo,
          page_size: 2,
          cursor: first_page.next_cursor
        )

      assert eager_ids == page_entry_ids(first_page) ++ page_entry_ids(second_page)
      assert first_page.next_cursor != nil
      assert second_page.next_cursor == nil
    end

    test "row_history/4 applies support scope" do
      support_time = ~U[2026-10-02 10:00:00.000000Z]
      admin_time = DateTime.add(support_time, 60, :second)

      support_txn = insert_transaction(%{occurred_at: support_time, source: "support"})
      admin_txn = insert_transaction(%{occurred_at: admin_time, source: "admin"})

      support_change =
        insert_change(support_txn, %{
          table_name: "users",
          table_pk: %{"id" => "row-scoped"},
          data_after: %{"id" => "row-scoped", "name" => "Scoped Alpha"},
          changed_fields: ["id", "name"],
          captured_at: support_time
        })

      insert_change(admin_txn, %{
        table_name: "users",
        table_pk: %{"id" => "row-scoped"},
        data_after: %{"id" => "row-scoped", "name" => "Admin Beta"},
        changed_fields: ["name"],
        captured_at: admin_time
      })

      results =
        Threadline.row_history(FakeUser, "row-scoped", [],
          repo: @repo,
          scope: %{source: "support"},
          scope_query_fn: &support_scope_query/3
        )

      assert Enum.map(results, & &1.audit_change.id) == [support_change.id]
      assert Enum.all?(results, &(&1.transaction.source == "support"))
    end

    test "row_history_page/4 applies support scope" do
      support_time = ~U[2026-10-02 11:00:00.000000Z]
      admin_time = DateTime.add(support_time, 60, :second)

      support_txn = insert_transaction(%{occurred_at: support_time, source: "support"})
      admin_txn = insert_transaction(%{occurred_at: admin_time, source: "admin"})

      support_change =
        insert_change(support_txn, %{
          table_name: "users",
          table_pk: %{"id" => "row-scoped-page"},
          data_after: %{"id" => "row-scoped-page", "name" => "Scoped Alpha"},
          changed_fields: ["id", "name"],
          captured_at: support_time
        })

      insert_change(admin_txn, %{
        table_name: "users",
        table_pk: %{"id" => "row-scoped-page"},
        data_after: %{"id" => "row-scoped-page", "name" => "Admin Beta"},
        changed_fields: ["name"],
        captured_at: admin_time
      })

      page =
        Threadline.row_history_page(FakeUser, "row-scoped-page", [],
          repo: @repo,
          page_size: 5,
          scope: %{source: "support"},
          scope_query_fn: &support_scope_query/3
        )

      assert Enum.map(page.entries, & &1.audit_change.id) == [support_change.id]
      assert page.next_cursor == nil
      assert Enum.all?(page.entries, &(&1.transaction.source == "support"))
    end
  end

  describe "actor_window/3 and actor_window_page/3" do
    test "returns change rows across tables for one actor" do
      actor = actor!(:user, "actor-window")
      actor_map = ActorRef.to_map(actor)
      other_actor = actor!(:user, "other-window")
      older = ~U[2026-09-01 09:00:00.000000Z]
      newer = DateTime.add(older, 60, :second)

      actor_txn = insert_transaction(%{actor_ref: actor_map, occurred_at: older})

      insert_change(actor_txn, %{
        table_name: "users",
        table_pk: %{"id" => "aw-1"},
        captured_at: older
      })

      insert_change(actor_txn, %{
        table_name: "posts",
        table_pk: %{"id" => "aw-2"},
        captured_at: newer
      })

      other_txn =
        insert_transaction(%{actor_ref: ActorRef.to_map(other_actor), occurred_at: newer})

      insert_change(other_txn, %{
        table_name: "users",
        table_pk: %{"id" => "aw-3"},
        captured_at: newer
      })

      results = Threadline.actor_window(actor, [], repo: @repo)

      assert Enum.map(results, & &1.audit_change.transaction_id) |> Enum.uniq() == [actor_txn.id]
      assert Enum.sort(Enum.map(results, & &1.audit_change.table_name)) == ["posts", "users"]
      assert Enum.all?(results, &match?(%AuditTransaction{}, &1.transaction))
    end

    test "paged actor window reuses the timeline keyset contract" do
      actor = actor!(:user, "actor-paged")
      txn = insert_transaction(%{actor_ref: ActorRef.to_map(actor)})
      t1 = ~U[2026-09-01 09:00:00.000000Z]
      t2 = t1
      t3 = DateTime.add(t1, -60, :second)

      insert_change(txn, %{table_name: "users", table_pk: %{"id" => "actor-1"}, captured_at: t1})
      insert_change(txn, %{table_name: "posts", table_pk: %{"id" => "actor-2"}, captured_at: t2})
      insert_change(txn, %{table_name: "teams", table_pk: %{"id" => "actor-3"}, captured_at: t3})

      eager_ids =
        Threadline.actor_window(actor, [], repo: @repo) |> Enum.map(& &1.audit_change.id)

      first_page = Threadline.actor_window_page(actor, [], repo: @repo, page_size: 2)

      second_page =
        Threadline.actor_window_page(actor, [],
          repo: @repo,
          page_size: 2,
          cursor: first_page.next_cursor
        )

      paged_ids = page_entry_ids(first_page) ++ page_entry_ids(second_page)

      assert eager_ids == paged_ids
      assert length(paged_ids) == length(Enum.uniq(paged_ids))
      assert second_page.next_cursor == nil
    end
  end

  describe "correlation_bundle/3 and correlation_bundle_page/3" do
    test "preserves strict inner-join correlation semantics" do
      matching_action = insert_action(%{correlation_id: "corr-match"})
      other_action = insert_action(%{correlation_id: "corr-other"})

      matching_txn = insert_transaction(%{action_id: matching_action.id})
      insert_change(matching_txn, %{table_name: "users", table_pk: %{"id" => "corr-1"}})

      other_corr_txn = insert_transaction(%{action_id: other_action.id})
      insert_change(other_corr_txn, %{table_name: "users", table_pk: %{"id" => "corr-2"}})

      orphan_txn = insert_transaction()
      insert_change(orphan_txn, %{table_name: "users", table_pk: %{"id" => "corr-3"}})

      results = Threadline.correlation_bundle("corr-match", [], repo: @repo)

      assert Enum.map(results, & &1.audit_change.transaction_id) == [matching_txn.id]
      assert Enum.all?(results, &(&1.audit_change.table_pk["id"] == "corr-1"))
      assert Enum.all?(results, &match?(%AuditAction{}, &1.action))
      assert Enum.all?(results, &(&1.action.correlation_id == "corr-match"))
    end

    test "paged correlation bundle concatenates to eager order" do
      action = insert_action(%{correlation_id: "corr-paged"})
      txn = insert_transaction(%{action_id: action.id})
      t1 = ~U[2026-09-03 09:00:00.000000Z]
      t2 = DateTime.add(t1, -60, :second)
      t3 = DateTime.add(t2, -60, :second)

      insert_change(txn, %{table_name: "users", table_pk: %{"id" => "cb-1"}, captured_at: t1})
      insert_change(txn, %{table_name: "posts", table_pk: %{"id" => "cb-2"}, captured_at: t2})
      insert_change(txn, %{table_name: "teams", table_pk: %{"id" => "cb-3"}, captured_at: t3})

      eager_ids =
        Threadline.correlation_bundle("corr-paged", [], repo: @repo)
        |> Enum.map(& &1.audit_change.id)

      first_page =
        Threadline.correlation_bundle_page("corr-paged", [], repo: @repo, page_size: 2)

      second_page =
        Threadline.correlation_bundle_page(
          "corr-paged",
          [],
          repo: @repo,
          page_size: 2,
          cursor: first_page.next_cursor
        )

      assert eager_ids == page_entry_ids(first_page) ++ page_entry_ids(second_page)
      assert first_page.next_cursor != nil
      assert second_page.next_cursor == nil
    end
  end

  describe "transaction_context/2" do
    test "uses storage_schema option for transaction and action preloads" do
      ensure_storage_schema!("audit")

      action =
        insert_action(
          %{correlation_id: "audit-storage-context", name: "audit.storage.context"},
          "audit"
        )

      default_action =
        insert_action(
          %{correlation_id: "audit-storage-context", name: "default.storage.context"},
          "threadline"
        )

      default_txn = insert_transaction(%{action_id: default_action.id})

      insert_change(default_txn, %{
        table_name: "users",
        table_pk: %{"id" => "default-context"},
        captured_at: ~U[2026-09-04 08:00:00.000000Z]
      })

      txn = insert_transaction(%{action_id: action.id}, "audit")

      change =
        insert_change(
          txn,
          %{
            table_name: "users",
            table_pk: %{"id" => "audit-context"},
            captured_at: ~U[2026-09-04 09:00:00.000000Z]
          },
          "audit"
        )

      result = Threadline.transaction_context(txn.id, repo: @repo, storage_schema: "audit")

      assert result.transaction.id == txn.id
      assert result.action.id == action.id
      assert [%LinkedChange{} = linked_change] = result.changes
      assert linked_change.audit_change.id == change.id
      assert linked_change.transaction.id == txn.id
      assert linked_change.action.id == action.id

      assert Threadline.transaction_context(txn.id, repo: @repo).transaction == nil
    end

    test "packages one transaction drill-down with linked change, transaction, and action context" do
      action = insert_action(%{correlation_id: "corr-transaction", name: "incident.reviewed"})
      txn = insert_transaction(%{action_id: action.id})
      captured_at = ~U[2026-09-04 09:00:00.000000Z]

      change =
        insert_change(txn, %{
          table_name: "users",
          table_pk: %{"id" => "tx-1"},
          captured_at: captured_at
        })

      result = Threadline.transaction_context(txn.id, repo: @repo)

      assert %LinkedTransaction{} = result
      assert result.transaction.id == txn.id
      assert result.action.id == action.id
      assert [%LinkedChange{} = linked_change] = result.changes
      assert linked_change.audit_change.id == change.id
      assert linked_change.transaction.id == txn.id
      assert linked_change.action.id == action.id
      refute Map.has_key?(result, :change_diff)
      refute Map.has_key?(linked_change, :change_diff)
    end

    test "returns an empty linked transaction when the transaction has no captured changes" do
      result = Threadline.transaction_context(Ecto.UUID.generate(), repo: @repo)

      assert %LinkedTransaction{} = result
      assert result.transaction == nil
      assert result.action == nil
      assert result.changes == []
    end
  end

  describe "incident_bundle/2" do
    test "packages ordered linked changes with JSON-ready diffs" do
      action = insert_action(%{correlation_id: "corr-incident", name: "incident.reviewed"})
      txn = insert_transaction(%{action_id: action.id})
      older = ~U[2026-09-04 09:00:00.000000Z]
      newer = DateTime.add(older, 60, :second)

      older_change =
        insert_change(txn, %{
          table_name: "users",
          table_pk: %{"id" => "incident-older"},
          op: "update",
          data_after: %{"name" => "Alice 1"},
          changed_fields: ["name"],
          changed_from: %{"name" => "Alice 0"},
          captured_at: older
        })

      newer_change =
        insert_change(txn, %{
          table_name: "users",
          table_pk: %{"id" => "incident-newer"},
          op: "update",
          data_after: %{"name" => "Alice 2"},
          changed_fields: ["name"],
          changed_from: %{"name" => "Alice 1"},
          captured_at: newer
        })

      assert {:ok, %IncidentBundle{} = result} = Threadline.incident_bundle(txn.id, repo: @repo)
      assert result.transaction.id == txn.id
      assert result.action.id == action.id

      assert [
               %IncidentChange{} = first_change,
               %IncidentChange{} = second_change
             ] = result.changes

      assert first_change.linked_change.audit_change.id == newer_change.id
      assert second_change.linked_change.audit_change.id == older_change.id
      assert %LinkedChange{} = first_change.linked_change
      assert first_change.linked_change.transaction.id == txn.id
      assert first_change.linked_change.action.id == action.id
      assert first_change.change_diff["schema_version"] == 1

      assert [%{"name" => "name", "after" => "Alice 2", "before" => "Alice 1"}] =
               first_change.change_diff["field_changes"]
    end

    test "returns {:ok, bundle} with empty changes for an existing transaction with no captured changes" do
      action = insert_action(%{correlation_id: "corr-empty", name: "incident.empty"})
      txn = insert_transaction(%{action_id: action.id})

      assert {:ok, %IncidentBundle{} = result} = Threadline.incident_bundle(txn.id, repo: @repo)
      assert result.transaction.id == txn.id
      assert result.action.id == action.id
      assert result.changes == []
    end

    test "returns {:error, :not_found} when the parent audit transaction does not exist" do
      assert {:error, :not_found} =
               Threadline.incident_bundle(Ecto.UUID.generate(), repo: @repo)
    end
  end
end
