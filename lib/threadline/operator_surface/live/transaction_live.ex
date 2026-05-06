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
