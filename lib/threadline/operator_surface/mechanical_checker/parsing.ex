defmodule Threadline.OperatorSurface.MechanicalChecker.Parsing do
  @moduledoc false

  # Parsing helpers shared by the mechanical checker and its per-check modules.
  #
  # Every function here reads a raw computed-style string from a Tier A scorecard
  # (a CSS colour, a pixel length, a duration list, a box-shadow) and turns it into
  # plain numbers. None of them judge a value; the check modules do that.

  # Sub-pixel tolerance for on-scale membership (browsers report integer px for tokens).
  @px_tolerance 0.5

  # Parse "rgb(...)", "rgba(...)", or "#rrggbb"/"#rgb" -> {:ok, {r, g, b, a}} | :error.
  def parse_color(str) when is_binary(str) do
    cond do
      String.starts_with?(str, "rgb") -> parse_rgb(str)
      String.starts_with?(str, "#") -> parse_hex(str)
      true -> :error
    end
  end

  def parse_color(_), do: :error

  defp parse_rgb(str) do
    case Regex.run(~r/^rgba?\(([^)]+)\)$/, str) do
      [_, inner] ->
        parts = inner |> String.split(",") |> Enum.map(&String.trim/1)

        case parts do
          [r, g, b] -> parse_rgb_parts(r, g, b, "1")
          [r, g, b, a] -> parse_rgb_parts(r, g, b, a)
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp parse_hex(str) do
    hex = String.trim_leading(str, "#")

    cond do
      Regex.match?(~r/^[0-9a-fA-F]{6}$/, hex) -> {:ok, expand_hex(hex, 2)}
      Regex.match?(~r/^[0-9a-fA-F]{3}$/, hex) -> {:ok, expand_hex(hex, 1)}
      true -> :error
    end
  end

  defp parse_rgb_parts(r, g, b, a) do
    with {red, ""} <- Integer.parse(r),
         {green, ""} <- Integer.parse(g),
         {blue, ""} <- Integer.parse(b),
         {alpha, ""} <- Float.parse(a),
         true <- Enum.all?([red, green, blue], &(&1 >= 0 and &1 <= 255)),
         true <- alpha >= 0.0 and alpha <= 1.0 do
      {:ok, {red, green, blue, alpha}}
    else
      _ -> :error
    end
  end

  defp expand_hex(hex, chunk) do
    [r, g, b] =
      hex
      |> String.graphemes()
      |> Enum.chunk_every(chunk)
      |> Enum.take(3)
      |> Enum.map(fn pair ->
        digits = Enum.join(pair)
        digits = if chunk == 1, do: digits <> digits, else: digits
        String.to_integer(digits, 16)
      end)

    {r, g, b, 1.0}
  end

  defp to_f(str) do
    case Float.parse(str) do
      {n, _} -> n
      :error -> 1.0
    end
  end

  # Extract every "<n>px" number from a computed value (e.g. "8px 8px 8px 8px").
  def px_values(nil), do: []

  def px_values(str) when is_binary(str) do
    ~r/(-?\d*\.?\d+)px/
    |> Regex.scan(str)
    |> Enum.map(fn [_, n] -> to_f(n) end)
    |> Enum.uniq()
  end

  def parse_px(nil), do: nil

  def parse_px(str) when is_binary(str) do
    case Regex.run(~r/(-?\d*\.?\d+)px/, str) do
      [_, n] -> to_f(n)
      _ -> nil
    end
  end

  def parse_px(_), do: nil

  # Comma-separated durations in seconds -> milliseconds (e.g. "0.12s, 0s" -> [120.0, 0.0]).
  def duration_ms_values(nil), do: []

  def duration_ms_values(str) when is_binary(str) do
    str
    |> String.split(",")
    |> Enum.flat_map(fn seg ->
      case Regex.run(~r/(-?\d*\.?\d+)s/, String.trim(seg)) do
        [_, n] -> [to_f(n) * 1000]
        _ -> []
      end
    end)
  end

  # Strip colour functions, split shadow layers, take each layer's (x, y, blur) px triple.
  def shadow_signatures(nil), do: []
  def shadow_signatures("none"), do: []

  def shadow_signatures(str) when is_binary(str) do
    ~r/rgba?\([^)]*\)/
    |> Regex.replace(str, "")
    |> String.split(",")
    |> Enum.flat_map(fn seg ->
      case px_layer_signature(seg) do
        [] -> []
        sig -> [sig]
      end
    end)
  end

  defp px_layer_signature(seg) do
    ~r/(-?\d*\.?\d+)px/
    |> Regex.scan(seg)
    |> Enum.map(fn [_, n] -> round(to_f(n)) end)
    |> Enum.take(3)
  end

  def on_scale?(value, scale, tolerance \\ @px_tolerance) do
    Enum.any?(scale, &(abs(&1 - value) <= tolerance))
  end

  def num(n) when is_number(n), do: n
  def num(_), do: 0

  def fmt(n) when is_float(n) do
    if n == Float.round(n), do: trunc(n), else: Float.round(n, 2)
  end

  def fmt(n), do: n
end
