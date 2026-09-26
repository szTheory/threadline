defmodule Threadline.Query.RowKey do
  @moduledoc false

  # Resolves a schema module's key columns, validates a caller-supplied id
  # argument against them, and asks PostgreSQL to render the comparison value
  # exactly as the capture trigger stored it.
  #
  # The id argument accepts a bare scalar (single-column tables only), or a
  # map or keyword list of every key field, atom- or string-keyed, in any
  # order. Caller-supplied string keys are never turned into atoms: they are
  # compared, as strings, against the resolved field set.

  alias Ecto.Adapters.SQL
  alias Threadline.Capture.{Naming, TriggerCaptureConfig}
  alias Threadline.StorageSchema

  @type resolved :: %{
          schema: module(),
          table_schema: String.t(),
          table_name: String.t(),
          fields: [{atom(), String.t()}]
        }

  @type triple :: {atom(), String.t(), term()}

  # Structs that are legitimate scalar values for a single-column key (dates,
  # times, and arbitrary-precision decimals), as opposed to a struct someone
  # accidentally passed instead of a map/keyword list of key fields. Proven
  # by row_key_types_test.exs (Date, NaiveDateTime round trips).
  @scalar_key_structs [Date, NaiveDateTime, DateTime, Time, Decimal]

  # Fixed Ecto-type -> PostgreSQL-cast-type map used only when the catalog has
  # no live entry for a key column (dropped/renamed host table or column).
  # The one known-inexact case is char(n): the fallback renders it as text,
  # which drops the stored blank-padding.
  @fallback_types %{
    Ecto.UUID => "uuid",
    id: "bigint",
    integer: "bigint",
    binary_id: "uuid",
    string: "text",
    date: "date",
    naive_datetime: "timestamp",
    naive_datetime_usec: "timestamp"
  }

  @doc """
  Resolves `schema_module`'s key columns in key order.

  Resolution order: a `primary_key:` override for the qualified table, else
  `__schema__(:primary_key)` mapped through `field_source`, else raise.
  """
  @spec resolve!(module()) :: resolved()
  def resolve!(schema_module) do
    table = schema_module.__schema__(:source)
    table_schema = schema_module.__schema__(:prefix) || "public"
    qualified = qualified_text(table_schema, table)

    fields =
      case override_primary_key(qualified) do
        nil ->
          primary_key_fields!(schema_module, qualified)

        declared ->
          override_fields!(schema_module, declared)
      end

    %{schema: schema_module, table_schema: table_schema, table_name: table, fields: fields}
  end

  # Maps each declared `primary_key:` override column back to the schema
  # field whose `field_source` equals it, in declared order. A declared
  # column with no mapped field raises, naming the column and the schema:
  # the schema cannot address that key at all.
  defp override_fields!(schema_module, declared_columns) do
    field_by_source =
      Map.new(schema_module.__schema__(:fields), fn field ->
        {to_string(schema_module.__schema__(:field_source, field)), field}
      end)

    Enum.map(declared_columns, fn column ->
      case Map.fetch(field_by_source, column) do
        {:ok, field} ->
          {field, column}

        :error ->
          raise ArgumentError,
                "no field of #{inspect(schema_module)} maps to primary_key: override " <>
                  "column #{inspect(column)}"
      end
    end)
  end

  defp primary_key_fields!(schema_module, qualified) do
    case schema_module.__schema__(:primary_key) do
      [] ->
        raise ArgumentError,
              "#{inspect(schema_module)} (#{qualified}) has no primary key and no " <>
                "primary_key: override configured. Add one via " <>
                "`config :threadline, :trigger_capture, tables: %{\"#{qualified}\" => " <>
                "[primary_key: [...]]}` in config/config.exs."

      pk_fields ->
        Enum.map(pk_fields, fn field ->
          {field, to_string(schema_module.__schema__(:field_source, field))}
        end)
    end
  end

  defp override_primary_key(qualified) do
    Enum.find_value(TriggerCaptureConfig.load(), fn {table, entry} ->
      if Naming.qualified(table) == qualified, do: Keyword.get(entry, :primary_key)
    end)
  end

  @doc """
  Validates `id` against `resolved`'s key fields and returns an ordered list
  of `{field, column, value}` triples, in resolved key order.

  Accepts a bare scalar (single-column tables only), or a map or keyword
  list naming every key field, atom- or string-keyed, in any order. A
  caller-supplied string key is never turned into an atom: it is compared,
  as a string, against the resolved field set. A missing, extra, or
  misnamed key, a nil value, an empty map/keyword list, a scalar for a
  composite table, or a loaded struct all raise `ArgumentError`.
  """
  @spec normalize!(resolved(), term()) :: [triple()]
  def normalize!(%{schema: schema, fields: fields}, id) when is_struct(id, schema) do
    raise ArgumentError,
          "a loaded #{inspect(schema)} struct is not accepted as a row key; pass a map " <>
            "or keyword list with #{inspect(field_names(fields))}"
  end

  def normalize!(%{fields: fields, schema: schema} = resolved, id)
      when is_map(id) and not is_struct(id) do
    normalize_key_map!(resolved, fields, schema, id, Map.keys(id))
  end

  def normalize!(%{fields: fields, schema: schema} = resolved, id) when is_list(id) do
    if Keyword.keyword?(id) do
      normalize_key_map!(resolved, fields, schema, Map.new(id), Keyword.keys(id))
    else
      raise ArgumentError,
            "expected keys #{inspect(field_names(fields))} for #{inspect(schema)}, " <>
              "got: #{inspect(id)}"
    end
  end

  def normalize!(%{fields: [{field, _column}], schema: schema}, nil) do
    raise ArgumentError,
          "expected a value for key field #{inspect(field)} of #{inspect(schema)}, got nil"
  end

  # A struct other than a matching-schema struct (rejected above) or one of
  # the legitimate scalar key value types (Date, NaiveDateTime, DateTime,
  # Time, Decimal — already proven by row_key_types_test.exs) reaching a
  # single-column table. Without this clause the struct falls through to the
  # scalar clause below and is only rejected later, deep in `dump_value!/4`,
  # with a generic "cannot cast" message instead of this purpose-built one.
  def normalize!(%{fields: [{_field, _column}] = fields, schema: schema}, %mod{} = id)
      when mod not in @scalar_key_structs do
    raise ArgumentError,
          "a struct is not accepted as a row key; pass a map or keyword list " <>
            "with #{inspect(field_names(fields))}, or a plain scalar value " <>
            "(got #{inspect(id)} for #{inspect(schema)})"
  end

  def normalize!(%{fields: [{field, column}]}, id) do
    [{field, column, id}]
  end

  def normalize!(%{fields: fields, schema: schema}, _id) do
    raise ArgumentError,
          "expected keys #{inspect(field_names(fields))} for #{inspect(schema)}, got a " <>
            "single value; pass a map or keyword list with every key field"
  end

  defp field_names(fields), do: Enum.map(fields, &elem(&1, 0))

  defp normalize_key_map!(_resolved, fields, schema, map, given_keys) do
    validate_key_set!(fields, schema, given_keys)

    Enum.map(fields, fn {field, column} ->
      {field, column, fetch_field!(schema, field, map)}
    end)
  end

  defp validate_key_set!(fields, schema, given_keys) do
    expected = MapSet.new(fields, fn {field, _column} -> Atom.to_string(field) end)
    normalized_given = Enum.map(given_keys, &key_to_string/1)
    given = MapSet.new(normalized_given)

    # `given` collapses distinct raw keys that normalize to the same field
    # name (e.g. `:tenant_id` and `"tenant_id"`, or a repeated keyword-list
    # key). Comparing set membership alone would silently accept such a
    # duplicate as long as the resulting *set* still matches the expected
    # fields 1:1 — even though one of the caller's values is then discarded
    # with no signal. Catching the length mismatch here treats any such
    # duplicate as the same extra/misnamed-key case that must raise.
    duplicated? = length(normalized_given) != MapSet.size(given)

    unless MapSet.equal?(expected, given) and not duplicated? do
      raise ArgumentError,
            "expected keys #{inspect(field_names(fields))} for #{inspect(schema)}, " <>
              "got #{inspect(given_keys)}"
    end
  end

  defp key_to_string(key) when is_atom(key), do: Atom.to_string(key)
  defp key_to_string(key) when is_binary(key), do: key
  defp key_to_string(key), do: inspect(key)

  defp fetch_field!(schema, field, map) do
    case Map.fetch(map, field) do
      {:ok, value} ->
        reject_nil!(field, schema, value)

      :error ->
        case Map.fetch(map, Atom.to_string(field)) do
          {:ok, value} -> reject_nil!(field, schema, value)
          :error -> raise ArgumentError, "expected key #{inspect(field)} for #{inspect(schema)}"
        end
    end
  end

  defp reject_nil!(field, schema, nil) do
    raise ArgumentError,
          "expected a value for key field #{inspect(field)} of #{inspect(schema)}, got nil"
  end

  defp reject_nil!(_field, _schema, value), do: value

  @doc """
  Looks up the PostgreSQL cast type and base type name for each column,
  reading the catalog once per call (no cross-call cache): an adopter can
  drop/retype a key column and the test suite drops and recreates
  same-named tables with different key types between tests.

  Falls back to a fixed Ecto-type map when the catalog has no live entry for
  a column (dropped/renamed host table), so history stays readable after the
  host table is gone. Raises only when the catalog cannot type the column
  AND the field's Ecto type has no built-in fallback.
  """
  @spec column_types!(module(), resolved(), [String.t()]) :: %{
          String.t() => {String.t(), String.t()}
        }
  def column_types!(repo, resolved, columns) when is_list(columns) do
    host_table = qualified_host_table(resolved)

    # Two round trips are required, not a stylistic choice: CAST($n AS <type>)
    # needs `<type>` to be a compile-time SQL-grammar token, so PostgreSQL
    # cannot take it from a subquery or a bind parameter in the same
    # statement as the render step (render!/3). This catalog lookup runs
    # first; render!/3 splices its result, unquoted, into the second
    # statement's literal SQL text.
    sql = """
    WITH RECURSIVE base AS (
      SELECT a.attname AS attname,
             a.atttypid AS atttypid,
             a.atttypmod AS atttypmod,
             t.typtype AS typtype,
             t.typbasetype AS typbasetype,
             t.typname AS typname
        FROM pg_attribute a
        JOIN pg_type t ON t.oid = a.atttypid
       WHERE a.attrelid = to_regclass($1)
         AND a.attname = ANY($2)
         AND a.attnum > 0
         AND NOT a.attisdropped
       UNION ALL
      SELECT base.attname, base.atttypid, base.atttypmod, t.typtype, t.typbasetype, t.typname
        FROM base
        JOIN pg_type t ON t.oid = base.typbasetype
       WHERE base.typtype = 'd'
    )
    SELECT attname, format_type(atttypid, atttypmod), typname
      FROM base
     WHERE typtype <> 'd'
    """

    %{rows: rows} = SQL.query!(repo, sql, [host_table, columns])

    found =
      Map.new(rows, fn [name, cast_type, base_type] ->
        {name, {validate_type_text!(cast_type), base_type}}
      end)

    Map.new(columns, fn column ->
      {column, Map.get(found, column) || fallback_type!(resolved, column)}
    end)
  end

  defp qualified_host_table(%{table_schema: table_schema, table_name: table_name}) do
    StorageSchema.qualified_host_table(qualified_text(table_schema, table_name))
  end

  defp qualified_text(table_schema, table), do: "#{table_schema}.#{table}"

  defp fallback_type!(%{schema: schema, fields: fields} = resolved, column) do
    case Enum.find(fields, fn {_field, col} -> col == column end) do
      {field, ^column} ->
        ecto_type = schema.__schema__(:type, field)

        case fallback_type_text(ecto_type) do
          nil ->
            raise ArgumentError,
                  "cannot determine the key type of #{inspect(field)} (#{inspect(ecto_type)}) " <>
                    "for #{qualified_text(resolved.table_schema, resolved.table_name)}: the " <>
                    "table or column is not in the database and the Ecto type has no built-in mapping"

          type_text ->
            {type_text, type_text}
        end

      nil ->
        raise ArgumentError,
              "no key field of #{inspect(schema)} maps to column #{inspect(column)}"
    end
  end

  defp fallback_type_text({:parameterized, {Ecto.Enum, _}}), do: "text"
  defp fallback_type_text({:parameterized, Ecto.Enum, _}), do: "text"
  defp fallback_type_text(Ecto.Enum), do: "text"
  defp fallback_type_text(type), do: Map.get(@fallback_types, type)

  # `format_type/2`'s output grammar: a bare, possibly multi-word identifier
  # (e.g. "bigint", "timestamp without time zone", "character varying") or a
  # double-quoted identifier (internal `"` doubled, per PostgreSQL quoting),
  # optionally schema-qualified, optionally followed by a typmod
  # (`(<digits>[,<digits>])`) and/or one or more `[]` array markers. This is
  # a positive allowlist of that finite grammar, not a denylist of a handful
  # of dangerous substrings: an unexpected catalog value fails closed
  # instead of only failing on specific substrings. `format_type`
  # itself double-quotes and escapes any type/domain/enum name that is not a
  # bare unquoted identifier, so a maliciously-named type still cannot break
  # out of the `CAST(... AS <type>)` position this value is spliced into.
  @type_text_pattern ~r/
    \A
    (?: [\p{L}_][\p{L}\p{N}_\s]* | "(?:[^"]|"")+" )
    (?: \. (?: [\p{L}_][\p{L}\p{N}_\s]* | "(?:[^"]|"")+" ) )?
    (?: \( \d+ (?: , \d+ )? \) )?
    (?: \[\] )*
    \z
  /xu

  defp validate_type_text!(type_text) do
    if Regex.match?(@type_text_pattern, type_text) do
      type_text
    else
      raise ArgumentError, "refusing unsafe PostgreSQL type text: #{inspect(type_text)}"
    end
  end

  @doc """
  Casts and dumps each triple's value through the schema field's Ecto type,
  then asks PostgreSQL to render the comparison value exactly as the capture
  trigger stored it (`to_jsonb(CAST($n AS <type>)) #>> '{}'`).
  """
  @spec render!(module(), resolved(), [triple()]) :: map()
  def render!(repo, resolved, triples) do
    columns = Enum.map(triples, fn {_field, column, _value} -> column end)
    types = column_types!(repo, resolved, columns)

    {pairs, params, _n} =
      Enum.reduce(triples, {[], [], 1}, fn {field, column, value}, {pairs, params, n} ->
        {cast_type, base_type} = Map.fetch!(types, column)
        dumped = dump_value!(resolved.schema, field, value, base_type)

        pair = "#{sql_string_literal(column)}, to_jsonb(CAST($#{n} AS #{cast_type})) #>> '{}'"
        {[pair | pairs], [dumped | params], n + 1}
      end)

    sql = "SELECT jsonb_build_object(#{pairs |> Enum.reverse() |> Enum.join(", ")})"

    %{rows: [[rendered]]} = SQL.query!(repo, sql, Enum.reverse(params))
    rendered
  end

  defp dump_value!(schema, field, value, base_type) do
    ecto_type = schema.__schema__(:type, field)

    with {:ok, cast_value} <- Ecto.Type.cast(ecto_type, value),
         {:ok, dumped} <- Ecto.Type.dump(ecto_type, cast_value),
         {:ok, ready} <- maybe_dump_uuid(dumped, base_type) do
      ready
    else
      :error ->
        raise ArgumentError,
              "cannot cast #{inspect(value)} to key field #{inspect(field)} of #{inspect(schema)}"
    end
  end

  # `:binary_id` schema fields pass through Ecto.Type.dump/2 unchanged (the
  # adapter, not Ecto.Type, normally does the string<->16-byte conversion for
  # a typed schema query); an `Ecto.UUID` field already dumps to the 16-byte
  # form itself. Raw parameterized SQL bypasses the adapter's conversion, so
  # it is done here — but only when the dumped value is not already the
  # 16-byte form, or `Ecto.UUID.dump/1` would reject its own output as an
  # invalid (36-byte) UUID string. A value that is not a valid UUID (canonical
  # string or 16-byte binary) fails Ecto.UUID.dump/1 and is treated as an
  # uncastable key value, not a raw Postgrex encoding crash.
  defp maybe_dump_uuid(<<_::128>> = value, "uuid"), do: {:ok, value}
  defp maybe_dump_uuid(value, "uuid") when is_binary(value), do: Ecto.UUID.dump(value)
  defp maybe_dump_uuid(value, _base_type), do: {:ok, value}

  # Escapes a column name for use as a jsonb object key string literal,
  # mirroring the escaping `Threadline.Capture.PrimaryKeySQL` already uses
  # for SQL string literals.
  defp sql_string_literal(str) do
    escaped = String.replace(str, "'", "''")
    "'#{escaped}'"
  end

  @doc """
  Resolves, validates, and renders `id` for `schema_module`, returning the
  where-clause payload `history/3`, `row_history_query/3`, and `as_of/4`
  compare against `audit_changes.table_pk`.
  """
  @spec match!(module(), term(), module()) :: %{
          table_schema: String.t(),
          table_name: String.t(),
          table_pk: map()
        }
  def match!(schema_module, id, repo) do
    resolved = resolve!(schema_module)
    triples = normalize!(resolved, id)
    rendered = render!(repo, resolved, triples)

    %{table_schema: resolved.table_schema, table_name: resolved.table_name, table_pk: rendered}
  end
end
