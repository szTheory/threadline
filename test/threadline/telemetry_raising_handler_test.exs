defmodule Threadline.TelemetryRaisingHandlerTest do
  @moduledoc """
  D-13: a crashing adopter handler never breaks export or purge.

  `:telemetry` 1.4.2 (`deps/telemetry/src/telemetry.erl`, `do_execute/4` and
  `attach_many/4`) catches any raise/exit/throw from a handler, detaches that
  handler id from **every** event it was attached with via `attach_many`
  (not only the one that fired), and emits
  `[:telemetry, :handler, :failure]` naming the handler id — the operation
  that triggered the event otherwise proceeds exactly as if no handler were
  attached at all.
  """

  use Threadline.DataCase, async: false

  import ExUnit.CaptureLog
  import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Export
  alias Threadline.Governance.RetentionRun
  alias Threadline.Retention

  @export_table "telemetry_raising_handler_fixture"

  # One attach_many across all four events D-13 cares about: the two export
  # outcomes, the per-batch retention event, and the purge-span stop event.
  @all_four_events [
    [:threadline, :export, :completed],
    [:threadline, :export, :failed],
    [:threadline, :retention, :batch_purged],
    [:threadline, :retention, :purge, :stop]
  ]

  @retention_events [
    [:threadline, :retention, :batch_purged],
    [:threadline, :retention, :purge, :stop]
  ]

  @doc false
  def raise_handler(_event, _measurements, _metadata, _config) do
    raise "handler boom"
  end

  defp attach_raising!(id, events) do
    :ok = :telemetry.attach_many(id, events, &__MODULE__.raise_handler/4, nil)

    ExUnit.Callbacks.on_exit(fn ->
      # Already detached by telemetry itself once the handler raised; a
      # second detach of an already-detached id returns {:error, :not_found}
      # — harmless, so it is discarded rather than asserted on.
      :telemetry.detach(id)
    end)

    :ok
  end

  defp insert_transaction(attrs \\ %{}) do
    defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}

    Repo.insert!(
      AuditTransaction.changeset(Map.merge(defaults, attrs)),
      repo_opts()
    )
  end

  defp insert_change(transaction, attrs \\ %{}) do
    defaults = %{
      table_schema: "public",
      table_name: @export_table,
      table_pk: %{"id" => "r-1"},
      op: "insert",
      data_after: %{"n" => 1},
      changed_fields: ["n"],
      captured_at: DateTime.utc_now(),
      transaction_id: transaction.id
    }

    Repo.insert!(
      AuditChange.changeset(Map.merge(defaults, attrs)),
      repo_opts()
    )
  end

  defp refute_handler_attached!(events, id) do
    for event <- events do
      refute Enum.any?(:telemetry.list_handlers(event), &(&1.id == id)),
             "expected handler #{inspect(id)} to be detached from #{inspect(event)}, " <>
               "but :telemetry.list_handlers/1 still lists it"
    end
  end

  test "a raising handler attached to all four events does not change the export result, " <>
         "detaches from every one of those events, and emits [:telemetry, :handler, :failure]" do
    id = make_ref()
    attach_raising!(id, @all_four_events)

    failure_ref = attach_telemetry!([[:telemetry, :handler, :failure]])

    tx = insert_transaction()
    insert_change(tx)

    {result, log} =
      with_log(fn ->
        Export.to_csv_iodata([repo: Repo, table: @export_table], [])
      end)

    assert log =~ "handler boom"
    assert {:ok, %{returned_count: 1}} = result

    refute_handler_attached!(@all_four_events, id)

    assert_receive {[:telemetry, :handler, :failure], ^failure_ref, measurements, metadata}
    assert metadata.handler_id == id
    assert metadata.event_name == [:threadline, :export, :completed]
    assert is_integer(measurements.monotonic_time)
  end

  describe "retention purge" do
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

    test "a raising handler on batch_purged and purge :stop does not change the purge " <>
           "result or deleted rows, and is detached from both events afterward" do
      cutoff = DateTime.utc_now(:microsecond)
      past = DateTime.add(cutoff, -10, :day)

      tx = insert_transaction(%{occurred_at: cutoff})
      insert_change(tx, %{captured_at: past, data_after: %{"tracked" => true}})

      id = make_ref()
      attach_raising!(id, @retention_events)

      {result, log} =
        with_log(fn ->
          Retention.purge(repo: Repo, batch_size: 10, max_batches: 5)
        end)

      assert log =~ "handler boom"

      assert %{
               deleted_changes: 1,
               deleted_transactions: 1,
               batches_run: batches_run,
               dry_run: false
             } = result

      assert batches_run >= 1

      assert Repo.aggregate(AuditChange, :count, :id, repo_opts()) == 0
      assert Repo.aggregate(AuditTransaction, :count, :id, repo_opts()) == 0

      refute_handler_attached!(@retention_events, id)
    end
  end
end
