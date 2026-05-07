defmodule Threadline.Capture.TriggerCaptureConfig do
  @moduledoc """
  Shared loader for `config :threadline, :trigger_capture`.

  The normalized table entries returned here are reused by trigger generation
  and drift reconciliation so both surfaces share one validated config truth.
  """

  alias Threadline.Capture.RedactionPolicy

  @type table_entry :: keyword()
  @type tables_map :: %{optional(String.t()) => table_entry()}

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
      {normalize_table_name(table), normalize_table_entry(entry)}
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

  defp normalize_table_entry(entry) when is_map(entry) do
    entry
    |> Enum.into([])
    |> normalize_table_entry()
  end

  defp normalize_table_entry(entry) when is_list(entry) do
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
    normalized
  end

  defp normalize_table_entry(_other) do
    RedactionPolicy.validate!([])
    []
  end

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
