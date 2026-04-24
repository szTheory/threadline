defmodule ThreadlineAuditSchema do
  use Ecto.Migration

  def up do
    execute """
    CREATE TABLE IF NOT EXISTS audit_transactions (
      id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
      txid        bigint      NOT NULL UNIQUE,
      occurred_at timestamptz NOT NULL DEFAULT now(),
      source      text,
      meta        jsonb
    )
    """

    execute "CREATE INDEX IF NOT EXISTS audit_transactions_txid_idx ON audit_transactions (txid)"

    execute """
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
    """

    execute "CREATE INDEX IF NOT EXISTS audit_changes_transaction_id_idx ON audit_changes (transaction_id)"
    execute "CREATE INDEX IF NOT EXISTS audit_changes_table_name_idx ON audit_changes (table_name)"
    execute "CREATE INDEX IF NOT EXISTS audit_changes_captured_at_idx ON audit_changes (captured_at)"

    execute "CREATE OR REPLACE FUNCTION threadline_capture_changes()\nRETURNS TRIGGER\nLANGUAGE plpgsql\nAS $threadline_trigger$\nDECLARE\n  v_txid           bigint;\n  v_tx_id          uuid;\n  v_data_after     jsonb;\n  v_table_pk       jsonb;\n  v_changed_fields text[];\nBEGIN\n  v_txid := txid_current();\n\n  -- Upsert the audit_transactions row keyed on the PostgreSQL transaction ID.\n  -- ON CONFLICT DO NOTHING is idempotent: multiple writes in the same transaction\n  -- reuse the existing row. This is PgBouncer-safe because txid_current() is\n  -- transaction-scoped, not session-scoped.\n  INSERT INTO audit_transactions (id, txid, occurred_at, actor_ref)\n  VALUES (\n    gen_random_uuid(),\n    v_txid,\n    clock_timestamp(),\n    NULLIF(current_setting('threadline.actor_ref', true), '')::jsonb\n  )\n  ON CONFLICT (txid) DO NOTHING;\n\n  SELECT id INTO v_tx_id\n  FROM audit_transactions\n  WHERE txid = v_txid;\n\n\n  IF TG_OP = 'DELETE' THEN\n    v_table_pk       := jsonb_build_object('id', (to_jsonb(OLD) ->> 'id'));\n    v_data_after     := NULL;\n    v_changed_fields := NULL;\n\n  ELSIF TG_OP = 'INSERT' THEN\n    v_table_pk       := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));\n    v_data_after     := to_jsonb(NEW);\n    v_changed_fields := NULL;\n\n  ELSE\n    -- UPDATE: capture changed field names\n    v_table_pk   := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));\n    v_data_after := to_jsonb(NEW);\n\n    SELECT array_agg(n.key ORDER BY n.key)\n    INTO   v_changed_fields\n    FROM   jsonb_each(to_jsonb(NEW)) AS n\n    JOIN   jsonb_each(to_jsonb(OLD)) AS o ON n.key = o.key\n    WHERE  n.value IS DISTINCT FROM o.value;\n  END IF;\n\n  INSERT INTO audit_changes (\n    id, transaction_id, table_schema, table_name,\n    table_pk, op, data_after, changed_fields, changed_from, captured_at\n  ) VALUES (\n    gen_random_uuid(), v_tx_id, TG_TABLE_SCHEMA, TG_TABLE_NAME,\n    v_table_pk, lower(TG_OP), v_data_after, v_changed_fields, NULL::jsonb, clock_timestamp()\n  );\n\n\n  IF TG_OP = 'DELETE' THEN\n    RETURN OLD;\n  END IF;\n  RETURN NEW;\nEND;\n$threadline_trigger$\n"
  end

  def down do
    execute "DROP FUNCTION IF EXISTS threadline_capture_changes()"
    execute "DROP TABLE IF EXISTS audit_changes"
    execute "DROP TABLE IF EXISTS audit_transactions"
  end
end
