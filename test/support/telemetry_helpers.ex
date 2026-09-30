defmodule Threadline.TelemetryHelpers do
  @moduledoc """
  Isolates `:telemetry` handlers so an `async: true` test only sees the events
  its own process (or a `$callers` child, e.g. a `Task.async/1` it awaits)
  emits.

  `:telemetry` handlers are VM-global: a handler attached by one test also
  fires for the same event emitted by every other concurrently running test,
  with no built-in way to tell them apart. A unique handler id or a ref tag on
  the handler config does not stop that — the handler still runs and still
  forwards the foreign event, just tagged with its own ref. `attach_telemetry!/1`
  closes that gap by checking the emitting process's identity before
  forwarding: only the attaching test process, or a process that lists it in
  `Process.get(:"$callers", [])` (a `Task` it started and awaited, a LiveView
  test child), gets the event.

  Call this from `setup` or directly inside a test body — never from
  `setup_all`, which runs in a different process than the test itself, so the
  identity check would always fail.
  """

  @doc false
  @spec handle_event(
          :telemetry.event_name(),
          :telemetry.event_measurements(),
          :telemetry.event_metadata(),
          map()
        ) ::
          :ok
  def handle_event(event, measurements, metadata, %{test_pid: test_pid, ref: ref}) do
    if self() == test_pid or test_pid in Process.get(:"$callers", []) do
      send(test_pid, {event, ref, measurements, metadata})
    end

    :ok
  end

  @doc """
  Attaches a handler for `events` (a list of `:telemetry` event names) that
  forwards `{event, ref, measurements, metadata}` to the calling process only
  when the event was emitted by that same process, or by a process that lists
  it in `$callers`.

  Returns the `ref` to pin in assertions (`assert_receive {event, ^ref, ...}`).
  Registers an `on_exit` callback that detaches the handler.
  """
  @spec attach_telemetry!([:telemetry.event_name()]) :: reference()
  def attach_telemetry!(events) when is_list(events) do
    test_pid = self()
    ref = make_ref()

    case :telemetry.attach_many(ref, events, &__MODULE__.handle_event/4, %{
           test_pid: test_pid,
           ref: ref
         }) do
      :ok ->
        :ok

      {:error, reason} ->
        raise "Threadline.TelemetryHelpers.attach_telemetry!/1 failed to attach: #{inspect(reason)}"
    end

    ExUnit.Callbacks.on_exit(fn -> :telemetry.detach(ref) end)

    ref
  end
end
