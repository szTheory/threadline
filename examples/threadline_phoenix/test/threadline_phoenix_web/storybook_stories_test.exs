defmodule ThreadlinePhoenixWeb.StorybookStoriesTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @storybook_root "storybook"
  @backend_path "lib/threadline_phoenix_web/storybook.ex"
  @wrapper_glob "lib/threadline_phoenix_web/storybook/**/*.{ex,exs}"

  @categories [
    {"Foundations", "foundations"},
    {"Primitives", "primitives"},
    {"Forms", "forms"},
    {"States", "states"},
    {"Overlays", "overlays"},
    {"Data Display", "data_display"},
    {"Groups", "groups"},
    {"Patterns", "patterns"}
  ]

  @ugly_cases ~w(
    long_id
    long_string
    non_ascii
    null_fields
    mixed_severity
    permission_denied
    stale
    reconnecting
    pagination_boundary
    timezone_boundary
    disabled
    error
    empty
    zero_count
  )

  @primitive_contracts [
    {"button", ["button", "UI.button"]},
    {"icon button", ["icon_button", "UI.icon_button"]},
    {"link", ["link", "UI.link"]},
    {"badge", ["badge", "UI.badge"]},
    {"alert", ["alert", "UI.alert"]},
    {"divider", ["divider", "UI.divider"]},
    {"spinner", ["spinner", "UI.spinner"]},
    {"avatar", ["avatar", "UI.avatar"]},
    {"card", ["card", "UI.card"]},
    {"stack", ["stack", "UI.stack"]},
    {"cluster", ["cluster", "UI.cluster"]},
    {"page header", ["page_header", "UI.page_header"]},
    {"pager", ["pager", "UI.pager"]},
    {"stat tile", ["stat_tile", "UI.stat_tile"]}
  ]

  @form_contracts [
    {"field/input", ["field", "UI.field", "input"]},
    {"label", ["label"]},
    {"help text", ["help", "help text"]},
    {"error text", ["error", "error text"]},
    {"error summary", ["error_summary", "UI.error_summary"]},
    {"field group", ["field_group", "UI.field_group"]},
    {"checkbox", ["checkbox"]},
    {"radio", ["radio"]},
    {"switch", ["switch"]},
    {"select", ["select"]},
    {"textarea", ["textarea"]},
    {"combobox", ["combobox", "UI.combobox"]}
  ]

  test "backend and wrapper render stories through the Threadline preview context" do
    assert File.exists?(@backend_path), "expected Storybook backend at #{@backend_path}"

    source = File.read!(@backend_path) <> "\n" <> helper_sources()

    assert source =~ "use PhoenixStorybook"
    assert source =~ "content_path"
    assert source =~ @storybook_root
    assert source =~ "threadline_preview"
    assert source =~ "preview_section"
    assert source =~ "Threadline.OperatorSurface.Style.css"
    assert source =~ ~s|class="threadline-ui"|
    assert source =~ "data-tl-theme"

    for theme <- ~w(dark light system) do
      assert source =~ theme, "expected #{theme} theme support in Storybook wrapper"
    end
  end

  test "story taxonomy includes the required categories and small Patterns branch" do
    source = story_source!()

    for {label, dir} <- @categories do
      assert File.dir?(Path.join(@storybook_root, dir)),
             "expected Storybook category directory #{dir}"

      assert source =~ label or source =~ dir,
             "expected Storybook category label #{label}"
    end
  end

  test "stories document metadata, wrapper usage, theme support, and ugly-data provenance" do
    source = story_source!() <> "\n" <> helper_sources()

    for term <- [
          "curated documentation",
          "fixture provenance",
          "accessibility",
          "theme support",
          "Threadline.OperatorSurface.StressFixtures",
          "threadline_preview",
          ".threadline-ui",
          "data-tl-theme"
        ] do
      assert source =~ term, "expected story metadata or helper source to mention #{term}"
    end

    for ugly_case <- @ugly_cases do
      assert source =~ ugly_case, "missing representative ugly-data case #{ugly_case}"
    end
  end

  test "primitive stories cover the UI-SPEC minimum or provide source-backed rationale" do
    source = story_source!() <> "\n" <> helper_sources()

    for {component, terms} <- @primitive_contracts do
      assert covered_or_source_backed?(source, component, terms),
             "missing primitive Storybook coverage or source-backed rationale for #{component}"
    end
  end

  test "form stories cover the UI-SPEC minimum or provide source-backed rationale" do
    source = story_source!() <> "\n" <> helper_sources()

    for {component, terms} <- @form_contracts do
      assert covered_or_source_backed?(source, component, terms),
             "missing form Storybook coverage or source-backed rationale for #{component}"
    end
  end

  defp covered_or_source_backed?(source, component, terms) do
    Enum.any?(terms, &String.contains?(source, &1)) or
      (source =~ "unsupported: #{component}" and
         source =~ "Threadline.OperatorSurface.UI" and
         source =~ "source-backed rationale")
  end

  defp story_source! do
    paths = story_paths()

    assert paths != [],
           "expected curated PhoenixStorybook files under #{@storybook_root}"

    Enum.map_join(paths, "\n", &File.read!/1)
  end

  defp story_paths do
    [Path.join(@storybook_root, "**/*.story.exs"), Path.join(@storybook_root, "**/index.exs")]
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.filter(&File.regular?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp helper_sources do
    @wrapper_glob
    |> Path.wildcard()
    |> Enum.filter(&File.regular?/1)
    |> Enum.map_join("\n", &File.read!/1)
  end
end
