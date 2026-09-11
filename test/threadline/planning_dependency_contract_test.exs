defmodule Threadline.PlanningDependencyContract do
  @moduledoc false

  @planning_path ~r/\.planning(?:\/[^\s"')\]}]+)?/
  @file_io ~r/File\.(read!?|stream!?|open!?|stat!?)\s*\(\s*([^,\)]+)/
  @module_attribute ~r/@([a-zA-Z0-9_]+)\s+["']([^"']+)["']/

  def scan_sources(sources) when is_map(sources) do
    sources
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.flat_map(fn {file, source} -> source_violations(file, source) end)
  end

  defp source_violations(file, source) do
    attributes =
      Regex.scan(@module_attribute, source)
      |> Map.new(fn [_, name, value] -> {name, value} end)

    Regex.scan(@file_io, source, return: :index)
    |> Enum.flat_map(fn [{offset, _length}, {operation_offset, operation_length}, argument] ->
      operation = "File." <> binary_part(source, operation_offset, operation_length)
      argument_text = capture_text(source, argument)

      case planning_path(argument_text, attributes) do
        nil -> []
        path -> [violation(file, source, offset, operation, path)]
      end
    end)
  end

  defp planning_path(argument, attributes) do
    cond do
      match = Regex.run(@planning_path, argument) -> hd(match)
      match = Regex.run(~r/@([a-zA-Z0-9_]+)/, argument) -> Map.get(attributes, Enum.at(match, 1))
      true -> nil
    end
  end

  defp capture_text(source, {offset, length}), do: binary_part(source, offset, length)

  defp violation(file, source, offset, operation, path) do
    %{
      file: file,
      line: source |> binary_part(0, offset) |> count_lines(),
      operation: operation,
      path: path
    }
  end

  defp count_lines(prefix), do: length(:binary.matches(prefix, "\n")) + 1
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
