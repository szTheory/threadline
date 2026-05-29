defmodule Threadline.AdoptionEvidencePlaybookDocContractTest do
  use ExUnit.Case, async: true

  @playbook "guides/adoption-evidence-playbook.md"

  test "playbook links evaluator ladder, demo tracks, and verify entrypoints" do
    doc = File.read!(@playbook)

    assert String.contains?(doc, "mix ci.all")
    assert String.contains?(doc, "mix verify.example")
    assert String.contains?(doc, "mix verify.hex_evaluator")
    assert String.contains?(doc, "mix verify.example_browser")
    assert String.contains?(doc, "walkthrough_happy_path_test.exs")
    assert String.contains?(doc, "walkthrough_evidence_test.exs")
    assert String.contains?(doc, "track_a_golden_path_test.exs")
    assert String.contains?(doc, "evaluating-threadline.md")
    assert String.contains?(doc, "adoption-pilot-backlog.md")
    assert String.contains?(doc, "STG-HOST-TOPOLOGY-TEMPLATE")
    assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
  end

  test "playbook documents Track B tour URLs" do
    doc = File.read!(@playbook)

    assert String.contains?(doc, "Tour in five minutes")
    assert String.contains?(doc, "/audit/evidence")
    assert String.contains?(doc, "/audit/policy/redaction")
    assert String.contains?(doc, "/audit/coverage")
    assert String.contains?(doc, "walk-acme-4521-close")
  end
end
