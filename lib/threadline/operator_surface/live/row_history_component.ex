if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RowHistoryComponent do
    @moduledoc false
    use Phoenix.LiveComponent

    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI

    def update(assigns, socket) do
      schemas = assigns[:threadline_schemas] || %{}
      table = to_string(assigns.table)
      record_id = to_string(assigns.record_id)
      schema_module = schema_for_table(schemas, table)

      socket =
        socket
        |> assign(assigns)
        |> assign(:table, table)
        |> assign(:record_id, record_id)
        |> assign_new(:close_path, fn -> assigns[:base_path] end)
        |> assign_new(:history_path, fn ->
          "#{assigns[:base_path]}/history/#{encode_segment(table)}/#{encode_segment(record_id)}"
        end)

      if schema_module do
        opts = [
          repo: assigns.repo,
          scope: assigns[:scope],
          scope_query_fn: assigns[:scope_query_fn]
        ]

        history = Threadline.history(schema_module, assigns.record_id, opts)

        as_of_dt =
          assigns.as_of || if history != [], do: hd(history).captured_at, else: DateTime.utc_now()

        snapshot_result =
          Threadline.as_of(schema_module, assigns.record_id, as_of_dt, opts)

        {:ok,
         socket
         |> assign(:error, nil)
         |> assign(:history, history)
         |> assign(:snapshot_result, snapshot_result)
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

      {:noreply, push_patch(socket, to: as_of_path(socket.assigns.history_path, as_of))}
    end

    def render(assigns) do
      ~H"""
      <div class="tl-subview-shell" id={"#{@id}-shell"}>
        <div class="tl-subview-backdrop" aria-hidden="true"></div>
        <div
          class="tl-subview"
          id={@id}
          role="dialog"
          aria-modal="true"
          aria-labelledby={"#{@id}-title"}
          tabindex="-1"
          data-testid="row-history-drawer"
        >
          <div class="tl-subview__header">
            <div>
              <h3 class="tl-subview__title" id={"#{@id}-title"} title={"#{@table} / #{@record_id}"}>
                Row history: <%= @table %> / <%= Presentation.short_id(@record_id, 14) %>
              </h3>
            </div>
            <.link patch={@close_path} class="tl-button tl-button--secondary">
              <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_left} class="tl-button__icon" />
              Close
            </.link>
          </div>

          <%= if @error do %>
            <div class="tl-empty tl-empty--error"><%= @error %></div>
          <% else %>
            <div class="tl-subview__content">
              <div class="tl-subview__panel">
                <h4 class="tl-subview__panel-title">Row timeline</h4>
                <form phx-change="update-as-of" phx-target={@myself}>
                  <UI.field
                    id={"#{@id}-as-of"}
                    type="datetime-local"
                    name="as_of"
                    label="View snapshot at"
                    value={format_dt(@as_of_dt)}
                    class="tl-toolbar__field"
                  />
                </form>
                <ul class="tl-subview__timeline">
                  <%= for change <- @history do %>
                    <li>
                      <.link patch={"#{@history_path}?as_of=#{DateTime.to_iso8601(change.captured_at)}"}>
                        <span class="tl-change__op"><%= change.op %></span>
                        <time class="tl-change__time" datetime={Presentation.exact_time(change.captured_at)} title={Presentation.exact_time(change.captured_at)}>
                          <%= Presentation.human_time(change.captured_at) %>
                        </time>
                      </.link>
                    </li>
                  <% end %>
                </ul>
              </div>

              <div class="tl-subview__panel">
                <h4 class="tl-subview__panel-title">
                  Snapshot as of <time datetime={Presentation.exact_time(@as_of_dt)} title={Presentation.exact_time(@as_of_dt)}><%= Presentation.human_time(@as_of_dt) %></time>
                </h4>
                <.snapshot_result result={@snapshot_result} />
              </div>
            </div>
          <% end %>
        </div>
      </div>
      """
    end

    defp format_dt(%DateTime{} = dt) do
      dt |> DateTime.to_iso8601() |> String.slice(0..15)
    end

    defp format_dt(_), do: ""

    defp schema_for_table(schemas, table) when is_map(schemas) do
      case Map.fetch(schemas, table) do
        {:ok, schema} ->
          schema

        :error ->
          schemas
          |> Enum.find_value(fn
            {key, schema} when is_atom(key) ->
              if Atom.to_string(key) == table, do: schema

            _entry ->
              nil
          end)
      end
    end

    defp schema_for_table(_schemas, _table), do: nil

    defp as_of_path(history_path, %DateTime{} = as_of) do
      "#{history_path}?#{URI.encode_query(%{"as_of" => DateTime.to_iso8601(as_of)})}"
    end

    defp encode_segment(value), do: URI.encode(to_string(value), &URI.char_unreserved?/1)

    attr(:result, :any, required: true)

    defp snapshot_result(%{result: {:ok, snapshot}} = assigns) when is_map(snapshot) do
      assigns = assign(assigns, :rows, snapshot_rows(snapshot))

      ~H"""
      <dl class="tl-kv">
        <div :for={{key, token} <- @rows} class="tl-kv__row">
          <dt class="tl-kv__key"><%= key %></dt>
          <dd class="tl-kv__value">
            <span class={["tl-value", token.modifier]} title={Map.get(token, :title)}>
              <%= token.text %>
            </span>
          </dd>
        </div>
      </dl>
      """
    end

    defp snapshot_result(%{result: {:error, :deleted_record}} = assigns) do
      ~H"""
      <div class="tl-empty tl-empty--never">
        <p class="tl-empty__body">
          This row snapshot was deleted at the selected time.
          Choose an earlier point in row history.
        </p>
      </div>
      """
    end

    defp snapshot_result(%{result: {:error, :before_audit_horizon}} = assigns) do
      ~H"""
      <div class="tl-empty tl-empty--never">
        <p class="tl-empty__body">
          This row snapshot did not exist at the selected time.
          Choose a later point in row history.
        </p>
      </div>
      """
    end

    defp snapshot_result(assigns) do
      ~H"""
      <div class="tl-empty tl-empty--error">
        <p class="tl-empty__body">
          Could not render this row snapshot.
          Choose another point in row history, then retry.
        </p>
      </div>
      """
    end

    defp snapshot_rows(snapshot) do
      snapshot
      |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
      |> Enum.map(fn {key, value} -> {to_string(key), Presentation.value_token(value)} end)
    end
  end
end
