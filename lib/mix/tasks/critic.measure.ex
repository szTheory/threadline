defmodule Mix.Tasks.Critic.Measure do
  @shortdoc "Measures per-lens critic↔human trust and writes the critic_trust block (local-only; never auto-commits)"

  @moduledoc false

  use Mix.Task

  alias Threadline.CriticTrust.{LedgerSplice, Measure, RepositoryBoundary}

  @default_fixture_root "test/fixtures/operator_surface"
  @default_output_root "test/generated/operator_surface/critic-scores"
  @rubrics_dir "examples/threadline_phoenix/e2e/critic/rubrics"

  @impl Mix.Task
  def run(argv) do
    {:ok, _} = Application.ensure_all_started(:crypto)

    {source, paths} = parse_options!(argv)
    golden = read_golden!(source, paths)
    scores = read_scores!(paths)
    rubric_versions = read_rubric_versions!(paths)

    ledger_text =
      RepositoryBoundary.read_json_text!(
        paths.ledger,
        "design-system ledger",
        RepositoryBoundary.restore_command(paths.ledger)
      )

    block = Measure.build_block(golden, scores, rubric_versions)
    provenance = provenance_for(source, golden)

    with {:ok, trust_text} <- LedgerSplice.replace(ledger_text, block),
         {:ok, final_text} <- LedgerSplice.replace_provenance(trust_text, provenance) do
      RepositoryBoundary.atomic_replace!(paths.ledger, final_text)
      print_summary(block, source)
      Mix.shell().info("git diff -- #{paths.ledger}")
    else
      {:error, reason} ->
        RepositoryBoundary.task_error!(
          "could not splice ledger block (#{inspect(reason)})",
          paths.ledger,
          RepositoryBoundary.restore_command(paths.ledger)
        )
    end
  end

  defp parse_options!(argv) do
    project_root = RepositoryBoundary.project_root!()

    case OptionParser.parse(argv,
           strict: [source: :string, fixture_root: :string, output_root: :string]
         ) do
      {opts, [], []} ->
        source = source!(Keyword.get(opts, :source, "human"), project_root)

        fixture_root =
          RepositoryBoundary.resolve_repository_root!(
            Keyword.get(opts, :fixture_root, @default_fixture_root),
            project_root,
            "fixture root"
          )

        output_root =
          RepositoryBoundary.resolve_repository_root!(
            Keyword.get(opts, :output_root, @default_output_root),
            project_root,
            "critic-score output root"
          )

        RepositoryBoundary.require_directory!(
          fixture_root,
          "fixture root",
          RepositoryBoundary.restore_command(fixture_root)
        )

        RepositoryBoundary.require_directory!(
          output_root,
          "critic-score output root",
          "mix verify.ui_critique"
        )

        RepositoryBoundary.validate_root_separation!(fixture_root, output_root)

        {source,
         %{
           project_root: project_root,
           fixture_root: fixture_root,
           output_root: output_root,
           ledger: Path.join(fixture_root, "design-system-ledger.json"),
           golden: Path.join(fixture_root, "golden/golden-set.json"),
           synthetic: Path.join(fixture_root, "golden/synthetic-set.json"),
           rubrics: Path.join(project_root, @rubrics_dir)
         }}

      {_opts, args, invalid} ->
        RepositoryBoundary.task_error!(
          "command arguments are invalid: #{inspect(args ++ invalid)}",
          project_root,
          "mix help critic.measure"
        )
    end
  end

  defp source!("human", _path), do: :human
  defp source!("synthetic", _path), do: :synthetic

  defp source!(source, path) do
    RepositoryBoundary.task_error!(
      "unknown --source #{inspect(source)}",
      path,
      "mix help critic.measure"
    )
  end

  defp provenance_for(source, golden) do
    has_items = not Enum.empty?(Map.get(golden, "items", []) || [])

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

  defp read_golden!(source, paths) do
    path = if source == :synthetic, do: paths.synthetic, else: paths.golden

    recovery =
      if source == :synthetic,
        do: "mix critic.synth",
        else: RepositoryBoundary.restore_command(path)

    path
    |> RepositoryBoundary.read_json_object!("golden oracle", recovery)
    |> RepositoryBoundary.validate_golden!(path, recovery)
  end

  defp read_scores!(paths) do
    Path.wildcard(Path.join(paths.output_root, "*/*/*.json"))
    |> Enum.reduce(%{}, fn path, acc ->
      score = RepositoryBoundary.read_json_object!(path, "critic score", "mix verify.ui_critique")
      RepositoryBoundary.validate_score!(score, path)
      key = {score["cell_id"], score["lens"]}

      dimension = %{
        band: score["band"],
        score: score["score"],
        stable: score["stable"] == true,
        model_id: score["model_id"],
        rubric_version: score["rubric_version"]
      }

      Map.update(acc, key, [dimension], &[dimension | &1])
    end)
  end

  defp read_rubric_versions!(paths) do
    RepositoryBoundary.require_directory!(
      paths.rubrics,
      "critic rubric root",
      RepositoryBoundary.restore_command(paths.rubrics)
    )

    Map.new(Measure.lenses(), fn lens ->
      path = Path.join(paths.rubrics, "#{lens}.md")

      content =
        RepositoryBoundary.read_text!(
          path,
          "critic rubric",
          RepositoryBoundary.restore_command(path)
        )

      version =
        case Regex.run(
               ~r/<!--\s*lens:\s*\S+\s*\|\s*version:\s*(\S+)\s*\|\s*sha8:\s*(\S+)\s*-->/,
               content
             ) do
          [_, semver, sha8] ->
            "#{lens}@#{semver}+#{sha8}"

          _ ->
            RepositoryBoundary.task_error!(
              "critic rubric is invalid",
              path,
              RepositoryBoundary.restore_command(path)
            )
        end

      {lens, version}
    end)
  end

  defp print_summary(block, source) do
    Mix.shell().info("\ncritic_trust measured — oracle: #{source}:\n")
    Mix.shell().info("  lens             n   spearman   auc    (alpha)  validated")
    Mix.shell().info("  ---------------  --  --------  -----  -------  ---------")

    for lens <- Measure.lenses() do
      data = Map.fetch!(block, lens)

      Mix.shell().info(
        "  " <>
          String.pad_trailing(lens, 15) <>
          "  " <>
          String.pad_leading(to_string(data["n"]), 2) <>
          "  " <>
          String.pad_leading(fmt(data["spearman"]), 8) <>
          "  " <>
          String.pad_leading(fmt(data["auc"]), 5) <>
          "  " <>
          String.pad_leading(fmt(data["alpha"]), 7) <>
          "  " <>
          if(data["validated"], do: "  ✓ validated", else: "    provisional")
      )
    end

    Mix.shell().info(
      "\nReview and commit only the golden set and design-system-ledger.json. " <>
        "Generated critic scores and reports remain local and ignored. This task never commits."
    )
  end

  defp fmt(nil), do: "—"
  defp fmt(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 3)
  defp fmt(value), do: to_string(value)
end
