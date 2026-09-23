defmodule Threadline.OperatorSurface.MechanicalChecker.AccentHue do
  @moduledoc false

  alias Threadline.OperatorSurface.MechanicalChecker.Parsing

  # Distinct-accent-hue count for MODE-B: RGB -> HSL over the applied colours, grey
  # dropped by a saturation floor, then ±15° hue bucketing with wraparound at 360°.

  # Chromatic saturation floor: colours below this are grey and excluded from hue counting.
  @accent_saturation_floor 0.20
  # Hue bucketing window: two hues within this many degrees share an accent family.
  @hue_bucket_window 15

  def count(colors) do
    colors
    |> Enum.map(&Parsing.parse_color/1)
    |> Enum.flat_map(fn
      {:ok, {r, g, b, a}} when a >= 0.1 -> [rgb_to_hue_sat({r, g, b})]
      _ -> []
    end)
    |> Enum.filter(fn {_h, s} -> s > @accent_saturation_floor end)
    |> Enum.map(fn {h, _s} -> h end)
    |> count_hue_buckets()
  end

  defp rgb_to_hue_sat({r, g, b}) do
    rf = r / 255
    gf = g / 255
    bf = b / 255
    max = Enum.max([rf, gf, bf])
    min = Enum.min([rf, gf, bf])
    delta = max - min
    l = (max + min) / 2

    s = if delta == 0, do: 0.0, else: delta / (1 - abs(2 * l - 1))
    h = hue(max, delta, rf, gf, bf)
    {h, s}
  end

  defp hue(_max, +0.0, _rf, _gf, _bf), do: 0.0

  defp hue(max, delta, rf, gf, bf) do
    raw =
      cond do
        max == rf -> 60 * :math.fmod((gf - bf) / delta, 6)
        max == gf -> 60 * ((bf - rf) / delta + 2)
        true -> 60 * ((rf - gf) / delta + 4)
      end

    if raw < 0, do: raw + 360, else: raw
  end

  defp count_hue_buckets([]), do: 0

  defp count_hue_buckets(hues) do
    sorted = Enum.sort(hues)

    {count, _prev} =
      Enum.reduce(tl(sorted), {1, hd(sorted)}, fn h, {count, prev} ->
        if h - prev > @hue_bucket_window, do: {count + 1, h}, else: {count, h}
      end)

    wraparound_merge(count, sorted)
  end

  # 350° and 5° are 15° apart — merge the first and last clusters if they wrap.
  defp wraparound_merge(count, sorted) when count > 1 do
    if 360 - List.last(sorted) + hd(sorted) <= @hue_bucket_window, do: count - 1, else: count
  end

  defp wraparound_merge(count, _sorted), do: count
end
