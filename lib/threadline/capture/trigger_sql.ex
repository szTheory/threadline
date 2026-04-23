defmodule Threadline.Capture.TriggerSQL do
  @moduledoc """
  Generates PL/pgSQL trigger DDL for Threadline audit capture.

  The trigger function uses `txid_current()` to group row changes from the same
  database transaction under a single `audit_transactions` row. This approach is
  transaction-pooling safe per D-06: no session-local configuration writes.
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

  ## Redaction (`:exclude` / `:mask`)

  When non-empty column lists are passed to `install_function/1` or
  `install_function_for_table/2`, keys are removed (`:exclude`) or replaced with a
  stable placeholder (`:mask`) in `data_after` (and in `changed_from` when
  enabled). **`except_columns`** (per-table only) still removes keys from
  `changed_fields` / `changed_from` only; **`exclude`** also strips keys from the
  full-row `data_after` JSON. Union of both applies to change detection.

  **json / jsonb columns:** masking replaces the entire column value with the
  placeholder (no deep redaction).
  """

  alias Threadline.Capture.RedactionPolicy

  @doc """
  Returns SQL to create or replace the `threadline_capture_changes()` trigger function.

  The function assumes `audit_transactions` and `audit_changes` tables are accessible
  via the current `search_path`. `changed_from` is always written as NULL (use
  `install_function_for_table/2` for opt-in prior values).

  ## Options

  * `:exclude` — column names omitted entirely from `data_after` and from `changed_fields`.
  * `:mask` — column names whose values become the placeholder in `data_after` (after excludes).
  * `:mask_placeholder` — optional string; validated via `RedactionPolicy` (default `"[REDACTED]"`).

  When both lists are empty, SQL is identical to the historical global function.
  """
  def install_function(), do: install_function([])

  def install_function(opts) when is_list(opts) do
    exclude = Keyword.get(opts, :exclude, [])
    mask = Keyword.get(opts, :mask, [])
    placeholder = Keyword.get(opts, :mask_placeholder, RedactionPolicy.default_placeholder())

    if exclude == [] and mask == [] do
      global_install_function_sql_legacy()
    else
      RedactionPolicy.validate!(exclude: exclude, mask: mask, mask_placeholder: placeholder)
      global_capture_function_sql_redacted(exclude, mask, placeholder)
    end
  end

  @doc """
  Returns SQL to create or replace `threadline_capture_changes_<table>()` with
  UPDATE-time sparse `changed_from` built from `OLD` for keys in `changed_fields`
  (after `except_columns` and `exclude` are removed). Requires `store_changed_from: true`
  **or** non-empty `:exclude` / `:mask`.

  ## Options

  * `:store_changed_from` — when true, populate `changed_from` on UPDATE.
  * `:except_columns` — omit from `changed_fields` / `changed_from` (does not strip from `data_after`).
  * `:exclude`, `:mask`, `:mask_placeholder` — same semantics as `install_function/1` for row JSON.
  """
  def install_function_for_table(table_name, opts) do
    store_changed_from = Keyword.get(opts, :store_changed_from, false)
    exclude = Keyword.get(opts, :exclude, [])
    mask = Keyword.get(opts, :mask, [])

    unless store_changed_from or exclude != [] or mask != [] do
      raise ArgumentError,
            "install_function_for_table/2 requires [store_changed_from: true] and/or redaction :exclude/:mask, got: #{inspect(opts)}"
    end

    if exclude != [] or mask != [] do
      RedactionPolicy.validate!(
        exclude: exclude,
        mask: mask,
        mask_placeholder:
          Keyword.get(opts, :mask_placeholder, RedactionPolicy.default_placeholder())
      )
    end

    except_columns = Keyword.get(opts, :except_columns, [])
    placeholder = Keyword.get(opts, :mask_placeholder, RedactionPolicy.default_placeholder())

    if exclude == [] and mask == [] do
      per_table_install_sql_legacy(table_name, except_columns)
    else
      per_table_install_sql_redacted(
        table_name,
        except_columns,
        exclude,
        mask,
        placeholder,
        store_changed_from
      )
    end
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

  # Exact legacy SQL (pre–Phase 12) when no redaction rules apply.
  defp global_install_function_sql_legacy do
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
    #{transaction_capture_begin_sql()}

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

    #{audit_change_insert_sql_global()}

      IF TG_OP = 'DELETE' THEN
        RETURN OLD;
      END IF;
      RETURN NEW;
    END;
    $threadline_trigger$
    """
  end

  defp per_table_install_sql_legacy(table_name, except_columns) do
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

  defp per_table_install_sql_redacted(
         table_name,
         except_columns,
         exclude,
         mask,
         placeholder,
         store_changed_from
       ) do
    except_sql = changed_fields_except_array_sql(except_columns, exclude)
    fn_name = per_table_function_name(table_name)
    redact_after_new = data_after_redaction_statements("v_data_after", exclude, mask, placeholder)
    mask_array_sql = mask_array_sql_fragment(mask)
    placeholder_expr = mask_placeholder_sql_expr(placeholder)

    changed_from_block =
      if store_changed_from do
        """
            IF v_changed_fields IS NULL THEN
              v_changed_from := NULL::jsonb;
            ELSE
        #{per_table_changed_from_sql(mask_array_sql, placeholder_expr)}
            END IF;
        """
      else
        "        v_changed_from := NULL::jsonb;\n"
      end

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
    #{transaction_capture_begin_sql()}

      IF TG_OP = 'DELETE' THEN
        v_table_pk       := jsonb_build_object('id', (to_jsonb(OLD) ->> 'id'));
        v_data_after     := NULL;
        v_changed_fields := NULL;
        v_changed_from   := NULL;

      ELSIF TG_OP = 'INSERT' THEN
        v_table_pk       := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));
        v_data_after     := to_jsonb(NEW);
    #{redact_after_new}
        v_changed_fields := NULL;
        v_changed_from   := NULL;

      ELSE
        v_table_pk   := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));
        v_data_after := to_jsonb(NEW);
    #{redact_after_new}

        SELECT array_agg(n.key ORDER BY n.key)
        INTO   v_changed_fields
        FROM   jsonb_each(to_jsonb(NEW)) AS n
        JOIN   jsonb_each(to_jsonb(OLD)) AS o ON n.key = o.key
        WHERE  n.value IS DISTINCT FROM o.value
        AND NOT (n.key = ANY(#{except_sql}));

    #{changed_from_block}
      END IF;

    #{audit_change_insert_sql()}

      IF TG_OP = 'DELETE' THEN
        RETURN OLD;
      END IF;
      RETURN NEW;
    END;
    $threadline_trigger$
    """
  end

  defp global_capture_function_sql_redacted(exclude, mask, placeholder) do
    redact = data_after_redaction_statements("v_data_after", exclude, mask, placeholder)
    except_sql = changed_fields_except_array_sql([], exclude)

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
    #{transaction_capture_begin_sql()}

      IF TG_OP = 'DELETE' THEN
        v_table_pk       := jsonb_build_object('id', (to_jsonb(OLD) ->> 'id'));
        v_data_after     := NULL;
        v_changed_fields := NULL;

      ELSIF TG_OP = 'INSERT' THEN
        v_table_pk       := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));
        v_data_after     := to_jsonb(NEW);
    #{redact}
        v_changed_fields := NULL;

      ELSE
        -- UPDATE: capture changed field names
        v_table_pk   := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));
        v_data_after := to_jsonb(NEW);
    #{redact}

        SELECT array_agg(n.key ORDER BY n.key)
        INTO   v_changed_fields
        FROM   jsonb_each(to_jsonb(NEW)) AS n
        JOIN   jsonb_each(to_jsonb(OLD)) AS o ON n.key = o.key
        WHERE  n.value IS DISTINCT FROM o.value
        AND NOT (n.key = ANY(#{except_sql}));
      END IF;

    #{audit_change_insert_sql_global()}

      IF TG_OP = 'DELETE' THEN
        RETURN OLD;
      END IF;
      RETURN NEW;
    END;
    $threadline_trigger$
    """
  end

  defp transaction_capture_begin_sql do
    """
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
    """
  end

  defp audit_change_insert_sql_global do
    """
      INSERT INTO audit_changes (
        id, transaction_id, table_schema, table_name,
        table_pk, op, data_after, changed_fields, changed_from, captured_at
      ) VALUES (
        gen_random_uuid(), v_tx_id, TG_TABLE_SCHEMA, TG_TABLE_NAME,
        v_table_pk, lower(TG_OP), v_data_after, v_changed_fields, NULL::jsonb, clock_timestamp()
      );
    """
  end

  defp audit_change_insert_sql do
    """
      INSERT INTO audit_changes (
        id, transaction_id, table_schema, table_name,
        table_pk, op, data_after, changed_fields, changed_from, captured_at
      ) VALUES (
        gen_random_uuid(), v_tx_id, TG_TABLE_SCHEMA, TG_TABLE_NAME,
        v_table_pk, lower(TG_OP), v_data_after, v_changed_fields, v_changed_from, clock_timestamp()
      );
    """
  end

  defp per_table_changed_from_sql(mask_array_sql, placeholder_expr) do
    """
          SELECT jsonb_object_agg(
                   u.k,
                   CASE
                     WHEN u.k = ANY(#{mask_array_sql}) THEN #{placeholder_expr}
                     ELSE to_jsonb(OLD) -> u.k
                   END
                 )
          INTO v_changed_from
          FROM unnest(v_changed_fields) AS u(k);
    """
  end

  # D-10: changed_fields for masked columns uses raw NEW vs OLD from jsonb_each (already true).
  # Exclude list removes keys from change detection as well as payloads.

  defp data_after_redaction_statements(_var, [], [], _placeholder), do: ""

  defp data_after_redaction_statements(var, exclude, mask, placeholder) do
    strip =
      exclude
      |> Enum.map(fn col ->
        lit = sql_string_literal(col)
        "        #{var} := #{var} - #{lit};\n"
      end)
      |> IO.iodata_to_binary()

    mask_obj =
      if mask == [] do
        ""
      else
        pairs =
          mask
          |> Enum.map(fn col ->
            k = sql_string_literal(col)
            pe = mask_placeholder_sql_expr(placeholder)
            "#{k}, #{pe}"
          end)
          |> Enum.join(", ")

        "        #{var} := #{var} || jsonb_build_object(#{pairs});\n"
      end

    strip <> mask_obj
  end

  defp mask_placeholder_sql_expr(placeholder) do
    esc = String.replace(placeholder, "'", "''")
    "to_jsonb('#{esc}'::text)"
  end

  defp mask_array_sql_fragment([]), do: "ARRAY[]::text[]"

  defp mask_array_sql_fragment(cols) do
    inner =
      cols
      |> Enum.map(&sql_string_literal/1)
      |> Enum.join(", ")

    "ARRAY[#{inner}]::text[]"
  end

  defp changed_fields_except_array_sql(except_columns, exclude_columns) do
    (except_columns ++ exclude_columns)
    |> Enum.uniq()
    |> except_array_sql_fragment()
  end

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
