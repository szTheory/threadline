defmodule Threadline.Capture.Migration do
  @moduledoc """
  SQL DDL for the Threadline audit schema.

  Used by `mix threadline.install` to generate a migration file. The generated
  migration creates `audit_transactions` and `audit_changes` tables along with
  the `threadline_capture_changes()` trigger function.

  All DDL uses `IF NOT EXISTS` / `CREATE OR REPLACE` for idempotency (PKG-04).
  """

  alias Threadline.Capture.TriggerSQL

  @doc """
  Returns the full migration content as a string, ready to write to a `.exs` file.
  """
  def migration_content do
    """
    defmodule ThreadlineAuditSchema do
      use Ecto.Migration

      def up do
        execute \"\"\"
        CREATE TABLE IF NOT EXISTS audit_transactions (
          id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
          txid        bigint      NOT NULL UNIQUE,
          occurred_at timestamptz NOT NULL DEFAULT now(),
          source      text,
          meta        jsonb
        )
        \"\"\"

        execute "CREATE INDEX IF NOT EXISTS audit_transactions_txid_idx ON audit_transactions (txid)"

        execute \"\"\"
        CREATE TABLE IF NOT EXISTS audit_changes (
          id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
          transaction_id uuid        NOT NULL REFERENCES audit_transactions(id) ON DELETE CASCADE,
          table_schema   text        NOT NULL,
          table_name     text        NOT NULL,
          table_pk       jsonb       NOT NULL,
          op             text        NOT NULL CHECK (op IN ('insert', 'update', 'delete')),
          data_after     jsonb,
          changed_fields text[],
          changed_from     jsonb,
          captured_at    timestamptz NOT NULL DEFAULT now()
        )
        \"\"\"

        execute "CREATE INDEX IF NOT EXISTS audit_changes_transaction_id_idx ON audit_changes (transaction_id)"
        execute "CREATE INDEX IF NOT EXISTS audit_changes_table_name_idx ON audit_changes (table_name)"
        execute "CREATE INDEX IF NOT EXISTS audit_changes_captured_at_idx ON audit_changes (captured_at)"

        execute #{inspect(TriggerSQL.install_function([]))}
      end

      def down do
        execute #{inspect(TriggerSQL.drop_function())}
        execute "DROP TABLE IF EXISTS audit_changes"
        execute "DROP TABLE IF EXISTS audit_transactions"
      end
    end
    """
  end
end
