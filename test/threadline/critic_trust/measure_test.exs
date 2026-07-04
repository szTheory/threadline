defmodule Threadline.CriticTrust.MeasureTest do
  use ExUnit.Case, async: true

  alias Threadline.CriticTrust.Measure

  @ver "hierarchy@1.0.0+aaaaaaaa"
  @pin "claude-opus-4-8"

  @matched %{"good" => "strong", "borderline" => "ok", "bad" => "weak", "broken" => "fail"}
  @required ~w(alpha ci95 golden_rubric_version model_id n pairwise_acc raw_agreement validated)

  defp gitem(cell, lens, verdict, kept \\ true) do
    %{
      "id" => cell,
      "cell_id" => cell,
      "lens" => lens,
      "kind" => "single",
      "kept" => kept,
      "r1" => %{"verdict" => verdict, "evidence" => "e1", "blind" => true},
      "r2" => %{"verdict" => verdict, "evidence" => "e2", "blind" => true}
    }
  end

  defp dim(band, opts \\ []) do
    %{
      band: band,
      stable: Keyword.get(opts, :stable, true),
      model_id: Keyword.get(opts, :model, @pin),
      rubric_version: Keyword.get(opts, :ver, @ver)
    }
  end

  # 24 perfectly-agreeing hierarchy items spread across good/borderline/bad.
  defp agreeing_24(score_opts \\ []) do
    verdicts = for i <- 0..23, do: Enum.at(["good", "borderline", "bad"], rem(i, 3))

    items =
      for {v, i} <- Enum.with_index(verdicts), do: gitem("h#{i}", "hierarchy", v)

    scores =
      Map.new(Enum.with_index(verdicts), fn {v, i} ->
        {{"h#{i}", "hierarchy"}, [dim(@matched[v], score_opts)]}
      end)

    {%{"items" => items}, scores}
  end

  defp versions, do: %{"hierarchy" => @ver}

  test "every lens emits exactly the guard's 8-field key set" do
    block = Measure.build_block(%{"items" => []}, %{}, %{})

    assert Map.keys(block) |> Enum.sort() == Enum.sort(Measure.lenses())

    for lens <- Measure.lenses() do
      assert block[lens] |> Map.keys() |> Enum.sort() == Enum.sort(@required),
             "lens #{lens} field-set drift"
    end
  end

  test "empty golden set → vacuous block (matches the committed skeleton)" do
    block = Measure.build_block(%{"items" => []}, %{}, %{})

    for lens <- Measure.lenses() do
      d = block[lens]
      assert d["alpha"] == nil
      assert d["raw_agreement"] == nil
      assert d["pairwise_acc"] == nil
      assert d["n"] == 0
      assert d["ci95"] == nil
      assert d["golden_rubric_version"] == nil
      assert d["model_id"] == @pin
      assert d["validated"] == false
    end
  end

  test "promotes a lens that clears the full bar (α≥0.67 ∧ n≥20 ∧ raw≥0.80 ∧ fresh)" do
    {golden, scores} = agreeing_24()
    block = Measure.build_block(golden, scores, versions())
    h = block["hierarchy"]

    assert h["n"] == 24
    assert is_number(h["alpha"]) and h["alpha"] >= 0.67
    assert h["raw_agreement"] == 1.0
    assert h["model_id"] == @pin
    assert h["golden_rubric_version"] == @ver
    assert [_lo, _hi] = h["ci95"]
    assert h["validated"] == true

    # Lenses with no labels stay provisional.
    assert block["density"]["validated"] == false
    assert block["density"]["n"] == 0
  end

  test "n < 20 stays provisional even at perfect agreement" do
    verdicts = for i <- 0..11, do: Enum.at(["good", "bad"], rem(i, 2))
    items = for {v, i} <- Enum.with_index(verdicts), do: gitem("h#{i}", "hierarchy", v)

    scores =
      Map.new(Enum.with_index(verdicts), fn {v, i} ->
        {{"h#{i}", "hierarchy"}, [dim(@matched[v])]}
      end)

    h = Measure.build_block(%{"items" => items}, scores, versions())["hierarchy"]

    assert h["n"] == 12
    assert is_number(h["alpha"])
    assert h["validated"] == false
  end

  test "stale rubric version blocks promotion (auto-invalidation)" do
    {golden, scores} = agreeing_24(ver: "hierarchy@0.9.0+deadbeef")
    h = Measure.build_block(golden, scores, versions())["hierarchy"]

    assert h["n"] == 24
    assert is_number(h["alpha"]) and h["alpha"] >= 0.67
    assert h["validated"] == false, "stale rubric must not validate"
  end

  test "model_id mismatch blocks promotion" do
    {golden, scores} = agreeing_24(model: "claude-sonnet-4-6")
    h = Measure.build_block(golden, scores, versions())["hierarchy"]

    assert h["validated"] == false
    assert h["model_id"] == "claude-sonnet-4-6"
  end

  test "critic value is the min() band across stable dims; unstable dims are dropped" do
    items = [gitem("c0", "hierarchy", "good"), gitem("c1", "hierarchy", "good")]

    scores = %{
      # c0: min(strong=4, ok=3) = 3 → mismatch vs human good=4
      {"c0", "hierarchy"} => [dim("strong"), dim("ok")],
      # c1: strong=4 stable; a fail=1 dim is unstable and must be ignored → 4 → match
      {"c1", "hierarchy"} => [dim("strong"), dim("fail", stable: false)]
    }

    h = Measure.build_block(%{"items" => items}, scores, versions())["hierarchy"]

    assert h["n"] == 2
    # one match (c1), one mismatch (c0) → raw 0.5 proves min() picked 3 for c0
    assert h["raw_agreement"] == 0.5
  end

  test "kept:false items and items without a stable critic score are skipped" do
    items = [
      gitem("k0", "hierarchy", "good"),
      gitem("k1", "hierarchy", "good", false),
      gitem("k2", "hierarchy", "good")
    ]

    scores = %{
      {"k0", "hierarchy"} => [dim("strong")],
      {"k1", "hierarchy"} => [dim("strong")],
      # k2 has only an unstable dim → no critic value → excluded
      {"k2", "hierarchy"} => [dim("strong", stable: false)]
    }

    h = Measure.build_block(%{"items" => items}, scores, versions())["hierarchy"]

    assert h["n"] == 1
  end

  test "bootstrap CI is deterministic for a fixed seed" do
    {golden, scores} = agreeing_24()
    a = Measure.build_block(golden, scores, versions())["hierarchy"]["ci95"]
    b = Measure.build_block(golden, scores, versions())["hierarchy"]["ci95"]
    assert a == b
  end
end
