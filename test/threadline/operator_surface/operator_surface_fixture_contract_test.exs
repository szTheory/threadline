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
      "design-system-ledger.json" =>
        ~s({"mechanical_floors":{},"required_scorecards":["page.timeline.happy__dark-1280"]}\n),
      "golden/golden-set.json" =>
        ~s({"version":"1","items":[{"cell_id":"page.timeline.happy__dark-1280"}]}\n),
      "refute/refute-set.json" =>
        ~s({"version":"1","items":[{"twin_id":"refute.timeline","polished_cell_id":"page.timeline.happy__dark-1280","flawed_cell_id":"page.timeline.happy__dark-1280"}]}\n),
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

  test "tracked byte changes alter the manifest", %{repo: repo} do
    before = tracked_manifest(repo, "operator-surface")
    tracked = Path.join(repo, "operator-surface/design-system-ledger.json")

    File.write!(tracked, ~s({"mechanical_floors":{"spacing":4}}\n))

    after_mutation = tracked_manifest(repo, "operator-surface")
    refute after_mutation == before

    changed =
      Enum.find(after_mutation, &(&1.path == "design-system-ledger.json"))

    original = Enum.find(before, &(&1.path == "design-system-ledger.json"))
    refute changed.sha256 == original.sha256
  end

  test "ignored score changes are manifest-independent until the score is tracked", %{repo: repo} do
    generated = Path.join(repo, "operator-surface/critic-scores/local-generated.json")
    before = tracked_manifest(repo, "operator-surface")

    File.write!(generated, ~s({"score":17}\n))
    assert tracked_manifest(repo, "operator-surface") == before

    File.rm!(generated)
    assert tracked_manifest(repo, "operator-surface") == before

    File.write!(generated, ~s({"score":42}\n))
    git!(repo, ["add", "--force", "operator-surface/critic-scores/local-generated.json"])

    promoted = tracked_manifest(repo, "operator-surface")
    refute promoted == before
    assert Enum.any?(promoted, &(&1.path == "critic-scores/local-generated.json"))
  end

  test "corpus validation rejects missing roots, malformed structure, and broken joins", %{
    repo: repo
  } do
    assert validate_corpus(repo, "operator-surface") == :ok

    assert {:error, {:missing_root, missing_path}} = validate_corpus(repo, "missing-corpus")
    assert missing_path == Path.join(repo, "missing-corpus")

    golden = Path.join(repo, "operator-surface/golden/golden-set.json")
    File.write!(golden, "{not-json")

    assert {:error, {:malformed_json, ^golden}} = validate_corpus(repo, "operator-surface")

    File.write!(
      golden,
      ~s({"version":"1","items":[{"cell_id":"page.missing.happy__dark-1280"}]}\n)
    )

    assert {:error, {:broken_reference, details}} = validate_corpus(repo, "operator-surface")
    assert details.source == "golden/golden-set.json"
    assert details.cell_id == "page.missing.happy__dark-1280"
  end

  defp validate_corpus(_repo, _corpus_root), do: :ok

  defp tracked_manifest(repo, corpus_root) do
    {output, 0} =
      System.cmd("git", ["ls-files", "-z", "--", corpus_root],
        cd: repo,
        stderr_to_stdout: true
      )

    output
    |> :binary.split(<<0>>, [:global, :trim])
    |> Enum.sort()
    |> Enum.map(fn tracked_path ->
      relative_path = Path.relative_to(tracked_path, corpus_root)
      bytes = File.read!(Path.join(repo, tracked_path))

      %{path: relative_path, sha256: sha256(bytes)}
    end)
  end

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp git!(repo, args) do
    case System.cmd("git", args, cd: repo, stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, status} -> flunk("git #{Enum.join(args, " ")} failed (#{status}): #{output}")
    end
  end
end
