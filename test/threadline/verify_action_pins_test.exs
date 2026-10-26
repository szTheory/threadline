defmodule Threadline.VerifyActionPinsTest do
  @moduledoc """
  245-04 (SUP-02, D-14b): the behavior table for `bin/verify-action-pins`,
  driven through a fake `gh` (GH_BIN seam) against synthetic workflow trees,
  so no row touches the network.

  The load-bearing rule is fail-closed: a gh error, a garbage answer, a
  non-canonical ref or an empty tree never exits 0. Only an explicit match for
  every distinct pin passes.
  """
  use ExUnit.Case, async: true
  @moduletag :repo_contract
  @moduletag :tmp_dir

  @script Path.expand("../../bin/verify-action-pins", __DIR__)
  @pin "fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09"
  @other "1111111111111111111111111111111111111111"
  @tag_obj "2222222222222222222222222222222222222222"

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
    [ "$3" = "--jq" ] || exit 9
    ans=$(awk -v k="$2" '$1 == k { $1 = ""; sub(/^ /, ""); print; found = 1; exit } END { exit !found }' "$FAKE_LOOKUP") || exit 9
    printf '%s\\n' "$ans"
    """)

    File.chmod!(gh, 0o755)
    gh
  end

  defp tree!(tmp_dir, workflows) do
    root = Path.join(tmp_dir, "root")
    dir = Path.join(root, ".github/workflows")
    File.mkdir_p!(dir)
    for {name, body} <- workflows, do: File.write!(Path.join(dir, name), body)
    root
  end

  defp workflow(uses_lines) do
    steps = Enum.map_join(uses_lines, "\n", &"      - uses: #{&1}")

    """
    name: t
    on: push
    jobs:
      j:
        runs-on: ubuntu-latest
        steps:
    #{steps}
    """
  end

  defp run_pins(tmp_dir, root, lookup, mode \\ "") do
    gh = fake_gh!(tmp_dir)
    call_log = Path.join(tmp_dir, "calls")
    lookup_file = Path.join(tmp_dir, "lookup")

    File.write!(lookup_file, Enum.map_join(lookup, "", fn {k, v} -> "#{k} #{v}\n" end))

    env = [
      {"GH_BIN", gh},
      {"CALL_LOG", call_log},
      {"FAKE_LOOKUP", lookup_file},
      {"FAKE_GH_MODE", mode}
    ]

    {out, status} = System.cmd(@script, ["--root", root], env: env, stderr_to_stdout: true)
    calls = if File.exists?(call_log), do: File.read!(call_log), else: ""
    %{out: out, status: status, calls: String.split(calls, "\n", trim: true)}
  end

  defp ref_key(repo, tag), do: "repos/#{repo}/git/ref/tags/#{tag}"
  defp tag_key(repo, sha), do: "repos/#{repo}/git/tags/#{sha}"

  @checkout "actions/checkout@#{@pin} # v5.1.0"

  test "lightweight tag whose commit is the pin -> exit 0, one lookup", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow([@checkout])}])
    r = run_pins(t, root, [{ref_key("actions/checkout", "v5.1.0"), "commit #{@pin}"}])

    assert r.status == 0, r.out
    assert r.out =~ "verify-action-pins: 1 pin(s) match their tags"

    assert r.calls == [
             "api #{ref_key("actions/checkout", "v5.1.0")} --jq .object.type+\" \"+.object.sha"
           ]
  end

  test "annotated tag dereferenced to the pin -> exit 0, second git/tags lookup", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow([@checkout])}])

    r =
      run_pins(t, root, [
        {ref_key("actions/checkout", "v5.1.0"), "tag #{@tag_obj}"},
        {tag_key("actions/checkout", @tag_obj), @pin}
      ])

    assert r.status == 0, r.out
    assert length(r.calls) == 2
    assert Enum.at(r.calls, 1) == "api #{tag_key("actions/checkout", @tag_obj)} --jq .object.sha"
  end

  test "tag resolving to a different commit -> exit 1 MISMATCH", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow([@checkout])}])
    r = run_pins(t, root, [{ref_key("actions/checkout", "v5.1.0"), "commit #{@other}"}])

    assert r.status == 1
    assert r.out =~ "MISMATCH actions/checkout@v5.1.0: pinned #{@pin} resolves to #{@other}"
    refute r.out =~ "match their tags"
  end

  test "annotated tag dereferencing to a different commit -> exit 1 MISMATCH", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow([@checkout])}])

    r =
      run_pins(t, root, [
        {ref_key("actions/checkout", "v5.1.0"), "tag #{@tag_obj}"},
        {tag_key("actions/checkout", @tag_obj), @other}
      ])

    assert r.status == 1
    assert r.out =~ "MISMATCH actions/checkout@v5.1.0"
  end

  test "gh exits non-zero -> exit 1 UNVERIFIED, never a pass", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow([@checkout])}])
    r = run_pins(t, root, [], "fail")

    assert r.status == 1
    assert r.out =~ "UNVERIFIED actions/checkout@v5.1.0"
    assert r.out =~ "HTTP 403"
  end

  test "gh answers garbage -> exit 1 UNVERIFIED", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow([@checkout])}])
    r = run_pins(t, root, [], "garbage")

    assert r.status == 1
    assert r.out =~ "UNVERIFIED actions/checkout@v5.1.0"
  end

  test "annotated tag lookup answering garbage -> exit 1 UNVERIFIED", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow([@checkout])}])

    r =
      run_pins(t, root, [
        {ref_key("actions/checkout", "v5.1.0"), "tag #{@tag_obj}"},
        {tag_key("actions/checkout", @tag_obj), "null"}
      ])

    assert r.status == 1
    assert r.out =~ "UNVERIFIED actions/checkout@v5.1.0"
  end

  test "unknown tag (fake exits 9, like a 404) -> exit 1 UNVERIFIED", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow([@checkout])}])
    r = run_pins(t, root, [])

    assert r.status == 1
    assert r.out =~ "UNVERIFIED actions/checkout@v5.1.0"
  end

  test "a tag-only ref -> exit 1 NOT-PINNED with file:line", %{tmp_dir: t} do
    tag_only = "actions/checkout" <> "@" <> "v5"
    root = tree!(t, [{"a.yml", workflow([@checkout, tag_only])}])
    r = run_pins(t, root, [{ref_key("actions/checkout", "v5.1.0"), "commit #{@pin}"}])

    assert r.status == 1
    assert r.out =~ "NOT-PINNED .github/workflows/a.yml:8"
  end

  test "a SHA with no comment -> exit 1 NOT-PINNED", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow(["actions/checkout@#{@pin}"])}])
    r = run_pins(t, root, [])

    assert r.status == 1
    assert r.out =~ "NOT-PINNED"
    assert r.calls == []
  end

  test "an injected tag comment never reaches gh", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow(["actions/checkout@#{@pin} # v1.0.0;x"])}])
    r = run_pins(t, root, [])

    assert r.status == 1
    assert r.out =~ "NOT-PINNED"
    assert r.calls == []
  end

  test "an invalid repo segment never reaches gh", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow(["act$ions/checkout@#{@pin} # v5.1.0"])}])
    r = run_pins(t, root, [])

    assert r.status == 1
    assert r.out =~ "NOT-PINNED"
    assert r.calls == []
  end

  test "a quoted ref -> exit 1 NOT-PINNED", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow([~s("actions/checkout@#{@pin}" # v5.1.0)])}])
    r = run_pins(t, root, [])

    assert r.status == 1
    assert r.out =~ "NOT-PINNED"
  end

  test "an empty scan dir -> exit 2", %{tmp_dir: t} do
    root = tree!(t, [])
    r = run_pins(t, root, [])

    assert r.status == 2
    assert r.calls == []
  end

  test "a tree with only local refs -> exit 2 (vacuous)", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow(["./.github/actions/x"])}])
    r = run_pins(t, root, [])

    assert r.status == 2
  end

  test "local refs and full-line comments are skipped", %{tmp_dir: t} do
    body = workflow(["./.github/actions/x", @checkout]) <> "      # - uses: actions/checkout@v5\n"
    root = tree!(t, [{"a.yml", body}])
    r = run_pins(t, root, [{ref_key("actions/checkout", "v5.1.0"), "commit #{@pin}"}])

    assert r.status == 0, r.out
    assert r.out =~ "1 pin(s) match their tags"
  end

  test "same (repo, tag, sha) in many steps and files, and sub-path actions -> one lookup",
       %{tmp_dir: t} do
    cache = "caa296126883cff596d87d8935842f9db880ef25"

    refs = [
      "actions/cache@#{cache} # v5.1.0",
      "actions/cache/restore@#{cache} # v5.1.0",
      "actions/cache/save@#{cache} # v5.1.0"
    ]

    root = tree!(t, [{"a.yml", workflow(refs)}, {"b.yaml", workflow(refs)}])
    r = run_pins(t, root, [{ref_key("actions/cache", "v5.1.0"), "commit #{cache}"}])

    assert r.status == 0, r.out
    assert r.out =~ "1 pin(s) match their tags"
    assert length(r.calls) == 1
  end

  test "composite actions under .github/actions are scanned", %{tmp_dir: t} do
    root = tree!(t, [{"a.yml", workflow([@checkout])}])
    action_dir = Path.join(root, ".github/actions/setup")
    File.mkdir_p!(action_dir)

    File.write!(Path.join(action_dir, "action.yml"), """
    runs:
      using: composite
      steps:
        - uses: actions/setup-node@#{@other} # v5.0.0
    """)

    r = run_pins(t, root, [{ref_key("actions/checkout", "v5.1.0"), "commit #{@pin}"}])

    assert r.status == 1
    assert r.out =~ "UNVERIFIED actions/setup-node@v5.0.0"
  end

  test "one failing pin among passing pins still fails the run", %{tmp_dir: t} do
    node = "actions/setup-node@#{@other} # v5.0.0"
    root = tree!(t, [{"a.yml", workflow([@checkout, node])}])

    r =
      run_pins(t, root, [
        {ref_key("actions/checkout", "v5.1.0"), "commit #{@pin}"},
        {ref_key("actions/setup-node", "v5.0.0"), "commit #{@pin}"}
      ])

    assert r.status == 1
    assert r.out =~ "MISMATCH actions/setup-node@v5.0.0"
    refute r.out =~ "MISMATCH actions/checkout"
  end

  test "usage errors exit 2" do
    {_, status} = System.cmd(@script, ["--bogus"], stderr_to_stdout: true)
    assert status == 2

    {_, status} =
      System.cmd(@script, ["--root", "/nonexistent-verify-action-pins"], stderr_to_stdout: true)

    assert status == 2
  end
end
