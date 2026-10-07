defmodule Threadline.ExportPublicContractTest do
  @moduledoc false
  use Threadline.DataCase, async: false

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Export
  alias Threadline.Health.Finding
  alias Threadline.Semantics.{ActorRef, AuditAction}

  @repo Threadline.Test.Repo
  @base_keys ~w(id transaction_id table_schema table_name op captured_at table_pk data_after changed_fields changed_from transaction)
  @transaction_keys ~w(id occurred_at actor_ref source)
  @action_keys ~w(id correlation_id)
  @csv_headers ~w(id transaction_id table_schema table_name op captured_at table_pk data_after changed_fields changed_from transaction_json)
  @finding_codes [
    :legacy_trigger_no_pk_args,
    :pk_drift,
    :shared_capture_function,
    :duplicate_capture_trigger,
    :capture_trigger_disabled,
    :unresolved_legacy_keys
  ]

  defp insert_transaction(attrs \\ %{}) do
    defaults = %{
      txid: System.unique_integer([:positive]),
      occurred_at: ~U[2026-10-01 12:00:00.000000Z]
    }

    @repo.insert!(AuditTransaction.changeset(Map.merge(defaults, attrs)), repo_opts())
  end

  defp insert_change!(transaction, name) do
    @repo.insert!(
      AuditChange.changeset(%{
        table_schema: "public",
        table_name: name,
        table_pk: %{"id" => name},
        op: "insert",
        data_after: %{"name" => name},
        changed_fields: ["name"],
        captured_at: ~U[2026-10-01 12:00:01.000000Z],
        transaction_id: transaction.id
      }),
      repo_opts()
    )
  end

  defp actual_finding_codes do
    ["lib/threadline/health/*.ex", "lib/threadline/health/**/*.ex"]
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.flat_map(fn path ->
      path
      |> File.read!()
      |> then(&Regex.scan(~r/\bcode:\s*:(\w+)/, &1, capture: :all_but_first))
      |> List.flatten()
      |> Enum.map(&String.to_atom/1)
    end)
    |> MapSet.new()
  end

  defp assert_exact_set!(actual, expected, label) do
    added = MapSet.difference(actual, expected) |> Enum.sort()
    removed = MapSet.difference(expected, actual) |> Enum.sort()

    assert added == [] and removed == [],
           "#{label} drift: added=#{inspect(added)} removed=#{inspect(removed)}"
  end

  test "CSV and JSON exports pin default and action metadata output with named rows" do
    suffix = System.unique_integer([:positive])
    plain_name = "public_contract_plain_#{suffix}"
    action_name = "public_contract_action_#{suffix}"

    plain_tx = insert_transaction()
    insert_change!(plain_tx, plain_name)

    {:ok, actor_ref} = ActorRef.new(:user, "public-contract-user")

    action =
      @repo.insert!(
        AuditAction.changeset(%AuditAction{}, %{
          name: "member.role_changed",
          actor_ref: ActorRef.to_map(actor_ref),
          status: :ok,
          correlation_id: "public-contract-correlation"
        }),
        repo_opts()
      )

    action_tx = insert_transaction(%{action_id: action.id})
    insert_change!(action_tx, action_name)

    assert {:ok, %{data: csv_default}} =
             Export.to_csv_iodata([repo: @repo, table: plain_name], [])

    [csv_header | [plain_csv_row]] =
      csv_default |> IO.iodata_to_binary() |> String.trim_trailing("\r\n") |> String.split("\r\n")

    assert parse_csv_row(csv_header) == @csv_headers
    assert parse_csv_row(plain_csv_row) |> length() == length(@csv_headers)

    assert {:ok, %{data: csv_with_meta}} =
             Export.to_csv_iodata([repo: @repo, table: action_name],
               include_action_metadata: true
             )

    [meta_header | [action_csv_row]] =
      csv_with_meta
      |> IO.iodata_to_binary()
      |> String.trim_trailing("\r\n")
      |> String.split("\r\n")

    assert parse_csv_row(meta_header) == @csv_headers ++ ~w(correlation_id action_id)
    action_cells = parse_csv_row(action_csv_row)
    assert Enum.take(action_cells, length(@csv_headers)) |> length() == length(@csv_headers)
    assert Enum.take(action_cells, -2) == ["public-contract-correlation", action.id]

    assert {:ok, %{data: json_default}} =
             Export.to_json_document([repo: @repo, table: plain_name], [])

    [plain_change] = decode_changes(json_default)

    assert_exact_set!(
      Map.keys(plain_change) |> MapSet.new(),
      MapSet.new(@base_keys),
      "default JSON keys"
    )

    refute Map.has_key?(plain_change, "action"),
           "missing action metadata must omit the JSON action object"

    assert_exact_set!(
      Map.keys(plain_change["transaction"]) |> MapSet.new(),
      MapSet.new(@transaction_keys),
      "JSON transaction keys"
    )

    assert {:ok, %{data: json_with_meta}} =
             Export.to_json_document([repo: @repo, table: action_name], [])

    [action_change] = decode_changes(json_with_meta)

    assert_exact_set!(
      Map.keys(action_change) |> MapSet.new(),
      MapSet.new(@base_keys ++ ["action"]),
      "action JSON keys"
    )

    assert_exact_set!(
      Map.keys(action_change["action"]) |> MapSet.new(),
      MapSet.new(@action_keys),
      "JSON action keys"
    )

    assert action_change["action"]["correlation_id"] == "public-contract-correlation"
    assert action_change["action"]["id"] == action.id
  end

  test "CSV and JSON export shape controls reject removed and added pins" do
    assert_raise ExUnit.AssertionError,
                 ~r/CSV header control drift: added=\[\] removed=\["transaction_json"\]/,
                 fn ->
                   assert_exact_set!(
                     MapSet.new(@csv_headers -- ["transaction_json"]),
                     MapSet.new(@csv_headers),
                     "CSV header control"
                   )
                 end

    assert_raise ExUnit.AssertionError,
                 ~r/JSON key control drift: added=\["new_key"\] removed=\[\]/,
                 fn ->
                   assert_exact_set!(
                     MapSet.new(@base_keys ++ ["new_key"]),
                     MapSet.new(@base_keys),
                     "JSON key control"
                   )
                 end
  end

  test "Health.Finding code producers match the complete literal code set" do
    assert Code.ensure_loaded?(Finding)
    assert_exact_set!(actual_finding_codes(), MapSet.new(@finding_codes), "Health.Finding codes")

    assert_raise ExUnit.AssertionError,
                 ~r/Finding code control drift: added=\[\] removed=\[:pk_drift\]/,
                 fn ->
                   assert_exact_set!(
                     MapSet.new(@finding_codes -- [:pk_drift]),
                     MapSet.new(@finding_codes),
                     "Finding code control"
                   )
                 end
  end

  defp parse_csv_row(line) do
    [row] = NimbleCSV.RFC4180.parse_string(line <> "\r\n", skip_headers: false)
    row
  end

  defp decode_changes(data) do
    data |> IO.iodata_to_binary() |> Jason.decode!() |> Map.fetch!("changes")
  end
end
