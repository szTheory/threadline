defmodule Threadline.CriticTrust.Measure do
  @moduledoc """
  Pure engine that turns an **oracle set** + the critic's scores into the per-lens
  `critic_trust` block written to `.planning/design-system-ledger.json`.

  The oracle is label-source-agnostic (this engine only needs items carrying an
  `r1.verdict`): either the maintainer's human `golden-set.json`, or — under D-12 —
  the constructed `synthetic-set.json` (a graded twin-severity ladder, verdicts known
  by construction). Synthetic validation proves the critic tracks known-severity
  flaws monotonically on held-out rungs; it is NOT a claim of taste-agreement on
  ambiguous UI. The oracle used is recorded honestly in the sibling
  `critic_trust_provenance` ledger block (written by `mix critic.measure`).

  This is the measurement/writer half of CRITIC-03: `mix critic.measure` (the IO
  shell in `Mix.Tasks.Critic.Measure`) reads the files, calls `build_block/4`, and
  splices the result via `Threadline.CriticTrust.LedgerSplice`. The guard
  `mix verify.critic_trust` (in `ci.all`) then *asserts* the block this produces.

  Kept pure (no file IO) so it is unit-testable in memory.

  ## Trust metric (ranking, not agreement)

  Per resolved cell we take:

    * Oracle ordinal — the set's `r1.verdict` bucketed `broken → 1, bad → 2,
      borderline → 3, good → 4`. The oracle is either a human label (golden-set.json) or
      a **constructed** graded-twin label (synthetic-set.json, D-12) — this engine does
      not care which. Single-kind items only.
    * Critic score — the **mean of the stable dimensions' median scores** (0..100), the
      continuous ranking signal. (A legacy `min()` band, crosswalked
      `fail → 1 … strong/exemplary → 4`, is also kept for the companion α.)

  The **primary trust metric is Spearman's ρ** between the oracle ordinal and the critic
  score (`RankMetrics.spearman/2`) — it rewards correct *ordering* of severity, which is
  what a forward-only ratchet needs, and tolerates the critic's scale *compression*.
  `auc` (`RankMetrics.auc/1`) reports good-vs-bad separation. `alpha` (Krippendorff
  band-agreement) and `raw_agreement` (exact-bucket match) are retained as reported-only
  companions — they sink on a compressing critic even when its ranking is strong, so they
  no longer gate. `pairwise_acc` stays `nil`.

  ## Promotion

  A lens is `validated: true` only when **all** hold: `spearman >= 0.7`,
  `n >= 20`, `model_id == "claude-opus-4-8"`, and every contributing score was produced
  at the current rubric version (auto-invalidation on a rubric or model bump). Otherwise
  the measured numbers are still written (honest provisional). All 6 lenses are emitted
  every run.
  """

  alias Threadline.CriticTrust.{KrippendorffAlpha, RankMetrics}

  @lenses ~w(hierarchy density rhythm typography color_contrast brand_fidelity)
  @model_pin "claude-opus-4-8"

  # Primary trust bar: Spearman's ρ between oracle severity and the critic's continuous
  # per-cell score (ranking, not agreement — the critic ranks well but compresses the scale).
  @spearman_bar 0.7

  # Oracle verdict bucket → ordinal (single-kind items only). "Oracle" = the set's
  # r1.verdict, whether human-labeled or constructed by the graded-twin ladder (D-12).
  @oracle %{"broken" => 1, "bad" => 2, "borderline" => 3, "good" => 4}
  # Critic band → ordinal (strong and exemplary both fold to "good" to match oracle granularity).
  @band %{"fail" => 1, "weak" => 2, "ok" => 3, "strong" => 4, "exemplary" => 4}

  # Fixed field order — matches the committed ledger block for a minimal diff.
  # `spearman` (primary gate) + `auc` (companion) lead; `alpha`/`raw_agreement` are
  # retained as reported-only companions (D-12 gate revision v2 — ranking, not agreement).
  @field_order ~w(spearman auc alpha raw_agreement pairwise_acc n ci95 golden_rubric_version model_id validated)

  @default_seed 424_242

  @doc "The 6 frozen critic lenses, in ledger order."
  def lenses, do: @lenses

  @doc "The per-lens field order emitted into the ledger block."
  def field_order, do: @field_order

  @doc "The pinned model id required for a validated lens."
  def model_pin, do: @model_pin

  @doc """
  Build the full `critic_trust` block (all 6 lenses) as a plain map.

    * `golden` — decoded `golden-set.json` (a map with `"items"`).
    * `scores` — `%{{cell_id, lens} => [dim, ...]}` where each `dim` is
      `%{band: String.t() | nil, stable: boolean(), model_id: String.t(),
         rubric_version: String.t()}`.
    * `rubric_versions` — `%{lens => "<lens>@<semver>+<sha8>"}` (or `nil` per lens).
    * `seed` — deterministic RNG seed for the bootstrap CI (default `#{@default_seed}`).

  Returns `%{lens => %{"alpha" => ..., ...8 fields...}}`.
  """
  def build_block(golden, scores, rubric_versions, seed \\ @default_seed) do
    :rand.seed(:exsss, {seed, 0, 0})
    items = Map.get(golden, "items", []) || []

    Map.new(@lenses, fn lens ->
      {lens, measure_lens(lens, items, scores, rubric_versions)}
    end)
  end

  defp measure_lens(lens, items, scores, rubric_versions) do
    current_version = Map.get(rubric_versions || %{}, lens)

    resolved =
      items
      |> Enum.filter(fn it ->
        it["lens"] == lens and it["kind"] == "single" and Map.get(it, "kept", true) != false
      end)
      |> Enum.flat_map(&resolve(&1, lens, scores, current_version))

    n = length(resolved)

    # Primary gate: Spearman's ρ (oracle severity vs the critic's continuous score).
    spearman =
      case RankMetrics.spearman(Enum.map(resolved, & &1.oracle), Enum.map(resolved, & &1.score)) do
        {:ok, r} -> r
        {:error, _} -> nil
      end

    # Companion: good-vs-bad separation over the continuous score.
    auc =
      case RankMetrics.auc(Enum.map(resolved, &{&1.score, &1.oracle})) do
        {:ok, a} -> a
        {:error, _} -> nil
      end

    # Legacy companions (reported, never gate): band-agreement α + raw exact-match.
    band_pairs = Enum.map(resolved, &{&1.oracle, &1.band})
    {alpha, ci95} = alpha_and_ci(band_pairs)

    raw =
      if n > 0, do: Enum.count(resolved, &(&1.oracle == &1.band)) / n, else: nil

    model_id =
      case resolved do
        [] -> @model_pin
        [r | _] -> r.model_id || @model_pin
      end

    fresh = resolved != [] and Enum.all?(resolved, & &1.fresh)

    # D-12 gate revision v2: the trust bar is a RANKING correlation, not agreement. A
    # forward-only ratchet asks "did this get worse?" (ordering) — and the critic ranks
    # severity well (ρ) even though it compresses the exact scale (which sank α/raw). α +
    # raw_agreement stay as reported-only companions; auc is a separation sanity check.
    validated =
      is_number(spearman) and spearman >= @spearman_bar and n >= 20 and
        model_id == @model_pin and fresh

    %{
      "spearman" => spearman,
      "auc" => auc,
      "alpha" => alpha,
      "raw_agreement" => raw,
      "pairwise_acc" => nil,
      "n" => n,
      "ci95" => ci95,
      "golden_rubric_version" => if(n > 0, do: current_version, else: nil),
      "model_id" => model_id,
      "validated" => validated
    }
  end

  # Resolve one oracle item into zero or one record with the oracle ordinal, the critic's
  # continuous per-cell score (mean of stable dims' median scores — the ranking signal),
  # the min-band (legacy α companion), and provenance.
  defp resolve(item, lens, scores, current_version) do
    oracle = Map.get(@oracle, get_in(item, ["r1", "verdict"]))
    dims = Map.get(scores, {item["cell_id"], lens}, [])
    stable_dims = Enum.filter(dims, & &1.stable)

    bands =
      stable_dims
      |> Enum.map(&Map.get(@band, &1.band))
      |> Enum.reject(&is_nil/1)

    dim_scores = stable_dims |> Enum.map(& &1.score) |> Enum.filter(&is_number/1)

    if oracle == nil or bands == [] or dim_scores == [] do
      []
    else
      fresh =
        Enum.all?(stable_dims, fn d ->
          d.model_id == @model_pin and d.rubric_version == current_version
        end)

      [
        %{
          oracle: oracle,
          score: Enum.sum(dim_scores) / length(dim_scores),
          band: Enum.min(bands),
          model_id: List.first(stable_dims).model_id,
          fresh: fresh
        }
      ]
    end
  end

  defp alpha_and_ci([]), do: {nil, nil}

  defp alpha_and_ci(pairs) do
    alpha =
      case KrippendorffAlpha.compute(pairs) do
        {:ok, a} -> a
        {:error, _} -> nil
      end

    ci95 =
      case KrippendorffAlpha.bootstrap_ci(pairs) do
        {:ok, {lo, hi}} -> [lo, hi]
        {:error, _} -> nil
      end

    {alpha, ci95}
  end
end
