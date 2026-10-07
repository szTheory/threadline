defmodule ThreadlinePhoenix.IncidentReplaySafetyTest do
  use ExUnit.Case, async: true

  alias ThreadlinePhoenix.IncidentReplaySafety

  describe "disposable_database?/1" do
    test "allows the example app's exact dev database and test partitions" do
      assert IncidentReplaySafety.disposable_database?("threadline_phoenix_dev")
      assert IncidentReplaySafety.disposable_database?("threadline_phoenix_test")
      assert IncidentReplaySafety.disposable_database?("threadline_phoenix_test3")
    end

    test "rejects names that merely contain dev, test, or disposable" do
      refute IncidentReplaySafety.disposable_database?("threadline_production_dev")
      refute IncidentReplaySafety.disposable_database?("production_test")
      refute IncidentReplaySafety.disposable_database?("my_disposable_database")
      refute IncidentReplaySafety.disposable_database?("threadline_phoenix_test_backup")
      refute IncidentReplaySafety.disposable_database?(nil)
    end
  end
end
