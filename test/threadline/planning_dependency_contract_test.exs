defmodule Threadline.PlanningDependencyContract do
  @moduledoc false

  def scan_sources(_sources), do: []
end

defmodule Threadline.PlanningDependencyContractTest do
  use ExUnit.Case, async: true

  alias Threadline.PlanningDependencyContract, as: Contract

  test "reports planning-backed file reads with their source location" do
    sources = %{
      "test/threadline/example_contract_test.exs" =>
        ~S|def receipt, do: File.read!(".planning/phases/198-green-bringup/receipt.md")|
    }

    assert Contract.scan_sources(sources) == [
             %{
               file: "test/threadline/example_contract_test.exs",
               line: 1,
               operation: "File.read!",
               path: ".planning/phases/198-green-bringup/receipt.md"
             }
           ]
  end

  test "accepts planning paths used only as diagnostic text" do
    sources = %{
      "test/threadline/diagnostic_test.exs" =>
        ~S|IO.warn("restore .planning/phases/198-green-bringup/receipt.md to investigate")|
    }

    assert Contract.scan_sources(sources) == []
  end
end
