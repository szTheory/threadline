defmodule Threadline.ChangelogContractTest do
  @moduledoc """
  Structural guard for the human-owned changelog (RELEASE-04).

  Two things are under test here, and they are separate concerns:

    * The ownership split itself — release-please's `changelog-path` must keep
      naming the generated file. That one key is the whole of the bot's write
      access to a changelog; if it is ever pointed back at the human file, the
      bot regains the ability to write commit-subject vocabulary into the file
      that ships in the Hex tarball.
    * The shape of the newest release entry — human highlights present, and
      breaking changes / required action above the feature tour. An upgrader's
      first two questions are "will this break me" and "what must I do"; an
      entry that answers them after the feature list answers them too late.

  The entry-body assertions are scoped to the NEWEST dated entry only.
  Historical entries predate this contract — most of them were written by
  release automation when it owned this file — and retroactively invalidating
  published history would make this module fail for a reason no one can fix.
  """
  use ExUnit.Case, async: true

  @root File.cwd!()

  @human_changelog "CHANGELOG.md"
  @generated_changelog "CHANGELOG-GENERATED.md"
  @release_please_config "release-please-config.json"

  # A dated release heading, in either shape `bin/verify-release-shape` accepts:
  #   ## [0.10.0] - 2026-09-22
  #   ## [0.9.0](https://.../compare/v0.8.0...v0.9.0) (2026-06-03)
  @dated_entry_regex ~r/^## \[(\d+\.\d+\.\d+)\](?: - \d{4}-\d{2}-\d{2}|\([^)]*\) \(\d{4}-\d{2}-\d{2}\))$/m

  # Any bracketed unreleased-style heading, at any heading level. The bracket is
  # the problem: release-please's version-header pattern matches on it, so a
  # bracketed standing block is read as a release rather than as a staging area.
  @bracketed_unreleased_regex ~r/^\#{1,6}\s*\[\s*unreleased\s*\]/mi

  # release-please's generated bullet shape: a subject followed by a short-SHA
  # link into /commit/. If this appears inside the human entry, generated
  # content has drifted back across the ownership split.
  @generated_bullet_regex ~r/^\*\s.*\(\[[0-9a-f]{7,}\]\(https?:\/\/\S*\/commit\//m

  @breaking_section_regex ~r/^### (?:Breaking changes|Required action)\b/m
  @feature_tour_section_regex ~r/^### (?:Added|Changed|Fixed|Deprecated|Removed|Features|Bug Fixes)\b/m

  defp read!(relative), do: @root |> Path.join(relative) |> File.read!()

  defp dated_entries do
    changelog = read!(@human_changelog)

    Regex.scan(@dated_entry_regex, changelog, return: :index)
    |> Enum.map(fn [{start, _len} | _] -> start end)
  end

  # Body of the newest dated entry: from its heading to the next `## ` heading.
  defp newest_entry_body do
    changelog = read!(@human_changelog)
    [newest | _] = dated_entries()

    tail = binary_part(changelog, newest, byte_size(changelog) - newest)

    case Regex.run(~r/\n## /, tail, return: :index, offset: 1) do
      [{stop, _len}] -> binary_part(tail, 0, stop)
      nil -> tail
    end
  end

  test "the human changelog contains at least one dated release entry" do
    # Asserted FIRST and on its own: every entry-scoped assertion below reads
    # from this list, so a heading pattern that silently stops matching would
    # make the whole module pass vacuously rather than fail.
    assert dated_entries() != [],
           "no dated release heading matched in #{@human_changelog}. Every assertion in this " <>
             "module is scoped to the newest dated entry, so an unmatched heading pattern " <>
             "turns this contract into a guard that asserts nothing. Either the heading shape " <>
             "changed (and #{@dated_entry_regex.source} must move with it) or the file lost " <>
             "its release entries."
  end

  test "the newest release entry opens with human-written highlights" do
    body = newest_entry_body()

    [heading | rest] = String.split(body, "\n")

    prose =
      rest
      |> Enum.take_while(&(not String.starts_with?(&1, "###")))
      |> Enum.reject(&(String.trim(&1) == ""))

    assert prose != [],
           "the newest release entry (#{String.trim(heading)}) has no prose between its " <>
             "heading and its first subsection. A release entry with no human highlights is a " <>
             "failure, not a no-op: the file that ships in the Hex tarball would open the " <>
             "newest release with a bare section list. Write a sentence an upgrader can read."
  end

  test "the newest release entry answers breaking changes and required action before the feature tour" do
    body = newest_entry_body()

    breaking = Regex.run(@breaking_section_regex, body, return: :index)
    feature_tour = Regex.run(@feature_tour_section_regex, body, return: :index)

    assert breaking != nil,
           "the newest release entry has no `### Breaking changes` or `### Required action` " <>
             "section. An explicit `None` beats omission, which an upgrader reads as oversight."

    assert feature_tour != nil,
           "the newest release entry has no feature-tour section (`### Added`, `### Changed`, " <>
             "…). This contract compares the two section positions, so a missing feature tour " <>
             "would make the ordering assertion below vacuous."

    [{breaking_at, _}] = breaking
    [{feature_tour_at, _}] = feature_tour

    assert breaking_at < feature_tour_at,
           "the newest release entry puts its feature tour (offset #{feature_tour_at}) above " <>
             "its breaking-changes / required-action section (offset #{breaking_at}). An " <>
             "upgrader's first two questions are \"will this break me\" and \"what must I " <>
             "do\"; answering them after the feature list answers them too late. Move the " <>
             "breaking-changes and required-action sections above the feature tour."
  end

  test "the newest release entry carries no generated commit-link bullets" do
    body = newest_entry_body()

    refute Regex.match?(@generated_bullet_regex, body),
           "the newest release entry contains a release-please-shaped commit-link bullet. " <>
             "Generated notes belong in #{@generated_changelog}; #{@human_changelog} is " <>
             "human-owned and is scanned for internal planning vocabulary before it ships. " <>
             "Generated content drifting back across the ownership split is exactly what the " <>
             "split exists to prevent."
  end

  test "no bracketed unreleased-style heading exists anywhere in the human changelog" do
    changelog = read!(@human_changelog)

    refute Regex.match?(@bracketed_unreleased_regex, changelog),
           "#{@human_changelog} contains a bracketed unreleased-style heading. The bracket is " <>
             "the problem: release-please's version-header pattern matches on it, so the block " <>
             "is read as a release rather than as a staging area. Use the unbracketed standing " <>
             "form (`## Unreleased — highlights`) instead."
  end

  test "release-please owns the generated changelog and has no claim on the human one" do
    assert File.regular?(Path.join(@root, @generated_changelog)),
           "#{@generated_changelog} does not exist. release-please's `changelog-path` names " <>
             "it, so its absence means the release PR would create it unreviewed — and the " <>
             "ownership split this contract guards would exist only in configuration."

    config = read!(@release_please_config)
    parsed = Jason.decode!(config)

    changelog_path = get_in(parsed, ["packages", ".", "changelog-path"])

    assert changelog_path == @generated_changelog,
           "release-please `changelog-path` is #{inspect(changelog_path)}, not " <>
             "#{inspect(@generated_changelog)}. That single key is the whole of the bot's " <>
             "write access to a changelog. Pointed back at #{@human_changelog}, the bot " <>
             "regains the ability to write raw commit subjects — measured at 40 of 317 " <>
             "carrying internal planning vocabulary — into the file that ships in the Hex " <>
             "tarball and is scanned by the release artifact contract."

    refute config
           |> String.replace(@generated_changelog, "")
           |> String.contains?(@human_changelog),
           "#{@release_please_config} names #{@human_changelog} somewhere. The human changelog " <>
             "must appear in NO release-please key — not `changelog-path`, not `extra-files`. " <>
             "Any of them would hand a bot write access to adopter-facing prose."
  end

  test "the generated changelog documents the ownership split and holds no pre-0.10.0 entry" do
    generated = read!(@generated_changelog)

    assert String.contains?(generated, @human_changelog),
           "#{@generated_changelog} does not name #{@human_changelog}. Its header is where a " <>
             "maintainer who opens the wrong file learns which one adopters read."

    assert String.contains?(generated, "release-please"),
           "#{@generated_changelog} does not name its owner. A file nobody is documented as " <>
             "owning gets hand-edited, and a hand edit here is silently overwritten."

    # release-please writes a dated entry here on every release PR, starting at
    # 0.10.0, so the invariant is about WHICH entries may appear, not whether any
    # do. An earlier version here means published history was migrated out of
    # the human changelog, or the bot was pointed back at an old range.
    for [_heading, version] <- Regex.scan(@dated_entry_regex, generated) do
      assert Version.compare(version, "0.10.0") != :lt,
             "#{@generated_changelog} carries a dated entry for #{version}. Generated notes " <>
               "begin accumulating at 0.10.0; earlier generated bodies stay in " <>
               "#{@human_changelog} as published history because the compare and commit " <>
               "links inside them are what adopters have followed."
    end
  end
end
