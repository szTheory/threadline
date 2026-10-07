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

  defp bullet_ids!(content, scope, source) do
    bullets = Regex.scan(~r/(?ms)^- (.*?)(?=^- |\z)/, content, capture: :all_but_first)

    assert bullets != [], "expected #{source} to contain scoped top-level bullets"

    Enum.flat_map(bullets, fn [bullet] ->
      ids =
        Regex.scan(~r/<!-- threadline:upgrade:#{scope}:([a-z0-9-]+) -->/, bullet,
          capture: :all_but_first
        )

      values = Enum.map(ids, fn [id] -> "#{scope}/#{id}" end)

      assert length(values) == 1,
             "#{source} has a scoped bullet with #{length(values)} #{scope} IDs; expected exactly one: #{String.slice(String.trim(bullet), 0, 120)}"

      values
    end)
  end

  defp duplicate_values(values), do: values -- Enum.uniq(values)

  defp assert_exact_ids!(source_ids, guide_ids, scope) do
    source_duplicates = duplicate_values(source_ids)
    guide_duplicates = duplicate_values(guide_ids)

    assert source_duplicates == [],
           "#{@changelog_path} duplicates #{scope} IDs: #{inspect(source_duplicates)}"

    assert guide_duplicates == [],
           "#{@guide_path} duplicates #{scope} IDs: #{inspect(guide_duplicates)}"

    source_set = MapSet.new(source_ids)
    guide_set = MapSet.new(guide_ids)
    missing = MapSet.difference(source_set, guide_set) |> MapSet.to_list() |> Enum.sort()
    extra = MapSet.difference(guide_set, source_set) |> MapSet.to_list() |> Enum.sort()

    assert missing == [],
           "#{@guide_path} is missing #{scope} change IDs from #{@changelog_path}: #{inspect(missing)}"

    assert extra == [], "#{@guide_path} has unmatched #{scope} change IDs: #{inspect(extra)}"
  end

  test "the 0.11-only preflight maps the three 0.12.0 breaking changes exactly" do
    source =
      changelog_scope!(changelog(), "0.12") |> subsection!("Breaking changes", @changelog_path)

    source_ids = bullet_ids!(source, "0.12", @changelog_path)

    guide_content = guide()

    preflight =
      heading_section!(guide_content, ~r/^## Before you upgrade from 0\.11\.x$/, @guide_path)

    guide_ids =
      Regex.scan(~r/<!-- threadline:upgrade:0\.12:([a-z0-9-]+) -->/, preflight,
        capture: :all_but_first
      )
      |> Enum.map(fn [id] -> "0.12/#{id}" end)

    assert Regex.scan(~r/## Step \d+:/, guide_content) |> length() == 7,
           "#{@guide_path} must have exactly seven numbered 1.0 steps"

    assert String.contains?(preflight, "0.11.x")
    assert String.contains?(preflight, "upgrade-path.md")
    assert String.contains?(preflight, "CHANGELOG.md")
    assert_exact_ids!(source_ids, guide_ids, "0.12 preflight")
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

    guide_ids =
      Regex.scan(~r/<!-- threadline:upgrade:1\.0:([a-z0-9-]+) -->/, common_steps,
        capture: :all_but_first
      )
      |> Enum.map(fn [id] -> "1.0/#{id}" end)

    assert_exact_ids!(source_ids, guide_ids, "1.0 guide")
    assert Regex.match?(~r/1\.0 changes require no\s+trigger regeneration/, content)
    assert String.contains?(content, "AuditTransaction")
    assert String.contains?(content, "AuditAction")
    assert String.contains?(content, "action_id")
    assert String.contains?(content, "PostgreSQL 15")
  end

  test "the guide is registered in ExDoc and the Adopt guide graph" do
    assert String.contains?(File.read!("mix.exs"), "\"guides/upgrading-to-1.0.md\"")
    graph = File.read!("test/threadline/guide_graph_contract_test.exs")
    assert String.contains?(graph, "\"guides/upgrading-to-1.0.md\"")
  end
end
