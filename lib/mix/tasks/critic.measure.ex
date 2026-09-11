defmodule Mix.Tasks.Critic.Measure do
  @shortdoc "Measures per-lens critic↔human trust and writes the critic_trust block (local-only; never auto-commits)"

  @moduledoc """
  Computes the per-lens `critic_trust` block from the maintainer's golden set and
  critic scores, then writes it into the repository's design-system ledger.

  The task is a repository-only edge. Its private `--fixture-root` and
  `--output-root` overrides resolve from `Mix.Project.project_file/0`, never the
  caller's current directory or ambient environment. The fixture root owns the
  ledger and golden oracles; the output root owns generated critic scores.

  ## Usage

      mix critic.measure
      mix critic.measure --source synthetic
      mix critic.measure --fixture-root .planning --output-root .planning/critic-scores

  It computes per-lens trust via `Threadline.CriticTrust.Measure` and surgically
  replaces only `critic_trust` and `critic_trust_provenance` through
  `Threadline.CriticTrust.LedgerSplice`. The maintainer reviews the resulting
  ledger diff; this task never runs git or commits.
  """

  use Mix.Task

  alias Threadline.CriticTrust.{LedgerSplice, Measure}

  @default_fixture_root ".planning"
  @default_output_root ".planning/critic-scores"
  @rubrics_dir "examples/threadline_phoenix/e2e/critic/rubrics"

  @impl Mix.Task
  def run(argv) do
    {:ok, _} = Application.ensure_all_started(:crypto)

    {source, paths} = parse_options!(argv)
    golden = read_golden!(source, paths)
    scores = read_scores!(paths)
    rubric_versions = read_rubric_versions!(paths)

    ledger_text =
      read_json_text!(paths.ledger, "design-system ledger", restore_command(paths.ledger))

    block = Measure.build_block(golden, scores, rubric_versions)
    provenance = provenance_for(source, golden)

    with {:ok, trust_text} <- LedgerSplice.replace(ledger_text, block),
         {:ok, final_text} <- LedgerSplice.replace_provenance(trust_text, provenance) do
      atomic_replace!(paths.ledger, final_text)
      print_summary(block, source)
      Mix.shell().info("git diff -- #{paths.ledger}")
    else
      {:error, reason} ->
        task_error!(
          "could not splice ledger block (#{inspect(reason)})",
          paths.ledger,
          restore_command(paths.ledger)
        )
    end
  end

  # ── Source + provenance ────────────────────────────────────────────────────

  defp parse_options!(argv) do
    project_root = project_root!()

    case OptionParser.parse(argv,
           strict: [source: :string, fixture_root: :string, output_root: :string]
         ) do
      {opts, [], []} ->
        source = source!(Keyword.get(opts, :source, "human"), project_root)

        fixture_root =
          resolve_repository_root!(
            Keyword.get(opts, :fixture_root, @default_fixture_root),
            project_root,
            "fixture root"
          )

        output_root =
          resolve_repository_root!(
            Keyword.get(opts, :output_root, @default_output_root),
            project_root,
            "critic-score output root"
          )

        require_directory!(fixture_root, "fixture root", restore_command(fixture_root))
        require_directory!(output_root, "critic-score output root", "mix verify.ui_critique")
        validate_root_separation!(fixture_root, output_root)

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
        task_error!(
          "command arguments are invalid: #{inspect(args ++ invalid)}",
          project_root,
          "mix help critic.measure"
        )
    end
  end

  defp source!("human", _path), do: :human
  defp source!("synthetic", _path), do: :synthetic

  defp source!(source, path) do
    task_error!("unknown --source #{inspect(source)}", path, "mix help critic.measure")
  end

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

  # ── Readers ────────────────────────────────────────────────────────────────

  defp read_golden!(source, paths) do
    path = if source == :synthetic, do: paths.synthetic, else: paths.golden
    recovery = if source == :synthetic, do: "mix critic.synth", else: restore_command(path)
    read_json_object!(path, "golden oracle", recovery)
  end

  defp read_scores!(paths) do
    Path.wildcard(Path.join(paths.output_root, "*/*/*.json"))
    |> Enum.reduce(%{}, fn path, acc ->
      score = read_json_object!(path, "critic score", "mix verify.ui_critique")
      validate_score!(score, path)
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
    require_directory!(paths.rubrics, "critic rubric root", restore_command(paths.rubrics))

    Map.new(Measure.lenses(), fn lens ->
      path = Path.join(paths.rubrics, "#{lens}.md")
      content = read_text!(path, "critic rubric", restore_command(path))

      version =
        case Regex.run(
               ~r/<!--\s*lens:\s*\S+\s*\|\s*version:\s*(\S+)\s*\|\s*sha8:\s*(\S+)\s*-->/,
               content
             ) do
          [_, semver, sha8] -> "#{lens}@#{semver}+#{sha8}"
          _ -> task_error!("critic rubric is invalid", path, restore_command(path))
        end

      {lens, version}
    end)
  end

  # ── Repository-only path and decode boundary ──────────────────────────────

  defp project_root! do
    case Mix.Project.project_file() do
      nil ->
        task_error!("no Mix project file is loaded", File.cwd!(), "mix help critic.measure")

      project_file ->
        project_file
        |> Path.expand()
        |> Path.dirname()
    end
  end

  defp resolve_repository_root!(path, project_root, dataset) when is_binary(path) do
    expanded = Path.expand(path, project_root)
    relative = Path.relative_to(expanded, project_root)

    case Path.safe_relative_to(relative, project_root) do
      {:ok, safe_relative} ->
        Path.join(project_root, safe_relative)

      :error ->
        task_error!(
          "#{dataset} escapes or aliases the repository",
          expanded,
          "mix help critic.measure"
        )
    end
  end

  defp validate_root_separation!(fixture_root, output_root) do
    immutable = [
      Path.join(fixture_root, "scorecards"),
      Path.join(fixture_root, "golden"),
      Path.join(fixture_root, "refute"),
      Path.join(fixture_root, "design-system-ledger.json")
    ]

    if output_root == fixture_root or Enum.any?(immutable, &within?(output_root, &1)) do
      task_error!(
        "critic-score output root aliases immutable evidence",
        output_root,
        "mix help critic.measure"
      )
    end
  end

  defp within?(candidate, parent) do
    case Path.relative_to(candidate, parent) do
      "." -> true
      ".." -> false
      "../" <> _ -> false
      relative -> Path.type(relative) == :relative
    end
  end

  defp require_directory!(path, dataset, recovery) do
    if not File.dir?(path), do: task_error!("#{dataset} is unavailable", path, recovery)
  end

  defp read_json_object!(path, dataset, recovery) do
    case path |> read_text!(dataset, recovery) |> Jason.decode() do
      {:ok, decoded} when is_map(decoded) ->
        decoded

      {:ok, _other} ->
        task_error!("#{dataset} is invalid (expected a JSON object)", path, recovery)

      {:error, error} ->
        task_error!("#{dataset} is invalid (#{Exception.message(error)})", path, recovery)
    end
  end

  defp read_json_text!(path, dataset, recovery) do
    text = read_text!(path, dataset, recovery)

    case Jason.decode(text) do
      {:ok, decoded} when is_map(decoded) ->
        text

      {:ok, _other} ->
        task_error!("#{dataset} is invalid (expected a JSON object)", path, recovery)

      {:error, error} ->
        task_error!("#{dataset} is invalid (#{Exception.message(error)})", path, recovery)
    end
  end

  defp read_text!(path, dataset, recovery) do
    case File.read(path) do
      {:ok, text} ->
        text

      {:error, reason} ->
        task_error!(
          "#{dataset} is unavailable (#{:file.format_error(reason)})",
          path,
          recovery
        )
    end
  end

  defp validate_score!(score, path) do
    valid =
      is_binary(score["cell_id"]) and score["cell_id"] != "" and
        score["lens"] in Measure.lenses()

    if not valid, do: task_error!("critic score is invalid", path, "mix verify.ui_critique")
  end

  defp atomic_replace!(target, contents) do
    temp = "#{target}.tmp-#{System.unique_integer([:positive, :monotonic])}"

    case File.open(temp, [:write, :binary, :exclusive]) do
      {:ok, io_device} ->
        result =
          try do
            with :ok <- IO.binwrite(io_device, contents),
                 :ok <- :file.sync(io_device),
                 :ok <- File.close(io_device),
                 :ok <- atomic_write_hook(),
                 :ok <- File.rename(temp, target) do
              :ok
            end
          after
            _ = File.close(io_device)
            _ = File.rm(temp)
          end

        case result do
          :ok ->
            :ok

          {:error, reason} ->
            task_error!(
              "atomic ledger replacement failed (#{inspect(reason)})",
              target,
              restore_command(target)
            )
        end

      {:error, reason} ->
        task_error!(
          "could not create exclusive sibling temp (#{inspect(reason)})",
          target,
          restore_command(target)
        )
    end
  end

  defp atomic_write_hook do
    case Process.get({__MODULE__, :atomic_write_hook}) do
      hook when is_function(hook, 0) -> hook.()
      _other -> :ok
    end
  end

  defp restore_command(path), do: "git restore -- #{Path.relative_to(path, project_root!())}"

  defp task_error!(message, path, recovery) do
    Mix.raise(
      "critic.measure: #{message}\n" <>
        "resolved path: #{Path.expand(path)}\n" <>
        "repository-only: true\n" <>
        "next: #{recovery}"
    )
  end

  # ── Output ─────────────────────────────────────────────────────────────────

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
      "\nReview the diff and commit the golden set, critic-scores, CRITIQUE.md, and " <>
        "design-system-ledger.json as one reviewed commit. This task never commits (T-195-24)."
    )
  end

  defp fmt(nil), do: "—"
  defp fmt(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 3)
  defp fmt(value), do: to_string(value)
end
