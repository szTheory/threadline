defmodule Threadline.MainCiObserverContractTest do
  use ExUnit.Case, async: true
  @script Path.expand("../../bin/observe-main-ci", __DIR__)
  @sha String.duplicate("a", 40)

  defp run(runs, jobs \\ ~s({"jobs":[]}), opts \\ []) do
    root = Path.join(System.tmp_dir!(), "main_ci_#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    gh = Path.join(root, "gh")
    runs_path = Path.join(root, "runs")
    jobs_path = Path.join(root, "jobs")
    argv_path = Path.join(root, "argv")
    File.write!(runs_path, runs)
    File.write!(jobs_path, jobs)
    File.write!(argv_path, "")

    File.write!(
      gh,
      """
      #!/usr/bin/env bash
      set -euo pipefail
      printf 'CALL\\0' >> "$ARGV_LOG"
      printf '%s\\0' "$@" >> "$ARGV_LOG"

      if [ "$#" -eq 12 ] && [ "$1" = run ] && [ "$2" = list ] &&
         [ "$3" = --workflow ] && [ "$4" = .github/workflows/ci.yml ] &&
         [ "$5" = --branch ] && [ "$6" = main ] && [ "$7" = --event ] &&
         [ "$8" = push ] && [ "$9" = --limit ] && [ "${10}" = 100 ] &&
         [ "${11}" = --json ] &&
         [ "${12}" = databaseId,headSha,status,conclusion,createdAt ]; then
        [ "${FAIL_OPERATION:-}" != list ] || exit 19
        cat "$RUNS"
      elif [ "$#" -eq 5 ] && [ "$1" = run ] && [ "$2" = view ] &&
           [[ "$3" =~ ^[0-9]+$ ]] && [ "$4" = --json ] && [ "$5" = jobs ]; then
        [ "${FAIL_OPERATION:-}" != view ] || exit 23
        cat "$JOBS"
      else
        echo "fake-gh: rejected argv" >&2
        exit 97
      fi
      """
    )

    File.chmod!(gh, 0o755)
    on_exit(fn -> File.rm_rf!(root) end)

    args = Keyword.get(opts, :args, ["--sha", @sha, "--format", "json"])

    env = [
      {"GH_BIN", gh},
      {"RUNS", runs_path},
      {"JOBS", jobs_path},
      {"ARGV_LOG", argv_path},
      {"FAIL_OPERATION", Keyword.get(opts, :fail_operation, "")}
    ]

    result = System.cmd(@script, args, env: env, stderr_to_stdout: true)

    calls =
      argv_path |> File.read!() |> :binary.split(<<0>>, [:global, :trim_all]) |> split_calls()

    {result, calls}
  end

  defp split_calls(entries) do
    entries
    |> Enum.chunk_by(&(&1 == "CALL"))
    |> Enum.reject(&(&1 == ["CALL"]))
  end

  test "newest exact SHA is selected before status" do
    runs =
      ~s([{"databaseId":1,"headSha":"#{@sha}","status":"completed","conclusion":"success","createdAt":"2026-01-01T00:00:00Z"},{"databaseId":2,"headSha":"#{@sha}","status":"in_progress","conclusion":null,"createdAt":"2026-01-02T00:00:00Z"}])

    assert {{out, 0}, [list_call]} = run(runs)
    assert %{"selected_id" => 2, "state" => "incomplete"} = Jason.decode!(out)

    assert list_call == [
             "run",
             "list",
             "--workflow",
             ".github/workflows/ci.yml",
             "--branch",
             "main",
             "--event",
             "push",
             "--limit",
             "100",
             "--json",
             "databaseId,headSha,status,conclusion,createdAt"
           ]
  end

  test "success requires one successful aggregate and non-empty jobs" do
    runs =
      ~s([{"databaseId":3,"headSha":"#{@sha}","status":"completed","conclusion":"success","createdAt":"2026-01-01T00:00:00Z"}])

    jobs = ~s({"jobs":[{"name":"CI required","conclusion":"success"}]})
    assert {{out, 0}, [_, ["run", "view", "3", "--json", "jobs"]]} = run(runs, jobs)
    assert %{"state" => "success", "ci_required_count" => 1} = Jason.decode!(out)

    assert {{out, 0}, [_, ["run", "view", "3", "--json", "jobs"]]} =
             run(runs, ~s({"jobs":[]}))

    assert %{"state" => "failure"} = Jason.decode!(out)
  end

  test "absence is explicit and invalid SHA fails" do
    assert {{out, 0}, [_list_call]} = run("[]")
    assert %{"state" => "not_observed"} = Jason.decode!(out)
    assert {_out, status} = System.cmd(@script, ["--sha", "main"], stderr_to_stdout: true)
    assert status != 0
  end

  test "write verbs, unknown flags, and shell-hostile run IDs never reach gh" do
    for args <- [
          ["dispatch"],
          ["workflow", "run"],
          ["rerun"],
          ["cancel"],
          ["delete"],
          ["api", "--method", "POST"],
          ["api", "--method", "PATCH"],
          ["api", "--method", "PUT"],
          ["api", "--method", "DELETE"],
          ["--sha", @sha, "--extra", "value"]
        ] do
      assert {{_out, status}, []} = run("[]", ~s({"jobs":[]}), args: args)
      assert status != 0
    end

    hostile =
      ~s([{"databaseId":"3; touch /tmp/pwned","headSha":"#{@sha}","status":"completed","conclusion":"success","createdAt":"2026-01-01T00:00:00Z"}])

    assert {{_out, status}, [_list_only]} = run(hostile)
    assert status != 0
  end

  test "API errors and malformed JSON fail without fallback invocations" do
    assert {{_out, 19}, [_list_only]} = run("[]", ~s({"jobs":[]}), fail_operation: "list")
    assert {{_out, status}, [_list_only]} = run("not-json")
    assert status != 0

    runs =
      ~s([{"databaseId":3,"headSha":"#{@sha}","status":"completed","conclusion":"success","createdAt":"2026-01-01T00:00:00Z"}])

    assert {{_out, 23}, [_, ["run", "view", "3", "--json", "jobs"]]} =
             run(runs, ~s({"jobs":[]}), fail_operation: "view")

    assert {{_out, status}, [_, ["run", "view", "3", "--json", "jobs"]]} =
             run(runs, "not-json")

    assert status != 0
  end
end
