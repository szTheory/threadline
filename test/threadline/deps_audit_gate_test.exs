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
  @real_root Path.expand("../..", __DIR__)

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
  #
  # deps.get: for a dir whose basename is one of the comma-separated
  # FAKE_LOCK_DRIFT tokens, `deps.get --check-locked` prints Mix's real
  # out-of-date-lock message and exits 1, while plain `deps.get` (no
  # --check-locked) exits 0 — mirroring real Mix, which silently re-resolves
  # a drifted lock instead of refusing it.
  #
  # deps.tree (SUP-03): prints a `--format plain` tree of FAKE_TREE_<base>
  # (default `telemetry`; `__EMPTY__` for an empty closure); `<base>:deps.tree`
  # in FAKE_FAIL exits 1. hex.audit --format sarif --output P builds a Hex
  # 2.6.0-shaped SARIF at P from FAKE_SARIF_<base> (see the inline comment).
  # <base> is the dir basename with `/`, `.` and `-` mapped to `_`.
  defp fake_mix(root) do
    path = Path.join(root, "mix")

    File.write!(path, ~S"""
    #!/usr/bin/env bash
    set -u
    printf '%s|%s\n' "$(pwd)" "$*" >> "$CALL_LOG"
    cmd="$1"
    base=$(basename "$(pwd)")
    # Env-key form of the dir basename: `/`, `.` and `-` become `_`.
    key_base=$(printf '%s' "$base" | tr '/.-' '___')
    knob() {
      eval "printf '%s' \"\${$1_$key_base-}\""
    }
    if [ "$cmd" = "hex.info" ]; then
      if [ -n "${FAKE_HEX_INFO:-}" ]; then
        printf '%s\n' "$FAKE_HEX_INFO"
      fi
      exit 0
    fi
    if [ "$cmd" = "hex.config" ]; then
      key="${2:-}"
      if [ -n "${FAKE_HEX_CONFIG_PREFIX:-}" ]; then
        printf '%s\n' "$FAKE_HEX_CONFIG_PREFIX"
      fi
      if [ "$key" = "ignore_advisories" ]; then
        val="${FAKE_HEX_CONFIG_IGNORE_ADVISORIES-[]}"
        [ "$val" = "__NOOUTPUT__" ] || printf '%s\n' "$val"
      elif [ "$key" = "ignore_retirements" ]; then
        val="${FAKE_HEX_CONFIG_IGNORE_RETIREMENTS-[]}"
        [ "$val" = "__NOOUTPUT__" ] || printf '%s\n' "$val"
      fi
      exit "${FAKE_HEX_CONFIG_EXIT:-0}"
    fi
    if [ "$cmd" = "deps.get" ]; then
      case ",${FAKE_LOCK_DRIFT:-}," in
        *",$base,"*)
          case " $* " in
            *" --check-locked "*)
              printf '** (Mix) Your mix.lock is out of date and must be updated without the --check-locked flag\n'
              exit 1
              ;;
          esac
          ;;
      esac
    fi
    case ",${FAKE_FAIL:-}," in
      *",$base:$cmd,"*)
        [ "$cmd" = "deps.tree" ] && printf '** (Mix) fake deps.tree failure\n' >&2
        exit 1
        ;;
    esac
    if [ "$cmd" = "deps.tree" ]; then
      # FAKE_TREE_<base>: package names (newline, comma or space separated),
      # rendered under a project line; default `telemetry`; `__EMPTY__`
      # prints only the project line (an empty closure).
      spec="$(knob FAKE_TREE)"
      [ -n "$spec" ] || spec="telemetry"
      printf '%s\n' "$base"
      [ "$spec" = "__EMPTY__" ] && exit 0
      printf '%s\n' "$spec" | tr ', ' '\n\n' | sed '/^$/d' | while IFS= read -r name; do
        printf '|-- %s ~> 1.0 (Hex package)\n' "$name"
      done
      exit 0
    fi
    if [ "$cmd" = "hex.audit" ]; then
      out=""
      prev=""
      for a in "$@"; do
        [ "$prev" = "--output" ] && out="$a"
        prev="$a"
      done
      # FAKE_SARIF_<base>: `kind:package:id;...` (kind advisory, retired or
      # any other word; `raw:<fingerprint>` writes that fingerprint verbatim),
      # or `__NOFILE__` (a registry failure: no file, exit 1), `__NOJSON__`
      # (OTP below 27: no file, exit 1) or
      # `__MALFORMED__` (unparseable JSON, exit 1). FAKE_AUDIT_EXIT_<base>
      # overrides the exit status (default: 1 when any result exists).
      spec="$(knob FAKE_SARIF)"
      forced="$(knob FAKE_AUDIT_EXIT)"
      if [ "$spec" = "__NOJSON__" ]; then
        printf '** (Mix) SARIF output requires OTP 27+: the :json module is not available\n'
        exit 1
      fi
      if [ "$spec" = "__NOFILE__" ]; then
        printf 'Failed to fetch record for plug from registry\n'
        exit 1
      fi
      [ -n "$out" ] || exit 64
      if [ "$spec" = "__MALFORMED__" ]; then
        printf 'not json {' > "$out"
        exit "${forced:-1}"
      fi
      printf '%s\n' "$spec" | tr ';' '\n' | sed '/^$/d' | while IFS= read -r e; do
        kind="${e%%:*}"
        rest="${e#*:}"
        pkg="${rest%%:*}"
        id="${rest#*:}"
        case "$kind" in
          advisory) fp="advisory:hexpm/$pkg:$id" ;;
          raw) fp="$rest"; pkg="?"; id="RAW" ;;
          *) fp="$kind:hexpm/$pkg" ;;
        esac
        printf '%s\t%s\t%s\n' "$fp" "$id" "Dependency '$pkg' has a $kind finding '$id'."
      done | jq -Rn '[inputs | split("\t") | {ruleId: .[1], level: "warning", message: {text: .[2]}, partialFingerprints: {"hexAudit/v1": .[0]}}] | {version: "2.1.0", runs: [{tool: {driver: {name: "mix hex.audit", version: "2.6.0"}}, results: .}]}' > "$out"
      count=$(jq '.runs[0].results | length' "$out")
      if [ -n "$forced" ]; then exit "$forced"; fi
      [ "$count" -eq 0 ] && exit 0
      printf 'Found packages with security advisories\n'
      exit 1
    fi
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

  # CALL_LOG lines for `deps.get --check-locked` run in the dir named `name`.
  defp fetch_calls(log, name) do
    log
    |> String.split("\n")
    |> Enum.count(&String.ends_with?(&1, "/#{name}|deps.get --check-locked"))
  end

  defp run(args, env, root) do
    mix = fake_mix(root)
    log = call_log(root)

    base_env = [
      {"MIX_BIN", mix},
      {"CALL_LOG", log},
      {"FAKE_HEX_INFO", "Hex:    2.6.0"},
      {"FAKE_FAIL", ""},
      {"HEX_IGNORE_ADVISORIES", ""},
      {"HEX_IGNORE_RETIREMENTS", ""},
      {"RETRY_NETWORK_BASE_DELAY", "0"}
    ]

    full_env =
      Enum.reduce(env, base_env, fn {k, v}, acc ->
        [{k, v} | Enum.reject(acc, fn {ek, _} -> ek == k end)]
      end)

    {out, status} = System.cmd(@script, args, env: full_env, stderr_to_stdout: true)
    {out, status, File.read!(log)}
  end

  test "clean run over three dirs: exit 0, CALL_LOG order is hex.info then per-dir deps.get/deps.unlock/deps.tree/hex.audit sarif" do
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

    sarif_prefix = Path.join([@real_root, "tmp", "deps-audit-sarif."])

    {per_dir, audits} =
      calls
      |> Enum.drop(3)
      |> Enum.map_reduce([], fn call, acc ->
        case Regex.run(~r/^hex\.audit --format sarif --output (\S+)$/, call) do
          [_, path] -> {"hex.audit --format sarif --output <sarif>", [path | acc]}
          nil -> {call, acc}
        end
      end)

    assert Enum.take(calls, 3) == [
             "hex.info",
             "hex.config ignore_advisories",
             "hex.config ignore_retirements"
           ]

    per_dir_calls = [
      "deps.get --check-locked",
      "deps.unlock --check-unused",
      "deps.tree --only prod --format plain",
      "hex.audit --format sarif --output <sarif>"
    ]

    assert per_dir == per_dir_calls ++ per_dir_calls ++ per_dir_calls

    # A fresh SARIF path per audit call, under tmp/deps-audit-sarif.*, removed
    # by the single EXIT trap.
    assert length(Enum.uniq(audits)) == 3

    for path <- audits do
      assert String.starts_with?(path, sarif_prefix), path
      refute File.exists?(Path.dirname(path)), "SARIF dir #{path} was not removed"
    end
  end

  test "tracer: a root runtime advisory blocks the gate through the shared tier library" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {out, status, log} =
      run(
        [d1],
        [
          {"FAKE_TREE_one", "plug\nplug_crypto\ntelemetry"},
          {"FAKE_SARIF_one", "advisory:plug:EEF-CVE-2026-56813"}
        ],
        root
      )

    assert status == 1, out
    assert out =~ "deps-audit-finding tier=blocking dir=#{d1} kind=advisory"
    assert out =~ "package=plug id=EEF-CVE-2026-56813"
    assert out =~ "FAIL #{d1}: blocking advisory plug EEF-CVE-2026-56813"
    assert out =~ "::error::"
    assert log =~ "#{d1}|deps.tree --only prod --format plain"
    refute out =~ "audit clean"
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
      assert out =~ "requires Hex >= 2.6.0"
      assert out =~ version
      assert String.trim(log) == "#{root}|hex.info" or String.contains?(log, "|hex.info")
      refute log =~ "deps.get"
      refute log =~ "hex.audit"
    end
  end

  # REL-04: the maintainers' Hex at 1.1.0 (2.5.1) is below the chosen pin, so
  # the floor refuses it before any lock is checked. The pin is toolchain
  # determinism; the 1.1.0 `[]` lock is caught by the lock hygiene tests below.
  test "the 1.1.0 local Hex is below the floor CI pins" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {out, status, log} =
      run(
        [d1],
        [
          {"FAKE_HEX_INFO", "Hex:    2.5.1"}
        ],
        root
      )

    assert status != 0

    assert out =~
             "requires Hex >= 2.6.0, found 2.5.1"

    refute log =~ "deps.get"
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
    # REL-03: a transient fetch failure is retried through bin/retry-network.
    assert fetch_calls(log, "one") == 3, log
  end

  test "lock drift fails on the first attempt: bin/retry-network never retries it" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {out, status, log} = run([d1], [{"FAKE_LOCK_DRIFT", "one"}], root)

    assert status != 0
    assert out =~ "mix.lock is out of date"
    assert fetch_calls(log, "one") == 1, log
  end

  test "a lock that no longer matches mix.exs fails via --check-locked and skips that dir's hex.audit" do
    root = tmp_root()
    d1 = project_dir(root, "one")

    {out, status, log} = run([d1], [{"FAKE_LOCK_DRIFT", "one"}], root)

    assert status != 0
    assert out =~ "one"
    assert out =~ "--check-locked"
    refute log =~ "one|hex.audit"
  end

  test "lock drift in the 1st of 3 dirs is aggregated: dirs two and three still run hex.audit" do
    root = tmp_root()
    d1 = project_dir(root, "one")
    d2 = project_dir(root, "two")
    d3 = project_dir(root, "three")

    {out, status, log} = run([d1, d2, d3], [{"FAKE_LOCK_DRIFT", "one"}], root)

    assert status != 0
    assert out =~ "one"
    assert out =~ "--check-locked"
    refute log =~ "one|hex.audit"
    assert log =~ "two|hex.audit"
    assert log =~ "three|hex.audit"
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

    # Check only this run's own neutral dir(s). A global
    # `tmp/deps-audit-hex-config.*` wildcard also sees the live neutral dir of
    # a sibling async test's concurrent bin/verify-deps-audit run.
    for pwd <- Enum.uniq(config_pwds) do
      refute File.exists?(pwd), "neutral hex.config dir #{pwd} was not removed"
    end
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
      {"FAKE_HEX_INFO", "Hex:    2.6.0"},
      {"FAKE_FAIL", ""},
      {"HEX_IGNORE_ADVISORIES", ""},
      {"HEX_IGNORE_RETIREMENTS", ""},
      {"RETRY_NETWORK_BASE_DELAY", "0"}
    ]

    {_out, status} = System.cmd(@script, [], env: env, cd: real_root, stderr_to_stdout: true)

    assert status == 0
    contents = File.read!(log)
    lines = contents |> String.trim() |> String.split("\n")
    pwds = Enum.map(lines, fn line -> line |> String.split("|", parts: 2) |> hd() end)

    # The first three lines (hex.info, hex.config x2) run in ROOT. Each
    # directory starts with its own `deps.get --check-locked`; only the root
    # (a closure-rule dir) also runs deps.tree.
    dir_pwds =
      lines
      |> Enum.filter(&String.ends_with?(&1, "|deps.get --check-locked"))
      |> Enum.map(fn line -> line |> String.split("|", parts: 2) |> hd() end)

    assert length(dir_pwds) == 3
    _ = pwds

    tree_pwds =
      lines
      |> Enum.filter(&String.contains?(&1, "|deps.tree"))
      |> Enum.map(fn line -> line |> String.split("|", parts: 2) |> hd() end)

    assert tree_pwds == [real_root]

    assert Enum.at(dir_pwds, 0) |> String.ends_with?(real_root)
    assert Enum.at(dir_pwds, 1) |> String.ends_with?("/bench")
    assert Enum.at(dir_pwds, 2) |> String.ends_with?("/examples/threadline_phoenix")
  end

  describe "lock hygiene (REL-04)" do
    @hygiene Path.expand("../../bin/verify-lock-hygiene", __DIR__)

    # The plug_crypto 2.2.1 entry exactly as commit a3301bed wrote it, with an
    # empty build-manager list. Commit f7fdcaca restored `[:mix]`. Kept as a
    # literal, not read through `git show`, because a CI clone may not hold
    # that commit.
    @a3301bed_entry ~s("plug_crypto": {:hex, :plug_crypto, "2.2.1", "bd1d0358a2e2f5ffb818217e64c394f9d24ed191d862b7fa1bcce264ace2b8ea", [], [], "hexpm", "4417ccbd8f85e627321cd07d2ab9c4b621f1fd883b9905af241f9b4b780b94b6"},)
    @f7fdcaca_entry String.replace(
                      @a3301bed_entry,
                      ~s("2.2.1", "bd1d0358a2e2f5ffb818217e64c394f9d24ed191d862b7fa1bcce264ace2b8ea", []),
                      ~s("2.2.1", "bd1d0358a2e2f5ffb818217e64c394f9d24ed191d862b7fa1bcce264ace2b8ea", [:mix])
                    )

    defp lock_text(entry), do: "%{\n  " <> entry <> "\n}\n"

    defp write_lock(root, name, content) do
      path = Path.join(root, name)
      File.write!(path, content)
      path
    end

    defp hygiene(paths), do: System.cmd(@hygiene, paths, stderr_to_stdout: true)

    test "mutation control: the a3301bed entry with [] managers exits 1, naming file, package and version" do
      root = tmp_root()
      lock = write_lock(root, "a3301bed.lock", lock_text(@a3301bed_entry))

      {out, status} = hygiene([lock])

      assert status == 1, out
      assert out =~ "FAIL #{lock}"
      assert out =~ "plug_crypto"
      assert out =~ "2.2.1"
      assert out =~ "([])"
    end

    test "control: the f7fdcaca entry with [:mix] managers exits 0" do
      root = tmp_root()
      lock = write_lock(root, "f7fdcaca.lock", lock_text(@f7fdcaca_entry))

      {out, status} = hygiene([lock])

      assert status == 0, out
      assert out =~ "verify-lock-hygiene: 1 lock(s), 1 :hex entries clean"
    end

    test "no arguments is a usage error (exit 2)" do
      {_out, status} = hygiene([])

      assert status == 2
    end

    test "a successful (warm) fetch cannot mask a [] lock: the gate fails the dir and still audits the others" do
      root = tmp_root()
      d1 = project_dir(root, "one")
      d2 = project_dir(root, "two")
      File.write!(Path.join(d1, "mix.lock"), lock_text(@a3301bed_entry))
      File.write!(Path.join(d2, "mix.lock"), lock_text(@f7fdcaca_entry))

      {out, status, log} = run([d1, d2], [], root)

      assert status != 0
      assert out =~ "FAIL #{d1}: lock hygiene"
      assert out =~ "plug_crypto"
      assert log =~ "two|hex.audit"
      # Aggregate, not fail-fast: the [] dir still runs its fetch and audit.
      assert log =~ "one|hex.audit"
    end

    test "the same gate run with [:mix] locks exits 0" do
      root = tmp_root()
      d1 = project_dir(root, "one")
      d2 = project_dir(root, "two")
      File.write!(Path.join(d1, "mix.lock"), lock_text(@f7fdcaca_entry))
      File.write!(Path.join(d2, "mix.lock"), lock_text(@f7fdcaca_entry))

      {out, status, _log} = run([d1, d2], [], root)

      assert status == 0, out
      refute out =~ "lock hygiene"
    end

    @canonical_locks ["mix.lock", "bench/mix.lock", "examples/threadline_phoenix/mix.lock"]

    defp tracked_locks do
      {out, 0} = System.cmd("git", ["ls-files", "*mix.lock"], cd: @real_root)
      String.split(out, "\n", trim: true)
    end

    defp hex_count(out) do
      [_, count] = Regex.run(~r/lock\(s\), (\d+) :hex entries clean/, out)
      String.to_integer(count)
    end

    test "live tree: every git-tracked mix.lock is clean, and each canonical lock has :hex entries" do
      locks = tracked_locks()

      for lock <- @canonical_locks, do: assert(lock in locks, "#{lock} is not tracked")

      {out, status} = System.cmd(@hygiene, locks, cd: @real_root, stderr_to_stdout: true)
      assert status == 0, out
      assert out =~ "verify-lock-hygiene: #{length(locks)} lock(s)"

      for lock <- @canonical_locks do
        {out, status} = System.cmd(@hygiene, [lock], cd: @real_root, stderr_to_stdout: true)
        assert status == 0, out
        assert hex_count(out) > 0, "#{lock}: hygiene check counted no :hex entries (vacuous)"
      end
    end

    test "live-lock mutation: the root mix.lock with plug_crypto's [:mix] set to [] exits 1" do
      root = tmp_root()
      live = File.read!(Path.join(@real_root, "mix.lock"))

      anchor =
        ~s("2.2.1", "bd1d0358a2e2f5ffb818217e64c394f9d24ed191d862b7fa1bcce264ace2b8ea", [:mix])

      assert length(String.split(live, anchor)) == 2, "mutation anchor not unique in mix.lock"

      mutated = String.replace(live, anchor, String.replace(anchor, "[:mix]", "[]"))
      lock = write_lock(root, "mutated.lock", mutated)

      {out, status} = hygiene([lock])

      assert status == 1, out
      assert out =~ "plug_crypto 2.2.1 has an empty build-manager list"
    end

    for {label, content} <- [
          {"an empty file", ""},
          {"a whitespace-only file", "  \n"},
          {"%{}", "%{}\n"}
        ] do
      test "#{label} is a clean lock with 0 :hex entries" do
        root = tmp_root()
        lock = write_lock(root, "lock", unquote(content))

        {out, status} = hygiene([lock])

        assert status == 0, out
        assert out =~ "verify-lock-hygiene: 1 lock(s), 0 :hex entries clean"
      end
    end

    for {label, content} <- [
          {"unparseable text", "not a lock {"},
          {"a top-level list", "[1, 2]\n"},
          {"a :hex entry with an atom manager slot",
           ~s(%{\n  "x": {:hex, :x, "1.0.0", "abc", :mix, [], "hexpm", "def"},\n}\n)},
          {"a :hex entry with too few elements", ~s(%{\n  "x": {:hex, :x, "1.0.0"},\n}\n)},
          {"a two-element :hex entry", ~s(%{\n  "x": {:hex, :x},\n}\n)},
          # R2-WR-02: a non-string version (or name) used to reach String.Chars
          # in the FAIL line and crash the script with exit 1, reporting a
          # malformed lock as a hygiene violation.
          {"a :hex entry with [] managers and a non-string version",
           ~s(%{\n  "x": {:hex, :x, {:a, :b}, "a", [], [], "hexpm", "b"},\n}\n)},
          {"a :hex entry with [:mix] managers and a non-string version",
           ~s(%{\n  "x": {:hex, :x, {:a, :b}, "a", [:mix], [], "hexpm", "b"},\n}\n)},
          {"a :hex entry with [] managers and a non-literal name",
           ~s(%{\n  {:a, :b} => {:hex, :x, "1.0.0", "a", [], [], "hexpm", "b"},\n}\n)}
        ] do
      test "#{label} fails closed (exit 2), naming the path" do
        root = tmp_root()
        lock = write_lock(root, "lock", unquote(content))

        {out, status} = hygiene([lock])

        assert status == 2, out
        assert out =~ lock
        refute out =~ "** (", "the hygiene check crashed instead of failing closed:\n#{out}"
      end
    end

    # R2-WR-02: every lock is checked before the exit status is chosen, so a
    # malformed later lock cannot hide a violation in an earlier one.
    test "a violation in the 1st lock is still reported when the 2nd lock is missing (exit 2)" do
      root = tmp_root()
      bad = write_lock(root, "a3301bed.lock", lock_text(@a3301bed_entry))
      missing = Path.join(root, "absent.lock")

      {out, status} = hygiene([bad, missing])

      assert status == 2, out
      assert out =~ "FAIL #{bad}"
      assert out =~ "plug_crypto 2.2.1 has an empty build-manager list"
      assert out =~ missing
    end

    test "a missing 1st lock does not stop the 2nd lock's violation from being reported (exit 2)" do
      root = tmp_root()
      missing = Path.join(root, "absent.lock")
      bad = write_lock(root, "a3301bed.lock", lock_text(@a3301bed_entry))

      {out, status} = hygiene([missing, bad])

      assert status == 2, out
      assert out =~ missing
      assert out =~ "FAIL #{bad}"
    end

    test "a missing file fails closed (exit 2), naming the path" do
      root = tmp_root()
      missing = Path.join(root, "absent.lock")

      {out, status} = hygiene([missing])

      assert status == 2, out
      assert out =~ missing
    end

    test "a lock with only a :git entry is clean (non-:hex entries are skipped)" do
      root = tmp_root()

      lock =
        write_lock(
          root,
          "lock",
          ~s(%{\n  "dep": {:git, "https://example.com/dep.git", "0123abcd", []},\n}\n)
        )

      {out, status} = hygiene([lock])

      assert status == 0, out
      assert out =~ "verify-lock-hygiene: 1 lock(s), 0 :hex entries clean"
    end
  end

  describe "SUP-03 tiered findings (D-23)" do
    @tier_scripts ["verify-deps-audit", "deps-audit-tier", "retry-network", "verify-lock-hygiene"]

    # PATTERNS hazard 4: the gate decides a directory's role only from its
    # resolved path, with no seam. Cases 5 and 6 therefore run a copy of the
    # bin/ scripts inside a temp root, so the literal `bench` and
    # `examples/threadline_phoenix` arguments resolve to `<root>/bench` and
    # `<root>/examples/threadline_phoenix`, exactly as in the real tree.
    defp copied_bin_root do
      root = tmp_root()
      bin = Path.join(root, "bin")
      File.mkdir_p!(bin)

      for script <- @tier_scripts do
        dest = Path.join(bin, script)
        File.cp!(Path.join([@real_root, "bin", script]), dest)
        File.chmod!(dest, 0o755)
      end

      File.write!(Path.join(root, "mix.exs"), "")
      File.write!(Path.join(root, "mix.lock"), "")
      project_dir(root, "bench")
      project_dir(Path.join(root, "examples"), "threadline_phoenix")
      root
    end

    defp run_copied(root, args, env) do
      mix = fake_mix(root)
      log = call_log(root)

      base_env = [
        {"MIX_BIN", mix},
        {"CALL_LOG", log},
        {"FAKE_HEX_INFO", "Hex:    2.6.0"},
        {"FAKE_FAIL", ""},
        {"HEX_IGNORE_ADVISORIES", ""},
        {"HEX_IGNORE_RETIREMENTS", ""},
        {"RETRY_NETWORK_BASE_DELAY", "0"}
      ]

      full_env =
        Enum.reduce(env, base_env, fn {k, v}, acc ->
          [{k, v} | Enum.reject(acc, fn {ek, _} -> ek == k end)]
        end)

      {out, status} =
        System.cmd(Path.join([root, "bin", "verify-deps-audit"]), args,
          env: full_env,
          cd: root,
          stderr_to_stdout: true
        )

      {out, status, File.read!(log)}
    end

    for {label, pkg, tree} <- [
          {"case 1: root plug", "plug", "plug,plug_crypto,telemetry"},
          {"case 2: root transitive plug_crypto", "plug_crypto", "plug,plug_crypto,telemetry"},
          {"case 3: root optional oban", "oban", "ecto,oban,telemetry"}
        ] do
      test "#{label} advisory in the runtime closure blocks (exit 1, tier=blocking)" do
        root = tmp_root()
        d1 = project_dir(root, "one")
        pkg = unquote(pkg)

        {out, status, _log} =
          run(
            [d1],
            [
              {"FAKE_TREE_one", unquote(tree)},
              {"FAKE_SARIF_one", "advisory:#{pkg}:EEF-CVE-2026-0001"}
            ],
            root
          )

        assert status == 1, out

        assert out =~
                 "deps-audit-finding tier=blocking dir=#{d1} kind=advisory package=#{pkg} id=EEF-CVE-2026-0001"

        assert out =~ "FAIL #{d1}: blocking advisory #{pkg} EEF-CVE-2026-0001"
        assert out =~ "#{pkg} is in the shipped runtime closure"
      end
    end

    # WR-01: deps.tree lists the app name, SARIF names the Hex package, so a
    # dep declared `{:foo, "~> 1.0", hex: :foo_bar}` must still block.
    test "case 3b: an advisory on the Hex package of a renamed (hex:) runtime dep blocks" do
      root = tmp_root()
      d1 = project_dir(root, "one")

      File.write!(
        Path.join(d1, "mix.lock"),
        ~s(%{\n  "foo": {:hex, :foo_bar, "1.0.0", "abc", [:mix], [], "hexpm", "def"},\n}\n)
      )

      {out, status, _log} =
        run(
          [d1],
          [
            {"FAKE_TREE_one", "foo,telemetry"},
            {"FAKE_SARIF_one", "advisory:foo_bar:EEF-CVE-2026-0003"}
          ],
          root
        )

      assert status == 1, out

      assert out =~
               "deps-audit-finding tier=blocking dir=#{d1} kind=advisory package=foo_bar id=EEF-CVE-2026-0003"

      assert out =~ "FAIL #{d1}: blocking advisory foo_bar EEF-CVE-2026-0003"
    end

    test "case 4: a root dev-only ex_doc advisory is non-blocking (exit 0, ::warning::)" do
      root = tmp_root()
      d1 = project_dir(root, "one")

      {out, status, _log} =
        run(
          [d1],
          [
            {"FAKE_TREE_one", "plug,telemetry"},
            {"FAKE_SARIF_one", "advisory:ex_doc:EEF-CVE-2026-0002"}
          ],
          root
        )

      assert status == 0, out

      assert out =~
               "deps-audit-finding tier=non-blocking dir=#{d1} kind=advisory package=ex_doc id=EEF-CVE-2026-0002"

      assert out =~ "::warning::ex_doc is not in the --only prod closure of #{d1}; dev/test only"
      refute out =~ "FAIL "
      assert out =~ "1 lockfile(s) audit clean (Hex 2.6.0; 1 non-blocking finding(s))"
    end

    test "case 5: a bench benchee advisory is non-blocking, and bench never reads a closure" do
      root = copied_bin_root()

      {out, status, log} =
        run_copied(root, ["bench"], [{"FAKE_SARIF_bench", "advisory:benchee:EEF-CVE-2026-0003"}])

      assert status == 0, out

      assert out =~
               "deps-audit-finding tier=non-blocking dir=bench kind=advisory package=benchee id=EEF-CVE-2026-0003"

      assert out =~ "benchee is only in bench/mix.lock; not shipped in the Hex package"
      refute log =~ "deps.tree"
    end

    test "case 6: an example plug advisory is non-blocking even with plug in that dir's tree" do
      root = copied_bin_root()

      {out, status, _log} =
        run_copied(root, ["examples/threadline_phoenix"], [
          {"FAKE_TREE_threadline_phoenix", "plug,telemetry"},
          {"FAKE_SARIF_threadline_phoenix", "advisory:plug:EEF-CVE-2026-54892"}
        ])

      assert status == 0, out

      assert out =~
               "deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=plug id=EEF-CVE-2026-54892"

      assert out =~ "plug is only in examples/threadline_phoenix/mix.lock"
    end

    test "control for cases 5/6: the copied root `.` still uses the closure rule and blocks" do
      root = copied_bin_root()

      {out, status, _log} =
        run_copied(root, ["."], [
          {"FAKE_TREE_" <> Path.basename(root), "plug"},
          {"FAKE_SARIF_" <> Path.basename(root), "advisory:plug:EEF-CVE-2026-54892"}
        ])

      assert status == 1, out
      assert out =~ "deps-audit-finding tier=blocking dir=. kind=advisory package=plug"
      assert out =~ "plug is in the shipped runtime closure (root mix.lock)"
    end

    test "case 7: a retirement of a closure package blocks with the SARIF ruleId as id" do
      root = tmp_root()
      d1 = project_dir(root, "one")

      {out, status, _log} =
        run([d1], [{"FAKE_TREE_one", "plug"}, {"FAKE_SARIF_one", "retired:plug:HEX0002"}], root)

      assert status == 1, out

      assert out =~
               "deps-audit-finding tier=blocking dir=#{d1} kind=retirement package=plug id=HEX0002"

      assert out =~ "FAIL #{d1}: blocking retirement plug HEX0002"
    end

    test "case 7: a retirement of a dev-only package is non-blocking" do
      root = tmp_root()
      d1 = project_dir(root, "one")

      {out, status, _log} =
        run([d1], [{"FAKE_TREE_one", "plug"}, {"FAKE_SARIF_one", "retired:credo:HEX0001"}], root)

      assert status == 0, out

      assert out =~
               "deps-audit-finding tier=non-blocking dir=#{d1} kind=retirement package=credo id=HEX0001"
    end

    for {label, env, text} <- [
          {"no SARIF file (registry failure)", [{"FAKE_SARIF_one", "__NOFILE__"}],
           "SARIF output missing"},
          {"a non-zero exit with zero results", [{"FAKE_AUDIT_EXIT_one", "1"}],
           "hex.audit exited 1 with no SARIF results"},
          {"malformed SARIF JSON", [{"FAKE_SARIF_one", "__MALFORMED__"}],
           "SARIF output unparseable"},
          {"exit 0 with results",
           [{"FAKE_SARIF_one", "advisory:ex_doc:EEF-X"}, {"FAKE_AUDIT_EXIT_one", "0"}],
           "hex.audit exited 0 with findings (unclassifiable)"},
          {"an unparseable fingerprint", [{"FAKE_SARIF_one", "raw:advisory:hexpm"}],
           "unparseable fingerprint"},
          {"a denied finding kind", [{"FAKE_SARIF_one", "denied:plug:HEX0005"}],
           "unknown finding kind denied"},
          {"OTP below 27", [{"FAKE_SARIF_one", "__NOJSON__"}], "SARIF needs OTP 27+"}
        ] do
      test "case 8 (D-19): #{label} is its own FAIL line (exit 1)" do
        root = tmp_root()
        d1 = project_dir(root, "one")

        {out, status, _log} = run([d1], [{"FAKE_TREE_one", "plug"} | unquote(env)], root)

        assert status == 1, out
        assert out =~ "FAIL #{d1}: #{unquote(text)}"
        refute out =~ "audit clean"
      end
    end

    test "case 9: a failing deps.tree is a FAIL line and the audit is not trusted" do
      root = tmp_root()
      d1 = project_dir(root, "one")

      {out, status, log} = run([d1], [{"FAKE_FAIL", "one:deps.tree"}], root)

      assert status == 1, out
      assert out =~ "FAIL #{d1}: deps.tree --only prod exited 1"
      refute log =~ "hex.audit"
    end

    test "case 9: an empty closure in a closure-rule directory is a FAIL line" do
      root = tmp_root()
      d1 = project_dir(root, "one")

      {out, status, log} = run([d1], [{"FAKE_TREE_one", "__EMPTY__"}], root)

      assert status == 1, out
      assert out =~ "FAIL #{d1}: empty runtime closure"
      refute log =~ "hex.audit"
    end

    test "deps.tree runs only after that dir's successful --check-locked fetch" do
      root = tmp_root()
      d1 = project_dir(root, "one")
      d2 = project_dir(root, "two")

      {_out, status, log} = run([d1, d2], [{"FAKE_LOCK_DRIFT", "one"}], root)

      assert status == 1
      refute log =~ "#{d1}|deps.tree"
      assert log =~ "#{d2}|deps.tree"
    end

    test "case 10: a non-blocking finding plus bench lock drift still exits 1 (D-20)" do
      root = copied_bin_root()
      base = Path.basename(root)

      {out, status, _log} =
        run_copied(root, [".", "bench"], [
          {"FAKE_TREE_" <> base, "plug"},
          {"FAKE_SARIF_" <> base, "advisory:ex_doc:EEF-CVE-2026-0002"},
          {"FAKE_LOCK_DRIFT", "bench"}
        ])

      assert status == 1, out
      assert out =~ "deps-audit-finding tier=non-blocking dir=. kind=advisory package=ex_doc"
      assert out =~ "FAIL bench: deps.get --check-locked exited 1"
    end

    test "case 11: a clean run reports the non-blocking finding count" do
      root = tmp_root()
      d1 = project_dir(root, "one")

      {out, status, _log} =
        run(
          [d1],
          [
            {"FAKE_TREE_one", "plug"},
            {"FAKE_SARIF_one", "advisory:ex_doc:EEF-CVE-2026-0002;retired:credo:HEX0001"}
          ],
          root
        )

      assert status == 0, out

      assert out =~
               "verify-deps-audit: 1 lockfile(s) audit clean (Hex 2.6.0; 2 non-blocking finding(s))"
    end

    test "a clean run with no findings reports 0 non-blocking findings" do
      root = tmp_root()
      d1 = project_dir(root, "one")

      {out, 0, _log} = run([d1], [], root)

      assert out =~ "1 lockfile(s) audit clean (Hex 2.6.0; 0 non-blocking finding(s))"
    end

    test "GITHUB_STEP_SUMMARY gains one table row per finding with tier and reason" do
      root = tmp_root()
      d1 = project_dir(root, "one")
      summary = Path.join(root, "step_summary.md")
      File.write!(summary, "prior content\n")

      {_out, 1, _log} =
        run(
          [d1],
          [
            {"FAKE_TREE_one", "plug"},
            {"FAKE_SARIF_one",
             "advisory:plug:EEF-CVE-2026-54892;advisory:ex_doc:EEF-CVE-2026-0002"},
            {"GITHUB_STEP_SUMMARY", summary}
          ],
          root
        )

      body = File.read!(summary)
      assert body =~ "prior content\n"

      assert length(Regex.scan(~r/^\| dir \| package \| kind \| id \| tier \| why \|$/m, body)) ==
               1

      assert body =~
               "| #{d1} | plug | advisory | EEF-CVE-2026-54892 | blocking | plug is in the shipped runtime closure (#{d1}/mix.lock) |"

      assert body =~
               "| #{d1} | ex_doc | advisory | EEF-CVE-2026-0002 | non-blocking | ex_doc is not in the --only prod closure of #{d1}; dev/test only |"
    end

    test "every finding prints exactly one machine line" do
      root = tmp_root()
      d1 = project_dir(root, "one")

      {out, _status, _log} =
        run(
          [d1],
          [
            {"FAKE_TREE_one", "plug"},
            {"FAKE_SARIF_one", "advisory:plug:A;advisory:ex_doc:B;retired:credo:HEX0001"}
          ],
          root
        )

      assert length(Regex.scan(~r/^deps-audit-finding /m, out)) == 3
    end
  end

  describe "lock hygiene FAIL reason (D-20, 244 R2-IN-01)" do
    test "exit 1 names the empty build-manager list" do
      root = tmp_root()
      d1 = project_dir(root, "one")

      File.write!(
        Path.join(d1, "mix.lock"),
        ~s(%{\n  "x": {:hex, :x, "1.0.0", "abc", [], [], "hexpm", "def"},\n}\n)
      )

      {out, 1, _log} = run([d1], [], root)

      assert out =~ "FAIL #{d1}: lock hygiene exited 1 (an empty build-manager list"
    end

    test "exit 2 names usage, missing file, parse error or malformed entry" do
      root = tmp_root()
      d1 = project_dir(root, "one")
      File.write!(Path.join(d1, "mix.lock"), "not a lock {")

      {out, 1, _log} = run([d1], [], root)

      assert out =~
               "FAIL #{d1}: lock hygiene could not check mix.lock (usage, missing file, parse error or malformed entry; see the lines above)"

      refute out =~ "empty build-manager list in mix.lock passes"
    end
  end

  describe "live tree: the root --only prod runtime closure (D-23)" do
    @dev_test_only ~w(credo dialyxir ex_doc lazy_html stream_data yaml_elixir)a

    test "contains every root dep declared without only: and none of the dev/test tools" do
      {out, status} =
        System.cmd("mix", ["deps.tree", "--only", "prod", "--format", "plain"],
          cd: @real_root,
          stderr_to_stdout: true
        )

      assert status == 0, out

      closure =
        out
        |> String.split("\n")
        |> Enum.drop(1)
        |> Enum.map(fn line ->
          line |> String.replace(~r/^[|` -]*/, "") |> String.split(" ") |> hd()
        end)
        |> Enum.reject(&(&1 == ""))
        |> MapSet.new()

      assert MapSet.size(closure) > 0, out

      runtime =
        for dep <- Mix.Project.config()[:deps],
            opts = dep_opts(dep),
            not Keyword.has_key?(opts, :only),
            do: dep |> elem(0) |> Atom.to_string()

      assert runtime != []

      for name <- runtime do
        assert MapSet.member?(closure, name),
               "#{name} (no only:) missing from the closure:\n#{out}"
      end

      for name <- @dev_test_only do
        refute MapSet.member?(closure, Atom.to_string(name)),
               "#{name} is dev/test only but appears in the --only prod closure"
      end
    end

    defp dep_opts({_name, opts}) when is_list(opts), do: opts
    defp dep_opts({_name, _req}), do: []
    defp dep_opts({_name, _req, opts}) when is_list(opts), do: opts
  end
end
