defmodule Threadline.OperatorSurface.FixtureContractTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :repo_contract

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
      "design-system-ledger.json" => ledger_json("page.timeline.happy"),
      "local/.gitkeep" => ""
    }

    File.mkdir_p!(repo)
    git!(repo, ["init", "--quiet"])
    File.write!(Path.join(repo, ".gitignore"), "operator-surface/local/*.json\n")

    for {relative, bytes} <- tracked do
      path = Path.join(corpus, relative)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, bytes)
    end

    File.write!(Path.join(corpus, "local/local-generated.json"), ~s({"score":91}\n))
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

    refute Enum.any?(manifest, &(&1.path == "local/local-generated.json"))
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

  test "generic source inventories are separate from the immutable rendered corpus", %{repo: repo} do
    before = evidence_manifest(repo, "operator-surface")

    for name <- ["route-inventory.json", "source-surface-checklist.json"] do
      File.write!(Path.join([repo, "operator-surface", name]), "{}\n")
      git!(repo, ["add", "operator-surface/" <> name])
    end

    assert evidence_manifest(repo, "operator-surface") == before
    assert length(tracked_manifest(repo, "operator-surface")) == length(before) + 2

    File.write!(Path.join([repo, "operator-surface", "unexpected-reference.json"]), "{}\n")
    git!(repo, ["add", "operator-surface/unexpected-reference.json"])
    refute evidence_manifest(repo, "operator-surface") == before
  end

  test "tracked byte changes alter the manifest", %{repo: repo} do
    before = tracked_manifest(repo, "operator-surface")
    tracked = Path.join(repo, "operator-surface/design-system-ledger.json")

    File.write!(tracked, ledger_json("page.home.happy"))

    after_mutation = tracked_manifest(repo, "operator-surface")
    refute after_mutation == before

    changed =
      Enum.find(after_mutation, &(&1.path == "design-system-ledger.json"))

    original = Enum.find(before, &(&1.path == "design-system-ledger.json"))
    refute changed.sha256 == original.sha256
  end

  test "ignored local output is manifest-independent until it is tracked", %{repo: repo} do
    generated = Path.join(repo, "operator-surface/local/local-generated.json")
    before = tracked_manifest(repo, "operator-surface")

    File.write!(generated, ~s({"score":17}\n))
    assert tracked_manifest(repo, "operator-surface") == before

    File.rm!(generated)
    assert tracked_manifest(repo, "operator-surface") == before

    File.write!(generated, ~s({"score":42}\n))
    git!(repo, ["add", "--force", "operator-surface/local/local-generated.json"])

    promoted = tracked_manifest(repo, "operator-surface")
    refute promoted == before
    assert Enum.any?(promoted, &(&1.path == "local/local-generated.json"))
  end

  test "corpus validation rejects missing roots, malformed structure, and broken joins", %{
    repo: repo
  } do
    assert validate_corpus(repo, "operator-surface") == :ok

    assert {:error, {:missing_root, missing_path}} = validate_corpus(repo, "missing-corpus")
    assert missing_path == Path.join(repo, "missing-corpus")

    ledger = Path.join(repo, "operator-surface/design-system-ledger.json")
    File.write!(ledger, "{not-json")

    assert {:error, {:malformed_json, ^ledger}} = validate_corpus(repo, "operator-surface")

    File.write!(ledger, ~s({"entries":[],"screenshot_allowlist":{"ci":[],"local_review":[]}}\n))

    assert {:error, {:malformed_structure, ^ledger}} = validate_corpus(repo, "operator-surface")

    File.write!(
      ledger,
      ~s({"entries":[{"id":"page.timeline.happy"}],"screenshot_allowlist":{"ci":[{"ledger_id":"page.missing.happy"}],"local_review":[]}}\n)
    )

    assert {:error, {:broken_reference, details}} = validate_corpus(repo, "operator-surface")
    assert details.source == "design-system-ledger.json"
    assert details.ledger_id == "page.missing.happy"

    git!(repo, [
      "rm",
      "--quiet",
      "--cached",
      "--force",
      "operator-surface/design-system-ledger.json"
    ])

    assert {:error, {:missing_required_entry, missing}} =
             validate_corpus(repo, "operator-surface")

    assert missing == ledger
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
           {:ok, entry_ids, allowlisted} <- ledger_shape(root, ledger) do
        validate_references(entry_ids, allowlisted)
      end
    else
      {:error, {:missing_root, root}}
    end
  end

  defp require_corpus_entries(paths, root) do
    if MapSet.member?(paths, "design-system-ledger.json"),
      do: :ok,
      else: {:error, {:missing_required_entry, Path.join(root, "design-system-ledger.json")}}
  end

  defp decode_json(root, relative_path) do
    path = Path.join(root, relative_path)

    case Jason.decode(File.read!(path)) do
      {:ok, document} when is_map(document) -> {:ok, document}
      _error -> {:error, {:malformed_json, path}}
    end
  end

  # The ledger must carry a non-empty entry list and the screenshot allowlist that the
  # stress session and operator-stress.spec.ts read.
  defp ledger_shape(root, %{"entries" => [_ | _] = entries, "screenshot_allowlist" => lanes})
       when is_map(lanes) do
    ids = for %{"id" => id} <- entries, is_binary(id) and id != "", do: id
    allowlisted = for {_lane, items} <- lanes, is_list(items), item <- items, do: item

    if length(ids) == length(entries),
      do: {:ok, MapSet.new(ids), allowlisted},
      else: {:error, {:malformed_structure, Path.join(root, "design-system-ledger.json")}}
  end

  defp ledger_shape(root, _ledger),
    do: {:error, {:malformed_structure, Path.join(root, "design-system-ledger.json")}}

  defp validate_references(entry_ids, allowlisted) do
    case Enum.find(allowlisted, &(not MapSet.member?(entry_ids, &1["ledger_id"]))) do
      nil ->
        :ok

      item ->
        {:error,
         {:broken_reference, %{source: "design-system-ledger.json", ledger_id: item["ledger_id"]}}}
    end
  end

  defp ledger_json(entry_id) do
    ~s({"entries":[{"id":"#{entry_id}"}],"screenshot_allowlist":{"ci":[{"ledger_id":"#{entry_id}"}],"local_review":[]}}\n)
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
    |> Enum.reject(
      &(&1.path in [
          "README.md",
          "manifest.sha256",
          "route-inventory.json",
          "source-surface-checklist.json"
        ])
    )
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
