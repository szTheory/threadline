if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.ActorLive do
    use Phoenix.LiveView
    import Ecto.Query

    alias Threadline.Capture.AuditChange
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.StorageSchema

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

          {has_ever_acted, last_activity} =
            if Enum.empty?(page.entries) do
              case Threadline.actor_history(actor_ref,
                     repo: repo,
                     limit: 1,
                     scope: socket.assigns[:threadline_scope],
                     scope_query_fn: socket.assigns[:threadline_scope_query_fn],
                     surface: :actor_history,
                     params: %{actor_ref: actor_ref}
                   ) do
                %{entries: [latest | _]} -> {true, latest.occurred_at}
                _ -> {false, nil}
              end
            else
              {true, nil}
            end

          actor_summaries = actor_summaries(page.entries, repo, socket.assigns[:threadline_scope])

          {:ok,
           socket
           |> assign(:not_found, false)
           |> assign(:actor_ref, actor_ref)
           |> assign(:repo, repo)
           |> assign(:actor_summaries, actor_summaries)
           |> assign(:from_time, from_time)
           |> assign(:time_window_hours, 24)
           |> assign(:has_ever_acted, has_ever_acted)
           |> assign(:last_activity, last_activity)
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
      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
        <Threadline.OperatorSurface.Style.css />
        <Threadline.OperatorSurface.Script.js />
        <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
          coverage={@threadline_coverage}
          base_path={@base_path}
          error={@threadline_coverage_error}
          coverage_enabled={@threadline_coverage_enabled}
          policy_enabled={@threadline_policy_enabled}
          evidence_enabled={@threadline_evidence_enabled}
          exports_enabled={@threadline_exports_enabled}
          current={:timeline}
          scoped={not is_nil(assigns[:threadline_scope])}
        />
        <main id="tl-main" class="tl-page" tabindex="-1">
        <%= if @not_found do %>
          <div class="tl-empty tl-empty--error">
            <h3 class="tl-empty__title">Invalid Actor Reference</h3>
            <p class="tl-empty__body">This actor kind and id cannot be parsed as a Threadline actor reference.</p>
            <div class="tl-empty__actions">
              <.link navigate={"#{@base_path}/timeline"} class="tl-button tl-button--secondary">
                <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_left} class="tl-button__icon" />
                Timeline
              </.link>
            </div>
          </div>
        <% else %>
          <div class="tl-transaction">
            <nav class="tl-transaction__breadcrumbs" aria-label="Investigation path">
              <a href={"#{@base_path}/timeline"} class="tl-link tl-link--back">← Timeline</a>
              <span>Actor</span>
            </nav>
            <div class="tl-page__header">
              <div>
                <h1 class="tl-transaction__title">Actor: <%= @actor_ref.type %> / <%= @actor_ref.id %></h1>
                <p class="tl-page__lede">Review what this actor touched in a time window, then open a transaction to inspect row-level changes.</p>
                <a href={timeline_actor_path(@base_path, @actor_ref)} class="tl-link tl-link--deep">Open in timeline to filter and export →</a>
              </div>
              <div class="tl-segmented" role="group" aria-label="Actor activity window">
                <button type="button" phx-click="set-window" phx-value-hours="1" aria-pressed={pressed_state(@time_window_hours, 1)} class="tl-segmented__item">1h</button>
                <button type="button" phx-click="set-window" phx-value-hours="24" aria-pressed={pressed_state(@time_window_hours, 24)} class="tl-segmented__item">24h</button>
                <button type="button" phx-click="set-window" phx-value-hours="168" aria-pressed={pressed_state(@time_window_hours, 168)} class="tl-segmented__item">7d</button>
                <button type="button" phx-click="set-window" phx-value-hours="720" aria-pressed={pressed_state(@time_window_hours, 720)} class="tl-segmented__item">30d</button>
              </div>
            </div>
          </div>

          <%= if not @has_ever_acted do %>
            <div class="tl-empty tl-empty--never">
              <h3 class="tl-empty__title">No actor activity recorded</h3>
              <p class="tl-empty__body">This actor has never recorded any events.</p>
            </div>
          <% else %>
            <%= if @has_ever_acted and Enum.empty?(@streams.transactions.inserts) do %>
              <div class="tl-empty">
                <h3 class="tl-empty__title">No events in this window</h3>
                <p class="tl-empty__body">No events found in the selected time window.<%= if @last_activity do %> This actor was last active <%= Presentation.human_time(@last_activity) %>.<% end %></p>
                <div class="tl-empty__actions">
                  <button :if={@time_window_hours != 720} type="button" phx-click="set-window" phx-value-hours="720" class="tl-button tl-button--secondary">
                    <Threadline.OperatorSurface.Components.Icon.icon name={:history} class="tl-button__icon" />
                    Widen to 30 days
                  </button>
                  <a href={timeline_actor_path(@base_path, @actor_ref)} class="tl-button tl-button--ghost">
                    <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
                    Open in timeline
                  </a>
                </div>
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
                      <span class="tl-actor-summary"><%= Map.get(@actor_summaries, tx.id, Presentation.actor_transaction_summary(nil)) %></span>
                      <time class="tl-change__time" datetime={Presentation.exact_time(tx.occurred_at)} title={Presentation.exact_time(tx.occurred_at)}>
                        <%= Presentation.human_time(tx.occurred_at) %>
                      </time>
                    </div>
                    <div class="tl-meta">
                      <% tx_ref = Presentation.secondary_ref(tx.id, 24) %>
                      <span>Transaction <code class="tl-secondary-ref" title={tx_ref.title}><%= tx_ref.visible %></code></span>
                      <button :if={Threadline.OperatorSurface.Script.enabled?()} type="button" class="tl-copy" data-tl-copy={tx.id} aria-label="Copy transaction id">Copy</button>
                    </div>
                    <div class="tl-change__actions">
                      <a href={"#{@base_path}/transactions/#{tx.id}"} class="tl-button tl-button--compact tl-button--secondary" data-testid="transaction-link">
                        <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
                        Open transaction
                      </a>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        <% end %>
        </main>
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

      actor_summaries =
        actor_summaries(page.entries, socket.assigns.repo, socket.assigns[:threadline_scope])

      {:noreply,
       socket
       |> assign(:time_window_hours, hours)
       |> assign(:from_time, from_time)
       |> assign(:actor_summaries, actor_summaries)
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

        actor_summaries =
          Map.merge(
            socket.assigns.actor_summaries,
            actor_summaries(page.entries, socket.assigns.repo, socket.assigns[:threadline_scope])
          )

        {:noreply,
         socket
         |> assign(:actor_summaries, actor_summaries)
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

        actor_summaries =
          Map.merge(
            socket.assigns.actor_summaries,
            actor_summaries(page.entries, socket.assigns.repo, socket.assigns[:threadline_scope])
          )

        {:noreply,
         socket
         |> assign(:actor_summaries, actor_summaries)
         |> assign(:prev_cursor, page.prev_cursor)
         |> stream(:transactions, page.entries, at: 0)}
      else
        {:noreply, socket}
      end
    end

    defp timeline_actor_path(base_path, actor_ref) do
      query =
        URI.encode_query(%{
          "actor_kind" => to_string(actor_ref.type),
          "actor_id" => to_string(actor_ref.id)
        })

      "#{base_path}/timeline?#{query}"
    end

    defp pressed_state(current, value) when current == value, do: "true"
    defp pressed_state(_current, _value), do: "false"

    defp actor_summaries(_transactions, _repo, scope)
         when not is_nil(scope),
         do: %{}

    defp actor_summaries(transactions, repo, _scope) do
      ids = transactions |> Enum.map(& &1.id) |> Enum.reject(&is_nil/1)

      if ids == [] do
        %{}
      else
        AuditChange
        |> where([ac], ac.transaction_id in ^ids)
        |> order_by([ac], asc: ac.transaction_id, desc: ac.captured_at, desc: ac.table_name)
        |> repo.all(StorageSchema.repo_opts())
        |> Enum.group_by(& &1.transaction_id)
        |> Map.new(fn {transaction_id, changes} ->
          {transaction_id,
           Presentation.actor_transaction_summary(Enum.map(changes, &summary_change/1))}
        end)
      end
    end

    defp summary_change(%AuditChange{} = change) do
      %{
        op: change.op,
        table_name: change.table_name,
        field_changes: change.changed_fields || []
      }
    end
  end
end
