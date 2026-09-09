defmodule Threadline.MainCiObserverContractTest do
  use ExUnit.Case, async: true
  @script Path.expand("../../bin/observe-main-ci", __DIR__)
  @sha String.duplicate("a", 40)

  defp run(runs, jobs \\ ~s({"jobs":[]})) do
    root = Path.join(System.tmp_dir!(), "main_ci_#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    gh = Path.join(root, "gh")
    runs_path = Path.join(root, "runs")
    jobs_path = Path.join(root, "jobs")
    File.write!(runs_path, runs)
    File.write!(jobs_path, jobs)

    File.write!(
      gh,
      "#!/usr/bin/env bash\nif [ \"$1 $2\" = \"run list\" ]; then cat \"$RUNS\"; else cat \"$JOBS\"; fi\n"
    )

    File.chmod!(gh, 0o755)
    on_exit(fn -> File.rm_rf!(root) end)

    System.cmd(@script, ["--sha", @sha, "--format", "json"],
      env: [{"GH_BIN", gh}, {"RUNS", runs_path}, {"JOBS", jobs_path}],
      stderr_to_stdout: true
    )
  end

  test "newest exact SHA is selected before status" do
    runs =
      ~s([{"databaseId":1,"headSha":"#{@sha}","status":"completed","conclusion":"success","createdAt":"2026-01-01T00:00:00Z"},{"databaseId":2,"headSha":"#{@sha}","status":"in_progress","conclusion":null,"createdAt":"2026-01-02T00:00:00Z"}])

    assert {out, 0} = run(runs)
    assert %{"selected_id" => 2, "state" => "incomplete"} = Jason.decode!(out)
  end

  test "success requires one successful aggregate and non-empty jobs" do
    runs =
      ~s([{"databaseId":3,"headSha":"#{@sha}","status":"completed","conclusion":"success","createdAt":"2026-01-01T00:00:00Z"}])

    jobs = ~s({"jobs":[{"name":"CI required","conclusion":"success"}]})
    assert {out, 0} = run(runs, jobs)
    assert %{"state" => "success", "ci_required_count" => 1} = Jason.decode!(out)
    assert {out, 0} = run(runs, ~s({"jobs":[]}))
    assert %{"state" => "failure"} = Jason.decode!(out)
  end

  test "absence is explicit and invalid SHA fails" do
    assert {out, 0} = run("[]")
    assert %{"state" => "not_observed"} = Jason.decode!(out)
    assert {_out, status} = System.cmd(@script, ["--sha", "main"], stderr_to_stdout: true)
    assert status != 0
  end
end
