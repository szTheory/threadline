defmodule Threadline.CleanCheckoutContractTest do
  use ExUnit.Case, async: false

  @root Path.expand("../..", __DIR__)

  @generated_paths [
    {"erl_crash.dump", "/erl_crash.dump"},
    {"threadline-0.10.0.tar", "/threadline-*.tar"},
    {"threadline-0.10.0/lib/threadline.ex", "/threadline-*/"},
    {".dialyzer/threadline.plt", "/.dialyzer/*.plt"},
    {".dialyzer/threadline.plt.hash", "/.dialyzer/*.plt.hash"},
    {"examples/threadline_phoenix/e2e/test-results/results.json", "test-results/"},
    {"examples/threadline_phoenix/e2e/playwright-report/index.html", "playwright-report/"},
    {"examples/threadline_phoenix/e2e/blob-report/report.zip", "blob-report/"},
    {"examples/threadline_phoenix/e2e/artifacts/capture/screenshot.png",
     "/examples/threadline_phoenix/e2e/artifacts/"},
    {"test/fixtures/operator_surface/critic-scores/local-run.json",
     "/test/fixtures/operator_surface/critic-scores/*"}
  ]

  @trackable_paths [
    ".tool-versions",
    "notes/erl_crash.dump",
    "packages/threadline-0.10.0.tar",
    ".dialyzer/nested/threadline.plt",
    "examples/threadline_phoenix/e2e/artifacts-reviewed/screenshot.png",
    "examples/threadline_phoenix/e2e/tests/operator.spec.ts-snapshots/screenshot.png",
    "test/fixtures/operator_surface/critic-scores/.gitkeep",
    "test/fixtures/operator_surface/critic-scores-reviewed/local-run.json",
    "test/fixtures/operator_surface/scorecards/page.timeline.json",
    "test/fixtures/operator_surface/golden/golden-set.json",
    "lib/threadline/critic_scores.ex"
  ]

  test "generated output is ignored by its exact producer-owned rule" do
    for {path, expected_pattern} <- @generated_paths do
      {output, status} =
        System.cmd("git", ["check-ignore", "--no-index", "-v", "--", path],
          cd: @root,
          stderr_to_stdout: true
        )

      assert status == 0, "expected #{path} to be ignored, got: #{output}"

      assert output =~ "#{expected_pattern}\t#{path}",
             "expected #{path} to map to #{expected_pattern}, got: #{output}"
    end
  end

  test "reviewed evidence, source, local config, and prefix-confusion paths remain trackable" do
    for path <- @trackable_paths do
      {_output, status} =
        System.cmd("git", ["check-ignore", "--no-index", "--quiet", "--", path], cd: @root)

      assert status == 1, "expected #{path} to remain trackable"
    end
  end

  describe "safe temp-tree cleanup" do
    test "removes only the registered literal child" do
      with_temp_parent(fn parent ->
        child = Path.join(parent, "valid-child")
        File.mkdir!(child)
        File.write!(Path.join(child, "generated.txt"), "generated")

        assert {output, 0} = run_cleanup(parent, child)
        assert output =~ "SAFE_TEMP_TREE_REMOVED"
        refute File.exists?(child)
        assert File.dir?(parent)
      end)
    end

    test "rejects empty, root, parent, outside, caller-worktree, symlink, and replacement targets" do
      with_temp_parent(fn parent ->
        caller_sentinel = Path.join(@root, ".safe-temp-tree-caller-sentinel")
        outside = unique_temp_path("threadline-safe-outside")
        File.mkdir!(outside)
        outside = canonical_path(outside)
        outside_sentinel = Path.join(outside, "sentinel")
        File.write!(outside_sentinel, "outside survives")
        File.write!(caller_sentinel, "caller survives")

        on_exit(fn ->
          File.rm(caller_sentinel)
          File.rm_rf(outside)
        end)

        for target <- ["", "/", parent, outside, @root] do
          assert {_output, status} = run_cleanup(parent, target)
          assert status != 0, "expected cleanup to reject #{inspect(target)}"
        end

        assert File.read!(caller_sentinel) == "caller survives"
        assert File.read!(outside_sentinel) == "outside survives"

        symlink_child = Path.join(parent, "symlink-child")
        symlink_original = Path.join(parent, "symlink-original")
        File.mkdir!(symlink_child)

        assert {_output, status} =
                 run_cleanup(parent, symlink_child, """
                 mv "$SAFE_TEMP_TREE_CHILD" #{shell_quote(symlink_original)}
                 ln -s #{shell_quote(outside)} "$SAFE_TEMP_TREE_CHILD"
                 """)

        assert status != 0
        assert File.read!(outside_sentinel) == "outside survives"
        assert File.dir?(symlink_original)

        File.rm!(symlink_child)
        File.rm_rf!(symlink_original)

        replaced_child = Path.join(parent, "replaced-child")
        replaced_original = Path.join(parent, "replaced-original")
        File.mkdir!(replaced_child)

        assert {_output, status} =
                 run_cleanup(parent, replaced_child, """
                 mv "$SAFE_TEMP_TREE_CHILD" #{shell_quote(replaced_original)}
                 mkdir "$SAFE_TEMP_TREE_CHILD"
                 """)

        assert status != 0
        assert File.dir?(replaced_child)
        assert File.dir?(replaced_original)
      end)
    end

    test "rejects every registered linked worktree root without mutating or unregistering it" do
      raw_parent = unique_temp_path("threadline-safe-parent")
      File.mkdir!(raw_parent)
      parent = canonical_path(raw_parent)
      linked = Path.join(parent, "registered-worktree")

      try do
        assert {_output, 0} =
                 System.cmd("git", ["worktree", "add", "--detach", linked, "HEAD"],
                   cd: @root,
                   stderr_to_stdout: true
                 )

        sentinel = Path.join(linked, "sentinel.bin")
        sentinel_bytes = <<0, 1, 2, 253, 254, 255>>
        File.write!(sentinel, sentinel_bytes)

        assert {output, status} = run_cleanup(parent, linked)
        assert status != 0
        assert output =~ "registered Git worktree"
        assert File.read!(sentinel) == sentinel_bytes

        {worktrees, 0} =
          System.cmd("git", ["worktree", "list", "--porcelain"],
            cd: @root,
            stderr_to_stdout: true
          )

        assert worktrees =~ "worktree #{linked}"
      after
        System.cmd("git", ["worktree", "remove", "--force", linked],
          cd: @root,
          stderr_to_stdout: true
        )

        File.rm_rf!(parent)
      end
    end

    test "retains the registered child when Git worktree enumeration fails" do
      with_temp_parent(fn parent ->
        child = Path.join(parent, "enumeration-failure")
        File.mkdir!(child)
        sentinel = Path.join(child, "sentinel.bin")
        sentinel_bytes = <<91, 0, 92, 255>>
        File.write!(sentinel, sentinel_bytes)

        fake_bin = Path.join(parent, "fake-bin")
        File.mkdir!(fake_bin)
        fake_git = Path.join(fake_bin, "git")
        real_git = System.find_executable("git")

        File.write!(fake_git, """
        #!/usr/bin/env bash
        if [[ " $* " == *" worktree list "* ]]; then
          exit 86
        fi
        exec #{shell_quote(real_git)} "$@"
        """)

        File.chmod!(fake_git, 0o755)

        assert {output, status} =
                 run_cleanup(parent, child, "", [
                   {"PATH", fake_bin <> ":" <> System.get_env("PATH")}
                 ])

        assert status != 0
        assert output =~ "cannot enumerate Git worktrees"
        assert File.read!(sentinel) == sentinel_bytes
        assert File.dir?(child)
      end)
    end
  end

  describe "committed checkout verifier" do
    @tag timeout: 120_000
    test "proves exact committed HEAD stays clean while reviewed controls remain trackable" do
      verifier = Path.join(@root, "bin/verify-clean-checkout")

      assert File.exists?(verifier),
             "#{verifier} must exist before the clean-checkout proof can run"

      {expected_sha, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: @root)

      assert {output, 0} =
               System.cmd(verifier, [],
                 cd: @root,
                 stderr_to_stdout: true
               )

      assert output =~ "SOURCE_SHA=#{String.trim(expected_sha)}"
      assert output =~ "DEPENDENCY_STATUS=CLEAN"
      assert output =~ "GENERATED_PROBE_STATUS=CLEAN"
      assert output =~ "TRACKABLE_CONTROLS=VISIBLE"
      assert output =~ "CLEAN_CHECKOUT_VERIFIED"
    end

    test "forced verifier failure cleans only its clone child and preserves caller state" do
      raw_temp_root = unique_temp_path("threadline-clean-verifier-test")
      File.mkdir!(raw_temp_root)
      temp_root = canonical_path(raw_temp_root)
      sentinel = Path.join(temp_root, "caller-sentinel.bin")
      sentinel_bytes = <<12, 34, 56, 78, 90>>
      File.write!(sentinel, sentinel_bytes)

      {head_before, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: @root)
      {status_before, 0} = checkout_status()

      try do
        assert {output, status} =
                 System.cmd(Path.join(@root, "bin/verify-clean-checkout"), [],
                   cd: @root,
                   env: [
                     {"TMPDIR", temp_root},
                     {"THREADLINE_VERIFY_CLEAN_CHECKOUT_FORCE_FAILURE", "1"}
                   ],
                   stderr_to_stdout: true
                 )

        assert status != 0
        assert output =~ "forced failure control"
        assert File.read!(sentinel) == sentinel_bytes

        assert Path.wildcard(Path.join(temp_root, "threadline-clean-checkout-*")) == []

        {head_after, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: @root)
        {status_after, 0} = checkout_status()
        assert head_after == head_before
        assert status_after == status_before
      after
        File.rm_rf!(temp_root)
      end
    end
  end

  defp run_cleanup(parent, child, mutation \\ "", env \\ []) do
    script = """
    set -u
    source #{shell_quote(Path.join(@root, "bin/safe-temp-tree"))}
    safe_temp_tree_register #{shell_quote(parent)} #{shell_quote(child)}
    #{mutation}
    safe_temp_tree_cleanup #{shell_quote(parent)} #{shell_quote(child)}
    """

    System.cmd("bash", ["-c", script], cd: @root, env: env, stderr_to_stdout: true)
  end

  defp with_temp_parent(fun) do
    raw_parent = unique_temp_path("threadline-safe-parent")
    File.mkdir!(raw_parent)
    parent = canonical_path(raw_parent)

    try do
      fun.(parent)
    after
      File.rm_rf!(parent)
    end
  end

  defp unique_temp_path(prefix) do
    Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive, :monotonic])}")
  end

  defp canonical_path(path) do
    {canonical, 0} = System.cmd("realpath", [path])
    String.trim(canonical)
  end

  defp checkout_status do
    System.cmd("git", ["status", "--porcelain=v1", "--untracked-files=all"], cd: @root)
  end

  defp shell_quote(value), do: "'#{String.replace(value, "'", "'\\''")}'"
end
