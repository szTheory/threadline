defmodule Threadline.InvestigationTest do
  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}
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

  defp insert_transaction(attrs \\ %{}) do
    defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}
    @repo.insert!(AuditTransaction.changeset(Map.merge(defaults, attrs)))
  end

  defp insert_change(transaction, attrs) do
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

    @repo.insert!(AuditChange.changeset(Map.merge(defaults, Map.new(attrs))))
  end

  defp insert_action(attrs) do
    actor = actor!(:user, "investigator")

    defaults = %{
      name: "investigation.test",
      actor_ref: ActorRef.to_map(actor),
      status: :ok,
      correlation_id: "corr-default"
    }

    @repo.insert!(AuditAction.changeset(%AuditAction{}, Map.merge(defaults, attrs)))
  end

  defp actor!(type, id) do
    {:ok, ref} = ActorRef.new(type, id)
    ref
  end

  defp page_entry_ids(%TimelinePage{entries: entries}), do: Enum.map(entries, & &1.id)

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

      assert Enum.map(results, & &1.table_pk["id"]) == ["row-1", "row-1"]
      assert Enum.all?(results, &(&1.table_name == "users"))
      assert Enum.map(results, & &1.captured_at) == [newer, older]
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
        |> Enum.map(& &1.id)

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

      assert Enum.map(results, & &1.transaction_id) |> Enum.uniq() == [actor_txn.id]
      assert Enum.sort(Enum.map(results, & &1.table_name)) == ["posts", "users"]
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

      eager_ids = Threadline.actor_window(actor, [], repo: @repo) |> Enum.map(& &1.id)

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

      assert Enum.map(results, & &1.transaction_id) == [matching_txn.id]
      assert Enum.all?(results, &(&1.table_pk["id"] == "corr-1"))
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
        Threadline.correlation_bundle("corr-paged", [], repo: @repo) |> Enum.map(& &1.id)

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
end
