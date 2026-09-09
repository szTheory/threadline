defmodule Threadline.Phase198AutomationPolicyTest do
  use ExUnit.Case, async: true

  @script Path.expand("../../bin/verify-phase198-evidence", __DIR__)
  @policy Path.expand("../../.planning/audits/198-automation-policy.json", __DIR__)

  defp run_policy(policy) do
    path = Path.join(System.tmp_dir!(), "policy-#{System.unique_integer([:positive])}.json")
    File.write!(path, Jason.encode!(policy))
    on_exit(fn -> File.rm(path) end)
    System.cmd(@script, ["--policy", path, "--format", "json"], stderr_to_stdout: true)
  end

  defp reject(policy) do
    assert {_out, status} = run_policy(policy)
    assert status != 0
  end

  test "policy computes stable complete prediction sets and abstains across populations" do
    assert {out, 0} = System.cmd(@script, ["--policy", @policy, "--format", "json"])
    doc = Jason.decode!(out)

    assert doc["checks"] == %{"failed" => 0}
    assert doc["lane_classification"] == "code_test"
    assert doc["search_path_classification"] == "test_side"
    assert doc["populations"] == %{"comparable" => false, "state" => "not_comparable"}

    assert doc["prediction"] == %{
             "composition" => "partial",
             "extra" => ["operator-accessibility"],
             "intersection" => ["verify-capture", "verify-example-browser"],
             "missing" => [],
             "observed" => [
               "operator-accessibility",
               "verify-capture",
               "verify-example-browser"
             ],
             "predicted" => ["verify-capture", "verify-example-browser"],
             "target" => "miss"
           }
  end

  test "exact recursive schemas reject unknown, missing, wrongly typed, and empty evidence" do
    policy = Jason.decode!(File.read!(@policy))

    reject(Map.put(policy, "surprise", true))
    reject(pop_in(policy, ["mechanical", "id"]) |> elem(1))
    reject(put_in(policy, ["prediction", "target_max_red"], "1"))
    reject(put_in(policy, ["evidence"], []))
    reject(update_in(policy, ["evidence", Access.at(0)], &Map.put(&1, "unknown", 1)))
    reject(put_in(policy, ["evidence", Access.at(0), "contains"], []))
  end

  test "duplicate IDs and dangling or dishonest evidence joins fail closed" do
    policy = Jason.decode!(File.read!(@policy))
    first_evidence_id = get_in(policy, ["evidence", Access.at(0), "id"])

    reject(put_in(policy, ["evidence", Access.at(1), "id"], first_evidence_id))

    reject(
      put_in(policy, ["timeouts", Access.at(1), "id"], get_in(policy, ["timeouts", Access.at(0), "id"]))
    )

    reject(put_in(policy, ["measurements", Access.at(1), "id"], "round4-ci"))
    reject(put_in(policy, ["prediction", "evidence_id"], "missing-source"))
    reject(put_in(policy, ["mechanical", "evidence_id"], "missing-source"))
    reject(put_in(policy, ["evidence", Access.at(0), "path"], "README.missing"))
    reject(put_in(policy, ["evidence", Access.at(0), "subject"], "not in the evidence"))
  end

  test "timeout equality passes while overruns and malformed quantities fail" do
    policy = Jason.decode!(File.read!(@policy))

    boundary =
      put_in(
        policy,
        ["timeouts", Access.at(0), "observed_seconds"],
        get_in(policy, ["timeouts", Access.at(0), "timeout_minutes"]) * 60
      )

    assert {_out, 0} = run_policy(boundary)
    reject(update_in(boundary, ["timeouts", Access.at(0), "observed_seconds"], &(&1 + 1)))

    for value <- [-1, 1.5, "NaN", nil] do
      reject(put_in(policy, ["timeouts", Access.at(0), "observed_seconds"], value))
    end

    reject(put_in(policy, ["timeouts", Access.at(0), "timeout_minutes"], 0))
    reject(put_in(policy, ["search_path", "fresh_db_failures"], -1))
    reject(put_in(policy, ["measurements", Access.at(0), "cap"], -1))
  end

  test "prediction duplicates fail and equal populations compute comparison" do
    policy = Jason.decode!(File.read!(@policy))
    reject(update_in(policy, ["prediction", "predicted"], &(&1 ++ [hd(&1)])))
    reject(update_in(policy, ["prediction", "observed"], &(&1 ++ [hd(&1)])))

    comparable =
      policy
      |> put_in(
        ["measurements", Access.at(1), "population_id"],
        get_in(policy, ["measurements", Access.at(0), "population_id"])
      )
      |> put_in(["measurements", Access.at(1), "cap"], 5)

    assert {out, 0} = run_policy(comparable)
    assert Jason.decode!(out)["populations"] == %{"comparable" => true, "state" => "equal"}
  end

  test "every load-bearing classification field is falsifiable" do
    policy = Jason.decode!(File.read!(@policy))

    mutations = [
      put_in(policy, ["mechanical", "text_content_same"], false),
      put_in(policy, ["mechanical", "text_width_same"], false),
      put_in(policy, ["mechanical", "layout_protected"], true),
      put_in(policy, ["lane_differential", "classification"], "narrative"),
      put_in(policy, ["lane_differential", "current", "tests"], 1),
      put_in(policy, ["search_path", "classification"], "narrative"),
      put_in(policy, ["search_path", "unprefixed_defects"], 1),
      put_in(policy, ["prediction", "target_max_red"], -1)
    ]

    Enum.each(mutations, &reject/1)
  end
end
