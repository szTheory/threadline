defmodule Threadline.VerifyCoverageTaskTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Ecto.Adapters.SQL
  alias Mix.Tasks.Threadline.Health.Coverage
  alias Mix.Tasks.Threadline.VerifyCoverage
  alias Threadline.Capture.TriggerSQL
  alias Threadline.Test.LegacyTriggerSQL
  alias Threadline.Verify.CoveragePolicy

  @repo Threadline.Test.Repo

  defp cmd_env(extra) do
    System.get_env()
    |> Map.merge(Map.new(extra))
    |> Map.to_list()
  end

  test "mix threadline.verify_coverage exits 0 when expected canary table is covered" do
    assert {output, 0} =
             System.cmd(
               "mix",
               ["threadline.verify_coverage"],
               cd: File.cwd!(),
               env: cmd_env(%{"MIX_ENV" => "test"}),
               stderr_to_stdout: true
             )

    assert output =~ "summary:"
    assert output =~ "threadline_ci_coverage_canary"
    assert output =~ "covered"
  end

  test "mix threadline.verify_coverage exits 1 when expected table lacks trigger (SC1)" do
    env =
      cmd_env(%{
        "MIX_ENV" => "test",
        "THREADLINE_VERIFY_COVERAGE_FAILURE_TEST" => "1"
      })

    assert {output, exit_status} =
             System.cmd(
               "mix",
               ["threadline.verify_coverage"],
               cd: File.cwd!(),
               env: env,
               stderr_to_stdout: true
             )

    assert exit_status == 1
    assert output =~ "threadline_verify_cov_uncovered"
    assert output =~ "uncovered"
    assert output =~ "summary:"
  end

  describe "findings gate — OS-level exit status (D-17)" do
    setup do
      SQL.query!(@repo, "DROP TABLE IF EXISTS public.threadline_verify_cov_findings", [])

      SQL.query!(
        @repo,
        "CREATE TABLE public.threadline_verify_cov_findings (id bigserial PRIMARY KEY)",
        []
      )

      SQL.query!(@repo, TriggerSQL.create_trigger("threadline_verify_cov_findings"), [])

      on_exit(fn ->
        SQL.query!(@repo, "DROP TABLE IF EXISTS public.threadline_verify_cov_findings", [])
      end)

      :ok
    end

    test "exits 1 when the findings-gated table's trigger is disabled" do
      SQL.query!(
        @repo,
        "ALTER TABLE public.threadline_verify_cov_findings DISABLE TRIGGER threadline_audit_threadline_verify_cov_findings",
        []
      )

      env =
        cmd_env(%{
          "MIX_ENV" => "test",
          "THREADLINE_VERIFY_COVERAGE_FINDINGS_TEST" => "1"
        })

      assert {output, exit_status} =
               System.cmd(
                 "mix",
                 ["threadline.verify_coverage"],
                 cd: File.cwd!(),
                 env: env,
                 stderr_to_stdout: true
               )

      assert exit_status == 1
      assert output =~ "capture_trigger_disabled"
    end

    test "exits 0 when the same table's trigger is enabled (clean negative control)" do
      env =
        cmd_env(%{
          "MIX_ENV" => "test",
          "THREADLINE_VERIFY_COVERAGE_FINDINGS_TEST" => "1"
        })

      assert {_output, exit_status} =
               System.cmd(
                 "mix",
                 ["threadline.verify_coverage"],
                 cd: File.cwd!(),
                 env: env,
                 stderr_to_stdout: true
               )

      assert exit_status == 0
    end
  end

  describe "malformed :trigger_capture config (D-07)" do
    setup do
      original = Application.get_env(:threadline, :trigger_capture)

      on_exit(fn ->
        case original do
          nil -> Application.delete_env(:threadline, :trigger_capture)
          value -> Application.put_env(:threadline, :trigger_capture, value)
        end
      end)

      Application.put_env(:threadline, :trigger_capture, tables: %{"x" => [primary_key: "id"]})
      :ok
    end

    test "VerifyCoverage.run/1 raises Mix.Error naming the config" do
      Mix.Task.reenable("threadline.verify_coverage")

      assert_raise Mix.Error, ~r/config :threadline, :trigger_capture/, fn ->
        capture_io(fn -> VerifyCoverage.run([]) end)
      end
    end

    test "Coverage.run/1 raises Mix.Error naming the config" do
      Mix.Task.reenable("threadline.health.coverage")

      assert_raise Mix.Error, ~r/config :threadline, :trigger_capture/, fn ->
        capture_io(fn -> Coverage.run([]) end)
      end
    end
  end

  test "SC4: policy violations align with trigger_coverage tuples for expected overlap" do
    coverage = Threadline.Health.trigger_coverage(repo: @repo)
    expected = ["threadline_ci_coverage_canary"]

    tuples_for_expected =
      coverage
      |> Enum.filter(fn {_s, name} -> name in expected end)
      |> MapSet.new()

    policy_input = MapSet.new(coverage)

    assert MapSet.subset?(tuples_for_expected, policy_input)
    assert CoveragePolicy.violations(coverage, expected) == []
  end

  describe "selected host schema support" do
    setup do
      prepare_support_tickets!()

      original_storage_schema = Application.get_env(:threadline, :storage_schema)
      original_verify_coverage = Application.get_env(:threadline, :verify_coverage)

      on_exit(fn ->
        SQL.query!(@repo, "DROP SCHEMA IF EXISTS support CASCADE", [])
        restore_env(:storage_schema, original_storage_schema)
        restore_env(:verify_coverage, original_verify_coverage)
      end)

      :ok
    end

    test "health coverage reports support.tickets only when --schema=support is selected" do
      Threadline.StorageSchemaCase.with_storage_schema("audit", fn ->
        coverage = Threadline.Health.trigger_coverage(repo: @repo, schema: "support")

        assert {:covered, "tickets"} in coverage

        refute Enum.any?(coverage, fn {_status, table} ->
                 table == "threadline_ci_coverage_canary"
               end)

        assert Application.get_env(:threadline, :storage_schema) == "audit"
      end)
    end

    test "mix threadline.health.coverage --schema=support reports support tables only" do
      Mix.Task.reenable("threadline.health.coverage")

      output =
        capture_io(fn ->
          Coverage.run(["--schema=support", "--json"])
        end)

      parsed = Jason.decode!(output)

      assert parsed["schema"] == "support"
      assert parsed["covered"] == ["tickets"]
      refute "threadline_ci_coverage_canary" in parsed["covered"]
    end

    test "mix threadline.verify_coverage --schema=support verifies support table names" do
      Application.put_env(:threadline, :verify_coverage, expected_tables: ["tickets"])
      Mix.Task.reenable("threadline.verify_coverage")

      output =
        capture_io(fn ->
          VerifyCoverage.run(["--schema=support"])
        end)

      assert output =~ "tickets"
      assert output =~ "covered"
      assert output =~ "summary: 1/1 expected tables covered (0 violated)"
    end
  end

  describe "findings gate" do
    setup do
      SQL.query!(@repo, "DROP SCHEMA IF EXISTS vcov_findings CASCADE", [])
      SQL.query!(@repo, "CREATE SCHEMA vcov_findings", [])

      SQL.query!(@repo, "CREATE TABLE vcov_findings.gated_t (id bigserial PRIMARY KEY)", [])
      SQL.query!(@repo, "CREATE TABLE vcov_findings.other_t (id bigserial PRIMARY KEY)", [])
      SQL.query!(@repo, "CREATE TABLE vcov_findings.legacy_t (id bigserial PRIMARY KEY)", [])

      SQL.query!(@repo, TriggerSQL.create_trigger("vcov_findings.gated_t"), [])
      SQL.query!(@repo, TriggerSQL.create_trigger("vcov_findings.other_t"), [])

      original_verify_coverage = Application.get_env(:threadline, :verify_coverage)

      on_exit(fn ->
        SQL.query!(@repo, "DROP SCHEMA IF EXISTS vcov_findings CASCADE", [])
        restore_env(:verify_coverage, original_verify_coverage)
      end)

      :ok
    end

    test "(a) a disabled trigger on an expected table exits {:shutdown, 1} and prints the finding" do
      SQL.query!(
        @repo,
        "ALTER TABLE vcov_findings.gated_t DISABLE TRIGGER threadline_audit_vcov_findings_gated_t",
        []
      )

      Application.put_env(:threadline, :verify_coverage, expected_tables: ["gated_t"])
      Mix.Task.reenable("threadline.verify_coverage")

      {reason, output} =
        with_io(fn -> catch_exit(VerifyCoverage.run(["--schema=vcov_findings"])) end)

      assert reason == {:shutdown, 1}
      assert output =~ "capture_trigger_disabled"
      assert output =~ "vcov_findings.gated_t"
    end

    test "(b) a disabled trigger on the only listed table fails when a different table is listed" do
      SQL.query!(
        @repo,
        "ALTER TABLE vcov_findings.other_t DISABLE TRIGGER threadline_audit_vcov_findings_other_t",
        []
      )

      Application.put_env(:threadline, :verify_coverage, expected_tables: ["other_t"])
      Mix.Task.reenable("threadline.verify_coverage")

      {reason, output} =
        with_io(fn -> catch_exit(VerifyCoverage.run(["--schema=vcov_findings"])) end)

      assert reason == {:shutdown, 1}
      assert output =~ "capture_trigger_disabled"
      assert output =~ "vcov_findings.other_t"
    end

    test "(c) an error on an unlisted table prints NOT GATED and does not exit" do
      SQL.query!(
        @repo,
        "ALTER TABLE vcov_findings.other_t DISABLE TRIGGER threadline_audit_vcov_findings_other_t",
        []
      )

      Application.put_env(:threadline, :verify_coverage, expected_tables: ["gated_t"])
      Mix.Task.reenable("threadline.verify_coverage")

      output =
        capture_io(fn -> VerifyCoverage.run(["--schema=vcov_findings"]) end)

      assert output =~ "NOT GATED"
      assert output =~ "vcov_findings.other_t"
    end

    test "(d) a legacy no-arg trigger yields a printed warning and does not exit" do
      SQL.query!(
        @repo,
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "vcov_findings",
          "legacy_t",
          ~s|"threadline"."threadline_capture_changes"()|
        ),
        []
      )

      Application.put_env(:threadline, :verify_coverage, expected_tables: ["legacy_t"])
      Mix.Task.reenable("threadline.verify_coverage")

      output =
        capture_io(fn -> VerifyCoverage.run(["--schema=vcov_findings"]) end)

      assert output =~ "legacy_trigger_no_pk_args"
    end

    test "(e) no findings prints findings: none" do
      Application.put_env(:threadline, :verify_coverage, expected_tables: ["gated_t"])
      Mix.Task.reenable("threadline.verify_coverage")

      output =
        capture_io(fn -> VerifyCoverage.run(["--schema=vcov_findings"]) end)

      assert output =~ "findings: none"
    end
  end

  defp prepare_support_tickets! do
    SQL.query!(@repo, "DROP SCHEMA IF EXISTS support CASCADE", [])
    SQL.query!(@repo, "CREATE SCHEMA support", [])

    SQL.query!(
      @repo,
      """
      CREATE TABLE support.tickets (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        subject text NOT NULL
      )
      """,
      []
    )

    SQL.query!(@repo, TriggerSQL.create_trigger("support.tickets"), [])
  end

  defp restore_env(key, nil), do: Application.delete_env(:threadline, key)
  defp restore_env(key, value), do: Application.put_env(:threadline, key, value)
end
