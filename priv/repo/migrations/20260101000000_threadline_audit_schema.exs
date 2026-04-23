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
      captured_at    timestamptz NOT NULL DEFAULT now()
    )
    """

    execute "CREATE INDEX IF NOT EXISTS audit_changes_transaction_id_idx ON audit_changes (transaction_id)"
    execute "CREATE INDEX IF NOT EXISTS audit_changes_table_name_idx ON audit_changes (table_name)"
    execute "CREATE INDEX IF NOT EXISTS audit_changes_captured_at_idx ON audit_changes (captured_at)"

    execute """
    CREATE OR REPLACE FUNCTION threadline_capture_changes()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $threadline_trigger$
    DECLARE
      v_txid           bigint;
      v_tx_id          uuid;
      v_data_after     jsonb;
      v_table_pk       jsonb;
      v_changed_fields text[];
    BEGIN
      v_txid := txid_current();

      INSERT INTO audit_transactions (id, txid, occurred_at)
      VALUES (gen_random_uuid(), v_txid, clock_timestamp())
      ON CONFLICT (txid) DO NOTHING;

      SELECT id INTO v_tx_id
      FROM audit_transactions
      WHERE txid = v_txid;

      IF TG_OP = 'DELETE' THEN
        v_table_pk       := jsonb_build_object('id', (to_jsonb(OLD) ->> 'id'));
        v_data_after     := NULL;
        v_changed_fields := NULL;

      ELSIF TG_OP = 'INSERT' THEN
        v_table_pk       := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));
        v_data_after     := to_jsonb(NEW);
        v_changed_fields := NULL;

      ELSE
        v_table_pk   := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));
        v_data_after := to_jsonb(NEW);

        SELECT array_agg(n.key ORDER BY n.key)
        INTO   v_changed_fields
        FROM   jsonb_each(to_jsonb(NEW)) AS n
        JOIN   jsonb_each(to_jsonb(OLD)) AS o ON n.key = o.key
        WHERE  n.value IS DISTINCT FROM o.value;
      END IF;

      INSERT INTO audit_changes (
        id, transaction_id, table_schema, table_name,
        table_pk, op, data_after, changed_fields, captured_at
      ) VALUES (
        gen_random_uuid(), v_tx_id, TG_TABLE_SCHEMA, TG_TABLE_NAME,
        v_table_pk, lower(TG_OP), v_data_after, v_changed_fields, clock_timestamp()
      );

      IF TG_OP = 'DELETE' THEN
        RETURN OLD;
      END IF;
      RETURN NEW;
    END;
    $threadline_trigger$
    """
  end

  def down do
    execute "DROP FUNCTION IF EXISTS threadline_capture_changes()"
    execute "DROP TABLE IF EXISTS audit_changes"
    execute "DROP TABLE IF EXISTS audit_transactions"
  end
end
