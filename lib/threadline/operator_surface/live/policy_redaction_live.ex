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

        <main class="policy-redaction-page">
          <%= if @threadline_policy_enabled do %>
            <header class="policy-redaction-summary">
              <h2>Policy redaction drift</h2>
              <p class="filter-hint">
                <strong>Drift detected:</strong> <%= @report.summary.drift_detected %>
                <span aria-hidden="true">|</span>
                <strong>Could not introspect:</strong> <%= @report.summary.could_not_introspect %>
                <span aria-hidden="true">|</span>
                <strong>Config matches deployed:</strong> <%= @report.summary.config_matches_deployed %>
              </p>
            </header>

            <%= for section <- @sections do %>
              <section class={["policy-redaction-section", section_modifier(section.status)]}>
                <div class="policy-redaction-section-header">
                  <h3><%= section.title %> (<%= length(section.rows) %>)</h3>
                </div>

                <%= if section.rows == [] do %>
                  <p class="policy-redaction-empty">No tables in this section.</p>
                <% else %>
                  <div class="policy-redaction-rows">
                    <%= for row <- section.rows do %>
                      <details class={["policy-redaction-row", row_modifier(row.status)]}>
                        <summary>
                          <div class="policy-redaction-row-main">
                            <span class="policy-redaction-table"><%= row.table %></span>
                            <span class="policy-redaction-status"><%= status_label(row.status) %></span>
                          </div>
                          <p class="policy-redaction-hint"><%= row.hint %></p>
                          <%= if row.warning do %>
                            <p class="policy-redaction-warning"><%= row.warning %></p>
                          <% end %>
                        </summary>

                        <div class="policy-redaction-details">
                          <table class="policy-redaction-detail-table">
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

    defp section_modifier(:drift_detected), do: "policy-redaction-section--drift"
    defp section_modifier(:could_not_introspect), do: "policy-redaction-section--introspect"
    defp section_modifier(:config_matches_deployed), do: "policy-redaction-section--match"

    defp row_modifier(:drift_detected), do: "policy-redaction-row--drift"
    defp row_modifier(:could_not_introspect), do: "policy-redaction-row--introspect"
    defp row_modifier(:config_matches_deployed), do: "policy-redaction-row--match"

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
