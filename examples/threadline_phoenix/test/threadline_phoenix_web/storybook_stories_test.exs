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
    {"button", ["<UI.button"]},
    {"icon button", ["<UI.icon_button"]},
    {"link", ["<UI.link"]},
    {"badge", ["<UI.badge"]},
    {"alert", ["<UI.alert"]},
    {"divider", ["<UI.divider"]},
    {"spinner", ["<UI.spinner"]},
    {"avatar", ["<UI.avatar"]},
    {"card", ["<UI.card"]},
    {"stack", ["<UI.stack"]},
    {"cluster", ["<UI.cluster"]},
    {"page header", ["<UI.page_header"]},
    {"pager", ["<UI.pager"]},
    {"stat tile", ["<UI.stat_tile"]}
  ]

  @form_contracts [
    {"field/input", ["<UI.field", "<UI.input"]},
    {"label", ["<UI.label"]},
    {"help text", ["<UI.help"]},
    {"error text", ["<UI.error"]},
    {"error summary", ["<UI.error_summary"]},
    {"field group", ["<UI.field_group"]},
    {"checkbox", [~s|type="checkbox"|]},
    {"radio", ["<UI.radio"]},
    {"switch", ["<UI.switch"]},
    {"select", [~s|type="select"|]},
    {"textarea", [~s|type="textarea"|]},
    {"combobox", ["<UI.combobox"]}
  ]

  @overlay_contracts [
    {"modal", ["<UI.modal"]},
    {"drawer", ["<UI.drawer"]},
    {"toast", ["<UI.toast"]},
    {"tooltip", ["<UI.tooltip"]},
    {"popover", ["<UI.popover"]},
    {"dropdown", ["<UI.dropdown"]},
    {"accordion", ["<UI.accordion"]},
    {"tabs", ["<UI.tabs"]},
    {"segmented control", ["<UI.segmented_control"]}
  ]

  @data_display_contracts [
    {"ref", ["<UI.ref"]},
    {"kv", ["<UI.kv"]},
    {"data table", ["<UI.data_table"]},
    {"data panel", ["<UI.data_panel"]},
    {"code block", ["<UI.code_block"]},
    {"detail header", ["<UI.detail_header"]},
    {"toolbar", ["<UI.toolbar"]}
  ]

  @group_story_ids [
    "group.toolbar.current",
    "group.data-panel.current",
    "group.detail-header.current",
    "group.modal-destructive.current",
    "group.offline.current",
    "group.permission-denied.current"
  ]

  @pattern_contracts [
    "toolbar plus filters",
    "detail header plus metadata",
    "data panel plus state and pager",
    "inert destructive modal",
    "offline and reconnect",
    "permission denied"
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
    source = story_file!("primitives/button.story.exs")

    for {component, markers} <- @primitive_contracts do
      assert rendered_or_source_backed?(source, component, markers),
             "missing primitive Storybook coverage or source-backed rationale for #{component}"
    end
  end

  test "form stories cover the UI-SPEC minimum or provide source-backed rationale" do
    source = story_file!("forms/field.story.exs")

    for {component, markers} <- @form_contracts do
      assert rendered_or_source_backed?(source, component, markers),
             "missing form Storybook coverage or source-backed rationale for #{component}"
    end
  end

  test "overlay stories cover the UI-SPEC minimum with inert focus-contract examples" do
    source = story_file!("overlays/modal.story.exs")

    for {component, markers} <- @overlay_contracts do
      assert rendered_or_source_backed?(source, component, markers),
             "missing overlay Storybook coverage or source-backed rationale for #{component}"
    end

    assert source =~ "focus"
    assert source =~ "keyboard"
    assert source =~ "inert destructive"
    refute source =~ "phx-submit"
    refute source =~ "JS.push"
  end

  test "data-display stories cover the UI-SPEC minimum with representative ugly data" do
    source = story_file!("data_display/data_table.story.exs") <> "\n" <> helper_sources()

    for {component, markers} <- @data_display_contracts do
      assert rendered_or_source_backed?(source, component, markers),
             "missing data-display Storybook coverage or source-backed rationale for #{component}"
    end

    for ugly_case <- [
          "long_id",
          "null_fields",
          "mixed_severity",
          "pagination_boundary",
          "timezone_boundary",
          "disabled",
          "error",
          "empty"
        ] do
      assert source =~ ugly_case, "missing data-display ugly-data case #{ugly_case}"
    end
  end

  test "group stories are traceable to explicit recurring stress fixture groups" do
    source = story_file!("groups/operator_groups.story.exs")

    assert source =~ "Threadline.OperatorSurface.StressFixtures"
    assert source =~ "fixture provenance"
    assert source =~ "ledger remains"

    for story_id <- @group_story_ids do
      assert source =~ story_id, "missing recurring group Storybook coverage for #{story_id}"
    end
  end

  test "patterns branch stays small and excludes stress page-flow generation" do
    source = story_file!("patterns/operator_patterns.story.exs")

    for contract <- @pattern_contracts do
      assert source =~ contract, "missing small Patterns branch contract #{contract}"
    end

    refute source =~ ".planning/design-system-ledger.json"
    refute source =~ "page.home"
    refute source =~ "page.timeline"
    refute source =~ "footgun."
    refute source =~ "operator-stress"
  end

  defp rendered_or_source_backed?(source, component, markers) do
    Enum.all?(markers, &String.contains?(source, &1)) or
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

  defp story_file!(relative_path) do
    path = Path.join(@storybook_root, relative_path)

    assert File.exists?(path), "expected curated PhoenixStorybook story file #{path}"
    File.read!(path)
  end

  defp helper_sources do
    @wrapper_glob
    |> Path.wildcard()
    |> Enum.filter(&File.regular?/1)
    |> Enum.map_join("\n", &File.read!/1)
  end
end
