if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RetentionHistoryLive.Components do
    @moduledoc false
    use Phoenix.Component
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI

    attr(:retention_summary, :map, required: true)
    attr(:retention_actions, :map, required: true)
    attr(:runs, :any, required: true)
    attr(:runs_count, :integer, required: true)
    attr(:default_limit, :integer, required: true)

    attr(:streamed, :boolean, default: true)
    attr(:table_id, :string, default: "retention-runs")

    def run_history(assigns) do
      ~H"""
              <section class="tl-summary-grid" aria-label="Retention window health">
                <div class="tl-card--metric">
                  <span class="tl-card__metric-label">Latest run</span>
                  <strong class="tl-card__metric"><%= @retention_summary.latest_status %></strong>
                </div>
                <div class="tl-card--metric">
                  <span class="tl-card__metric-label">Latest completed run</span>
                  <strong class="tl-card__metric"><%= @retention_summary.latest_completed %></strong>
                </div>
                <div class="tl-card--metric">
                  <span class="tl-card__metric-label">Rows deleted in recent runs</span>
                  <strong class="tl-card__metric"><%= @retention_summary.total_deleted %></strong>
                </div>
                <div class="tl-card--metric" data-status={if @retention_summary.failure_count > 0, do: "danger"}>
                  <span class="tl-card__metric-label">Failures</span>
                  <strong class="tl-card__metric">
                    <%= if @retention_summary.first_failed_dom_id do %>
                      <a href={"##{@retention_summary.first_failed_dom_id}"} class="tl-link tl-link--deep"><%= @retention_summary.failure_count %></a>
                    <% else %>
                      <%= @retention_summary.failure_count %>
                    <% end %>
                  </strong>
                </div>
              </section>

              <%!-- Signal-to-chrome rule: no status alert and no
              "destructive action" self-label here. The stat cards above already carry
              latest status + failure count (with a danger state and a deep link), and
              the type-to-confirm prune modal delivers the destructive warning at the
              point of action — restating either as banner prose is chrome. --%>


              <%!-- Retention is a recent-only, low-volume view, not a keyset pager.
                    Report the actual rendered count
                    (never over-claim against a short table) and, when the cap is hit,
                    interpolate the real @default_limit rather than a hardcoded literal. --%>
              <p class="tl-status" role="status" aria-live="polite">
                <%= if @runs_count >= @default_limit do %>
                  Showing the most recent <%= @default_limit %> retention runs (newest first).
                <% else %>
                  Showing the most recent <%= @runs_count %> <%= if @runs_count == 1, do: "retention run", else: "retention runs" %> (newest first).
                <% end %>
              </p>
              <div class="tl-table-wrap" data-testid="retention-runs-table">
                <UI.Data.data_table
                  class="tl-table--retention tl-table--compact tl-table--sticky"
                  rows={if @streamed, do: nil, else: @runs}
                  stream={if @streamed, do: @runs, else: nil}
                  tbody_id={@table_id}
                  row_id={fn {dom_id, _run} -> dom_id end}
                  row_status={fn {_dom_id, run} -> run.status end}
                  data-testid="retention-runs-table-el"
                >
                  <:col :let={{_dom_id, run}} label="Run">
                    <UI.Display.ref value={"retention_run/#{run.id}"} kind="actor" copy_label="Copy retention run id" />
                  </:col>
                  <:col :let={{_dom_id, run}} label="Status">
                    <span class={["tl-chip", Presentation.status_modifier(run.status)]}><%= Presentation.status_label(run.status) %></span>
                  </:col>
                  <:col :let={{_dom_id, run}} label="Deleted Rows"><%= count_label(run.deleted_count) %></:col>
                  <:col :let={{_dom_id, run}} label="Duration"><%= duration_label(run.duration_ms) %></:col>
                  <:col :let={{_dom_id, run}} label="Outcome">
                    <%= if run.status == "failed" do %>
                      <span class="tl-retention-failure">
                        <%= failure_summary(run) %>
                      </span>
                    <% else %>
                      <span class="tl-muted">No additional outcome details</span>
                    <% end %>
                  </:col>
                  <:col :let={{_dom_id, run}} label="Date">
                    <%= if run.started_at do %>
                      <time datetime={Presentation.exact_time(run.started_at)} title={Presentation.exact_time(run.started_at)}>
                        <%= Presentation.human_time(run.started_at) %>
                      </time>
                    <% else %>
                      <span class="tl-muted">No start time recorded</span>
                    <% end %>
                  </:col>
                  <:action :let={{_dom_id, _run}}>
                    <.link :if={@retention_actions.evidence_path} navigate={@retention_actions.evidence_path} class="tl-button tl-button--compact tl-button--secondary">
                      <Threadline.OperatorSurface.Components.Icon.icon name={:evidence} class="tl-button__icon" />
                      Review evidence
                    </.link>
                  </:action>
                </UI.Data.data_table>
              </div>
      """
    end

    attr(:preview, :map, default: nil)
    attr(:state, :atom, required: true)

    def retention_preview(assigns) do
      ~H"""
      <p :if={@state == :loading} role="status">Generating retention preview…</p>
      <p :if={@state == :error} class="tl-alert tl-alert--error" role="alert">Retention preview is unavailable. No counts are shown and a prune cannot be started from this view. Refresh the history and try the preview again; if it keeps failing, contact your administrator.</p>
      <section :if={@state == :ready and @preview} class="tl-card" data-testid="retention-preview" aria-label="Retention preview">
        <h2 class="tl-card__title">Retention preview</h2>
        <dl>
          <dt>Estimated AuditChange candidates</dt><dd><%= @preview.result.deleted_changes %></dd>
          <dt>Estimated empty AuditTransaction candidates</dt>
          <dd :if={@preview.policy.delete_empty_transactions}><%= @preview.result.deleted_transactions %></dd>
          <dd :if={not @preview.policy.delete_empty_transactions}>Empty-transaction cleanup is disabled, so empty AuditTransaction candidates are not included in this estimate.</dd>
        </dl>
        <p>Preview generated at <time datetime={DateTime.to_iso8601(@preview.generated_at)}><%= Calendar.strftime(@preview.generated_at, "%Y-%m-%d %H:%M:%S.%f") %> UTC</time>.</p>
        <p>All eligible history in the worker's configured Threadline audit store is included. The current user or tenant scope does not narrow this estimate.</p>
        <p>These counts are sequential estimates, not a snapshot. History and settings may change before the run. The worker recomputes its cutoff later; batch limits apply to the run, not these counts. Actual removals may differ.</p>
      </section>
      """
    end

    defp safe_failure_category("prune_error"), do: "prune error"
    defp safe_failure_category("invalid_policy"), do: "invalid policy"
    defp safe_failure_category("disabled"), do: "policy disabled"
    defp safe_failure_category("Abandoned"), do: "abandoned"
    defp safe_failure_category(_), do: "prune error"

    defp failure_summary(run) do
      deleted = run.deleted_count || 0
      noun = if deleted == 1, do: "row was", else: "rows were"

      "Retention prune failed (#{safe_failure_category(run.error_message)}). #{deleted} #{noun} deleted before the failure. Review this run and resolve the reported category before starting another prune."
    end

    defp count_label(nil), do: "No deletion count recorded"
    defp count_label(value), do: value

    defp duration_label(nil), do: "No duration recorded"
    defp duration_label(value), do: "#{value}ms"
  end
end
