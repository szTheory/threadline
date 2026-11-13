if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.PolicyRedactionLive do
    @moduledoc false

    use Phoenix.LiveView

    # This page declares its own form capability because the redaction diff includes a
    # host-schema picker. Keeping that fact beside the page prevents a separate list
    # from silently treating the current interaction as formless.
    Module.register_attribute(__MODULE__, :ui_form_policy, persist: true)
    @ui_form_policy {:has_forms, "host-schema picker for the redaction diff view"}

    alias Threadline.Capture.TriggerCaptureConfig
    alias Threadline.StorageSchema
    alias Threadline.Health.CoverageSchemas
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI
    alias Threadline.OperatorSurface.Unsupported
    alias Threadline.Policy.RedactionPresenter

    @section_defs [
      {:drift_detected, "Drift detected"},
      {:could_not_introspect, "Could not inspect"},
      {:config_matches_deployed, "Config matches deployed"}
    ]

    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:base_path, nil)
       |> assign(:schema_param, "public")
       |> assign(:available_schemas, [])
       |> assign(:form_error, nil)
       |> assign(:inspected_at, nil)
       |> assign(:report, nil)
       |> assign(:sections, [])}
    end

    def handle_params(params, uri, socket) do
      uri_parsed = URI.parse(uri)
      base_path = (uri_parsed.path || "") |> String.replace_suffix("/policy/redaction", "")
      socket = assign(socket, :base_path, base_path)
      schema_param = Map.get(params, "schema", "public")

      if socket.assigns[:threadline_policy_enabled] do
        with {:ok, schemas} <- safe_available_schemas(socket),
             {:ok, schema} <- safe_validate_schema(socket, schema_param, schemas) do
          {:noreply,
           socket
           |> assign(:schema_param, schema)
           |> assign(:available_schemas, schemas)
           |> assign(:form_error, nil)
           |> fetch_report_for_schema(schema)}
        else
          {:unavailable, schemas} ->
            {:noreply, policy_unavailable(socket, schema_param, schemas)}

          {:error, message, schemas} ->
            {:noreply,
             socket
             |> assign(:schema_param, schema_display(schema_param))
             |> assign(:available_schemas, schemas)
             |> assign(:form_error, message)
             |> assign(:inspected_at, nil)
             |> assign(:report, nil)
             |> assign(:sections, [])}
        end
      else
        {:noreply, socket}
      end
    end

    def handle_event("select-schema", %{"schema" => schema}, socket) when is_binary(schema) do
      schema =
        case String.trim(to_string(schema)) do
          "" -> "public"
          value -> value
        end

      {:noreply,
       push_patch(socket,
         to:
           "#{socket.assigns.base_path}/policy/redaction?#{URI.encode_query(%{"schema" => schema})}"
       )}
    end

    def handle_event("select-schema", _params, socket) do
      {:noreply,
       socket
       |> assign(:schema_param, "Invalid schema")
       |> assign(:form_error, "Choose a schema from the list.")
       |> assign(:inspected_at, nil)
       |> assign(:report, nil)
       |> assign(:sections, [])}
    end

    def handle_event(
          "refresh-policy-inspection",
          _params,
          %{assigns: %{threadline_policy_enabled: true, form_error: nil}} = socket
        ) do
      handle_params(
        %{"schema" => socket.assigns.schema_param},
        "#{socket.assigns.base_path}/policy/redaction",
        socket
      )
    end

    def handle_event("refresh-policy-inspection", _params, socket), do: {:noreply, socket}

    def render(assigns) do
      ~H"""
      <UI.Page.shell
        theme={@threadline_theme}
        coverage={@threadline_coverage || %{uncovered_count: 0}}
        base_path={@base_path}
        error={@threadline_coverage_error}
        coverage_enabled={@threadline_coverage_enabled}
        policy_enabled={@threadline_policy_enabled}
        evidence_enabled={@threadline_evidence_enabled}
        exports_enabled={@threadline_exports_enabled}
        current={:policy}
        main_class="tl-page"
      >
          <%= if @threadline_policy_enabled do %>
            <UI.Page.page_header title="Redaction policy">
              <:lede>Compare the configured redaction policy with deployed database trigger policy before relying on sensitive Timeline captures.</:lede>
            </UI.Page.page_header>

            <.schema_form schema={@schema_param} available_schemas={@available_schemas} />
            <.policy_refresh :if={is_nil(@form_error)} />

            <%= if @form_error do %>
              <.render_invalid_schema schema={@schema_param} form_error={@form_error} base_path={@base_path} />
            <% else %>
              <.redaction_policy_summary
                report={@report}
                schema={@schema_param}
                inspected_at={@inspected_at}
                base_path={@base_path}
                coverage_enabled={@threadline_coverage_enabled}
                evidence_enabled={@threadline_evidence_enabled}
              />

              <%= for section <- @sections do %>
                <section class={["tl-section", "tl-policy__section", section_modifier(section.status)]} data-testid="policy-section">
                  <div class="tl-section__header tl-policy__section-header">
                    <h3 class="tl-section__title"><%= section.title %> (<%= length(section.rows) %>)</h3>
                  </div>

                  <%= if section.rows == [] do %>
                    <p class="tl-policy__empty"><%= empty_section_label(section.status, @report.tables == []) %></p>
                  <% else %>
                    <div class="tl-policy__rows">
                      <%= for row <- section.rows do %>
                        <details class={["tl-policy__row", row_modifier(row.status)]}>
                          <summary class="tl-policy__summary">
                            <div class="tl-policy__row-main">
                              <span class="tl-policy__table"><%= row.table %></span>
                              <span class={["tl-chip", Presentation.status_modifier(row.status)]}><%= status_label(row.status) %></span>
                            </div>
                            <p class="tl-policy__hint"><%= row.hint %></p>
                            <%= if row.warning do %>
                              <p class="tl-policy__warning"><%= row.warning %></p>
                            <% end %>
                            <div class="tl-policy__summary-actions">
                              <.link navigate={timeline_table_path(@base_path, row.table_name, row.table_schema)} class="tl-button tl-button--compact tl-button--secondary">
                                <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
                                View activity
                              </.link>
                              <.link :if={@threadline_coverage_enabled and @base_path} navigate={coverage_path(@base_path, @schema_param)} class="tl-button tl-button--compact tl-button--ghost">
                                <Threadline.OperatorSurface.Components.Icon.icon name={:shield} class="tl-button__icon" />
                                Check coverage
                              </.link>
                            </div>
                          </summary>

                          <div class="tl-policy__details">
                            <div class="tl-table-wrap">
                              <table class="tl-table tl-table--policy tl-table--responsive">
                                <thead>
                                  <tr>
                                    <th></th>
                                    <th>Configured</th>
                                    <th>Deployed</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  <tr>
                                    <th scope="row" data-label="Field">Left out</th>
                                    <td data-label="Configured" class={diff_cell_class(row, :config, :exclude)}><%= columns_label(row.configured.exclude) %></td>
                                    <td data-label="Deployed" class={diff_cell_class(row, :deployed, :exclude)}><%= deployed_columns_label(row.deployed, :exclude) %></td>
                                  </tr>
                                  <tr>
                                    <th scope="row" data-label="Field">Redacted</th>
                                    <td data-label="Configured" class={diff_cell_class(row, :config, :mask)}><%= columns_label(row.configured.mask) %></td>
                                    <td data-label="Deployed" class={diff_cell_class(row, :deployed, :mask)}><%= deployed_columns_label(row.deployed, :mask) %></td>
                                  </tr>
                                  <tr>
                                    <th scope="row" data-label="Field">Replacement</th>
                                    <td data-label="Configured" class={diff_cell_class(row, :config, :placeholder)}><%= placeholder_label(row.configured.mask_placeholder, row.configured.mask) %></td>
                                    <td data-label="Deployed" class={diff_cell_class(row, :deployed, :placeholder)}><%= deployed_placeholder_label(row.deployed) %></td>
                                  </tr>
                                </tbody>
                              </table>
                            </div>
                          </div>
                        </details>
                      <% end %>
                    </div>
                  <% end %>
                </section>
              <% end %>
            <% end %>
          <% else %>
            <Threadline.OperatorSurface.Components.UnsupportedView.unsupported_view
              descriptor={Unsupported.descriptor(:policy_redaction_unavailable)}
              base_path={@base_path}
            />
          <% end %>
      </UI.Page.shell>
      """
    end

    defp policy_refresh(assigns) do
      ~H"""
      <div class="tl-cluster tl-cluster--start tl-policy__refresh">
        <button
          type="button"
          phx-click="refresh-policy-inspection"
          phx-disable-with="Inspecting policy…"
          class="tl-button tl-button--primary"
        >
          Refresh policy inspection
        </button>
      </div>
      """
    end

    defp build_sections(report) do
      grouped = Map.new(report.grouped)

      Enum.map(@section_defs, fn {status, title} ->
        %{
          status: status,
          title: if(report.tables == [], do: "No configured policy to compare", else: title),
          rows: Map.get(grouped, status, [])
        }
      end)
    end

    defp validate_schema(socket, schema) when is_binary(schema) do
      socket
      |> resolve_repo()
      |> CoverageSchemas.validate(schema)
    end

    defp safe_available_schemas(socket) do
      {:ok, available_schemas(socket)}
    rescue
      DBConnection.ConnectionError -> {:unavailable, ["public"]}
      _ -> {:unavailable, ["public"]}
    end

    defp safe_validate_schema(socket, schema, schemas) when is_binary(schema) do
      case validate_schema(socket, schema) do
        {:ok, schema} -> {:ok, schema}
        {:error, reason} -> {:error, safe_policy_error(reason), schemas}
      end
    rescue
      DBConnection.ConnectionError -> {:unavailable, schemas}
      _ -> {:unavailable, schemas}
    end

    defp safe_validate_schema(_socket, _schema, schemas),
      do: {:error, "Choose a schema from the list.", schemas}

    defp safe_policy_error(_reason), do: "Choose a schema from the list."
    defp schema_display(schema) when is_binary(schema), do: schema
    defp schema_display(_schema), do: "Invalid schema"

    defp fetch_report_for_schema(socket, schema) do
      configured = configured_table_keys(schema)

      report =
        socket
        |> resolve_repo()
        |> then(&RedactionPresenter.build(repo: &1, schema: schema))
        |> configured_comparison(configured)

      socket
      |> assign(:inspected_at, DateTime.utc_now())
      |> assign(:report, report)
      |> assign(:sections, build_sections(report))
    rescue
      _ ->
        policy_unavailable(socket, schema, socket.assigns.available_schemas)
    end

    # The presenter also inventories deployed tables absent from host config.
    # Its default empty policy is useful for drift analysis, but is not evidence
    # that a host actually configured that policy. Compare only explicit keys.
    defp configured_table_keys(schema) do
      TriggerCaptureConfig.load()
      |> Enum.flat_map(fn {identifier, _policy} ->
        table = StorageSchema.parse_table_identifier(identifier)

        if table.schema == schema do
          [if(schema == "public", do: table.table, else: schema <> "." <> table.table)]
        else
          []
        end
      end)
      |> MapSet.new()
    end

    defp configured_comparison(report, configured) do
      tables = Enum.filter(report.tables, &MapSet.member?(configured, &1.table))

      grouped =
        Enum.map(@section_defs, fn {status, _title} ->
          {status, Enum.filter(tables, &(&1.status == status))}
        end)

      summary = Map.new(grouped, fn {status, rows} -> {status, length(rows)} end)

      %{report | tables: tables, grouped: grouped, summary: summary}
      |> Map.put(:unconfigured_deployed_count, length(report.tables) - length(tables))
    end

    defp policy_unavailable(socket, schema, schemas) do
      socket
      |> assign(:schema_param, schema_display(schema))
      |> assign(:available_schemas, schemas)
      |> assign(:form_error, nil)
      |> assign(:inspected_at, nil)
      |> assign(:report, nil)
      |> assign(:sections, [])
    end

    defp resolve_repo(socket) do
      socket.assigns[:threadline_repo] ||
        Application.get_env(:threadline, :ecto_repos, []) |> List.first()
    end

    defp available_schemas(socket) do
      socket
      |> resolve_repo()
      |> CoverageSchemas.available()
    end

    defp schema_options(available_schemas, schema) do
      (["public", schema] ++ List.wrap(available_schemas))
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&to_string/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()
      |> Enum.sort()
    end

    defp policy_path(base_path, schema) do
      "#{base_path}/policy/redaction?#{URI.encode_query(%{"schema" => schema})}"
    end

    defp coverage_path(base_path, schema) do
      "#{base_path}/coverage?#{URI.encode_query(%{"schema" => schema})}"
    end

    attr(:schema, :string, required: true)
    attr(:available_schemas, :list, default: [])

    defp schema_form(assigns) do
      ~H"""
      <form phx-submit="select-schema" class="tl-schema-picker" aria-label="Redaction host schema">
        <label class="tl-schema-picker__label" for="policy-redaction-schema">Host schema</label>
        <select id="policy-redaction-schema" name="schema" class="tl-control tl-schema-picker__control">
          <option :for={option <- schema_options(@available_schemas, @schema)} value={option} selected={option == @schema}>
            <%= option %>
          </option>
        </select>
        <button type="submit" class="tl-button tl-button--quiet-primary">Apply schema</button>
      </form>
      """
    end

    attr(:schema, :string, required: true)
    attr(:form_error, :string, required: true)
    attr(:base_path, :string, required: true)

    defp render_invalid_schema(assigns) do
      ~H"""
      <div class="tl-alert tl-alert--error" role="alert">
        <p>Could not load redaction policy for <%= @schema %>: <%= @form_error %></p>
        <p>Choose a schema from the list or use public schema.</p>
        <.link navigate={policy_path(@base_path, "public")} class="tl-button tl-button--quiet-primary">
          Use public schema
        </.link>
      </div>
      """
    end

    defp redaction_policy_summary(%{report: nil} = assigns) do
      ~H"""
      <section class="tl-alert tl-alert--error" role="alert" aria-label="Policy inspection unavailable">
        <h2>Policy inspection unavailable</h2>
        <p>Policy inspection is unavailable for schema <%= @schema %>. Retry the inspection before treating policy as matched.</p>
        <p>Host schema: <code><%= @schema %></code></p>
      </section>
      """
    end

    defp redaction_policy_summary(assigns) do
      assigns =
        assigns
        |> assign(:all_clear?, redaction_all_clear?(assigns.report.summary))
        |> assign(:empty?, assigns.report.tables == [])
        |> assign(:actions, redaction_contextual_actions(assigns))

      ~H"""
      <section class="tl-section tl-policy__posture" aria-label="Redaction policy posture">
        <header class="tl-section__header">
          <h2 class="tl-section__title">
            <%= cond do %>
              <% @empty? -> %> No configured policy to compare
              <% @all_clear? -> %> Configured policy matches deployed trigger policy
              <% @report.summary.drift_detected == 0 -> %> Deployed policy could not be inspected
              <% true -> %> Redaction drift detected
            <% end %>
          </h2>
        </header>

        <p :if={@all_clear?} class="tl-policy__success">
          Configured redaction policy matches deployed trigger policy for every introspected table. Continue to Evidence for the latest evidence record.
        </p>

        <p :if={@report.tables == []} class="tl-policy__empty">
          No configured redaction policies were found for this inspection.
        </p>

        <p :if={@report.summary.could_not_introspect > 0} class="tl-policy__hint">
          Deployed policy could not be inspected. Retry before treating policy as matched.
        </p>

        <p :if={@report.unconfigured_deployed_count > 0} class="tl-policy__hint">
          <%= @report.unconfigured_deployed_count %> deployed <%= if @report.unconfigured_deployed_count == 1, do: "table has", else: "tables have" %> no configured policy to compare.
        </p>

        <p class="tl-policy__source-note">Configured: host application policy. Deployed: current database trigger definition.</p>
        <dl class="tl-policy__inspection-time">
          <dt>Inspection completed at</dt>
          <dd><time datetime={DateTime.to_iso8601(@inspected_at)}><%= DateTime.to_iso8601(@inspected_at) %></time></dd>
        </dl>
        <p class="tl-policy__hint">Left out fields are not recorded. Redacted fields use the configured replacement.</p>

        <p class="tl-policy__scope-note">
          This inspection compares current deployed trigger definitions only. It does not establish whether historical audit rows or downstream exports were redacted.
        </p>

        <UI.Display.kv :if={!@empty?}>
          <:item key="Host schema">
            <code><%= @schema %></code>
          </:item>
          <:item key="Drift">
            <span class={["tl-chip", if(@report.summary.drift_detected > 0, do: "tl-chip--warning", else: "tl-chip--success")]}>
              <%= @report.summary.drift_detected %>
            </span>
          </:item>
          <:item key="Introspection failures">
            <span class={["tl-chip", if(@report.summary.could_not_introspect > 0, do: "tl-chip--warning", else: "tl-chip--success")]}>
              <%= @report.summary.could_not_introspect %>
            </span>
          </:item>
          <:item key="Deployed matches config">
            <span class="tl-chip tl-chip--success"><%= @report.summary.config_matches_deployed %></span>
          </:item>
        </UI.Display.kv>

        <div :if={@actions != []} class="tl-cluster tl-cluster--start">
          <.link
            :for={action <- @actions}
            navigate={action.path}
            class="tl-button tl-button--compact tl-button--secondary"
          >
            <Threadline.OperatorSurface.Components.Icon.icon name={action.icon} class="tl-button__icon" />
            <%= action.label %>
          </.link>
        </div>
      </section>
      """
    end

    defp redaction_all_clear?(summary) do
      summary.config_matches_deployed > 0 and summary.drift_detected == 0 and
        summary.could_not_introspect == 0
    end

    defp redaction_contextual_actions(assigns) do
      [
        if(assigns.coverage_enabled and assigns.base_path,
          do: %{
            path: coverage_path(assigns.base_path, assigns.schema),
            icon: :shield,
            label: "Check coverage"
          }
        ),
        if(assigns.evidence_enabled and assigns.base_path,
          do: %{
            path: "#{assigns.base_path}/evidence?subject=redaction_policy",
            icon: :evidence,
            label: "Review evidence"
          }
        )
      ]
      |> Enum.reject(&is_nil/1)
    end

    defp section_modifier(:drift_detected), do: "tl-policy__section--drift"
    defp section_modifier(:could_not_introspect), do: "tl-policy__section--introspect"
    defp section_modifier(:config_matches_deployed), do: "tl-policy__section--match"

    defp row_modifier(:drift_detected), do: "tl-policy__row--drift"
    defp row_modifier(:could_not_introspect), do: "tl-policy__row--introspect"
    defp row_modifier(:config_matches_deployed), do: "tl-policy__row--match"

    defp status_label(:drift_detected), do: "Drift detected"
    defp status_label(:could_not_introspect), do: "Could not inspect"
    defp status_label(:config_matches_deployed), do: "Deployed matches config"

    defp empty_section_label(_status, true),
      do: "No configured redaction policies were found for this inspection."

    defp empty_section_label(status, false), do: empty_section_label(status)

    defp empty_section_label(:drift_detected), do: "No redaction drift detected."
    defp empty_section_label(:could_not_introspect), do: "All configured tables introspected."

    defp empty_section_label(:config_matches_deployed),
      do: "No matching deployed policy rows yet."

    defp columns_label([]), do: "none"
    defp columns_label(columns), do: Enum.join(columns, ", ")

    defp deployed_columns_label(nil, _field), do: "not available"
    defp deployed_columns_label(policy, field), do: columns_label(Map.get(policy, field, []))

    defp placeholder_label(_placeholder, []), do: "not used"
    defp placeholder_label(placeholder, _mask), do: placeholder

    defp deployed_placeholder_label(nil), do: "not available"
    defp deployed_placeholder_label(%{mask: []}), do: "not used"
    defp deployed_placeholder_label(%{mask_placeholder: placeholder}), do: placeholder

    defp timeline_table_path(base_path, table, "public") do
      "#{base_path}/timeline?#{URI.encode_query(%{"table" => table})}"
    end

    defp timeline_table_path(base_path, table, schema) do
      "#{base_path}/timeline?#{URI.encode_query([{"table_schema", schema}, {"table", table}])}"
    end

    # Tint only the cells that actually diverge, and only on a real drift row,
    # so the eye lands on the mismatch instead of scanning identical text.
    defp diff_cell_class(%{status: :drift_detected, diff: diff}, side, field) do
      if cell_drifted?(diff, side, field), do: "tl-policy__cell--drift"
    end

    defp diff_cell_class(_row, _side, _field), do: nil

    defp cell_drifted?(diff, :config, :exclude),
      do: Map.get(diff, :exclude_only_in_config, []) != []

    defp cell_drifted?(diff, :deployed, :exclude),
      do: Map.get(diff, :exclude_only_in_deployed, []) != []

    defp cell_drifted?(diff, :config, :mask), do: Map.get(diff, :mask_only_in_config, []) != []

    defp cell_drifted?(diff, :deployed, :mask),
      do: Map.get(diff, :mask_only_in_deployed, []) != []

    defp cell_drifted?(diff, _side, :placeholder), do: Map.get(diff, :placeholder_mismatch, false)
    defp cell_drifted?(_diff, _side, _field), do: false
  end
end
