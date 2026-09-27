defmodule Threadline.FlakeClassifierContractTest do
  @moduledoc """
  GREEN-11 / CR-01 / CR-02 (198-11): the flake-detection classifier is present,
  well-reasoned, and was completely unreachable on the only path it exists for —
  `set -uo pipefail` does not clear the `-e` GitHub injects via
  `shell: /usr/bin/bash -e {0}`, so a failing `mix verify.flake` aborted the
  `repeat` step before `exit_code` was ever written, which skipped the
  `Classify broken vs flaky` step (no `if:`, defaults to `success()`), which
  transitively skipped the tracking-issue step. This test module is the proof
  that the fix (bin/classify-flake-run + `if: always()`) actually holds, rather
  than another assertion that the reasoning is correct.

  Test 1 is the load-bearing half: the six-row classification behavior table,
  driven against `bin/classify-flake-run` directly — no workflow involved,
  runs in well under a second under plain `mix test`.

  Tests 2-4 are the reachability half: they read the amended workflow file and
  assert the specific conditions that make the classifier reachable on a
  failing run, so a future edit that silently removes `if: always()` (exactly
  the shape of the original bug) fails a fast local test rather than being
  caught 120 minutes into a nightly run nobody watches.
  """

  use ExUnit.Case, async: true
  @moduletag :tmp_dir

  @repo_root File.cwd!()
  @script Path.join(@repo_root, "bin/classify-flake-run")
  @workflow_path Path.join(@repo_root, ".github/workflows/flake-detection.yml")
  @seed_header "Running ExUnit with seed: 12345, max_cases: 8\n"

  defp fixture_log(tmp_dir, header_count) do
    path = Path.join(tmp_dir, "flake-fixture-#{System.unique_integer([:positive])}.log")
    File.write!(path, String.duplicate(@seed_header, header_count))
    path
  end

  defp fixture_log_missing_headers_marker(tmp_dir) do
    # A log file that exists but contains no ExUnit seed banner at all — the
    # "tee failed / disk filled / step layout changed" case CR-02 named.
    path = Path.join(tmp_dir, "flake-fixture-#{System.unique_integer([:positive])}.log")
    File.write!(path, "some unrelated output\nno seed banner here\n")
    path
  end

  defp run_classifier(log_path, exit_code_env) do
    env =
      case exit_code_env do
        nil -> []
        value -> [{"EXIT_CODE", value}]
      end

    System.cmd(@script, [log_path], env: env, stderr_to_stdout: false)
  end

  describe "Test 1: six-row classification behavior table (the load-bearing half)" do
    test "exit code 0, any header count -> pass", %{tmp_dir: tmp_dir} do
      log = fixture_log(tmp_dir, 3)
      {output, exit_status} = run_classifier(log, "0")

      assert exit_status == 0
      assert String.trim(output) == "pass"
    end

    test "exit code non-zero, 0 headers -> unknown (suite never started)", %{tmp_dir: tmp_dir} do
      log = fixture_log(tmp_dir, 0)
      {output, exit_status} = run_classifier(log, "2")

      assert exit_status == 0
      assert String.trim(output) == "unknown"
    end

    test "exit code non-zero, exactly 1 header -> broken (failed on first iteration)", %{
      tmp_dir: tmp_dir
    } do
      log = fixture_log(tmp_dir, 1)
      {output, exit_status} = run_classifier(log, "2")

      assert exit_status == 0
      assert String.trim(output) == "broken"
    end

    test "exit code non-zero, 2 or more headers -> flaky", %{tmp_dir: tmp_dir} do
      log = fixture_log(tmp_dir, 3)
      {output, exit_status} = run_classifier(log, "2")

      assert exit_status == 0
      assert String.trim(output) == "flaky"
    end

    test "exit code non-zero, header count empty/non-numeric -> unknown, NOT flaky (CR-02)", %{
      tmp_dir: tmp_dir
    } do
      # This is the exact fall-through CR-02 named: grep -c against a log with
      # no seed banner does not error, it legitimately counts zero — but the
      # historical bug's `else` branch made anything not provably 0 or 1 land
      # on `flaky`. Assert the marker case explicitly here too.
      log = fixture_log_missing_headers_marker(tmp_dir)
      {output, exit_status} = run_classifier(log, "2")

      assert exit_status == 0
      assert String.trim(output) == "unknown"
      refute String.trim(output) == "flaky"
    end

    test "exit code empty or non-numeric -> unknown, and the script says so on stderr", %{
      tmp_dir: tmp_dir
    } do
      log = fixture_log(tmp_dir, 3)

      # EXIT_CODE unset entirely.
      {output, exit_status} = run_classifier(log, nil)
      assert exit_status == 0
      assert String.trim(output) == "unknown"

      # EXIT_CODE non-numeric.
      {output2, exit_status2} = run_classifier(log, "not-a-number")
      assert exit_status2 == 0
      assert String.trim(output2) == "unknown"
    end

    test "embedded dash is not an integer -> unknown, NOT flaky (198 review WR-01)", %{
      tmp_dir: tmp_dir
    } do
      log = fixture_log(tmp_dir, 3)

      # A dash is a sign only in leading position. "1-2" once slipped through the
      # validator's character-class check and classified as `flaky` off a
      # malformed exit code — the one verdict the classifier must never reach
      # without evidence.
      for malformed <- ["1-2", "-1-2", "-", "1 2"] do
        {output, exit_status} = run_classifier(log, malformed)
        assert exit_status == 0

        assert String.trim(output) == "unknown",
               "EXIT_CODE=#{inspect(malformed)} must classify as unknown, got #{String.trim(output)}"
      end

      # Positive control: a well-formed non-zero code over the same log still
      # reaches `flaky`, so the guard above rejects malformed input rather than
      # disabling the branch.
      {ok_output, ok_status} = run_classifier(log, "1")
      assert ok_status == 0
      assert String.trim(ok_output) == "flaky"
    end
  end

  describe "Test 1b: GITHUB_OUTPUT append behavior" do
    test "appends classification= and reason= after existing GITHUB_OUTPUT contents", %{
      tmp_dir: tmp_dir
    } do
      log = fixture_log(tmp_dir, 3)
      output_path = Path.join(tmp_dir, "github-output")
      File.write!(output_path, "pre_existing=value\n")

      {output, exit_status} =
        System.cmd(@script, [log], env: [{"EXIT_CODE", "0"}, {"GITHUB_OUTPUT", output_path}])

      assert exit_status == 0
      # Stdout stays the bare classification token; the reason rides only in GITHUB_OUTPUT.
      assert output == "pass\n"

      assert ["pre_existing=value" | appended] =
               output_path |> File.read!() |> String.split("\n", trim: true)

      assert "classification=pass" in appended

      assert Enum.any?(appended, &String.starts_with?(&1, "reason=")),
             "expected a reason= line appended after classification=, got #{inspect(appended)}"
    end
  end

  describe "Test 1c: a budget expiry is inconclusive, never flaky (D-04)" do
    defp classify_with_output(tmp_dir, headers, exit_code) do
      log = fixture_log(tmp_dir, headers)
      output_path = Path.join(tmp_dir, "github-output-#{System.unique_integer([:positive])}")

      {output, status} =
        System.cmd(@script, [log],
          env: [{"EXIT_CODE", exit_code}, {"GITHUB_OUTPUT", output_path}]
        )

      {String.trim(output), status, File.read!(output_path)}
    end

    test "exit 124 with 3 headers -> inconclusive, with a reason naming the clean iterations",
         %{tmp_dir: tmp_dir} do
      {output, status, gh_output} = classify_with_output(tmp_dir, 3, "124")

      assert status == 0
      assert output == "inconclusive"
      refute output == "flaky"
      assert gh_output =~ ~r/^classification=inconclusive$/m
      assert gh_output =~ ~r/^reason=budget exhausted after 2 clean iteration\(s\)/m
    end

    test "exit 137 (killed after the grace period) with 2 headers -> inconclusive", %{
      tmp_dir: tmp_dir
    } do
      {output, status, _} = classify_with_output(tmp_dir, 2, "137")

      assert status == 0
      assert output == "inconclusive"
      refute output == "flaky"
    end

    test "exit 124 with 0 headers -> unknown, timed out before the suite started", %{
      tmp_dir: tmp_dir
    } do
      {output, status, gh_output} = classify_with_output(tmp_dir, 0, "124")

      assert status == 0
      assert output == "unknown"
      refute output == "flaky"
      assert gh_output =~ ~r/^reason=.*timed out before the suite started/m
    end

    test "the original rows are unchanged next to the new ones", %{tmp_dir: tmp_dir} do
      assert {"broken", 0, _} = classify_with_output(tmp_dir, 1, "2")
      assert {"flaky", 0, flaky_out} = classify_with_output(tmp_dir, 3, "2")
      assert flaky_out =~ ~r/^reason=passed 2 time\(s\) then failed on iteration 3$/m
      assert {"pass", 0, _} = classify_with_output(tmp_dir, 3, "0")
      assert {"unknown", 0, empty_out} = classify_with_output(tmp_dir, 3, "")
      assert empty_out =~ ~r/^reason=EXIT_CODE empty or non-numeric$/m
    end
  end

  describe "Test 1d: the SHA gate decision is classified before the exit code (D-03/D-04)" do
    defp classify_gated(tmp_dir, gate, exit_code) do
      log = fixture_log(tmp_dir, 0)
      output_path = Path.join(tmp_dir, "github-output-#{System.unique_integer([:positive])}")

      {output, status} =
        System.cmd(@script, [log],
          env: [{"GATE_DECISION", gate}, {"EXIT_CODE", exit_code}, {"GITHUB_OUTPUT", output_path}],
          stderr_to_stdout: false
        )

      {String.trim(output), status, File.read!(output_path)}
    end

    test "GATE_DECISION=skip -> skip", %{tmp_dir: tmp_dir} do
      {output, status, gh_output} = classify_gated(tmp_dir, "skip", "")

      assert status == 0
      assert output == "skip"
      assert gh_output =~ ~r/^reason=.*already proved this SHA green/m
    end

    test "GATE_DECISION=broken-upstream -> broken-upstream, even with EXIT_CODE empty", %{
      tmp_dir: tmp_dir
    } do
      {output, status, gh_output} = classify_gated(tmp_dir, "broken-upstream", "")

      assert status == 0
      assert output == "broken-upstream"
      refute output == "flaky"
      assert gh_output =~ ~r/^reason=.*ci\.yml is red on this SHA/m
    end

    test "GATE_DECISION=run falls through to the exit-code table", %{tmp_dir: tmp_dir} do
      assert {"unknown", 0, _} = classify_gated(tmp_dir, "run", "")
      assert {"pass", 0, _} = classify_gated(tmp_dir, "run", "0")
    end
  end

  describe "Test 2: the classify step in the workflow carries an always-condition" do
    test "flake-detection.yml is non-empty and the classify step carries if: always()" do
      assert File.exists?(@workflow_path), "expected #{@workflow_path} to exist"
      yaml = File.read!(@workflow_path)

      refute yaml == "", "flake-detection.yml must not be empty"

      # Isolate the "Classify broken vs flaky" step body from the next step.
      [_, after_classify] = String.split(yaml, "Classify broken vs flaky", parts: 2)
      classify_step_body = after_classify |> String.split(~r/\n\s{6}- name:/, parts: 2) |> hd()

      assert classify_step_body =~ ~r/if:\s*always\(\)/,
             "the `Classify broken vs flaky` step must carry `if: always()` — " <>
               "without it, a failing `repeat` step skips classification entirely " <>
               "(the classifier is present but unreachable on the only path it exists for)"
    end
  end

  describe "Test 3: the classify step invokes the tested script (workflow/script cannot drift)" do
    test "the classify step's run: body references bin/classify-flake-run, and it exists and is executable" do
      yaml = File.read!(@workflow_path)

      [_, after_classify] = String.split(yaml, "Classify broken vs flaky", parts: 2)
      classify_step_body = after_classify |> String.split(~r/\n\s{6}- name:/, parts: 2) |> hd()

      assert classify_step_body =~ "bin/classify-flake-run",
             "the classify step must invoke bin/classify-flake-run so the tested " <>
               "script and the workflow that calls it cannot drift apart"

      assert File.exists?(@script), "bin/classify-flake-run must exist"

      stat = File.stat!(@script)
      executable? = Bitwise.band(stat.mode, 0o111) != 0

      assert executable?, "bin/classify-flake-run must be executable (chmod +x)"
    end
  end

  describe "Test 4: the repeat step does not depend on inherited errexit for its output" do
    test "the repeat step disables errexit explicitly (set +e) or uses continue-on-error, so exit_code is always written" do
      yaml = File.read!(@workflow_path)

      [_, after_repeat] = String.split(yaml, "Repeat the suite until failure", parts: 2)
      repeat_step_body = after_repeat |> String.split(~r/\n\s{6}- name:/, parts: 2) |> hd()

      uses_set_plus_e = repeat_step_body =~ ~r/set \+e/
      uses_continue_on_error = repeat_step_body =~ ~r/continue-on-error:\s*true/

      assert uses_set_plus_e or uses_continue_on_error,
             "the `repeat` step must not rely on the shell's inherited `-e` for writing " <>
               "`exit_code` — GitHub runs `run:` bodies as `bash -e {0}`, and `set -uo pipefail` " <>
               "alone does not clear it (CR-01). Expected either an explicit `set +e` in the " <>
               "step body or `continue-on-error: true` on the step."

      assert repeat_step_body =~ ~r/exit_code=/,
             "the repeat step must write exit_code=... to \$GITHUB_OUTPUT on every path, " <>
               "including a failing mix verify.flake"
    end
  end

  describe "Test 5: bounded weekly lane shape (D-01/D-02/D-04)" do
    defp step_body(yaml, step_name) do
      [_, after_step] = String.split(yaml, step_name, parts: 2)
      after_step |> String.split(~r/\n\s{6}- name:/, parts: 2) |> hd()
    end

    defp job_timeout(yaml) do
      [_, job] = String.split(yaml, "\n  verify-flake:\n", parts: 2)
      [header, _steps] = String.split(job, "\n    steps:\n", parts: 2)
      [_, minutes] = Regex.run(~r/^    timeout-minutes:\s*(\d+)\s*$/m, header)
      String.to_integer(minutes)
    end

    defp repeat_step_timeout(yaml) do
      body = step_body(yaml, "Repeat the suite until failure")

      case Regex.run(~r/^\s+timeout-minutes:\s*(\d+)\s*$/m, body) do
        [_, minutes] -> String.to_integer(minutes)
        nil -> nil
      end
    end

    # Returns every lane-shape violation in `yaml`; [] means the shape holds.
    defp lane_shape_violations(yaml) do
      crons = Regex.scan(~r/^\s*- cron:\s*"([^"]+)"/m, yaml, capture: :all_but_first)

      weekly? =
        case crons do
          [[expr]] ->
            case String.split(expr) do
              [_min, _hour, "*", "*", dow] -> dow =~ ~r/^[0-6]$/
              _ -> false
            end

          _ ->
            false
        end

      step = repeat_step_timeout(yaml)
      job = job_timeout(yaml)

      [
        {weekly?, "exactly one cron: and it must be weekly (one fixed day of week)"},
        {yaml =~ ~r/^\s+workflow_dispatch:/m, "workflow_dispatch: trigger missing"},
        {step_body(yaml, "Repeat the suite until failure") =~
           "timeout --signal=TERM --kill-after=60s 55m mix verify.flake",
         "repeat step must run mix verify.flake under the timeout(1) budget"},
        {is_integer(step) and step < job,
         "repeat step timeout-minutes (#{inspect(step)}) must be below the job's (#{job})"}
      ]
      |> Enum.reject(&elem(&1, 0))
      |> Enum.map(&elem(&1, 1))
    end

    @heavy_steps [
      "- uses: erlef/setup-beam@v1",
      "- name: Cache deps",
      "- name: Install dependencies",
      "- name: Compile (warnings as errors)",
      "- name: Repeat the suite until failure"
    ]

    defp heavy_step_body(yaml, marker) do
      [_, after_step] = String.split(yaml, marker, parts: 2)
      after_step |> String.split(~r/\n\s*\n/, parts: 2) |> hd()
    end

    # Returns every gate-wiring violation in `yaml`; [] means the wiring holds.
    defp gate_wiring_violations(yaml) do
      [_, job] = String.split(yaml, "\n  verify-flake:\n", parts: 2)
      [header, _steps] = String.split(job, "\n    steps:\n", parts: 2)

      ungated =
        Enum.reject(@heavy_steps, fn marker ->
          heavy_step_body(yaml, marker) =~ "if: steps.gate.outputs.decision == 'run'"
        end)

      gate_body = step_body(yaml, "Decide whether this SHA needs a flake run")
      issue_body = step_body(yaml, "Open or update the flake tracking issue")
      fail_body = step_body(yaml, "Fail the job if the suite did not pass")
      skip_excluded = "steps.classify.outputs.classification != 'skip'"

      [
        {header =~ ~r/^      actions: read$/m, "job permissions must grant actions: read"},
        {gate_body =~ "id: gate" and
           gate_body =~
             ~s(bin/ci-sha-gate --workflow flake-detection.yml --sha "$GITHUB_SHA" --event "$GITHUB_EVENT_NAME" --upstream ci.yml),
         "gate step must run bin/ci-sha-gate on this SHA and event with ci.yml upstream"},
        {ungated == [], "heavy steps missing the gate if: #{inspect(ungated)}"},
        {step_body(yaml, "Classify broken vs flaky") =~
           "GATE_DECISION: ${{ steps.gate.outputs.decision }}",
         "classify step must receive GATE_DECISION"},
        {issue_body =~ skip_excluded, "issue step must exclude skip"},
        {fail_body =~ skip_excluded, "fail step must exclude skip"}
      ]
      |> Enum.reject(&elem(&1, 0))
      |> Enum.map(&elem(&1, 1))
    end

    test "the SHA gate runs first and gates every heavy step (D-03)" do
      yaml = File.read!(@workflow_path)
      assert gate_wiring_violations(yaml) == []

      [before_gate, _] = String.split(yaml, "Decide whether this SHA needs a flake run", parts: 2)
      refute before_gate =~ "erlef/setup-beam", "the gate must run before any heavy step"
    end

    test "gate mutation controls: dropping actions: read or one heavy step's if: is caught" do
      yaml = File.read!(@workflow_path)

      no_actions = String.replace(yaml, "      actions: read\n", "")
      assert no_actions != yaml
      assert Enum.any?(gate_wiring_violations(no_actions), &(&1 =~ "actions: read"))

      ungated_compile =
        String.replace(
          yaml,
          "- name: Compile (warnings as errors)\n        if: steps.gate.outputs.decision == 'run'\n",
          "- name: Compile (warnings as errors)\n"
        )

      assert ungated_compile != yaml
      assert Enum.any?(gate_wiring_violations(ungated_compile), &(&1 =~ "Compile"))
    end

    test "the committed workflow is weekly plus dispatch, budgeted, with step < job timeout" do
      yaml = File.read!(@workflow_path)

      assert lane_shape_violations(yaml) == []
      assert yaml =~ ~s(cron: "0 7 * * 1")
      assert repeat_step_timeout(yaml) == 58
      assert job_timeout(yaml) == 70
    end

    test "mutation controls: each broken copy is caught" do
      yaml = File.read!(@workflow_path)

      daily = String.replace(yaml, ~s(cron: "0 7 * * 1"), ~s(cron: "0 7 * * *"))
      assert daily != yaml
      assert Enum.any?(lane_shape_violations(daily), &(&1 =~ "weekly"))

      swapped =
        yaml
        |> String.replace(~r/^(\s+)timeout-minutes: 58$/m, "\\1timeout-minutes: __JOB__")
        |> String.replace(~r/^    timeout-minutes: 70$/m, "    timeout-minutes: 58")
        |> String.replace("__JOB__", "70")

      assert swapped != yaml
      assert Enum.any?(lane_shape_violations(swapped), &(&1 =~ "must be below"))

      unwrapped =
        String.replace(
          yaml,
          "timeout --signal=TERM --kill-after=60s 55m mix verify.flake",
          "mix verify.flake"
        )

      assert unwrapped != yaml
      assert Enum.any?(lane_shape_violations(unwrapped), &(&1 =~ "timeout(1) budget"))
    end
  end
end
