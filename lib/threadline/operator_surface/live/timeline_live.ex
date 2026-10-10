if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive do
    @moduledoc false
    use Phoenix.LiveView

    # The timeline owns forms for its primary query controls (the filter toolbar)
    # and for saving the current search.
    Module.register_attribute(__MODULE__, :ui_form_policy, persist: true)
    @ui_form_policy {:has_forms, "filter toolbar and saved-search form"}

    import Ecto.Query

    alias Threadline.Governance.ExportJob
    alias Threadline.Governance.SavedView
    alias Threadline.OperatorSurface.Live.TimelineLive.Changes
    alias Threadline.OperatorSurface.Live.TimelineLive.Filters
    alias Threadline.OperatorSurface.Live.TimelineLive.Helpers
    alias Threadline.OperatorSurface.UI
    alias Threadline.Query
    alias Threadline.Query.ExportReads
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
        |> assign(:saved_search_error, nil)
        |> assign(:pending_delete_view, nil)
        |> assign(:cursor, nil)
        |> assign(:filters, [])
        |> assign(:filters_raw, %{})
        |> assign(:search_url, "")
        |> assign(:form_error, nil)
        |> assign(:query_error, false)
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

        {:noreply,
         socket
         |> assign(:search_url, timeline_path)
         |> push_patch(to: "#{timeline_path}?#{query_string}", replace: true)}
      else
        filters_raw = FilterParams.filters_raw_from_params(params)
        filter_query = build_canonical_query(filters_raw)

        search_url =
          if filter_query == "", do: timeline_path, else: "#{timeline_path}?#{filter_query}"

        socket =
          socket
          |> assign(:filters_raw, filters_raw)
          |> assign(:filter_query, filter_query)
          |> assign(:search_url, search_url)
          |> assign(:saved_search_error, nil)

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
      |> assign(:query_error, false)
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

      # Scope callbacks must receive the query being applied, never the previous
      # result's filters. Clear the cursor before resetting the stream.
      socket = socket |> assign(:filters, filters) |> assign(:cursor, nil)

      try do
        page_opts = scope_aware_opts(socket)

        # Two parallel queries; await with a generous timeout. A query failure must
        # not crash the LiveView or leave partial rows attached to the new filter.
        # async_stream owns cleanup if a query raises, times out, or the consumer exits.
        results =
          Task.Supervisor.async_stream_nolink(
            Threadline.Export.TaskSupervisor,
            [:count, :page],
            fn
              :count ->
                safe_query(fn ->
                  ExportReads.count_matching(filters, count_opts(socket, 10_001))
                end)

              :page ->
                safe_query(fn -> Query.timeline_page(filters, page_opts) end)
            end,
            max_concurrency: 2,
            ordered: true,
            timeout: 8_000,
            on_timeout: :kill_task
          )
          |> Enum.to_list()

        case results do
          [
            {:ok, {:ok, {:ok, %{count: count}}}},
            {:ok, {:ok, page}}
          ] ->
            page = preload_visible_context(page, socket.assigns.repo, scope_aware_opts(socket))
            filter_query = build_canonical_query(socket.assigns.filters_raw)
            future_window_empty = future_window_empty?(filters, count, socket)

            socket
            |> assign(:filters, filters)
            |> assign(:form_error, nil)
            |> assign(:query_error, false)
            |> assign(:unknown_table_attempted, unknown_table_attempted)
            |> assign(:future_window_empty, future_window_empty)
            |> assign(:match_count, count)
            |> assign(:shown_count, length(page.entries))
            |> assign(:filter_query, filter_query)
            |> stream(:changes, page.entries, reset: true)
            |> assign(:cursor, page.cursor)

          _failed_or_timed_out ->
            query_error(socket)
        end
      rescue
        _error -> query_error(socket)
      catch
        _kind, _reason -> query_error(socket)
      end
    end

    defp safe_query(query_fn) do
      {:ok, query_fn.()}
    rescue
      _error -> {:error, :query_failed}
    catch
      _kind, _reason -> {:error, :query_failed}
    end

    defp query_error(socket) do
      filter_query = build_canonical_query(socket.assigns.filters_raw)

      socket
      |> assign(:form_error, nil)
      |> assign(:query_error, true)
      |> assign(:unknown_table_attempted, false)
      |> assign(:future_window_empty, false)
      |> assign(:match_count, nil)
      |> assign(:shown_count, 0)
      |> assign(:filter_query, filter_query)
      |> assign(:cursor, nil)
      |> stream(:changes, [], reset: true)
    end

    def handle_event("save-view", %{"name" => name}, socket) do
      actor_ref = socket.assigns[:threadline_actor_ref]
      name = if is_binary(name), do: String.trim(name), else: ""

      cond do
        not ActorRef.identifiable?(actor_ref) ->
          saved_search_error(socket, "Sign in as a recognized actor to save searches.")

        name == "" ->
          saved_search_error(socket, "Enter a name for this saved search.")

        not is_nil(socket.assigns.form_error) ->
          saved_search_error(socket, "Fix Timeline filters before saving this search.")

        true ->
          attrs = %{
            name: name,
            actor_ref: ActorRef.to_map(actor_ref),
            filters: canonical_filters(socket.assigns.filters_raw)
          }

          changeset = SavedView.changeset(attrs)

          try do
            case socket.assigns.repo.insert(changeset, storage_opts(socket)) do
              {:ok, view} ->
                socket =
                  socket
                  |> assign(:saved_views, [view | socket.assigns.saved_views])
                  |> assign(:saved_search_error, nil)

                {:noreply, socket}

              {:error, _changeset} ->
                saved_search_error(
                  socket,
                  "Could not save this search. Check the name and try again."
                )
            end
          rescue
            _error -> saved_search_error(socket, "Could not save this search. Try again.")
          catch
            _kind, _reason -> saved_search_error(socket, "Could not save this search. Try again.")
          end
      end
    end

    def handle_event("apply-view", %{"id" => id}, socket) do
      case Enum.find(socket.assigns.saved_views, &(&1.id == id)) do
        nil ->
          {:noreply, socket}

        view ->
          query = build_canonical_query(view.filters)

          path =
            if query == "",
              do: socket.assigns.timeline_path,
              else: "#{socket.assigns.timeline_path}?#{query}"

          {:noreply,
           socket
           |> assign(:saved_search_error, nil)
           |> push_patch(to: path)}
      end
    end

    def handle_event("delete-view", %{"id" => id}, socket) do
      actor_ref = socket.assigns[:threadline_actor_ref]

      if ActorRef.identifiable?(actor_ref) do
        case Enum.find(socket.assigns.saved_views, &(&1.id == id)) do
          %SavedView{} = view ->
            {:noreply,
             socket
             |> assign(:pending_delete_view, view)
             |> assign(:saved_search_error, nil)}

          _ ->
            {:noreply, socket}
        end
      else
        {:noreply, socket}
      end
    end

    def handle_event("close-delete-view", _params, socket) do
      {:noreply, assign(socket, :pending_delete_view, nil)}
    end

    def handle_event("confirm-delete-view", _params, socket) do
      actor_ref = socket.assigns[:threadline_actor_ref]
      pending = socket.assigns[:pending_delete_view]

      if ActorRef.identifiable?(actor_ref) and match?(%SavedView{}, pending) do
        try do
          case owned_saved_view(socket, pending.id, actor_ref) do
            nil ->
              saved_search_error(socket, "This saved search is no longer available.")

            view ->
              case socket.assigns.repo.delete(view, storage_opts(socket)) do
                {:ok, _deleted} ->
                  socket =
                    socket
                    |> assign(
                      :saved_views,
                      Enum.reject(socket.assigns.saved_views, &(&1.id == view.id))
                    )
                    |> assign(:pending_delete_view, nil)
                    |> assign(:saved_search_error, nil)

                  {:noreply, socket}

                {:error, _changeset} ->
                  saved_search_error(socket, "Could not delete this saved search. Try again.")
              end
          end
        rescue
          _error -> saved_search_error(socket, "Could not delete this saved search. Try again.")
        catch
          _kind, _reason ->
            saved_search_error(socket, "Could not delete this saved search. Try again.")
        end
      else
        {:noreply, assign(socket, :pending_delete_view, nil)}
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
         |> assign(:cursor, page.cursor)
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

        <Filters.query_feedback
          form_error={@form_error}
          query_error={@query_error}
          timeline_path={@timeline_path}
          filter_query={@filter_query}
          empty_changes={Enum.empty?(@streams.changes.inserts)}
          unknown_table_attempted={@unknown_table_attempted}
          filters_raw={@filters_raw}
          audited_tables={@audited_tables}
          match_count={@match_count}
        />

        <Changes.change_list
          changes={@streams.changes}
          cursor={@cursor}
          base_path={@base_path}
          timeline_path={@timeline_path}
          schemas={assigns[:threadline_schemas]}
          filters_raw={@filters_raw}
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
          :if={not @query_error and @cursor == nil and Enum.empty?(@streams.changes.inserts)}
          variant={Helpers.timeline_empty_variant(@filters_raw, @future_window_empty)}
          role="status"
          icon={Helpers.timeline_empty_icon(@filters_raw, @future_window_empty)}
        >
          <:title>
            <%= if field_filtered_query?(@filters_raw) and not @future_window_empty, do: "No changes match these filters", else: Helpers.timeline_empty_title(@filters_raw, @future_window_empty) %>
          </:title>
          <%= if field_filtered_query?(@filters_raw) and not @future_window_empty do %>
            Adjust the time range or filters, then apply again.
            <span :if={@scope}>Scoped views only show records you are authorized to see.</span>
          <% else %>
            <%= Helpers.timeline_empty_body(@filters_raw, @future_window_empty) %>
          <% end %>
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
          search_url={@search_url}
          base_path={@base_path}
          filter_query={@filter_query}
          export_ready={is_nil(@form_error)}
          background_export_ready={
              is_nil(@form_error) and is_nil(@scope) and
              is_nil(assigns[:threadline_export_scope]) and
              ActorRef.identifiable?(assigns[:threadline_actor_ref])
          }
        />
        <div :if={@saved_search_error && is_nil(@pending_delete_view)} class="tl-alert tl-alert--error" role="alert">
          <%= @saved_search_error %>
        </div>
        <.saved_search_delete_modal
          :if={@pending_delete_view}
          view={@pending_delete_view}
          error={@saved_search_error}
        />
      </UI.Page.shell>
      """
    end

    attr(:view, :map, required: true)
    attr(:error, :string, default: nil)

    defp saved_search_delete_modal(assigns) do
      ~H"""
      <UI.Overlay.modal id="saved-search-delete-confirm" show={true} on_cancel={Phoenix.LiveView.JS.push("close-delete-view")}>
        <h2 id="saved-search-delete-confirm-title" class="tl-modal__title">Delete saved search</h2>
        <p id="saved-search-delete-confirm-description" class="tl-modal__body">
          Delete saved search “<%= @view.name %>”? This removes it from your saved searches.
        </p>
        <div :if={@error} class="tl-alert tl-alert--error" role="alert"><%= @error %></div>
        <div class="tl-modal__actions">
          <button type="button" class="tl-button tl-button--secondary" phx-click="close-delete-view">
            Keep saved search
          </button>
          <button type="button" class="tl-button tl-button--danger" phx-click="confirm-delete-view" data-tl-mutating>
            <Threadline.OperatorSurface.Components.Icon.icon name={:trash} class="tl-button__icon" />
            Delete search
          </button>
        </div>
      </UI.Overlay.modal>
      """
    end

    defp saved_search_error(socket, message) do
      {:noreply, assign(socket, :saved_search_error, message)}
    end

    defp canonical_filters(filters_raw) do
      filters_raw
      |> build_canonical_query()
      |> URI.decode_query()
    end

    defp owned_saved_view(socket, id, actor_ref) do
      socket.assigns.repo.get_by(
        SavedView,
        [id: id, actor_ref: actor_ref],
        storage_opts(socket)
      )
    end

    defp field_filtered_query?(filters_raw) do
      Enum.any?(["table_schema", "table", "actor_kind", "actor_id", "correlation_id"], fn key ->
        value = Map.get(filters_raw, key)
        is_binary(value) and value != ""
      end)
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
        | entries:
            entries
            |> repo.preload([:transaction], StorageSchema.repo_opts(opts))
            |> Threadline.Query.hydrate_actions(repo, opts)
      }
    end

    defp future_window_empty?(_filters, count, _socket) when count != 0, do: false

    defp future_window_empty?(filters, 0, socket) do
      if future_leaning_window?(filters) do
        {:ok, %{count: count}} =
          filters
          |> Keyword.drop([:from, :to])
          |> ExportReads.count_matching(count_opts(socket, 1))

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
