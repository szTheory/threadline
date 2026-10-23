if Code.ensure_loaded?(Phoenix.Component) do
  defmodule Threadline.OperatorSurface.UI.Overlay do
    @moduledoc false
    use Phoenix.Component
    alias Phoenix.LiveView.JS
    alias Threadline.OperatorSurface.Components.Icon

    @doc false
    attr(:id, :string, required: true)
    attr(:show, :boolean, default: false)
    attr(:on_cancel, JS, default: %JS{})
    attr(:class, :any, default: nil)
    attr(:rest, :global)
    slot(:inner_block, required: true)

    def modal(assigns) do
      ~H"""
      <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={JS.exec("data-tl-hide", to: "##{@id}.tl-overlay-visible")}
      data-tl-hide={hide_modal(@id)}
      data-tl-cancel={hide_modal(@on_cancel, @id)}
      class={["tl-modal-container", if(!@show, do: "hidden")]}
      {@rest}
      >
      <div
        id={"#{@id}-bg"}
        class="tl-modal-scrim"
        aria-hidden="true"
        phx-click={JS.exec("data-tl-cancel", to: "##{@id}.tl-overlay-visible")}
      />
      <.focus_wrap
        id={"#{@id}-focus"}
        class="tl-modal-wrapper"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
      >
        <div
          id={"#{@id}-content"}
          class={["tl-modal", @class]}
          tabindex="-1"
          phx-focus={JS.focus_first(to: "##{@id}-content")}
          phx-window-keydown={JS.exec("data-tl-cancel", to: "##{@id}.tl-overlay-visible:focus-within:not(:has([role=menu]:focus-within))")}
          phx-key="escape"
        >
          <%= render_slot(@inner_block) %>
        </div>
      </.focus_wrap>
      </div>
      """
    end

    @doc false
    def show_modal(js \\ %JS{}, id) do
      js
      |> JS.add_class("tl-overlay-visible", to: "##{id}")
      |> JS.add_class("tl-overlay-visible", to: "##{id}-content")
      |> JS.show(
        to: "##{id}",
        time: 180,
        transition: {"tl-fade-in", "opacity-0", "opacity-100"}
      )
      |> JS.show(
        to: "##{id}-content",
        time: 180,
        transition: {"tl-rise-in", "opacity-0 translate-y-4", "opacity-100 translate-y-0"}
      )
      |> JS.add_class("overflow-hidden", to: "body")
      |> JS.focus(to: "##{id}-content")
      |> JS.focus_first(to: "##{id}-content")
      |> JS.focus(to: "##{id} [data-tl-initial-focus]")
    end

    @doc false
    def hide_modal(js \\ %JS{}, id) do
      js
      |> JS.hide(
        to: "##{id}-content",
        time: 180,
        transition: {"tl-rise-out", "opacity-100 translate-y-0", "opacity-0 translate-y-4"}
      )
      |> JS.hide(
        to: "##{id}",
        time: 180,
        transition: {"tl-fade-out", "opacity-100", "opacity-0"}
      )
      |> JS.remove_class("overflow-hidden", to: "body")
      |> JS.remove_class("tl-overlay-visible", to: "##{id}")
      |> JS.remove_class("tl-overlay-visible", to: "##{id}-content")
      |> JS.focus(to: "#tl-main")
      |> JS.pop_focus()
    end

    @doc false
    attr(:id, :string, required: true)
    attr(:show, :boolean, default: false)
    attr(:on_cancel, JS, default: %JS{})
    attr(:motion, :atom, values: [:standard, :immediate], default: :standard)
    attr(:class, :any, default: nil)
    attr(:rest, :global)
    slot(:inner_block, required: true)

    def drawer(assigns) do
      ~H"""
      <div
      id={@id}
      phx-mounted={@show && show_drawer_for_motion(@id, @motion)}
      phx-remove={JS.exec("data-tl-hide", to: "##{@id}.tl-overlay-visible")}
      data-tl-hide={hide_drawer_for_motion(@id, @motion)}
      data-tl-cancel={cancel_drawer_for_motion(@on_cancel, @id, @motion)}
      class={["tl-drawer-container", if(!@show, do: "hidden")]}
      {@rest}
      >
      <div
        id={"#{@id}-bg"}
        class="tl-drawer-scrim"
        aria-hidden="true"
        phx-click={JS.exec("data-tl-cancel", to: "##{@id}.tl-overlay-visible")}
      />
      <.focus_wrap
        id={"#{@id}-focus"}
        class="tl-drawer-wrapper"
        role="dialog"
        aria-modal="true"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
      >
        <div
          id={"#{@id}-content"}
          class={["tl-drawer", @class]}
          tabindex="-1"
          phx-focus={JS.focus_first(to: "##{@id}-content")}
          phx-window-keydown={JS.exec("data-tl-cancel", to: "##{@id}.tl-overlay-visible:focus-within:not(:has([role=menu]:focus-within))")}
          phx-key="escape"
        >
          <%= render_slot(@inner_block) %>
        </div>
      </.focus_wrap>
      </div>
      """
    end

    @doc false
    def show_drawer(js \\ %JS{}, id) do
      js
      |> JS.add_class("tl-overlay-visible", to: "##{id}")
      |> JS.add_class("tl-overlay-visible", to: "##{id}-content")
      |> JS.show(
        to: "##{id}",
        time: 180,
        transition: {"tl-fade-in", "opacity-0", "opacity-100"}
      )
      |> JS.show(
        to: "##{id}-content",
        time: 180,
        transition: {"tl-slide-in-right", "translate-x-full", "translate-x-0"}
      )
      |> JS.add_class("overflow-hidden", to: "body")
      |> JS.focus(to: "##{id}-content")
      |> JS.focus_first(to: "##{id}-content")
      |> JS.focus(to: "##{id} [data-tl-initial-focus]")
    end

    defp show_drawer_for_motion(id, :immediate), do: show_drawer_immediately(id)
    defp show_drawer_for_motion(id, _motion), do: show_drawer(id)

    defp show_drawer_immediately(js \\ %JS{}, id) do
      js
      |> JS.add_class("tl-overlay-visible", to: "##{id}")
      |> JS.add_class("tl-overlay-visible", to: "##{id}-content")
      |> JS.show(to: "##{id}")
      |> JS.show(to: "##{id}-content")
      |> JS.add_class("overflow-hidden", to: "body")
      |> JS.focus(to: "##{id}-content")
      |> JS.focus_first(to: "##{id}-content")
      |> JS.focus(to: "##{id} [data-tl-initial-focus]")
    end

    defp hide_drawer_for_motion(id, :immediate), do: hide_drawer_immediately(id)
    defp hide_drawer_for_motion(id, _motion), do: hide_drawer(id)

    defp cancel_drawer_for_motion(js, _id, :immediate), do: js
    defp cancel_drawer_for_motion(js, id, _motion), do: hide_drawer(js, id)

    defp hide_drawer_immediately(id) do
      %JS{}
      |> JS.hide(to: "##{id}-content")
      |> JS.hide(to: "##{id}")
      |> JS.remove_class("overflow-hidden", to: "body")
      |> JS.remove_class("tl-overlay-visible", to: "##{id}")
      |> JS.remove_class("tl-overlay-visible", to: "##{id}-content")
      |> JS.focus(to: "#tl-main")
      |> JS.pop_focus()
    end

    @doc false
    def hide_drawer(js \\ %JS{}, id) do
      js
      |> JS.hide(
        to: "##{id}-content",
        time: 180,
        transition: {"tl-slide-out-right", "translate-x-0", "translate-x-full"}
      )
      |> JS.hide(
        to: "##{id}",
        time: 180,
        transition: {"tl-fade-out", "opacity-100", "opacity-0"}
      )
      |> JS.remove_class("overflow-hidden", to: "body")
      |> JS.remove_class("tl-overlay-visible", to: "##{id}")
      |> JS.remove_class("tl-overlay-visible", to: "##{id}-content")
      |> JS.focus(to: "#tl-main")
      |> JS.pop_focus()
    end

    @doc false
    attr(:id, :string, required: true)
    attr(:kind, :string, default: "info", values: ~w(info success warning error))
    attr(:title, :string, default: nil)
    attr(:class, :any, default: nil)
    attr(:rest, :global)
    slot(:inner_block, required: true)

    def toast(assigns) do
      ~H"""
      <div
      id={@id}
      class={["tl-toast", "tl-toast--#{@kind}", @class]}
      role="alert"
      phx-mounted={show_toast(@id)}
      data-tl-dismiss={hide_toast(@id)}
      phx-window-keydown={JS.exec("data-tl-dismiss", to: "##{@id}.tl-overlay-visible:focus-within")}
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
    # Toast fade-up entrance (Open Question 3): the same rise utility classes the
    # modal uses, token-synced via explicit time:. Manual/phx-click dismiss only —
    # no auto-dismiss (out of scope).
    def show_toast(js \\ %JS{}, id) do
      js
      |> JS.add_class("tl-overlay-visible", to: "##{id}")
      |> JS.show(
        to: "##{id}",
        time: 180,
        transition: {"tl-rise-in", "opacity-0 translate-y-4", "opacity-100 translate-y-0"}
      )
    end

    @doc false
    def hide_toast(js \\ %JS{}, id) do
      js
      |> JS.hide(
        to: "##{id}",
        time: 180,
        transition: {"tl-fade-out", "opacity-100", "opacity-0"}
      )
      |> JS.remove_class("tl-overlay-visible", to: "##{id}")
      |> JS.focus(
        to:
          ".tl-drawer.tl-overlay-visible [data-tl-initial-focus], .tl-modal.tl-overlay-visible [data-tl-initial-focus]"
      )
    end

    @doc false
    # Reconnect / offline banner verified against LiveView's real lifecycle classes. A
    # calm, transient `role="status"` strip rendered at the shell level. It is
    # hidden by default and revealed PURELY in CSS while the `[data-phx-main]`
    # container carries LiveView lifecycle classes; `.threadline-ui` is the scoped
    # descendant shell the selector enters. Zero new JS, zero new deps, CSP-clean —
    # it rides phoenix_live_view's own client-applied connection classes, so it
    # catches a dropped socket mid-session (unlike a mount-time `connected?/1`
    # assign).
    #
    # Mutating controls elsewhere in the shell carry `data-tl-mutating` so the paired
    # CSS disables them (pointer-events + dimming) while disconnected. Because
    # `pointer-events:none` is an affordance, not enforcement, so mutating
    # LINKS (which cannot take HTML `disabled`) must ALSO set `aria-disabled="true"`
    # and `tabindex="-1"` so keyboard/SR users are not stranded on a dead control,
    # e.g.:
    #
    #     <.button data-tl-mutating>Prune now</.button>
    #     <a href={~p"/..."} data-tl-mutating aria-disabled="true" tabindex="-1">Re-run</a>
    attr(:class, :any, default: nil)
    attr(:rest, :global)

    def reconnect_banner(assigns) do
      ~H"""
      <div class={["tl-reconnect-banner", @class]} role="status" {@rest}>
        <Icon.icon name={:refresh} class="tl-alert__icon" />
        <span class="tl-reconnect-banner__lost">Connection lost. Read-only information may be stale; actions are paused until current status is refreshed.</span>
        <span class="tl-reconnect-banner__reconnecting">Reconnecting. Actions will remain unavailable until current status is refreshed.</span>
      </div>
      """
    end

    @doc false
    attr(:id, :string, required: true)
    attr(:class, :any, default: nil)
    attr(:rest, :global)
    slot(:trigger, required: true)
    slot(:inner_block, required: true)

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
    attr(:id, :string, required: true)
    attr(:class, :any, default: nil)
    attr(:rest, :global)
    slot(:trigger, required: true)
    slot(:inner_block, required: true)

    def popover(assigns) do
      ~H"""
      <div class={["relative", @class]} {@rest}>
        <button
          type="button"
          id={"#{@id}-trigger"}
          aria-expanded="false"
          aria-controls={@id}
          aria-haspopup="dialog"
          phx-click={
            JS.toggle(
              to: "##{@id}",
              in: {"tl-rise-in", "opacity-0 translate-y-4", "opacity-100 translate-y-0"},
              out: {"tl-rise-out", "opacity-100 translate-y-0", "opacity-0 translate-y-4"},
              time: 180
            )
            |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{@id}-trigger")
          }
          phx-click-away={
            JS.hide(
              to: "##{@id}",
              transition: {"tl-rise-out", "opacity-100 translate-y-0", "opacity-0 translate-y-4"},
              time: 180
            )
            |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}-trigger")
          }
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
    attr(:id, :string, required: true)
    attr(:class, :any, default: nil)
    attr(:rest, :global)
    slot(:trigger, required: true)
    slot(:inner_block, required: true)

    def dropdown(assigns) do
      ~H"""
      <div class={["relative", @class]} {@rest}>
        <button
          type="button"
          id={"#{@id}-button"}
          aria-expanded="false"
          aria-haspopup="menu"
          phx-click={
            JS.toggle(
              to: "##{@id}-menu",
              in: {"tl-rise-in", "opacity-0 translate-y-4", "opacity-100 translate-y-0"},
              out: {"tl-rise-out", "opacity-100 translate-y-0", "opacity-0 translate-y-4"},
              time: 180
            )
            |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{@id}-button")
            |> JS.focus(to: "##{@id}-menu")
            |> JS.focus_first(to: "##{@id}-menu")
          }
          phx-click-away={
            JS.hide(
              to: "##{@id}-menu",
              transition: {"tl-rise-out", "opacity-100 translate-y-0", "opacity-0 translate-y-4"},
              time: 180
            )
            |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}-button")
          }
        >
          <%= render_slot(@trigger) %>
        </button>
        <div
          id={"#{@id}-menu"}
          class="hidden absolute tl-shadow-popover"
          role="menu"
          tabindex="-1"
          aria-labelledby={"#{@id}-button"}
          data-tl-close={JS.hide(to: "##{@id}-menu") |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}-button") |> JS.focus(to: "##{@id}-button")}
          phx-window-keydown={JS.exec("data-tl-close", to: "##{@id}-menu:focus-within")}
          phx-key="escape"
        >
          <%= render_slot(@inner_block) %>
        </div>
      </div>
      """
    end

    @doc false
    attr(:id, :string, required: true)
    attr(:title, :string, required: true)
    attr(:class, :any, default: nil)
    attr(:rest, :global)
    slot(:inner_block, required: true)

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
            phx-click={
              JS.toggle(
                to: "##{@id}-content",
                in: {"tl-fade-in", "opacity-0", "opacity-100"},
                out: {"tl-fade-out", "opacity-100", "opacity-0"},
                time: 180
              )
              |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{@id}-button")
            }
          >
            <%= @title %>
            <span class="tl-accordion__icon" aria-hidden="true"></span>
          </button>
        </h3>
        <div
          id={"#{@id}-content"}
          class="hidden tl-accordion__panel"
          role="region"
          aria-labelledby={"#{@id}-button"}
        >
          <%= render_slot(@inner_block) %>
        </div>
      </div>
      """
    end
  end
end
