defmodule Mix.Tasks.Critic.Synth do
  @shortdoc "Generates the synthetic golden set from the graded twin ladder"

  @moduledoc false

  use Mix.Task

  alias Threadline.OperatorSurface.StressFixtures

  @default_fixture_root "test/fixtures/operator_surface"
  @theme "dark"
  @breakpoint 1280
  @set_version "195.12.0"
  @model_pin "claude-opus-4-8"

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("loadpaths")
    Mix.Task.run("compile")

    fixture_root = parse_fixture_root!(argv)
    target = Path.join(fixture_root, "golden/synthetic-set.json")
    require_directory!(Path.dirname(target), "synthetic oracle root", restore_command(target))

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
          "adjudicated" => %{"source" => "agreement", "verdict" => verdict},
          "kept" => true
        }
      end)

    doc = %{
      "version" => 1,
      "golden_source" => "synthetic",
      "oracle_note" =>
        "Constructed graded-twin severity labels. Proves the critic tracks " <>
          "known-severity injected flaws monotonically on held-out interpolation rungs — " <>
          "NOT that it matches human taste on ambiguous real UI.",
      "set_version" => @set_version,
      "model_pin" => @model_pin,
      "rubric_rev" => nil,
      "held_out_ids" => [],
      "items" => items
    }

    atomic_replace!(target, Jason.encode!(doc, pretty: true) <> "\n")

    by_lens =
      items
      |> Enum.frequencies_by(& &1["lens"])
      |> Enum.sort()
      |> Enum.map(fn {l, n} -> "#{l}=#{n}" end)

    Mix.shell().info("wrote #{length(items)} synthetic items → #{target}")
    Mix.shell().info("  per lens: #{Enum.join(by_lens, ", ")}")
    Mix.shell().info("  oracle: synthetic — cells captured via `npm run capture:graded`")
    Mix.shell().info("git diff -- #{target}")
  end

  defp parse_fixture_root!(argv) do
    project_root = project_root!()

    case OptionParser.parse(argv, strict: [fixture_root: :string]) do
      {opts, [], []} ->
        root =
          resolve_repository_root!(
            Keyword.get(opts, :fixture_root, @default_fixture_root),
            project_root
          )

        require_directory!(root, "fixture root", restore_command(root))
        root

      {_opts, args, invalid} ->
        task_error!(
          "command arguments are invalid: #{inspect(args ++ invalid)}",
          project_root,
          "mix help critic.synth"
        )
    end
  end

  defp project_root! do
    case Mix.Project.project_file() do
      nil -> task_error!("no Mix project file is loaded", File.cwd!(), "mix help critic.synth")
      project_file -> project_file |> Path.expand() |> Path.dirname()
    end
  end

  defp resolve_repository_root!(path, project_root) when is_binary(path) do
    expanded = Path.expand(path, project_root)
    relative = Path.relative_to(expanded, project_root)

    case Path.safe_relative_to(relative, project_root) do
      {:ok, safe_relative} ->
        Path.join(project_root, safe_relative)

      :error ->
        task_error!(
          "fixture root escapes or aliases the repository",
          expanded,
          "mix help critic.synth"
        )
    end
  end

  defp require_directory!(path, dataset, recovery) do
    if not File.dir?(path), do: task_error!("#{dataset} is unavailable", path, recovery)
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
                 :ok <- atomic_write_hook() do
              File.rename(temp, target)
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
              "atomic synthetic-oracle replacement failed (#{inspect(reason)})",
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

  @spec task_error!(String.t(), Path.t(), String.t()) :: no_return()
  defp task_error!(message, path, recovery) do
    Mix.raise(
      "critic.synth: #{message}\n" <>
        "resolved path: #{Path.expand(path)}\n" <>
        "repository-only: true\n" <>
        "next: #{recovery}"
    )
  end
end
