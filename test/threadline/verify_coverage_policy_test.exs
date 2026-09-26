defmodule Threadline.VerifyCoveragePolicyTest do
  use ExUnit.Case, async: true

  alias Threadline.Health.Finding
  alias Threadline.Verify.CoveragePolicy

  describe "violations/2" do
    test "all expected covered → no violations" do
      coverage = [{:covered, "a"}, {:uncovered, "b"}, {:covered, "c"}]
      assert CoveragePolicy.violations(coverage, ["a", "c"]) == []
    end

    test "one expected uncovered → one {:uncovered, tuple}" do
      coverage = [{:covered, "a"}, {:uncovered, "posts"}, {:covered, "c"}]

      assert CoveragePolicy.violations(coverage, ["posts"]) == [{:uncovered, "posts"}]
    end

    test "expected table absent from coverage list → {:missing, name}" do
      coverage = [{:covered, "only_me"}]

      assert CoveragePolicy.violations(coverage, ["ghost"]) == [{:missing, "ghost"}]
    end

    test "empty expected → [] (Mix task fails closed before calling for empty config)" do
      coverage = [{:uncovered, "x"}]
      assert CoveragePolicy.violations(coverage, []) == []
    end

    test "violations are sorted by table name" do
      coverage = [
        {:uncovered, "zebra"},
        {:covered, "apple"},
        {:uncovered, "mango"}
      ]

      assert CoveragePolicy.violations(coverage, ["zebra", "mango", "missing"]) == [
               {:missing, "missing"},
               {:uncovered, "mango"},
               {:uncovered, "zebra"}
             ]
    end

    test "expected_uncovered tuples do not produce violations (Phase 66 D-32f)" do
      coverage = [
        {:covered, "users"},
        {:expected_uncovered, "schema_migrations"},
        {:uncovered, "orders"}
      ]

      expected = ["users"]

      # users is covered → no violation; schema_migrations & orders aren't expected,
      # so they don't trigger the case at all.
      assert CoveragePolicy.violations(coverage, expected) == []

      coverage_with_violation = [
        {:expected_uncovered, "schema_migrations"},
        {:uncovered, "orders"}
      ]

      expected = ["users"]

      # users missing-from-coverage still flags as :missing (not present in by_table at all)
      assert CoveragePolicy.violations(coverage_with_violation, expected) == [{:missing, "users"}]
    end
  end

  describe "summary_counts/2" do
    test "counts covered vs violated expected tables" do
      coverage = [{:covered, "a"}, {:uncovered, "b"}]

      assert CoveragePolicy.summary_counts(coverage, ["a", "b"]) == %{
               expected: 2,
               covered: 1,
               violated: 1
             }
    end
  end

  describe "partition_findings/2" do
    defp finding(attrs) do
      struct!(
        Finding,
        Map.merge(
          %{
            code: :capture_trigger_disabled,
            severity: :error,
            schema: "public",
            table: "t",
            message: "fix it",
            details: %{}
          },
          attrs
        )
      )
    end

    test "an :error finding for an expected table is gated" do
      f = finding(%{table: "gated_t"})

      assert CoveragePolicy.partition_findings([f], ["gated_t"]) == %{
               gated: [f],
               not_gated: [],
               warnings: []
             }
    end

    test "an :error finding for an unlisted table is not_gated" do
      f = finding(%{table: "other_t"})

      assert CoveragePolicy.partition_findings([f], ["gated_t"]) == %{
               gated: [],
               not_gated: [f],
               warnings: []
             }
    end

    test "a :warning finding is always a warning, listed or not" do
      f = finding(%{severity: :warning, table: "gated_t", code: :legacy_trigger_no_pk_args})

      assert CoveragePolicy.partition_findings([f], ["gated_t"]) == %{
               gated: [],
               not_gated: [],
               warnings: [f]
             }
    end

    test "an empty findings list yields empty buckets" do
      assert CoveragePolicy.partition_findings([], ["gated_t"]) == %{
               gated: [],
               not_gated: [],
               warnings: []
             }
    end

    test "duplicate expected table names do not duplicate a finding across buckets" do
      f = finding(%{table: "gated_t"})

      assert CoveragePolicy.partition_findings([f], ["gated_t", "gated_t"]) == %{
               gated: [f],
               not_gated: [],
               warnings: []
             }
    end

    test "input order is preserved within each bucket" do
      f1 = finding(%{table: "gated_t", code: :capture_trigger_disabled})
      f2 = finding(%{table: "gated_t", code: :duplicate_capture_trigger})

      assert CoveragePolicy.partition_findings([f1, f2], ["gated_t"]) == %{
               gated: [f1, f2],
               not_gated: [],
               warnings: []
             }
    end
  end
end
