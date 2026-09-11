defmodule Threadline.OperatorSurface.FixtureContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  setup do
    repo =
      Path.join(
        System.tmp_dir!(),
        "threadline-fixture-contract-#{System.unique_integer([:positive])}"
      )

    corpus = Path.join(repo, "operator-surface")

    tracked = %{
      "critic-scores/.gitkeep" => "",
      "design-system-ledger.json" => ~s({"mechanical_floors":{}}\n),
      "golden/golden-set.json" => ~s({"version":"1","items":[]}\n),
      "refute/refute-set.json" => ~s({"version":"1","items":[]}\n),
      "scorecards/page.timeline.happy__dark-1280.aria.yml" => "role: main\n",
      "scorecards/page.timeline.happy__dark-1280.json" =>
        ~s({"cell_id":"page.timeline.happy__dark-1280"}\n)
    }

    File.mkdir_p!(repo)
    git!(repo, ["init", "--quiet"])
    File.write!(Path.join(repo, ".gitignore"), "operator-surface/critic-scores/*.json\n")

    for {relative, bytes} <- tracked do
      path = Path.join(corpus, relative)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, bytes)
    end

    File.write!(Path.join(corpus, "critic-scores/local-generated.json"), ~s({"score":91}\n))
    git!(repo, ["add", ".gitignore", "operator-surface"])

    on_exit(fn -> File.rm_rf!(repo) end)

    {:ok, repo: repo, tracked: tracked}
  end

  test "manifest is derived from tracked evidence entries only", %{repo: repo, tracked: tracked} do
    manifest = tracked_manifest(repo, "operator-surface")
    expected_paths = tracked |> Map.keys() |> Enum.sort()

    assert Enum.map(manifest, & &1.path) == expected_paths

    assert manifest ==
             Enum.map(expected_paths, fn path ->
               %{path: path, sha256: sha256(Map.fetch!(tracked, path))}
             end)

    refute Enum.any?(manifest, &(&1.path == "critic-scores/local-generated.json"))
    assert manifest == tracked_manifest(repo, "operator-surface")
  end

  defp tracked_manifest(_repo, _corpus_root), do: []

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp git!(repo, args) do
    case System.cmd("git", args, cd: repo, stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, status} -> flunk("git #{Enum.join(args, " ")} failed (#{status}): #{output}")
    end
  end
end
