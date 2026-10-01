defmodule Threadline.TelemetryHelpersTest do
  use ExUnit.Case, async: true

  import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]

  @event [:threadline, :test, :telemetry_helpers]

  test "an event executed in the test process is received with the returned ref" do
    ref = attach_telemetry!([@event])

    :telemetry.execute(@event, %{count: 1}, %{source: :self})

    assert_receive {@event, ^ref, %{count: 1}, %{source: :self}}
  end

  test "an event executed inside an awaited Task ($callers child) is received" do
    ref = attach_telemetry!([@event])

    Task.async(fn -> :telemetry.execute(@event, %{count: 1}, %{source: :task}) end)
    |> Task.await()

    assert_receive {@event, ^ref, %{count: 1}, %{source: :task}}
  end

  test "an event executed by a bare spawn process (no $callers) is NOT received" do
    ref = attach_telemetry!([@event])
    test_pid = self()

    spawn(fn ->
      :telemetry.execute(@event, %{count: 1}, %{source: :spawn})
      send(test_pid, :emitted)
    end)

    # Telemetry runs handlers synchronously in the emitter before the send,
    # so by the time :emitted arrives, a would-be forward has already either
    # happened or been filtered out — deterministic, no sleep needed.
    assert_receive :emitted
    refute_received {@event, ^ref, _measurements, _metadata}
  end

  test "the handler is detached after the attaching test exits" do
    # `on_exit` callbacks run LIFO, and run in a separate on_exit-runner
    # process from the test process — a linked Agent does not reliably
    # survive to be queried from there. `:persistent_term` survives
    # independent of any process. Registering our check on_exit BEFORE
    # calling attach_telemetry!/1 means the helper's own on_exit (registered
    # second, so it runs first) detaches the handler before our check below
    # runs — letting us prove detachment deterministically, without sleeping.
    key = make_ref()

    on_exit(fn ->
      ref = :persistent_term.get(key)

      handlers_after_detach =
        :telemetry.list_handlers(@event) |> Enum.filter(&(&1.id == ref))

      assert handlers_after_detach == [],
             "expected handler for ref #{inspect(ref)} to be detached on exit"

      :persistent_term.erase(key)
    end)

    ref = attach_telemetry!([@event])
    :persistent_term.put(key, ref)

    handlers_before_exit =
      :telemetry.list_handlers(@event) |> Enum.filter(&(&1.id == ref))

    assert handlers_before_exit != []
  end
end
