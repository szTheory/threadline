defmodule Threadline.Capture.TriggerSQL do
  @moduledoc """
  Generates PL/pgSQL trigger DDL for Threadline audit capture.

  The trigger function uses `txid_current()` to group row changes from the same
  database transaction under a single `audit_transactions` row. This approach is
  PgBouncer transaction-pooling safe per D-06: no `SET LOCAL`, no session variables.
  The `txid` column on `audit_transactions` has a `UNIQUE` constraint so concurrent
  INSERTs with `ON CONFLICT DO NOTHING` are safe.
  """

  @doc """
  Returns SQL to create or replace the `threadline_capture_changes()` trigger function.

  The function assumes `audit_transactions` and `audit_changes` tables are accessible
  via the current `search_path`.
  """
  def install_function do
    """
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

      -- Upsert the audit_transactions row keyed on the PostgreSQL transaction ID.
      -- ON CONFLICT DO NOTHING is idempotent: multiple writes in the same transaction
      -- reuse the existing row. This is PgBouncer-safe because txid_current() is
      -- transaction-scoped, not session-scoped.
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
        -- UPDATE: capture changed field names
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

  @doc "Returns SQL to drop the trigger function."
  def drop_function do
    "DROP FUNCTION IF EXISTS threadline_capture_changes()"
  end

  @doc "Returns SQL to install a trigger on the given table."
  def create_trigger(table_name) do
    """
    CREATE TRIGGER threadline_audit_#{table_name}
    AFTER INSERT OR UPDATE OR DELETE ON #{table_name}
    FOR EACH ROW EXECUTE FUNCTION threadline_capture_changes()
    """
  end

  @doc "Returns SQL to drop a trigger from the given table."
  def drop_trigger(table_name) do
    "DROP TRIGGER IF EXISTS threadline_audit_#{table_name} ON #{table_name}"
  end
end
