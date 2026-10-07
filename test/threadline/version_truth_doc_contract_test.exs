defmodule Threadline.VersionTruthDocContractTest do
  @moduledoc """
  Central, drift-proof version-truth guard (ADOPT-01).

  Every public install/version reference must agree with the single source of
  truth: `mix.exs` `@version`. This test derives everything from that version —
  it never hardcodes a literal, because a hardcoded version would be the same
  drift footgun it is meant to guard (T-191-03).

  Four families, each failing on a distinct drift:

    * Family A — install pins. Globs README + guides and asserts every
      `{:threadline, "~> x.y.z"}` equals the three-segment `~> major.minor.0`
      derived from `@version`. Fails if any doc advertises a stale floor.
    * Family B — current-version prose. Every line carrying the
      `x-release-please-version` marker must contain `@version` AND its file must
      be registered in `release-please-config.json` `extra-files`, so the release
      commit auto-bumps it (born-red-proof by identity).
    * Family B-inverse — ownership separation. No install-pin line may also
      carry an `x-release-please-version` marker; pin lines belong to
      `mix release.pins` alone.
    * Family C — upgrade coverage. `guides/upgrade-path.md` must document the
      latest earlier release minor -> the current release minor (ASCII or
      U+2192 arrow), including the first stable release after 0.x.
  """
  use ExUnit.Case, async: true

  @version Threadline.MixProject.project()[:version]
  @parsed Version.parse!(@version)

  # Three-segment pin derived from @version. For @version 0.9.0 this is
  # "0.9.0"; a tight `.0` derivation keeps patch releases green by construction
  # because `~> 0.9.0` covers all of 0.9.x.
  @expected_pin_version "#{@parsed.major}.#{@parsed.minor}.0"

  @release_please_config "release-please-config.json"

  # The install-pin shape, shared by Family A and by the pin/marker separation
  # test below. `mix release.pins` carries a character-identical copy of this
  # expression: the task and this contract must never disagree about which
  # lines count as an install pin.
  @pin_regex ~r/\{:threadline,\s*"~>\s*([0-9][0-9.]*)"\}/

  # README + guides only — priv/ and examples/ are intentionally excluded by
  # this glob (their pins are exercised by mix verify.hex_evaluator / the
  # example app, not doc-contract). A glob (not an allowlist) means a future
  # guide that adds an install snippet cannot silently slip past the guard.
  defp doc_files do
    ["README.md" | Path.wildcard("guides/**/*.md")]
  end

  # Family A ---------------------------------------------------------------

  test "every threadline install pin across README + guides equals the derived ~> #{@expected_pin_version}" do
    # Prove the glob actually finds pins — a silent empty scan would make this
    # guard vacuously pass and let drift through.
    all_pins =
      for path <- doc_files(),
          [_full, captured] <- Regex.scan(@pin_regex, File.read!(path)),
          do: {path, captured}

    assert all_pins != [],
           "no {:threadline, \"~> x.y.z\"} pin found across README + guides — the glob or " <>
             "regex is broken, which would let install-pin drift pass unguarded."

    for {path, captured} <- all_pins do
      assert captured == @expected_pin_version,
             "#{path} advertises install pin `~> #{captured}` but mix.exs @version is " <>
               "#{@version}, so every public pin must read `~> #{@expected_pin_version}` " <>
               "(three-segment, current-minor `.0`). Flip the stale pin — a wrong floor " <>
               "routes adopters to the wrong version and erodes trust (T-191-01)."
    end
  end

  # Family B ---------------------------------------------------------------

  test "every x-release-please-version marked line carries @version and is wired into release-please" do
    config = File.read!(@release_please_config)

    marked =
      for path <- doc_files(),
          line <- String.split(File.read!(path), "\n"),
          String.contains?(line, "x-release-please-version"),
          do: {path, line}

    assert marked != [],
           "no x-release-please-version marker found across README + guides — the " <>
             "current-version SSOT lines lost their release-please anchors and the next " <>
             "release PR would silently drift (T-191-02)."

    for {path, line} <- marked do
      assert String.contains?(line, @version),
             "#{path} has an x-release-please-version marked line that does not contain the " <>
               "current @version #{@version}. release-please replaces the version on the marked " <>
               "line; if the prose does not match @version today, the current-version claim is " <>
               "already stale. Update the number to #{@version}."

      assert String.contains?(config, path),
             "#{path} carries an x-release-please-version marker but is NOT listed under " <>
               "`extra-files` in #{@release_please_config}. release-please will not auto-bump it, " <>
               "so the marked line will be born red on the next release. Register the file in " <>
               "extra-files (prose-claim files only — never a pin-bearing file)."
    end
  end

  # Family B-inverse -------------------------------------------------------

  test "no install pin line is also owned by a release-please version marker" do
    pin_lines =
      for path <- doc_files(),
          {line, number} <-
            path |> File.read!() |> String.split("\n") |> Enum.with_index(1),
          Regex.match?(@pin_regex, line),
          do: {path, number, line}

    # Prove the scan actually found pin lines. Without this the separation
    # assertion below would pass vacuously the moment the glob or the regex
    # stopped matching, which is precisely the drift it exists to catch.
    assert pin_lines != [],
           "no {:threadline, \"~> x.y.z\"} pin line found across README + guides — the glob " <>
             "or regex is broken, so this ownership guard is asserting nothing."

    for {path, number, line} <- pin_lines do
      refute String.contains?(line, "x-release-please-version"),
             "#{path}:#{number} carries BOTH an install pin and an x-release-please-version " <>
               "marker, so release automation would own a pin line. That cannot work: the " <>
               "generic updater writes the FULL version onto a marked line, emitting " <>
               "`~> x.y.1` on a patch release while this contract derives `~> x.y.0`; and the " <>
               "component updater replaces the first bare integer on the line, which inside " <>
               "`{:threadline, \"~> 0.9.0\"}` is the leading `0` of the requirement string, " <>
               "producing a nonsense major. Install pins are owned by `mix release.pins` and " <>
               "by nothing else — remove the marker, and never register a pin-bearing file " <>
               "under `extra-files` in #{@release_please_config}.\n\n    #{String.trim(line)}"
    end
  end

  # Family C ---------------------------------------------------------------

  defp previous_release_minor! do
    releases =
      File.read!("CHANGELOG.md")
      |> then(&Regex.scan(~r/^## \[(\d+\.\d+\.\d+)\]/m, &1, capture: :all_but_first))
      |> Enum.map(fn [version] -> Version.parse!(version) end)

    previous_minor =
      Enum.reduce(releases, nil, fn version, best ->
        same_minor? = {version.major, version.minor} == {@parsed.major, @parsed.minor}

        if not same_minor? and Version.compare(version, @parsed) == :lt and
             (is_nil(best) or Version.compare(version, best) == :gt) do
          version
        else
          best
        end
      end)

    previous_minor || flunk("CHANGELOG.md has no earlier release minor before #{@version}")
  end

  test "upgrade-path.md documents the previous-release-minor coverage for #{@version}" do
    guide = File.read!("guides/upgrade-path.md")
    previous = previous_release_minor!()
    coverage_from = "#{previous.major}.#{previous.minor}.x"
    coverage_to = "#{@parsed.major}.#{@parsed.minor}.x"

    # Accept either the ASCII `->` or the Unicode U+2192 arrow between segments.
    coverage_regex =
      ~r/#{Regex.escape(coverage_from)}\s*(->|\x{2192})\s*#{Regex.escape(coverage_to)}/u

    assert Regex.match?(coverage_regex, guide),
           "guides/upgrade-path.md is missing the current-minor upgrade coverage " <>
             "`#{coverage_from} -> #{coverage_to}` derived from @version #{@version} and the " <>
             "latest earlier release in CHANGELOG.md. Every minor or major transition must have " <>
             "a covered upgrade path so adopters find the action (or 'nothing required'). Add the " <>
             "coverage row/bullet (structural theme checks stay in upgrade_path_doc_contract_test)."
  end
end
