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
    assert String.contains?(doc, "support-incident-queries")

    {idx_routing, _} = :binary.match(doc, "## Exploration API routing (v1.10+)")
    {idx_support, _} = :binary.match(doc, "## Support incident queries")
    assert idx_routing < idx_support
  end

  test "domain-reference retains v1.11 example incident JSON anchor (COMP-EXAMPLE-INCIDENT-JSON)" do
    doc = read_rel!(["guides", "domain-reference.md"])

    assert String.contains?(doc, "COMP-EXAMPLE-INCIDENT-JSON")
    assert String.contains?(doc, "examples/threadline_phoenix")
    assert String.contains?(doc, "GET /api/audit_transactions")
    assert String.contains?(doc, "audit_transaction_id")
  end

  test "domain-reference retains Time Travel hub and ASOF-06 anchor" do
    doc = read_rel!(["guides", "domain-reference.md"])

    assert String.contains?(doc, "## Time Travel (As-of)")
    assert String.contains?(doc, "time-travel-as-of-v120")
    assert String.contains?(doc, "ASOF-06")
    assert String.contains?(doc, "as_of/4")
    assert String.contains?(doc, "cast: true")
    assert String.contains?(doc, "genesis gap")
    assert String.contains?(doc, "deleted-record")
  end

  test "production-checklist links to Exploration API routing anchor" do
    doc = read_rel!(["guides", "production-checklist.md"])

    assert String.contains?(doc, "domain-reference.md#exploration-api-routing-v110")
    assert String.contains?(doc, "domain-reference.md#support-incident-queries")
  end
end
