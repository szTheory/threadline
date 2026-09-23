defmodule ThreadlinePhoenixWeb.Storybook.Foundations.IndexStory do
  use PhoenixStorybook.Story, :page

  import ThreadlinePhoenixWeb.Storybook.Wrapper
  alias ThreadlinePhoenixWeb.Storybook.Fixtures
  alias Threadline.OperatorSurface.UI

  def doc do
    """
    Threadline foundations are curated documentation for maintainers. Fixture provenance:
    representative values come from ThreadlinePhoenixWeb.Storybook.Fixtures, which samples
    Threadline.OperatorSurface.StressFixtures through an explicit allowlist. Accessibility,
    theme support, and ugly-data coverage are noted per D-182-13, D-182-14, D-182-16,
    D-182-17, D-182-18, D-182-23, D-182-24, and D-182-25.

    Ugly cases covered: #{Enum.join(Fixtures.ugly_cases(), ", ")}.
    Preview contract: threadline_preview renders .threadline-ui with data-tl-theme.
    """
  end

  def render(assigns) do
    assigns = assign(assigns, :fixtures, Fixtures.component_assigns("foundations"))

    ~H"""
    <.threadline_preview theme="dark">
      <.preview_section
        title="Foundation rules"
        description="Tokens, theme lanes, typography, density, radius, focus, and motion rules for component review."
      >
        <UI.page_header title="Follow what happened">
          <:lede>
            Audit history uses calm hierarchy, dense spacing, visible focus, and exact domain language.
          </:lede>
        </UI.page_header>

        <UI.Display.stack gap="section">
          <UI.Display.cluster>
            <UI.Display.badge variant="info">theme support</UI.Display.badge>
            <UI.Display.badge variant="success">accessibility</UI.Display.badge>
            <UI.Display.badge variant="warning">fixture provenance</UI.Display.badge>
          </UI.Display.cluster>

          <UI.Display.card>
            <:title>Theme lanes</:title>
            <UI.Display.stack>
              <%= for theme <- @fixtures.themes do %>
                <.threadline_preview theme={theme}>
                  <UI.Display.alert variant="info">
                    data-tl-theme="<%= theme %>" uses the real Threadline.OperatorSurface.Style.css lane.
                  </UI.Display.alert>
                </.threadline_preview>
              <% end %>
            </UI.Display.stack>
          </UI.Display.card>

          <UI.Display.card>
            <:title>Typography and density</:title>
            <p>
              Body text stays readable at 16px, labels stay compact, and refs use mono only for
              technical anchors such as <code><%= @fixtures.typography_sample %></code>.
            </p>
            <UI.Display.cluster>
              <UI.Display.badge :for={density <- @fixtures.density} variant="neutral"><%= density %></UI.Display.badge>
            </UI.Display.cluster>
          </UI.Display.card>

          <UI.Display.card>
            <:title>Radius, focus, and motion</:title>
            <UI.Display.kv>
              <:item key="Radius"><%= Enum.join(@fixtures.radius, ", ") %></:item>
              <:item key="Motion"><%= Enum.join(@fixtures.motion, ", ") %></:item>
              <:item key="Focus">Visible ring from Style.css, not a Storybook-only override.</:item>
            </UI.Display.kv>
          </UI.Display.card>
        </UI.Display.stack>
      </.preview_section>
    </.threadline_preview>
    """
  end
end
