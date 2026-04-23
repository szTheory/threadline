defmodule Threadline.Capture.TriggerTest do
  use Threadline.DataCase

  import Ecto.Query

  setup_all do
    # Create a temporary audited table for trigger testing
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS test_audit_target (
      id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      name  text NOT NULL,
      value integer
    )
    """)

    # Install trigger on test_audit_target
    Repo.query!(Threadline.Capture.TriggerSQL.create_trigger("test_audit_target"))

    on_exit(fn ->
      Repo.query!(Threadline.Capture.TriggerSQL.drop_trigger("test_audit_target"))
      Repo.query!("DROP TABLE IF EXISTS test_audit_target")
    end)

    :ok
  end

  setup do
    Repo.query!("DELETE FROM test_audit_target")
    :ok
  end

  test "INSERT produces an AuditChange row with op=insert and correct data_after" do
    Repo.query!("INSERT INTO test_audit_target (name, value) VALUES ('alice', 1)")

    changes = Repo.all(AuditChange)
    assert length(changes) == 1

    change = hd(changes)
    assert change.op == "insert"
    assert change.table_name == "test_audit_target"
    assert change.data_after["name"] == "alice"
    assert change.data_after["value"] == 1
    assert change.table_pk["id"] != nil

    # An AuditTransaction row must exist
    txns = Repo.all(AuditTransaction)
    assert length(txns) == 1
  end

  test "UPDATE produces an AuditChange row with op=update and changed_fields" do
    %{rows: [[row_id]]} =
      Repo.query!("INSERT INTO test_audit_target (name, value) VALUES ('bob', 10) RETURNING id")

    # Clean insert change before testing update
    Repo.delete_all(AuditChange)
    Repo.delete_all(AuditTransaction)

    Repo.query!("UPDATE test_audit_target SET value = 20 WHERE id = $1", [row_id])

    changes = Repo.all(AuditChange)
    assert length(changes) == 1

    change = hd(changes)
    assert change.op == "update"
    assert change.data_after["value"] == 20
    assert "value" in change.changed_fields
    refute "name" in change.changed_fields
  end

  test "DELETE produces an AuditChange row with op=delete and null data_after" do
    %{rows: [[row_id]]} =
      Repo.query!(
        "INSERT INTO test_audit_target (name, value) VALUES ('charlie', 99) RETURNING id"
      )

    Repo.delete_all(AuditChange)
    Repo.delete_all(AuditTransaction)

    Repo.query!("DELETE FROM test_audit_target WHERE id = $1", [row_id])

    changes = Repo.all(AuditChange)
    assert length(changes) == 1

    change = hd(changes)
    assert change.op == "delete"
    assert change.data_after == nil
    assert change.table_pk["id"] != nil
  end

  test "multiple writes in one transaction share an AuditTransaction" do
    Repo.transaction(fn ->
      Repo.query!("INSERT INTO test_audit_target (name) VALUES ('first')")
      Repo.query!("INSERT INTO test_audit_target (name) VALUES ('second')")
    end)

    changes = Repo.all(AuditChange)
    assert length(changes) == 2

    [tx_id1, tx_id2] = Enum.map(changes, & &1.transaction_id)
    assert tx_id1 == tx_id2, "Both AuditChange rows must share the same AuditTransaction"

    txns = Repo.all(AuditTransaction)
    assert length(txns) == 1
  end

  test "audit trigger is not installed on audit_transactions (no recursive loop)" do
    # Inserting into audit_transactions should not create audit_changes rows
    initial_count = Repo.aggregate(AuditChange, :count)

    Repo.query!("""
    INSERT INTO audit_transactions (id, txid, occurred_at)
    VALUES (gen_random_uuid(), txid_current() + 9999999, now())
    """)

    final_count = Repo.aggregate(AuditChange, :count)

    assert final_count == initial_count,
           "No audit_changes row should be created from audit_transactions insert"
  end
end
