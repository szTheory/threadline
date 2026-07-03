defmodule Threadline.CriticTrust.KrippendorffAlpha do
  @moduledoc """
  Pure-Elixir Krippendorff's alpha (ordinal distance function) for two raters.

  Computes the chance-corrected inter-rater agreement coefficient α over a list
  of `{r1_value, r2_value}` ordinal pairs. Used by `mix verify.critic_trust` to
  gate per-lens critic trust (CRITIC-03).

  ## Formula (ordinal coincidence matrix, Krippendorff 2011)

      α = 1 − Dₒ / Dₑ

  where:
  - Dₒ = observed disagreement (weighted sum over the coincidence matrix)
  - Dₑ = expected disagreement (what chance agreement predicts)

  The ordinal distance between categories v and v' is:

      d²(v, v') = (Σ_{g=v}^{v'} n_g − (n_v + n_v') / 2)²

  where n_g is the marginal frequency of category g across both raters.

  ## Edge cases

  - Perfect agreement: Dₒ = 0, returns `{:ok, 1.0}`.
  - All raters use a single value (Dₑ = 0): convention is `{:ok, 1.0}` (no
    disagreement is possible; reliability is maximum by definition).
  - Systematic agreement worse than chance: returns `{:ok, alpha}` where
    `alpha < 0`. **Never clamp** — a negative α is a meaningful signal (the
    critic disagrees with the human oracle more than chance predicts).
  - Fewer than 2 pairs: returns `{:error, :insufficient_data}`.

  No external dependencies — safe in `ci.all` alongside `stress_ledger_test.exs`.
  """

  @doc """
  Computes Krippendorff's α (ordinal) for two raters.

  ## Parameters

    - `pairs` — list of `{r1_value, r2_value}` ordinal pairs. Values must be
      comparable terms (integers, atoms, or any type with a natural sort order).

  ## Returns

    - `{:ok, alpha}` — chance-corrected coefficient. May be negative.
    - `{:error, :insufficient_data}` — fewer than 2 pairs provided.

  ## Examples

      iex> alias Threadline.CriticTrust.KrippendorffAlpha
      iex> KrippendorffAlpha.compute([{1, 1}, {2, 2}, {3, 3}])
      {:ok, 1.0}

      iex> KrippendorffAlpha.compute([{1, 2}])
      {:error, :insufficient_data}
  """
  @spec compute([{term(), term()}]) :: {:ok, float()} | {:error, :insufficient_data}
  def compute(pairs) when is_list(pairs) do
    # n = total number of observations = 2 × n_pairs (one per rater per item)
    n = length(pairs) * 2

    if n < 4 do
      {:error, :insufficient_data}
    else
      all_values = Enum.flat_map(pairs, fn {v1, v2} -> [v1, v2] end)
      freq = Enum.frequencies(all_values)
      sorted_values = freq |> Map.keys() |> Enum.sort()

      # Build the coincidence matrix o_{v,v'}.
      # For 2 raters each pair {v1, v2} contributes:
      #   v1 == v2  →  +2 to o_{v1,v1}
      #   v1 != v2  →  +1 to o_{v1,v2} and +1 to o_{v2,v1}  (symmetric)
      coincidences =
        Enum.reduce(pairs, %{}, fn {v1, v2}, acc ->
          if v1 == v2 do
            Map.update(acc, {v1, v1}, 2, &(&1 + 2))
          else
            acc
            |> Map.update({v1, v2}, 1, &(&1 + 1))
            |> Map.update({v2, v1}, 1, &(&1 + 1))
          end
        end)

      do_ = weighted_sum(coincidences, sorted_values, freq, n, :observed)
      de_ = weighted_sum(coincidences, sorted_values, freq, n, :expected)

      if de_ == 0.0 do
        # All raters used a single value; no disagreement was possible.
        {:ok, 1.0}
      else
        {:ok, 1.0 - do_ / de_}
      end
    end
  end

  @doc """
  Bootstrap 95% confidence interval for α.

  Resamples `pairs` with replacement `b` times (default 1 000) and returns the
  `alpha_level / 2` and `(1 − alpha_level / 2)` percentiles.

  Determinism depends on the calling process's RNG state. Seed before calling
  if you need reproducible results:

      :rand.seed(:exsss, {42, 0, 0})
      {:ok, {lo, hi}} = KrippendorffAlpha.bootstrap_ci(pairs)

  ## Returns

    - `{:ok, {lo, hi}}` — lo and hi are floats; lo ≤ hi.
    - `{:error, :insufficient_bootstrap_data}` — all resamples returned `:insufficient_data`.
  """
  @spec bootstrap_ci([{term(), term()}], pos_integer(), float()) ::
          {:ok, {float(), float()}} | {:error, :insufficient_bootstrap_data}
  def bootstrap_ci(pairs, b \\ 1_000, alpha_level \\ 0.05) do
    n = length(pairs)

    alphas =
      1..b
      |> Enum.map(fn _ ->
        # Resample with replacement: draw n items independently from `pairs`.
        sample = for _ <- 1..n, do: Enum.at(pairs, :rand.uniform(n) - 1)

        case compute(sample) do
          {:ok, a} -> a
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort()

    case alphas do
      [] ->
        {:error, :insufficient_bootstrap_data}

      [_single] ->
        {:error, :insufficient_bootstrap_data}

      sorted ->
        m = length(sorted)
        lo_idx = max(0, floor(m * alpha_level / 2))
        hi_idx = min(m - 1, floor(m * (1 - alpha_level / 2)))
        {:ok, {Enum.at(sorted, lo_idx) * 1.0, Enum.at(sorted, hi_idx) * 1.0}}
    end
  end

  # ── Private helpers ────────────────────────────────────────────────────────

  # Compute the weighted sum of either the observed or expected coincidence counts,
  # using the ordinal distance² as the weight.
  #
  # The full matrix is symmetric: every (v, v') is paired with (v', v).
  # We sum over all ordered pairs and divide by 2 at the end to avoid
  # double-counting. The factor cancels in α = 1 − Dₒ/Dₑ.
  defp weighted_sum(coincidences, sorted_values, freq, n, kind) do
    all_pairs = for v <- sorted_values, v2 <- sorted_values, do: {v, v2}

    sum =
      Enum.reduce(all_pairs, 0.0, fn {v, v2}, acc ->
        w = ordinal_distance_sq(v, v2, sorted_values, freq)

        contribution =
          case kind do
            :observed ->
              Map.get(coincidences, {v, v2}, 0) * w

            :expected ->
              e =
                if v == v2 do
                  # Diagonal: n_v choose 2 (coincidences within the same category)
                  freq[v] * (freq[v] - 1) / (n - 1)
                else
                  # Off-diagonal: product of marginals, normalised by n−1
                  freq[v] * freq[v2] / (n - 1)
                end

              e * w
          end

        acc + contribution
      end)

    sum / 2.0
  end

  # d²(v, v) = 0.
  defp ordinal_distance_sq(v, v2, _sorted_values, _freq) when v == v2, do: 0.0

  # d²(v, v') — the Krippendorff ordinal metric squared.
  #
  # Sum the marginal frequencies of all categories g in [min(v,v'), max(v,v')]
  # (inclusive), then subtract half the endpoint frequencies, and square:
  #
  #   delta = Σ_{g=lo}^{hi} n_g  −  (n_lo + n_hi) / 2
  #   d²(v, v') = delta²
  defp ordinal_distance_sq(v, v2, sorted_values, freq) do
    lo = min(v, v2)
    hi = max(v, v2)

    range_sum =
      sorted_values
      |> Enum.filter(&(&1 >= lo and &1 <= hi))
      |> Enum.reduce(0, fn g, acc -> acc + Map.get(freq, g, 0) end)

    delta = range_sum - (Map.get(freq, lo, 0) + Map.get(freq, hi, 0)) / 2.0
    delta * delta
  end
end
