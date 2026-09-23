if Code.ensure_loaded?(Phoenix.Component) do
  defmodule Threadline.OperatorSurface.UI do
    @moduledoc false
    use Phoenix.Component
    alias Phoenix.LiveView.JS
    alias Threadline.OperatorSurface.Script
    alias Threadline.OperatorSurface.UI.Display
    alias Threadline.OperatorSurface.UI.Overlay

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

    slot(:heading,
      doc: "Rich heading content rendered inside the single <h1> (overrides title attr)"
    )

    slot(:lede)

    slot(:meta,
      doc: "Optional supporting meta line rendered under the lede (e.g. last-checked time)"
    )

    slot(:actions)
    slot(:inner_block)

    def page_header(assigns) do
      ~H"""
      <header class={["tl-page__header"] ++ if(@variant == "display", do: ["tl-home__hero"], else: []) ++ List.wrap(@class)} {@rest}>
        <.breadcrumb_trail :if={@breadcrumbs != []} crumbs={@breadcrumbs} />
        <div>
          <h1 id={@id} class={if @variant == "display", do: "tl-home__headline", else: "tl-page__title"}>
            <%= if @heading != [], do: render_slot(@heading), else: @title %>
          </h1>
          <p :if={@lede != []} class={if @variant == "display", do: "tl-home__lede", else: "tl-page__lede"}>
            <%= render_slot(@lede) %>
          </p>
          <p :if={@meta != []} class="tl-page__meta"><%= render_slot(@meta) %></p>
          <%= render_slot(@inner_block) %>
        </div>
        <div :if={@actions != []} class="tl-page__actions"><%= render_slot(@actions) %></div>
      </header>
      """
    end

    @doc false
    attr(:crumbs, :list, required: true)

    defp breadcrumb_trail(assigns) do
      assigns = assign(assigns, :last_index, length(assigns.crumbs) - 1)

      ~H"""
      <nav aria-label="Breadcrumb" class="tl-transaction__breadcrumbs">
        <%= for {crumb, idx} <- Enum.with_index(@crumbs) do %>
          <%= if crumb[:href] do %>
            <a href={crumb[:href]} class="tl-link tl-link--back"><%= crumb[:label] %></a>
          <% else %>
            <span class={idx == @last_index && "tl-transaction__breadcrumbs-current"}><%= crumb[:label] %></span>
          <% end %>
        <% end %>
      </nav>
      """
    end

    @doc false
    # De-emphasized, accessible pager over the existing keyset engine.
    # Infinite scroll stays the primary interaction; this gives keyboard/SR users explicit
    # "Older"/"Newer" (time-axis) controls plus an honest end-of-stream signal. No engine
    # change — the controls emit the host page's existing next-page/prev-page events.
    #
    # Contract (locked by pager_test.exs):
    #   * hide-at-zero: renders nothing when match_count == 0 (no tl-pager markup).
    #   * disable-not-hide: a boundary control stays in the DOM but `disabled`,
    #     never dropped (a Newer/Older control is only omitted when its event is nil,
    #     e.g. Timeline is next-only).
    #   * range caption is a role="status" aria-live="polite" "Showing N of … matching
    #     changes" live region.
    #   * deep-total cap: match_count >= 10_001 renders "10,000+", never an exact
    #     deep total (mirrors timeline_live format_count/1).
    attr(:shown, :integer, required: true, doc: "Count currently rendered on the page")

    attr(:match_count, :any,
      default: nil,
      doc:
        "Total matching count (integer, capped at 10,000+). nil renders an honest count-free caption for surfaces (e.g. the actor sliding window) that have no cheap real total."
    )

    attr(:has_older, :boolean, default: false, doc: "Whether an older keyset page exists")
    attr(:has_newer, :boolean, default: false, doc: "Whether a newer keyset page exists")

    attr(:older_event, :string,
      default: "next-page",
      doc: "phx-click event for the Older control (older = further back in time = next page)"
    )

    attr(:newer_event, :any,
      default: "prev-page",
      doc:
        "phx-click event for the Newer control; nil omits the control entirely (next-only pages)"
    )

    attr(:label, :string,
      default: "Timeline pagination",
      doc:
        "aria-label for the pager <nav> landmark; callers on non-timeline surfaces (e.g. the actor page) should pass an accurate label."
    )

    attr(:class, :any, default: nil)
    attr(:rest, :global)

    def pager(assigns) do
      ~H"""
      <nav
        :if={is_nil(@match_count) or @match_count > 0}
        class={["tl-pager", @class]}
        aria-label={@label}
        {@rest}
      >
        <button
          :if={@newer_event}
          type="button"
          phx-click={@newer_event}
          disabled={!@has_newer}
          class="tl-button tl-button--secondary tl-button--compact tl-pager__control"
        >
          Newer
        </button>
        <span class="tl-pager__range" role="status" aria-live="polite">
          <%= if is_nil(@match_count) do %>
            Showing <%= @shown %> matching changes
          <% else %>
            Showing <%= @shown %> of <%= pager_total(@match_count) %> matching changes
          <% end %>
        </span>
        <button
          :if={@older_event}
          type="button"
          phx-click={@older_event}
          disabled={!@has_older}
          class="tl-button tl-button--secondary tl-button--compact tl-pager__control"
        >
          Older
        </button>
      </nav>
      """
    end

    # Honest range total: at/above the keyset cap (10_001) show "10,000+" (never an exact
    # deep total — mitigates T-175-09); below the cap show the exact integer with separators.
    defp pager_total(count) when is_integer(count) and count >= 10_001, do: "10,000+"

    defp pager_total(count) when is_integer(count) do
      count
      |> Integer.to_string()
      |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")
    end

    @doc false
    # Filter/search/sort toolbar. A `cluster`-style row that carries cross-child disabled
    # coordination: when the data region is loading or in a hard error, the page derives
    # `disabled` from the same state assign (`state in [:loading, :error]`) and passes it
    # here. The container then gets
    # `aria-disabled` + the `is-disabled` class (pointer-events:none + dimming — affordance
    # only). The page MUST ALSO set the HTML `disabled` attribute on the actual controls
    # from that same assign: `pointer-events:none` alone leaves controls keyboard-focusable
    # and screen-reader activatable; affordance is not enforcement.
    attr(:disabled, :boolean,
      default: false,
      doc: "true while the data region is loading or in a hard error"
    )

    attr(:class, :any, default: nil)
    attr(:rest, :global)
    slot(:inner_block, required: true)

    def toolbar(assigns) do
      ~H"""
      <div
        class={["tl-toolbar", "tl-cluster", @disabled && "is-disabled", @class]}
        role="search"
        aria-disabled={to_string(@disabled)}
        {@rest}
      >
        <%= render_slot(@inner_block) %>
      </div>
      """
    end

    @doc false
    # Detail-page header. Title + metadata kv + actions cluster, recurring on the
    # transaction / actor / row-history pages. Renders an <h2> (NOT <h1>) — page_header
    # owns the single <h1> per page. Composes the existing kv/1 + cluster
    # rather than re-rolling layout.
    attr(:title, :string, required: true)
    attr(:class, :any, default: nil)
    attr(:rest, :global)

    slot :metadata, doc: "kv rows: <:metadata key=\"...\">value</:metadata>" do
      attr(:key, :string, required: true)
    end

    slot(:actions)

    def detail_header(assigns) do
      ~H"""
      <header class={["tl-detail-header", @class]} {@rest}>
        <div class="tl-detail-header__top">
          <h2 class="tl-detail-header__title"><%= @title %></h2>
          <Display.cluster :if={@actions != []} justify="end" class="tl-detail-header__actions">
            <%= render_slot(@actions) %>
          </Display.cluster>
        </div>
        <Display.kv :if={@metadata != []} class="tl-detail-header__meta">
          <:item :for={m <- @metadata} key={m.key}><%= render_slot(m) %></:item>
        </Display.kv>
      </header>
      """
    end

    @doc false
    # This is the single shared shell and chrome for all operator
    # LiveViews. Before this component existed, every LiveView hand-duplicated
    # the threadline-ui root + the inner #tl-main wrapper, which is exactly why
    # the reconnect strip had no home and nothing mounted it. Routing every page
    # through `shell/1` gives that strip a single mount
    # point — rendered exactly ONCE by the banner component below, directly
    # above the #tl-main element and inside the threadline-ui root — and kills
    # the 11-way drift.
    #
    # Phoenix LiveView applies `.phx-loading`,
    # `.phx-error`, and `.phx-client-error` to the `[data-phx-main]` container in
    # this app; the threadline-ui element is the scoped descendant shell. The strip
    # + `[data-tl-mutating]` dimming is pure CSS keyed off that ancestor/container
    # relationship — never the document body, never the legacy pre-1.0 disconnected
    # class.
    #
    # Stays `@doc false` and private: there is no public host-facing component API.
    # Pages keep their own `<main>` class via `:main_class` so the
    # per-page centering wrappers (e.g. `tl-container`, `tl-home`) survive, and any
    # page-specific `<main>` attributes ride the `:main_rest` global.
    # `:base_path` is nilable: four LiveViews (evidence, policy_redaction,
    # retention_history, export_status) only render `surface_header` when a
    # `base_path` is present — when nil the chrome nav is suppressed but the
    # shell, reconnect banner, and `#tl-main` body still render. Gating the
    # header on `@base_path` here preserves that per-page behavior byte-for-byte
    # while still mounting the banner exactly once.
    # `:header_theme` lets the stress lab preview a `:theme`-driven root
    # (`data-tl-theme`) while keeping the chrome nav on the host's own theme —
    # the one place where the root and nav themes intentionally diverge. It
    # defaults to `:theme` so the other 10 pages render identically.
    attr(:theme, :string, default: "dark")
    attr(:header_theme, :string, default: nil)
    attr(:current, :atom, default: nil)
    attr(:coverage, :map, default: %{uncovered_count: 0})
    attr(:base_path, :string, default: nil)
    attr(:error, :string, default: nil)
    attr(:coverage_enabled, :boolean, default: false)
    attr(:policy_enabled, :boolean, default: false)
    attr(:evidence_enabled, :boolean, default: false)
    attr(:exports_enabled, :boolean, default: false)
    attr(:scoped, :boolean, default: false)
    attr(:script, :boolean, default: false)
    attr(:main_class, :any, default: "tl-page")
    attr(:main_rest, :global, include: ~w(data-testid))
    slot(:inner_block, required: true)

    def shell(assigns) do
      assigns = assign_new(assigns, :header_theme, fn -> assigns[:theme] end)

      ~H"""
      <div class="threadline-ui" data-tl-theme={@theme}>
        <Threadline.OperatorSurface.Style.css />
        <Script.js :if={@script} />
        <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
          :if={@base_path}
          theme={@header_theme || @theme}
          coverage={@coverage}
          base_path={@base_path}
          error={@error}
          coverage_enabled={@coverage_enabled}
          policy_enabled={@policy_enabled}
          evidence_enabled={@evidence_enabled}
          exports_enabled={@exports_enabled}
          current={@current}
          scoped={@scoped}
        />
        <Overlay.reconnect_banner />
        <main id="tl-main" class={@main_class} tabindex="-1" {@main_rest}>
          <%= render_slot(@inner_block) %>
        </main>
      </div>
      """
    end

    @doc false
    attr(:class, :any, default: nil)
    attr(:rest, :global)

    slot :tab, required: true do
      attr(:active, :boolean)
      attr(:id, :string)
      attr(:controls, :string)
    end

    def tabs(assigns) do
      ~H"""
      <div class={["tl-tabs", @class]} role="tablist" {@rest}>
        <button
          :for={tab <- @tab}
          type="button"
          id={tab[:id]}
          role="tab"
          aria-selected={if tab[:active], do: "true", else: "false"}
          aria-controls={tab[:controls]}
          tabindex={if tab[:active], do: "0", else: "-1"}
          class={["tl-tab", tab[:active] && "tl-tab--active"]}
        >
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
      attr(:"phx-click", :string)
      attr(:"phx-value-hours", :string)
    end

    def segmented_control(assigns) do
      ~H"""
      <div class={["tl-segmented-control", @class]} role="group" {@rest}>
        <button
          :for={seg <- @segment}
          type="button"
          aria-pressed={if seg[:active], do: "true", else: "false"}
          class={["tl-segment", seg[:active] && "tl-segment--active"]}
          phx-click={seg[:"phx-click"]}
          phx-value-hours={seg[:"phx-value-hours"]}
        >
          <%= render_slot(seg) %>
        </button>
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
