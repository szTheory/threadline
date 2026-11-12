defmodule Threadline.OperatorSurface.FontsTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias Threadline.OperatorSurface.Fonts
  alias Threadline.Test.StyleSource

  @repo_root Path.expand("../../..", __DIR__)
  @font_dir Path.join([@repo_root, "brand", "assets", "fonts", "web"])

  @approved_faces [
    {"Threadline Familjen Grotesk", "400 700", "FamiljenGrotesk-normal-400-700.woff2"},
    {"Threadline Geist", "400 700", "Geist-normal-400-700.woff2"},
    {"Threadline IBM Plex Mono", "400", "IBMPlexMono-normal-400.woff2"},
    {"Threadline IBM Plex Mono", "500", "IBMPlexMono-normal-500.woff2"}
  ]

  setup do
    original = Application.fetch_env(:threadline, :operator_surface_embed_fonts)

    on_exit(fn ->
      case original do
        {:ok, value} -> Application.put_env(:threadline, :operator_surface_embed_fonts, value)
        :error -> Application.delete_env(:threadline, :operator_surface_embed_fonts)
      end
    end)

    :ok
  end

  test "embeds exactly the approved WOFF2 bytes under private aliases and weights" do
    Application.put_env(:threadline, :operator_surface_embed_fonts, true)
    css = Fonts.face_css()
    faces = Regex.scan(~r/@font-face\s*\{[^}]*\}/s, css)

    assert length(faces) == 4

    for {{family, weight, filename}, [face]} <- Enum.zip(@approved_faces, faces) do
      assert face =~ ~s(font-family: "#{family}";)
      assert face =~ "font-style: normal;"
      assert face =~ "font-weight: #{weight};"
      assert face =~ "font-display: swap;"
      assert String.contains?(face, "format(\"woff2\");")

      assert [encoded] =
               Regex.run(~r/src: url\("data:font\/woff2;base64,([^"]+)"\)/s, face,
                 capture: :all_but_first
               )

      assert Base.decode64!(encoded) == File.read!(Path.join(@font_dir, filename))
    end

    refute css =~ ~s(font-family: "Geist";)
    refute css =~ ~s(font-family: "IBM Plex Mono";)
    refute css =~ ~s(font-family: "Familjen Grotesk";)
  end

  test "an absent embedding option emits the approved faces by default" do
    Application.delete_env(:threadline, :operator_surface_embed_fonts)

    assert Fonts.face_css() =~ ~s(font-family: "Threadline Geist";)
    assert length(Regex.scan(~r/@font-face\s*\{/s, Fonts.face_css())) == 4
  end

  test "the existing false embedding option emits no faces" do
    Application.put_env(:threadline, :operator_surface_embed_fonts, false)

    assert Fonts.face_css() == ""
  end

  test "type tokens and investigation selectors preserve approved roles and fallbacks" do
    src = StyleSource.read!()
    tokens = selector_block!(src, ".threadline-ui")
    heading = selector_block!(src, ".tl-timeline-command__title")
    label = selector_block!(src, ".tl-toolbar__field")
    control = selector_block!(src, ".tl-toolbar__control,\n  .tl-control")
    button = selector_block!(src, ".tl-button")
    value = selector_block!(src, ".tl-value")
    metadata = selector_block!(src, ".tl-timeline-fact__detail")
    table_name = selector_block!(src, ".tl-policy__table")
    record_id = selector_block!(src, ".tl-secondary-ref")
    code_role = selector_block!(src, ".tl-code")

    assert tokens =~ ~s(--tl-font-family: "Threadline Geist",)
    assert tokens =~ ~s(--tl-font-mono: "Threadline IBM Plex Mono",)
    assert tokens =~ ~s(--tl-font-heading: "Threadline Familjen Grotesk",)
    assert tokens =~ "--tl-font-size-body: 16px;"
    assert tokens =~ "--tl-font-size-label: 12px;"
    assert tokens =~ "--tl-font-size-dense: 13px;"
    assert tokens =~ "--tl-font-size-heading: 28px;"
    assert tokens =~ "--tl-line-body: 1.55;"
    assert tokens =~ "--tl-line-label: 1.2;"
    assert tokens =~ "--tl-line-metadata: 1.4;"
    assert tokens =~ "--tl-line-mono: 1.5;"
    assert tokens =~ "system-ui"
    assert tokens =~ "ui-monospace"

    assert heading =~ "font-family: var(--tl-font-heading);"
    assert heading =~ "font-size: var(--tl-font-size-heading);"
    assert heading =~ "font-weight: var(--tl-weight-strong);"
    assert heading =~ "line-height: var(--tl-line-heading);"

    assert label =~ "font-size: var(--tl-font-size-label);"
    assert label =~ "font-weight: var(--tl-weight-strong);"
    assert label =~ "line-height: var(--tl-line-label);"
    assert label =~ "letter-spacing: var(--tl-tracking-caps);"

    for selector <- [control, button] do
      assert selector =~ "font-size: var(--tl-font-size-body);"
      assert selector =~ "font-family: var(--tl-font-family);"
      assert selector =~ "font-weight: var(--tl-weight-regular);"
      assert selector =~ "line-height: var(--tl-line-body);"
    end

    assert value =~ "font-family: var(--tl-font-mono);"
    assert value =~ "font-size: var(--tl-font-size-dense);"
    assert value =~ "font-weight: var(--tl-weight-regular);"
    assert value =~ "line-height: var(--tl-line-mono);"

    assert table_name =~ "font-family: var(--tl-font-mono);"
    assert table_name =~ "font-size: var(--tl-font-size-dense);"
    assert table_name =~ "font-weight: var(--tl-weight-regular);"
    assert table_name =~ "line-height: var(--tl-line-mono);"

    assert code_role =~ "font-size: var(--tl-font-size-dense);"
    assert code_role =~ "line-height: var(--tl-line-mono);"

    assert record_id =~ "font-family: var(--tl-font-mono);"
    assert record_id =~ "font-size: var(--tl-font-size-dense);"
    assert record_id =~ "font-weight: var(--tl-weight-regular);"
    assert record_id =~ "font-variant-numeric: tabular-nums;"
    assert record_id =~ "line-height: var(--tl-line-mono);"

    assert metadata =~ "font-size: var(--tl-font-size-sm);"
    assert metadata =~ "font-weight: var(--tl-weight-regular);"
    assert metadata =~ "line-height: var(--tl-line-metadata);"
  end

  defp selector_block!(source, selector) do
    pattern = Regex.compile!("(?m)^\\s*" <> Regex.escape(selector) <> "\\s*\\{([^}]*)\\}", "s")

    case Regex.run(pattern, source) do
      [_, block] -> block
      nil -> flunk("missing CSS selector #{selector}")
    end
  end
end
