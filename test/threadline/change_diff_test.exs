defmodule Threadline.ChangeDiffTest do
  use ExUnit.Case, async: true

  alias Threadline
  alias Threadline.Capture.AuditChange
  alias Threadline.ChangeDiff

  @tx_id Ecto.UUID.generate()
  @chg_id Ecto.UUID.generate()

  defp base_attrs do
    %{
      id: @chg_id,
      transaction_id: @tx_id,
      table_schema: "public",
      table_name: "widgets",
      table_pk: %{"id" => "row-1"},
      captured_at: ~U[2026-04-24 12:00:00.000000Z]
    }
  end

  describe "from_audit_change/2 primary format" do
    test "INSERT encodes with Jason and default field_changes is empty" do
      ch =
        struct(
          AuditChange,
          Map.merge(base_attrs(), %{
            op: "INSERT",
            data_after: %{"name" => "n1", "sort" => 2},
            changed_fields: nil,
            changed_from: nil
          })
        )

      map = ChangeDiff.from_audit_change(ch, [])
      assert map["before_values"] == "none"
      assert map["field_changes"] == []
      assert Jason.encode!(map)
    end

    test "INSERT expand_insert_fields derives sorted set rows from data_after" do
      ch =
        struct(
          AuditChange,
          Map.merge(base_attrs(), %{
            op: "INSERT",
            data_after: %{"z" => 1, "a" => 2},
            changed_fields: nil,
            changed_from: nil
          })
        )

      map = ChangeDiff.from_audit_change(ch, expand_insert_fields: true)
      names = Enum.map(map["field_changes"], & &1["name"])
      assert names == Enum.sort(names)
      assert names == ["a", "z"]
      assert Enum.all?(map["field_changes"], &(&1["kind"] == "set"))
      assert Jason.encode!(map)
    end

    test "UPDATE with changed_from nil omits before on fields and encodes" do
      ch =
        struct(
          AuditChange,
          Map.merge(base_attrs(), %{
            op: "UPDATE",
            data_after: %{"a" => 1, "b" => 2},
            changed_fields: ["b", "a"],
            changed_from: nil
          })
        )

      map = ChangeDiff.from_audit_change(ch, [])
      assert map["before_values"] == "none"

      by_name = Map.new(map["field_changes"], &{&1["name"], &1})
      refute Map.has_key?(by_name["a"], "before")
      refute Map.has_key?(by_name["a"], "prior_state")
      refute Map.has_key?(by_name["b"], "before")
      assert Jason.encode!(map)
    end

    test "UPDATE sparse changed_from missing column uses prior_state omitted" do
      ch =
        struct(
          AuditChange,
          Map.merge(base_attrs(), %{
            op: "UPDATE",
            data_after: %{"email" => "x@y", "name" => "Ada"},
            changed_fields: ["email", "name"],
            changed_from: %{"email" => "old@y"}
          })
        )

      map = ChangeDiff.from_audit_change(ch, [])
      assert map["before_values"] == "sparse"

      by_name = Map.new(map["field_changes"], &{&1["name"], &1})
      assert by_name["email"]["before"] == "old@y"
      assert by_name["name"]["prior_state"] == "omitted"
      refute Map.has_key?(by_name["name"], "before")
      assert Jason.encode!(map)
    end

    test "UPDATE field order is lexicographic by name" do
      ch =
        struct(
          AuditChange,
          Map.merge(base_attrs(), %{
            op: "UPDATE",
            data_after: %{"m" => 1, "z" => 2, "a" => 3},
            changed_fields: ["z", "m", "a"],
            changed_from: nil
          })
        )

      map = ChangeDiff.from_audit_change(ch, [])
      assert Enum.map(map["field_changes"], & &1["name"]) == ["a", "m", "z"]
    end

    test "mask placeholder :mask passes through and encodes" do
      ch =
        struct(
          AuditChange,
          Map.merge(base_attrs(), %{
            op: "UPDATE",
            data_after: %{"secret" => :mask},
            changed_fields: ["secret"],
            changed_from: nil
          })
        )

      map = ChangeDiff.from_audit_change(ch, [])
      json = Jason.encode!(map)
      assert json =~ "mask"
      assert Jason.decode!(json)["field_changes"] |> hd() |> Map.fetch!("after") == "mask"
    end

    test "DELETE encodes with empty field_changes and nil data_after" do
      ch =
        struct(
          AuditChange,
          Map.merge(base_attrs(), %{
            op: "DELETE",
            data_after: nil,
            changed_fields: nil,
            changed_from: nil
          })
        )

      map = ChangeDiff.from_audit_change(ch, [])
      assert map["data_after"] == nil
      assert map["field_changes"] == []
      assert Jason.encode!(map)
    end

    test "unsupported op raises ArgumentError mentioning unsupported op" do
      ch =
        struct(
          AuditChange,
          Map.merge(base_attrs(), %{
            op: "MERGE",
            data_after: %{},
            changed_fields: [],
            changed_from: nil
          })
        )

      assert_raise ArgumentError, ~r/unsupported op/i, fn ->
        ChangeDiff.from_audit_change(ch, [])
      end
    end
  end

  describe "from_audit_change/2 :export_compat" do
    test "flat string keys align with export base and Jason encodes" do
      ch =
        struct(
          AuditChange,
          Map.merge(base_attrs(), %{
            op: "UPDATE",
            data_after: %{"x" => 1},
            changed_fields: ["x"],
            changed_from: %{"x" => 0}
          })
        )

      map = ChangeDiff.from_audit_change(ch, format: :export_compat)

      for k <-
            ~w(op data_after changed_fields changed_from id transaction_id table_schema table_name captured_at table_pk) do
        assert Map.has_key?(map, k)
        assert is_binary(k)
      end

      assert map["id"] == to_string(@chg_id)
      assert map["transaction_id"] == to_string(@tx_id)
      assert map["changed_fields"] == ["x"]
      assert map["changed_from"] == %{"x" => 0}
      assert Jason.encode!(map)
    end
  end

  describe "Threadline.change_diff/2 delegator" do
    test "matches ChangeDiff.from_audit_change/2" do
      ch =
        struct(
          AuditChange,
          Map.merge(base_attrs(), %{
            op: "INSERT",
            data_after: %{"x" => 1},
            changed_fields: nil,
            changed_from: nil
          })
        )

      assert Threadline.change_diff(ch) == ChangeDiff.from_audit_change(ch)
    end
  end
end
