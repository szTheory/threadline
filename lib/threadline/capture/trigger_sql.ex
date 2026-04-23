defmodule Threadline.Capture.TriggerSQL do
  @moduledoc """
  Generates PL/pgSQL trigger DDL for Threadline audit capture.

  The trigger function uses `txid_current()` to group row changes from the same
  database transaction under a single `audit_transactions` row. This approach is
  PgBouncer transaction-pooling safe per D-06: no session-local configuration writes.
  Optional `audit_transactions.actor_ref` is read from the transaction-local GUC
  `threadline.actor_ref` (published by the host application in the same
  transaction — see D-09); the trigger only **reads** this setting and never
  assigns session configuration from PL/pgSQL. The `txid` column on `audit_transactions` has a `UNIQUE`
  constraint so concurrent INSERTs with `ON CONFLICT DO NOTHING` are safe.

  ## Before-values (`changed_from`)

  The default `threadline_capture_changes()` always writes `changed_from` as SQL
  NULL. To capture sparse prior-row JSON on UPDATE for specific tables, generate a
  migration with `mix threadline.gen.triggers --tables ... --store-changed-from`
  (and optional `--except-columns col1,col2`). That emits a per-table function
  `threadline_capture_changes_<table>()` and rewires triggers to call it.
  """

  @doc """
  Returns SQL to create or replace the `threadline_capture_changes()` trigger function.

  The function assumes `audit_transactions` and `audit_changes` tables are accessible
  via the current `search_path`. `changed_from` is always written as NULL (use
  `install_function_for_table/2` for opt-in prior values).
  """
  def install_function(), do: install_function([])

  def install_function(_opts) do
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
      INSERT INTO audit_transactions (id, txid, occurred_at, actor_ref)
      VALUES (
        gen_random_uuid(),
        v_txid,
        clock_timestamp(),
        NULLIF(current_setting('threadline.actor_ref', true), '')::jsonb
      )
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
        table_pk, op, data_after, changed_fields, changed_from, captured_at
      ) VALUES (
        gen_random_uuid(), v_tx_id, TG_TABLE_SCHEMA, TG_TABLE_NAME,
        v_table_pk, lower(TG_OP), v_data_after, v_changed_fields, NULL::jsonb, clock_timestamp()
      );

      IF TG_OP = 'DELETE' THEN
        RETURN OLD;
      END IF;
      RETURN NEW;
    END;
    $threadline_trigger$
    """
  end

  @doc """
  Returns SQL to create or replace `threadline_capture_changes_<table>()` with
  UPDATE-time sparse `changed_from` built from `OLD` for keys in `changed_fields`
  (after `except_columns` are removed). Requires `store_changed_from: true`.
  """
  def install_function_for_table(table_name, opts) do
    unless Keyword.get(opts, :store_changed_from, false) do
      raise ArgumentError,
            "install_function_for_table/2 requires [store_changed_from: true], got: #{inspect(opts)}"
    end

    except_columns = Keyword.get(opts, :except_columns, [])
    except_sql = except_array_sql_fragment(except_columns)
    fn_name = per_table_function_name(table_name)

    """
    CREATE OR REPLACE FUNCTION #{fn_name}()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $threadline_trigger$
    DECLARE
      v_txid           bigint;
      v_tx_id          uuid;
      v_data_after     jsonb;
      v_table_pk       jsonb;
      v_changed_fields text[];
      v_changed_from   jsonb;
    BEGIN
      v_txid := txid_current();

      INSERT INTO audit_transactions (id, txid, occurred_at, actor_ref)
      VALUES (
        gen_random_uuid(),
        v_txid,
        clock_timestamp(),
        NULLIF(current_setting('threadline.actor_ref', true), '')::jsonb
      )
      ON CONFLICT (txid) DO NOTHING;

      SELECT id INTO v_tx_id
      FROM audit_transactions
      WHERE txid = v_txid;

      IF TG_OP = 'DELETE' THEN
        v_table_pk       := jsonb_build_object('id', (to_jsonb(OLD) ->> 'id'));
        v_data_after     := NULL;
        v_changed_fields := NULL;
        v_changed_from   := NULL;

      ELSIF TG_OP = 'INSERT' THEN
        v_table_pk       := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));
        v_data_after     := to_jsonb(NEW);
        v_changed_fields := NULL;
        v_changed_from   := NULL;

      ELSE
        v_table_pk   := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));
        v_data_after := to_jsonb(NEW);

        SELECT array_agg(n.key ORDER BY n.key)
        INTO   v_changed_fields
        FROM   jsonb_each(to_jsonb(NEW)) AS n
        JOIN   jsonb_each(to_jsonb(OLD)) AS o ON n.key = o.key
        WHERE  n.value IS DISTINCT FROM o.value
        AND NOT (n.key = ANY(#{except_sql}));

        IF v_changed_fields IS NULL THEN
          v_changed_from := NULL::jsonb;
        ELSE
          SELECT jsonb_object_agg(u.k, to_jsonb(OLD) -> u.k)
          INTO v_changed_from
          FROM unnest(v_changed_fields) AS u(k);
        END IF;
      END IF;

      INSERT INTO audit_changes (
        id, transaction_id, table_schema, table_name,
        table_pk, op, data_after, changed_fields, changed_from, captured_at
      ) VALUES (
        gen_random_uuid(), v_tx_id, TG_TABLE_SCHEMA, TG_TABLE_NAME,
        v_table_pk, lower(TG_OP), v_data_after, v_changed_fields, v_changed_from, clock_timestamp()
      );

      IF TG_OP = 'DELETE' THEN
        RETURN OLD;
      END IF;
      RETURN NEW;
    END;
    $threadline_trigger$
    """
  end

  @doc "Returns SQL to drop the global trigger function."
  def drop_function do
    "DROP FUNCTION IF EXISTS threadline_capture_changes()"
  end

  @doc "Returns SQL to drop a per-table capture function (use after dropping triggers, or with CASCADE)."
  def drop_function_for_table(table_name) do
    name = per_table_function_name(table_name)
    "DROP FUNCTION IF EXISTS #{name}() CASCADE"
  end

  @doc """
  Returns SQL to install a trigger on the given table.

  * `:default` — calls `threadline_capture_changes()` (default).
  * `:per_table` — calls `threadline_capture_changes_<table>()` from `install_function_for_table/2`.
  """
  def create_trigger(table_name, mode \\ :default)

  def create_trigger(table_name, :default) do
    create_trigger_sql(table_name, "threadline_capture_changes()")
  end

  def create_trigger(table_name, :per_table) do
    fname = per_table_function_name(table_name) <> "()"
    create_trigger_sql(table_name, fname)
  end

  defp create_trigger_sql(table_name, function_invocation) do
    """
    CREATE TRIGGER threadline_audit_#{table_name}
    AFTER INSERT OR UPDATE OR DELETE ON #{table_name}
    FOR EACH ROW EXECUTE FUNCTION #{function_invocation}
    """
  end

  @doc "Returns SQL to drop a trigger from the given table."
  def drop_trigger(table_name) do
    "DROP TRIGGER IF EXISTS threadline_audit_#{table_name} ON #{table_name}"
  end

  defp per_table_function_name(table_name), do: "threadline_capture_changes_#{table_name}"

  defp except_array_sql_fragment([]), do: "ARRAY[]::text[]"

  defp except_array_sql_fragment(cols) do
    inner =
      cols
      |> Enum.map(&sql_string_literal/1)
      |> Enum.join(", ")

    "ARRAY[#{inner}]::text[]"
  end

  defp sql_string_literal(str) do
    escaped = String.replace(str, "'", "''")
    "'#{escaped}'"
  end
end
