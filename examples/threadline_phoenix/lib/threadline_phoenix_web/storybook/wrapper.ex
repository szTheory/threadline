defmodule ThreadlinePhoenixWeb.Storybook.Wrapper do
  @moduledoc false

  use Phoenix.Component

  @doc false
  attr(:theme, :string, default: "dark", values: ~w(dark light system))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def threadline_preview(assigns) do
    ~H"""
    <div class="threadline-ui" data-tl-theme={@theme} data-threadline-storybook-preview="true">
      <Threadline.OperatorSurface.Style.css />
      <div class={["tl-storybook-preview", @class]} data-threadline-preview-container="true" {@rest}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc false
  attr(:title, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def preview_section(assigns) do
    ~H"""
    <section class={["tl-storybook-section", "tl-stack", @class]} data-threadline-preview-section="true" {@rest}>
      <div :if={@title || @description} class="tl-storybook-section__header">
        <h2 :if={@title} class="tl-page__title"><%= @title %></h2>
        <p :if={@description} class="tl-page__lede"><%= @description %></p>
      </div>
      <div class="tl-storybook-section__body">
        <%= render_slot(@inner_block) %>
      </div>
    </section>
    """
  end
end
