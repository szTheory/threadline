defmodule Threadline.SupportPlaybookDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  # Mirrors Threadline.StgDocContractTest — reads guide markdown from repo root for LOOP-04 anchors.
  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "domain-reference retains Support incident queries section and LOOP-04 anchors" do
    doc = read_rel!(["guides", "domain-reference.md"])

    assert String.contains?(doc, "## Support incident queries")
    assert String.contains?(doc, "LOOP-04-SUPPORT-INCIDENT-QUERIES")

    for heading <- [
          "### 1. Row history - PK changes in a time window",
          "### 2. Actor window - one actor across tables",
          "### 3. Correlation bundle - shared correlation_id",
          "### 4. Export parity - timeline and export filters agree",
          "### 5. Action and capture - link semantic actions to changes"
        ] do
      assert String.contains?(doc, heading)
    end

    # At-a-glance invariant: table rows numbered 1–5 (must_haves / 26-CONTEXT D-6).
    assert String.contains?(doc, "| 1 |")
    assert String.contains?(doc, "| 5 |")
  end

  test "production-checklist links Support incident queries to domain-reference anchors" do
    doc = read_rel!(["guides", "production-checklist.md"])

    assert String.contains?(doc, "## Support incident queries")
    assert String.contains?(doc, "domain-reference.md#")
  end
end
