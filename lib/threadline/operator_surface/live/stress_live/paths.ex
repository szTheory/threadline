if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.StressLive.Paths do
    @moduledoc false

    def base_path(uri) do
      uri
      |> URI.parse()
      |> Map.get(:path)
      |> case do
        path when is_binary(path) -> String.replace_suffix(path, "/__stress", "")
        _ -> "/audit"
      end
    end

    def stress_path(uri) do
      uri
      |> URI.parse()
      |> Map.get(:path)
      |> case do
        path when is_binary(path) -> path
        _ -> "/audit/__stress"
      end
    end

    def clear_path(stress_path), do: stress_path

    def filter_path(stress_path, category, status) do
      query =
        %{}
        |> maybe_put("category", category)
        |> maybe_put("status", status)
        |> URI.encode_query()

      if query == "", do: clear_path(stress_path), else: "#{stress_path}?#{query}"
    end

    def story_path(stress_path, story, category, status, theme, viewport) do
      query =
        %{"story" => story.id}
        |> maybe_put("category", category)
        |> maybe_put("status", status)
        |> maybe_put("theme", theme)
        |> maybe_put("viewport", viewport)
        |> URI.encode_query()

      "#{stress_path}?#{query}"
    end

    defp maybe_put(map, _key, nil), do: map
    defp maybe_put(map, key, value), do: Map.put(map, key, value)
  end
end
