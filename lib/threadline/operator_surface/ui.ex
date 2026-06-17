defmodule Threadline.OperatorSurface.UI do
  @moduledoc false
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]
  alias Phoenix.LiveView.JS

  @doc false
  attr(:type, :string, default: "button")
  attr(:class, :any, default: nil)

  attr(:variant, :string,
    default: "secondary",
    values: ~w(primary secondary quiet-primary danger ghost icon)
  )

  attr(:compact, :boolean, default: false)
  attr(:rest, :global, include: ~w(disabled form name value phx-disable-with))
  slot(:inner_block, required: true)

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
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(disabled form name value phx-disable-with))
  slot(:inner_block, required: true)

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
  attr(:navigate, :string, default: nil)
  attr(:patch, :string, default: nil)
  attr(:href, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:variant, :string, default: "deep", values: ~w(back deep))
  attr(:rest, :global)
  slot(:inner_block, required: true)

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
  attr(:variant, :string,
    default: "neutral",
    values: ~w(info warning danger success accent muted neutral)
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def badge(assigns) do
    ~H"""
    <span class={["tl-chip", "tl-chip--#{@variant}", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  @doc false
  attr(:variant, :string, default: "info", values: ~w(info warning success error))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def alert(assigns) do
    ~H"""
    <div class={["tl-alert", "tl-alert--#{@variant}", @class]} role="alert" {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc false
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def divider(assigns) do
    ~H"""
    <hr class={["tl-divider", @class]} {@rest} />
    """
  end

  @doc false
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def spinner(assigns) do
    ~H"""
    <svg class={["tl-spinner", @class]} viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" {@rest}>
      <circle cx="12" cy="12" r="10" stroke-opacity="0.25" />
      <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" />
    </svg>
    """
  end

  @doc false
  attr(:src, :string, required: true)
  attr(:alt, :string, default: "")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def avatar(assigns) do
    ~H"""
    <img src={@src} alt={@alt} class={["tl-avatar", @class]} {@rest} />
    """
  end

  @doc false
  attr(:class, :any, default: nil)

  attr(:variant, :string,
    default: nil,
    values: [nil, "danger", "warning", "success", "info", "signal"]
  )

  attr(:rest, :global)
  slot(:title)
  slot(:meta)
  slot(:actions)
  slot(:inner_block, required: true)

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
  attr(:title, :string, default: nil)
  attr(:id, :string, default: nil)
  attr(:variant, :string, default: "heading", values: ~w(heading display))

  attr(:breadcrumbs, :list,
    default: [],
    doc: "Ordered location trail; each item is a map %{label: ..., href: nil | binary}"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:lede)
  slot(:actions)
  slot(:inner_block)

  def page_header(assigns) do
    ~H"""
    <header class={["tl-page__header"] ++ if(@variant == "display", do: ["tl-home__hero"], else: []) ++ List.wrap(@class)} {@rest}>
      <.breadcrumb_trail :if={@breadcrumbs != []} crumbs={@breadcrumbs} />
      <div>
        <h1 id={@id} class={if @variant == "display", do: "tl-home__headline", else: "tl-page__title"}>
          <%= @title %>
        </h1>
        <p :if={@lede != []} class={if @variant == "display", do: "tl-home__lede", else: "tl-page__lede"}>
          <%= render_slot(@lede) %>
        </p>
        <%= render_slot(@inner_block) %>
      </div>
      <div :if={@actions != []} class="tl-page__actions"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc false
  attr(:crumbs, :list, required: true)

  defp breadcrumb_trail(assigns) do
    ~H"""
    <nav aria-label="Breadcrumb" class="tl-transaction__breadcrumbs">
      <%= for crumb <- @crumbs do %>
        <%= if crumb[:href] do %>
          <a href={crumb[:href]} class="tl-link tl-link--back"><%= crumb[:label] %></a>
        <% else %>
          <span><%= crumb[:label] %></span>
        <% end %>
      <% end %>
    </nav>
    """
  end

  @doc false
  attr(:class, :any, default: nil)

  attr(:status, :string,
    default: nil,
    values: [nil, "danger", "warning", "success", "info", "signal"]
  )

  attr(:label, :string, required: true)
  attr(:value, :string, required: true)
  attr(:rest, :global)

  def stat_tile(assigns) do
    ~H"""
    <div class={["tl-card--metric", @class]} data-status={@status} {@rest}>
      <div class="tl-card__metric-label"><%= @label %></div>
      <div class="tl-card__metric"><%= @value %></div>
    </div>
    """
  end

  @doc false
  attr(:class, :any, default: nil)
  attr(:variant, :string, default: nil, values: [nil, "error", "never", "unsupported"])
  attr(:rest, :global)
  slot(:title)
  slot(:actions)
  slot(:inner_block, required: true)

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
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:title)
  slot(:actions)
  slot(:inner_block, required: true)

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
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def code_block(assigns) do
    ~H"""
    <pre class={["tl-code", @class]} {@rest}><code><%= render_slot(@inner_block) %></code></pre>
    """
  end

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
  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, JS, default: %JS{})
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

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
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :tab, required: true do
    attr(:active, :boolean)
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
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :segment, required: true do
    attr(:active, :boolean)
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

  @doc false
  attr(:for, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def label(assigns) do
    ~H"""
    <label for={@for} class={["tl-label", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def error(assigns) do
    ~H"""
    <p id={@id} class={["tl-error", @class]} {@rest}>
      <svg class="tl-error-icon" aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="12" cy="12" r="10" />
        <line x1="12" y1="8" x2="12" y2="12" />
        <line x1="12" y1="16" x2="12.01" y2="16" />
      </svg>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def help(assigns) do
    ~H"""
    <p id={@id} class={["tl-help", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:type, :string, default: "text")
  attr(:class, :any, default: nil)
  attr(:options, :list, default: [])
  attr(:checked, :boolean, default: false)
  attr(:rest, :global)

  def input(%{type: "checkbox"} = assigns) do
    assigns = assign(assigns, :checked, assigns.value == true || assigns.value == "true")

    ~H"""
    <input
      type="checkbox"
      id={@id}
      name={@name}
      value="true"
      checked={@checked}
      class={["tl-checkbox", @class]}
      {@rest}
    />
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <select id={@id} name={@name} class={["tl-control", "tl-control--select", @class]} {@rest}>
      <option :for={{label, value} <- @options} value={value} selected={to_string(value) == to_string(@value)}><%= label %></option>
    </select>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <textarea id={@id} name={@name} class={["tl-control", "tl-control--textarea", @class]} {@rest}><%= @value %></textarea>
    """
  end

  def input(assigns) do
    ~H"""
    <input
      type={@type}
      id={@id}
      name={@name}
      value={@value}
      class={["tl-control", @class]}
      {@rest}
    />
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:type, :string, default: "text")
  attr(:label, :string, required: true)
  attr(:errors, :list, default: [])
  attr(:help_text, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:options, :list, default: [])

  attr(:rest, :global,
    include:
      ~w(autocomplete disabled readonly required placeholder phx-debounce step min max checked list maxlength)
  )

  def field(assigns) do
    assigns =
      assigns
      |> assign(:error_id, "#{assigns.id}-error")
      |> assign(:help_id, "#{assigns.id}-help")

    ~H"""
    <div class={["tl-field", @errors != [] && "tl-field--error", @class]}>
      <.label for={@id}><%= @label %></.label>
      
      <% aria_describedby = [
        @help_text && @help_id,
        @errors != [] && @error_id
      ] |> Enum.reject(&is_nil/1) |> Enum.join(" ") %>
      
      <.input
        id={@id}
        name={@name}
        value={@value}
        type={@type}
        options={@options}
        aria-describedby={if aria_describedby != "", do: aria_describedby, else: nil}
        {@rest}
      />
      
      <.error :for={msg <- @errors} id={@error_id}><%= msg %></.error>
      <.help :if={@help_text} id={@help_id}><%= @help_text %></.help>
    </div>
    """
  end

  @doc false
  # errors is a list of {field_id, message} tuples. Each message links to the
  # offending field's error id ("#\#{field_id}-error"). Renders nothing when empty.
  attr(:id, :string, required: true)
  attr(:errors, :list, default: [])
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:title)

  def error_summary(assigns) do
    ~H"""
    <div
      :if={@errors != []}
      id={@id}
      role="alert"
      aria-labelledby={"#{@id}-title"}
      class={["tl-error", "tl-error-summary", @class]}
      {@rest}
    >
      <h2 id={"#{@id}-title"} class="tl-error-summary__title">
        <%= if @title != [], do: render_slot(@title), else: "There is a problem" %>
      </h2>
      <ul class="tl-error-summary__list">
        <li :for={{field_id, message} <- @errors}>
          <a href={"##{field_id}-error"}><%= message %></a>
        </li>
      </ul>
    </div>
    """
  end

  @doc false
  attr(:legend, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def field_group(assigns) do
    ~H"""
    <fieldset class={["tl-filter-group", @class]} {@rest}>
      <legend class="tl-filter-group__legend"><%= @legend %></legend>
      <%= render_slot(@inner_block) %>
    </fieldset>
    """
  end

  @doc false
  # Native radio group: every option shares @name; the option whose value equals
  # @value is checked; each input has a distinct id and an associated <label>.
  attr(:name, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:options, :list, default: [])
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def radio(assigns) do
    ~H"""
    <div class={["tl-radio-group", @class]} role="group" {@rest}>
      <div :for={{label, value} <- @options} class="tl-radio">
        <input
          type="radio"
          id={"#{@name}-#{value}"}
          name={@name}
          value={value}
          checked={to_string(value) == to_string(@value)}
          class="tl-radio__input"
        />
        <label for={"#{@name}-#{value}"} class="tl-radio__label"><%= label %></label>
      </div>
    </div>
    """
  end

  @doc false
  # Native checkbox styled as a switch. Submits without JS; role/aria-checked
  # carry switch semantics for assistive tech.
  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def switch(assigns) do
    assigns = assign(assigns, :checked, assigns.value == true || assigns.value == "true")

    ~H"""
    <input
      type="checkbox"
      role="switch"
      id={@id}
      name={@name}
      value="true"
      checked={@checked}
      aria-checked={if @checked, do: "true", else: "false"}
      class={["tl-checkbox", "tl-switch", @class]}
      {@rest}
    />
    """
  end

  @doc false
  # Combobox: a free-text input (role="combobox") paired with a hidden listbox.
  # Open/close is driven purely by Phoenix.LiveView.JS (ARIA state only, no data
  # fetch, no third-party JS runtime). With JS disabled the input still accepts
  # free text, so the control degrades gracefully and submits like any text field.
  attr(:id, :string, required: true)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:options, :list, default: [])
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def combobox(assigns) do
    ~H"""
    <div class={["tl-combobox", @class]} {@rest}>
      <input
        type="text"
        id={@id}
        name={@name}
        value={@value}
        role="combobox"
        aria-expanded="false"
        aria-controls={"#{@id}-listbox"}
        aria-autocomplete="list"
        autocomplete="off"
        class="tl-control"
        phx-click={
          JS.toggle(to: "##{@id}-listbox")
          |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{@id}")
        }
        phx-click-away={
          JS.hide(to: "##{@id}-listbox")
          |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
        }
      />
      <ul id={"#{@id}-listbox"} class="hidden tl-combobox__listbox" role="listbox" aria-label={@name}>
        <li :for={{label, value} <- @options} role="option" data-value={value} class="tl-combobox__option">
          <%= label %>
        </li>
      </ul>
    </div>
    """
  end
end
