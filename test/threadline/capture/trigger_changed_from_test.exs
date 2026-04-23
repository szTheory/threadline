defmodule Threadline.Capture.TriggerChangedFromTest do
  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, TriggerSQL}

  @table "test_audit_changed_from"

  setup_all do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS #{@table} (
      id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      name  text NOT NULL,
      value integer
    )
    """)

    Repo.query!(TriggerSQL.install_function([]))

    on_exit(fn ->
      Repo.query!(TriggerSQL.drop_trigger(@table))
      Repo.query!(TriggerSQL.drop_function_for_table(@table))
      Repo.query!("DROP TABLE IF EXISTS #{@table}")
    end)

    :ok
  end

  setup do
    Repo.query!(TriggerSQL.drop_trigger(@table))
    Repo.query!(TriggerSQL.drop_function_for_table(@table))
    Repo.query!("TRUNCATE #{@table} CASCADE")
    Repo.delete_all(AuditChange)
    Repo.delete_all(Threadline.Capture.AuditTransaction)
    :ok
  end

  describe "global threadline_capture_changes()" do
    setup %{test: _} do
      Repo.query!(TriggerSQL.create_trigger(@table))
      on_exit(fn -> Repo.query!(TriggerSQL.drop_trigger(@table)) end)
      :ok
    end

    test "UPDATE leaves changed_from nil when per-table opt-in is off" do
      %{rows: [[id]]} =
        Repo.query!("INSERT INTO #{@table} (name, value) VALUES ('a', 1) RETURNING id")

      Repo.delete_all(AuditChange)
      Repo.delete_all(Threadline.Capture.AuditTransaction)

      Repo.query!("UPDATE #{@table} SET value = 2 WHERE id = $1", [id])

      [change] = Repo.all(AuditChange)
      assert change.op == "update"
      assert "value" in change.changed_fields
      assert change.changed_from == nil
    end

    test "INSERT and DELETE rows have changed_from nil" do
      %{rows: [[id]]} =
        Repo.query!("INSERT INTO #{@table} (name, value) VALUES ('b', 3) RETURNING id")

      insert = Repo.one!(Ecto.Query.from(c in AuditChange, where: c.op == "insert"))
      assert insert.changed_from == nil

      Repo.delete_all(AuditChange)
      Repo.delete_all(Threadline.Capture.AuditTransaction)

      Repo.query!("DELETE FROM #{@table} WHERE id = $1", [id])

      delete = Repo.one!(Ecto.Query.from(c in AuditChange, where: c.op == "delete"))
      assert delete.changed_from == nil
    end
  end

  describe "per-table capture with store_changed_from" do
    setup %{test: _} do
      sql =
        TriggerSQL.install_function_for_table(@table,
          store_changed_from: true,
          except_columns: []
        )

      Repo.query!(sql)
      Repo.query!(TriggerSQL.create_trigger(@table, :per_table))
      on_exit(fn -> Repo.query!(TriggerSQL.drop_trigger(@table)) end)
      :ok
    end

    test "UPDATE stores sparse changed_from from OLD row" do
      %{rows: [[id]]} =
        Repo.query!("INSERT INTO #{@table} (name, value) VALUES ('c', 10) RETURNING id")

      Repo.delete_all(AuditChange)
      Repo.delete_all(Threadline.Capture.AuditTransaction)

      Repo.query!("UPDATE #{@table} SET value = 20, name = 'c2' WHERE id = $1", [id])

      [change] = Repo.all(AuditChange)
      assert change.op == "update"
      assert Enum.sort(change.changed_fields) == ["name", "value"]

      assert is_map(change.changed_from)
      assert Map.get(change.changed_from, "value") == 10
      assert Map.get(change.changed_from, "name") == "c"
    end

    test "except_columns omits a column from changed_fields and changed_from" do
      sql =
        TriggerSQL.install_function_for_table(@table,
          store_changed_from: true,
          except_columns: ["value"]
        )

      Repo.query!(TriggerSQL.drop_trigger(@table))
      Repo.query!(sql)
      Repo.query!(TriggerSQL.create_trigger(@table, :per_table))

      %{rows: [[id]]} =
        Repo.query!("INSERT INTO #{@table} (name, value) VALUES ('d', 5) RETURNING id")

      Repo.delete_all(AuditChange)
      Repo.delete_all(Threadline.Capture.AuditTransaction)

      Repo.query!("UPDATE #{@table} SET value = 6, name = 'd2' WHERE id = $1", [id])

      [change] = Repo.all(AuditChange)
      assert change.changed_fields == ["name"]
      assert change.changed_from == %{"name" => "d"}
    end
  end
end
