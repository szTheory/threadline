defmodule Threadline.TelemetryRegistryContractTest do
  @moduledoc """
  Runtime allowlist and static-scan contract for `Threadline.Telemetry`.

  The runtime allowlist attaches to every registered event, drives a real
  operation per event family, and asserts the observed measurement and
  metadata key sets equal the registry entry exactly. An event that never
  fires, or that carries an unlisted key, turns this red.

  The static scan proves every `:telemetry.execute/3` and `:telemetry.span/3`
  call in `lib/` lives in `lib/threadline/telemetry.ex`, that no registered
  event name contains `:query`, and that no Mix task references
  `Threadline.Telemetry` directly.

  Extended by later plans in this phase as new events and drivers are added.
  """

  use Threadline.DataCase, async: false

  import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]
  import Plug.Test, only: [conn: 2, init_test_session: 2]

  alias Threadline.OperatorSurface.Auth
  alias Threadline.OperatorSurface.Coverage.OnMount, as: CoverageOnMount
  alias Threadline.OperatorSurface.ThemeAuthPlug
  alias Threadline.Semantics.ActorRef

  @repo Threadline.Test.Repo

  defp mock_socket(assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      endpoint: MyApp.Endpoint,
      router: MyApp.Router,
      assigns: Map.merge(%{__changed__: %{}}, assigns)
    }
  end

  defp drive_all! do
    drive_action_recorded_and_transaction_committed!()
    drive_health_checked!()
    drive_health_checked_error!()
    drive_health_findings_checked!()
    drive_operator_surface_authorize!()
    drive_operator_surface_export_authorize!()
    drive_operator_surface_actor_ref_mismatch!()
  end

  defp drive_action_recorded_and_transaction_committed! do
    {:ok, actor_ref} = ActorRef.new(:user, "registry-contract-driver")
    Threadline.record_action(:registry_contract_test_event, actor: actor_ref, repo: @repo)
  end

  defp drive_health_checked! do
    Threadline.Health.trigger_coverage(repo: @repo, schema: "public")
  end

  defp drive_health_checked_error! do
    socket =
      mock_socket(%{
        threadline_coverage_enabled: true,
        threadline_repo: Threadline.Test.NoSuchRepo
      })

    CoverageOnMount.on_mount([], %{}, %{}, socket)
  end

  defp drive_health_findings_checked! do
    Threadline.Health.trigger_findings(repo: @repo)
  end

  defp drive_operator_surface_authorize! do
    opts = [authorize_fn: fn _ -> :ok end]

    conn(:post, "/audit/theme")
    |> init_test_session(operator_id: "support")
    |> ThemeAuthPlug.call(ThemeAuthPlug.init(opts))
  end

  defp drive_operator_surface_export_authorize! do
    opts = [
      authorize_fn: fn _socket -> :ok end,
      export_authorize_fn: fn _mirror -> raise "authorization backend unavailable" end
    ]

    Auth.on_mount(opts, %{}, %{}, mock_socket())
  end

  defp drive_operator_surface_actor_ref_mismatch! do
    session = %{"threadline_actor_ref" => ~s({"id":"user-1","type":"user"})}
    scope = %{user_id: 456}
    opts = [authorize_fn: fn _socket -> {:ok, scope} end]

    Auth.on_mount(opts, %{}, session, mock_socket())
  end

  test "every registry event fires with exactly its registered keys" do
    entries = Threadline.Telemetry.__events__()
    assert entries != [], "the registry is empty — Threadline.Telemetry.__events__/0 is broken"

    event_names = Enum.map(entries, & &1.name)
    telemetry_ref = attach_telemetry!(event_names)

    drive_all!()

    for entry <- entries do
      assert_receive {name, ^telemetry_ref, measurements, metadata} when name == entry.name

      assert MapSet.new(Map.keys(measurements)) == MapSet.new(entry.measurements),
             "#{inspect(entry.name)} measurement keys #{inspect(Map.keys(measurements))} " <>
               "do not match registry #{inspect(entry.measurements)}"

      assert MapSet.new(Map.keys(metadata)) == MapSet.new(entry.metadata),
             "#{inspect(entry.name)} metadata keys #{inspect(Map.keys(metadata))} " <>
               "do not match registry #{inspect(entry.metadata)}"
    end
  end

  describe "static scan" do
    @lib_glob "lib/**/*.ex"
    @mix_glob "lib/mix/**/*.ex"
    @telemetry_file "lib/threadline/telemetry.ex"

    defp lib_files, do: @lib_glob |> Path.wildcard() |> Enum.sort()
    defp mix_files, do: @mix_glob |> Path.wildcard() |> Enum.sort()

    test "the lib scan set is non-empty" do
      assert lib_files() != [],
             "no files matched #{@lib_glob}: the glob is broken, and a broken glob would " <>
               "let the execute/span scan pass vacuously"
    end

    test ":telemetry.execute/:telemetry.span appear only in lib/threadline/telemetry.ex" do
      offenders =
        lib_files()
        |> Enum.reject(&(&1 == @telemetry_file))
        |> Enum.filter(fn path ->
          src = File.read!(path)
          String.contains?(src, ":telemetry.execute(") or String.contains?(src, ":telemetry.span(")
        end)

      assert offenders == [],
             "found :telemetry.execute(/:telemetry.span( outside #{@telemetry_file}: #{inspect(offenders)}"
    end

    test "no registry event name contains :query" do
      refute Enum.any?(Threadline.Telemetry.__events__(), fn entry ->
               :query in entry.name
             end)
    end

    test "no Mix task references Threadline.Telemetry" do
      offenders =
        mix_files()
        |> Enum.filter(&String.contains?(File.read!(&1), "Threadline.Telemetry"))

      assert offenders == [],
             "found Threadline.Telemetry referenced from a Mix task: #{inspect(offenders)}"
    end
  end
end
