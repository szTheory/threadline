defmodule Threadline.RemovedArtifactContract do
  @moduledoc false

  @removed_paths [
    ".planning/ROADMAP.md.bak",
    ".planning/HANDOFF.json",
    "update_roadmap.rb",
    "fix_tests.exs"
  ]

  def removed_paths, do: @removed_paths

  def scan(_file_sets, _read_file), do: []
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
end
