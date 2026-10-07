defmodule Threadline.UpgradingTo100DocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @changelog_path "CHANGELOG.md"
  @guide_path "guides/upgrading-to-1.0.md"
  @step_headings [
    "## Step 1: Move to the supported API",
    "## Step 2: Bound row history",
    "## Step 3: Use the shared Page shape",
    "## Step 4: Handle lookup results and options",
    "## Step 5: Read action associations through exploration APIs",
    "## Step 6: Upgrade PostgreSQL",
    "## Step 7: Replace deprecated calls"
  ]

  defp changelog, do: File.read!(@changelog_path)
  defp guide, do: File.read!(@guide_path)

  defp heading_section!(content, matcher, source) do
    headings =
      Regex.scan(~r/(?m)^#+ .*$/, content, return: :index)
      |> Enum.map(fn [{start, length}] ->
        heading = binary_part(content, start, length)
        [prefix] = Regex.run(~r/^#+/, heading)
        {start, length, String.length(prefix)}
      end)

    {start, length, level} =
      Enum.find(headings, fn {offset, size, _} ->
        content |> binary_part(offset, size) |> then(&Regex.match?(matcher, &1))
      end) || flunk("expected #{source} to contain heading matching #{inspect(matcher)}")

    body_start = start + length

    body_end =
      headings
      |> Enum.find_value(byte_size(content), fn {offset, _, next_level} ->
        if offset > start and next_level <= level, do: offset
      end)

    binary_part(content, body_start, body_end - body_start)
  end

  defp changelog_scope!(content, "0.12") do
    heading_section!(content, ~r/^## \[0\.12\.0\]/, @changelog_path)
  end

  defp changelog_scope!(content, "1.0") do
    unreleased = heading_section!(content, ~r/^## Unreleased — highlights$/, @changelog_path)

    if Regex.match?(~r/^## \[1\.0\.0\]/m, content) do
      heading_section!(content, ~r/^## \[1\.0\.0\]/, @changelog_path)
    else
      unreleased
    end
  end

  defp subsection!(content, heading, source) do
    heading_section!(content, Regex.compile!("^### #{Regex.escape(heading)}$"), source)
  end

  defp extract_ids(content) do
    Regex.scan(~r/<!-- threadline:upgrade:([^:]+):([a-z0-9-]+) -->/, content,
      capture: :all_but_first
    )
    |> Enum.map(fn [scope, id] -> "#{scope}/#{id}" end)
  end

  defp bullet_ids!(content, scope, source) do
    bullets = Regex.scan(~r/(?ms)^- (.*?)(?=^- |\z)/, content, capture: :all_but_first)

    assert bullets != [], "expected #{source} to contain scoped top-level bullets"

    Enum.flat_map(bullets, fn [bullet] ->
      values = extract_ids(bullet)

      assert length(values) == 1,
             "#{source} has a bullet with #{length(values)} upgrade IDs; expected exactly one #{scope} ID: #{String.slice(String.trim(bullet), 0, 120)}"

      assert String.starts_with?(hd(values), "#{scope}/"),
             "#{source} bullet is tagged for the wrong scope: #{inspect(hd(values))}"

      values
    end)
  end

  defp duplicate_values(values), do: values -- Enum.uniq(values)

  defp compare_ids(source_ids, guide_ids, scope) do
    expected_prefix = "#{scope}/"
    source_scoped = Enum.filter(source_ids, &String.starts_with?(&1, expected_prefix))
    guide_scoped = Enum.filter(guide_ids, &String.starts_with?(&1, expected_prefix))

    source_set = MapSet.new(source_scoped)
    guide_set = MapSet.new(guide_scoped)

    %{
      source_duplicates: duplicate_values(source_ids),
      guide_duplicates: duplicate_values(guide_ids),
      wrong_source_scope: Enum.reject(source_ids, &String.starts_with?(&1, expected_prefix)),
      wrong_guide_scope: Enum.reject(guide_ids, &String.starts_with?(&1, expected_prefix)),
      missing: MapSet.difference(source_set, guide_set) |> MapSet.to_list() |> Enum.sort(),
      extra: MapSet.difference(guide_set, source_set) |> MapSet.to_list() |> Enum.sort()
    }
  end

  defp assert_exact_ids!(source_ids, guide_ids, scope) do
    report = compare_ids(source_ids, guide_ids, scope)

    assert report.wrong_source_scope == [],
           "#{@changelog_path} contains IDs outside #{scope}: #{inspect(report.wrong_source_scope)}"

    assert report.wrong_guide_scope == [],
           "#{@guide_path} contains IDs outside #{scope}: #{inspect(report.wrong_guide_scope)}"

    assert report.source_duplicates == [],
           "#{@changelog_path} duplicates #{scope} IDs: #{inspect(report.source_duplicates)}"

    assert report.guide_duplicates == [],
           "#{@guide_path} duplicates #{scope} IDs: #{inspect(report.guide_duplicates)}"

    assert report.missing == [],
           "#{@guide_path} is missing #{scope} change IDs from #{@changelog_path}: #{inspect(report.missing)}"

    assert report.extra == [],
           "#{@guide_path} has unmatched #{scope} change IDs: #{inspect(report.extra)}"
  end

  test "the 0.11-only preflight maps the three 0.12.0 breaking changes exactly" do
    release_012 = changelog_scope!(changelog(), "0.12")
    source = subsection!(release_012, "Breaking changes", @changelog_path)

    source_ids = bullet_ids!(source, "0.12", @changelog_path)

    guide_content = guide()

    preflight =
      heading_section!(guide_content, ~r/^## Before you upgrade from 0\.11\.x$/, @guide_path)

    guide_ids = extract_ids(preflight)

    assert Regex.scan(~r/## Step \d+:/, guide_content) |> length() == 7,
           "#{@guide_path} must have exactly seven numbered 1.0 steps"

    assert String.contains?(preflight, "0.11.x")
    assert String.contains?(preflight, "upgrade-path.md")
    assert String.contains?(preflight, "CHANGELOG.md")
    assert String.contains?(preflight, "CHANGELOG.md#breaking-changes-0-12-0")
    assert String.contains?(release_012, "<a id=\"breaking-changes-0-12-0\"></a>")
    assert_exact_ids!(source_ids, guide_ids, "0.12")
  end

  test "the seven ordered 1.0 steps map every breaking change and deprecation exactly" do
    scope = changelog_scope!(changelog(), "1.0")
    breaking = subsection!(scope, "Breaking changes", @changelog_path)
    deprecations = subsection!(scope, "Deprecations", @changelog_path)

    source_ids =
      bullet_ids!(breaking, "1.0", @changelog_path) ++
        bullet_ids!(deprecations, "1.0", @changelog_path)

    content = guide()

    offsets =
      Enum.map(@step_headings, fn heading ->
        case :binary.match(content, heading) do
          {offset, _} -> offset
          :nomatch -> flunk("expected #{@guide_path} to contain #{inspect(heading)}")
        end
      end)

    assert offsets == Enum.sort(offsets), "the seven 1.0 step headings must appear in order"

    assert Regex.scan(~r/(?m)^## Step \d+:/, content) |> length() == 7,
           "#{@guide_path} must contain only seven numbered 1.0 steps"

    {first_step, _} = :binary.match(content, @step_headings |> List.first())
    common_steps = binary_part(content, first_step, byte_size(content) - first_step)

    guide_ids = extract_ids(common_steps)

    assert_exact_ids!(source_ids, guide_ids, "1.0")
    assert Regex.match?(~r/1\.0 changes require no\s+trigger regeneration/, content)
    assert String.contains?(content, "AuditTransaction")
    assert String.contains?(content, "AuditAction")
    assert String.contains?(content, "action_id")
    assert String.contains?(content, "PostgreSQL 15")
    assert String.contains?(content, "deprecated unbounded history read")
    refute String.contains?(content, "Threadline.history/3")
  end

  test "the guide is registered in ExDoc and the Adopt guide graph" do
    mix = File.read!("mix.exs")
    assert String.contains?(mix, "\"guides/upgrading-to-1.0.md\"")

    adopt_group =
      mix
      |> String.split("Adopt:", parts: 2)
      |> List.last()
      |> String.split("Operate:", parts: 2)
      |> hd()

    assert String.contains?(adopt_group, "upgrading-to-1\\.0")

    guide = File.read!(@guide_path)
    assert String.contains?(guide, "timeline_page/2")
    assert String.contains?(guide, "actor_history/2")
    assert String.contains?(guide, "actor_window/3")
    assert String.contains?(guide, "correlation_bundle/3")

    graph = File.read!("test/threadline/guide_graph_contract_test.exs")
    assert String.contains?(graph, "\"guides/upgrading-to-1.0.md\"")
  end

  test "the ID extractor handles empty and single-ID regions" do
    assert extract_ids("no upgrade markers here") == []

    assert extract_ids("<!-- threadline:upgrade:1.0:single-change -->") == [
             "1.0/single-change"
           ]
  end

  test "the source selector accepts Unreleased staging and a dated 1.0.0 block" do
    staged =
      "## Unreleased — highlights\n\n### Breaking changes\n- staged\n## [0.12.0] - 2026-10-02\n"

    released =
      "## Unreleased — highlights\n\n### Breaking changes\n- future\n" <>
        "## [1.0.0] - 2026-10-10\n\n### Breaking changes\n- released\n## [0.12.0] - 2026-10-02\n"

    assert String.contains?(changelog_scope!(staged, "1.0"), "- staged")
    assert String.contains?(changelog_scope!(released, "1.0"), "- released")
    refute String.contains?(changelog_scope!(released, "1.0"), "- future")
  end

  test "source and guide mutations report removed, added, duplicated, wrong-set, and cross-scope IDs" do
    assert compare_ids([], [], "1.0").missing == []
    assert compare_ids([], [], "1.0").extra == []

    source_removed = compare_ids(["1.0/a"], [], "1.0")
    assert source_removed.extra == []
    assert source_removed.missing == ["1.0/a"]

    guide_removed = compare_ids([], ["1.0/a"], "1.0")
    assert guide_removed.missing == []
    assert guide_removed.extra == ["1.0/a"]

    unmatched_source = compare_ids(["1.0/a", "1.0/new-source"], ["1.0/a"], "1.0")
    assert unmatched_source.missing == ["1.0/new-source"]

    unmatched_guide = compare_ids(["1.0/a"], ["1.0/a", "1.0/new-guide"], "1.0")
    assert unmatched_guide.extra == ["1.0/new-guide"]

    equal_size_wrong_set = compare_ids(["1.0/a"], ["1.0/b"], "1.0")
    assert equal_size_wrong_set.missing == ["1.0/a"]
    assert equal_size_wrong_set.extra == ["1.0/b"]

    duplicate_source = compare_ids(["1.0/a", "1.0/a"], ["1.0/a"], "1.0")
    assert duplicate_source.source_duplicates == ["1.0/a"]

    duplicate_guide = compare_ids(["1.0/a"], ["1.0/a", "1.0/a"], "1.0")
    assert duplicate_guide.guide_duplicates == ["1.0/a"]

    moved_preflight_id = compare_ids(["1.0/a"], ["0.12/preflight-change"], "1.0")
    assert moved_preflight_id.missing == ["1.0/a"]
    assert moved_preflight_id.wrong_guide_scope == ["0.12/preflight-change"]
  end
end
