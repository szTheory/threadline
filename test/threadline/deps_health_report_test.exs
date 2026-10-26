defmodule Threadline.DepsHealthReportTest do
  @moduledoc """
  SUP-04: `bin/deps-health-report` is the deps-health lane's classification
  engine, extracted into a standalone script (the same idiom as
  `bin/classify-flake-run`) so its behavior is unit-tested offline via a fake
  `MIX_BIN`, rather than living as untested inline workflow shell.

  Classification precedence (D-25, highest wins, across all three canonical
  lockfile directories): `advisory` > `retirement` > `unknown` > `clean`. A
  confirmed finding anywhere in the fan-out always outranks an unrelated
  `unknown` elsewhere (Threat T-215-17), and `unknown` never reads as `clean`.
  Findings come only from Hex 2.6.0 SARIF fixtures under
  `test/fixtures/deps_audit/sarif/`, which the fake `hex.audit` copies to the
  `--output` path per directory (`FAKE_SARIF_ROOT`, `FAKE_SARIF_BENCH`,
  `FAKE_SARIF_EXAMPLE`). The fake `hex.outdated` exits 1 by default: the
  classifier must never run it (D-24).

  The classification tests drive the script directly through a fake `mix`
  binary (the `MIX_BIN` seam, same pattern as `bin/verify-deps-audit`'s own
  tests), fully offline. The workflow tests assert the
  `.github/workflows/deps-health.yml` shape that wires this script to a
  single `ci-deps` issue lifecycle, so the script and the workflow that calls
  it cannot drift apart.
  """

  use ExUnit.Case, async: true

  @repo_root File.cwd!()
  @script Path.join(@repo_root, "bin/deps-health-report")
  @workflow_path Path.join(@repo_root, ".github/workflows/deps-health.yml")
  @canonical_dirs [".", "bench", "examples/threadline_phoenix"]
  @sarif_dir Path.join(@repo_root, "test/fixtures/deps_audit/sarif")

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
        if should_match "${FAKE_HUGE:-}"; then emit_huge; fi
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
        echo "deps.get ok for $REL"
        exit 0
        ;;
      hex.audit)
        if should_match "${FAKE_HUGE:-}"; then emit_huge; fi
        sarif_out=""
        prev=""
        for a in "$@"; do
          [ "$prev" = "--output" ] && sarif_out="$a"
          prev="$a"
        done
        # A registry failure writes no SARIF file at all (Hex 2.6.0).
        if should_match "${FAKE_SARIF_NO_FILE:-}"; then
          echo "Failed to fetch record for plug from registry"
          echo "** (Mix) Could not audit these locked packages:"
          exit 1
        fi
        case "$REL" in
          .) fixture="${FAKE_SARIF_ROOT:-clean.json}" ;;
          bench) fixture="${FAKE_SARIF_BENCH:-clean.json}" ;;
          examples/threadline_phoenix) fixture="${FAKE_SARIF_EXAMPLE:-clean.json}" ;;
          *) fixture="clean.json" ;;
        esac
        if [ -n "$sarif_out" ]; then
          cp "${FAKE_SARIF_DIR:?FAKE_SARIF_DIR must be set}/$fixture" "$sarif_out"
        fi
        if should_match "${FAKE_AUDIT_FORCE_NONZERO:-}"; then exit 1; fi
        if should_match "${FAKE_AUDIT_FORCE_ZERO:-}"; then exit 0; fi
        if [ "$fixture" = "clean.json" ]; then
          echo "No retired or security advisory packages found"
          exit 0
        fi
        echo "Found packages with security advisories"
        exit 1
        ;;
      deps.tree)
        # SUP-03 (D-27): the `--only prod` closure, rendered as a plain tree
        # under a project line. FAKE_TREE_ROOT|BENCH|EXAMPLE are comma or
        # space separated names (default `plug,telemetry`); FAKE_TREE_FAIL
        # lists dirs whose deps.tree exits 1.
        if should_match "${FAKE_TREE_FAIL:-}"; then
          echo "** (Mix) fake deps.tree failure for $REL" >&2
          exit 1
        fi
        case "$REL" in
          .) tree="${FAKE_TREE_ROOT:-plug,telemetry}" ;;
          bench) tree="${FAKE_TREE_BENCH:-plug,telemetry}" ;;
          examples/threadline_phoenix) tree="${FAKE_TREE_EXAMPLE:-plug,telemetry}" ;;
          *) tree="plug,telemetry" ;;
        esac
        echo "project"
        printf '%s\n' "$tree" | tr ', ' '\n\n' | sed '/^$/d' | while IFS= read -r name; do
          printf '|-- %s ~> 1.0 (Hex package)\n' "$name"
        done
        exit 0
        ;;
      hex.outdated)
        # Regression bait (D-24): real hex.outdated exits 1 whenever anything
        # is outdated. The classifier must never call it.
        echo "some outdated packages for $REL"
        exit 1
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

  # Fake bin/verify-action-pins (VERIFY_ACTION_PINS_BIN seam, RESEARCH Pitfall
  # 9): every run uses it, so the offline suite never reaches gh. Exits
  # FAKE_PINS_EXIT (default 0) after printing FAKE_PINS_OUTPUT.
  defp fake_pins do
    dir = Path.join(System.tmp_dir!(), "fake-pins-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    path = Path.join(dir, "verify-action-pins")

    File.write!(path, """
    #!/usr/bin/env bash
    [ -z "${FAKE_PINS_OUTPUT:-}" ] || printf '%s\\n' "$FAKE_PINS_OUTPUT"
    exit "${FAKE_PINS_EXIT:-0}"
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
        {"VERIFY_ACTION_PINS_BIN", fake_pins()},
        {"FAKE_MIX_ROOT", @repo_root},
        {"FAKE_MIX_LOG", log},
        {"FAKE_SARIF_DIR", @sarif_dir},
        {"RETRY_NETWORK_BASE_DELAY", "0"}
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

    test "tracer: a retired:hexpm/plug SARIF result in root -> retirement end to end" do
      out_dir = tmp_out_dir()

      output_path =
        Path.join(System.tmp_dir!(), "github-output-#{System.unique_integer([:positive])}")

      on_exit(fn -> File.rm(output_path) end)

      {output, status, calls} =
        run_report(out_dir, [
          {"FAKE_SARIF_ROOT", "retired_plug.json"},
          {"GITHUB_OUTPUT", output_path}
        ])

      assert status == 0
      assert output =~ "classification=retirement", diag(out_dir, output)
      assert File.read!(output_path) =~ ~r/^classification=retirement$/m

      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ ~r/\A# Dependency health: retirement\n/
      assert body =~ "- retirement plug HEX0002: Dependency 'plug' '1.20.0' is retired"
      assert calls =~ ~r/^\. hex\.audit --format sarif --output \S+audit\.sarif$/m
    end

    test "an advisory SARIF result in the example -> advisory" do
      out_dir = tmp_out_dir()

      {output, status, _calls} =
        run_report(out_dir, [{"FAKE_SARIF_EXAMPLE", "advisory_plug.json"}])

      assert status == 0
      assert output =~ "classification=advisory", diag(out_dir, output)
    end

    test "hex.audit writes no SARIF file (registry failure) -> unknown with a named reason" do
      out_dir = tmp_out_dir()

      {output, status, _calls} = run_report(out_dir, [{"FAKE_SARIF_NO_FILE", "bench"}])

      assert status == 0
      assert output =~ "classification=unknown", diag(out_dir, output)

      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ "- audit: unknown (hex.audit exited 1 and wrote no SARIF file)"
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
      # REL-03: the transient fetch failure is retried through bin/retry-network.
      assert length(Regex.scan(~r/^\. deps\.get --check-locked$/m, calls)) == 3, calls
    end

    test "deps.get fails in root AND hex.audit fails in bench -> advisory (a real advisory outranks unknown)" do
      out_dir = tmp_out_dir()

      {output, status, calls} =
        run_report(out_dir, [
          {"FAKE_FAIL_DEPS_GET", "."},
          {"FAKE_SARIF_BENCH", "advisory_plug.json"}
        ])

      assert status == 0
      assert output =~ "classification=advisory", diag(out_dir, output)
      refute calls =~ ". hex.audit"

      report_path = Path.join(out_dir, "report.md")
      body = File.read!(report_path)
      assert body =~ ~r/## \.\n.*fetch.*(unknown|failed|non-zero|deps\.get)/is
    end
  end

  describe "every class arm, one directory at a time" do
    for {name, env, expected} <- [
          {"advisory SARIF in bench", [{"FAKE_SARIF_BENCH", "advisory_plug.json"}], "advisory"},
          {"retired SARIF in the example", [{"FAKE_SARIF_EXAMPLE", "retired_plug.json"}],
           "retirement"},
          {"retired + advisory (plug 1.20.0) in root", [{"FAKE_SARIF_ROOT", "plug_1_20_0.json"}],
           "advisory"},
          {"the real vulnerable-fixture fingerprints in root",
           [{"FAKE_SARIF_ROOT", "vulnerable_lock.json"}], "advisory"},
          {"no SARIF file written in root", [{"FAKE_SARIF_NO_FILE", "."}], "unknown"},
          {"an unparseable fingerprint in bench",
           [{"FAKE_SARIF_BENCH", "unparseable_fingerprint.json"}], "unknown"},
          {"a denied finding in bench", [{"FAKE_SARIF_BENCH", "denied_plug.json"}], "unknown"},
          {"a non-zero exit with zero results in the example",
           [{"FAKE_AUDIT_FORCE_NONZERO", "examples/threadline_phoenix"}], "unknown"},
          {"exit 0 with results in root",
           [{"FAKE_SARIF_ROOT", "advisory_plug.json"}, {"FAKE_AUDIT_FORCE_ZERO", "."}],
           "unknown"},
          {"a drifted lock in bench", [{"FAKE_LOCK_DRIFT", "bench"}], "unknown"},
          {"an active suppression", [{"HEX_IGNORE_ADVISORIES", "x"}], "unknown"},
          {"every directory clean", [], "clean"}
        ] do
      @env env
      @expected expected
      test "#{name} -> #{expected}" do
        out_dir = tmp_out_dir()
        {output, status, _calls} = run_report(out_dir, @env)

        assert status == 0
        assert output =~ ~r/^classification=#{@expected}$/m, diag(out_dir, output)
      end
    end

    test "unparseable and denied shapes name their reason in the report" do
      for {fixture, reason} <- [
            {"unparseable_fingerprint.json",
             "- audit: unknown (unparseable hexAudit/v1 fingerprint: advisory:hexpm)"},
            {"denied_plug.json", "- audit: unknown (unexpected hex.audit finding kind: denied)"}
          ] do
        out_dir = tmp_out_dir()
        {output, 0, _calls} = run_report(out_dir, [{"FAKE_SARIF_BENCH", fixture}])
        assert File.read!(Path.join(out_dir, "report.md")) =~ reason, diag(out_dir, output)
      end
    end

    test "a missing directory (no examples/threadline_phoenix) -> unknown" do
      root =
        Path.join(System.tmp_dir!(), "deps-health-root-#{System.unique_integer([:positive])}")

      on_exit(fn -> File.rm_rf!(root) end)
      File.mkdir_p!(Path.join(root, "bin"))
      File.mkdir_p!(Path.join(root, "bench"))

      for script <- ["deps-health-report", "deps-audit-tier", "retry-network"] do
        File.cp!(Path.join(@repo_root, "bin/#{script}"), Path.join(root, "bin/#{script}"))
      end

      File.write!(Path.join(root, "mix.exs"), "")
      File.write!(Path.join(root, "bench/mix.exs"), "")
      out_dir = tmp_out_dir()

      {output, status} =
        System.cmd(Path.join(root, "bin/deps-health-report"), [out_dir],
          env: [
            {"MIX_BIN", fake_mix()},
            {"VERIFY_ACTION_PINS_BIN", fake_pins()},
            {"FAKE_MIX_ROOT", root},
            {"FAKE_SARIF_DIR", @sarif_dir},
            {"RETRY_NETWORK_BASE_DELAY", "0"}
          ],
          stderr_to_stdout: true
        )

      assert status == 0
      assert output =~ "classification=unknown", diag(out_dir, output)

      assert File.read!(Path.join(out_dir, "report.md")) =~
               "missing directory or mix.exs"
    end
  end

  describe "precedence across directories" do
    test "advisory (example) + retirement (bench) -> advisory" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} =
        run_report(out_dir, [
          {"FAKE_SARIF_EXAMPLE", "advisory_plug.json"},
          {"FAKE_SARIF_BENCH", "retired_plug.json"}
        ])

      assert output =~ "classification=advisory", diag(out_dir, output)
      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ "- retirement plug HEX0002:"
      assert body =~ "- advisory plug EEF-CVE-2026-56813:"
    end

    test "retirement (root) + fetch failure (bench) -> retirement" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} =
        run_report(out_dir, [
          {"FAKE_SARIF_ROOT", "retired_plug.json"},
          {"FAKE_FAIL_DEPS_GET", "bench"}
        ])

      assert output =~ "classification=retirement", diag(out_dir, output)
    end

    test "unknown (bench) + clean elsewhere -> unknown" do
      out_dir = tmp_out_dir()
      {output, 0, _calls} = run_report(out_dir, [{"FAKE_SARIF_NO_FILE", "bench"}])
      assert output =~ "classification=unknown", diag(out_dir, output)
    end
  end

  describe "action pin provenance (SUP-02, D-14b, D-25)" do
    @mismatch "MISMATCH actions/checkout@v5.1.0: pinned " <>
                "fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09 resolves to " <>
                "1111111111111111111111111111111111111111"

    test "a pin mismatch with clean dirs -> unknown, reason first under the title" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} =
        run_report(out_dir, [{"FAKE_PINS_EXIT", "1"}, {"FAKE_PINS_OUTPUT", @mismatch}])

      assert output =~ "classification=unknown", diag(out_dir, output)
      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ ~r/\A# Dependency health: unknown\n\n## Action pin provenance\n/

      [provenance, _] = String.split(body, "\n## .\n", parts: 2)
      assert provenance =~ @mismatch
    end

    test "a pin mismatch plus a root advisory -> advisory (a finding outranks unknown)" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} =
        run_report(out_dir, [
          {"FAKE_PINS_EXIT", "1"},
          {"FAKE_PINS_OUTPUT", @mismatch},
          {"FAKE_SARIF_ROOT", "advisory_plug.json"}
        ])

      assert output =~ "classification=advisory", diag(out_dir, output)
      assert File.read!(Path.join(out_dir, "report.md")) =~ "## Action pin provenance"
    end

    test "a passing pin check -> no provenance block, class follows the dirs" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} =
        run_report(out_dir, [
          {"FAKE_PINS_OUTPUT", "verify-action-pins: 8 pin(s) match their tags"}
        ])

      assert output =~ "classification=clean", diag(out_dir, output)
      refute File.read!(Path.join(out_dir, "report.md")) =~ "Action pin provenance"
    end

    test "a missing pin-check binary fails closed to unknown" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} =
        run_report(out_dir, [{"VERIFY_ACTION_PINS_BIN", "/nonexistent/verify-action-pins"}])

      assert output =~ "classification=unknown", diag(out_dir, output)
      assert File.read!(Path.join(out_dir, "report.md")) =~ "## Action pin provenance"
    end

    test "an active suppression does not skip the pin check" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} =
        run_report(out_dir, [
          {"HEX_IGNORE_ADVISORIES", "x"},
          {"FAKE_PINS_EXIT", "1"},
          {"FAKE_PINS_OUTPUT", @mismatch}
        ])

      assert output =~ "classification=unknown", diag(out_dir, output)
      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ @mismatch
      assert body =~ "Hex advisory suppression is active"
    end
  end

  describe "tier sections (SUP-03, D-27, D-23 case 12)" do
    defp section(body, title) do
      case String.split(body, "## " <> title <> "\n", parts: 2) do
        [_, rest] -> rest |> String.split(~r/^## |^---$/m, parts: 2) |> hd()
        _ -> flunk("section #{title} missing from:\n#{body}")
      end
    end

    test "root runtime plug is Blocking; bench plug and plug_crypto are Non-blocking; class stays advisory" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} =
        run_report(out_dir, [
          {"FAKE_SARIF_ROOT", "advisory_plug.json"},
          {"FAKE_SARIF_BENCH", "vulnerable_lock.json"}
        ])

      assert output =~ "classification=advisory", diag(out_dir, output)
      body = File.read!(Path.join(out_dir, "report.md"))
      blocking = section(body, "Blocking — shipped runtime")
      non_blocking = section(body, "Non-blocking — dev/test/bench/example")

      assert blocking =~
               "- .: advisory plug EEF-CVE-2026-56813 — plug is in the shipped runtime closure (root mix.lock)"

      refute blocking =~ "bench"

      assert non_blocking =~
               "- bench: advisory plug EEF-CVE-2026-54892 — plug is only in bench/mix.lock; not shipped in the Hex package"

      assert non_blocking =~ "- bench: advisory plug_crypto "
      refute non_blocking =~ "- .:"
    end

    test "a root advisory for a package outside the closure is Non-blocking (dev/test only)" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} =
        run_report(out_dir, [
          {"FAKE_SARIF_ROOT", "advisory_plug.json"},
          {"FAKE_TREE_ROOT", "telemetry"}
        ])

      assert output =~ "classification=advisory", diag(out_dir, output)
      body = File.read!(Path.join(out_dir, "report.md"))
      assert section(body, "Blocking — shipped runtime") =~ "- none"

      assert section(body, "Non-blocking — dev/test/bench/example") =~
               "- .: advisory plug EEF-CVE-2026-56813 — plug is not in the --only prod closure of .; dev/test only"
    end

    test "a retirement keeps its own class and is tiered the same way" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} = run_report(out_dir, [{"FAKE_SARIF_EXAMPLE", "retired_plug.json"}])

      assert output =~ "classification=retirement", diag(out_dir, output)
      body = File.read!(Path.join(out_dir, "report.md"))

      assert section(body, "Non-blocking — dev/test/bench/example") =~
               "- examples/threadline_phoenix: retirement plug HEX0002 — plug is only in examples/threadline_phoenix/mix.lock"
    end

    test "a clean run lists none under both sections" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} = run_report(out_dir)

      assert output =~ "classification=clean", diag(out_dir, output)
      body = File.read!(Path.join(out_dir, "report.md"))
      assert section(body, "Blocking — shipped runtime") =~ "- none"
      assert section(body, "Non-blocking — dev/test/bench/example") =~ "- none"
      assert body =~ ~r/\A# Dependency health: clean\n/
    end

    test "a deps.tree failure in root after a successful fetch -> unknown, findings untiered" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} =
        run_report(out_dir, [{"FAKE_TREE_FAIL", "."}])

      assert output =~ "classification=unknown", diag(out_dir, output)
      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ "deps.tree --only prod failed"
    end

    test "a deps.tree failure does not hide a root advisory from the class or the body" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} =
        run_report(out_dir, [{"FAKE_TREE_FAIL", "."}, {"FAKE_SARIF_ROOT", "advisory_plug.json"}])

      assert output =~ "classification=advisory", diag(out_dir, output)
      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ "deps.tree --only prod failed"
      assert body =~ "- advisory plug EEF-CVE-2026-56813"
      refute section(body, "Blocking — shipped runtime") =~ "plug"
      refute section(body, "Non-blocking — dev/test/bench/example") =~ "plug"
    end

    test "an empty root closure -> unknown" do
      out_dir = tmp_out_dir()

      {output, 0, _calls} = run_report(out_dir, [{"FAKE_TREE_ROOT", " "}])

      assert output =~ "classification=unknown", diag(out_dir, output)
      assert File.read!(Path.join(out_dir, "report.md")) =~ "empty runtime closure"
    end

    test "deps.tree runs only in root, only after its successful --check-locked fetch" do
      out_dir = tmp_out_dir()

      {_output, 0, calls} = run_report(out_dir)
      lines = String.split(calls, "\n", trim: true)

      tree_idx = Enum.find_index(lines, &(&1 == ". deps.tree --only prod --format plain"))
      fetch_idx = Enum.find_index(lines, &(&1 == ". deps.get --check-locked"))
      assert tree_idx && fetch_idx && fetch_idx < tree_idx, calls
      assert length(Enum.filter(lines, &String.contains?(&1, "deps.tree"))) == 1, calls

      {_output, 0, drift_calls} = run_report(tmp_out_dir(), [{"FAKE_LOCK_DRIFT", "."}])
      refute drift_calls =~ "deps.tree", drift_calls
    end
  end

  describe "hex.outdated is never invoked (D-24)" do
    test "with the fake hex.outdated exiting 1, an all-clean tree still classifies clean" do
      out_dir = tmp_out_dir()
      {output, 0, calls} = run_report(out_dir)

      assert output =~ "classification=clean", diag(out_dir, output)
      assert calls =~ "hex.audit"
      refute calls =~ "hex.outdated"
    end
  end

  describe "deps.get output (D-26 noise trim)" do
    test "appears only for the directory whose fetch failed" do
      out_dir = tmp_out_dir()
      {output, 0, _calls} = run_report(out_dir, [{"FAKE_FAIL_DEPS_GET", "bench"}])

      body = File.read!(Path.join(out_dir, "report.md"))
      assert body =~ "deps.get failed for bench", diag(out_dir, output)
      refute body =~ "deps.get ok for"
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
      end
    end

    test "is capped at 60000 bytes with a trailing truncation marker when oversized" do
      out_dir = tmp_out_dir()

      # deps.get output reaches the body only for a failed fetch (D-26).
      {_output, status, _calls} =
        run_report(out_dir, [
          {"FAKE_HUGE", ".,bench,examples/threadline_phoenix"},
          {"FAKE_FAIL_DEPS_GET", ".,bench,examples/threadline_phoenix"}
        ])

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

  describe "GITHUB_OUTPUT classification values" do
    test "only ever hold a value from {clean, unknown, retirement, advisory}" do
      arms = [
        [],
        [{"FAKE_SARIF_ROOT", "advisory_plug.json"}],
        [{"FAKE_SARIF_ROOT", "retired_plug.json"}],
        [{"FAKE_SARIF_NO_FILE", "."}],
        [{"FAKE_SARIF_BENCH", "unparseable_fingerprint.json"}],
        [{"FAKE_SARIF_BENCH", "denied_plug.json"}],
        [{"FAKE_AUDIT_FORCE_NONZERO", "bench"}],
        [{"FAKE_LOCK_DRIFT", "bench"}],
        [{"FAKE_FAIL_DEPS_GET", "."}],
        [{"HEX_IGNORE_RETIREMENTS", "x"}]
      ]

      values =
        for env <- arms do
          out_dir = tmp_out_dir()

          output_path =
            Path.join(System.tmp_dir!(), "github-output-#{System.unique_integer([:positive])}")

          on_exit(fn -> File.rm(output_path) end)
          {_output, 0, _calls} = run_report(out_dir, [{"GITHUB_OUTPUT", output_path} | env])

          lines = output_path |> File.read!() |> String.split("\n", trim: true)
          [value] = for "classification=" <> v <- lines, do: v
          value
        end

      allowed = MapSet.new(["clean", "unknown", "retirement", "advisory"])
      assert MapSet.subset?(MapSet.new(values), allowed), inspect(values)
      assert MapSet.new(values) == allowed, "every class should be exercised: #{inspect(values)}"
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
    test "a drifted lock in bench -> unknown, bench's audit skipped, root and example still run hex.audit" do
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

      # the id: must precede the run: line in the same step; look just before.
      [before_report, _] = String.split(yaml, "bin/deps-health-report", parts: 2)
      step_start = before_report |> String.split(~r/\n\s{6}- name:/) |> List.last()

      assert step_start =~ ~r/id:\s*report/,
             "the step invoking bin/deps-health-report must carry `id: report`"
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

    test "the fail step exempts only 'clean'" do
      yaml = File.read!(@workflow_path)

      [_, after_fail] = String.split(yaml, "Fail the job", parts: 2)
      step_body = after_fail |> String.split(~r/\n\s{6}- name:/, parts: 2) |> hd()

      [if_line] = Regex.run(~r/^\s*if:.*$/m, step_body)
      assert if_line =~ ~r/!=\s*'clean'/
      assert length(Regex.scan(~r/!=/, if_line)) == 1, "the fail step must exempt only 'clean'"

      assert step_body =~
               ~r/CLASSIFICATION:\s*\$\{\{\s*steps\.report\.outputs\.classification\s*\}\}/

      [_, run_block] = String.split(step_body, "run: |", parts: 2)
      refute run_block =~ "${{", "the classification must reach run: through env:, not ${{ }}"
    end

    test "the close step fires on == 'clean' only" do
      yaml = File.read!(@workflow_path)

      [_, after_close] =
        String.split(yaml, "Close the dependency health issue on a clean run", parts: 2)

      step_body = after_close |> String.split(~r/\n\s{6}- name:/, parts: 2) |> hd()
      [if_line] = Regex.run(~r/^\s*if:.*$/m, step_body)
      assert if_line =~ ~r/^\s*if:\s*steps\.report\.outputs\.classification == 'clean'\s*$/
      assert step_body =~ "--close"
    end

    test "push to main is path-filtered to exactly the canonical mix.exs/mix.lock pairs, and a cron is daily" do
      parsed = YamlElixir.read_from_file!(@workflow_path)
      triggers = parsed["on"] || parsed[true]

      expected =
        for dir <- @canonical_dirs, file <- ["mix.exs", "mix.lock"] do
          if dir == ".", do: file, else: "#{dir}/#{file}"
        end

      assert triggers["push"]["branches"] == ["main"]
      assert Enum.sort(triggers["push"]["paths"]) == Enum.sort(expected)
      assert Map.has_key?(triggers, "workflow_dispatch")

      crons = Enum.map(triggers["schedule"], & &1["cron"])

      assert Enum.any?(crons, &(&1 =~ ~r/^\S+ \S+ \* \* \*$/)),
             "expected a daily cron, got #{inspect(crons)}"

      assert parsed["concurrency"] == %{"group" => "deps-health", "cancel-in-progress" => false}
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
