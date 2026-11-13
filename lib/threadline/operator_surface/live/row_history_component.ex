if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RowHistoryComponent do
    @moduledoc false
    use Phoenix.LiveComponent

    alias Phoenix.LiveView.JS
    alias Threadline.OperatorSurface.Live.TimelineLive.Helpers
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI

    def update(assigns, socket) do
      schemas = assigns[:threadline_schemas] || %{}
      table = to_string(assigns.table)
      record_id = to_string(assigns.record_id)
      schema_module = schema_for_table(schemas, table)
      snapshot_invalid? = assigns[:snapshot_invalid?] || false

      socket =
        socket
        |> assign(assigns)
        |> assign(:table, table)
        |> assign(:record_id, record_id)
        |> assign(:snapshot_invalid?, snapshot_invalid?)
        |> assign_new(:close_path, fn -> assigns[:base_path] end)
        |> assign_new(:return_label, fn -> "Timeline" end)
        |> assign_new(:context_lost?, fn -> false end)
        |> assign_new(:history_path, fn ->
          "#{assigns[:base_path]}/history/#{encode_segment(table)}/#{encode_segment(record_id)}"
        end)

      if schema_module do
        row_history_opts = [
          repo: assigns.repo,
          scope: assigns[:scope],
          scope_query_fn: assigns[:scope_query_fn],
          limit: :infinity
        ]

        as_of_opts = [
          repo: assigns.repo,
          scope: assigns[:scope],
          scope_query_fn: assigns[:scope_query_fn]
        ]

        try do
          history =
            schema_module
            |> Threadline.row_history(assigns.record_id, row_history_opts)
            |> Enum.map(& &1.audit_change)

          {as_of_dt, snapshot_result} =
            if snapshot_invalid? do
              {nil, nil}
            else
              dt =
                assigns.as_of ||
                  if history != [], do: hd(history).captured_at, else: DateTime.utc_now()

              {dt, Threadline.as_of(schema_module, assigns.record_id, dt, as_of_opts)}
            end

          {:ok,
           socket
           |> assign(:error, nil)
           |> assign(:retryable, false)
           |> assign(:history, history)
           |> assign(:snapshot_result, snapshot_result)
           |> assign(:as_of_dt, as_of_dt)}
        rescue
          _error in DBConnection.ConnectionError ->
            {:ok,
             socket
             |> assign(:error, unavailable_message(socket.assigns.return_label))
             |> assign(:retryable, true)
             |> assign(:history, [])
             |> assign(:snapshot_result, nil)}

          e in ArgumentError ->
            {:ok,
             assign(
               socket,
               :error,
               "Row history could not be loaded for this key: " <> Exception.message(e)
             )
             |> assign(:retryable, false)}
        end
      else
        {:ok,
         assign(
           socket,
           :error,
           "Table '#{assigns.table}' is not mapped to an Ecto schema. Configure :schemas in the auth plug."
         )
         |> assign(:retryable, false)}
      end
    end

    def handle_event("retry", _params, socket) do
      retry_assigns =
        Map.take(socket.assigns, [
          :id,
          :table,
          :record_id,
          :as_of,
          :snapshot_invalid?,
          :base_path,
          :close_path,
          :return_label,
          :context_lost?,
          :history_path,
          :threadline_schemas,
          :repo,
          :scope,
          :scope_query_fn
        ])

      {:ok, socket} = update(retry_assigns, socket)
      {:noreply, socket}
    end

    def handle_event("update-as-of", %{"as_of" => value}, socket) when is_binary(value) do
      candidate =
        cond do
          String.length(value) == 16 -> value <> ":00Z"
          Regex.match?(~r/T\d{2}:\d{2}:\d{2}(?:\.\d+)?$/, value) -> value <> "Z"
          true -> value
        end

      requested =
        case DateTime.from_iso8601(candidate) do
          {:ok, dt, _offset} -> dt
          _ -> value
        end

      {:noreply, push_patch(socket, to: as_of_path(socket.assigns.history_path, requested))}
    end

    def handle_event("update-as-of", _params, socket) do
      {:noreply, assign(socket, snapshot_invalid?: true, as_of_dt: nil, snapshot_result: nil)}
    end

    def render(assigns) do
      ~H"""
      <div id={"#{@id}-shell"}>
        <UI.Overlay.drawer
          id={@id}
          show
          motion={:immediate}
          on_cancel={JS.patch(@close_path)}
          class="tl-row-history-drawer"
          data-testid="row-history-drawer"
        >
          <div class="tl-subview__header">
            <div>
              <h3 class="tl-subview__title" id={"#{@id}-title"} title={"#{@table} / #{@record_id}"}>
                Row history: <%= @table %> / <%= Presentation.short_id(@record_id, 14) %>
              </h3>
              <p id={"#{@id}-description"} class="tl-modal__body">
                Inspect captured row state at the selected point in row history.
              </p>
              <UI.Display.ref value={@record_id} copy_label="Copy row id" />
            </div>
            <.link patch={@close_path} class="tl-button tl-button--secondary" data-tl-initial-focus>
              <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_left} class="tl-button__icon" />
              Close
            </.link>
          </div>

          <p :if={assigns[:context_lost?]} class="tl-alert tl-alert--warning" role="status" data-testid="timeline-context-loss">
            Some Timeline filters could not be restored. Return to Timeline to choose filters before continuing.
          </p>

          <%= if @error do %>
            <div class="tl-empty tl-empty--error" role="alert">
              <p class="tl-empty__body"><%= @error %></p>
              <button :if={@retryable} type="button" phx-click="retry" phx-target={@myself} class="tl-button tl-button--secondary">
                Retry row history
              </button>
            </div>
          <% else %>
            <div class="tl-subview__content">
              <div class="tl-subview__panel">
                <h4 class="tl-subview__panel-title">Row timeline</h4>
                <form id={"#{@id}-as-of-form"} phx-change="update-as-of" phx-target={@myself}>
                  <UI.Form.field
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
                      <.link patch={as_of_path(@history_path, change.captured_at)}>
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
                <%= if @snapshot_invalid? do %>
                  <div class="tl-alert tl-alert--warning" role="alert">
                    <p>This snapshot time is invalid. Enter a valid date and time, or clear the field to view the latest snapshot.</p>
                    <.link patch={as_of_path(@history_path, nil)} class="tl-button tl-button--secondary">
                      View latest snapshot
                    </.link>
                  </div>
                <% else %>
                  <h4 class="tl-subview__panel-title">
                    Snapshot as of <time datetime={Presentation.exact_time(@as_of_dt)} title={Presentation.exact_time(@as_of_dt)}><%= Presentation.human_time(@as_of_dt) %></time>
                  </h4>
                  <.snapshot_result result={@snapshot_result} />
                <% end %>
              </div>
            </div>
          <% end %>
        </UI.Overlay.drawer>
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
          Enum.find_value(schemas, &schema_for_atom_key(&1, table))
      end
    end

    defp schema_for_table(_schemas, _table), do: nil

    defp schema_for_atom_key({key, schema}, table) when is_atom(key) do
      if Atom.to_string(key) == table, do: schema
    end

    defp schema_for_atom_key(_entry, _table), do: nil

    defp as_of_path(history_path, %DateTime{} = as_of),
      do: as_of_path(history_path, DateTime.to_iso8601(as_of))

    defp as_of_path(history_path, as_of) when is_binary(as_of) or is_nil(as_of) do
      uri = URI.parse(history_path)
      params = if uri.query, do: URI.decode_query(uri.query), else: %{}
      origin_query = timeline_origin_query(params)
      as_of_query = if as_of in [nil, ""], do: "", else: URI.encode_query(%{"as_of" => as_of})
      query = Enum.reject([origin_query, as_of_query], &(&1 == "")) |> Enum.join("&")
      path = uri.path || history_path

      if query == "", do: path, else: path <> "?" <> query
    end

    defp timeline_origin_query(params) do
      case Helpers.timeline_filter_query(params) do
        {:ok, filter_query} ->
          Enum.join(Enum.reject(["origin=timeline", filter_query], &(&1 == "")), "&")

        :error ->
          ""
      end
    end

    defp unavailable_message("Timeline"),
      do: "Row history is unavailable. Retry row history or return to Timeline."

    defp unavailable_message(_return_label),
      do: "Row history is unavailable. Retry row history or return to the transaction."

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
