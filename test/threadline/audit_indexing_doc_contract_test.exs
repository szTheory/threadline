defmodule Threadline.AuditIndexingDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "audit-indexing guide retains IDX-02 marker and operator spine" do
    doc = read_rel!(["guides", "audit-indexing.md"])

    assert String.contains?(doc, "<!-- IDX-02-AUDIT-INDEXING -->")

    for heading <- [
          "## Installed defaults",
          "### audit_transactions",
          "### audit_changes",
          "### audit_actions",
          "## Timeline and Threadline.Query",
          "## Export and Threadline.Export",
          "## Correlation filtering",
          "## Retention and Threadline.Retention",
          "## Tradeoffs and evidence"
        ] do
      assert String.contains?(doc, heading)
    end
  end

  test "audit-indexing guide links to domain-reference and production-checklist" do
    doc = read_rel!(["guides", "audit-indexing.md"])

    assert String.contains?(doc, "domain-reference.md")
    assert String.contains?(doc, "production-checklist.md")
  end
end
