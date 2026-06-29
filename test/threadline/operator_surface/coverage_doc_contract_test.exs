defmodule Threadline.OperatorSurface.CoverageDocContractTest do
  @moduledoc """
  Phase 66 (COV-03) doc-contract — pure source-reading literal pin.

  Mirrors BROWSE-04 and EXPO-05 patterns. Asserts that all locked literals
  from CONTEXT.md D-35 / UI-SPEC §"Doc-Contract Test Literals" appear
  verbatim in their source files. Includes one runtime test that invokes
  `mix threadline.health.coverage --json` to assert the JSON output schema.

  Drift between CONTEXT.md decisions and actual source fails CI explicitly.
  """

  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @router_path "lib/threadline/operator_surface/router.ex"
  @health_path "lib/threadline/health.ex"
  @policy_path "lib/threadline/health/policy.ex"
  @coverage_lv_path "lib/threadline/operator_surface/live/coverage_live.ex"
  @coverage_schemas_path "lib/threadline/health/coverage_schemas.ex"
  @on_mount_path "lib/threadline/operator_surface/coverage/on_mount.ex"
  @surface_header_path "lib/threadline/operator_surface/components/surface_header.ex"
  @mix_task_path "lib/mix/tasks/threadline.health.coverage.ex"
  @verify_task_path "lib/mix/tasks/threadline.verify_coverage.ex"
  @row_history_path "lib/threadline/operator_surface/live/row_history_component.ex"

  describe "LV route literal (D-35 #1)" do
    test "router declares live(\"/coverage\", CoverageLive, :index) inside live_session :threadline" do
      src = File.read!(@router_path)

      assert String.contains?(src, ~s|live("/coverage", CoverageLive, :index)|),
             "expected #{@router_path} to declare `live(\"/coverage\", CoverageLive, :index)` inside the live_session :threadline scope per D-35"
    end
  end

  describe "on_mount order (Pitfall 7 / D-30)" do
    test "Auth runs before Coverage.OnMount in the on_mount: list" do
      src = File.read!(@router_path)
      lines = String.split(src, "\n")

      auth_line = Enum.find_index(lines, &String.contains?(&1, "Auth, unquote(opts)"))

      coverage_line =
        Enum.find_index(lines, &String.contains?(&1, "Coverage.OnMount, unquote(opts)"))

      assert auth_line, "expected #{@router_path} to declare {Auth, unquote(opts)}"

      assert coverage_line,
             "expected #{@router_path} to declare {Coverage.OnMount, unquote(opts)}"

      assert auth_line < coverage_line,
             "expected Auth on_mount entry to appear BEFORE Coverage.OnMount in the on_mount: list (Pitfall 7)"
    end
  end

  describe "surface header literals (D-31a, D-35 #3, #4)" do
    test "surface_header.ex contains the literal \"All tables captured\" for the boring-case pill" do
      src = File.read!(@surface_header_path)

      assert String.contains?(src, "All tables captured"),
             "expected #{@surface_header_path} to render the literal \"All tables captured\""
    end

    test "surface_header.ex renders the audit coverage gap pluralization format" do
      src = File.read!(@surface_header_path)

      assert String.contains?(src, "tables need audit coverage"),
             "expected #{@surface_header_path} to render clear coverage-gap copy"

      # Pin the warning chip class literal (D-31a CSS class)
      assert String.contains?(src, "tl-chip--warning"),
             "expected the tl-chip--warning CSS class for the uncovered pill"

      # Pin the neutral chip class literal (D-31a CSS class)
      assert String.contains?(src, "tl-chip--muted"),
             "expected the tl-chip--muted CSS class for the all-captured pill"
    end
  end

  describe "three badge state literals on CoverageLive (D-32d, D-35 #5)" do
    test "coverage_live.ex renders the literal \"Covered\" badge state" do
      src = File.read!(@coverage_lv_path)

      assert String.contains?(src, ">Covered<"),
             "expected literal `Covered` badge in #{@coverage_lv_path}"
    end

    test "coverage_live.ex renders the literal \"Needs capture\" badge state" do
      src = File.read!(@coverage_lv_path)

      assert String.contains?(src, ">Needs capture<"),
             "expected literal `Needs capture` badge in #{@coverage_lv_path}"
    end

    test "coverage_live.ex renders the literal \"Expected gap\" badge state" do
      src = File.read!(@coverage_lv_path)

      assert String.contains?(src, ">Expected gap<"),
             "expected literal `Expected gap` badge in #{@coverage_lv_path}"
    end

    test "coverage_live.ex page heading and schema picker literals" do
      src = File.read!(@coverage_lv_path)

      assert String.contains?(src, "Audit coverage"),
             "expected literal page heading `Audit coverage` in #{@coverage_lv_path}"

      assert String.contains?(src, "Apply schema"),
             "expected visible schema picker affordance in #{@coverage_lv_path}"
    end

    test "coverage schema helper error copy contains \"' not found.\" (D-33a)" do
      src = File.read!(@coverage_schemas_path)

      assert String.contains?(src, "' not found."),
             "expected literal `Schema 'X' not found.` error copy fragment per D-33a in #{@coverage_schemas_path}"
    end

    test "coverage_live.ex shows Refresh affordance with phx-click=refresh" do
      src = File.read!(@coverage_lv_path)

      assert String.contains?(src, "Refresh"),
             "expected `Refresh` literal per D-30b in #{@coverage_lv_path}"

      assert String.contains?(src, ~s|phx-click="refresh"|),
             "expected `phx-click=\"refresh\"` attribute per D-30b in #{@coverage_lv_path}"
    end
  end

  describe "Phase 185 selected-schema readiness contracts (COV-01/COV-02/COV-03)" do
    test "coverage_live.ex owns one selected-schema verdict and native schema select" do
      src = File.read!(@coverage_lv_path)

      assert String.contains?(src, "Selected schema readiness")
      assert String.contains?(src, "tl-coverage-verdict")
      assert String.contains?(src, ~s|<select|)
      assert String.contains?(src, ~s|id="coverage-schema"|)
      assert String.contains?(src, ~s|name="schema"|)
      refute String.contains?(src, ~s|<datalist|)
      refute String.contains?(src, ~s|list="coverage-schema-options"|)
    end

    test "operator guide documents selected-schema readiness, schema recovery, refresh, and row actions" do
      guide = File.read!("guides/operator-surface.md")
      coverage_section = guide_section(guide, "## Coverage and audit readiness")

      for heading <- [
            "## Coverage and audit readiness",
            "### Selected schema readiness",
            "### Schema selection",
            "### Refresh and stale data",
            "### Row actions and remediation",
            "### Multi-schema adopters"
          ] do
        assert String.contains?(guide, heading), "missing operator guide heading #{heading}"
      end

      assert String.contains?(guide, "Selected schema readiness")
      assert String.contains?(guide, "Use public schema")
      assert String.contains?(guide, "last known results")
      assert String.contains?(guide, "table_schema=NAME&table=TABLE")
      assert String.contains?(guide, "mix threadline.verify_coverage --schema=NAME")

      assert String.contains?(
               guide,
               "Can operators rely on audit history for the selected schema?"
             )

      refute String.contains?(coverage_section, "dashboard")
      refute String.contains?(guide, "Which tables are covered right now?")
    end

    test "production checklist uses audit-readiness language instead of dashboard language" do
      checklist = File.read!("guides/production-checklist.md")
      coverage_section = guide_section(checklist, "## Coverage drift visibility")

      assert String.contains?(checklist, "selected-schema audit readiness")
      assert String.contains?(checklist, "one readiness verdict")
      refute String.contains?(checklist, "Coverage dashboard responds")
      refute String.contains?(coverage_section, "dashboard")
    end
  end

  describe "Mix-task help text and flags (D-34, D-35 #6, #7)" do
    test "threadline.health.coverage.ex declares @shortdoc with the locked literal" do
      src = File.read!(@mix_task_path)

      assert String.contains?(src, ~s|@shortdoc "Show trigger coverage for audited tables"|),
             "expected literal `@shortdoc \"Show trigger coverage for audited tables\"` in #{@mix_task_path} per D-34"
    end

    test "threadline.health.coverage.ex @moduledoc lists the three usage forms" do
      src = File.read!(@mix_task_path)

      assert String.contains?(src, "mix threadline.health.coverage"),
             "expected literal `mix threadline.health.coverage` in @moduledoc per D-34"

      assert String.contains?(src, "mix threadline.health.coverage --json"),
             "expected literal `mix threadline.health.coverage --json` in @moduledoc per D-34"

      assert String.contains?(src, "mix threadline.health.coverage --schema=NAME"),
             "expected literal `mix threadline.health.coverage --schema=NAME` in @moduledoc per D-34"
    end

    test "threadline.health.coverage.ex declares the OptionParser strict spec [json: :boolean, schema: :string]" do
      src = File.read!(@mix_task_path)

      assert String.contains?(src, "strict: [json: :boolean, schema: :string]"),
             "expected `strict: [json: :boolean, schema: :string]` OptionParser spec in #{@mix_task_path}"
    end
  end

  describe "Mix-task --json output schema (D-34, D-35 #8, #9, #10)" do
    setup do
      Mix.Task.reenable("threadline.health.coverage")
      :ok
    end

    test "--json emits exactly the locked top-level keys (sorted)" do
      output =
        capture_io(fn ->
          Mix.Tasks.Threadline.Health.Coverage.run(["--json"])
        end)

      parsed = Jason.decode!(output)

      assert parsed |> Map.keys() |> Enum.sort() ==
               ["covered", "expected_uncovered", "schema", "uncovered"],
             "expected JSON top-level keys to be exactly [\"covered\", \"expected_uncovered\", \"schema\", \"uncovered\"] per D-34/D-35"
    end

    test "--json expected_uncovered entries have exactly [\"source\", \"table\"] keys with source ∈ {baseline, config}" do
      output =
        capture_io(fn ->
          Mix.Tasks.Threadline.Health.Coverage.run(["--json"])
        end)

      parsed = Jason.decode!(output)

      for entry <- parsed["expected_uncovered"] do
        assert entry |> Map.keys() |> Enum.sort() == ["source", "table"],
               "expected entry keys to be [\"source\", \"table\"] per D-34, got: #{inspect(Map.keys(entry))}"

        assert entry["source"] in ["baseline", "config"],
               "expected source ∈ [\"baseline\", \"config\"] per D-34, got: #{inspect(entry["source"])}"
      end
    end
  end

  describe "hardcoded baseline (D-32a, D-35 #11)" do
    test "Threadline.Health declares @expected_uncovered_baseline ~w(schema_migrations) and only that" do
      src = File.read!(@health_path)

      assert String.contains?(src, "@expected_uncovered_baseline ~w(schema_migrations)"),
             "expected #{@health_path} to declare exactly `@expected_uncovered_baseline ~w(schema_migrations)` per D-32a — growing this list is a CI-visible decision (do NOT add oban_jobs / oban_peers to the baseline)"
    end
  end

  describe "atom-safety refute (Pitfall 11, D-35 #12)" do
    test "coverage_live.ex source does NOT call String.to_atom (atom-leak vector closed)" do
      src = File.read!(@coverage_lv_path)

      refute src =~ ~r/String\.to_atom\b/,
             "atom-leak vector via String.to_atom in #{@coverage_lv_path}"
    end

    test "threadline.health.coverage.ex source does NOT call String.to_atom" do
      src = File.read!(@mix_task_path)

      refute src =~ ~r/String\.to_atom\b/,
             "atom-leak vector via String.to_atom in #{@mix_task_path}"
    end

    test "threadline.verify_coverage.ex source does NOT call String.to_atom" do
      src = File.read!(@verify_task_path)

      refute src =~ ~r/String\.to_atom\b/,
             "atom-leak vector via String.to_atom in #{@verify_task_path}"
    end
  end

  describe "SQL-injection refute (Pitfall 2, D-35 #13)" do
    test "health.ex source does NOT contain interpolated nspname = '# or schemaname = '#" do
      src = File.read!(@health_path)

      refute src =~ ~r/nspname = '#/,
             "SQL-injection vector via interpolated nspname in #{@health_path}"

      refute src =~ ~r/schemaname = '#/,
             "SQL-injection vector via interpolated schemaname in #{@health_path}"

      # Also assert the OLD literal `'public'` interpolation is gone (Plan 01 replaced it with $1)
      refute String.contains?(src, "schemaname = 'public'"),
             "expected the legacy literal `schemaname = 'public'` to be replaced with `schemaname = $1` per D-33c"
    end

    test "coverage_live.ex source does NOT contain interpolated nspname = '#" do
      src = File.read!(@coverage_lv_path)

      refute src =~ ~r/nspname = '#/,
             "SQL-injection vector in #{@coverage_lv_path}"
    end

    test "threadline.health.coverage.ex source does NOT contain interpolated nspname = '#" do
      src = File.read!(@mix_task_path)

      refute src =~ ~r/nspname = '#/,
             "SQL-injection vector in #{@mix_task_path}"
    end

    test "threadline.verify_coverage.ex source does NOT contain interpolated nspname = '#" do
      src = File.read!(@verify_task_path)

      refute src =~ ~r/nspname = '#/,
             "SQL-injection vector in #{@verify_task_path}"
    end
  end

  describe "file-scope optional-deps gate (D-36, Pitfall 11)" do
    test "coverage_live.ex first line is the file-scope gate" do
      src = File.read!(@coverage_lv_path)
      first_line = src |> String.split("\n") |> hd()

      assert first_line == "if Code.ensure_loaded?(Phoenix.LiveView) do",
             "expected line 1 of #{@coverage_lv_path} to be the Sentry-idiom file-scope gate, got: #{inspect(first_line)}"
    end

    test "on_mount.ex first line is the file-scope gate" do
      src = File.read!(@on_mount_path)
      first_line = src |> String.split("\n") |> hd()

      assert first_line == "if Code.ensure_loaded?(Phoenix.LiveView) do",
             "expected line 1 of #{@on_mount_path} to be the file-scope gate, got: #{inspect(first_line)}"
    end

    test "surface_header.ex first line is the file-scope gate" do
      src = File.read!(@surface_header_path)
      first_line = src |> String.split("\n") |> hd()

      assert first_line == "if Code.ensure_loaded?(Phoenix.LiveView) do",
             "expected line 1 of #{@surface_header_path} to be the file-scope gate, got: #{inspect(first_line)}"
    end
  end

  describe "NO file-scope gate (D-36 — pure-stdlib for capture-only adopters, D-35 #15)" do
    test "threadline.health.coverage.ex does NOT have a Phoenix.LiveView file-scope gate" do
      src = File.read!(@mix_task_path)

      refute src =~ ~r/Code\.ensure_loaded\?\(Phoenix\.LiveView\)/,
             "expected #{@mix_task_path} to be pure-stdlib (capture-only adopters use this — D-36)"
    end

    test "health/policy.ex does NOT have a Phoenix.LiveView file-scope gate" do
      src = File.read!(@policy_path)

      refute src =~ ~r/Code\.ensure_loaded\?\(Phoenix\.LiveView\)/,
             "expected #{@policy_path} to be pure-stdlib (D-36 — capture-only adopters need this)"
    end
  end

  describe "RowHistoryComponent inheritance (UI-SPEC out-of-scope note)" do
    test "row_history_component.ex does NOT contain its own surface_header invocation" do
      if File.exists?(@row_history_path) do
        src = File.read!(@row_history_path)

        refute String.contains?(src, "Components.SurfaceHeader.surface_header"),
               "RowHistoryComponent should inherit the surface header via TransactionLive's render — see UI-SPEC §\"Out of scope for this UI contract\""
      end
    end
  end

  defp guide_section(markdown, heading) do
    markdown
    |> String.split(heading, parts: 2)
    |> List.last()
    |> String.split("\n## ", parts: 2)
    |> List.first()
  end
end
