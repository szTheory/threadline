defmodule Threadline.OperatorSurface.MechanicalChecker.Contrast do
  @moduledoc false

  alias Threadline.OperatorSurface.MechanicalChecker
  alias Threadline.OperatorSurface.MechanicalChecker.Parsing

  # MODE-A WCAG contrast over a scorecard's color_pairs.
  #
  # The locked thresholds are declared in the parent module, where the meta-test
  # pins them, and arrive here as the `thresholds` map:
  #
  #   * `:text` — normal text ratio
  #   * `:large_text` — large text ratio
  #   * `:non_text` — UI component ratio
  #   * `:large_text_px` — size at which any weight counts as large text
  #   * `:large_text_bold_px` — size at which bold text counts as large text
  #
  # Luminance and ratio arithmetic come from the parent's public functions, so the
  # gamma-2.4 linearization has exactly one home.

  def check(scorecard, thresholds) do
    cell_id = scorecard["cell_id"]
    page_bg = Parsing.parse_color(scorecard["tokens"]["--tl-color-bg"])

    scorecard
    |> Map.get("color_pairs", [])
    |> Enum.flat_map(&wcag_violation(&1, cell_id, page_bg, thresholds))
  end

  defp wcag_violation(pair, cell_id, page_bg, thresholds) do
    with {:ok, fg_rgba} <- Parsing.parse_color(pair["color"]),
         true <- visible?(fg_rgba),
         {:ok, bg_rgb} <- resolve_background(pair["background_color"], page_bg) do
      fg_rgb = composite(fg_rgba, bg_rgb)

      ratio =
        MechanicalChecker.contrast_ratio(
          MechanicalChecker.relative_luminance(fg_rgb),
          MechanicalChecker.relative_luminance(bg_rgb)
        )

      required = required_contrast(pair, thresholds)

      if ratio + 0.05 < required do
        [wcag_violation_map(pair, cell_id, ratio, required)]
      else
        []
      end
    else
      _ -> []
    end
  end

  # Resolve the effective (opaque) background a text pair renders against. A translucent
  # element fill (e.g. a chip/tab tint at 0.15–0.18 alpha) must be COMPOSITED over the page
  # background before contrast is judged — otherwise its raw RGB is treated as opaque and a
  # faint same-hue tint reads as a false low-contrast failure (thread-blue text on an 18%
  # thread-blue fill scored 1.26:1 as if blue-on-blue, when it renders as blue-on-dark). A
  # fully/near-transparent bg falls back to the page background token.
  defp resolve_background(raw, page_bg) do
    case Parsing.parse_color(raw) do
      {:ok, {_r, _g, _b, a} = bg_rgba} when a >= 0.1 ->
        with {:ok, page_rgb} <- to_rgb(page_bg), do: {:ok, composite(bg_rgba, page_rgb)}

      _ ->
        to_rgb(page_bg)
    end
  end

  defp to_rgb({:ok, {r, g, b, _a}}), do: {:ok, {r, g, b}}
  defp to_rgb(_), do: :error

  defp visible?({_r, _g, _b, a}), do: a >= 0.1

  # Composite a possibly-translucent foreground over an opaque background.
  defp composite({r, g, b, a}, {br, bg, bb}) do
    {
      round(r * a + br * (1 - a)),
      round(g * a + bg * (1 - a)),
      round(b * a + bb * (1 - a))
    }
  end

  defp required_contrast(pair, thresholds) do
    cond do
      ui_component?(pair["selector"]) -> thresholds.non_text
      large_text?(pair, thresholds) -> thresholds.large_text
      true -> thresholds.text
    end
  end

  defp ui_component?(selector) when is_binary(selector) do
    tag = selector |> String.split(".") |> List.first()
    tag in ~w(button input select textarea)
  end

  defp ui_component?(_), do: false

  defp large_text?(pair, thresholds) do
    size = Parsing.parse_px(pair["font_size"]) || 0.0
    bold = bold?(pair["font_weight"])
    size >= thresholds.large_text_px or (bold and size >= thresholds.large_text_bold_px)
  end

  defp bold?(weight) when is_binary(weight) do
    case Integer.parse(weight) do
      {n, _} -> n >= 700
      :error -> weight in ~w(bold bolder)
    end
  end

  defp bold?(weight) when is_integer(weight), do: weight >= 700
  defp bold?(_), do: false

  defp wcag_violation_map(pair, cell_id, ratio, required) do
    %{
      cell_id: cell_id,
      metric: "wcag_contrast",
      mode: "A",
      selector: pair["selector"],
      observed: "#{Parsing.fmt(ratio)}:1",
      expected: ">= #{Parsing.fmt(required)}:1",
      fix:
        "raise contrast to >= #{Parsing.fmt(required)}:1 (observed #{Parsing.fmt(ratio)}:1) — " <>
          "lighten the foreground toward --tl-color-text or darken the background"
    }
  end
end
