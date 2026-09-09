defmodule Threadline.Phase198NyquistContractTest do
  @moduledoc """
  Durable offline contracts for Phase 198 evidence that previously had only
  plan-local shell checks. These tests deliberately fail if the evidence is
  missing, vacuous, internally inconsistent, or if the CI/archive invariants
  regress.
  """

  use ExUnit.Case, async: true

  @root File.cwd!()
  @planning Path.join(@root, ".planning")

  defp read!(relative), do: @root |> Path.join(relative) |> File.read!()

  test "GREEN-01 preserves a non-vacuous historical CI failure record with its staleness caveat" do
    path = Path.join(@planning, "audits/198-ci-run-28214113903-logs.md")
    body = File.read!(path)

    assert body =~ "28214113903"
    assert body =~ ~r/predates.*ci\.yml/is
    assert body =~ ~r/\|\s*Job(?: name)?\s*\|\s*Conclusion\s*\|/i

    assert body =~ "```" or body =~ "## Status: LOGS UNAVAILABLE",
           "the preserved run must contain either captured logs or an explicit loss record"
  end

  test "GREEN-02 full-default Credo evidence is non-empty and reconciles to its report" do
    json_path = Path.join(@planning, "audits/198-credo-full-default.json")
    report = read!(".planning/audits/198-credo-histogram.md")
    issues = json_path |> File.read!() |> Jason.decode!() |> Map.fetch!("issues")

    assert issues != [],
           "the full-default run must contain findings or the measurement is vacuous"

    assert report =~ "Per-check"
    assert report =~ "Per-file"
    assert report =~ "/tmp/198-full-default.credo.exs"

    [_, baseline] =
      Regex.run(~r/Baseline issue count \(`baseline_count`\) \| \*\*(\d+)\*\*/, report)

    [_, full] = Regex.run(~r/Full-default issue count \| \*\*(\d+)\*\*/, report)

    assert String.to_integer(full) == length(issues)
    assert String.to_integer(full) > String.to_integer(baseline)
  end

  test "GREEN-03 mechanical probe demonstrates both insensitive variants and a failing control" do
    report = read!(".planning/audits/198-mechanical-sensitivity.md")

    for row <- ["control", "text-content", "text-width", "token", "empty directory"] do
      assert report =~ row, "mechanical probe is missing the #{row} result"
    end

    assert report =~ ~r/text-content[\s\S]*?\{:ok, \[\]\}/
    assert report =~ ~r/text-width[\s\S]*?\{:ok, \[\]\}/

    assert report =~ ~r/token[\s\S]*?\{:error, /,
           "the positive control must fail or the probe has no demonstrated teeth"

    assert report =~ "## Finding"
    assert report =~ "lib/threadline/operator_surface/mechanical_checker.ex"
    assert report =~ ~r/`:\d+(?:-\d+)?`/
  end

  test "GREEN-06 every workflow job is bounded and browser runs fail fast" do
    for relative <- [
          ".github/workflows/ci.yml",
          ".github/workflows/release.yml",
          ".github/workflows/browser-full.yml"
        ] do
      yaml = read!(relative)
      [_, jobs_block] = String.split(yaml, "\njobs:\n", parts: 2)
      jobs = Regex.scan(~r/^  [a-z][a-z0-9-]+:\s*$/m, jobs_block) |> length()
      timeouts = Regex.scan(~r/^    timeout-minutes:\s*\d+\s*$/m, jobs_block) |> length()

      assert jobs > 0, "#{relative} contains no derived jobs"

      assert timeouts == jobs,
             "#{relative} has #{jobs} jobs but #{timeouts} timeout-minutes bounds"
    end

    playwright = read!("examples/threadline_phoenix/e2e/playwright.config.ts")
    assert playwright =~ ~r/maxFailures:\s*process\.env\.CI\s*\?\s*[1-9]\d*\s*:\s*0/
  end

  test "GREEN-12 every archive-register row resolves to an annotated local tag" do
    register = read!(".planning/ARCHIVE-REGISTER.md")

    refs =
      Regex.scan(~r/^\| `([^`]+)` \| `([0-9a-f]{40})` \|/m, register, capture: :all_but_first)

    assert refs != [], "archive register has no rows"

    for {ref, sha} <- Enum.map(refs, &List.to_tuple/1) do
      tag = "archive/#{ref}"
      assert_archive_tag!(tag, sha)
    end
  end

  test "GREEN-12 archive diagnostics identify missing and lightweight refs" do
    assert_raise ExUnit.AssertionError, ~r/archive\/missing-contract-fixture.*missing tag object/s, fn ->
      assert_archive_tag!("archive/missing-contract-fixture", String.duplicate("0", 40))
    end

    {head, 0} = System.cmd("git", ["rev-parse", "HEAD"], stderr_to_stdout: true)

    assert_raise ExUnit.AssertionError, ~r/HEAD.*annotated tag/s, fn ->
      assert_archive_tag!("HEAD", String.trim(head))
    end
  end

  test "Phase 198 evidence judgments are evaluated by the committed policy" do
    script = Path.join(@root, "bin/verify-phase198-evidence")
    policy = Path.join(@planning, "audits/198-automation-policy.json")
    {output, status} = System.cmd(script, ["--policy", policy, "--format", "json"])
    assert status == 0
    assert Jason.decode!(output)["checks"]["failed"] == 0
  end

  defp assert_archive_tag!(tag, expected_sha) do
    case System.cmd("git", ["rev-parse", "--verify", "#{tag}^{}"], stderr_to_stdout: true) do
      {object, 0} ->
        assert String.trim(object) == expected_sha,
               "#{tag} resolves to #{String.trim(object)}, expected #{expected_sha}"

      {output, _status} ->
        flunk("#{tag}: missing tag object (#{String.trim(output)})")
    end

    case System.cmd("git", ["cat-file", "-t", tag], stderr_to_stdout: true) do
      {"tag\n", 0} -> :ok
      {type, 0} -> flunk("#{tag}: expected annotated tag, got #{String.trim(type)}")
      {output, _status} -> flunk("#{tag}: missing tag object (#{String.trim(output)})")
    end
  end
end
