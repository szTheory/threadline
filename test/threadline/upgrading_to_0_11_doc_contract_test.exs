defmodule Threadline.UpgradingTo011DocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  # Copied from test/threadline/release_artifact_contract_test.exs @banned_shapes
  # (D-06): the release archive scan already runs these over the whole built
  # Hex tarball; this contract catches the same shapes locally, before build.
  @banned_shapes [
    {:phase_prose, ~r/\bPhase\s+\d+(?:\.\d+)?\b/i},
    {:phase_identifier, ~r/\bphase[_-]?\d+(?:[_-][a-z0-9_]+)?\b/i},
    {:decision_id, ~r/\bD-\d{2,}\b/},
    {:requirement_id,
     ~r/\b(?:ADOPT|COMP|CRITIC|DATA|GREEN|GROUP|MECH|NAV|PROOF|SURFACE|WR)-\d{2,}\b/},
    {:milestone_literal, ~r/\bv1\.(?:3[4-9]|4[01])\b/}
  ]

  @guide_path "guides/upgrading-to-0.11.md"

  defp guide, do: File.read!(@guide_path)

  @headings [
    "## Who this guide is for",
    "## Before you start",
    "## Step 1: Bump the dependency",
    "## Step 2: Regenerate triggers",
    "## Step 3: Migrate",
    "## Step 4: Add the row-history index",
    "## Step 5: Verify coverage",
    "## Step 6 (optional): Backfill unresolved primary keys",
    "## What cannot be recovered",
    "## What changed that you may notice",
    "## Rolling back",
    "## Next steps"
  ]

  @step_headings [
    "## Step 1: Bump the dependency",
    "## Step 2: Regenerate triggers",
    "## Step 3: Migrate",
    "## Step 4: Add the row-history index",
    "## Step 5: Verify coverage",
    "## Step 6 (optional): Backfill unresolved primary keys"
  ]

  test "guide carries all twelve locked headings, with the six steps in ascending order" do
    content = guide()

    for heading <- @headings do
      assert String.contains?(content, heading),
             "expected guides/upgrading-to-0.11.md to contain #{inspect(heading)}"
    end

    offsets =
      Enum.map(@step_headings, fn heading ->
        {offset, _len} = :binary.match(content, heading)
        offset
      end)

    assert offsets == Enum.sort(offsets),
           "expected the six Step headings to appear in ascending order, got offsets #{inspect(offsets)}"
  end

  test "guide pins the locked commands and their step order" do
    content = guide()

    commands = [
      "mix threadline.gen.triggers --tables",
      "mix ecto.migrate",
      "mix threadline.gen.row_history_index",
      "DROP INDEX CONCURRENTLY IF EXISTS",
      "mix threadline.verify_coverage",
      "mix threadline.health.coverage"
    ]

    for command <- commands do
      assert String.contains?(content, command),
             "expected guides/upgrading-to-0.11.md to contain #{inspect(command)}"
    end

    {regenerate_at, _} = :binary.match(content, "mix threadline.gen.triggers --tables")
    {index_at, _} = :binary.match(content, "mix threadline.gen.row_history_index")
    {verify_at, _} = :binary.match(content, "mix threadline.verify_coverage")

    assert regenerate_at < index_at,
           "expected the regenerate-triggers command before the row-history-index command"

    assert index_at < verify_at,
           "expected the row-history-index command before the verify-coverage command"
  end

  test "guide states the together-regeneration rule verbatim" do
    content = guide()

    assert String.contains?(
             content,
             "Tables that shared a capture function must be regenerated together in one " <>
               "`mix threadline.gen.triggers --tables` run."
           )
  end

  test "mix.exs exposes the new guide in ExDoc extras" do
    mix_exs = File.read!("mix.exs")
    assert String.contains?(mix_exs, "\"guides/upgrading-to-0.11.md\"")
  end

  @markers [
    "<!-- threadline:backfill-sql:start -->",
    "<!-- threadline:backfill-sql:end -->",
    "<!-- threadline:backfill-sql-composite:start -->",
    "<!-- threadline:backfill-sql-composite:end -->",
    "<!-- threadline:rollback-cleanup-sql:start -->",
    "<!-- threadline:rollback-cleanup-sql:end -->"
  ]

  test "guide carries each locked marker exactly once" do
    content = guide()

    for marker <- @markers do
      assert Regex.scan(~r/#{Regex.escape(marker)}/, content) |> length() == 1,
             "expected exactly one #{marker}"
    end
  end

  defp extract_marker_block!(content, marker) do
    start_marker = "<!-- threadline:#{marker}:start -->"
    end_marker = "<!-- threadline:#{marker}:end -->"

    assert Regex.scan(~r/#{Regex.escape(start_marker)}/, content) |> length() == 1,
           "expected exactly one #{start_marker}"

    assert Regex.scan(~r/#{Regex.escape(end_marker)}/, content) |> length() == 1,
           "expected exactly one #{end_marker}"

    {start_at, _} = :binary.match(content, start_marker)
    {end_at, _} = :binary.match(content, end_marker)
    assert start_at < end_at, "expected #{start_marker} to precede #{end_marker}"

    [_, rest] = String.split(content, start_marker, parts: 2)
    [block, _] = String.split(rest, end_marker, parts: 2)
    block
  end

  test "backfill-sql marker block is one guarded, batched sql statement" do
    block = extract_marker_block!(guide(), "backfill-sql")

    assert Regex.scan(~r/```sql/, block) |> length() == 1

    for fragment <- [
          "jsonb_build_object(",
          "data_after ->> '<key_col>'",
          ~s('{"id": null}'::jsonb),
          "'{}'::jsonb",
          "op IN ('insert', 'update')",
          "IS NOT NULL",
          "LIMIT <batch_size>"
        ] do
      assert String.contains?(block, fragment),
             "expected backfill-sql block to contain #{inspect(fragment)}"
    end

    refute Regex.match?(~r/data_after\s*->\s*'/, block),
           "backfill-sql block must use the text (->>) arrow, never the JSON (->) arrow"
  end

  test "backfill-sql-composite marker block is one guarded, batched sql statement" do
    block = extract_marker_block!(guide(), "backfill-sql-composite")

    assert Regex.scan(~r/```sql/, block) |> length() == 1

    for fragment <- [
          "jsonb_build_object(",
          "data_after ->> '<key_col_1>'",
          "data_after ->> '<key_col_2>'",
          ~s('{"id": null}'::jsonb),
          "'{}'::jsonb",
          "op IN ('insert', 'update')",
          "IS NOT NULL",
          "LIMIT <batch_size>"
        ] do
      assert String.contains?(block, fragment),
             "expected backfill-sql-composite block to contain #{inspect(fragment)}"
    end

    refute Regex.match?(~r/data_after\s*->\s*'/, block),
           "backfill-sql-composite block must use the text (->>) arrow, never the JSON (->) arrow"
  end

  test "rollback-cleanup-sql marker block drops only orphaned functions, without cascade" do
    block = extract_marker_block!(guide(), "rollback-cleanup-sql")

    assert String.contains?(block, "DROP FUNCTION")
    assert String.contains?(block, "NOT EXISTS")
    refute String.contains?(block, "CASCADE")
  end

  test "guide states every D-191-style upgrade fact an adopter needs" do
    content = guide()

    for fact <- [
          ~s({"id": null}),
          "{}",
          "ArgumentError",
          "primary_key:",
          "config :threadline, :trigger_capture",
          "timestamptz",
          "mask",
          "exclude",
          "ENABLE TRIGGER",
          "shared_capture_function"
        ] do
      assert String.contains?(content, fact),
             "expected guides/upgrading-to-0.11.md to state the fact #{inspect(fact)}"
    end
  end

  test "guide carries no phase, decision, requirement, or milestone vocabulary" do
    content = guide()

    matches =
      for {line, line_number} <- content |> String.split("\n") |> Enum.with_index(1),
          {shape, regex} <- @banned_shapes,
          Regex.match?(regex, line),
          do: {shape, line_number, String.trim(line)}

    assert matches == [],
           "guides/upgrading-to-0.11.md carries planning vocabulary that must not ship: " <>
             inspect(matches)
  end
end
