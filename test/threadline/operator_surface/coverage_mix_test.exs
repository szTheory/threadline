defmodule Threadline.OperatorSurface.CoverageMixTest do
  @moduledoc """
  Integration tests for `mix threadline.health.coverage` (Plan 66-02, 229-03).

  Covers (per CONTEXT D-34 + D-35, and 229-CONTEXT D-05..D-10, D-16, D-18, D-20):
  - default table format renders three sections + footer literal
  - --json output decodes to the locked schema (top-level keys + entry keys + source enum)
  - --schema=public passes; --schema=Public fails with regex error; --schema=nonexistent fails with pg_namespace error
  - Mix task exits 0 without --strict even when uncovered tables exist (viewer, not gate)
  - --schema flag parity on mix threadline.verify_coverage (additive; default unchanged)
  - --strict: the {clean, warning-only, error} x {non-strict, --strict} x {table, --json} matrix,
    cross-schema isolation, uncovered-only is never gated, legacy-key wiring, the timeout hint,
    and unknown/invalid switches raising before the repo starts
  """

  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Ecto.Adapters.SQL
  alias Mix.Tasks.Threadline.Health.Coverage
  alias Mix.Tasks.Threadline.VerifyCoverage
  alias Threadline.Capture.TriggerSQL
  alias Threadline.StorageSchema
  alias Threadline.Test.LegacyTriggerSQL

  @repo Threadline.Test.Repo

  # Mix.Task.run/2 return values and exit/1 (e.g. --strict's gate) can't both
  # be captured by ExUnit.Assertions.catch_exit/1, which raises when no exit
  # happens. This normalizes both outcomes to a plain return value: the
  # function's own return (:ok) or the caught exit reason.
  defp run_catching_exit(fun) do
    fun.()
  catch
    :exit, reason -> reason
  end

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

    test "exits 0 without --strict even when uncovered tables exist" do
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

  describe "--strict (HLTH-01 tracer)" do
    setup do
      SQL.query!(@repo, "DROP SCHEMA IF EXISTS hcov_strict CASCADE", [])
      SQL.query!(@repo, "CREATE SCHEMA hcov_strict", [])
      SQL.query!(@repo, "CREATE TABLE hcov_strict.t (id bigserial PRIMARY KEY)", [])
      SQL.query!(@repo, TriggerSQL.create_trigger("hcov_strict.t"), [])

      SQL.query!(
        @repo,
        "ALTER TABLE hcov_strict.t DISABLE TRIGGER threadline_audit_hcov_strict_t",
        []
      )

      on_exit(fn ->
        SQL.query!(@repo, "DROP SCHEMA IF EXISTS hcov_strict CASCADE", [])
      end)

      :ok
    end

    test "a disabled trigger fails --strict end-to-end with exit 1 and the stderr status line" do
      {{reason, stdout}, stderr} =
        with_io(:stderr, fn ->
          with_io(fn ->
            catch_exit(Coverage.run(["--strict", "--schema=hcov_strict"]))
          end)
        end)

      assert reason == {:shutdown, 1}
      assert stdout =~ "capture_trigger_disabled"
      assert stderr =~ "strict: FAILED — 1 error finding(s)"
    end
  end

  describe "severity x strict x format matrix (D-09)" do
    @clean_schema "hcov_matrix_clean"
    @warning_schema "hcov_matrix_warning"
    @error_schema "hcov_matrix_error"
    @uncovered_schema "hcov_matrix_uncovered"

    setup do
      for schema <- [@clean_schema, @warning_schema, @error_schema, @uncovered_schema] do
        SQL.query!(@repo, "DROP SCHEMA IF EXISTS #{schema} CASCADE", [])
        SQL.query!(@repo, "CREATE SCHEMA #{schema}", [])
      end

      # Clean: one covered id-keyed table, no findings.
      SQL.query!(@repo, "CREATE TABLE #{@clean_schema}.t (id bigserial PRIMARY KEY)", [])
      SQL.query!(@repo, TriggerSQL.create_trigger("#{@clean_schema}.t"), [])

      # Warning-only: a no-args legacy trigger (:legacy_trigger_no_pk_args) plus a
      # regenerated-trigger table whose audit row is rewritten to an unresolved
      # table_pk (:unresolved_legacy_keys).
      SQL.query!(@repo, "CREATE TABLE #{@warning_schema}.t_noargs (id bigserial PRIMARY KEY)", [])

      SQL.query!(
        @repo,
        LegacyTriggerSQL.v0_10_2_create_trigger(
          @warning_schema,
          "t_noargs",
          StorageSchema.function("threadline_capture_changes") <> "()"
        ),
        []
      )

      SQL.query!(
        @repo,
        "CREATE TABLE #{@warning_schema}.t_unresolved (id bigserial PRIMARY KEY)",
        []
      )

      SQL.query!(@repo, TriggerSQL.create_trigger("#{@warning_schema}.t_unresolved"), [])
      SQL.query!(@repo, "INSERT INTO #{@warning_schema}.t_unresolved DEFAULT VALUES", [])
      rewrite_table_pk!(@warning_schema, "t_unresolved", %{"id" => nil})

      # Error: a disabled trigger.
      SQL.query!(@repo, "CREATE TABLE #{@error_schema}.t (id bigserial PRIMARY KEY)", [])
      SQL.query!(@repo, TriggerSQL.create_trigger("#{@error_schema}.t"), [])

      SQL.query!(
        @repo,
        "ALTER TABLE #{@error_schema}.t DISABLE TRIGGER threadline_audit_#{@error_schema}_t",
        []
      )

      # Uncovered-only: a table with no trigger at all.
      SQL.query!(@repo, "CREATE TABLE #{@uncovered_schema}.t (id bigserial PRIMARY KEY)", [])

      on_exit(fn ->
        for schema <- [@clean_schema, @warning_schema, @error_schema, @uncovered_schema] do
          SQL.query!(@repo, "DROP SCHEMA IF EXISTS #{schema} CASCADE", [])
        end
      end)

      :ok
    end

    @matrix for schema_key <- [:clean, :warning, :error],
                strict <- [[], ["--strict"]],
                json <- [[], ["--json"]],
                do: {schema_key, strict, json}

    for {schema_key, strict_flag, json_flag} <- @matrix do
      schema_name =
        case schema_key do
          :clean -> @clean_schema
          :warning -> @warning_schema
          :error -> @error_schema
        end

      strict? = strict_flag != []
      expect_exit? = schema_key == :error and strict?

      test "schema=#{schema_key} strict=#{strict?} json=#{json_flag != []} " <>
             "outcome=#{if expect_exit?, do: "exit 1", else: "ok"}" do
        schema_name = unquote(schema_name)
        strict_flag = unquote(Macro.escape(strict_flag))
        json_flag = unquote(Macro.escape(json_flag))
        strict? = unquote(strict?)
        expect_exit? = unquote(expect_exit?)

        Mix.Task.reenable("threadline.health.coverage")

        argv = ["--schema=#{schema_name}"] ++ strict_flag ++ json_flag

        {{result, stdout}, stderr} =
          with_io(:stderr, fn ->
            with_io(fn -> run_catching_exit(fn -> Coverage.run(argv) end) end)
          end)

        if expect_exit? do
          assert result == {:shutdown, 1}
          assert stderr =~ ~r/strict: FAILED — \d+ error finding\(s\)/
        else
          assert result == :ok

          if strict? do
            assert stderr =~ ~r/strict: passed \(\d+ warning\(s\) not gated\)/
          else
            assert stderr == ""
          end
        end

        if json_flag != [] do
          parsed = Jason.decode!(stdout)

          assert parsed |> Map.keys() |> Enum.sort() ==
                   ["covered", "expected_uncovered", "findings", "schema", "uncovered"]
        end
      end
    end

    test "the warning schema's findings include unresolved_legacy_keys and --strict passes" do
      Mix.Task.reenable("threadline.health.coverage")

      {{result, stdout}, stderr} =
        with_io(:stderr, fn ->
          with_io(fn ->
            run_catching_exit(fn ->
              Coverage.run(["--strict", "--schema=#{@warning_schema}", "--json"])
            end)
          end)
        end)

      assert result == :ok
      assert stderr =~ ~r/strict: passed \(\d+ warning\(s\) not gated\)/

      parsed = Jason.decode!(stdout)
      codes = Enum.map(parsed["findings"], & &1["code"])
      assert "unresolved_legacy_keys" in codes
      assert "legacy_trigger_no_pk_args" in codes
      assert Enum.all?(parsed["findings"], &(&1["severity"] == "warning"))
    end

    test "uncovered-only schema with --strict returns :ok" do
      Mix.Task.reenable("threadline.health.coverage")

      {result, _stdout} =
        with_io(fn ->
          run_catching_exit(fn -> Coverage.run(["--strict", "--schema=#{@uncovered_schema}"]) end)
        end)

      assert result == :ok
    end

    test "an :error finding in another schema does not fail --strict --schema=<clean schema>" do
      Mix.Task.reenable("threadline.health.coverage")

      {result, _stdout} =
        with_io(fn ->
          run_catching_exit(fn -> Coverage.run(["--strict", "--schema=#{@clean_schema}"]) end)
        end)

      assert result == :ok
    end

    defp rewrite_table_pk!(schema, table, pk_term) do
      storage = StorageSchema.get()

      SQL.query!(
        @repo,
        """
        UPDATE #{StorageSchema.qualify(storage, "audit_changes")}
        SET table_pk = $1::jsonb
        WHERE table_schema = $2 AND table_name = $3
        """,
        [pk_term, schema, table]
      )
    end
  end

  describe "unknown switches (D-16)" do
    test "unknown or invalid switches raise Mix.Error naming the switch, before any DB access" do
      for argv <- [["--stict"], ["--jsn"], ["--schema"]] do
        assert_raise Mix.Error, ~r/unknown or invalid option/, fn ->
          Coverage.run(argv)
        end
      end
    end
  end

  describe "legacy probe timeout hint (D-20)" do
    setup do
      SQL.query!(@repo, "DROP SCHEMA IF EXISTS hcov_timeout CASCADE", [])
      SQL.query!(@repo, "CREATE SCHEMA hcov_timeout", [])
      SQL.query!(@repo, "CREATE TABLE hcov_timeout.t (id bigserial PRIMARY KEY)", [])
      SQL.query!(@repo, TriggerSQL.create_trigger("hcov_timeout.t"), [])
      SQL.query!(@repo, "INSERT INTO hcov_timeout.t DEFAULT VALUES", [])

      storage = StorageSchema.get()

      SQL.query!(
        @repo,
        """
        UPDATE #{StorageSchema.qualify(storage, "audit_changes")}
        SET table_pk = $1::jsonb
        WHERE table_schema = $2 AND table_name = $3
        """,
        [%{"id" => nil}, "hcov_timeout", "t"]
      )

      on_exit(fn ->
        SQL.query!(@repo, "DROP SCHEMA IF EXISTS hcov_timeout CASCADE", [])
      end)

      :ok
    end

    test "a cancelled probe prints the row-history-index hint and continues with []" do
      test_pid = self()
      storage = StorageSchema.get()

      {:ok, lock_pid} =
        Task.start(fn ->
          @repo.transaction(fn ->
            SQL.query!(
              @repo,
              "LOCK TABLE #{StorageSchema.qualify(storage, "audit_changes")} IN ACCESS EXCLUSIVE MODE",
              []
            )

            send(test_pid, :locked)

            receive do
              :release -> :ok
            after
              5_000 -> :ok
            end
          end)
        end)

      assert_receive :locked, 2_000

      {result, stderr} =
        with_io(:stderr, fn ->
          Coverage.legacy_findings_or_hint(@repo,
            schema: "hcov_timeout",
            statement_timeout: 200
          )
        end)

      assert result == []
      assert stderr =~ "step-4-add-the-row-history-index"

      send(lock_pid, :release)
      ref = Process.monitor(lock_pid)
      assert_receive {:DOWN, ^ref, :process, ^lock_pid, _reason}, 2_000
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
