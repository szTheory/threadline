defmodule Threadline.OperatorSurface.UIStressTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Threadline.OperatorSurface.UI

  describe "permutations" do
    test "validates full matrix of component instances" do
      # Button permutations
      for variant <- ~w(primary secondary quiet-primary danger ghost icon) do
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <UI.Actions.button variant={@variant}>Btn</UI.Actions.button>
          """)

        assert html =~ "tl-button"

        if variant != "secondary" do
          assert html =~ "tl-button--#{variant}"
        end
      end

      # Badge permutations
      for variant <- ~w(info warning danger success accent muted neutral) do
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <UI.Display.badge variant={@variant}>Badge</UI.Display.badge>
          """)

        assert html =~ "tl-chip"
        assert html =~ "tl-chip--#{variant}"
      end

      # Alert permutations
      for variant <- ~w(info warning success error) do
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <UI.Display.alert variant={@variant}>Alert</UI.Display.alert>
          """)

        assert html =~ "tl-alert"
        assert html =~ "tl-alert--#{variant}"
      end

      # Card permutations
      for variant <- [nil, "danger", "warning", "success", "info", "signal"] do
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <UI.Display.card variant={@variant}>Card</UI.Display.card>
          """)

        assert html =~ "tl-card"

        if variant do
          assert html =~ "tl-card--#{variant}"
        end
      end

      # Stat tile permutations
      for status <- [nil, "danger", "warning", "success", "info", "signal"] do
        assigns = %{status: status}

        html =
          rendered_to_string(~H"""
          <UI.Display.stat_tile status={@status} label="L" value="V" />
          """)

        assert html =~ "tl-card--metric"

        if status do
          assert html =~ "data-status=\"#{status}\""
        end
      end

      # Empty state permutations
      for variant <- [nil, "error", "never", "unsupported"] do
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <UI.Data.empty_state variant={@variant}>Empty</UI.Data.empty_state>
          """)

        assert html =~ "tl-empty"

        if variant do
          assert html =~ "tl-empty--#{variant}"
        end
      end
    end

    test "ensures non-interactive badges/states don't output cursor-pointer or button-like bindings" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.Display.badge variant="success">Active</UI.Display.badge>
        """)

      refute html =~ "cursor-pointer"
      refute html =~ "phx-click"
      refute html =~ "href="
      refute html =~ "type=\"button\""
      refute html =~ "<button"

      html =
        rendered_to_string(~H"""
        <UI.Display.stat_tile label="L" value="V" />
        """)

      refute html =~ "cursor-pointer"
      refute html =~ "phx-click"
      refute html =~ "href="
      refute html =~ "type=\"button\""
      refute html =~ "<button"
    end
  end
end
