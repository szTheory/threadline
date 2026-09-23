defmodule Threadline.OperatorSurface.MechanicalChecker.TokenConformance do
  @moduledoc false

  alias Threadline.OperatorSurface.MechanicalChecker.Parsing

  # MODE-A token conformance over a scorecard's element_styles: radius, box-shadow,
  # motion duration, font size, and spacing must each sit on a --tl-* token scale.
  #
  # The four scale lists are declared in the parent module, where the meta-test pins
  # them, and arrive here as the `scales` map (`:radius`, `:motion`, `:font_size`,
  # `:spacing`).

  # box-shadow token geometry signatures (offset-x, offset-y, blur) in px, derived
  # from --tl-shadow-border/subtle/popover/raised in
  # lib/threadline/operator_surface/style/01_tokens.css. [3, 0, 0] is the status
  # stripe — `inset var(--tl-status-stripe-width) 0 0 <color>` with --tl-status-stripe-width:
  # 3px — a tokenized inset left-edge indicator (cards/facts with data-status), not a stray
  # drop shadow; it was previously (incorrectly) flagged as off-token geometry.
  @shadow_token_signatures [[0, 0, 0], [0, 1, 2], [0, 1, 3], [0, 10, 28], [0, 18, 48], [3, 0, 0]]

  # Sub-millisecond tolerance for on-scale motion durations.
  @ms_tolerance 1.0

  @spacing_props ~w(margin_top margin_bottom padding_top padding_bottom)

  def check(scorecard, scales) do
    cell_id = scorecard["cell_id"]

    scorecard
    |> Map.get("element_styles", [])
    |> Enum.flat_map(&element_conformance(&1, cell_id, scales))
  end

  defp element_conformance(el, cell_id, scales) do
    radius_violations(el, cell_id, scales.radius) ++
      shadow_violations(el, cell_id) ++
      motion_violations(el, cell_id, scales.motion) ++
      font_size_violations(el, cell_id, scales.font_size) ++
      spacing_violations(el, cell_id, scales.spacing)
  end

  defp radius_violations(el, cell_id, scale) do
    el["border_radius"]
    |> Parsing.px_values()
    |> Enum.reject(&(&1 == 0.0 or Parsing.on_scale?(&1, scale)))
    |> Enum.map(fn value ->
      scale_violation(
        cell_id,
        "border_radius",
        el["selector"],
        value,
        scale,
        "--tl-radius"
      )
    end)
  end

  defp shadow_violations(el, cell_id) do
    el["box_shadow"]
    |> Parsing.shadow_signatures()
    |> Enum.reject(&(&1 in @shadow_token_signatures))
    |> Enum.map(fn sig ->
      %{
        cell_id: cell_id,
        metric: "box_shadow",
        mode: "A",
        selector: el["selector"],
        observed: "geometry #{inspect(sig)}",
        expected: "one of #{inspect(@shadow_token_signatures)}",
        fix: "replace box-shadow with a --tl-shadow-* token (border/subtle/popover/raised)"
      }
    end)
  end

  defp motion_violations(el, cell_id, scale) do
    el["transition_duration"]
    |> Parsing.duration_ms_values()
    |> Enum.reject(&(&1 == 0.0 or Parsing.on_scale?(&1, scale, @ms_tolerance)))
    |> Enum.map(fn value ->
      scale_violation(
        cell_id,
        "transition_duration",
        el["selector"],
        value,
        scale,
        "--tl-motion",
        "ms"
      )
    end)
  end

  defp font_size_violations(el, cell_id, scale) do
    case Parsing.parse_px(el["font_size"]) do
      nil ->
        []

      +0.0 ->
        []

      value ->
        if Parsing.on_scale?(value, scale) do
          []
        else
          [
            scale_violation(
              cell_id,
              "font_size",
              el["selector"],
              value,
              scale,
              "--tl-font-size"
            )
          ]
        end
    end
  end

  defp spacing_violations(el, cell_id, scale) do
    @spacing_props
    |> Enum.flat_map(&off_scale_spacing(el, &1, scale))
    |> Enum.map(fn {prop, value} ->
      scale_violation(cell_id, prop, el["selector"], value, scale, "--tl-space")
    end)
  end

  # One spacing property of one element: [] when absent, zero, or on the scale,
  # otherwise the single off-scale {prop, value} pair.
  defp off_scale_spacing(el, prop, scale) do
    case Parsing.parse_px(el[prop]) do
      nil -> []
      +0.0 -> []
      value -> if Parsing.on_scale?(value, scale), do: [], else: [{prop, value}]
    end
  end

  defp scale_violation(cell_id, metric, selector, value, scale, token_family, unit \\ "px") do
    nearest = Enum.min_by(scale, &abs(&1 - value))

    %{
      cell_id: cell_id,
      metric: metric,
      mode: "A",
      selector: selector,
      observed: "#{Parsing.fmt(value)}#{unit}",
      expected: "one of #{inspect(scale)} #{unit}",
      fix:
        "snap #{metric} #{Parsing.fmt(value)}#{unit} -> nearest token #{nearest}#{unit} (#{token_family}-* scale)"
    }
  end
end
