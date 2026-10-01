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
      end
    end
  end
end
