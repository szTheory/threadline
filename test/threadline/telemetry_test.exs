defmodule Threadline.TelemetryTest do
  use Threadline.DataCase

  alias Threadline.Semantics.ActorRef

  @repo Threadline.Test.Repo

  defp actor!(type \\ :user, id \\ "u-tel-1") do
    {:ok, ref} = ActorRef.new(type, id)
    ref
  end

  describe "HLTH-04: [:threadline, :action, :recorded] event" do
    test "emitted with status :ok on successful record_action/2" do
      :telemetry.attach(
        "test-action-recorded-ok",
        [:threadline, :action, :recorded],
        fn _name, measurements, _meta, pid ->
          send(pid, {:action_recorded, measurements})
        end,
        self()
      )

      on_exit(fn -> :telemetry.detach("test-action-recorded-ok") end)

      Threadline.record_action(:test_event, actor: actor!(), repo: @repo)

      assert_receive {:action_recorded, %{status: :ok}}
    end

    test "emitted with status :error when actor is missing" do
      :telemetry.attach(
        "test-action-recorded-err",
        [:threadline, :action, :recorded],
        fn _name, measurements, _meta, pid ->
          send(pid, {:action_recorded, measurements})
        end,
        self()
      )

      on_exit(fn -> :telemetry.detach("test-action-recorded-err") end)

      Threadline.record_action(:test_event, repo: @repo)

      assert_receive {:action_recorded, %{status: :error}}
    end
  end

  describe "HLTH-03: [:threadline, :transaction, :committed] event" do
    test "emitted with table_count: 0 when record_action/2 succeeds (proxy)" do
      :telemetry.attach(
        "test-txn-committed",
        [:threadline, :transaction, :committed],
        fn _name, measurements, _meta, pid ->
          send(pid, {:txn_committed, measurements})
        end,
        self()
      )

      on_exit(fn -> :telemetry.detach("test-txn-committed") end)

      Threadline.record_action(:test_event, actor: actor!(), repo: @repo)

      assert_receive {:txn_committed, %{table_count: 0}}
    end

    test "Threadline.Telemetry.transaction_committed/2 emits with caller-provided table_count" do
      :telemetry.attach(
        "test-txn-committed-explicit",
        [:threadline, :transaction, :committed],
        fn _name, measurements, _meta, pid ->
          send(pid, {:txn_committed, measurements})
        end,
        self()
      )

      on_exit(fn -> :telemetry.detach("test-txn-committed-explicit") end)

      Threadline.Telemetry.transaction_committed(%{}, table_count: 5)

      assert_receive {:txn_committed, %{table_count: 5}}
    end
  end
end
