defmodule Threadline.Guides.StabilityContractTest do
  use ExUnit.Case, async: true

  @guide "guides/stability.md"
  @required_claims [
    "Threadline's 1.x Elixir API follows Hex semantic versioning",
    "functioning, fully specced delegate throughout 1.x",
    "no earlier than 2.0",
    "may add tables,",
    "but does not remove or rename them",
    "trigger-function names",
    "`threadline.actor_ref`",
    "security- or correctness-critical fix",
    "trigger regeneration",
    "`threadline_operator_surface/2` router macro",
    "documented mount routes are public integration contracts",
    "Rendered HTML, CSS, and LiveView internals are not public API",
    "security and correctness fixes are backported for six",
    "Public option `@type` names are stable and option lists are additive",
    "may ship in a minor or patch\nrelease",
    "with a `CHANGELOG.md` note",
    "can cause Dialyzer\nwarnings"
  ]

  test "the 1.x compatibility promises are stated in the adopter guide" do
    guide = File.read!(@guide)

    for claim <- @required_claims do
      assert guide =~ claim, "stability guide is missing claim: #{claim}"
    end

    assert guide =~ "test/threadline/capture/trigger_pk_shapes_test.exs"
    assert guide =~ "test/threadline/operator_surface/router_test.exs"
  end

  test "removing a promised 1.x claim fails the document contract" do
    guide = File.read!(@guide)
    mutated = String.replace(guide, "no earlier than 2.0", "no promised date")

    refute mutated =~ "no earlier than 2.0"
    assert "no earlier than 2.0" in missing_claims(mutated)
  end

  defp missing_claims(guide), do: Enum.reject(@required_claims, &String.contains?(guide, &1))
end
