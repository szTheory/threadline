if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Components.SurfaceHeader do
    @moduledoc """
    Surface-wide header showing a coverage-drift badge that links to
    `/audit/coverage`.

    Reads `coverage` (a `Threadline.OperatorSurface.Coverage.Snapshot`) and
    `base_path` (the operator-surface mount path, e.g. `"/audit"`) from the
    parent LV's assigns.

    - `uncovered_count == 0` → `<a class="tl-chip tl-chip--muted">All tables captured</a>` (never hidden).
    - `uncovered_count > 0`  → `<a class="tl-chip tl-chip--warning">{n} tables need audit coverage</a>`.
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
    attr(:scoped, :boolean, default: false)

    def surface_header(assigns) do
      ~H"""
      <a
        class="tl-skip-link"
        href="#tl-main"
        onclick="var target=document.getElementById('tl-main'); if (target) target.focus();"
      >Skip to main content</a>
      <header class="tl-topbar" data-testid="operator-header">
        <a class="tl-topbar__brand" href={@base_path || "#"} aria-label="Threadline operator home">
          <Threadline.OperatorSurface.Components.Logo.compact />
        </a>
        <div class="tl-topbar__status">
        <span
          :if={@scoped}
          class="tl-chip tl-chip--info"
          data-testid="operator-scope"
          title="Results are limited to the records you are authorized to see."
        >Scoped view</span>
        <%= if @coverage_enabled do %>
          <%= if @coverage && @coverage.uncovered_count > 0 do %>
            <a class="tl-chip tl-chip--warning" href={"#{@base_path}/coverage"}>
              <%= @coverage.uncovered_count %> tables need audit coverage
            </a>
          <% else %>
            <a class="tl-chip tl-chip--muted" href={"#{@base_path}/coverage"}>All tables captured</a>
          <% end %>
        <% end %>
        <%= if @error do %>
          <span class="tl-topbar__stale">stale (last checked <%= seconds_ago(@coverage) %>s ago)</span>
        <% end %>
        </div>
      </header>
      <input
        id="tl-shell-nav-toggle"
        class="tl-shell-nav__control"
        type="checkbox"
        tabindex="-1"
        aria-hidden="true"
      />
      <nav class="tl-shell-nav" data-testid="operator-nav-shell" aria-label="Operator surface">
        <button
          type="button"
          class="tl-shell-nav__toggle"
          aria-controls="tl-shell-nav-panel"
          aria-expanded="false"
          onclick="var nav=this.closest('.tl-shell-nav'); var input=document.getElementById('tl-shell-nav-toggle'); var open=nav ? !nav.classList.contains('tl-shell-nav--open') : !(input && input.checked); if (nav) { nav.classList.toggle('tl-shell-nav--open', open); } if (input) { input.checked = open; } this.setAttribute('aria-expanded', open ? 'true' : 'false');"
        >Menu</button>
        <div id="tl-shell-nav-panel" class="tl-shell-nav__panel">
          <div class="tl-shell-nav__overview">
            <.nav_link
              href={home_path(@base_path)}
              current={@current}
              page={:start}
              test_id="operator-nav-overview"
            >Overview</.nav_link>
          </div>
          <section class="tl-shell-nav__group" aria-labelledby="tl-shell-nav-find">
            <h2 id="tl-shell-nav-find" class="tl-shell-nav__label">Find</h2>
            <.nav_link href={timeline_path(@base_path)} current={@current} page={:timeline}>Timeline</.nav_link>
          </section>
          <section :if={@coverage_enabled} class="tl-shell-nav__group" aria-labelledby="tl-shell-nav-verify">
            <h2 id="tl-shell-nav-verify" class="tl-shell-nav__label">Verify</h2>
            <.nav_link href={"#{@base_path}/coverage"} current={@current} page={:coverage}>Coverage</.nav_link>
          </section>
          <section
            :if={@evidence_enabled or @policy_enabled or @exports_enabled}
            class="tl-shell-nav__group"
            aria-labelledby="tl-shell-nav-prove"
          >
            <h2 id="tl-shell-nav-prove" class="tl-shell-nav__label">Prove</h2>
            <.nav_link :if={@evidence_enabled} href={"#{@base_path}/evidence"} current={@current} page={:evidence}>Evidence</.nav_link>
            <.nav_link :if={@policy_enabled} href={"#{@base_path}/policy/redaction"} current={@current} page={:policy}>Redaction</.nav_link>
            <.nav_link :if={@policy_enabled} href={"#{@base_path}/policy/retention"} current={@current} page={:retention}>Retention</.nav_link>
            <.nav_link :if={@exports_enabled} href={"#{@base_path}/exports"} current={@current} page={:exports}>Exports</.nav_link>
          </section>
        </div>
      </nav>
      """
    end

    attr(:href, :string, required: true)
    attr(:current, :atom, default: nil)
    attr(:page, :atom, required: true)
    attr(:test_id, :string, default: nil)
    slot(:inner_block, required: true)

    defp nav_link(assigns) do
      ~H"""
      <a
        href={@href || "#"}
        class={["tl-shell-nav__item", @current == @page && "tl-shell-nav__item--active"]}
        aria-current={if @current == @page, do: "page", else: nil}
        data-testid={@test_id || "operator-nav-#{@page}"}
      >
        <%= render_slot(@inner_block) %>
      </a>
      """
    end

    defp home_path(base_path) when is_binary(base_path), do: base_path
    defp home_path(_), do: "#"

    defp timeline_path(base_path) when is_binary(base_path), do: "#{base_path}/timeline"
    defp timeline_path(_), do: "#"

    defp seconds_ago(%{last_checked_at: %DateTime{} = ts}) do
      DateTime.diff(DateTime.utc_now(), ts, :second)
    end

    defp seconds_ago(_), do: 0
  end
end
