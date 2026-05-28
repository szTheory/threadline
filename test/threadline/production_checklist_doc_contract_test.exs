defmodule Threadline.ProductionChecklistDocContractTest do
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "production checklist cross-links threadline ecto_repos to getting-started" do
    doc = read_rel!(["guides", "production-checklist.md"])
    literal = "config :threadline, ecto_repos: [MyApp.Repo]"

    assert String.contains?(doc, "## Host repo wiring (prerequisite)")
    assert String.contains?(doc, literal)
    assert String.contains?(doc, "getting-started-saas.md#configure-threadline")
    assert String.contains?(doc, "resolve_repo!/0")

    {host_idx, _} = :binary.match(doc, "## Host repo wiring (prerequisite)")
    {section_1_idx, _} = :binary.match(doc, "## 1. Capture and triggers")
    assert host_idx < section_1_idx
  end
end
