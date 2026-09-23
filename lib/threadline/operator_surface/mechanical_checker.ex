defmodule Threadline.OperatorSurface.MechanicalChecker do
  @moduledoc false

  alias Threadline.OperatorSurface.MechanicalChecker.AccentHue
  alias Threadline.OperatorSurface.MechanicalChecker.Contrast
  alias Threadline.OperatorSurface.MechanicalChecker.Parsing
  alias Threadline.OperatorSurface.MechanicalChecker.RatchetMetrics
  alias Threadline.OperatorSurface.MechanicalChecker.Scorecards
  alias Threadline.OperatorSurface.MechanicalChecker.TokenConformance

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

  # MODE-B metrics keyed as they appear in mechanical_floors[ledger_id][metric][theme_bp].
  @mode_b_metrics ~w(
    type_size_count
    interactive_control_count
    card_nesting_depth
    scroll_cost
    distinct_accent_hue_count
  )

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
    Contrast.check(scorecard, wcag_thresholds()) ++
      TokenConformance.check(scorecard, token_scales()) ++
      RatchetMetrics.check(scorecard, floors, mode_b_limits(scorecard))
  end

  defp wcag_thresholds do
    %{
      text: @wcag_text_contrast_ratio,
      large_text: @wcag_large_text_contrast_ratio,
      non_text: @wcag_non_text_contrast_ratio,
      large_text_px: @wcag_large_text_px,
      large_text_bold_px: @wcag_large_text_bold_px
    }
  end

  defp token_scales do
    %{
      radius: @radius_scale_px,
      motion: @motion_duration_ms,
      font_size: @font_size_scale_px,
      spacing: @spacing_scale_px
    }
  end

  defp mode_b_limits(scorecard) do
    %{
      metrics: @mode_b_metrics,
      measured: measure_mode_b(scorecard),
      ceilings: %{
        "card_nesting_depth" => @mode_b_card_nesting_ceiling,
        "distinct_accent_hue_count" => @mode_b_distinct_accent_hue_ceiling
      }
    }
  end

  @doc """
  Returns the measured MODE-B metric values for a decoded scorecard as a map
  keyed by the `@mode_b_metrics` names.

  This is the single source of truth for MODE-B measurement: the MODE-B check
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
      "distinct_accent_hue_count" => AccentHue.count(scorecard["applied_colors"] || [])
    }
  end
end
