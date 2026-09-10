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

  @tag :classic_adapter
  test "classic protection adapter preserves absent present and observation errors" do
    with_fake_gh(fn env ->
      assert {"absent\n", 0} = run_classic_adapter(env, "404")
      assert {"present\n", 0} = run_classic_adapter(env, "success")

      for failure <- ~w(403 429 500 502 503 transport malformed unknown) do
        {output, status} = run_classic_adapter(env, failure)
        refute status == 0, "#{failure} unexpectedly produced a protection state: #{output}"
        refute output in ["absent\n", "present\n"]
      end

      for invalid <- ["", "unknown", "absent\npresent", "present extra"] do
        {output, status} =
          System.cmd(@script, ["fixture-classic-consumer", invalid],
            env: env,
            stderr_to_stdout: true
          )

        refute status == 0
        assert output =~ "unknown state"
      end
    end)
  end

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

  test "completed round 11 remains readable only as immutable legacy receipt evidence" do
    inventory = Path.join(@root, ".planning/audits/198-round11-ref-disposition.json")
    decision = Path.join(@root, ".planning/audits/198-round11-ref-disposition.md")

    assert {output, 0} =
             System.cmd(
               @script,
               ["inventory", "--inventory", inventory, "--decision", decision],
               stderr_to_stdout: true
             )

    assert output =~ "historical inventory OK"
    assert output =~ "not retrospective argv proof"
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

  test "round 11 fixture proves inventory, retire authority, controls, post-target, and final" do
    with_round11_lifecycle(fn fixture ->
      assert {_, 0} =
               run_stage(
                 "inventory",
                 fixture.inventory,
                 fixture.undecided_md,
                 fixture.live_initial
               )

      assert {_, 0} =
               run_stage("decision", fixture.decided, fixture.decided_md, fixture.live_initial)

      for target <- fixture.targets do
        assert {_, 0} =
                 run_stage(
                   "authority",
                   fixture.decided,
                   fixture.decided_md,
                   fixture.live_initial,
                   [
                     "--target",
                     target
                   ]
                 )

        assert {_, 0} =
                 run_stage(
                   "post-target",
                   fixture.post[target],
                   fixture.decided_md,
                   fixture.live_post[target],
                   [
                     "--target",
                     target,
                     "--register",
                     fixture.register
                   ]
                 )
      end

      assert {_, 0} =
               run_stage("controls", fixture.decided, fixture.decided_md, fixture.live_initial)

      assert {output, 0} =
               run_stage("final", fixture.final, fixture.decided_md, fixture.live_final, [
                 "--register",
                 fixture.register
               ])

      assert output =~ "live-derived namespaces empty"
    end)
  end

  test "production lifecycle stages reject fixture adapters and disabled live observation" do
    with_round11_lifecycle(fn fixture ->
      target = "ci/198-gap-closure"

      invocations = [
        {"decision", fixture.decided, fixture.live_initial, []},
        {"authority", fixture.decided, fixture.live_initial, ["--target", target]},
        {"controls", fixture.decided, fixture.live_initial, []},
        {"post-target", fixture.post[target], fixture.live_post[target],
         ["--target", target, "--register", fixture.register]},
        {"final", fixture.final, fixture.live_final, ["--register", fixture.register]}
      ]

      for {stage, inventory, live, extra} <- invocations do
        {fixture_output, fixture_status} =
          run_production_stage(stage, inventory, fixture.decided_md, extra,
            PHASE198_REF_DISPOSITION_LIVE_FIXTURE: live
          )

        refute fixture_status == 0
        assert fixture_output =~ ~s("stage":"#{stage}")
        assert fixture_output =~ ~s("operation":"fixture-boundary")

        {disabled_output, disabled_status} =
          run_production_stage(stage, inventory, fixture.decided_md, extra,
            PHASE198_REF_DISPOSITION_DISABLE_LIVE: "1"
          )

        refute disabled_status == 0
        assert disabled_output =~ ~s("stage":"#{stage}")
        assert disabled_output =~ ~s("retryable":false)
      end
    end)
  end

  test "fixture decision requires pristine execution state and zero receipts" do
    with_round11_lifecycle(fn fixture ->
      pristine =
        mutate_json_file(fixture.decided, fn doc ->
          doc
          |> Map.put("execution", nil)
          |> Map.put("command_receipts", [])
        end)

      assert {_, 0} =
               run_stage("decision", pristine, fixture.decided_md, fixture.live_initial)

      for mutation <- [
            &Map.put(&1, "execution", %{}),
            &Map.put(&1, "execution", %{"status" => "authorized"}),
            &Map.put(&1, "command_receipts", [%{"type" => "archive-register-row"}])
          ] do
        tainted = mutate_json_file(pristine, mutation)
        assert_failed(run_stage("decision", tainted, fixture.decided_md, fixture.live_initial))
        File.rm(tainted)
      end

      File.rm(pristine)
    end)
  end

  test "bounded live failure is structured and cannot fall back to committed evidence" do
    with_round11_lifecycle(fn fixture ->
      pristine =
        mutate_json_file(fixture.decided, fn doc ->
          doc
          |> Map.put("execution", nil)
          |> Map.put("command_receipts", [])
        end)

      {output, status} =
        run_production_stage("decision", pristine, fixture.decided_md, [],
          PHASE198_REF_DISPOSITION_LIVE_DEADLINE_SECONDS: "0"
        )

      refute status == 0
      assert output =~ ~s("stage":"decision")
      assert output =~ ~s("operation":"deadline")
      assert output =~ ~s("elapsed_ms":)
      assert output =~ ~s("deadline_ms":0)
      assert output =~ ~s("retryable":true)
      refute output =~ "decision OK"
      File.rm(pristine)
    end)
  end

  test "round 11 authority rejects silence, preserve, abort, stale digests, missing subjects, and outsiders" do
    with_round11_lifecycle(fn fixture ->
      assert_failed(
        run_stage("authority", fixture.inventory, fixture.undecided_md, fixture.live_initial, [
          "--target",
          hd(fixture.targets)
        ])
      )

      for option <- ["preserve all subjects", "abort"] do
        {inventory, markdown} = lifecycle_decision_variant(fixture, option)

        assert_failed(
          run_stage("authority", inventory, markdown, fixture.live_initial, [
            "--target",
            hd(fixture.targets)
          ])
        )
      end

      stale_md =
        Regex.replace(
          ~r/<!-- inventory-sha256: [0-9a-f]{64}/,
          File.read!(fixture.decided_md),
          "<!-- inventory-sha256: #{String.duplicate("0", 64)}"
        )

      stale_md = write_text(fixture.dir, "stale-digest.md", stale_md)
      assert_failed(run_stage("decision", fixture.decided, stale_md, fixture.live_initial))

      missing =
        mutate_json_file(fixture.decided, fn doc ->
          update_in(doc["preservation_subjects"], &tl/1)
        end)

      assert_failed(
        run_stage("authority", missing, fixture.decided_md, fixture.live_initial, [
          "--target",
          hd(fixture.targets)
        ])
      )

      File.rm(missing)

      assert_failed(
        run_stage("authority", fixture.decided, fixture.decided_md, fixture.live_initial, [
          "--target",
          "ci/198-unremembered"
        ])
      )
    end)
  end

  test "round 11 controls fail on every immutable control or task-baseline drift" do
    with_round11_lifecycle(fn fixture ->
      paths = [
        ["stable_controls", "origin_main_sha"],
        ["stable_controls", "pr34", "head_sha"],
        ["stable_controls", "ruleset_protection_digest"],
        ["stable_controls", "required_contexts"],
        ["stable_controls", "worktrees"],
        ["task_baseline", "active_branch"],
        ["task_baseline", "active_head_sha"],
        ["task_baseline", "upstream"]
      ]

      for path <- paths do
        live =
          mutate_json_file(fixture.live_initial, fn doc ->
            current = get_in_path(doc, path)
            replacement = if is_list(current), do: [], else: String.duplicate("0", 40)
            put_path(doc, path, replacement)
          end)

        assert_failed(run_stage("controls", fixture.decided, fixture.decided_md, live))
        File.rm(live)
      end
    end)
  end

  test "fixture authority compares every identity and protected-control field used by production" do
    with_round11_lifecycle(fn fixture ->
      target = "ci/198-gap-closure"

      paths = [
        ["target_universe", "remote", 0, "sha"],
        ["pull_requests", target, "state"],
        ["pull_requests", target, "head"],
        ["pull_requests", target, "base"],
        ["pull_requests", target, "head_sha"],
        ["stable_controls", "origin_main_sha"],
        ["stable_controls", "pr34", "head_sha"],
        ["stable_controls", "required_contexts"],
        ["stable_controls", "ruleset_protection_digest"],
        ["stable_controls", "classic_protection"],
        ["stable_controls", "worktrees"]
      ]

      for path <- paths do
        live =
          mutate_json_file(fixture.live_initial, fn doc ->
            current = get_in_path(doc, path)

            replacement =
              cond do
                is_list(current) -> []
                is_boolean(current) -> not current
                current == "absent" -> "present"
                true -> String.duplicate("0", 40)
              end

            put_path(doc, path, replacement)
          end)

        assert_failed(
          run_stage("authority", fixture.decided, fixture.decided_md, live, [
            "--target",
            target
          ])
        )

        File.rm(live)
      end
    end)
  end

  test "controls post-target and final independently reject protected-control drift" do
    with_round11_lifecycle(fn fixture ->
      target = hd(fixture.targets)

      for {stage, inventory, live, extra} <- [
            {"controls", fixture.decided, fixture.live_initial, []},
            {"post-target", fixture.post[target], fixture.live_post[target],
             ["--target", target, "--register", fixture.register]},
            {"final", fixture.final, fixture.live_final, ["--register", fixture.register]}
          ] do
        drifted =
          mutate_json_file(live, fn doc ->
            put_path(
              doc,
              ["stable_controls", "required_contexts_digest"],
              String.duplicate("0", 64)
            )
          end)

        assert_failed(run_stage(stage, inventory, fixture.decided_md, drifted, extra))
        File.rm(drifted)
      end
    end)
  end

  test "round 11 refuses delete-before-preserve ordering and incomplete divergent preservation" do
    with_round11_lifecycle(fn fixture ->
      target = "ci/198-gap-closure"

      reordered =
        mutate_json_file(fixture.post[target], fn doc ->
          [first | rest] = doc["command_receipts"]
          put_in(doc["command_receipts"], [List.last(rest), first | Enum.drop(rest, -1)])
        end)

      assert_failed(
        run_stage("post-target", reordered, fixture.decided_md, fixture.live_post[target], [
          "--target",
          target,
          "--register",
          fixture.register
        ])
      )

      File.rm(reordered)

      incomplete =
        mutate_json_file(fixture.post[target], fn doc ->
          update_in(doc["command_receipts"], fn receipts ->
            Enum.reject(receipts, fn receipt ->
              is_binary(receipt["subject_id"]) and
                receipt["subject_id"] =~ "origin:ci/198-gap-closure"
            end)
          end)
        end)

      assert_failed(
        run_stage("post-target", incomplete, fixture.decided_md, fixture.live_post[target], [
          "--target",
          target,
          "--register",
          fixture.register
        ])
      )

      File.rm(incomplete)
    end)
  end

  test "round 11 final derives both namespaces and rejects an unremembered live ref or GREEN-07 promotion" do
    with_round11_lifecycle(fn fixture ->
      extra =
        mutate_json_file(fixture.live_final, fn doc ->
          put_in(doc["target_universe"]["remote"], [
            %{"branch" => "ci/198-unremembered", "sha" => String.duplicate("a", 40)}
          ])
        end)

      assert_failed(
        run_stage("final", fixture.final, fixture.decided_md, extra, [
          "--register",
          fixture.register
        ])
      )

      File.rm(extra)

      promoted = mutate_json_file(fixture.live_final, &put_in(&1["green07_status"], "Complete"))

      assert_failed(
        run_stage("final", fixture.final, fixture.decided_md, promoted, [
          "--register",
          fixture.register
        ])
      )

      File.rm(promoted)
    end)
  end

  test "fixture mutation receipts reject force batching ambiguity and unverifiable outcomes" do
    with_round11_lifecycle(fn fixture ->
      target = "ci/198-gap-closure"
      valid = fixture.post[target]

      mutations = [
        fn receipt -> Map.put(receipt, "force", true) end,
        fn receipt -> Map.put(receipt, "argv", Enum.join(receipt["argv"], " ")) end,
        fn receipt -> Map.put(receipt, "argv", receipt["argv"] ++ ["refs/tags/extra"]) end,
        fn receipt -> Map.put(receipt, "argv", List.insert_at(receipt["argv"], 1, "--force")) end,
        fn receipt ->
          Map.put(receipt, "argv", List.replace_at(receipt["argv"], -1, "refs/tags/*"))
        end,
        fn receipt -> Map.put(receipt, "started_at", receipt["completed_at"]) end,
        fn receipt -> Map.put(receipt, "completed_at", "2026-09-09T21:59:59Z") end,
        fn receipt -> Map.put(receipt, "exit_status", 1) end,
        fn receipt -> Map.put(receipt, "before", receipt["after"]) end,
        fn receipt -> Map.delete(receipt, "argv") end
      ]

      for {mutation, index} <- Enum.with_index(mutations) do
        malformed =
          mutate_json_file(valid, fn doc ->
            update_in(doc["command_receipts"], fn [first | rest] ->
              [mutation.(first) | rest]
            end)
          end)

        assert_failed(
          run_stage("post-target", malformed, fixture.decided_md, fixture.live_post[target], [
            "--target",
            target,
            "--register",
            fixture.register
          ])
        )

        File.rm(malformed)
        assert index >= 0
      end
    end)
  end

  test "each destructive receipt names exactly one literal authorized object" do
    with_round11_lifecycle(fn fixture ->
      target = "ci/198-gap-closure"

      cases = [
        {"local-annotated-tag", fn argv -> argv ++ [String.duplicate("a", 40)] end},
        {"remote-single-tag", fn argv -> argv ++ ["refs/tags/extra:refs/tags/extra"] end},
        {"pr-close", fn argv -> List.insert_at(argv, 4, "30") end},
        {"remote-ref-delete", fn argv -> List.replace_at(argv, -1, ":refs/heads/ci/198-*") end},
        {"local-ref-delete", fn argv -> List.replace_at(argv, 2, "-D") end}
      ]

      for {type, mutate_argv} <- cases do
        malformed =
          mutate_json_file(fixture.post[target], fn doc ->
            update_in(doc["command_receipts"], fn receipts ->
              Enum.map(receipts, fn receipt ->
                if receipt["type"] == type,
                  do: Map.update!(receipt, "argv", mutate_argv),
                  else: receipt
              end)
            end)
          end)

        assert_failed(
          run_stage("post-target", malformed, fixture.decided_md, fixture.live_post[target], [
            "--target",
            target,
            "--register",
            fixture.register
          ])
        )

        File.rm(malformed)
      end
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

  defp with_fake_gh(fun) do
    dir = Path.join(System.tmp_dir!(), "phase198-fake-gh-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    gh = Path.join(dir, "gh")

    File.write!(gh, """
    #!/bin/sh
    case "${PHASE198_FAKE_CLASSIC_MODE:-unknown}" in
      success) printf '%s\\n' '{}' ; exit 0 ;;
      403|404|429|500|502|503) printf 'HTTP/2 %s fixture\\n' "$PHASE198_FAKE_CLASSIC_MODE" >&2; exit 1 ;;
      transport) printf 'transport failure\\n' >&2; exit 1 ;;
      malformed) printf 'HTTP status unavailable\\n' >&2; exit 1 ;;
      *) printf 'unknown adapter state\\n' >&2; exit 1 ;;
    esac
    """)

    File.chmod!(gh, 0o755)

    try do
      fun.([
        {"PATH", dir <> ":" <> System.fetch_env!("PATH")},
        {"PHASE198_REF_DISPOSITION_LIVE_ATTEMPTS", "1"},
        {"PHASE198_REF_DISPOSITION_LIVE_DEADLINE_SECONDS", "5"}
      ])
    after
      File.rm_rf!(dir)
    end
  end

  defp run_classic_adapter(base_env, mode) do
    System.cmd(@script, ["fixture-classic-adapter", "szTheory/threadline"],
      env: [{"PHASE198_FAKE_CLASSIC_MODE", mode} | base_env],
      stderr_to_stdout: true
    )
  end

  defp run_stage(stage, inventory, decision, live, extra \\ []) do
    System.cmd(
      @script,
      ["fixture-#{stage}", "--inventory", inventory, "--decision", decision] ++ extra,
      env: [{"PHASE198_REF_DISPOSITION_LIVE_FIXTURE", live}],
      stderr_to_stdout: true
    )
  end

  defp run_production_stage(stage, inventory, decision, extra, env) do
    System.cmd(
      @script,
      [stage, "--inventory", inventory, "--decision", decision] ++ extra,
      env: Enum.map(env, fn {key, value} -> {to_string(key), value} end),
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
        "target_universe" => %{
          "local" =>
            Enum.filter(source["target_universe"]["local"], &(&1["branch"] == target["branch"])),
          "remote" =>
            Enum.filter(source["target_universe"]["remote"], &(&1["branch"] == target["branch"]))
        },
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

      live = %{
        "target_universe" => inventory["target_universe"],
        "stable_controls" => inventory["stable_controls"],
        "task_baseline" => inventory["task_baseline"],
        "pull_requests" => %{target["branch"] => target["pull_request"]}
      }

      File.write!(live_path, Jason.encode!(live))
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

  defp with_round11_lifecycle(fun) do
    dir = Path.join(System.tmp_dir!(), "phase198-lifecycle-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    try do
      tracer = Path.join(@root, ".planning/audits/198-round11-ref-disposition.json")
      source = tracer |> File.read!() |> Jason.decode!()
      evidence_template = source["preservation_subjects"] |> hd() |> Map.fetch!("evidence")

      prs = %{
        "ci/198-gap-closure" =>
          pr_fixture(29, "ci/198-gap-closure", "f748e43d7e4c1e63a0142569a55f57c7187e5cb1", false),
        "ci/198-round3" =>
          pr_fixture(30, "ci/198-round3", "80bf701e7486962e538d16f213874cbba8f24115", true),
        "ci/198-round4" =>
          pr_fixture(31, "ci/198-round4", "f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6", true),
        "ci/198-round5" =>
          pr_fixture(32, "ci/198-round5", "14f923a71c0901cd5f95fc3a72e0971b05861543", true),
        "ci/198-round6" =>
          pr_fixture(33, "ci/198-round6", "23c16267d11a63858aad23eab63c9fbfc385ef4b", true)
      }

      subjects =
        for {side, entries} <- [
              {"local", source["target_universe"]["local"]},
              {"origin", source["target_universe"]["remote"]}
            ],
            entry <- entries do
          sha = entry["sha"]
          branch = entry["branch"]

          %{
            "id" => "#{side}:#{branch}@#{sha}",
            "branch" => branch,
            "side" => side,
            "sha" => sha,
            "evidence" =>
              evidence_template
              |> Map.put("sha", sha)
              |> Map.put("merge_base_head", sha)
              |> Map.put("merge_base_main", sha),
            "pull_request" => Map.get(prs, branch),
            "recommendation" => %{
              "action" => "retire",
              "rationale" => "Fixture subject is fully preserved before retirement."
            },
            "archive_tag" => "archive/#{branch}/#{side}-#{String.slice(sha, 0, 12)}",
            "restore_command" => "git branch #{branch} #{sha}"
          }
        end

      base = %{
        source
        | "preservation_subjects" => subjects,
          "decision" => nil,
          "execution" => nil,
          "command_receipts" => []
      }

      inventory = write_json(dir, "inventory.json", base)
      digest = inventory_digest(inventory)
      undecided_md = write_text(dir, "undecided.md", lifecycle_markdown(base, digest, nil))

      decision = decision_payload("retire", digest, subjects)
      decided_doc = %{base | "decision" => decision, "execution" => nil}
      decided = write_json(dir, "decided.json", decided_doc)
      decided_md = write_text(dir, "decided.md", lifecycle_markdown(base, digest, decision))
      targets = subjects |> Enum.map(& &1["branch"]) |> Enum.uniq() |> Enum.sort()
      live_initial_doc = live_fixture(base, prs)
      live_initial = write_json(dir, "live-initial.json", live_initial_doc)

      register =
        write_text(
          dir,
          "register.md",
          Enum.map_join(
            subjects,
            "\n",
            &"<!-- archive-subject: #{&1["id"]}|#{&1["archive_tag"]}|#{&1["sha"]}|#{&1["restore_command"]} -->"
          )
        )

      post =
        Map.new(targets, fn target ->
          receipts =
            receipts_for(Enum.filter(subjects, &(&1["branch"] == target)), Map.get(prs, target))

          doc = %{
            decided_doc
            | "execution" => %{"status" => "retiring", "target" => target},
              "command_receipts" => receipts
          }

          {target, write_json(dir, "post-#{String.replace(target, "/", "-")}.json", doc)}
        end)

      live_post =
        Map.new(targets, fn target ->
          target_subjects = Enum.filter(subjects, &(&1["branch"] == target))
          live = retire_from_live(live_initial_doc, target, target_subjects, Map.get(prs, target))
          {target, write_json(dir, "live-post-#{String.replace(target, "/", "-")}.json", live)}
        end)

      final_receipts =
        targets
        |> Enum.flat_map(fn target ->
          receipts_for(Enum.filter(subjects, &(&1["branch"] == target)), Map.get(prs, target))
        end)
        |> Enum.with_index(1)
        |> Enum.map(fn {receipt, seq} -> Map.put(receipt, "seq", seq) end)

      final_doc = %{
        decided_doc
        | "execution" => %{"status" => "complete"},
          "command_receipts" => final_receipts
      }

      final = write_json(dir, "final.json", final_doc)

      live_final_doc =
        Enum.reduce(targets, live_initial_doc, fn target, live ->
          retire_from_live(
            live,
            target,
            Enum.filter(subjects, &(&1["branch"] == target)),
            Map.get(prs, target)
          )
        end)

      live_final = write_json(dir, "live-final.json", live_final_doc)

      fun.(%{
        dir: dir,
        inventory: inventory,
        undecided_md: undecided_md,
        decided: decided,
        decided_md: decided_md,
        digest: digest,
        subjects: subjects,
        targets: targets,
        live_initial: live_initial,
        post: post,
        live_post: live_post,
        final: final,
        live_final: live_final,
        register: register,
        base: base
      })
    after
      File.rm_rf!(dir)
    end
  end

  defp pr_fixture(number, branch, sha, draft) do
    %{
      "number" => number,
      "state" => "OPEN",
      "is_draft" => draft,
      "merge_state" => "BLOCKED",
      "head" => branch,
      "base" => "main",
      "head_sha" => sha
    }
  end

  defp decision_payload(verbatim, digest, subjects) do
    option = if String.starts_with?(verbatim, "preserve"), do: "preserve", else: verbatim

    %{
      "option" => option,
      "verbatim" => verbatim,
      "recorded_at" => "2026-09-09T22:00:00Z",
      "inventory_sha256" => digest,
      "subjects" =>
        Enum.map(subjects, &Map.take(&1, ["id", "branch", "side", "sha", "archive_tag"]))
    }
  end

  defp lifecycle_markdown(doc, digest, decision) do
    controls = doc["stable_controls"]

    markers =
      Enum.map_join(doc["preservation_subjects"], "\n", fn subject ->
        "<!-- subject: #{subject["id"]}|#{subject["archive_tag"]}|#{subject["restore_command"]} -->"
      end)

    decision_marker =
      if decision do
        "<!-- maintainer-decision-json\n#{Jason.encode!(decision)}\n-->"
      else
        "Status: undecided. No authority is granted."
      end

    """
    # Phase 198 Round 11 ref disposition
    <!-- schema: phase198-ref-disposition/v2; round: 11 -->
    <!-- inventory-sha256: #{digest} -->
    <!-- controls: #{controls["origin_main_sha"]}|34|#{controls["pr34"]["head_sha"]}|#{controls["ruleset_protection_digest"]}|#{controls["required_contexts_digest"]}|#{controls["worktree_list_digest"]} -->
    #{markers}
    Plan 52 is preserved but superseded as inapplicable because Plan 51 recorded verbatim abort and proved the exact-three scope incomplete.
    ## Maintainer decision
    #{decision_marker}
    """
  end

  defp live_fixture(doc, prs) do
    %{
      "target_universe" => doc["target_universe"],
      "stable_controls" => doc["stable_controls"],
      "task_baseline" => doc["task_baseline"],
      "pull_requests" => prs,
      "local_tags" => [],
      "remote_tags" => [],
      "green07_status" => "Pending"
    }
  end

  defp receipts_for(subjects, pr) do
    preservation =
      Enum.flat_map(subjects, fn subject ->
        for type <- ["local-annotated-tag", "remote-single-tag", "archive-register-row"] do
          strict_preservation_receipt(type, subject)
        end
      end)

    target = hd(subjects)["branch"]

    retirement = if pr, do: [strict_pr_receipt(target, pr)], else: []

    retirement =
      if Enum.any?(subjects, &(&1["side"] == "origin")),
        do: retirement ++ [strict_ref_delete_receipt("remote-ref-delete", target, subjects)],
        else: retirement

    retirement =
      if Enum.any?(subjects, &(&1["side"] == "local")),
        do: retirement ++ [strict_ref_delete_receipt("local-ref-delete", target, subjects)],
        else: retirement

    (preservation ++ retirement)
    |> Enum.with_index(1)
    |> Enum.map(fn {receipt, seq} -> Map.put(receipt, "seq", seq) end)
  end

  defp strict_preservation_receipt(type, subject) do
    tag = subject["archive_tag"]
    sha = subject["sha"]

    {argv, before_state, after_state} =
      case type do
        "local-annotated-tag" ->
          {[
             "git",
             "tag",
             "-a",
             tag,
             sha,
             "-m",
             "Archive #{subject["id"]}"
           ], %{"exists" => false},
           %{"exists" => true, "tag" => tag, "sha" => sha, "annotated" => true}}

        "remote-single-tag" ->
          ref = "refs/tags/#{tag}"

          {["git", "push", "origin", "#{ref}:#{ref}"], %{"exists" => false},
           %{"exists" => true, "ref" => ref, "sha" => sha}}

        "archive-register-row" ->
          {["archive-register", "append", subject["id"]], %{"joined" => false},
           %{"joined" => true, "subject_id" => subject["id"], "tag" => tag, "sha" => sha}}
      end

    receipt_base(type, subject["branch"], argv, before_state, after_state)
    |> Map.merge(%{"subject_id" => subject["id"], "tag" => tag, "sha" => sha})
  end

  defp strict_pr_receipt(target, pr) do
    receipt_base(
      "pr-close",
      target,
      ["gh", "pr", "close", Integer.to_string(pr["number"]), "--repo", "szTheory/threadline"],
      %{"number" => pr["number"], "state" => "OPEN"},
      %{"number" => pr["number"], "state" => "CLOSED"}
    )
    |> Map.put("pr", pr["number"])
  end

  defp strict_ref_delete_receipt(type, target, subjects) do
    side = if type == "remote-ref-delete", do: "origin", else: "local"
    sha = subjects |> Enum.find(&(&1["side"] == side)) |> Map.fetch!("sha")
    ref = "refs/heads/#{target}"

    argv =
      if type == "remote-ref-delete",
        do: ["git", "push", "origin", ":#{ref}"],
        else: ["git", "branch", "-d", target]

    receipt_base(type, target, argv, %{"ref" => ref, "sha" => sha}, %{"ref" => ref, "sha" => nil})
  end

  defp receipt_base(type, target, argv, before_state, after_state) do
    %{
      "type" => type,
      "target" => target,
      "argv" => argv,
      "force" => false,
      "started_at" => "2026-09-09T22:40:00Z",
      "completed_at" => "2026-09-09T22:40:01Z",
      "exit_status" => 0,
      "before" => before_state,
      "after" => after_state
    }
  end

  defp retire_from_live(live, target, subjects, pr) do
    local_tags =
      Enum.map(subjects, &%{"tag" => &1["archive_tag"], "sha" => &1["sha"], "annotated" => true})

    remote_tags = Enum.map(subjects, &%{"tag" => &1["archive_tag"], "sha" => &1["sha"]})

    live
    |> update_in(
      ["target_universe", "local"],
      &Enum.reject(&1, fn entry -> entry["branch"] == target end)
    )
    |> update_in(
      ["target_universe", "remote"],
      &Enum.reject(&1, fn entry -> entry["branch"] == target end)
    )
    |> update_in(["local_tags"], &Enum.uniq(&1 ++ local_tags))
    |> update_in(["remote_tags"], &Enum.uniq(&1 ++ remote_tags))
    |> then(fn value ->
      if pr, do: put_in(value, ["pull_requests", target, "state"], "CLOSED"), else: value
    end)
  end

  defp lifecycle_decision_variant(fixture, verbatim) do
    decision = decision_payload(verbatim, fixture.digest, fixture.subjects)
    doc = fixture.decided |> File.read!() |> Jason.decode!() |> Map.put("decision", decision)
    inventory = write_json(fixture.dir, "variant-#{String.replace(verbatim, " ", "-")}.json", doc)

    markdown =
      write_text(
        fixture.dir,
        "variant-#{String.replace(verbatim, " ", "-")}.md",
        lifecycle_markdown(fixture.base, fixture.digest, decision)
      )

    {inventory, markdown}
  end

  defp write_json(dir, name, doc), do: write_text(dir, name, Jason.encode!(doc))

  defp write_text(dir, name, content) do
    path = Path.join(dir, name)
    File.write!(path, content)
    path
  end

  defp mutate_json_file(path, fun) do
    mutated = path <> ".#{System.unique_integer([:positive])}.mutated"

    path
    |> File.read!()
    |> Jason.decode!()
    |> fun.()
    |> then(&File.write!(mutated, Jason.encode!(&1)))

    mutated
  end

  defp assert_failed({_output, status}), do: refute(status == 0)

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
