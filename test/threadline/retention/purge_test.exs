defmodule Threadline.Retention.PurgeTest do
  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Retention

  setup do
    prev = Application.get_env(:threadline, :retention)

    on_exit(fn ->
      Application.put_env(:threadline, :retention, prev)
    end)

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: true
    )

    :ok
  end

  test "purge/1 without repo raises KeyError" do
    assert_raise KeyError, fn ->
      Retention.purge([])
    end
  end

  test "purge/1 returns disabled when retention.enabled is false" do
    Application.put_env(:threadline, :retention,
      enabled: false,
      keep_days: 1,
      delete_empty_transactions: true
    )

    assert Retention.purge(repo: Repo) == {:error, :disabled}
  end

  # batch_size / max_batches: multi-batch purge deletes expired changes then empty parents.
  test "purge/1 multi-batch, idempotent, and removes empty audit_transactions" do
    cutoff = DateTime.utc_now(:microsecond)
    past = DateTime.add(cutoff, -10, :day)

    for _i <- 1..6 do
      {:ok, tx} =
        Repo.insert(
          AuditTransaction.changeset(%AuditTransaction{}, %{
            txid: System.unique_integer([:positive]),
            occurred_at: cutoff
          })
        )

      Repo.insert!(
        AuditChange.changeset(%AuditChange{}, %{
          transaction_id: tx.id,
          table_schema: "public",
          table_name: "purge_fixture",
          table_pk: %{"id" => Ecto.UUID.generate()},
          op: "insert",
          captured_at: past,
          data_after: %{"n" => 1}
        })
      )
    end

    assert Repo.aggregate(AuditChange, :count) == 6
    assert Repo.aggregate(AuditTransaction, :count) == 6

    summary =
      Retention.purge(repo: Repo, batch_size: 2, max_batches: 20)

    assert summary.deleted_changes == 6
    assert summary.deleted_transactions == 6
    assert summary.batches_run >= 2

    assert Repo.aggregate(AuditChange, :count) == 0
    assert Repo.aggregate(AuditTransaction, :count) == 0

    again = Retention.purge(repo: Repo, batch_size: 2, max_batches: 10)
    assert again.deleted_changes == 0
    assert again.deleted_transactions == 0
  end

  test "purge/1 skips orphan cleanup when delete_empty_transactions is false" do
    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: false
    )

    cutoff = DateTime.utc_now(:microsecond)
    past = DateTime.add(cutoff, -10, :day)

    {:ok, tx} =
      Repo.insert(
        AuditTransaction.changeset(%AuditTransaction{}, %{
          txid: System.unique_integer([:positive]),
          occurred_at: cutoff
        })
      )

    Repo.insert!(
      AuditChange.changeset(%AuditChange{}, %{
        transaction_id: tx.id,
        table_schema: "public",
        table_name: "purge_fixture",
        table_pk: %{"id" => Ecto.UUID.generate()},
        op: "insert",
        captured_at: past,
        data_after: %{}
      })
    )

    tx_id = tx.id

    assert %{
             deleted_changes: 1,
             deleted_transactions: 0
           } = Retention.purge(repo: Repo, batch_size: 10, max_batches: 5)

    assert Repo.get(AuditTransaction, tx_id) != nil
  end
end
