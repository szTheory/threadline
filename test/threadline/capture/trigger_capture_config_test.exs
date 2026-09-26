defmodule Threadline.Capture.TriggerCaptureConfigTest do
  @moduledoc """
  Proves CONF-01's validation half (D-12, D-15): every malformed
  `primary_key:` override fails at config load with a message naming the
  table and the offending value; well-formed configs without the key are
  unaffected.
  """

  use ExUnit.Case, async: true

  alias Threadline.Capture.TriggerCaptureConfig

  describe "primary_key: accepted values" do
    test "a list of strings or atoms normalizes to strings, in declared order" do
      loaded =
        TriggerCaptureConfig.load(tables: %{"posts_tags" => [primary_key: [:post_id, "tag_id"]]})

      assert Keyword.get(loaded["posts_tags"], :primary_key) == ["post_id", "tag_id"]
    end

    test "the config key and the qualified key resolve to the same table" do
      loaded =
        TriggerCaptureConfig.load(
          tables: %{"public.posts_tags" => [primary_key: ["post_id", "tag_id"]]}
        )

      assert Keyword.get(loaded["public.posts_tags"], :primary_key) == ["post_id", "tag_id"]
    end

    test "an entry without primary_key loads exactly as before this plan" do
      loaded = TriggerCaptureConfig.load(tables: %{"t" => [mask: ["email"]]})
      assert loaded["t"] == [mask: ["email"]]
    end

    test "except_columns overlap with primary_key is harmless" do
      loaded =
        TriggerCaptureConfig.load(
          tables: %{"t" => [primary_key: ["code"], except_columns: ["code"]]}
        )

      assert Keyword.get(loaded["t"], :primary_key) == ["code"]
      assert Keyword.get(loaded["t"], :except_columns) == ["code"]
    end
  end

  describe "primary_key: rejected values" do
    test "a bare string suggests a list" do
      error =
        assert_raise ArgumentError, fn ->
          TriggerCaptureConfig.load(tables: %{"t" => [primary_key: "code"]})
        end

      assert error.message =~ ~s|"t"|
      assert error.message =~ "primary_key"
      assert error.message =~ ~s|["code"]|
    end

    test "a bare atom suggests a list" do
      error =
        assert_raise ArgumentError, fn ->
          TriggerCaptureConfig.load(tables: %{"t" => [primary_key: :code]})
        end

      assert error.message =~ ~s|"t"|
      assert error.message =~ "primary_key"
      assert error.message =~ ~s|["code"]|
    end

    test "a non-list, non-binary, non-atom value is rejected" do
      for value <- [5, %{a: 1}] do
        error =
          assert_raise ArgumentError, fn ->
            TriggerCaptureConfig.load(tables: %{"t" => [primary_key: value]})
          end

        assert error.message =~ ~s|"t"|
        assert error.message =~ "primary_key"
        assert error.message =~ inspect(value)
      end
    end

    test "an empty list is rejected" do
      error =
        assert_raise ArgumentError, fn ->
          TriggerCaptureConfig.load(tables: %{"t" => [primary_key: []]})
        end

      assert error.message =~ ~s|"t"|
      assert error.message =~ "primary_key"
    end

    test "an empty name is rejected" do
      error =
        assert_raise ArgumentError, fn ->
          TriggerCaptureConfig.load(tables: %{"t" => [primary_key: [""]]})
        end

      assert error.message =~ "primary_key"
    end

    test "a name containing NUL is rejected" do
      error =
        assert_raise ArgumentError, fn ->
          TriggerCaptureConfig.load(tables: %{"t" => [primary_key: ["a\0b"]]})
        end

      assert error.message =~ "primary_key"
    end

    test "a name with leading or trailing whitespace is rejected" do
      for value <- [" code", "code "] do
        error =
          assert_raise ArgumentError, fn ->
            TriggerCaptureConfig.load(tables: %{"t" => [primary_key: [value]]})
          end

        assert error.message =~ "primary_key"
        assert error.message =~ inspect(value)
      end
    end

    test "a name over 63 bytes is rejected" do
      long = String.duplicate("a", 64)

      error =
        assert_raise ArgumentError, fn ->
          TriggerCaptureConfig.load(tables: %{"t" => [primary_key: [long]]})
        end

      assert error.message =~ "primary_key"
      assert error.message =~ "63 bytes"
    end

    test "a name not matching the identifier rule is rejected" do
      error =
        assert_raise ArgumentError, fn ->
          TriggerCaptureConfig.load(tables: %{"t" => [primary_key: ["1code"]]})
        end

      assert error.message =~ "primary_key"
      assert error.message =~ "1code"
    end

    # WR-03 (210-REVIEW.md): a legally-quoted Postgres identifier (contains
    # a hyphen, here) would be *detected* correctly if it were a real
    # primary key column (the detected path never applies this regex — see
    # primary_key_sql.ex's pg_attribute.attname handling and the
    # pk_mixed_case coverage in trigger_pk_shapes_test.exs), but D-15
    # deliberately keeps the same strict bare-identifier regex for
    # *declared* overrides. This is a documented limitation
    # (guides/configuration-and-commands.md), not a bug: pin that the
    # refusal message says so instead of silently rejecting with no
    # guidance.
    test "a legal quoted identifier that fails the bare-identifier rule documents the known limitation" do
      error =
        assert_raise ArgumentError, fn ->
          TriggerCaptureConfig.load(tables: %{"t" => [primary_key: ["post-id"]]})
        end

      assert error.message =~ "primary_key"
      assert error.message =~ "post-id"
      assert error.message =~ "Known limitation"
      assert error.message =~ "guides/configuration-and-commands.md"
    end

    test "a duplicate after to_string is rejected, including atom/string pairs" do
      for value <- [["post_id", "post_id"], [:post_id, "post_id"]] do
        error =
          assert_raise ArgumentError, fn ->
            TriggerCaptureConfig.load(tables: %{"t" => [primary_key: value]})
          end

        assert error.message =~ "primary_key"
        assert error.message =~ "post_id"
      end
    end

    test "a non-binary, non-atom element is rejected" do
      error =
        assert_raise ArgumentError, fn ->
          TriggerCaptureConfig.load(tables: %{"t" => [primary_key: [123]]})
        end

      assert error.message =~ "primary_key"
      assert error.message =~ "123"
    end

    test "overlap with mask is rejected, naming the column" do
      error =
        assert_raise ArgumentError, fn ->
          TriggerCaptureConfig.load(tables: %{"t" => [primary_key: ["email"], mask: ["email"]]})
        end

      assert error.message =~ "email"
    end

    test "overlap with exclude is rejected, naming the column" do
      error =
        assert_raise ArgumentError, fn ->
          TriggerCaptureConfig.load(
            tables: %{"t" => [primary_key: ["notes"], exclude: ["notes"]]}
          )
        end

      assert error.message =~ "notes"
    end
  end

  describe "near-miss keys" do
    test "pk:, primary_keys:, pkey: and primary: all raise, suggesting primary_key:" do
      for key <- [:pk, :primary_keys, :pkey, :primary] do
        error =
          assert_raise ArgumentError, fn ->
            TriggerCaptureConfig.load(tables: %{"t" => [{key, ["code"]}]})
          end

        assert error.message =~ "primary_key:"
      end
    end
  end
end
