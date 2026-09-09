defmodule Threadline.E2ePreflightContractTest do
  use ExUnit.Case, async: true

  @script "examples/threadline_phoenix/e2e/run-e2e.sh"

  test "preflight exposes an isolated behavioral contract mode" do
    source = File.read!(@script)

    assert source =~ "THREADLINE_E2E_PREFLIGHT_ONLY",
           "the runner must expose preflight-only execution before setup or Playwright"
  end
end
