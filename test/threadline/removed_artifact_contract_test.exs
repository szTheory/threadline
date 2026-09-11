defmodule Threadline.RemovedArtifactContract do
  @moduledoc false

  @removed_paths [
    ".planning/ROADMAP.md.bak",
    ".planning/HANDOFF.json",
    "update_roadmap.rb",
    "fix_tests.exs"
  ]

  @root_one_off ~r/^(?:fix|update|patch|migrate)[_-].*\.(?:exs|rb)$/
  @standard_root_executables MapSet.new([".credo.exs", ".formatter.exs", "mix.exs"])
  @executable_extensions MapSet.new([".ex", ".exs", ".js", ".rb", ".sh", ".ts", ".yaml", ".yml"])
  @scanner_path "test/threadline/removed_artifact_contract_test.exs"

  def removed_paths, do: @removed_paths

  def repository_file_sets(tracked) when is_list(tracked) do
    %{
      tracked: tracked,
      executables: Enum.filter(tracked, &executable_consumer?/1),
      documents: Enum.filter(tracked, &document_consumer?/1)
    }
  end

  def scan(file_sets, read_file) when is_map(file_sets) and is_function(read_file, 1) do
    tracked = MapSet.new(Map.fetch!(file_sets, :tracked))

    tracked_target_violations =
      for target <- @removed_paths, MapSet.member?(tracked, target) do
        violation(:tracked_removed_path, target, 1, target)
      end

    root_executable_violations =
      file_sets
      |> Map.fetch!(:executables)
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.reject(&(&1 in @removed_paths))
      |> Enum.filter(&root_one_off_executable?/1)
      |> Enum.map(&violation(:root_one_off_executable, &1, 1, nil))

    citation_violations =
      file_sets
      |> Map.take([:executables, :documents])
      |> Map.values()
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.reject(&(&1 in @removed_paths))
      |> Enum.flat_map(&citation_violations(&1, read_file.(&1)))

    tracked_target_violations ++ root_executable_violations ++ citation_violations
  end

  defp root_one_off_executable?(file) do
    Path.dirname(file) == "." and
      not MapSet.member?(@standard_root_executables, file) and
      Regex.match?(@root_one_off, Path.basename(file))
  end

  defp executable_consumer?(@scanner_path), do: false
  defp executable_consumer?(".planning/" <> _historical_path), do: false

  defp executable_consumer?(file) do
    MapSet.member?(@executable_extensions, Path.extname(file))
  end

  defp document_consumer?(file) do
    file in [
      "README.md",
      "CONTRIBUTING.md"
    ] or (String.starts_with?(file, "guides/") and Path.extname(file) == ".md")
  end

  defp citation_violations(file, content) do
    for {line, line_number} <- lines_with_numbers(content),
        target <- @removed_paths,
        active_citation?(line, target),
        not historical_supersession?(content, target) do
      violation(:active_citation, file, line_number, target)
    end
  end

  defp lines_with_numbers(content) do
    content
    |> String.split("\n")
    |> Enum.with_index(1)
  end

  defp active_citation?(line, target) do
    trimmed = String.trim_leading(line)

    String.starts_with?(trimmed, "@#{target}") or
      String.contains?(line, "](#{target})") or
      (String.contains?(line, target) and
         (Regex.match?(~r/File\.(?:read|read!|stream|open)/, line) or
            Regex.match?(~r/—\s+current\b/i, line)))
  end

  defp historical_supersession?(content, target) do
    marker =
      "removed-artifact: #{target} existed at execution time; superseded and removed in Phase 199"

    String.contains?(content, marker)
  end

  defp violation(kind, file, line, target) do
    %{file: file, kind: kind, line: line, target: target}
  end
end

defmodule Threadline.RemovedArtifactContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.RemovedArtifactContract, as: Scanner

  test "scanner reports a removed-path citation with file and line and accepts a clean tree" do
    stale_tree = %{
      tracked: ["README.md"],
      executables: [],
      documents: ["README.md"]
    }

    stale_files = %{
      "README.md" => "# Setup\n@.planning/HANDOFF.json\n"
    }

    assert Scanner.scan(stale_tree, &Map.fetch!(stale_files, &1)) == [
             %{
               file: "README.md",
               kind: :active_citation,
               line: 2,
               target: ".planning/HANDOFF.json"
             }
           ]

    clean_files = %{
      "README.md" =>
        "# Removal notes\nThe removed path `.planning/HANDOFF.json` is absent by design.\n"
    }

    assert Scanner.scan(stale_tree, &Map.fetch!(clean_files, &1)) == []
  end

  test "scanner rejects tracked removal targets and unexpected root one-off executables" do
    tree = %{
      tracked: ["fix_tests.exs", "patch_release.rb", "mix.exs"],
      executables: ["fix_tests.exs", "patch_release.rb", "mix.exs"],
      documents: []
    }

    files = %{
      "fix_tests.exs" => "File.write!(\"README.md\", \"patched\")\n",
      "patch_release.rb" => "File.write('README.md', 'patched')\n",
      "mix.exs" => "defmodule Threadline.MixProject do\nend\n"
    }

    assert Scanner.scan(tree, &Map.fetch!(files, &1)) == [
             %{
               file: "fix_tests.exs",
               kind: :tracked_removed_path,
               line: 1,
               target: "fix_tests.exs"
             },
             %{file: "patch_release.rb", kind: :root_one_off_executable, line: 1, target: nil}
           ]
  end

  test "repository file sets never treat planning history as an executable consumer" do
    planning_script =
      ".planning/milestones/v1.39-phases/192-ci-cd-measurement-and-efficiency-hardening/scripts/aggregate-ci-baseline.sh"

    assert %{executables: [], documents: []} =
             Scanner.repository_file_sets([planning_script])
  end

  test "live repository has no removed targets, root one-offs, or active citations" do
    root = Path.expand("../..", __DIR__)
    {tracked_output, 0} = System.cmd("git", ["ls-files", "-z"], cd: root)

    tracked = :binary.split(tracked_output, <<0>>, [:global, :trim_all])
    file_sets = Scanner.repository_file_sets(tracked)

    assert Scanner.scan(file_sets, fn relative ->
             relative |> then(&Path.join(root, &1)) |> File.read!()
           end) == []
  end
end
