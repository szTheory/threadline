defmodule Threadline.PlaywrightFailFastContractTest do
  use ExUnit.Case, async: false
  @script Path.expand("../../bin/verify-playwright-fail-fast", __DIR__)
  @e2e Path.expand("../../examples/threadline_phoenix/e2e", __DIR__)

  @tag :tmp_dir
  test "production CI config is exercised by a clean seven-case behavioral smoke", %{
    tmp_dir: tmp_dir
  } do
    assert File.exists?(@script)
    source = File.read!(@script)
    assert source =~ "base.maxFailures !== 5"
    assert source =~ ~s(base.use?.trace !== "retain-on-failure")
    assert source =~ ~s(packages["node_modules/@playwright/test"].version)
    assert source =~ ~s(--package="@playwright/test@$playwright_version")
    assert source =~ ~s(NODE_PATH="$playwright_node_modules)
    assert source =~ ~s(cp "$E2E/playwright.config.ts" "$TMP/production.config.ts")
    refute source =~ "npx playwright test"
    assert source =~ "i <= 7"
    assert source =~ ~s([ "$failed" -eq 5 ])
    assert source =~ ~s([ "$traces" -ge 5 ])

    # Reproduce the root test jobs: the committed config and lockfile exist but
    # the dedicated browser job has not populated e2e/node_modules.
    clean_e2e = Path.join(tmp_dir, "e2e")
    File.mkdir_p!(clean_e2e)

    File.cp!(
      Path.join(@e2e, "playwright.config.ts"),
      Path.join(clean_e2e, "playwright.config.ts")
    )

    File.cp!(Path.join(@e2e, "package-lock.json"), Path.join(clean_e2e, "package-lock.json"))
    refute File.exists?(Path.join(clean_e2e, "node_modules"))

    assert {output, 0} =
             System.cmd(@script, [],
               env: [{"THREADLINE_PLAYWRIGHT_E2E", clean_e2e}],
               stderr_to_stdout: true
             )

    assert output =~ ~r/failures=5 skipped=[2-7] traces=[5-9]/
  end
end
