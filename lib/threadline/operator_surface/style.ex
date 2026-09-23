if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Style do
    @moduledoc false

    # The operator stylesheet lives in ordered `.css` segments next to this
    # module and is read at compile time. The list order is the cascade order,
    # so it is spelled out rather than globbed. Every segment is an external
    # resource, so editing a `.css` file recompiles this module.

    import Phoenix.Component

    alias Threadline.OperatorSurface.Fonts

    @style_dir Path.join(__DIR__, "style")
    @segments ~w(
      stylesheet.css
      02_base_shell.css
      03_page_home.css
      04_controls.css
      05_feedback.css
      06_layout_primitives.css
      07_find_detail.css
      08_overlays_motion.css
      09_responsive.css
    )

    for segment <- @segments do
      @external_resource Path.join(@style_dir, segment)
    end

    @stylesheet "<style>" <>
                  Enum.map_join(@segments, &File.read!(Path.join(@style_dir, &1))) <>
                  "</style>"

    @doc false
    def segments, do: @segments

    def css(assigns) do
      assigns =
        assigns
        |> assign(:fonts_html, Phoenix.HTML.raw(font_face_style()))
        |> assign(:stylesheet, Phoenix.HTML.raw(@stylesheet))

      ~H"""
      {@fonts_html}{@stylesheet}
      """
    end

    defp font_face_style do
      case Fonts.face_css() do
        "" -> ""
        css -> "<style>" <> css <> "</style>"
      end
    end
  end
end
