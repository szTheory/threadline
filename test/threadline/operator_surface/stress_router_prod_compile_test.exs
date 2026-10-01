if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.StressRouterProdCompileTest do
    # Split from stress_router_test.exs: this one check is a cold
    # `MIX_ENV=prod` compile of the project and its deps, the single costliest
    # piece of that module in CI. On its own file it can run in a different
    # test partition from the stress router renders.
    use ExUnit.Case, async: false

    # Cold prod compile on a shared CI runner: the same kind of budget as the
    # other nested-build contract tests (CI run 36799589565 timed it out at
    # ExUnit's default 60s).
    @moduletag timeout: 180_000

    test "real prod Mix.env macro path fails closed without the stress_env hook" do
      {output, status} =
        System.cmd(
          "bash",
          ["-lc", "MIX_ENV=prod mix run --no-start test/support/stress_router_prod_compile.exs"],
          stderr_to_stdout: true
        )

      assert status != 0
      assert output =~ "Threadline stress surface is dev/test-only"
    end
  end
end
