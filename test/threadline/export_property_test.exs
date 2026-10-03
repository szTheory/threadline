defmodule Threadline.ExportPropertyTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Threadline.Test.ExportHostileValueGenerators

  alias Threadline.ChangeDiff
  alias Threadline.Export
  alias Threadline.Semantics.ActorRef
  alias Threadline.Test.PropertyRuns
  alias Threadline.Test.StrictRFC4180

  @csv_columns ~w(id transaction_id table_schema table_name op captured_at
                  table_pk data_after changed_fields changed_from transaction_json)
  @csv_meta_columns @csv_columns ++ ~w(correlation_id action_id)

  describe "csv_header/1 (asserted once, not per property run)" do
    test "default header matches the documented column order" do
      [header] =
        Export.csv_header([])
        |> IO.iodata_to_binary()
        |> StrictRFC4180.decode!()

      assert header == @csv_columns
    end

    test "include_action_metadata header appends correlation_id and action_id" do
      [header] =
        Export.csv_header(include_action_metadata: true)
        |> IO.iodata_to_binary()
        |> StrictRFC4180.decode!()

      assert header == @csv_meta_columns
    end
  end

  describe "PROP-05: CSV round-trip" do
    property "every generated row round-trips through the independent strict decoder" do
      check all(
              {_fact, _audit_change, row} <- export_row_gen(),
              include_meta <- boolean(),
              max_runs: PropertyRuns.pure(150)
            ) do
        header_iodata = Export.csv_header(include_action_metadata: include_meta)

        body_iodata =
          Export.format_changes_iodata([row], :csv, include_action_metadata: include_meta)

        full = IO.iodata_to_binary([header_iodata, body_iodata])

        [_header, data_record] = StrictRFC4180.decode!(full)

        [
          id_cell,
          tx_id_cell,
          schema_cell,
          name_cell,
          op_cell,
          captured_cell,
          pk_cell,
          data_after_cell,
          changed_fields_cell,
          changed_from_cell,
          tx_json_cell
          | meta_cells
        ] = data_record

        assert id_cell === to_string(row.id), "id must round-trip unchanged"

        assert tx_id_cell === to_string(row.transaction_id),
               "transaction_id must round-trip unchanged"

        assert schema_cell === row.table_schema, "table_schema must round-trip unchanged"
        assert name_cell === row.table_name, "table_name must round-trip unchanged"
        assert op_cell === row.op, "op must round-trip unchanged"

        assert_datetime!(captured_cell, row.captured_at)

        defaults = export_defaults(row)

        assert Jason.decode!(pk_cell) === defaults.table_pk
        assert Jason.decode!(data_after_cell) === defaults.csv_data_after
        assert Jason.decode!(changed_fields_cell) === defaults.changed_fields
        assert Jason.decode!(changed_from_cell) === defaults.changed_from

        tx_decoded = Jason.decode!(tx_json_cell)
        {tx_occurred_cell, tx_rest} = Map.pop(tx_decoded, "occurred_at")
        assert_datetime!(tx_occurred_cell, row.tx_occurred_at)

        assert tx_rest ===
                 %{
                   "id" => to_string(row.transaction_id),
                   "actor_ref" => expected_actor_json(row.tx_actor_ref),
                   "source" => row.tx_source
                 }

        if include_meta do
          [cid_cell, aid_cell] = meta_cells
          assert cid_cell === defaults.correlation_id
          assert aid_cell === defaults.action_id
        else
          assert meta_cells == []
        end
      end
    end

    property "a leading =, +, -, or @ value round-trips unchanged (no formula escaping added)" do
      check all(
              {_fact, _audit_change, row} <- export_row_gen(),
              prefix <- member_of(~w(= + - @)),
              max_runs: PropertyRuns.pure(150)
            ) do
        hostile_row = %{row | table_name: prefix <> "SUM(A1)"}

        full =
          IO.iodata_to_binary([
            Export.csv_header([]),
            Export.format_changes_iodata([hostile_row], :csv, [])
          ])

        [_header, data_record] = StrictRFC4180.decode!(full)
        assert Enum.at(data_record, 3) === prefix <> "SUM(A1)"
      end
    end
  end

  describe "PROP-05: JSON round-trip" do
    property ":json_wrapped round-trips every generated row" do
      check all({_fact, _audit_change, row} <- export_row_gen(), max_runs: PropertyRuns.pure(150)) do
        [encoded] = Export.format_changes_iodata([row], :json_wrapped, [])
        decoded = Jason.decode!(encoded)
        assert_row_matches_json!(decoded, row)
      end
    end

    property ":ndjson round-trips every generated row, one line per row" do
      check all({_fact, _audit_change, row} <- export_row_gen(), max_runs: PropertyRuns.pure(150)) do
        [line] = Export.format_changes_iodata([row], :ndjson, [])

        assert String.ends_with?(line, "\n")

        newline_count = line |> String.graphemes() |> Enum.count(&(&1 == "\n"))
        assert newline_count == 1, "ndjson line must end with exactly one newline"

        decoded = line |> String.trim_trailing("\n") |> Jason.decode!()
        assert_row_matches_json!(decoded, row)
      end
    end
  end

  describe "PROP-05: D-19 export_defaults are pinned, not changed" do
    test "nil changed_from becomes {} in both CSV and JSON" do
      row = fixed_row(changed_from: nil)
      assert export_defaults(row).changed_from == %{}

      [json_encoded] = Export.format_changes_iodata([row], :json_wrapped, [])
      assert Jason.decode!(json_encoded)["changed_from"] == %{}

      csv_full =
        IO.iodata_to_binary([
          Export.csv_header([]),
          Export.format_changes_iodata([row], :csv, [])
        ])

      [_header, data_record] = StrictRFC4180.decode!(csv_full)
      assert Jason.decode!(Enum.at(data_record, 9)) == %{}
    end

    test "nil data_after becomes \"{}\" in CSV but stays JSON null" do
      row = fixed_row(data_after: nil, op: "delete")
      defaults = export_defaults(row)
      assert defaults.csv_data_after == %{}
      assert defaults.json_data_after == nil

      [json_encoded] = Export.format_changes_iodata([row], :json_wrapped, [])
      assert Jason.decode!(json_encoded)["data_after"] == nil

      csv_full =
        IO.iodata_to_binary([
          Export.csv_header([]),
          Export.format_changes_iodata([row], :csv, [])
        ])

      [_header, data_record] = StrictRFC4180.decode!(csv_full)
      assert Jason.decode!(Enum.at(data_record, 7)) == %{}
    end

    test "nil correlation id and nil action id become \"\" with include_action_metadata: true" do
      row = fixed_row(aa_id: Ecto.UUID.generate(), aa_correlation_id: nil)
      defaults = export_defaults(row)
      assert defaults.correlation_id == ""

      csv_full =
        IO.iodata_to_binary([
          Export.csv_header(include_action_metadata: true),
          Export.format_changes_iodata([row], :csv, include_action_metadata: true)
        ])

      [_header, data_record] = StrictRFC4180.decode!(csv_full)
      assert Enum.at(data_record, -2) == ""
    end

    test "a row with no linked action at all gives \"\" for both correlation id and action id" do
      row = fixed_row(aa_id: nil, aa_correlation_id: nil)
      defaults = export_defaults(row)
      assert defaults.correlation_id == ""
      assert defaults.action_id == ""

      [json_encoded] = Export.format_changes_iodata([row], :json_wrapped, [])
      refute Map.has_key?(Jason.decode!(json_encoded), "action")
    end
  end

  describe "PROP-05: cross-format agreement with ChangeDiff" do
    property "json_wrapped's base fields agree with ChangeDiff.from_audit_change/2 :export_compat" do
      check all({_fact, audit_change, row} <- export_row_gen(), max_runs: PropertyRuns.pure(150)) do
        [encoded] = Export.format_changes_iodata([row], :json_wrapped, [])
        decoded = Jason.decode!(encoded)
        base_decoded = Map.drop(decoded, ["transaction", "action"])

        change_diff_decoded =
          audit_change
          |> ChangeDiff.from_audit_change(format: :export_compat)
          |> Jason.encode!()
          |> Jason.decode!()

        {export_captured, export_rest} = Map.pop(base_decoded, "captured_at")
        {cd_captured, cd_rest} = Map.pop(change_diff_decoded, "captured_at")

        assert_datetime!(export_captured, audit_change.captured_at)
        assert_datetime!(cd_captured, audit_change.captured_at)

        assert export_rest === cd_rest
      end
    end
  end

  ## -- shared helpers --------------------------------------------------

  defp fixed_row(overrides) do
    %{
      id: Ecto.UUID.generate(),
      transaction_id: Ecto.UUID.generate(),
      table_schema: "public",
      table_name: "users",
      op: "insert",
      captured_at: ~U[2026-06-01 00:00:00.000000Z],
      table_pk: %{"id" => "1"},
      data_after: %{"x" => 1},
      changed_fields: ["x"],
      changed_from: nil,
      tx_occurred_at: ~U[2026-06-01 00:00:00.000000Z],
      tx_actor_ref: nil,
      tx_source: nil,
      aa_id: nil,
      aa_correlation_id: nil
    }
    |> Map.merge(Map.new(overrides))
  end

  # D-19: Export's documented nil-default substitutions, modelled once so
  # every round-trip assertion (CSV and JSON) applies the exact same
  # substitution Export itself applies — these are pinned, not fixed, in
  # this phase. `data_after` is the one field whose default differs by
  # format: CSV turns a nil into the JSON object `{}`; JSON keeps `null`.
  defp export_defaults(row) do
    %{
      table_pk: normalize(row.table_pk || %{}),
      changed_fields: normalize(row.changed_fields || []),
      changed_from: normalize(row.changed_from || %{}),
      csv_data_after: normalize(row.data_after || %{}),
      json_data_after: if(row.data_after, do: normalize(row.data_after), else: nil),
      correlation_id: row.aa_correlation_id || "",
      action_id: if(row.aa_id, do: to_string(row.aa_id), else: "")
    }
  end

  # Lossless-comparison normalisation (D-16): atom keys become strings;
  # non-boolean, non-nil atom values become strings. Needed because
  # `ChangeFactGenerators`/`ExportHostileValueGenerators` sometimes render
  # a fact's map keys as atoms (`fact.keys == :atom`), which both Export
  # and `Jason.encode!/1` serialize as strings — `===` against the raw
  # Elixir term would otherwise fail on the key type alone.
  defp normalize(v) when is_atom(v) and v not in [nil, true, false], do: Atom.to_string(v)
  defp normalize(v) when is_map(v), do: v |> Enum.map(&normalize_entry/1) |> Map.new()
  defp normalize(v) when is_list(v), do: Enum.map(v, &normalize/1)
  defp normalize(v), do: v

  defp normalize_entry({k, v}), do: {normalize_key(k), normalize(v)}

  defp normalize_key(k) when is_atom(k), do: Atom.to_string(k)
  defp normalize_key(k), do: k

  defp assert_datetime!(iso_string, expected_dt) do
    assert {:ok, parsed, _offset} = DateTime.from_iso8601(iso_string)
    assert parsed === expected_dt
  end

  # Built by hand from the generated `{type, id}` actor facts — deliberately
  # not calling the serializer under test, so this oracle cannot share a
  # bug with the function it is checking.
  defp expected_actor_json(nil), do: nil
  defp expected_actor_json(%ActorRef{type: :anonymous}), do: %{"type" => "anonymous"}

  defp expected_actor_json(%ActorRef{type: type, id: id}),
    do: %{"type" => Atom.to_string(type), "id" => id}

  defp assert_row_matches_json!(decoded, row) do
    {captured_cell, rest1} = Map.pop(decoded, "captured_at")
    assert_datetime!(captured_cell, row.captured_at)

    {transaction, rest2} = Map.pop(rest1, "transaction")
    {occurred_cell, tx_rest} = Map.pop(transaction, "occurred_at")
    assert_datetime!(occurred_cell, row.tx_occurred_at)

    assert tx_rest ===
             %{
               "id" => to_string(row.transaction_id),
               "actor_ref" => expected_actor_json(row.tx_actor_ref),
               "source" => row.tx_source
             }

    {action, rest3} = Map.pop(rest2, "action")
    defaults = export_defaults(row)

    if row.aa_id do
      # Unlike CSV's `include_action_metadata` columns (which always exist
      # and so default a nil correlation id to `""`), JSON's "action"
      # object only exists when `aa_id` is present, and then forwards
      # `aa_correlation_id` unchanged — including JSON `null` when it is
      # nil. The `""` default is a CSV-only substitution (D-19).
      assert action === %{"id" => defaults.action_id, "correlation_id" => row.aa_correlation_id}
    else
      assert action == nil
    end

    assert rest3 ===
             %{
               "id" => to_string(row.id),
               "transaction_id" => to_string(row.transaction_id),
               "table_schema" => row.table_schema,
               "table_name" => row.table_name,
               "op" => row.op,
               "table_pk" => defaults.table_pk,
               "data_after" => defaults.json_data_after,
               "changed_fields" => defaults.changed_fields,
               "changed_from" => defaults.changed_from
             }
  end
end
