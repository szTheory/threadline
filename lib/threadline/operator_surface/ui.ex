defmodule Threadline.OperatorSurface.UI do
  @moduledoc false
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]

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

  @doc false
  attr :variant, :string, default: "neutral", values: ~w(info warning danger success accent muted neutral)
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={["tl-chip", "tl-chip--#{@variant}", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  @doc false
  attr :variant, :string, default: "info", values: ~w(info warning success error)
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def alert(assigns) do
    ~H"""
    <div class={["tl-alert", "tl-alert--#{@variant}", @class]} role="alert" {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc false
  attr :class, :any, default: nil
  attr :rest, :global

  def divider(assigns) do
    ~H"""
    <hr class={["tl-divider", @class]} {@rest} />
    """
  end

  @doc false
  attr :class, :any, default: nil
  attr :rest, :global

  def spinner(assigns) do
    ~H"""
    <svg class={["tl-spinner", @class]} viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" {@rest}>
      <circle cx="12" cy="12" r="10" stroke-opacity="0.25" />
      <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" />
    </svg>
    """
  end

  @doc false
  attr :src, :string, required: true
  attr :alt, :string, default: ""
  attr :class, :any, default: nil
  attr :rest, :global

  def avatar(assigns) do
    ~H"""
    <img src={@src} alt={@alt} class={["tl-avatar", @class]} {@rest} />
    """
  end

  @doc false
  attr :class, :any, default: nil
  attr :variant, :string, default: nil, values: [nil, "danger", "warning", "success", "info", "signal"]
  attr :rest, :global
  slot :title
  slot :meta
  slot :actions
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={["tl-card", @variant && "tl-card--#{@variant}", @class]} {@rest}>
      <div :if={@title != [] || @meta != []} class="tl-card__header">
        <h3 :if={@title != []} class="tl-card__title"><%= render_slot(@title) %></h3>
        <div :if={@meta != []} class="tl-card__meta"><%= render_slot(@meta) %></div>
      </div>
      <div class="tl-card__body">
        <%= render_slot(@inner_block) %>
      </div>
      <div :if={@actions != []} class="tl-card__actions"><%= render_slot(@actions) %></div>
    </div>
    """
  end

  @doc false
  attr :class, :any, default: nil
  attr :status, :string, default: nil, values: [nil, "danger", "warning", "success", "info", "signal"]
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :rest, :global

  def stat_tile(assigns) do
    ~H"""
    <div class={["tl-card--metric", @class]} data-status={@status} {@rest}>
      <div class="tl-card__metric-label"><%= @label %></div>
      <div class="tl-card__metric"><%= @value %></div>
    </div>
    """
  end
end
