if Code.ensure_loaded?(Phoenix.Component) do
  defmodule Threadline.OperatorSurface.UI.Form do
    @moduledoc false
    use Phoenix.Component
    alias Phoenix.LiveView.JS

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
        ~w(autocomplete disabled form readonly required placeholder phx-debounce step min max checked list maxlength)
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
        tabindex="-1"
        phx-mounted={JS.focus(to: "##{@id}")}
        class={["tl-error", "tl-error-summary", @class]}
        {@rest}
      >
        <h2 id={"#{@id}-title"} class="tl-error-summary__title">
          <%= if @title != [], do: render_slot(@title), else: "There is a problem" %>
        </h2>
        <ul class="tl-error-summary__list">
          <li :for={{field_id, message} <- @errors}>
            <a href={"##{field_id}"}><%= message %></a>
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
          aria-haspopup="listbox"
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
end
