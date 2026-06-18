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
      assert html =~ "Nothing here yet"
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
      assert redacted =~ "withheld by policy"

      assert pruned =~ "tl-empty--unavailable"
      # archive glyph — the pruned-by-retention distinction
      assert pruned =~ "M3 7h18"
      assert pruned =~ "Removed under retention"
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
      assert html =~ "showing last known data"
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

    test "stylesheet reveals the banner + disables [data-tl-mutating] under phx-loading/phx-error" do
      src = File.read!(@style_path)

      # Hidden by default; revealed purely in CSS on the LiveView client classes.
      assert src =~ ".tl-reconnect-banner {"
      assert src =~ ".threadline-ui.phx-loading .tl-reconnect-banner,"
      assert src =~ ".threadline-ui.phx-error .tl-reconnect-banner {"
      assert src =~ "background: var(--tl-color-warning-bg);"

      # Mutating controls dim + go pointer-events:none while disconnected.
      assert src =~ ".threadline-ui.phx-loading [data-tl-mutating],"
      assert src =~ ".threadline-ui.phx-error [data-tl-mutating] {"
      assert src =~ "pointer-events: none;"
      assert src =~ "opacity: 0.55;"
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
end
