defmodule Threadline.OperatorSurface.ComponentContractTest do
  @moduledoc """
  Shift-left automation of Phase 177 human-verification items (177-UAT.md).

  Covers UAT #2 (data_panel state matrix) in full and the structural half of
  UAT #4 (reconnect / [data-tl-mutating] CSS contract) as fast, deterministic
  DOM/contract assertions — no browser required. The real-viewport, motion, and
  live-socket halves live in the example app's
  `e2e/tests/operator-phase-177-uat.spec.ts` (CI job `verify-example-browser`).

  These replace the manual /audit/__stress checkpoints, so the recurring value is
  in `mix test` (CI job `verify-test`) on every change.
  """
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Threadline.OperatorSurface.UI

  @style_path "lib/threadline/operator_surface/style.ex"
  @ui_source_path "lib/threadline/operator_surface/ui.ex"
  @source_prose_files [
    "test/threadline/operator_surface/card_nesting_regression_test.exs",
    "test/threadline/operator_surface/data_state_mapping_wave0_test.exs",
    "test/threadline/operator_surface/component_contract_test.exs",
    "test/threadline/operator_surface/style_contract_test.exs",
    "test/threadline/operator_surface/live/retention_history_live_test.exs",
    "test/threadline/operator_surface/breadcrumb_test.exs",
    "test/threadline/operator_surface/stress_fixtures_test.exs"
  ]

  @stale_source_prose_patterns [
    old_red_today_marker: ~r/\bRED\s+today\b/i,
    old_red_until_plan_marker: ~r/\bRED\s+until\s+Plan\b/i,
    old_red_wave_marker: ~r/\bRED\s+Wave-0\s+scaffold\b/i,
    old_wave_red_marker: ~r/\bWave-0\s+RED\b/i,
    old_binding_target_marker: ~r/\bbinding\s+RED\s+target\b/i,
    old_turns_green_marker: ~r/\bturns?\s+GREEN\b/i
  ]

  describe "active source-test prose repair guard (181-04)" do
    test "current source-test prose describes live invariants, not old scaffold state" do
      offenders =
        for file <- @source_prose_files,
            source = File.read!(file),
            {marker, pattern} <- @stale_source_prose_patterns,
            {line, line_no} <- source |> String.split("\n") |> Enum.with_index(1),
            Regex.match?(pattern, line) do
          {file, line_no, marker, String.trim(line)}
        end

      assert offenders == [],
             "active source-test prose still describes repaired guards as old scaffolds: #{inspect(offenders, pretty: true)}"
    end
  end

  # --- UAT #2: data_panel state matrix (D-03 / D-06 / D-13..D-16) -------------

  describe "data_panel state matrix (UAT #2)" do
    test ":ok renders the :data slot + pager, region tagged data-state=ok" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.data_panel state={:ok}>
          <:data><p id="payload">live rows</p></:data>
          <:pager><span id="pager">1 of 3</span></:pager>
        </UI.data_panel>
        """)

      assert html =~ ~s(data-state="ok")
      assert html =~ ~s(<p id="payload">live rows</p>)
      assert html =~ ~s(<span id="pager">1 of 3</span>)
      assert html =~ "tl-data-panel__pager"
    end

    test ":loading shows the loading state (role=status, aria-busy) and suppresses data/pager" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.data_panel state={:loading}>
          <:data><p id="payload">should not appear</p></:data>
          <:pager><span id="pager">hidden</span></:pager>
        </UI.data_panel>
        """)

      assert html =~ ~s(data-state="loading")
      assert html =~ "tl-empty--loading"
      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-busy="true")
      refute html =~ "should not appear"
      refute html =~ "tl-data-panel__pager"
    end

    test ":empty shows first-run empty (role=status), no variant modifier" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.data_panel state={:empty}>
          <:data><p>hidden</p></:data>
        </UI.data_panel>
        """)

      assert html =~ ~s(data-state="empty")
      assert html =~ "tl-empty"
      assert html =~ ~s(role="status")
      assert html =~ "No audit changes yet"
      assert html =~ "Audit changes appear after captured database transactions."
      refute html =~ "tl-empty--permission"
      refute html =~ "tl-empty--unavailable"
    end

    test ":no_data shows the filtered-out state with the funnel glyph (role=status)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.data_panel state={:no_data}>
          <:data><p>hidden</p></:data>
        </UI.data_panel>
        """)

      assert html =~ ~s(data-state="no_data")
      assert html =~ "tl-empty--no_data"
      assert html =~ ~s(role="status")
      assert html =~ "tl-empty__icon"
      # funnel glyph — the distinct "filters active, not an error" shape (D-16)
      assert html =~ "M4 5h16l-6 7v6l-4 2v-8L4 5Z"
    end

    test ":error shows the hard-error state (role=alert, focus-rescue heading)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.data_panel state={:error}>
          <:data><p>hidden</p></:data>
        </UI.data_panel>
        """)

      assert html =~ ~s(data-state="error")
      assert html =~ "tl-empty--error"
      assert html =~ ~s(role="alert")
      assert html =~ ~s(tabindex="-1")
    end

    test ":permission collapses to ONE message with the lock glyph (role=alert), never a generic empty" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.data_panel state={:permission} reason={:unauthorized}>
          <:data><p>should never leak</p></:data>
        </UI.data_panel>
        """)

      assert html =~ ~s(data-state="permission")
      assert html =~ "tl-empty--permission"
      assert html =~ ~s(role="alert")
      # lock glyph — the load-bearing "you lack access" forensic distinction (D-176-16)
      assert html =~ "M6 11h12v9H6z"
      refute html =~ "should never leak"
      # MUST NOT degrade to the generic empty / error copy.
      refute html =~ "Nothing here yet"
    end

    test ":unavailable (source_down) shows the cloud_off glyph and states it is NOT a permissions issue" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.data_panel state={:unavailable} reason={:source_down}>
          <:data><p>hidden</p></:data>
        </UI.data_panel>
        """)

      assert html =~ ~s(data-state="unavailable")
      assert html =~ "tl-empty--unavailable"
      # cloud_off slash — distinct from lock/funnel
      assert html =~ "M3 3l18 18"
      assert html =~ "not a permissions issue"
    end

    test ":unavailable distinguishes redacted (eye_off) from pruned (archive)" do
      assigns = %{}

      redacted =
        rendered_to_string(~H"""
        <UI.data_panel state={:unavailable} reason={:redacted}>
          <:data><p>hidden</p></:data>
        </UI.data_panel>
        """)

      pruned =
        rendered_to_string(~H"""
        <UI.data_panel state={:unavailable} reason={:pruned} as_of="2026-06-01">
          <:data><p>hidden</p></:data>
        </UI.data_panel>
        """)

      assert redacted =~ "tl-empty--unavailable"
      assert redacted =~ "Value redacted by policy"
      assert redacted =~ "Check the redaction policy before relying on this view."

      assert pruned =~ "tl-empty--unavailable"
      # archive glyph — the pruned-by-retention distinction
      assert pruned =~ "M3 7h18"
      assert pruned =~ "Audit data pruned under retention"
    end

    test "permission/unavailable without a typed reason fails loudly (never silently collapses)" do
      for state <- [:permission, :unavailable] do
        assigns = %{state: state}

        assert_raise ArgumentError, ~r/requires a typed :reason/, fn ->
          rendered_to_string(~H"""
          <UI.data_panel state={@state}>
            <:data><p>hidden</p></:data>
          </UI.data_panel>
          """)
        end
      end
    end

    test "stale banner (role=status, warning) sits ABOVE the still-rendered live region (D-176-14)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.data_panel state={:ok} as_of="2026-06-17 09:00">
          <:data><p id="payload">last known good rows</p></:data>
        </UI.data_panel>
        """)

      # stale banner coexists with :ok data, never replaces it
      assert html =~ "tl-alert--warning"
      assert html =~ "showing last known audit data"
      assert html =~ "last known good rows"

      banner_at = index_of!(html, "tl-alert--warning")
      region_at = index_of!(html, "tl-data-panel__region")
      payload_at = index_of!(html, "last known good rows")

      assert banner_at < region_at, "stale banner must precede the data region"
      assert region_at < payload_at, "live data still renders inside the region"
    end
  end

  # --- UAT #2: toolbar cross-child disable coordination (D-06) ----------------

  describe "toolbar disabled coordination (UAT #2)" do
    test "toolbar dims + marks aria-disabled when the data region is loading/erroring" do
      assigns = %{}

      disabled =
        rendered_to_string(~H"""
        <UI.toolbar disabled={true}><span>filters</span></UI.toolbar>
        """)

      enabled =
        rendered_to_string(~H"""
        <UI.toolbar disabled={false}><span>filters</span></UI.toolbar>
        """)

      assert disabled =~ "tl-toolbar"
      assert disabled =~ "is-disabled"
      assert disabled =~ ~s(aria-disabled="true")

      refute enabled =~ "is-disabled"
      assert enabled =~ ~s(aria-disabled="false")
    end
  end

  # --- Phase 173 UAT #2 (stacking): overlay z-index layer order ---------------

  describe "overlay z-index stacking order (Phase 173 UAT #2)" do
    test "z-layer tokens are defined in strict ascending order so overlays stack correctly" do
      src = File.read!(@style_path)

      layers = ~w(base toolbar header popover subview toast)

      values =
        Enum.map(layers, fn name ->
          case Regex.run(~r/--tl-z-#{name}:\s*(\d+);/, src) do
            [_, v] -> String.to_integer(v)
            _ -> flunk("missing --tl-z-#{name} token in style.ex")
          end
        end)

      # Each layer must sit strictly above the previous one: base < toolbar < header
      # < popover < subview (modal/drawer) < toast. This is the contract that keeps
      # tooltips/popovers/modals stacking above page chrome instead of behind it.
      assert values == Enum.sort(values) and length(Enum.uniq(values)) == length(values),
             "z-layer tokens must be strictly ascending, got: #{inspect(Enum.zip(layers, values))}"
    end
  end

  # --- UAT #4 (structural half): reconnect banner + mutating-control contract --

  describe "reconnect / offline contract (UAT #4)" do
    test "reconnect_banner renders a calm role=status strip with the refresh glyph" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <UI.reconnect_banner />
        """)

      assert html =~ "tl-reconnect-banner"
      assert html =~ ~s(role="status")
      assert html =~ "Reconnecting"
      # refresh glyph present (icon, not color, carries the meaning — D-16)
      assert html =~ "tl-alert__icon"
    end

    test "stylesheet anchors reconnect affordances on [data-phx-main] and scopes through .threadline-ui" do
      block =
        @style_path
        |> File.read!()
        |> reconnect_css_block!()

      # Hidden by default; revealed purely in CSS on the class-bearing
      # [data-phx-main] LiveView container, then scoped into the Threadline shell.
      assert block =~ ".tl-reconnect-banner {"

      for state <- ~w(loading error client-error) do
        assert block =~
                 "[data-phx-main].phx-#{state} .threadline-ui .tl-reconnect-banner",
               "reconnect banner selector must anchor on [data-phx-main].phx-#{state} and then descend through .threadline-ui"
      end

      assert block =~ "background: var(--tl-color-warning-bg);"

      # Mutating controls dim + go pointer-events:none while disconnected.
      for state <- ~w(loading error client-error) do
        assert block =~
                 "[data-phx-main].phx-#{state} .threadline-ui [data-tl-mutating]",
               "[data-tl-mutating] selector must anchor on [data-phx-main].phx-#{state} and then descend through .threadline-ui"
      end

      assert block =~ "pointer-events: none;"
      assert block =~ "opacity: 0.55;"

      refute Regex.match?(~r/\.threadline-ui\.phx-(loading|error|client-error)/, block),
             "reconnect CSS must not put LiveView lifecycle classes on .threadline-ui itself"

      refute String.contains?(block, "body.phx-"),
             "reconnect CSS must not use document-body lifecycle anchors"

      refute String.contains?(block, ".phx-disconnected"),
             "reconnect CSS must not use the legacy disconnected-class anchor"
    end
  end

  # --- Phase 180 A11Y-02: APG/native/non-applicability component map ----------

  describe "A11Y-02 APG semantics map" do
    test "custom APG widgets declare the state, popup, and relationship hooks they implement" do
      src = File.read!(@ui_source_path)

      assert src =~ ~s(role="dialog")
      assert src =~ ~s(aria-modal="true")
      assert src =~ ~S(aria-labelledby={"#{@id}-title"})
      assert src =~ ~S(aria-describedby={"#{@id}-description"})

      assert src =~ ~s(aria-haspopup="menu"),
             "dropdown triggers must expose the actual popup type, not a generic true value"

      assert src =~ ~s(aria-haspopup="dialog"),
             "popover triggers must expose the dialog popup type"

      assert src =~ ~s(aria-haspopup="listbox"),
             "combobox inputs must expose their listbox popup type"

      assert src =~ ~s(role="region"),
             "accordion panels must expose a named region relationship"

      assert src =~ ~s(tabindex={if tab[:active], do: "0", else: "-1"}),
             "tabs must use a roving-tabindex contract instead of placing every tab in the tab order"
    end

    test "native/non-applicable categories stay documented instead of gaining misleading ARIA roles" do
      src = File.read!(@ui_source_path)

      assert src =~ ~s(<select id={@id} name={@name}),
             "select remains native HTML, not a custom combobox"

      assert src =~ ~s(<input\n      type={@type}),
             "search/date/number controls remain native inputs"

      assert src =~ "NO ARIA role=\"table\"/\"row\"/\"cell\"",
             "data_table documents native table semantics rather than pretending to be an interactive grid"

      refute src =~ ~s(role="grid"),
             "Threadline has no custom interactive grid widget in the current operator surface"
    end
  end

  # --- Phase 178 (SEED-005 / D-10, D-11): reconnect banner mounted once --------
  #
  # SEED-005 (D-10) extracted the previously-11-way-duplicated
  # `<div class="threadline-ui">…<Style.css/>…<surface_header/>…<main id="tl-main">`
  # wrapper into ONE shared `@doc false` `UI.shell/1` chrome component. That shell
  # is the single mount point for `reconnect_banner/1`: rendered exactly once,
  # directly above `#tl-main` and inside `.threadline-ui`. All 11 operator
  # LiveViews route their chrome through `UI.shell` instead of hand-rolling the
  # wrapper, which is what gives the banner one structural home and kills drift.
  #
  # The guard therefore has two halves:
  #   (1) the shell in ui.ex carries the banner exactly once, in the right order;
  #   (2) every page LiveView routes through `UI.shell` (no per-page
  #       `class="threadline-ui"` / `id="tl-main"` duplication left behind).
  #
  # Parser-agnostic by design (RESEARCH Pitfall 2): we scan SOURCE (no DB, no
  # socket) and assert via substring + byte-offset ordering — never Floki/LazyHTML
  # tree traversal. NEVER uses document-body lifecycle selectors or the legacy
  # disconnected-class anchor (D-11) — those are forbidden anchors.
  @page_live_views ~w(
    actor_live.ex
    coverage_live.ex
    evidence_live.ex
    export_status_live.ex
    policy_redaction_live.ex
    retention_history_live.ex
    row_history_live.ex
    start_live.ex
    stress_live.ex
    timeline_live.ex
    transaction_live.ex
  )

  @ui_module "lib/threadline/operator_surface/ui.ex"

  describe "reconnect banner mounted once in shared shell (SEED-005 / D-10, D-11)" do
    test "the shared UI.shell mounts tl-reconnect-banner exactly once, above #tl-main inside .threadline-ui" do
      src = File.read!(@ui_module)

      assert src =~ "def shell(assigns)",
             "ui.ex must define the shared @doc false shell/1 chrome component (D-10)"

      banner_count =
        src
        |> String.split("reconnect_banner")
        |> length()
        |> Kernel.-(1)
        # def reconnect_banner + the single <.reconnect_banner /> mount in shell/1
        |> Kernel.-(1)

      assert banner_count == 1,
             "ui.ex shell must mount reconnect_banner EXACTLY once (D-10), found #{banner_count} mount references"

      shell_at = index_of!(src, ~s(class="threadline-ui"))
      banner_at = index_of!(src, "<.reconnect_banner")
      main_at = index_of!(src, ~s(id="tl-main"))

      assert shell_at < banner_at and banner_at < main_at,
             "the reconnect banner must sit AFTER the .threadline-ui open and BEFORE #tl-main (D-10/D-11)"
    end

    test "every operator page routes its chrome through the shared UI.shell (no per-page wrapper duplication)" do
      for file <- @page_live_views do
        src = File.read!(Path.join("lib/threadline/operator_surface/live", file))

        assert src =~ "UI.shell" or src =~ "<.shell",
               "#{file}: must render its chrome via the shared shell component (D-10), not a hand-rolled <div class=\"threadline-ui\"> wrapper"

        refute String.contains?(src, ~s(class="threadline-ui")),
               "#{file}: the `.threadline-ui` wrapper now lives in UI.shell — no per-page duplication (D-10)"

        refute String.contains?(src, ~s(id="tl-main")),
               "#{file}: the `#tl-main` element now lives in UI.shell — no per-page duplication (D-10)"
      end
    end

    test "neither the shell nor any page anchors reconnect on <body> or the legacy .phx-disconnected (D-11)" do
      for file <- [
            @ui_module
            | Enum.map(@page_live_views, &Path.join("lib/threadline/operator_surface/live", &1))
          ] do
        src = File.read!(file)

        refute String.contains?(src, ".phx-disconnected"),
               "#{file}: .phx-disconnected is a LiveView <1.0 class — connection state anchors on [data-phx-main] with .threadline-ui descendant scoping (D-11)"

        refute String.contains?(src, "body.phx-"),
               "#{file}: connection classes attach to [data-phx-main], never the document body (D-11)"
      end
    end
  end

  # --- Phase 178 (PAGE-02 #4, D-06): Esc + click-outside dismiss markers -------
  #
  # RED Wave-0 scaffold. Footgun #4 (Esc / click-outside dismiss). This is #4's OWN
  # structural detector, asserted INDEPENDENTLY of #3's focus-entry hooks
  # (JS.focus_first/phx-mounted) — the two are distinct halves, so 178-05's "#4 →
  # green" ratchets against a real failing detector and cannot piggyback on #3.
  #
  # Each overlay (modal, drawer) must carry BOTH:
  #   (a) an Escape-key dismiss binding (phx-key="escape" + phx-window-keydown) — present today, and
  #   (b) a CLICK-OUTSIDE/scrim dismiss marker: the SCRIM element itself carrying a
  #       phx-click dismiss. Today the scrim is inert (`aria-hidden="true"`, no
  #       phx-click) and dismissal rides phx-click-away on the CONTENT element — a
  #       different mechanism. A genuine click-outside affordance puts the dismiss on
  #       the scrim. RED today (scrim has no phx-click dismiss).
  describe "overlay Esc + click-outside dismiss markers (PAGE-02 #4, D-06)" do
    test "modal and drawer scrims carry a click-outside (phx-click) dismiss marker, independent of #3 focus hooks" do
      src = File.read!(@ui_source_path)

      for {component, scrim_class} <- [
            {"modal", "tl-modal-scrim"},
            {"drawer", "tl-drawer-scrim"}
          ] do
        # (a) Escape dismiss binding — present today (GREEN-confirming half of #4).
        assert Regex.match?(~r/def #{component}\(assigns\).*?phx-key="escape"/s, src),
               "#{component} must bind an Escape-key dismiss (phx-key=\"escape\")"

        # (b) Click-outside: the SCRIM element itself must carry a phx-click dismiss.
        # Extract the scrim element tag and require a phx-click on it. RED today —
        # the scrim is `aria-hidden="true"` with no phx-click; dismissal currently
        # rides phx-click-away on the content (a distinct mechanism, not a clickable
        # scrim). This is the binding #4 click-outside half Plan 05 turns green.
        scrim_tag =
          case Regex.run(~r/<div[^>]*class="#{scrim_class}"[^>]*\/?>/s, src) do
            [tag] -> tag
            _ -> flunk("#{component}: missing #{scrim_class} element")
          end

        assert String.contains?(scrim_tag, "phx-click"),
               "#{component} scrim (.#{scrim_class}) must carry a phx-click click-outside dismiss marker (PAGE-02 #4, RED today — the scrim is inert; phx-click-away on the content is the #3-adjacent mechanism, not #4's own clickable scrim)"
      end
    end
  end

  # --- Phase 178 (PAGE-02 #5/#7/#8/#9, D-06/D-07): footgun structural guards ---
  #
  # Permanent structural guards for the remaining footgun classes whose structural
  # half is Tier-A-assertable. These EXTEND the existing z-order/reconnect/pager
  # idioms (D-07, do not reinvent). Each becomes a permanent CI assertion; the ones
  # that already pass today are GREEN-confirming (documented in the SUMMARY), the
  # Tier B computed-style/real-engine halves live in operator-phase-178-uat.spec.ts.
  describe "footgun structural guards #5/#7/#8/#9 (PAGE-02, D-07)" do
    test "#8 nav active-state carries aria-current + a non-color cue (not color alone)" do
      src = File.read!(@style_path)

      active_block =
        case Regex.run(
               ~r/\.threadline-ui \.tl-shell-nav__item\[aria-current="page"\]\s*\{[^}]*\}/s,
               src
             ) do
          [block] -> block
          _ -> flunk("missing nav active-state selector keyed on aria-current=\"page\"")
        end

      # Non-color cue: a border/box-shadow shape change, never background color alone.
      assert String.contains?(active_block, "box-shadow:") or
               String.contains?(active_block, "border-color:"),
             "#8: active nav must carry a non-color cue (border/box-shadow), not background color alone (footgun #8)"
    end

    test "#9 pager disables at the edges and hides at zero matches (UI.pager contract)" do
      src = File.read!(@ui_source_path)

      pager_def =
        case Regex.run(~r/def pager\(assigns\) do.*?~H"""(.*?)"""/s, src) do
          [_, template] -> template
          _ -> flunk("missing UI.pager/1 definition")
        end

      # Disabled-at-edge: both controls bind disabled to the has_newer/has_older edge.
      assert String.contains?(pager_def, "disabled={!@has_newer}"),
             "#9: Newer control must disable at the newest-edge"

      assert String.contains?(pager_def, "disabled={!@has_older}"),
             "#9: Older control must disable at the oldest-edge"

      # Hide-at-zero: the pager nav is conditionally rendered when there are matches.
      assert String.contains?(pager_def, "is_nil(@match_count) or @match_count > 0"),
             "#9: the pager must hide entirely when match_count is 0 (no orphaned controls)"
    end

    test "#5/#7 disabled affordance: toolbar marks aria-disabled + is-disabled (not enabled-looking)" do
      assigns = %{}

      disabled =
        rendered_to_string(~H"""
        <UI.toolbar disabled={true}><span>filters</span></UI.toolbar>
        """)

      # #7 disabled-looks-enabled: the disabled toolbar must carry BOTH the real
      # aria-disabled state and the is-disabled affordance class (the paired CSS sets
      # pointer-events:none + dimming). #5 hover-on-non-interactive is covered by the
      # is-disabled pointer-events:none affordance + the Tier B cursor check.
      assert disabled =~ ~s(aria-disabled="true"),
             "#7: a disabled control must expose aria-disabled=\"true\" (not just look dimmed)"

      assert disabled =~ "is-disabled",
             "#7: a disabled control must carry the is-disabled affordance class (pointer-events:none + dimming)"
    end
  end

  # Byte offset of `needle` in `haystack`, used to assert DOM ordering
  # (e.g. the stale banner precedes the data region).
  defp index_of!(haystack, needle) do
    case :binary.match(haystack, needle) do
      {at, _len} -> at
      :nomatch -> flunk("expected to find #{inspect(needle)} in rendered HTML:\n#{haystack}")
    end
  end

  defp reconnect_css_block!(src) do
    start_at = index_of!(src, ".tl-reconnect-banner {")
    marker_at = index_of!(src, "Motion — purposeful")

    if start_at >= marker_at do
      flunk("could not isolate the active reconnect CSS block in style.ex")
    end

    binary_part(src, start_at, marker_at - start_at)
  end
end
