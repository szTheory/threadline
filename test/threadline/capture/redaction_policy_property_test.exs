defmodule Threadline.Capture.RedactionPolicyPropertyTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Threadline.Test.RedactionPolicyGenerators

  alias Threadline.Capture.RedactionPolicy
  alias Threadline.Test.PropertyRuns

  # PROP-03: every generated valid policy is accepted; every generated
  # invalid policy raises ArgumentError whose message matches its tag. The
  # expected verdict comes only from the generator's own tag, never from
  # calling RedactionPolicy or its normalization — see
  # RedactionPolicyGenerators' moduledoc for how valid/invalid inputs are
  # built so the label is known before validate!/1 ever runs.
  property "validate!/1 accepts every generated valid policy and rejects every tagged invalid one" do
    check all(input <- policy_gen(), max_runs: PropertyRuns.pure(200)) do
      case input do
        {:valid, opts} ->
          assert RedactionPolicy.validate!(opts) == :ok,
                 "expected a valid policy to pass: #{inspect(opts)}"

        {:invalid, :overlap, column, opts} ->
          error =
            assert_raise ArgumentError, fn ->
              RedactionPolicy.validate!(opts)
            end

          trimmed = String.trim(column)

          assert error.message =~ "exclude",
                 "overlap message must name exclude: #{inspect(error.message)}"

          assert error.message =~ "mask",
                 "overlap message must name mask: #{inspect(error.message)}"

          assert error.message =~ trimmed,
                 "overlap message must name the column #{inspect(trimmed)}: #{inspect(error.message)}"

        {:invalid, :empty_placeholder, _tag, opts} ->
          assert_invalid_matches(opts, ~r/empty/i)

        {:invalid, :too_long, _tag, opts} ->
          assert_invalid_matches(opts, ~r/max length/i)

        {:invalid, :control_char, _tag, opts} ->
          assert_invalid_matches(opts, ~r/control/i)

        {:invalid, :non_list_columns, _which, opts} ->
          assert_invalid_matches(opts, ~r/must be a list/i)

        {:invalid, :non_binary_placeholder, _tag, opts} ->
          assert_invalid_matches(opts, ~r/must be a string/i)
      end
    end
  end

  defp assert_invalid_matches(opts, regex) do
    error =
      assert_raise ArgumentError, fn ->
        RedactionPolicy.validate!(opts)
      end

    assert error.message =~ regex,
           "expected message #{inspect(error.message)} to match #{inspect(regex)}"
  end

  describe "D-18 regression examples" do
    test "a non-list exclude: raises ArgumentError naming exclude and list" do
      error =
        assert_raise ArgumentError, fn ->
          RedactionPolicy.validate!(exclude: :ssn)
        end

      assert error.message =~ "exclude"
      assert error.message =~ "list"
    end

    test "a non-list mask: raises ArgumentError naming mask and list" do
      error =
        assert_raise ArgumentError, fn ->
          RedactionPolicy.validate!(mask: "ssn")
        end

      assert error.message =~ "mask"
      assert error.message =~ "list"
    end

    test "a non-list exclude: on the string-keyed map path also raises" do
      assert_raise ArgumentError, fn ->
        RedactionPolicy.validate!(%{"exclude" => :ssn})
      end
    end

    test "exclude: nil stays no columns, same as absent" do
      assert RedactionPolicy.validate!(exclude: nil, mask: ["a"]) == :ok
    end

    test "a non-binary mask_placeholder raises ArgumentError, not FunctionClauseError" do
      for placeholder <- [5, :x] do
        error =
          assert_raise ArgumentError, fn ->
            RedactionPolicy.validate!(mask: ["a"], mask_placeholder: placeholder)
          end

        assert error.message =~ "placeholder"
      end

      error =
        assert_raise ArgumentError, fn ->
          RedactionPolicy.validate_placeholder!(5)
        end

      assert error.message =~ "placeholder"
    end

    test "mask_placeholder: false or nil fall back to the default placeholder" do
      assert RedactionPolicy.validate!(mask: ["a"], mask_placeholder: false) == :ok
      assert RedactionPolicy.validate!(mask: ["a"], mask_placeholder: nil) == :ok
    end

    test "when both :exclude and \"exclude\" are given, the atom key wins (no overlap)" do
      assert RedactionPolicy.validate!(%{
               :exclude => ["a"],
               "exclude" => ["b"],
               :mask => ["b"]
             }) == :ok
    end

    test "a placeholder of exactly 200 multibyte graphemes is accepted" do
      placeholder = String.duplicate("é", 200)
      assert RedactionPolicy.validate_placeholder!(placeholder) == :ok
    end

    test "a placeholder of 201 ASCII graphemes is rejected" do
      placeholder = String.duplicate("a", 201)

      assert_raise ArgumentError, fn ->
        RedactionPolicy.validate_placeholder!(placeholder)
      end
    end

    test "a placeholder containing DEL (127) or U+0085 is accepted" do
      assert RedactionPolicy.validate_placeholder!("del" <> <<127>> <> "end") == :ok
      assert RedactionPolicy.validate_placeholder!("nel" <> <<0x85::utf8>> <> "end") == :ok
    end
  end
end
