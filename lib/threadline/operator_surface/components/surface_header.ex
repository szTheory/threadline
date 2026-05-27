if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Components.SurfaceHeader do
    @moduledoc """
    Surface-wide header showing a coverage-drift badge that links to
    `/audit/coverage`.

    Reads `coverage` (a `Threadline.OperatorSurface.Coverage.Snapshot`) and
    `base_path` (the operator-surface mount path, e.g. `"/audit"`) from the
    parent LV's assigns.

    - `uncovered_count == 0` → `<a class="surface-badge surface-badge--ok">All covered</a>` (D-31a — never hidden).
    - `uncovered_count > 0`  → `<a class="surface-badge surface-badge--warn">{n} uncovered</a>`.
    - `:threadline_coverage_error` set → small "stale (last checked Xs ago)" indicator.
    """

    use Phoenix.Component

    attr(:coverage, :map, required: true)
    attr(:base_path, :string, required: true)
    attr(:error, :string, default: nil)
    attr(:coverage_enabled, :boolean, default: false)
    attr(:policy_enabled, :boolean, default: false)
    attr(:evidence_enabled, :boolean, default: false)

    def surface_header(assigns) do
      ~H"""
      <header class="threadline-ui-header">
        <span class="brand">Threadline</span>
        <%= if @coverage_enabled do %>
          <%= if @coverage && @coverage.uncovered_count > 0 do %>
            <a class="surface-badge surface-badge--warn" href={"#{@base_path}/coverage"}>
              <%= @coverage.uncovered_count %> uncovered
            </a>
          <% else %>
            <a class="surface-badge surface-badge--ok" href={"#{@base_path}/coverage"}>All covered</a>
          <% end %>
        <% end %>
        <a :if={@evidence_enabled} class="surface-badge surface-badge--ok" href={"#{@base_path}/evidence"}>Evidence</a>
        <a :if={@policy_enabled} class="surface-badge surface-badge--ok" href={"#{@base_path}/policy/retention"}>Retention</a>
        <%= if @error do %>
          <span class="stale-indicator">stale (last checked <%= seconds_ago(@coverage) %>s ago)</span>
        <% end %>
      </header>
      """
    end

    defp seconds_ago(%{last_checked_at: %DateTime{} = ts}) do
      DateTime.diff(DateTime.utc_now(), ts, :second)
    end

    defp seconds_ago(_), do: 0
  end
end
