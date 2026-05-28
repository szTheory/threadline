defmodule Threadline.AdoptionPilotDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @guide "guides/adoption-pilot-backlog.md"
  @version Threadline.MixProject.project()[:version]

  test "adoption-pilot distribution preflight matches mix.exs version and ~> 0.6 constraint" do
    guide = File.read!(@guide)

    assert String.contains?(guide, @version)
    assert String.contains?(guide, "~> 0.6")
    refute String.contains?(guide, "~> 0.5")
    refute String.contains?(guide, "0.2.0")
    refute String.contains?(guide, "~> 0.2")
  end

  test "adoption-pilot links upgrade-path for lane story" do
    guide = File.read!(@guide)
    assert String.contains?(guide, "guides/upgrade-path.md")
  end

  test "adoption-pilot refutes stale hardcoded test counts (PILOT-01)" do
    guide = File.read!(@guide)

    refute String.contains?(guide, "136 tests")
    refute Regex.match?(~r/\(\d+ tests/, guide)
  end

  defp hex_distribution_row_ok?(guide) do
    guide
    |> String.split("\n")
    |> Enum.find(fn line ->
      String.contains?(line, "threadline") and String.contains?(line, "Hex")
    end)
    |> case do
      nil -> false
      row -> String.contains?(row, "| OK |")
    end
  end

  test "when Hex distribution row is OK, refutes stale 0.5.0 lag narrative" do
    guide = File.read!(@guide)

    if hex_distribution_row_ok?(guide) do
      refute String.contains?(guide, "latest is **0.5.0**")
      refute String.contains?(guide, "Unblock: push tag")
    end
  end

  test "adoption-pilot evidence pass cites canonical verify entrypoints (PILOT-01)" do
    guide = File.read!(@guide)

    assert String.contains?(guide, "mix ci.all")
    assert String.contains?(guide, "mix verify.doc_contract")

    for step <- [
          "verify.format",
          "verify.credo",
          "verify.compile_no_optional",
          "verify.test",
          "verify.threadline",
          "verify.example"
        ] do
      assert String.contains?(guide, step)
    end

    assert String.contains?(guide, "CONTRIBUTING.md")
  end
end
