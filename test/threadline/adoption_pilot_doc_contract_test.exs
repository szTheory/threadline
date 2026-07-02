defmodule Threadline.AdoptionPilotDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @guide "guides/adoption-pilot-backlog.md"
  @release_please_config "release-please-config.json"
  @version Threadline.MixProject.project()[:version]

  test "adoption-pilot distribution preflight matches mix.exs version and ~> 0.9.0 constraint" do
    guide = File.read!(@guide)

    assert String.contains?(guide, @version)
    assert String.contains?(guide, "~> 0.9.0")
    refute String.contains?(guide, "~> 0.6")
    refute String.contains?(guide, "~> 0.5")
    refute String.contains?(guide, "0.2.0")
    refute String.contains?(guide, "~> 0.2")
  end

  # Shift-left guard for the release automation (see release-please-config.json
  # `extra-files`): the SSOT "reflects the **X** tree" line is bumped by
  # release-please in the release commit so the release PR is green by
  # construction — no manual prep. Both halves of the wiring must stay intact:
  # (1) the annotation marks which guide line to bump, and (2) the config points
  # release-please at this guide. If either is removed, the next release PR would
  # silently be born red on the version-match assertion above. Fail here instead.
  test "release-please is wired to auto-bump the SSOT preflight line (no manual prep)" do
    ssot_line =
      @guide
      |> File.read!()
      |> String.split("\n")
      |> Enum.find(&String.starts_with?(&1, "Distribution preflight below reflects the "))

    assert ssot_line,
           "SSOT preflight line not found in #{@guide} — release-please generic updater anchor is gone"

    assert String.contains?(ssot_line, "x-release-please-version"),
           "SSOT preflight line lost its `x-release-please-version` annotation; release-please can " <>
             "no longer auto-bump it and the release PR will be born red. Restore the annotation."

    config = File.read!(@release_please_config)

    assert String.contains?(config, "extra-files") and String.contains?(config, @guide),
           "#{@release_please_config} no longer lists #{@guide} under `extra-files`; release-please " <>
             "will not bump the guide's version on release. Restore the extra-files entry."
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
