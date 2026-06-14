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
    defp paths(:copy), do: ["M9 9h11v11H9z", "M4 4h11v11"]
    defp paths(:download), do: ["M12 3v12", "M7 10l5 5 5-5", "M5 21h14"]
    defp paths(:evidence), do: ["M7 3h7l3 3v15H7z", "M14 3v4h4", "M9 12h6", "M9 16h4"]
    defp paths(:filter_x), do: ["M4 5h16l-6 7v5l-4 2v-7L4 5Z", "M16 16l4 4", "M20 16l-4 4"]
    defp paths(:history), do: ["M3 12a9 9 0 1 0 3-6.7", "M3 4v5h5", "M12 7v6l4 2"]

    defp paths(:refresh),
      do: ["M20 6v5h-5", "M4 18v-5h5", "M19 11a7 7 0 0 0-12-4", "M5 13a7 7 0 0 0 12 4"]

    defp paths(:search), do: ["M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15Z", "M16 16l5 5"]
    defp paths(:shield), do: ["M12 3 5 6v5c0 5 3.5 8.5 7 10 3.5-1.5 7-5 7-10V6l-7-3Z"]
    defp paths(:trash), do: ["M4 7h16", "M9 7V4h6v3", "M6 7l1 14h10l1-14", "M10 11v6", "M14 11v6"]
    defp paths(:warning), do: ["M12 3 2 21h20L12 3Z", "M12 9v5", "M12 18h.01"]
    defp paths(_), do: []
  end
end
