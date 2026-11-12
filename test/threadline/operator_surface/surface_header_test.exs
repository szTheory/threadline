if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.SurfaceHeaderTest do
    use ExUnit.Case, async: true
    import Phoenix.LiveViewTest

    alias Threadline.OperatorSurface.Components.SurfaceHeader

    @coverage %{uncovered_count: 0, last_checked_at: ~U[2026-06-04 00:00:00Z]}
    @root Path.expand("../../..", __DIR__)

    test "renders grouped rail IA and preserved header affordances" do
      html = render_header()

      assert nav_root_count(html) == 1
      assert html =~ ~s|href="/audit"|
      assert html =~ ~s|class="tl-topbar__brand"|
      assert html =~ ~s|aria-label="Threadline Admin home"|
      assert Regex.scan(~r/aria-label="Threadline Admin home"/, html) |> length() == 1
      assert_supplied_logo_pair(html)
      assert html =~ ~s|href="#tl-main"|
      assert html =~ ~s|data-testid="operator-nav-shell"|
      assert html =~ ~s|aria-label="Audit navigation"|
      assert html =~ ~s|<details class="tl-shell-nav__disclosure">|
      assert html =~ ~s|class="tl-shell-nav__toggle"|
      assert html =~ ~s|aria-controls="tl-shell-nav-panel"|
      assert html =~ ">Audit navigation</summary>"
      assert html =~ ~s|id="tl-shell-nav-panel"|
      assert html =~ ~s|class="tl-shell-nav__overview"|
      assert html =~ ~s|data-testid="operator-nav-overview"|
      assert html =~ ~s|data-testid="operator-scope"|
      assert html =~ "Scoped view"
      assert html =~ "All tables captured"
      assert_before(html, ~s|data-testid="operator-nav-overview"|, ~s|id="tl-shell-nav-find"|)

      for {id, label} <- [
            {"tl-shell-nav-find", "Investigate"},
            {"tl-shell-nav-verify", "Audit readiness"},
            {"tl-shell-nav-prove", "Evidence & exports"}
          ] do
        assert html =~ ~s|id="#{id}"|
        assert html =~ ">#{html_label(label)}</h2>"
      end

      for old_label <- ["Find", "Verify", "Prove"] do
        refute html =~ ">#{old_label}</h2>"
      end

      assert_nav_href(html, :start, "/audit")
      assert_nav_href(html, :timeline, "/audit/timeline")
      assert_nav_href(html, :coverage, "/audit/coverage")
      assert_nav_href(html, :evidence, "/audit/evidence")
      assert_nav_href(html, :policy, "/audit/policy/redaction")
      assert_nav_href(html, :retention, "/audit/policy/retention")
      assert_nav_href(html, :exports, "/audit/exports")

      for page <- [:timeline, :coverage, :evidence, :policy, :retention, :exports] do
        assert html =~ ~s|data-testid="operator-nav-#{page}"|
      end
    end

    test "supplied lockups preserve source geometry and colors without duplicate names" do
      html = render_header()

      for {variant, filename} <- [
            {"dark", "threadline-lockup-dark.svg"},
            {"light", "threadline-lockup-light.svg"}
          ] do
        source = File.read!(Path.join([@root, "brand", "assets", "logo", filename]))
        rendered = rendered_logo!(html, variant)

        assert rendered["attributes"] =~ ~s|aria-hidden="true"|
        assert rendered["attributes"] =~ ~s|focusable="false"|
        refute rendered["attributes"] =~ ~s|role="img"|
        refute rendered["body"] =~ "<title>"
        assert source_view_box(source) == rendered_view_box(rendered["attributes"])
        assert source_paths(source) == rendered_paths(rendered["body"])
        assert length(rendered_paths(rendered["body"])) == 3
      end
    end

    test "renders immediate native POST theme buttons with stable CSRF and pressed state" do
      html = render_header(%{theme: "system"})

      assert html =~ ~s|action="/audit/theme"|
      assert html =~ ~s|method="post"|
      assert html =~ ~s|name="_csrf_token"|
      assert html =~ ~s|id="tl-shell-nav-theme" class="tl-shell-nav__label">Theme</legend>|
      assert html =~ ~s|class="tl-theme-picker__selected"|
      assert html =~ "Selected"

      theme_buttons =
        html
        |> Regex.scan(~r/<button\b[^>]*name="theme"[^>]*>.*?<\/button>/s)
        |> Enum.map(&List.first/1)

      assert length(theme_buttons) == 3

      for {value, label} <- [{"system", "System"}, {"light", "Light"}, {"dark", "Dark"}] do
        [button] = Enum.filter(theme_buttons, &String.contains?(&1, ~s|value="#{value}"|))

        assert button =~ ~s|type="submit"|
        assert button =~ ~s|aria-label="#{label}"|
        assert button =~ ~r/aria-pressed="(?:true|false)"/
        assert button =~ ~r/>#{label}<\/span>/
      end

      assert Enum.count(theme_buttons, &String.contains?(&1, ~s|aria-pressed="true"|)) == 1
      assert Enum.any?(theme_buttons, &String.contains?(&1, ~s|value="system" aria-pressed="true"|))
      refute html =~ ~s|Apply theme|
      refute html =~ ~s|type="radio"|
      refute html =~ ~s|onclick=|
      refute html =~ ~s|localStorage|
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

    test "keeps Exports as a normal Evidence & exports destination" do
      html = render_header()

      refute html =~ ~s|class="tl-topbar__nav-handoff"|
      assert html =~ ~s|data-testid="operator-nav-exports"|
      assert_nav_href(html, :exports, "/audit/exports")
    end

    test "feature flags remove only governed destinations and preserve header affordances" do
      html = render_header(%{coverage_enabled: false})

      refute html =~ ~s|data-testid="operator-nav-coverage"|
      refute html =~ ~s|data-testid="operator-nav-group-readiness"|
      refute html =~ ">Audit readiness</h2>"
      refute html =~ "All tables captured"
      assert html =~ ~s|data-testid="operator-nav-overview"|
      assert html =~ ">Investigate</h2>"
      assert html =~ ">Evidence & exports</h2>"
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

    test "feature-gated navigation groups expose stable source IDs" do
      html = render_header()

      assert html =~ ~s|data-testid="operator-nav-group-investigate"|
      assert html =~ ~s|data-testid="operator-nav-group-readiness"|
      assert html =~ ~s|data-testid="operator-nav-group-evidence"|
      assert html =~ ~s|data-testid="operator-nav-group-theme"|

      html = render_header(%{coverage_enabled: false})

      assert html =~ ~s|data-testid="operator-nav-group-investigate"|
      refute html =~ ~s|data-testid="operator-nav-group-readiness"|
      assert html =~ ~s|data-testid="operator-nav-group-evidence"|
      assert html =~ ~s|data-testid="operator-nav-group-theme"|

      html =
        render_header(%{
          evidence_enabled: false,
          policy_enabled: false,
          exports_enabled: false
        })

      assert html =~ ~s|data-testid="operator-nav-group-investigate"|
      assert html =~ ~s|data-testid="operator-nav-group-readiness"|
      refute html =~ ~s|data-testid="operator-nav-group-evidence"|
      refute html =~ ">Evidence &amp; exports</h2>"
      assert html =~ ~s|data-testid="operator-nav-group-theme"|
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

    defp nav_root_count(html) do
      ~r/<nav[^>]*data-testid="operator-nav-shell"[^>]*aria-label="Audit navigation"[^>]*>/
      |> Regex.scan(html)
      |> length()
    end

    defp assert_nav_href(html, page, href) do
      assert nav_tag!(html, page) =~ ~s|href="#{href}"|
    end

    defp html_label(label) do
      label
    end

    defp assert_preserved_affordances(html) do
      assert html =~ ~s|class="tl-topbar__brand" href="/audit"|
      assert html =~ ~s|aria-label="Threadline Admin home"|
      assert html =~ ~s|href="#tl-main"|
      assert html =~ ~s|data-testid="operator-nav-overview"|
      assert html =~ ~s|data-testid="operator-scope"|
    end

    defp assert_supplied_logo_pair(html) do
      assert length(
               Regex.scan(
                 ~r/<svg class="tl-topbar__brand-logo tl-topbar__brand-logo--dark"/,
                 html
               )
             ) == 1

      assert length(
               Regex.scan(
                 ~r/<svg class="tl-topbar__brand-logo tl-topbar__brand-logo--light"/,
                 html
               )
             ) == 1

      assert html =~ ~s|class="tl-topbar__brand-lockups"|
    end

    defp rendered_logo!(html, variant) do
      pattern =
        ~r/<svg class="tl-topbar__brand-logo tl-topbar__brand-logo--#{variant}"(?<attributes>[^>]*)>(?<body>.*?)<\/svg>/s

      case Regex.named_captures(pattern, html) do
        %{"attributes" => attributes, "body" => body} ->
          %{"attributes" => attributes, "body" => body}

        nil ->
          flunk("expected rendered #{variant} lockup in:\n#{html}")
      end
    end

    defp source_view_box(source) do
      Regex.run(~r/<svg[^>]*viewBox="([^"]+)"/, source, capture: :all_but_first)
      |> List.first()
    end

    defp rendered_view_box(attributes) do
      Regex.run(~r/\bviewBox="([^"]+)"/, attributes, capture: :all_but_first)
      |> List.first()
    end

    defp source_paths(source),
      do: Regex.scan(~r/<path\b[^>]*\/>/, source, capture: :first) |> List.flatten()

    defp rendered_paths(body),
      do: Regex.scan(~r/<path\b[^>]*\/>/, body, capture: :first) |> List.flatten()

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
