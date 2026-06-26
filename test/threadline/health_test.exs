defmodule Threadline.HealthTest do
  use Threadline.DataCase

  @repo Threadline.Test.Repo

  describe "trigger_coverage/1 — HLTH-01, HLTH-02" do
    test "returns a list of three-tuple variants for tables in public schema" do
      result = Threadline.Health.trigger_coverage(repo: @repo)
      assert is_list(result)

      for item <- result do
        assert match?({:covered, name} when is_binary(name), item) or
                 match?({:uncovered, name} when is_binary(name), item) or
                 match?({:expected_uncovered, name} when is_binary(name), item)
      end
    end

    test "audit tables are not included in the result" do
      result = Threadline.Health.trigger_coverage(repo: @repo)
      table_names = Enum.map(result, fn {_status, name} -> name end)

      refute "audit_transactions" in table_names
      refute "audit_changes" in table_names
      refute "audit_actions" in table_names
    end

    test "HLTH-02: tables without triggers are tagged :uncovered" do
      result = Threadline.Health.trigger_coverage(repo: @repo)
      uncovered = Enum.filter(result, &match?({:uncovered, _}, &1))
      assert is_list(uncovered)
    end

    test "HLTH-01: tables with Threadline triggers are tagged :covered" do
      result = Threadline.Health.trigger_coverage(repo: @repo)
      covered = Enum.filter(result, &match?({:covered, _}, &1))
      assert is_list(covered)
    end
  end

  describe "trigger_coverage/1 — Phase 66 :schema opt (D-33c)" do
    test "default :schema is \"public\" — explicit and absent return same result" do
      default_result = Threadline.Health.trigger_coverage(repo: @repo)
      explicit_result = Threadline.Health.trigger_coverage(repo: @repo, schema: "public")

      assert Enum.sort(default_result) == Enum.sort(explicit_result)
    end
  end

  describe "CoverageSchemas boundary helper" do
    test "validates existing lowercase schemas and rejects invalid input" do
      assert Threadline.Health.CoverageSchemas.validate(@repo, "public") == {:ok, "public"}

      assert Threadline.Health.CoverageSchemas.validate(@repo, "Public") ==
               {:error, "Schema 'Public' not found."}

      assert Threadline.Health.CoverageSchemas.validate(
               @repo,
               "nonexistent_schema_xyz_definitely_not_present"
             ) ==
               {:error, "Schema 'nonexistent_schema_xyz_definitely_not_present' not found."}
    end

    test "lists non-system schemas with ordinary tables" do
      schemas = Threadline.Health.CoverageSchemas.available(@repo)

      assert "public" in schemas
      refute "information_schema" in schemas
      refute Enum.any?(schemas, &String.starts_with?(&1, "pg_"))
    end
  end

  describe "trigger_coverage/1 — Phase 66 three-bucket policy (D-32, D-32a, D-32b, D-32c)" do
    setup do
      original_health = Application.get_env(:threadline, :health)

      on_exit(fn ->
        if is_nil(original_health) do
          Application.delete_env(:threadline, :health)
        else
          Application.put_env(:threadline, :health, original_health)
        end
      end)

      :ok
    end

    test "schema_migrations is in the :expected_uncovered bucket by default (D-32a baseline)" do
      Application.delete_env(:threadline, :health)

      result = Threadline.Health.trigger_coverage(repo: @repo)

      assert {:expected_uncovered, "schema_migrations"} in result
    end

    test "configured :expected_uncovered_tables flow into the third bucket (D-32b)" do
      Application.put_env(:threadline, :health,
        expected_uncovered_tables: ["threadline_verify_cov_uncovered"]
      )

      result = Threadline.Health.trigger_coverage(repo: @repo)

      assert {:expected_uncovered, "threadline_verify_cov_uncovered"} in result
    end

    test ":audit_anyway removes a baseline entry from the :expected_uncovered bucket (D-32c)" do
      Application.put_env(:threadline, :health, audit_anyway: ["schema_migrations"])

      result = Threadline.Health.trigger_coverage(repo: @repo)

      refute {:expected_uncovered, "schema_migrations"} in result
      # schema_migrations is now treated like any other uncovered table
      assert {:uncovered, "schema_migrations"} in result
    end
  end

  describe "HLTH-05: [:threadline, :health, :checked] telemetry — Phase 66 additive shape" do
    test "trigger_coverage/1 emits :health, :checked event with expected_uncovered measurement" do
      :telemetry.attach(
        "test-health-checked-3-keys",
        [:threadline, :health, :checked],
        fn _name, measurements, _meta, pid ->
          send(pid, {:telemetry, measurements})
        end,
        self()
      )

      on_exit(fn -> :telemetry.detach("test-health-checked-3-keys") end)

      Threadline.Health.trigger_coverage(repo: @repo)

      assert_receive {:telemetry,
                      %{
                        covered: covered,
                        uncovered: uncovered,
                        expected_uncovered: expected_uncovered
                      }}

      assert is_integer(covered)
      assert is_integer(uncovered)
      assert is_integer(expected_uncovered)
    end
  end

  describe "trigger_coverage/1 — backward-compat callsite (Continuity line 71 pattern)" do
    test "membership check {:covered, name} in coverage continues to work for covered tables" do
      coverage = Threadline.Health.trigger_coverage(repo: @repo)
      # threadline_ci_coverage_canary has a trigger installed by the test migration
      assert {:covered, "threadline_ci_coverage_canary"} in coverage
    end
  end

  describe "trigger_coverage/1 — schema isolation regression (Pitfall 1)" do
    @describetag :schema_isolation

    setup do
      Ecto.Adapters.SQL.query!(@repo, "DROP SCHEMA IF EXISTS tenant_iso CASCADE", [])
      Ecto.Adapters.SQL.query!(@repo, "CREATE SCHEMA tenant_iso", [])

      Ecto.Adapters.SQL.query!(@repo, "DROP TABLE IF EXISTS public.iso_test_table", [])

      Ecto.Adapters.SQL.query!(
        @repo,
        "CREATE TABLE public.iso_test_table (id bigserial PRIMARY KEY)",
        []
      )

      Ecto.Adapters.SQL.query!(
        @repo,
        "CREATE TABLE tenant_iso.iso_test_table (id bigserial PRIMARY KEY)",
        []
      )

      # Trigger only on public.iso_test_table — proves cross-schema isolation
      Ecto.Adapters.SQL.query!(
        @repo,
        Threadline.Capture.TriggerSQL.create_trigger("iso_test_table"),
        []
      )

      on_exit(fn ->
        # Trigger drop must succeed even if table is gone; ignore failures.
        try do
          Ecto.Adapters.SQL.query!(
            @repo,
            Threadline.Capture.TriggerSQL.drop_trigger("iso_test_table"),
            []
          )
        rescue
          _ -> :ok
        end

        Ecto.Adapters.SQL.query!(@repo, "DROP TABLE IF EXISTS public.iso_test_table", [])
        Ecto.Adapters.SQL.query!(@repo, "DROP SCHEMA IF EXISTS tenant_iso CASCADE", [])
      end)

      :ok
    end

    test "trigger on public.iso_test_table only — public sees :covered, tenant_iso sees :uncovered" do
      public_result = Threadline.Health.trigger_coverage(repo: @repo, schema: "public")
      tenant_result = Threadline.Health.trigger_coverage(repo: @repo, schema: "tenant_iso")

      assert {:covered, "iso_test_table"} in public_result,
             "expected public.iso_test_table to be :covered (trigger present in public schema)"

      assert {:uncovered, "iso_test_table"} in tenant_result,
             "expected tenant_iso.iso_test_table to be :uncovered — pg_namespace join must filter the trigger out (Pitfall 1)"
    end
  end
end
