defmodule Threadline.Capture.PrimaryKeySQL do
  @moduledoc false

  # Owns the generated SQL that knows about primary keys: the shared,
  # catalog-free row-key fragment every capture-function body interpolates,
  # and the migrate-time DO block that resolves a table's real primary key
  # from pg_index and installs its trigger with the resolved columns as
  # trigger arguments. Kept in its own module so trigger_sql.ex stays under
  # its line cap.

  alias Threadline.Capture.Naming
  alias Threadline.StorageSchema

  @doc """
  Returns the shared PL/pgSQL fragment that reads `v_row` (already assigned
  by the caller to `to_jsonb(NEW)` or `to_jsonb(OLD)`) and sets `v_table_pk`.

  Indented to sit inside a renderer's `IF`/`ELSIF`/`ELSE` branch, immediately
  after the `v_row := ...;` assignment.

  * No trigger arguments (a trigger installed before this release): the
    legacy `id`-only key when present, otherwise `{}`.
  * Otherwise: builds the key column by column from `TG_ARGV`. The key is
    all or nothing — any missing or NULL column stores `{}`, never a
    partial composite key.

  No catalog lookup, no dynamic statement, no per-row aggregate: every
  column comes from `TG_ARGV`, resolved once at migrate time.
  """
  @spec row_key_statements() :: String.t()
  def row_key_statements do
    """
        IF TG_NARGS = 0 THEN
          IF v_row ? 'id' THEN
            v_table_pk := jsonb_build_object('id', v_row ->> 'id');
          ELSE
            v_table_pk := '{}'::jsonb;
          END IF;
        ELSE
          v_table_pk := '{}'::jsonb;
          FOR i IN 0 .. TG_NARGS - 1 LOOP
            IF (v_row ->> TG_ARGV[i]) IS NULL THEN
              v_table_pk := '{}'::jsonb;
              EXIT;
            END IF;
            v_table_pk := coalesce(v_table_pk, '{}'::jsonb)
                          || jsonb_build_object(TG_ARGV[i], v_row ->> TG_ARGV[i]);
          END LOOP;
        END IF;
        v_table_pk := coalesce(v_table_pk, '{}'::jsonb);
    """
  end

  @doc """
  Returns a `DO` block that resolves the table's primary key at migrate
  time and installs its capture trigger with the resolved columns as
  trigger arguments.

  `function_literal` is the fully schema-qualified, quoted function name
  (no parentheses), such as `StorageSchema.function("threadline_capture_changes", opts)`
  or a per-table function name.

  Resolution: only the table's own primary key counts
  (`pg_index.indisprimary`), and only its first `indnkeyatts` key columns —
  an `INCLUDE` column never becomes a trigger argument. `unnest(...) WITH
  ORDINALITY` preserves primary-key position order; `indkey` is 0-based, so
  `WITH ORDINALITY` is used instead of indexing it directly. A deferrable
  primary key is accepted.

  A table with **no primary key** refuses the migration instead of
  installing an argument-less trigger, because its audit rows could never
  be told apart: the error names the qualified table and, when a unique
  index over `NOT NULL` columns already qualifies as a stand-in, its
  `HINT` gives a paste-ready `config/config.exs` snippet and the
  `mix threadline.gen.triggers` command to rerun. A qualified table that
  does not exist also raises, so the migration rolls back before any host
  write instead of silently installing a trigger on nothing.

  Every resolved key column's type is checked against an allowlist —
  `smallint`/`integer`/`bigint`; `text`/`varchar`/`char`/`citext`; `uuid`;
  `date`; `timestamp` (without time zone); enums; and domains over any of
  these, resolved through `typbasetype`. A column outside the allowlist
  (`timestamptz`, `numeric`, floats, `json`/`jsonb`, arrays, `bytea`, …)
  has no stable text form for an audit key, so it refuses the migration,
  naming the column and its `format_type`. A table with a pre-0.11
  no-argument trigger keeps capturing under the legacy branch of
  `row_key_statements/0` until it is regenerated.

  ## Options

  * `:primary_key` — a declared column list for a table with no primary
    key (`config :threadline, :trigger_capture, tables: %{"t" =>
    [primary_key: [...]]}`). Skips the `pg_index` primary-key lookup:
    refuses if the table already has a primary key, refuses a declared
    column that does not exist (matched by `attname`, never `attnum`),
    and otherwise requires a qualifying unique index whose key-column set
    equals the declared set exactly (no subset, no superset, `INCLUDE`
    columns don't count). Declared order becomes trigger-argument order.
  * `:redacted_columns` — column names the table's function masks or
    excludes (`exclude ++ mask`). When non-empty, a detected or declared
    primary-key column listed here refuses the migration: redacting a
    key column would erase row identity from the audit trail.

  The trigger name, the `ON` table and the function are all literal text
  inside the `format()` call (never `%I`), because
  `Threadline.Mix.TriggerMigration`'s rerun detection scans for that exact
  literal shape. The table reference is built only from
  `StorageSchema.qualified_host_table/1`; the `regclass` variable is never
  rendered back to text, which would drop the schema qualifier whenever it
  is on `search_path`.
  """
  @spec create_trigger_block(Naming.table(), String.t(), keyword()) :: String.t()
  def create_trigger_block(table_name, function_literal, opts \\ []) do
    case Keyword.get(opts, :primary_key) do
      nil -> detected_trigger_block(table_name, function_literal, opts)
      declared -> override_trigger_block(table_name, function_literal, declared, opts)
    end
  end

  defp detected_trigger_block(table_name, function_literal, opts) do
    qualified = Naming.qualified(table_name)
    host_table = StorageSchema.qualified_host_table(table_name)
    config_key = Naming.table_token(table_name)
    statement = create_trigger_statement(table_name, function_literal)
    redacted_columns = Keyword.get(opts, :redacted_columns, [])
    redaction_check = redaction_check_sql(qualified, redacted_columns)

    """
    -- threadline: resolve the primary key of #{qualified}, then install its capture trigger
    DO $$
    DECLARE
      tbl      regclass := to_regclass('#{host_table}');
      keys     text[];
      idx_name text;
      idx_cols text;
      col      text;
      coltype  text;
      args     text;
    BEGIN
      IF tbl IS NULL THEN
        RAISE EXCEPTION 'threadline: table #{qualified} does not exist';
      END IF;

      SELECT array_agg(a.attname::text ORDER BY k.ord)
        INTO keys
        FROM pg_index i
        CROSS JOIN LATERAL unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
        JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
       WHERE i.indrelid = tbl AND i.indisprimary AND k.ord <= i.indnkeyatts;

      IF keys IS NULL THEN
        SELECT ic.relname
          INTO idx_name
          FROM pg_index i
          JOIN pg_class ic ON ic.oid = i.indexrelid
         WHERE i.indrelid = tbl AND #{qualifying_index_predicate()}
           AND NOT EXISTS (
                 SELECT 1 FROM unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
                  WHERE k.ord <= i.indnkeyatts AND k.attnum = 0
               )
           AND NOT EXISTS (
                 SELECT 1 FROM unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
                 JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
                  WHERE k.ord <= i.indnkeyatts AND NOT a.attnotnull
               )
         ORDER BY ic.relname
         LIMIT 1;

        IF idx_name IS NOT NULL THEN
          SELECT string_agg(
                   chr(34) || replace(a.attname::text, chr(34), chr(34) || chr(34)) || chr(34),
                   ', ' ORDER BY k.ord
                 )
            INTO idx_cols
            FROM pg_index i
            JOIN pg_class ic ON ic.oid = i.indexrelid
            CROSS JOIN LATERAL unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
            JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
           WHERE ic.relname = idx_name AND i.indrelid = tbl AND k.ord <= i.indnkeyatts;

          RAISE EXCEPTION 'threadline: #{qualified} has no primary key, so its audit rows could not be told apart. Declare one with the primary_key: option.'
            USING DETAIL = format('The unique index %I could be used instead.', idx_name),
                  HINT = 'Add to config/config.exs: config :threadline, :trigger_capture, tables: %{' || chr(34) || '#{config_key}' || chr(34) || ' => [primary_key: [' || idx_cols || ']]}, then run: mix threadline.gen.triggers --tables #{config_key}';
        ELSE
          RAISE EXCEPTION 'threadline: #{qualified} has no primary key, so its audit rows could not be told apart. Declare one with the primary_key: option.'
            USING DETAIL = 'No unique index over NOT NULL columns qualifies.',
                  HINT = 'Create a unique index over NOT NULL columns first. Then add to config/config.exs: config :threadline, :trigger_capture, tables: %{' || chr(34) || '#{config_key}' || chr(34) || ' => [primary_key: [' || chr(34) || 'column_name' || chr(34) || ']]}, then run: mix threadline.gen.triggers --tables #{config_key}';
        END IF;
      END IF;

    #{key_type_check_sql(qualified)}
    #{redaction_check}
      SELECT string_agg(quote_literal(k), ', ' ORDER BY ord)
        INTO args
        FROM unnest(keys) WITH ORDINALITY AS u(k, ord);

      EXECUTE format('#{statement}', coalesce(args, ''));
    END $$;
    """
  end

  # A table with a declared primary_key: override (config-only; see
  # TriggerCaptureConfig). Skips the pg_index primary-key lookup entirely:
  # refuses if the table already has a real primary key (it would be
  # discovered automatically), refuses a declared column that does not
  # exist, and otherwise requires a qualifying unique index whose key set
  # equals the declared set exactly before installing the trigger with the
  # declared columns, in declared order, as its arguments.
  defp override_trigger_block(table_name, function_literal, declared, opts) do
    qualified = Naming.qualified(table_name)
    host_table = StorageSchema.qualified_host_table(table_name)
    statement = create_trigger_statement(table_name, function_literal)
    redacted_columns = Keyword.get(opts, :redacted_columns, [])
    redaction_check = redaction_check_sql(qualified, redacted_columns)
    declared_literal = text_array_sql(declared)

    """
    -- threadline: install the declared primary_key: override for #{qualified}, then install its capture trigger
    DO $$
    DECLARE
      tbl        regclass := to_regclass('#{host_table}');
      declared   text[] := #{declared_literal};
      keys       text[];
      missing    text;
      discovered text;
      idx_name   text;
      idx_detail text;
      col        text;
      coltype    text;
      args       text;
    BEGIN
      IF tbl IS NULL THEN
        RAISE EXCEPTION 'threadline: table #{qualified} does not exist';
      END IF;

      SELECT string_agg(a.attname::text, ', ' ORDER BY k.ord)
        INTO discovered
        FROM pg_index i
        CROSS JOIN LATERAL unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
        JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
       WHERE i.indrelid = tbl AND i.indisprimary AND k.ord <= i.indnkeyatts;

      IF discovered IS NOT NULL THEN
        RAISE EXCEPTION 'threadline: #{qualified} already has a primary key, so primary_key: is not needed'
          USING HINT = 'Remove primary_key: from this table''s :trigger_capture entry in config/config.exs; Threadline discovers (' || discovered || ') automatically.';
      END IF;

      SELECT d
        INTO missing
        FROM unnest(declared) AS d
       WHERE NOT EXISTS (
             SELECT 1 FROM pg_attribute a
              WHERE a.attrelid = tbl AND a.attname = d AND a.attnum > 0 AND NOT a.attisdropped
           )
       LIMIT 1;

      IF missing IS NOT NULL THEN
        RAISE EXCEPTION 'threadline: primary_key: column % of #{qualified} does not exist', missing;
      END IF;

      SELECT ic.relname
        INTO idx_name
        FROM pg_index i
        JOIN pg_class ic ON ic.oid = i.indexrelid
       WHERE i.indrelid = tbl AND #{qualifying_index_predicate()}
         AND NOT EXISTS (
               SELECT 1 FROM unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
               JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
                WHERE k.ord <= i.indnkeyatts AND NOT a.attnotnull
             )
         AND #{override_index_key_set_sql()}
             = (SELECT array_agg(d ORDER BY d) FROM unnest(declared) AS d)
       ORDER BY ic.relname
       LIMIT 1;

      IF idx_name IS NULL THEN
        IF NOT EXISTS (SELECT 1 FROM pg_index i WHERE i.indrelid = tbl AND i.indisunique) THEN
          RAISE EXCEPTION 'threadline: no unique index on #{qualified} matches primary_key: [%]', array_to_string(declared, ', ')
            USING DETAIL = 'no unique index exists',
                  HINT = 'Create a unique index over exactly the declared columns, all NOT NULL, then rerun mix ecto.migrate.';
        END IF;

    #{override_index_mismatch_detail_sql()}
        RAISE EXCEPTION 'threadline: no unique index on #{qualified} matches primary_key: [%]', array_to_string(declared, ', ')
          USING DETAIL = idx_detail,
                HINT = 'Create a unique index over exactly the declared columns, all NOT NULL, then rerun mix ecto.migrate.';
      END IF;

      keys := declared;
    #{key_type_check_sql(qualified)}
    #{redaction_check}
      SELECT string_agg(quote_literal(k), ', ' ORDER BY ord)
        INTO args
        FROM unnest(keys) WITH ORDINALITY AS u(k, ord);

      EXECUTE format('#{statement}', coalesce(args, ''));
    END $$;
    """
  end

  # The sorted key-column-name array of a unique index's first indnkeyatts
  # columns (INCLUDE columns excluded), compared against the sorted declared
  # array for set equality. Shared by the qualifying-index match and the
  # per-index "column-set mismatch" reason below, and reused as-is by
  # Threadline.Health.TriggerCatalog so its override-qualification read can
  # never diverge from the migration's own enforcement.
  @doc false
  @spec override_index_key_set_sql() :: String.t()
  def override_index_key_set_sql do
    """
    (SELECT array_agg(a.attname::text ORDER BY a.attname)
           FROM unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
           JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
          WHERE k.ord <= i.indnkeyatts)
    """
  end

  # Builds idx_detail: one line per unique index on the table, naming its key
  # columns and every reason (of partial, deferrable, expression, nullable
  # column, invalid, column-set mismatch) it does not qualify as the
  # declared override's stand-in. Reuses the caller's already-declared
  # `idx_detail` and `declared` variables.
  defp override_index_mismatch_detail_sql do
    """
      SELECT string_agg(
               ic.relname || ' (' || coalesce(cols.col_list, '') || '): ' || reasons.text,
               '; ' ORDER BY ic.relname
             )
        INTO idx_detail
        FROM pg_index i
        JOIN pg_class ic ON ic.oid = i.indexrelid
        CROSS JOIN LATERAL (
          SELECT string_agg(a.attname::text, ', ' ORDER BY k.ord) AS col_list
            FROM unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
            LEFT JOIN pg_attribute a
              ON a.attrelid = i.indrelid AND a.attnum = k.attnum AND k.attnum <> 0
           WHERE k.ord <= i.indnkeyatts
        ) cols
        CROSS JOIN LATERAL (
          SELECT concat_ws(', ',
                   CASE WHEN i.indpred IS NOT NULL THEN 'partial' END,
                   CASE WHEN NOT i.indimmediate THEN 'deferrable' END,
                   CASE WHEN i.indexprs IS NOT NULL
                          OR EXISTS (
                               SELECT 1 FROM unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
                                WHERE k.ord <= i.indnkeyatts AND k.attnum = 0
                             )
                        THEN 'expression' END,
                   CASE WHEN EXISTS (
                               SELECT 1 FROM unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
                               JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
                                WHERE k.ord <= i.indnkeyatts AND NOT a.attnotnull
                             )
                        THEN 'nullable column' END,
                   CASE WHEN NOT i.indisvalid OR NOT i.indisready THEN 'invalid' END,
                   CASE WHEN #{override_index_key_set_sql()} IS DISTINCT FROM
                             (SELECT array_agg(d ORDER BY d) FROM unnest(declared) AS d)
                        THEN 'column-set mismatch' END
                 ) AS text
        ) reasons
       WHERE i.indrelid = tbl AND i.indisunique;
    """
  end

  # The type-allowlist FOREACH loop shared by the detected-key and
  # override-key branches. Reuses the caller's already-declared `tbl`,
  # `keys`, `col` and `coltype` variables.
  defp key_type_check_sql(qualified) do
    """
      FOREACH col IN ARRAY keys LOOP
        SELECT format_type(a.atttypid, a.atttypmod)
          INTO coltype
          FROM pg_attribute a
         WHERE a.attrelid = tbl AND a.attname = col;

        IF NOT EXISTS (
              WITH RECURSIVE base_type AS (
                SELECT t.oid, t.typtype, t.typbasetype, t.typname
                  FROM pg_attribute a
                  JOIN pg_type t ON t.oid = a.atttypid
                 WHERE a.attrelid = tbl AND a.attname = col
                 UNION ALL
                SELECT t.oid, t.typtype, t.typbasetype, t.typname
                  FROM base_type bt
                  JOIN pg_type t ON t.oid = bt.typbasetype
                 WHERE bt.typtype = 'd'
              )
              SELECT 1 FROM base_type
               WHERE typtype = 'e'
                  OR typname IN ('int2', 'int4', 'int8', 'text', 'varchar', 'bpchar', 'citext', 'uuid', 'date', 'timestamp')
            )
        THEN
          RAISE EXCEPTION 'threadline: primary key column % of #{qualified} has type %, which has no stable text form for audit keys', col, coltype
            USING HINT = 'Supported types: smallint, integer, bigint, text, varchar, char, citext, uuid, date, timestamp without time zone, enum types, and domains over these. Triggers installed by earlier releases keep capturing this table until it is regenerated.';
        END IF;
      END LOOP;
    """
  end

  # Emitted only when the table has redaction rules: a detected
  # primary-key column listed in the table's mask or exclude refuses the
  # migration, naming the first offending column in key order. The literal
  # array is built from the same `exclude ++ mask` list that builds the
  # table's per-table function, so a test can pin that they never drift
  # apart. Reuses the already-declared `col` variable.
  defp redaction_check_sql(_qualified, []), do: ""

  defp redaction_check_sql(qualified, columns) do
    array_literal = text_array_sql(columns)

    """

        SELECT k INTO col
          FROM unnest(keys) WITH ORDINALITY AS u(k, ord)
         WHERE k = ANY(#{array_literal})
         ORDER BY ord
         LIMIT 1;
        IF col IS NOT NULL THEN
          RAISE EXCEPTION 'threadline: primary key column % of #{qualified} is listed in mask or exclude', col
            USING HINT = 'Remove ' || col || ' from this table''s :mask or :exclude in config/config.exs; redacting a key column would erase row identity from the audit trail.';
        END IF;
    """
  end

  defp text_array_sql(columns) do
    inner = Enum.map_join(columns, ", ", &sql_string_literal/1)
    "ARRAY[#{inner}]::text[]"
  end

  defp sql_string_literal(str) do
    escaped = String.replace(str, "'", "''")
    "'#{escaped}'"
  end

  # The boolean conditions a unique index must satisfy before it is even
  # considered as a stand-in primary key: valid, ready, immediate (never
  # deferred), unconditional and non-expression. Shared text so a future
  # `primary_key:` config override match reuses the identical predicate.
  @doc false
  @spec qualifying_index_predicate() :: String.t()
  def qualifying_index_predicate do
    "i.indisunique AND i.indisvalid AND i.indisready AND i.indimmediate AND i.indpred IS NULL AND i.indexprs IS NULL"
  end

  # The literal CREATE OR REPLACE TRIGGER statement text passed as the first
  # argument to format(), with a trailing `(%s)` placeholder for the
  # resolved trigger arguments. Every piece is doubled for single quotes and
  # percent signs before interpolation, even though validated identifiers
  # never contain either — the placeholder itself is appended afterward, so
  # it is never escaped.
  defp create_trigger_statement(table_name, function_literal) do
    trigger_literal =
      table_name
      |> Naming.trigger_name()
      |> StorageSchema.quote_ident()
      |> format_literal()

    host_table =
      table_name
      |> StorageSchema.qualified_host_table()
      |> format_literal()

    fn_literal = format_literal(function_literal)

    "CREATE OR REPLACE TRIGGER #{trigger_literal}\n" <>
      "AFTER INSERT OR UPDATE OR DELETE ON #{host_table}\n" <>
      "FOR EACH ROW EXECUTE FUNCTION #{fn_literal}(%s)"
  end

  defp format_literal(text) do
    text
    |> String.replace("'", "''")
    |> String.replace("%", "%%")
  end
end
