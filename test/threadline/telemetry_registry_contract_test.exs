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

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Export
  alias Threadline.Governance.RetentionRun
  alias Threadline.OperatorSurface.Auth
  alias Threadline.OperatorSurface.Coverage.OnMount, as: CoverageOnMount
  alias Threadline.OperatorSurface.ThemeAuthPlug
  alias Threadline.Retention
  alias Threadline.Semantics.ActorRef

  @repo Threadline.Test.Repo

  defmodule FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

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
    drive_export_completed!()
    drive_export_failed!()
    drive_retention_purge!()
    drive_row_history_truncated!()
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

  defp drive_export_completed! do
    tname = "registry_contract_export_#{System.unique_integer([:positive])}"

    txn =
      @repo.insert!(
        AuditTransaction.changeset(%{
          txid: System.unique_integer([:positive]),
          occurred_at: DateTime.utc_now()
        }),
        repo_opts()
      )

    @repo.insert!(
      AuditChange.changeset(%{
        table_schema: "public",
        table_name: tname,
        table_pk: %{"id" => "1"},
        op: "insert",
        data_after: %{"x" => 1},
        changed_fields: ["x"],
        captured_at: DateTime.utc_now(),
        transaction_id: txn.id
      }),
      repo_opts()
    )

    Export.to_csv_iodata([repo: @repo, table: tname], [])
  end

  defp drive_export_failed! do
    assert_raise ArgumentError, fn ->
      Export.to_csv_iodata([repo: @repo, not_a_real_filter: true], [])
    end
  end

  defp drive_retention_purge! do
    prev = Application.get_env(:threadline, :retention)

    ExUnit.Callbacks.on_exit(fn ->
      Application.put_env(:threadline, :retention, prev)
    end)

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: false
    )

    cutoff = ~U[2000-01-01 00:00:00.000000Z]

    # start, one empty batch_purged, stop
    Retention.purge(repo: @repo, cutoff: cutoff)

    missing = "threadline_missing_registry_#{System.unique_integer([:positive])}"

    # start, exception
    assert_raise Postgrex.Error, fn ->
      Retention.purge(repo: @repo, storage_schema: missing, cutoff: cutoff)
    end

    @repo.delete_all(RetentionRun, repo_opts())
  end

  defp drive_row_history_truncated! do
    txn =
      @repo.insert!(
        AuditTransaction.changeset(%{
          txid: System.unique_integer([:positive]),
          occurred_at: DateTime.utc_now()
        }),
        repo_opts()
      )

    for i <- 1..201 do
      @repo.insert!(
        AuditChange.changeset(%{
          table_schema: "public",
          table_name: "users",
          table_pk: %{"id" => "telemetry-row-history"},
          op: "insert",
          data_after: %{"name" => "Alice"},
          changed_fields: ["name"],
          captured_at: DateTime.add(~U[2026-01-01 00:00:00.000000Z], i, :microsecond),
          transaction_id: txn.id
        }),
        repo_opts()
      )
    end

    Threadline.row_history(FakeUser, "telemetry-row-history", repo: @repo)
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

      assert_measurement_value_types!(entry, measurements)
      assert_metadata_value_types!(entry, metadata)
    end
  end

  # Every measurement value must be an integer or an atom — never a binary,
  # map, or struct (a free-text or identity-carrying leak).
  defp assert_measurement_value_types!(entry, measurements) do
    for {key, value} <- measurements do
      assert is_integer(value) or is_atom(value),
             "#{inspect(entry.name)} measurement #{inspect(key)} => #{inspect(value)} " <>
               "is neither an integer nor an atom"
    end
  end

  # Every metadata value outside an entry's `exempt_metadata` (span-internal
  # kind/reason/stacktrace) and the automatic `telemetry_span_context` must be
  # an atom, boolean, integer, nil, reference, or a list of atoms — the single
  # allowed exception is `:path` on `[:threadline, :operator_surface,
  # :authorize]`, which is a fixed mount route-template string (the macro's
  # own compile-time path argument, never a live request path). Anything else
  # is a free-text or identity leak this contract exists to catch.
  defp assert_metadata_value_types!(entry, metadata) do
    exempt = Map.get(entry, :exempt_metadata, [])

    for {key, value} <- metadata do
      cond do
        key in exempt ->
          :ok

        key == :telemetry_span_context ->
          :ok

        entry.name == [:threadline, :operator_surface, :authorize] and key == :path ->
          assert is_binary(value)

        true ->
          assert allowed_metadata_value?(value),
                 "#{inspect(entry.name)} metadata #{inspect(key)} => #{inspect(value)} " <>
                   "is not an allowed value type (atom, boolean, integer, nil, reference, " <>
                   "or list of atoms)"
      end
    end
  end

  defp allowed_metadata_value?(value) when is_atom(value), do: true
  defp allowed_metadata_value?(value) when is_integer(value), do: true
  defp allowed_metadata_value?(value) when is_reference(value), do: true
  defp allowed_metadata_value?(nil), do: true

  defp allowed_metadata_value?(value) when is_list(value),
    do: Enum.all?(value, &is_atom/1)

  defp allowed_metadata_value?(_value), do: false

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

          String.contains?(src, ":telemetry.execute(") or
            String.contains?(src, ":telemetry.span(")
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
