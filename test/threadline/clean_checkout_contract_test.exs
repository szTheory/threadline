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
        outside_sentinel = Path.join(outside, "sentinel")
        File.mkdir!(outside)
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
      with_temp_parent(fn parent ->
        linked = Path.join(parent, "registered-worktree")

        assert {_output, 0} =
                 System.cmd("git", ["worktree", "add", "--detach", linked, "HEAD"],
                   cd: @root,
                   stderr_to_stdout: true
                 )

        sentinel = Path.join(linked, "sentinel.bin")
        sentinel_bytes = <<0, 1, 2, 253, 254, 255>>
        File.write!(sentinel, sentinel_bytes)

        on_exit(fn ->
          System.cmd("git", ["worktree", "remove", "--force", linked],
            cd: @root,
            stderr_to_stdout: true
          )
        end)

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
      end)
    end
  end

  defp run_cleanup(parent, child, mutation \\ "") do
    script = """
    set -u
    source #{shell_quote(Path.join(@root, "bin/safe-temp-tree"))}
    safe_temp_tree_register #{shell_quote(parent)} #{shell_quote(child)}
    #{mutation}
    safe_temp_tree_cleanup #{shell_quote(parent)} #{shell_quote(child)}
    """

    System.cmd("bash", ["-c", script], cd: @root, stderr_to_stdout: true)
  end

  defp with_temp_parent(fun) do
    parent = unique_temp_path("threadline-safe-parent")
    File.mkdir!(parent)

    try do
      fun.(parent)
    after
      File.rm_rf!(parent)
    end
  end

  defp unique_temp_path(prefix) do
    Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive, :monotonic])}")
  end

  defp shell_quote(value), do: "'#{String.replace(value, "'", "'\\''")}'"
end
