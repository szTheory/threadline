defmodule Threadline.OperatorSurface.CoverageMixTest do
  @moduledoc """
  Integration tests for `mix threadline.health.coverage` (Plan 66-02).

  Covers (per CONTEXT D-34 + D-35):
  - default table format renders three sections + footer literal
  - --json output decodes to the locked schema (top-level keys + entry keys + source enum)
  - --schema=public passes; --schema=Public fails with regex error; --schema=nonexistent fails with pg_namespace error
  - Mix task exits 0 even when uncovered tables exist (viewer, not gate)
  - --schema flag parity on mix threadline.verify_coverage (additive; default unchanged)
  """

  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Ecto.Adapters.SQL
  alias Mix.Tasks.Threadline.Health.Coverage
  alias Mix.Tasks.Threadline.VerifyCoverage
  alias Threadline.Capture.TriggerSQL

  @repo Threadline.Test.Repo

  setup do
    # Re-enable both Mix tasks so each test case can re-invoke (Pitfall 8 — Mix.Task
    # no-ops on a second run/2 within the same OS process unless reenabled).
    Mix.Task.reenable("threadline.health.coverage")
    Mix.Task.reenable("threadline.verify_coverage")
    :ok
  end

  describe "default table format" do
    test "prints TABLE / STATUS / SOURCE header and a Coverage summary line" do
      output =
        capture_io(fn ->
          Coverage.run([])
        end)

      # Header literals — MUST be present
      assert output =~ "TABLE"
      assert output =~ "STATUS"
      assert output =~ "SOURCE"

      # Footer summary literal — exact format per D-34 / UI-SPEC line 244
      assert output =~ ~r/Coverage: \d+ covered, \d+ uncovered, \d+ expected uncovered/

      # Status literals (at least one bucket should appear; expect schema_migrations as expected/baseline)
      assert output =~ "schema_migrations"
      assert output =~ "expected"
      assert output =~ "baseline"
    end

    test "exits 0 even when uncovered tables exist (viewer, not gate)" do
      # No assertion on exit code — if it raised, the test would fail.
      # Just verify the task completes without an exception.
      output =
        capture_io(fn ->
          Coverage.run([])
        end)

      assert is_binary(output)
    end
  end

  describe "--json output" do
    test "produces valid JSON with the locked top-level keys plus additive findings (HLTH-06/D-18)" do
      output =
        capture_io(fn ->
          Coverage.run(["--json"])
        end)

      parsed = Jason.decode!(output)

      assert parsed |> Map.keys() |> Enum.sort() ==
               ["covered", "expected_uncovered", "findings", "schema", "uncovered"]

      assert parsed["schema"] == "public"
      assert is_list(parsed["covered"])
      assert is_list(parsed["uncovered"])
      assert is_list(parsed["expected_uncovered"])
      assert is_list(parsed["findings"])
    end

    test ~s(expected_uncovered entries have keys ["source", "table"] and source ∈ {baseline, config}) do
      output =
        capture_io(fn ->
          Coverage.run(["--json"])
        end)

      parsed = Jason.decode!(output)

      for entry <- parsed["expected_uncovered"] do
        assert entry |> Map.keys() |> Enum.sort() == ["source", "table"]
        assert entry["source"] in ["baseline", "config"]
        assert is_binary(entry["table"])
      end
    end

    test "schema_migrations is in expected_uncovered with source baseline" do
      output =
        capture_io(fn ->
          Coverage.run(["--json"])
        end)

      parsed = Jason.decode!(output)

      schema_migrations_entry =
        Enum.find(parsed["expected_uncovered"], fn entry ->
          entry["table"] == "schema_migrations"
        end)

      assert schema_migrations_entry, "schema_migrations should appear in expected_uncovered"
      assert schema_migrations_entry["source"] == "baseline"
    end
  end

  describe "--schema=NAME validation" do
    test "--schema=public passes" do
      # Should not raise — public is the canonical schema.
      output =
        capture_io(fn ->
          Coverage.run(["--schema=public"])
        end)

      assert output =~ "TABLE"
    end

    test "--schema=Public fails the regex (uppercase rejected)" do
      assert_raise Mix.Error, ~r/not a valid PostgreSQL identifier|schema "Public"/, fn ->
        capture_io(fn ->
          Coverage.run(["--schema=Public"])
        end)
      end
    end

    test "--schema=nonexistent fails the pg_namespace lookup" do
      assert_raise Mix.Error, ~r/not found/, fn ->
        capture_io(fn ->
          Coverage.run([
            "--schema=nonexistent_schema_xyz_definitely_not_present"
          ])
        end)
      end
    end

    test "--schema with semicolon (SQL-injection probe) fails the regex" do
      assert_raise Mix.Error, ~r/not a valid PostgreSQL identifier/, fn ->
        capture_io(fn ->
          Coverage.run(["--schema=public;DROP"])
        end)
      end
    end
  end

  describe "mix threadline.verify_coverage --schema=NAME (additive flag)" do
    test "default behavior (no flag) is unchanged — same as before Phase 66" do
      # If this test fails, we broke the existing CI gate.
      # We don't assert exit code (verify_coverage may exit 1 on violations);
      # we just assert it runs to completion against the public schema.
      result =
        try do
          capture_io(fn ->
            VerifyCoverage.run([])
          end)
        catch
          :exit, {:shutdown, _} -> :ok
        end

      assert result == :ok or is_binary(result)
    end

    test "--schema=public is byte-equivalent to no-flag default" do
      out_no_flag =
        try do
          capture_io(fn -> VerifyCoverage.run([]) end)
        catch
          :exit, {:shutdown, _} -> ""
        end

      Mix.Task.reenable("threadline.verify_coverage")

      out_with_flag =
        try do
          capture_io(fn -> VerifyCoverage.run(["--schema=public"]) end)
        catch
          :exit, {:shutdown, _} -> ""
        end

      # Both runs should produce identical output for the default schema
      # (the schema is the only variable).
      if is_binary(out_no_flag) and is_binary(out_with_flag) do
        assert out_no_flag == out_with_flag
      end
    end

    test "--schema=Public fails the regex (uppercase rejected)" do
      assert_raise Mix.Error, ~r/not a valid PostgreSQL identifier/, fn ->
        capture_io(fn ->
          VerifyCoverage.run(["--schema=Public"])
        end)
      end
    end
  end

  describe "health.coverage findings (HLTH-06/D-18)" do
    setup do
      SQL.query!(@repo, "DROP SCHEMA IF EXISTS hcov_findings CASCADE", [])
      SQL.query!(@repo, "CREATE SCHEMA hcov_findings", [])
      SQL.query!(@repo, "CREATE TABLE hcov_findings.t (id bigserial PRIMARY KEY)", [])
      SQL.query!(@repo, TriggerSQL.create_trigger("hcov_findings.t"), [])

      SQL.query!(
        @repo,
        "ALTER TABLE hcov_findings.t DISABLE TRIGGER threadline_audit_hcov_findings_t",
        []
      )

      on_exit(fn ->
        SQL.query!(@repo, "DROP SCHEMA IF EXISTS hcov_findings CASCADE", [])
      end)

      :ok
    end

    test "--json findings entry has exactly the locked keys for a disabled trigger" do
      output =
        capture_io(fn ->
          Coverage.run(["--schema=hcov_findings", "--json"])
        end)

      parsed = Jason.decode!(output)

      assert [entry] = parsed["findings"]
      assert entry |> Map.keys() |> Enum.sort() == ~w(code details message schema severity table)
      assert entry["code"] == "capture_trigger_disabled"
      assert entry["severity"] == "error"
      assert entry["schema"] == "hcov_findings"
      assert entry["table"] == "t"
      assert entry["details"]["enabled_state"] == "D"
    end

    test "text mode shows FINDINGS section after the existing Coverage summary line" do
      output =
        capture_io(fn ->
          Coverage.run(["--schema=hcov_findings"])
        end)

      assert output =~ "FINDINGS"
      assert output =~ "SEVERITY"
      assert output =~ "CODE"
      assert output =~ "MESSAGE"
      assert output =~ "capture_trigger_disabled"
      assert output =~ "hcov_findings.t"

      coverage_index = :binary.match(output, "Coverage: ") |> elem(0)
      findings_index = :binary.match(output, "FINDINGS") |> elem(0)
      assert coverage_index < findings_index
    end

    test "the task returns :ok (no exit) with an error finding present" do
      assert Coverage.run(["--schema=hcov_findings"]) == :ok
    end

    test "a schema with no findings prints FINDINGS then none, and JSON emits an empty list" do
      SQL.query!(
        @repo,
        "ALTER TABLE hcov_findings.t ENABLE TRIGGER threadline_audit_hcov_findings_t",
        []
      )

      Mix.Task.reenable("threadline.health.coverage")

      text_output =
        capture_io(fn ->
          Coverage.run(["--schema=hcov_findings"])
        end)

      assert text_output =~ "FINDINGS"
      assert text_output =~ ~r/FINDINGS\nnone/

      Mix.Task.reenable("threadline.health.coverage")

      json_output =
        capture_io(fn ->
          Coverage.run(["--schema=hcov_findings", "--json"])
        end)

      assert Jason.decode!(json_output)["findings"] == []
    end
  end
end
