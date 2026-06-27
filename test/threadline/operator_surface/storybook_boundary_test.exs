defmodule Threadline.OperatorSurface.StorybookBoundaryTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @root_package_files ~w(mix.exs mix.lock)
  @root_source_globs ~w(
    lib/threadline/**/*.ex
    lib/threadline/**/*.exs
  )

  @example_allowed_globs ~w(
    examples/threadline_phoenix/mix.exs
    examples/threadline_phoenix/mix.lock
    examples/threadline_phoenix/lib/**/*.ex
    examples/threadline_phoenix/lib/**/*.exs
    examples/threadline_phoenix/storybook/**/*.exs
  )

  @storybook_terms [
    "PhoenixStorybook",
    "phoenix_storybook",
    "live_storybook",
    "storybook_assets",
    "/dev/storybook"
  ]

  test "root package files do not depend on PhoenixStorybook" do
    for path <- existing_paths(@root_package_files) do
      source = File.read!(path)

      for term <- @storybook_terms do
        refute source =~ term, "#{path} must not contain #{term}"
      end
    end
  end

  test "root operator source does not expose Storybook route or macro surface" do
    for path <- existing_paths(@root_source_globs) do
      source = File.read!(path)

      for term <- @storybook_terms do
        refute source =~ term, "#{path} must not contain #{term}"
      end
    end
  end

  test "Storybook terms are allowed only inside the Phoenix example maintainer lane" do
    scanned_paths =
      existing_paths(@root_package_files ++ @root_source_globs ++ @example_allowed_globs)

    for path <- scanned_paths,
        source = File.read!(path),
        term <- @storybook_terms,
        source =~ term do
      assert String.starts_with?(path, "examples/threadline_phoenix/"),
             "#{term} may only appear in examples/threadline_phoenix, found in #{path}"
    end
  end

  test "root public router macro remains distinct from stress and component-lab routes" do
    router_source = File.read!("lib/threadline/operator_surface/router.ex")

    refute router_source =~ "threadline_operator_surface_stress"
    refute router_source =~ "threadline_operator_surface_storybook"
    refute router_source =~ ~s|"/__stress"|
    refute router_source =~ ~s|"/dev/storybook"|
    refute router_source =~ "live_storybook"
  end

  defp existing_paths(patterns) do
    patterns
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.filter(&File.regular?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
