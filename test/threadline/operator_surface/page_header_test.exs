if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.PageHeaderTest do
    @moduledoc """
    Wave 0 RED scaffold for NAV-01 / D-11 — the one-`<h1>`-per-page page header.

    Asserts the *target* contract for the not-yet-built `UI.page_header/1`
    component (Plan 03 owns the implementation): a single `<h1 class="tl-page__title">`
    wrapped in `<header class="tl-page__header">`, and an optional breadcrumb landmark
    `<nav aria-label="Breadcrumb">` when a `breadcrumbs` assign is supplied.

    Expected state at Wave 0 (this plan, 175-01):
      * RED — `Threadline.OperatorSurface.UI.page_header/1` does not exist yet, so the
        render raises / fails to compile the call. This is an acceptable Wave 0 scaffold;
        Plan 03 turns it GREEN by adding the component on the contract below.

    Idiom copied from `ui_test.exs` (rendered_to_string standalone component render).
    """
    use ExUnit.Case, async: true
    import Phoenix.Component
    import Phoenix.LiveViewTest

    alias Threadline.OperatorSurface.UI

    test "renders exactly one <h1 class=tl-page__title> inside tl-page__header (NAV-01/D-11)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.page_header title="Timeline" />
        """)

      assert html =~ ~s|<header class="tl-page__header"|
      assert html =~ "tl-page__title"
      assert html =~ "Timeline"
      assert h1_count(html) == 1
    end

    test "renders a Breadcrumb landmark when breadcrumbs are supplied (NAV-01)" do
      assigns = %{
        crumbs: [
          %{label: "Timeline", href: "/audit/timeline"},
          %{label: "Transaction"}
        ]
      }

      html =
        rendered_to_string(~H"""
        <UI.page_header title="Transaction" breadcrumbs={@crumbs} />
        """)

      assert html =~ ~s|<nav aria-label="Breadcrumb"|
      assert h1_count(html) == 1
    end

    defp h1_count(html) do
      ~r/<h1[\s>]/
      |> Regex.scan(html)
      |> length()
    end
  end
end
