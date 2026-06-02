if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.PolicyRedactionLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Threadline.Policy.RedactionPresenter
    alias Threadline.OperatorSurface.Unsupported

    @section_defs [
      {:drift_detected, "Drift detected"},
      {:could_not_introspect, "Could not introspect"},
      {:config_matches_deployed, "Config matches deployed"}
    ]

    def mount(_params, _session, socket) do
      if socket.assigns[:threadline_policy_enabled] do
        report = RedactionPresenter.build(repo: resolve_repo(socket))

        {:ok,
         socket
         |> assign(:base_path, nil)
         |> assign(:report, report)
         |> assign(:sections, build_sections(report))}
      else
        {:ok,
         socket
         |> assign(:base_path, nil)
         |> assign(:report, nil)
         |> assign(:sections, [])}
      end
    end

    def handle_params(_params, uri, socket) do
      uri_parsed = URI.parse(uri)
      base_path = (uri_parsed.path || "") |> String.replace_suffix("/policy/redaction", "")
      {:noreply, assign(socket, :base_path, base_path)}
    end

    def render(assigns) do
      ~H"""
      <div class="threadline-ui">
        <Threadline.OperatorSurface.Style.css />
        <%= if @base_path do %>
          <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
            coverage={@threadline_coverage || %{uncovered_count: 0}}
            base_path={@base_path}
            error={@threadline_coverage_error}
            coverage_enabled={@threadline_coverage_enabled}
            policy_enabled={@threadline_policy_enabled}
            evidence_enabled={@threadline_evidence_enabled}
            exports_enabled={@threadline_exports_enabled}
            current={:policy}
          />
        <% end %>

        <main class="tl-page">
          <%= if @threadline_policy_enabled do %>
            <header class="tl-page__header">
              <div>
              <h2 class="tl-page__title">Policy redaction drift</h2>
              <p class="tl-page__lede">
                <strong>Drift detected:</strong> <%= @report.summary.drift_detected %>
                <span aria-hidden="true">|</span>
                <strong>Could not introspect:</strong> <%= @report.summary.could_not_introspect %>
                <span aria-hidden="true">|</span>
                <strong>Config matches deployed:</strong> <%= @report.summary.config_matches_deployed %>
              </p>
              </div>
            </header>

            <%= for section <- @sections do %>
              <section class={["tl-section", "tl-policy__section", section_modifier(section.status)]} data-testid="policy-section">
                <div class="tl-section__header tl-policy__section-header">
                  <h3 class="tl-section__title"><%= section.title %> (<%= length(section.rows) %>)</h3>
                </div>

                <%= if section.rows == [] do %>
                  <p class="tl-policy__empty">No tables in this section.</p>
                <% else %>
                  <div class="tl-policy__rows">
                    <%= for row <- section.rows do %>
                      <details class={["tl-policy__row", row_modifier(row.status)]}>
                        <summary class="tl-policy__summary">
                          <div class="tl-policy__row-main">
                            <span class="tl-policy__table"><%= row.table %></span>
                            <span class="tl-policy__status"><%= status_label(row.status) %></span>
                          </div>
                          <p class="tl-policy__hint"><%= row.hint %></p>
                          <%= if row.warning do %>
                            <p class="tl-policy__warning"><%= row.warning %></p>
                          <% end %>
                        </summary>

                        <div class="tl-policy__details">
                          <div class="tl-table-wrap">
                            <table class="tl-table tl-table--policy">
                              <thead>
                                <tr>
                                  <th></th>
                                  <th>Configured</th>
                                  <th>Deployed</th>
                                </tr>
                              </thead>
                              <tbody>
                                <tr>
                                  <th>exclude</th>
                                  <td><%= columns_label(row.configured.exclude) %></td>
                                  <td><%= deployed_columns_label(row.deployed, :exclude) %></td>
                                </tr>
                                <tr>
                                  <th>mask</th>
                                  <td><%= columns_label(row.configured.mask) %></td>
                                  <td><%= deployed_columns_label(row.deployed, :mask) %></td>
                                </tr>
                                <tr>
                                  <th>mask placeholder</th>
                                  <td><%= placeholder_label(row.configured.mask_placeholder, row.configured.mask) %></td>
                                  <td><%= deployed_placeholder_label(row.deployed) %></td>
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
          <% else %>
            <Threadline.OperatorSurface.Components.UnsupportedView.unsupported_view
              descriptor={Unsupported.descriptor(:policy_redaction_unavailable)}
              base_path={@base_path}
            />
          <% end %>
        </main>
      </div>
      """
    end

    defp build_sections(report) do
      grouped = Map.new(report.grouped)

      Enum.map(@section_defs, fn {status, title} ->
        %{status: status, title: title, rows: Map.get(grouped, status, [])}
      end)
    end

    defp resolve_repo(socket) do
      socket.assigns[:threadline_repo] ||
        Application.get_env(:threadline, :ecto_repos, []) |> List.first()
    end

    defp section_modifier(:drift_detected), do: "tl-policy__section--drift"
    defp section_modifier(:could_not_introspect), do: "tl-policy__section--introspect"
    defp section_modifier(:config_matches_deployed), do: "tl-policy__section--match"

    defp row_modifier(:drift_detected), do: "tl-policy__row--drift"
    defp row_modifier(:could_not_introspect), do: "tl-policy__row--introspect"
    defp row_modifier(:config_matches_deployed), do: "tl-policy__row--match"

    defp status_label(:drift_detected), do: "Drift detected"
    defp status_label(:could_not_introspect), do: "Could not introspect"
    defp status_label(:config_matches_deployed), do: "Config matches deployed"

    defp columns_label([]), do: "none"
    defp columns_label(columns), do: Enum.join(columns, ", ")

    defp deployed_columns_label(nil, _field), do: "not available"
    defp deployed_columns_label(policy, field), do: columns_label(Map.get(policy, field, []))

    defp placeholder_label(_placeholder, []), do: "not used"
    defp placeholder_label(placeholder, _mask), do: placeholder

    defp deployed_placeholder_label(nil), do: "not available"
    defp deployed_placeholder_label(%{mask: []}), do: "not used"
    defp deployed_placeholder_label(%{mask_placeholder: placeholder}), do: placeholder
  end
end
