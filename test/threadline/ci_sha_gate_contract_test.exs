defmodule Threadline.CiShaGateContractTest do
  @moduledoc """
  218-05 (ECON-01, D-03/D-04): the decision table for `bin/ci-sha-gate`, driven
  through a fake `gh` (GH_BIN seam) so no row ever touches the network.

  The two load-bearing rules:
    * `skip` is reachable only from a `schedule` event on a SHA that the SAME
      workflow already proved green (exact `head_sha` match, `status=success`).
    * any gh or jq failure fails OPEN to `run`, never to `skip` — a skip on error
      would silently turn off the only flake signal.
  """
  use ExUnit.Case, async: true
  @moduletag :tmp_dir

  @script Path.expand("../../bin/ci-sha-gate", __DIR__)
  @sha "5e78b2f05d00619e11aa9b29bc8f612087756846"
  @own "flake-detection.yml"
  @upstream "ci.yml"

  defp count(n), do: ~s({"total_count":#{n},"workflow_runs":[]})

  defp fake_gh!(tmp_dir) do
    gh = Path.join(tmp_dir, "gh")

    File.write!(gh, """
    #!/usr/bin/env bash
    printf '%s\\n' "$*" >> "$CALL_LOG"
    case "${FAKE_GH_MODE:-}" in
      fail) echo "HTTP 403: Resource not accessible by integration" >&2; exit 1 ;;
      garbage) echo "not-json"; exit 0 ;;
    esac
    [ "$1" = "api" ] || exit 9
    case "$2" in
      */workflows/#{@own}/runs\\?*status=success*) printf '%s' "$OWN_SUCCESS_JSON" ;;
      */workflows/#{@upstream}/runs\\?*status=success*) printf '%s' "$UP_SUCCESS_JSON" ;;
      */workflows/#{@upstream}/runs\\?*status=failure*) printf '%s' "$UP_FAILURE_JSON" ;;
      *) exit 9 ;;
    esac
    """)

    File.chmod!(gh, 0o755)
    gh
  end

  defp gate(tmp_dir, opts) do
    gh = fake_gh!(tmp_dir)
    call_log = Path.join(tmp_dir, "calls")

    env = [
      {"GH_BIN", gh},
      {"CALL_LOG", call_log},
      {"GITHUB_REPOSITORY", "owner/repo"},
      {"GITHUB_OUTPUT", Keyword.get(opts, :github_output, "")},
      {"FAKE_GH_MODE", Keyword.get(opts, :mode, "")},
      {"OWN_SUCCESS_JSON", Keyword.get(opts, :own_success, count(0))},
      {"UP_SUCCESS_JSON", Keyword.get(opts, :up_success, count(0))},
      {"UP_FAILURE_JSON", Keyword.get(opts, :up_failure, count(0))}
    ]

    args =
      Keyword.get_lazy(opts, :args, fn ->
        base = ["--workflow", @own, "--sha", @sha, "--event", Keyword.fetch!(opts, :event)]
        if opts[:upstream], do: base ++ ["--upstream", @upstream], else: base
      end)

    {out, status} = System.cmd(@script, args, env: env, stderr_to_stdout: true)
    calls = if File.exists?(call_log), do: File.read!(call_log), else: ""
    %{out: out, status: status, calls: calls, decision: decision(out)}
  end

  defp decision(out) do
    case Regex.run(~r/^decision=(.*)$/m, out) do
      [_, d] -> d
      nil -> nil
    end
  end

  describe "decision table" do
    test "schedule on a SHA this workflow already proved green -> skip", %{tmp_dir: t} do
      r = gate(t, event: "schedule", own_success: count(1), upstream: true)
      assert r.status == 0
      assert r.decision == "skip"
      assert r.out =~ ~r/^reason=.+/m
    end

    test "schedule, no prior success, upstream neither red nor green -> run", %{tmp_dir: t} do
      r = gate(t, event: "schedule", upstream: true)
      assert {r.status, r.decision} == {0, "run"}
    end

    test "workflow_dispatch never skips, even on a proven SHA", %{tmp_dir: t} do
      r = gate(t, event: "workflow_dispatch", own_success: count(1))
      assert {r.status, r.decision} == {0, "run"}
    end

    test "push never skips, even on a proven SHA", %{tmp_dir: t} do
      r = gate(t, event: "push", own_success: count(1))
      assert {r.status, r.decision} == {0, "run"}
    end

    test "schedule with upstream red and no green re-run -> broken-upstream", %{tmp_dir: t} do
      r = gate(t, event: "schedule", upstream: true, up_failure: count(1))
      assert {r.status, r.decision} == {0, "broken-upstream"}
    end

    test "workflow_dispatch with upstream red and no green re-run -> broken-upstream", %{
      tmp_dir: t
    } do
      r = gate(t, event: "workflow_dispatch", upstream: true, up_failure: count(1))
      assert {r.status, r.decision} == {0, "broken-upstream"}
    end

    test "upstream red but a re-run went green -> run", %{tmp_dir: t} do
      r = gate(t, event: "schedule", upstream: true, up_failure: count(1), up_success: count(1))
      assert {r.status, r.decision} == {0, "run"}
    end

    test "zero prior runs (total_count 0) -> run", %{tmp_dir: t} do
      r = gate(t, event: "schedule")
      assert {r.status, r.decision} == {0, "run"}
    end

    test "a green upstream alone never causes a skip (same-workflow rule)", %{tmp_dir: t} do
      r = gate(t, event: "schedule", upstream: true, up_success: count(3))
      assert {r.status, r.decision} == {0, "run"}
    end
  end

  describe "fail open to run" do
    test "gh exits 1 (403 or network) -> run, with a reason naming the failed query", %{
      tmp_dir: t
    } do
      r = gate(t, event: "schedule", upstream: true, mode: "fail")
      assert {r.status, r.decision} == {0, "run"}
      assert r.out =~ ~r/^reason=.*#{Regex.escape(@own)}.*query failed/m
    end

    test "gh prints not-json -> run", %{tmp_dir: t} do
      r = gate(t, event: "schedule", upstream: true, mode: "garbage")
      assert {r.status, r.decision} == {0, "run"}
    end

    test "total_count that is not a number -> run", %{tmp_dir: t} do
      r = gate(t, event: "schedule", own_success: ~s({"total_count":"x"}), upstream: true)
      assert {r.status, r.decision} == {0, "run"}

      r2 = gate(t, event: "schedule", own_success: ~s({"total_count":1.5}))
      assert {r2.status, r2.decision} == {0, "run"}
    end

    test "empty API response -> run", %{tmp_dir: t} do
      r = gate(t, event: "schedule", own_success: "", upstream: true, up_failure: "")
      assert {r.status, r.decision} == {0, "run"}
    end
  end

  describe "query shape" do
    test "the own-workflow query filters by exact head_sha and status=success", %{tmp_dir: t} do
      r = gate(t, event: "schedule")

      assert r.calls =~
               "api repos/owner/repo/actions/workflows/#{@own}/runs?head_sha=#{@sha}&status=success&per_page=1"
    end

    test "non-schedule events never query their own workflow for a skip", %{tmp_dir: t} do
      r = gate(t, event: "workflow_dispatch", own_success: count(1))
      refute r.calls =~ "workflows/#{@own}/"
    end
  end

  describe "usage errors exit 2" do
    test "missing --workflow", %{tmp_dir: t} do
      assert %{status: 2} = gate(t, args: ["--sha", @sha, "--event", "schedule"])
    end

    test "unknown flag", %{tmp_dir: t} do
      args = ["--workflow", @own, "--sha", @sha, "--event", "schedule", "--bogus", "x"]
      assert %{status: 2} = gate(t, args: args)
    end

    test "invalid --sha", %{tmp_dir: t} do
      for sha <- ["abc", "ZZZZZZZ", "#{@sha}0", "abc123;rm", ""] do
        r = gate(t, args: ["--workflow", @own, "--sha", sha, "--event", "schedule"])
        assert r.status == 2, "--sha #{inspect(sha)} must be rejected, got #{inspect(r)}"
      end
    end

    test "invalid --workflow", %{tmp_dir: t} do
      for wf <- ["../x", "x", "a/b.yml", "ci.yml?x=1", "ci.json"] do
        r = gate(t, args: ["--workflow", wf, "--sha", @sha, "--event", "schedule"])
        assert r.status == 2, "--workflow #{inspect(wf)} must be rejected"
      end
    end

    test "missing GITHUB_REPOSITORY", %{tmp_dir: t} do
      {_, status} =
        System.cmd(@script, ["--workflow", @own, "--sha", @sha, "--event", "schedule"],
          env: [{"GITHUB_REPOSITORY", ""}, {"GH_BIN", fake_gh!(t)}],
          stderr_to_stdout: true
        )

      assert status == 2
    end
  end

  describe "GITHUB_OUTPUT" do
    test "decision= and reason= are appended without overwriting", %{tmp_dir: t} do
      out = Path.join(t, "github_output")
      File.write!(out, "pre_existing=value\n")
      r = gate(t, event: "schedule", own_success: count(1), github_output: out)
      assert r.decision == "skip"

      assert ["pre_existing=value", "decision=skip", "reason=" <> _] =
               out |> File.read!() |> String.split("\n", trim: true)
    end
  end
end
