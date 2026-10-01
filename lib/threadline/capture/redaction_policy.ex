defmodule Threadline.Capture.RedactionPolicy do
  @moduledoc false

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
    exclude = normalize_columns(Map.get(opts, :exclude, Map.get(opts, "exclude", [])), "exclude")
    mask = normalize_columns(Map.get(opts, :mask, Map.get(opts, "mask", [])), "mask")
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

  Raises if empty, longer than #{@max_placeholder_length} graphemes, or
  contains ASCII control bytes 0..31 (message contains `"placeholder"`).

  DEL (127) and C1 control code points (U+0080..U+009F) are deliberately
  accepted: this check only guards static SQL string embedding against the
  bytes PostgreSQL's string-literal syntax cannot represent unescaped
  (0..31). The placeholder is always emitted as a quoted SQL literal, so
  DEL and C1 bytes are safe to embed and are not rejected here.
  """
  def validate_placeholder!(placeholder) when is_binary(placeholder) do
    if placeholder == "" do
      raise ArgumentError, "placeholder must not be empty"
    end

    if String.length(placeholder) > @max_placeholder_length do
      raise ArgumentError,
            "placeholder exceeds max length (#{@max_placeholder_length} graphemes)"
    end

    if String.contains?(placeholder, <<0>>) or
         Enum.any?(1..31, &String.contains?(placeholder, <<&1>>)) do
      raise ArgumentError, "placeholder must not contain control characters"
    end

    :ok
  end

  def validate_placeholder!(placeholder) do
    raise ArgumentError, "placeholder must be a string, got: #{inspect(placeholder)}"
  end

  defp normalize_columns(nil, _key), do: []

  defp normalize_columns(list, _key) when is_list(list) do
    list
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp normalize_columns(other, key) do
    raise ArgumentError,
          "#{key} must be a list of column names, got: #{inspect(other)}"
  end
end
