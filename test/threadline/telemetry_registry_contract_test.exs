defmodule Threadline.TelemetryRegistryContractTest do
  @moduledoc """
  Runtime allowlist contract for `Threadline.Telemetry.__events__/0`.

  Attaches to every registered event, drives a real operation per event
  family, and asserts the observed measurement and metadata key sets equal
  the registry entry exactly. An event that never fires, or that carries an
  unlisted key, turns this red.

  Extended by later plans in this phase as new events and drivers are added.
  """

  use Threadline.DataCase, async: false

  import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]
  import Plug.Test, only: [conn: 2, init_test_session: 2]

  alias Threadline.OperatorSurface.ThemeAuthPlug

  # Event names this task's driver set covers. Widened to every registry
  # entry as later tasks add their own drivers.
  @driven [
    [:threadline, :operator_surface, :authorize]
  ]

  defp drive_all! do
    drive_operator_surface_authorize!()
  end

  defp drive_operator_surface_authorize! do
    opts = [authorize_fn: fn _ -> :ok end]

    conn(:post, "/audit/theme")
    |> init_test_session(operator_id: "support")
    |> ThemeAuthPlug.call(ThemeAuthPlug.init(opts))
  end

  test "every driven registry event fires with exactly its registered keys" do
    entries = Threadline.Telemetry.__events__()
    driven_entries = Enum.filter(entries, &(&1.name in @driven))

    assert driven_entries != [], "no registry entries matched the driven set — check @driven"

    event_names = Enum.map(entries, & &1.name)
    telemetry_ref = attach_telemetry!(event_names)

    drive_all!()

    for entry <- driven_entries do
      assert_receive {name, ^telemetry_ref, measurements, metadata} when name == entry.name

      assert MapSet.new(Map.keys(measurements)) == MapSet.new(entry.measurements),
             "#{inspect(entry.name)} measurement keys #{inspect(Map.keys(measurements))} " <>
               "do not match registry #{inspect(entry.measurements)}"

      assert MapSet.new(Map.keys(metadata)) == MapSet.new(entry.metadata),
             "#{inspect(entry.name)} metadata keys #{inspect(Map.keys(metadata))} " <>
               "do not match registry #{inspect(entry.metadata)}"
    end
  end
end
