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
        <UI.stack gap="section">
          <UI.card>
            <:title>fixture provenance</:title>
            <UI.kv>
              <:item key="Toolbar"><%= @groups["toolbar"].story_id %> / <%= @groups["toolbar"].fixture_key %></:item>
              <:item key="Data panel"><%= @groups["data_panel"].story_id %> / <%= @groups["data_panel"].fixture_key %></:item>
              <:item key="Detail header"><%= @groups["detail_header"].story_id %> / <%= @groups["detail_header"].fixture_key %></:item>
              <:item key="Destructive modal"><%= @groups["modal_destructive"].story_id %> / <%= @groups["modal_destructive"].fixture_key %></:item>
              <:item key="Offline"><%= @groups["offline"].story_id %> / <%= @groups["offline"].fixture_key %></:item>
              <:item key="Permission denied"><%= @groups["permission_denied"].story_id %> / <%= @groups["permission_denied"].fixture_key %></:item>
            </UI.kv>
          </UI.card>

          <UI.toolbar>
            <UI.field
              id="group-toolbar-filter"
              name="group_toolbar_filter"
              label="Filter Audit Actions"
              value="ticket.reopened"
              help_text={@groups["toolbar"].body}
            />
            <UI.button type="button" variant="primary">Apply filters</UI.button>
            <UI.button type="button" variant="secondary">Reset</UI.button>
          </UI.toolbar>

          <UI.detail_header title="Transaction detail group">
            <:metadata key="Story"><%= @groups["detail_header"].story_id %></:metadata>
            <:metadata key="Audit Transaction">
              <UI.ref value={@long_id} kind="correlation" copy_label="Copy grouped detail reference" />
            </:metadata>
            <:metadata key="Cases"><%= Enum.join(@groups["detail_header"].cases, ", ") %></:metadata>
            <:actions>
              <UI.button type="button" variant="secondary">Compare changes</UI.button>
            </:actions>
          </UI.detail_header>

          <UI.data_panel state={:ok} id="group-data-panel" as_of={@stale.as_of}>
            <:data>
              <UI.data_table rows={[%{subject: "ticket:4521", action: "ticket.reopened", status: "warning"}]}>
                <:col :let={row} label="Subject"><%= row.subject %></:col>
                <:col :let={row} label="Action"><%= row.action %></:col>
                <:col :let={row} label="Status"><%= row.status %></:col>
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

          <UI.cluster>
            <UI.modal id="group-modal-destructive" show>
              <UI.stack>
                <h2 id="group-modal-destructive-title" class="tl-detail-header__title">
                  Prune retention window permanently?
                </h2>
                <p id="group-modal-destructive-description" class="tl-page__lede">
                  <%= @groups["modal_destructive"].body %>
                </p>
                <UI.button type="button" variant="danger">Prune records permanently</UI.button>
              </UI.stack>
            </UI.modal>

            <UI.data_state reason={:unauthorized} />
          </UI.cluster>

          <UI.alert variant="warning" data-tl-mutating>
            <UI.reconnect_banner />
            <span><%= @groups["offline"].body %></span>
            <UI.button type="button" disabled>Retry while reconnecting</UI.button>
          </UI.alert>
        </UI.stack>
      </.preview_section>
    </.threadline_preview>
    """
  end
end
