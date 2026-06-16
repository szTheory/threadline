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
end
