defmodule Threadline.StgDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "CONTRIBUTING documents host STG evidence for integrators" do
    doc = read_rel!(["CONTRIBUTING.md"])
    assert String.contains?(doc, "## Host STG evidence (integrators)")
  end

  test "production checklist points to backlog STG rubric" do
    doc = read_rel!(["guides", "production-checklist.md"])
    assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
    assert String.contains?(doc, "guides/adoption-pilot-backlog.md")
  end

  test "adoption pilot backlog retains STG template and rubric markers" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "STG-HOST-TOPOLOGY-TEMPLATE")
    assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
  end
end
