if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive do
    @moduledoc false
    use Phoenix.LiveView
    import Ecto.Query

    alias Threadline.Export
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.Exports.FilterParams
    alias Threadline.Query
    alias Threadline.StorageSchema

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
            StorageSchema.repo_opts()
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
            socket =
              socket
              |> assign(:form_error, message)
              |> assign(:filters, [])
              |> assign(:cursor, nil)
              |> assign(:future_window_empty, false)
              |> assign(:match_count, 0)
              |> assign(:filter_query, "")
              |> stream(:changes, [], reset: true)

            {:noreply, socket}

          {:ok, filters} ->
            case safe_validate(filters) do
              {:error, message} ->
                socket =
                  socket
                  |> assign(:form_error, message)
                  |> assign(:filters, [])
                  |> assign(:cursor, nil)
                  |> assign(:future_window_empty, false)
                  |> assign(:match_count, 0)
                  |> assign(:filter_query, "")
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
                  |> preload_visible_context(socket.assigns.repo)

                filter_query = build_canonical_query(socket.assigns.filters_raw)
                future_window_empty = future_window_empty?(filters, count, socket)

                socket =
                  socket
                  |> assign(:filters, filters)
                  |> assign(:form_error, nil)
                  |> assign(:unknown_table_attempted, unknown_table_attempted)
                  |> assign(:future_window_empty, future_window_empty)
                  |> assign(:match_count, count)
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

        case socket.assigns.repo.insert(changeset, StorageSchema.repo_opts()) do
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
          socket.assigns.repo.delete!(view, StorageSchema.repo_opts())
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
          %{assigns: %{threadline_exports_enabled: true}} = socket
        ) do
      repo = scope_aware_opts(socket)[:repo] || default_repo()

      job = %Threadline.Governance.ExportJob{
        status: "pending",
        query_params: Map.new(socket.assigns.filters, fn {k, v} -> {to_string(k), v} end),
        actor_ref: socket.assigns[:threadline_actor_ref]
      }

      job = repo.insert!(job, StorageSchema.repo_opts())

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
          |> repo.update!(StorageSchema.repo_opts())

          {:noreply, put_flash(socket, :error, error_message)}
      end
    end

    def handle_event("request_background_export", _params, socket), do: {:noreply, socket}

    def handle_event("next-page", _, socket) do
      if socket.assigns.cursor do
        page =
          Query.timeline_page(
            socket.assigns.filters,
            repo: scope_aware_opts(socket)[:repo] || default_repo(),
            scope: socket.assigns[:threadline_scope],
            page_size: 50,
            cursor: socket.assigns.cursor
          )
          |> preload_visible_context(socket.assigns.repo)

        {:noreply,
         socket
         |> assign(:cursor, page.next_cursor)
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
      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
        <Threadline.OperatorSurface.Style.css />
        <Threadline.OperatorSurface.Script.js />
        <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
          coverage={assigns[:threadline_coverage] || %{uncovered_count: 0}}
          base_path={@base_path}
          error={assigns[:threadline_coverage_error]}
          coverage_enabled={@threadline_coverage_enabled}
          policy_enabled={@threadline_policy_enabled}
          evidence_enabled={@threadline_evidence_enabled}
          exports_enabled={@threadline_exports_enabled}
          current={:timeline}
          scoped={not is_nil(assigns[:threadline_scope])}
        />

        <main id="tl-main" class="tl-page tl-page--intro" tabindex="-1">
          <section class="tl-orientation tl-orientation--investigation" aria-label="Investigation starting point">
            <div class="tl-orientation__header">
              <div>
                <h1 class="tl-orientation__title">Investigate audit activity</h1>
                <p class="tl-orientation__lede">
                  Start with a window, table, actor, or correlation id. Check readiness before treating results as exhaustive, then open a transaction to reconstruct what changed together.
                </p>
              </div>
              <div class="tl-orientation__actions">
                <a :if={@threadline_coverage_enabled and @base_path} href={"#{@base_path}/coverage"} class="tl-button tl-button--secondary">
                  Check coverage
                </a>
                <a :if={@threadline_evidence_enabled and @base_path} href={"#{@base_path}/evidence"} class="tl-button tl-button--secondary">
                  Review evidence
                </a>
              </div>
            </div>

            <section class="tl-summary-grid" aria-label="Current investigation summary">
              <div class="tl-card--metric" data-status="info">
                <span class="tl-card__metric-label">Current window</span>
                <strong class="tl-card__metric"><%= filter_window_label(@filters_raw) %></strong>
              </div>
              <div class="tl-card--metric">
                <span class="tl-card__metric-label">Matching changes</span>
                <strong class="tl-card__metric"><%= format_count(@match_count) %></strong>
              </div>
              <div class="tl-card--metric" data-status={if coverage_warning?(assigns[:threadline_coverage]), do: "warning"}>
                <span class="tl-card__metric-label">Audit readiness</span>
                <strong class="tl-card__metric"><%= coverage_summary(assigns[:threadline_coverage]) %></strong>
              </div>
            </section>

          </section>

          <header class="tl-toolbar">
          <form id="timeline-filters" phx-submit="apply" role="search" class="tl-toolbar__form">
            <label class="tl-toolbar__field">From
              <input type="datetime-local" name="filter[from]" id="filter-from"
                     aria-label="from" value={@filters_raw["from"] || ""} phx-debounce="blur" class="tl-toolbar__control" />
            </label>
            <label class="tl-toolbar__field">To
              <input type="datetime-local" name="filter[to]" id="filter-to"
                     aria-label="to" value={@filters_raw["to"] || ""} phx-debounce="blur" class="tl-toolbar__control" />
            </label>
             <label class="tl-toolbar__field">Table
               <input type="text" list="audited-tables" name="filter[table]" id="filter-table"
                      aria-label="table" value={@filters_raw["table"] || ""} phx-debounce="blur" class="tl-toolbar__control" />
               <datalist id="audited-tables">
                 <option :for={name <- @audited_tables} value={name}></option>
               </datalist>
             </label>
             <label class="tl-toolbar__field">Schema
               <input type="text" name="filter[table_schema]" id="filter-table-schema"
                      aria-label="table schema" value={@filters_raw["table_schema"] || ""} phx-debounce="blur" class="tl-toolbar__control" />
             </label>
             <label class="tl-toolbar__field">Actor kind
              <select name="filter[actor_kind]" id="filter-actor-kind" aria-label="actor kind" class="tl-toolbar__control">
                <option value="">Any kind</option>
                <option :for={k <- ~w(user admin service_account job system anonymous)}
                        value={k} selected={@filters_raw["actor_kind"] == k}><%= k %></option>
              </select>
            </label>
            <label class="tl-toolbar__field">Actor id
              <input type="text" name="filter[actor_id]" id="filter-actor-id"
                     aria-label="actor id"
                     value={@filters_raw["actor_id"] || ""}
                     disabled={@filters_raw["actor_kind"] == "anonymous"}
                     phx-debounce="blur" class="tl-toolbar__control" />
              <small :if={@filters_raw["actor_kind"] == "anonymous"} class="tl-toolbar__hint">n/a for anonymous</small>
            </label>
            <label class="tl-toolbar__field tl-toolbar__field--wide">Correlation id
              <input type="text" name="filter[correlation_id]" id="filter-correlation-id"
                     aria-label="correlation id"
                     value={@filters_raw["correlation_id"] || ""}
                     maxlength="256" phx-debounce="300" class="tl-toolbar__control" />
              <small class="tl-toolbar__hint">request_id, job_id, or integration token. Up to 256 chars.</small>
            </label>
            <div class="tl-toolbar__actions">
              <div class="tl-action-group">
                <.link patch={@timeline_path} class="tl-button tl-button--ghost">Clear all</.link>
                <button type="submit" class="tl-button tl-button--primary">Apply</button>
              </div>
              <%= if @threadline_exports_enabled do %>
                <div class="tl-action-group tl-action-group--secondary" aria-label="Export actions">
                  <button phx-click="request_background_export" type="button" class="tl-button tl-button--quiet-primary">Queue export</button>
                  <.link
                    navigate={"#{@base_path}/exports?#{@filter_query}"}
                    class="tl-button tl-button--compact tl-button--secondary"
                    data-earned-flow="EF3"
                    data-persona="P3"
                    data-jtbd="J6"
                  >
                    Carry to Exports
                  </.link>
                  <.link href={"#{@base_path}/exports/changes.csv?#{@filter_query}"} download class="tl-button tl-button--compact tl-button--secondary">CSV</.link>
                  <.link href={"#{@base_path}/exports/changes.json?#{@filter_query}"} download class="tl-button tl-button--compact tl-button--secondary">JSON</.link>
                  <.link href={"#{@base_path}/exports/changes.ndjson?#{@filter_query}"} download class="tl-button tl-button--compact tl-button--secondary">NDJSON</.link>
                </div>
              <% end %>
            </div>
          </form>
          <%= if assigns[:threadline_actor_ref] do %>
            <div class="tl-toolbar__saved-views">
              <form id="save-view-form" phx-submit="save-view" class="tl-nav">
                <input type="text" name="name" placeholder="Name this view..." aria-label="View name" required class="tl-control" />
                <button type="submit" class="tl-button tl-button--secondary">Save View</button>
              </form>
              <div class="tl-nav" :if={@saved_views != []}>
                <strong>Saved Views:</strong>
                <ul class="tl-toolbar__saved-list">
                  <li :for={view <- @saved_views} class="tl-toolbar__saved-item">
                    <button phx-click="apply-view" phx-value-id={view.id} type="button" class="tl-button tl-button--secondary"><%= view.name %></button>
                    <button phx-click="delete-view" phx-value-id={view.id} type="button" class="tl-button tl-button--ghost tl-button--danger tl-button--icon" aria-label={"Delete " <> view.name}>&times;</button>
                  </li>
                </ul>
              </div>
            </div>
          <% end %>
        </header>

        <%= if @form_error do %>
          <div class="tl-alert tl-alert--error" role="alert">
            <%= invalid_filter_message(@form_error) %>
          </div>
        <% end %>

        <%= if Enum.empty?(@streams.changes.inserts) and @unknown_table_attempted do %>
          <div class="tl-alert tl-alert--info">
            No rows found for this table. Audited tables: <%= Enum.join(@audited_tables, ", ") %>
          </div>
        <% end %>

        <div class="tl-status" role="status">
          <%= length(@streams.changes.inserts) %> shown · <%= format_count(@match_count) %> matches · current filter window
        </div>

        <section class="tl-filter-summary" aria-label="Active Timeline filters">
          <strong>Active filters</strong>
          <span>Window: <%= filter_window_label(@filters_raw) %></span>
          <span :for={{label, value} <- active_filter_pairs(@filters_raw)} class="tl-chip tl-chip--neutral">
            <%= label %>: <%= value %>
          </span>
          <span :if={active_filter_pairs(@filters_raw) == []}>No table, actor, or correlation filter</span>
        </section>

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
                <span class="tl-change__table tl-secondary-ref" title={table_ref(change).title}>
                  <%= table_ref(change).visible %>
                </span>
                <time class="tl-change__time" datetime={Presentation.exact_time(change.captured_at)} title={Presentation.exact_time(change.captured_at)}>
                  <%= Presentation.human_time(change.captured_at) %>
                </time>
              </div>
              <div class="tl-meta">
                <span>
                  Actor
                  <%= if path = actor_path(@base_path, change) do %>
                    <a href={path} class="tl-link tl-link--deep"><code><%= actor_label(change) %></code></a>
                  <% else %>
                    <code><%= actor_label(change) %></code>
                  <% end %>
                </span>
                <span :if={correlation_id(change)}>
                  Correlation
                  <a href={correlation_path(@timeline_path, correlation_id(change))} class="tl-link tl-link--deep" title={correlation_ref(change).title}>
                    <code class="tl-secondary-ref"><%= correlation_ref(change).visible %></code>
                  </a>
                  <button :if={Threadline.OperatorSurface.Script.enabled?()} type="button" class="tl-copy" data-tl-copy={correlation_id(change)} aria-label="Copy correlation id">Copy</button>
                </span>
              </div>
              <div class="tl-change__actions">
                <a href={"#{@base_path}/transactions/#{change.transaction_id}"} class="tl-button tl-button--compact tl-button--secondary" data-testid="transaction-link">Open transaction</a>
              </div>
            </div>
          </div>
        </section>
        <div :if={@cursor == nil and Enum.empty?(@streams.changes.inserts)}
             class="tl-empty">
          <h3 class="tl-empty__title"><%= empty_title(@future_window_empty) %></h3>
          <p class="tl-empty__body"><%= empty_body(@future_window_empty) %></p>
          <div class="tl-empty__actions">
            <.link patch={@timeline_path} class="tl-button tl-button--secondary">Clear filters</.link>
          </div>
        </div>
        <aside class="tl-journey--legend" aria-label="Investigation journey">
          <p>
            <strong>FIND</strong> filter the timeline ·
            <strong>EXPLAIN</strong> open transaction and row history ·
            <strong>PACKAGE</strong> queue or download the current export
          </p>
        </aside>
        </main>
      </div>
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
        params: %{filters: socket.assigns.filters}
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

    defp preload_visible_context(%{entries: entries} = page, repo) do
      %{page | entries: repo.preload(entries, transaction: :action)}
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

    defp correlation_ref(change), do: Presentation.secondary_ref(correlation_id(change), 34)

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

    defp filter_window_label(%{} = raw) do
      non_window_filter? =
        raw
        |> Map.drop(["from", "to"])
        |> Enum.any?(fn {_key, value} -> is_binary(value) and value != "" end)

      cond do
        non_window_filter? -> "Filtered"
        raw["from"] not in [nil, ""] and raw["to"] not in [nil, ""] -> "24h window"
        true -> "Last 24h"
      end
    end

    defp filter_window_label(_), do: "Last 24h"

    defp active_filter_pairs(%{} = raw) do
      raw
      |> Map.take(["table", "actor_kind", "actor_id", "correlation_id"])
      |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
      |> Enum.map(fn {key, value} -> {filter_label(key), value} end)
    end

    defp active_filter_pairs(_), do: []

    defp filter_label("actor_kind"), do: "actor kind"
    defp filter_label("actor_id"), do: "actor id"
    defp filter_label("correlation_id"), do: "correlation id"
    defp filter_label(key), do: key

    defp invalid_filter_message(message) do
      "Timeline filters could not be applied. Fix the highlighted value, then apply filters again. #{message}"
    end

    defp empty_title(true), do: "No captured changes in this time window"
    defp empty_title(false), do: "No captured changes match this window"

    defp empty_body(true) do
      "This window has no matching changes, but Threadline has audit data outside it. Move the window back toward recent activity or clear filters."
    end

    defp empty_body(false) do
      "Widen the time range, or clear the table filter to search every audited table. Scoped views only show records you are authorized to see."
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
