if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive do
    @moduledoc false
    use Phoenix.LiveView

    alias Threadline.Query
    alias Threadline.Semantics.ActorRef

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

      socket =
        socket
        |> stream_configure(:changes, dom_id: fn change -> "change-#{change.id}" end)
        |> stream(:changes, [])
        |> assign(:repo, repo)
        |> assign(:scope, scope)
        |> assign(:audited_tables, audited_tables)
        |> assign(:cursor, nil)
        |> assign(:filters, [])
        |> assign(:filters_raw, %{})
        |> assign(:form_error, nil)
        |> assign(:unknown_table_attempted, false)
        |> assign(:base_path, nil)

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
        socket = assign(socket, :filters_raw, filters_raw_from_params(params))

        case build_filters(params) do
          {:error, message} ->
            socket =
              socket
              |> assign(:form_error, message)
              |> assign(:filters, [])
              |> assign(:cursor, nil)
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

                page = Query.timeline_page(filters, scope_aware_opts(socket))

                socket =
                  socket
                  |> assign(:filters, filters)
                  |> assign(:form_error, nil)
                  |> assign(:unknown_table_attempted, unknown_table_attempted)
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
            </div>
          </form>
        </header>

        <%= if @form_error do %>
          <div class="filter-error" role="alert"><%= @form_error %></div>
        <% end %>

        <%= if Enum.empty?(@streams.changes.inserts) and @unknown_table_attempted do %>
          <div class="filter-hint">
            No rows found for this table. Audited tables: <%= Enum.join(@audited_tables, ", ") %>
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
          <div :if={@cursor == nil and Enum.empty?(@streams.changes.inserts)}
               class="empty-state">
            No changes match these filters in the selected window.
          </div>
        </section>
      </div>
      """
    end

    # --------------------------------------------------------------------------
    # Private helpers
    # --------------------------------------------------------------------------

    defp scope_aware_opts(socket) do
      base = [repo: socket.assigns.repo, page_size: @page_size]

      case socket.assigns.scope do
        nil -> base
        scope -> Keyword.merge(base, scope_to_query_opts(scope))
      end
    end

    # Phase 64 passthrough — extension point for v1.19+ scope-derived predicates.
    defp scope_to_query_opts(_scope), do: []

    defp default_repo do
      Application.get_env(:threadline, :ecto_repos) |> hd()
    end

    defp filters_raw_from_params(params) do
      raw = %{
        "from" => params["from"] || "",
        "to" => params["to"] || "",
        "table" => params["table"] || "",
        "actor_kind" => params["actor_kind"] || "",
        "actor_id" => params["actor_id"] || "",
        "correlation_id" => params["correlation_id"] || ""
      }

      # Mirror the actor_kind=anonymous strip-id normalization so the form
      # echoes the canonical (post-strip) URL, not the user-typed pre-strip URL.
      case raw["actor_kind"] do
        "anonymous" -> Map.put(raw, "actor_id", "")
        _ -> raw
      end
    end

    defp normalize_params(params) do
      for {key, value} <- params,
          key in @filter_keys,
          is_binary(value),
          value != "",
          into: [] do
        {String.to_existing_atom(key), value}
      end
    end

    defp parse_datetimes(filters) do
      Enum.reduce_while(filters, {:ok, []}, fn
        {:from, val}, {:ok, acc} ->
          case parse_datetime_local(val) do
            {:ok, nil} -> {:cont, {:ok, acc}}
            {:ok, dt} -> {:cont, {:ok, [{:from, dt} | acc]}}
            {:error, _} -> {:halt, {:error, "invalid datetime: #{val}"}}
          end

        {:to, val}, {:ok, acc} ->
          case parse_datetime_local(val) do
            {:ok, nil} -> {:cont, {:ok, acc}}
            {:ok, dt} -> {:cont, {:ok, [{:to, dt} | acc]}}
            {:error, _} -> {:halt, {:error, "invalid datetime: #{val}"}}
          end

        other, {:ok, acc} ->
          {:cont, {:ok, [other | acc]}}
      end)
      |> case do
        {:ok, filters} -> {:ok, Enum.reverse(filters)}
        error -> error
      end
    end

    defp collapse_actor_ref(filters) do
      actor_kind = Keyword.get(filters, :actor_kind)
      actor_id = Keyword.get(filters, :actor_id)

      filters_without_actor_params =
        filters
        |> Keyword.delete(:actor_kind)
        |> Keyword.delete(:actor_id)

      cond do
        actor_kind == "anonymous" ->
          actor_ref = %ActorRef{type: :anonymous, id: nil}
          {:ok, Keyword.put(filters_without_actor_params, :actor_ref, actor_ref)}

        is_binary(actor_kind) and actor_kind != "" and is_binary(actor_id) and actor_id != "" ->
          case safe_actor_kind(actor_kind) do
            {:ok, kind_atom} ->
              case ActorRef.new(kind_atom, actor_id) do
                {:ok, actor_ref} ->
                  {:ok, Keyword.put(filters_without_actor_params, :actor_ref, actor_ref)}

                {:error, :unknown_actor_type} ->
                  {:error, "unknown actor kind: " <> inspect(actor_kind)}

                {:error, :missing_actor_id} ->
                  {:error, "actor id is required for non-anonymous actors"}
              end

            {:error, :unknown_actor_type} ->
              {:error, "unknown actor kind: " <> inspect(actor_kind)}
          end

        is_binary(actor_kind) and actor_kind != "" ->
          # kind supplied but no id — leave without actor_ref filter
          {:ok, filters_without_actor_params}

        true ->
          {:ok, filters_without_actor_params}
      end
    end

    defp build_filters(params) do
      with normalized <- normalize_params(params),
           {:ok, with_datetimes} <- parse_datetimes(normalized),
           {:ok, with_actor_ref} <- collapse_actor_ref(with_datetimes) do
        {:ok, with_actor_ref}
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

    defp parse_datetime_local(nil), do: {:ok, nil}
    defp parse_datetime_local(""), do: {:ok, nil}

    defp parse_datetime_local(str) when is_binary(str) do
      padded = if String.length(str) == 16, do: str <> ":00Z", else: str <> "Z"

      case DateTime.from_iso8601(padded) do
        {:ok, dt, _offset} -> {:ok, dt}
        _ -> {:error, :invalid_datetime}
      end
    end

    defp safe_actor_kind(kind) when is_binary(kind) do
      try do
        {:ok, String.to_existing_atom(kind)}
      rescue
        ArgumentError -> {:error, :unknown_actor_type}
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
