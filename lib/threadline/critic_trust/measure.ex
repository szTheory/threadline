defmodule Threadline.CriticTrust.Measure do
  @moduledoc """
  Pure engine that turns the maintainer's golden-set labels + the critic's scores
  into the per-lens `critic_trust` block written to `.planning/design-system-ledger.json`.

  This is the measurement/writer half of CRITIC-03: `mix critic.measure` (the IO
  shell in `Mix.Tasks.Critic.Measure`) reads the files, calls `build_block/4`, and
  splices the result via `Threadline.CriticTrust.LedgerSplice`. The guard
  `mix verify.critic_trust` (in `ci.all`) then *asserts* the block this produces.

  Kept pure (no file IO) so it is unit-testable in memory.

  ## Agreement metric

  Both raters are placed on a shared 1..4 ordinal scale and fed to
  `Threadline.CriticTrust.KrippendorffAlpha.compute/1`:

    * Human verdict bucket — `broken → 1, bad → 2, borderline → 3, good → 4`
      (single-kind golden items; pairwise verdicts are excluded from α).
    * Critic — the `min()` band across a lens's stable dimension scorecards
      (D-06 "only as good as the worst-served"), crosswalked
      `fail → 1, weak → 2, ok → 3, strong → 4, exemplary → 4`.

  `raw_agreement` is the exact-bucket match rate over the `n` resolved pairs.
  `pairwise_acc` is emitted as `nil` — the label CLI does not yet persist pair
  margins, so no clear-margin pairs resolve (the guard never gates on it).

  ## Promotion

  A lens is `validated: true` only when **all** hold: `alpha >= 0.67`, `n >= 20`,
  `raw_agreement >= 0.80`, `model_id == "claude-opus-4-8"`, and every contributing
  score was produced at the current rubric version (auto-invalidation on a rubric
  or model bump). Otherwise the measured numbers are still written (honest
  provisional). All 6 lenses are emitted every run.
  """

  alias Threadline.CriticTrust.KrippendorffAlpha

  @lenses ~w(hierarchy density rhythm typography color_contrast brand_fidelity)
  @model_pin "claude-opus-4-8"

  # Human verdict bucket → ordinal (single-kind items only).
  @human %{"broken" => 1, "bad" => 2, "borderline" => 3, "good" => 4}
  # Critic band → ordinal (strong and exemplary both fold to "good" to match human granularity).
  @band %{"fail" => 1, "weak" => 2, "ok" => 3, "strong" => 4, "exemplary" => 4}

  # Fixed field order — matches the committed ledger block for a minimal diff.
  @field_order ~w(alpha raw_agreement pairwise_acc n ci95 golden_rubric_version model_id validated)

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

    pairs = Enum.map(resolved, &{&1.human, &1.critic})
    n = length(pairs)

    {alpha, ci95} = alpha_and_ci(pairs)

    raw =
      if n > 0 do
        Enum.count(resolved, &(&1.human == &1.critic)) / n
      else
        nil
      end

    model_id =
      case resolved do
        [] -> @model_pin
        [r | _] -> r.model_id || @model_pin
      end

    fresh = resolved != [] and Enum.all?(resolved, & &1.fresh)

    validated =
      is_number(alpha) and alpha >= 0.67 and n >= 20 and
        is_number(raw) and raw >= 0.80 and model_id == @model_pin and fresh

    %{
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

  # Resolve one golden item into zero or one {human, critic} pair with provenance.
  defp resolve(item, lens, scores, current_version) do
    human = Map.get(@human, get_in(item, ["r1", "verdict"]))
    dims = Map.get(scores, {item["cell_id"], lens}, [])
    stable_dims = Enum.filter(dims, & &1.stable)

    bands =
      stable_dims
      |> Enum.map(&Map.get(@band, &1.band))
      |> Enum.reject(&is_nil/1)

    if human == nil or bands == [] do
      []
    else
      fresh =
        Enum.all?(stable_dims, fn d ->
          d.model_id == @model_pin and d.rubric_version == current_version
        end)

      [
        %{
          human: human,
          critic: Enum.min(bands),
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
