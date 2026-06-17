if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RetentionHistoryLive do
    @moduledoc false

    use Phoenix.LiveView
    import Ecto.Query

    alias Threadline.Governance.RetentionRun
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI
    alias Threadline.OperatorSurface.Unsupported
    alias Threadline.StorageSchema
    alias Threadline.Retention.Pruner

    @default_limit 40

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
      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
        <Threadline.OperatorSurface.Style.css />
        <%= if @base_path do %>
          <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
          theme={@threadline_theme}
            coverage={@threadline_coverage || %{uncovered_count: 0}}
            base_path={@base_path}
            coverage_enabled={@threadline_coverage_enabled}
            policy_enabled={@threadline_policy_enabled}
            evidence_enabled={@threadline_evidence_enabled}
            exports_enabled={@threadline_exports_enabled}
            current={:retention}
          />
        <% end %>

        <main id="tl-main" class="tl-page" tabindex="-1">
          <%= if @threadline_policy_enabled do %>
            <UI.page_header title="What was purged, and did it succeed?">
              <:lede>Review the latest completed purge, failures, and evidence before triggering another destructive retention pass.</:lede>
            </UI.page_header>

            <section class="tl-trust-rail" aria-label="Retention context">
              <span class="tl-trust-rail__label">Retention assurance</span>
              <span class="tl-chip tl-chip--warning">Permanent deletion</span>
              <.link :if={@threadline_evidence_enabled and @base_path} navigate={"#{@base_path}/evidence?subject=retention_run"} class="tl-button tl-button--compact tl-button--secondary">
                <Threadline.OperatorSurface.Components.Icon.icon name={:evidence} class="tl-button__icon" />
                Review evidence
              </.link>
              <.link :if={@base_path} navigate={"#{@base_path}/timeline"} class="tl-button tl-button--compact tl-button--ghost">
                <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
                Open timeline
              </.link>
            </section>

            <%= if not @has_runs do %>
              <div class="tl-empty">
                <h3 class="tl-empty__title">No retention runs yet</h3>
                <p class="tl-empty__body">Configure retention, run a dry-run first with <code>mix threadline.retention.purge --dry-run</code>, then trigger a prune to record evidence here.</p>
                <div class="tl-empty__actions">
                  <button class="tl-button tl-button--secondary tl-button--danger" phx-click="prune_now" data-confirm="Confirm retention prune. This permanently deletes older audit records; review the latest completed run and failure count first.">
                    <Threadline.OperatorSurface.Components.Icon.icon name={:trash} class="tl-button__icon" />
                    Run retention prune
                  </button>
                </div>
              </div>
            <% else %>
              <section class="tl-summary-grid" aria-label="Retention summary">
                <div class="tl-card--metric">
                  <span class="tl-card__metric-label">Latest run</span>
                  <strong class="tl-card__metric"><%= @runs_summary.latest_status %></strong>
                </div>
                <div class="tl-card--metric">
                  <span class="tl-card__metric-label">Latest completed run</span>
                  <strong class="tl-card__metric"><%= latest_completed_label(@runs_summary.latest_completed_at) %></strong>
                </div>
                <div class="tl-card--metric">
                  <span class="tl-card__metric-label">Rows deleted</span>
                  <strong class="tl-card__metric"><%= @runs_summary.total_deleted %></strong>
                </div>
                <div class="tl-card--metric" data-status={if @runs_summary.failure_count > 0, do: "danger"}>
                  <span class="tl-card__metric-label">Failures</span>
                  <strong class="tl-card__metric">
                    <%= if @runs_summary.first_failed_dom_id do %>
                      <a href={"##{@runs_summary.first_failed_dom_id}"} class="tl-link tl-link--deep"><%= @runs_summary.failure_count %></a>
                    <% else %>
                      <%= @runs_summary.failure_count %>
                    <% end %>
                  </strong>
                </div>
              </section>

              <%= if @runs_summary.healthy? do %>
                <div class="tl-alert tl-alert--success" role="status">
                  Latest run succeeded<%= if @runs_summary.latest_at do %> <%= Presentation.human_time(@runs_summary.latest_at) %><% end %> — retention is healthy. Pruning permanently deletes older audit records, so review before running another.
                </div>
              <% else %>
                <div class="tl-alert tl-alert--warning" role="status">
                  Review the latest status and failure count before running another prune. Retention deletes older audit records permanently.
                </div>
              <% end %>

              <div class="tl-page__actions">
                <span class="tl-hint">Permanent delete action</span>
                <button class="tl-button tl-button--secondary tl-button--danger" phx-click="prune_now" data-confirm="Confirm retention prune. This permanently deletes older audit records; review the latest completed run and failure count first.">
                  <Threadline.OperatorSurface.Components.Icon.icon name={:trash} class="tl-button__icon" />
                  Run retention prune
                </button>
              </div>

              <div class="tl-table-wrap" data-testid="retention-runs-table">
                <table class="tl-table tl-table--retention tl-table--compact tl-table--sticky tl-table--responsive">
                  <thead>
                    <tr>
                      <th>Status</th>
                      <th>Deleted Rows</th>
                      <th>Duration</th>
                      <th>Date</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody id="retention-runs" phx-update="stream" data-testid="retention-runs">
                    <tr :for={{dom_id, run} <- @streams.runs} id={dom_id} class={["tl-table__row--" <> run.status, if(run.status == "failed", do: "tl-target-row")]}>
                      <td data-label="Status"><span class={["tl-chip", Presentation.status_modifier(run.status)]}><%= Presentation.status_label(run.status) %></span></td>
                      <td data-label="Deleted Rows" class="tl-table__number"><%= count_label(run.deleted_count) %></td>
                      <td data-label="Duration" class="tl-table__number"><%= duration_label(run.duration_ms) %></td>
                      <td data-label="Date" class="tl-table__date">
                        <%= if run.started_at do %>
                          <time datetime={Presentation.exact_time(run.started_at)} title={Presentation.exact_time(run.started_at)}>
                            <%= Presentation.human_time(run.started_at) %>
                          </time>
                        <% else %>
                          <span class="tl-muted">Not started</span>
                        <% end %>
                      </td>
                      <td data-label="Actions" class="tl-table__actions">
                        <.link :if={@threadline_evidence_enabled} navigate={"#{@base_path}/evidence?subject=retention_run"} class="tl-button tl-button--compact tl-button--secondary">
                          <Threadline.OperatorSurface.Components.Icon.icon name={:evidence} class="tl-button__icon" />
                          Review evidence
                        </.link>
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
        |> repo.all(StorageSchema.repo_opts())
      end
    end

    defp has_runs?(socket) do
      if not socket.assigns[:threadline_policy_enabled] do
        false
      else
        repo = resolve_repo(socket)
        repo.exists?(from(r in RetentionRun), StorageSchema.repo_opts())
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
      failure_count = Enum.count(runs, &(&1.status == "failed"))
      latest_completed = Enum.find(runs, &(&1.status == "completed"))
      first_failed = Enum.find(runs, &(&1.status == "failed"))

      %{
        latest_status: Presentation.status_label(run.status),
        latest_at: run.started_at,
        latest_completed_at: latest_completed && latest_completed.completed_at,
        healthy?: failure_count == 0 and run.status == "completed",
        total_deleted: Enum.reduce(runs, 0, &((&1.deleted_count || 0) + &2)),
        failure_count: failure_count,
        first_failed_dom_id: first_failed && "runs-#{first_failed.id}"
      }
    end

    defp summarize_runs(_) do
      %{
        latest_status: "None",
        latest_at: nil,
        latest_completed_at: nil,
        healthy?: false,
        total_deleted: 0,
        failure_count: 0,
        first_failed_dom_id: nil
      }
    end

    defp latest_completed_label(nil), do: "No completed run yet"
    defp latest_completed_label(%DateTime{} = value), do: Presentation.human_time(value)

    defp count_label(nil), do: "No rows deleted"
    defp count_label(value), do: value

    defp duration_label(nil), do: "No duration yet"
    defp duration_label(value), do: "#{value}ms"
  end
end
