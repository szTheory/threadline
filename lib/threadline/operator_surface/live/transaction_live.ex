if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TransactionLive do
    use Phoenix.LiveView

    def mount(%{"id" => id}, _session, socket) do
      repo =
        socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

      case Threadline.incident_bundle(id, repo: repo, preload: :action) do
        {:error, :not_found} ->
          {:ok, assign(socket, :not_found, true)}

        {:ok, bundle} ->
          {:ok,
           socket
           |> assign(:not_found, false)
           |> assign(:bundle, bundle)
           |> stream_configure(:changes,
             dom_id: fn change -> "change-#{change.change_diff["id"]}" end
           )
           |> stream(:changes, bundle.changes)}
      end
    end

    def handle_params(params, uri, socket) do
      uri_parsed = URI.parse(uri)
      # Extract base path up to /transactions/:id
      base_path = 
        case Regex.run(~r/(.*\/transactions\/[^\/]+)/, uri_parsed.path) do
          [_, path] -> path
          _ -> uri_parsed.path
        end

      socket = assign(socket, :base_path, base_path)

      if socket.assigns.live_action == :history do
        table = params["table"]
        record_id = params["record_id"]
        
        as_of = case params["as_of"] do
          nil -> nil
          "" -> nil
          str -> case DateTime.from_iso8601(str) do
            {:ok, dt, _offset} -> dt
            _ -> nil
          end
        end

        {:noreply, assign(socket, show_history: true, history_table: table, history_record_id: record_id, history_as_of: as_of)}
      else
        {:noreply, assign(socket, show_history: false, history_table: nil, history_record_id: nil, history_as_of: nil)}
      end
    end

    def render(assigns) do
      ~H"""
      <div class="threadline-ui">
        <Threadline.OperatorSurface.Style.css />
        <%= if @not_found do %>
          <div class="empty-state">
            <p>Transaction Not Found - The requested transaction ID does not exist or has been purged by the retention policy.</p>
          </div>
        <% else %>
          <div class="transaction-header">
            <h2>Transaction: <%= @bundle.transaction.id %></h2>
          </div>
          <%= if Enum.empty?(@bundle.changes) do %>
            <div class="empty-state">
              <p>No Changes Recorded</p>
            </div>
          <% else %>
            <div
              id="changes-list"
              phx-update="stream"
              phx-viewport-top="prev-page"
              phx-viewport-bottom="next-page"
              class="viewport-container"
            >
              <div :for={{dom_id, change} <- @streams.changes} id={dom_id} class="change-row">
                <div class="change-header">
                  <span class="change-op"><%= change.change_diff["op"] %></span>
                  <span class="change-table"><%= change.change_diff["table_name"] %></span>
                  <span class="change-time"><%= change.change_diff["captured_at"] %></span>
                  <.link patch={"#{@base_path}/history/#{change.change_diff["table_name"]}/#{change.change_diff["table_pk"] |> Map.values() |> List.first()}?as_of=#{change.change_diff["captured_at"]}"} class="history-link" title="View Row History">
                    History
                  </.link>
                </div>
                <div class="change-fields">
                  <%= for field <- change.change_diff["field_changes"] do %>
                    <div class="field-diff">
                      <span class="field-name"><%= field["name"] %></span>:
                      <%= if Map.has_key?(field, "before") do %>
                        <span class="field-before"><%= inspect(field["before"]) %></span> ->
                      <% end %>
                      <%= if Map.has_key?(field, "prior_state") do %>
                        <span class="field-prior-omitted">(omitted)</span> ->
                      <% end %>
                      <span class="field-after"><%= inspect(field["after"]) %></span>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
        <%= if @show_history do %>
          <.live_component 
            module={Threadline.OperatorSurface.Live.RowHistoryComponent} 
            id="row-history" 
            table={@history_table}
            record_id={@history_record_id}
            as_of={@history_as_of}
            base_path={@base_path}
            threadline_schemas={@threadline_schemas}
            repo={@threadline_repo}
          />
        <% end %>
      </div>
      """
    end

    def handle_event("prev-page", _, socket) do
      {:noreply, socket}
    end

    def handle_event("next-page", _, socket) do
      {:noreply, socket}
    end
  end
end
