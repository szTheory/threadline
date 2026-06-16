defmodule Threadline.OperatorSurface.UITest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Threadline.OperatorSurface.UI

  describe "button" do
    test "renders button with correct tl-button class" do
      assigns = %{}
      html = rendered_to_string(~H"""
      <UI.button>Click Me</UI.button>
      """)
      assert html =~ "tl-button"
      assert html =~ "Click Me"
    end
  end

  describe "icon_button" do
    test "renders icon_button" do
      assigns = %{}
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
      <UI.divider />
      """)
      assert html =~ "tl-divider"
      assert html =~ "<hr"
    end
  end

  describe "spinner" do
    test "renders spinner component properly" do
      assigns = %{}
      html = rendered_to_string(~H"""
      <UI.spinner />
      """)
      assert html =~ "tl-spinner"
      assert html =~ "<svg"
    end
  end

  describe "avatar" do
    test "renders avatar component properly" do
      assigns = %{}
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
      html = rendered_to_string(~H"""
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
end
