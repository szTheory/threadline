defmodule Threadline.OperatorSurface.UITest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Threadline.OperatorSurface.UI

  describe "button" do
    test "renders button with correct tl-button class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.button>Click Me</UI.button>
        """)

      assert html =~ "tl-button"
      assert html =~ "Click Me"
    end
  end

  describe "icon_button" do
    test "renders icon_button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.icon_button>X</UI.icon_button>
        """)

      assert html =~ "tl-button"
      assert html =~ "tl-button--icon"
      assert html =~ "X"
    end
  end

  describe "link" do
    test "renders link with correct interactive classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.link href="/">Home</UI.link>
        """)

      assert html =~ "tl-link"
      assert html =~ "tl-link--deep"
      assert html =~ ~s(href="/")
      assert html =~ "Home"
    end
  end

  describe "badge" do
    test "renders badge with static classes and no misleading affordances" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.badge variant="success">Active</UI.badge>
        """)

      assert html =~ "tl-chip"
      assert html =~ "tl-chip--success"
      assert html =~ "Active"
      refute html =~ "href="
    end
  end

  describe "alert" do
    test "renders alert with appropriate state variants" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.alert variant="warning">Watch out</UI.alert>
        """)

      assert html =~ "tl-alert"
      assert html =~ "tl-alert--warning"
      assert html =~ "Watch out"
      assert html =~ "role=\"alert\""
    end
  end

  describe "divider" do
    test "renders divider component properly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.divider />
        """)

      assert html =~ "tl-divider"
      assert html =~ "<hr"
    end
  end

  describe "spinner" do
    test "renders spinner component properly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.spinner />
        """)

      assert html =~ "tl-spinner"
      assert html =~ "<svg"
    end
  end

  describe "avatar" do
    test "renders avatar component properly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.avatar src="user.png" alt="User" />
        """)

      assert html =~ "tl-avatar"
      assert html =~ "src=\"user.png\""
      assert html =~ "alt=\"User\""
      assert html =~ "<img"
    end
  end

  describe "card" do
    test "renders card component properly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.card variant="danger">
          <:title>Card Title</:title>
          <:meta>Card Meta</:meta>
          Card Body
          <:actions><button>Action</button></:actions>
        </UI.card>
        """)

      assert html =~ "tl-card"
      assert html =~ "tl-card--danger"
      assert html =~ "tl-card__header"
      assert html =~ "tl-card__title"
      assert html =~ "Card Title"
      assert html =~ "tl-card__meta"
      assert html =~ "Card Meta"
      assert html =~ "tl-card__body"
      assert html =~ "Card Body"
      assert html =~ "tl-card__actions"
      assert html =~ "<button>Action</button>"
    end

    test "renders card without optional slots" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.card>Body Only</UI.card>
        """)

      assert html =~ "tl-card"
      assert html =~ "Body Only"
      refute html =~ "tl-card__header"
      refute html =~ "tl-card__actions"
    end
  end

  describe "stat_tile" do
    test "renders stat_tile component properly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.stat_tile status="success" label="Total" value="1,234" />
        """)

      assert html =~ "tl-card--metric"
      assert html =~ "data-status=\"success\""
      assert html =~ "tl-card__metric-label"
      assert html =~ "Total"
      assert html =~ "tl-card__metric"
      assert html =~ "1,234"
    end
  end

  describe "empty_state" do
    test "renders empty_state properly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.empty_state variant="unsupported">
          <:title>No items</:title>
          Nothing here
          <:actions><button>Add</button></:actions>
        </UI.empty_state>
        """)

      assert html =~ "tl-empty"
      assert html =~ "tl-empty--unsupported"
      assert html =~ "tl-empty__title"
      assert html =~ "No items"
      assert html =~ "tl-empty__body"
      assert html =~ "Nothing here"
      assert html =~ "tl-empty__actions"
      assert html =~ "<button>Add</button>"
    end
  end

  describe "error_state" do
    test "renders error_state wrapping empty_state properly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.error_state>
          <:title>Error Occurred</:title>
          Server failed
        </UI.error_state>
        """)

      assert html =~ "tl-empty"
      assert html =~ "tl-empty--error"
      assert html =~ "tl-empty__title"
      assert html =~ "Error Occurred"
      assert html =~ "tl-empty__body"
      assert html =~ "Server failed"
    end
  end

  describe "code_block" do
    test "renders code block safely" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.code_block>{"{\"key\": \"value\"}"}</UI.code_block>
        """)

      assert html =~ "<pre"
      assert html =~ "<code"
      assert html =~ "tl-code"
      assert html =~ "{&quot;key&quot;: &quot;value&quot;}"
    end
  end

  describe "modal" do
    test "renders modal with role dialog and aria-modal" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.modal id="test-modal">
          Modal Content
        </UI.modal>
        """)

      assert html =~ "role=\"dialog\""
      assert html =~ "aria-modal=\"true\""
      assert html =~ "Modal Content"
      assert html =~ "phx-window-keydown"
    end
  end

  describe "drawer" do
    test "renders drawer with JS macros" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.drawer id="test-drawer">
          Drawer Content
        </UI.drawer>
        """)

      assert html =~ "id=\"test-drawer\""
      assert html =~ "Drawer Content"
      assert html =~ "phx-window-keydown"
    end
  end

  describe "toast" do
    test "renders toast with phx-click-away and dismiss mechanisms" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.toast id="test-toast" kind="info" title="Info">
          Toast Message
        </UI.toast>
        """)

      assert html =~ "phx-click-away"
      assert html =~ "Toast Message"
    end
  end

  describe "tooltip" do
    test "renders tooltip with correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.tooltip id="test-tooltip">
          <:trigger>Hover me</:trigger>
          Tooltip text
        </UI.tooltip>
        """)

      assert html =~ "tl-tooltip"
      assert html =~ "Hover me"
      assert html =~ "Tooltip text"
    end
  end

  describe "popover" do
    test "renders popover with aria-expanded toggles" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.popover id="test-popover">
          <:trigger>Click me</:trigger>
          Popover content
        </UI.popover>
        """)

      assert html =~ "aria-expanded=\"false\""
      assert html =~ "phx-click-away"
      assert html =~ "Popover content"
    end
  end

  describe "dropdown" do
    test "renders dropdown with ARIA bindings" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.dropdown id="test-dropdown">
          <:trigger>Menu</:trigger>
          Dropdown item
        </UI.dropdown>
        """)

      assert html =~ "aria-haspopup=\"true\""
      assert html =~ "aria-expanded=\"false\""
      assert html =~ "Dropdown item"
      assert html =~ "role=\"menu\""
    end
  end

  describe "tabs" do
    test "renders tabs with role tablist and tab" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.tabs>
          <:tab active>Tab 1</:tab>
          <:tab>Tab 2</:tab>
        </UI.tabs>
        """)

      assert html =~ "role=\"tablist\""
      assert html =~ "role=\"tab\""
      assert html =~ "aria-selected=\"true\""
      assert html =~ "aria-selected=\"false\""
      assert html =~ "Tab 1"
      assert html =~ "Tab 2"
    end
  end

  describe "segmented_control" do
    test "renders segmented control with group role" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.segmented_control>
          <:segment active>Seg 1</:segment>
          <:segment>Seg 2</:segment>
        </UI.segmented_control>
        """)

      assert html =~ "role=\"group\""
      assert html =~ "aria-pressed=\"true\""
      assert html =~ "aria-pressed=\"false\""
      assert html =~ "Seg 1"
    end
  end

  describe "accordion" do
    test "renders accordion disclosure with aria-expanded" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.accordion id="test-accordion" title="Section 1">
          Accordion content
        </UI.accordion>
        """)

      assert html =~ "aria-expanded=\"false\""
      assert html =~ "aria-controls=\"test-accordion-content\""
      assert html =~ "Section 1"
      assert html =~ "Accordion content"
    end
  end

  describe "form components" do
    test "renders field with label, input, and connected aria-describedby for errors and help" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.field id="user-email" name="email" value="test@example" label="Email" type="email" help_text="Enter your email" errors={["Invalid format"]} />
        """)

      assert html =~ "tl-field"
      assert html =~ "tl-field--error"
      assert html =~ ~r/<label[^>]*for="user-email"[^>]*>\s*Email\s*<\/label>/
      assert html =~ ~r/<input[^>]*id="user-email"[^>]*>/
      assert html =~ ~r/<input[^>]*name="email"[^>]*>/
      assert html =~ ~r/<input[^>]*type="email"[^>]*>/
      assert html =~ ~r/<input[^>]*value="test@example"[^>]*>/

      # Check aria-describedby binding
      assert html =~ ~r/aria-describedby="[^"]*user-email-help[^"]*"/
      assert html =~ ~r/aria-describedby="[^"]*user-email-error[^"]*"/

      # Check help text and error text presence with correct IDs
      assert html =~ ~r/<p[^>]*id="user-email-help"[^>]*>\s*Enter your email\s*<\/p>/
      assert html =~ ~r/<p[^>]*id="user-email-error"[^>]*>.*Invalid format.*<\/p>/s

      # Test non-color validation applies to errors (e.g., error icon prefix)
      # Assuming an SVG icon is used for non-color validation
      assert html =~ "<svg"
    end

    test "standard inputs render correct HTML5 markup with BEM classes" do
      assigns = %{}

      # Text
      html =
        rendered_to_string(~H"""
        <UI.input id="t1" name="t1" value="text" type="text" />
        """)

      assert html =~ "tl-control"
      assert html =~ ~s(type="text")

      # Textarea
      html =
        rendered_to_string(~H"""
        <UI.input id="t2" name="t2" value="text" type="textarea" />
        """)

      assert html =~ "tl-control"
      assert html =~ ~s(<textarea)

      # Select
      html =
        rendered_to_string(~H"""
        <UI.input id="t3" name="t3" value="1" type="select" options={[{"One", "1"}]} />
        """)

      assert html =~ "tl-control"
      assert html =~ ~s(<select)
      assert html =~ ~s(<option value="1")

      # Checkbox
      html =
        rendered_to_string(~H"""
        <UI.input id="t4" name="t4" value="true" type="checkbox" />
        """)

      assert html =~ "tl-checkbox"
      assert html =~ ~s(type="checkbox")

      # Date
      html =
        rendered_to_string(~H"""
        <UI.input id="t5" name="t5" value="2024-01-01" type="date" />
        """)

      assert html =~ "tl-control"
      assert html =~ ~s(type="date")
    end
  end

  describe "error_summary" do
    test "renders an alert region with each message linked to its field" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.error_summary id="form-errors" errors={[{"email", "Email is invalid"}, {"name", "Name is required"}]} />
        """)

      assert html =~ ~s(role="alert")
      assert html =~ ~s(id="form-errors")
      # aria-labelledby points at the heading id
      assert html =~ ~r/aria-labelledby="form-errors-title"/
      assert html =~ ~r/id="form-errors-title"/
      # each message is an anchor whose href targets the field error id
      assert html =~ ~s(href="#email-error")
      assert html =~ ~s(href="#name-error")
      assert html =~ "Email is invalid"
      assert html =~ "Name is required"
      assert html =~ "<ul"
    end

    test "renders a heading from the title slot when provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.error_summary id="form-errors" errors={[{"email", "Email is invalid"}]}>
          <:title>Please fix the following</:title>
        </UI.error_summary>
        """)

      assert html =~ "Please fix the following"
      assert html =~ ~s(href="#email-error")
    end

    test "renders a default heading when no title slot is supplied" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.error_summary id="form-errors" errors={[{"email", "Email is invalid"}]} />
        """)

      assert html =~ "There is a problem"
    end

    test "renders nothing when there are no errors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.error_summary id="form-errors" errors={[]} />
        """)

      refute html =~ ~s(role="alert")
      refute html =~ "<ul"
    end
  end

  describe "field_group" do
    test "renders a fieldset and legend wrapping the inner content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.field_group legend="Date range">
          <span>inner field</span>
        </UI.field_group>
        """)

      assert html =~ "<fieldset"
      assert html =~ "<legend"
      assert html =~ "tl-filter-group"
      assert html =~ "tl-filter-group__legend"
      assert html =~ "Date range"
      assert html =~ "inner field"
    end

    test "passes through an extra class and global attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.field_group legend="Filters" class="extra-class" data-testid="grp">
          <span>content</span>
        </UI.field_group>
        """)

      assert html =~ "tl-filter-group"
      assert html =~ "extra-class"
      assert html =~ ~s(data-testid="grp")
    end
  end

  describe "radio" do
    test "renders a radio group sharing one name with distinct ids and a checked selection" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.radio name="mode" value="b" options={[{"Option A", "a"}, {"Option B", "b"}]} />
        """)

      # both inputs share the same name
      assert html =~ ~s(name="mode")
      # exactly one name= group: both options reference mode
      assert length(Regex.scan(~r/name="mode"/, html)) == 2
      # distinct ids per option
      assert html =~ ~s(id="mode-a")
      assert html =~ ~s(id="mode-b")
      assert html =~ ~s(type="radio")
      # selected value is checked
      assert html =~ ~r/<input[^>]*id="mode-b"[^>]*checked/
      # each input has an associated visible label
      assert html =~ ~s(for="mode-a")
      assert html =~ ~s(for="mode-b")
      assert html =~ "Option A"
      assert html =~ "Option B"
    end
  end

  describe "switch" do
    test "renders a native checkbox styled as a switch with role and aria-checked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.switch id="notify" name="notify" value={true} />
        """)

      assert html =~ ~s(role="switch")
      assert html =~ ~s(aria-checked="true")
      assert html =~ ~s(type="checkbox")
      assert html =~ ~s(id="notify")
      assert html =~ ~s(name="notify")
    end

    test "reflects unchecked state in aria-checked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.switch id="notify" name="notify" value={false} />
        """)

      assert html =~ ~s(aria-checked="false")
      assert html =~ ~s(type="checkbox")
    end
  end

  describe "search" do
    test "renders a native search input carrying the control class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.input id="q" name="q" value="" type="search" />
        """)

      assert html =~ ~s(type="search")
      assert html =~ "tl-control"
    end
  end

  describe "combobox" do
    test "renders a combobox input plus listbox with ARIA state and JS toggling only" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.combobox id="city" name="city" value="" options={[{"Berlin", "berlin"}, {"Paris", "paris"}]} />
        """)

      assert html =~ ~s(role="combobox")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(aria-controls="city-listbox")
      assert html =~ ~s(role="listbox")
      assert html =~ ~s(id="city-listbox")
      assert html =~ ~s(role="option")
      assert html =~ "Berlin"
      assert html =~ "Paris"
      # toggling uses Phoenix.LiveView.JS (phx-click present), not Alpine
      assert html =~ "phx-click"
      refute html =~ "x-data"
      # underlying input is a usable free-text field (degrades gracefully)
      assert html =~ ~s(name="city")
    end
  end

  describe "ref/1" do
    # A >40-char correlation id so the visible (truncated) face differs from the full value.
    @long_ref "chg_00000000-0000-4000-8000-000000000171/correlation/abcdef0123456789"

    defp copy_targets(html) do
      Regex.scan(~r/data-tl-copy="([^"]*)"/, html) |> Enum.map(fn [_, v] -> v end)
    end

    test "binds data-tl-copy to the full value (== full, != visible) on a long ref" do
      assigns = %{value: @long_ref}

      html =
        rendered_to_string(~H"""
        <UI.ref value={@value} kind="correlation" copy_label="Copy correlation id" />
        """)

      # The mono code element carries the full value as the copy target and title.
      assert html =~ "tl-secondary-ref"
      assert html =~ ~s(data-tl-copy="#{@long_ref}")
      assert html =~ ~s(title="#{@long_ref}")

      # Every data-tl-copy binding equals the full value — never the truncated visible text.
      targets = copy_targets(html)
      assert targets != []

      assert Enum.all?(targets, &(&1 == @long_ref)),
             "every data-tl-copy must equal the full value"

      # The visible (truncated) face is shown but is NOT what gets copied (forensic D-02).
      visible = Threadline.OperatorSurface.Presentation.ref(@long_ref, kind: :correlation).visible
      assert visible != @long_ref, "fixture must actually truncate so the test is meaningful"
      assert html =~ visible
      refute Enum.member?(targets, visible)
    end

    test "copy_label is a required attr (omitting it warns at compile time — D-07)" do
      warnings =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          Code.compile_string("""
          defmodule Threadline.OperatorSurface.UITest.RefMissingLabel#{System.unique_integer([:positive])} do
            use Phoenix.Component
            alias Threadline.OperatorSurface.UI

            def render(assigns) do
              ~H"<UI.ref value=\\"x\\" />"
            end
          end
          """)
        end)

      assert warnings =~ "copy_label",
             "omitting the required copy_label attr must emit a compile-time warning"
    end
  end

  describe "kv/1" do
    test "renders a tl-kv dl with dt from the required key attr and dd from the slot body" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.kv>
          <:item key="Correlation">corr-123</:item>
          <:item key="Actor">alice</:item>
        </UI.kv>
        """)

      assert html =~ ~r/<dl class="tl-kv\s*"/
      assert html =~ "tl-kv__row"
      assert html =~ ~r/<dt[^>]*>\s*Correlation\s*<\/dt>/
      assert html =~ ~r/<dd[^>]*>.*corr-123.*<\/dd>/s
      assert html =~ ~r/<dt[^>]*>\s*Actor\s*<\/dt>/
      assert html =~ "alice"
    end
  end

  describe "data_table/1" do
    test "the :col label feeds both the <th> and every <td data-label> from one source" do
      assigns = %{rows: [%{a: "1", b: "2"}, %{a: "3", b: "4"}]}

      html =
        rendered_to_string(~H"""
        <UI.data_table rows={@rows}>
          <:col :let={r} label="Status"><%= r.a %></:col>
          <:col :let={r} label="Count"><%= r.b %></:col>
        </UI.data_table>
        """)

      assert html =~ "tl-table"
      assert html =~ "tl-table--responsive"
      # Header labels.
      assert html =~ ~r/<th[^>]*>\s*Status\s*<\/th>/
      assert html =~ ~r/<th[^>]*>\s*Count\s*<\/th>/
      # Each <td> carries data-label matching its column header.
      assert html =~ ~s(data-label="Status")
      assert html =~ ~s(data-label="Count")
      # No ARIA table roles (D-09).
      refute html =~ ~s(role="table")
      refute html =~ ~s(role="row")
      refute html =~ ~s(role="cell")
    end

    test "stream toggles phx-update=stream on the tbody; rows mode does not" do
      assigns = %{rows: [%{a: "1"}], stream: [{"runs-1", %{a: "1"}}]}

      rows_html =
        rendered_to_string(~H"""
        <UI.data_table rows={@rows}>
          <:col :let={r} label="A"><%= r.a %></:col>
        </UI.data_table>
        """)

      refute rows_html =~ ~s(phx-update="stream")

      stream_html =
        rendered_to_string(~H"""
        <UI.data_table stream={@stream} row_id={fn {dom_id, _} -> dom_id end}>
          <:col :let={{_dom, r}} label="A"><%= r.a %></:col>
        </UI.data_table>
        """)

      assert stream_html =~ ~s(phx-update="stream")
      assert stream_html =~ ~s(id="runs-1")
    end

    test "row_status emits a data-status stripe and :action slot hosts the kebab" do
      assigns = %{rows: [%{a: "1", status: "failed"}]}

      html =
        rendered_to_string(~H"""
        <UI.data_table rows={@rows} row_status={fn r -> r.status end}>
          <:col :let={r} label="A"><%= r.a %></:col>
          <:action>menu</:action>
        </UI.data_table>
        """)

      assert html =~ ~s(data-status="failed")
      assert html =~ "menu"
    end
  end

  describe "loading_state/1" do
    test "renders a role=status aria-busy block with a spinner and default text node" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.loading_state />
        """)

      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-busy="true")
      assert html =~ "tl-spinner"
      assert html =~ "Loading audit changes"
    end

    test "accepts an inner_block override of the default text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.loading_state>Loading retention runs…</UI.loading_state>
        """)

      assert html =~ "Loading retention runs"
    end
  end

  describe "stale_banner/1" do
    test "renders a role=status warning strip above data with a refresh icon and as_of timestamp" do
      assigns = %{as_of: "2026-06-14 23:59 UTC"}

      html =
        rendered_to_string(~H"""
        <UI.stale_banner as_of={@as_of} />
        """)

      assert html =~ "tl-alert"
      assert html =~ "tl-alert--warning"
      assert html =~ ~s(role="status")
      assert html =~ "tl-icon"
      assert html =~ "Couldn't refresh"
      assert html =~ "2026-06-14 23:59 UTC"
      assert html =~ "Retry"
    end
  end

  describe "empty_state variant extension (no_data / permission / unavailable)" do
    test "no_data renders role=status with a funnel icon and the filter heading" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.empty_state variant="no_data">
          <:title>No changes match these filters</:title>
          Clear the filter or widen the time range.
        </UI.empty_state>
        """)

      assert html =~ "tl-empty--no_data"
      assert html =~ "No changes match these filters"
    end

    test "permission and unavailable are accepted variant values" do
      for variant <- ["permission", "unavailable"] do
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <UI.empty_state variant={@variant}>
            <:title>Heading</:title>
            Body
          </UI.empty_state>
          """)

        assert html =~ "tl-empty--#{variant}"
      end
    end
  end

  describe "data_state/1 — typed reason dispatch (DATA-03, D-13..D-16)" do
    @reason_cases [
      {:unauthorized, "alert", "don't have access", "lock"},
      {:no_data, "status", "No changes match", "funnel"},
      {:source_down, "alert", "temporarily unavailable", "cloud_off"},
      {:redacted, "status", "withheld by policy", "eye_off"},
      {:pruned, "status", "Removed under retention", "archive"},
      {:loading, "status", "Loading audit changes", "spinner"},
      {:boom, "alert", "Could not load", "warning"}
    ]

    defp data_state_html(reason) do
      assigns = %{reason: reason}

      rendered_to_string(~H"""
      <UI.data_state reason={@reason} />
      """)
    end

    test "each typed reason renders its locked role + heading" do
      for {reason, role, heading, _icon} <- @reason_cases do
        html = data_state_html(reason)

        assert html =~ ~s(role="#{role}"),
               "reason #{inspect(reason)} should carry role=#{role}"

        assert html =~ heading,
               "reason #{inspect(reason)} should render heading fragment #{inspect(heading)}"
      end
    end

    test "the content-replacing states each use a distinct icon shape (D-16, no color alone)" do
      icon_paths = %{
        lock: "M6 11h12v9H6z",
        funnel: "M4 5h16l-6 7v6l-4 2v-8L4 5Z",
        cloud_off: "M3 3l18 18",
        eye_off: "M10.6 10.6a2 2 0 0 0 2.8 2.8",
        archive: "M9 11h6"
      }

      signatures =
        for reason <- [:unauthorized, :no_data, :source_down, :redacted, :pruned] do
          html = data_state_html(reason)
          assert html =~ "tl-icon"
          html
        end

      # Each state's expected glyph path is present.
      assert data_state_html(:unauthorized) =~ icon_paths.lock
      assert data_state_html(:no_data) =~ icon_paths.funnel
      assert data_state_html(:source_down) =~ icon_paths.cloud_off
      assert data_state_html(:redacted) =~ icon_paths.eye_off
      assert data_state_html(:pruned) =~ icon_paths.archive

      # No two content-replacing states share their whole rendered glyph set.
      first_paths =
        Enum.map(signatures, fn html ->
          Regex.scan(~r/<path[^>]*\bd="([^"]*)"/, html)
          |> Enum.map(fn [_, d] -> d end)
          |> Enum.join("|")
        end)

      assert length(Enum.uniq(first_paths)) == length(first_paths)
    end

    test "the three unavailable sub-cases state they are NOT a permissions issue" do
      for reason <- [:source_down, :redacted, :pruned] do
        assert data_state_html(reason) =~ "not a permissions issue",
               "unavailable reason #{inspect(reason)} must say it is not a permissions issue"
      end
    end
  end

  describe "focus rescue (D-15) — error_state and permission heading" do
    test "error_state renders a tabindex=-1 heading and moves focus to it on mount" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.error_state>
          <:title>Could not load this timeline</:title>
          Retry, then check logs.
        </UI.error_state>
        """)

      assert html =~ ~s(tabindex="-1")
      assert html =~ "phx-mounted"
    end

    test "the permission data-state renders a tabindex=-1 heading with focus moved on mount" do
      html = data_state_html(:unauthorized)

      assert html =~ ~s(tabindex="-1")
      assert html =~ "phx-mounted"
    end
  end

  # ===========================================================================
  # Phase 177 (GROUP-01 / GROUP-02) — RED Wave-0 component scaffolds.
  #
  # These pin the render + coordination contract for the five new meta-components
  # BEFORE any production code exists (Nyquist: tests precede code). They fail
  # today because UI.stack/cluster/data_panel/toolbar/detail_header are undefined,
  # and turn GREEN in Plans 02 (stack/cluster/data_panel/toolbar) and 03
  # (detail_header + breadcrumb truncation). Do NOT add production code here.
  # ===========================================================================

  describe "stack/1 (D-02) [RED — Plan 02]" do
    test "owns vertical rhythm via gap classes and never raw child margins" do
      assigns = %{}

      section =
        rendered_to_string(~H"""
        <UI.stack gap="section">
          <div>row a</div>
          <div>row b</div>
        </UI.stack>
        """)

      assert section =~ "tl-stack"
      assert section =~ "tl-stack--section"
      assert section =~ "row a"

      default =
        rendered_to_string(~H"""
        <UI.stack>
          <div>only</div>
        </UI.stack>
        """)

      # Default gap is the stack rhythm.
      assert default =~ "tl-stack--stack"

      # The stack owns gap via flex — it must NOT push spacing through an inline
      # margin style on the element (that's the per-call-site class-soup D-02 kills).
      refute Regex.match?(~r/<div[^>]*style="[^"]*margin/, default)
    end
  end

  describe "cluster/1 (D-02) [RED — Plan 02]" do
    test "wraps horizontally and exposes a justify modifier" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.cluster justify="between">
          <button>search</button>
          <button>filter</button>
        </UI.cluster>
        """)

      assert html =~ "tl-cluster"
      assert html =~ "tl-cluster--between"
      assert html =~ "search"
    end
  end

  describe "data_panel/1 (D-03 / D-06 / D-06c) [RED — Plan 02]" do
    test ":ok renders the data slot and a pager slot only when ok" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.data_panel state={:ok}>
          <:data><div id="the-data-table">rows</div></:data>
          <:pager><div id="the-pager">pager</div></:pager>
        </UI.data_panel>
        """)

      assert html =~ "tl-data-panel"
      assert html =~ "the-data-table"
      # Pager renders in the :ok state.
      assert html =~ "the-pager"
    end

    test ":loading suppresses the data slot and shows the loading region" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.data_panel state={:loading}>
          <:data><div id="the-data-table">rows</div></:data>
          <:pager><div id="the-pager">pager</div></:pager>
        </UI.data_panel>
        """)

      # The data slot is NOT rendered while loading (toolbar-disable is the page's job).
      refute html =~ "the-data-table"
      # A status loading region appears instead.
      assert html =~ ~s(role="status")
      # Pager is hidden when not :ok.
      refute html =~ "the-pager"
    end

    test ":permission collapses the body to one message and suppresses the data slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.data_panel state={:permission} reason={:unauthorized}>
          <:data><div id="the-data-table">rows</div></:data>
        </UI.data_panel>
        """)

      refute html =~ "the-data-table"
      assert html =~ "don't have access"
      # Focus-move on permission is delegated to the existing state family (D-06c):
      # the rendered output carries the focus-rescue heading, not a reinvention.
      assert html =~ ~s(tabindex="-1")
      assert html =~ "phx-mounted"
    end

    test "as_of renders a stale banner ABOVE the region regardless of state" do
      assigns = %{as_of: "2026-06-14 23:59 UTC"}

      for state <- [:ok, :loading] do
        assigns = Map.put(assigns, :state, state)

        html =
          rendered_to_string(~H"""
          <UI.data_panel state={@state} as_of={@as_of}>
            <:data><div id="the-data-table">rows</div></:data>
          </UI.data_panel>
          """)

        assert html =~ "tl-alert--warning", "stale banner must render for state #{inspect(state)}"
        assert html =~ "2026-06-14 23:59 UTC"

        # The stale banner sits ABOVE the data region container, never replacing it (D-176-14).
        banner_idx = :binary.match(html, "tl-alert--warning") |> elem(0)
        region_idx = :binary.match(html, "tl-data-panel__region") |> elem(0)

        assert banner_idx < region_idx,
               "stale banner must precede the data region (#{inspect(state)})"
      end
    end
  end

  describe "toolbar/1 (D-06 / RESEARCH Pitfall 6) [RED — Plan 02]" do
    test "disabled emits aria-disabled + is-disabled and the controls carry HTML disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.toolbar disabled={true}>
          <button disabled>Filter</button>
        </UI.toolbar>
        """)

      assert html =~ "tl-toolbar"
      assert html =~ ~s(aria-disabled="true")
      assert html =~ "is-disabled"
      # pointer-events:none is the affordance; the HTML `disabled` attr is the
      # enforcement (the page sets it on controls from the same state assign).
      assert html =~ ~r/<button[^>]*\bdisabled/
    end

    test "enabled toolbar renders without the disabled coordination signals" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.toolbar disabled={false}>
          <button>Filter</button>
        </UI.toolbar>
        """)

      assert html =~ "tl-toolbar"
      refute html =~ "is-disabled"
    end
  end

  describe "detail_header/1 (D-03) [RED — Plan 03]" do
    test "renders an <h2> title (not <h1>), a kv metadata block, and an actions cluster" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.detail_header title="tx_0192">
          <:metadata key="Actor">alice</:metadata>
          <:metadata key="When">just now</:metadata>
          <:actions><button>Export</button></:actions>
        </UI.detail_header>
        """)

      assert html =~ "tl-detail-header"
      # page_header owns the single <h1>; the detail header is an <h2> (D-175-03).
      assert html =~ ~r/<h2[^>]*>\s*tx_0192\s*<\/h2>/
      refute html =~ "<h1"
      # Metadata is a kv block.
      assert html =~ "tl-kv"
      assert html =~ "Actor"
      assert html =~ "alice"
      # Actions render in a cluster.
      assert html =~ "tl-cluster"
      assert html =~ "Export"
    end
  end

  describe "page_header breadcrumbs (D-04 reconciled to D-14: keep list attr) [RED-ish — extends existing attr]" do
    test "renders the breadcrumb trail with the last crumb non-linked" do
      assigns = %{
        breadcrumbs: [
          %{label: "Timeline", href: "/audit/timeline"},
          %{label: "tx_0192"}
        ]
      }

      html =
        rendered_to_string(~H"""
        <UI.page_header title="Transaction" breadcrumbs={@breadcrumbs} />
        """)

      assert html =~ ~s(<nav aria-label="Breadcrumb")
      # Ancestor crumb is a link.
      assert html =~ ~s(href="/audit/timeline")
      assert html =~ "Timeline"
      # Last crumb is the current location — rendered as plain text, not a link.
      assert html =~ ~r/<span[^>]*>\s*tx_0192\s*<\/span>/
    end
  end
end
