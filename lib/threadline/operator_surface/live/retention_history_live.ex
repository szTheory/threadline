if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RetentionHistoryLive do
    @moduledoc false

    use Phoenix.LiveView
    import Ecto.Query

    alias Threadline.Governance.RetentionRun
    alias Threadline.OperatorSurface.Unsupported
    alias Threadline.Retention.Pruner

    @default_limit 100

    def mount(_params, _session, socket) do
      if connected?(socket) and socket.assigns[:threadline_policy_enabled] do
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
      if not socket.assigns[:threadline_policy_enabled] do
        {:noreply, socket}
      else
        case Pruner.trigger() do
          :ok ->
            # Schedule a quick refresh to see the new run pop up
            Process.send_after(self(), :refresh, 500)
            {:noreply, socket}

          {:error, :not_started} ->
            {:noreply, put_flash(socket, :error, "Retention runtime is not started.")}
        end
      end
    end

    def handle_info(:refresh, socket) do
      if not socket.assigns[:threadline_policy_enabled] do
        {:noreply, socket}
      else
        schedule_refresh(socket)

        runs = fetch_runs(socket)

        socket =
          Enum.reduce(runs, socket, fn run, acc_socket ->
            stream_insert(acc_socket, :runs, run)
          end)
          |> assign(:has_runs, length(runs) > 0)

        {:noreply, socket}
      end
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
            policy_enabled={@threadline_policy_enabled}
            evidence_enabled={@threadline_evidence_enabled}
            exports_enabled={@threadline_exports_enabled}
            current={:retention}
          />
        <% end %>

        <main class="tl-page">
          <%= if @threadline_policy_enabled do %>
            <header class="tl-page__header">
              <h2 class="tl-page__title">Retention History</h2>
              <button class="tl-button tl-button--primary" phx-click="prune_now" data-confirm="Prune: Are you sure you want to run a pruning batch? This permanently deletes older records.">Run Pruning Batch</button>
            </header>

            <%= if not @has_runs do %>
              <div class="tl-empty">
                <h3 class="tl-empty__title">No Retention History</h3>
                <p class="tl-empty__body">Configure your retention policy and trigger a prune to see runs here.</p>
              </div>
            <% else %>
              <div class="tl-table-wrap" data-testid="retention-runs-table">
                <table class="tl-table tl-table--retention">
                  <thead>
                    <tr>
                      <th>Status</th>
                      <th>Deleted Rows</th>
                      <th>Duration</th>
                      <th>Date</th>
                    </tr>
                  </thead>
                  <tbody id="retention-runs" phx-update="stream" data-testid="retention-runs">
                    <tr :for={{dom_id, run} <- @streams.runs} id={dom_id} class={"tl-table__row--" <> run.status}>
                      <td><span class={["tl-chip", retention_status_modifier(run.status)]}><%= run.status %></span></td>
                      <td class="tl-table__number"><%= run.deleted_count || "-" %></td>
                      <td class="tl-table__number"><%= if run.duration_ms, do: "#{run.duration_ms}ms", else: "-" %></td>
                      <td class="tl-table__date"><%= format_date(run.started_at) %></td>
                    </tr>
                  </tbody>
                </table>
              </div>
            <% end %>
          <% else %>
            <Threadline.OperatorSurface.Components.UnsupportedView.unsupported_view
              descriptor={Unsupported.descriptor(:retention_unavailable)}
              base_path={@base_path}
            />
          <% end %>
        </main>
      </div>
      """
    end

    defp fetch_runs(socket) do
      if not socket.assigns[:threadline_policy_enabled] do
        []
      else
        repo = resolve_repo(socket)

        from(r in RetentionRun, order_by: [desc: r.started_at], limit: @default_limit)
        |> repo.all()
      end
    end

    defp has_runs?(socket) do
      if not socket.assigns[:threadline_policy_enabled] do
        false
      else
        repo = resolve_repo(socket)
        repo.exists?(from(r in RetentionRun))
      end
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

    defp retention_status_modifier("completed"), do: "tl-chip--success"
    defp retention_status_modifier("failed"), do: "tl-chip--danger"

    defp retention_status_modifier(status) when status in ["pending", "running"],
      do: "tl-chip--accent"

    defp retention_status_modifier(_), do: "tl-chip--muted"
  end
end
