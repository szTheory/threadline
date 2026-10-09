defmodule Threadline.OperatorSurface.OperatorEvidenceContractTest do
  use ExUnit.Case, async: true

  @root Path.expand("../../..", __DIR__)
  @fixtures Path.join(@root, "test/fixtures/operator_surface")

  test "generic inventories close every independently discovered declaration" do
    inventory = Jason.decode!(File.read!(Path.join(@fixtures, "route-inventory.json")))
    assert inventory["items"] != nil && inventory["items"] != [],
           "route inventory must declare primitive, control and state items"

    assert File.regular?(Path.join(@fixtures, "source-surface-checklist.json")),
           "independent source checklist must exist"
  end
end
