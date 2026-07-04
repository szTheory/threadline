defmodule Mix.Tasks.Critic.Measure do
  @shortdoc "Measures per-lens critic↔human trust and writes the critic_trust block (local-only; never auto-commits)"

  @moduledoc """
  Computes the per-lens `critic_trust` block from the maintainer's golden set +
  the critic's scores and writes it into `.planning/design-system-ledger.json`.

  This is the measurement/writer half of CRITIC-03. It reads:

    * `.planning/golden/golden-set.json` — the reconciled human labels (oracle)
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

      mix critic.measure

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
  @critic_scores ".planning/critic-scores"
  @rubrics_dir "examples/threadline_phoenix/e2e/critic/rubrics"

  @impl Mix.Task
  def run(_argv) do
    {:ok, _} = Application.ensure_all_started(:crypto)

    golden = read_golden()
    scores = read_scores()
    rubric_versions = read_rubric_versions()

    block = Measure.build_block(golden, scores, rubric_versions)

    ledger_text = File.read!(@ledger)

    case LedgerSplice.replace(ledger_text, block) do
      {:ok, new_text} ->
        File.write!(@ledger, new_text)
        print_summary(block)

      {:error, reason} ->
        Mix.raise("critic.measure: could not splice critic_trust block (#{inspect(reason)})")
    end
  end

  # ── Readers ──────────────────────────────────────────────────────────────────

  defp read_golden do
    if File.exists?(@golden) do
      @golden |> File.read!() |> Jason.decode!()
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
        stable: score["stable"] == true,
        model_id: score["model_id"],
        rubric_version: score["rubric_version"]
      }

      Map.update(acc, key, [dim], &[dim | &1])
    end)
  end

  # For each lens: "<lens>@<semver>+<sha8>" where sha8 is the first 8 hex chars of
  # SHA-256 of the raw rubric bytes (matches the guard's sha8_of_file), and semver
  # is parsed from the rubric header. nil when the rubric file is absent.
  defp read_rubric_versions do
    Map.new(Measure.lenses(), fn lens ->
      path = Path.join(@rubrics_dir, "#{lens}.md")

      version =
        if File.exists?(path) do
          content = File.read!(path)
          semver = extract_semver(content)

          sha8 =
            :crypto.hash(:sha256, content) |> Base.encode16(case: :lower) |> String.slice(0, 8)

          if semver, do: "#{lens}@#{semver}+#{sha8}", else: nil
        end

      {lens, version}
    end)
  end

  defp extract_semver(content) do
    case Regex.run(~r/version:\s*(\d+\.\d+\.\d+)/, content) do
      [_, semver] -> semver
      _ -> nil
    end
  end

  # ── Output ───────────────────────────────────────────────────────────────────

  defp print_summary(block) do
    Mix.shell().info("\ncritic_trust measured (design-system-ledger.json updated):\n")
    Mix.shell().info("  lens             n   alpha    raw    validated")
    Mix.shell().info("  ---------------  --  -------  -----  ---------")

    for lens <- Measure.lenses() do
      d = Map.fetch!(block, lens)

      Mix.shell().info(
        "  " <>
          String.pad_trailing(lens, 15) <>
          "  " <>
          String.pad_leading(to_string(d["n"]), 2) <>
          "  " <>
          String.pad_leading(fmt(d["alpha"]), 7) <>
          "  " <>
          String.pad_leading(fmt(d["raw_agreement"]), 5) <>
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
