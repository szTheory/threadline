defmodule Threadline.HowThreadlineWorksDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @guide_path "guides/how-threadline-works.md"

  test "mental model guide locks the architecture, personas, and next-work map" do
    doc = File.read!(@guide_path)

    headings = [
      "# How Threadline works",
      "## The short version",
      "## The flow",
      "## Architecture layers",
      "## The SaaS Builder's JTBD Map",
      "## Public API surface",
      "## Evolution so far",
      "## Natural next work",
      "## Where to go next"
    ]

    Enum.each(headings, &assert(String.contains?(doc, &1)))

    Enum.each(
      [
        "DB truth",
        "app intent",
        "operator tooling",
        "Threadline.Plug",
        "Threadline.record_action/2",
        "Threadline.timeline/2",
        "Threadline.timeline_page/2",
        "Threadline.incident_bundle/2",
        "Threadline.as_of/4",
        "Threadline.export_json/2",
        "Threadline-owned RBAC platform",
        "legal hold",
        "immutable-storage",
        "generic compliance",
        "vendor-specific",
        "tenancy DSL"
      ],
      &assert(String.contains?(doc, &1))
    )

    Enum.each(
      [
        "Silent Witness",
        "Who Did This?",
        "3 AM Support Ticket",
        "Data Handoff",
        "retention admin",
        "saved views",
        "queued or scheduled exports",
        "threadline_web"
      ],
      &assert(String.contains?(doc, &1))
    )

    Enum.each(
      [
        "integration-contracts.md",
        "operator-surface.md",
        "domain-reference.md",
        "getting-started-saas.md",
        "upgrade-path.md"
      ],
      &assert(String.contains?(doc, &1))
    )
  end

  test "mental model guide locks recommended audited write path (NARR-03)" do
    doc = File.read!(@guide_path)

    assert String.contains?(doc, "Threadline.Audit.transaction/3")
    assert String.contains?(doc, "recommended audited write path")

    {idx_write, _} = :binary.match(doc, "### Write-side")
    write_len = byte_size(doc) - idx_write
    scope = {idx_write, write_len}

    {idx_tx, _} = :binary.match(doc, "Threadline.Audit.transaction/3", scope: scope)
    {idx_ra, _} = :binary.match(doc, "Threadline.record_action/2", scope: scope)
    assert idx_tx < idx_ra

    assert String.contains?(doc, "getting-started-saas.md")
    assert String.contains?(doc, "§6")
  end

  test "mental model guide locks Evolution semver chronology (DOC-02/DOC-03)" do
    doc = File.read!(@guide_path)

    assert String.contains?(doc, "## Evolution so far")
    assert String.contains?(doc, "`0.5.0`")
    assert String.contains?(doc, "`0.6.0`")
    assert String.contains?(doc, "0.6.0` packaged the Evidence plane")
    assert String.contains?(doc, "Threadline.Audit.transaction/3")

    {idx_evolution, _} = :binary.match(doc, "## Evolution so far")
    {idx_next, _} = :binary.match(doc, "## Natural next work")
    scope = {idx_evolution, idx_next - idx_evolution}

    {idx_05, _} = :binary.match(doc, "`0.5.0`", scope: scope)
    {idx_06, _} = :binary.match(doc, "`0.6.0`", scope: scope)
    assert idx_05 < idx_06
  end

  test "mental model guide locks host-written evidence framing (DOC-04)" do
    doc = File.read!(@guide_path)

    refute String.contains?(doc, "Threadline may persist evidence")
    assert String.contains?(doc, "domain-reference.md")

    assert String.contains?(doc, "host-written") or
             String.contains?(doc, "host apps write")
  end

  test "domain-reference locks evidence host-write boundary before proof contract (DOC-04)" do
    domain_ref = File.read!("guides/domain-reference.md")

    assert String.contains?(domain_ref, "EVIDENCE-HOST-WRITE-BOUNDARY")
    assert String.contains?(domain_ref, "## Evidence write boundary (host-written)")

    {idx_marker, _} = :binary.match(domain_ref, "EVIDENCE-HOST-WRITE-BOUNDARY")
    {idx_proof, _} = :binary.match(domain_ref, "## Evidence proof contract")
    slice_len = idx_proof - idx_marker
    slice = :binary.part(domain_ref, idx_marker, slice_len)

    assert String.contains?(slice, "does not auto-populate")
    assert String.contains?(slice, "record_redaction_policy")
    assert String.contains?(slice, "threadline_retention_runs")
  end
end
