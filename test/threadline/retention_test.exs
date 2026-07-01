defmodule Threadline.RetentionTest do
  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Governance.RetentionRun
  alias Threadline.Retention

  defp insert_transaction(storage_schema, attrs) do
    defaults = %{
      txid: System.unique_integer([:positive]),
      occurred_at: DateTime.utc_now(:microsecond)
    }

    Repo.insert!(
      AuditTransaction.changeset(%AuditTransaction{}, Map.merge(defaults, Map.new(attrs))),
      repo_opts(storage_schema)
    )
  end

  defp insert_change(storage_schema, transaction, attrs) do
    defaults = %{
      transaction_id: transaction.id,
      table_schema: "public",
      table_name: "purge_fixture",
      table_pk: %{"id" => Ecto.UUID.generate()},
      op: "insert",
      captured_at: DateTime.add(DateTime.utc_now(:microsecond), -10, :day),
      data_after: %{"n" => 1}
    }

    Repo.insert!(
      AuditChange.changeset(%AuditChange{}, Map.merge(defaults, Map.new(attrs))),
      repo_opts(storage_schema)
    )
  end

  defp count_changes(storage_schema) do
    Repo.aggregate(AuditChange, :count, :id, repo_opts(storage_schema))
  end

  defp count_transactions(storage_schema) do
    Repo.aggregate(AuditTransaction, :count, :id, repo_opts(storage_schema))
  end

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

    Repo.delete_all(RetentionRun, repo_opts())

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
      tx = insert_transaction("threadline", occurred_at: cutoff)
      insert_change("threadline", tx, captured_at: past)
    end

    assert count_changes("threadline") == 6
    assert count_transactions("threadline") == 6

    summary =
      Retention.purge(repo: Repo, batch_size: 2, max_batches: 20)

    assert summary.deleted_changes == 6
    assert summary.deleted_transactions == 6
    assert summary.batches_run >= 2

    assert count_changes("threadline") == 0
    assert count_transactions("threadline") == 0

    again = Retention.purge(repo: Repo, batch_size: 2, max_batches: 10)
    assert again.deleted_changes == 0
    assert again.deleted_transactions == 0
  end

  test "purge/1 records a completed retention run" do
    cutoff = DateTime.utc_now(:microsecond)
    past = DateTime.add(cutoff, -10, :day)

    tx = insert_transaction("threadline", occurred_at: cutoff)
    insert_change("threadline", tx, captured_at: past, data_after: %{"tracked" => true})

    assert %{deleted_changes: 1, deleted_transactions: 1} =
             Retention.purge(repo: Repo, batch_size: 10, max_batches: 5)

    [run] = Repo.all(RetentionRun, repo_opts())
    assert run.status == "completed"
    assert run.deleted_count == 2
    assert is_integer(run.duration_ms)
    assert run.duration_ms >= 0
    assert %DateTime{} = run.started_at
    assert %DateTime{} = run.completed_at
  end

  test "purge/1 skips orphan cleanup when delete_empty_transactions is false" do
    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: false
    )

    cutoff = DateTime.utc_now(:microsecond)
    past = DateTime.add(cutoff, -10, :day)

    tx = insert_transaction("threadline", occurred_at: cutoff)
    insert_change("threadline", tx, captured_at: past, data_after: %{})

    tx_id = tx.id

    assert %{
             deleted_changes: 1,
             deleted_transactions: 0
           } = Retention.purge(repo: Repo, batch_size: 10, max_batches: 5)

    assert Repo.get(AuditTransaction, tx_id, repo_opts()) != nil
  end

  test "dry-run counts only the selected storage schema" do
    ensure_storage_schema!("audit")

    cutoff = DateTime.utc_now(:microsecond)
    past = DateTime.add(cutoff, -10, :day)

    audit_tx = insert_transaction("audit", occurred_at: cutoff)
    insert_change("audit", audit_tx, captured_at: past)
    insert_transaction("audit", occurred_at: cutoff)

    for _ <- 1..2 do
      threadline_tx = insert_transaction("threadline", occurred_at: cutoff)
      insert_change("threadline", threadline_tx, captured_at: past)
    end

    for _ <- 1..3 do
      insert_transaction("threadline", occurred_at: cutoff)
    end

    result =
      Retention.purge(
        repo: Repo,
        storage_schema: "audit",
        dry_run: true,
        batch_size: 10,
        max_batches: 5
      )

    assert result.deleted_changes == 1
    assert result.deleted_transactions == 1
    assert result.batches_run == 0
    assert result.dry_run == true

    assert count_changes("audit") == 1
    assert count_transactions("audit") == 2
    assert count_changes("threadline") == 2
    assert count_transactions("threadline") == 5
  end

  test "purge deletes selected storage rows and records the run in the selected schema" do
    ensure_storage_schema!("audit")

    cutoff = DateTime.utc_now(:microsecond)
    past = DateTime.add(cutoff, -10, :day)

    audit_tx = insert_transaction("audit", occurred_at: cutoff)
    insert_change("audit", audit_tx, captured_at: past)
    insert_transaction("audit", occurred_at: cutoff)

    threadline_tx = insert_transaction("threadline", occurred_at: cutoff)
    insert_change("threadline", threadline_tx, captured_at: past)
    insert_transaction("threadline", occurred_at: cutoff)

    result =
      Retention.purge(
        repo: Repo,
        storage_schema: "audit",
        batch_size: 1,
        max_batches: 10,
        sleep_ms: 0
      )

    assert result.deleted_changes == 1
    assert result.deleted_transactions == 2
    assert result.batches_run >= 1

    assert count_changes("audit") == 0
    assert count_transactions("audit") == 0
    assert count_changes("threadline") == 1
    assert count_transactions("threadline") == 2

    assert [%RetentionRun{status: "completed", deleted_count: 3}] =
             Repo.all(RetentionRun, repo_opts("audit"))

    assert Repo.all(RetentionRun, repo_opts()) == []
  end
end
