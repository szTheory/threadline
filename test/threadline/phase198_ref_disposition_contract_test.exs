defmodule Threadline.Phase198RefDispositionContractTest do
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)
  @script Path.join(@root, "bin/verify-phase198-ref-disposition")
  @inventory Path.join(@root, ".planning/audits/198-round10-ref-disposition.json")
  @decision Path.join(@root, ".planning/audits/198-round10-ref-disposition.md")

  @required_paths [
    ["schema_version"],
    ["observed_at"],
    ["repository"],
    ["provenance"],
    ["provenance", "active_branch"],
    ["provenance", "active_head_sha"],
    ["provenance", "upstream"],
    ["provenance", "upstream_sha"],
    ["provenance", "authority"],
    ["target_universe"],
    ["target_universe", "local"],
    ["target_universe", "remote"],
    ["stable_controls"],
    ["stable_controls", "origin_main_sha"],
    ["stable_controls", "pr34"],
    ["stable_controls", "ruleset_protection_digest"],
    ["stable_controls", "classic_protection"],
    ["stable_controls", "required_contexts"],
    ["stable_controls", "required_contexts_digest"],
    ["stable_controls", "worktrees"],
    ["stable_controls", "worktree_list_digest"],
    ["targets"],
    ["targets", 0, "branch"],
    ["targets", 0, "pr"],
    ["targets", 0, "evidence_purpose"],
    ["targets", 0, "observed_at"],
    ["targets", 0, "local"],
    ["targets", 0, "remote"],
    ["targets", 0, "pull_request"],
    ["targets", 0, "recommendation"],
    ["targets", 0, "archive_sha"],
    ["targets", 0, "restore_command"],
    ["targets", 0, "local", "sha"],
    ["targets", 0, "local", "merge_base_head"],
    ["targets", 0, "local", "merge_base_main"],
    ["targets", 0, "local", "ancestor_of_head"],
    ["targets", 0, "local", "ancestor_of_main"],
    ["targets", 0, "local", "vs_head"],
    ["targets", 0, "local", "vs_main"],
    ["targets", 0, "local", "unique_vs_head"],
    ["targets", 0, "local", "unique_vs_main"],
    ["targets", 0, "local", "diffstat_vs_head"],
    ["targets", 0, "local", "diffstat_vs_main"],
    ["targets", 0, "remote", "sha"],
    ["targets", 0, "remote", "merge_base_head"],
    ["targets", 0, "remote", "merge_base_main"],
    ["targets", 0, "remote", "ancestor_of_head"],
    ["targets", 0, "remote", "ancestor_of_main"],
    ["targets", 0, "remote", "vs_head"],
    ["targets", 0, "remote", "vs_main"],
    ["targets", 0, "remote", "unique_vs_head"],
    ["targets", 0, "remote", "unique_vs_main"],
    ["targets", 0, "remote", "diffstat_vs_head"],
    ["targets", 0, "remote", "diffstat_vs_main"],
    ["targets", 0, "pull_request", "number"],
    ["targets", 0, "pull_request", "state"],
    ["targets", 0, "pull_request", "is_draft"],
    ["targets", 0, "pull_request", "merge_state"],
    ["targets", 0, "pull_request", "head"],
    ["targets", 0, "pull_request", "base"],
    ["targets", 0, "pull_request", "head_sha"],
    ["targets", 0, "recommendation", "action"],
    ["targets", 0, "recommendation", "rationale"],
    ["decision"],
    ["execution"],
    ["command_receipts"]
  ]

  test "canonical inventory is schema-valid, live-equal, Markdown-joined, and mutation-free" do
    assert {output, 0} = run(@inventory)
    assert output =~ "exactly 3 decision targets"
    assert output =~ "3 local and 6 remote"
  end

  for path <- @required_paths do
    label = Enum.map_join(path, ".", &to_string/1)

    test "deleting required field #{label} fails closed" do
      mutate(fn doc -> delete_path(doc, unquote(Macro.escape(path))) end)
    end
  end

  test "malformed full SHAs and digests fail closed" do
    for path <- [
          ["provenance", "active_head_sha"],
          ["stable_controls", "origin_main_sha"],
          ["stable_controls", "ruleset_protection_digest"],
          ["targets", 1, "local", "sha"],
          ["targets", 2, "pull_request", "head_sha"]
        ] do
      mutate(fn doc -> put_path(doc, path, "abc123") end)
    end
  end

  test "swapped PR head/base and branch-to-PR mappings fail" do
    mutate(fn doc ->
      doc
      |> put_path(["targets", 0, "pull_request", "head"], "main")
      |> put_path(["targets", 0, "pull_request", "base"], "ci/198-gap-closure")
    end)

    mutate(fn doc ->
      pr0 = get_in_path(doc, ["targets", 0, "pr"])
      pr1 = get_in_path(doc, ["targets", 1, "pr"])

      doc
      |> put_path(["targets", 0, "pr"], pr1)
      |> put_path(["targets", 1, "pr"], pr0)
    end)
  end

  test "a fourth target or altered complete namespace fails" do
    mutate(fn doc -> update_in(doc["targets"], &(&1 ++ [hd(&1)])) end)
    mutate(fn doc -> update_in(doc["target_universe"]["remote"], &tl/1) end)
  end

  test "stable-control drift and active-tip promotion into authority fail" do
    mutate(fn doc ->
      put_path(doc, ["stable_controls", "origin_main_sha"], String.duplicate("0", 40))
    end)

    mutate(fn doc ->
      put_in(doc["stable_controls"]["active_head_sha"], doc["provenance"]["active_head_sha"])
    end)

    mutate(fn doc -> put_in(doc["provenance"]["authority"], true) end)
  end

  test "retire recommendation fails if reachability or preservation evidence disagrees" do
    mutate(fn doc -> put_path(doc, ["targets", 0, "local", "ancestor_of_main"], false) end)

    mutate(fn doc ->
      put_path(doc, ["targets", 0, "remote", "unique_vs_main"], [
        %{"sha" => String.duplicate("a", 40), "subject" => "unique work"}
      ])
    end)
  end

  test "decision, execution state, and a simulated write-side receipt fail inventory stage" do
    mutate(fn doc -> put_in(doc["decision"], %{"option" => "retire"}) end)
    mutate(fn doc -> put_in(doc["execution"], %{"started" => true}) end)

    mutate(fn doc ->
      put_in(doc["command_receipts"], [
        %{"command" => "git push origin --delete ci/198-round5", "status" => "success"}
      ])
    end)
  end

  defp run(path) do
    System.cmd(
      @script,
      ["inventory", "--inventory", path, "--decision", @decision],
      env: [{"PHASE198_REF_DISPOSITION_LIVE_FIXTURE", @inventory}],
      stderr_to_stdout: true
    )
  end

  defp mutate(fun) do
    path = Path.join(System.tmp_dir!(), "phase198-ref-#{System.unique_integer([:positive])}.json")

    try do
      doc = @inventory |> File.read!() |> Jason.decode!() |> fun.()
      File.write!(path, Jason.encode!(doc))
      assert {_output, status} = run(path)
      refute status == 0
    after
      File.rm(path)
    end
  end

  defp get_in_path(value, []), do: value

  defp get_in_path(map, [key | rest]) when is_binary(key),
    do: get_in_path(Map.fetch!(map, key), rest)

  defp get_in_path(list, [index | rest]) when is_integer(index),
    do: get_in_path(Enum.at(list, index), rest)

  defp delete_path(map, [key]) when is_map(map), do: Map.delete(map, key)
  defp delete_path(list, [index]) when is_list(list), do: List.delete_at(list, index)

  defp delete_path(map, [key | rest]) when is_map(map),
    do: Map.update!(map, key, &delete_path(&1, rest))

  defp delete_path(list, [index | rest]) when is_list(list),
    do: List.update_at(list, index, &delete_path(&1, rest))

  defp put_path(_value, [], replacement), do: replacement

  defp put_path(map, [key | rest], replacement) when is_map(map),
    do: Map.update!(map, key, &put_path(&1, rest, replacement))

  defp put_path(list, [index | rest], replacement) when is_list(list),
    do: List.update_at(list, index, &put_path(&1, rest, replacement))
end
