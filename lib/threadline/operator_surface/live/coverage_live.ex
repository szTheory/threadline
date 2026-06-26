if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.CoverageLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.Coverage.Snapshot
    alias Threadline.OperatorSurface.UI
    alias Threadline.OperatorSurface.Unsupported
    alias Threadline.Health.CoverageSchemas

    @baseline ~w(schema_migrations)

    # ------------------------------------------------------------------
    # mount/3
    # ------------------------------------------------------------------
    #
    # :threadline_coverage and :threadline_coverage_error are populated by
    # Coverage.OnMount BEFORE this mount/3 runs (router on_mount: order
    # locked: Auth -> Coverage.OnMount -> mount/3). We additionally hold
    # :coverage_for_schema (the snapshot specific to the requested ?schema=)
    # and :form_error (set when ?schema=NAME is invalid).
    def mount(_params, _session, socket) do
      initial = socket.assigns[:threadline_coverage] || Snapshot.empty(DateTime.utc_now())

      socket =
        socket
        |> assign(:base_path, nil)
        |> assign(:schema_param, "public")
        |> assign(:coverage_for_schema, initial)
        |> assign(:available_schemas, [])
        |> assign(:form_error, nil)

      {:ok, socket}
    end

    def handle_params(params, uri, socket) do
      uri_parsed = URI.parse(uri)
      base_path = (uri_parsed.path || "") |> String.replace_suffix("/coverage", "")
      socket = assign(socket, :base_path, base_path)

      schema_param = Map.get(params, "schema", "public")

      if socket.assigns[:threadline_coverage_enabled] do
        case validate_schema(socket, schema_param) do
          {:ok, schema} ->
            socket =
              socket
              |> assign(:schema_param, schema)
              |> assign(:available_schemas, available_schemas(socket))
              |> assign(:form_error, nil)
              |> fetch_coverage_for_schema(schema)

            {:noreply, socket}

          {:error, message} ->
            socket =
              socket
              |> assign(:schema_param, schema_param)
              |> assign(:form_error, message)

            {:noreply, socket}
        end
      else
        {:noreply, socket}
      end
    end

    def handle_event("select-schema", %{"schema" => schema}, socket) do
      schema =
        case String.trim(to_string(schema)) do
          "" -> "public"
          value -> value
        end

      {:noreply,
       push_patch(socket,
         to: "#{socket.assigns.base_path}/coverage?#{URI.encode_query(%{"schema" => schema})}"
       )}
    end

    def handle_event("refresh", _params, socket) do
      if not socket.assigns[:threadline_coverage_enabled] do
        {:noreply, socket}
      else
        # Cancel pending timer (Pitfall 6 — manual refresh races a tick).
        # Process.cancel_timer/1 is idempotent on already-fired timers (returns false).
        if ref = socket.assigns[:threadline_timer_ref] do
          Process.cancel_timer(ref)
        end

        schema = socket.assigns[:schema_param] || "public"
        socket = fetch_coverage_for_schema(socket, schema)

        # Reschedule using the same interval Coverage.OnMount uses.
        interval =
          socket.assigns[:threadline_coverage_poll_ms] ||
            Application.get_env(:threadline, :coverage_poll_ms, 30_000)

        new_ref = Process.send_after(self(), :threadline_refresh_coverage, interval)
        socket = assign(socket, :threadline_timer_ref, new_ref)

        {:noreply, socket}
      end
    end

    def render(assigns) do
      ~H"""
      <UI.shell
        theme={@threadline_theme}
        coverage={@threadline_coverage}
        base_path={@base_path}
        error={@threadline_coverage_error}
        coverage_enabled={@threadline_coverage_enabled}
        policy_enabled={@threadline_policy_enabled}
        evidence_enabled={@threadline_evidence_enabled}
        exports_enabled={@threadline_exports_enabled}
        current={:coverage}
        script
        main_class="tl-page"
      >
          <%= if @threadline_coverage_enabled do %>
            <%= if @form_error do %>
              <UI.page_header title="Audit coverage">
                <:lede>
                  Audit readiness by table: table coverage status shows which tracked tables are covered, need capture, or are expected gaps.
                </:lede>
                <:meta>
                  Schema: <%= @schema_param %>
                </:meta>
                <:actions>
                  <.schema_form schema={@schema_param} available_schemas={@available_schemas} />
                  <button type="button" phx-click="refresh" class="tl-button tl-button--secondary">
                    <Threadline.OperatorSurface.Components.Icon.icon name={:refresh} class="tl-button__icon" />
                    Refresh
                  </button>
                </:actions>
              </UI.page_header>
              <div class="tl-alert tl-alert--error" role="alert"><%= @form_error %></div>
            <% else %>
              <%= if @coverage_for_schema.error do %>
                <div class="tl-alert tl-alert--warning" role="status">
                  Could not refresh - showing last known coverage results from <%= last_label(@coverage_for_schema.last_checked_at) %>.
                  Retry.
                </div>
              <% end %>

              <%= if all_empty?(@coverage_for_schema) do %>
                <UI.page_header title="Audit coverage">
                  <:lede>
                    Audit readiness by table: table coverage status shows which tracked tables are covered, need capture, or are expected gaps.
                  </:lede>
                  <:meta>
                    Schema: <%= @schema_param %>
                    <%= if @coverage_for_schema.last_checked_at do %>
                      · <%= Presentation.checked_label(@coverage_for_schema.last_checked_at) %>
                    <% end %>
                  </:meta>
                  <:actions>
                    <.schema_form schema={@schema_param} available_schemas={@available_schemas} />
                    <button type="button" phx-click="refresh" class="tl-button tl-button--secondary">
                      <Threadline.OperatorSurface.Components.Icon.icon name={:refresh} class="tl-button__icon" />
                      Refresh
                    </button>
                  </:actions>
                </UI.page_header>
                <div class="tl-empty">
                  <h3 class="tl-empty__title">No audited tables found</h3>
                  <p class="tl-empty__body">
                    No audited tables were found for schema '<%= @schema_param %>'. Run <code>mix threadline.gen.triggers</code> to set up capture, then refresh audit readiness.
                  </p>
                </div>
              <% else %>
                <UI.page_header title="Audit coverage">
                  <:lede>
                    Audit readiness by table: table coverage status shows which tracked tables are covered, need capture, or are expected gaps.
                  </:lede>
                  <:meta>
                    Schema: <%= @schema_param %>
                    <%= if @coverage_for_schema.last_checked_at do %>
                      · <%= Presentation.checked_label(@coverage_for_schema.last_checked_at) %>
                    <% end %>
                  </:meta>
                  <:actions>
                    <.schema_form schema={@schema_param} available_schemas={@available_schemas} />
                    <button type="button" phx-click="refresh" class="tl-button tl-button--secondary">
                      <Threadline.OperatorSurface.Components.Icon.icon name={:refresh} class="tl-button__icon" />
                      Refresh
                    </button>
                  </:actions>
                </UI.page_header>

                <section class="tl-trust-rail" aria-label="Audit readiness">
                  <span class="tl-trust-rail__label">Audit readiness</span>
                  <%= if @coverage_for_schema.uncovered_count > 0 do %>
                    <span class="tl-chip tl-chip--danger"><%= @coverage_for_schema.uncovered_count %> tables need capture</span>
                    <span class="tl-hint">Add capture before relying on Timeline answers for this schema.</span>
                  <% else %>
                    <span class="tl-chip tl-chip--success">All tracked tables covered</span>
                    <span class="tl-hint">Timeline can answer from every tracked table in this schema.</span>
                  <% end %>
                </section>

                <section class="tl-summary-grid" aria-label="Coverage summary">
                  <div class="tl-card--metric" data-status="success">
                    <span class="tl-card__metric-label">Covered</span>
                    <strong class="tl-card__metric"><%= @coverage_for_schema.covered_count %></strong>
                  </div>
                  <div class="tl-card--metric" data-status={if @coverage_for_schema.uncovered_count > 0, do: "danger"}>
                    <span class="tl-card__metric-label">Needs capture</span>
                    <strong class="tl-card__metric"><%= @coverage_for_schema.uncovered_count %></strong>
                  </div>
                  <div class="tl-card--metric">
                    <span class="tl-card__metric-label">Expected gaps</span>
                    <strong class="tl-card__metric"><%= @coverage_for_schema.expected_uncovered_count %></strong>
                  </div>
                </section>

                <section :if={@coverage_for_schema.uncovered_count > 0} class="tl-remediation" aria-label="Coverage remediation">
                  <header class="tl-remediation__header">
                    <h3 class="tl-remediation__title">Needs capture before relying on timeline results</h3>
                  </header>
                  <div class="tl-remediation__body">
                    Timeline results may be incomplete for these tables.
                    Add capture, verify coverage, then rerun the timeline search.
                  </div>
                </section>

                <div class="tl-table-wrap" data-testid="coverage-table">
                  <table class="tl-table tl-table--coverage tl-table--compact tl-table--sticky tl-table--actionable tl-table--responsive">
                    <thead>
                      <tr><th>TABLE</th><th>STATUS</th><th>SOURCE</th><th>Actions</th></tr>
                    </thead>
                    <tbody>
                      <%= for table <- @coverage_for_schema.tables[:uncovered] do %>
                        <% remediation = Presentation.coverage_remediation(table, schema: @schema_param) %>
                        <tr class="tl-table__row--uncovered">
                          <td data-label="TABLE"><code><%= table %></code></td>
                          <td data-label="STATUS"><span class="tl-chip tl-chip--danger">Needs capture</span></td>
                          <td data-label="SOURCE">missing trigger</td>
                          <td data-label="Actions" class="tl-table__actions">
                            <div class="tl-coverage-actions">
                              <details class="tl-row-action tl-row-action--capture">
                                <summary class="tl-row-action__summary">
                                  <Threadline.OperatorSurface.Components.Icon.icon name={:warning} class="tl-button__icon" />
                                  <span><%= remediation.label %></span>
                                </summary>
                                <div class="tl-row-action__body">
                                  <div :if={remediation.command} class="tl-command-copy">
                                    <code class="tl-remediation__command"><%= remediation.command %></code>
                                    <button :if={Threadline.OperatorSurface.Script.enabled?()} type="button" class="tl-copy tl-copy--command" data-tl-copy={remediation.command} aria-label={"Copy #{table} capture command"}>
                                      Copy
                                    </button>
                                  </div>
                                  <span class="tl-hint tl-row-action__hint"><%= remediation.follow_up %></span>
                                </div>
                              </details>
                            </div>
                          </td>
                        </tr>
                      <% end %>
                      <%= for table <- @coverage_for_schema.tables[:expected_uncovered] do %>
                        <tr class="tl-table__row--expected" title={tooltip_for(table)}>
                          <td data-label="TABLE"><code><%= table %></code></td>
                          <td data-label="STATUS"><span class="tl-chip tl-chip--warning">Expected gap</span></td>
                          <td data-label="SOURCE"><%= source_for(table) %></td>
                          <td data-label="Actions" class="tl-table__actions">
                            <div class="tl-coverage-actions">
                              <span class="tl-hint">Excluded from readiness</span>
                            </div>
                          </td>
                        </tr>
                      <% end %>
                      <%= for table <- @coverage_for_schema.tables[:covered] do %>
                        <tr class="tl-table__row--covered">
                          <td data-label="TABLE"><code><%= table %></code></td>
                          <td data-label="STATUS"><span class="tl-chip tl-chip--success">Covered</span></td>
                          <td data-label="SOURCE">trigger present</td>
                          <td data-label="Actions" class="tl-table__actions">
                            <div class="tl-coverage-actions">
                              <.link navigate={timeline_table_path(@base_path, table, @schema_param)} class="tl-button tl-button--compact tl-button--secondary">
                                <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
                                View activity
                              </.link>
                            </div>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              <% end %>
            <% end %>
          <% else %>
            <Threadline.OperatorSurface.Components.UnsupportedView.unsupported_view
              descriptor={Unsupported.descriptor(:coverage_unavailable)}
              base_path={@base_path}
            />
          <% end %>
      </UI.shell>
      """
    end

    attr(:schema, :string, required: true)
    attr(:available_schemas, :list, default: [])

    defp schema_form(assigns) do
      ~H"""
      <form phx-submit="select-schema" class="tl-schema-picker" aria-label="Coverage schema">
        <label class="tl-schema-picker__label" for="coverage-schema">Schema</label>
        <input
          id="coverage-schema"
          name="schema"
          type="text"
          value={@schema}
          list="coverage-schema-options"
          class="tl-control tl-schema-picker__control"
          autocomplete="off"
          spellcheck="false"
        />
        <datalist id="coverage-schema-options">
          <option :for={schema <- @available_schemas} value={schema} />
        </datalist>
        <button type="submit" class="tl-button tl-button--secondary">Apply schema</button>
      </form>
      """
    end

    # -------------------------- private helpers --------------------------

    defp validate_schema(socket, schema) when is_binary(schema) do
      socket
      |> resolve_repo()
      |> CoverageSchemas.validate(schema)
    end

    defp fetch_coverage_for_schema(socket, schema) do
      repo = resolve_repo(socket)
      now = DateTime.utc_now()

      try do
        coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)
        snapshot = Snapshot.from_coverage(coverage, last_checked_at: now)
        assign(socket, :coverage_for_schema, snapshot)
      rescue
        e ->
          message = Exception.message(e)
          Threadline.Telemetry.emit_health_checked_error(message)

          previous = socket.assigns[:coverage_for_schema] || Snapshot.empty(now)
          snapshot = %{previous | error: message, last_checked_at: now}
          assign(socket, :coverage_for_schema, snapshot)
      end
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

    defp last_label(%DateTime{} = ts), do: Presentation.human_time(ts)
    defp last_label(_), do: "never"

    defp source_for(table) do
      if table in @baseline, do: "baseline", else: "config"
    end

    defp tooltip_for(table) do
      if table in @baseline do
        "Baseline: schema_migrations"
      else
        "Configured via :expected_uncovered_tables"
      end
    end

    defp timeline_table_path(base_path, table, "public") do
      "#{base_path}/timeline?#{URI.encode_query(%{"table" => table})}"
    end

    defp timeline_table_path(base_path, table, schema) do
      "#{base_path}/timeline?#{URI.encode_query(%{"table_schema" => schema, "table" => table})}"
    end

    defp all_empty?(%Snapshot{
           covered_count: 0,
           uncovered_count: 0,
           expected_uncovered_count: 0
         }),
         do: true

    defp all_empty?(_), do: false
  end
end
