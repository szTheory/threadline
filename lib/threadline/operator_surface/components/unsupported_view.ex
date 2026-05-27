if Code.ensure_loaded?(Phoenix.Component) do
  defmodule Threadline.OperatorSurface.Components.UnsupportedView do
    @moduledoc false

    use Phoenix.Component

    attr(:descriptor, :map, default: nil)
    attr(:title, :string, default: "Unsupported View")

    attr(
      :body,
      :string,
      default: "This support-lane view is not available for the current transport or access tier."
    )

    attr(:fallback_label, :string, default: nil)
    attr(:fallback_value, :string, default: nil)
    attr(:base_path, :string, default: nil)

    def unsupported_view(assigns) do
      descriptor = assigns[:descriptor] || %{}

      assigns =
        assigns
        |> assign(:title, Map.get(descriptor, :title, assigns[:title]))
        |> assign(:body, Map.get(descriptor, :body, assigns[:body]))
        |> assign(:fallback_label, Map.get(descriptor, :fallback_label, assigns[:fallback_label]))
        |> assign(:fallback_value, Map.get(descriptor, :fallback_value, assigns[:fallback_value]))

      ~H"""
      <div class="empty-state unsupported-state" role="status">
        <h3><%= @title %></h3>
        <p><%= @body %></p>
        <p :if={@fallback_value} class="filter-hint">
          <strong><%= @fallback_label || "Try instead" %>:</strong>
          <code><%= @fallback_value %></code>
        </p>
        <.link :if={@base_path} href={@base_path} class="secondary-button">Back to Timeline</.link>
      </div>
      """
    end
  end
end
