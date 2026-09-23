defmodule Threadline.OperatorSurface.MechanicalChecker do
  @moduledoc false

  alias Threadline.OperatorSurface.MechanicalChecker.Parsing
  alias Threadline.OperatorSurface.MechanicalChecker.Scorecards

  # Deterministic mechanical gate for the operator-surface quality floor.
  #
  # Reads the committed Tier A scorecard JSON (RAW computed-style inputs emitted by
  # examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts) and computes
  # every mechanical verdict in pure Elixir. There is NO browser, NO network, and NO
  # LLM at assert time — the whole point is that a violation blocks a change with a
  # deterministic arithmetic proof.
  #
  # MODE-A (absolute hard blockers, no grandfathering): WCAG contrast (dark + light,
  # from color_pairs) and token conformance (radius / shadow / motion / font-size /
  # spacing, from element_styles). Each MODE-A violation carries a located, actionable,
  # fix-bearing map — the exact approved set for automated remediation.
  #
  # MODE-B (betterer-style ratchet floors): type-size count, interactive-control count,
  # card-nesting depth, scroll-cost/bp, distinct-accent-hue (Elixir does RGB->HSL +
  # ±15° hue bucketing over applied_colors). Card-nesting depth and distinct-accent-hue
  # carry an absolute far ceiling of 3 (>3 fails) UNLESS a recorded floor grandfathers
  # the pre-existing violation, in which case only worsening past that floor fails.
  #
  # MODE-A LOCKED constants below are pinned verbatim by mechanical_checker_test.exs
  # (the brandbook_token_parity idiom). They may NEVER be loosened.

  # --- MODE-A LOCKED WCAG constants (pinned by the meta-test) ---
  @wcag_text_contrast_ratio 4.5
  @wcag_large_text_contrast_ratio 3.0
  @wcag_non_text_contrast_ratio 3.0
  @wcag_large_text_px 24
  @wcag_large_text_bold_px 18.66

  # --- MODE-B far ceilings (brand-anchored absolute limits; >3 = violation) ---
  @mode_b_card_nesting_ceiling 3
  @mode_b_distinct_accent_hue_ceiling 3

  # --- Token scale constants (SSOT: lib/threadline/operator_surface/style.ex) ---
  @spacing_scale_px [4, 8, 12, 16, 20, 24, 32, 40, 48]
  @radius_scale_px [3, 4, 6, 8, 12, 999]
  @motion_duration_ms [120, 180, 240]
  @font_size_scale_px [12, 13, 14, 15, 16, 20, 24, 32]

  # box-shadow token geometry signatures (offset-x, offset-y, blur) in px, derived
  # from --tl-shadow-border/subtle/popover/raised in style.ex. [3, 0, 0] is the status
  # stripe — `inset var(--tl-status-stripe-width) 0 0 <color>` with --tl-status-stripe-width:
  # 3px — a tokenized inset left-edge indicator (cards/facts with data-status), not a stray
  # drop shadow; it was previously (incorrectly) flagged as off-token geometry.
  @shadow_token_signatures [[0, 0, 0], [0, 1, 2], [0, 1, 3], [0, 10, 28], [0, 18, 48], [3, 0, 0]]

  # MODE-B metrics keyed as they appear in mechanical_floors[ledger_id][metric][theme_bp].
  @mode_b_metrics ~w(
    type_size_count
    interactive_control_count
    card_nesting_depth
    scroll_cost
    distinct_accent_hue_count
  )

  # Sub-millisecond tolerance for on-scale motion durations.
  @ms_tolerance 1.0
  # Chromatic saturation floor: colours below this are grey and excluded from hue counting.
  @accent_saturation_floor 0.20
  # Hue bucketing window: two hues within this many degrees share an accent family.
  @hue_bucket_window 15

  @doc """
  Run every mechanical check against the supplied Tier A scorecard JSON.

  Required options:
    * `:scorecard_dir` — directory of `*.json` scorecards.
    * `:mechanical_floors` — MODE-B ratchet floors map.

  Returns `{:ok, []}` when there are no violations. Missing inputs return an actionable
  `{:error, {:missing_input, details}}` tuple. Mechanical violations retain their existing
  `{:error, violations}` result, where each violation is a located, actionable map:

      %{
        cell_id: "page.home.happy__dark-1280",
        metric: "wcag_contrast",
        mode: "A",
        selector: "h1.tl-home__title",
        observed: "3.2:1",
        expected: ">= 4.5:1",
        fix: "raise contrast to >= 4.5:1 ..."
      }
  """
  def run(opts) do
    with {:ok, dir} <- Scorecards.fetch_required_input(opts, :scorecard_dir),
         {:ok, floors} <- Scorecards.fetch_required_input(opts, :mechanical_floors),
         {:ok, scorecards} <- Scorecards.load(dir) do
      violations =
        scorecards
        |> Enum.flat_map(&check_scorecard(&1, floors))

      if violations == [], do: {:ok, []}, else: {:error, violations}
    end
  end

  @doc """
  WCAG 2.x relative luminance of an sRGB `{r, g, b}` (0..255) colour.

  Uses the piecewise sRGB linearization with the gamma exponent 2.4 — a 2.2 exponent
  silently mis-grades mid-tones. `{255, 255, 255}` -> `1.0`,
  `{0, 0, 0}` -> `0.0`.
  """
  def relative_luminance({r, g, b}) do
    [rl, gl, bl] = Enum.map([r, g, b], &linearize_channel/1)
    0.2126 * rl + 0.7152 * gl + 0.0722 * bl
  end

  @doc """
  WCAG 2.x contrast ratio between two relative luminances (order-independent).
  """
  def contrast_ratio(l1, l2) do
    {lighter, darker} = if l1 >= l2, do: {l1, l2}, else: {l2, l1}
    (lighter + 0.05) / (darker + 0.05)
  end

  # --- luminance helpers ---

  defp linearize_channel(c) do
    srgb = c / 255.0

    if srgb <= 0.04045 do
      srgb / 12.92
    else
      :math.pow((srgb + 0.055) / 1.055, 2.4)
    end
  end

  defp check_scorecard(scorecard, floors) do
    check_wcag(scorecard) ++
      check_conformance(scorecard) ++
      check_mode_b(scorecard, floors)
  end

  # --- MODE-A: WCAG contrast (from color_pairs) ---

  defp check_wcag(scorecard) do
    cell_id = scorecard["cell_id"]
    page_bg = Parsing.parse_color(scorecard["tokens"]["--tl-color-bg"])

    scorecard
    |> Map.get("color_pairs", [])
    |> Enum.flat_map(&wcag_violation(&1, cell_id, page_bg))
  end

  defp wcag_violation(pair, cell_id, page_bg) do
    with {:ok, fg_rgba} <- Parsing.parse_color(pair["color"]),
         true <- visible?(fg_rgba),
         {:ok, bg_rgb} <- resolve_background(pair["background_color"], page_bg) do
      fg_rgb = composite(fg_rgba, bg_rgb)
      ratio = contrast_ratio(relative_luminance(fg_rgb), relative_luminance(bg_rgb))
      required = required_contrast(pair)

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

  defp required_contrast(pair) do
    cond do
      ui_component?(pair["selector"]) -> @wcag_non_text_contrast_ratio
      large_text?(pair) -> @wcag_large_text_contrast_ratio
      true -> @wcag_text_contrast_ratio
    end
  end

  defp ui_component?(selector) when is_binary(selector) do
    tag = selector |> String.split(".") |> List.first()
    tag in ~w(button input select textarea)
  end

  defp ui_component?(_), do: false

  defp large_text?(pair) do
    size = Parsing.parse_px(pair["font_size"]) || 0.0
    bold = bold?(pair["font_weight"])
    size >= @wcag_large_text_px or (bold and size >= @wcag_large_text_bold_px)
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

  # --- MODE-A: token conformance (from element_styles) ---

  defp check_conformance(scorecard) do
    cell_id = scorecard["cell_id"]

    scorecard
    |> Map.get("element_styles", [])
    |> Enum.flat_map(&element_conformance(&1, cell_id))
  end

  defp element_conformance(el, cell_id) do
    radius_violations(el, cell_id) ++
      shadow_violations(el, cell_id) ++
      motion_violations(el, cell_id) ++
      font_size_violations(el, cell_id) ++
      spacing_violations(el, cell_id)
  end

  defp radius_violations(el, cell_id) do
    el["border_radius"]
    |> Parsing.px_values()
    |> Enum.reject(&(&1 == 0.0 or Parsing.on_scale?(&1, @radius_scale_px)))
    |> Enum.map(fn value ->
      scale_violation(
        cell_id,
        "border_radius",
        el["selector"],
        value,
        @radius_scale_px,
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

  defp motion_violations(el, cell_id) do
    el["transition_duration"]
    |> Parsing.duration_ms_values()
    |> Enum.reject(&(&1 == 0.0 or Parsing.on_scale?(&1, @motion_duration_ms, @ms_tolerance)))
    |> Enum.map(fn value ->
      scale_violation(
        cell_id,
        "transition_duration",
        el["selector"],
        value,
        @motion_duration_ms,
        "--tl-motion",
        "ms"
      )
    end)
  end

  defp font_size_violations(el, cell_id) do
    case Parsing.parse_px(el["font_size"]) do
      nil ->
        []

      +0.0 ->
        []

      value ->
        if Parsing.on_scale?(value, @font_size_scale_px) do
          []
        else
          [
            scale_violation(
              cell_id,
              "font_size",
              el["selector"],
              value,
              @font_size_scale_px,
              "--tl-font-size"
            )
          ]
        end
    end
  end

  defp spacing_violations(el, cell_id) do
    ~w(margin_top margin_bottom padding_top padding_bottom)
    |> Enum.flat_map(fn prop ->
      case Parsing.parse_px(el[prop]) do
        nil -> []
        +0.0 -> []
        # Structural debt: scale if inside case inside flat_map fn — extract the prop check
        # credo:disable-for-next-line Credo.Check.Refactor.Nesting
        value -> if Parsing.on_scale?(value, @spacing_scale_px), do: [], else: [{prop, value}]
      end
    end)
    |> Enum.map(fn {prop, value} ->
      scale_violation(cell_id, prop, el["selector"], value, @spacing_scale_px, "--tl-space")
    end)
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

  # --- MODE-B: ratchet-floor metrics + far ceilings ---

  @doc """
  Returns the measured MODE-B metric values for a decoded scorecard as a map
  keyed by the `@mode_b_metrics` names.

  This is the single source of truth for MODE-B measurement: `check_mode_b/2`
  ratchets these values against the recorded floors, and the betterer-floor
  seeder writes these same values into the ledger's `mechanical_floors` block,
  so committed floors can never drift from what the checker computes.
  """
  def measure_mode_b(scorecard) do
    mode_b = scorecard["mode_b"] || %{}

    %{
      "type_size_count" => Parsing.num(mode_b["type_size_count"]),
      "interactive_control_count" => Parsing.num(mode_b["interactive_control_count"]),
      "card_nesting_depth" => Parsing.num(mode_b["card_nesting_depth"]),
      "scroll_cost" => Parsing.num(mode_b["scroll_cost"]),
      "distinct_accent_hue_count" => distinct_accent_hue_count(scorecard["applied_colors"] || [])
    }
  end

  defp check_mode_b(scorecard, floors) do
    cell_id = scorecard["cell_id"]
    ledger_id = scorecard["ledger_id"]
    theme_bp = "#{scorecard["theme"]}_#{scorecard["breakpoint"]}"
    measured = measure_mode_b(scorecard)

    Enum.flat_map(@mode_b_metrics, fn metric ->
      current = Map.fetch!(measured, metric)
      floor = get_in(floors, [ledger_id, metric, theme_bp])
      ceiling = ceiling_for(metric)
      mode_b_metric_violations(metric, current, floor, ceiling, cell_id, theme_bp)
    end)
  end

  defp ceiling_for("card_nesting_depth"), do: @mode_b_card_nesting_ceiling
  defp ceiling_for("distinct_accent_hue_count"), do: @mode_b_distinct_accent_hue_ceiling
  defp ceiling_for(_), do: nil

  # Absent floor + a real far ceiling -> absolute blocker. A recorded floor grandfathers
  # any pre-existing >ceiling value; only worsening past that floor then fails.
  defp mode_b_metric_violations(metric, current, floor, ceiling, cell_id, theme_bp) do
    cond do
      is_nil(floor) and not is_nil(ceiling) and current > ceiling ->
        [ceiling_violation(metric, current, ceiling, cell_id, theme_bp)]

      not is_nil(floor) and current > floor ->
        [ratchet_violation(metric, current, floor, cell_id, theme_bp)]

      true ->
        []
    end
  end

  defp ceiling_violation(metric, current, ceiling, cell_id, theme_bp) do
    %{
      cell_id: cell_id,
      metric: metric,
      mode: "B",
      selector: "##{theme_bp}",
      observed: Parsing.fmt(current),
      expected: "<= #{ceiling}",
      fix: "reduce #{metric} to <= #{ceiling} (structural correction + human review required)"
    }
  end

  defp ratchet_violation(metric, current, floor, cell_id, theme_bp) do
    %{
      cell_id: cell_id,
      metric: metric,
      mode: "B",
      selector: "##{theme_bp}",
      observed: Parsing.fmt(current),
      expected: "<= floor #{Parsing.fmt(floor)}",
      fix:
        "#{metric} regressed past its ratchet floor (#{Parsing.fmt(current)} > #{Parsing.fmt(floor)}) — " <>
          "revert the regression or record a ratchet reset with rationale"
    }
  end

  # --- distinct-accent-hue (RGB -> HSL + ±15° bucketing over chromatic colours) ---

  defp distinct_accent_hue_count(colors) do
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
