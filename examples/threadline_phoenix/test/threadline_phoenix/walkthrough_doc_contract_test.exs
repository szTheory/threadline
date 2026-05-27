defmodule ThreadlinePhoenix.WalkthroughDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @walkthrough Path.expand("../../WALKTHROUGH.md", __DIR__)

  test "WALKTHROUGH.md carries walk-critical literals for RUN-01 self-containment" do
    doc = File.read!(@walkthrough)

    for literal <- [
          "4521",
          "4518",
          "walk-retention-offboarded-co",
          "2026-05-20T14:30:00Z",
          "mix demo.reset",
          "WALK-03-04"
        ] do
      assert String.contains?(doc, literal),
             "expected WALKTHROUGH.md to include #{inspect(literal)}"
    end
  end
end
