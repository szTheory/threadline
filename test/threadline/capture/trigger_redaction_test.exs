defmodule Threadline.Capture.TriggerRedactionTest do
  @moduledoc false
  # REDN-01, REDN-02 — persisted JSONB must omit excluded keys and mask listed columns.
  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, TriggerSQL}

  @table "test_redaction_users"

  setup_all do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS #{@table} (
      id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      password   text NOT NULL,
      email      text NOT NULL,
      public_bio text NOT NULL DEFAULT ''
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

  describe "per-table capture with exclude and mask" do
    setup %{test: _} do
      sql =
        TriggerSQL.install_function_for_table(@table,
          store_changed_from: true,
          except_columns: [],
          exclude: ["password"],
          mask: ["email"]
        )

      Repo.query!(sql)
      Repo.query!(TriggerSQL.create_trigger(@table, :per_table))
      on_exit(fn -> Repo.query!(TriggerSQL.drop_trigger(@table)) end)
      :ok
    end

    test "INSERT omits excluded keys and masks email" do
      Repo.query!(
        "INSERT INTO #{@table} (password, email, public_bio) VALUES ($1, $2, $3)",
        ["secret", "alice@example.com", "hi"]
      )

      [change] = Repo.all(AuditChange)
      assert change.op == "insert"
      assert change.data_after

      assert Map.has_key?(change.data_after, "public_bio")
      refute Map.has_key?(change.data_after, "password")
      assert Map.get(change.data_after, "email") == "[REDACTED]"
    end

    test "UPDATE masks changed_from for masked column and omits exclude from data_after" do
      %{rows: [[id]]} =
        Repo.query!(
          "INSERT INTO #{@table} (password, email, public_bio) VALUES ($1, $2, $3) RETURNING id",
          ["s0", "a@b.com", "x"]
        )

      Repo.delete_all(AuditChange)
      Repo.delete_all(Threadline.Capture.AuditTransaction)

      Repo.query!(
        "UPDATE #{@table} SET password = $2, email = $3, public_bio = $4 WHERE id = $1",
        [id, "s1", "c@d.com", "y"]
      )

      [change] = Repo.all(AuditChange)
      assert change.op == "update"
      assert "email" in change.changed_fields
      refute Map.has_key?(change.data_after, "password")
      assert Map.get(change.data_after, "email") == "[REDACTED]"

      assert is_map(change.changed_from)
      assert Map.get(change.changed_from, "email") == "[REDACTED]"
    end

    test "DELETE audit row does not leak raw secrets in JSON" do
      %{rows: [[id]]} =
        Repo.query!(
          "INSERT INTO #{@table} (password, email, public_bio) VALUES ($1, $2, $3) RETURNING id",
          ["pw", "u@example.com", "z"]
        )

      Repo.delete_all(AuditChange)
      Repo.delete_all(Threadline.Capture.AuditTransaction)

      Repo.query!("DELETE FROM #{@table} WHERE id = $1", [id])

      change = Repo.one!(Ecto.Query.from(c in AuditChange, where: c.op == "delete"))
      assert change.data_after == nil
    end
  end
end
