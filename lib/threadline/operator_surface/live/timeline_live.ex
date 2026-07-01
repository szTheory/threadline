if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive do
    @moduledoc false
    use Phoenix.LiveView
    import Ecto.Query

    alias Phoenix.LiveView.JS
    alias Threadline.Export
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.Exports.FilterParams
    alias Threadline.Query
    alias Threadline.StorageSchema
    alias Threadline.OperatorSurface.UI

    @page_size 50
    @default_window_hours 24

    # --------------------------------------------------------------------------
    # mount/3
    # --------------------------------------------------------------------------

    def mount(_params, _session, socket) do
      repo =
        socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

      # Bracket form — scope is set ONLY when :authorize_fn returns {:ok, scope}.
      # For :ok / true returns, the assign is absent. (auth.ex:21-27)
      scope = socket.assigns[:threadline_scope]
      actor_ref = socket.assigns[:threadline_actor_ref]

      # Datalist refreshed at mount; long-lived sessions may not see newly-audited tables
      # until the next page load. Future iterations may introduce a polled coverage source we can
      # subscribe to.
      audited_tables =
        Threadline.Health.trigger_coverage(repo: repo)
        |> Enum.flat_map(fn
          {:covered, name} -> [name]
          _ -> []
        end)
        |> Enum.sort()

      saved_views =
        if actor_ref do
          repo.all(
            from(v in Threadline.Governance.SavedView,
              where: v.actor_ref == ^actor_ref,
              order_by: [desc: v.inserted_at]
            ),
            storage_opts(socket)
          )
        else
          []
        end

      socket =
        socket
        |> stream_configure(:changes, dom_id: fn change -> "change-#{change.id}" end)
        |> stream(:changes, [])
        |> assign(:repo, repo)
        |> assign(:scope, scope)
        |> assign(:audited_tables, audited_tables)
        |> assign(:saved_views, saved_views)
        |> assign(:cursor, nil)
        |> assign(:filters, [])
        |> assign(:filters_raw, %{})
        |> assign(:form_error, nil)
        |> assign(:unknown_table_attempted, false)
        |> assign(:future_window_empty, false)
        |> assign(:base_path, nil)
        |> assign(:timeline_path, nil)
        |> assign(:match_count, 0)
        |> assign(:shown_count, 0)
        |> assign(:filter_query, "")

      {:ok, socket}
    end

    # --------------------------------------------------------------------------
    # handle_params/3
    # --------------------------------------------------------------------------

    def handle_params(params, uri, socket) do
      uri_parsed = URI.parse(uri)
      # Timeline is mounted at "<surface>/timeline"; strip the suffix so base_path
      # stays the surface root for cross-surface links (exports, coverage, actors,
      # transactions). timeline_path is the timeline's own path for self-patches.
      timeline_path = uri_parsed.path
      base_path = (timeline_path || "") |> String.replace_suffix("/timeline", "")

      socket =
        socket
        |> assign(:base_path, base_path)
        |> assign(:timeline_path, timeline_path)

      if params == %{} do
        from = DateTime.utc_now() |> DateTime.add(-@default_window_hours * 3600, :second)
        to = DateTime.utc_now()

        query_string =
          URI.encode_query([
            {"from", DateTime.to_iso8601(from) |> String.slice(0..15)},
            {"to", DateTime.to_iso8601(to) |> String.slice(0..15)}
          ])

        {:noreply, push_patch(socket, to: "#{timeline_path}?#{query_string}", replace: true)}
      else
        socket = assign(socket, :filters_raw, FilterParams.filters_raw_from_params(params))

        case FilterParams.parse(params) do
          {:error, message} ->
            filter_query = build_canonical_query(socket.assigns.filters_raw)

            socket =
              socket
              |> assign(:form_error, message)
              |> assign(:filters, [])
              |> assign(:cursor, nil)
              |> assign(:future_window_empty, false)
              |> assign(:match_count, 0)
              |> assign(:shown_count, 0)
              |> assign(:filter_query, filter_query)
              |> stream(:changes, [], reset: true)

            {:noreply, socket}

          {:ok, filters} ->
            case safe_validate(filters) do
              {:error, message} ->
                filter_query = build_canonical_query(socket.assigns.filters_raw)

                socket =
                  socket
                  |> assign(:form_error, message)
                  |> assign(:filters, [])
                  |> assign(:cursor, nil)
                  |> assign(:future_window_empty, false)
                  |> assign(:match_count, 0)
                  |> assign(:shown_count, 0)
                  |> assign(:filter_query, filter_query)
                  |> stream(:changes, [], reset: true)

                {:noreply, socket}

              :ok ->
                unknown_table_attempted =
                  case Keyword.get(filters, :table) do
                    nil ->
                      false

                    table ->
                      table not in socket.assigns.audited_tables
                  end

                # Clear cursor BEFORE stream reset (Pitfall 1 + F-3 mitigation)
                socket = assign(socket, :cursor, nil)

                count_task =
                  Task.async(fn ->
                    Export.count_matching(filters, count_opts(socket, 10_001))
                  end)

                page_task =
                  Task.async(fn ->
                    Query.timeline_page(filters, scope_aware_opts(socket))
                  end)

                # Two parallel queries; await with a generous timeout.
                # Default Task.await is 5_000 ms; bump to 8_000 to leave headroom for
                # slow capped-count queries on large tables (RESEARCH §P-7 line 651).
                {:ok, %{count: count}} = Task.await(count_task, 8_000)

                page =
                  page_task
                  |> Task.await(8_000)
                  |> preload_visible_context(socket.assigns.repo, scope_aware_opts(socket))

                filter_query = build_canonical_query(socket.assigns.filters_raw)
                future_window_empty = future_window_empty?(filters, count, socket)

                socket =
                  socket
                  |> assign(:filters, filters)
                  |> assign(:form_error, nil)
                  |> assign(:unknown_table_attempted, unknown_table_attempted)
                  |> assign(:future_window_empty, future_window_empty)
                  |> assign(:match_count, count)
                  |> assign(:shown_count, length(page.entries))
                  |> assign(:filter_query, filter_query)
                  |> stream(:changes, page.entries, reset: true)
                  |> assign(:cursor, page.next_cursor)

                {:noreply, socket}
            end
        end
      end
    end

    # --------------------------------------------------------------------------
    # handle_event/3
    # --------------------------------------------------------------------------

    def handle_event("save-view", %{"name" => name}, socket) do
      if socket.assigns[:threadline_actor_ref] && name != "" do
        attrs = %{
          name: name,
          actor_ref: Threadline.Semantics.ActorRef.to_map(socket.assigns.threadline_actor_ref),
          filters: socket.assigns.filters_raw
        }

        changeset = Threadline.Governance.SavedView.changeset(attrs)

        case socket.assigns.repo.insert(changeset, storage_opts(socket)) do
          {:ok, view} ->
            saved_views = [view | socket.assigns.saved_views]
            {:noreply, assign(socket, :saved_views, saved_views)}

          {:error, _} ->
            {:noreply, socket}
        end
      else
        {:noreply, socket}
      end
    end

    def handle_event("apply-view", %{"id" => id}, socket) do
      case Enum.find(socket.assigns.saved_views, &(&1.id == id)) do
        nil ->
          {:noreply, socket}

        view ->
          query = build_canonical_query(view.filters)
          {:noreply, push_patch(socket, to: "#{socket.assigns.timeline_path}?#{query}")}
      end
    end

    def handle_event("delete-view", %{"id" => id}, socket) do
      case Enum.find(socket.assigns.saved_views, &(&1.id == id)) do
        nil ->
          {:noreply, socket}

        view ->
          socket.assigns.repo.delete!(view, storage_opts(socket))
          saved_views = Enum.reject(socket.assigns.saved_views, &(&1.id == id))
          {:noreply, assign(socket, :saved_views, saved_views)}
      end
    end

    def handle_event("apply", %{"filter" => raw}, socket) do
      query = build_canonical_query(raw)
      {:noreply, push_patch(socket, to: "#{socket.assigns.timeline_path}?#{query}")}
    end

    def handle_event("apply", _params, socket) do
      {:noreply, push_patch(socket, to: socket.assigns.timeline_path)}
    end

    def handle_event(
          "request_background_export",
          _params,
          %{assigns: %{form_error: error}} = socket
        )
        when is_binary(error) and error != "" do
      {:noreply, put_flash(socket, :error, "Fix Timeline filters before exporting.")}
    end

    def handle_event(
          "request_background_export",
          _params,
          %{assigns: %{threadline_exports_enabled: true}} = socket
        ) do
      repo = scope_aware_opts(socket)[:repo] || default_repo()

      job = %Threadline.Governance.ExportJob{
        status: "pending",
        query_params: Map.new(socket.assigns.filters, fn {k, v} -> {to_string(k), v} end),
        actor_ref: socket.assigns[:threadline_actor_ref]
      }

      job = repo.insert!(job, storage_opts(socket))

      adapter =
        Application.get_env(
          :threadline,
          :export_queue_adapter,
          Threadline.ExportQueue.TaskAdapter
        )

      case adapter.enqueue(job.id) do
        :ok ->
          {:noreply,
           socket
           |> put_flash(
             :info,
             "Background export requested. View progress on the Export Status page."
           )
           |> push_navigate(to: "#{socket.assigns.base_path}/exports")}

        {:error, reason} ->
          error_message = background_export_error_message(reason)

          job
          |> Threadline.Governance.ExportJob.changeset(%{
            status: "failed",
            error_message: error_message,
            expires_at: terminal_export_expiry()
          })
          |> repo.update!(storage_opts(socket))

          {:noreply, put_flash(socket, :error, error_message)}
      end
    end

    def handle_event("request_background_export", _params, socket), do: {:noreply, socket}

    def handle_event("next-page", _, socket) do
      if socket.assigns.cursor do
        opts =
          socket
          |> scope_aware_opts()
          |> Keyword.put(:cursor, socket.assigns.cursor)

        page =
          Query.timeline_page(
            socket.assigns.filters,
            opts
          )
          |> preload_visible_context(socket.assigns.repo, scope_aware_opts(socket))

        {:noreply,
         socket
         |> assign(:cursor, page.next_cursor)
         |> Phoenix.Component.update(:shown_count, &(&1 + length(page.entries)))
         |> stream(:changes, page.entries, at: -1)}
      else
        {:noreply, socket}
      end
    end

    # --------------------------------------------------------------------------
    # render/1
    # --------------------------------------------------------------------------

    def render(assigns) do
      ~H"""
      <UI.shell
        theme={@threadline_theme}
        coverage={assigns[:threadline_coverage] || %{uncovered_count: 0}}
        base_path={@base_path}
        error={assigns[:threadline_coverage_error]}
        coverage_enabled={@threadline_coverage_enabled}
        policy_enabled={@threadline_policy_enabled}
        evidence_enabled={@threadline_evidence_enabled}
        exports_enabled={@threadline_exports_enabled}
        current={:timeline}
        scoped={not is_nil(assigns[:threadline_scope])}
        script
        main_class="tl-page tl-page--intro"
      >
          <.timeline_command
            filters_raw={@filters_raw}
            audited_tables={@audited_tables}
            shown_count={@shown_count}
            match_count={@match_count}
            coverage={assigns[:threadline_coverage]}
            coverage_enabled={@threadline_coverage_enabled}
            evidence_enabled={@threadline_evidence_enabled}
            exports_enabled={@threadline_exports_enabled}
            actor_ref={assigns[:threadline_actor_ref]}
            saved_views={@saved_views}
            base_path={@base_path}
            timeline_path={@timeline_path}
            filter_query={@filter_query}
          />

        <%= if @form_error do %>
          <div class="tl-alert tl-alert--error" role="alert">
            <%= invalid_filter_message(@form_error) %>
          </div>
        <% end %>

        <%= if Enum.empty?(@streams.changes.inserts) and @unknown_table_attempted do %>
          <div class="tl-alert tl-alert--info" role="status">
            <%= unknown_table_message(@filters_raw["table"], @audited_tables) %>
          </div>
        <% end %>

        <%= if @match_count > 5_000 and @match_count < 10_001 do %>
          <div class="tl-alert tl-alert--info" role="status">
            Large export — will stream in chunks.
          </div>
        <% end %>

        <%= if @match_count >= 10_001 do %>
          <div class="tl-alert tl-alert--warning" role="alert">
            Truncated to first 10,000 rows. Use `mix threadline.export --max-rows N` for the full window.
          </div>
        <% end %>

        <section class="tl-change-list" id="timeline-rows" phx-update="stream"
                 phx-viewport-bottom={@cursor && "next-page"}
                 data-testid="operator-timeline">
          <div :for={{dom_id, change} <- @streams.changes} id={dom_id} class={["tl-change", op_row_modifier(change.op)]} data-testid="timeline-row">
            <div class="tl-change__summary">
              <div class="tl-change__meta">
                <span class={["tl-change__op", Presentation.operation_modifier(change.op)]}><%= Presentation.operation_label(change.op) %></span>
                <span
                  class="tl-change__table tl-secondary-ref"
                  title={table_ref(change).title}
                  data-tl-copy={table_ref(change).title}
                >
                  <%= table_ref(change).visible %>
                </span>
                <time class="tl-change__time" datetime={Presentation.exact_time(change.captured_at)} title={Presentation.exact_time(change.captured_at)}>
                  <%= Presentation.human_time(change.captured_at) %>
                </time>
              </div>
              <div class="tl-meta">
                <span>
                  Actor
                  <%= if actor_label(change) != "unknown" do %>
                    <UI.ref value={actor_label(change)} kind="actor" copy_label="Copy actor ref" />
                    <a
                      :if={path = actor_path(@base_path, change)}
                      href={path}
                      class="tl-link tl-link--deep"
                      title="View actor activity"
                    >
                      <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
                      Actor timeline
                    </a>
                  <% else %>
                    <code><%= actor_label(change) %></code>
                  <% end %>
                </span>
                <span :if={correlation_id(change)}>
                  Correlation
                  <UI.ref value={correlation_id(change)} kind="correlation" copy_label="Copy correlation id" />
                  <a href={correlation_path(@timeline_path, correlation_id(change))} class="tl-link tl-link--deep" title="View correlated changes in Timeline">
                    <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
                    Timeline
                  </a>
                </span>
                <span :if={row_id = routeable_row_ref(change)}>
                  Row
                  <UI.ref value={row_id} kind="uuid" copy_label="Copy row id" />
                </span>
              </div>
              <div class="tl-change__actions">
                <a href={"#{@base_path}/transactions/#{change.transaction_id}"} class="tl-button tl-button--compact tl-button--secondary" data-testid="transaction-link">
                  <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
                  Open transaction
                </a>
                <a
                  :if={row_history_path = safe_row_history_path(@base_path, change, assigns[:threadline_schemas])}
                  href={row_history_path}
                  class="tl-button tl-button--compact tl-button--secondary"
                  data-testid="timeline-row-history-link"
                >
                  <Threadline.OperatorSurface.Components.Icon.icon name={:history} class="tl-button__icon" />
                  Row history
                </a>
              </div>
            </div>
          </div>
        </section>
        <UI.pager
          shown={@shown_count}
          match_count={@match_count}
          has_older={@cursor != nil}
          has_newer={false}
          older_event="next-page"
          newer_event={nil}
        />
        <UI.empty_state
          :if={@cursor == nil and Enum.empty?(@streams.changes.inserts)}
          variant={timeline_empty_variant(@filters_raw, @future_window_empty)}
          role="status"
          icon={timeline_empty_icon(@filters_raw, @future_window_empty)}
        >
          <:title><%= timeline_empty_title(@filters_raw, @future_window_empty) %></:title>
          <%= timeline_empty_body(@filters_raw, @future_window_empty) %>
          <:actions>
            <.link patch={@timeline_path} class="tl-button tl-button--secondary">
              <Threadline.OperatorSurface.Components.Icon.icon name={:filter_x} class="tl-button__icon" />
              <%= timeline_empty_action_label(@filters_raw, @future_window_empty) %>
            </.link>
          </:actions>
        </UI.empty_state>
        <.timeline_filter_drawer
          filters_raw={@filters_raw}
          coverage_enabled={@threadline_coverage_enabled}
          evidence_enabled={@threadline_evidence_enabled}
          exports_enabled={@threadline_exports_enabled}
          actor_ref={assigns[:threadline_actor_ref]}
          saved_views={@saved_views}
          base_path={@base_path}
          filter_query={@filter_query}
          export_ready={is_nil(@form_error)}
        />
      </UI.shell>
      """
    end

    defp timeline_command(assigns) do
      assigns =
        assigns
        |> assign(:window, filter_window_summary(assigns.filters_raw))
        |> assign(:active_filters, active_filter_pairs(assigns.filters_raw))
        |> assign(:advanced_filter_count, advanced_filter_count(assigns.filters_raw))

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
              <strong class="tl-timeline-fact__value"><%= format_count(@match_count) %></strong>
              <span class="tl-timeline-fact__detail">current result set</span>
            </div>
            <div
              class="tl-timeline-fact"
              data-status={if coverage_warning?(@coverage), do: "warning", else: "success"}
            >
              <span class="tl-timeline-fact__label">Audit readiness</span>
              <strong class="tl-timeline-fact__value"><%= coverage_summary(@coverage) %></strong>
              <span class="tl-timeline-fact__detail">coverage posture</span>
            </div>
          </div>
        </div>

        <form id="timeline-filters" phx-submit="apply" role="search" class="tl-toolbar__form">
          <UI.field_group legend="Search" class="tl-filter-group--primary">
            <div class="tl-filter-grid tl-filter-grid--primary">
              <UI.field
                id="filter-from"
                type="datetime-local"
                name="filter[from]"
                label="From"
                value={@filters_raw["from"] || ""}
                class="tl-toolbar__field"
                phx-debounce="blur"
              />
              <UI.field
                id="filter-to"
                type="datetime-local"
                name="filter[to]"
                label="To"
                value={@filters_raw["to"] || ""}
                class="tl-toolbar__field"
                phx-debounce="blur"
              />
              <UI.field
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
              <UI.field
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
                  phx-click={JS.push_focus() |> UI.show_drawer("timeline-filters-drawer")}
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
          </UI.field_group>
        </form>

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

      </section>
      """
    end

    defp timeline_filter_drawer(assigns) do
      assigns =
        assigns
        |> assign(:advanced_filter_count, advanced_filter_count(assigns.filters_raw))

      ~H"""
      <UI.drawer
        id="timeline-filters-drawer"
        class="tl-timeline-drawer"
        phx-window-keydown={UI.hide_drawer("timeline-filters-drawer")}
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
            phx-click={UI.hide_drawer("timeline-filters-drawer")}
            data-tl-initial-focus
          >
            Close
          </button>
        </div>

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
            <UI.field
              id="filter-table-schema"
              type="text"
              name="filter[table_schema]"
              label="Schema"
              value={@filters_raw["table_schema"] || ""}
              class="tl-toolbar__field"
              form="timeline-filters"
              phx-debounce="blur"
            />
            <UI.field
              id="filter-actor-kind"
              type="select"
              name="filter[actor_kind]"
              label="Actor kind"
              options={[{"Any kind", ""} | Enum.map(~w(user admin service_account job system anonymous), &{&1, &1})]}
              value={@filters_raw["actor_kind"] || ""}
              class="tl-toolbar__field"
              form="timeline-filters"
            />
            <UI.field
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

        <div class="tl-timeline-command__utilities">
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

          <section :if={@exports_enabled} class="tl-utility-group" aria-label="Export actions">
            <span class="tl-utility-group__label">Export</span>
            <.link
              navigate={"#{@base_path}/exports?#{@filter_query}"}
              class="tl-button tl-button--compact tl-button--secondary"
              data-earned-flow="EF3"
              data-persona="P3"
              data-jtbd="J6"
            >
              <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
              Carry to Exports
            </.link>
            <button
              :if={@export_ready}
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

          <section :if={@actor_ref} class="tl-utility-group tl-utility-group--views" aria-label="Saved views">
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
        </div>
      </UI.drawer>
      """
    end

    # --------------------------------------------------------------------------
    # Private helpers
    # --------------------------------------------------------------------------

    defp scope_aware_opts(socket) do
      [
        repo: socket.assigns.repo,
        page_size: @page_size,
        scope: socket.assigns.scope,
        scope_query_fn: socket.assigns[:threadline_scope_query_fn],
        surface: :timeline,
        params: %{filters: socket.assigns.filters},
        storage_schema: StorageSchema.get()
      ]
    end

    defp count_opts(socket, cap) do
      socket
      |> scope_aware_opts()
      |> Keyword.put(:cap, cap)
    end

    defp default_repo do
      Application.get_env(:threadline, :ecto_repos) |> hd()
    end

    defp storage_opts(_socket), do: StorageSchema.repo_opts(storage_schema: StorageSchema.get())

    defp preload_visible_context(%{entries: entries} = page, repo, opts) do
      %{
        page
        | entries: repo.preload(entries, [transaction: :action], StorageSchema.repo_opts(opts))
      }
    end

    defp actor_label(%{transaction: %{actor_ref: %{type: type, id: id}}}) when not is_nil(id),
      do: "#{type}/#{id}"

    defp actor_label(%{transaction: %{actor_ref: %{"type" => type, "id" => id}}})
         when not is_nil(id),
         do: "#{type}/#{id}"

    defp actor_label(_), do: "unknown"

    defp actor_path(base_path, change) when is_binary(base_path) do
      case actor_ref(change) do
        {type, id} when is_binary(type) and is_binary(id) and id != "" ->
          "#{base_path}/actors/#{URI.encode_www_form(type)}/#{URI.encode_www_form(id)}"

        _ ->
          nil
      end
    end

    defp actor_path(_base_path, _change), do: nil

    defp actor_ref(%{transaction: %{actor_ref: %{type: type, id: id}}}) when not is_nil(id),
      do: {to_string(type), to_string(id)}

    defp actor_ref(%{transaction: %{actor_ref: %{"type" => type, "id" => id}}})
         when not is_nil(id),
         do: {to_string(type), to_string(id)}

    defp actor_ref(_), do: nil

    defp correlation_id(%{transaction: %{action: %{correlation_id: correlation_id}}})
         when is_binary(correlation_id) and correlation_id != "",
         do: correlation_id

    defp correlation_id(_), do: nil

    defp correlation_path(base_path, correlation_id) when is_binary(correlation_id) do
      "#{base_path}?#{URI.encode_query(%{"correlation_id" => correlation_id})}"
    end

    defp correlation_path(base_path, _correlation_id), do: base_path

    defp table_ref(%{table_name: table_name}), do: Presentation.secondary_ref(table_name, 30)
    defp table_ref(_change), do: Presentation.secondary_ref("", 30)

    defp routeable_row_ref(change) do
      case routeable_row_identity(change) do
        {_table, record_id} -> record_id
        nil -> nil
      end
    end

    defp safe_row_history_path(base_path, change, schemas)
         when is_binary(base_path) and is_map(schemas) do
      case routeable_row_identity(change) do
        {table, record_id} ->
          if schema_for_table(schemas, table) do
            "#{base_path}/rows/#{encode_segment(table)}/#{encode_segment(record_id)}"
          end

        nil ->
          nil
      end
    end

    defp safe_row_history_path(_base_path, _change, _schemas), do: nil

    defp schema_for_table(schemas, table) when is_map(schemas) do
      case Map.fetch(schemas, table) do
        {:ok, schema} ->
          schema

        :error ->
          Enum.find_value(schemas, fn
            {key, schema} when is_atom(key) ->
              if Atom.to_string(key) == table, do: schema

            _entry ->
              nil
          end)
      end
    end

    defp routeable_row_identity(%{table_name: table, table_pk: table_pk}),
      do: routeable_row_identity(table, table_pk)

    defp routeable_row_identity(%{change_diff: %{} = diff}) do
      table = Map.get(diff, "table_name") || Map.get(diff, :table_name)
      table_pk = Map.get(diff, "table_pk") || Map.get(diff, :table_pk)

      routeable_row_identity(table, table_pk)
    end

    defp routeable_row_identity(_change), do: nil

    defp routeable_row_identity(table, %{} = table_pk) when is_binary(table) do
      table = String.trim(table)

      with true <- table != "",
           [{_key, value}] <- Map.to_list(table_pk),
           true <- routeable_row_value?(value) do
        {table, to_string(value)}
      else
        _ -> nil
      end
    end

    defp routeable_row_identity(_table, _table_pk), do: nil

    defp routeable_row_value?(value) when is_binary(value), do: String.trim(value) != ""
    defp routeable_row_value?(value) when is_integer(value), do: true
    defp routeable_row_value?(value) when is_float(value), do: true
    defp routeable_row_value?(_value), do: false

    defp encode_segment(value), do: URI.encode(to_string(value), &URI.char_unreserved?/1)

    # Renders the match count for the status line:
    # - At/above the cap (10_001) → "10,000+" (capped approximation per D-17 + RESEARCH §P-8)
    # - Below the cap → exact integer with thousands separators
    defp format_count(count) when is_integer(count) do
      cond do
        count >= 10_001 ->
          "10,000+"

        true ->
          count
          |> Integer.to_string()
          |> String.reverse()
          |> String.codepoints()
          |> Enum.chunk_every(3)
          |> Enum.map(&Enum.join/1)
          |> Enum.join(",")
          |> String.reverse()
      end
    end

    defp filter_window_summary(%{} = raw) do
      from_raw = Map.get(raw, "from", "")
      to_raw = Map.get(raw, "to", "")

      with {:ok, %DateTime{} = from} <- parse_window_datetime(from_raw),
           {:ok, %DateTime{} = to} <- parse_window_datetime(to_raw) do
        detail = "#{format_window_datetime(from)} to #{format_window_datetime(to)}"

        %{
          label: window_duration_label(from, to),
          detail: detail,
          title: detail
        }
      else
        {:ok, nil} ->
          partial_window_summary(from_raw, to_raw)

        {:error, _reason} ->
          %{
            label: "Custom",
            detail: "Invalid date value",
            title: "Invalid date value"
          }
      end
    end

    defp filter_window_summary(_), do: default_window_summary()

    defp active_filter_pairs(%{} = raw) do
      raw
      |> Map.take(["table", "table_schema", "actor_kind", "actor_id", "correlation_id"])
      |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
      |> Enum.map(fn {key, value} -> {filter_label(key), value} end)
    end

    defp active_filter_pairs(_), do: []

    defp advanced_filter_count(%{} = raw) do
      raw
      |> Map.take(["table_schema", "actor_kind", "actor_id"])
      |> Enum.count(fn {_key, value} -> is_binary(value) and value != "" end)
    end

    defp advanced_filter_count(_), do: 0

    defp parse_window_datetime(value) when value in [nil, ""], do: {:ok, nil}

    defp parse_window_datetime(value) when is_binary(value) do
      padded =
        cond do
          String.ends_with?(value, "Z") -> value
          String.length(value) == 16 -> value <> ":00Z"
          String.length(value) == 19 -> value <> "Z"
          true -> value
        end

      case DateTime.from_iso8601(padded) do
        {:ok, dt, _offset} -> {:ok, dt}
        _ -> {:error, :invalid_datetime}
      end
    end

    defp parse_window_datetime(_), do: {:error, :invalid_datetime}

    defp partial_window_summary("", ""), do: default_window_summary()

    defp partial_window_summary(from_raw, "") when is_binary(from_raw) do
      case parse_window_datetime(from_raw) do
        {:ok, %DateTime{} = from} ->
          detail = "From #{format_window_datetime(from)}"
          %{label: "From", detail: detail, title: detail}

        _ ->
          %{label: "Custom", detail: "Invalid date value", title: "Invalid date value"}
      end
    end

    defp partial_window_summary("", to_raw) when is_binary(to_raw) do
      case parse_window_datetime(to_raw) do
        {:ok, %DateTime{} = to} ->
          detail = "Until #{format_window_datetime(to)}"
          %{label: "Until", detail: detail, title: detail}

        _ ->
          %{label: "Custom", detail: "Invalid date value", title: "Invalid date value"}
      end
    end

    defp partial_window_summary(_from_raw, _to_raw),
      do: %{label: "Custom", detail: "Invalid date value", title: "Invalid date value"}

    defp default_window_summary do
      %{
        label: "Last 24h",
        detail: "Default rolling window",
        title: "Default rolling 24 hour window"
      }
    end

    defp window_duration_label(%DateTime{} = from, %DateTime{} = to) do
      seconds = DateTime.diff(to, from, :second)

      cond do
        seconds == @default_window_hours * 3600 ->
          "24h"

        seconds > 0 and rem(seconds, 86_400) == 0 and seconds <= 86_400 * 14 ->
          "#{div(seconds, 86_400)}d"

        seconds > 0 and rem(seconds, 3600) == 0 and seconds < 86_400 ->
          "#{div(seconds, 3600)}h"

        true ->
          "Custom"
      end
    end

    defp format_window_datetime(%DateTime{} = dt) do
      "#{dt.year}-#{pad2(dt.month)}-#{pad2(dt.day)} #{pad2(dt.hour)}:#{pad2(dt.minute)} UTC"
    end

    defp pad2(value) when is_integer(value) and value < 10, do: "0#{value}"
    defp pad2(value) when is_integer(value), do: Integer.to_string(value)

    defp filter_label("table_schema"), do: "host schema"
    defp filter_label("actor_kind"), do: "actor kind"
    defp filter_label("actor_id"), do: "actor id"
    defp filter_label("correlation_id"), do: "correlation id"
    defp filter_label(key), do: key

    defp invalid_filter_message(message) do
      target = invalid_filter_target(message)

      "Timeline filters could not be applied. Fix the #{target} filter, then apply filters again. #{message}"
    end

    defp invalid_filter_target(message) when is_binary(message) do
      cond do
        String.contains?(message, "correlation_id") -> "correlation id"
        String.contains?(message, "actor_kind") -> "actor kind"
        String.contains?(message, "actor_id") -> "actor id"
        String.contains?(message, "table_schema") -> "host schema"
        String.contains?(message, "table") -> "table"
        String.contains?(message, "from") or String.contains?(message, "to") -> "time window"
        true -> "named"
      end
    end

    defp invalid_filter_target(_message), do: "named"

    defp unknown_table_message(table, audited_tables) do
      table_name =
        table
        |> to_string()
        |> String.trim()
        |> case do
          "" -> "selected table"
          value -> value
        end

      base =
        "Table filter `#{table_name}` is not audited. Select an audited table or clear the table filter."

      case audited_tables do
        [] -> base
        tables -> base <> " Audited tables: " <> Enum.join(tables, ", ")
      end
    end

    # Distinguish the two ok-empty states (D-17): a first-run empty (no narrowing
    # filter beyond the time window) is `never` (history icon); a filtered-but-empty
    # result is `no_data` (funnel icon). AsyncResult/empty cannot make this call —
    # the page author branches it from whether a narrowing filter is active.
    @timeline_narrowing_filters ~w(table table_schema actor_kind actor_id correlation_id)

    defp timeline_filters_active?(%{} = raw) do
      Enum.any?(@timeline_narrowing_filters, fn key ->
        value = Map.get(raw, key)
        is_binary(value) and String.trim(value) != ""
      end)
    end

    defp timeline_filters_active?(_), do: false

    defp timeline_empty_reason(_raw, true), do: :future_window

    defp timeline_empty_reason(raw, false),
      do: if(timeline_filters_active?(raw), do: :filtered, else: :first_run)

    defp timeline_empty_variant(raw, future_window_empty) do
      case timeline_empty_reason(raw, future_window_empty) do
        :filtered -> "no_data"
        _ -> "never"
      end
    end

    defp timeline_empty_icon(raw, future_window_empty) do
      case timeline_empty_reason(raw, future_window_empty) do
        :filtered -> :funnel
        _ -> :history
      end
    end

    defp timeline_empty_title(raw, future_window_empty) do
      case timeline_empty_reason(raw, future_window_empty) do
        :future_window -> "No captured changes in this time window"
        :first_run -> "No captured changes in this window"
        :filtered -> "No captured changes match this window"
      end
    end

    defp timeline_empty_body(raw, future_window_empty) do
      case timeline_empty_reason(raw, future_window_empty) do
        :future_window ->
          "This window has no matching changes, but Threadline has audit data outside it. Move the window back toward recent activity or clear filters."

        :first_run ->
          "No audit changes were captured in this window. Reset to last 24h or widen the time range."

        :filtered ->
          "Widen the time range, or clear the table filter to search every audited table. Scoped views only show records you are authorized to see."
      end
    end

    defp timeline_empty_action_label(raw, future_window_empty) do
      case timeline_empty_reason(raw, future_window_empty) do
        :first_run -> "Reset to last 24h"
        _ -> "Clear filters"
      end
    end

    defp future_window_empty?(_filters, count, _socket) when count != 0, do: false

    defp future_window_empty?(filters, 0, socket) do
      if future_leaning_window?(filters) do
        filters
        |> Keyword.drop([:from, :to])
        |> Export.count_matching(count_opts(socket, 1))
        |> case do
          {:ok, %{count: count}} -> count > 0
          _ -> false
        end
      else
        false
      end
    end

    defp future_leaning_window?(filters) do
      now = DateTime.utc_now()

      filters
      |> Keyword.take([:from, :to])
      |> Enum.any?(fn {_key, value} ->
        match?(%DateTime{}, value) and DateTime.compare(value, now) == :gt
      end)
    end

    defp coverage_warning?(%{uncovered_count: count}) when is_integer(count), do: count > 0
    defp coverage_warning?(_), do: false

    defp coverage_summary(%{uncovered_count: count}) when is_integer(count) and count > 0 do
      "#{count} need capture"
    end

    defp coverage_summary(%{uncovered_count: 0}), do: "All captured"
    defp coverage_summary(_), do: "Not enabled"

    defp op_row_modifier(op) do
      case op |> to_string() |> String.downcase() do
        "insert" -> "tl-change--insert"
        "update" -> "tl-change--update"
        "delete" -> "tl-change--delete"
        _ -> nil
      end
    end

    defp safe_validate(filters) do
      try do
        Threadline.Query.validate_timeline_filters!(filters)
        :ok
      rescue
        e in ArgumentError -> {:error, e.message}
      end
    end

    defp build_canonical_query(%{} = raw), do: FilterParams.canonical_query(raw)

    defp background_export_error_message(:supervisor_not_started) do
      "Background export could not start because the built-in export runtime is unavailable."
    end

    defp background_export_error_message(reason) do
      "Background export could not start: #{inspect(reason)}."
    end

    defp terminal_export_expiry do
      retention_ttl_hours =
        Application.get_env(:threadline, :exports, [])
        |> Keyword.get(:retention_ttl_hours, 24 * 7)

      DateTime.utc_now()
      |> DateTime.truncate(:microsecond)
      |> DateTime.add(retention_ttl_hours * 60 * 60, :second)
    end
  end
end
