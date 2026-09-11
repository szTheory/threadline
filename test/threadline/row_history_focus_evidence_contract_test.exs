defmodule Threadline.RowHistoryFocusEvidenceContractTest do
  use ExUnit.Case, async: true

  @script "bin/verify-row-history-focus-red-control"
  @spec_path "examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts"
  @config "examples/threadline_phoenix/e2e/playwright.config.ts"
  @scenario "keeps row-history drawer dialog semantics and visible focus"
  @flag "THREADLINE_ROW_HISTORY_RED_CONTROL"
  @control "obscure-date-input"

  @tag :red_control_contract
  test "the row-history red control is exact, local, and preserves the protected assertion" do
    source = File.read!(@spec_path)

    assert occurrences(source, @flag) == 1
    assert source =~ "process.env.#{@flag}"
    assert source =~ @control
    assert source =~ "data-threadline-row-history-red-control"
    assert source =~ "await expectNonObscuredFocused(snapshot, page)"
    assert source =~ "await expectNoHorizontalOverflow(page)"
    assert source =~ ~s|toHaveAttribute("aria-modal", "true")|
    assert source =~ ~s|"aria-labelledby"|

    refute source =~
             ~r/expectNonObscuredFocused\([^)]*\)[\s\S]{0,160}(?:force:\s*true|waitForTimeout)/
  end

  @tag :red_control_contract
  test "the prover runs identical bounded RED then GREEN commands and rejects arguments" do
    fixture_dir = fixture_dir!()
    on_exit(fn -> File.rm_rf!(fixture_dir) end)
    argv_log = Path.join(fixture_dir, "argv")
    marker = Path.join(fixture_dir, "started")
    fake_mix = Path.join(fixture_dir, "mix")

    File.write!(
      fake_mix,
      "#!/usr/bin/env bash\n" <>
        "set -euo pipefail\n" <>
        "touch \"$PROVER_STARTED\"\n" <>
        "printf '%s\\0' \"$@\" >> \"$PROVER_ARGV_LOG\"\n" <>
        "if [[ \"${#{@flag}:-}\" == \"#{@control}\" ]]; then\n" <>
        "  echo 'expected non-obscured focus, got {\\\"visible\\\":false}' >&2\n" <>
        "  exit 1\n" <>
        "fi\n"
    )

    File.chmod!(fake_mix, 0o700)

    env = [
      {"THREADLINE_ROW_HISTORY_PROVER_MIX_BIN", fake_mix},
      {"PROVER_ARGV_LOG", argv_log},
      {"PROVER_STARTED", marker}
    ]

    assert {output, 0} = System.cmd("bash", [@script], env: env, stderr_to_stdout: true)
    assert output =~ "RED control failed at expectNonObscuredFocused"
    assert output =~ "clean control passed"

    calls =
      argv_log
      |> File.read!()
      |> :binary.split(<<0>>, [:global, :trim_all])
      |> Enum.chunk_every(5)

    expected = [
      "verify.example_browser",
      "operator-accessibility.spec.ts",
      "--project=mobile-chromium",
      "--grep",
      @scenario
    ]

    assert calls == [expected, expected]

    File.rm!(marker)

    assert {_output, status} =
             System.cmd("bash", [@script, "--update-snapshots"], env: env, stderr_to_stdout: true)

    assert status != 0
    refute File.exists?(marker)
  end

  @tag :red_control_contract
  test "Playwright keeps the existing bounded retry, worker, timeout, trace, and screenshot policy" do
    config = File.read!(@config)

    assert config =~ "timeout: 120_000"
    assert config =~ "expect: { timeout: 15_000 }"
    assert config =~ "retries: process.env.CI ? 1 : 0"
    assert config =~ "workers: 1"
    assert config =~ ~s|trace: "retain-on-failure"|
    assert config =~ ~s|screenshot: "only-on-failure"|

    refute File.read!(@script) =~
             ~r/(?:update-snapshots|updateSnapshots|--retries|--timeout|--workers)/
  end

  test "the scenario attaches synthetic focus and geometry evidence without masking assertions" do
    source = File.read!(@spec_path)
    scenario = source |> String.split(~s|test("#{@scenario}"|, parts: 2) |> List.last()

    scenario =
      scenario |> String.split(~s|test("opens stress rendered widgets|, parts: 2) |> List.first()

    for token <- [
          ~s|testInfo.attach("row-history-focus-geometry"|,
          "project",
          "repeatEachIndex",
          "retry",
          "activeElement",
          "dialogRect",
          "inputRect",
          "viewport",
          "documentScroll",
          "dialogScroll",
          "visible",
          "trace",
          "outputDirectory"
        ] do
      assert scenario =~ token, "missing structured evidence token #{inspect(token)}"
    end

    assert scenario =~ "await expectNonObscuredFocused(snapshot, page)"
    assert scenario =~ "await expectNoHorizontalOverflow(page)"
    assert scenario =~ ~s|toHaveAttribute("aria-modal", "true")|
    assert scenario =~ ~s|"aria-labelledby"|
    refute scenario =~ ~r/(?:waitForTimeout|force:\s*true|test\.slow|test\.setTimeout|retries)/
    assert scenario =~ ~s|toHaveCount(0)|
  end

  defp occurrences(text, needle), do: length(String.split(text, needle)) - 1

  defp fixture_dir! do
    path = Path.join(System.tmp_dir!(), "row-history-focus-#{System.unique_integer([:positive])}")
    File.mkdir_p!(path)
    path
  end
end
