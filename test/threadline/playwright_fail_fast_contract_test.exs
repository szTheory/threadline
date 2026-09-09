defmodule Threadline.PlaywrightFailFastContractTest do
  use ExUnit.Case, async: false
  @script Path.expand("../../bin/verify-playwright-fail-fast", __DIR__)

  test "production CI config is exercised by a seven-case behavioral smoke" do
    assert File.exists?(@script)
    source = File.read!(@script)
    assert source =~ "base.maxFailures !== 5"
    assert source =~ ~s(base.use?.trace !== "retain-on-failure")
    assert source =~ "i <= 7"
    assert source =~ ~s([ "$failed" -eq 5 ])
    assert source =~ ~s([ "$traces" -ge 5 ])
    assert {output, 0} = System.cmd(@script, [], stderr_to_stdout: true)
    assert output =~ ~r/failures=5 skipped=[2-7] traces=[5-9]/
  end
end
