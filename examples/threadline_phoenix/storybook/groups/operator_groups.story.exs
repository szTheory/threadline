defmodule ThreadlinePhoenixWeb.Storybook.Groups.OperatorGroupsStory do
  use PhoenixStorybook.Story, :page

  import ThreadlinePhoenixWeb.Storybook.Wrapper
  alias ThreadlinePhoenixWeb.Storybook.Fixtures
  alias Threadline.OperatorSurface.UI

  def doc do
    """
    Groups curated documentation samples recurring operator assemblies by explicit
    helper allowlist. fixture provenance: ThreadlinePhoenixWeb.Storybook.Fixtures
    selects named group stories from Threadline.OperatorSurface.StressFixtures; the
    ledger remains a ratchet/projection source and is not generated into Storybook
    navigation. Accessibility notes: disabled controls need real disabled attributes,
    permission denied uses alert semantics, and reconnect state disables mutating
    affordances without replacing authorization checks. Theme support: threadline_preview
    renders .threadline-ui with data-tl-theme.

    Covered group IDs: #{Enum.join(Fixtures.group_story_ids(), ", ")}.
    Representative IDs include group.toolbar.current, group.data-panel.current,
    group.detail-header.current, group.modal-destructive.current, group.offline.current,
    and group.permission-denied.current. Scope decisions: D-182-06, D-182-07,
    D-182-11, D-182-12, D-182-13, and D-182-20.
    """
  end

  def render(assigns) do
    groups = %{
      "toolbar" => Fixtures.group_sample("toolbar"),
      "data_panel" => Fixtures.group_sample("data_panel"),
      "detail_header" => Fixtures.group_sample("detail_header"),
      "modal_destructive" => Fixtures.group_sample("modal_destructive"),
      "offline" => Fixtures.group_sample("offline"),
      "permission_denied" => Fixtures.group_sample("permission_denied")
    }

    assigns =
      assigns
      |> assign(:groups, groups)
      |> assign(:long_id, Fixtures.sample("long_id"))
      |> assign(:stale, Fixtures.sample("stale"))
      |> assign(:pager, Fixtures.sample("pagination_boundary"))

    ~H"""
    <.threadline_preview theme="light">
      <.preview_section title="Recurring operator groups" description="Selected groups are sampled from the explicit Storybook helper allowlist, not generated from the full stress registry.">
        <UI.Display.stack gap="section">
          <UI.Display.card>
            <:title>fixture provenance</:title>
            <UI.Display.kv>
              <:item key="Toolbar"><%= @groups["toolbar"].story_id %> / <%= @groups["toolbar"].fixture_key %></:item>
              <:item key="Data panel"><%= @groups["data_panel"].story_id %> / <%= @groups["data_panel"].fixture_key %></:item>
              <:item key="Detail header"><%= @groups["detail_header"].story_id %> / <%= @groups["detail_header"].fixture_key %></:item>
              <:item key="Destructive modal"><%= @groups["modal_destructive"].story_id %> / <%= @groups["modal_destructive"].fixture_key %></:item>
              <:item key="Offline"><%= @groups["offline"].story_id %> / <%= @groups["offline"].fixture_key %></:item>
              <:item key="Permission denied"><%= @groups["permission_denied"].story_id %> / <%= @groups["permission_denied"].fixture_key %></:item>
            </UI.Display.kv>
          </UI.Display.card>

          <UI.Page.toolbar>
            <UI.Form.field
              id="group-toolbar-filter"
              name="group_toolbar_filter"
              label="Filter Audit Actions"
              value="ticket.reopened"
              help_text={@groups["toolbar"].body}
            />
            <UI.Actions.button type="button" variant="primary">Apply filters</UI.Actions.button>
            <UI.Actions.button type="button" variant="secondary">Reset</UI.Actions.button>
          </UI.Page.toolbar>

          <UI.Page.detail_header title="Transaction detail group">
            <:metadata key="Story"><%= @groups["detail_header"].story_id %></:metadata>
            <:metadata key="Audit Transaction">
              <UI.Display.ref value={@long_id} kind="correlation" copy_label="Copy grouped detail reference" />
            </:metadata>
            <:metadata key="Cases"><%= Enum.join(@groups["detail_header"].cases, ", ") %></:metadata>
            <:actions>
              <UI.Actions.button type="button" variant="secondary">Compare changes</UI.Actions.button>
            </:actions>
          </UI.Page.detail_header>

          <UI.Data.data_panel state={:ok} id="group-data-panel" as_of={@stale.as_of}>
            <:data>
              <UI.Data.data_table rows={[%{subject: "ticket:4521", action: "ticket.reopened", status: "warning"}]}>
                <:col :let={row} label="Subject"><%= row.subject %></:col>
                <:col :let={row} label="Action"><%= row.action %></:col>
                <:col :let={row} label="Status"><%= row.status %></:col>
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

          <UI.Display.cluster>
            <UI.Overlay.modal id="group-modal-destructive" show>
              <UI.Display.stack>
                <h2 id="group-modal-destructive-title" class="tl-detail-header__title">
                  Prune retention window permanently?
                </h2>
                <p id="group-modal-destructive-description" class="tl-page__lede">
                  <%= @groups["modal_destructive"].body %>
                </p>
                <UI.Actions.button type="button" variant="danger">Prune records permanently</UI.Actions.button>
              </UI.Display.stack>
            </UI.Overlay.modal>

            <UI.Data.data_state reason={:unauthorized} />
          </UI.Display.cluster>

          <UI.Display.alert variant="warning" data-tl-mutating>
            <UI.Overlay.reconnect_banner />
            <span><%= @groups["offline"].body %></span>
            <UI.Actions.button type="button" disabled>Retry while reconnecting</UI.Actions.button>
          </UI.Display.alert>
        </UI.Display.stack>
      </.preview_section>
    </.threadline_preview>
    """
  end
end
