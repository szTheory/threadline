defmodule Threadline.CriticTrust.RankMetrics do
  @moduledoc """
  Ranking / separation metrics for the critic trust gate (D-12 gate revision v2).

  Krippendorff's α measures exact-bucket *agreement*, which punishes a critic that
  ranks severity correctly but *compresses* the score scale (never using the full
  fail→exemplary range) — empirically how the LLM gestalt critic behaves. A
  forward-only ratchet only asks "did this get worse?" — i.e. correct *ordering* —
  so the trust bar is a rank correlation, not agreement.

    * `spearman/2` — Spearman's ρ between the oracle severity ordinal and the critic's
      continuous per-cell score (tie-aware average ranks; Pearson on the ranks).
    * `auc/1` — the Mann-Whitney separation P(good-tier score > bad-tier score), a
      reported companion: does the critic reliably put better UI above worse UI?

  Pure and dependency-light (mirrors `KrippendorffAlpha`).
  """

  @doc """
  Spearman's rank correlation ρ between two equal-length numeric lists.
  Returns `{:ok, rho}` or `{:error, reason}` (too few points, or a degenerate list
  with zero rank variance — e.g. all-equal scores).
  """
  @spec spearman([number()], [number()]) :: {:ok, float()} | {:error, atom()}
  def spearman(xs, ys)
      when is_list(xs) and is_list(ys) and length(xs) == length(ys) and length(xs) >= 3 do
    pearson(ranks(xs), ranks(ys))
  end

  def spearman(_, _), do: {:error, :too_few}

  @doc """
  Mann-Whitney AUC / separation: over `pairs` of `{critic_score, oracle_ordinal}`,
  the probability that a good-tier cell (oracle ≥ 3) outscores a bad-tier cell
  (oracle ≤ 2), counting ties as 0.5. `{:ok, auc}` or `{:error, :one_class}` when a
  tier is empty. 1.0 = perfect separation, 0.5 = chance.
  """
  @spec auc([{number(), integer()}]) :: {:ok, float()} | {:error, atom()}
  def auc(pairs) when is_list(pairs) do
    pos = for {s, o} <- pairs, o >= 3, do: s
    neg = for {s, o} <- pairs, o <= 2, do: s

    if pos == [] or neg == [] do
      {:error, :one_class}
    else
      wins =
        for p <- pos, n <- neg, reduce: 0.0 do
          acc ->
            cond do
              p > n -> acc + 1.0
              p == n -> acc + 0.5
              true -> acc
            end
        end

      {:ok, wins / (length(pos) * length(neg))}
    end
  end

  # Tie-aware ranks: each value gets the average of the 1-based positions of all
  # equal values in the sorted list (O(n²) — n ≤ ~30 here).
  defp ranks(vals) do
    sorted_indexed = vals |> Enum.sort() |> Enum.with_index(1)

    Enum.map(vals, fn v ->
      positions = for {sv, i} <- sorted_indexed, sv == v, do: i
      Enum.sum(positions) / length(positions)
    end)
  end

  defp pearson(xs, ys) do
    n = length(xs)
    mx = Enum.sum(xs) / n
    my = Enum.sum(ys) / n

    {num, dx, dy} =
      Enum.zip(xs, ys)
      |> Enum.reduce({0.0, 0.0, 0.0}, fn {a, b}, {num, dx, dy} ->
        {num + (a - mx) * (b - my), dx + (a - mx) * (a - mx), dy + (b - my) * (b - my)}
      end)

    den = :math.sqrt(dx * dy)
    if den == 0.0, do: {:error, :degenerate}, else: {:ok, num / den}
  end
end
