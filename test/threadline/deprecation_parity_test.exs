defmodule Threadline.DeprecationParityTest do
  @moduledoc """
  Pins the exact deprecated-entry-point inventory for `Threadline`,
  `Threadline.Query` and `Threadline.Investigation` (D-11, API-08).

  Every retired name is reached here only through `apply/3` — never a direct
  call — so this file's own compilation never emits a deprecation warning
  and `mix compile --warnings-as-errors` stays clean while still proving
  each deprecated delegate behaves exactly like its replacement over a
  250-change row (so the unbounded 0.12 behavior the delegates preserve is
  actually exercised, not just type-checked).
  """

  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}

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

  # Inserts `n` changes on `table_pk`, each one microsecond apart (strictly
  # increasing `captured_at`, so eager/paged/limited reads all agree on a
  # single unambiguous newest-first order). Returns the inserted changes in
  # insertion (oldest-first) order.
  defp insert_n_changes(txn, table_pk, n, base_time \\ ~U[2026-01-01 00:00:00.000000Z]) do
    for i <- 1..n do
      insert_change(txn, %{
        table_pk: table_pk,
        captured_at: DateTime.add(base_time, i, :microsecond)
      })
    end
  end

  describe "history/3 (deprecated, D-02, D-04)" do
    test "apply(Threadline, :history, ...) over 250 changes returns 250 AuditChange, ids equal row_history(limit: :infinity)" do
      txn = insert_transaction()
      table_pk = %{"id" => "history-parity"}
      changes = insert_n_changes(txn, table_pk, 250)

      args = [FakeUser, "history-parity", [repo: @repo]]
      results = apply(Threadline, :history, args)

      assert is_list(results)
      assert length(results) == 250
      assert Enum.all?(results, &match?(%AuditChange{}, &1))

      replacement =
        Threadline.row_history(FakeUser, "history-parity", repo: @repo, limit: :infinity)

      assert Enum.map(results, & &1.id) == Enum.map(replacement, & &1.audit_change.id)
      assert Enum.map(results, & &1.id) == changes |> Enum.reverse() |> Enum.map(& &1.id)
    end

    test "apply(Threadline.Query, :history, ...) returns the same ids as the facade's deprecated history/3" do
      txn = insert_transaction()
      table_pk = %{"id" => "history-query-parity"}
      insert_n_changes(txn, table_pk, 250)

      facade_args = [FakeUser, "history-query-parity", [repo: @repo]]
      query_args = [FakeUser, "history-query-parity", [repo: @repo]]

      facade_results = apply(Threadline, :history, facade_args)
      query_results = apply(Threadline.Query, :history, query_args)

      assert Enum.map(query_results, & &1.id) == Enum.map(facade_results, & &1.id)
    end

    test "limit: nil returns all 250 (nil maps to :infinity, D-04)" do
      txn = insert_transaction()
      table_pk = %{"id" => "history-limit-nil"}
      insert_n_changes(txn, table_pk, 250)

      args = [FakeUser, "history-limit-nil", [repo: @repo, limit: nil]]
      results = apply(Threadline, :history, args)

      assert length(results) == 250
    end

    test "limit: 5 returns the newest 5" do
      txn = insert_transaction()
      table_pk = %{"id" => "history-limit-5"}
      changes = insert_n_changes(txn, table_pk, 250)

      args = [FakeUser, "history-limit-5", [repo: @repo, limit: 5]]
      results = apply(Threadline, :history, args)

      assert length(results) == 5
      expected_ids = changes |> Enum.reverse() |> Enum.take(5) |> Enum.map(& &1.id)
      assert Enum.map(results, & &1.id) == expected_ids
    end

    test "limit: 0 raises ArgumentError" do
      args = [FakeUser, "history-limit-zero", [repo: @repo, limit: 0]]

      assert_raise ArgumentError, fn -> apply(Threadline, :history, args) end
    end

    test "Threadline.__info__(:deprecated) names {:history, 3} with the exact message" do
      assert {{:history, 3}, "Use Threadline.row_history/3 instead."} in Threadline.__info__(
               :deprecated
             )
    end
  end
end
