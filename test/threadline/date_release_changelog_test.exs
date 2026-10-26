defmodule Threadline.DateReleaseChangelogTest do
  @moduledoc """
  Fixture-driven behaviour tests of `bin/date-release-changelog` (REL-01).

  The release branch dates its own CHANGELOG: the sync-release-pr-pins job in
  release.yml runs the script after the pin writer, so the release PR's final
  head carries `## [X.Y.Z] - YYYY-MM-DD` with no separate dating PR. Each test
  builds a throwaway tree (mix.exs with an `@version` line, CHANGELOG.md,
  optional CHANGELOG-GENERATED.md, and a copy of `bin/verify-release-shape`)
  and drives the repo script against it with `--root`.
  """
  use ExUnit.Case, async: true
  @moduletag :repo_contract

  @moduletag :tmp_dir

  @script Path.expand("../../bin/date-release-changelog", __DIR__)
  @release_shape Path.expand("../../bin/verify-release-shape", __DIR__)

  # The em dash (U+2014) spelled as bytes, so the byte-level assertions below
  # cannot be satisfied by an editor silently normalising the source.
  @em_dash <<0xE2, 0x80, 0x94>>
  @standing_heading "## Unreleased " <> @em_dash <> " highlights"
  @placeholder "_Nothing yet for the next release._"

  @prose """
  Threadline 1.2.0 makes the release branch date its own changelog.

  ### Breaking changes

  None.

  ### Added

  - A dated heading on the release PR.
  """

  @history """
  ## [1.1.0] - 2026-10-23

  Threadline 1.1.0 refines the operator surface.
  """

  @generated """
  # Changelog

  ## [1.2.0](https://example/compare/v1.1.0...v1.2.0) (2026-11-02)


  ### Features

  * dated changelog

  ## [1.1.0](https://example/compare/v1.0.1...v1.1.0) (2026-10-23)
  """

  defp changelog(unreleased_heading, body) do
    "# Changelog\n\n<!-- human-owned -->\n\n" <>
      unreleased_heading <> "\n\n" <> body <> "\n" <> @history
  end

  defp fixture(dir, opts \\ []) do
    version = Keyword.get(opts, :version, "1.2.0")
    heading = Keyword.get(opts, :heading, @standing_heading)
    body = Keyword.get(opts, :body, @prose)
    changelog_text = Keyword.get(opts, :changelog, changelog(heading, body))
    generated = Keyword.get(opts, :generated, @generated)

    File.write!(Path.join(dir, "mix.exs"), """
    defmodule Fixture.MixProject do
      use Mix.Project

      @version "#{version}"
    end
    """)

    File.write!(Path.join(dir, "CHANGELOG.md"), changelog_text)

    if generated, do: File.write!(Path.join(dir, "CHANGELOG-GENERATED.md"), generated)

    bin = Path.join(dir, "bin")
    File.mkdir_p!(bin)
    File.cp!(@release_shape, Path.join(bin, "verify-release-shape"))
    File.chmod!(Path.join(bin, "verify-release-shape"), 0o755)

    dir
  end

  defp run(root, args \\ []) do
    System.cmd(@script, ["--root", root | args], stderr_to_stdout: true)
  end

  defp read(root), do: File.read!(Path.join(root, "CHANGELOG.md"))

  defp count_lines(text, line) do
    text |> String.split("\n") |> Enum.count(&(&1 == line))
  end

  test "happy path: dates the Unreleased prose from the generated heading and re-seeds the block",
       %{tmp_dir: dir} do
    root = fixture(dir)

    assert {out, 0} = run(root)
    assert out =~ "date-release-changelog: dated [1.2.0] - 2026-11-02"

    text = read(root)
    assert count_lines(text, "## [1.2.0] - 2026-11-02") == 1
    assert count_lines(text, @standing_heading) == 1

    assert text =~
             @standing_heading <>
               "\n\n" <>
               @placeholder <>
               "\n\n## [1.2.0] - 2026-11-02\n\nThreadline 1.2.0 makes the release branch"

    [_, dated] = String.split(text, "## [1.2.0] - 2026-11-02\n", parts: 2)
    [section, _] = String.split(dated, "## [1.1.0]", parts: 2)
    assert section =~ "### Breaking changes\n\nNone."
    assert section =~ "- A dated heading on the release PR."
    refute section =~ @placeholder

    assert {shape, 0} =
             System.cmd(Path.join(root, "bin/verify-release-shape"), [], stderr_to_stdout: true)

    assert shape =~ "Release shape OK for version 1.2.0"
  end

  test "byte level: the input em-dash heading is matched and the re-seeded heading is the same bytes",
       %{tmp_dir: dir} do
    root = fixture(dir)
    assert read(root) |> :binary.match(@standing_heading <> "\n") != :nomatch

    assert {_, 0} = run(root)
    text = read(root)

    assert text
           |> :binary.split("\n", [:global])
           |> Enum.count(&(&1 == "## Unreleased " <> <<0xE2, 0x80, 0x94>> <> " highlights")) == 1

    assert :binary.match(text, <<0xC3, 0xA2>>) == :nomatch,
           "the output carries a double-encoded em dash"

    refute text =~ "## Unreleased\n"
  end

  test "placeholder-only Unreleased block with no dated heading refuses and names the landing-PR rule",
       %{tmp_dir: dir} do
    root = fixture(dir, body: @placeholder <> "\n")
    before = read(root)

    assert {out, 1} = run(root)
    assert out =~ "Unreleased"
    assert out =~ "CONTRIBUTING"
    assert read(root) == before
  end

  test "empty Unreleased block with no dated heading refuses", %{tmp_dir: dir} do
    root = fixture(dir, body: "")
    before = read(root)

    assert {out, 1} = run(root)
    assert out =~ "CONTRIBUTING"
    assert read(root) == before
  end

  test "placeholder-only block with the dated heading already present is a no-op",
       %{tmp_dir: dir} do
    text =
      "# Changelog\n\n" <>
        @standing_heading <>
        "\n\n" <>
        @placeholder <> "\n\n## [1.2.0] - 2026-11-02\n\nShipped.\n\n" <> @history

    root = fixture(dir, changelog: text)

    assert {out, 0} = run(root)
    assert out =~ "date-release-changelog: [1.2.0] already dated, nothing to do"
    assert read(root) == text
  end

  test "idempotent: a second run exits 0 and leaves the file byte-identical", %{tmp_dir: dir} do
    root = fixture(dir)

    assert {_, 0} = run(root)
    first = read(root)

    assert {out, 0} = run(root)
    assert out =~ "already dated"
    assert read(root) == first
  end

  test "a bare `## Unreleased` heading is accepted and the re-seed uses the em-dash form",
       %{tmp_dir: dir} do
    root = fixture(dir, heading: "## Unreleased")

    assert {_, 0} = run(root)
    text = read(root)

    assert count_lines(text, @standing_heading) == 1
    assert count_lines(text, "## Unreleased") == 0
    assert count_lines(text, "## [1.2.0] - 2026-11-02") == 1
  end

  test "prose that also carries the placeholder line drops the placeholder from the dated section",
       %{tmp_dir: dir} do
    root = fixture(dir, body: @placeholder <> "\n\n" <> @prose)

    assert {_, 0} = run(root)
    text = read(root)

    assert count_lines(text, @placeholder) == 1
    [_, dated] = String.split(text, "## [1.2.0] - 2026-11-02\n", parts: 2)
    refute dated =~ @placeholder
    assert dated =~ "\nThreadline 1.2.0 makes the release branch"
  end

  test "--date overrides the generated heading's date", %{tmp_dir: dir} do
    root = fixture(dir)

    assert {_, 0} = run(root, ["--date", "2026-12-01"])
    text = read(root)
    assert count_lines(text, "## [1.2.0] - 2026-12-01") == 1
    refute text =~ "2026-11-02"
  end

  test "an invalid --date exits 2 and writes nothing", %{tmp_dir: dir} do
    root = fixture(dir)
    before = read(root)

    for bad <- ["2026-12-1", "tomorrow", "2026-12-01; touch x"] do
      assert {_, 2} = run(root, ["--date", bad])
    end

    assert {_, 2} = run(root, ["--date"])
    assert read(root) == before
    refute File.exists?(Path.join(root, "x"))
  end

  test "without CHANGELOG-GENERATED.md the date is today's UTC date", %{tmp_dir: dir} do
    root = fixture(dir, generated: false)

    assert {_, 0} = run(root)

    assert [[date]] =
             Regex.scan(~r/^## \[1\.2\.0\] - (\d{4}-\d{2}-\d{2})$/m, read(root),
               capture: :all_but_first
             )

    assert abs(Date.diff(Date.from_iso8601!(date), Date.utc_today())) <= 1
  end

  test "a generated changelog with no heading for the version falls back to today's UTC date",
       %{tmp_dir: dir} do
    root = fixture(dir, generated: "# Changelog\n\n## [1.1.0](https://example) (2020-01-01)\n")

    assert {_, 0} = run(root)

    assert [[date]] =
             Regex.scan(~r/^## \[1\.2\.0\] - (\d{4}-\d{2}-\d{2})$/m, read(root),
               capture: :all_but_first
             )

    refute date == "2020-01-01"
    assert abs(Date.diff(Date.from_iso8601!(date), Date.utc_today())) <= 1
  end

  test "the FIRST generated heading for the current version supplies the date", %{tmp_dir: dir} do
    generated = """
    # Changelog

    ## [1.3.0](https://example/compare/v1.2.0...v1.3.0) (2027-01-05)

    ## [1.2.0](https://example/compare/v1.1.0...v1.2.0) (2026-11-07)

    ## [1.2.0](https://example/compare/v1.1.0...v1.2.0) (2026-11-01)
    """

    root = fixture(dir, generated: generated)

    assert {_, 0} = run(root)
    assert count_lines(read(root), "## [1.2.0] - 2026-11-07") == 1
  end

  test "a non-semver @version exits 2 and writes nothing", %{tmp_dir: dir} do
    root = fixture(dir, version: "1.2")
    before = read(root)

    assert {_, 2} = run(root)
    assert read(root) == before
  end

  test "a shell-metacharacter @version exits 2, runs nothing and writes nothing",
       %{tmp_dir: dir} do
    root = fixture(dir, version: "1.2.0$(touch x)")
    before = read(root)

    assert {_, 2} = run(root)
    assert read(root) == before
    refute File.exists?(Path.join(root, "x"))
    refute File.exists?("x")
  end

  test "a pre-release @version is skipped with exit 0 and no write", %{tmp_dir: dir} do
    root = fixture(dir, version: "1.2.0-rc.1")
    before = read(root)

    assert {out, 0} = run(root)
    assert out =~ "skip"
    assert read(root) == before
  end

  test "two Unreleased headings are ambiguous and exit 1", %{tmp_dir: dir} do
    text =
      "# Changelog\n\n" <>
        @standing_heading <>
        "\n\n" <> @prose <> "\n## Unreleased\n\nMore prose.\n\n" <> @history

    root = fixture(dir, changelog: text)

    assert {out, 1} = run(root)
    assert out =~ "Unreleased"
    assert read(root) == text
  end

  test "a dated heading alongside Unreleased prose is ambiguous and exits 1", %{tmp_dir: dir} do
    text =
      "# Changelog\n\n" <>
        @standing_heading <>
        "\n\n" <> @prose <> "\n## [1.2.0] - 2026-11-02\n\nShipped.\n\n" <> @history

    root = fixture(dir, changelog: text)

    assert {out, 1} = run(root)
    assert out =~ "[1.2.0]"
    assert read(root) == text
  end

  test "--check never writes: exit 1 when a rename is pending, exit 0 once dated",
       %{tmp_dir: dir} do
    root = fixture(dir)
    before = read(root)

    assert {out, 1} = run(root, ["--check"])
    assert out =~ "date-release-changelog:"
    assert read(root) == before

    assert {_, 0} = run(root)
    dated = read(root)

    assert {_, 0} = run(root, ["--check"])
    assert read(root) == dated
  end

  test "a --root lacking mix.exs or CHANGELOG.md exits 2", %{tmp_dir: dir} do
    empty = Path.join(dir, "empty")
    File.mkdir_p!(empty)

    assert {_, 2} = run(empty)

    root = fixture(Path.join(dir, "no_changelog") |> tap(&File.mkdir_p!/1))
    File.rm!(Path.join(root, "CHANGELOG.md"))
    assert {_, 2} = run(root)
  end

  test "an unknown flag exits 2", %{tmp_dir: dir} do
    root = fixture(dir)
    assert {_, 2} = run(root, ["--frobnicate"])
  end
end
