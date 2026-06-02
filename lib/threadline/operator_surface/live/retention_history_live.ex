if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RetentionHistoryLive do
    @moduledoc false

    use Phoenix.LiveView
    import Ecto.Query

    alias Threadline.Governance.RetentionRun
    alias Threadline.OperatorSurface.Presentation
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
        |> assign_runs(fetch_runs(socket))
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
          |> assign(:runs_summary, summarize_runs(runs))
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
              <div>
                <h2 class="tl-page__title">Retention History</h2>
                <p class="tl-page__lede">Review pruning runs before triggering another destructive retention pass.</p>
              </div>
              <button class="tl-button tl-button--primary" phx-click="prune_now" data-confirm="Prune: Are you sure you want to run a pruning batch? This permanently deletes older records.">Run prune now</button>
            </header>

            <%= if not @has_runs do %>
              <div class="tl-empty">
                <h3 class="tl-empty__title">No Retention History</h3>
                <p class="tl-empty__body">Configure your retention policy and trigger a prune to see runs here.</p>
              </div>
            <% else %>
              <section class="tl-summary-grid" aria-label="Retention summary">
                <div class="tl-summary-card">
                  <span class="tl-summary-card__label">Latest run</span>
                  <strong><%= @runs_summary.latest_status %></strong>
                </div>
                <div class="tl-summary-card">
                  <span class="tl-summary-card__label">Rows deleted</span>
                  <strong><%= @runs_summary.total_deleted %></strong>
                </div>
                <div class="tl-summary-card">
                  <span class="tl-summary-card__label">Failures</span>
                  <strong><%= @runs_summary.failure_count %></strong>
                </div>
              </section>

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
                      <td><span class={["tl-chip", Presentation.status_modifier(run.status)]}><%= Presentation.status_label(run.status) %></span></td>
                      <td class="tl-table__number"><%= run.deleted_count || "-" %></td>
                      <td class="tl-table__number"><%= if run.duration_ms, do: "#{run.duration_ms}ms", else: "-" %></td>
                      <td class="tl-table__date">
                        <%= if run.started_at do %>
                          <time datetime={Presentation.exact_time(run.started_at)} title={Presentation.exact_time(run.started_at)}>
                            <%= Presentation.human_time(run.started_at) %>
                          </time>
                        <% else %>
                          <span class="tl-muted">Not started</span>
                        <% end %>
                      </td>
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

    defp assign_runs(socket, runs) do
      socket
      |> stream(:runs, runs)
      |> assign(:runs_summary, summarize_runs(runs))
    end

    defp summarize_runs([run | _] = runs) do
      %{
        latest_status: Presentation.status_label(run.status),
        total_deleted: Enum.reduce(runs, 0, &((&1.deleted_count || 0) + &2)),
        failure_count: Enum.count(runs, &(&1.status == "failed"))
      }
    end

    defp summarize_runs(_) do
      %{latest_status: "None", total_deleted: 0, failure_count: 0}
    end
  end
end
