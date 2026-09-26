defmodule Threadline.Health.TriggerCatalog do
  @moduledoc false

  alias Ecto.Adapters.SQL
  alias Threadline.Capture.PrimaryKeySQL

  # Kept in lockstep with Threadline.Capture.Naming's prefixes by a test pin;
  # the underscore is escaped for LIKE, never interpreted as a wildcard.
  @trigger_name_like "threadline\\_audit\\_%"
  @function_name_like "threadline\\_capture\\_changes\\_%"

  @doc false
  @spec trigger_name_like() :: String.t()
  def trigger_name_like, do: @trigger_name_like

  @doc false
  @spec function_name_like() :: String.t()
  def function_name_like, do: @function_name_like

  @doc false
  @spec threadline_triggers(module()) :: [map()]
  def threadline_triggers(repo) do
    sql = """
    SELECT n.nspname, c.relname, c.oid::bigint, t.tgname, t.tgenabled::text,
           t.tgnargs, t.tgargs, pn.nspname, p.proname
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_proc p ON p.oid = t.tgfoid
    JOIN pg_namespace pn ON pn.oid = p.pronamespace
    WHERE #{identification_predicate()}
    """

    %{rows: rows} = SQL.query!(repo, sql, [])

    Enum.map(rows, &row_to_map/1)
  end

  # The single definition of "this trigger is Threadline's", shared by
  # threadline_triggers/1 and the relid subquery below so the union of
  # conditions is written once. Assumes aliases t (pg_trigger), c (pg_class),
  # n (pg_namespace of c) and p (pg_proc) are in scope.
  defp identification_predicate do
    """
    NOT t.tgisinternal
      AND t.tgparentid = 0
      AND c.relkind IN ('r', 'p')
      AND n.nspname <> 'information_schema'
      AND n.nspname NOT LIKE 'pg\\_%' ESCAPE '\\'
      AND (
        t.tgname LIKE '#{@trigger_name_like}' ESCAPE '\\'
        OR p.proname = 'threadline_capture_changes'
        OR p.proname LIKE '#{@function_name_like}' ESCAPE '\\'
      )
    """
  end

  # The set of relids carrying at least one Threadline trigger, as a scalar
  # subquery text fragment for use in `... IN (...)`.
  defp threadline_relids_sql do
    """
    (
      SELECT c.oid
      FROM pg_trigger t
      JOIN pg_class c ON c.oid = t.tgrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      JOIN pg_proc p ON p.oid = t.tgfoid
      WHERE #{identification_predicate()}
    )
    """
  end

  @doc false
  @spec primary_keys(module()) :: %{integer() => [String.t()]}
  def primary_keys(repo) do
    sql = """
    SELECT i.indrelid::bigint, array_agg(a.attname::text ORDER BY k.ord)
    FROM pg_index i
    CROSS JOIN LATERAL unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
    JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
    WHERE i.indisprimary
      AND k.ord <= i.indnkeyatts
      AND i.indrelid IN #{threadline_relids_sql()}
    GROUP BY i.indrelid
    """

    %{rows: rows} = SQL.query!(repo, sql, [])

    Map.new(rows, fn [relid, cols] -> {relid, cols} end)
  end

  @doc false
  @spec live_columns(module()) :: %{integer() => MapSet.t(String.t())}
  def live_columns(repo) do
    sql = """
    SELECT a.attrelid::bigint, array_agg(a.attname::text)
    FROM pg_attribute a
    WHERE a.attnum > 0
      AND NOT a.attisdropped
      AND a.attrelid IN #{threadline_relids_sql()}
    GROUP BY a.attrelid
    """

    %{rows: rows} = SQL.query!(repo, sql, [])

    Map.new(rows, fn [relid, cols] -> {relid, MapSet.new(cols)} end)
  end

  @doc """
  Whether a unique index on `relid` qualifies as the stand-in for a
  `primary_key:` override declaring `declared`.

  Calls `PrimaryKeySQL.qualifying_index_predicate/0` and
  `PrimaryKeySQL.override_index_key_set_sql/0` directly, so this can never
  diverge from the migration's own enforcement. `declared` is passed as a
  `$2::text[]` bind, never interpolated.
  """
  @spec qualifying_override_index?(module(), integer(), [String.t()]) :: boolean()
  def qualifying_override_index?(repo, relid, declared) do
    sql = """
    SELECT EXISTS (
      SELECT 1
      FROM pg_index i
      WHERE i.indrelid = $1
        AND #{PrimaryKeySQL.qualifying_index_predicate()}
        AND NOT EXISTS (
              SELECT 1 FROM unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
               WHERE k.ord <= i.indnkeyatts AND k.attnum = 0
            )
        AND NOT EXISTS (
              SELECT 1 FROM unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
              JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
               WHERE k.ord <= i.indnkeyatts AND NOT a.attnotnull
            )
        AND #{PrimaryKeySQL.override_index_key_set_sql()}
            = (SELECT array_agg(d ORDER BY d) FROM unnest($2::text[]) AS d)
    )
    """

    %{rows: [[result]]} = SQL.query!(repo, sql, [relid, declared])

    result
  end

  @doc """
  Per-table capture functions referenced by Threadline triggers on more
  than one table, across the whole catalog — deliberately unfiltered by
  schema here; `TriggerFindings` filters the resulting findings by table
  schema afterward, since sharing a function can span schemas.

  Only matches `function_name_like/0` — the global default
  `threadline_capture_changes` is shared by design and is never matched here.
  `t.tgparentid = 0` excludes the trigger PostgreSQL clones onto each
  partition of a partitioned table, so a partitioned table's own per-table
  function is never reported as shared with its partitions.

  Returns one entry per shared function: `%{function_schema:, function:,
  tables: [{schema, table}]}`, tables sorted.
  """
  @spec shared_functions(module()) :: [
          %{function_schema: String.t(), function: String.t(), tables: [{String.t(), String.t()}]}
        ]
  def shared_functions(repo) do
    sql = """
    SELECT pn.nspname, p.proname,
           array_agg(DISTINCT n.nspname || '.' || c.relname ORDER BY n.nspname || '.' || c.relname)
    FROM pg_trigger t
    JOIN pg_proc p ON p.oid = t.tgfoid
    JOIN pg_namespace pn ON pn.oid = p.pronamespace
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE t.tgparentid = 0
      AND NOT t.tgisinternal
      AND p.proname LIKE '#{@function_name_like}' ESCAPE '\\'
    GROUP BY pn.nspname, p.proname
    HAVING count(DISTINCT t.tgrelid) > 1
    """

    %{rows: rows} = SQL.query!(repo, sql, [])

    Enum.map(rows, fn [function_schema, function, qualified_tables] ->
      %{
        function_schema: function_schema,
        function: function,
        tables: Enum.map(qualified_tables, &split_qualified/1)
      }
    end)
  end

  defp split_qualified(qualified) do
    [schema, table] = String.split(qualified, ".", parts: 2)
    {schema, table}
  end

  defp row_to_map([schema, table, relid, trigger, enabled, nargs, args, function_schema, function]) do
    %{
      schema: schema,
      table: table,
      relid: relid,
      trigger: trigger,
      enabled: enabled,
      nargs: nargs,
      args: decode_tgargs(args || <<>>),
      function_schema: function_schema,
      function: function
    }
  end

  @doc false
  @spec decode_tgargs(binary()) :: [String.t()]
  def decode_tgargs(binary) when is_binary(binary) do
    binary
    |> :binary.split(<<0>>, [:global])
    |> drop_trailing_empty()
  end

  defp drop_trailing_empty([]), do: []

  defp drop_trailing_empty(list) do
    case List.last(list) do
      "" -> List.delete_at(list, -1)
      _ -> list
    end
  end
end
