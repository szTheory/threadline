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
        <UI.stack gap="section">
          <UI.card>
            <:title>toolbar plus filters</:title>
            <UI.toolbar disabled={@disabled.disabled}>
              <UI.field
                id="pattern-action-filter"
                name="pattern_action_filter"
                label="Audit Action"
                value="ticket.reopened"
                help_text={@toolbar.story_id}
                disabled={@disabled.disabled}
              />
              <UI.button type="button" disabled={@disabled.disabled}>Apply</UI.button>
            </UI.toolbar>
          </UI.card>

          <UI.card>
            <:title>detail header plus metadata</:title>
            <UI.detail_header title="Ticket reply changed">
              <:metadata key="Pattern source"><%= @detail_header.story_id %></:metadata>
              <:metadata key="Audit Transaction">
                <UI.ref value={@long_id} kind="correlation" copy_label="Copy pattern Audit Transaction reference" />
              </:metadata>
              <:actions>
                <UI.button type="button" variant="secondary">Return</UI.button>
              </:actions>
            </UI.detail_header>
          </UI.card>

          <UI.card>
            <:title>data panel plus state and pager</:title>
            <UI.data_panel state={:ok} id="pattern-data-panel">
              <:data>
                <UI.data_table rows={[%{subject: "ticket:4521", action: "ticket.reopened"}]}>
                  <:col :let={row} label="Subject"><%= row.subject %></:col>
                  <:col :let={row} label="Action"><%= row.action %></:col>
                </UI.data_table>
              </:data>
              <:pager>
                <UI.pager
                  shown={@pager.shown}
                  match_count={@pager.match_count}
                  has_older={@pager.has_older}
                  has_newer={@pager.has_newer}
                />
              </:pager>
            </UI.data_panel>
            <UI.data_panel state={:empty} id="pattern-empty-panel">
              <:data><span>not rendered for empty pattern</span></:data>
            </UI.data_panel>
          </UI.card>

          <UI.card variant="danger">
            <:title>inert destructive modal</:title>
            <UI.modal id="pattern-destructive-modal" show>
              <UI.stack>
                <h2 id="pattern-destructive-modal-title" class="tl-detail-header__title">
                  Prune retention window permanently?
                </h2>
                <p id="pattern-destructive-modal-description" class="tl-page__lede">
                  <%= @modal_destructive.body %>
                </p>
                <UI.button type="button" variant="danger">Prune records permanently</UI.button>
              </UI.stack>
            </UI.modal>
          </UI.card>

          <UI.card>
            <:title>offline and reconnect</:title>
            <UI.alert variant="warning">
              <UI.reconnect_banner />
              <span><%= @offline.body %></span>
              <UI.button type="button" disabled>Retry after reconnect</UI.button>
            </UI.alert>
          </UI.card>

          <UI.card>
            <:title>permission denied</:title>
            <UI.data_state reason={:unauthorized} />
            <p class="tl-page__lede"><%= @permission_denied.story_id %></p>
          </UI.card>
        </UI.stack>
      </.preview_section>
    </.threadline_preview>
    """
  end
end
