defmodule Threadline.RetentionTest do
  use Threadline.DataCase

  import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Governance.RetentionRun
  alias Threadline.Retention

  @purge_span_events [
    [:threadline, :retention, :purge, :start],
    [:threadline, :retention, :purge, :stop],
    [:threadline, :retention, :purge, :exception]
  ]
  @batch_purged_event [:threadline, :retention, :batch_purged]

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
    ref = attach_telemetry!(@purge_span_events)

    assert_raise KeyError, fn ->
      Retention.purge([])
    end

    for event <- @purge_span_events do
      refute_received {^event, ^ref, _measurements, _metadata}
    end
  end

  test "purge/1 returns disabled when retention.enabled is false" do
    Application.put_env(:threadline, :retention,
      enabled: false,
      keep_days: 1,
      delete_empty_transactions: true
    )

    ref = attach_telemetry!(@purge_span_events)

    assert Retention.purge(repo: Repo) == {:error, :disabled}

    for event <- @purge_span_events do
      refute_received {^event, ^ref, _measurements, _metadata}
    end
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

    ref = attach_telemetry!(@purge_span_events)

    summary =
      Retention.purge(repo: Repo, batch_size: 2, max_batches: 20)

    assert summary.deleted_changes == 6
    assert summary.deleted_transactions == 6
    assert summary.batches_run >= 2

    assert count_changes("threadline") == 0
    assert count_transactions("threadline") == 0

    assert_receive {[:threadline, :retention, :purge, :start], ^ref, _start_measurements,
                    %{dry_run: false}}

    assert_receive {[:threadline, :retention, :purge, :stop], ^ref, stop_measurements,
                    %{dry_run: false}}

    assert stop_measurements.deleted_changes == summary.deleted_changes
    assert stop_measurements.deleted_transactions == summary.deleted_transactions
    assert stop_measurements.batches_run == summary.batches_run
    assert is_integer(stop_measurements.duration)
    assert stop_measurements.duration >= 0

    refute_received {[:threadline, :retention, :purge, :exception], ^ref, _, _}

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

    ref = attach_telemetry!(@purge_span_events)

    result =
      Retention.purge(
        repo: Repo,
        storage_schema: "audit",
        dry_run: true,
        batch_size: 10,
        max_batches: 5
      )

    assert result.deleted_changes == 1
    assert result.deleted_transactions == 2
    assert result.batches_run == 0
    assert result.dry_run == true

    assert_receive {[:threadline, :retention, :purge, :start], ^ref, _start_measurements,
                    %{dry_run: true}}

    assert_receive {[:threadline, :retention, :purge, :stop], ^ref, stop_measurements,
                    %{dry_run: true}}

    assert stop_measurements.deleted_changes == result.deleted_changes
    assert stop_measurements.deleted_transactions == result.deleted_transactions
    assert stop_measurements.batches_run == 0

    assert count_changes("audit") == 1
    assert count_transactions("audit") == 2
    assert count_changes("threadline") == 2
    assert count_transactions("threadline") == 5
  end

  test "dry run counts the transactions a purge would empty, matching a completed real purge (D-20 regression)" do
    cutoff = ~U[2001-06-01 00:00:00.000000Z]

    t1 = insert_transaction("threadline", occurred_at: cutoff)
    insert_change("threadline", t1, captured_at: DateTime.add(cutoff, -1, :microsecond))

    t2 = insert_transaction("threadline", occurred_at: cutoff)
    insert_change("threadline", t2, captured_at: cutoff)

    t3 = insert_transaction("threadline", occurred_at: cutoff)
    insert_change("threadline", t3, captured_at: DateTime.add(cutoff, -1, :second))
    insert_change("threadline", t3, captured_at: DateTime.add(cutoff, 1, :second))

    dry = Retention.purge(repo: Repo, cutoff: cutoff, dry_run: true)
    assert dry.deleted_changes == 2
    assert dry.deleted_transactions == 1

    real =
      Retention.purge(repo: Repo, cutoff: cutoff, batch_size: 10, max_batches: 5, sleep_ms: 0)

    assert real.deleted_changes == 2
    assert real.deleted_transactions == 1
  end

  test "dry run ignores :batch_size and :max_batches (preview is a full-table count, not batched)" do
    cutoff = ~U[2001-06-01 00:00:00.000000Z]

    for _ <- 1..5 do
      tx = insert_transaction("threadline", occurred_at: cutoff)
      insert_change("threadline", tx, captured_at: DateTime.add(cutoff, -1, :second))
    end

    unbounded = Retention.purge(repo: Repo, cutoff: cutoff, dry_run: true)

    bounded =
      Retention.purge(
        repo: Repo,
        cutoff: cutoff,
        dry_run: true,
        batch_size: 1,
        max_batches: 1
      )

    assert bounded == unbounded
    assert bounded.deleted_changes == 5
    assert bounded.deleted_transactions == 5
    assert bounded.batches_run == 0
  end

  test "cutoff newer than the policy cutoff raises ArgumentError naming retention" do
    future = DateTime.add(DateTime.utc_now(:microsecond), 1, :day)

    ref = attach_telemetry!(@purge_span_events)

    assert_raise ArgumentError, ~r/retention/, fn ->
      Retention.purge(repo: Repo, cutoff: future, dry_run: true)
    end

    for event <- @purge_span_events do
      refute_received {^event, ^ref, _measurements, _metadata}
    end
  end

  test "a precision-0 cutoff gives the same dry-run result as the equivalent microsecond cutoff" do
    cutoff_usec = ~U[2001-06-01 00:00:00.000000Z]
    cutoff_precision0 = DateTime.truncate(cutoff_usec, :second)

    t1 = insert_transaction("threadline", occurred_at: cutoff_usec)
    insert_change("threadline", t1, captured_at: DateTime.add(cutoff_usec, -1, :second))

    dry_usec = Retention.purge(repo: Repo, cutoff: cutoff_usec, dry_run: true)
    dry_precision0 = Retention.purge(repo: Repo, cutoff: cutoff_precision0, dry_run: true)

    assert dry_precision0 == dry_usec
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
