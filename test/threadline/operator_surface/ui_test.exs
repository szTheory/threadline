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
end
