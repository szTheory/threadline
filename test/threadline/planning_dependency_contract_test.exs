defmodule Threadline.PlanningDependencyContract do
  @moduledoc false

  @scanner_path "test/threadline/planning_dependency_contract_test.exs"
  @planning_path ~r/\.planning\/(?:audits|phases|milestones)(?:\/[^\s"')\]}]+)?|\.planning\/(?:ARCHIVE-REGISTER|REQUIREMENTS|ROADMAP|STATE)\.md/
  @file_io ~r/File\.(read!?|stream!?|open!?|stat!?|exists\?|dir\?|regular\?|ls!?)\s*\(\s*([^,\)]+)/
  @module_attribute ~r/^\s*@([a-zA-Z0-9_]+)\s+(.+)$/m

  def scan_sources(sources) when is_map(sources) do
    sources
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.flat_map(fn {file, source} -> source_violations(file, source) end)
  end

  def tracked_active_sources!(root) do
    {tracked, 0} = System.cmd("git", ["ls-files", "-z"], cd: root)

    tracked
    |> :binary.split(<<0>>, [:global, :trim_all])
    |> Enum.filter(&active_source?/1)
    |> Enum.reject(&(&1 == @scanner_path))
    |> Map.new(fn relative -> {relative, File.read!(Path.join(root, relative))} end)
  end

  defp source_violations(file, source) do
    attributes =
      Regex.scan(@module_attribute, source)
      |> Map.new(fn [_, name, expression] -> {name, historical_path(expression)} end)

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
      path = historical_path(argument) -> path
      match = Regex.run(~r/@([a-zA-Z0-9_]+)/, argument) -> Map.get(attributes, Enum.at(match, 1))
      true -> nil
    end
  end

  defp historical_path(text) do
    case Regex.run(@planning_path, text) do
      nil -> nil
      [path | _] -> path
    end
  end

  defp active_source?("mix.exs"), do: true

  defp active_source?(file) do
    (String.starts_with?(file, "test/") and String.ends_with?(file, "_test.exs")) or
      (String.starts_with?(file, "lib/mix/tasks/") and Path.extname(file) == ".ex") or
      (String.starts_with?(file, ".github/workflows/") and
         Path.extname(file) in [".yml", ".yaml"])
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

  test "reports planning-backed existence checks as live dependencies" do
    sources = %{
      "test/threadline/example_contract_test.exs" =>
        ~S|def evidence?, do: File.exists?(".planning/phases/199-decouple/evidence.json")|
    }

    assert Contract.scan_sources(sources) == [
             %{
               file: "test/threadline/example_contract_test.exs",
               line: 1,
               operation: "File.exists?",
               path: ".planning/phases/199-decouple/evidence.json"
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

  test "tracked active ExUnit, Mix, and CI sources do not read planning history" do
    root = Path.expand("../..", __DIR__)
    sources = Contract.tracked_active_sources!(root)

    for required <- [
          "mix.exs",
          ".github/workflows/ci.yml",
          "test/threadline/row_history_focus_evidence_contract_test.exs",
          "test/threadline/operator_surface/style_contract_test.exs"
        ] do
      assert Map.has_key?(sources, required), "derived active source set is missing #{required}"
    end

    assert Contract.scan_sources(sources) == []
  end
end
