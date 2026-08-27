if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.EvidenceLive do
    @moduledoc false

    use Phoenix.LiveView

    # GREEN-05 / D-07: this page declares its own form policy, so a change that adds
    # a form control fails the guard in the same diff. See
    # test/threadline/operator_surface/ui_form_policy_contract_test.exs.
    Module.register_attribute(__MODULE__, :ui_form_policy, persist: true)
    @ui_form_policy :formless

    alias Threadline.Evidence
    alias Threadline.Evidence.Proof
    alias Threadline.Evidence.Subject
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI
    alias Threadline.OperatorSurface.Unsupported
    alias Threadline.StorageSchema

    @evidence_source_query "source=evidence"

    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:base_path, nil)
       |> assign(:request, %{subject: nil, subject_ref: nil, mode: :latest})
       |> assign(:groups, [])
       |> assign(:form_error, nil)}
    end

    def handle_params(params, uri, socket) do
      uri_parsed = URI.parse(uri)
      base_path = (uri_parsed.path || "") |> String.replace_suffix("/evidence", "")
      socket = assign(socket, :base_path, base_path)

      if socket.assigns[:threadline_evidence_enabled] do
        case parse_request(params) do
          {:ok, request} ->
            records = fetch_records(request, resolve_repo(socket), storage_schema_opts(socket))

            {:noreply,
             socket
             |> assign(:request, request)
             |> assign(:groups, build_groups(records))
             |> assign(:form_error, nil)}

          {:error, message} ->
            {:noreply,
             socket
             |> assign(:request, %{subject: nil, subject_ref: nil, mode: :latest})
             |> assign(:groups, [])
             |> assign(:form_error, message)}
        end
      else
        {:noreply, socket}
      end
    end

    def render(assigns) do
      ~H"""
      <UI.shell
        theme={@threadline_theme}
        coverage={@threadline_coverage || %{uncovered_count: 0}}
        base_path={@base_path}
        error={@threadline_coverage_error}
        coverage_enabled={@threadline_coverage_enabled}
        policy_enabled={@threadline_policy_enabled}
        evidence_enabled={@threadline_evidence_enabled}
        exports_enabled={@threadline_exports_enabled}
        current={:evidence}
        main_class="tl-page"
      >
          <%= if @threadline_evidence_enabled do %>
            <%!-- Density: no lede in latest mode — the "Latest projection" Mode chip in the
            Evidence scope card already carries the projection semantics, so the prose
            restatement is chrome (196-06, signal-to-chrome). History mode keeps its lede
            because it disambiguates the drilled-in view. --%>
            <%= if @request.mode == :history do %>
              <UI.page_header title="Evidence">
                <:lede>
                  Viewing append-only proof history for one evidence subject reference.
                </:lede>
              </UI.page_header>
            <% else %>
              <UI.page_header title="Evidence" />
            <% end %>

            <.evidence_workflow_summary
              base_path={@base_path}
              request={@request}
              exports_enabled={@threadline_exports_enabled}
              form_error={@form_error}
            />

            <%= if @form_error do %>
              <div class="tl-alert tl-alert--error" role="alert"><%= @form_error %></div>
            <% else %>
              <%= if @groups == [] do %>
                <UI.empty_state variant="no_data" role="status" icon={:funnel}>
                  <:title>No evidence records yet</:title>
                  Threadline has not recorded evidence for this selection yet. Use mix threadline.evidence.show or the Threadline.Evidence API to confirm the current evidence record, then narrow by subject if needed.
                </UI.empty_state>
              <% else %>
                <section :for={group <- @groups} class="tl-section">
                  <header class="tl-section__header">
                    <h3 class="tl-section__title"><%= group.title %></h3>
                  </header>

                  <div class="tl-record-list" data-testid="evidence-table">
                    <article :for={row <- group.rows} class={["tl-record-card", record_modifier(row.verdict_status)]}>
                      <div class="tl-record-card__main">
                        <h4 class="tl-record-card__title">
                          <span class={["tl-chip", Presentation.status_modifier(row.verdict_status)]}>
                            <%= Presentation.status_label(row.verdict_status) %>
                          </span>
                          <span><%= row.proof_label %></span>
                        </h4>
                        <%!-- Density: the section header already names the subject for every card in
                        the group (groups are keyed by subject), so it is not repeated as an inline
                        label here — each fact renders once (196-05, signal-to-chrome). --%>
                        <div class="tl-record-card__meta">
                          <UI.ref value={row.subject_ref} copy_label="Copy subject ref" />
                          <time class="tl-table__date" datetime={Presentation.exact_time(row.recorded_at)} title={Presentation.exact_time(row.recorded_at)}>
                            <%= Presentation.human_time(row.recorded_at) %>
                          </time>
                        </div>
                      </div>
                      <div class="tl-record-card__actions">
                        <.link
                          :if={show_history_link?(@request)}
                          patch={history_path(@base_path, row.subject, row.subject_ref_json)}
                          class="tl-button tl-button--compact tl-button--secondary"
                        >
                          <Threadline.OperatorSurface.Components.Icon.icon name={:history} class="tl-button__icon" />
                          Open proof history
                        </.link>
                      </div>
                    </article>
                  </div>

                  <%!-- Density: groups are keyed by subject, so "Filter to subject" and the
                  support cross-link are identical for every card in the group. They render
                  once per group here instead of once per card — same targets, less chrome
                  (196-06, signal-to-chrome). "Open proof history" stays per card because it
                  is row-specific (subject_ref). --%>
                  <footer
                    :if={show_subject_link?(@request) or support_action(@base_path, group.title)}
                    class="tl-cluster tl-cluster--start"
                  >
                    <.link
                      :if={show_subject_link?(@request)}
                      patch={subject_path(@base_path, group.title)}
                      class="tl-link tl-link--deep"
                    >
                      Filter to subject
                    </.link>
                    <%= if action = support_action(@base_path, group.title) do %>
                      <a href={action.path} class="tl-link tl-link--deep"><%= action.label %></a>
                    <% end %>
                  </footer>
                </section>
              <% end %>
            <% end %>
          <% else %>
            <Threadline.OperatorSurface.Components.UnsupportedView.unsupported_view
              descriptor={Unsupported.descriptor(:evidence_unavailable)}
              base_path={@base_path}
            />
          <% end %>
      </UI.shell>
      """
    end

    defp parse_request(params) do
      with {:ok, subject} <- parse_subject(Map.get(params, "subject")),
           {:ok, subject_ref} <- parse_subject_ref(Map.get(params, "subject_ref_json")),
           {:ok, mode} <- parse_mode(Map.get(params, "mode", "latest")),
           :ok <- validate_request_shape(subject, subject_ref, mode) do
        {:ok, %{subject: subject, subject_ref: subject_ref, mode: mode}}
      end
    end

    defp parse_subject(nil), do: {:ok, nil}
    defp parse_subject(""), do: {:ok, nil}

    defp parse_subject(subject) do
      case Subject.validate(subject) do
        :ok ->
          {:ok, subject}

        {:error, {:unsupported_subject, value}} ->
          {:error, "Unsupported evidence subject: #{inspect(value)}"}
      end
    end

    defp parse_subject_ref(nil), do: {:ok, nil}
    defp parse_subject_ref(""), do: {:ok, nil}

    defp parse_subject_ref(payload) do
      case Jason.decode(payload) do
        {:ok, value} when is_map(value) -> {:ok, value}
        {:ok, _other} -> {:error, "subject_ref_json must decode to a JSON object."}
        {:error, error} -> {:error, "Invalid subject_ref_json: #{Exception.message(error)}"}
      end
    end

    defp parse_mode("latest"), do: {:ok, :latest}
    defp parse_mode("history"), do: {:ok, :history}
    defp parse_mode(mode), do: {:error, "Unsupported evidence mode: #{inspect(mode)}"}

    defp validate_request_shape(nil, nil, :latest), do: :ok
    defp validate_request_shape(subject, nil, :latest) when is_binary(subject), do: :ok

    defp validate_request_shape(subject, subject_ref, :latest)
         when is_binary(subject) and is_map(subject_ref),
         do: :ok

    defp validate_request_shape(subject, subject_ref, :history)
         when is_binary(subject) and is_map(subject_ref),
         do: :ok

    defp validate_request_shape(nil, subject_ref, _mode) when is_map(subject_ref) do
      {:error, "subject_ref_json requires a subject filter."}
    end

    defp validate_request_shape(subject, nil, :history) when is_binary(subject) do
      {:error, "History drill-down requires subject_ref_json."}
    end

    defp validate_request_shape(nil, nil, :history) do
      {:error, "History drill-down requires a subject filter."}
    end

    defp fetch_records(
           %{subject: nil, subject_ref: nil, mode: :latest},
           repo,
           storage_schema_opts
         ) do
      Evidence.list_overview([], evidence_opts(repo, storage_schema_opts))
    end

    defp fetch_records(
           %{subject: subject, subject_ref: nil, mode: :latest},
           repo,
           storage_schema_opts
         ) do
      Evidence.list_latest_subject_refs(subject, evidence_opts(repo, storage_schema_opts))
    end

    defp fetch_records(
           %{subject: subject, subject_ref: subject_ref, mode: :latest},
           repo,
           storage_schema_opts
         ) do
      case Evidence.get_latest_subject_ref(
             subject,
             subject_ref,
             evidence_opts(repo, storage_schema_opts)
           ) do
        nil -> []
        record -> [record]
      end
    end

    defp fetch_records(
           %{subject: subject, subject_ref: subject_ref, mode: :history},
           repo,
           storage_schema_opts
         ) do
      Evidence.list_subject_ref_history(
        subject,
        subject_ref,
        evidence_opts(repo, storage_schema_opts)
      )
    end

    defp build_groups(records) do
      records
      |> Enum.map(&build_row/1)
      |> Enum.group_by(& &1.subject)
      |> Enum.sort_by(fn {subject, _rows} -> subject end)
      |> Enum.map(fn {subject, rows} ->
        %{title: subject, rows: rows}
      end)
    end

    defp build_row(record) do
      presented = Proof.present_record(record)

      %{
        id: record.id,
        subject: presented.subject,
        subject_ref: presented.subject_ref,
        subject_ref_json: Jason.encode!(presented.subject_ref),
        summary_status: presented.summary_status,
        proof_label: proof_label(presented),
        recorded_at: record.recorded_at,
        verdict_status: presented.verdict_status
      }
    end

    defp proof_label(%{subject: "export_delivery", summary_status: status})
         when status in ["failed", "error", "unsupported"] do
      "Failed export evidence"
    end

    defp proof_label(%{summary_status: status}), do: Presentation.status_label(status)

    defp resolve_repo(socket) do
      socket.assigns[:threadline_repo] ||
        Application.get_env(:threadline, :ecto_repos, []) |> List.first() || Threadline.Repo
    end

    defp storage_schema_opts(_socket), do: [storage_schema: StorageSchema.get()]

    defp evidence_opts(repo, storage_schema_opts),
      do: Keyword.put(storage_schema_opts, :repo, repo)

    defp show_subject_link?(%{subject: nil, mode: :latest}), do: true
    defp show_subject_link?(_request), do: false

    defp show_history_link?(%{mode: :latest}), do: true
    defp show_history_link?(_request), do: false

    defp evidence_workflow_summary(assigns) do
      assigns =
        assigns
        |> assign(
          :carry_path,
          carry_to_exports_path(assigns.base_path, assigns.request, assigns.exports_enabled)
        )
        |> assign(:mode_label, evidence_mode_label(assigns.request.mode))
        |> assign(:scope_label, evidence_scope_label(assigns.request))

      ~H"""
      <section class="tl-section tl-evidence__workflow-summary" aria-label="Evidence workflow summary">
        <header class="tl-section__header">
          <h2 class="tl-section__title">Evidence scope</h2>
        </header>

        <UI.kv>
          <:item key="Mode"><span class="tl-chip tl-chip--info"><%= @mode_label %></span></:item>
          <:item key="Subject"><%= @scope_label %></:item>
          <:item :if={@request.subject_ref} key="Subject ref">
            <UI.ref value={@request.subject_ref} copy_label="Copy subject ref" />
          </:item>
        </UI.kv>

        <div class="tl-cluster tl-cluster--start">
          <.link
            :if={@request.mode == :history and @request.subject}
            patch={subject_path(@base_path, @request.subject)}
            class="tl-button tl-button--compact tl-button--secondary"
          >
            <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_left} class="tl-button__icon" />
            Back to latest for <%= @request.subject %>
          </.link>
          <.link
            :if={@carry_path}
            navigate={@carry_path}
            class="tl-button tl-button--compact tl-button--secondary"
            data-earned-flow="EF3"
            data-persona="P3"
            data-jtbd="J6"
          >
            <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
            Carry to Exports
          </.link>
          <span :if={@form_error} class="tl-hint" role="status">
            Export handoff unavailable until Evidence has a valid subject context.
          </span>
          <span :if={!@exports_enabled} class="tl-hint" role="status">
            Exports are disabled for this support lane.
          </span>
        </div>
      </section>
      """
    end

    defp evidence_mode_label(:history), do: "Append-only history"
    defp evidence_mode_label(_mode), do: "Latest projection"

    defp evidence_scope_label(%{subject: nil}), do: "All evidence subjects"
    defp evidence_scope_label(%{subject: subject, subject_ref: nil}), do: subject
    defp evidence_scope_label(%{subject: subject}), do: subject

    defp record_modifier(status) do
      case Presentation.status_modifier(status) do
        "tl-chip--success" -> "tl-record-card--success"
        "tl-chip--warning" -> "tl-record-card--warning"
        "tl-chip--danger" -> "tl-record-card--danger"
        "tl-chip--info" -> "tl-record-card--info"
        _ -> nil
      end
    end

    defp support_action(base_path, "retention_run") when is_binary(base_path),
      do: %{path: "#{base_path}/policy/retention", label: "Review retention"}

    defp support_action(base_path, "redaction_policy") when is_binary(base_path),
      do: %{path: "#{base_path}/policy/redaction", label: "Check redaction"}

    defp support_action(base_path, "trigger_coverage") when is_binary(base_path),
      do: %{path: "#{base_path}/coverage", label: "Check coverage"}

    defp support_action(base_path, "export_job") when is_binary(base_path),
      do: %{path: "#{base_path}/exports", label: "Open exports"}

    defp support_action(base_path, "export_delivery") when is_binary(base_path),
      do: %{path: "#{base_path}/exports", label: "Open exports"}

    defp support_action(_base_path, _subject), do: nil

    defp subject_path(base_path, subject), do: "#{base_path}/evidence?subject=#{subject}"

    defp carry_to_exports_path(base_path, %{subject: nil}, true) when is_binary(base_path),
      do: nil

    defp carry_to_exports_path(base_path, request, true) when is_binary(base_path) do
      params =
        URI.decode_query(@evidence_source_query)
        |> maybe_put("subject", request.subject)
        |> maybe_put_subject_ref(request.subject_ref)
        |> maybe_put_mode(request.mode)

      "#{base_path}/exports?#{URI.encode_query(params)}"
    end

    defp carry_to_exports_path(_base_path, _request, _exports_enabled), do: nil

    defp history_path(base_path, subject, subject_ref_json) do
      "#{base_path}/evidence?" <>
        URI.encode_query(%{
          "subject" => subject,
          "subject_ref_json" => subject_ref_json,
          "mode" => "history"
        })
    end

    defp maybe_put(params, _key, nil), do: params
    defp maybe_put(params, _key, ""), do: params
    defp maybe_put(params, key, value), do: Map.put(params, key, value)

    defp maybe_put_subject_ref(params, nil), do: params

    defp maybe_put_subject_ref(params, subject_ref),
      do: Map.put(params, "subject_ref_json", Jason.encode!(subject_ref))

    defp maybe_put_mode(params, :history), do: Map.put(params, "mode", "history")
    defp maybe_put_mode(params, _mode), do: params
  end
end
