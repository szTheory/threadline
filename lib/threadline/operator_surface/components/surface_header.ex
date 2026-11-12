if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Components.SurfaceHeader do
    @moduledoc false

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
    attr(:theme, :string, default: "dark")

    def surface_header(assigns) do
      ~H"""
      <a class="tl-skip-link" href="#tl-main">Skip to main content</a>
      <header class="tl-topbar" data-testid="operator-header">
        <a class="tl-topbar__brand" href={@base_path || "#"} aria-label="Threadline Admin home">
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
          <%= if @error do %>
            <a class="tl-chip tl-chip--warning" href={"#{@base_path}/coverage"}>
              <%= if last_checked?(@coverage), do: "Coverage refresh failed", else: "Coverage unavailable" %>
            </a>
          <% else %>
            <%= if @coverage && @coverage.uncovered_count > 0 do %>
            <a class="tl-chip tl-chip--warning" href={"#{@base_path}/coverage"}>
              <%= @coverage.uncovered_count %> tables need audit coverage
            </a>
            <% else %>
              <a class="tl-chip tl-chip--muted" href={"#{@base_path}/coverage"}>All tables captured</a>
            <% end %>
          <% end %>
        <% end %>
        <%= if @error && last_checked?(@coverage) do %>
          <span class="tl-topbar__stale">stale (last checked <%= seconds_ago(@coverage) %>s ago)</span>
        <% end %>
        </div>
      </header>
      <nav class="tl-shell-nav" data-testid="operator-nav-shell" aria-label="Audit navigation">
        <details class="tl-shell-nav__disclosure">
          <summary class="tl-shell-nav__toggle" aria-controls="tl-shell-nav-panel">Audit navigation</summary>
        </details>
        <div id="tl-shell-nav-panel" class="tl-shell-nav__panel">
          <div class="tl-shell-nav__overview">
            <.nav_link
              href={home_path(@base_path)}
              current={@current}
              page={:start}
              test_id="operator-nav-overview"
            >Overview</.nav_link>
          </div>
          <section
            class="tl-shell-nav__group"
            aria-labelledby="tl-shell-nav-find"
            data-testid="operator-nav-group-investigate"
          >
            <h2 id="tl-shell-nav-find" class="tl-shell-nav__label">Investigate</h2>
            <.nav_link href={timeline_path(@base_path)} current={@current} page={:timeline}>Timeline</.nav_link>
          </section>
          <section
            :if={@coverage_enabled}
            class="tl-shell-nav__group"
            aria-labelledby="tl-shell-nav-verify"
            data-testid="operator-nav-group-readiness"
          >
            <h2 id="tl-shell-nav-verify" class="tl-shell-nav__label">Audit readiness</h2>
            <.nav_link href={"#{@base_path}/coverage"} current={@current} page={:coverage}>Coverage</.nav_link>
          </section>
          <section
            :if={@evidence_enabled or @policy_enabled or @exports_enabled}
            class="tl-shell-nav__group"
            aria-labelledby="tl-shell-nav-prove"
            data-testid="operator-nav-group-evidence"
          >
            <h2 id="tl-shell-nav-prove" class="tl-shell-nav__label">Evidence & exports</h2>
            <.nav_link :if={@evidence_enabled} href={"#{@base_path}/evidence"} current={@current} page={:evidence}>Evidence</.nav_link>
            <.nav_link :if={@policy_enabled} href={"#{@base_path}/policy/redaction"} current={@current} page={:policy}>Redaction</.nav_link>
            <.nav_link :if={@policy_enabled} href={"#{@base_path}/policy/retention"} current={@current} page={:retention}>Retention</.nav_link>
            <.nav_link :if={@exports_enabled} href={"#{@base_path}/exports"} current={@current} page={:exports}>Exports</.nav_link>
          </section>
          <section
            class="tl-shell-nav__group tl-theme-picker"
            aria-labelledby="tl-shell-nav-theme"
            data-testid="operator-nav-group-theme"
          >
            <form action={"#{@base_path}/theme"} method="post" class="tl-theme-picker__form">
              <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
              <fieldset class="tl-theme-picker__options">
                <legend id="tl-shell-nav-theme" class="tl-shell-nav__label">Theme</legend>
                <button
                  class="tl-theme-picker__option"
                  type="submit"
                  name="theme"
                  value="system"
                  aria-label="System"
                  aria-pressed={if(@theme == "system", do: "true", else: "false")}
                >
                  <span>System</span>
                  <span :if={@theme == "system"} class="tl-theme-picker__selected" aria-hidden="true">
                    <span>✓</span><span>Selected</span>
                  </span>
                </button>
                <button
                  class="tl-theme-picker__option"
                  type="submit"
                  name="theme"
                  value="light"
                  aria-label="Light"
                  aria-pressed={if(@theme == "light", do: "true", else: "false")}
                >
                  <span>Light</span>
                  <span :if={@theme == "light"} class="tl-theme-picker__selected" aria-hidden="true">
                    <span>✓</span><span>Selected</span>
                  </span>
                </button>
                <button
                  class="tl-theme-picker__option"
                  type="submit"
                  name="theme"
                  value="dark"
                  aria-label="Dark"
                  aria-pressed={if(@theme == "dark", do: "true", else: "false")}
                >
                  <span>Dark</span>
                  <span :if={@theme == "dark"} class="tl-theme-picker__selected" aria-hidden="true">
                    <span>✓</span><span>Selected</span>
                  </span>
                </button>
              </fieldset>
            </form>
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

    defp last_checked?(%{last_checked_at: %DateTime{}}), do: true
    defp last_checked?(_), do: false
  end
end
