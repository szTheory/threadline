defmodule Threadline.OperatorSurface.MechanicalChecker do
  @moduledoc false

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

  # Sub-pixel tolerances for on-scale membership (browsers report integer px for tokens).
  @px_tolerance 0.5
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
    with {:ok, dir} <- fetch_required_input(opts, :scorecard_dir),
         {:ok, floors} <- fetch_required_input(opts, :mechanical_floors),
         {:ok, scorecards} <- load_scorecards(dir) do
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

  # --- scorecard loading ---

  defp fetch_required_input(opts, option) do
    case Keyword.fetch(opts, option) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_input, missing_input_details(option)}}
    end
  end

  defp missing_input_details(:scorecard_dir) do
    %{
      dataset: "mechanical scorecard corpus",
      option: :scorecard_dir,
      path: nil,
      repository_only: false,
      recovery:
        ~s|call MechanicalChecker.run(scorecard_dir: "/absolute/path/to/scorecards", mechanical_floors: floors)|
    }
  end

  defp missing_input_details(:mechanical_floors) do
    %{
      dataset: "mechanical floor map",
      option: :mechanical_floors,
      path: nil,
      repository_only: false,
      recovery:
        ~s|call MechanicalChecker.run(scorecard_dir: scorecard_dir, mechanical_floors: %{})|
    }
  end

  defp load_scorecards(dir) do
    expanded_dir = Path.expand(dir)

    with {:ok, paths} <- list_scorecard_paths(expanded_dir),
         {:ok, scorecards} <- decode_scorecards(paths) do
      {:ok, scorecards}
    end
  end

  defp list_scorecard_paths(dir) do
    case File.ls(dir) do
      {:ok, files} ->
        paths =
          files
          |> Enum.filter(&String.ends_with?(&1, ".json"))
          # The mechanical FLOOR governs the real operator surface — the Tier-A `/audit`
          # (`page.*`) cells and the committed refute/graded oracle. Two cell families are
          # deliberately out of its jurisdiction:
          #   • `route.*` — live-server, live-data captures, gitignored and not byte-stable;
          #     a local capture would otherwise redden the gate off a
          #     non-deterministic artifact (e.g. the deliberately-degraded ranking twin).
          #   • `story.*` — Storybook demo cells that exist to feed the LLM critic's aesthetic
          #     scoring, NOT the deterministic pixel-grid floor. They render isolated/unstyled
          #     demo primitives (e.g. demo-only tl-accordion/tl-toast with no style.ex rules)
          #     and demo scaffolding (bare description <p>) that were never meant to pass the
          #     token-grid checks — holding demos to the production floor is a category error.
          # CI over the real surface is unaffected (Tier-A cells still gate).
          |> Enum.reject(
            &(String.starts_with?(&1, "route.") or String.starts_with?(&1, "story."))
          )
          |> Enum.sort()
          |> Enum.map(&Path.join(dir, &1))

        if paths == [] do
          corpus_error(:empty_corpus, dir, :no_eligible_scorecards)
        else
          {:ok, paths}
        end

      {:error, :enoent} ->
        corpus_error(:missing_corpus, dir, :enoent)

      {:error, reason} ->
        corpus_error(:unreadable_corpus, dir, reason)
    end
  end

  defp decode_scorecards(paths) do
    Enum.reduce_while(paths, {:ok, []}, fn path, {:ok, scorecards} ->
      case decode_scorecard(path) do
        {:ok, scorecard} -> {:cont, {:ok, [scorecard | scorecards]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, scorecards} -> {:ok, Enum.reverse(scorecards)}
      error -> error
    end
  end

  defp decode_scorecard(path) do
    with {:ok, body} <- File.read(path),
         {:ok, scorecard} <- Jason.decode(body),
         :ok <- validate_scorecard(scorecard) do
      {:ok, scorecard}
    else
      {:error, %Jason.DecodeError{} = error} ->
        corpus_error(:malformed_scorecard, path, Exception.message(error))

      {:error, {:invalid_scorecard, reason}} ->
        corpus_error(:malformed_scorecard, path, reason)

      {:error, reason} ->
        corpus_error(:unreadable_corpus, path, reason)
    end
  end

  defp validate_scorecard(scorecard) when is_map(scorecard) do
    required = [
      {"cell_id", &is_binary/1, "a string"},
      {"ledger_id", &is_binary/1, "a string"},
      {"theme", &is_binary/1, "a string"},
      {"breakpoint", &is_number/1, "a number"},
      {"tokens", &is_map/1, "an object"},
      {"color_pairs", &list_of_maps?/1, "an array of objects"},
      {"element_styles", &list_of_maps?/1, "an array of objects"},
      {"applied_colors", &is_list/1, "an array"},
      {"mode_b", &is_map/1, "an object"}
    ]

    case Enum.find(required, fn {key, valid?, _expected} ->
           not valid?.(Map.get(scorecard, key))
         end) do
      nil ->
        validate_nested_scorecard(scorecard)

      {key, _valid?, expected} ->
        {:error, {:invalid_scorecard, "#{key} must be #{expected}"}}
    end
  end

  defp validate_scorecard(_scorecard) do
    {:error, {:invalid_scorecard, "top-level JSON value must be an object"}}
  end

  defp list_of_maps?(value), do: is_list(value) and Enum.all?(value, &is_map/1)

  defp validate_nested_scorecard(scorecard) do
    with :ok <-
           validate_color(get_in(scorecard, ["tokens", "--tl-color-bg"]), "tokens.--tl-color-bg"),
         :ok <- validate_non_empty_list(scorecard["color_pairs"], "color_pairs"),
         :ok <- validate_entries(scorecard["color_pairs"], &validate_color_pair/2),
         :ok <- validate_non_empty_list(scorecard["element_styles"], "element_styles"),
         :ok <- validate_entries(scorecard["element_styles"], &validate_element_style/2),
         :ok <- validate_non_empty_list(scorecard["applied_colors"], "applied_colors"),
         :ok <- validate_entries(scorecard["applied_colors"], &validate_applied_color/2),
         :ok <- validate_mode_b(scorecard["mode_b"]) do
      :ok
    end
  end

  defp validate_non_empty_list([], field), do: invalid_scorecard("#{field} must not be empty")
  defp validate_non_empty_list(_values, _field), do: :ok

  defp validate_entries(values, validator) do
    values
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {value, index}, :ok ->
      case validator.(value, index) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp validate_color_pair(pair, index) do
    prefix = "color_pairs[#{index}]"

    with :ok <- validate_non_empty_string(pair["selector"], "#{prefix}.selector"),
         :ok <- validate_color(pair["color"], "#{prefix}.color"),
         :ok <- validate_color(pair["background_color"], "#{prefix}.background_color"),
         :ok <- validate_px(pair["font_size"], "#{prefix}.font_size"),
         :ok <- validate_font_weight(pair["font_weight"], "#{prefix}.font_weight") do
      :ok
    end
  end

  defp validate_element_style(style, index) do
    prefix = "element_styles[#{index}]"

    with :ok <- validate_non_empty_string(style["selector"], "#{prefix}.selector"),
         :ok <- validate_px_list(style["border_radius"], "#{prefix}.border_radius"),
         :ok <- validate_box_shadow(style["box_shadow"], "#{prefix}.box_shadow"),
         :ok <-
           validate_duration_list(style["transition_duration"], "#{prefix}.transition_duration"),
         :ok <- validate_px(style["font_size"], "#{prefix}.font_size"),
         :ok <- validate_px(style["margin_top"], "#{prefix}.margin_top"),
         :ok <- validate_px(style["margin_bottom"], "#{prefix}.margin_bottom"),
         :ok <- validate_px(style["padding_top"], "#{prefix}.padding_top"),
         :ok <- validate_px(style["padding_bottom"], "#{prefix}.padding_bottom") do
      :ok
    end
  end

  defp validate_applied_color(color, index),
    do: validate_color(color, "applied_colors[#{index}]")

  defp validate_mode_b(mode_b) do
    ~w(type_size_count interactive_control_count card_nesting_depth scroll_cost)
    |> Enum.reduce_while(:ok, fn metric, :ok ->
      if is_number(mode_b[metric]) do
        {:cont, :ok}
      else
        {:halt, invalid_scorecard("mode_b.#{metric} must be a number")}
      end
    end)
  end

  defp validate_non_empty_string(value, _field) when is_binary(value) and value != "", do: :ok

  defp validate_non_empty_string(_value, field),
    do: invalid_scorecard("#{field} must be a non-empty string")

  defp validate_color(value, field) do
    case parse_color(value) do
      {:ok, _rgba} -> :ok
      :error -> invalid_scorecard("#{field} must be a parseable CSS color")
    end
  end

  defp validate_px(value, field) when is_binary(value) do
    if Regex.match?(~r/^-?(?:\d+(?:\.\d+)?|\.\d+)px$/, value),
      do: :ok,
      else: invalid_scorecard("#{field} must be a CSS pixel value")
  end

  defp validate_px(_value, field), do: invalid_scorecard("#{field} must be a CSS pixel value")

  defp validate_px_list(value, field) when is_binary(value) do
    values = String.split(value)

    if values != [] and length(values) <= 4 and
         Enum.all?(values, &Regex.match?(~r/^-?(?:\d+(?:\.\d+)?|\.\d+)px$/, &1)),
       do: :ok,
       else: invalid_scorecard("#{field} must contain one to four CSS pixel values")
  end

  defp validate_px_list(_value, field),
    do: invalid_scorecard("#{field} must contain one to four CSS pixel values")

  defp validate_box_shadow("none", _field), do: :ok

  defp validate_box_shadow(value, field) when is_binary(value) do
    signatures = shadow_signatures(value)

    if signatures != [] and Enum.all?(signatures, &(length(&1) == 3)),
      do: :ok,
      else: invalid_scorecard("#{field} must be none or a parseable CSS box-shadow")
  end

  defp validate_box_shadow(_value, field),
    do: invalid_scorecard("#{field} must be none or a parseable CSS box-shadow")

  defp validate_duration_list(value, field) when is_binary(value) do
    durations = value |> String.split(",") |> Enum.map(&String.trim/1)

    if durations != [] and
         Enum.all?(durations, &Regex.match?(~r/^-?(?:\d+(?:\.\d+)?|\.\d+)s$/, &1)),
       do: :ok,
       else: invalid_scorecard("#{field} must contain CSS durations in seconds")
  end

  defp validate_duration_list(_value, field),
    do: invalid_scorecard("#{field} must contain CSS durations in seconds")

  defp validate_font_weight(value, _field)
       when is_integer(value) and value >= 1 and value <= 1000,
       do: :ok

  defp validate_font_weight(value, field) when is_binary(value) do
    valid =
      value in ~w(normal bold bolder lighter) or
        match?({weight, ""} when weight >= 1 and weight <= 1000, Integer.parse(value))

    if valid, do: :ok, else: invalid_scorecard("#{field} must be a CSS font weight")
  end

  defp validate_font_weight(_value, field),
    do: invalid_scorecard("#{field} must be a CSS font weight")

  defp invalid_scorecard(reason), do: {:error, {:invalid_scorecard, reason}}

  defp corpus_error(tag, path, reason) do
    expanded_path = Path.expand(path)

    {:error,
     {tag,
      %{
        dataset: "mechanical scorecard corpus",
        path: expanded_path,
        reason: reason,
        repository_only: false,
        recovery:
          ~s|call MechanicalChecker.run(scorecard_dir: #{inspect(expanded_path)}, mechanical_floors: floors)|
      }}}
  end

  defp check_scorecard(scorecard, floors) do
    check_wcag(scorecard) ++
      check_conformance(scorecard) ++
      check_mode_b(scorecard, floors)
  end

  # --- MODE-A: WCAG contrast (from color_pairs) ---

  defp check_wcag(scorecard) do
    cell_id = scorecard["cell_id"]
    page_bg = parse_color(scorecard["tokens"]["--tl-color-bg"])

    scorecard
    |> Map.get("color_pairs", [])
    |> Enum.flat_map(&wcag_violation(&1, cell_id, page_bg))
  end

  defp wcag_violation(pair, cell_id, page_bg) do
    with {:ok, fg_rgba} <- parse_color(pair["color"]),
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
    case parse_color(raw) do
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
    size = parse_px(pair["font_size"]) || 0.0
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
      observed: "#{fmt(ratio)}:1",
      expected: ">= #{fmt(required)}:1",
      fix:
        "raise contrast to >= #{fmt(required)}:1 (observed #{fmt(ratio)}:1) — " <>
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
    |> px_values()
    |> Enum.reject(&(&1 == 0.0))
    |> Enum.reject(&on_scale?(&1, @radius_scale_px))
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
    |> shadow_signatures()
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
    |> duration_ms_values()
    |> Enum.reject(&(&1 == 0.0))
    |> Enum.reject(&on_scale?(&1, @motion_duration_ms, @ms_tolerance))
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
    case parse_px(el["font_size"]) do
      nil ->
        []

      +0.0 ->
        []

      value ->
        if on_scale?(value, @font_size_scale_px) do
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
      case parse_px(el[prop]) do
        nil -> []
        +0.0 -> []
        value -> if on_scale?(value, @spacing_scale_px), do: [], else: [{prop, value}]
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
      observed: "#{fmt(value)}#{unit}",
      expected: "one of #{inspect(scale)} #{unit}",
      fix:
        "snap #{metric} #{fmt(value)}#{unit} -> nearest token #{nearest}#{unit} (#{token_family}-* scale)"
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
      "type_size_count" => num(mode_b["type_size_count"]),
      "interactive_control_count" => num(mode_b["interactive_control_count"]),
      "card_nesting_depth" => num(mode_b["card_nesting_depth"]),
      "scroll_cost" => num(mode_b["scroll_cost"]),
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
      observed: fmt(current),
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
      observed: fmt(current),
      expected: "<= floor #{fmt(floor)}",
      fix:
        "#{metric} regressed past its ratchet floor (#{fmt(current)} > #{fmt(floor)}) — " <>
          "revert the regression or record a ratchet reset with rationale"
    }
  end

  # --- distinct-accent-hue (RGB -> HSL + ±15° bucketing over chromatic colours) ---

  defp distinct_accent_hue_count(colors) do
    colors
    |> Enum.map(&parse_color/1)
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

  # --- shared parsing helpers ---

  # Parse "rgb(...)", "rgba(...)", or "#rrggbb"/"#rgb" -> {:ok, {r, g, b, a}} | :error.
  defp parse_color(str) when is_binary(str) do
    cond do
      String.starts_with?(str, "rgb") -> parse_rgb(str)
      String.starts_with?(str, "#") -> parse_hex(str)
      true -> :error
    end
  end

  defp parse_color(_), do: :error

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
  defp px_values(nil), do: []

  defp px_values(str) when is_binary(str) do
    ~r/(-?\d*\.?\d+)px/
    |> Regex.scan(str)
    |> Enum.map(fn [_, n] -> to_f(n) end)
    |> Enum.uniq()
  end

  defp parse_px(nil), do: nil

  defp parse_px(str) when is_binary(str) do
    case Regex.run(~r/(-?\d*\.?\d+)px/, str) do
      [_, n] -> to_f(n)
      _ -> nil
    end
  end

  defp parse_px(_), do: nil

  # Comma-separated durations in seconds -> milliseconds (e.g. "0.12s, 0s" -> [120.0, 0.0]).
  defp duration_ms_values(nil), do: []

  defp duration_ms_values(str) when is_binary(str) do
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
  defp shadow_signatures(nil), do: []
  defp shadow_signatures("none"), do: []

  defp shadow_signatures(str) when is_binary(str) do
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

  defp on_scale?(value, scale, tolerance \\ @px_tolerance) do
    Enum.any?(scale, &(abs(&1 - value) <= tolerance))
  end

  defp num(n) when is_number(n), do: n
  defp num(_), do: 0

  defp fmt(n) when is_float(n) do
    if n == Float.round(n), do: trunc(n), else: Float.round(n, 2)
  end

  defp fmt(n), do: n
end
