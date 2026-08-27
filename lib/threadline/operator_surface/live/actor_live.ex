if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.ActorLive do
    use Phoenix.LiveView

    # GREEN-05 / D-07: this page declares its own form policy, so a change that adds
    # a form control fails the guard in the same diff. See
    # test/threadline/operator_surface/ui_form_policy_contract_test.exs.
    Module.register_attribute(__MODULE__, :ui_form_policy, persist: true)
    @ui_form_policy :formless

    import Ecto.Query

    alias Threadline.Capture.AuditChange
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI
    alias Threadline.Semantics.ActorRef
    alias Threadline.StorageSchema

    @actor_kinds ~w(user admin service_account job system anonymous)a

    def mount(%{"kind" => kind, "id" => id}, _session, socket) do
      repo =
        socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

      with {:ok, type} <- safe_actor_kind(kind),
           {:ok, actor_ref} <- ActorRef.new(type, id) do
        from_time = DateTime.utc_now() |> DateTime.add(-24, :hour)

        page =
          Threadline.actor_history(
            actor_ref,
            [
              repo: repo,
              from: from_time,
              scope: socket.assigns[:threadline_scope],
              scope_query_fn: socket.assigns[:threadline_scope_query_fn],
              surface: :actor_history,
              params: %{actor_ref: actor_ref, from: from_time}
            ] ++ storage_schema_opts(socket)
          )

        {has_ever_acted, last_activity} =
          if Enum.empty?(page.entries) do
            case Threadline.actor_history(
                   actor_ref,
                   [
                     repo: repo,
                     limit: 1,
                     scope: socket.assigns[:threadline_scope],
                     scope_query_fn: socket.assigns[:threadline_scope_query_fn],
                     surface: :actor_history,
                     params: %{actor_ref: actor_ref}
                   ] ++ storage_schema_opts(socket)
                 ) do
              %{entries: [latest | _]} -> {true, latest.occurred_at}
              _ -> {false, nil}
            end
          else
            {true, nil}
          end

        actor_summaries =
          actor_summaries(
            page.entries,
            repo,
            socket.assigns[:threadline_scope],
            storage_schema_opts(socket)
          )

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
         |> assign(:shown_count, length(page.entries))
         |> stream_configure(:transactions, dom_id: fn tx -> "tx-#{tx.id}" end)
         |> stream(:transactions, page.entries)}
      else
        _ ->
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
      <UI.shell
        theme={@threadline_theme}
        coverage={@threadline_coverage}
        base_path={@base_path}
        error={@threadline_coverage_error}
        coverage_enabled={@threadline_coverage_enabled}
        policy_enabled={@threadline_policy_enabled}
        evidence_enabled={@threadline_evidence_enabled}
        exports_enabled={@threadline_exports_enabled}
        current={:timeline}
        scoped={not is_nil(assigns[:threadline_scope])}
        script
        main_class="tl-page"
      >
        <%= if @not_found do %>
          <div class="tl-transaction">
            <UI.page_header
              title="Actor activity"
              breadcrumbs={[
                %{label: "Timeline", href: "#{@base_path}/timeline"},
                %{label: "Actor activity"}
              ]}
            >
              <:lede>Review what an actor touched in a time window, then open a transaction to inspect row-level changes.</:lede>
            </UI.page_header>

            <UI.error_state>
              <:title>Invalid actor reference</:title>
              This actor kind and id could not be parsed as a Threadline actor reference.
              Return to Timeline and check the actor reference.
              <:actions>
                <.link navigate={"#{@base_path}/timeline"} class="tl-button tl-button--secondary">
                  <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_left} class="tl-button__icon" />
                  Open timeline
                </.link>
              </:actions>
            </UI.error_state>
          </div>
        <% else %>
          <div class="tl-transaction">
            <UI.page_header
              title="Actor activity"
              breadcrumbs={[
                %{label: "Timeline", href: "#{@base_path}/timeline"},
                %{label: "Actor - #{@actor_ref.type}/#{@actor_ref.id}"}
              ]}
            >
              <:lede>Review what this actor touched in a time window, then open a transaction to inspect row-level changes.</:lede>
            </UI.page_header>

            <UI.detail_header title={actor_detail_title(@actor_ref)}>
              <:metadata key="Kind"><%= @actor_ref.type %></:metadata>
              <:metadata :if={@actor_ref.id} key="Actor id">
                <UI.ref value={@actor_ref.id} kind="actor" copy_label="Copy actor id" />
              </:metadata>
              <:metadata key="Window"><%= actor_window_label(@time_window_hours) %></:metadata>
              <:metadata key="Transactions"><%= actor_transaction_count(@shown_count) %></:metadata>
              <:metadata key="Visible scope"><%= actor_visible_scope(assigns[:threadline_scope]) %></:metadata>
              <:actions>
                <a href={timeline_actor_path(@base_path, @actor_ref)} class="tl-button tl-button--compact tl-button--secondary">
                  <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
                  Open timeline
                </a>
              </:actions>
            </UI.detail_header>

            <UI.segmented_control aria-label="Actor activity window">
              <:segment active={@time_window_hours == 1} phx-click="set-window" phx-value-hours="1">1h</:segment>
              <:segment active={@time_window_hours == 24} phx-click="set-window" phx-value-hours="24">24h</:segment>
              <:segment active={@time_window_hours == 168} phx-click="set-window" phx-value-hours="168">7d</:segment>
              <:segment active={@time_window_hours == 720} phx-click="set-window" phx-value-hours="720">30d</:segment>
            </UI.segmented_control>
          </div>

          <%= if not @has_ever_acted do %>
            <UI.empty_state variant="never" role="status" icon={:history}>
              <:title>No actor activity recorded</:title>
              No transactions or actions are linked to this actor yet.
              Run an audited transaction or record a semantic action for this actor, then return here.
              <:actions>
                <a href={timeline_actor_path(@base_path, @actor_ref)} class="tl-button tl-button--secondary">
                  <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
                  Open timeline
                </a>
              </:actions>
            </UI.empty_state>
          <% else %>
            <%= if @has_ever_acted and Enum.empty?(@streams.transactions.inserts) do %>
              <UI.empty_state variant="no_data" role="status" icon={:funnel}>
                <:title>No actor activity in this window</:title>
                No transactions or actions are linked to this actor in the selected time window.
                <%= if @last_activity do %>This actor was last active <%= Presentation.human_time(@last_activity) %>.<% end %>
                Widen the time window or open Timeline to adjust actor filters.
                <:actions>
                  <button :if={@time_window_hours != 720} type="button" phx-click="set-window" phx-value-hours="720" class="tl-button tl-button--secondary">
                    <Threadline.OperatorSurface.Components.Icon.icon name={:history} class="tl-button__icon" />
                    Widen to 30 days
                  </button>
                  <a href={timeline_actor_path(@base_path, @actor_ref)} class="tl-button tl-button--ghost">
                    <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
                    Open timeline
                  </a>
                </:actions>
              </UI.empty_state>
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
                      <span>Transaction <UI.ref value={tx.id} kind="uuid" copy_label="Copy transaction id" /></span>
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
              <UI.pager
                shown={@shown_count}
                match_count={nil}
                label="Actor activity pagination"
                has_older={@next_cursor != nil}
                has_newer={@prev_cursor != nil}
                older_event="next-page"
                newer_event="prev-page"
              />
            <% end %>
          <% end %>
        <% end %>
      </UI.shell>
      """
    end

    def handle_event("set-window", %{"hours" => hours_str}, socket) do
      hours = String.to_integer(hours_str)
      from_time = DateTime.utc_now() |> DateTime.add(-hours, :hour)

      page =
        Threadline.actor_history(
          socket.assigns.actor_ref,
          [
            repo: socket.assigns.repo,
            from: from_time,
            scope: socket.assigns[:threadline_scope],
            scope_query_fn: socket.assigns[:threadline_scope_query_fn],
            surface: :actor_history,
            params: %{actor_ref: socket.assigns.actor_ref, from: from_time}
          ] ++ storage_schema_opts(socket)
        )

      actor_summaries =
        actor_summaries(
          page.entries,
          socket.assigns.repo,
          socket.assigns[:threadline_scope],
          storage_schema_opts(socket)
        )

      {:noreply,
       socket
       |> assign(:time_window_hours, hours)
       |> assign(:from_time, from_time)
       |> assign(:actor_summaries, actor_summaries)
       |> assign(:next_cursor, page.next_cursor)
       |> assign(:prev_cursor, page.prev_cursor)
       |> assign(:shown_count, length(page.entries))
       |> stream(:transactions, page.entries, reset: true)}
    end

    def handle_event("next-page", _, socket) do
      if socket.assigns.next_cursor do
        page =
          Threadline.actor_history(
            socket.assigns.actor_ref,
            [
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
            ] ++ storage_schema_opts(socket)
          )

        actor_summaries =
          Map.merge(
            socket.assigns.actor_summaries,
            actor_summaries(
              page.entries,
              socket.assigns.repo,
              socket.assigns[:threadline_scope],
              storage_schema_opts(socket)
            )
          )

        {:noreply,
         socket
         |> assign(:actor_summaries, actor_summaries)
         |> assign(:next_cursor, page.next_cursor)
         |> Phoenix.Component.update(:shown_count, &(&1 + length(page.entries)))
         |> stream(:transactions, page.entries, at: -1)}
      else
        {:noreply, socket}
      end
    end

    def handle_event("prev-page", _, socket) do
      if socket.assigns.prev_cursor do
        page =
          Threadline.actor_history(
            socket.assigns.actor_ref,
            [
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
            ] ++ storage_schema_opts(socket)
          )

        actor_summaries =
          Map.merge(
            socket.assigns.actor_summaries,
            actor_summaries(
              page.entries,
              socket.assigns.repo,
              socket.assigns[:threadline_scope],
              storage_schema_opts(socket)
            )
          )

        {:noreply,
         socket
         |> assign(:actor_summaries, actor_summaries)
         |> assign(:prev_cursor, page.prev_cursor)
         |> Phoenix.Component.update(:shown_count, &(&1 + length(page.entries)))
         |> stream(:transactions, page.entries, at: 0)}
      else
        {:noreply, socket}
      end
    end

    defp safe_actor_kind(kind) when is_binary(kind) do
      case Enum.find(@actor_kinds, &(Atom.to_string(&1) == kind)) do
        nil -> {:error, :unknown_actor_type}
        actor_kind -> {:ok, actor_kind}
      end
    end

    defp safe_actor_kind(_), do: {:error, :unknown_actor_type}

    defp actor_detail_title(%ActorRef{type: type}), do: "#{type} actor"

    defp actor_window_label(1), do: "1 hour"
    defp actor_window_label(24), do: "24 hours"
    defp actor_window_label(168), do: "7 days"
    defp actor_window_label(720), do: "30 days"
    defp actor_window_label(hours), do: "#{hours} hours"

    defp actor_transaction_count(1), do: "1 transaction"
    defp actor_transaction_count(count), do: "#{count} transactions"

    defp actor_visible_scope(nil), do: "All visible activity"
    defp actor_visible_scope(_scope), do: "Scoped activity"

    defp timeline_actor_path(base_path, actor_ref) do
      query =
        URI.encode_query(%{
          "actor_kind" => to_string(actor_ref.type),
          "actor_id" => to_string(actor_ref.id)
        })

      "#{base_path}/timeline?#{query}"
    end

    defp storage_schema_opts(_socket), do: [storage_schema: StorageSchema.get()]

    defp actor_summaries(_transactions, _repo, scope, _storage_schema_opts)
         when not is_nil(scope),
         do: %{}

    defp actor_summaries(transactions, repo, _scope, storage_schema_opts) do
      ids = transactions |> Enum.map(& &1.id) |> Enum.reject(&is_nil/1)

      if ids == [] do
        %{}
      else
        AuditChange
        |> where([ac], ac.transaction_id in ^ids)
        |> order_by([ac], asc: ac.transaction_id, desc: ac.captured_at, desc: ac.table_name)
        |> repo.all(StorageSchema.repo_opts(storage_schema_opts))
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
