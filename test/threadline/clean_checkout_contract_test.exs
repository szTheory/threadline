defmodule Threadline.CleanCheckoutContractTest do
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)

  @generated_paths [
    {"erl_crash.dump", "/erl_crash.dump"},
    {"threadline-0.10.0.tar", "/threadline-*.tar"},
    {"threadline-0.10.0/lib/threadline.ex", "/threadline-*/"},
    {".dialyzer/threadline.plt", "/.dialyzer/*.plt"},
    {".dialyzer/threadline.plt.hash", "/.dialyzer/*.plt.hash"},
    {"examples/threadline_phoenix/e2e/test-results/results.json",
     "/examples/threadline_phoenix/e2e/test-results/"},
    {"examples/threadline_phoenix/e2e/playwright-report/index.html",
     "/examples/threadline_phoenix/e2e/playwright-report/"},
    {"examples/threadline_phoenix/e2e/blob-report/report.zip",
     "/examples/threadline_phoenix/e2e/blob-report/"},
    {"examples/threadline_phoenix/e2e/artifacts/capture/screenshot.png",
     "/examples/threadline_phoenix/e2e/artifacts/"},
    {"test/fixtures/operator_surface/critic-scores/local-run.json",
     "/test/fixtures/operator_surface/critic-scores/*"}
  ]

  @trackable_paths [
    ".tool-versions",
    "notes/erl_crash.dump",
    "packages/threadline-0.10.0.tar",
    ".dialyzer/nested/threadline.plt",
    "examples/threadline_phoenix/e2e/artifacts-reviewed/screenshot.png",
    "examples/threadline_phoenix/e2e/tests/operator.spec.ts-snapshots/screenshot.png",
    "test/fixtures/operator_surface/critic-scores/.gitkeep",
    "test/fixtures/operator_surface/critic-scores-reviewed/local-run.json",
    "test/fixtures/operator_surface/scorecards/page.timeline.json",
    "test/fixtures/operator_surface/golden/golden-set.json",
    "lib/threadline/critic_scores.ex"
  ]

  test "generated output is ignored by its exact producer-owned rule" do
    for {path, expected_pattern} <- @generated_paths do
      {output, status} =
        System.cmd("git", ["check-ignore", "--no-index", "-v", "--", path],
          cd: @root,
          stderr_to_stdout: true
        )

      assert status == 0, "expected #{path} to be ignored, got: #{output}"

      assert output =~ "#{expected_pattern}\t#{path}",
             "expected #{path} to map to #{expected_pattern}, got: #{output}"
    end
  end

  test "reviewed evidence, source, local config, and prefix-confusion paths remain trackable" do
    for path <- @trackable_paths do
      {_output, status} =
        System.cmd("git", ["check-ignore", "--no-index", "--quiet", "--", path], cd: @root)

      assert status == 1, "expected #{path} to remain trackable"
    end
  end
end
