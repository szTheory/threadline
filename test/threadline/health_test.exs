defmodule Threadline.HealthTest do
  use Threadline.DataCase

  @repo Threadline.Test.Repo

  describe "trigger_coverage/1 — HLTH-01, HLTH-02" do
    test "returns a list of tagged tuples for tables in public schema" do
      result = Threadline.Health.trigger_coverage(repo: @repo)
      assert is_list(result)

      for item <- result do
        assert match?({:covered, name} when is_binary(name), item) or
                 match?({:uncovered, name} when is_binary(name), item)
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

  describe "HLTH-05: [:threadline, :health, :checked] telemetry" do
    test "trigger_coverage/1 emits :health, :checked event" do
      :telemetry.attach(
        "test-health-checked",
        [:threadline, :health, :checked],
        fn _name, measurements, _meta, pid ->
          send(pid, {:telemetry, measurements})
        end,
        self()
      )

      on_exit(fn -> :telemetry.detach("test-health-checked") end)

      Threadline.Health.trigger_coverage(repo: @repo)

      assert_receive {:telemetry, %{covered: covered, uncovered: uncovered}}
      assert is_integer(covered)
      assert is_integer(uncovered)
    end
  end
end
