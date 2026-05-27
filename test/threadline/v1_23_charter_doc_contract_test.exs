defmodule Threadline.V123CharterDocContractTest do
  @moduledoc """
  Machine-checkable proxies for Phase 104 charter / v1.23 framing artifacts.

  Replaces subjective human UAT on planning-doc readability.
  """
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  defp line_number(haystack, needle) do
    haystack
    |> String.split("\n", trim: false)
    |> Enum.find_index(&String.contains?(&1, needle))
    |> case do
      nil -> nil
      idx -> idx + 1
    end
  end

  test "PROJECT.md locks v1.24 milestone framing" do
    doc = read_rel!([".planning", "PROJECT.md"])

    assert String.contains?(doc, "## Current Milestone: v1.24 Audited Write Path & Adopter Truth")
    assert String.contains?(doc, "Threadline.Audit.transaction")

    assert String.contains?(doc, "**v1.24 non-goals:**")
    assert String.contains?(doc, "**Current State:**")

    non_goals_line = line_number(doc, "**v1.24 non-goals:**")
    current_state_line = line_number(doc, "**Current State:**")

    assert non_goals_line
    assert current_state_line
    assert non_goals_line < current_state_line
  end

  test "MILESTONE-ARC.md locks v1.24 arc row and strategic thesis" do
    doc = read_rel!([".planning", "MILESTONE-ARC.md"])

    assert String.contains?(
             doc,
             "**Active milestone:** v1.24 — Audited Write Path & Adopter Truth"
           )

    assert String.contains?(doc, "v1.24 closes the largest remaining adoption wedge")
    assert String.contains?(doc, "see PROJECT.md Key Decisions")
    assert String.contains?(doc, "| v1.24 | **active** | Audited Write Path & Adopter Truth |")
    assert String.contains?(doc, "manual audited-transaction recipe")
    assert String.contains?(doc, "first sustained external signal")
  end
end
