defmodule Threadline.Capture.RedactionPolicy do
  @moduledoc """
  Validates trigger redaction options at codegen time (Mix / `TriggerSQL`).

  Excludes and masks are mutually exclusive per column: a column cannot appear
  in both `:exclude` and `:mask`.
  """

  @max_placeholder_length 200

  @doc "Default JSON-safe mask token baked into generated SQL."
  def default_placeholder, do: "[REDACTED]"

  @doc """
  Validates `:exclude`, `:mask`, and optional `:mask_placeholder`.

  Raises `ArgumentError` if `exclude` and `mask` intersect (message mentions both
  `"exclude"` and `"mask"` and lists an offending column).
  """
  def validate!(opts) when is_list(opts), do: validate!(Map.new(opts))

  def validate!(opts) when is_map(opts) do
    exclude = normalize_columns(Map.get(opts, :exclude, Map.get(opts, "exclude", [])))
    mask = normalize_columns(Map.get(opts, :mask, Map.get(opts, "mask", [])))
    intersection = MapSet.intersection(MapSet.new(exclude), MapSet.new(mask))

    if MapSet.size(intersection) > 0 do
      sample = intersection |> MapSet.to_list() |> List.first()
      cols = intersection |> MapSet.to_list() |> Enum.sort() |> Enum.join(", ")

      raise ArgumentError,
            "exclude and mask overlap on columns: #{cols}. " <>
              "Column #{inspect(sample)} cannot be both excluded and masked."
    end

    placeholder =
      Map.get(opts, :mask_placeholder) ||
        Map.get(opts, "mask_placeholder") ||
        default_placeholder()

    validate_placeholder!(placeholder)
    :ok
  end

  @doc """
  Validates a mask placeholder string for static SQL embedding.

  Raises if empty, longer than #{@max_placeholder_length}, or contains ASCII
  control characters (message contains `"placeholder"`).
  """
  def validate_placeholder!(placeholder) when is_binary(placeholder) do
    if placeholder == "" do
      raise ArgumentError, "placeholder must not be empty"
    end

    if String.length(placeholder) > @max_placeholder_length do
      raise ArgumentError,
            "placeholder exceeds max length (#{@max_placeholder_length})"
    end

    if String.contains?(placeholder, <<0>>) or
         Enum.any?(1..31, &String.contains?(placeholder, <<&1>>)) do
      raise ArgumentError, "placeholder must not contain control characters"
    end

    :ok
  end

  defp normalize_columns(list) when is_list(list) do
    list
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp normalize_columns(_), do: []
end
