defmodule Threadline.FormatterTopologyContractTest do
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)

  @representative_paths [
    ".formatter.exs",
    "config/config.exs",
    "lib/threadline.ex",
    "test/test_helper.exs",
    "bench/audit_capture_bench.exs",
    "bench/scripts/seed_audit_changes.exs",
    "examples/threadline_phoenix/mix.exs",
    "examples/threadline_phoenix/lib/threadline_phoenix.ex",
    "examples/threadline_phoenix/storybook/index.exs",
    "examples/threadline_phoenix/priv/scripts/incident_replay.exs",
    "examples/threadline_phoenix/priv/repo/seeds.exs",
    "examples/threadline_phoenix/priv/repo/migrations/20260424080611_create_posts.exs"
  ]

  test "repository formatter configs give representative Elixir files exactly one owner" do
    owners = formatter_owners(Path.join(@root, ".formatter.exs"))
    owner_files = Enum.map(owners, &{&1, owned_files(&1)})
    root_config = owner!(owners, @root).config

    assert Keyword.get(root_config, :subdirectories, []) == [
             "bench",
             "examples/threadline_phoenix"
           ]

    assert "scripts/**/*.{ex,exs}" in Keyword.fetch!(root_config, :inputs)

    assert ownership_errors(@representative_paths, owner_files) == [],
           "every representative path must have exactly one formatter owner"

    overlapping =
      update_owner(owners, @root, fn config ->
        Keyword.update!(config, :inputs, &["bench/**/*.exs" | &1])
      end)

    overlapping_owner = owner!(overlapping, @root)
    overlapping_owner_files = replace_owner_files(owner_files, overlapping_owner)

    assert ownership_errors(["bench/audit_capture_bench.exs"], overlapping_owner_files) == [
             {"bench/audit_capture_bench.exs", :overlap, [@root, Path.join(@root, "bench")]}
           ]

    uncovered =
      update_owner(owners, Path.join(@root, "bench"), fn config ->
        Keyword.update!(config, :inputs, &List.delete(&1, "*.{ex,exs}"))
      end)

    uncovered_owner = owner!(uncovered, Path.join(@root, "bench"))
    uncovered_owner_files = replace_owner_files(owner_files, uncovered_owner)

    assert ownership_errors(["bench/audit_capture_bench.exs"], uncovered_owner_files) == [
             {"bench/audit_capture_bench.exs", :uncovered, []}
           ]
  end

  defp formatter_owners(config_path) do
    {config, _binding} = Code.eval_file(config_path)
    root = Path.dirname(config_path)
    owner = %{root: root, config: config}

    children =
      config
      |> Keyword.get(:subdirectories, [])
      |> Enum.flat_map(&Path.wildcard(Path.join(root, &1)))
      |> Enum.map(&Path.join(&1, ".formatter.exs"))
      |> Enum.flat_map(fn child_config ->
        assert File.regular?(child_config),
               "formatter subdirectory #{Path.dirname(child_config)} has no .formatter.exs"

        formatter_owners(child_config)
      end)

    [owner | children]
  end

  defp ownership_errors(paths, owned_files_by_owner) do
    Enum.flat_map(paths, fn relative_path ->
      absolute_path = Path.join(@root, relative_path)

      matching_roots =
        owned_files_by_owner
        |> Enum.filter(fn {_owner, files} -> MapSet.member?(files, absolute_path) end)
        |> Enum.map(fn {owner, _files} -> owner.root end)
        |> Enum.sort()

      case matching_roots do
        [_owner] -> []
        [] -> [{relative_path, :uncovered, []}]
        roots -> [{relative_path, :overlap, roots}]
      end
    end)
  end

  defp owned_files(%{root: root, config: config}) do
    config
    |> Keyword.fetch!(:inputs)
    |> Enum.flat_map(&Path.wildcard(Path.join(root, &1), match_dot: true))
    |> MapSet.new()
  end

  defp replace_owner_files(owned_files_by_owner, changed_owner) do
    changed_files = owned_files(changed_owner)

    Enum.map(owned_files_by_owner, fn {owner, files} ->
      if owner.root == changed_owner.root,
        do: {changed_owner, changed_files},
        else: {owner, files}
    end)
  end

  defp owner!(owners, root), do: Enum.find(owners, &(&1.root == root))

  defp update_owner(owners, root, update) do
    Enum.map(owners, fn owner ->
      if owner.root == root, do: %{owner | config: update.(owner.config)}, else: owner
    end)
  end
end
