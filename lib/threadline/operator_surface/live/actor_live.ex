if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.ActorLive do
    use Phoenix.LiveView

    def mount(%{"kind" => kind, "id" => id}, _session, socket) do
      repo =
        socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

      type =
        try do
          String.to_existing_atom(kind)
        rescue
          ArgumentError -> String.to_atom(kind)
        end

      case Threadline.Semantics.ActorRef.new(type, id) do
        {:ok, actor_ref} ->
          from_time = DateTime.utc_now() |> DateTime.add(-24, :hour)

          page =
            Threadline.actor_history(actor_ref,
              repo: repo,
              from: from_time,
              scope: socket.assigns[:threadline_scope],
              scope_query_fn: socket.assigns[:threadline_scope_query_fn],
              surface: :actor_history,
              params: %{actor_ref: actor_ref, from: from_time}
            )

          has_ever_acted =
            if Enum.empty?(page.entries) do
              case Threadline.actor_history(actor_ref,
                     repo: repo,
                     limit: 1,
                     scope: socket.assigns[:threadline_scope],
                     scope_query_fn: socket.assigns[:threadline_scope_query_fn],
                     surface: :actor_history,
                     params: %{actor_ref: actor_ref}
                   ) do
                %{entries: []} -> false
                _ -> true
              end
            else
              true
            end

          {:ok,
           socket
           |> assign(:not_found, false)
           |> assign(:actor_ref, actor_ref)
           |> assign(:repo, repo)
           |> assign(:from_time, from_time)
           |> assign(:time_window_hours, 24)
           |> assign(:has_ever_acted, has_ever_acted)
           |> assign(:next_cursor, page.next_cursor)
           |> assign(:prev_cursor, page.prev_cursor)
           |> stream_configure(:transactions, dom_id: fn tx -> "tx-#{tx.id}" end)
           |> stream(:transactions, page.entries)}

        {:error, _} ->
          {:ok, assign(socket, :not_found, true)}
      end
    end

    def handle_params(_params, uri, socket) do
      uri_parsed = URI.parse(uri)

      base_path =
        case Regex.run(~r/(.*)\/actors\/[^\/]+\/[^\/]+/, uri_parsed.path) do
          [_, path] -> path
          _ -> uri_parsed.path
        end

      {:noreply, assign(socket, :base_path, base_path)}
    end

    def render(assigns) do
      ~H"""
      <div class="threadline-ui">
        <Threadline.OperatorSurface.Style.css />
        <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
          coverage={@threadline_coverage}
          base_path={@base_path}
          error={@threadline_coverage_error}
          coverage_enabled={@threadline_coverage_enabled}
          policy_enabled={@threadline_policy_enabled}
          evidence_enabled={@threadline_evidence_enabled}
          exports_enabled={@threadline_exports_enabled}
          current={:timeline}
        />
        <%= if @not_found do %>
          <div class="tl-empty tl-empty--error">
            <.link patch={@base_path} class="tl-link tl-link--back">← Timeline</.link>
            <p class="tl-empty__body">Invalid Actor Reference</p>
          </div>
        <% else %>
          <div class="tl-transaction">
            <a href={@base_path} class="tl-link tl-link--back">← Timeline</a>
            <h2 class="tl-transaction__title">Actor: <%= @actor_ref.type %> / <%= @actor_ref.id %></h2>
            <div class="tl-nav" role="group" aria-label="Actor activity window">
              Showing last
              <a href="#" phx-click="set-window" phx-value-hours="1" class={time_window_class(@time_window_hours, 1)}>1h</a>
              <a href="#" phx-click="set-window" phx-value-hours="24" class={time_window_class(@time_window_hours, 24)}>24h</a>
              <a href="#" phx-click="set-window" phx-value-hours="168" class={time_window_class(@time_window_hours, 168)}>7d</a>
              <a href="#" phx-click="set-window" phx-value-hours="720" class={time_window_class(@time_window_hours, 720)}>30d</a>
            </div>
          </div>

          <%= if not @has_ever_acted do %>
            <div class="tl-empty tl-empty--never">
              <p class="tl-empty__body">This actor has never recorded any events.</p>
            </div>
          <% else %>
            <%= if @has_ever_acted and Enum.empty?(@streams.transactions.inserts) do %>
              <div class="tl-empty">
                <p class="tl-empty__body">No events found in the selected time window.</p>
              </div>
            <% else %>
              <div
                id="transactions-list"
                phx-update="stream"
                phx-viewport-top="prev-page"
                phx-viewport-bottom="next-page"
                class="tl-viewport"
              >
                <div :for={{dom_id, tx} <- @streams.transactions} id={dom_id} class="tl-change" data-testid="actor-transaction-row">
                  <div class="tl-change__summary">
                    <div class="tl-change__meta">
                      <span class="tl-change__time"><%= tx.occurred_at %></span>
                    </div>
                    <div class="tl-meta-row">
                      <span>Transaction <code><%= tx.id %></code></span>
                    </div>
                    <div class="tl-change__actions">
                      <a href={"#{@base_path}/transactions/#{tx.id}"} class="tl-link tl-link--deep" data-testid="transaction-link">View transaction</a>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        <% end %>
      </div>
      """
    end

    def handle_event("set-window", %{"hours" => hours_str}, socket) do
      hours = String.to_integer(hours_str)
      from_time = DateTime.utc_now() |> DateTime.add(-hours, :hour)

      page =
        Threadline.actor_history(socket.assigns.actor_ref,
          repo: socket.assigns.repo,
          from: from_time,
          scope: socket.assigns[:threadline_scope],
          scope_query_fn: socket.assigns[:threadline_scope_query_fn],
          surface: :actor_history,
          params: %{actor_ref: socket.assigns.actor_ref, from: from_time}
        )

      {:noreply,
       socket
       |> assign(:time_window_hours, hours)
       |> assign(:from_time, from_time)
       |> assign(:next_cursor, page.next_cursor)
       |> assign(:prev_cursor, page.prev_cursor)
       |> stream(:transactions, page.entries, reset: true)}
    end

    def handle_event("next-page", _, socket) do
      if socket.assigns.next_cursor do
        page =
          Threadline.actor_history(socket.assigns.actor_ref,
            repo: socket.assigns.repo,
            from: socket.assigns.from_time,
            after: socket.assigns.next_cursor,
            scope: socket.assigns[:threadline_scope],
            scope_query_fn: socket.assigns[:threadline_scope_query_fn],
            surface: :actor_history,
            params: %{
              actor_ref: socket.assigns.actor_ref,
              from: socket.assigns.from_time,
              after: socket.assigns.next_cursor
            }
          )

        {:noreply,
         socket
         |> assign(:next_cursor, page.next_cursor)
         |> stream(:transactions, page.entries, at: -1)}
      else
        {:noreply, socket}
      end
    end

    def handle_event("prev-page", _, socket) do
      if socket.assigns.prev_cursor do
        page =
          Threadline.actor_history(socket.assigns.actor_ref,
            repo: socket.assigns.repo,
            from: socket.assigns.from_time,
            before: socket.assigns.prev_cursor,
            scope: socket.assigns[:threadline_scope],
            scope_query_fn: socket.assigns[:threadline_scope_query_fn],
            surface: :actor_history,
            params: %{
              actor_ref: socket.assigns.actor_ref,
              from: socket.assigns.from_time,
              before: socket.assigns.prev_cursor
            }
          )

        {:noreply,
         socket
         |> assign(:prev_cursor, page.prev_cursor)
         |> stream(:transactions, page.entries, at: 0)}
      else
        {:noreply, socket}
      end
    end

    defp time_window_class(current, value) do
      if current == value do
        "tl-chip tl-chip--accent"
      else
        "tl-chip tl-chip--muted"
      end
    end
  end
end
