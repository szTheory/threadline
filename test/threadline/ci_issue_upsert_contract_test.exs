defmodule Threadline.CiIssueUpsertContractTest do
  use ExUnit.Case, async: true
  @script Path.expand("../../bin/upsert-ci-issue", __DIR__)

  defp fixture(list_json) do
    root = Path.join(System.tmp_dir!(), "ci_upsert_#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    log = Path.join(root, "calls")
    state = Path.join(root, "list.json")
    body = Path.join(root, "body.md")
    gh = Path.join(root, "gh")
    File.write!(state, list_json)
    File.write!(body, "body with `code` and\nmultiple lines\n")

    File.write!(gh, """
    #!/usr/bin/env bash
    set -eu
    printf '%s\n' "$*" >> "$CALL_LOG"
    if [ "$1 $2" = "issue list" ]; then cat "$LIST_JSON"; exit 0; fi
    if [ "$1 $2" = "issue create" ]; then printf '%s\n' 'https://example.test/issues/41'; exit 0; fi
    if [ "$1 $2" = "issue comment" ] || [ "$1 $2" = "label create" ]; then exit 0; fi
    exit 9
    """)

    File.chmod!(gh, 0o755)
    on_exit(fn -> File.rm_rf!(root) end)
    %{gh: gh, log: log, state: state, body: body}
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
      env: [{"GH_BIN", f.gh}, {"CALL_LOG", f.log}, {"LIST_JSON", f.state}],
      stderr_to_stdout: true
    )
  end

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
end
