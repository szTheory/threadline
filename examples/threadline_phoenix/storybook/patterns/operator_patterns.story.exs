defmodule ThreadlinePhoenixWeb.Storybook.Patterns.OperatorPatternsStory do
  use PhoenixStorybook.Story, :page

  import ThreadlinePhoenixWeb.Storybook.Wrapper
  alias ThreadlinePhoenixWeb.Storybook.Fixtures
  alias Threadline.OperatorSurface.UI

  def doc do
    """
    Patterns curated documentation stays intentionally small: toolbar plus filters,
    detail header plus metadata, data panel plus state and pager, inert destructive
    modal, offline and reconnect, and permission denied. Fixture provenance is explicit
    through ThreadlinePhoenixWeb.Storybook.Fixtures; these examples document component
    composition only and do not move auth behavior, navigation flows, or stress footguns
    into Storybook. Accessibility notes: custom assemblies keep labels, status regions,
    disabled coordination, and focus expectations visible. Theme support:
    threadline_preview renders .threadline-ui with data-tl-theme.

    Scope decisions: D-182-06, D-182-07, D-182-11, D-182-12, D-182-13, and D-182-20.
    """
  end

  def render(assigns) do
    assigns =
      assigns
      |> assign(:toolbar, Fixtures.group_sample("toolbar"))
      |> assign(:detail_header, Fixtures.group_sample("detail_header"))
      |> assign(:data_panel, Fixtures.group_sample("data_panel"))
      |> assign(:modal_destructive, Fixtures.group_sample("modal_destructive"))
      |> assign(:offline, Fixtures.group_sample("offline"))
      |> assign(:permission_denied, Fixtures.group_sample("permission_denied"))
      |> assign(:long_id, Fixtures.sample("long_id"))
      |> assign(:disabled, Fixtures.sample("disabled"))
      |> assign(:pager, Fixtures.sample("pagination_boundary"))

    ~H"""
    <.threadline_preview theme="dark">
      <.preview_section title="Small operator patterns" description="Six recurring assemblies for maintainers to review without expanding Storybook into flow testing.">
        <UI.Display.stack gap="section">
          <UI.Display.card>
            <:title>toolbar plus filters</:title>
            <UI.Page.toolbar disabled={@disabled.disabled}>
              <UI.Form.field
                id="pattern-action-filter"
                name="pattern_action_filter"
                label="Audit Action"
                value="ticket.reopened"
                help_text={@toolbar.story_id}
                disabled={@disabled.disabled}
              />
              <UI.Actions.button type="button" disabled={@disabled.disabled}>Apply</UI.Actions.button>
            </UI.Page.toolbar>
          </UI.Display.card>

          <UI.Display.card>
            <:title>detail header plus metadata</:title>
            <UI.Page.detail_header title="Ticket reply changed">
              <:metadata key="Pattern source"><%= @detail_header.story_id %></:metadata>
              <:metadata key="Audit Transaction">
                <UI.Display.ref value={@long_id} kind="correlation" copy_label="Copy pattern Audit Transaction reference" />
              </:metadata>
              <:actions>
                <UI.Actions.button type="button" variant="secondary">Return</UI.Actions.button>
              </:actions>
            </UI.Page.detail_header>
          </UI.Display.card>

          <UI.Display.card>
            <:title>data panel plus state and pager</:title>
            <UI.Data.data_panel state={:ok} id="pattern-data-panel">
              <:data>
                <UI.Data.data_table rows={[%{subject: "ticket:4521", action: "ticket.reopened"}]}>
                  <:col :let={row} label="Subject"><%= row.subject %></:col>
                  <:col :let={row} label="Action"><%= row.action %></:col>
                </UI.Data.data_table>
              </:data>
              <:pager>
                <UI.Page.pager
                  shown={@pager.shown}
                  match_count={@pager.match_count}
                  has_older={@pager.has_older}
                  has_newer={@pager.has_newer}
                />
              </:pager>
            </UI.Data.data_panel>
            <UI.Data.data_panel state={:empty} id="pattern-empty-panel">
              <:data><span>not rendered for empty pattern</span></:data>
            </UI.Data.data_panel>
          </UI.Display.card>

          <UI.Display.card variant="danger">
            <:title>inert destructive modal</:title>
            <UI.Overlay.modal id="pattern-destructive-modal" show>
              <UI.Display.stack>
                <h2 id="pattern-destructive-modal-title" class="tl-detail-header__title">
                  Prune retention window permanently?
                </h2>
                <p id="pattern-destructive-modal-description" class="tl-page__lede">
                  <%= @modal_destructive.body %>
                </p>
                <UI.Actions.button type="button" variant="danger">Prune records permanently</UI.Actions.button>
              </UI.Display.stack>
            </UI.Overlay.modal>
          </UI.Display.card>

          <UI.Display.card>
            <:title>offline and reconnect</:title>
            <UI.Display.alert variant="warning">
              <UI.Overlay.reconnect_banner />
              <span><%= @offline.body %></span>
              <UI.Actions.button type="button" disabled>Retry after reconnect</UI.Actions.button>
            </UI.Display.alert>
          </UI.Display.card>

          <UI.Display.card>
            <:title>permission denied</:title>
            <UI.Data.data_state reason={:unauthorized} />
            <p class="tl-page__lede"><%= @permission_denied.story_id %></p>
          </UI.Display.card>
        </UI.Display.stack>
      </.preview_section>
    </.threadline_preview>
    """
  end
end
