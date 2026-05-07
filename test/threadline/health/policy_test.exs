defmodule Threadline.Health.PolicyTest do
  use ExUnit.Case, async: true

  alias Threadline.Health.Policy

  describe "validate!/1 — dual-form intake" do
    test "accepts an empty keyword list" do
      assert Policy.validate!([]) == :ok
    end

    test "accepts an empty map" do
      assert Policy.validate!(%{}) == :ok
    end

    test "accepts a keyword list with both known keys populated" do
      assert Policy.validate!(
               expected_uncovered_tables: ["foo", "bar"],
               audit_anyway: ["schema_migrations"]
             ) == :ok
    end

    test "accepts a map with both known keys populated" do
      assert Policy.validate!(%{
               expected_uncovered_tables: ["foo"],
               audit_anyway: ["bar"]
             }) == :ok
    end
  end

  describe "validate!/1 — :expected_uncovered_tables errors" do
    test "raises ArgumentError on a non-binary entry, mentions key and offending value" do
      assert_raise ArgumentError, ~r/:expected_uncovered_tables/, fn ->
        Policy.validate!(expected_uncovered_tables: ["foo", :bar])
      end

      assert_raise ArgumentError, ~r/:bar/, fn ->
        Policy.validate!(expected_uncovered_tables: ["foo", :bar])
      end
    end

    test "raises ArgumentError on duplicate entries, mentions duplicate value" do
      assert_raise ArgumentError, ~r/duplicate/, fn ->
        Policy.validate!(expected_uncovered_tables: ["foo", "foo"])
      end

      assert_raise ArgumentError, ~r/"foo"/, fn ->
        Policy.validate!(expected_uncovered_tables: ["foo", "foo"])
      end
    end
  end

  describe "validate!/1 — :audit_anyway errors" do
    test "raises ArgumentError on integer entry, mentions key and offending value" do
      assert_raise ArgumentError, ~r/:audit_anyway/, fn ->
        Policy.validate!(audit_anyway: ["foo", 42])
      end

      assert_raise ArgumentError, ~r/42/, fn ->
        Policy.validate!(audit_anyway: ["foo", 42])
      end
    end
  end

  describe "validate!/1 — unknown keys" do
    test "raises ArgumentError mentioning unknown key" do
      assert_raise ArgumentError, ~r/unknown_key/, fn ->
        Policy.validate!(unknown_key: "value")
      end
    end
  end

  describe "validate!/1 — non-keyword/non-map fallback (Pitfall 9)" do
    test "raises ArgumentError on a bare string" do
      assert_raise ArgumentError, ~r/keyword list or map/, fn ->
        Policy.validate!("not a keyword or map")
      end
    end

    test "raises ArgumentError on a non-keyword list" do
      assert_raise ArgumentError, ~r/keyword list or map/, fn ->
        Policy.validate!(["just", "strings"])
      end
    end
  end
end
