defmodule Threadline.RepoHygieneGuardTest do
  @moduledoc """
  Offline behavior matrix for `bin/verify-repo-hygiene`, driven against
  runtime-built fixture repos through the REPO_HYGIENE_ROOT env seam. Every
  fixture path is assembled at runtime by string concatenation, so this
  file's own text never contains a matchable home-directory literal — a
  future scrub of the tracked tree must never need to touch this file.
  """
  use ExUnit.Case, async: true
  @moduletag :tmp_dir

  @script Path.expand("../../bin/verify-repo-hygiene", __DIR__)

  # Builds a fresh git repo under `tmp_dir/repo`, writes each `path =>
  # contents` pair, and `git add`s exactly those paths (no commit needed —
  # `git grep` searches tracked work-tree files, not history).
  defp fixture_repo!(tmp_dir, files) do
    root = Path.join(tmp_dir, "repo")
    File.mkdir_p!(root)

    for {rel_path, contents} <- files do
      full = Path.join(root, rel_path)
      File.mkdir_p!(Path.dirname(full))
      File.write!(full, contents)
    end

    {_, 0} = System.cmd("git", ["init", "-q"], cd: root)
    {_, 0} = System.cmd("git", ["add", "--"] ++ Map.keys(files), cd: root)
    root
  end

  defp run_guard(root, env \\ []) do
    System.cmd(@script, [],
      env: [{"REPO_HYGIENE_ROOT", root}, {"GIT_TERMINAL_PROMPT", "0"}] ++ env,
      stderr_to_stdout: true
    )
  end

  # "/" <> "Users" <> "/" <> "fixture-user", assembled at runtime per the
  # ci_workflow_parity_contract_test.exs self-referential-safety convention.
  @fake_macos_home "/" <> "Users" <> "/" <> "fixture-user"

  test "one macOS-home hit goes red end-to-end with a HIT file:line: token report", %{
    tmp_dir: tmp_dir
  } do
    root =
      fixture_repo!(tmp_dir, %{
        "notes.md" => "line one\n#{@fake_macos_home}/code\nline three\n"
      })

    assert {output, 1} = run_guard(root)
    assert output =~ "HIT notes.md:2:"
    assert output =~ @fake_macos_home
  end

  test "the same fixture without that line is clean", %{tmp_dir: tmp_dir} do
    root =
      fixture_repo!(tmp_dir, %{
        "notes.md" => "line one\nline two\nline three\n"
      })

    assert {output, 0} = run_guard(root)
    assert output =~ "tracked text file(s) clean"
  end
end
