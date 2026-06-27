defmodule ThreadlinePhoenixWeb.Storybook.Overlays.ModalStory do
  use PhoenixStorybook.Story, :page

  import ThreadlinePhoenixWeb.Storybook.Wrapper
  alias ThreadlinePhoenixWeb.Storybook.Fixtures
  alias Threadline.OperatorSurface.UI

  def doc do
    """
    Overlay curated documentation covers static open-state examples for the private
    Threadline overlay and disclosure components. Fixture provenance: samples come from
    ThreadlinePhoenixWeb.Storybook.Fixtures, which reads a small allowlist from
    Threadline.OperatorSurface.StressFixtures. Accessibility notes: modal and drawer
    previews document focus entry/restoration, Escape dismissal, labelled dialog regions,
    keyboard expectations, and inert destructive review states. Theme support:
    threadline_preview renders .threadline-ui with data-tl-theme.

    Covered overlays: UI.modal, UI.drawer, UI.toast, UI.tooltip, UI.popover,
    UI.dropdown, UI.accordion, UI.tabs, and UI.segmented_control. Ugly cases covered:
    #{Enum.join(Fixtures.ugly_cases(), ", ")}. Scope decisions: D-182-08, D-182-12,
    D-182-15, D-182-18, and D-182-20.
    """
  end

  def render(assigns) do
    assigns =
      assigns
      |> assign(:long_id, Fixtures.sample("long_id"))
      |> assign(:long_string, Fixtures.sample("long_string"))
      |> assign(:non_ascii, Fixtures.sample("non_ascii"))
      |> assign(:stale, Fixtures.sample("stale"))

    ~H"""
    <.threadline_preview theme="dark">
      <.preview_section title="Overlay and disclosure contracts" description="Static open states for visual, focus, keyboard, and layering review without page-flow behavior.">
        <UI.stack gap="section">
          <UI.alert variant="info">
            Storybook keeps overlays component-focused: the destructive modal is an inert destructive example,
            not a live retention action, and page-flow stress remains in /audit/__stress.
          </UI.alert>

          <UI.modal id="storybook-prune-modal" show>
            <UI.stack>
              <h2 id="storybook-prune-modal-title" class="tl-detail-header__title">
                Prune retention window permanently?
              </h2>
              <p id="storybook-prune-modal-description" class="tl-page__lede">
                Type default exactly. This static preview documents focus and keyboard expectations only.
              </p>
              <UI.kv>
                <:item key="Audit Transaction"><UI.ref value={@long_id} kind="correlation" copy_label="Copy inert modal reference" /></:item>
                <:item key="Consequence">Permanently deletes audit records older than the retention window.</:item>
              </UI.kv>
              <label class="tl-label" for="storybook-prune-confirm">Confirmation text</label>
              <input
                id="storybook-prune-confirm"
                name="storybook_prune_confirm"
                value="default"
                class="tl-control"
                data-tl-initial-focus
              />
              <UI.cluster justify="end">
                <UI.button type="button" variant="secondary">Cancel</UI.button>
                <UI.button type="button" variant="danger">Prune records permanently</UI.button>
              </UI.cluster>
            </UI.stack>
          </UI.modal>

          <UI.drawer id="storybook-filter-drawer" show>
            <UI.stack>
              <h2 id="storybook-filter-drawer-title" class="tl-detail-header__title">
                Audit filter drawer
              </h2>
              <p id="storybook-filter-drawer-description" class="tl-page__lede">
                Drawer focus enters the first control and returns to the trigger on close.
              </p>
              <UI.field
                id="drawer-action"
                name="drawer_action"
                label="Audit Action"
                value="ticket.reopened"
                help_text="Keyboard users close this drawer with Escape or Cancel."
              />
              <UI.button type="button" variant="primary">Apply filters</UI.button>
            </UI.stack>
          </UI.drawer>

          <UI.cluster>
            <UI.toast id="storybook-toast" kind="warning" title="Timeline stale">
              Could not refresh - showing last known <%= @stale.object_label %> from <%= @stale.as_of %>.
            </UI.toast>

            <UI.tooltip id="storybook-tooltip">
              <:trigger>
                <span class="tl-button tl-button--secondary">Why disabled?</span>
              </:trigger>
              Refresh is disabled while the source is reconnecting.
            </UI.tooltip>
          </UI.cluster>

          <UI.cluster>
            <UI.popover id="storybook-popover">
              <:trigger>
                <span class="tl-button tl-button--secondary">Inspect policy</span>
              </:trigger>
              <UI.kv>
                <:item key="Policy">retention.default</:item>
                <:item key="Sample"><%= @non_ascii %></:item>
              </UI.kv>
            </UI.popover>

            <UI.dropdown id="storybook-dropdown">
              <:trigger>
                <span class="tl-button tl-button--secondary">Export actions</span>
              </:trigger>
              <a href="/audit/exports" role="menuitem" class="tl-link">Download CSV</a>
              <a href="/audit/exports" role="menuitem" class="tl-link">Download NDJSON</a>
            </UI.dropdown>
          </UI.cluster>

          <UI.accordion id="storybook-accordion" title="Keyboard contract">
            Disclosure state is announced through aria-expanded and the panel remains tied to the trigger.
          </UI.accordion>

          <UI.stack>
            <UI.tabs>
              <:tab id="storybook-tab-action" controls="storybook-panel-action" active>Audit Action</:tab>
              <:tab id="storybook-tab-change" controls="storybook-panel-change">Audit Change</:tab>
              <:tab id="storybook-tab-actor" controls="storybook-panel-actor">Actor</:tab>
            </UI.tabs>
            <div id="storybook-panel-action" role="tabpanel" aria-labelledby="storybook-tab-action">
              <%= @long_string %>
            </div>
          </UI.stack>

          <UI.segmented_control aria-label="Theme support">
            <:segment active>Dark</:segment>
            <:segment>Light</:segment>
            <:segment>System</:segment>
          </UI.segmented_control>
        </UI.stack>
      </.preview_section>
    </.threadline_preview>
    """
  end
end
