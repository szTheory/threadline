defmodule Threadline.Capture.TriggerCaptureConfig do
  @moduledoc false

  alias Threadline.Capture.RedactionPolicy
  alias Threadline.StorageSchema

  @type table_entry :: keyword()
  @type tables_map :: %{optional(String.t()) => table_entry()}

  # Keys an adopter might reach for instead of primary_key:. Rejected with a
  # message naming the key and suggesting the right one, so a typo fails
  # loudly instead of the override silently never applying.
  @primary_key_near_misses [:primary_keys, :pk, :pkey, :primary]

  @doc """
  Loads and normalizes `config :threadline, :trigger_capture`.

  Accepts an explicit config value for tests; otherwise reads from application
  env. Every table entry is re-validated through
  `Threadline.Capture.RedactionPolicy.validate!/1`.
  """
  @spec load(nil | keyword() | map()) :: tables_map()
  def load(raw_config \\ Application.get_env(:threadline, :trigger_capture)) do
    raw_config
    |> extract_tables()
    |> normalize_tables_map()
  end

  @doc """
  Normalizes the configured `:tables` map into string-keyed keyword entries.
  """
  @spec normalize_tables_map(map()) :: tables_map()
  def normalize_tables_map(map) when is_map(map) do
    Map.new(map, fn {table, entry} ->
      name = normalize_table_name(table)
      {name, normalize_table_entry(name, entry)}
    end)
  end

  def normalize_tables_map(_), do: %{}

  defp extract_tables(nil), do: %{}

  defp extract_tables(config) when is_list(config) do
    Keyword.get(config, :tables, %{})
  end

  defp extract_tables(config) when is_map(config) do
    Map.get(config, :tables, Map.get(config, "tables", %{}))
  end

  defp extract_tables(_), do: %{}

  defp normalize_table_name(name) when is_atom(name), do: Atom.to_string(name)
  defp normalize_table_name(name) when is_binary(name), do: name
  defp normalize_table_name(name), do: to_string(name)

  defp normalize_table_entry(table, entry) when is_map(entry) do
    entry
    |> Enum.into([])
    |> then(&normalize_table_entry(table, &1))
  end

  defp normalize_table_entry(table, entry) when is_list(entry) do
    check_near_miss_keys!(table, entry)

    normalized =
      []
      |> put_if_present(:exclude, normalize_columns(Keyword.get(entry, :exclude, [])))
      |> put_if_present(:mask, normalize_columns(Keyword.get(entry, :mask, [])))
      |> put_if_present(:mask_placeholder, Keyword.get(entry, :mask_placeholder))
      |> put_if_present(:store_changed_from, Keyword.get(entry, :store_changed_from))
      |> put_if_present(
        :except_columns,
        normalize_columns(Keyword.get(entry, :except_columns, []))
      )

    RedactionPolicy.validate!(normalized)

    raw_primary_key = Keyword.get(entry, :primary_key)
    validate_primary_key!(table, raw_primary_key, normalized)

    normalized
    |> put_if_present(:primary_key, normalize_primary_key(raw_primary_key))
  end

  defp normalize_table_entry(_table, _other) do
    RedactionPolicy.validate!([])
    []
  end

  # A near-miss key, such as :pk or :primary_keys, is rejected loudly rather
  # than silently ignored — an entry without :primary_key at all keeps
  # loading exactly as before.
  defp check_near_miss_keys!(table, entry) do
    case Enum.find(@primary_key_near_misses, &Keyword.has_key?(entry, &1)) do
      nil ->
        :ok

      key ->
        raise ArgumentError,
              primary_key_error(
                table,
                "#{inspect(key)} is not a valid option; did you mean primary_key:?"
              )
    end
  end

  # Validates the raw (not yet normalized) :primary_key value: a non-empty
  # list of non-blank, NUL-free, untrimmed-equal, valid identifiers (each
  # at most 63 bytes), with no duplicate after to_string and no overlap
  # with the table's own :mask or :exclude. Run on the raw value, before
  # normalize_columns/1, which silently dedups and drops blanks and would
  # hide exactly these errors.
  defp validate_primary_key!(table, raw, normalized) do
    case raw do
      nil ->
        :ok

      v when is_binary(v) or is_atom(v) ->
        raise ArgumentError,
              primary_key_error(
                table,
                "must be a list, e.g. #{inspect([to_string(v)])}, got: #{inspect(v)}"
              )

      v when not is_list(v) ->
        raise ArgumentError, primary_key_error(table, "must be a list, got: #{inspect(v)}")

      [] ->
        raise ArgumentError, primary_key_error(table, "must not be an empty list")

      list ->
        names = Enum.map(list, &validate_primary_key_name!(table, &1))
        check_primary_key_duplicates!(table, names)
        check_primary_key_redaction_overlap!(table, names, normalized)
        :ok
    end
  end

  defp validate_primary_key_name!(table, name) when is_binary(name) or is_atom(name) do
    str = to_string(name)

    cond do
      str == "" ->
        raise ArgumentError, primary_key_error(table, "must not include an empty name")

      String.contains?(str, <<0>>) ->
        raise ArgumentError,
              primary_key_error(table, "must not contain NUL, got: #{inspect(name)}")

      String.trim(str) != str ->
        raise ArgumentError,
              primary_key_error(
                table,
                "must not have leading or trailing whitespace, got: #{inspect(name)}"
              )

      true ->
        try do
          StorageSchema.validate_identifier!(str, :primary_key_column)
        rescue
          e in ArgumentError ->
            reraise ArgumentError,
                    primary_key_error(
                      table,
                      Exception.message(e) <>
                        ". Known limitation: primary_key: only accepts bare identifiers " <>
                        "(letters, digits, underscore, not starting with a digit); a column " <>
                        "that requires double-quoting in PostgreSQL (mixed case, spaces, " <>
                        "punctuation, or a leading digit) cannot be declared here even though " <>
                        "the same name would be captured correctly if it were auto-detected " <>
                        "from a real primary key. See guides/configuration-and-commands.md."
                    ),
                    __STACKTRACE__
        end
    end
  end

  defp validate_primary_key_name!(table, name) do
    raise ArgumentError,
          primary_key_error(table, "column names must be strings or atoms, got: #{inspect(name)}")
  end

  defp check_primary_key_duplicates!(table, names) do
    duplicate =
      names
      |> Enum.frequencies()
      |> Enum.find_value(fn {name, count} -> if count > 1, do: name end)

    if duplicate do
      raise ArgumentError, primary_key_error(table, "duplicate column #{inspect(duplicate)}")
    end
  end

  defp check_primary_key_redaction_overlap!(table, names, normalized) do
    redacted =
      MapSet.new(Keyword.get(normalized, :mask, []) ++ Keyword.get(normalized, :exclude, []))

    case Enum.find(names, &MapSet.member?(redacted, &1)) do
      nil ->
        :ok

      column ->
        raise ArgumentError,
              primary_key_error(
                table,
                "column #{inspect(column)} is also listed in mask or exclude"
              )
    end
  end

  defp primary_key_error(table, detail),
    do: "tables " <> inspect(table) <> ": primary_key " <> detail

  defp normalize_primary_key(nil), do: nil
  defp normalize_primary_key(list) when is_list(list), do: Enum.map(list, &to_string/1)

  defp normalize_columns(list) when is_list(list) do
    list
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp normalize_columns(_), do: []

  defp put_if_present(kw, _key, nil), do: kw
  defp put_if_present(kw, _key, []), do: kw
  defp put_if_present(kw, _key, false), do: kw
  defp put_if_present(kw, key, value), do: Keyword.put(kw, key, value)
end
