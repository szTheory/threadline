if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RetentionHistoryLive do
    @moduledoc false

    use Phoenix.LiveView
    import Ecto.Query

    alias Phoenix.LiveView.JS
    alias Threadline.Governance.RetentionRun
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI
    alias Threadline.OperatorSurface.Unsupported
    alias Threadline.Semantics.ActorRef
    alias Threadline.StorageSchema
    alias Threadline.Retention.Pruner

    @default_limit 40

    # The retention policy is a process-wide singleton (one config, no per-row
    # policy table), so the object's OWN identifier (D-20) is its canonical
    # policy name. The operator types this to confirm the irreversible prune;
    # the handler re-derives it SERVER-SIDE at action time and never trusts a
    # client-supplied value. It is the only thing rendered into the prompt — the
    # comparison runs against this server constant, never a client claim.
    @canonical_policy_name "default"

    def mount(_params, _session, socket) do
      if connected?(socket) and socket.assigns[:threadline_policy_enabled] do
        schedule_refresh(socket)
      end

      socket =
        socket
        |> assign(:base_path, nil)
        |> assign(:prune_modal_open, false)
        |> assign_runs(fetch_runs(socket))
        |> assign(:has_runs, has_runs?(socket))

      {:ok, socket}
    end

    def handle_params(_params, uri, socket) do
      uri_parsed = URI.parse(uri)
      base_path = (uri_parsed.path || "") |> String.replace_suffix("/policy/retention", "")
      {:noreply, assign(socket, :base_path, base_path)}
    end

    # T3 type-to-confirm prune with FULL server-side enforcement (DATA-04, D-21).
    #
    # The client signal is untrusted from end to end: the typed confirmation and
    # any `phx-value-id` are claims, never grants. Every irreversible prune,
    # independent of any client-side confirm, must, in order:
    #   1. re-check authorization in the event (policy access can change between
    #      mount and submit; a forged id is not a grant);
    #   2. re-derive the CANONICAL confirmation token server-side (never shipped
    #      to the client to compare client-side; `phx-value-id` is ignored as a
    #      scope grant so a forged scope fails closed);
    #   3. `Plug.Crypto.secure_compare/2` the typed value against the canonical
    #      token (constant-time — never a hand-rolled `==`);
    #   4. audit the destructive action itself as an `AuditAction` (§9.3.4)
    #      BEFORE triggering — an audit-insert failure must abort the prune so
    #      there is never an unaudited deletion (D-21.3); audit runs only after
    #      a valid `secure_compare`, so a forged token still records nothing;
    #   5. trigger the real backend (`Pruner.trigger/0`) once the action is on
    #      the audit trail;
    #   6. fail closed — the default path on ANY mismatch is refusal, no prune.
    def handle_event("prune_now", params, socket) do
      typed = confirm_param(params)

      with :ok <- authorize_prune(socket),
           canonical <- @canonical_policy_name,
           true <- Plug.Crypto.secure_compare(typed, canonical),
           {:ok, _action} <- audit_prune(socket, canonical),
           :ok <- Pruner.trigger() do
        # Schedule a quick refresh to see the new run pop up.
        Process.send_after(self(), :refresh, 500)

        {:noreply,
         socket
         |> assign(:prune_modal_open, false)
         |> put_flash(:info, "Retention prune started. Follow retention runs here.")}
      else
        {:error, :not_started} ->
          {:noreply,
           socket
           |> assign(:prune_modal_open, false)
           |> put_flash(:error, "Retention runtime is not started.")}

        _ ->
          # Fail closed: token mismatch, forged id, or missing authorization.
          # No prune is performed and no destructive action is audited.
          {:noreply,
           socket
           |> assign(:prune_modal_open, false)
           |> put_flash(:error, "Could not prune — confirmation did not match.")}
      end
    end

    def handle_event("open_prune_modal", _params, socket) do
      {:noreply, assign(socket, :prune_modal_open, true)}
    end

    def handle_event("close_prune_modal", _params, socket) do
      {:noreply, assign(socket, :prune_modal_open, false)}
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
          |> assign(:runs_count, length(runs))
          |> assign(:default_limit, @default_limit)

        {:noreply, socket}
      end
    end

    def render(assigns) do
      ~H"""
      <UI.shell
        theme={@threadline_theme}
        coverage={@threadline_coverage || %{uncovered_count: 0}}
        base_path={@base_path}
        coverage_enabled={@threadline_coverage_enabled}
        policy_enabled={@threadline_policy_enabled}
        evidence_enabled={@threadline_evidence_enabled}
        exports_enabled={@threadline_exports_enabled}
        current={:retention}
        main_class="tl-page"
      >
          <%= if @threadline_policy_enabled do %>
            <UI.page_header title="Retention window">
              <:lede>Review retention window pruning runs, failures, and evidence before triggering another destructive retention pass.</:lede>
            </UI.page_header>

            <section class="tl-trust-rail" aria-label="Retention context">
              <span class="tl-trust-rail__label">Retention window</span>
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
                <p class="tl-empty__body">Configure a retention window, run a dry-run first with <code>mix threadline.retention.purge --dry-run</code>, then trigger a prune to record evidence here.</p>
                <div class="tl-empty__actions">
                  <button
                    type="button"
                    class="tl-button tl-button--secondary tl-button--danger"
                    phx-click={JS.push_focus() |> JS.push("open_prune_modal")}
                  >
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
                  Latest run succeeded<%= if @runs_summary.latest_at do %> <%= Presentation.human_time(@runs_summary.latest_at) %><% end %> — the retention window is healthy. Pruning permanently deletes older audit records by policy, so review before running another.
                </div>
              <% else %>
                <div class="tl-alert tl-alert--warning" role="status">
                  Review the latest status and failure count before running another prune. Pruning permanently deletes older audit records by policy.
                </div>
              <% end %>

              <div class="tl-page__actions">
                <span class="tl-hint">Retention window destructive action</span>
                <button
                  type="button"
                  class="tl-button tl-button--secondary tl-button--danger"
                  phx-click={JS.push_focus() |> JS.push("open_prune_modal")}
                >
                  <Threadline.OperatorSurface.Components.Icon.icon name={:trash} class="tl-button__icon" />
                  Run retention prune
                </button>
              </div>

              <%!-- Honest cap caption (D-20, WR-04/WR-05): Retention is recent-only /
                    low-volume, not a keyset pager. Report the actual rendered count
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
                <UI.data_table
                  class="tl-table--retention tl-table--compact tl-table--sticky"
                  stream={@streams.runs}
                  tbody_id="retention-runs"
                  row_id={fn {dom_id, _run} -> dom_id end}
                  row_status={fn {_dom_id, run} -> run.status end}
                  data-testid="retention-runs-table-el"
                >
                  <:col :let={{_dom_id, run}} label="Run">
                    <UI.ref value={"retention_run/#{run.id}"} kind="actor" copy_label="Copy retention run id" />
                  </:col>
                  <:col :let={{_dom_id, run}} label="Status">
                    <span class={["tl-chip", Presentation.status_modifier(run.status)]}><%= Presentation.status_label(run.status) %></span>
                  </:col>
                  <:col :let={{_dom_id, run}} label="Deleted Rows"><%= count_label(run.deleted_count) %></:col>
                  <:col :let={{_dom_id, run}} label="Duration"><%= duration_label(run.duration_ms) %></:col>
                  <:col :let={{_dom_id, run}} label="Date">
                    <%= if run.started_at do %>
                      <time datetime={Presentation.exact_time(run.started_at)} title={Presentation.exact_time(run.started_at)}>
                        <%= Presentation.human_time(run.started_at) %>
                      </time>
                    <% else %>
                      <span class="tl-muted">Not started</span>
                    <% end %>
                  </:col>
                  <:action :let={{_dom_id, _run}}>
                    <UI.dropdown id={"run-actions-#{System.unique_integer([:positive])}"} class="tl-table__actions">
                      <:trigger>
                        <span class="tl-button tl-button--compact tl-button--ghost" aria-label="Run actions">
                          <Threadline.OperatorSurface.Components.Icon.icon name={:kebab} class="tl-button__icon" />
                        </span>
                      </:trigger>
                      <.link :if={@threadline_evidence_enabled} navigate={"#{@base_path}/evidence?subject=retention_run"} role="menuitem" class="tl-button tl-button--compact tl-button--secondary">
                        <Threadline.OperatorSurface.Components.Icon.icon name={:evidence} class="tl-button__icon" />
                        Review evidence
                      </.link>
                      <UI.divider />
                      <button
                        type="button"
                        role="menuitem"
                        class="tl-button tl-button--compact tl-button--danger"
                        phx-click={JS.push_focus() |> JS.push("open_prune_modal")}
                      >
                        <Threadline.OperatorSurface.Components.Icon.icon name={:trash} class="tl-button__icon" />
                        Prune records permanently
                      </button>
                    </UI.dropdown>
                  </:action>
                </UI.data_table>
              </div>
            <% end %>

            <%!-- T3 type-to-confirm modal (D-20/D-21). The operator types the
                  policy NAME (the object's own identifier) to confirm; the
                  canonical token is re-derived and compared SERVER-SIDE in the
                  prune_now handler and is never shipped to the client for a
                  client-side comparison. The danger button copy names the
                  irreversible consequence (not "Continue"). --%>
            <UI.modal :if={@prune_modal_open} id="prune-confirm" show={true} on_cancel={JS.push("close_prune_modal")}>
              <h2 id="prune-confirm-title" class="tl-modal__title">Prune retention window permanently?</h2>
              <p id="prune-confirm-description" class="tl-modal__body">
                This permanently deletes audit records older than the retention window for policy <code>default</code>; it cannot be undone.
                To confirm, type the policy name <code>default</code> exactly.
              </p>
              <form phx-submit="prune_now" class="tl-form">
                <label class="tl-field">
                  <span class="tl-field__label">Type the policy name <code>default</code> to confirm</span>
                  <input
                    id="prune-confirm-input"
                    type="text"
                    name="confirm"
                    autocomplete="off"
                    class="tl-control"
                    aria-label="Policy name to confirm"
                    data-tl-initial-focus
                  />
                </label>
                <div class="tl-modal__actions">
                  <button type="button" class="tl-button tl-button--secondary" phx-click={JS.push("close_prune_modal")}>
                    Cancel
                  </button>
                  <button type="submit" class="tl-button tl-button--danger" data-tl-mutating>
                    <Threadline.OperatorSurface.Components.Icon.icon name={:trash} class="tl-button__icon" />
                    Prune records permanently
                  </button>
                </div>
              </form>
            </UI.modal>
          <% else %>
            <Threadline.OperatorSurface.Components.UnsupportedView.unsupported_view
              descriptor={Unsupported.descriptor(:retention_unavailable)}
              base_path={@base_path}
            />
          <% end %>
      </UI.shell>
      """
    end

    # The typed confirmation can arrive under `confirm` (form field) and is the
    # only client value we read for the comparison. Anything else (e.g. a forged
    # `phx-value-id`) is deliberately ignored as a scope grant.
    defp confirm_param(%{"confirm" => typed}) when is_binary(typed), do: typed
    defp confirm_param(_params), do: ""

    # Re-check authorization at action time. `phx-value-id` is an untrusted claim,
    # so authorization is derived only from the server-resolved policy gate.
    defp authorize_prune(socket) do
      if socket.assigns[:threadline_policy_enabled], do: :ok, else: {:error, :unauthorized}
    end

    # Audit the destructive action itself (D-21.3 / domain §9.3.4): a successful
    # prune records an `AuditAction` so the irreversible operation is never
    # unattributable. The retention runtime is a system actor.
    defp audit_prune(socket, policy_name) do
      {:ok, actor} = ActorRef.new(:system, "retention_pruner")

      Threadline.record_action(:"retention.pruned",
        repo: resolve_repo(socket),
        actor: actor,
        comment: "Operator-triggered retention prune for policy #{policy_name}"
      )
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
      |> assign(:runs_count, length(runs))
      |> assign(:default_limit, @default_limit)
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
