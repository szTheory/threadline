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
    alias Threadline.OperatorSurface.Live.RetentionHistoryLive.Components
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI
    alias Threadline.OperatorSurface.Unsupported
    alias Threadline.Retention.{Policy, Pruner}
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
        |> assign(:preview_state, :idle)
        |> assign(:preview, nil)
        |> assign(:preview_request, nil)
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
    #   5. trigger only the server-held preview target via `Pruner.trigger_if_target/1` once the action is on
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
           {:ok, preview} <- confirmed_preview(socket),
           canonical <- @canonical_policy_name,
           true <- Plug.Crypto.secure_compare(typed, canonical),
           :ok <- authorize_prune(socket),
           {:ok, _action} <- audit_prune(socket, canonical, preview.target),
           :ok <- Pruner.trigger_if_target(preview.target) do
        # The pruner acknowledges only after the queued row is persisted. Read it
        # back so the operator follows persisted state rather than a flash claim.
        Process.send_after(self(), :refresh, 500)

        {:noreply,
         socket
         |> clear_preview()
         |> load_runs()
         |> assign(:prune_modal_open, false)
         |> assign(:prune_confirmation_error, nil)
         |> put_flash(:info, "Prune request accepted. Follow its persisted status here.")}
      else
        {:error, :not_started} ->
          {:noreply,
           socket
           |> clear_preview()
           |> put_flash(:error, "Retention runtime is unavailable. Refresh and try again.")}

        {:error, :acceptance_unknown} ->
          Process.send_after(self(), :refresh, 500)

          {:noreply,
           socket
           |> clear_preview()
           |> load_runs()
           |> put_flash(
             :error,
             "The prune request could not be confirmed. It may still be queued. Refresh the history before making another deliberate request."
           )}

        {:error, :unavailable} ->
          {:noreply,
           socket
           |> clear_preview()
           |> put_flash(:error, "Prune could not be queued. Refresh the history and try again.")}

        {:error, :audit_failed} ->
          {:noreply,
           socket
           |> clear_preview()
           |> put_flash(
             :error,
             "Prune could not start because its audit record could not be saved."
           )}

        {:error, :unauthorized} ->
          {:noreply,
           socket
           |> clear_preview()
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
           |> clear_preview()
           |> assign(:prune_modal_open, false)
           |> assign(:prune_confirmation_error, nil)
           |> put_flash(
             :error,
             "The prune could not start. Refresh the retention history and try again."
           )}
      end
    end

    def handle_event("preview_retention", _params, socket) do
      socket = clear_preview(socket)

      with :ok <- authorize_prune(socket),
           {:ok, target, policy} <- preview_inputs(socket) do
        request = make_ref()
        socket = assign(socket, preview_state: :loading, preview_request: request)
        read_socket = socket

        {:noreply,
         start_async(socket, {:retention_preview, request}, fn ->
           with {:ok, ^target, ^policy} <- preview_inputs(read_socket),
                :ok <- authorize_prune(read_socket) do
             result =
               Threadline.Retention.purge(
                 repo: target.repo,
                 storage_schema: target.storage_schema,
                 sleep_ms: target.sleep_ms,
                 dry_run: true
               )

             case result do
               %{dry_run: true, deleted_changes: changes, deleted_transactions: transactions}
               when is_integer(changes) and changes >= 0 and is_integer(transactions) and
                      transactions >= 0 ->
                 {:ok,
                  %{
                    result: result,
                    target: target,
                    policy: policy,
                    generated_at: DateTime.utc_now(:microsecond)
                  }}

               _ ->
                 {:error, :unavailable}
             end
           else
             _ -> {:error, :unavailable}
           end
         end)}
      else
        _ -> {:noreply, preview_failed(socket)}
      end
    end

    def handle_event("open_prune_modal", _params, socket) do
      with :ok <- authorize_prune(socket), {:ok, _preview} <- confirmed_preview(socket) do
        {:noreply, assign(socket, prune_modal_open: true, prune_confirmation_error: nil)}
      else
        _ -> {:noreply, preview_failed(socket)}
      end
    end

    def handle_event("close_prune_modal", _params, socket),
      do: {:noreply, clear_preview(socket)}

    def handle_event("refresh_runs", _params, socket) do
      {:noreply, load_runs(socket)}
    end

    def handle_async({:retention_preview, request}, outcome, socket) do
      if socket.assigns.preview_request == request do
        with {:ok, {:ok, preview}} <- outcome,
             {:ok, target, policy} <- preview_inputs(socket),
             true <- preview.target == target and preview.policy == policy,
             :ok <- authorize_prune(socket) do
          {:noreply,
           assign(socket, preview_state: :ready, preview: preview, preview_request: nil)}
        else
          _ -> {:noreply, preview_failed(socket)}
        end
      else
        {:noreply, socket}
      end
    end

    defp preview_inputs(socket) do
      with {:ok, target} <- Pruner.target_snapshot(),
           true <-
             target.repo == resolve_repo(socket) and target.storage_schema == StorageSchema.get(),
           %{enabled: true} = policy <-
             Policy.resolve!(Application.get_env(:threadline, :retention) || []) do
        {:ok, target, policy}
      else
        _ -> {:error, :unavailable}
      end
    rescue
      _ -> {:error, :unavailable}
    end

    defp confirmed_preview(%{assigns: %{preview_state: :ready, preview: preview}} = socket) do
      with {:ok, target, policy} <- preview_inputs(socket),
           true <- preview.target == target and preview.policy == policy do
        {:ok, preview}
      else
        _ -> {:error, :unavailable}
      end
    end

    defp confirmed_preview(_socket), do: {:error, :unavailable}

    defp clear_preview(socket) do
      socket =
        case socket.assigns[:preview_request] do
          nil -> socket
          request -> cancel_async(socket, {:retention_preview, request})
        end

      assign(socket,
        preview: nil,
        preview_state: :idle,
        preview_request: nil,
        prune_modal_open: false,
        prune_confirmation_error: nil
      )
    end

    defp preview_failed(socket), do: socket |> clear_preview() |> assign(:preview_state, :error)

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

            <Components.retention_preview preview={@preview} state={@preview_state} />
            <div class="tl-page__actions">
              <button type="button" class="tl-button tl-button--secondary" phx-click="preview_retention" disabled={@preview_state == :loading or @prune_submitting} data-tl-mutating data-tl-server-disabled={if(@preview_state == :loading or @prune_submitting, do: "true", else: "false")} phx-disable-with="Generating preview…">Preview retention</button>
              <button :if={@preview_state == :ready} type="button" class="tl-button tl-button--secondary" phx-click={JS.push_focus() |> JS.push("open_prune_modal")} disabled={@prune_submitting}>Review and confirm</button>
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

                </UI.Data.empty_state>
              <% :loaded -> %>
                <Components.run_history
                  retention_summary={@retention_summary}
                  retention_actions={@retention_actions}
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
              preview={@preview}
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

    attr(:preview, :map, required: true)
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
              <Components.retention_preview preview={@preview} state={:ready} />
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
    defp audit_prune(socket, policy_name, target) do
      case socket.assigns[:threadline_actor_ref] do
        %ActorRef{} = actor ->
          if ActorRef.identifiable?(actor) do
            record_prune_action(target, actor, policy_name)
          else
            {:error, :audit_failed}
          end

        _ ->
          {:error, :unauthorized}
      end
    rescue
      _ -> {:error, :audit_failed}
    end

    defp record_prune_action(target, actor, policy_name) do
      case Threadline.record_action(:"retention.pruned",
             repo: target.repo,
             actor: actor,
             comment: "Operator-triggered retention prune for policy #{policy_name}",
             storage_schema: target.storage_schema
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

      recorded_counts =
        Enum.flat_map(runs, fn run ->
          if is_nil(run.deleted_count), do: [], else: [run.deleted_count]
        end)

      %{
        latest_status: Presentation.status_label(run.status),
        latest_at: run.started_at,
        latest_completed_at: latest_completed && latest_completed.completed_at,
        healthy?: failure_count == 0 and run.status == "completed",
        total_deleted: if(recorded_counts == [], do: nil, else: Enum.sum(recorded_counts)),
        missing_deletion_counts: length(runs) - length(recorded_counts),
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
        total_deleted: nil,
        missing_deletion_counts: 0,
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
        missing_deletion_counts: runs_summary.missing_deletion_counts,
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

    defp latest_completed_label(nil), do: "No completed run yet"
    defp latest_completed_label(%DateTime{} = value), do: Presentation.human_time(value)
  end
end
