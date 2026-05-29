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

  test "PROJECT.md locks v1.27 milestone framing" do
    doc = read_rel!([".planning", "PROJECT.md"])

    assert String.contains?(
             doc,
             "## Latest Milestone Shipped: v1.27 Distribution & First-Hour Finish"
           )

    assert String.contains?(doc, "Threadline.Audit.transaction")
    assert String.contains?(doc, "phx-gen-auth-reference")
    assert String.contains?(doc, "AUTH-PROOF-01")
  end

  test "MILESTONE-ARC.md locks v1.27 arc row and strategic thesis" do
    doc = read_rel!([".planning", "MILESTONE-ARC.md"])

    assert String.contains?(
             doc,
             "**Active milestone:** **v1.29 First-Hour Parity**"
           )

    assert String.contains?(doc, "distribution + first-hour finish wedge is closed")
    assert String.contains?(doc, "see PROJECT.md Key Decisions")

    assert String.contains?(doc, "| v1.27 | **shipped** | Distribution & First-Hour Finish |")

    assert String.contains?(doc, "0.6.0")
    refute String.contains?(doc, "still lists **0.5.0**")

    assert String.contains?(doc, "first sustained external signal")
  end
end
