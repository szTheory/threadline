defmodule Threadline.Capture.NoticeGuardCanaryTest do
  use ExUnit.Case, async: false

  @canary "priv/ci/notice_guard_canary.exs"

  defp cmd_env(extra) do
    System.get_env()
    |> Map.merge(Map.new(extra))
    |> Map.to_list()
  end

  defp run_canary(extra_env) do
    System.cmd("mix", ["test", @canary],
      cd: File.cwd!(),
      env: cmd_env(Map.merge(%{"MIX_ENV" => "test"}, extra_env)),
      stderr_to_stdout: true
    )
  end

  test "an undrained truncation notice makes mix test exit non-zero" do
    {output, exit_status} = run_canary(%{"THREADLINE_TRUNCATION_GUARD_CANARY" => "1"})

    assert exit_status != 0, output
    assert output =~ "identifier truncation (SQLSTATE 42622)"
    assert output =~ "42622"
    assert output =~ String.duplicate("c", 64)
  end

  test "the same run without a truncation exits zero" do
    {output, exit_status} = run_canary(%{"THREADLINE_TRUNCATION_GUARD_CANARY" => nil})

    assert exit_status == 0, output
    refute output =~ "identifier truncation"
  end
end
