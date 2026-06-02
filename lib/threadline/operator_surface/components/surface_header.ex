if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Components.SurfaceHeader do
    @moduledoc """
    Surface-wide header showing a coverage-drift badge that links to
    `/audit/coverage`.

    Reads `coverage` (a `Threadline.OperatorSurface.Coverage.Snapshot`) and
    `base_path` (the operator-surface mount path, e.g. `"/audit"`) from the
    parent LV's assigns.

    - `uncovered_count == 0` → `<a class="tl-chip tl-chip--muted">All covered</a>` (D-31a — never hidden).
    - `uncovered_count > 0`  → `<a class="tl-chip tl-chip--warning">{n} uncovered</a>`.
    - `:threadline_coverage_error` set → small "stale (last checked Xs ago)" indicator.
    """

    use Phoenix.Component

    attr(:coverage, :map, required: true)
    attr(:base_path, :string, required: true)
    attr(:error, :string, default: nil)
    attr(:coverage_enabled, :boolean, default: false)
    attr(:policy_enabled, :boolean, default: false)
    attr(:evidence_enabled, :boolean, default: false)
    attr(:exports_enabled, :boolean, default: false)
    attr(:current, :atom, default: nil)

    def surface_header(assigns) do
      ~H"""
      <header class="tl-topbar" data-testid="operator-header">
        <a class="tl-topbar__brand" href={@base_path || "#"}>Threadline</a>
        <nav class="tl-topbar__nav" aria-label="Operator surface">
          <.nav_link href={@base_path} current={@current} page={:timeline}>Timeline</.nav_link>
          <.nav_link :if={@evidence_enabled} href={"#{@base_path}/evidence"} current={@current} page={:evidence}>Evidence</.nav_link>
          <.nav_link :if={@coverage_enabled} href={"#{@base_path}/coverage"} current={@current} page={:coverage}>Coverage</.nav_link>
          <.nav_link :if={@policy_enabled} href={"#{@base_path}/policy/redaction"} current={@current} page={:policy}>Policy</.nav_link>
          <.nav_link :if={@policy_enabled} href={"#{@base_path}/policy/retention"} current={@current} page={:retention}>Retention</.nav_link>
          <.nav_link :if={@exports_enabled} href={"#{@base_path}/exports"} current={@current} page={:exports}>Exports</.nav_link>
        </nav>
        <div class="tl-topbar__status">
        <%= if @coverage_enabled do %>
          <%= if @coverage && @coverage.uncovered_count > 0 do %>
            <a class="tl-chip tl-chip--warning" href={"#{@base_path}/coverage"}>
              <%= @coverage.uncovered_count %> uncovered
            </a>
          <% else %>
            <a class="tl-chip tl-chip--muted" href={"#{@base_path}/coverage"}>All covered</a>
          <% end %>
        <% end %>
        <%= if @error do %>
          <span class="tl-topbar__stale">stale (last checked <%= seconds_ago(@coverage) %>s ago)</span>
        <% end %>
        </div>
      </header>
      """
    end

    attr(:href, :string, required: true)
    attr(:current, :atom, default: nil)
    attr(:page, :atom, required: true)
    slot(:inner_block, required: true)

    defp nav_link(assigns) do
      ~H"""
      <a
        href={@href || "#"}
        class={["tl-topbar__nav-item", @current == @page && "tl-topbar__nav-item--active"]}
        aria-current={if @current == @page, do: "page", else: nil}
        data-testid={"operator-nav-#{@page}"}
      >
        <%= render_slot(@inner_block) %>
      </a>
      """
    end

    defp seconds_ago(%{last_checked_at: %DateTime{} = ts}) do
      DateTime.diff(DateTime.utc_now(), ts, :second)
    end

    defp seconds_ago(_), do: 0
  end
end
