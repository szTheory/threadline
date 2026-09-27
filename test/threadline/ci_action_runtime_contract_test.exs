defmodule Threadline.CiActionRuntimeContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  # Fail-closed allowlist of every `{action, ref}` pair a workflow may use.
  #
  # Each entry was verified by fetching that ref's action.yml and reading
  # `runs.using`. To add or re-pin an action, fetch its action.yml at the exact
  # ref, confirm `node24`, `composite` or `docker`, then add the entry here.
  # Anything not listed (including a Node 20 major) fails the live scan.
  @node24_or_non_js %{
    {"actions/checkout", "v5"} => :node24,
    {"erlef/setup-beam", "v1"} => :node24,
    {"actions/setup-node", "v5"} => :node24,
    {"actions/cache", "v5"} => :node24,
    {"actions/cache/restore", "v5"} => :node24,
    {"actions/cache/save", "v5"} => :node24,
    {"actions/upload-artifact", "v7"} => :node24,
    {"actions/github-script", "v8"} => :node24,
    {"googleapis/release-please-action", "v5"} => :node24,
    {"re-actors/alls-green", "b5b5b37504aa4183270bd3d855c52a67f212be35"} => :composite
  }

  @remedy "fetch the action's action.yml at that exact ref, confirm `runs.using` is " <>
            "node24, composite or docker, then add the {action, ref} pair to " <>
            "@node24_or_non_js in this test"

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  # Globs BOTH extensions on purpose. GitHub Actions honours .yaml as well as
  # .yml, so a guard that only globbed .yml could be defeated by a rename.
  defp workflow_paths do
    paths =
      @repo_root
      |> Path.join(".github/workflows/*.{yml,yaml}")
      |> Path.wildcard()
      |> Enum.map(&Path.relative_to(&1, @repo_root))
      |> Enum.sort()

    assert paths != [],
           "no workflow files found under .github/workflows — refusing to pass vacuously"

    paths
  end

  defp live_yaml_by_path do
    Map.new(workflow_paths(), &{&1, read_rel!([&1])})
  end

  defp strip_comment_lines(block) do
    block
    |> String.split("\n")
    |> Enum.reject(&String.match?(&1, ~r/^\s*#/))
    |> Enum.join("\n")
  end

  # Returns every `uses:` value on comment-stripped lines, in both the mapping
  # form (`uses: x@y`) and the list-item form (`- uses: x@y`), quoted or not.
  # Local (`./`) and `docker://` refs come back tagged so they are reported,
  # not silently skipped.
  defp uses_refs(yaml) do
    ~r/^\s*(?:-\s+)?uses:\s*["']?([^\s"'#]+)/m
    |> Regex.scan(strip_comment_lines(yaml), capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(&classify_ref/1)
  end

  defp classify_ref("./" <> _ = value), do: {:needs_decision, value}
  defp classify_ref("docker://" <> _ = value), do: {:needs_decision, value}

  defp classify_ref(value) do
    case String.split(value, "@", parts: 2) do
      [action, ref] when action != "" and ref != "" -> {:pair, {action, ref}}
      _ -> {:needs_decision, value}
    end
  end

  defp node20_errors(yaml_by_path) do
    yaml_by_path
    |> Enum.sort()
    |> Enum.flat_map(fn {path, yaml} ->
      yaml |> uses_refs() |> Enum.flat_map(&ref_error(path, &1))
    end)
  end

  defp ref_error(path, {:pair, {action, ref} = pair}) do
    if Map.has_key?(@node24_or_non_js, pair) do
      []
    else
      [
        "#{path}: #{action}@#{ref} is not verified as a Node 24 (or non-JavaScript) " <>
          "action — #{@remedy}"
      ]
    end
  end

  defp ref_error(path, {:needs_decision, value}) do
    [
      "#{path}: `uses: #{value}` is a local, docker or unpinned ref and needs an " <>
        "explicit allowlist decision before any workflow may use it"
    ]
  end

  defp used_pairs(yaml_by_path) do
    yaml_by_path
    |> Map.values()
    |> Enum.flat_map(&uses_refs/1)
    |> Enum.flat_map(fn
      {:pair, pair} -> [pair]
      _ -> []
    end)
    |> Enum.uniq()
  end

  describe "live workflows" do
    test "every workflow action ref is verified as Node 24 or non-JavaScript" do
      yaml_by_path = live_yaml_by_path()

      assert node20_errors(yaml_by_path) == []

      ref_count = yaml_by_path |> Map.values() |> Enum.flat_map(&uses_refs/1) |> length()

      assert ref_count > 0,
             "the workflow scan found no `uses:` refs at all — the scanner is broken, " <>
               "not the workflows clean"
    end

    test "every allowlist entry is used by at least one workflow" do
      unused = Map.keys(@node24_or_non_js) -- used_pairs(live_yaml_by_path())

      assert unused == [],
             "stale @node24_or_non_js entries (used by no workflow; remove them so the " <>
               "allowlist stays an exact record of what runs): #{inspect(Enum.sort(unused))}"
    end
  end

  describe "node20_errors/1 mutation controls" do
    test "flags a known Node 20 cache major" do
      yaml = "      - name: Cache\n        uses: " <> "actions/cache@" <> "v4" <> "\n"
      assert [message] = node20_errors(%{"synthetic.yml" => yaml})
      assert message =~ "actions/cache@v4"
      assert message =~ "synthetic.yml"
    end

    test "flags the previous Release Please action major" do
      yaml = "        uses: " <> "googleapis/release-please-action@" <> "v4" <> "\n"
      assert [_] = node20_errors(%{"synthetic.yml" => yaml})
    end

    test "fails closed on an unknown action" do
      yaml = "        uses: some-org/new-action@v1\n"
      assert [message] = node20_errors(%{"synthetic.yml" => yaml})
      assert message =~ "some-org/new-action@v1"
      assert message =~ "action.yml"
    end

    test "flags the list-item form" do
      yaml = "      - uses: " <> "actions/upload-artifact@" <> "v4" <> "\n"
      assert [message] = node20_errors(%{"synthetic.yml" => yaml})
      assert message =~ "actions/upload-artifact@v4"
    end

    test "flags a quoted ref" do
      yaml = "        uses: \"" <> "actions/cache@" <> "v4" <> "\"\n"
      assert [message] = node20_errors(%{"synthetic.yml" => yaml})
      assert message =~ "actions/cache@v4"
    end

    test "ignores a commented-out ref" do
      yaml = "        # uses: " <> "actions/cache@" <> "v4" <> "\n"
      assert node20_errors(%{"synthetic.yml" => yaml}) == []
    end

    test "reports local and docker refs as needing an explicit decision" do
      yaml = """
            - uses: ./.github/actions/setup
            - uses: docker://alpine:3.20
      """

      errors = node20_errors(%{"synthetic.yml" => yaml})
      assert length(errors) == 2
      assert Enum.all?(errors, &(&1 =~ "explicit allowlist decision"))
    end

    test "passes a benign workflow that uses only allowlisted refs" do
      yaml = """
      jobs:
        build:
          steps:
            - uses: actions/checkout@v5
            - name: Cache
              uses: actions/cache@v5 # trailing comment
            - uses: "erlef/setup-beam@v1"
      """

      assert node20_errors(%{"synthetic.yml" => yaml}) == []
    end
  end
end
