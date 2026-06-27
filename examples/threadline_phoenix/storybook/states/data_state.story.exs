defmodule ThreadlinePhoenixWeb.Storybook.States.DataStateStory do
  use PhoenixStorybook.Story, :page

  import ThreadlinePhoenixWeb.Storybook.Wrapper
  alias ThreadlinePhoenixWeb.Storybook.Fixtures
  alias Threadline.OperatorSurface.UI

  def doc do
    """
    State curated documentation keeps data-state distinctions visible without becoming a
    page-flow test. Fixture provenance: representative static samples plus allowlisted
    Threadline.OperatorSurface.StressFixtures samples. Accessibility notes: permission and
    source-down states use alert semantics; loading uses status and aria-busy; stale data
    stays above last-good content. Theme support: threadline_preview renders .threadline-ui
    with data-tl-theme.

    Covered states: empty, no-data, permission, loading, stale, generic error,
    unavailable/source-down, redacted, pruned, null fields, pagination boundary,
    timezone boundary, reconnecting, disabled, error, and zero_count. Ugly cases covered:
    #{Enum.join(Fixtures.ugly_cases(), ", ")}. Scope decisions: D-182-08, D-182-10,
    D-182-13, D-182-15, D-182-16, D-182-17, D-182-23, D-182-24, and D-182-25.
    """
  end

  def render(assigns) do
    assigns = assign(assigns, :fixtures, Fixtures.component_assigns("states"))

    ~H"""
    <.threadline_preview theme="system">
      <.preview_section title="Data-state variation groups" description="Representative empty, no-data, permission, loading, stale, error, unavailable, redacted, pruned, null, pagination, and timezone boundaries.">
        <UI.stack gap="section">
          <UI.stale_banner
            as_of={@fixtures.stale.as_of}
            object_label={@fixtures.stale.object_label}
          />

          <UI.cluster>
            <UI.empty_state role="status">
              <:title><%= @fixtures.empty.title %></:title>
              Audit Changes appear after captured database transactions.
            </UI.empty_state>

            <UI.data_state reason={@fixtures.no_data.reason} />
          </UI.cluster>

          <UI.cluster>
            <UI.data_state reason={:loading} />
            <UI.data_state reason={:unauthorized} capability={@fixtures.permission.capability} />
          </UI.cluster>

          <UI.cluster>
            <UI.data_state reason={:source_down} logs_label={@fixtures.source_down.logs_label} />
            <UI.error_state>
              <:title><%= @fixtures.error.title %></:title>
              Retry, then check <%= @fixtures.error.logs_label %>.
            </UI.error_state>
          </UI.cluster>

          <UI.cluster>
            <UI.data_state reason={:redacted} />
            <UI.data_state reason={:pruned} as_of={@fixtures.pruned.as_of} />
          </UI.cluster>

          <UI.card>
            <:title>Null fields and timezone boundary</:title>
            <UI.kv>
              <:item key="Previous value"><%= inspect(@fixtures.null_fields.previous) %></:item>
              <:item key="Current value"><%= @fixtures.null_fields.current %></:item>
              <:item key="UTC"><%= @fixtures.timezone_boundary.utc %></:item>
              <:item key="Local"><%= @fixtures.timezone_boundary.local %></:item>
            </UI.kv>
          </UI.card>

          <UI.card>
            <:title>Pagination boundary and zero count</:title>
            <UI.pager
              shown={@fixtures.pagination_boundary.shown}
              match_count={@fixtures.pagination_boundary.match_count}
              has_older={@fixtures.pagination_boundary.has_older}
              has_newer={@fixtures.pagination_boundary.has_newer}
            />
            <p><%= @fixtures.empty.count %> current rows and <%= @fixtures.zero_count.label %>.</p>
          </UI.card>
        </UI.stack>
      </.preview_section>
    </.threadline_preview>
    """
  end
end
