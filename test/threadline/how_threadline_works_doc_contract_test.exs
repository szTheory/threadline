defmodule Threadline.HowThreadlineWorksDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @guide_path "guides/how-threadline-works.md"

  test "architecture guide follows the two end-to-end journeys in reader order" do
    doc = File.read!(@guide_path)

    assert_ordered(doc, [
      "# How Threadline works",
      "## Threadline in one picture",
      "## Vocabulary for the trip",
      "## Journey 1: installation creates host-owned database machinery",
      "## Journey 2: an audited request becomes an investigation trail",
      "## The data model is the architecture",
      "## Safety properties",
      "## Cross-cutting operations",
      "## Module atlas",
      "## Code-reading routes",
      "## Changing Threadline safely",
      "## Where to go next"
    ])

    refute String.contains?(doc, "## The SaaS Builder's JTBD Map")
    refute String.contains?(doc, "## Evolution so far")
    refute String.contains?(doc, "## Natural next work")
  end

  test "architecture guide contains four accessible Mermaid diagrams" do
    doc = File.read!(@guide_path)

    assert length(Regex.scan(~r/^```mermaid$/m, doc)) == 4
    assert length(Regex.scan(~r/^    accTitle:/m, doc)) == 4
    assert length(Regex.scan(~r/^    accDescr:/m, doc)) == 4

    for title <- [
          "Threadline end-to-end audit flow",
          "Threadline installation ownership boundary",
          "Runtime capture and correlation journey",
          "Threadline data relationships"
        ] do
      assert String.contains?(doc, title)
    end
  end

  test "architecture guide locks source-backed ownership and safety boundaries" do
    doc = File.read!(@guide_path)

    for claim <- [
          "PostgreSQL records what changed. The host supplies who and why.",
          "Threadline.Audit.transaction/3",
          "recommended audited write path",
          "transaction-local",
          "txid_current()",
          "Capture-only",
          "Correlation-ready",
          "Strict correlation",
          "PgBouncer transaction pooling",
          "host-owned",
          "exclude",
          "mask",
          "except_columns",
          "before_audit_horizon",
          "advisory lock",
          "host-written"
        ] do
      assert String.contains?(doc, claim), "missing architecture claim: #{claim}"
    end

    assert String.contains?(doc, "[Code walkthrough](code-walkthrough.md)")
    assert String.contains?(doc, "Threadline.OperatorSurface.Scope")
    assert String.contains?(doc, "Threadline.Export.Orchestrator")
    assert String.contains?(doc, "Threadline.Evidence")
  end

  test "architecture guide keeps host-written evidence framing" do
    doc = File.read!(@guide_path)

    refute String.contains?(doc, "Threadline may persist evidence")
    assert String.contains?(doc, "Host code calls those entrypoints deliberately")
    assert String.contains?(doc, "does not auto-populate compliance claims")
  end

  test "domain reference keeps evidence host-write boundary before proof contract" do
    domain_ref = File.read!("guides/domain-reference.md")

    assert String.contains?(domain_ref, "EVIDENCE-HOST-WRITE-BOUNDARY")
    assert String.contains?(domain_ref, "## Evidence write boundary (host-written)")

    {idx_marker, _} = :binary.match(domain_ref, "EVIDENCE-HOST-WRITE-BOUNDARY")
    {idx_proof, _} = :binary.match(domain_ref, "## Evidence proof contract")
    slice = :binary.part(domain_ref, idx_marker, idx_proof - idx_marker)

    assert String.contains?(slice, "does not auto-populate")
    assert String.contains?(slice, "record_redaction_policy")
    assert String.contains?(slice, "threadline_retention_runs")
  end

  defp assert_ordered(doc, markers) do
    positions =
      Enum.map(markers, fn marker ->
        assert {position, _length} = :binary.match(doc, marker), "missing marker: #{marker}"
        position
      end)

    assert positions == Enum.sort(positions)
  end
end
