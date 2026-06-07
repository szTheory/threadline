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
        <a class="tl-topbar__brand" href={@base_path || "#"}>
          <svg
            class="tl-topbar__brand-mark"
            viewBox="0 0 64 64"
            aria-hidden="true"
            focusable="false"
          >
            <defs>
              <linearGradient id="tl-operator-brand-gradient" x1="8" y1="50" x2="56" y2="14" gradientUnits="userSpaceOnUse">
                <stop stop-color="var(--tl-color-accent)" />
                <stop offset="1" stop-color="var(--tl-color-signal)" />
              </linearGradient>
            </defs>
            <path d="M10 46C18 22 30 21 36 34C41 45 50 43 54 18" fill="none" stroke="url(#tl-operator-brand-gradient)" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" />
            <path d="M10 46H27M36 34H50" fill="none" stroke="var(--tl-color-text)" stroke-opacity=".42" stroke-width="2" stroke-linecap="round" />
            <circle cx="10" cy="46" r="4" fill="var(--tl-color-accent)" />
            <circle cx="36" cy="34" r="4" fill="var(--tl-color-signal)" />
            <circle cx="54" cy="18" r="4" fill="var(--tl-color-text)" />
          </svg>
          <span class="tl-topbar__brand-text">Threadline</span>
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
        aria-label="Toggle operator navigation"
      />
      <nav class="tl-shell-nav" data-testid="operator-nav-shell" aria-label="Operator surface">
        <label class="tl-shell-nav__toggle" for="tl-shell-nav-toggle">Menu</label>
        <div class="tl-shell-nav__panel">
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
    slot(:inner_block, required: true)

    defp nav_link(assigns) do
      ~H"""
      <a
        href={@href || "#"}
        class={["tl-shell-nav__item", @current == @page && "tl-shell-nav__item--active"]}
        aria-current={if @current == @page, do: "page", else: nil}
        data-testid={"operator-nav-#{@page}"}
      >
        <%= render_slot(@inner_block) %>
      </a>
      """
    end

    defp timeline_path(base_path) when is_binary(base_path), do: "#{base_path}/timeline"
    defp timeline_path(_), do: "#"

    defp seconds_ago(%{last_checked_at: %DateTime{} = ts}) do
      DateTime.diff(DateTime.utc_now(), ts, :second)
    end

    defp seconds_ago(_), do: 0
  end
end
