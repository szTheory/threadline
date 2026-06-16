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

  @doc false
  attr :class, :any, default: nil
  attr :variant, :string, default: nil, values: [nil, "error", "never", "unsupported"]
  attr :rest, :global
  slot :title
  slot :actions
  slot :inner_block, required: true

  def empty_state(assigns) do
    ~H"""
    <div class={["tl-empty", @variant && "tl-empty--#{@variant}", @class]} {@rest}>
      <h3 :if={@title != []} class="tl-empty__title"><%= render_slot(@title) %></h3>
      <div class="tl-empty__body">
        <%= render_slot(@inner_block) %>
      </div>
      <div :if={@actions != []} class="tl-empty__actions"><%= render_slot(@actions) %></div>
    </div>
    """
  end

  @doc false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :title
  slot :actions
  slot :inner_block, required: true

  def error_state(assigns) do
    ~H"""
    <.empty_state variant="error" class={@class} {@rest}>
      <:title :if={@title != []}><%= render_slot(@title) %></:title>
      <%= render_slot(@inner_block) %>
      <:actions :if={@actions != []}><%= render_slot(@actions) %></:actions>
    </.empty_state>
    """
  end

  @doc false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def code_block(assigns) do
    ~H"""
    <pre class={["tl-code", @class]} {@rest}><code><%= render_slot(@inner_block) %></code></pre>
    """
    end

    @doc false
    attr :id, :string, required: true
    attr :show, :boolean, default: false
    attr :on_cancel, JS, default: %JS{}
    attr :class, :any, default: nil
    attr :rest, :global
    slot :inner_block, required: true

    def modal(assigns) do
    ~H"""
    <div
    id={@id}
    phx-mounted={@show && show_modal(@id)}
    phx-remove={hide_modal(@id)}
    class={["tl-modal-container", if(!@show, do: "hidden")]}
    {@rest}
    >
    <div id={"#{@id}-bg"} class="tl-modal-scrim" aria-hidden="true" />
    <div
      class="tl-modal-wrapper"
      aria-labelledby={"#{@id}-title"}
      aria-describedby={"#{@id}-description"}
      role="dialog"
      aria-modal="true"
      tabindex="0"
    >
      <div
        id={"#{@id}-content"}
        class={["tl-modal", @class]}
        phx-click-away={JS.exec(@on_cancel, "phx-remove") |> hide_modal(@id)}
        phx-window-keydown={JS.exec(@on_cancel, "phx-remove") |> hide_modal(@id)}
        phx-key="escape"
      >
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    </div>
    """
    end

    @doc false
    def show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(
    to: "##{id}",
    transition: {"tl-fade-in", "opacity-0", "opacity-100"}
    )
    |> JS.show(
    to: "##{id}-content",
    transition: {"tl-rise-in", "opacity-0 translate-y-4", "opacity-100 translate-y-0"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
    end

    @doc false
    def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
    to: "##{id}-content",
    transition: {"tl-rise-out", "opacity-100 translate-y-0", "opacity-0 translate-y-4"}
    )
    |> JS.hide(
    to: "##{id}",
    transition: {"tl-fade-out", "opacity-100", "opacity-0"}
    )
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
    end

    @doc false
    attr :id, :string, required: true
    attr :show, :boolean, default: false
    attr :on_cancel, JS, default: %JS{}
    attr :class, :any, default: nil
    attr :rest, :global
    slot :inner_block, required: true

    def drawer(assigns) do
    ~H"""
    <div
    id={@id}
    phx-mounted={@show && show_drawer(@id)}
    phx-remove={hide_drawer(@id)}
    class={["tl-drawer-container", if(!@show, do: "hidden")]}
    {@rest}
    >
    <div id={"#{@id}-bg"} class="tl-drawer-scrim" aria-hidden="true" />
    <div
      class="tl-drawer-wrapper"
      role="dialog"
      aria-modal="true"
      tabindex="0"
    >
      <div
        id={"#{@id}-content"}
        class={["tl-drawer", @class]}
        phx-click-away={JS.exec(@on_cancel, "phx-remove") |> hide_drawer(@id)}
        phx-window-keydown={JS.exec(@on_cancel, "phx-remove") |> hide_drawer(@id)}
        phx-key="escape"
      >
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    </div>
    """
    end

    @doc false
    def show_drawer(js \\ %JS{}, id) do
    js
    |> JS.show(
    to: "##{id}",
    transition: {"tl-fade-in", "opacity-0", "opacity-100"}
    )
    |> JS.show(
    to: "##{id}-content",
    transition: {"tl-slide-in-right", "translate-x-full", "translate-x-0"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
    end

    @doc false
    def hide_drawer(js \\ %JS{}, id) do
    js
    |> JS.hide(
    to: "##{id}-content",
    transition: {"tl-slide-out-right", "translate-x-0", "translate-x-full"}
    )
    |> JS.hide(
    to: "##{id}",
    transition: {"tl-fade-out", "opacity-100", "opacity-0"}
    )
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
    end

    @doc false
    attr :id, :string, required: true
    attr :kind, :string, default: "info", values: ~w(info success warning error)
    attr :title, :string, default: nil
    attr :class, :any, default: nil
    attr :rest, :global
    slot :inner_block, required: true

    def toast(assigns) do
    ~H"""
    <div
    id={@id}
    class={["tl-toast", "tl-toast--#{@kind}", @class]}
    role="alert"
    phx-click-away={hide_toast(@id)}
    phx-window-keydown={hide_toast(@id)}
    phx-key="escape"
    {@rest}
    >
    <div :if={@title} class="tl-toast__title"><%= @title %></div>
    <div class="tl-toast__body">
      <%= render_slot(@inner_block) %>
    </div>
    <button type="button" class="tl-toast__close" aria-label="Close" phx-click={hide_toast(@id)}>
      <span aria-hidden="true">&times;</span>
    </button>
    </div>
    """
    end

    @doc false
    def hide_toast(js \\ %JS{}, id) do
    js
    |> JS.hide(
    to: "##{id}",
    transition: {"tl-fade-out", "opacity-100", "opacity-0"}
    )
    end

  @doc false
  attr :id, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :trigger, required: true
  slot :inner_block, required: true

  def tooltip(assigns) do
    ~H"""
    <div class={["tl-tooltip-wrapper", @class]} {@rest}>
      <div class="tl-tooltip-trigger" aria-describedby={@id}>
        <%= render_slot(@trigger) %>
      </div>
      <div id={@id} role="tooltip" class="tl-tooltip">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc false
  attr :id, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :trigger, required: true
  slot :inner_block, required: true

  def popover(assigns) do
    ~H"""
    <div class={["relative", @class]} {@rest}>
      <button
        type="button"
        id={"#{@id}-trigger"}
        aria-expanded="false"
        aria-controls={@id}
        phx-click={JS.toggle(to: "##{@id}") |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{@id}-trigger")}
        phx-click-away={JS.hide(to: "##{@id}") |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}-trigger")}
      >
        <%= render_slot(@trigger) %>
      </button>
      <div id={@id} class="hidden absolute tl-popover" role="dialog" aria-labelledby={"#{@id}-trigger"}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc false
  attr :id, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :trigger, required: true
  slot :inner_block, required: true

  def dropdown(assigns) do
    ~H"""
    <div class={["relative", @class]} {@rest}>
      <button
        type="button"
        id={"#{@id}-button"}
        aria-expanded="false"
        aria-haspopup="true"
        phx-click={JS.toggle(to: "##{@id}-menu") |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{@id}-button")}
        phx-click-away={JS.hide(to: "##{@id}-menu") |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}-button")}
      >
        <%= render_slot(@trigger) %>
      </button>
      <div id={"#{@id}-menu"} class="hidden absolute tl-shadow-popover" role="menu" aria-labelledby={"#{@id}-button"}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :tab, required: true do
    attr :active, :boolean
  end

  def tabs(assigns) do
    ~H"""
    <div class={["tl-tabs", @class]} role="tablist" {@rest}>
      <button :for={tab <- @tab} type="button" role="tab" aria-selected={if tab[:active], do: "true", else: "false"} class={["tl-tab", tab[:active] && "tl-tab--active"]}>
        <%= render_slot(tab) %>
      </button>
    </div>
    """
  end

  @doc false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :segment, required: true do
    attr :active, :boolean
  end

  def segmented_control(assigns) do
    ~H"""
    <div class={["tl-segmented-control", @class]} role="group" {@rest}>
      <button :for={seg <- @segment} type="button" aria-pressed={if seg[:active], do: "true", else: "false"} class={["tl-segment", seg[:active] && "tl-segment--active"]}>
        <%= render_slot(seg) %>
      </button>
    </div>
    """
  end

  @doc false
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def accordion(assigns) do
    ~H"""
    <div class={["tl-accordion", @class]} {@rest}>
      <h3 class="tl-accordion__header">
        <button
          type="button"
          id={"#{@id}-button"}
          aria-expanded="false"
          aria-controls={"#{@id}-content"}
          class="tl-accordion__trigger"
          phx-click={JS.toggle(to: "##{@id}-content") |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{@id}-button")}
        >
          <%= @title %>
          <span class="tl-accordion__icon" aria-hidden="true"></span>
        </button>
      </h3>
      <div id={"#{@id}-content"} class="hidden tl-accordion__panel" aria-labelledby={"#{@id}-button"}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end


