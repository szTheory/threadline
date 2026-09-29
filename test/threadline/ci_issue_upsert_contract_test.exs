defmodule Threadline.CiIssueUpsertContractTest do
  use ExUnit.Case, async: true
  @script Path.expand("../../bin/upsert-ci-issue", __DIR__)

  defp fixture(list_json, root \\ nil) do
    root =
      root || Path.join(System.tmp_dir!(), "ci_upsert_#{System.unique_integer([:positive])}")

    File.mkdir_p!(root)
    log = Path.join(root, "calls")
    args_log = Path.join(root, "args")
    state = Path.join(root, "list.json")
    body = Path.join(root, "body.md")
    gh = Path.join(root, "gh")
    File.write!(state, list_json)
    File.write!(body, "body with `code` and\nmultiple lines\n")

    File.write!(gh, """
    #!/usr/bin/env bash
    set -eu
    printf '%s\n' "$*" >> "$CALL_LOG"
    { printf -- '--call--\n'; for a in "$@"; do printf '%s\n' "$a"; done; } >> "$ARGS_LOG"
    if [ "$1 $2" = "issue list" ]; then cat "$LIST_JSON"; exit 0; fi
    if [ "$1 $2" = "issue create" ]; then printf '%s\n' 'https://example.test/issues/41'; exit 0; fi
    if [ "$1 $2" = "issue comment" ] || [ "$1 $2" = "label create" ]; then exit 0; fi
    if [ "$1 $2" = "issue close" ]; then exit 0; fi
    exit 9
    """)

    File.chmod!(gh, 0o755)
    on_exit(fn -> File.rm_rf!(root) end)
    %{gh: gh, log: log, args_log: args_log, state: state, body: body}
  end

  defp run(f, marker \\ "Lane: stable") do
    System.cmd(
      @script,
      [
        "--marker",
        marker,
        "--title",
        marker <> " failed",
        "--body-file",
        f.body,
        "--label",
        "ci-test"
      ],
      env: env(f),
      stderr_to_stdout: true
    )
  end

  defp env(f),
    do: [
      {"GH_BIN", f.gh},
      {"CALL_LOG", f.log},
      {"ARGS_LOG", f.args_log},
      {"LIST_JSON", f.state}
    ]

  # Close mode takes no --title (D-06): closing names an existing issue.
  defp run_close(f, marker \\ "Lane: stable") do
    System.cmd(
      @script,
      ["--close", "--marker", marker, "--label", "ci-test", "--body-file", f.body],
      env: env(f),
      stderr_to_stdout: true
    )
  end

  defp calls(f), do: if(File.exists?(f.log), do: File.read!(f.log), else: "")

  test "zero matches creates and one exact match updates" do
    f = fixture("[]")
    assert {out, 0} = run(f)
    assert out =~ "action=create"
    File.write!(f.state, ~s([{"number":41,"title":"Lane: stable failed"}]))
    File.write!(f.log, "")
    assert {out, 0} = run(f)
    assert out =~ "action=update"
    assert File.read!(f.log) =~ "issue comment 41"
    refute File.read!(f.log) =~ "issue create"
  end

  test "ambiguous matches fail closed" do
    f = fixture(~s([{"number":1,"title":"Lane: stable a"},{"number":2,"title":"Lane: stable b"}]))
    assert {out, status} = run(f)
    assert status != 0
    assert out =~ "ambiguous marker"
  end

  test "marker metacharacters remain argv data and malformed JSON fails" do
    marker = "Lane: $(touch /tmp/never-threadline) [x]"
    f = fixture("[]")
    assert {_out, 0} = run(f, marker)
    refute File.exists?("/tmp/never-threadline")
    File.write!(f.state, "not-json")
    assert {_out, status} = run(f, marker)
    assert status != 0
  end

  describe "--close" do
    @describetag :tmp_dir

    test "zero matches prints action=none and writes nothing", %{tmp_dir: tmp_dir} do
      f = fixture("[]", tmp_dir)
      assert {out, 0} = run_close(f)
      assert out =~ "action=none"
      refute calls(f) =~ "issue comment"
      refute calls(f) =~ "issue close"
      refute calls(f) =~ "label create"
    end

    test "exactly one match comments then closes as completed", %{tmp_dir: tmp_dir} do
      f = fixture(~s([{"number":41,"title":"Lane: stable failed"}]), tmp_dir)
      assert {out, 0} = run_close(f)
      assert out =~ "action=close"
      assert out =~ "issue_number=41"
      log = calls(f)
      assert log =~ "issue comment 41 --body-file"
      assert log =~ "issue close 41 --reason completed"
      {comment_at, _} = :binary.match(log, "issue comment 41")
      {close_at, _} = :binary.match(log, "issue close 41")
      assert comment_at < close_at, "the citing comment must be posted before the close"
      refute log =~ "label create"
    end

    test "more than one match fails closed and closes nothing", %{tmp_dir: tmp_dir} do
      f =
        fixture(
          ~s([{"number":1,"title":"Lane: stable a"},{"number":2,"title":"Lane: stable b"}]),
          tmp_dir
        )

      assert {out, 1} = run_close(f)
      assert out =~ "ambiguous marker matched 2 open issues"
      refute calls(f) =~ "issue close"
      refute calls(f) =~ "issue comment"
    end

    test "marker metacharacters stay one argv element in close mode", %{tmp_dir: tmp_dir} do
      pwned = Path.join(tmp_dir, "pwned")
      marker = "Lane: $(touch #{pwned}) `touch #{pwned}` [x]"
      f = fixture(~s([{"number":7,"title":"#{marker} failed"}]), tmp_dir)
      assert {out, 0} = run_close(f, marker)
      assert out =~ "action=close"
      refute File.exists?(pwned)
      assert File.read!(f.args_log) |> String.split("\n") |> Enum.member?(marker <> " in:title")
    end

    test "--title is optional but --label and --body-file are still required", %{
      tmp_dir: tmp_dir
    } do
      f = fixture("[]", tmp_dir)

      assert {_out, 0} = run_close(f)

      assert {out, 1} =
               System.cmd(@script, ["--close", "--marker", "M", "--body-file", f.body],
                 env: env(f),
                 stderr_to_stdout: true
               )

      assert out =~ "--label is required"

      assert {out, 1} =
               System.cmd(@script, ["--close", "--marker", "M", "--label", "ci-test"],
                 env: env(f),
                 stderr_to_stdout: true
               )

      assert out =~ "--body-file must name a readable file"
    end
  end
end
