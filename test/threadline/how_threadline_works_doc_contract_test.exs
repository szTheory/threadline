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
end
