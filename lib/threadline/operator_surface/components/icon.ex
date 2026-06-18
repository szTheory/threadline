if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Components.Icon do
    @moduledoc false

    use Phoenix.Component

    attr(:name, :atom, required: true)
    attr(:class, :any, default: nil)
    attr(:rest, :global)

    def icon(assigns) do
      assigns = assign(assigns, :paths, paths(assigns.name))

      ~H"""
      <svg
        class={["tl-icon", @class]}
        viewBox="0 0 24 24"
        aria-hidden="true"
        focusable="false"
        {@rest}
      >
        <path :for={path <- @paths} d={path} />
      </svg>
      """
    end

    defp paths(:archive), do: ["M3 7h18", "M5 7v12h14V7", "M9 11h6", "M7 3h10l2 4H5l2-4Z"]
    defp paths(:arrow_left), do: ["M19 12H5", "M12 19l-7-7 7-7"]
    defp paths(:arrow_right), do: ["M5 12h14", "M12 5l7 7-7 7"]
    defp paths(:check), do: ["M20 6 9 17l-5-5"]

    defp paths(:cloud_off),
      do: ["M7 17h9a4 4 0 0 0 1.6-7.7A6 6 0 0 0 6.5 7.5", "M3 3l18 18"]

    defp paths(:copy), do: ["M9 9h11v11H9z", "M4 4h11v11"]
    defp paths(:download), do: ["M12 3v12", "M7 10l5 5 5-5", "M5 21h14"]
    defp paths(:evidence), do: ["M7 3h7l3 3v15H7z", "M14 3v4h4", "M9 12h6", "M9 16h4"]

    defp paths(:eye_off),
      do: [
        "M3 3l18 18",
        "M10.6 10.6a2 2 0 0 0 2.8 2.8",
        "M9.9 5.1A9.6 9.6 0 0 1 12 5c5 0 9 4.5 9 7a12 12 0 0 1-2.2 3.1",
        "M6.1 6.6A12 12 0 0 0 3 12c0 2.5 4 7 9 7a9.5 9.5 0 0 0 3.4-.6"
      ]

    defp paths(:filter_x), do: ["M4 5h16l-6 7v5l-4 2v-7L4 5Z", "M16 16l4 4", "M20 16l-4 4"]
    defp paths(:funnel), do: ["M4 5h16l-6 7v6l-4 2v-8L4 5Z"]
    defp paths(:history), do: ["M3 12a9 9 0 1 0 3-6.7", "M3 4v5h5", "M12 7v6l4 2"]

    defp paths(:kebab),
      do: ["M12 5h.01", "M12 12h.01", "M12 19h.01"]

    defp paths(:lock),
      do: ["M6 11h12v9H6z", "M9 11V8a3 3 0 0 1 6 0v3", "M12 15v2"]

    defp paths(:refresh),
      do: ["M20 6v5h-5", "M4 18v-5h5", "M19 11a7 7 0 0 0-12-4", "M5 13a7 7 0 0 0 12 4"]

    defp paths(:search), do: ["M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15Z", "M16 16l5 5"]
    defp paths(:shield), do: ["M12 3 5 6v5c0 5 3.5 8.5 7 10 3.5-1.5 7-5 7-10V6l-7-3Z"]
    defp paths(:trash), do: ["M4 7h16", "M9 7V4h6v3", "M6 7l1 14h10l1-14", "M10 11v6", "M14 11v6"]
    defp paths(:warning), do: ["M12 3 2 21h20L12 3Z", "M12 9v5", "M12 18h.01"]
    defp paths(_), do: []
  end
end
