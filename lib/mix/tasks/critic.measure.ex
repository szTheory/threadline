defmodule Mix.Tasks.Critic.Measure do
  @shortdoc "Measures per-lens critic↔human trust and writes the critic_trust block (local-only; never auto-commits)"

  @moduledoc """
  Computes the per-lens `critic_trust` block from the maintainer's golden set +
  the critic's scores and writes it into `.planning/design-system-ledger.json`.

  This is the measurement/writer half of CRITIC-03. It reads:

    * the **oracle set** — `.planning/golden/golden-set.json` (reconciled human labels)
      by default, or `.planning/golden/synthetic-set.json` under `--source synthetic`
      (the D-12 graded twin oracle: constructed severity labels, zero human labeling)
    * `.planning/critic-scores/<cell>/<lens>/<dim>.json` — the critic's scores
    * `examples/threadline_phoenix/e2e/critic/rubrics/<lens>.md` — for the
      versioned rubric hash stamped into `golden_rubric_version`

  computes per-lens Krippendorff's α + raw agreement + n + bootstrap CI via
  `Threadline.CriticTrust.Measure`, and splices the result over only the
  `critic_trust` object via `Threadline.CriticTrust.LedgerSplice` (all other
  ledger bytes preserved). A lens is promoted to `validated: true` only when
  `alpha >= 0.67 ∧ n >= 20 ∧ raw_agreement >= 0.80 ∧ model_id == "claude-opus-4-8"`
  and every contributing score used the current rubric version.

  ## Usage

      mix critic.measure                     # human golden-set oracle
      mix critic.measure --source synthetic  # D-12 graded twin oracle (labeling-free)

  Also writes the sibling `critic_trust_provenance` block (`oracle`, `set_version`,
  `generated_from`) so every promotion honestly records which oracle produced it.

  Local-only and **excluded from `ci.all`** (it mutates a committed file). It
  **never** runs git — the maintainer reviews the diff and commits the golden set,
  critic-scores, CRITIQUE.md, and the updated ledger as one reviewed commit
  (T-195-24: rescoring is never auto-green). The `mix verify.critic_trust` gate in
  `ci.all` then re-asserts whatever was recorded.

  Running with an empty golden set reproduces the vacuous block (all lenses
  `validated: false`, `n: 0`) — a byte-identical no-op.
  """

  use Mix.Task

  alias Threadline.CriticTrust.{LedgerSplice, Measure}

  @ledger ".planning/design-system-ledger.json"
  @golden ".planning/golden/golden-set.json"
  @synthetic ".planning/golden/synthetic-set.json"
  @critic_scores ".planning/critic-scores"
  @rubrics_dir "examples/threadline_phoenix/e2e/critic/rubrics"

  @impl Mix.Task
  def run(argv) do
    {:ok, _} = Application.ensure_all_started(:crypto)

    source = parse_source(argv)
    golden = read_golden(source)
    scores = read_scores()
    rubric_versions = read_rubric_versions()

    block = Measure.build_block(golden, scores, rubric_versions)
    provenance = provenance_for(source, golden)

    ledger_text = File.read!(@ledger)

    with {:ok, t1} <- LedgerSplice.replace(ledger_text, block),
         {:ok, t2} <- LedgerSplice.replace_provenance(t1, provenance) do
      File.write!(@ledger, t2)
      print_summary(block, source)
    else
      {:error, reason} ->
        Mix.raise("critic.measure: could not splice ledger block (#{inspect(reason)})")
    end
  end

  # ── Source + provenance (D-12) ───────────────────────────────────────────────

  # `--source synthetic` reads the graded-twin oracle; default reads the human golden set.
  defp parse_source(argv) do
    case OptionParser.parse(argv, strict: [source: :string]) do
      {[source: "synthetic"], _, _} -> :synthetic
      {[source: "human"], _, _} -> :human
      {[], _, _} -> :human
      {opts, _, _} -> Mix.raise("critic.measure: unknown --source #{inspect(opts)}")
    end
  end

  # The sibling critic_trust_provenance block. `oracle` is only stamped when the set
  # actually carries items (an empty run stays a null/no-op) so the honest-label guard
  # never sees an unlabeled promotion.
  defp provenance_for(source, golden) do
    has_items = length(Map.get(golden, "items", []) || []) > 0

    oracle =
      cond do
        not has_items -> nil
        source == :synthetic -> "synthetic"
        true -> "human"
      end

    %{
      "oracle" => oracle,
      "set_version" => if(has_items, do: Map.get(golden, "set_version"), else: nil),
      "generated_from" =>
        cond do
          not has_items -> nil
          source == :synthetic -> "graded-twin-ladder"
          true -> "human-blind-test-retest"
        end
    }
  end

  # ── Readers ──────────────────────────────────────────────────────────────────

  defp read_golden(source) do
    path = if source == :synthetic, do: @synthetic, else: @golden

    if File.exists?(path) do
      path |> File.read!() |> Jason.decode!()
    else
      %{"items" => []}
    end
  end

  # Group critic-score files by {cell_id, lens} → [%{band:, stable:, model_id:, rubric_version:}].
  defp read_scores do
    Path.wildcard(Path.join(@critic_scores, "*/*/*.json"))
    |> Enum.reduce(%{}, fn path, acc ->
      score = path |> File.read!() |> Jason.decode!()
      key = {score["cell_id"], score["lens"]}

      dim = %{
        band: score["band"],
        score: score["score"],
        stable: score["stable"] == true,
        model_id: score["model_id"],
        rubric_version: score["rubric_version"]
      }

      Map.update(acc, key, [dim], &[dim | &1])
    end)
  end

  # For each lens: the header-declared "<lens>@<semver>+<sha8>", read straight from the
  # rubric's `<!-- lens: X | version: V | sha8: S -->` comment — the SAME source the
  # scorer (run.ts getRubricVersion) stamps into each score's rubric_version. Reading
  # (not recomputing) keeps score-time and measure-time versions identical, so `fresh`
  # holds while a rubric is unchanged. The dedicated rubric-hash guard (in
  # critic_trust_test) separately asserts the header sha8 tracks the file bytes once a
  # rubric is stamped (placeholder "00000000" = uninitialized). nil when absent/malformed.
  defp read_rubric_versions do
    Map.new(Measure.lenses(), fn lens ->
      path = Path.join(@rubrics_dir, "#{lens}.md")

      version =
        if File.exists?(path) do
          content = File.read!(path)

          case Regex.run(
                 ~r/<!--\s*lens:\s*\S+\s*\|\s*version:\s*(\S+)\s*\|\s*sha8:\s*(\S+)\s*-->/,
                 content
               ) do
            [_, semver, sha8] -> "#{lens}@#{semver}+#{sha8}"
            _ -> nil
          end
        end

      {lens, version}
    end)
  end

  # ── Output ───────────────────────────────────────────────────────────────────

  defp print_summary(block, source) do
    Mix.shell().info(
      "\ncritic_trust measured (design-system-ledger.json updated) — oracle: #{source}:\n"
    )

    Mix.shell().info("  lens             n   spearman   auc    (alpha)  validated")
    Mix.shell().info("  ---------------  --  --------  -----  -------  ---------")

    for lens <- Measure.lenses() do
      d = Map.fetch!(block, lens)

      Mix.shell().info(
        "  " <>
          String.pad_trailing(lens, 15) <>
          "  " <>
          String.pad_leading(to_string(d["n"]), 2) <>
          "  " <>
          String.pad_leading(fmt(d["spearman"]), 8) <>
          "  " <>
          String.pad_leading(fmt(d["auc"]), 5) <>
          "  " <>
          String.pad_leading(fmt(d["alpha"]), 7) <>
          "  " <>
          if(d["validated"], do: "  ✓ validated", else: "    provisional")
      )
    end

    Mix.shell().info(
      "\nReview the diff and commit the golden set, critic-scores, CRITIQUE.md, and " <>
        "design-system-ledger.json as one reviewed commit. This task never commits (T-195-24)."
    )
  end

  defp fmt(nil), do: "—"
  defp fmt(x) when is_float(x), do: :erlang.float_to_binary(x, decimals: 3)
  defp fmt(x), do: to_string(x)
end
