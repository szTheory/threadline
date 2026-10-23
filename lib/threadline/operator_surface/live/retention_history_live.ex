if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RetentionHistoryLive do
    @moduledoc false

    use Phoenix.LiveView

    # This page owns the form policy for its destructive "Prune now" action. The
    # server-enforced type-to-confirm flow has one modal form and one confirmation
    # text input.
    Module.register_attribute(__MODULE__, :ui_form_policy, persist: true)
    @ui_form_policy {:has_forms, "type-to-confirm prune modal (security-mandated)"}

    import Ecto.Query

    alias Phoenix.LiveView.JS
    alias Threadline.Governance.RetentionRun
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI
    alias Threadline.OperatorSurface.Unsupported
    alias Threadline.Retention.Pruner
    alias Threadline.Semantics.ActorRef
    alias Threadline.StorageSchema

    @default_limit 40

    # The retention policy is a process-wide singleton (one config, no per-row
    # policy table), so the object's own stable identifier is its canonical policy
    # name. The operator types this to confirm the irreversible prune;
    # the handler re-derives it SERVER-SIDE at action time and never trusts a
    # client-supplied value. It is the only thing rendered into the prompt — the
    # comparison runs against this server constant, never a client claim.
    @canonical_policy_name "default"

    def mount(_params, _session, socket) do
      socket =
        socket
        |> assign(:base_path, nil)
        |> assign(:prune_modal_open, false)
        |> assign(:prune_confirmation_error, nil)
        |> assign(:prune_submitting, false)
        |> assign(:mutation_revision, nil)
        |> assign(:runs_state, :loading)
        |> assign(:runs_summary, summarize_runs([]))
        |> assign(:runs_count, 0)
        |> assign(:default_limit, @default_limit)
        |> stream(:runs, [])

      socket =
        if connected?(socket) do
          if socket.assigns[:threadline_policy_enabled] do
            send(self(), :load_runs)
            schedule_refresh(socket)
          else
            socket
          end
        else
          load_runs(socket)
        end

      {:ok, socket}
    end

    def handle_params(_params, uri, socket) do
      uri_parsed = URI.parse(uri)
      base_path = (uri_parsed.path || "") |> String.replace_suffix("/policy/retention", "")
      {:noreply, assign(socket, :base_path, base_path)}
    end

    # Type-to-confirm prune with full server-side enforcement.
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
    #   4. audit the destructive action itself as an `AuditAction`
    #      BEFORE triggering — an audit-insert failure must abort the prune so
    #      there is never an unaudited operator-triggered deletion; audit runs only after
    #      a valid `secure_compare`, so a forged token still records nothing;
    #   5. trigger the real backend (`Pruner.trigger/0`) once the action is on
    #      the audit trail;
    #   6. fail closed — the default path on ANY mismatch is refusal, no prune.
    def handle_event("prune_now", _params, %{assigns: %{prune_submitting: true}} = socket) do
      {:noreply,
       put_flash(
         socket,
         :error,
         "A retention prune is already in progress. Follow its persisted status here."
       )}
    end

    def handle_event("prune_now", params, socket) do
      typed = confirm_param(params)

      with :ok <- authorize_prune(socket),
           canonical <- @canonical_policy_name,
           true <- Plug.Crypto.secure_compare(typed, canonical),
           {:ok, _action} <- audit_prune(socket, canonical),
           :ok <- Pruner.trigger() do
        # The pruner acknowledges only after the queued row is persisted. Read it
        # back so the operator follows persisted state rather than a flash claim.
        Process.send_after(self(), :refresh, 500)

        {:noreply,
         socket
         |> load_runs()
         |> assign(:prune_modal_open, false)
         |> assign(:prune_confirmation_error, nil)
         |> put_flash(:info, "Prune request accepted. Follow its persisted status here.")}
      else
        {:error, :not_started} ->
          {:noreply,
           socket
           |> put_flash(:error, "Retention runtime is unavailable. Refresh and try again.")}

        {:error, :unavailable} ->
          {:noreply,
           socket
           |> put_flash(:error, "Prune could not be queued. Refresh the history and try again.")}

        {:error, :audit_failed} ->
          {:noreply,
           socket
           |> put_flash(
             :error,
             "Prune could not start because its audit record could not be saved."
           )}

        {:error, :unauthorized} ->
          {:noreply,
           socket
           |> assign(:prune_modal_open, false)
           |> assign(:prune_confirmation_error, nil)
           |> put_flash(
             :error,
             "You are not authorized to start this retention prune. Refresh the history or contact your administrator."
           )}

        false ->
          {:noreply,
           socket
           |> assign(:prune_modal_open, true)
           |> assign(
             :prune_confirmation_error,
             "The policy name did not match. Check the exact name and try again."
           )}

        _ ->
          # Fail closed on any unexpected backend response.
          {:noreply,
           socket
           |> assign(:prune_modal_open, false)
           |> assign(:prune_confirmation_error, nil)
           |> put_flash(
             :error,
             "The prune could not start. Refresh the retention history and try again."
           )}
      end
    end

    def handle_event("open_prune_modal", _params, socket) do
      {:noreply,
       socket
       |> assign(:prune_modal_open, true)
       |> assign(:prune_confirmation_error, nil)}
    end

    def handle_event("close_prune_modal", _params, socket) do
      {:noreply,
       socket
       |> assign(:prune_modal_open, false)
       |> assign(:prune_confirmation_error, nil)}
    end

    def handle_event("refresh_runs", _params, socket) do
      {:noreply, load_runs(socket)}
    end

    def handle_info(:load_runs, socket) do
      {:noreply, load_runs(socket)}
    end

    def handle_info(:refresh, socket) do
      if socket.assigns[:threadline_policy_enabled] do
        {:noreply, socket |> schedule_refresh() |> load_runs()}
      else
        {:noreply, socket}
      end
    end

    def terminate(_reason, socket) do
      cancel_refresh(socket)
      :ok
    end

    def render(assigns) do
      assigns =
        assigns
        |> assign(:retention_summary, retention_window_summary(assigns[:runs_summary]))
        |> assign(:retention_actions, retention_contextual_actions(assigns))
        |> assign(:prune_copy, prune_modal_copy(@canonical_policy_name))

      ~H"""
      <UI.Page.shell
        theme={@threadline_theme}
        coverage={@threadline_coverage || %{uncovered_count: 0}}
        base_path={@base_path}
        coverage_enabled={@threadline_coverage_enabled}
        policy_enabled={@threadline_policy_enabled}
        evidence_enabled={@threadline_evidence_enabled}
        exports_enabled={@threadline_exports_enabled}
        current={:retention}
        script
        main_class="tl-page"
      >
          <span hidden data-tl-mutation-revision={@mutation_revision}></span>
          <%= if @threadline_policy_enabled do %>
            <UI.Page.page_header title="Retention window">
              <:lede>Review retention window pruning runs, failures, and evidence before triggering another destructive retention pass.</:lede>
              <:actions>
                <.link :if={@retention_actions.evidence_path} navigate={@retention_actions.evidence_path} class="tl-button tl-button--compact tl-button--secondary">
                  <Threadline.OperatorSurface.Components.Icon.icon name={:evidence} class="tl-button__icon" />
                  Review evidence
                </.link>
              </:actions>
            </UI.Page.page_header>

            <section class="tl-card" data-testid="retention-scope">
              <p class="tl-card__body"><%= @prune_copy.scope_explanation %></p>
            </section>

            <div :if={Phoenix.Flash.get(@flash, :error)} class="tl-alert tl-alert--error" role="alert">
              <%= Phoenix.Flash.get(@flash, :error) %>
            </div>
            <div :if={Phoenix.Flash.get(@flash, :info)} class="tl-alert tl-alert--success" role="status">
              <%= Phoenix.Flash.get(@flash, :info) %>
            </div>

            <%= case @runs_state do %>
              <% :loading -> %>
                <UI.Data.loading_state>Loading retention runs…</UI.Data.loading_state>
              <% :error -> %>
                <UI.Data.error_state>
                  <:title>Retention history could not be loaded</:title>
                  The saved runs are unchanged. Refresh to check their current status.
                  <:actions>
                    <button type="button" class="tl-button tl-button--secondary" phx-click="refresh_runs">
                      <Threadline.OperatorSurface.Components.Icon.icon name={:refresh} class="tl-button__icon" />
                      Refresh retention history
                    </button>
                  </:actions>
                </UI.Data.error_state>
              <% :empty -> %>
                <UI.Data.empty_state variant="never" role="status">
                  <:title>No retention runs</:title>
                  A run will appear here after a confirmed prune or scheduled retention operation.
                  <:actions>
                    <button
                      type="button"
                      class="tl-button tl-button--secondary"
                      phx-click={JS.push_focus() |> JS.push("open_prune_modal")}
                    >
                      <Threadline.OperatorSurface.Components.Icon.icon name={:trash} class="tl-button__icon" />
                      <%= @prune_copy.open_label %>
                    </button>
                  </:actions>
                </UI.Data.empty_state>
              <% :loaded -> %>
                <.run_history
                  retention_summary={@retention_summary}
                  retention_actions={@retention_actions}
                  prune_copy={@prune_copy}
                  runs={@streams.runs}
                  runs_count={@runs_count}
                  default_limit={@default_limit}
                />
            <% end %>

            <%!-- Type-to-confirm modal. The operator types the
                  policy NAME (the object's own identifier) to confirm; the
                  canonical token is re-derived and compared SERVER-SIDE in the
                  prune_now handler and is never shipped to the client for a
                  client-side comparison. The danger button copy names the
                  irreversible consequence (not "Continue"). --%>
            <.prune_modal
              :if={@prune_modal_open}
              prune_copy={@prune_copy}
              submitting={@prune_submitting}
              confirmation_error={@prune_confirmation_error}
            />
          <% else %>
            <Threadline.OperatorSurface.Components.UnsupportedView.unsupported_view
              descriptor={Unsupported.descriptor(:retention_unavailable)}
              base_path={@base_path}
            />
          <% end %>
      </UI.Page.shell>
      """
    end

    attr(:retention_summary, :map, required: true)
    attr(:retention_actions, :map, required: true)
    attr(:prune_copy, :map, required: true)
    attr(:runs, :any, required: true)
    attr(:runs_count, :integer, required: true)
    attr(:default_limit, :integer, required: true)

    defp run_history(assigns) do
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
              <div class="tl-page__actions">
                <button
                  type="button"
                  class="tl-button tl-button--secondary"
                  phx-click={JS.push_focus() |> JS.push("open_prune_modal")}
                >
                  <Threadline.OperatorSurface.Components.Icon.icon name={:trash} class="tl-button__icon" />
                  <%= @prune_copy.open_label %>
                </button>
              </div>

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
                  stream={@runs}
                  tbody_id="retention-runs"
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
                      <span class="tl-muted">Not started</span>
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

    attr(:prune_copy, :map, required: true)
    attr(:submitting, :boolean, required: true)
    attr(:confirmation_error, :string, default: nil)

    defp prune_modal(assigns) do
      ~H"""
            <UI.Overlay.modal id="prune-confirm" show={true} on_cancel={JS.push("close_prune_modal")}>
              <h2 id="prune-confirm-title" class="tl-modal__title"><%= @prune_copy.title %></h2>
              <p id="prune-confirm-description" class="tl-modal__body">
                <%= @prune_copy.scope_explanation %>
                To confirm, type the policy name “<%= @prune_copy.policy_name %>” exactly. This action cannot be undone.
              </p>
              <form phx-submit="prune_now" class="tl-form">
                <label class="tl-field">
                  <span class="tl-field__label">Type the policy name “<code><%= @prune_copy.policy_name %></code>” to confirm</span>
                  <input
                    id="prune-confirm-input"
                    type="text"
                    name="confirm"
                    autocomplete="off"
                    class="tl-control"
                    aria-label="Policy name to confirm"
                    aria-describedby={if(@confirmation_error, do: "prune-confirm-error", else: nil)}
                    aria-invalid={@confirmation_error != nil}
                    required
                    data-tl-initial-focus
                  />
                </label>
                <p
                  :if={@confirmation_error}
                  id="prune-confirm-error"
                  class="tl-alert tl-alert--error"
                  role="alert"
                >
                  <%= @confirmation_error %>
                </p>
                <div class="tl-modal__actions">
                  <button type="button" class="tl-button tl-button--secondary" phx-click={JS.push("close_prune_modal")}>
                    <%= @prune_copy.cancel_label %>
                  </button>
                  <button type="submit" class="tl-button tl-button--danger" data-tl-mutating data-tl-server-disabled={if(@submitting, do: "true", else: "false")} disabled={@submitting} phx-disable-with="Starting prune…">
                    <Threadline.OperatorSurface.Components.Icon.icon name={:trash} class="tl-button__icon" />
                    <%= @prune_copy.submit_label %>
                  </button>
                </div>
              </form>
            </UI.Overlay.modal>
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
      case socket.assigns[:threadline_policy_authorize_fn] do
        authorize_fn when is_function(authorize_fn, 1) ->
          mirror = %{assigns: socket.assigns}

          case authorize_fn.(mirror) do
            :ok -> :ok
            true -> :ok
            {:ok, _scope} -> :ok
            _ -> {:error, :unauthorized}
          end

        _ ->
          {:error, :unauthorized}
      end
    rescue
      _ -> {:error, :unauthorized}
    end

    # Audit the operator's request only after authorization and confirmation
    # succeed, and before starting the prune. The backend records completed
    # deletion totals only after the purge succeeds.
    defp audit_prune(socket, policy_name) do
      case socket.assigns[:threadline_actor_ref] do
        %ActorRef{} = actor ->
          if ActorRef.identifiable?(actor) do
            record_prune_action(socket, actor, policy_name)
          else
            {:error, :audit_failed}
          end

        _ ->
          {:error, :unauthorized}
      end
    rescue
      _ -> {:error, :audit_failed}
    end

    defp record_prune_action(socket, actor, policy_name) do
      case Threadline.record_action(:"retention.pruned",
             repo: resolve_repo(socket),
             actor: actor,
             comment: "Operator-triggered retention prune for policy #{policy_name}",
             storage_schema: StorageSchema.get()
           ) do
        {:ok, action} -> {:ok, action}
        {:error, _reason} -> {:error, :audit_failed}
      end
    end

    defp fetch_runs(socket) do
      if socket.assigns[:threadline_policy_enabled] do
        repo = resolve_repo(socket)

        from(r in RetentionRun, order_by: [desc: r.inserted_at], limit: @default_limit)
        |> repo.all(storage_opts(socket))
        |> then(&{:ok, &1})
      else
        {:ok, []}
      end
    rescue
      _error -> {:error, :read_failed}
    catch
      _kind, _reason -> {:error, :read_failed}
    end

    defp schedule_refresh(socket) do
      cancel_refresh(socket)

      interval =
        socket.assigns[:threadline_retention_poll_ms] ||
          Application.get_env(:threadline, :retention_poll_ms, 5_000)

      timer_ref = Process.send_after(self(), :refresh, interval)
      assign(socket, :threadline_retention_timer_ref, timer_ref)
    end

    defp cancel_refresh(socket) do
      if timer_ref = socket.assigns[:threadline_retention_timer_ref] do
        case Process.cancel_timer(timer_ref) do
          _result -> :ok
        end
      end

      :ok
    end

    defp resolve_repo(socket) do
      socket.assigns[:threadline_repo] ||
        Application.get_env(:threadline, :ecto_repos, []) |> List.first() || Threadline.Repo
    end

    defp storage_opts(_socket), do: StorageSchema.repo_opts(storage_schema: StorageSchema.get())

    defp load_runs(socket), do: assign_runs(socket, fetch_runs(socket))

    defp assign_runs(socket, {:ok, runs}) do
      socket
      |> stream(:runs, runs, reset: true)
      |> assign(:mutation_revision, mutation_revision())
      |> assign(:prune_submitting, Enum.any?(runs, &(&1.status in ["queued", "running"])))
      |> assign(:runs_state, if(runs == [], do: :empty, else: :loaded))
      |> assign(:runs_summary, summarize_runs(runs))
      |> assign(:runs_count, length(runs))
      |> assign(:default_limit, @default_limit)
    end

    defp assign_runs(socket, {:error, _reason}) do
      assign(socket, :runs_state, :error)
    end

    defp mutation_revision do
      System.unique_integer([:positive, :monotonic])
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

    defp retention_window_summary(runs_summary) do
      %{
        latest_status: runs_summary.latest_status,
        latest_at: runs_summary.latest_at,
        latest_completed: latest_completed_label(runs_summary.latest_completed_at),
        healthy?: runs_summary.healthy?,
        total_deleted: runs_summary.total_deleted,
        failure_count: runs_summary.failure_count,
        first_failed_dom_id: runs_summary.first_failed_dom_id
      }
    end

    defp retention_contextual_actions(assigns) do
      evidence_path =
        if assigns[:threadline_evidence_enabled] and assigns[:base_path] do
          "#{assigns[:base_path]}/evidence?subject=retention_run"
        end

      %{evidence_path: evidence_path}
    end

    defp prune_modal_copy(policy_name) do
      %{
        open_label: "Prune now",
        title: "Prune retained audit data?",
        scope_explanation:
          "This prune applies the configured retention policy globally to the configured Threadline storage schema. At execution, it removes AuditChange rows strictly older than the policy cutoff and may also remove empty AuditTransaction rows when configured. The current operator or tenant scope does not limit this prune. This history does not record a preview count or the cutoff used for this run.",
        policy_name: policy_name,
        cancel_label: "Keep audit data",
        submit_label: "Prune now"
      }
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

    defp latest_completed_label(nil), do: "No completed run yet"
    defp latest_completed_label(%DateTime{} = value), do: Presentation.human_time(value)

    defp count_label(nil), do: "No rows deleted"
    defp count_label(value), do: value

    defp duration_label(nil), do: "No duration yet"
    defp duration_label(value), do: "#{value}ms"
  end
end
