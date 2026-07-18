defmodule Mix.Tasks.Critic.Synth do
  @shortdoc "Generates the synthetic golden set from the graded twin ladder (D-12)"

  @moduledoc """
  Writes `.planning/golden/synthetic-set.json` — the **synthetic twin oracle** (Phase
  195 D-12). Each graded-ladder story (lens × scenario × severity rung) becomes a
  `golden-set.json`-shaped item whose verdict is the rung's *constructed* label
  (r4→good, r3→borderline, r2→bad, r1→broken). Because the labels are definitional
  (authored, not observed), this reaches the trust gate's n≥20/lens with **zero human
  labeling**.

  This file is a **parallel** to the human `golden-set.json` (kept pristine/empty) so
  provenance is never conflated at the data layer. `mix critic.measure --source
  synthetic` reads it; `npm run capture:graded` reads its cell_ids to know what to shoot.

  Honest claim (recorded in `golden_source`/`oracle_note`): the synthetic oracle proves
  the critic **tracks known-severity injected flaws monotonically on held-out
  interpolation rungs** — NOT that it matches the maintainer's taste on ambiguous real
  UI. See D-12 in the phase context.

  ## Usage

      mix critic.synth

  Deterministic: same catalog → byte-identical output.
  """

  use Mix.Task

  alias Threadline.OperatorSurface.StressFixtures

  @out ".planning/golden/synthetic-set.json"
  @theme "dark"
  @breakpoint 1280
  @set_version "195.12.0"
  @model_pin "claude-opus-4-8"

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("loadpaths")
    Mix.Task.run("compile")

    graded =
      StressFixtures.all()
      |> Enum.filter(fn s -> s.category == "refute" and Map.get(s.data, :rung) != nil end)
      |> Enum.sort_by(& &1.id)

    items =
      graded
      |> Enum.with_index(1)
      |> Enum.map(fn {s, i} ->
        rung = s.data.rung
        verdict = StressFixtures.rung_verdict(rung)
        cell_id = "#{s.id}__#{@theme}-#{@breakpoint}"

        evidence =
          "constructed: #{s.data.lens} \"#{s.data.scenario}\" at severity #{rung} " <>
            "(#{verdict}); held-out interpolation rung, label is definitional"

        %{
          "id" => "syn_" <> String.pad_leading(to_string(i), 3, "0"),
          "cell_id" => cell_id,
          "lens" => s.data.lens,
          "kind" => "single",
          "pair_with" => nil,
          "r1" => %{"verdict" => verdict, "evidence" => evidence, "blind" => true},
          "r2" => %{"verdict" => verdict, "evidence" => evidence, "blind" => true},
          "kept" => true
        }
      end)

    doc = %{
      "version" => 1,
      "golden_source" => "synthetic",
      "oracle_note" =>
        "Constructed graded-twin severity labels (D-12). Proves the critic tracks " <>
          "known-severity injected flaws monotonically on held-out interpolation rungs — " <>
          "NOT that it matches human taste on ambiguous real UI.",
      "set_version" => @set_version,
      "model_pin" => @model_pin,
      "rubric_rev" => nil,
      "held_out_ids" => [],
      "items" => items
    }

    File.mkdir_p!(Path.dirname(@out))
    File.write!(@out, Jason.encode!(doc, pretty: true) <> "\n")

    by_lens =
      items
      |> Enum.frequencies_by(& &1["lens"])
      |> Enum.sort()
      |> Enum.map(fn {l, n} -> "#{l}=#{n}" end)

    Mix.shell().info("wrote #{length(items)} synthetic items → #{@out}")
    Mix.shell().info("  per lens: #{Enum.join(by_lens, ", ")}")
    Mix.shell().info("  oracle: synthetic (D-12) — cells captured via `npm run capture:graded`")
  end
end
