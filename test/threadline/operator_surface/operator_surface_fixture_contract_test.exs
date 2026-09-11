defmodule Threadline.OperatorSurface.FixtureContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repository_root Path.expand("../../..", __DIR__)
  @live_corpus_root "test/fixtures/operator_surface"

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

  test "live repository corpus matches its tracked manifest and validates non-vacuously" do
    manifest = evidence_manifest(@repository_root, @live_corpus_root)

    assert manifest != [],
           "#{Path.join(@repository_root, @live_corpus_root)} must contain tracked evidence"

    assert File.read!(Path.join(@repository_root, @live_corpus_root <> "/manifest.sha256")) ==
             encode_manifest(manifest)

    assert validate_corpus(@repository_root, @live_corpus_root) == :ok
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

  defp validate_corpus(repo, corpus_root) do
    root = Path.join(repo, corpus_root)

    if File.dir?(root) do
      manifest_paths =
        repo
        |> tracked_manifest(corpus_root)
        |> Enum.map(& &1.path)
        |> MapSet.new()

      with :ok <- require_corpus_entries(manifest_paths, root),
           {:ok, ledger} <- decode_json(root, "design-system-ledger.json"),
           {:ok, golden} <- decode_json(root, "golden/golden-set.json"),
           {:ok, refute} <- decode_json(root, "refute/refute-set.json"),
           {:ok, scorecards} <- decode_scorecards(root, manifest_paths),
           :ok <- validate_aria_pairs(manifest_paths),
           :ok <- validate_references(ledger, golden, refute, scorecards) do
        :ok
      end
    else
      {:error, {:missing_root, root}}
    end
  end

  defp require_corpus_entries(paths, root) do
    required = [
      "critic-scores/.gitkeep",
      "design-system-ledger.json",
      "golden/golden-set.json",
      "refute/refute-set.json"
    ]

    case Enum.find(required, &(not MapSet.member?(paths, &1))) do
      nil -> :ok
      missing -> {:error, {:missing_required_entry, Path.join(root, missing)}}
    end
  end

  defp decode_scorecards(root, manifest_paths) do
    paths =
      manifest_paths
      |> Enum.filter(&(String.starts_with?(&1, "scorecards/") and String.ends_with?(&1, ".json")))
      |> Enum.sort()

    if paths == [] do
      {:error, {:empty_scorecards, Path.join(root, "scorecards")}}
    else
      Enum.reduce_while(paths, {:ok, %{}}, fn path, {:ok, scorecards} ->
        case decode_json(root, path) do
          {:ok, %{"cell_id" => cell_id}} when is_binary(cell_id) and cell_id != "" ->
            {:cont, {:ok, Map.put(scorecards, cell_id, path)}}

          {:ok, _document} ->
            {:halt, {:error, {:malformed_structure, Path.join(root, path)}}}

          {:error, _reason} = error ->
            {:halt, error}
        end
      end)
    end
  end

  defp decode_json(root, relative_path) do
    path = Path.join(root, relative_path)

    case Jason.decode(File.read!(path)) do
      {:ok, document} when is_map(document) -> {:ok, document}
      _error -> {:error, {:malformed_json, path}}
    end
  end

  defp validate_aria_pairs(paths) do
    paths
    |> Enum.filter(&String.ends_with?(&1, ".aria.yml"))
    |> Enum.find_value(:ok, fn aria_path ->
      scorecard_path = String.replace_suffix(aria_path, ".aria.yml", ".json")

      if MapSet.member?(paths, scorecard_path) do
        false
      else
        {:error, {:broken_pair, %{source: aria_path, missing: scorecard_path}}}
      end
    end)
  end

  defp validate_references(ledger, golden, refute, scorecards) do
    with {:ok, references} <- corpus_references(ledger, golden, refute) do
      case Enum.find(references, fn {_source, cell_id} ->
             not Map.has_key?(scorecards, cell_id)
           end) do
        nil -> :ok
        {source, cell_id} -> {:error, {:broken_reference, %{source: source, cell_id: cell_id}}}
      end
    end
  end

  defp corpus_references(ledger, golden, refute) do
    with required when is_list(required) <- ledger["required_scorecards"],
         golden_items when is_list(golden_items) and golden_items != [] <- golden["items"],
         refute_items when is_list(refute_items) and refute_items != [] <- refute["items"] do
      references =
        Enum.map(required, &{"design-system-ledger.json", &1}) ++
          Enum.map(golden_items, &{"golden/golden-set.json", &1["cell_id"]}) ++
          Enum.flat_map(refute_items, fn item ->
            [
              {"refute/refute-set.json", item["polished_cell_id"]},
              {"refute/refute-set.json", item["flawed_cell_id"]}
            ]
          end)

      if Enum.all?(references, fn {_source, cell_id} -> is_binary(cell_id) and cell_id != "" end) do
        {:ok, references}
      else
        {:error, {:malformed_structure, "corpus references"}}
      end
    else
      _invalid -> {:error, {:malformed_structure, "corpus roots"}}
    end
  end

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

  defp evidence_manifest(repo, corpus_root) do
    repo
    |> tracked_manifest(corpus_root)
    |> Enum.reject(&(&1.path in ["README.md", "manifest.sha256"]))
  end

  defp encode_manifest(manifest) do
    Enum.map_join(manifest, "", &"#{&1.sha256}  #{&1.path}\n")
  end

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp git!(repo, args) do
    case System.cmd("git", args, cd: repo, stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, status} -> flunk("git #{Enum.join(args, " ")} failed (#{status}): #{output}")
    end
  end
end
