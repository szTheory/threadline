defmodule Threadline.CriticTrust.KrippendorffAlphaTest do
  use ExUnit.Case, async: true

  alias Threadline.CriticTrust.KrippendorffAlpha

  # ── perfect agreement ──────────────────────────────────────────────────────

  test "perfect agreement (all pairs agree) returns {:ok, 1.0}" do
    pairs = [{1, 1}, {2, 2}, {3, 3}, {1, 1}, {2, 2}]
    assert {:ok, 1.0} == KrippendorffAlpha.compute(pairs)
  end

  # ── De=0 (all identical values, no disagreement possible) ──────────────────

  test "all identical values (De=0) returns {:ok, 1.0}" do
    pairs = [{2, 2}, {2, 2}, {2, 2}]
    assert {:ok, 1.0} == KrippendorffAlpha.compute(pairs)
  end

  # ── systematic worse-than-chance (negative alpha, must NOT be clamped) ─────

  test "systematic disagreement returns negative alpha (not clamped)" do
    # Rater 1 always gives 1, Rater 2 always gives 3 — maximum disagreement.
    # α < 0 is a valid signal — never clamp.
    pairs = [{1, 3}, {1, 3}, {1, 3}, {1, 3}]
    assert {:ok, alpha} = KrippendorffAlpha.compute(pairs)
    assert alpha < 0,
           "systematic disagreement must produce alpha < 0, got #{inspect(alpha)}"
  end

  # ── insufficient data ──────────────────────────────────────────────────────

  test "empty list returns {:error, :insufficient_data}" do
    assert {:error, :insufficient_data} == KrippendorffAlpha.compute([])
  end

  test "single pair returns {:error, :insufficient_data}" do
    assert {:error, :insufficient_data} == KrippendorffAlpha.compute([{1, 2}])
  end

  # ── reference vectors ──────────────────────────────────────────────────────

  test "mostly-agreeing 3-category pairs produces positive alpha below 1.0" do
    # 3 exact agreements + 2 adjacent mismatches — should be moderately reliable
    pairs = [{1, 1}, {2, 2}, {3, 3}, {1, 2}, {2, 3}]
    assert {:ok, alpha} = KrippendorffAlpha.compute(pairs)
    assert alpha > 0.0, "expected alpha > 0 for mostly-agreeing pairs, got #{alpha}"
    assert alpha < 1.0, "expected alpha < 1 for partially-disagreeing pairs, got #{alpha}"
  end

  test "binary ordinal — 3/4 agreement produces positive alpha below 1.0" do
    pairs = [{1, 1}, {1, 1}, {2, 2}, {1, 2}]
    assert {:ok, alpha} = KrippendorffAlpha.compute(pairs)
    assert alpha > 0.0, "expected positive alpha for 3/4 agreement, got #{alpha}"
    assert alpha < 1.0, "expected alpha < 1 for partial agreement, got #{alpha}"
  end

  test "known alpha value is correct within 1e-6 tolerance" do
    # Exact case: 4 pairs all systematically reversed on a 3-point scale.
    # Rater 1 always 1, Rater 2 always 3 — worst-case systematic disagreement.
    # With freq = {1: 4, 3: 4}, n = 8:
    #   coincidences: {1,3}=4, {3,1}=4 (no diagonal)
    #   ordinal d²(1,3): range_sum = 4+4 = 8, delta = 8 - (4+4)/2 = 4, d² = 16
    #   Do = (4*16 + 4*16) / 2 = 64
    #   e_{1,3} = 4*4/(8-1) = 16/7
    #   De = (16/7*16 + 16/7*16) / 2 = (256/7*2)/2 = 256/7 ≈ 36.571
    #   α = 1 - 64 / (256/7) = 1 - 64*7/256 = 1 - 448/256 = 1 - 1.75 = -0.75
    pairs = [{1, 3}, {1, 3}, {1, 3}, {1, 3}]
    assert {:ok, alpha} = KrippendorffAlpha.compute(pairs)
    assert_in_delta alpha, -0.75, 1.0e-6
  end

  # ── bootstrap CI ──────────────────────────────────────────────────────────

  test "bootstrap_ci/1 returns {:ok, {lo, hi}} with lo <= hi for n>=20" do
    # 20 pairs: 15 agreements + 5 mismatches on a 3-value scale
    pairs = build_pairs(20)

    :rand.seed(:exsss, {42, 0, 0})
    assert {:ok, {lo, hi}} = KrippendorffAlpha.bootstrap_ci(pairs)
    assert is_float(lo), "CI lower bound must be a float, got #{inspect(lo)}"
    assert is_float(hi), "CI upper bound must be a float, got #{inspect(hi)}"
    assert lo <= hi, "CI lower bound #{lo} must be <= upper bound #{hi}"
  end

  test "bootstrap_ci/1 is deterministic for the same RNG seed" do
    pairs = build_pairs(20)

    :rand.seed(:exsss, {42, 0, 0})
    assert {:ok, result1} = KrippendorffAlpha.bootstrap_ci(pairs)

    :rand.seed(:exsss, {42, 0, 0})
    assert {:ok, result2} = KrippendorffAlpha.bootstrap_ci(pairs)

    assert result1 == result2,
           "bootstrap_ci must be deterministic for the same RNG seed, " <>
             "got #{inspect(result1)} vs #{inspect(result2)}"
  end

  # ── helpers ───────────────────────────────────────────────────────────────

  # Build 20 pairs: 15 exact agreements (values cycling 1..3) + 5 mismatches
  defp build_pairs(count) do
    for i <- 1..count do
      v = rem(i - 1, 3) + 1
      if rem(i, 4) == 0, do: {v, rem(v, 3) + 1}, else: {v, v}
    end
  end
end
