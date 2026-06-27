defmodule ThreadlinePhoenixWeb.Storybook.Forms.FieldStory do
  use PhoenixStorybook.Story, :page

  import ThreadlinePhoenixWeb.Storybook.Wrapper
  alias ThreadlinePhoenixWeb.Storybook.Fixtures
  alias Threadline.OperatorSurface.UI

  def doc do
    """
    Form curated documentation maps the UI-SPEC form vocabulary to the current private
    Threadline.OperatorSurface.UI source. Fixture provenance: static ugly samples plus an
    allowlisted Threadline.OperatorSurface.StressFixtures error sample. Accessibility notes:
    label/help text/error text are connected by ids, error summary receives focus, radio and
    switch stay native, and combobox degrades to a text input. Theme support: threadline_preview
    renders .threadline-ui with data-tl-theme.

    Covered forms: UI.field and input default branch, UI.label, UI.help, UI.error,
    UI.error_summary, UI.field_group, checkbox, UI.radio, UI.switch, select, textarea,
    and UI.combobox. Ugly cases covered: #{Enum.join(Fixtures.ugly_cases(), ", ")}.
    Scope decisions: D-182-08, D-182-10, D-182-13, D-182-15, D-182-16, D-182-17,
    D-182-23, D-182-24, and D-182-25.
    """
  end

  def render(assigns) do
    assigns = assign(assigns, :fixtures, Fixtures.component_assigns("forms"))

    ~H"""
    <.threadline_preview theme="light">
      <.preview_section title="Form variation groups" description="Field, input, help, error, choice, select, textarea, and combobox controls.">
        <UI.stack gap="section">
          <UI.error_summary
            id="storybook-error-summary"
            errors={[
              {"audit-action", "Choose an Audit Action before filtering."},
              {"retention-reason", @fixtures.error}
            ]}
          >
            <:title>There is a problem with this filter</:title>
          </UI.error_summary>

          <UI.field
            id="audit-action"
            name={@fixtures.field.name}
            label={@fixtures.field.label}
            value={@fixtures.field.value}
            help_text={@fixtures.help}
          />

          <UI.field
            id="retention-reason"
            name="retention_reason"
            label="Retention reason"
            value={@fixtures.textarea.value}
            type="textarea"
            errors={[@fixtures.error]}
          />

          <div class="tl-field">
            <UI.label for="manual-subject">Subject</UI.label>
            <UI.input id="manual-subject" name="subject" value="ticket:4521" />
            <UI.help id="manual-subject-help">Help text names how this filter affects Timeline entries.</UI.help>
            <UI.error id="manual-subject-error">Error text stays adjacent to the field.</UI.error>
          </div>

          <UI.field_group legend="Export options">
            <UI.input id="include-redacted" name={@fixtures.checkbox.name} type="checkbox" value="false" />
            <UI.label for="include-redacted"><%= @fixtures.checkbox.label %></UI.label>
            <UI.radio name={@fixtures.radio.name} value="CSV" options={[{"CSV", "CSV"}, {"NDJSON", "NDJSON"}]} />
            <UI.switch id="show-stale" name={@fixtures.switch.name} value="true" />
            <UI.label for="show-stale"><%= @fixtures.switch.label %></UI.label>
          </UI.field_group>

          <UI.field
            id="severity"
            name={@fixtures.select.name}
            label="Severity"
            type="select"
            value="warning"
            options={[{"Info", "info"}, {"Warning", "warning"}, {"Danger", "danger"}]}
          />

          <UI.combobox
            id="actor"
            name={@fixtures.combobox.name}
            value={@fixtures.combobox.value}
            options={[
              {"Support operator", "support.operator@example.invalid"},
              {"System actor", "system:retention"}
            ]}
          />
        </UI.stack>
      </.preview_section>
    </.threadline_preview>
    """
  end
end
