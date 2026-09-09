defmodule Threadline.Phase198AutomationPolicyTest do
  use ExUnit.Case, async: true
  @script Path.expand("../../bin/verify-phase198-evidence", __DIR__)
  @policy Path.expand("../../.planning/audits/198-automation-policy.json", __DIR__)

  test "policy computes classifications, non-comparable populations, and separate prediction scores" do
    assert {out, 0} = System.cmd(@script, ["--policy", @policy, "--format", "json"])
    doc = Jason.decode!(out)
    assert doc["checks"]["failed"] == 0
    assert doc["lane_classification"] == "code_test"
    assert doc["search_path_classification"] == "test_side"
    assert doc["populations"] == %{"comparable" => false, "state" => "not_comparable"}
    assert doc["prediction"]["target"] == "miss"
    assert doc["prediction"]["exact"] == false
    assert doc["prediction"]["extra"] == ["operator-accessibility"]
  end

  test "empty evidence and timeout overruns fail closed" do
    policy = Jason.decode!(File.read!(@policy))

    for changed <- [
          put_in(policy, ["timeouts"], []),
          put_in(policy, ["timeouts", Access.at(0), "timeout_minutes"], 1)
        ] do
      path = Path.join(System.tmp_dir!(), "policy-#{System.unique_integer([:positive])}.json")
      File.write!(path, Jason.encode!(changed))
      on_exit(fn -> File.rm(path) end)
      assert {_out, status} = System.cmd(@script, ["--policy", path], stderr_to_stdout: true)
      assert status != 0
    end
  end
end
