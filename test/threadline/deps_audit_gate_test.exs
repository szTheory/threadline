defmodule Threadline.DepsAuditGateTest do
  @moduledoc """
  Offline behavior tests of `bin/verify-deps-audit`, driven through a fake
  `mix` binary (the `MIX_BIN` seam) so the full matrix runs in the default
  `mix test` lane with no network access. The network-backed positive proof
  (a real advisory, a real old Hex refusal) is `bin/verify-deps-audit
  --self-test`, exercised as a step in the `verify-deps-audit` CI job.
  """
  use ExUnit.Case, async: true

  @script Path.expand("../../bin/verify-deps-audit", __DIR__)

  defp tmp_root do
    root = Path.join(System.tmp_dir!(), "deps_audit_gate_#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    root
  end

  # Fake `mix`: logs `<cwd>|<args>` to CALL_LOG, prints FAKE_HEX_INFO (if any)
  # for `hex.info`, prints a fake `hex.config KEY` answer for `hex.config`, and
  # exits 1 when `<basename of cwd>:<subcommand>` is one of the comma-separated
  # FAKE_FAIL tokens. Exits 0 otherwise.
  #
  # hex.config KEY: prints FAKE_HEX_CONFIG_PREFIX (a warning line) first, if
  # set; then the value of FAKE_HEX_CONFIG_IGNORE_ADVISORIES for key
  # ignore_advisories or FAKE_HEX_CONFIG_IGNORE_RETIREMENTS for key
  # ignore_retirements, using bash's unset-only default expansion so an UNSET
  # var prints `[]` (clean). The literal sentinel `__NOOUTPUT__` prints
  # nothing at all for that key instead (used by the fail-closed "hex.config
  # prints nothing" tests) — a real empty-string env value cannot be
  # delivered through `System.cmd`'s `:env` option, which drops zero-length
  # values entirely rather than passing them through, so this sentinel is the
  # only way to exercise that fail-closed path from Elixir. Exits
  # FAKE_HEX_CONFIG_EXIT (default 0).
  defp fake_mix(root) do
    path = Path.join(root, "mix")

    File.write!(path, """
    #!/usr/bin/env bash
    set -u
    printf '%s|%s\\n' "$(pwd)" "$*" >> "$CALL_LOG"
    cmd="$1"
    if [ "$cmd" = "hex.info" ]; then
      if [ -n "${FAKE_HEX_INFO:-}" ]; then
        printf '%s\\n' "$FAKE_HEX_INFO"
      fi
      exit 0
    fi
    if [ "$cmd" = "hex.config" ]; then
      key="${2:-}"
      if [ -n "${FAKE_HEX_CONFIG_PREFIX:-}" ]; then
        printf '%s\\n' "$FAKE_HEX_CONFIG_PREFIX"
      fi
      if [ "$key" = "ignore_advisories" ]; then
        val="${FAKE_HEX_CONFIG_IGNORE_ADVISORIES-[]}"
        [ "$val" = "__NOOUTPUT__" ] || printf '%s\\n' "$val"
      elif [ "$key" = "ignore_retirements" ]; then
        val="${FAKE_HEX_CONFIG_IGNORE_RETIREMENTS-[]}"
        [ "$val" = "__NOOUTPUT__" ] || printf '%s\\n' "$val"
      fi
      exit "${FAKE_HEX_CONFIG_EXIT:-0}"
    fi
    base=$(basename "$(pwd)")
    key="$base:$cmd"
    case ",${FAKE_FAIL:-}," in
      *",$key,"*) exit 1 ;;
    esac
    exit 0
    """)

    File.chmod!(path, 0o755)
    path
  end

  defp project_dir(root, name) do
    dir = Path.join(root, name)
    File.mkdir_p!(dir)
    File.write!(Path.join(dir, "mix.exs"), "")
    File.write!(Path.join(dir, "mix.lock"), "")
    dir
  end

  defp call_log(root) do
    log = Path.join(root, "call_log_#{System.unique_integer([:positive])}")
    File.write!(log, "")
    log
  end

  defp run(args, env, root) do
    mix = fake_mix(root)
    log = call_log(root)

    base_env = [
      {"MIX_BIN", mix},
      {"CALL_LOG", log},
      {"FAKE_HEX_INFO", "Hex:    2.5.1"},
      {"FAKE_FAIL", ""},
      {"HEX_IGNORE_ADVISORIES", ""},
      {"HEX_IGNORE_RETIREMENTS", ""}
    ]

    full_env =
      Enum.reduce(env, base_env, fn {k, v}, acc ->
        [{k, v} | Enum.reject(acc, fn {ek, _} -> ek == k end)]
      end)

    {out, status} = System.cmd(@script, args, env: full_env, stderr_to_stdout: true)
    {out, status, File.read!(log)}
  end

  test "clean run over three dirs: exit 0, CALL_LOG order is hex.info then per-dir deps.get/deps.unlock/hex.audit" do
    root = tmp_root()
    d1 = project_dir(root, "one")
    d2 = project_dir(root, "two")
    d3 = project_dir(root, "three")

    {_out, status, log} = run([d1, d2, d3], [], root)

    assert status == 0
    lines = log |> String.trim() |> String.split("\n")

    calls =
      Enum.map(lines, fn line ->
        [_pwd, args] = String.split(line, "|", parts: 2)
        args
      end)

    assert calls == [
             "hex.info",
             "hex.config ignore_advisories",
             "hex.config ignore_retirements",
             "deps.get",
             "deps.unlock --check-unused",
             "hex.audit",
             "deps.get",
             "deps.unlock --check-unused",
             "hex.audit",
             "deps.get",
             "deps.unlock --check-unused",
             "hex.audit"
           ]
  end

  test "Hex 2.10.0 passes the floor check (numeric, not lexical, comparison)" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {_out, status, _log} = run([d1], [{"FAKE_HEX_INFO", "Hex:    2.10.0"}], root)

    assert status == 0
  end

  for version <- ["2.5.0", "2.4.9", "1.99.99"] do
    test "Hex #{version} fails the floor check before any audit runs" do
      root = tmp_root()
      d1 = project_dir(root, "one")
      version = unquote(version)

      {out, status, log} = run([d1], [{"FAKE_HEX_INFO", "Hex:    #{version}"}], root)

      assert status != 0
      assert out =~ "requires Hex >= 2.5.1"
      assert out =~ version
      assert String.trim(log) == "#{root}|hex.info" or String.contains?(log, "|hex.info")
      refute log =~ "deps.get"
      refute log =~ "hex.audit"
    end
  end

  test "unparseable hex.info output fails closed" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {out, status, log} = run([d1], [{"FAKE_HEX_INFO", ""}], root)

    assert status != 0
    assert out =~ "could not determine Hex version"
    refute log =~ "deps.get"
  end

  test "hex.audit failing in the 2nd of 3 dirs is aggregated, not fail-fast" do
    root = tmp_root()
    d1 = project_dir(root, "one")
    d2 = project_dir(root, "two")
    d3 = project_dir(root, "three")

    {out, status, log} = run([d1, d2, d3], [{"FAKE_FAIL", "two:hex.audit"}], root)

    assert status != 0
    assert out =~ "two"
    assert out =~ "hex.audit"
    assert log =~ "three|hex.audit"
  end

  test "deps.unlock --check-unused failing in one dir names the dir and check-unused" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {out, status, _log} = run([d1], [{"FAKE_FAIL", "one:deps.unlock"}], root)

    assert status != 0
    assert out =~ "one"
    assert out =~ "check-unused"
  end

  test "deps.get failing in one dir skips that dir's hex.audit (vacuous audit avoided)" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {out, status, log} = run([d1], [{"FAKE_FAIL", "one:deps.get"}], root)

    assert status != 0
    assert out =~ "one"
    assert out =~ "deps.get"
    refute log =~ "hex.audit"
  end

  test "HEX_IGNORE_ADVISORIES non-empty exits non-zero before any mix call, naming the variable" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {out, status, log} = run([d1], [{"HEX_IGNORE_ADVISORIES", "x"}], root)

    assert status != 0
    assert out =~ "HEX_IGNORE_ADVISORIES"
    assert String.trim(log) == ""
  end

  test "HEX_IGNORE_RETIREMENTS non-empty exits non-zero before any mix call, naming the variable" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {out, status, log} = run([d1], [{"HEX_IGNORE_RETIREMENTS", "x"}], root)

    assert status != 0
    assert out =~ "HEX_IGNORE_RETIREMENTS"
    assert String.trim(log) == ""
  end

  @real_root Path.expand("../..", __DIR__)

  test "a non-empty global hex.config ignore_advisories exits non-zero before any audit call, naming the key" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {out, status, log} =
      run([d1], [{"FAKE_HEX_CONFIG_IGNORE_ADVISORIES", ~s(["EEF-CVE-2026-54892"])}], root)

    assert status != 0
    assert out =~ "ignore_advisories"
    refute log =~ "deps.get"
    refute log =~ "hex.audit"
  end

  test "a non-empty global hex.config ignore_retirements exits non-zero before any audit call, naming the key" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {out, status, log} =
      run([d1], [{"FAKE_HEX_CONFIG_IGNORE_RETIREMENTS", ~s([{"plug", nil}])}], root)

    assert status != 0
    assert out =~ "ignore_retirements"
    refute log =~ "deps.get"
    refute log =~ "hex.audit"
  end

  for {key, env_key} <- [
        {"ignore_advisories", "FAKE_HEX_CONFIG_IGNORE_ADVISORIES"},
        {"ignore_retirements", "FAKE_HEX_CONFIG_IGNORE_RETIREMENTS"}
      ] do
    test "hex.config #{key} printing nothing fails closed, naming the key" do
      root = tmp_root()
      d1 = project_dir(root, "one")
      env_key = unquote(env_key)

      {out, status, log} = run([d1], [{env_key, "__NOOUTPUT__"}], root)

      assert status != 0
      assert out =~ "could not read global Hex config"
      refute log =~ "deps.get"
    end

    test "hex.config #{key} printing a non-list word fails closed" do
      root = tmp_root()
      d1 = project_dir(root, "one")
      env_key = unquote(env_key)

      {out, status, log} = run([d1], [{env_key, "nope"}], root)

      assert status != 0
      assert out =~ "could not read global Hex config"
      refute log =~ "deps.get"
    end

    test "hex.config #{key} exiting non-zero fails closed" do
      root = tmp_root()
      d1 = project_dir(root, "one")
      env_key = unquote(env_key)

      {out, status, log} = run([d1], [{env_key, "[]"}, {"FAKE_HEX_CONFIG_EXIT", "1"}], root)

      assert status != 0
      assert out =~ "could not read global Hex config"
      refute log =~ "deps.get"
    end
  end

  test "a warning line before the final [] line is tolerated (clean, gate proceeds)" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {_out, status, _log} = run([d1], [{"FAKE_HEX_CONFIG_PREFIX", "warning: something"}], root)

    assert status == 0
  end

  test "the hex.config query runs from a neutral, mix.exs-free dir under tmp/, removed afterwards" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {_out, status, log} = run([d1], [], root)

    assert status == 0
    lines = log |> String.trim() |> String.split("\n")

    config_pwds =
      lines
      |> Enum.filter(&String.contains?(&1, "|hex.config"))
      |> Enum.map(fn line -> line |> String.split("|", parts: 2) |> hd() end)

    assert length(config_pwds) == 2

    for pwd <- config_pwds do
      assert String.starts_with?(pwd, Path.join(@real_root, "tmp") <> "/")
      refute pwd == @real_root
      refute pwd == d1
    end

    assert Path.wildcard(Path.join(@real_root, "tmp/deps-audit-hex-config.*")) == []
  end

  test "a directory argument that does not exist is a non-zero exit naming it" do
    root = tmp_root()
    missing = Path.join(root, "does-not-exist")

    {out, status, _log} = run([missing], [], root)

    assert status != 0
    assert out =~ missing
  end

  test "a directory without mix.lock is a non-zero exit naming it" do
    root = tmp_root()
    dir = Path.join(root, "no-lock")
    File.mkdir_p!(dir)
    File.write!(Path.join(dir, "mix.exs"), "")

    {out, status, _log} = run([dir], [], root)

    assert status != 0
    assert out =~ dir
  end

  test "the same directory given twice is a non-zero exit containing duplicate" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {out, status, log} = run([d1, d1], [], root)

    assert status != 0
    assert out =~ "duplicate"
    assert String.trim(log) == ""
  end

  test "no arguments audits exactly the three canonical directories in order" do
    real_root = Path.expand("../..", __DIR__)
    log = Path.join(System.tmp_dir!(), "call_log_canonical_#{System.unique_integer([:positive])}")
    File.write!(log, "")
    on_exit(fn -> File.rm(log) end)

    fake_dir =
      Path.join(System.tmp_dir!(), "deps_audit_fake_mix_#{System.unique_integer([:positive])}")

    File.mkdir_p!(fake_dir)
    on_exit(fn -> File.rm_rf!(fake_dir) end)
    mix = fake_mix(fake_dir)

    env = [
      {"MIX_BIN", mix},
      {"CALL_LOG", log},
      {"FAKE_HEX_INFO", "Hex:    2.5.1"},
      {"FAKE_FAIL", ""},
      {"HEX_IGNORE_ADVISORIES", ""},
      {"HEX_IGNORE_RETIREMENTS", ""}
    ]

    {_out, status} = System.cmd(@script, [], env: env, cd: real_root, stderr_to_stdout: true)

    assert status == 0
    contents = File.read!(log)
    lines = contents |> String.trim() |> String.split("\n")
    pwds = Enum.map(lines, fn line -> line |> String.split("|", parts: 2) |> hd() end)

    # First three lines are hex.info + hex.config ignore_advisories +
    # hex.config ignore_retirements (all run in ROOT); the next three groups
    # of three (deps.get / deps.unlock / hex.audit) are the canonical dirs.
    dir_pwds = pwds |> Enum.drop(3) |> Enum.take_every(3)

    assert Enum.at(dir_pwds, 0) |> String.ends_with?(real_root)
    assert Enum.at(dir_pwds, 1) |> String.ends_with?("/bench")
    assert Enum.at(dir_pwds, 2) |> String.ends_with?("/examples/threadline_phoenix")
  end
end
