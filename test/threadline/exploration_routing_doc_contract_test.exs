defmodule Threadline.ExplorationRoutingDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "domain-reference retains Exploration API routing section and XPLO-03 anchors" do
    doc = read_rel!(["guides", "domain-reference.md"])

    assert String.contains?(doc, "## Exploration API routing (v1.10+)")
    assert String.contains?(doc, "XPLO-03-API-ROUTING")
    assert String.contains?(doc, "audit_changes_for_transaction")
    assert String.contains?(doc, "change_diff") or String.contains?(doc, "ChangeDiff")
  end

  test "production-checklist links to Exploration API routing anchor" do
    doc = read_rel!(["guides", "production-checklist.md"])

    assert String.contains?(doc, "domain-reference.md#exploration-api-routing-v110")
  end
end
