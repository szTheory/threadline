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

  describe "Phase 66 — emit_health_checked/3 additive measurement" do
    test "emits :health, :checked with covered, uncovered, and expected_uncovered measurements" do
      :telemetry.attach(
        "test-health-checked-3-arity",
        [:threadline, :health, :checked],
        fn _name, measurements, _meta, pid ->
          send(pid, {:health_checked, measurements})
        end,
        self()
      )

      on_exit(fn -> :telemetry.detach("test-health-checked-3-arity") end)

      Threadline.Telemetry.emit_health_checked(2, 1, 3)

      assert_receive {:health_checked, %{covered: 2, uncovered: 1, expected_uncovered: 3}}
    end

    test "old-shape destructure %{covered: c, uncovered: u} continues to work (additive)" do
      :telemetry.attach(
        "test-health-checked-old-destructure",
        [:threadline, :health, :checked],
        fn _name, %{covered: covered, uncovered: uncovered}, _meta, pid ->
          send(pid, {:health_checked_old_shape, covered, uncovered})
        end,
        self()
      )

      on_exit(fn -> :telemetry.detach("test-health-checked-old-destructure") end)

      Threadline.Telemetry.emit_health_checked(7, 4, 2)

      assert_receive {:health_checked_old_shape, 7, 4}
    end
  end

  describe "Phase 66 — emit_health_checked_error/1 sibling event" do
    test "emits :health, :checked, :error with %{error: message} metadata" do
      :telemetry.attach(
        "test-health-checked-error",
        [:threadline, :health, :checked, :error],
        fn _name, measurements, metadata, pid ->
          send(pid, {:health_error, measurements, metadata})
        end,
        self()
      )

      on_exit(fn -> :telemetry.detach("test-health-checked-error") end)

      Threadline.Telemetry.emit_health_checked_error("connection refused")

      assert_receive {:health_error, %{}, %{error: "connection refused"}}
    end
  end
end
