defmodule Threadline.OperatorSurface.MechanicalCheckerTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.OperatorSurface.MechanicalChecker

  # House style mirrors brandbook_token_parity_test.exs + stress_ledger_test.exs:
  # File.read! at the top of each meta-test, one concern per block, custom failure
  # messages naming observed vs expected, async: true (pure filesystem + arithmetic,
  # no DB / browser / network). This file is `mix verify.mechanical`.

  @checker_path "lib/threadline/operator_surface/mechanical_checker.ex"
  @scorecards_dir ".planning/scorecards"

  # ---------------------------------------------------------------------------
  # Meta-test: MODE-A LOCKED constants are pinned verbatim in the source. This is
  # the parity lock — loosening a constant to fake a pass fails CI (T-194-07).
  # ---------------------------------------------------------------------------

  test "MODE-A LOCKED constants appear verbatim in mechanical_checker.ex" do
    source = File.read!(@checker_path)

    for {constant, value} <- [
          {"@wcag_text_contrast_ratio", "4.5"},
          {"@wcag_large_text_contrast_ratio", "3.0"},
          {"@wcag_non_text_contrast_ratio", "3.0"},
          {"@wcag_large_text_px", "24"},
          {"@wcag_large_text_bold_px", "18.66"},
          {"@mode_b_card_nesting_ceiling", "3"},
          {"@mode_b_distinct_accent_hue_ceiling", "3"}
        ] do
      assert String.contains?(source, "#{constant} #{value}"),
             "#{@checker_path} must declare #{constant} #{value} — MODE-A LOCKED constants may never be loosened"
    end
  end

  test "token scale constants match the style.ex --tl-* SSOT values" do
    source = File.read!(@checker_path)

    assert String.contains?(source, "@spacing_scale_px [4, 8, 12, 16, 20, 24, 32, 40, 48]"),
           "#{@checker_path} @spacing_scale_px must match the 9-step --tl-space-* scale from style.ex"

    assert String.contains?(source, "@radius_scale_px [3, 4, 6, 8, 12, 999]"),
           "#{@checker_path} @radius_scale_px must match the 6-value --tl-radius-* scale from style.ex"

    assert String.contains?(source, "@motion_duration_ms [120, 180, 240]"),
           "#{@checker_path} @motion_duration_ms must match --tl-motion-fast/base/slow from style.ex"

    assert String.contains?(source, "@font_size_scale_px [12, 13, 14, 15, 16, 20, 24, 32]"),
           "#{@checker_path} @font_size_scale_px must match the 8-step --tl-font-size-* scale from style.ex"
  end

  test "the WCAG formula uses the 2.4 gamma exponent, not 2.2 (Pitfall 4)" do
    source = File.read!(@checker_path)

    assert String.contains?(source, ":math.pow((srgb + 0.055) / 1.055, 2.4)"),
           "#{@checker_path} must linearize sRGB with the gamma 2.4 exponent — a 2.2 exponent silently mis-grades mid-tones"
  end

  # ---------------------------------------------------------------------------
  # WCAG unit tests (public relative_luminance/1 + contrast_ratio/2).
  # ---------------------------------------------------------------------------

  test "relative luminance endpoints are exact (white = 1.0, black = 0.0)" do
    assert MechanicalChecker.relative_luminance({255, 255, 255}) == 1.0,
           "pure white must have relative luminance 1.0"

    assert MechanicalChecker.relative_luminance({0, 0, 0}) == 0.0,
           "pure black must have relative luminance 0.0"
  end

  # NOTE (Rule 1 — plan factual fix): the plan/PATTERNS named thread-blue (79,140,255)
  # as the mid-tone that fails 4.5:1 but passes 3.0:1. Empirically thread-blue on the
  # dark bg is 5.885:1 — it correctly PASSES AA (the desirable brand outcome, and itself
  # a useful sanity check on the 2.4 gamma). To prove the dual-threshold band as intended
  # we use a muted steel mid-tone (110,118,134) which genuinely lands at ~4.15:1.
  test "a muted mid-tone on dark bg fails 4.5:1 normal text but passes 3.0:1 non-text (proves 2.4 gamma)" do
    dark_bg = MechanicalChecker.relative_luminance({11, 16, 32})

    mid = MechanicalChecker.relative_luminance({110, 118, 134})
    mid_ratio = MechanicalChecker.contrast_ratio(mid, dark_bg)

    assert mid_ratio < 4.5,
           "muted steel (110,118,134) on dark bg (11,16,32) must fail the 4.5:1 normal-text threshold, got #{mid_ratio}"

    assert mid_ratio >= 3.0,
           "muted steel (110,118,134) on dark bg (11,16,32) must pass the 3.0:1 non-text threshold, got #{mid_ratio}"

    # Sanity: thread-blue itself is a light accent that comfortably passes AA on dark.
    thread_blue = MechanicalChecker.relative_luminance({79, 140, 255})

    assert MechanicalChecker.contrast_ratio(thread_blue, dark_bg) >= 4.5,
           "thread-blue (79,140,255) on dark bg is a light accent and must pass 4.5:1"
  end

  test "contrast_ratio is order-independent" do
    a = MechanicalChecker.relative_luminance({255, 255, 255})
    b = MechanicalChecker.relative_luminance({11, 16, 32})

    assert MechanicalChecker.contrast_ratio(a, b) == MechanicalChecker.contrast_ratio(b, a),
           "contrast ratio must not depend on argument order"
  end

  # ---------------------------------------------------------------------------
  # run/1 integration + MODE-A/MODE-B fixture teeth. Every fixture is synthetic,
  # owned by this test, and written to a per-test tmp dir — so the checker is
  # provably correct with NO dependency on real captured scorecards existing.
  # ---------------------------------------------------------------------------

  test "run/1 over an all-passing scorecard returns {:ok, []}" do
    dir = write_fixtures([passing_scorecard()])

    assert MechanicalChecker.run(scorecard_dir: dir, mechanical_floors: %{}) == {:ok, []},
           "a fully token-conformant, high-contrast, within-ceiling scorecard must produce no violations"
  end

  test "run/1 over an empty/absent scorecards directory returns {:ok, []} (nothing to check)" do
    empty = Path.join(System.tmp_dir!(), "mech_empty_#{System.unique_integer([:positive])}")
    File.mkdir_p!(empty)

    assert MechanicalChecker.run(scorecard_dir: empty, mechanical_floors: %{}) == {:ok, []}
    assert MechanicalChecker.run(scorecard_dir: Path.join(empty, "does-not-exist")) == {:ok, []}
  end

  test "an off-scale border-radius yields a MODE-A radius violation carrying a nearest-token :fix" do
    card = passing_scorecard()
    off = put_in(card, ["element_styles"], [element_style(%{"border_radius" => "10px"})])
    dir = write_fixtures([off])

    assert {:error, violations} =
             MechanicalChecker.run(scorecard_dir: dir, mechanical_floors: %{})

    radius = Enum.find(violations, &(&1.metric == "border_radius"))

    assert radius, "off-scale 10px border-radius must produce a border_radius MODE-A violation"
    assert radius.mode == "A"
    assert radius.observed == "10px"

    assert String.contains?(radius.fix, "8px"),
           "the fix must name the nearest token 8px, got: #{radius.fix}"
  end

  test "an off-scale padding yields a MODE-A spacing violation with a nearest-token :fix" do
    card = passing_scorecard()
    off = put_in(card, ["element_styles"], [element_style(%{"padding_top" => "18px"})])
    dir = write_fixtures([off])

    assert {:error, violations} =
             MechanicalChecker.run(scorecard_dir: dir, mechanical_floors: %{})

    spacing = Enum.find(violations, &(&1.metric == "padding_top"))

    assert spacing, "18px padding must produce a padding_top MODE-A violation"

    assert String.contains?(spacing.fix, "16px") or String.contains?(spacing.fix, "20px"),
           "the fix must name the nearest token (16px or 20px), got: #{spacing.fix}"
  end

  test "a failing-contrast color pair yields a MODE-A wcag_contrast violation (RED teeth)" do
    card = passing_scorecard()
    # muted-grey body text on the dark surface — deliberately below 4.5:1.
    bad = put_in(card, ["color_pairs"], [color_pair(%{"color" => "rgb(90, 96, 110)"})])
    dir = write_fixtures([bad])

    assert {:error, violations} =
             MechanicalChecker.run(scorecard_dir: dir, mechanical_floors: %{})

    wcag = Enum.find(violations, &(&1.metric == "wcag_contrast"))

    assert wcag, "low-contrast body text must produce a wcag_contrast MODE-A violation"
    assert wcag.mode == "A"

    assert String.contains?(wcag.expected, "4.5"),
           "normal body text must be graded against the 4.5:1 threshold, got: #{wcag.expected}"
  end

  test "a card_nesting_depth of 4 yields a MODE-B far-ceiling violation" do
    card = passing_scorecard()
    deep = put_in(card, ["mode_b", "card_nesting_depth"], 4)
    dir = write_fixtures([deep])

    assert {:error, violations} =
             MechanicalChecker.run(scorecard_dir: dir, mechanical_floors: %{})

    nesting = Enum.find(violations, &(&1.metric == "card_nesting_depth"))

    assert nesting, "card_nesting_depth 4 must breach the >3 MODE-B far ceiling"
    assert nesting.mode == "B"
    assert nesting.observed == 4
    assert nesting.expected == "<= 3"
  end

  test "a card_nesting_depth of 4 is grandfathered when a recorded floor covers it" do
    card = passing_scorecard()
    deep = put_in(card, ["mode_b", "card_nesting_depth"], 4)
    dir = write_fixtures([deep])

    floors = %{
      "page.home.happy" => %{"card_nesting_depth" => %{"dark_1280" => 4}}
    }

    assert MechanicalChecker.run(scorecard_dir: dir, mechanical_floors: floors) == {:ok, []},
           "a pre-existing depth of 4 recorded as a floor must be grandfathered (green at phase end)"
  end

  test "worsening past a recorded MODE-B floor fails even when below the far ceiling" do
    card = passing_scorecard()
    worse = put_in(card, ["mode_b", "type_size_count"], 9)
    dir = write_fixtures([worse])

    floors = %{
      "page.home.happy" => %{"type_size_count" => %{"dark_1280" => 6}}
    }

    assert {:error, violations} =
             MechanicalChecker.run(scorecard_dir: dir, mechanical_floors: floors)

    ratchet = Enum.find(violations, &(&1.metric == "type_size_count"))

    assert ratchet, "type_size_count 9 above the recorded floor of 6 must fail the ratchet"
    assert ratchet.mode == "B"
  end

  test "more than 3 distinct accent hues breaches the MODE-B distinct-accent-hue ceiling" do
    card = passing_scorecard()

    # Four clearly-distinct chromatic hues: blue, cyan, iris, ember (+ grey, excluded).
    colors = [
      "rgb(79, 140, 255)",
      "rgb(78, 223, 209)",
      "rgb(138, 124, 255)",
      "rgb(255, 138, 91)",
      "rgb(120, 120, 120)"
    ]

    over = put_in(card, ["applied_colors"], colors)
    dir = write_fixtures([over])

    assert {:error, violations} =
             MechanicalChecker.run(scorecard_dir: dir, mechanical_floors: %{})

    hue = Enum.find(violations, &(&1.metric == "distinct_accent_hue_count"))

    assert hue, "4 distinct accent hues must breach the >3 far ceiling"
    assert hue.observed == 4
  end

  test "the Threadline accent family (thread-blue + stitch-blue count as one) stays within ceiling" do
    card = passing_scorecard()

    # thread-blue (~218°) + stitch-blue (~218°) = 1 bucket, cyan, iris = 3 distinct.
    colors = [
      "rgb(79, 140, 255)",
      "rgb(71, 129, 230)",
      "rgb(78, 223, 209)",
      "rgb(138, 124, 255)"
    ]

    ok = put_in(card, ["applied_colors"], colors)
    dir = write_fixtures([ok])

    assert MechanicalChecker.run(scorecard_dir: dir, mechanical_floors: %{}) == {:ok, []},
           "the two blues must bucket into one accent hue, keeping the page at 3 distinct hues"
  end

  test "run/1 against the committed .planning/scorecards is clean ({:ok, []})" do
    # At phase end this proves the real evidence passes. Locally the directory is
    # empty/absent (capture is CI-run), so this is a vacuously-clean "nothing to
    # check" result — the teeth above prove the checker still blocks real violations.
    assert {:ok, []} = MechanicalChecker.run(scorecard_dir: @scorecards_dir)
  end

  # ---------------------------------------------------------------------------
  # Fixture builders (synthetic, all-passing baseline; tests mutate one field).
  # ---------------------------------------------------------------------------

  defp passing_scorecard do
    %{
      "schema_version" => 1,
      "cell_id" => "page.home.happy__dark-1280",
      "ledger_id" => "page.home.happy",
      "theme" => "dark",
      "breakpoint" => 1280,
      "capture_tier" => "A",
      "band" => 1,
      "tokens" => %{"--tl-color-bg" => "rgb(11, 16, 32)"},
      "color_pairs" => [color_pair(%{})],
      "element_styles" => [element_style(%{})],
      "applied_colors" => ["rgb(215, 222, 234)", "rgb(79, 140, 255)"],
      "mode_b" => %{
        "type_size_count" => 5,
        "interactive_control_count" => 12,
        "card_nesting_depth" => 2,
        "scroll_cost" => 1.4,
        "font_sizes" => ["12px", "16px"]
      }
    }
  end

  # High-contrast fog-on-dark body text by default.
  defp color_pair(overrides) do
    Map.merge(
      %{
        "selector" => "p.tl-body",
        "color" => "rgb(215, 222, 234)",
        "background_color" => "rgb(11, 16, 32)",
        "font_size" => "16px",
        "font_weight" => "400"
      },
      overrides
    )
  end

  # Fully token-conformant element by default.
  defp element_style(overrides) do
    Map.merge(
      %{
        "selector" => "div.tl-home__card",
        "border_radius" => "8px",
        "box_shadow" => "none",
        "transition_duration" => "0s",
        "font_size" => "16px",
        "font_weight" => "400",
        "margin_top" => "0px",
        "margin_bottom" => "16px",
        "padding_top" => "16px",
        "padding_bottom" => "16px"
      },
      overrides
    )
  end

  defp write_fixtures(scorecards) do
    dir = Path.join(System.tmp_dir!(), "mech_fixtures_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    for card <- scorecards do
      path = Path.join(dir, "#{card["cell_id"]}.json")
      File.write!(path, Jason.encode!(card))
    end

    on_exit_rm(dir)
    dir
  end

  defp on_exit_rm(dir) do
    ExUnit.Callbacks.on_exit(fn -> File.rm_rf(dir) end)
  end
end
