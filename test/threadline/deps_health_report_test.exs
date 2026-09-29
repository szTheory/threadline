defmodule Threadline.DepsHealthReportTest do
  @moduledoc """
  SUP-04: `bin/deps-health-report` is the weekly deps-health lane's
  classification engine, extracted into a standalone script (the same idiom
  as `bin/classify-flake-run`) so its behavior is unit-tested offline via a
  fake `MIX_BIN`, rather than living as untested inline workflow shell.

  Classification precedence (highest wins, across all three canonical
  lockfile directories): `advisory` > `unknown` > `outdated` > `clean`. A real
  advisory anywhere in the fan-out always outranks a fetch failure elsewhere
  (Threat T-215-17: an advisory must never be silently swallowed by an
  unrelated `unknown`).

  Tests 1-8 drive the script directly through a fake `mix` binary (the
  `MIX_BIN` seam, same pattern as `bin/verify-deps-audit`'s own tests) —
  fully offline, no network, no real Hex call. Tests 9-13 assert the
  `.github/workflows/deps-health.yml` shape that wires this script to a
  single `ci-deps` issue upsert, so the script and the workflow that calls it
  cannot drift apart.
  """

  use ExUnit.Case, async: true

  @repo_root File.cwd!()
  @script Path.join(@repo_root, "bin/deps-health-report")
  @workflow_path Path.join(@repo_root, ".github/workflows/deps-health.yml")
  @canonical_dirs [".", "bench", "examples/threadline_phoenix"]

  defp fake_mix do
    dir = Path.join(System.tmp_dir!(), "fake-mix-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    path = Path.join(dir, "mix")

    File.write!(path, """
    #!/usr/bin/env bash
    set -u
    SUBCMD="$1"
    ROOT_DIR="${FAKE_MIX_ROOT:?FAKE_MIX_ROOT must be set}"
    REL="${PWD#$ROOT_DIR}"
    REL="${REL#/}"
    [ -z "$REL" ] && REL="."

    if [ -n "${FAKE_MIX_LOG:-}" ]; then
      printf '%s %s\\n' "$REL" "$*" >> "$FAKE_MIX_LOG"
    fi

    should_match() {
      local list="$1"
      case ",$list," in
        *",$REL,"*) return 0 ;;
        *) return 1 ;;
      esac
    }

    emit_huge() {
      head -c 100000 /dev/zero | tr '\\0' 'x'
    }

    case "$SUBCMD" in
      deps.get)
        if [ -n "${FAKE_MIX_STDIN_LOG:-}" ]; then
          cat >> "$FAKE_MIX_STDIN_LOG"
        fi
        if should_match "${FAKE_LOCK_DRIFT:-}"; then
          case " $* " in
            *" --check-locked "*)
              echo "** (Mix) Your mix.lock is out of date and must be updated without the --check-locked flag"
              exit 1
              ;;
          esac
        fi
        if should_match "${FAKE_FAIL_DEPS_GET:-}"; then
          echo "deps.get failed for $REL"
          exit 1
        fi
        if should_match "${FAKE_HUGE:-}"; then emit_huge; fi
        exit 0
        ;;
      hex.audit)
        if should_match "${FAKE_HUGE:-}"; then emit_huge; fi
        if should_match "${FAKE_FAIL_HEX_AUDIT:-}"; then
          echo "Advisories found for $REL"
          exit 1
        fi
        echo "No retired or security advisory packages found"
        exit 0
        ;;
      hex.outdated)
        if should_match "${FAKE_HUGE:-}"; then emit_huge; fi
        if should_match "${FAKE_FAIL_HEX_OUTDATED:-}"; then
          echo "some outdated packages for $REL"
          exit 1
        fi
        echo "All dependencies up to date"
        exit 0
        ;;
      hex.config)
        key="${2:-}"
        if [ "$key" = "ignore_advisories" ]; then
          val="${FAKE_HEX_CONFIG_IGNORE_ADVISORIES-[]}"
          [ "$val" = "__NOOUTPUT__" ] || printf '%s\\n' "$val"
        elif [ "$key" = "ignore_retirements" ]; then
          val="${FAKE_HEX_CONFIG_IGNORE_RETIREMENTS-[]}"
          [ "$val" = "__NOOUTPUT__" ] || printf '%s\\n' "$val"
        fi
        exit "${FAKE_HEX_CONFIG_EXIT:-0}"
        ;;
      *)
        exit 0
        ;;
    esac
    """)

    File.chmod!(path, 0o755)
    on_exit(fn -> File.rm_rf!(dir) end)
    path
  end

  defp tmp_out_dir do
    dir = Path.join(System.tmp_dir!(), "deps-health-out-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    dir
  end

  defp tmp_log do
    path = Path.join(System.tmp_dir!(), "deps-health-log-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm(path) end)
    path
  end

  defp run_report(out_dir, extra_env \\ []) do
    log = tmp_log()

    env =
      [
        {"MIX_BIN", fake_mix()},
        {"FAKE_MIX_ROOT", @repo_root},
        {"FAKE_MIX_LOG", log}
      ] ++ extra_env

    {output, status} = System.cmd(@script, [out_dir], env: env, stderr_to_stdout: true)
    calls = if File.exists?(log), do: File.read!(log), else: ""
    {output, status, calls}
  end

  # Assertion message for every classification check: the script's own
  # stdout/stderr plus the report body, so a future intermittent failure names
  # the arm (suppression, missing dir, fetch exit) that fired.
  defp diag(out_dir, output) do
    report_path = Path.join(out_dir, "report.md")

    body =
      case File.read(report_path) do
        {:ok, body} -> body
        {:error, reason} -> "<could not read #{report_path}: #{inspect(reason)}>"
      end

    "script output:\n#{output}\nreport.md:\n#{body}"
  end

  describe "classification behavior" do
    test "every command succeeds -> clean, exit 0" do
      out_dir = tmp_out_dir()
      {output, status, _calls} = run_report(out_dir)

      assert status == 0
      assert output =~ "classification=clean", diag(out_dir, output)
    end

    test "hex.outdated fails in bench only -> outdated" do
      out_dir = tmp_out_dir()

      {output, status, _calls} =
        run_report(out_dir, [{"FAKE_FAIL_HEX_OUTDATED", "bench"}])

      assert status == 0
      assert output =~ "classification=outdated", diag(out_dir, output)
    end

    test "hex.audit fails in the example -> advisory, even if outdated also fails there" do
      out_dir = tmp_out_dir()

      {output, status, _calls} =
        run_report(out_dir, [
          {"FAKE_FAIL_HEX_AUDIT", "examples/threadline_phoenix"},
          {"FAKE_FAIL_HEX_OUTDATED", "examples/threadline_phoenix"}
        ])

      assert status == 0
      assert output =~ "classification=advisory", diag(out_dir, output)
    end

    test "deps.get fails in root -> unknown, and no hex.audit/hex.outdated logged for root" do
      out_dir = tmp_out_dir()

      {output, status, calls} =
        run_report(out_dir, [{"FAKE_FAIL_DEPS_GET", "."}])

      assert status == 0
      assert output =~ "classification=unknown", diag(out_dir, output)
      refute calls =~ ". hex.audit"
      refute calls =~ ". hex.outdated"
      assert calls =~ "bench hex.audit"
      assert calls =~ "examples/threadline_phoenix hex.audit"
    end

    test "deps.get fails in root AND hex.audit fails in bench -> advisory (a real advisory outranks unknown)" do
      out_dir = tmp_out_dir()

      {output, status, calls} =
        run_report(out_dir, [
          {"FAKE_FAIL_DEPS_GET", "."},
          {"FAKE_FAIL_HEX_AUDIT", "bench"}
        ])

      assert status == 0
      assert output =~ "classification=advisory", diag(out_dir, output)
      refute calls =~ ". hex.audit"

      report_path = Path.join(out_dir, "report.md")
      body = File.read!(report_path)
      assert body =~ ~r/## \.\n.*fetch.*(unknown|failed|non-zero|deps\.get)/is
    end
  end

  describe "report body" do
    test "has one ## <dir> section per canonical dir, in canonical order" do
      out_dir = tmp_out_dir()
      {_output, status, _calls} = run_report(out_dir)
      assert status == 0

      report_path = Path.join(out_dir, "report.md")
      assert File.exists?(report_path)
      body = File.read!(report_path)

      positions =
        for dir <- @canonical_dirs do
          heading = "## #{dir}"
          assert body =~ heading, "expected a #{inspect(heading)} section in the report body"

          {pos, _len} = :binary.match(body, heading)
          pos
        end

      assert positions == Enum.sort(positions),
             "## <dir> sections must appear in canonical order #{inspect(@canonical_dirs)}"

      for dir <- @canonical_dirs do
        heading = "## #{dir}"
        [_, after_heading] = String.split(body, heading, parts: 2)

        section =
          after_heading
          |> String.split(~r/\n## /, parts: 2)
          |> List.first()

        assert section =~ ~r/fetch/i
        assert section =~ ~r/audit/i
        assert section =~ ~r/outdated/i
      end
    end

    test "is capped at 60000 bytes with a trailing truncation marker when oversized" do
      out_dir = tmp_out_dir()

      {_output, status, _calls} =
        run_report(out_dir, [{"FAKE_HUGE", ".,bench,examples/threadline_phoenix"}])

      assert status == 0

      report_path = Path.join(out_dir, "report.md")
      %{size: size} = File.stat!(report_path)

      assert size <= 60_000, "report body must be capped at 60000 bytes, got #{size}"

      body = File.read!(report_path)
      assert body =~ "(truncated)"
    end
  end

  describe "GITHUB_OUTPUT" do
    test "appends classification and report path without overwriting existing contents" do
      out_dir = tmp_out_dir()

      output_path =
        Path.join(System.tmp_dir!(), "github-output-#{System.unique_integer([:positive])}")

      File.write!(output_path, "pre_existing=value\n")
      on_exit(fn -> File.rm(output_path) end)

      {output, status, _calls} =
        run_report(out_dir, [{"GITHUB_OUTPUT", output_path}])

      assert status == 0, diag(out_dir, output)

      contents = File.read!(output_path)
      assert contents =~ "pre_existing=value"
      assert contents =~ ~r/^classification=clean$/m, diag(out_dir, output)
      assert contents =~ ~r/^report=.*report\.md$/m
    end
  end

  describe "Hex advisory suppression" do
    test "a non-empty global hex.config ignore_advisories -> unknown, no per-dir mix calls, report names it" do
      out_dir = tmp_out_dir()

      {output, status, calls} =
        run_report(out_dir, [
          {"FAKE_HEX_CONFIG_IGNORE_ADVISORIES", ~s(["EEF-CVE-2026-54892"])}
        ])

      assert status == 0
      assert output =~ "classification=unknown", diag(out_dir, output)
      refute calls =~ "deps.get"
      refute calls =~ "hex.audit"
      refute calls =~ "hex.outdated"

      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ "ignore_advisories"

      for dir <- @canonical_dirs do
        assert body =~ "## #{dir}"
      end
    end

    test "a non-empty global hex.config ignore_retirements -> unknown, no per-dir mix calls, report names it" do
      out_dir = tmp_out_dir()

      {output, status, calls} =
        run_report(out_dir, [
          {"FAKE_HEX_CONFIG_IGNORE_RETIREMENTS", ~s([{"plug", nil}])}
        ])

      assert status == 0
      assert output =~ "classification=unknown", diag(out_dir, output)
      refute calls =~ "deps.get"
      refute calls =~ "hex.audit"
      refute calls =~ "hex.outdated"

      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ "ignore_retirements"
    end

    test "HEX_IGNORE_ADVISORIES set in the environment -> unknown, no per-dir mix calls, report names it" do
      out_dir = tmp_out_dir()

      {output, status, calls} = run_report(out_dir, [{"HEX_IGNORE_ADVISORIES", "x"}])

      assert status == 0
      assert output =~ "classification=unknown", diag(out_dir, output)
      refute calls =~ "deps.get"
      refute calls =~ "hex.audit"
      refute calls =~ "hex.outdated"

      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ "HEX_IGNORE_ADVISORIES"
    end

    test "HEX_IGNORE_RETIREMENTS set in the environment -> unknown, no per-dir mix calls, report names it" do
      out_dir = tmp_out_dir()

      {output, status, calls} = run_report(out_dir, [{"HEX_IGNORE_RETIREMENTS", "x"}])

      assert status == 0
      assert output =~ "classification=unknown", diag(out_dir, output)
      refute calls =~ "deps.get"
      refute calls =~ "hex.audit"
      refute calls =~ "hex.outdated"

      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ "HEX_IGNORE_RETIREMENTS"
    end

    test "hex.config printing nothing fails closed" do
      out_dir = tmp_out_dir()

      {output, status, calls} =
        run_report(out_dir, [{"FAKE_HEX_CONFIG_IGNORE_ADVISORIES", "__NOOUTPUT__"}])

      assert status == 0
      assert output =~ "classification=unknown", diag(out_dir, output)
      refute calls =~ "deps.get"

      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ "could not read global Hex config"
    end

    test "hex.config exiting non-zero fails closed" do
      out_dir = tmp_out_dir()

      {output, status, calls} =
        run_report(out_dir, [{"FAKE_HEX_CONFIG_EXIT", "1"}])

      assert status == 0
      assert output =~ "classification=unknown", diag(out_dir, output)
      refute calls =~ "deps.get"

      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ "could not read global Hex config"
    end

    test "default fakes (hex.config answers []) still classify clean" do
      out_dir = tmp_out_dir()
      {output, status, _calls} = run_report(out_dir)

      assert status == 0
      assert output =~ "classification=clean", diag(out_dir, output)
    end

    test "the suppression key literal is present in both bin/deps-health-report and bin/verify-deps-audit" do
      health_report = File.read!(Path.join(@repo_root, "bin/deps-health-report"))
      verify_audit = File.read!(Path.join(@repo_root, "bin/verify-deps-audit"))

      assert health_report =~ "ignore_advisories ignore_retirements"
      assert verify_audit =~ "ignore_advisories ignore_retirements"
    end
  end

  describe "committed lock (WR-02)" do
    test "a drifted lock in bench -> unknown, bench's audit/outdated skipped, root and example still run hex.audit" do
      out_dir = tmp_out_dir()

      {output, status, calls} = run_report(out_dir, [{"FAKE_LOCK_DRIFT", "bench"}])

      assert status == 0
      assert output =~ "classification=unknown", diag(out_dir, output)
      refute calls =~ "bench hex.audit"
      refute calls =~ "bench hex.outdated"
      assert calls =~ ". hex.audit"
      assert calls =~ "examples/threadline_phoenix hex.audit"
    end

    test "deps.get gets the `n` prompt answer on stdin, and no script pipes into $MIX_BIN" do
      out_dir = tmp_out_dir()
      stdin_log = tmp_log()

      {output, status, _calls} = run_report(out_dir, [{"FAKE_MIX_STDIN_LOG", stdin_log}])

      assert status == 0
      assert output =~ "classification=clean", diag(out_dir, output)
      assert File.read!(stdin_log) == "n\nn\nn\n"

      # `printf 'n\n' | "$MIX_BIN" deps.get ...` under `set -o pipefail` also
      # counts printf's status, which fails (EPIPE: BEAM-spawned children
      # ignore SIGPIPE) whenever mix exits before printf writes. That race
      # classified a clean run as `unknown`. Guard both scripts that shared it.
      for script <- ["bin/deps-health-report", "bin/verify-deps-audit"] do
        source = File.read!(Path.join(@repo_root, script))

        refute source =~ ~r/\|\s*"\$MIX_BIN"/,
               "#{script} must not pipe into $MIX_BIN (pipefail + EPIPE race)"
      end
    end

    test "every fetch on a default run carries --check-locked" do
      out_dir = tmp_out_dir()
      {_output, status, calls} = run_report(out_dir)

      assert status == 0
      assert calls =~ ". deps.get --check-locked"
      assert calls =~ "bench deps.get --check-locked"
      assert calls =~ "examples/threadline_phoenix deps.get --check-locked"
    end
  end

  describe "the report step in the workflow" do
    test "invokes bin/deps-health-report and carries id: report" do
      assert File.exists?(@workflow_path)
      yaml = File.read!(@workflow_path)

      [_, after_report] = String.split(yaml, "bin/deps-health-report", parts: 2)
      # the id: must precede the run: line in the same step; look just before.
      [before_report, _] = String.split(yaml, "bin/deps-health-report", parts: 2)
      step_start = before_report |> String.split(~r/\n\s{6}- name:/) |> List.last()

      assert step_start =~ ~r/id:\s*report/,
             "the step invoking bin/deps-health-report must carry `id: report`"

      refute after_report == nil
    end

    test "the upsert step's if: starts with always() && and compares against 'clean'" do
      yaml = File.read!(@workflow_path)

      [_, after_upsert] =
        String.split(yaml, "Open or update the dependency health issue", parts: 2)

      step_body = after_upsert |> String.split(~r/\n\s{6}- name:/, parts: 2) |> hd()

      assert step_body =~ ~r/if:\s*always\(\)\s*&&/,
             "the upsert step's if: must start with always() &&"

      assert step_body =~ ~r/!=\s*'clean'/,
             "the upsert step must be gated on classification != 'clean'"
    end

    test "the fail step exempts only 'clean' and 'outdated'" do
      yaml = File.read!(@workflow_path)

      [_, after_fail] = String.split(yaml, "Fail the job", parts: 2)
      step_body = after_fail |> String.split(~r/\n\s{6}- name:/, parts: 2) |> hd()

      assert step_body =~ ~r/!=\s*'clean'/
      assert step_body =~ ~r/!=\s*'outdated'/
    end

    test "the title is built from $TITLE_PREFIX, the same value used as --marker" do
      yaml = File.read!(@workflow_path)

      [_, after_title] =
        String.split(yaml, "Open or update the dependency health issue", parts: 2)

      step_body = after_title |> String.split(~r/\n\s{6}- name:/, parts: 2) |> hd()

      assert step_body =~ ~r/--marker\s+"\$TITLE_PREFIX"/
      assert step_body =~ ~r/--title\s+"\$TITLE_PREFIX/
    end

    test "YamlElixir parses deps-health.yml as real YAML" do
      parsed = YamlElixir.read_from_file!(@workflow_path)

      assert is_map(parsed)
      assert Map.has_key?(parsed, "jobs")
      assert Map.has_key?(parsed["jobs"], "deps-health")
    end
  end
end
