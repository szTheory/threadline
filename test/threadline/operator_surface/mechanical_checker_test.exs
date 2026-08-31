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
  # scroll_cost capture-scope guards (phase-199).
  #
  # Background: `scroll_cost` spent four phases reading
  # `document.documentElement.scrollHeight` on /audit/__stress, where ~98.5% of the
  # document is the harness's own sidebar listing every registered stress story. The
  # metric therefore tracked the story catalog rather than the captured page, drifted
  # on every new story, and reddened `verify-capture`'s byte-stability step. See
  # .planning/audits/198-tier-a-byte-stability.md.
  #
  # Two things let that persist unnoticed for so long, and each gets a guard here:
  # the committed floors were never checked against the committed evidence, and
  # nothing asserted the measured values were even plausible.
  # ---------------------------------------------------------------------------

  # `refute.*.graded.*` cells are produced by operator-graded-capture.spec.ts, which
  # carries the identical document-scoped read and is deliberately NOT regenerated by
  # this authorization: their `scroll_cost` is rendered verbatim into the LLM critic's
  # prompt (e2e/critic/bundle.ts), so recapturing them can move per-lens agreement and
  # force critic-trust re-validation. They legitimately still hold document-scoped
  # values and are excluded here rather than silently normalised.
  defp product_scoped_scorecards do
    @scorecards_dir
    |> Path.join("*.json")
    |> Path.wildcard()
    |> Enum.reject(&String.contains?(Path.basename(&1), ".graded."))
    |> Enum.map(&{Path.basename(&1), &1 |> File.read!() |> Jason.decode!()})
  end

  test "committed scroll_cost values are product-scoped, not document-scoped" do
    # A correctly-scoped cell measures the preview panel against a 900px viewport and
    # lands well under 1.0. A document-scoped regression reads the whole stress-lab
    # page and lands near 40 — two orders of magnitude away, so this threshold needs no
    # precision to be decisive.
    offenders =
      for {name, sc} <- product_scoped_scorecards(),
          cost = get_in(sc, ["mode_b", "scroll_cost"]),
          is_number(cost) and cost >= 5.0,
          do: {name, cost}

    assert offenders == [],
           """
           These scorecards carry a scroll_cost >= 5.0, which means the capture is
           measuring the /audit/__stress harness document again instead of the product
           surface under test:

           #{Enum.map_join(offenders, "\n", fn {n, c} -> "  #{n}: #{c}" end)}

           Fix the capture scope in operator-tier-a-capture.spec.ts — `rawInputs` must read
           `main.scrollHeight` (the [data-testid="stress-preview"] element every sibling
           field is already scoped to), never `document.documentElement.scrollHeight`.
           Do not raise this threshold: the failure it catches is a ~70x error.
           """
  end

  test "committed mechanical_floors agree with the committed evidence they were seeded from" do
    # measure_mode_b/1 is documented as the single source of truth for MODE-B: the
    # checker ratchets against it and the floor seeder writes it. Nothing enforced that
    # until now, which is exactly how 120 floors sat frozen three capture generations
    # behind the evidence while the gate reported green.
    floors =
      ".planning/design-system-ledger.json"
      |> File.read!()
      |> Jason.decode!()
      |> Map.fetch!("mechanical_floors")

    drifted =
      for {_name, sc} <- product_scoped_scorecards(),
          ledger_id = sc["ledger_id"],
          recorded =
            get_in(floors, [ledger_id, "scroll_cost", "#{sc["theme"]}_#{sc["breakpoint"]}"]),
          not is_nil(recorded),
          measured = MechanicalChecker.measure_mode_b(sc)["scroll_cost"],
          measured != recorded,
          do: {sc["cell_id"], recorded, measured}

    assert drifted == [],
           """
           Recorded scroll_cost floors disagree with the committed scorecards they are
           supposed to have been seeded from:

           #{Enum.map_join(drifted, "\n", fn {cell, r, m} -> "  #{cell}: floor #{r}, evidence #{m}" end)}

           Re-seed from the evidence rather than editing either side by hand. A floor that
           drifts above its evidence makes the ratchet vacuous — it can no longer fail —
           which is worse than a red gate because it still reports green.
           """
  end

  test "the scroll_cost ratchet still has teeth against the committed evidence" do
    # Positive control. The two tests above assert a clean state; a clean state is also
    # what a broken checker reports. This proves the gate can still fail, using the real
    # committed floors rather than a synthetic fixture.
    case product_scoped_scorecards() do
      [] ->
        # Fresh clone with no captured evidence — the synthetic teeth above still apply.
        :ok

      [{_name, sample} | _] ->
        floors =
          ".planning/design-system-ledger.json"
          |> File.read!()
          |> Jason.decode!()
          |> Map.fetch!("mechanical_floors")

        worsened = update_in(sample, ["mode_b", "scroll_cost"], &(&1 + 0.01))
        dir = write_fixtures([worsened])

        assert {:error, violations} =
                 MechanicalChecker.run(scorecard_dir: dir, mechanical_floors: floors),
               "a scroll_cost worse than its recorded floor must fail the ratchet"

        assert Enum.any?(violations, &(&1.metric == "scroll_cost" and &1.mode == "B")),
               "expected a MODE-B scroll_cost ratchet violation, got: #{inspect(violations)}"
    end
  end

  test "the Tier A capture spec reads the product surface, not the document" do
    # Source pin, matching this file's existing idiom of locking LOCKED constants
    # against their source. Scoped to the Tier A spec only: the page/graded/storybook
    # capture specs legitimately still contain the document-scoped read pending their
    # own authorization, so a repo-wide assertion here would be wrong.
    spec =
      File.read!("examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts")

    assert String.contains?(spec, "main.scrollHeight"),
           "operator-tier-a-capture.spec.ts must scope scrollCost to the stress-preview element"

    refute String.contains?(spec, "document.documentElement.scrollHeight"),
           """
           operator-tier-a-capture.spec.ts reads document.documentElement.scrollHeight again.

           On /audit/__stress that is ~98.5% harness sidebar, so every committed cell's
           scroll_cost would once more grow with the story catalog and re-red the
           byte-stability gate on the next unrelated story registration.
           """
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

  # ---------------------------------------------------------------------------
  # Recurring integration gate: run/1 over the REAL committed Tier A evidence.
  # The blocks above prove the checker's teeth on synthetic fixtures; this block
  # asserts the committed .planning/scorecards/*.json are actually clean, so a
  # real MODE-A/B regression (or stale mechanical_floors) blocks CI. On a fresh
  # clone with no committed capture the dir is empty and run/1 is vacuously
  # {:ok, []} — still a valid pass.
  # ---------------------------------------------------------------------------

  test "run/1 is clean over the committed Tier A scorecards (real-evidence gate)" do
    committed = Path.wildcard(Path.join(@scorecards_dir, "*.json"))

    assert {:ok, []} == MechanicalChecker.run(),
           "MechanicalChecker.run/1 must be clean over the #{length(committed)} committed " <>
             "Tier A scorecards (0 = fresh clone, vacuously clean). Regenerate with " <>
             "`mix verify.capture` or fix the offending token/style source — never loosen " <>
             "the checker's LOCKED constants."
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
