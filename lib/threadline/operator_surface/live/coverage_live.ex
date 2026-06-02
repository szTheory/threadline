if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.CoverageLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Threadline.OperatorSurface.Coverage.Snapshot
    alias Threadline.OperatorSurface.Unsupported

    @schema_regex ~r/\A[a-z_][a-z0-9_]{0,62}\z/
    @baseline ~w(schema_migrations)

    # ------------------------------------------------------------------
    # mount/3
    # ------------------------------------------------------------------
    #
    # :threadline_coverage and :threadline_coverage_error are populated by
    # Coverage.OnMount BEFORE this mount/3 runs (router on_mount: order
    # locked: Auth -> Coverage.OnMount -> mount/3). We additionally hold
    # :coverage_for_schema (the snapshot specific to the requested ?schema=)
    # and :form_error (set when ?schema=NAME is invalid).
    def mount(_params, _session, socket) do
      initial = socket.assigns[:threadline_coverage] || Snapshot.empty(DateTime.utc_now())

      socket =
        socket
        |> assign(:base_path, nil)
        |> assign(:schema_param, "public")
        |> assign(:coverage_for_schema, initial)
        |> assign(:form_error, nil)

      {:ok, socket}
    end

    def handle_params(params, uri, socket) do
      uri_parsed = URI.parse(uri)
      base_path = (uri_parsed.path || "") |> String.replace_suffix("/coverage", "")
      socket = assign(socket, :base_path, base_path)

      schema_param = Map.get(params, "schema", "public")

      if socket.assigns[:threadline_coverage_enabled] do
        case validate_schema(socket, schema_param) do
          {:ok, schema} ->
            socket =
              socket
              |> assign(:schema_param, schema)
              |> assign(:form_error, nil)
              |> fetch_coverage_for_schema(schema)

            {:noreply, socket}

          {:error, message} ->
            socket =
              socket
              |> assign(:schema_param, schema_param)
              |> assign(:form_error, message)

            {:noreply, socket}
        end
      else
        {:noreply, socket}
      end
    end

    def handle_event("refresh", _params, socket) do
      if not socket.assigns[:threadline_coverage_enabled] do
        {:noreply, socket}
      else
        # Cancel pending timer (Pitfall 6 — manual refresh races a tick).
        # Process.cancel_timer/1 is idempotent on already-fired timers (returns false).
        if ref = socket.assigns[:threadline_timer_ref] do
          Process.cancel_timer(ref)
        end

        schema = socket.assigns[:schema_param] || "public"
        socket = fetch_coverage_for_schema(socket, schema)

        # Reschedule using the same interval Coverage.OnMount uses.
        interval =
          socket.assigns[:threadline_coverage_poll_ms] ||
            Application.get_env(:threadline, :coverage_poll_ms, 30_000)

        new_ref = Process.send_after(self(), :threadline_refresh_coverage, interval)
        socket = assign(socket, :threadline_timer_ref, new_ref)

        {:noreply, socket}
      end
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
          current={:coverage}
        />

        <main class="tl-page">
          <%= if @threadline_coverage_enabled do %>
            <header class="tl-page__header">
              <div>
                <h2 class="tl-page__title">Coverage — schema: <%= @schema_param %></h2>
                <p class="tl-page__lede">
                  <%= if @coverage_for_schema.last_checked_at do %>
                    Last checked <%= seconds_ago(@coverage_for_schema.last_checked_at) %>s ago
                  <% end %>
                </p>
              </div>
              <a href="#" phx-click="refresh" class="tl-button tl-button--secondary">Refresh</a>
            </header>

            <%= if @form_error do %>
              <div class="tl-alert tl-alert--error" role="alert"><%= @form_error %></div>
            <% else %>
              <%= if @threadline_coverage_error do %>
                <div class="tl-alert tl-alert--warning" role="status">
                  Coverage check failed at <%= now_label() %> — showing last successful result from <%= last_label(@coverage_for_schema.last_checked_at) %>.
                </div>
              <% end %>

              <%= if all_empty?(@coverage_for_schema) do %>
                <div class="tl-empty">
                  No audited tables found for schema '<%= @schema_param %>'. Run mix threadline.gen.triggers to set up capture.
                </div>
              <% else %>
                <div class="tl-table-wrap" data-testid="coverage-table">
                  <table class="tl-table tl-table--coverage">
                    <thead>
                      <tr><th>TABLE</th><th>STATUS</th><th>SOURCE</th></tr>
                    </thead>
                    <tbody>
                      <%= for table <- @coverage_for_schema.tables[:covered] do %>
                        <tr class="tl-table__row--covered">
                          <td><code><%= table %></code></td>
                          <td><span class="tl-chip tl-chip--success">covered</span></td>
                          <td></td>
                        </tr>
                      <% end %>
                      <%= for table <- @coverage_for_schema.tables[:uncovered] do %>
                        <tr class="tl-table__row--uncovered">
                          <td><code><%= table %></code></td>
                          <td><span class="tl-chip tl-chip--danger">uncovered</span></td>
                          <td></td>
                        </tr>
                      <% end %>
                      <%= for table <- @coverage_for_schema.tables[:expected_uncovered] do %>
                        <tr class="tl-table__row--expected" title={tooltip_for(table)}>
                          <td><code><%= table %></code></td>
                          <td><span class="tl-chip tl-chip--muted">expected</span></td>
                          <td><%= source_for(table) %></td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>

                <p class="tl-hint">
                  Coverage: <%= @coverage_for_schema.covered_count %> covered, <%= @coverage_for_schema.uncovered_count %> uncovered, <%= @coverage_for_schema.expected_uncovered_count %> expected uncovered
                </p>
              <% end %>
            <% end %>
          <% else %>
            <Threadline.OperatorSurface.Components.UnsupportedView.unsupported_view
              descriptor={Unsupported.descriptor(:coverage_unavailable)}
              base_path={@base_path}
            />
          <% end %>
        </main>
      </div>
      """
    end

    # -------------------------- private helpers --------------------------

    defp validate_schema(socket, schema) when is_binary(schema) do
      if schema =~ @schema_regex do
        repo = resolve_repo(socket)
        sql = "SELECT 1 FROM pg_namespace WHERE nspname = $1 LIMIT 1"

        case Ecto.Adapters.SQL.query!(repo, sql, [schema]) do
          %{rows: []} -> {:error, "Schema '#{schema}' not found."}
          %{rows: _} -> {:ok, schema}
        end
      else
        {:error, "Schema '#{schema}' not found."}
      end
    end

    defp fetch_coverage_for_schema(socket, schema) do
      repo = resolve_repo(socket)
      now = DateTime.utc_now()

      try do
        coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)
        snapshot = Snapshot.from_coverage(coverage, last_checked_at: now)
        assign(socket, :coverage_for_schema, snapshot)
      rescue
        e ->
          message = Exception.message(e)
          Threadline.Telemetry.emit_health_checked_error(message)

          previous = socket.assigns[:coverage_for_schema] || Snapshot.empty(now)
          snapshot = %{previous | error: message, last_checked_at: now}
          assign(socket, :coverage_for_schema, snapshot)
      end
    end

    defp resolve_repo(socket) do
      socket.assigns[:threadline_repo] ||
        Application.get_env(:threadline, :ecto_repos, []) |> List.first()
    end

    defp seconds_ago(%DateTime{} = ts), do: DateTime.diff(DateTime.utc_now(), ts, :second)
    defp seconds_ago(_), do: 0

    defp now_label, do: DateTime.utc_now() |> DateTime.to_string()
    defp last_label(%DateTime{} = ts), do: DateTime.to_string(ts)
    defp last_label(_), do: "never"

    defp source_for(table) do
      if table in @baseline, do: "baseline", else: "config"
    end

    defp tooltip_for(table) do
      if table in @baseline do
        "Baseline: schema_migrations"
      else
        "Configured via :expected_uncovered_tables"
      end
    end

    defp all_empty?(%Snapshot{
           covered_count: 0,
           uncovered_count: 0,
           expected_uncovered_count: 0
         }),
         do: true

    defp all_empty?(_), do: false
  end
end
