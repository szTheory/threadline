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
        |> assign(:coverage_for_schema_name, "public")
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
        schemas = available_schemas(socket)

        case validate_schema(socket, schema_param) do
          {:ok, schema} ->
            socket =
              socket
              |> assign(:schema_param, schema)
              |> assign(:available_schemas, schemas)
              |> assign(:form_error, nil)
              |> fetch_coverage_for_schema(schema)

            {:noreply, socket}

          {:error, message} ->
            socket =
              socket
              |> assign(:schema_param, schema_param)
              |> assign(:available_schemas, schemas)
              |> assign(:coverage_for_schema, Snapshot.empty(DateTime.utc_now()))
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
            <UI.page_header title="Audit coverage">
              <:lede>
                Selected-schema audit readiness and table-level capture gaps.
              </:lede>
              <:meta>
                Schema: <%= @schema_param %>
                <%= if is_nil(@form_error) and @coverage_for_schema.last_checked_at do %>
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

            <%= if @form_error do %>
              <.render_invalid_schema schema={@schema_param} form_error={@form_error} base_path={@base_path} />
            <% else %>
              <%= if stale_selected_schema?(@coverage_for_schema) do %>
                <div class="tl-alert tl-alert--warning" role="status">
                  Could not refresh - showing last known coverage results from <%= last_label(@coverage_for_schema.last_checked_at) %>.
                  Retry.
                </div>
              <% end %>

              <.coverage_verdict snapshot={@coverage_for_schema} schema={@schema_param} />

              <%= if all_empty?(@coverage_for_schema) do %>
                <div class="tl-empty">
                  <h3 class="tl-empty__title">No audited tables found</h3>
                  <p class="tl-empty__body">
                    No audited tables were found for schema <%= @schema_param %>. Generate trigger migrations for the tables that should be tracked, apply them, then refresh audit readiness.
                  </p>
                </div>
              <% else %>
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
    attr(:form_error, :string, required: true)
    attr(:base_path, :string, required: true)

    defp render_invalid_schema(assigns) do
      ~H"""
      <div class="tl-alert tl-alert--error" role="alert">
        <p><%= @form_error %></p>
        <p>Choose a schema from the list or use public schema.</p>
        <.link navigate={coverage_path(@base_path, "public")} class="tl-button tl-button--secondary">
          Use public schema
        </.link>
      </div>
      """
    end

    attr(:snapshot, :map, required: true)
    attr(:schema, :string, required: true)

    defp coverage_verdict(assigns) do
      ~H"""
      <section class={["tl-coverage-verdict", "tl-coverage-verdict--#{verdict_status(@snapshot)}"]} aria-label="Selected schema readiness">
        <p class="tl-coverage-verdict__eyebrow">Selected schema readiness</p>
        <span class={["tl-coverage-verdict__status", "tl-chip", verdict_chip_class(@snapshot)]}>
          <%= verdict_label(@snapshot) %>
        </span>
        <h2 class="tl-coverage-verdict__title"><%= verdict_heading(@snapshot, @schema) %></h2>
        <p class="tl-coverage-verdict__meta">
          selected schema: <code><%= @schema %></code>
          <%= if @snapshot.last_checked_at do %>
            · Checked <%= Presentation.human_time(@snapshot.last_checked_at) %>
          <% end %>
        </p>
        <dl class="tl-coverage-verdict__counts">
          <div class="tl-coverage-verdict__count">
            <dt>Covered</dt>
            <dd><%= @snapshot.covered_count %></dd>
          </div>
          <div class="tl-coverage-verdict__count">
            <dt>Needs capture</dt>
            <dd><%= @snapshot.uncovered_count %></dd>
          </div>
          <div class="tl-coverage-verdict__count">
            <dt>Expected gaps</dt>
            <dd><%= @snapshot.expected_uncovered_count %></dd>
          </div>
        </dl>
        <p class="tl-coverage-verdict__next-step"><%= verdict_next_step(@snapshot, @schema) %></p>
      </section>
      """
    end

    attr(:schema, :string, required: true)
    attr(:available_schemas, :list, default: [])

    defp schema_form(assigns) do
      ~H"""
      <form phx-submit="select-schema" class="tl-schema-picker" aria-label="Coverage schema">
        <label class="tl-schema-picker__label" for="coverage-schema">Schema</label>
        <select id="coverage-schema" name="schema" class="tl-control tl-schema-picker__control">
          <option :for={option <- schema_options(@available_schemas, @schema)} value={option} selected={option == @schema}>
            <%= option %>
          </option>
        </select>
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

        socket
        |> assign(:coverage_for_schema, snapshot)
        |> assign(:coverage_for_schema_name, schema)
      rescue
        e ->
          message = Exception.message(e)
          Threadline.Telemetry.emit_health_checked_error(message)

          previous = socket.assigns[:coverage_for_schema]
          previous_schema = socket.assigns[:coverage_for_schema_name]

          snapshot =
            case {previous_schema, previous} do
              {^schema, %Snapshot{last_checked_at: %DateTime{}} = last_good} ->
                %{last_good | error: message}

              _ ->
                %{Snapshot.empty(nil) | error: message}
            end

          socket
          |> assign(:coverage_for_schema, snapshot)
          |> assign(:coverage_for_schema_name, schema)
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

    defp coverage_path(base_path, schema) do
      "#{base_path}/coverage?#{URI.encode_query(%{"schema" => schema})}"
    end

    defp schema_options(available_schemas, schema) do
      (["public", schema] ++ List.wrap(available_schemas))
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&to_string/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()
      |> Enum.sort()
    end

    defp stale_selected_schema?(%Snapshot{error: error}) when is_binary(error) do
      String.trim(error) != ""
    end

    defp stale_selected_schema?(_), do: false

    defp verdict_status(snapshot) do
      cond do
        all_empty?(snapshot) -> "empty"
        snapshot.uncovered_count > 0 -> "not-ready"
        snapshot.expected_uncovered_count > 0 -> "tracked-ready"
        true -> "ready"
      end
    end

    defp verdict_chip_class(snapshot) do
      cond do
        all_empty?(snapshot) -> "tl-chip--warning"
        snapshot.uncovered_count > 0 -> "tl-chip--danger"
        snapshot.expected_uncovered_count > 0 -> "tl-chip--success"
        true -> "tl-chip--success"
      end
    end

    defp verdict_label(snapshot) do
      cond do
        all_empty?(snapshot) -> "No audited tables"
        snapshot.uncovered_count > 0 -> "Not ready"
        snapshot.expected_uncovered_count > 0 -> "Ready for tracked tables"
        true -> "Ready"
      end
    end

    defp verdict_heading(snapshot, schema) do
      cond do
        all_empty?(snapshot) ->
          "No audited tables found"

        snapshot.uncovered_count > 0 ->
          count = snapshot.uncovered_count
          verb = if count == 1, do: "needs", else: "need"
          "Not ready for #{schema}: #{count} #{table_word(count)} #{verb} capture."

        snapshot.expected_uncovered_count > 0 ->
          "Ready for tracked tables in #{schema}: #{snapshot.covered_count} covered, #{snapshot.expected_uncovered_count} expected gaps excluded."

        true ->
          "Ready for #{schema}: all tracked tables covered."
      end
    end

    defp verdict_next_step(snapshot, schema) do
      verifier = verifier_command(schema)

      cond do
        all_empty?(snapshot) ->
          "Generate trigger migrations for the tables that should be tracked, apply them, then refresh audit readiness."

        snapshot.uncovered_count > 0 ->
          "Fix rows marked Needs capture, apply the generated migration, run #{verifier}, then refresh audit readiness."

        snapshot.expected_uncovered_count > 0 ->
          "Expected gaps are excluded from readiness. Run #{verifier} after capture changes, then refresh audit readiness."

        true ->
          "Run #{verifier} after capture changes, then refresh audit readiness."
      end
    end

    defp verifier_command("public"), do: "mix threadline.verify_coverage"
    defp verifier_command(schema), do: "mix threadline.verify_coverage --schema=#{schema}"

    defp table_word(1), do: "table"
    defp table_word(_), do: "tables"

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
