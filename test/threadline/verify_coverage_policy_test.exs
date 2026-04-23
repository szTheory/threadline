defmodule Threadline.VerifyCoveragePolicyTest do
  use ExUnit.Case, async: true

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
end
