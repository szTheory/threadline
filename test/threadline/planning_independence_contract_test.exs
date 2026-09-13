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

      assert File.read!(invocation_log) ==
               "deps.get --check-locked\nnpm ci\ndialyzer --plt\nci.all\n"

      assert Path.wildcard(Path.join(temp_root, "threadline-planning-independent-*")) == []

      {status_after, 0} = checkout_status()
      assert status_after == status_before
    end)
  end

  test "aggregate failure restores planning before contained cleanup" do
    verifier = Path.join(@root, "bin/verify-planning-independent")

    with_verifier_fixture("aggregate-failure", fn temp_root, fake_bin, _invocation_log ->
      sentinel = write_caller_sentinel(temp_root)
      {status_before, 0} = checkout_status()

      assert {output, 73} =
               System.cmd(verifier, [],
                 cd: @root,
                 env: [{"TMPDIR", temp_root}, {"PATH", path_with(fake_bin)}],
                 stderr_to_stdout: true
               )

      assert output =~ "AGGREGATE_RESULT=FAIL status=73"
      assert_before(output, "AGGREGATE_RESULT=FAIL", "PLANNING_RESTORED")
      assert_before(output, "PLANNING_RESTORED", "SAFE_TEMP_TREE_REMOVED")
      assert Path.wildcard(Path.join(temp_root, "threadline-planning-independent-*")) == []
      assert_caller_unchanged(sentinel, status_before)
    end)
  end

  test "clone failure preserves caller planning names and removes only the registered clone" do
    verifier = Path.join(@root, "bin/verify-planning-independent")

    with_verifier_fixture("clone-failure", fn temp_root, fake_bin, _invocation_log ->
      caller = Path.join(temp_root, "caller")
      caller_planning = Path.join(caller, ".planning")
      caller_quarantine = Path.join(caller, ".planning.threadline-quarantine")
      planning_sentinel = Path.join(caller_planning, "sentinel.bin")
      quarantine_sentinel = Path.join(caller_quarantine, "sentinel.bin")
      planning_bytes = <<0, 17, 34, 255>>
      quarantine_bytes = <<255, 68, 51, 0>>

      File.mkdir_p!(caller_planning)
      File.mkdir_p!(caller_quarantine)
      File.write!(planning_sentinel, planning_bytes)
      File.write!(quarantine_sentinel, quarantine_bytes)

      assert {output, 76} =
               System.cmd(verifier, [],
                 cd: caller,
                 env: [{"TMPDIR", temp_root}, {"PATH", path_with(fake_bin)}],
                 stderr_to_stdout: true
               )

      assert output =~ "fake git: clone failed before entering checkout"
      refute output =~ "could not restore planning"
      assert File.read!(planning_sentinel) == planning_bytes
      assert File.read!(quarantine_sentinel) == quarantine_bytes
      assert Path.wildcard(Path.join(temp_root, "threadline-planning-independent-*")) == []
    end)
  end

  test "restoration failure retains the clone and reports its quarantine" do
    verifier = Path.join(@root, "bin/verify-planning-independent")

    with_verifier_fixture("restore-failure", fn temp_root, fake_bin, _invocation_log ->
      sentinel = write_caller_sentinel(temp_root)
      {status_before, 0} = checkout_status()

      assert {output, 74} =
               System.cmd(verifier, [],
                 cd: @root,
                 env: [{"TMPDIR", temp_root}, {"PATH", path_with(fake_bin)}],
                 stderr_to_stdout: true
               )

      assert output =~ "could not restore planning"
      assert output =~ "retained clone and quarantine"
      refute output =~ "SAFE_TEMP_TREE_REMOVED"

      assert [retained_parent] =
               Path.wildcard(Path.join(temp_root, "threadline-planning-independent-parent.*"))

      assert File.dir?(Path.join(retained_parent, "checkout/.planning"))
      assert File.dir?(Path.join(retained_parent, "checkout/.planning.threadline-quarantine"))
      assert_caller_unchanged(sentinel, status_before)
    end)
  end

  test "symlink replacement is rejected without touching the outside target or caller" do
    verifier = Path.join(@root, "bin/verify-planning-independent")
    outside = unique_temp_path("threadline-planning-independent-outside")
    File.mkdir!(outside)
    outside = canonical_path(outside)
    outside_sentinel = Path.join(outside, "sentinel.bin")
    outside_bytes = <<255, 128, 64, 0>>
    File.write!(outside_sentinel, outside_bytes)

    try do
      with_verifier_fixture("symlink-swap", fn temp_root, fake_bin, _invocation_log ->
        sentinel = write_caller_sentinel(temp_root)
        {status_before, 0} = checkout_status()

        assert {output, 75} =
                 System.cmd(verifier, [],
                   cd: @root,
                   env: [
                     {"TMPDIR", temp_root},
                     {"PATH", path_with(fake_bin)},
                     {"THREADLINE_TEST_OUTSIDE_TARGET", outside}
                   ],
                   stderr_to_stdout: true
                 )

        assert output =~ "PLANNING_RESTORED"
        assert output =~ "literal child was replaced, removed, or is a symlink"
        refute output =~ "SAFE_TEMP_TREE_REMOVED"
        assert File.read!(outside_sentinel) == outside_bytes
        assert_caller_unchanged(sentinel, status_before)
      end)
    after
      File.rm_rf!(outside)
    end
  end

  defp with_verifier_fixture(fun) do
    with_verifier_fixture("pass", fun)
  end

  defp with_verifier_fixture(mode, fun) do
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

      case #{shell_quote(mode)} in
        aggregate-failure)
          exit 73
          ;;
        restore-failure)
          mkdir .planning
          exit 74
          ;;
        symlink-swap)
          original="$PWD"
          mv -- "$original" "${original}.moved"
          ln -s -- "$THREADLINE_TEST_OUTSIDE_TARGET" "$original"
          exit 75
          ;;
      esac
    fi
    """)

    File.chmod!(fake_mix, 0o755)

    fake_npm = Path.join(fake_bin, "npm")

    File.write!(fake_npm, """
    #!/usr/bin/env bash
    set -euo pipefail
    printf 'npm %s\\n' "$*" >>#{shell_quote(invocation_log)}
    """)

    File.chmod!(fake_npm, 0o755)

    fake_git = Path.join(fake_bin, "git")
    real_git = System.find_executable("git") || flunk("git executable is required")

    File.write!(fake_git, """
    #!/usr/bin/env bash
    set -euo pipefail
    if [ #{shell_quote(mode)} = 'clone-failure' ] && [ "${1:-}" = 'clone' ]; then
      printf 'fake git: clone failed before entering checkout\n' >&2
      exit 76
    fi
    exec #{shell_quote(real_git)} "$@"
    """)

    File.chmod!(fake_git, 0o755)

    try do
      fun.(temp_root, fake_bin, invocation_log)
    after
      File.rm_rf!(temp_root)
    end
  end

  defp checkout_status do
    System.cmd("git", ["status", "--porcelain=v1", "--untracked-files=all"], cd: @root)
  end

  defp write_caller_sentinel(temp_root) do
    path = Path.join(temp_root, "caller-sentinel.bin")
    bytes = <<0, 11, 22, 33, 244, 255>>
    File.write!(path, bytes)
    {path, bytes}
  end

  defp assert_caller_unchanged({sentinel, bytes}, status_before) do
    assert File.read!(sentinel) == bytes
    {status_after, 0} = checkout_status()
    assert status_after == status_before
  end

  defp assert_before(output, earlier, later) do
    {earlier_at, _} = :binary.match(output, earlier)
    {later_at, _} = :binary.match(output, later)
    assert earlier_at < later_at
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
