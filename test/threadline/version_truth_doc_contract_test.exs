defmodule Threadline.VersionTruthDocContractTest do
  @moduledoc """
  Central, drift-proof version-truth guard (ADOPT-01).

  Every public install/version reference must agree with the single source of
  truth: `mix.exs` `@version`. This test derives everything from that version —
  it never hardcodes a literal, because a hardcoded version would be the same
  drift footgun it is meant to guard (T-191-03).

  Three families, each failing on a distinct drift:

    * Family A — install pins. Globs README + guides and asserts every
      `{:threadline, "~> x.y.z"}` equals the three-segment `~> major.minor.0`
      derived from `@version`. Fails if any doc advertises a stale floor.
    * Family B — current-version prose. Every line carrying the
      `x-release-please-version` marker must contain `@version` AND its file must
      be registered in `release-please-config.json` `extra-files`, so the release
      commit auto-bumps it (born-red-proof by identity).
    * Family C — upgrade coverage. `guides/upgrade-path.md` must document the
      current-minor bump `0.(minor-1).x -> 0.minor.x` (ASCII or U+2192 arrow).
  """
  use ExUnit.Case, async: true

  @version Threadline.MixProject.project()[:version]
  @parsed Version.parse!(@version)

  # Three-segment pin derived from @version. For @version 0.9.0 this is
  # "0.9.0"; a tight `.0` derivation keeps patch releases green by construction
  # because `~> 0.9.0` covers all of 0.9.x.
  @expected_pin_version "#{@parsed.major}.#{@parsed.minor}.0"

  # Current-minor upgrade coverage: 0.(minor-1).x -> 0.minor.x.
  @prev_minor @parsed.minor - 1
  @coverage_from "0.#{@prev_minor}.x"
  @coverage_to "0.#{@parsed.minor}.x"

  @release_please_config "release-please-config.json"

  # README + guides only — priv/ and examples/ are intentionally excluded by
  # this glob (their pins are exercised by mix verify.hex_evaluator / the
  # example app, not doc-contract). A glob (not an allowlist) means a future
  # guide that adds an install snippet cannot silently slip past the guard.
  defp doc_files do
    ["README.md" | Path.wildcard("guides/**/*.md")]
  end

  # Family A ---------------------------------------------------------------

  test "every threadline install pin across README + guides equals the derived ~> #{@expected_pin_version}" do
    pin_regex = ~r/\{:threadline,\s*"~>\s*([0-9][0-9.]*)"\}/

    # Prove the glob actually finds pins — a silent empty scan would make this
    # guard vacuously pass and let drift through.
    all_pins =
      for path <- doc_files(),
          [_full, captured] <- Regex.scan(pin_regex, File.read!(path)),
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

  # Family C ---------------------------------------------------------------

  test "upgrade-path.md documents the current-minor coverage #{@coverage_from} -> #{@coverage_to}" do
    guide = File.read!("guides/upgrade-path.md")

    # Accept either the ASCII `->` or the Unicode U+2192 arrow between segments.
    coverage_regex =
      ~r/#{Regex.escape(@coverage_from)}\s*(->|\x{2192})\s*#{Regex.escape(@coverage_to)}/u

    assert Regex.match?(coverage_regex, guide),
           "guides/upgrade-path.md is missing the current-minor upgrade coverage " <>
             "`#{@coverage_from} -> #{@coverage_to}` derived from @version #{@version}. Every " <>
             "minor bump must have a covered upgrade path so an adopter crossing #{@coverage_from} " <>
             "to #{@coverage_to} finds the action (or 'nothing required') for their jump. Add the " <>
             "coverage row/bullet (structural theme checks stay in upgrade_path_doc_contract_test)."
  end
end
