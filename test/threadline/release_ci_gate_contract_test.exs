defmodule Threadline.ReleaseCiGateContractTest do
  use ExUnit.Case, async: true

  @release_workflow Path.expand("../../.github/workflows/release.yml", __DIR__)

  test "release gate trusts only the newest authoritative main push run" do
    source = File.read!(@release_workflow)

    assert source =~ "run.event === 'push'"
    assert source =~ "run.head_branch === 'main'"
    assert source =~ "return createdDelta || b.id - a.id;"
    assert source =~ "const authoritativeRun = runs[0];"
    assert source =~ "authoritativeRun.conclusion === 'success'"

    refute source =~ "runs.find((run) => run.conclusion === 'success')",
           "an older successful run must never override a newer failed rerun"

    refute source =~ "runs.some((run) => run.status !== 'completed')",
           "the release gate should wait only for the selected authoritative run"
  end
end
