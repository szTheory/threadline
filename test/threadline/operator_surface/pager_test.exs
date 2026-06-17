if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.PagerTest do
    @moduledoc """
    Wave 0 RED scaffold for NAV-02 / D-16 / D-17 / D-18 — the timeline pager.

    Asserts the *target* contract for the not-yet-built `UI.pager/1` component
    (Plan 04 owns the implementation):
      * D-16 hide-at-zero — when there are no results the pager renders nothing
        (no `tl-pager` markup at all), never an empty disabled shell.
      * D-18 disable-not-hide — on a boundary (e.g. the only/last page), the
        unavailable directional control ("Older"/"Newer") stays in the DOM but is
        `disabled`; it is never dropped.
      * range caption — the count container carries `role="status" aria-live="polite"`
        with the "Showing N of … matching changes" copy from 175-UI-SPEC.md.
      * D-17 deep-total cap — when `match_count >= 10_001` the caption shows "10,000+"
        and never an exact deep total.

    Expected state at Wave 0 (this plan, 175-01):
      * RED — `Threadline.OperatorSurface.UI.pager/1` does not exist yet, so the render
        raises / fails to compile the call. Plan 04 turns it GREEN on the contract above.

    Idiom copied from `ui_test.exs` (rendered_to_string standalone component render).
    """
    use ExUnit.Case, async: true
    import Phoenix.Component
    import Phoenix.LiveViewTest

    alias Threadline.OperatorSurface.UI

    test "hides the entire pager when there are zero results (NAV-02/D-16)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.pager shown={0} match_count={0} has_older={false} has_newer={false} />
        """)

      refute html =~ "tl-pager"
    end

    test "disables, never hides, the unavailable boundary control (NAV-02/D-18)" do
      assigns = %{}

      # A single full page: "Newer" has nowhere to go and must render disabled.
      html =
        rendered_to_string(~H"""
        <UI.pager shown={25} match_count={25} has_older={true} has_newer={false} />
        """)

      assert html =~ "Older"
      assert html =~ "Newer"
      assert html =~ "disabled"
    end

    test "range caption is a polite status with Showing-N-of copy (NAV-02)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.pager shown={25} match_count={250} has_older={true} has_newer={true} />
        """)

      assert html =~ ~s|role="status"|
      assert html =~ ~s|aria-live="polite"|
      assert html =~ "Showing"
      assert html =~ "matching changes"
    end

    test "caps the deep total at 10,000+ rather than an exact count (NAV-02/D-17)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.pager shown={25} match_count={50_000} has_older={true} has_newer={true} />
        """)

      assert html =~ "10,000+"
      refute html =~ "50,000"
      refute html =~ "50000"
    end
  end
end
