defmodule Threadline.MeasureMainCiContractTest do
  @moduledoc """
  Fake-gh contract for `bin/measure-main-ci` (phase 247 D-08 / D-12).

  The fake gh answers only the exact read-only argv shapes the script is allowed
  to send (exit 97 otherwise) and logs every call, so each test proves both the
  measurement and the closed read boundary: attempt-1 data wins over the run
  object, cancelled runs are excluded, and write verbs or hostile ids never
  reach gh.
  """
  use ExUnit.Case, async: true

  @script Path.expand("../../bin/measure-main-ci", __DIR__)
  @since String.duplicate("a", 40)
  @start ~U[2026-10-01 00:00:00Z]

  defp sha(n), do: n |> Integer.to_string(16) |> String.downcase() |> String.pad_leading(40, "b")

  defp iso(%DateTime{} = at, offset_s), do: at |> DateTime.add(offset_s) |> DateTime.to_iso8601()

  defp run_row(id, opts \\ []) do
    %{
      "databaseId" => id,
      "headSha" => Keyword.get(opts, :head, sha(id)),
      "event" => Keyword.get(opts, :event, "push"),
      "status" => "completed",
      # The run object reflects the LATEST attempt; the script must not trust it.
      "conclusion" => Keyword.get(opts, :latest_conclusion, "success"),
      "createdAt" => iso(@start, id * 3600)
    }
  end

  defp attempt(id, wall_s, conclusion \\ "success") do
    started = DateTime.add(@start, id * 3600)

    %{
      "id" => id,
      "run_attempt" => 1,
      "status" => "completed",
      "conclusion" => conclusion,
      "run_started_at" => iso(started, 0),
      "updated_at" => iso(started, wall_s)
    }
  end

  defp jobs(id, durations) do
    started = DateTime.add(@start, id * 3600)

    %{
      "total_count" => length(durations),
      "jobs" =>
        durations
        |> Enum.with_index(1)
        |> Enum.map(fn {{name, seconds}, index} ->
          %{
            "id" => id * 100 + index,
            "name" => name,
            "started_at" => iso(started, 0),
            "completed_at" => iso(started, seconds)
          }
        end)
    }
  end

  # fixtures: %{"runs" => list, {:compare, head} => status, {:attempt, id} => map,
  # {:bare, id} => map, {:jobs, id} => map, {:log, job_id} => text}
  defp measure(fixtures, args) do
    root = Path.join(System.tmp_dir!(), "measure_main_ci_#{System.unique_integer([:positive])}")
    fixture_dir = Path.join(root, "fixtures")
    File.mkdir_p!(fixture_dir)
    on_exit(fn -> File.rm_rf!(root) end)

    for {key, value} <- fixtures do
      {name, body} =
        case key do
          "runs" -> {"runs.json", value}
          {:compare, head} -> {"compare-#{head}", value}
          {:attempt, id} -> {"attempt-#{id}.json", value}
          {:bare, id} -> {"bare-#{id}.json", value}
          {:jobs, id} -> {"jobs-#{id}.json", value}
          {:log, id} -> {"log-#{id}.txt", value}
        end

      body = if is_binary(body), do: body, else: Jason.encode!(body)
      File.write!(Path.join(fixture_dir, name), body)
    end

    gh = Path.join(root, "gh")
    argv_path = Path.join(root, "argv")
    File.write!(argv_path, "")

    File.write!(
      gh,
      """
      #!/usr/bin/env bash
      set -euo pipefail
      printf 'CALL\\0' >> "$ARGV_LOG"
      printf '%s\\0' "$@" >> "$ARGV_LOG"
      reject() { echo "fake-gh: rejected argv" >&2; exit 97; }
      serve() { [ -f "$FIXTURES/$1" ] || reject; cat "$FIXTURES/$1"; }
      p='repos/[{]owner[}]/[{]repo[}]'

      if [ "$#" -eq 10 ] && [ "$1" = run ] && [ "$2" = list ] &&
         [ "$3" = --workflow ] && [ "$4" = .github/workflows/ci.yml ] &&
         [ "$5" = --branch ] && [ "$6" = main ] && [ "$7" = --limit ] &&
         [ "$8" = 100 ] && [ "$9" = --json ] &&
         [ "${10}" = databaseId,headSha,event,status,conclusion,createdAt ]; then
        serve runs.json
      elif [ "$#" -eq 4 ] && [ "$1" = api ] && [ "$3" = --jq ] && [ "$4" = .status ] &&
           [[ "$2" =~ ^${p}/compare/[0-9a-f]{40}\\.\\.\\.([0-9a-f]{40})$ ]]; then
        serve "compare-${BASH_REMATCH[1]}"
      elif [ "$#" -eq 2 ] && [ "$1" = api ] && [[ "$2" =~ ^${p}/actions/runs/([0-9]+)/attempts/1$ ]]; then
        serve "attempt-${BASH_REMATCH[1]}.json"
      elif [ "$#" -eq 2 ] && [ "$1" = api ] && [[ "$2" =~ ^${p}/actions/runs/([0-9]+)$ ]]; then
        serve "bare-${BASH_REMATCH[1]}.json"
      elif [ "$#" -eq 3 ] && [ "$1" = api ] && [ "$3" = --paginate ] &&
           [[ "$2" =~ ^${p}/actions/runs/([0-9]+)/attempts/1/jobs$ ]]; then
        serve "jobs-${BASH_REMATCH[1]}.json"
      elif [ "$#" -eq 2 ] && [ "$1" = api ] && [[ "$2" =~ ^${p}/actions/jobs/([0-9]+)/logs$ ]]; then
        serve "log-${BASH_REMATCH[1]}.txt"
      else
        reject
      fi
      """
    )

    File.chmod!(gh, 0o755)

    env = [{"GH_BIN", gh}, {"FIXTURES", fixture_dir}, {"ARGV_LOG", argv_path}]
    {out, status} = System.cmd(@script, args, env: env, stderr_to_stdout: true)

    calls =
      argv_path
      |> File.read!()
      |> :binary.split(<<0>>, [:global, :trim_all])
      |> Enum.chunk_by(&(&1 == "CALL"))
      |> Enum.reject(&(&1 == ["CALL"]))

    refute Enum.any?(calls, &write_call?/1), "a write verb reached gh: #{inspect(calls)}"
    {out, status, calls}
  end

  defp write_call?(argv) do
    joined = Enum.join(argv, " ")

    hd(argv) not in ["run", "api"] or
      (hd(argv) == "run" and Enum.at(argv, 1) != "list") or
      joined =~ ~r/--method|-X\b|rerun|workflow run|cancel|delete|--input|-f\b|-F\b/
  end

  defp json!(out) do
    out |> String.split("\n", trim: true) |> List.last() |> Jason.decode!()
  end

  defp five_run_fixtures do
    walls = [{1, 600}, {2, 540}, {3, 560}, {4, 580}, {5, 620}]

    base = %{
      "runs" =>
        Enum.map(walls, fn {id, _} ->
          run_row(id, event: if(id == 3, do: "workflow_dispatch", else: "push"))
        end)
    }

    Enum.reduce(walls, base, fn {id, wall}, acc ->
      acc
      |> Map.put({:compare, sha(id)}, "ahead\n")
      |> Map.put({:attempt, id}, attempt(id, wall))
      |> Map.put(
        {:jobs, id},
        jobs(id, [{"Build and test (current)", wall - 60}, {"Lint", 30}])
      )
    end)
  end

  test "five qualifying runs give the median of attempt-1 walls, oldest first" do
    {out, 0, calls} =
      measure(five_run_fixtures(), ["--since", @since, "--count", "5", "--format", "json"])

    result = json!(out)
    assert result["schema"] == "threadline.main-ci-measurement/1"
    assert result["state"] == "measured"
    assert result["since"] == @since
    assert Enum.map(result["runs"], & &1["id"]) == [1, 2, 3, 4, 5]
    assert Enum.map(result["runs"], & &1["wall_s"]) == [600, 540, 560, 580, 620]
    assert Enum.at(result["runs"], 2)["event"] == "workflow_dispatch"
    assert result["median_wall_s"] == 580
    assert result["excluded"] == []
    assert result["ratios"] == nil

    first = hd(result["runs"])
    assert first["slowest_job"] == %{"name" => "Build and test (current)", "seconds" => 540}
    assert Enum.map(first["jobs"], & &1["seconds"]) == [540, 30]

    assert hd(calls) == [
             "run",
             "list",
             "--workflow",
             ".github/workflows/ci.yml",
             "--branch",
             "main",
             "--limit",
             "100",
             "--json",
             "databaseId,headSha,event,status,conclusion,createdAt"
           ]
  end

  test "the attempt-1 wall wins when the run object's updated_at moved with a re-run" do
    fixtures =
      five_run_fixtures()
      |> Map.put({:bare, 1}, Map.put(attempt(1, 600), "updated_at", iso(@start, 3600 + 9000)))
      |> Map.update!("runs", fn runs ->
        List.update_at(runs, 0, &Map.put(&1, "conclusion", "failure"))
      end)

    {out, 0, calls} = measure(fixtures, ["--since", @since, "--format", "json"])
    assert hd(json!(out)["runs"])["wall_s"] == 600

    paths = Enum.map(calls, &Enum.at(&1, 1))
    assert "repos/{owner}/{repo}/actions/runs/1/attempts/1" in paths
    refute "repos/{owner}/{repo}/actions/runs/1" in paths, "the bare run object was read"
  end

  test "cancelled attempt-1 runs are excluded and listed; runs before --since are not selected" do
    fixtures =
      five_run_fixtures()
      |> Map.update!("runs", fn runs ->
        [run_row(0) | runs] ++ [run_row(6), run_row(7, event: "pull_request")]
      end)
      |> Map.put({:compare, sha(0)}, "behind\n")
      |> Map.put({:compare, sha(6)}, "ahead\n")
      |> Map.put({:attempt, 6}, attempt(6, 700))
      |> Map.put({:jobs, 6}, jobs(6, [{"Lint", 30}]))
      |> Map.put({:attempt, 2}, attempt(2, 540, "cancelled"))

    {out, 0, calls} = measure(fixtures, ["--since", @since, "--format", "json"])
    result = json!(out)

    assert Enum.map(result["runs"], & &1["id"]) == [1, 3, 4, 5, 6]
    assert result["median_wall_s"] == 600

    assert result["excluded"] == [
             %{"id" => 2, "event" => "push", "head_sha" => sha(2), "reason" => "cancelled"}
           ]

    paths = Enum.map(calls, &Enum.at(&1, 1))
    refute "repos/{owner}/{repo}/actions/runs/0/attempts/1" in paths
    refute Enum.any?(paths, &(&1 =~ "/runs/7/")), "a pull_request run was measured"
    refute Enum.any?(paths, &(&1 =~ "/runs/2/attempts/1/jobs")), "an excluded run was timed"
  end

  test "the head equal to --since needs no compare call and an even count averages the middles" do
    fixtures =
      five_run_fixtures()
      |> Map.update!("runs", fn runs ->
        List.update_at(runs, 0, &Map.put(&1, "headSha", @since))
      end)
      |> Map.delete({:compare, sha(1)})

    {out, 0, calls} = measure(fixtures, ["--since", @since, "--count", "4", "--format", "json"])
    result = json!(out)
    assert Enum.map(result["runs"], & &1["id"]) == [1, 2, 3, 4]
    assert result["median_wall_s"] == 570
    refute Enum.any?(calls, &(Enum.at(&1, 1) =~ "compare/#{@since}...#{@since}"))
  end

  test "fewer qualifying runs than --count is reported as insufficient, exit 0" do
    fixtures =
      five_run_fixtures()
      |> Map.update!("runs", &Enum.take(&1, 2))

    {out, 0, _calls} = measure(fixtures, ["--since", @since, "--count", "5", "--format", "json"])
    result = json!(out)
    assert result["state"] == "insufficient"
    assert result["found"] == 2
    assert result["median_wall_s"] == nil
  end

  test "--ratios reads the partition max/min row per Build and test lane" do
    fixtures =
      %{
        "runs" => [run_row(1)],
        {:compare, sha(1)} => "ahead\n",
        {:attempt, 1} => attempt(1, 600),
        {:jobs, 1} =>
          jobs(1, [
            {"Build and test (current)", 500},
            {"Build and test (min)", 400},
            {"Lint", 30}
          ]),
        {:log, 101} =>
          "2026-10-01T00:05:00.0000000Z | partition | weight | seconds | tests |\n" <>
            "2026-10-01T00:05:00.0000000Z \e[1m| max/min | - | 1.12 | - |\e[0m\n",
        {:log, 102} => "2026-10-01T00:05:00.0000000Z no table here\n"
      }

    {out, 0, calls} =
      measure(fixtures, ["--since", @since, "--count", "1", "--ratios", "--format", "json"])

    assert out =~ "warning: no max/min row in job 102 (min)"
    assert json!(out)["ratios"] == %{"current" => [1.12], "min" => [nil]}

    assert ["api", "repos/{owner}/{repo}/actions/jobs/101/logs"] in calls
    refute Enum.any?(calls, &(&1 == ["api", "repos/{owner}/{repo}/actions/jobs/103/logs"]))
  end

  test "hostile arguments, unknown flags and write verbs exit 1 before any gh call" do
    for args <- [
          ["--since", "nothex"],
          ["--since", String.duplicate("a", 39) <> ";"],
          ["--since", "$(touch pwned)" <> String.duplicate("a", 26)],
          ["--since", String.upcase(@since)],
          ["--since", @since, "--count", "0"],
          ["--since", @since, "--count", "5;rm"],
          ["--since", @since, "--format", "yaml"],
          ["--since", @since, "--extra", "value"],
          ["run", "rerun", "1"],
          ["workflow", "run", "ci.yml"],
          ["api", "--method", "POST"],
          ["api", "--method", "DELETE"]
        ] do
      assert {_out, 1, []} = measure(%{"runs" => []}, args), "#{inspect(args)} reached gh"
    end
  end

  test "a non-digit run id or malformed head sha from gh exits 1 after the list call only" do
    for row <- [
          Map.put(run_row(1), "databaseId", "1; touch /tmp/pwned"),
          Map.put(run_row(1), "headSha", "main"),
          Map.put(run_row(1), "databaseId", 1.5)
        ] do
      assert {out, 1, [["run", "list" | _]]} =
               measure(%{"runs" => [row]}, ["--since", @since, "--format", "json"])

      assert out =~ "non-digit id or a malformed head sha"
    end
  end

  test "gh failures stop the measurement instead of falling back" do
    fixtures = five_run_fixtures() |> Map.delete({:attempt, 1})

    assert {_out, status, calls} = measure(fixtures, ["--since", @since, "--format", "json"])
    assert status != 0
    assert List.last(calls) == ["api", "repos/{owner}/{repo}/actions/runs/1/attempts/1"]
  end
end
