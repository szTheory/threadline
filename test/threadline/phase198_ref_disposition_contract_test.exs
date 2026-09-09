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

  test "round 11 keeps divergent local and remote tips as separate preservation subjects" do
    with_round11_tracer(fn inventory, decision, live ->
      assert {output, 0} = run_stage("inventory", inventory, decision, live)
      assert output =~ "round 11"

      subjects =
        inventory |> File.read!() |> Jason.decode!() |> Map.fetch!("preservation_subjects")

      assert Enum.map(subjects, & &1["side"]) |> Enum.sort() == ["local", "origin"]
      assert subjects |> Enum.map(& &1["sha"]) |> Enum.uniq() |> length() == 2
      assert subjects |> Enum.map(& &1["archive_tag"]) |> Enum.uniq() |> length() == 2
    end)
  end

  test "round 11 rejects a missing, substituted, or collapsed divergent side" do
    with_round11_tracer(fn inventory, decision, live ->
      tracer_mutate(inventory, decision, live, fn doc ->
        update_in(doc["preservation_subjects"], &tl/1)
      end)

      tracer_mutate(inventory, decision, live, fn doc ->
        put_path(doc, ["preservation_subjects", 1, "sha"], String.duplicate("a", 40))
      end)

      tracer_mutate(inventory, decision, live, fn doc ->
        put_path(
          doc,
          ["preservation_subjects", 1, "id"],
          get_in_path(doc, ["preservation_subjects", 0, "id"])
        )
      end)
    end)
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

  defp run_stage(stage, inventory, decision, live, extra \\ []) do
    System.cmd(
      @script,
      [stage, "--inventory", inventory, "--decision", decision] ++ extra,
      env: [{"PHASE198_REF_DISPOSITION_LIVE_FIXTURE", live}],
      stderr_to_stdout: true
    )
  end

  defp with_round11_tracer(fun) do
    prefix =
      Path.join(System.tmp_dir!(), "phase198-round11-#{System.unique_integer([:positive])}")

    inventory_path = prefix <> ".json"
    decision_path = prefix <> ".md"
    live_path = prefix <> "-live.json"

    try do
      source = @inventory |> File.read!() |> Jason.decode!()
      target = hd(source["targets"])

      subjects =
        for side <- ["local", "origin"] do
          evidence = if side == "local", do: target["local"], else: target["remote"]
          sha = evidence["sha"]

          %{
            "id" => "#{side}:#{target["branch"]}@#{sha}",
            "branch" => target["branch"],
            "side" => side,
            "sha" => sha,
            "evidence" => evidence,
            "pull_request" => target["pull_request"],
            "recommendation" => target["recommendation"],
            "archive_tag" => "archive/#{target["branch"]}/#{side}-#{String.slice(sha, 0, 12)}",
            "restore_command" => "git branch #{target["branch"]} #{sha}"
          }
        end

      inventory = %{
        "schema_version" => 2,
        "round" => 11,
        "observed_at" => source["observed_at"],
        "repository" => source["repository"],
        "provenance" => source["provenance"],
        "task_baseline" => source["provenance"] |> Map.drop(["authority"]),
        "target_universe" => source["target_universe"],
        "stable_controls" => source["stable_controls"],
        "preservation_subjects" => subjects,
        "decision" => nil,
        "execution" => nil,
        "command_receipts" => []
      }

      File.write!(inventory_path, Jason.encode!(inventory))
      digest = inventory_digest(inventory_path)
      controls = inventory["stable_controls"]

      markers =
        Enum.map_join(subjects, "\n", fn subject ->
          "<!-- subject: #{subject["id"]}|#{subject["archive_tag"]}|#{subject["restore_command"]} -->"
        end)

      markdown = """
      # Phase 198 Round 11 ref disposition

      <!-- schema: phase198-ref-disposition/v2; round: 11 -->
      <!-- inventory-sha256: #{digest} -->
      <!-- controls: #{controls["origin_main_sha"]}|34|#{controls["pr34"]["head_sha"]}|#{controls["ruleset_protection_digest"]}|#{controls["required_contexts_digest"]}|#{controls["worktree_list_digest"]} -->
      #{markers}

      Plan 52 is preserved but superseded as inapplicable because Plan 51 recorded verbatim abort and proved the exact-three scope incomplete.

      ## Maintainer decision

      Status: undecided. No authority is granted.
      """

      File.write!(decision_path, markdown)
      File.write!(live_path, Jason.encode!(inventory))
      fun.(inventory_path, decision_path, live_path)
    after
      File.rm(inventory_path)
      File.rm(decision_path)
      File.rm(live_path)
    end
  end

  defp tracer_mutate(inventory, decision, live, fun) do
    path = inventory <> ".mutated"

    try do
      doc = inventory |> File.read!() |> Jason.decode!() |> fun.()
      File.write!(path, Jason.encode!(doc))
      assert {_output, status} = run_stage("inventory", path, decision, live)
      refute status == 0
    after
      File.rm(path)
    end
  end

  defp inventory_digest(path) do
    {canonical, 0} =
      System.cmd("jq", ["-cS", "del(.decision,.execution,.command_receipts)", path])

    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
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
