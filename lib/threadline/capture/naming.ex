defmodule Threadline.Capture.Naming do
  @moduledoc false

  # The single owner of every identifier Threadline derives from a host table.
  #
  # These names are frozen: the generator writes them as literals into
  # migrations the host owns, so a change here renames triggers and functions
  # in installs that already exist. PostgreSQL truncates identifiers longer
  # than 63 bytes, so every name below is capped at 63 bytes and measured in
  # bytes, never characters.
  #
  # hash12 is the first 12 lowercase hex characters of SHA-256 over the exact
  # bytes of "schema.table" (no case folding; a bare table is public). An
  # operator can reproduce it in SQL:
  #
  #     SELECT left(encode(sha256(convert_to('billing.invoices', 'UTF8')), 'hex'), 12);
  #
  # Trigger names are never hashed. PostgreSQL scopes a trigger name to its
  # table, so two tables may share one, and installs that already exist carry
  # the legacy name cut to 63 bytes. Keeping that exact name means a
  # regenerated migration replaces the trigger instead of adding a second one.
  #
  # Capture function names live in one schema, so they must be unique across
  # tables. A public table of at most 36 bytes keeps its legacy name; every
  # other table gets a 23-byte readable stem plus "_" and its hash12:
  #
  #   * legacy vs legacy: distinct, because public table names are distinct;
  #   * hashed vs hashed: distinct unless two tables collide on 48 bits of
  #     SHA-256, about 1.8e-7 at 10,000 tables;
  #   * legacy vs hashed: a legacy name never ends in "_" plus 12 lowercase
  #     hex characters, because such tables are hashed instead.
  #
  # A trigger migration keeps today's name, threadline_triggers_<suffixes>[_n],
  # whenever it fits in 63 bytes. Otherwise the readable part is cut and the
  # name ends in "_" plus hash12 over the sorted, de-duplicated qualified names
  # joined by commas, so the hash does not depend on the order of the tables.

  alias Threadline.StorageSchema

  # PostgreSQL's NAMEDATALEN - 1.
  @max_identifier_bytes 63
  @trigger_prefix "threadline_audit_"
  # 27 bytes.
  @function_prefix "threadline_capture_changes_"
  # 20 bytes.
  @migration_prefix "threadline_triggers_"
  # "_" plus hash12.
  @hash_segment_bytes 13
  # 27 + 36 = 63: the longest public table that keeps its legacy function name.
  @legacy_table_max 36
  # 27 + 23 + 1 + 12 = 63.
  @stem_max 23
  # A source, not a compiled regex, so the module compiles on OTP releases
  # that refuse regexes in module attributes.
  @hash_tail "_[0-9a-f]{12}\\z"

  @type pair :: %{schema: String.t(), table: String.t()}
  @type table :: String.t() | pair()

  @doc false
  @spec hash12(binary()) :: String.t()
  def hash12(input) when is_binary(input) do
    :crypto.hash(:sha256, input) |> Base.encode16(case: :lower) |> binary_part(0, 12)
  end

  # A map is normally the result of StorageSchema.parse_table_identifier/1.
  # Its fields are validated again anyway, because the names derived here are
  # written into host migrations and cannot be changed afterwards: an invalid
  # or oversized field raises instead of producing an invalid name. Callers
  # holding a raw string pass the string, which is parsed and validated here.
  @doc false
  @spec pair(table()) :: pair()
  def pair(%{schema: schema, table: table}) do
    %{
      schema: StorageSchema.validate_identifier!(schema, :host_schema),
      table: StorageSchema.validate_identifier!(table, :host_table)
    }
  end

  def pair(value) when is_binary(value), do: StorageSchema.parse_table_identifier(value)

  @doc false
  @spec qualified(table()) :: String.t()
  def qualified(table) do
    %{schema: schema, table: name} = pair(table)
    schema <> "." <> name
  end

  @doc """
  The table as `mix threadline.gen.triggers --tables` and a `:trigger_capture`
  config key take it: bare for `public`, `schema.table` otherwise. Shared by
  `TriggerSQL.function_owner_guard/2` and `PrimaryKeySQL`'s no-primary-key
  HINT, so both modules print the same token for one table.
  """
  @spec table_token(table()) :: String.t()
  def table_token(table) do
    case pair(table) do
      %{schema: "public", table: name} -> name
      %{schema: schema, table: name} -> schema <> "." <> name
    end
  end

  @doc false
  @spec suffix(table()) :: String.t()
  def suffix(table) do
    case pair(table) do
      %{schema: "public", table: name} -> name
      %{schema: schema, table: name} -> schema <> "_" <> name
    end
  end

  @doc false
  @spec trigger_name(table()) :: String.t()
  def trigger_name(table), do: cut(@trigger_prefix <> suffix(table), @max_identifier_bytes)

  @doc false
  @spec legacy_function_name(table()) :: String.t()
  def legacy_function_name(table),
    do: cut(@function_prefix <> suffix(table), @max_identifier_bytes)

  @doc false
  @spec function_name(table()) :: String.t()
  def function_name(table) do
    pair = pair(table)

    if legacy_function?(pair) do
      @function_prefix <> pair.table
    else
      @function_prefix <> cut(suffix(pair), @stem_max) <> "_" <> hash12(qualified(pair))
    end
  end

  @doc false
  @spec migration_name([table()], pos_integer()) :: {String.t(), String.t()}
  def migration_name(tables, ordinal)
      when is_list(tables) and tables != [] and is_integer(ordinal) and ordinal >= 1 do
    pairs = Enum.map(tables, &pair/1)
    suffixes = Enum.map(pairs, &suffix/1)
    ord_parts = if ordinal == 1, do: [], else: [Integer.to_string(ordinal)]
    candidate = @migration_prefix <> Enum.join(suffixes ++ ord_parts, "_")

    if byte_size(candidate) <= @max_identifier_bytes do
      {candidate, module_for(suffixes ++ ord_parts)}
    else
      hash =
        pairs
        |> Enum.map(&qualified/1)
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.join(",")
        |> hash12()

      ord = Enum.map_join(ord_parts, "", &("_" <> &1))

      room =
        @max_identifier_bytes - byte_size(@migration_prefix) - @hash_segment_bytes -
          byte_size(ord)

      readable = suffixes |> Enum.join("_") |> cut(room) |> String.trim_trailing("_")

      {@migration_prefix <> readable <> "_" <> hash <> ord,
       module_for([readable, hash] ++ ord_parts)}
    end
  end

  defp module_for(parts),
    do: "ThreadlineTriggers" <> Enum.map_join(parts, "", &Macro.camelize/1)

  defp legacy_function?(%{schema: "public", table: name}) do
    byte_size(name) <= @legacy_table_max and
      not Regex.match?(Regex.compile!(@hash_tail), name)
  end

  defp legacy_function?(_pair), do: false

  defp cut(string, max), do: binary_part(string, 0, min(max, byte_size(string)))
end
