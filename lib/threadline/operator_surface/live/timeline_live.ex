if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive do
    @moduledoc false
    use Phoenix.LiveView
    import Ecto.Query

    alias Threadline.Export
    alias Threadline.OperatorSurface.Exports.FilterParams
    alias Threadline.Query

    @page_size 50
    @filter_keys ~w(from to table actor_kind actor_id correlation_id)
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
      # until the next page load. Phase 66 will introduce a polled coverage source we can
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
            )
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
        |> assign(:base_path, nil)
        |> assign(:match_count, 0)
        |> assign(:filter_query, "")

      {:ok, socket}
    end

    # --------------------------------------------------------------------------
    # handle_params/3
    # --------------------------------------------------------------------------

    def handle_params(params, uri, socket) do
      uri_parsed = URI.parse(uri)
      base_path = uri_parsed.path
      socket = assign(socket, :base_path, base_path)

      if params == %{} do
        from = DateTime.utc_now() |> DateTime.add(-@default_window_hours * 3600, :second)
        to = DateTime.utc_now()

        query_string =
          URI.encode_query([
            {"from", DateTime.to_iso8601(from) |> String.slice(0..15)},
            {"to", DateTime.to_iso8601(to) |> String.slice(0..15)}
          ])

        {:noreply, push_patch(socket, to: "#{base_path}?#{query_string}", replace: true)}
      else
        socket = assign(socket, :filters_raw, FilterParams.filters_raw_from_params(params))

        case FilterParams.parse(params) do
          {:error, message} ->
            socket =
              socket
              |> assign(:form_error, message)
              |> assign(:filters, [])
              |> assign(:cursor, nil)
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
                    Export.count_matching(filters, cap: 10_001, repo: socket.assigns.repo)
                  end)

                page_task =
                  Task.async(fn ->
                    Query.timeline_page(filters, scope_aware_opts(socket))
                  end)

                # Two parallel queries; await with a generous timeout.
                # Default Task.await is 5_000 ms; bump to 8_000 to leave headroom for
                # slow capped-count queries on large tables (RESEARCH §P-7 line 651).
                {:ok, %{count: count}} = Task.await(count_task, 8_000)
                page = Task.await(page_task, 8_000)

                filter_query = build_canonical_query(socket.assigns.filters_raw)

                socket =
                  socket
                  |> assign(:filters, filters)
                  |> assign(:form_error, nil)
                  |> assign(:unknown_table_attempted, unknown_table_attempted)
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
        
        case socket.assigns.repo.insert(changeset) do
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
        nil -> {:noreply, socket}
        view ->
          query = build_canonical_query(view.filters)
          {:noreply, push_patch(socket, to: "#{socket.assigns.base_path}?#{query}")}
      end
    end

    def handle_event("delete-view", %{"id" => id}, socket) do
      case Enum.find(socket.assigns.saved_views, &(&1.id == id)) do
        nil -> {:noreply, socket}
        view ->
          socket.assigns.repo.delete!(view)
          saved_views = Enum.reject(socket.assigns.saved_views, &(&1.id == id))
          {:noreply, assign(socket, :saved_views, saved_views)}
      end
    end

    def handle_event("apply", %{"filter" => raw}, socket) do
      query = build_canonical_query(raw)
      {:noreply, push_patch(socket, to: "#{socket.assigns.base_path}?#{query}")}
    end

    def handle_event("apply", _params, socket) do
      {:noreply, push_patch(socket, to: socket.assigns.base_path)}
    end

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
      <div class="threadline-ui">
        <Threadline.OperatorSurface.Style.css />
        <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
          coverage={@threadline_coverage}
          base_path={@base_path}
          error={@threadline_coverage_error}
        />

        <header class="timeline-toolbar">
          <form id="timeline-filters" phx-submit="apply" role="search">
            <label>From
              <input type="datetime-local" name="filter[from]" id="filter-from"
                     aria-label="from" value={@filters_raw["from"] || ""} phx-debounce="blur" />
            </label>
            <label>To
              <input type="datetime-local" name="filter[to]" id="filter-to"
                     aria-label="to" value={@filters_raw["to"] || ""} phx-debounce="blur" />
            </label>
            <label>Table
              <input type="text" list="audited-tables" name="filter[table]" id="filter-table"
                     aria-label="table" value={@filters_raw["table"] || ""} phx-debounce="blur" />
              <datalist id="audited-tables">
                <option :for={name <- @audited_tables} value={name}></option>
              </datalist>
            </label>
            <label>Actor kind
              <select name="filter[actor_kind]" id="filter-actor-kind" aria-label="actor kind">
                <option value="">Any kind</option>
                <option :for={k <- ~w(user admin service_account job system anonymous)}
                        value={k} selected={@filters_raw["actor_kind"] == k}><%= k %></option>
              </select>
            </label>
            <label>Actor id
              <input type="text" name="filter[actor_id]" id="filter-actor-id"
                     aria-label="actor id"
                     value={@filters_raw["actor_id"] || ""}
                     disabled={@filters_raw["actor_kind"] == "anonymous"}
                     phx-debounce="blur" />
            </label>
            <label>Correlation id
              <input type="text" name="filter[correlation_id]" id="filter-correlation-id"
                     aria-label="correlation id"
                     value={@filters_raw["correlation_id"] || ""}
                     maxlength="256" phx-debounce="300" />
              <small>request_id, job_id, or integration token. Up to 256 chars.</small>
            </label>
            <div class="button-cluster">
              <.link patch={@base_path} class="clear-link">Clear all</.link>
              <button type="submit">Apply</button>
              <.link href={"#{@base_path}/exports/changes.csv?#{@filter_query}"} download class="download-button">Download CSV</.link>
              <.link href={"#{@base_path}/exports/changes.json?#{@filter_query}"} download class="download-button">Download JSON</.link>
              <.link href={"#{@base_path}/exports/changes.ndjson?#{@filter_query}"} download class="download-button">Download NDJSON</.link>
            </div>
          </form>
          <%= if assigns[:threadline_actor_ref] do %>
            <div class="saved-views-toolbar">
              <form id="save-view-form" phx-submit="save-view" class="save-view-form">
                <input type="text" name="name" placeholder="Name this view..." aria-label="View name" required />
                <button type="submit">Save View</button>
              </form>
              <div class="saved-views-list" :if={@saved_views != []}>
                <strong>Saved Views:</strong>
                <ul class="saved-views-ul">
                  <li :for={view <- @saved_views} class="saved-view-item">
                    <button phx-click="apply-view" phx-value-id={view.id} type="button" class="apply-view-btn"><%= view.name %></button>
                    <button phx-click="delete-view" phx-value-id={view.id} type="button" class="delete-view-btn" aria-label={"Delete " <> view.name}>&times;</button>
                  </li>
                </ul>
              </div>
            </div>
          <% end %>
        </header>

        <%= if @form_error do %>
          <div class="filter-error" role="alert"><%= @form_error %></div>
        <% end %>

        <%= if Enum.empty?(@streams.changes.inserts) and @unknown_table_attempted do %>
          <div class="filter-hint">
            No rows found for this table. Audited tables: <%= Enum.join(@audited_tables, ", ") %>
          </div>
        <% end %>

        <div class="match-count-status" role="status">
          Showing <%= length(@streams.changes.inserts) %> of <%= format_count(@match_count) %> matches in this window.
        </div>

        <%= if @match_count > 5_000 and @match_count < 10_001 do %>
          <div class="truncation-banner informational" role="status">
            Large export — will stream in chunks.
          </div>
        <% end %>

        <%= if @match_count >= 10_001 do %>
          <div class="truncation-banner warning" role="alert">
            Truncated to first 10,000 rows. Use `mix threadline.export --max-rows N` for the full window.
          </div>
        <% end %>

        <section class="timeline-rows" id="timeline-rows" phx-update="stream"
                 phx-viewport-bottom={@cursor && "next-page"}>
          <div :for={{dom_id, change} <- @streams.changes} id={dom_id} class="change-row">
            <div class="change-header">
              <span class="change-op"><%= change.op %></span>
              <span class="change-table"><%= change.table_name %></span>
              <span class="change-time"><%= change.captured_at %></span>
              <a href={"#{@base_path}/transactions/#{change.transaction_id}"} class="tx-link">View Incident</a>
            </div>
          </div>
        </section>
        <div :if={@cursor == nil and Enum.empty?(@streams.changes.inserts)}
             class="empty-state">
          No changes match these filters in the selected window.
        </div>
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

    defp default_repo do
      Application.get_env(:threadline, :ecto_repos) |> hd()
    end

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

    defp safe_validate(filters) do
      try do
        Threadline.Query.validate_timeline_filters!(filters)
        :ok
      rescue
        e in ArgumentError -> {:error, e.message}
      end
    end

    defp build_canonical_query(%{} = raw) do
      raw
      |> normalize_anonymous()
      |> Enum.filter(fn {k, v} -> k in @filter_keys and is_binary(v) and v != "" end)
      |> Enum.sort_by(fn {k, _v} -> Enum.find_index(@filter_keys, &(&1 == k)) end)
      |> URI.encode_query()
    end

    defp normalize_anonymous(%{"actor_kind" => "anonymous"} = raw),
      do: Map.delete(raw, "actor_id")

    defp normalize_anonymous(raw), do: raw
  end
end
