if Code.ensure_loaded?(Phoenix.Component) do
  defmodule Threadline.OperatorSurface.Components.Logo do
    @moduledoc false

    use Phoenix.Component

    @dark_path Path.expand("../../../../brand/assets/logo/threadline-lockup-dark.svg", __DIR__)
    @light_path Path.expand("../../../../brand/assets/logo/threadline-lockup-light.svg", __DIR__)
    @external_resource @dark_path
    @external_resource @light_path

    @dark_svg @dark_path
              |> File.read!()
              |> String.replace(
                "<svg xmlns=",
                ~s|<svg class="tl-topbar__brand-logo tl-topbar__brand-logo--dark" xmlns=|,
                global: false
              )
              |> String.replace(
                ~s| role="img"><title>Threadline</title>|,
                ~s| aria-hidden="true" focusable="false">|,
                global: false
              )

    @light_svg @light_path
               |> File.read!()
               |> String.replace(
                 "<svg xmlns=",
                 ~s|<svg class="tl-topbar__brand-logo tl-topbar__brand-logo--light" xmlns=|,
                 global: false
               )
               |> String.replace(
                 ~s| role="img"><title>Threadline</title>|,
                 ~s| aria-hidden="true" focusable="false">|,
                 global: false
               )

    attr(:rest, :global)

    def compact(assigns) do
      assigns = assign(assigns, dark_svg: @dark_svg, light_svg: @light_svg)

      ~H"""
      <span class="tl-topbar__brand-lockups" {@rest}>
        {Phoenix.HTML.raw(@dark_svg)}
        {Phoenix.HTML.raw(@light_svg)}
      </span>
      """
    end
  end
end
