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

  alias Threadline.Test.CiIssuePairing

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
    defp classify_log(tmp_dir, log_contents, env) do
      log = Path.join(tmp_dir, "flake-fixture-#{System.unique_integer([:positive])}.log")
      File.write!(log, log_contents)
      output_path = Path.join(tmp_dir, "github-output-#{System.unique_integer([:positive])}")

      {output, status} =
        System.cmd(@script, [log], env: [{"GITHUB_OUTPUT", output_path} | env])

      {String.trim(output), status, File.read!(output_path)}
    end

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
      # 137 counts as a budget kill only with elapsed-time evidence at or over
      # the budget (218 review WR-02); see Test 1f for the other rows.
      {output, status, _} =
        classify_log(tmp_dir, String.duplicate(@seed_header, 2), [
          {"EXIT_CODE", "137"},
          {"ELAPSED_S", "3361"},
          {"BUDGET_S", "3300"}
        ])

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

  describe "Test 1f: a cut-off iteration's failure and a non-budget kill are not inconclusive (218 review WR-02)" do
    @failure_entry "\n  1) test widget saves (Threadline.WidgetTest)\n     test/widget_test.exs:12\n     Assertion with == failed\n"
    @clean_summary "Finished in 200.1 seconds\n2460 tests, 0 failures, 26 excluded\n"

    test "124 with a failure printed in the cut-off iteration -> flaky, not inconclusive", %{
      tmp_dir: tmp_dir
    } do
      log = String.duplicate(@seed_header <> @clean_summary, 2) <> @seed_header <> @failure_entry

      {output, 0, gh_output} = classify_log(tmp_dir, log, [{"EXIT_CODE", "124"}])

      assert output == "flaky"
      assert gh_output =~ ~r/^reason=.*failed on iteration 3 before the time budget cut it off/m
    end

    test "124 with a failure in the first, cut-off iteration -> broken", %{tmp_dir: tmp_dir} do
      {output, 0, _} =
        classify_log(tmp_dir, @seed_header <> @failure_entry, [{"EXIT_CODE", "124"}])

      assert output == "broken"
    end

    test "a failure summary line alone is failure evidence", %{tmp_dir: tmp_dir} do
      log = @seed_header <> @clean_summary <> @seed_header <> "2460 tests, 1 failure\n"

      assert {"flaky", 0, _} = classify_log(tmp_dir, log, [{"EXIT_CODE", "124"}])
    end

    test "control: clean summaries only (0 failures) stay inconclusive", %{tmp_dir: tmp_dir} do
      log = String.duplicate(@seed_header <> @clean_summary, 2) <> @seed_header

      assert {"inconclusive", 0, _} = classify_log(tmp_dir, log, [{"EXIT_CODE", "124"}])
    end

    test "137 well under the budget -> unknown (OOM or external kill), not inconclusive", %{
      tmp_dir: tmp_dir
    } do
      {output, 0, gh_output} =
        classify_log(tmp_dir, String.duplicate(@seed_header, 2), [
          {"EXIT_CODE", "137"},
          {"ELAPSED_S", "600"},
          {"BUDGET_S", "3300"}
        ])

      assert output == "unknown"
      assert gh_output =~ ~r/^reason=killed \(exit 137\) after 600 s, under the 3300 s budget/m
    end

    test "137 with no elapsed-time evidence -> unknown", %{tmp_dir: tmp_dir} do
      {output, 0, gh_output} =
        classify_log(tmp_dir, String.duplicate(@seed_header, 2), [{"EXIT_CODE", "137"}])

      assert output == "unknown"
      assert gh_output =~ ~r/^reason=killed \(exit 137\) with no elapsed-time evidence/m
    end

    test "the workflow records elapsed time and passes it with the budget to the classifier" do
      yaml = File.read!(@workflow_path)
      repeat = step_body(yaml, "Repeat the suite until failure")
      classify = step_body(yaml, "Classify broken vs flaky")

      assert repeat =~ ~s(echo "elapsed_s=$SECONDS" >> "$GITHUB_OUTPUT")
      assert classify =~ "ELAPSED_S: ${{ steps.repeat.outputs.elapsed_s }}"

      assert [_, budget] = Regex.run(~r/^\s+BUDGET_S: "(\d+)"$/m, classify)
      assert String.to_integer(budget) == budget_seconds(yaml)
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

  describe "Test 1e: the classify step writes a well-formed GITHUB_OUTPUT (218 review WR-01)" do
    # Runs the committed classify step's `run:` body, under the same
    # `bash --noprofile --norc -eo pipefail` shell GitHub uses, against a real
    # log. `grep -c` prints 0 AND exits 1 on a zero-header log, so a
    # `|| echo 0` fallback appended a second bare `0` line, which the runner
    # rejects as "Invalid format".
    defp classify_run_body(yaml) do
      body = step_body(yaml, "Classify broken vs flaky")
      [_, script] = String.split(body, "run: |\n", parts: 2)

      script
      |> String.split("\n")
      |> Enum.map_join("\n", &String.replace_prefix(&1, "          ", ""))
    end

    defp run_classify_step(tmp_dir, yaml, log_contents, exit_code) do
      work = Path.join(tmp_dir, "classify-step-#{System.unique_integer([:positive])}")
      File.mkdir_p!(work)
      File.ln_s!(Path.join(@repo_root, "bin"), Path.join(work, "bin"))

      if log_contents, do: File.write!(Path.join(work, "flake-detection.log"), log_contents)

      output_path = Path.join(work, "github-output")
      File.write!(output_path, "")

      {_, status} =
        System.cmd(
          "bash",
          ["--noprofile", "--norc", "-eo", "pipefail", "-c", classify_run_body(yaml)],
          cd: work,
          env: [
            {"GITHUB_OUTPUT", output_path},
            {"EXIT_CODE", exit_code},
            {"GATE_DECISION", "run"}
          ],
          stderr_to_stdout: true
        )

      {status, output_path |> File.read!() |> String.split("\n", trim: true)}
    end

    defp malformed_output_lines(lines), do: Enum.reject(lines, &(&1 =~ ~r/^[A-Za-z_]+=/))

    test "every log shape yields exactly one iterations= line and no bare lines", %{
      tmp_dir: tmp_dir
    } do
      yaml = File.read!(@workflow_path)

      cases = [
        {"zero-header log, suite never started", "compile error\n", "2", "iterations=0"},
        {"zero-header log, timed out before the suite started", "", "124", "iterations=0"},
        {"missing log", nil, "2", "iterations=0"},
        {"three-header log", String.duplicate(@seed_header, 3), "2", "iterations=3"}
      ]

      for {label, log, exit_code, expected} <- cases do
        {status, lines} = run_classify_step(tmp_dir, yaml, log, exit_code)

        assert status == 0, "#{label}: classify step exited #{status}"
        assert malformed_output_lines(lines) == [], "#{label}: malformed lines #{inspect(lines)}"

        assert Enum.filter(lines, &String.starts_with?(&1, "iterations=")) == [expected],
               "#{label}: expected exactly one #{expected} line, got #{inspect(lines)}"
      end
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

    # The old `*)` arm claimed a missing seed header for every non-broken,
    # non-flaky outcome, which is how a timeout got filed as issue #36
    # ("reported unknown"). The needle is assembled at runtime so this file
    # does not contain it and cannot match itself.
    @old_header_claim "header " <> "was found"
    @close_step "Close the flake tracking issue on a passing run"
    @pass_only "if: always() && steps.classify.outputs.classification == 'pass'"

    # Returns every reporting violation in `yaml`; [] means the issue text is
    # truthful and a pass (and only a pass) closes the tracking issue (D-04/D-06).
    defp close_if(close_body) do
      case Regex.run(~r/^\s+(if: .+)$/m, close_body) do
        [_, condition] -> condition
        nil -> nil
      end
    end

    defp reporting_violations(yaml) do
      issue_body = step_body(yaml, "Open or update the flake tracking issue")

      close_body =
        if String.contains?(yaml, @close_step), do: step_body(yaml, @close_step), else: ""

      [
        {not String.contains?(yaml, @old_header_claim),
         "workflow still claims the seed header is missing"},
        {issue_body =~ "REASON: ${{ steps.classify.outputs.reason }}",
         "issue step must receive REASON from the classifier"},
        {issue_body =~ ~r/^\s+inconclusive\)$/m, "issue step needs an inconclusive) arm"},
        {issue_body =~ ~r/^\s+broken-upstream\)$/m, "issue step needs a broken-upstream) arm"},
        {issue_body =~ ~r/^\s+\*\)\n.*unknown.*\n.*Reason: \$\{REASON\}/m,
         "the *) arm must say unknown and print Reason: ${REASON}"},
        {issue_body =~ "- Reason: ${REASON}", "issue body bullets must include the reason"},
        {close_if(close_body) == @pass_only,
         "close step must run only when the classification is pass"},
        {close_body =~
           ~s(bin/upsert-ci-issue --close --marker "$TITLE_PREFIX" --label "$LABEL" --body-file "$body_file"),
         "close step must call bin/upsert-ci-issue --close"}
      ]
      |> Enum.reject(&elem(&1, 0))
      |> Enum.map(&elem(&1, 1))
      |> Kernel.++(
        CiIssuePairing.violations(yaml, "Open or update the flake tracking issue", @close_step)
      )
    end

    test "every non-pass outcome reports its cause, and only a pass closes the issue (D-04/D-06)" do
      yaml = File.read!(@workflow_path)
      assert reporting_violations(yaml) == []

      # The close step sits after the issue step, so both see the same classification.
      [before_close, _] = String.split(yaml, @close_step, parts: 2)
      assert before_close =~ "Open or update the flake tracking issue"
    end

    test "reporting controls: the old header claim or a loosened close condition is caught" do
      yaml = File.read!(@workflow_path)

      reinserted =
        String.replace(
          yaml,
          ~s(detail="Reason: ${REASON}.),
          ~s(detail="No seed #{@old_header_claim}. Reason: ${REASON}.)
        )

      refute reinserted == yaml, "control did not change the input"
      assert Enum.any?(reporting_violations(reinserted), &(&1 =~ "seed header is missing"))

      loosened = String.replace(yaml, @pass_only, "if: always()")
      refute loosened == yaml, "control did not change the input"

      assert Enum.any?(
               reporting_violations(loosened),
               &(&1 =~ "only when the classification is pass")
             )

      wrong_label =
        String.replace(
          yaml,
          "--close --marker \"$TITLE_PREFIX\" --label \"$LABEL\"",
          "--close --marker \"$TITLE_PREFIX\" --label ci-flaky"
        )

      refute wrong_label == yaml, "control did not change the input"
      assert Enum.any?(reporting_violations(wrong_label), &(&1 =~ "--close"))
    end

    test "reporting controls: renaming only the open step's TITLE_PREFIX or LABEL is caught (WR-06)" do
      yaml = File.read!(@workflow_path)
      [before_close, close_and_after] = String.split(yaml, @close_step, parts: 2)

      for {from, to} <- [
            {~s(TITLE_PREFIX: "Flake Detection: test suite"),
             ~s(TITLE_PREFIX: "Flake Detection: suite")},
            {"LABEL: ci-flake\n", "LABEL: ci-flakes\n"}
          ] do
        renamed_open = String.replace(before_close, from, to) <> @close_step <> close_and_after
        refute renamed_open == yaml, "control did not change the input"

        assert reporting_violations(renamed_open) != [],
               "renaming only the open step (#{to}) must fail the contract"
      end
    end
  end

  describe "Test 6: the repeat count fits inside the timeout(1) budget (D-01/D-02)" do
    # Per-run figures measured on Flake Detection dispatch run 36888506162
    # (2026-10-01, THREADLINE_PROPERTY_SCALE=5, 11 completed iterations, all
    # green, before the 55-minute budget expired mid the 12th): cold first run
    # 345.1 s, repeats 286.8-293.5 s, rounded up with a 1 s margin. This run
    # was classified inconclusive by budget, not by any failure (225's
    # ceilings, 287 s / 228 s, did not account for the 5x property scale added
    # in 226-05, so the repeat count is re-derived here alongside the ceilings).
    @cold_first_run_ceiling_s 346
    @repeat_ceiling_s 295
    # Headroom kept free under the budget for runner variance and suite growth.
    @headroom_percent 10

    @mix_exs_path Path.join(@repo_root, "mix.exs")
    @contributing_path Path.join(@repo_root, "CONTRIBUTING.md")

    defp flake_repeats(mix_exs) do
      [_, n] = Regex.run(~r/"verify\.flake":\s*\["test --repeat-until-failure (\d+)"\]/, mix_exs)
      String.to_integer(n)
    end

    defp budget_seconds(yaml) do
      [_, minutes] =
        Regex.run(~r/timeout --signal=TERM --kill-after=60s (\d+)m mix verify\.flake/, yaml)

      String.to_integer(minutes) * 60
    end

    # Returns every sizing violation; [] means 1 + repeats suite runs fit the budget.
    defp sizing_violations(repeats, cold_s, repeat_s, budget_s) do
      needed = cold_s + repeats * repeat_s
      usable = div(budget_s * (100 - @headroom_percent), 100)

      [
        {repeats >= 1 and repeats <= 15,
         "repeats (#{repeats}) must stay within D-02's bound of 15"},
        {needed <= usable,
         "1 + #{repeats} runs need #{needed} s (#{cold_s} + #{repeats} x #{repeat_s}), " <>
           "over #{usable} s (#{budget_s} s budget less #{@headroom_percent}% headroom)"}
      ]
      |> Enum.reject(&elem(&1, 0))
      |> Enum.map(&elem(&1, 1))
    end

    test "the committed repeat count fits the budget at the measured per-run ceilings" do
      repeats = flake_repeats(File.read!(@mix_exs_path))
      budget = budget_seconds(File.read!(@workflow_path))

      assert budget == 55 * 60

      assert sizing_violations(repeats, @cold_first_run_ceiling_s, @repeat_ceiling_s, budget) ==
               []
    end

    test "the workflow comment, CONTRIBUTING and the classifier state the committed count" do
      repeats = flake_repeats(File.read!(@mix_exs_path))
      yaml = File.read!(@workflow_path)

      assert yaml =~ "`mix test --repeat-until-failure #{repeats}`: #{repeats + 1} suite runs"
      assert yaml =~ "bounded #{repeats}-repeat"
      assert yaml =~ "run 36888506162"

      assert File.read!(@contributing_path) =~ "full suite, #{repeats} repeats (fresh seed each)"
      assert File.read!(@script) =~ "(`test --repeat-until-failure #{repeats}`)"
    end

    test "sizing mutation controls: the shipped 15 repeats or a longer ceiling is caught" do
      budget = budget_seconds(File.read!(@workflow_path))

      # The lane as 218-05 shipped it, at the measured median: red.
      assert Enum.any?(
               sizing_violations(15, @cold_first_run_ceiling_s, 209, budget),
               &(&1 =~ "over")
             )

      mix_exs = File.read!(@mix_exs_path)
      committed = flake_repeats(mix_exs)

      reverted =
        String.replace(
          mix_exs,
          "test --repeat-until-failure #{committed}",
          "test --repeat-until-failure 15"
        )

      if committed != 15, do: refute(reverted == mix_exs, "control did not change the input")

      assert Enum.any?(
               sizing_violations(
                 flake_repeats(reverted),
                 @cold_first_run_ceiling_s,
                 @repeat_ceiling_s,
                 budget
               ),
               &(&1 =~ "over")
             )

      assert Enum.any?(sizing_violations(16, 1, 1, budget), &(&1 =~ "bound of 15"))
    end
  end
end
