defmodule ThreadlinePhoenixWeb.Storybook.Primitives.ButtonStory do
  use PhoenixStorybook.Story, :page

  import ThreadlinePhoenixWeb.Storybook.Wrapper
  alias ThreadlinePhoenixWeb.Storybook.Fixtures
  alias Threadline.OperatorSurface.UI

  def doc do
    """
    Primitive curated documentation using variation groups for interesting states instead of
    duplicating every theme/state combination. Fixture provenance is explicit:
    ThreadlinePhoenixWeb.Storybook.Fixtures samples Threadline.OperatorSurface.StressFixtures
    through an allowlist. Accessibility notes: icon button examples need an aria-label;
    link text must name the destination; spinner sits inside a role=status parent.
    Theme support: rendered through threadline_preview, .threadline-ui, and data-tl-theme.

    Covered primitives: UI.button, UI.icon_button, UI.link, UI.badge, UI.alert,
    UI.divider, UI.spinner, UI.avatar, UI.card, UI.stack, UI.cluster, UI.page_header,
    UI.pager, and UI.stat_tile. Ugly cases covered: #{Enum.join(Fixtures.ugly_cases(), ", ")}.
    Scope decisions: D-182-08, D-182-10, D-182-13, D-182-15, D-182-16, D-182-17,
    D-182-23, D-182-24, and D-182-25.
    """
  end

  def render(assigns) do
    assigns = assign(assigns, :fixtures, Fixtures.component_assigns("primitives"))

    ~H"""
    <.threadline_preview theme="dark">
      <.preview_section title="Primitive variation groups" description="Buttons, signals, containers, layout, and counters under real Threadline theme CSS.">
        <UI.stack gap="section">
          <UI.page_header title="Audit Transaction primitives">
            <:lede>Use these private components to filter, scan, open, copy, compare, refresh, and return.</:lede>
            <:actions>
              <UI.button variant="primary"><%= @fixtures.button.primary_label %></UI.button>
              <UI.button variant="secondary" disabled><%= @fixtures.button.disabled_label %></UI.button>
            </:actions>
          </UI.page_header>

          <UI.cluster>
            <UI.button variant="primary">Open Audit Transaction</UI.button>
            <UI.button variant="secondary">Refresh Timeline</UI.button>
            <UI.button variant="danger">Confirm prune</UI.button>
            <UI.icon_button aria-label={@fixtures.icon_button.label}>Copy</UI.icon_button>
            <UI.link href={@fixtures.link.href}><%= @fixtures.link.label %></UI.link>
          </UI.cluster>

          <UI.divider />

          <UI.cluster>
            <UI.badge variant="info">info</UI.badge>
            <UI.badge variant="warning">warning</UI.badge>
            <UI.badge variant="danger">danger</UI.badge>
            <UI.badge variant="success">success</UI.badge>
            <UI.badge variant="neutral">neutral</UI.badge>
          </UI.cluster>

          <UI.alert variant="warning">
            <%= @fixtures.alert.body %>
          </UI.alert>

          <UI.card>
            <:title>Threadline component card</:title>
            <:meta>fixture provenance: mixed_severity</:meta>
            <UI.stack>
              <p>Long refs stay copyable and readable.</p>
              <UI.ref value={@fixtures.ref.value} kind="correlation" copy_label="Copy Audit Change reference" />
            </UI.stack>
          </UI.card>

          <UI.cluster>
            <UI.avatar
              src="data:image/gif;base64,R0lGODlhAQABAAAAACw="
              alt="Support operator avatar"
            />
            <div role="status" aria-live="polite">
              <UI.spinner /> Loading Timeline Entry preview
            </div>
          </UI.cluster>

          <UI.stack>
            <UI.stat_tile label={@fixtures.stat_tile.label} value={@fixtures.stat_tile.value} status="warning" />
            <UI.pager
              shown={@fixtures.pager.shown}
              match_count={@fixtures.pager.match_count}
              has_older={@fixtures.pager.has_older}
              has_newer={@fixtures.pager.has_newer}
            />
          </UI.stack>
        </UI.stack>
      </.preview_section>
    </.threadline_preview>
    """
  end
end
