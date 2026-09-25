if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive.Filters do
    @moduledoc false

    use Phoenix.Component

    alias Phoenix.LiveView.JS
    alias Threadline.OperatorSurface.Live.TimelineLive.Helpers
    alias Threadline.OperatorSurface.UI
    alias Threadline.Semantics.ActorRef

    attr(:filters_raw, :map, required: true)
    attr(:audited_tables, :list, required: true)
    attr(:match_count, :integer, required: true)
    attr(:coverage, :map, default: nil)
    attr(:timeline_path, :string, required: true)

    def timeline_command(assigns) do
      assigns =
        assigns
        |> assign(:window, Helpers.filter_window_summary(assigns.filters_raw))
        |> assign(:active_filters, Helpers.active_filter_pairs(assigns.filters_raw))
        |> assign(:advanced_filter_count, Helpers.advanced_filter_count(assigns.filters_raw))

      ~H"""
      <section class="tl-toolbar tl-timeline-command" aria-labelledby="timeline-command-title">
        <div class="tl-timeline-command__summary">
          <div class="tl-timeline-command__heading">
            <h1 id="timeline-command-title" class="tl-timeline-command__title">
              Investigate audit activity
            </h1>
            <p class="tl-timeline-command__lede">
              Start with a time window, table, or correlation id. Add actor and schema filters only when the investigation needs them.
            </p>
          </div>

          <.command_facts window={@window} match_count={@match_count} coverage={@coverage} />
        </div>

        <form id="timeline-filters" phx-submit="apply" role="search" class="tl-toolbar__form">
          <UI.Form.field_group legend="Search" class="tl-filter-group--primary">
            <div class="tl-filter-grid tl-filter-grid--primary">
              <UI.Form.field
                id="filter-from"
                type="datetime-local"
                name="filter[from]"
                label="From"
                value={@filters_raw["from"] || ""}
                class="tl-toolbar__field"
                phx-debounce="blur"
              />
              <UI.Form.field
                id="filter-to"
                type="datetime-local"
                name="filter[to]"
                label="To"
                value={@filters_raw["to"] || ""}
                class="tl-toolbar__field"
                phx-debounce="blur"
              />
              <UI.Form.field
                id="filter-table"
                type="text"
                name="filter[table]"
                label="Table"
                value={@filters_raw["table"] || ""}
                class="tl-toolbar__field"
                phx-debounce="blur"
                list="audited-tables"
              />
              <datalist id="audited-tables">
                <option :for={name <- @audited_tables} value={name}></option>
              </datalist>
              <UI.Form.field
                id="filter-correlation-id"
                type="text"
                name="filter[correlation_id]"
                label="Correlation id"
                value={@filters_raw["correlation_id"] || ""}
                class="tl-toolbar__field tl-toolbar__field--wide"
                maxlength="256"
                phx-debounce="300"
                placeholder="request, job, or integration id"
              />
              <div class="tl-toolbar__actions tl-filter-actions">
                <button
                  type="button"
                  class="tl-button tl-button--secondary"
                  aria-haspopup="dialog"
                  aria-controls="timeline-filters-drawer"
                  phx-click={JS.push_focus() |> UI.Overlay.show_drawer("timeline-filters-drawer")}
                >
                  <Threadline.OperatorSurface.Components.Icon.icon name={:funnel} class="tl-button__icon" />
                  Filters
                  <span :if={@advanced_filter_count > 0} class="tl-button__meta">
                    <%= @advanced_filter_count %>
                  </span>
                </button>
                <.link patch={@timeline_path} class="tl-button tl-button--ghost">
                  <Threadline.OperatorSurface.Components.Icon.icon name={:filter_x} class="tl-button__icon" />
                  Reset to last 24h
                </.link>
                <button type="submit" class="tl-button tl-button--primary">
                  <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
                  Apply
                </button>
              </div>
            </div>
          </UI.Form.field_group>
        </form>

        <.active_filter_summary window={@window} active_filters={@active_filters} />

      </section>
      """
    end

    attr(:filters_raw, :map, required: true)
    attr(:coverage_enabled, :boolean, required: true)
    attr(:evidence_enabled, :boolean, required: true)
    attr(:exports_enabled, :boolean, required: true)
    attr(:actor_ref, :any, default: nil)
    attr(:saved_views, :list, required: true)
    attr(:base_path, :string, required: true)
    attr(:filter_query, :string, required: true)
    attr(:export_ready, :boolean, required: true)
    attr(:background_export_ready, :boolean, required: true)

    def timeline_filter_drawer(assigns) do
      ~H"""
      <UI.Overlay.drawer
        id="timeline-filters-drawer"
        class="tl-timeline-drawer"
        phx-window-keydown={UI.Overlay.hide_drawer("timeline-filters-drawer")}
        phx-key="Escape"
      >
        <div class="tl-timeline-drawer__header">
          <div class="tl-timeline-drawer__heading">
            <h2 id="timeline-filters-drawer-title" class="tl-modal__title">
              Filters and handoff
            </h2>
            <p id="timeline-filters-drawer-description" class="tl-modal__body">
              Refine the current Timeline query, save reusable views, or package this result set for a handoff.
            </p>
          </div>
          <button
            type="button"
            class="tl-button tl-button--secondary"
            phx-click={UI.Overlay.hide_drawer("timeline-filters-drawer")}
            data-tl-initial-focus
          >
            Close
          </button>
        </div>

        <.advanced_filters filters_raw={@filters_raw} />

        <div class="tl-timeline-command__utilities">
          <.check_links
            coverage_enabled={@coverage_enabled}
            evidence_enabled={@evidence_enabled}
            base_path={@base_path}
          />

          <.export_actions
            exports_enabled={@exports_enabled}
            base_path={@base_path}
            filter_query={@filter_query}
            export_ready={@export_ready}
            background_export_ready={@background_export_ready}
          />

          <.saved_views_group actor_ref={@actor_ref} saved_views={@saved_views} />
        </div>
      </UI.Overlay.drawer>
      """
    end

    attr(:window, :map, required: true)
    attr(:match_count, :integer, required: true)
    attr(:coverage, :map, default: nil)

    defp command_facts(assigns) do
      ~H"""
      <div class="tl-timeline-command__facts" aria-label="Current investigation summary">
        <div class="tl-timeline-fact tl-timeline-fact--window" data-status="info">
          <span class="tl-timeline-fact__label">Window</span>
          <strong class="tl-timeline-fact__value" title={@window.title}>
            <%= @window.label %>
          </strong>
          <span class="tl-timeline-fact__detail"><%= @window.detail %></span>
        </div>
        <div class="tl-status tl-timeline-fact">
          <span class="tl-timeline-fact__label">Matching changes</span>
          <strong class="tl-timeline-fact__value"><%= Helpers.format_count(@match_count) %></strong>
          <span class="tl-timeline-fact__detail">current result set</span>
        </div>
        <div
          class="tl-timeline-fact"
          data-status={if Helpers.coverage_warning?(@coverage), do: "warning", else: "success"}
        >
          <span class="tl-timeline-fact__label">Audit readiness</span>
          <strong class="tl-timeline-fact__value"><%= Helpers.coverage_summary(@coverage) %></strong>
          <span class="tl-timeline-fact__detail">coverage posture</span>
        </div>
      </div>
      """
    end

    attr(:window, :map, required: true)
    attr(:active_filters, :list, required: true)

    defp active_filter_summary(assigns) do
      ~H"""
      <section class="tl-filter-summary" aria-label="Active Timeline filters">
        <strong>Active filters</strong>
        <span class="tl-chip tl-chip--info" title={@window.title}>Window: <%= @window.label %></span>
        <span class="tl-filter-summary__window"><%= @window.detail %></span>
        <span :for={{label, value} <- @active_filters} class="tl-chip tl-chip--neutral">
          <%= label %>: <%= value %>
        </span>
        <span :if={@active_filters == []} class="tl-filter-summary__empty">
          No table, schema, actor, or correlation filter
        </span>
      </section>
      """
    end

    attr(:filters_raw, :map, required: true)

    defp advanced_filters(assigns) do
      assigns =
        assign(
          assigns,
          :advanced_filter_count,
          Helpers.advanced_filter_count(assigns.filters_raw)
        )

      ~H"""
      <section class="tl-timeline-drawer__section" aria-labelledby="timeline-advanced-filters-title">
        <div class="tl-timeline-drawer__section-heading">
          <h3 id="timeline-advanced-filters-title" class="tl-utility-group__label">
            Advanced filters
          </h3>
          <span :if={@advanced_filter_count > 0} class="tl-chip tl-chip--neutral">
            <%= @advanced_filter_count %> active
          </span>
        </div>
        <div class="tl-filter-grid tl-filter-grid--advanced">
          <UI.Form.field
            id="filter-table-schema"
            type="text"
            name="filter[table_schema]"
            label="Schema"
            value={@filters_raw["table_schema"] || ""}
            class="tl-toolbar__field"
            form="timeline-filters"
            phx-debounce="blur"
          />
          <UI.Form.field
            id="filter-actor-kind"
            type="select"
            name="filter[actor_kind]"
            label="Actor kind"
            options={[{"Any kind", ""} | Enum.map(~w(user admin service_account job system anonymous), &{&1, &1})]}
            value={@filters_raw["actor_kind"] || ""}
            class="tl-toolbar__field"
            form="timeline-filters"
          />
          <UI.Form.field
            id="filter-actor-id"
            type="text"
            name="filter[actor_id]"
            label="Actor id"
            value={@filters_raw["actor_id"] || ""}
            class="tl-toolbar__field"
            disabled={@filters_raw["actor_kind"] == "anonymous"}
            form="timeline-filters"
            phx-debounce="blur"
            help_text={if @filters_raw["actor_kind"] == "anonymous", do: "n/a for anonymous", else: nil}
          />
        </div>
        <div class="tl-toolbar__actions tl-timeline-drawer__actions">
          <button type="submit" form="timeline-filters" class="tl-button tl-button--primary">
            <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
            Apply filters
          </button>
        </div>
      </section>
      """
    end

    attr(:coverage_enabled, :boolean, required: true)
    attr(:evidence_enabled, :boolean, required: true)
    attr(:base_path, :string, required: true)

    defp check_links(assigns) do
      ~H"""
      <section
        :if={@coverage_enabled or @evidence_enabled}
        class="tl-utility-group"
        aria-label="Investigation checks"
      >
        <span class="tl-utility-group__label">Check</span>
        <a
          :if={@coverage_enabled and @base_path}
          href={"#{@base_path}/coverage"}
          class="tl-button tl-button--secondary"
        >
          <Threadline.OperatorSurface.Components.Icon.icon name={:shield} class="tl-button__icon" />
          Coverage
        </a>
        <a
          :if={@evidence_enabled and @base_path}
          href={"#{@base_path}/evidence"}
          class="tl-button tl-button--secondary"
        >
          <Threadline.OperatorSurface.Components.Icon.icon name={:evidence} class="tl-button__icon" />
          Evidence
        </a>
      </section>
      """
    end

    attr(:exports_enabled, :boolean, required: true)
    attr(:base_path, :string, required: true)
    attr(:filter_query, :string, required: true)
    attr(:export_ready, :boolean, required: true)
    attr(:background_export_ready, :boolean, required: true)

    defp export_actions(assigns) do
      ~H"""
      <section :if={@exports_enabled} class="tl-utility-group" aria-label="Export actions">
        <span class="tl-utility-group__label">Export</span>
        <.link
          navigate={"#{@base_path}/exports?#{@filter_query}"}
          class="tl-button tl-button--compact tl-button--secondary"
        >
          <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
          Carry to Exports
        </.link>
        <button
          :if={@background_export_ready}
          phx-click="request_background_export"
          type="button"
          class="tl-button tl-button--quiet-primary"
        >
          <Threadline.OperatorSurface.Components.Icon.icon name={:archive} class="tl-button__icon" />
          Queue export
        </button>
        <.link
          :if={@export_ready}
          href={"#{@base_path}/exports/changes.csv?#{@filter_query}"}
          download
          class="tl-button tl-button--compact tl-button--secondary"
        >
          <Threadline.OperatorSurface.Components.Icon.icon name={:download} class="tl-button__icon" />
          CSV
        </.link>
        <.link
          :if={@export_ready}
          href={"#{@base_path}/exports/changes.json?#{@filter_query}"}
          download
          class="tl-button tl-button--compact tl-button--secondary"
        >
          <Threadline.OperatorSurface.Components.Icon.icon name={:download} class="tl-button__icon" />
          JSON
        </.link>
        <.link
          :if={@export_ready}
          href={"#{@base_path}/exports/changes.ndjson?#{@filter_query}"}
          download
          class="tl-button tl-button--compact tl-button--secondary"
        >
          <Threadline.OperatorSurface.Components.Icon.icon name={:download} class="tl-button__icon" />
          NDJSON
        </.link>
      </section>
      """
    end

    attr(:actor_ref, :any, default: nil)
    attr(:saved_views, :list, required: true)

    defp saved_views_group(assigns) do
      ~H"""
      <section
        :if={ActorRef.identifiable?(@actor_ref)}
        class="tl-utility-group tl-utility-group--views"
        aria-label="Saved views"
      >
        <span class="tl-utility-group__label">Views</span>
        <form id="save-view-form" phx-submit="save-view" class="tl-saved-view-form">
          <input
            type="text"
            name="name"
            placeholder="Name this view..."
            aria-label="View name"
            required
            class="tl-control"
          />
          <button type="submit" class="tl-button tl-button--secondary" data-tl-mutating>
            <Threadline.OperatorSurface.Components.Icon.icon name={:archive} class="tl-button__icon" />
            Save view
          </button>
        </form>
        <ul :if={@saved_views != []} class="tl-toolbar__saved-list" aria-label="Saved views">
          <li :for={view <- @saved_views} class="tl-toolbar__saved-item">
            <button
              phx-click="apply-view"
              phx-value-id={view.id}
              type="button"
              class="tl-button tl-button--secondary"
            >
              <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
              <%= view.name %>
            </button>
            <button
              phx-click="delete-view"
              phx-value-id={view.id}
              type="button"
              class="tl-button tl-button--ghost tl-button--danger tl-button--icon"
              aria-label={"Delete " <> view.name}
              data-tl-mutating
            >
              <Threadline.OperatorSurface.Components.Icon.icon name={:trash} />
            </button>
          </li>
        </ul>
      </section>
      """
    end
  end
end
