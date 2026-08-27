if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RowHistoryLive do
    @moduledoc false
    use Phoenix.LiveView

    # GREEN-05 / D-07: this page declares its own form policy, so a change that adds
    # a form control fails the guard in the same diff. See
    # test/threadline/operator_surface/ui_form_policy_contract_test.exs.
    Module.register_attribute(__MODULE__, :ui_form_policy, persist: true)
    @ui_form_policy :formless

    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI

    def mount(_params, _session, socket) do
      repo =
        socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

      {:ok, assign(socket, :threadline_repo, repo)}
    end

    def handle_params(params, uri, socket) do
      parsed_uri = URI.parse(uri)
      path = parsed_uri.path || ""
      base_path = surface_root(path)
      table = params["table"]
      record_id = params["record_id"]

      {:noreply,
       assign(socket,
         base_path: base_path,
         table: table,
         record_id: record_id,
         as_of: parse_as_of(params["as_of"]),
         history_path: row_history_path(base_path, table, record_id),
         close_path: "#{base_path}/timeline"
       )}
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
        script
        main_class="tl-page"
        data-earned-flow="EF2"
        data-persona="P1"
        data-jtbd="J2"
      >
          <UI.page_header
            title="Row history"
            breadcrumbs={[
              %{label: "Timeline", href: "#{@base_path}/timeline"},
              %{label: "Row history - #{@table}"}
            ]}
          >
            <:lede>Inspect the captured state of one row over time, then jump back to the timeline.</:lede>
          </UI.page_header>
          <UI.detail_header title={row_history_detail_title(@table, @record_id)}>
            <:metadata key="Table"><code><%= @table %></code></:metadata>
            <:metadata key="Row id">
              <UI.ref value={@record_id} copy_label="Copy row id" />
            </:metadata>
            <:metadata :if={@as_of} key="Selected snapshot">
              <time datetime={Presentation.exact_time(@as_of)} title={Presentation.exact_time(@as_of)}>
                <%= Presentation.human_time(@as_of) %>
              </time>
            </:metadata>
          </UI.detail_header>
          <.live_component
            module={Threadline.OperatorSurface.Live.RowHistoryComponent}
            id="row-history"
            table={@table}
            record_id={@record_id}
            as_of={@as_of}
            base_path={@base_path}
            close_path={@close_path}
            history_path={@history_path}
            threadline_schemas={@threadline_schemas}
            repo={@threadline_repo}
            scope={@threadline_scope}
            scope_query_fn={@threadline_scope_query_fn}
          />
      </UI.shell>
      """
    end

    defp parse_as_of(nil), do: nil
    defp parse_as_of(""), do: nil

    defp parse_as_of(value) when is_binary(value) do
      case DateTime.from_iso8601(value) do
        {:ok, dt, _offset} -> dt
        _ -> nil
      end
    end

    defp parse_as_of(_), do: nil

    defp surface_root(path) when is_binary(path) do
      case Regex.run(~r/^(.*)\/rows\/[^\/]+\/[^\/]+$/, path) do
        [_, root] when root != "" -> root
        _ -> path
      end
    end

    defp row_history_path(base_path, table, record_id) do
      "#{base_path}/rows/#{encode_segment(table)}/#{encode_segment(record_id)}"
    end

    defp encode_segment(value), do: URI.encode(to_string(value), &URI.char_unreserved?/1)

    defp row_history_detail_title(table, record_id) do
      "#{table} / #{Presentation.short_id(record_id, 14)}"
    end
  end
end
