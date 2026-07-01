defmodule Threadline.VerifyCoverageTaskTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Threadline.Capture.TriggerSQL

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

  test "SC4: policy violations align with trigger_coverage tuples for expected overlap" do
    coverage = Threadline.Health.trigger_coverage(repo: @repo)
    expected = ["threadline_ci_coverage_canary"]

    tuples_for_expected =
      coverage
      |> Enum.filter(fn {_s, name} -> name in expected end)
      |> MapSet.new()

    policy_input = MapSet.new(coverage)

    assert MapSet.subset?(tuples_for_expected, policy_input)
    assert Threadline.Verify.CoveragePolicy.violations(coverage, expected) == []
  end

  describe "selected host schema support" do
    setup do
      prepare_support_tickets!()

      original_storage_schema = Application.get_env(:threadline, :storage_schema)
      original_verify_coverage = Application.get_env(:threadline, :verify_coverage)

      on_exit(fn ->
        Ecto.Adapters.SQL.query!(@repo, "DROP SCHEMA IF EXISTS support CASCADE", [])
        restore_env(:storage_schema, original_storage_schema)
        restore_env(:verify_coverage, original_verify_coverage)
      end)

      :ok
    end

    test "health coverage reports support.tickets only when --schema=support is selected" do
      Threadline.StorageSchemaCase.with_storage_schema("audit", fn ->
        coverage = Threadline.Health.trigger_coverage(repo: @repo, schema: "support")

        assert {:covered, "tickets"} in coverage
        refute Enum.any?(coverage, fn {_status, table} -> table == "threadline_ci_coverage_canary" end)
        assert Application.get_env(:threadline, :storage_schema) == "audit"
      end)
    end

    test "mix threadline.health.coverage --schema=support reports support tables only" do
      Mix.Task.reenable("threadline.health.coverage")

      output =
        capture_io(fn ->
          Mix.Tasks.Threadline.Health.Coverage.run(["--schema=support", "--json"])
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
          Mix.Tasks.Threadline.VerifyCoverage.run(["--schema=support"])
        end)

      assert output =~ "tickets"
      assert output =~ "covered"
      assert output =~ "summary: 1/1 expected tables covered (0 violated)"
    end
  end

  defp prepare_support_tickets! do
    Ecto.Adapters.SQL.query!(@repo, "DROP SCHEMA IF EXISTS support CASCADE", [])
    Ecto.Adapters.SQL.query!(@repo, "CREATE SCHEMA support", [])

    Ecto.Adapters.SQL.query!(
      @repo,
      """
      CREATE TABLE support.tickets (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        subject text NOT NULL
      )
      """,
      []
    )

    Ecto.Adapters.SQL.query!(@repo, TriggerSQL.create_trigger("support.tickets"), [])
  end

  defp restore_env(key, nil), do: Application.delete_env(:threadline, key)
  defp restore_env(key, value), do: Application.put_env(:threadline, key, value)
end
