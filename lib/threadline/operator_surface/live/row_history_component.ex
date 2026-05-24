if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RowHistoryComponent do
    @moduledoc false
    use Phoenix.LiveComponent

    def update(assigns, socket) do
      schemas = assigns[:threadline_schemas] || %{}

      schema_module =
        Map.get(schemas, assigns.table) || Map.get(schemas, String.to_atom(assigns.table))

      socket = assign(socket, assigns)

      if schema_module do
        opts = [
          repo: assigns.repo,
          scope: assigns[:scope],
          scope_query_fn: assigns[:scope_query_fn]
        ]

        history = Threadline.history(schema_module, assigns.record_id, opts)

        as_of_dt =
          assigns.as_of || if history != [], do: hd(history).captured_at, else: DateTime.utc_now()

        snapshot =
          Threadline.as_of(schema_module, assigns.record_id, as_of_dt, opts)

        {:ok,
         socket
         |> assign(:error, nil)
         |> assign(:history, history)
         |> assign(:snapshot, snapshot)
         |> assign(:as_of_dt, as_of_dt)}
      else
        {:ok,
         assign(
           socket,
           :error,
           "Table '#{assigns.table}' is not mapped to an Ecto schema. Configure :schemas in the auth plug."
         )}
      end
    end

    def handle_event("update-as-of", %{"as_of" => as_of_str}, socket) do
      as_of_str =
        if String.length(as_of_str) == 16, do: as_of_str <> ":00Z", else: as_of_str <> "Z"

      as_of =
        case DateTime.from_iso8601(as_of_str) do
          {:ok, dt, _} -> dt
          _ -> socket.assigns.as_of_dt
        end

      path =
        "#{socket.assigns.base_path}/history/#{socket.assigns.table}/#{socket.assigns.record_id}?as_of=#{URI.encode_www_form(DateTime.to_iso8601(as_of))}"

      {:noreply, push_patch(socket, to: path)}
    end

    def render(assigns) do
      ~H"""
      <div class="threadline-ui-subview slide-over" id={@id}>
        <div class="subview-header">
          <h3>Row History: <%= @table %> / <%= @record_id %></h3>
          <.link patch={@base_path} class="close-button">Close</.link>
        </div>
        
        <%= if @error do %>
          <div class="empty-state error-state"><%= @error %></div>
        <% else %>
          <div class="subview-content">
            <div class="timeline-panel">
              <h4>Timeline</h4>
              <form phx-change="update-as-of" phx-target={@myself}>
                <label>Manual As-Of:
                  <input type="datetime-local" name="as_of" value={format_dt(@as_of_dt)} />
                </label>
              </form>
              <ul class="timeline-list">
                <%= for change <- @history do %>
                  <li>
                    <.link patch={"#{@base_path}/history/#{@table}/#{@record_id}?as_of=#{DateTime.to_iso8601(change.captured_at)}"}>
                      <%= change.captured_at %> - <%= change.op %>
                    </.link>
                  </li>
                <% end %>
              </ul>
            </div>
            
            <div class="snapshot-panel">
              <h4>Snapshot as of <%= @as_of_dt %></h4>
              <%= if @snapshot do %>
                <pre><%= inspect(@snapshot, pretty: true) %></pre>
              <% else %>
                <p>Record did not exist at this time.</p>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
      """
    end

    defp format_dt(%DateTime{} = dt) do
      dt |> DateTime.to_iso8601() |> String.slice(0..15)
    end

    defp format_dt(_), do: ""
  end
end
