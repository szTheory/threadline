defmodule Threadline.Capture.TriggerRerunTest do
  @moduledoc """
  Applies the trigger DDL a rerun migration emits against the real database:
  installing the audit trigger again must replace it in place, and switching a
  table between the global and per-table capture functions must re-point the
  existing trigger.
  """

  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction, TriggerSQL}
  alias Threadline.StorageSchema

  @table "test_trigger_rerun_target"

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
    Repo.delete_all(AuditChange, repo_opts())
    Repo.delete_all(AuditTransaction, repo_opts())
    :ok
  end

  describe "rerunning trigger installation" do
    test "installing the trigger twice succeeds" do
      Repo.query!(TriggerSQL.create_trigger(@table))
      Repo.query!(TriggerSQL.create_trigger(@table))

      assert trigger_function() == {StorageSchema.get(), "threadline_capture_changes"}
    end

    test "a rerun re-points the trigger to the per-table function" do
      Repo.query!(TriggerSQL.create_trigger(@table))

      Repo.query!(
        TriggerSQL.install_function_for_table(@table,
          store_changed_from: true,
          except_columns: []
        )
      )

      Repo.query!(TriggerSQL.create_trigger(@table, :per_table))

      assert trigger_function() ==
               {StorageSchema.get(), "threadline_capture_changes_" <> @table}

      %{rows: [[id]]} =
        Repo.query!("INSERT INTO #{@table} (name, value) VALUES ('a', 1) RETURNING id")

      Repo.delete_all(AuditChange, repo_opts())
      Repo.delete_all(AuditTransaction, repo_opts())

      Repo.query!("UPDATE #{@table} SET value = 2 WHERE id = $1", [id])

      [change] = Repo.all(AuditChange, repo_opts())
      assert change.op == "update"
      assert is_map(change.changed_from)
      assert Map.get(change.changed_from, "value") == 1
    end
  end

  # Identifies the trigger's function by catalog name and namespace rather than
  # its text rendering, which varies with search_path. The table name is sent as
  # text and cast, because Postgrex encodes a bare regclass parameter as an oid.
  defp trigger_function do
    %{rows: [[nsp, proname]]} =
      Repo.query!(
        """
        SELECT n.nspname, p.proname
        FROM pg_trigger t
        JOIN pg_proc p ON p.oid = t.tgfoid
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE t.tgrelid = $1::text::regclass AND t.tgname = $2 AND NOT t.tgisinternal
        """,
        [@table, "threadline_audit_" <> @table]
      )

    {nsp, proname}
  end
end
