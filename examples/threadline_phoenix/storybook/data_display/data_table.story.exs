defmodule ThreadlinePhoenixWeb.Storybook.DataDisplay.DataTableStory do
  use PhoenixStorybook.Story, :page

  import ThreadlinePhoenixWeb.Storybook.Wrapper
  alias ThreadlinePhoenixWeb.Storybook.Fixtures
  alias Threadline.OperatorSurface.UI

  def doc do
    """
    Data Display curated documentation covers forensic refs, key/value metadata,
    responsive tables, data panels, code blocks, detail headers, and toolbar
    coordination. Fixture provenance: static ugly samples plus allowlisted
    Threadline.OperatorSurface.StressFixtures values. Accessibility notes: responsive
    data_table cells keep data-label parity, toolbar disabled state must be paired
    with disabled controls, and data_panel keeps loading/empty/error states distinct.
    Theme support: threadline_preview renders .threadline-ui with data-tl-theme.

    Covered data display: UI.ref, UI.kv, UI.data_table, UI.data_panel, UI.code_block,
    UI.detail_header, and UI.toolbar. Ugly cases covered: long_id, null_fields,
    mixed_severity, pagination_boundary, timezone_boundary, disabled, error, empty,
    #{Enum.join(Fixtures.ugly_cases(), ", ")}. Scope decisions: D-182-08, D-182-12,
    D-182-15, D-182-16, D-182-17, and D-182-20.
    """
  end

  def render(assigns) do
    rows = [
      %{
        key: "row-1",
        id: Fixtures.sample("long_id"),
        subject: "ticket:4521",
        action: "ticket.reopened",
        actor: Fixtures.sample("non_ascii"),
        severity: "warning",
        previous: nil,
        current: "open",
        captured_at: Fixtures.sample("timezone_boundary").utc
      },
      %{
        key: "row-2",
        id: "chg_00000000-0000-4000-8000-182-data-display-2",
        subject: "ticket_reply:991",
        action: "reply.redacted",
        actor: "system:policy",
        severity: "danger",
        previous: "visible",
        current: Fixtures.sample("null_fields").rendered,
        captured_at: Fixtures.sample("timezone_boundary").local
      },
      %{
        key: "row-3",
        id: "chg_00000000-0000-4000-8000-182-data-display-3",
        subject: "audit_export:ndjson",
        action: "export.downloaded",
        actor: "support.operator@example.invalid",
        severity: "success",
        previous: "queued",
        current: "downloaded",
        captured_at: "2026-06-27T01:18:30Z"
      }
    ]

    assigns =
      assigns
      |> assign(:rows, rows)
      |> assign(:long_id, Fixtures.sample("long_id"))
      |> assign(:null_fields, Fixtures.sample("null_fields"))
      |> assign(:mixed_severity, Fixtures.sample("mixed_severity"))
      |> assign(:pager, Fixtures.sample("pagination_boundary"))
      |> assign(:timezone, Fixtures.sample("timezone_boundary"))
      |> assign(:disabled, Fixtures.sample("disabled"))
      |> assign(:error, Fixtures.sample("error"))
      |> assign(:empty, Fixtures.sample("empty"))

    ~H"""
    <.threadline_preview theme="system">
      <.preview_section title="Data Display contracts" description="Refs, metadata, tables, panels, code, headers, and toolbar coordination under representative ugly data.">
        <UI.stack gap="section">
          <UI.detail_header title="Audit Transaction #4521">
            <:metadata key="Audit Transaction">
              <UI.ref value={@long_id} kind="correlation" copy_label="Copy Audit Transaction reference" />
            </:metadata>
            <:metadata key="Previous value"><%= inspect(@null_fields.previous) %></:metadata>
            <:metadata key="Current value"><%= @null_fields.current %></:metadata>
            <:metadata key="Timezone boundary"><%= @timezone.utc %> / <%= @timezone.local %></:metadata>
            <:actions>
              <UI.button type="button" variant="primary">Download current view</UI.button>
              <UI.button type="button" disabled>Refresh disabled</UI.button>
            </:actions>
          </UI.detail_header>

          <UI.toolbar disabled={@disabled.disabled}>
            <UI.field
              id="storybook-data-filter"
              name="storybook_data_filter"
              label="Filter"
              value="ticket.reopened"
              help_text={@disabled.reason}
              disabled={@disabled.disabled}
            />
            <UI.button type="button" disabled={@disabled.disabled}>Refresh</UI.button>
          </UI.toolbar>

          <UI.data_table
            rows={@rows}
            row_id={fn row -> "storybook-#{row.key}" end}
            row_status={fn row -> row.severity end}
          >
            <:col :let={row} label="Audit Change">
              <UI.ref value={row.id} kind="correlation" copy_label={"Copy #{row.action} reference"} />
            </:col>
            <:col :let={row} label="Subject"><%= row.subject %></:col>
            <:col :let={row} label="Action"><%= row.action %></:col>
            <:col :let={row} label="Actor"><%= row.actor %></:col>
            <:col :let={row} label="Before"><%= row.previous || "null" %></:col>
            <:col :let={row} label="After"><%= row.current %></:col>
            <:col :let={row} label="Captured"><%= row.captured_at %></:col>
            <:action :let={row}>
              <UI.link href={"/audit/transactions/#{row.key}"}>Open</UI.link>
            </:action>
          </UI.data_table>

          <UI.data_panel state={:ok} id="storybook-data-panel" as_of="2026-06-27 01:12:00Z">
            <:data>
              <UI.kv>
                <:item key="Mixed severity"><%= inspect(@mixed_severity) %></:item>
                <:item key="Empty count"><%= @empty.count %></:item>
                <:item key="Error state"><%= @error.title %></:item>
              </UI.kv>
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
            <UI.data_panel state={:loading} id="storybook-loading-panel">
              <:data><span>not rendered while loading</span></:data>
            </UI.data_panel>

            <UI.data_panel state={:empty} id="storybook-empty-panel">
              <:data><span>not rendered for empty state</span></:data>
            </UI.data_panel>

            <UI.data_panel state={:error} id="storybook-error-panel">
              <:data><span>not rendered for error state</span></:data>
            </UI.data_panel>
          </UI.cluster>

          <UI.code_block>
    <%= "{" %>
      "audit_transaction_id": "<%= @long_id %>",
      "previous": <%= inspect(@null_fields.previous) %>,
      "current": "<%= @null_fields.current %>",
      "captured_at_utc": "<%= @timezone.utc %>"
    <%= "}" %>
          </UI.code_block>
        </UI.stack>
      </.preview_section>
    </.threadline_preview>
    """
  end
end
