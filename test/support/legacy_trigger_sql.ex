defmodule Threadline.Test.LegacyTriggerSQL do
  @moduledoc """
  Frozen copies of the trigger SQL earlier releases wrote into host migrations.

  Each renderer reproduces one historical template byte for byte and never
  calls the current SQL or naming code, so a change there cannot quietly
  change these fixtures:

    * `v0_9_create_trigger/2`: release v0.9.0 (7378b75a) and earlier. Nothing
      is quoted or qualified, and long names are written uncut.
    * `v0_10_0_create_trigger/3`: release v0.10.0 (3d148435), identical in
      v0.10.1. Quoted trigger name, `ON "schema"."table"`, plain
      `CREATE TRIGGER`.
    * `v0_10_2_create_trigger/3`: release v0.10.2 (ee137e51). The same as
      v0.10.0 but `CREATE OR REPLACE TRIGGER`.
    * `v0_10_2_install_function/2`: release v0.10.2 (ee137e51) global capture
      function body — `TG_NARGS` never appears in it, because arguments did
      not exist yet. Copied verbatim from
      `git show v0.10.2:lib/threadline/capture/trigger_sql.ex`
      (`global_install_function_sql_legacy/1`, `transaction_capture_begin_sql/1`
      and `audit_change_insert_sql_global/1`, expanded inline), with only the
      function reference and the two storage-qualified table names
      substituted by plain string interpolation of already-quoted literals.
    * `v0_10_2_drop_function_for_table/2`: release v0.10.2's per-table
      capture function drop statement, copied verbatim from
      `git show v0.10.2:lib/threadline/capture/trigger_sql.ex`
      (`drop_function_for_table/2`) — a plain `DROP FUNCTION IF EXISTS ...()
      CASCADE`, with no check for whether another table's trigger still
      calls it. This is the hazard `guides/upgrading-to-0.11.md`'s "Rolling
      back" section warns about and its rollback-cleanup SQL replaces.
    * `v0_10_2_install_function_for_table/3`: release v0.10.2's per-table
      capture function body, copied verbatim from
      `git show v0.10.2:lib/threadline/capture/trigger_sql.ex`
      (`per_table_install_sql_legacy/3` and `per_table_install_sql_redacted/7`,
      with their private helpers inlined), with only the function reference
      and storage-qualified table names substituted by plain string
      interpolation of already-quoted literals. Used to seed the
      shared-capture-function-pair fixture (two tables, one per-table
      function) at the exact 0.10.2 shape, instead of the current
      `TriggerSQL.install_function_for_table/2` renderer.

  `migration_source/3` wraps statements in a migration file the way every
  release wrote them: one `execute` call per statement with the SQL passed
  through `inspect/1`.
  """

  @doc "The v0.9.0 trigger statement for an unqualified table."
  def v0_9_create_trigger(table, function_ref \\ "threadline_capture_changes()") do
    """
    CREATE TRIGGER threadline_audit_#{table}
    AFTER INSERT OR UPDATE OR DELETE ON #{table}
    FOR EACH ROW EXECUTE FUNCTION #{function_ref}
    """
  end

  @doc "The v0.10.0 and v0.10.1 trigger statement."
  def v0_10_0_create_trigger(schema, table, function_ref \\ nil) do
    v0_10_create_trigger("CREATE TRIGGER", schema, table, function_ref)
  end

  @doc "The v0.10.2 trigger statement."
  def v0_10_2_create_trigger(schema, table, function_ref \\ nil) do
    v0_10_create_trigger("CREATE OR REPLACE TRIGGER", schema, table, function_ref)
  end

  @doc "A migration file with each statement written as `execute` plus `inspect(sql)`."
  def migration_source(module, up_sqls, down_sqls) do
    """
    defmodule #{module} do
      use Ecto.Migration

      def up do
    #{executes(up_sqls)}
      end

      def down do
    #{executes(down_sqls)}
      end
    end
    """
  end

  @doc """
  The v0.10.2 global capture function body, frozen byte for byte.

  `function_ref` is the fully quoted `CREATE FUNCTION` target (schema and
  name quoted, no parens), such as `~s|"threadline"."legacy_capture_v0_10_2"|`.
  `storage_schema` is a plain schema name string, interpolated here into
  `"schema"."audit_transactions"` / `"schema"."audit_changes"` literals built
  only in this function — never through the current storage-schema or
  capture-SQL renderers, so a change to either cannot quietly change this
  fixture. There is no `TG_NARGS` branch: this body always reads
  `to_jsonb(NEW|OLD) ->> 'id'` directly.
  """
  def v0_10_2_install_function(function_ref, storage_schema) do
    audit_transactions = ~s|"#{storage_schema}"."audit_transactions"|
    audit_changes = ~s|"#{storage_schema}"."audit_changes"|

    """
    CREATE OR REPLACE FUNCTION #{function_ref}()
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
      INSERT INTO #{audit_transactions} (id, txid, occurred_at, actor_ref)
      VALUES (
        gen_random_uuid(),
        v_txid,
        clock_timestamp(),
        NULLIF(current_setting('threadline.actor_ref', true), '')::jsonb
      )
      ON CONFLICT (txid) DO NOTHING;

      SELECT id INTO v_tx_id
      FROM #{audit_transactions}
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

      INSERT INTO #{audit_changes} (
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
  The v0.10.2 per-table capture function drop statement, frozen byte for
  byte: a plain `DROP FUNCTION IF EXISTS "storage"."name"() CASCADE`, with no
  check for whether a trigger still uses it.

  `function_name` is the bare per-table function name (for example
  `threadline_capture_changes_billing_invoices`); `storage_schema` is a
  plain schema name string, interpolated here directly — never through the
  current storage-schema renderer — matching `v0_10_2_install_function/2`'s
  own interpolation style.
  """
  def v0_10_2_drop_function_for_table(function_name, storage_schema) do
    ~s|DROP FUNCTION IF EXISTS "#{storage_schema}"."#{function_name}"() CASCADE|
  end

  @doc """
  The v0.10.2 per-table capture function body, frozen byte for byte.

  `function_name` is the bare per-table function name (for example
  `threadline_capture_changes_billing_invoices`); `storage_schema` is a
  plain schema name string, interpolated here directly — never through the
  current storage-schema renderer — matching `v0_10_2_install_function/2`'s
  and `v0_10_2_drop_function_for_table/2`'s own interpolation style.

  ## Options

    * `:mask` — column names masked (via a `jsonb_build_object` overlay) in
      `data_after`, same semantics as 0.10.2's `install_function_for_table/2`.
    * `:mask_placeholder` — placeholder string (default `"[REDACTED]"`).
    * `:exclude` — column names stripped from `data_after`.
    * `:store_changed_from` — when true, populate `changed_from` on UPDATE
      from `OLD`, for keys in `changed_fields`.
    * `:except_columns` — omit from `changed_fields`/`changed_from` (does
      not strip from `data_after`).

  At least one of `:store_changed_from`, `:exclude`, or `:mask` is required,
  matching the release's own guard in `install_function_for_table/2`.
  """
  def v0_10_2_install_function_for_table(function_name, storage_schema, opts \\ []) do
    store_changed_from = Keyword.get(opts, :store_changed_from, false)
    exclude = Keyword.get(opts, :exclude, [])
    mask = Keyword.get(opts, :mask, [])
    except_columns = Keyword.get(opts, :except_columns, [])
    placeholder = Keyword.get(opts, :mask_placeholder, "[REDACTED]")

    unless store_changed_from or exclude != [] or mask != [] do
      raise ArgumentError,
            "v0_10_2_install_function_for_table/3 requires [store_changed_from: true] and/or " <>
              ":exclude/:mask, got: #{inspect(opts)}"
    end

    fn_name = ~s|"#{storage_schema}"."#{function_name}"|
    audit_transactions = ~s|"#{storage_schema}"."audit_transactions"|
    audit_changes = ~s|"#{storage_schema}"."audit_changes"|

    if exclude == [] and mask == [] do
      v0_10_2_per_table_legacy_sql(fn_name, audit_transactions, audit_changes, except_columns)
    else
      v0_10_2_per_table_redacted_sql(
        fn_name,
        audit_transactions,
        audit_changes,
        except_columns,
        exclude,
        mask,
        placeholder,
        store_changed_from
      )
    end
  end

  defp v0_10_2_per_table_legacy_sql(fn_name, audit_transactions, audit_changes, except_columns) do
    except_sql = v0_10_2_array_sql_fragment(except_columns)

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

      INSERT INTO #{audit_transactions} (id, txid, occurred_at, actor_ref)
      VALUES (
        gen_random_uuid(),
        v_txid,
        clock_timestamp(),
        NULLIF(current_setting('threadline.actor_ref', true), '')::jsonb
      )
      ON CONFLICT (txid) DO NOTHING;

      SELECT id INTO v_tx_id
      FROM #{audit_transactions}
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

      INSERT INTO #{audit_changes} (
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

  defp v0_10_2_per_table_redacted_sql(
         fn_name,
         audit_transactions,
         audit_changes,
         except_columns,
         exclude,
         mask,
         placeholder,
         store_changed_from
       ) do
    except_sql = v0_10_2_array_sql_fragment(Enum.uniq(except_columns ++ exclude))
    redact_after_new = v0_10_2_data_after_redaction_statements(exclude, mask, placeholder)
    mask_array_sql = v0_10_2_array_sql_fragment(mask)
    placeholder_expr = v0_10_2_mask_placeholder_sql_expr(placeholder)

    changed_from_block =
      if store_changed_from do
        """
            IF v_changed_fields IS NULL THEN
              v_changed_from := NULL::jsonb;
            ELSE
              SELECT jsonb_object_agg(
                       u.k,
                       CASE
                         WHEN u.k = ANY(#{mask_array_sql}) THEN #{placeholder_expr}
                         ELSE to_jsonb(OLD) -> u.k
                       END
                     )
              INTO v_changed_from
              FROM unnest(v_changed_fields) AS u(k);
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
      v_txid := txid_current();

      INSERT INTO #{audit_transactions} (id, txid, occurred_at, actor_ref)
      VALUES (
        gen_random_uuid(),
        v_txid,
        clock_timestamp(),
        NULLIF(current_setting('threadline.actor_ref', true), '')::jsonb
      )
      ON CONFLICT (txid) DO NOTHING;

      SELECT id INTO v_tx_id
      FROM #{audit_transactions}
      WHERE txid = v_txid;

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

      INSERT INTO #{audit_changes} (
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

  # Masked-column change detection compares raw NEW and OLD values before
  # redaction; the exclude list removes keys from change detection as well
  # as from payloads (mirrors the real code's own comment).

  defp v0_10_2_data_after_redaction_statements([], [], _placeholder), do: ""

  defp v0_10_2_data_after_redaction_statements(exclude, mask, placeholder) do
    strip =
      exclude
      |> Enum.map(fn col ->
        lit = v0_10_2_sql_string_literal(col)
        "        v_data_after := v_data_after - #{lit};\n"
      end)
      |> IO.iodata_to_binary()

    mask_obj =
      if mask == [] do
        ""
      else
        pairs =
          Enum.map_join(mask, ", ", fn col ->
            k = v0_10_2_sql_string_literal(col)
            pe = v0_10_2_mask_placeholder_sql_expr(placeholder)
            "#{k}, #{pe}"
          end)

        "        v_data_after := v_data_after || jsonb_build_object(#{pairs});\n"
      end

    strip <> mask_obj
  end

  defp v0_10_2_mask_placeholder_sql_expr(placeholder) do
    esc = String.replace(placeholder, "'", "''")
    "to_jsonb('#{esc}'::text)"
  end

  defp v0_10_2_array_sql_fragment([]), do: "ARRAY[]::text[]"

  defp v0_10_2_array_sql_fragment(cols) do
    inner = Enum.map_join(cols, ", ", &v0_10_2_sql_string_literal/1)
    "ARRAY[#{inner}]::text[]"
  end

  defp v0_10_2_sql_string_literal(str) do
    escaped = String.replace(str, "'", "''")
    "'#{escaped}'"
  end

  defp v0_10_create_trigger(verb, schema, table, function_ref) do
    suffix = if schema == "public", do: table, else: schema <> "_" <> table
    function_ref = function_ref || ~s|"public"."threadline_capture_changes"()|

    """
    #{verb} "threadline_audit_#{suffix}"
    AFTER INSERT OR UPDATE OR DELETE ON "#{schema}"."#{table}"
    FOR EACH ROW EXECUTE FUNCTION #{function_ref}
    """
  end

  # printable_limit/limit: :infinity, same as the real generator's
  # execute_line/1 — plain inspect/1 cuts a string over 4096 bytes and
  # appends `<> ...`, which would corrupt a large trigger SQL fixture.
  defp executes(sqls),
    do:
      Enum.map_join(sqls, "\n", fn sql ->
        "    execute " <> inspect(sql, printable_limit: :infinity, limit: :infinity)
      end)
end
