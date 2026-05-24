if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RetentionHistoryLive do
    @moduledoc false

    use Phoenix.LiveView
    import Ecto.Query

    alias Threadline.Governance.RetentionRun
    alias Threadline.Retention.Pruner

    @default_limit 100

    def mount(_params, _session, socket) do
      if connected?(socket) do
        schedule_refresh(socket)
      end

      socket =
        socket
        |> assign(:base_path, nil)
        |> stream(:runs, fetch_runs(socket))
        |> assign(:has_runs, has_runs?(socket))

      {:ok, socket}
    end

    def handle_params(_params, uri, socket) do
      uri_parsed = URI.parse(uri)
      base_path = (uri_parsed.path || "") |> String.replace_suffix("/policy/retention", "")
      {:noreply, assign(socket, :base_path, base_path)}
    end

    def handle_event("prune_now", _params, socket) do
      case Pruner.trigger() do
        :ok ->
          # Schedule a quick refresh to see the new run pop up
          Process.send_after(self(), :refresh, 500)
          {:noreply, socket}

        {:error, :not_started} ->
          {:noreply, put_flash(socket, :error, "Retention runtime is not started.")}
      end
    end

    def handle_info(:refresh, socket) do
      schedule_refresh(socket)

      runs = fetch_runs(socket)

      socket =
        Enum.reduce(runs, socket, fn run, acc_socket ->
          stream_insert(acc_socket, :runs, run)
        end)
        |> assign(:has_runs, length(runs) > 0)

      {:noreply, socket}
    end

    def render(assigns) do
      ~H"""
      <div class="threadline-ui">
        <Threadline.OperatorSurface.Style.css />
        <%= if @base_path do %>
          <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
            coverage={@threadline_coverage || %{uncovered_count: 0}}
            base_path={@base_path}
            coverage_enabled={@threadline_coverage_enabled}
          />
        <% end %>

        <main class="retention-history-page">
          <header class="page-header">
            <h2>Retention History</h2>
            <button class="primary" phx-click="prune_now" data-confirm="Prune: Are you sure you want to run a pruning batch? This permanently deletes older records.">Run Pruning Batch</button>
          </header>

          <%= if not @has_runs do %>
            <div class="empty-state">
              <h3>No Retention History</h3>
              <p>There is no retention history. Configure your retention policy and trigger a prune to see runs here.</p>
            </div>
          <% else %>
            <table class="retention-table">
              <thead>
                <tr>
                  <th>Status</th>
                  <th>Deleted Rows</th>
                  <th>Duration</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody id="retention-runs" phx-update="stream">
                <tr :for={{dom_id, run} <- @streams.runs} id={dom_id} class={"run-row--" <> run.status}>
                  <td><%= run.status %></td>
                  <td><%= run.deleted_count || "-" %></td>
                  <td><%= if run.duration_ms, do: "#{run.duration_ms}ms", else: "-" %></td>
                  <td><%= format_date(run.started_at) %></td>
                </tr>
              </tbody>
            </table>
          <% end %>
        </main>
      </div>
      """
    end

    defp fetch_runs(socket) do
      repo = resolve_repo(socket)

      from(r in RetentionRun, order_by: [desc: r.started_at], limit: @default_limit)
      |> repo.all()
    end

    defp has_runs?(socket) do
      repo = resolve_repo(socket)
      repo.exists?(from(r in RetentionRun))
    end

    defp schedule_refresh(socket) do
      interval =
        socket.assigns[:threadline_retention_poll_ms] ||
          Application.get_env(:threadline, :retention_poll_ms, 5_000)

      Process.send_after(self(), :refresh, interval)
    end

    defp resolve_repo(socket) do
      socket.assigns[:threadline_repo] ||
        Application.get_env(:threadline, :ecto_repos, []) |> List.first() || Threadline.Repo
    end

    defp format_date(nil), do: "-"

    defp format_date(%DateTime{} = dt) do
      DateTime.to_string(dt) |> String.replace("Z", " UTC")
    end
  end
end
