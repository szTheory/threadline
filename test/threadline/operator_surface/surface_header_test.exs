if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.SurfaceHeaderTest do
    use ExUnit.Case, async: true
    import Phoenix.LiveViewTest

    alias Threadline.OperatorSurface.Components.SurfaceHeader

    @coverage %{uncovered_count: 0, last_checked_at: ~U[2026-06-04 00:00:00Z]}

    test "renders grouped rail IA and preserved header affordances" do
      html = render_header()

      assert html =~ ~s|href="/audit"|
      assert html =~ ~s|class="tl-topbar__brand"|
      assert html =~ ~s|aria-label="Threadline operator home"|
      assert html =~ ~s|class="tl-topbar__brand-logo"|
      assert html =~ ~s|class="tl-topbar__brand-wordmark"|
      assert html =~ ~s|>Threadline</text>|
      assert html =~ ~s|aria-hidden="true"|
      assert html =~ ~s|focusable="false"|
      refute html =~ ~s|tl-topbar__brand-mark|
      refute html =~ ~s|tl-topbar__brand-text|
      refute html =~ ~s|role="img"|
      assert html =~ ~s|href="#tl-main"|
      assert html =~ ~s|data-testid="operator-nav-shell"|
      assert html =~ ~s|class="tl-shell-nav__toggle"|
      assert html =~ ~s|class="tl-shell-nav__overview"|
      assert html =~ ~s|data-testid="operator-nav-overview"|
      assert html =~ ~s|data-testid="operator-scope"|
      assert html =~ "Scoped view"
      assert html =~ "All tables captured"
      assert_before(html, ~s|data-testid="operator-nav-overview"|, ~s|id="tl-shell-nav-find"|)

      for label <- ["Find", "Verify", "Prove"] do
        assert html =~ ">#{label}</h2>"
      end

      for page <- [:timeline, :coverage, :evidence, :policy, :retention, :exports] do
        assert html =~ ~s|data-testid="operator-nav-#{page}"|
      end
    end

    test "uses current atom as the single aria-current source" do
      for page <- [:start, :timeline, :coverage, :evidence, :policy, :retention, :exports] do
        html = render_header(%{current: page})
        tag = nav_tag!(html, page)

        assert aria_current_count(html) == 1
        assert tag =~ ~s|aria-current="page"|
        assert tag =~ "tl-shell-nav__item--active"
      end
    end

    test "start current marks Overview active and keeps Home on the brand link" do
      html = render_header(%{current: :start})
      tag = nav_tag!(html, :start)

      assert html =~ ~s|class="tl-topbar__brand" href="/audit"|
      assert aria_current_count(html) == 1
      assert tag =~ ~s|aria-current="page"|
      assert tag =~ "tl-shell-nav__item--active"

      for page <- [:timeline, :coverage, :evidence, :policy, :retention, :exports] do
        refute nav_tag!(html, page) =~ "tl-shell-nav__item--active"
      end
    end

    test "keeps Exports as a normal Prove destination" do
      html = render_header()

      refute html =~ ~s|class="tl-topbar__nav-handoff"|
      assert html =~ ~s|data-testid="operator-nav-exports"|
    end

    test "feature flags remove only governed destinations and preserve header affordances" do
      html = render_header(%{coverage_enabled: false})

      refute html =~ ~s|data-testid="operator-nav-coverage"|
      refute html =~ "All tables captured"
      assert html =~ ~s|data-testid="operator-nav-overview"|
      assert html =~ ">Find</h2>"
      assert html =~ ">Prove</h2>"
      assert html =~ ~s|data-testid="operator-nav-exports"|
      assert_preserved_affordances(html)

      html = render_header(%{evidence_enabled: false})

      refute html =~ ~s|data-testid="operator-nav-evidence"|
      assert html =~ ~s|data-testid="operator-nav-overview"|
      assert html =~ ~s|data-testid="operator-nav-policy"|
      assert html =~ ~s|data-testid="operator-nav-retention"|
      assert html =~ ~s|data-testid="operator-nav-exports"|
      assert_preserved_affordances(html)

      html = render_header(%{policy_enabled: false})

      refute html =~ ~s|data-testid="operator-nav-policy"|
      refute html =~ ~s|data-testid="operator-nav-retention"|
      assert html =~ ~s|data-testid="operator-nav-overview"|
      assert html =~ ~s|data-testid="operator-nav-evidence"|
      assert html =~ ~s|data-testid="operator-nav-exports"|
      assert_preserved_affordances(html)

      html = render_header(%{exports_enabled: false})

      refute html =~ ~s|data-testid="operator-nav-exports"|
      assert html =~ ~s|data-testid="operator-nav-overview"|
      assert html =~ ~s|data-testid="operator-nav-evidence"|
      assert html =~ ~s|data-testid="operator-nav-policy"|
      assert html =~ ~s|data-testid="operator-nav-retention"|
      assert_preserved_affordances(html)
    end

    defp render_header(overrides \\ %{}) do
      assigns =
        Map.merge(
          %{
            coverage: @coverage,
            base_path: "/audit",
            coverage_enabled: true,
            policy_enabled: true,
            evidence_enabled: true,
            exports_enabled: true,
            current: nil,
            scoped: true
          },
          overrides
        )

      render_component(&SurfaceHeader.surface_header/1, assigns)
    end

    defp nav_tag!(html, :start) do
      tag_by_test_id!(html, "operator-nav-overview")
    end

    defp nav_tag!(html, page) do
      tag_by_test_id!(html, "operator-nav-#{page}")
    end

    defp tag_by_test_id!(html, test_id) do
      pattern = ~r/<a[^>]*data-testid="#{test_id}"[^>]*>/

      case Regex.run(pattern, html) do
        [tag] -> tag
        nil -> flunk("expected #{test_id} link in:\n#{html}")
      end
    end

    defp aria_current_count(html) do
      ~r/aria-current="page"/
      |> Regex.scan(html)
      |> length()
    end

    defp assert_preserved_affordances(html) do
      assert html =~ ~s|class="tl-topbar__brand" href="/audit"|
      assert html =~ ~s|href="#tl-main"|
      assert html =~ ~s|data-testid="operator-nav-overview"|
      assert html =~ ~s|data-testid="operator-scope"|
    end

    defp assert_before(html, first, second) do
      first_index = :binary.match(html, first)
      second_index = :binary.match(html, second)

      assert first_index != :nomatch
      assert second_index != :nomatch

      {first_offset, _} = first_index
      {second_offset, _} = second_index
      assert first_offset < second_offset
    end
  end
end
