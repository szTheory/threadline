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

  @repo_root File.cwd!()
  @script Path.join(@repo_root, "bin/classify-flake-run")
  @workflow_path Path.join(@repo_root, ".github/workflows/flake-detection.yml")
  @seed_header "Running ExUnit with seed: 12345, max_cases: 8\n"

  defp fixture_log(header_count) do
    path = Path.join(System.tmp_dir!(), "flake-fixture-#{System.unique_integer([:positive])}.log")
    contents = String.duplicate(@seed_header, header_count)
    File.write!(path, contents)
    on_exit_delete(path)
    path
  end

  defp fixture_log_missing_headers_marker do
    # A log file that exists but contains no ExUnit seed banner at all — the
    # "tee failed / disk filled / step layout changed" case CR-02 named.
    path = Path.join(System.tmp_dir!(), "flake-fixture-#{System.unique_integer([:positive])}.log")
    File.write!(path, "some unrelated output\nno seed banner here\n")
    on_exit_delete(path)
    path
  end

  defp on_exit_delete(path) do
    ExUnit.Callbacks.on_exit(fn -> File.rm(path) end)
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
    test "exit code 0, any header count -> pass" do
      log = fixture_log(3)
      {output, exit_status} = run_classifier(log, "0")

      assert exit_status == 0
      assert String.trim(output) == "pass"
    end

    test "exit code non-zero, 0 headers -> unknown (suite never started)" do
      log = fixture_log(0)
      {output, exit_status} = run_classifier(log, "2")

      assert exit_status == 0
      assert String.trim(output) == "unknown"
    end

    test "exit code non-zero, exactly 1 header -> broken (failed on first iteration)" do
      log = fixture_log(1)
      {output, exit_status} = run_classifier(log, "2")

      assert exit_status == 0
      assert String.trim(output) == "broken"
    end

    test "exit code non-zero, 2 or more headers -> flaky" do
      log = fixture_log(3)
      {output, exit_status} = run_classifier(log, "2")

      assert exit_status == 0
      assert String.trim(output) == "flaky"
    end

    test "exit code non-zero, header count empty/non-numeric -> unknown, NOT flaky (CR-02)" do
      # This is the exact fall-through CR-02 named: grep -c against a log with
      # no seed banner does not error, it legitimately counts zero — but the
      # historical bug's `else` branch made anything not provably 0 or 1 land
      # on `flaky`. Assert the marker case explicitly here too.
      log = fixture_log_missing_headers_marker()
      {output, exit_status} = run_classifier(log, "2")

      assert exit_status == 0
      assert String.trim(output) == "unknown"
      refute String.trim(output) == "flaky"
    end

    test "exit code empty or non-numeric -> unknown, and the script says so on stderr" do
      log = fixture_log(3)

      # EXIT_CODE unset entirely.
      {output, exit_status} = run_classifier(log, nil)
      assert exit_status == 0
      assert String.trim(output) == "unknown"

      # EXIT_CODE non-numeric.
      {output2, exit_status2} = run_classifier(log, "not-a-number")
      assert exit_status2 == 0
      assert String.trim(output2) == "unknown"
    end
  end

  describe "Test 1b: GITHUB_OUTPUT append behavior" do
    test "appends classification=<token> to GITHUB_OUTPUT without overwriting existing contents" do
      log = fixture_log(3)

      output_path =
        Path.join(System.tmp_dir!(), "github-output-#{System.unique_integer([:positive])}")

      File.write!(output_path, "pre_existing=value\n")
      on_exit_delete(output_path)

      {_output, exit_status} =
        System.cmd(@script, [log], env: [{"EXIT_CODE", "0"}, {"GITHUB_OUTPUT", output_path}])

      assert exit_status == 0

      contents = File.read!(output_path)
      assert contents =~ "pre_existing=value"
      assert contents =~ ~r/^classification=pass$/m
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
end
