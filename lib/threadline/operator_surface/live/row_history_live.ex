if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RowHistoryLive do
    @moduledoc false
    use Phoenix.LiveView

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
      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
        <Threadline.OperatorSurface.Style.css />
        <Threadline.OperatorSurface.Script.js />
        <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
          theme={@threadline_theme}
          coverage={@threadline_coverage}
          base_path={@base_path}
          error={@threadline_coverage_error}
          coverage_enabled={@threadline_coverage_enabled}
          policy_enabled={@threadline_policy_enabled}
          evidence_enabled={@threadline_evidence_enabled}
          exports_enabled={@threadline_exports_enabled}
          current={nil}
        />
        <main
          id="tl-main"
          class="tl-page"
          tabindex="-1"
          data-earned-flow="EF2"
          data-persona="P1"
          data-jtbd="J2"
        >
          <UI.page_header
            title={"Row history · #{@table}"}
            breadcrumbs={[
              %{label: "Timeline", href: "#{@base_path}/timeline"},
              %{label: "Row history · #{@table}"}
            ]}
          >
            <:lede>Inspect the captured state of one row over time, then jump back to the timeline.</:lede>
          </UI.page_header>
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
        </main>
      </div>
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
  end
end
