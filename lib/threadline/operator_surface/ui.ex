defmodule Threadline.OperatorSurface.UI do
  @moduledoc false
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]
  alias Phoenix.LiveView.JS

  @doc false
  attr :type, :string, default: "button"
  attr :class, :any, default: nil
  attr :variant, :string, default: "secondary", values: ~w(primary secondary quiet-primary danger ghost icon)
  attr :compact, :boolean, default: false
  attr :rest, :global, include: ~w(disabled form name value phx-disable-with)
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "tl-button",
        @variant != "secondary" && "tl-button--#{@variant}",
        @compact && "tl-button--compact",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value phx-disable-with)
  slot :inner_block, required: true

  def icon_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "tl-button",
        "tl-button--icon",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc false
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :string, default: nil
  attr :class, :any, default: nil
  attr :variant, :string, default: "deep", values: ~w(back deep)
  attr :rest, :global
  slot :inner_block, required: true

  def link(assigns) do
    ~H"""
    <Phoenix.Component.link
      navigate={@navigate}
      patch={@patch}
      href={@href}
      class={[
        "tl-link",
        @variant && "tl-link--#{@variant}",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end
end
