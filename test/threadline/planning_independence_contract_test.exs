defmodule Threadline.PlanningIndependenceContractTest do
  use ExUnit.Case, async: false

  @root Path.expand("../..", __DIR__)

  @tag timeout: 120_000
  test "certifies exact committed HEAD with planning absent and preserves caller state" do
    verifier = Path.join(@root, "bin/verify-planning-independent")

    assert File.exists?(verifier),
           "#{verifier} must exist before planning-independent certification can run"

    with_verifier_fixture(fn temp_root, fake_bin, invocation_log ->
      sentinel = Path.join(temp_root, "caller-sentinel.bin")
      sentinel_bytes = <<0, 11, 22, 33, 244, 255>>
      File.write!(sentinel, sentinel_bytes)

      {expected_sha, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: @root)
      {status_before, 0} = checkout_status()

      assert {output, 0} =
               System.cmd(verifier, [],
                 cd: @root,
                 env: [{"TMPDIR", temp_root}, {"PATH", path_with(fake_bin)}],
                 stderr_to_stdout: true
               )

      assert output =~ "CERTIFIED_SHA=#{String.trim(expected_sha)}"
      assert output =~ "PLANNING_STATUS=ABSENT"
      assert output =~ "AGGREGATE_RESULT=PASS"
      assert output =~ "PLANNING_RESTORED"
      assert output =~ "SAFE_TEMP_TREE_REMOVED"
      assert File.read!(sentinel) == sentinel_bytes
      assert File.read!(invocation_log) == "deps.get --check-locked\nci.all\n"
      assert Path.wildcard(Path.join(temp_root, "threadline-planning-independent-*")) == []

      {status_after, 0} = checkout_status()
      assert status_after == status_before
    end)
  end

  defp with_verifier_fixture(fun) do
    raw_temp_root = unique_temp_path("threadline-planning-independent-contract")
    File.mkdir!(raw_temp_root)
    temp_root = canonical_path(raw_temp_root)
    fake_bin = Path.join(temp_root, "bin")
    invocation_log = Path.join(temp_root, "mix-invocations")
    File.mkdir!(fake_bin)

    fake_mix = Path.join(fake_bin, "mix")

    File.write!(fake_mix, """
    #!/usr/bin/env bash
    set -euo pipefail
    printf '%s\\n' "$*" >>#{shell_quote(invocation_log)}
    if [ "$*" = 'ci.all' ]; then
      [ ! -e .planning ] || {
        printf 'fake mix: planning remained visible during aggregate\\n' >&2
        exit 91
      }
    fi
    """)

    File.chmod!(fake_mix, 0o755)

    try do
      fun.(temp_root, fake_bin, invocation_log)
    after
      File.rm_rf!(temp_root)
    end
  end

  defp checkout_status do
    System.cmd("git", ["status", "--porcelain=v1", "--untracked-files=all"], cd: @root)
  end

  defp path_with(fake_bin), do: fake_bin <> ":" <> System.get_env("PATH", "")

  defp unique_temp_path(prefix) do
    Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive, :monotonic])}")
  end

  defp canonical_path(path) do
    {canonical, 0} = System.cmd("realpath", [path])
    String.trim(canonical)
  end

  defp shell_quote(value), do: "'#{String.replace(value, "'", "'\\''")}'"
end
