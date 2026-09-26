defmodule Threadline.Query.RowKeyValidationTest do
  @moduledoc """
  DB-free validation matrix for `Threadline.Query.RowKey.resolve!/1` and
  `normalize!/2` (D-03 message shapes): every bad key shape raises
  `ArgumentError` before any query would run. No Repo, no fixture tables —
  `resolve!/1` and `normalize!/2` never touch the database, so this file
  runs concurrently with the rest of the suite.
  """

  use ExUnit.Case, async: true

  alias Threadline.Query.RowKey

  defmodule RkLineItemV do
    use Ecto.Schema

    @primary_key false
    schema "rk_line_items_v" do
      field(:tenant_id, :integer, primary_key: true)
      field(:id, :integer, primary_key: true)
    end
  end

  defmodule RkSingleFieldV do
    use Ecto.Schema

    schema "rk_single_field_v" do
      field(:name, :string)
    end
  end

  defmodule RkNoKeyV do
    use Ecto.Schema

    @primary_key false
    schema "rk_no_key_v" do
      field(:name, :string)
    end
  end

  describe "composite key validation (D-03)" do
    setup do
      %{resolved: RowKey.resolve!(RkLineItemV)}
    end

    test "a missing key names the expected fields and what was given", %{resolved: resolved} do
      error = assert_raise(ArgumentError, fn -> RowKey.normalize!(resolved, id: 5) end)

      assert Exception.message(error) ==
               "expected keys [:tenant_id, :id] for #{inspect(RkLineItemV)}, got [:id]"
    end

    test "an extra key is listed in the got list", %{resolved: resolved} do
      error =
        assert_raise(ArgumentError, fn ->
          RowKey.normalize!(resolved, tenant_id: 1, id: 5, extra: 1)
        end)

      message = Exception.message(error)
      assert message =~ "expected keys [:tenant_id, :id]"
      assert message =~ inspect([:tenant_id, :id, :extra])
    end

    test "a misnamed string key is shown verbatim, not silently dropped", %{resolved: resolved} do
      error =
        assert_raise(ArgumentError, fn ->
          RowKey.normalize!(resolved, %{"tenant" => 1, "id" => 5})
        end)

      message = Exception.message(error)
      assert message =~ "expected keys [:tenant_id, :id]"
      assert message =~ ~s("tenant")
      assert message =~ ":id"
    end

    test "a scalar for a composite table requires a map or keyword list with every key field",
         %{resolved: resolved} do
      error = assert_raise(ArgumentError, fn -> RowKey.normalize!(resolved, 5) end)

      assert Exception.message(error) ==
               "expected keys [:tenant_id, :id] for #{inspect(RkLineItemV)}, got a single " <>
                 "value; pass a map or keyword list with every key field"
    end

    test "an empty keyword list raises with the expected-keys text and got []",
         %{resolved: resolved} do
      error = assert_raise(ArgumentError, fn -> RowKey.normalize!(resolved, []) end)

      assert Exception.message(error) ==
               "expected keys [:tenant_id, :id] for #{inspect(RkLineItemV)}, got []"
    end

    test "an empty map raises with the expected-keys text and got []", %{resolved: resolved} do
      error = assert_raise(ArgumentError, fn -> RowKey.normalize!(resolved, %{}) end)

      assert Exception.message(error) ==
               "expected keys [:tenant_id, :id] for #{inspect(RkLineItemV)}, got []"
    end

    test "a nil value for one field names that field and nil", %{resolved: resolved} do
      error =
        assert_raise(ArgumentError, fn ->
          RowKey.normalize!(resolved, tenant_id: 1, id: nil)
        end)

      assert Exception.message(error) ==
               "expected a value for key field :id of #{inspect(RkLineItemV)}, got nil"
    end

    test "a loaded struct is rejected outright", %{resolved: resolved} do
      error =
        assert_raise(ArgumentError, fn ->
          RowKey.normalize!(resolved, %RkLineItemV{tenant_id: 1, id: 5})
        end)

      message = Exception.message(error)
      assert message =~ "struct is not accepted as a row key"
      assert message =~ inspect(RkLineItemV)
    end

    test "a string key that names no field raises, and the atom table stays untouched",
         %{resolved: resolved} do
      key = "zzz_row_key_never_an_atom_211"

      assert_raise(ArgumentError, fn ->
        RowKey.normalize!(resolved, %{key => 1, "id" => 5})
      end)

      assert_raise(ArgumentError, fn -> String.to_existing_atom(key) end)
    end

    test "the resolved key set is caller-order independent", %{resolved: resolved} do
      assert RowKey.normalize!(resolved, id: 5, tenant_id: 1) ==
               RowKey.normalize!(resolved, tenant_id: 1, id: 5)
    end

    test "the same field given as both an atom and its string form raises (CR-01)", %{
      resolved: resolved
    } do
      error =
        assert_raise(ArgumentError, fn ->
          RowKey.normalize!(resolved, %{"tenant_id" => 99, tenant_id: 1, id: 5})
        end)

      message = Exception.message(error)
      assert message =~ "expected keys [:tenant_id, :id]"
      assert message =~ ":tenant_id"
      assert message =~ ~s("tenant_id")
      assert message =~ ":id"
    end

    test "a duplicated keyword-list key raises instead of last-value-wins (IN-01)", %{
      resolved: resolved
    } do
      error =
        assert_raise(ArgumentError, fn ->
          RowKey.normalize!(resolved, tenant_id: 1, tenant_id: 2, id: 5)
        end)

      assert Exception.message(error) ==
               "expected keys [:tenant_id, :id] for #{inspect(RkLineItemV)}, " <>
                 "got #{inspect([:tenant_id, :tenant_id, :id])}"
    end
  end

  describe "a schema with no primary key and no override" do
    test "raises naming the schema and primary_key: in config/config.exs" do
      error = assert_raise(ArgumentError, fn -> RowKey.resolve!(RkNoKeyV) end)

      message = Exception.message(error)
      assert message =~ inspect(RkNoKeyV)
      assert message =~ "primary_key:"
      assert message =~ "config/config.exs"
    end
  end

  describe "single-column tables keep accepting a bare scalar" do
    test "a scalar, map, or keyword-list id all validate to the same triple" do
      resolved = RowKey.resolve!(RkSingleFieldV)

      assert RowKey.normalize!(resolved, 5) == [{:id, "id", 5}]
      assert RowKey.normalize!(resolved, id: 5) == [{:id, "id", 5}]
      assert RowKey.normalize!(resolved, %{id: 5}) == [{:id, "id", 5}]
      assert RowKey.normalize!(resolved, %{"id" => 5}) == [{:id, "id", 5}]
    end

    test "nil raises before any query would run" do
      resolved = RowKey.resolve!(RkSingleFieldV)

      assert_raise(ArgumentError, ~r/got nil/, fn -> RowKey.normalize!(resolved, nil) end)
    end
  end

  describe "struct scalar values for single-column tables (WR-02)" do
    test "legitimate scalar-value structs are still accepted as a bare id" do
      resolved = RowKey.resolve!(RkSingleFieldV)

      assert RowKey.normalize!(resolved, ~D[2026-09-25]) == [{:id, "id", ~D[2026-09-25]}]

      assert RowKey.normalize!(resolved, ~N[2026-09-25 12:00:00]) ==
               [{:id, "id", ~N[2026-09-25 12:00:00]}]

      assert RowKey.normalize!(resolved, ~U[2026-09-25 12:00:00Z]) ==
               [{:id, "id", ~U[2026-09-25 12:00:00Z]}]

      assert RowKey.normalize!(resolved, ~T[12:00:00]) == [{:id, "id", ~T[12:00:00]}]
      assert RowKey.normalize!(resolved, Decimal.new("7")) == [{:id, "id", Decimal.new("7")}]
    end

    test "an unrelated struct raises the purpose-built message, not a generic cast failure" do
      resolved = RowKey.resolve!(RkSingleFieldV)

      error =
        assert_raise(ArgumentError, fn ->
          RowKey.normalize!(resolved, %RkLineItemV{tenant_id: 1, id: 5})
        end)

      message = Exception.message(error)
      assert message =~ "struct is not accepted as a row key"
      assert message =~ inspect(RkSingleFieldV)
    end
  end
end
