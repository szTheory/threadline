defmodule Threadline.DbPropertyHarnessTest do
  @moduledoc """
  End-to-end self-test for `Threadline.Test.DbProperty` against a real
  trigger-captured table (D-01, D-02). This filename deliberately does not
  end in `_property_test.exs` so the scale contract's glob ignores it —
  it exercises the harness itself, not a property that uses it.
  """

  use Threadline.DataCase

  import Threadline.Test.DbProperty

  alias Threadline.Capture.TriggerSQL
  alias Threadline.StorageSchema

  @table "dbp_harness_rows"

  setup_all do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS #{@table} (
      id uuid PRIMARY KEY,
      v  text
    )
    """)

    Repo.query!(TriggerSQL.install_function([]))
    Repo.query!(TriggerSQL.create_trigger(@table))

    on_exit(fn ->
      Repo.query!(TriggerSQL.drop_trigger(@table))
      Repo.query!("DROP TABLE IF EXISTS #{@table}")
    end)

    :ok
  end

  # `ordered_id/2` returns the human-readable uuid string (per
  # `Ecto.UUID.load!/1`'s contract), matching what the trigger stores as
  # `table_pk->>'id'`. A raw SQL parameter bound to an actual `uuid`-typed
  # column goes through the Postgrex binary protocol, which expects the raw
  # 16-byte form instead, so inserts/updates of the host row dump it back.
  defp uuid_param(id_string), do: Ecto.UUID.dump!(id_string)

  test "a real row is captured and cleaned per iteration in FK order" do
    id =
      with_iteration(
        fn n -> delete_iteration!(@table, [ordered_id(1, n)]) end,
        fn n ->
          id = ordered_id(1, n)

          Repo.query!("INSERT INTO #{@table} (id, v) VALUES ($1, $2)", [uuid_param(id), "a"])
          Repo.query!("UPDATE #{@table} SET v = $2 WHERE id = $1", [uuid_param(id), "b"])

          audit_changes = StorageSchema.table("audit_changes")

          %{rows: rows} =
            Repo.query!(
              "SELECT op FROM #{audit_changes} WHERE table_name = $1 AND table_pk->>'id' = $2",
              [@table, id]
            )

          assert length(rows) == 2, "expected the insert and the update to both be captured"

          id
        end
      )

    assert assert_audit_tables_empty!() == :ok

    %{rows: host_rows} = Repo.query!("SELECT 1 FROM #{@table} WHERE id = $1", [uuid_param(id)])
    assert host_rows == [], "the host row must be gone after with_iteration's cleanup"
  end

  test "a body that fails an assertion still runs cleanup" do
    test_pid = self()

    assert_raise ExUnit.AssertionError, fn ->
      with_iteration(
        fn n -> delete_iteration!(@table, [ordered_id(1, n)]) end,
        fn n ->
          id = ordered_id(1, n)
          send(test_pid, {:iteration_id, id})
          Repo.query!("INSERT INTO #{@table} (id, v) VALUES ($1, $2)", [uuid_param(id), "a"])
          assert 1 == 2, "forced failure"
        end
      )
    end

    assert_receive {:iteration_id, id}
    %{rows: host_rows} = Repo.query!("SELECT 1 FROM #{@table} WHERE id = $1", [uuid_param(id)])
    assert host_rows == [], "cleanup must run even though the body raised"
  end

  test "a cleanup that raises warns and the body's own error propagates" do
    warning =
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        assert_raise ExUnit.AssertionError, ~r/forced body failure/, fn ->
          with_iteration(
            fn _n -> raise "cleanup boom" end,
            fn _n -> flunk("forced body failure") end
          )
        end
      end)

    assert warning =~ "cleanup boom"
  end

  test "assert_audit_tables_empty! flunks with the exact message when a transaction row exists" do
    audit_transactions = StorageSchema.table("audit_transactions")
    txid = iteration_key()

    %{rows: [[id]]} =
      Repo.query!(
        "INSERT INTO #{audit_transactions} (txid) VALUES ($1) RETURNING id::text",
        [txid]
      )

    assert_raise ExUnit.AssertionError,
                 ~r/foreign rows present; global purge oracle unsound/,
                 fn ->
                   assert_audit_tables_empty!()
                 end

    delete_transactions!([id])
    assert assert_audit_tables_empty!() == :ok
  end

  test "ordered_id/2 orders two generated uuids by rank" do
    n = iteration_key()
    low = ordered_id(1, n)
    high = ordered_id(2, n)

    %{rows: [[less?]]} =
      Repo.query!("SELECT $1::uuid < $2::uuid", [uuid_param(low), uuid_param(high)])

    assert less?
  end

  test "delete_iteration! rejects an invalid host_table name" do
    assert_raise ArgumentError, fn -> delete_iteration!("bad name;", []) end
  end
end
