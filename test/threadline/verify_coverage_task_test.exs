defmodule Threadline.VerifyCoverageTaskTest do
  use ExUnit.Case, async: false

  @repo Threadline.Test.Repo

  defp cmd_env(extra \\ %{}) do
    System.get_env()
    |> Map.merge(Map.new(extra))
    |> Map.to_list()
  end

  test "mix threadline.verify_coverage exits 0 when expected canary table is covered" do
    assert {output, 0} =
             System.cmd(
               "mix",
               ["threadline.verify_coverage"],
               cd: File.cwd!(),
               env: cmd_env(%{"MIX_ENV" => "test"}),
               stderr_to_stdout: true
             )

    assert output =~ "summary:"
    assert output =~ "threadline_ci_coverage_canary"
    assert output =~ "covered"
  end

  test "mix threadline.verify_coverage exits 1 when expected table lacks trigger (SC1)" do
    env =
      cmd_env(%{
        "MIX_ENV" => "test",
        "THREADLINE_VERIFY_COVERAGE_FAILURE_TEST" => "1"
      })

    assert {output, exit_status} =
             System.cmd(
               "mix",
               ["threadline.verify_coverage"],
               cd: File.cwd!(),
               env: env,
               stderr_to_stdout: true
             )

    assert exit_status == 1
    assert output =~ "threadline_verify_cov_uncovered"
    assert output =~ "uncovered"
    assert output =~ "summary:"
  end

  test "SC4: policy violations align with trigger_coverage tuples for expected overlap" do
    coverage = Threadline.Health.trigger_coverage(repo: @repo)
    expected = ["threadline_ci_coverage_canary"]

    tuples_for_expected =
      coverage
      |> Enum.filter(fn {_s, name} -> name in expected end)
      |> MapSet.new()

    policy_input = MapSet.new(coverage)

    assert MapSet.subset?(tuples_for_expected, policy_input)
    assert Threadline.Verify.CoveragePolicy.violations(coverage, expected) == []
  end
end
