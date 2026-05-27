defmodule Threadline.V123CharterDocContractTest do
  @moduledoc """
  Machine-checkable proxies for Phase 104 charter / milestone framing artifacts.

  Replaces subjective human UAT on planning-doc readability.
  """
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "PROJECT.md locks v1.25 milestone framing" do
    doc = read_rel!([".planning", "PROJECT.md"])

    assert String.contains?(
             doc,
             "## Current Milestone: v1.25 Adopter-Ready Release & First-Hour Truth"
           )

    assert String.contains?(doc, "Threadline.Audit.transaction")
    assert String.contains?(doc, "**REL**")
    assert String.contains?(doc, "0.6.0")
  end

  test "MILESTONE-ARC.md locks v1.25 arc row and strategic thesis" do
    doc = read_rel!([".planning", "MILESTONE-ARC.md"])

    assert String.contains?(
             doc,
             "**Active milestone:** v1.25 — Adopter-Ready Release & First-Hour Truth"
           )

    assert String.contains?(doc, "Hex release truth + first-hour doc/example alignment")
    assert String.contains?(doc, "see PROJECT.md Key Decisions")

    assert String.contains?(
             doc,
             "| v1.25 | **recommended** | Adopter-Ready Release & First-Hour Truth |"
           )

    assert String.contains?(doc, "first sustained external signal")
  end
end
