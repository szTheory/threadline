if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive do
    @moduledoc false
    use Phoenix.LiveView

    # The timeline owns forms for its primary query controls (the filter toolbar)
    # and for saving the current view.
    Module.register_attribute(__MODULE__, :ui_form_policy, persist: true)
    @ui_form_policy {:has_forms, "filter toolbar and saved-view form"}

    import Ecto.Query

    alias Threadline.Export
    alias Threadline.Governance.ExportJob
    alias Threadline.Governance.SavedView
    alias Threadline.OperatorSurface.Live.TimelineLive.Filters
    alias Threadline.OperatorSurface.Live.TimelineLive.Helpers
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI
    alias Threadline.Query
    alias Threadline.Query.FilterParams
    alias Threadline.Semantics.ActorRef
    alias Threadline.StorageSchema

    @page_size 50

    def mount(_params, _session, socket) do
      repo =
        socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

      # Bracket form — the scope assign is nil unless the operator's :authorize_fn
      # returns {:ok, scope} (see `Threadline.OperatorSurface.Auth`).
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
        if ActorRef.identifiable?(actor_ref) do
          repo.all(
            from(v in SavedView,
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
        from = DateTime.utc_now() |> DateTime.add(-Helpers.default_window_hours() * 3600, :second)
        to = DateTime.utc_now()

        query_string =
          URI.encode_query([
            {"from", DateTime.to_iso8601(from) |> String.slice(0..15)},
            {"to", DateTime.to_iso8601(to) |> String.slice(0..15)}
          ])

        {:noreply, push_patch(socket, to: "#{timeline_path}?#{query_string}", replace: true)}
      else
        socket = assign(socket, :filters_raw, FilterParams.filters_raw_from_params(params))

        with {:ok, filters} <- FilterParams.parse(params),
             :ok <- safe_validate(filters) do
          {:noreply, load_filtered_page(socket, filters)}
        else
          {:error, message} -> {:noreply, filter_error(socket, message)}
        end
      end
    end

    defp filter_error(socket, message) do
      filter_query = build_canonical_query(socket.assigns.filters_raw)

      socket
      |> assign(:form_error, message)
      |> assign(:filters, [])
      |> assign(:cursor, nil)
      |> assign(:future_window_empty, false)
      |> assign(:match_count, 0)
      |> assign(:shown_count, 0)
      |> assign(:filter_query, filter_query)
      |> stream(:changes, [], reset: true)
    end

    defp load_filtered_page(socket, filters) do
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

      page_opts = scope_aware_opts(socket)

      page_task = Task.async(fn -> Query.timeline_page(filters, page_opts) end)

      # Two parallel queries; await with a generous timeout.
      # Default Task.await is 5_000 ms; use 8_000 to leave headroom for
      # capped-count queries on large tables.
      {:ok, %{count: count}} = Task.await(count_task, 8_000)

      page =
        page_task
        |> Task.await(8_000)
        |> preload_visible_context(socket.assigns.repo, scope_aware_opts(socket))

      filter_query = build_canonical_query(socket.assigns.filters_raw)
      future_window_empty = future_window_empty?(filters, count, socket)

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
    end

    def handle_event("save-view", %{"name" => name}, socket) do
      if ActorRef.identifiable?(socket.assigns[:threadline_actor_ref]) and name != "" do
        attrs = %{
          name: name,
          actor_ref: ActorRef.to_map(socket.assigns.threadline_actor_ref),
          filters: socket.assigns.filters_raw
        }

        changeset = SavedView.changeset(attrs)

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
          %{
            assigns: %{
              threadline_exports_enabled: true,
              threadline_scope: scope,
              threadline_export_scope: export_scope,
              threadline_actor_ref: %ActorRef{type: actor_type, id: actor_id}
            }
          } = socket
        )
        when actor_type != :anonymous and is_binary(actor_id) and actor_id != "" and
               (not is_nil(scope) or not is_nil(export_scope)) do
      {:noreply,
       put_flash(
         socket,
         :error,
         "Scoped background exports are unavailable. Use a scoped CSV, JSON, or NDJSON download instead."
       )}
    end

    def handle_event(
          "request_background_export",
          _params,
          %{
            assigns: %{
              threadline_exports_enabled: true,
              threadline_actor_ref: %ActorRef{type: actor_type, id: actor_id} = actor_ref
            }
          } = socket
        )
        when actor_type != :anonymous and is_binary(actor_id) and actor_id != "" do
      repo = scope_aware_opts(socket)[:repo] || default_repo()

      job_changeset =
        ExportJob.operator_changeset(%{
          status: "pending",
          query_params: Map.new(socket.assigns.filters, fn {k, v} -> {to_string(k), v} end),
          actor_ref: actor_ref
        })

      storage_schema = StorageSchema.get()

      job =
        repo.insert!(job_changeset, StorageSchema.repo_opts(storage_schema: storage_schema))

      adapter =
        Application.get_env(
          :threadline,
          :export_queue_adapter,
          Threadline.ExportQueue.TaskAdapter
        )

      case adapter.enqueue(job.id, storage_schema: storage_schema) do
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
          |> ExportJob.changeset(%{
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

    def render(assigns) do
      ~H"""
      <UI.Page.shell
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
          <Filters.timeline_command
            filters_raw={@filters_raw}
            audited_tables={@audited_tables}
            match_count={@match_count}
            coverage={assigns[:threadline_coverage]}
            timeline_path={@timeline_path}
          />

        <%= if @form_error do %>
          <div class="tl-alert tl-alert--error" role="alert">
            <%= Helpers.invalid_filter_message(@form_error) %>
          </div>
        <% end %>

        <%= if Enum.empty?(@streams.changes.inserts) and @unknown_table_attempted do %>
          <div class="tl-alert tl-alert--info" role="status">
            <%= Helpers.unknown_table_message(@filters_raw["table"], @audited_tables) %>
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

        <.change_list
          changes={@streams.changes}
          cursor={@cursor}
          base_path={@base_path}
          timeline_path={@timeline_path}
          schemas={assigns[:threadline_schemas]}
        />
        <UI.Page.pager
          shown={@shown_count}
          match_count={@match_count}
          has_older={@cursor != nil}
          has_newer={false}
          older_event="next-page"
          newer_event={nil}
        />
        <UI.Data.empty_state
          :if={@cursor == nil and Enum.empty?(@streams.changes.inserts)}
          variant={Helpers.timeline_empty_variant(@filters_raw, @future_window_empty)}
          role="status"
          icon={Helpers.timeline_empty_icon(@filters_raw, @future_window_empty)}
        >
          <:title><%= Helpers.timeline_empty_title(@filters_raw, @future_window_empty) %></:title>
          <%= Helpers.timeline_empty_body(@filters_raw, @future_window_empty) %>
          <:actions>
            <.link patch={@timeline_path} class="tl-button tl-button--secondary">
              <Threadline.OperatorSurface.Components.Icon.icon name={:filter_x} class="tl-button__icon" />
              <%= Helpers.timeline_empty_action_label(@filters_raw, @future_window_empty) %>
            </.link>
          </:actions>
        </UI.Data.empty_state>
        <Filters.timeline_filter_drawer
          filters_raw={@filters_raw}
          coverage_enabled={@threadline_coverage_enabled}
          evidence_enabled={@threadline_evidence_enabled}
          exports_enabled={@threadline_exports_enabled}
          actor_ref={assigns[:threadline_actor_ref]}
          saved_views={@saved_views}
          base_path={@base_path}
          filter_query={@filter_query}
          export_ready={is_nil(@form_error)}
          background_export_ready={
              is_nil(@form_error) and is_nil(@scope) and
              is_nil(assigns[:threadline_export_scope]) and
              ActorRef.identifiable?(assigns[:threadline_actor_ref])
          }
        />
      </UI.Page.shell>
      """
    end

    attr(:changes, :any, required: true)
    attr(:cursor, :any, default: nil)
    attr(:base_path, :string, required: true)
    attr(:timeline_path, :string, required: true)
    attr(:schemas, :map, default: nil)

    defp change_list(assigns) do
      ~H"""
      <section class="tl-change-list" id="timeline-rows" phx-update="stream"
               phx-viewport-bottom={@cursor && "next-page"}
               data-testid="operator-timeline">
        <div :for={{dom_id, change} <- @changes} id={dom_id} class={["tl-change", Helpers.op_row_modifier(change.op)]} data-testid="timeline-row">
          <div class="tl-change__summary">
            <div class="tl-change__meta">
              <span class={["tl-change__op", Presentation.operation_modifier(change.op)]}><%= Presentation.operation_label(change.op) %></span>
              <span
                class="tl-change__table tl-secondary-ref"
                title={Helpers.table_ref(change).title}
                data-tl-copy={Helpers.table_ref(change).title}
              >
                <%= Helpers.table_ref(change).visible %>
              </span>
              <time class="tl-change__time" datetime={Presentation.exact_time(change.captured_at)} title={Presentation.exact_time(change.captured_at)}>
                <%= Presentation.human_time(change.captured_at) %>
              </time>
            </div>
            <div class="tl-meta">
              <span>
                Actor
                <%= if Helpers.actor_label(change) != "unknown" do %>
                  <UI.Display.ref value={Helpers.actor_label(change)} kind="actor" copy_label="Copy actor ref" />
                  <a
                    :if={path = Helpers.actor_path(@base_path, change)}
                    href={path}
                    class="tl-link tl-link--deep"
                    title="View actor activity"
                  >
                    <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
                    Actor timeline
                  </a>
                <% else %>
                  <code><%= Helpers.actor_label(change) %></code>
                <% end %>
              </span>
              <span :if={Helpers.correlation_id(change)}>
                Correlation
                <UI.Display.ref value={Helpers.correlation_id(change)} kind="correlation" copy_label="Copy correlation id" />
                <a href={Helpers.correlation_path(@timeline_path, Helpers.correlation_id(change))} class="tl-link tl-link--deep" title="View correlated changes in Timeline">
                  <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
                  Timeline
                </a>
              </span>
              <span :if={row_id = Helpers.routeable_row_ref(change)}>
                Row
                <UI.Display.ref value={row_id} kind="uuid" copy_label="Copy row id" />
              </span>
            </div>
            <div class="tl-change__actions">
              <a href={"#{@base_path}/transactions/#{change.transaction_id}"} class="tl-button tl-button--compact tl-button--secondary" data-testid="transaction-link">
                <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
                Open transaction
              </a>
              <a
                :if={row_history_path = Helpers.safe_row_history_path(@base_path, change, @schemas)}
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
      """
    end

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

    defp future_window_empty?(_filters, count, _socket) when count != 0, do: false

    defp future_window_empty?(filters, 0, socket) do
      if future_leaning_window?(filters) do
        {:ok, %{count: count}} =
          filters
          |> Keyword.drop([:from, :to])
          |> Export.count_matching(count_opts(socket, 1))

        count > 0
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

    defp safe_validate(filters) do
      Threadline.Query.validate_timeline_filters!(filters)
      :ok
    rescue
      e in ArgumentError -> {:error, e.message}
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
