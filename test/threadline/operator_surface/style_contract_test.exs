defmodule Threadline.OperatorSurface.StyleContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @style_path "lib/threadline/operator_surface/style.ex"
  @motion_inventory_path ".planning/milestones/v1.31-phases/141-motion-micro-animation/141-MOTION-INVENTORY.md"

  test "operator surface is dark-primary with governed light and system token lanes" do
    src = File.read!(@style_path)

    assert String.contains?(src, "color-scheme: dark;")
    assert String.contains?(src, ~s|.threadline-ui[data-tl-theme="light"]|)
    assert String.contains?(src, ~s|.threadline-ui[data-tl-theme="system"]|)
    assert String.contains?(src, "@media (prefers-color-scheme: light)")
    assert String.contains?(src, "color-scheme: light;")
    assert String.contains?(src, "--tl-color-accent-inset: rgba(127, 169, 255, 0.16);")
    assert String.contains?(src, "--tl-color-accent-inset: rgba(21, 87, 192, 0.16);")

    assert String.contains?(
             src,
             "box-shadow: inset 0 0 0 1px var(--tl-color-accent-inset);"
           )

    refute String.contains?(
             src,
             "box-shadow: inset 0 0 0 1px rgba(127, 169, 255, 0.16);"
           )
  end

  test "operator shell is CSP-proof: native [open] nav + pure-CSS picker cue + hardened scroll (NAV-03/NAV-04)" do
    src = File.read!(@style_path)

    # Mobile nav reveals its panel on the native <details> [open] attribute,
    # never on a JS-toggled checkbox/.--open class.
    assert String.contains?(src, ".tl-shell-nav[open]"),
           "mobile nav must key off the native <details> [open] attribute"

    refute String.contains?(src, ".tl-shell-nav__control:checked"),
           "the JS-driven hidden-checkbox nav toggle must be gone (CSP-proof shell)"

    refute String.contains?(src, "tl-shell-nav--open"),
           "the JS-toggled .--open class must be gone (CSP-proof shell)"

    # The selected theme radio gets a pure-CSS non-color cue via :has(:checked).
    assert String.contains?(src, ":has(:checked)"),
           "theme picker active cue must be driven by :has(:checked), not a markup --active class"

    refute String.contains?(src, "tl-segmented__item--active"),
           "the dead tl-segmented__item--active rule/markup hook must be gone"

    # Sticky/scroll hardening: anchored content is never covered, no nested-scroll trap.
    assert String.contains?(src, "scroll-padding-top"),
           "scroll container must reserve the sticky-header offset (no covered anchors)"

    assert String.contains?(src, "overscroll-behavior: contain") or
             String.contains?(src, "overscroll-behavior:contain"),
           "scrollable panel/rail must contain overscroll (no scroll-chain trap)"

    assert String.contains?(src, "100svh"),
           "shell must use the small viewport unit (mobile browser chrome safe)"
  end

  test "A11Y-02 target-size and selected-state cues stay mapped to actual rendered selectors" do
    src = File.read!(@style_path)

    assert String.contains?(src, "--tl-hit-area: 40px;")
    assert String.contains?(src, "--tl-control-height-compact: 32px;")

    assert_exact_selector_contains(src, ".tl-button", ["min-height: var(--tl-hit-area);"])

    assert_exact_selector_contains(src, ".tl-button--compact", [
      "min-height: var(--tl-control-height-compact);"
    ])

    assert_exact_selector_contains(src, ".tl-button--icon", ["width: var(--tl-hit-area);"])

    assert_exact_selector_contains(src, ".tl-shell-nav__toggle", [
      "min-height: var(--tl-hit-area);"
    ])

    assert_exact_selector_contains(src, ".threadline-ui .tl-shell-nav__item", [
      "min-height: var(--tl-hit-area);"
    ])

    assert_exact_selector_contains(src, ".tl-theme-picker__option", [
      "min-height: var(--tl-hit-area);"
    ])

    assert_selector_contains(src, ".tl-tab", ["min-height: var(--tl-control-height-compact);"])

    assert_selector_contains(src, ~s(.tl-tab[aria-selected="true"]), [
      "box-shadow:",
      "font-weight: var(--tl-weight-strong);"
    ])

    assert_selector_contains(src, ".tl-segment", ["min-height: var(--tl-control-height-compact);"])

    assert_selector_contains(src, ~s(.tl-segment[aria-pressed="true"]), [
      "box-shadow:",
      "font-weight: var(--tl-weight-strong);"
    ])

    refute String.contains?(src, ".tl-segmented__item"),
           "segmented-control hit-area and selected-state CSS must target UI.segmented_control/1's actual .tl-segment markup"
  end

  test "dark interaction tokens cover readable hover and focus states" do
    src = File.read!(@style_path)

    assert String.contains?(src, "--tl-color-surface-hover:")
    assert String.contains?(src, "--tl-color-surface-selected:")
    assert String.contains?(src, "--tl-color-border-focus:")
    assert String.contains?(src, "--tl-focus-ring:")
    assert String.contains?(src, ".tl-toolbar__control:hover:not(:disabled)")
    assert String.contains?(src, ".tl-button:disabled")
  end

  test "dark semantic status tokens include visible borders" do
    src = File.read!(@style_path)

    assert String.contains?(src, "--tl-color-danger-border:")
    assert String.contains?(src, "--tl-color-warning-border:")
    assert String.contains?(src, "--tl-color-success-border:")
    assert String.contains?(src, "--tl-color-info-border:")
    assert String.contains?(src, ".tl-alert--error")
    assert String.contains?(src, ".tl-chip--danger")
  end

  test "prove cluster primitives stay token-backed and reusable" do
    src = File.read!(@style_path)

    assert String.contains?(src, ".tl-job-group")
    assert String.contains?(src, ".tl-job-group__header")
    assert String.contains?(src, ".tl-secondary-ref")

    # DATA-01 / D-05: the CSS double-truncation is removed. Server middle-truncation
    # is the ONLY truncator; the .tl-secondary-ref rule must NOT re-introduce
    # text-overflow: ellipsis (a latent tail-clipper at 320px) and MUST wrap via
    # overflow-wrap: anywhere so the preserved tail is always reachable on mobile.
    # This assertion LOCKS the deletion against silent regression.
    refute Regex.match?(
             selector_block_pattern(".tl-secondary-ref", ~r/text-overflow:\s*ellipsis;/),
             src
           ),
           ".tl-secondary-ref must NOT re-introduce text-overflow: ellipsis (D-05 double-truncation)"

    assert Regex.match?(
             selector_block_pattern(".tl-secondary-ref", ~r/overflow-wrap:\s*anywhere;/),
             src
           ),
           ".tl-secondary-ref must keep overflow-wrap: anywhere so the truncated tail wraps (never clips)"

    assert String.contains?(src, ".tl-target-row")
    assert String.contains?(src, ".tl-target-row:target")
    assert String.contains?(src, "scroll-margin-top: calc(var(--tl-header-height-mobile)")
    assert String.contains?(src, "font-family: var(--tl-font-mono)")
    assert String.contains?(src, "background: var(--tl-color-surface-raised)")
    assert String.contains?(src, "border-color: var(--tl-color-border)")
  end

  test "phase 138 find primitives stay token-backed" do
    src = File.read!(@style_path)

    for class <- [
          ".tl-value",
          ".tl-value--null",
          ".tl-value--time",
          ".tl-value--redacted",
          ".tl-value--omitted",
          ".tl-value--absent",
          ".tl-diff",
          ".tl-diff__arrow",
          ".tl-filter-summary",
          ".tl-journey--legend",
          ".tl-actor-summary",
          ".tl-remediation__command",
          ".tl-remediation__action",
          ".tl-coverage-actions",
          ".tl-row-action",
          ".tl-row-action__summary",
          ".tl-command-copy",
          ".tl-short-content"
        ] do
      assert String.contains?(src, class)
    end

    find_section =
      src
      |> String.split("/* Find cluster primitives")
      |> List.last()
      |> String.split("/* End Find cluster primitives */")
      |> List.first()

    assert String.contains?(find_section, "var(--tl-")
    refute String.contains?(find_section, "@tailwind")
    refute String.contains?(find_section, "from shadcn")
    refute Regex.match?(~r/#[0-9a-fA-F]{6}/, find_section)
    assert String.contains?(src, ".tl-copy:hover")
  end

  test "phase 139 shell navigation primitives stay mobile-reachable and token-backed" do
    src = File.read!(@style_path)

    topbar_section =
      src
      |> String.split(".tl-topbar {")
      |> Enum.at(1)
      |> String.split("/* Mobile-first base:")
      |> List.first()

    for selector <- [
          ".tl-topbar__brand-logo",
          ".tl-topbar__brand-wordmark",
          ".tl-shell-nav",
          ".tl-shell-nav__toggle",
          ".tl-shell-nav__panel",
          ".tl-shell-nav__overview",
          ".tl-shell-nav__group",
          ".tl-shell-nav__label",
          ~s|.threadline-ui .tl-shell-nav__item[aria-current="page"]|
        ] do
      assert String.contains?(topbar_section, selector)
    end

    assert String.contains?(topbar_section, "var(--tl-")
    refute String.contains?(topbar_section, "@tailwind")
    refute String.contains?(topbar_section, "from shadcn")
    refute Regex.match?(~r/#[0-9a-fA-F]{6}/, topbar_section)
    refute String.contains?(topbar_section, ".tl-topbar__nav-label")
    assert String.contains?(topbar_section, "var(--tl-color-accent-inset)")

    assert_selector_contains(topbar_section, ".tl-topbar__brand", [
      "display: inline-flex;",
      "flex: 0 0 auto;",
      "min-height: var(--tl-brand-logo-height);",
      "white-space: nowrap;"
    ])

    assert_selector_contains(topbar_section, ".tl-topbar__brand-logo", [
      "width: var(--tl-brand-logo-width);",
      "height: var(--tl-brand-logo-height);",
      "flex: 0 0 var(--tl-brand-logo-width);"
    ])

    assert_selector_contains(topbar_section, ".tl-topbar__brand-wordmark", [
      "font-family: var(--tl-font-family);",
      "font-weight: var(--tl-weight-strong);"
    ])
  end

  test "phase 139 home orientation primitives stay scoped token-backed" do
    src = File.read!(@style_path)

    home_section =
      src
      |> String.split("/* Operator Home")
      |> Enum.at(1)
      |> String.split(".tl-page__header")
      |> List.first()

    for selector <- [
          ".tl-home__health",
          ".tl-home__resume",
          ".tl-home__resume-empty",
          ".tl-home__card-links",
          ".tl-home__prove-handoff"
        ] do
      assert String.contains?(home_section, selector)
    end

    assert String.contains?(home_section, "var(--tl-")
    refute String.contains?(home_section, "@tailwind")
    refute String.contains?(home_section, "from shadcn")
    refute Regex.match?(~r/#[0-9a-fA-F]{6}/, home_section)
  end

  test "phase 140 home earned-flow controls stay scoped token-backed" do
    src = File.read!(@style_path)

    home_section =
      src
      |> String.split("/* Operator Home")
      |> Enum.at(1)
      |> String.split(".tl-page__header")
      |> List.first()

    for selector <- [
          ".tl-home__earned-flow",
          ".tl-home__earned-panel",
          ".tl-home__earned-copy",
          ".tl-home__earned-form",
          ".tl-home__earned-panel .tl-alert"
        ] do
      assert String.contains?(home_section, selector)
    end

    assert String.contains?(home_section, "var(--tl-")
    refute String.contains?(home_section, "@tailwind")
    refute String.contains?(home_section, "from shadcn")
    refute Regex.match?(~r/#[0-9a-fA-F]{6}/, home_section)
  end

  test "phase 141 motion inventory is source-testable and rationale-backed" do
    inventory = File.read!(@motion_inventory_path)

    for required <- [
          "selector_or_keyframe",
          "persona_jtbd",
          "reduced_motion",
          "prefers-reduced-motion",
          "tl-thread-draw"
        ] do
      assert String.contains?(inventory, required)
    end

    rows = motion_inventory_rows(inventory)
    assert length(rows) >= 19

    for row <- rows do
      for field <- [
            :id,
            :selector_or_keyframe,
            :trigger,
            :persona_jtbd,
            :rationale,
            :token,
            :reduced_motion
          ] do
        value = Map.fetch!(row, field)
        assert value != "", "motion inventory #{row.id} has empty #{field}"
        refute Regex.match?(~r/\bTBD\b/i, value), "motion inventory #{row.id} has TBD in #{field}"
      end
    end
  end

  test "phase 141 motion tokens and keyframes stay locked" do
    src = File.read!(@style_path)

    for token <- [
          "--tl-motion-fast: 120ms;",
          "--tl-motion-base: 180ms;",
          "--tl-motion-slow: 240ms;",
          "--tl-motion-stagger: 40ms;",
          "--tl-motion-distance-sm: 8px;",
          "--tl-motion-distance-md: 16px;",
          "--tl-ease-standard: cubic-bezier(0.2, 0, 0, 1);",
          "--tl-ease-out: cubic-bezier(0.16, 1, 0.3, 1);",
          "--tl-transition-fast: var(--tl-motion-fast) var(--tl-ease-standard);"
        ] do
      assert String.contains?(src, token), "missing locked motion token #{token}"
    end

    keyframes =
      Regex.scan(~r/@keyframes\s+([a-z0-9-]+)/, src, capture: :all_but_first)
      |> List.flatten()
      |> Enum.sort()

    assert keyframes ==
             Enum.sort(~w(tl-drawer-in tl-rise-in tl-thread-draw tl-fade-in tl-copy-pulse))
  end

  test "phase 141 animation consumers are inventoried and token-backed" do
    src = File.read!(@style_path)
    inventory = File.read!(@motion_inventory_path)

    for {selector, keyframe} <- [
          {".tl-home__card", "tl-rise-in"},
          {".tl-home__card--primary::before", "tl-thread-draw"},
          {".tl-subview", "tl-drawer-in"},
          {"#retention-runs > tr", "tl-rise-in"},
          {".tl-subview__timeline > *", "tl-rise-in"},
          {".tl-record-list > .tl-record-card", "tl-fade-in"},
          {"#transactions-list > .tl-change", "tl-fade-in"},
          {".tl-copy.is-copied", "tl-copy-pulse"},
          {".tl-journey-rail::before", "tl-thread-draw"},
          {".tl-policy__success::after", "tl-thread-draw"}
        ] do
      assert String.contains?(inventory, selector), "motion inventory is missing #{selector}"
      assert String.contains?(inventory, keyframe), "motion inventory is missing #{keyframe}"
      assert_selector_uses_animation(src, selector, keyframe)
    end

    for selector <- [
          ".tl-home__card--primary::before",
          ".tl-journey-rail::before",
          ".tl-policy__success::after"
        ] do
      row = motion_inventory_row!(inventory, selector)

      assert Regex.match?(~r/signature|proof|progression/i, row.rationale),
             "#{selector} must justify tl-thread-draw as signature/proof/progression motion"
    end
  end

  test "phase 141 transition families are inventoried and token-backed" do
    src = File.read!(@style_path)
    inventory = File.read!(@motion_inventory_path)

    for selector <- [
          ".threadline-ui a",
          ".threadline-ui .tl-shell-nav__item",
          ".tl-toolbar__control",
          ".tl-control",
          ".tl-button",
          ".tl-change",
          ".tl-policy__summary",
          ".tl-policy__row::details-content",
          ".tl-copy",
          ".tl-policy__summary::before"
        ] do
      assert String.contains?(inventory, selector),
             "motion inventory is missing transition #{selector}"

      assert_selector_uses_tokenized_transition(src, selector)
    end
  end

  test "phase 141 rejects ad-hoc motion and ungoverned duration drift" do
    src = File.read!(@style_path)

    refute Regex.match?(~r/transition:\s*all\b/, src)

    for marker <- ["animejs", "framer-motion", "gsap", "motion.dev", "lottie"] do
      refute String.contains?(String.downcase(src), marker)
    end

    for [keyframe] <- Regex.scan(~r/animation:\s*(tl-[a-z0-9-]+)/, src, capture: :all_but_first) do
      assert keyframe in ~w(tl-drawer-in tl-rise-in tl-thread-draw tl-fade-in tl-copy-pulse),
             "unapproved animation keyframe #{keyframe}"
    end

    for line <- String.split(src, "\n"), Regex.match?(~r/\b\d+ms\b/, line) do
      assert allowed_motion_duration_line?(line),
             "literal motion duration is not governed: #{line}"
    end
  end

  test "phase 141 reduced-motion blanket covers animations, transitions, and transform reset" do
    src = File.read!(@style_path)

    reduced_motion =
      src
      |> String.split("@media (prefers-reduced-motion: reduce) {")
      |> Enum.at(1)
      |> String.split("</style>")
      |> List.first()

    for required <- [
          ".threadline-ui *",
          ".threadline-ui *::before",
          ".threadline-ui *::after",
          ".tl-policy__row::details-content",
          "transition-duration: 1ms !important;",
          "animation-duration: 1ms !important;",
          "animation-delay: 0ms !important;",
          "animation-iteration-count: 1 !important;",
          "scroll-behavior: auto !important;",
          ".tl-button:active",
          ".tl-fade-in",
          ".tl-rise-in",
          ".tl-slide-in-right",
          ".translate-y-4",
          ".translate-x-full",
          ".tl-toast",
          ".tl-subview",
          "animation: none !important;",
          "transform: none;"
        ] do
      assert String.contains?(reduced_motion, required),
             "reduced-motion block missing #{required}"
    end
  end

  test "MOTION-01 press feedback is enabled-only and disabled controls remain still" do
    src = File.read!(@style_path)

    refute Regex.match?(
             ~r/\.tl-button:active\s*\{[^}]*transform:\s*scale\(0\.96\);/s,
             src
           ),
           "button press feedback must not be attached to the unqualified active selector"

    assert_selector_contains(
      src,
      ~S|.tl-button:active:not(:disabled):not([disabled]):not([aria-disabled="true"])|,
      ["transform: scale(0.96);"]
    )

    assert Regex.match?(
             ~r/\.tl-button:disabled,\s*\.tl-button\[disabled\],\s*\.tl-button\[aria-disabled="true"\]\s*\{[^}]*cursor:\s*not-allowed;[^}]*box-shadow:\s*none;[^}]*transform:\s*none;/s,
             src
           ),
           "disabled and aria-disabled button controls must share the still/disabled block"
  end

  test "MOTION-01 rejects unsafe zero-scale and layout-affecting motion transitions" do
    src = File.read!(@style_path)

    refute Regex.match?(~r/transform:\s*scale\(\s*0(?:\.0+)?\s*\)/, src),
           "surface motion must not collapse elements with transform: scale(0)"

    refute Regex.match?(~r/transform:\s*scale3d\(\s*0(?:\.0+)?\s*,/i, src),
           "surface motion must not collapse elements with transform: scale3d(0, ...)"

    for [_, declaration, properties] <-
          Regex.scan(~r/((?:transition|transition-property):\s*([^;]+);)/, src) do
      refute Regex.match?(
               ~r/\b(block-size|inline-size|content-visibility|width|height|left|right|top|bottom|margin|padding|gap|grid-template)\b/,
               properties
             ),
             "layout-affecting motion is forbidden in #{String.trim(declaration)}"
    end
  end

  test "MOTION-01 keeps high-frequency timeline and table streams free of entrance animations" do
    src = File.read!(@style_path)
    timeline_row = selector_block!(src, ".tl-change")

    refute String.contains?(timeline_row, "animation:"),
           "the high-frequency timeline row primitive must not animate on stream updates"

    for forbidden_pattern <- [
          ~r/#timeline-rows\s*>\s*\.tl-change[^}]*animation\s*:/s,
          ~r/#changes-list\s*>\s*\.tl-change[^}]*animation\s*:/s,
          ~r/\.tl-change-list\s*>\s*\.tl-change[^}]*animation\s*:/s,
          ~r/\.tl-table--actionable\s+tbody\s+tr[^}]*animation\s*:/s
        ] do
      refute Regex.match?(forbidden_pattern, src),
             "high-frequency row/list/table selectors must stay still"
    end
  end

  test "phase 142 breakpoint scale is tokenized and source-governed" do
    src = File.read!(@style_path)

    for token <- [
          "--tl-breakpoint-phone-proof: 375px;",
          "--tl-breakpoint-tablet: 768px;",
          "--tl-breakpoint-desktop: 1280px;"
        ] do
      assert String.contains?(src, token), "missing phase 142 breakpoint token #{token}"
    end

    for comment <- [
          "Phase 142 breakpoint tokens document the accepted phone/tablet/desktop scale",
          "CSS custom properties are not valid inside @media conditions",
          "Phone-proof base: 375px acceptance viewport",
          "Tablet enhancement layer starts at 768px",
          "Desktop dense/operator layer starts at 1280px"
        ] do
      assert String.contains?(src, comment), "missing phase 142 breakpoint comment #{comment}"
    end

    min_width_literals =
      Regex.scan(~r/@media\s+\(min-width:\s*(\d+)px\)/, src, capture: :all_but_first)
      |> List.flatten()
      |> Enum.sort()

    assert min_width_literals == ["1280", "768"],
           "phase 142 allows only 768px and 1280px min-width media literals"

    refute String.contains?(src, "@media (min-width: 481px)"),
           "phase 142 retires the old 481px tablet media layer"

    refute String.contains?(src, "@media (min-width: 721px)"),
           "phase 142 retires the old 721px desktop media layer"

    refute Regex.match?(~r/@media[^{]*var\(--tl-breakpoint/, src),
           "phase 142 breakpoint tokens must not be used inside @media conditions"
  end

  test "phase 142 responsive primitives keep mobile-first source contracts" do
    src = File.read!(@style_path)
    base = base_responsive_section(src)

    assert_selector_contains(base, ".tl-shell-nav__panel", [
      "display: none;",
      "border-top: 1px solid var(--tl-color-border);"
    ])

    assert_selector_contains(
      base,
      ".tl-shell-nav[open] .tl-shell-nav__panel",
      ["display: grid;"]
    )

    assert_selector_contains(base, ".tl-shell-nav__toggle", [
      "min-height: var(--tl-hit-area);",
      "cursor: pointer;"
    ])

    assert_selector_contains(base, ".tl-shell-nav__overview", [
      "display: grid;",
      "padding-bottom: var(--tl-space-2);",
      "border-bottom: 1px solid var(--tl-color-border);"
    ])

    assert_selector_contains(base, ".tl-toolbar__form", [
      "display: grid;",
      "gap: var(--tl-space-3);"
    ])

    assert_selector_contains(base, ".tl-filter-grid", [
      "display: grid;",
      "grid-template-columns: 1fr;",
      "align-items: start;"
    ])

    assert_selector_contains(base, ".tl-filter-disclosure", [
      "display: grid;",
      "border-top: 1px solid var(--tl-color-border);"
    ])

    assert_selector_contains(base, "#tl-main > .tl-trust-rail", [
      "margin-bottom: var(--tl-space-4);"
    ])

    # DATA-05 / D-12: the synthetic `tl-coverage-command` command-shell is flattened
    # away — the coverage success branch now uses UI.page_header with its children
    # (trust-rail, tl-summary-grid metric tiles, remediation, table) as direct
    # page-stack siblings. The dead `tl-coverage-command__*` CSS must be GONE so it
    # can't silently regress (paired-deletion contract). The metric-grid keeps its
    # generic `.tl-summary-grid` spacing.
    refute String.contains?(src, "tl-coverage-command"),
           ".tl-coverage-command* CSS must be deleted (D-12 flatten); the command shell is retired"

    assert_selector_contains(base, ".tl-summary-grid", [
      "margin-bottom: var(--tl-space-4);"
    ])

    assert_selector_contains(base, ".tl-table--coverage .tl-table__actions", [
      "white-space: normal;"
    ])

    assert_selector_contains(base, ".tl-row-action__summary", [
      "min-height: var(--tl-hit-area);",
      "cursor: pointer;"
    ])

    assert_selector_contains(base, ".tl-command-copy", [
      "grid-template-columns: minmax(0, 1fr) auto;",
      "min-width: 0;"
    ])

    assert_selector_contains(base, ".tl-table-wrap .tl-table--responsive", ["min-width: 0;"])
    assert_selector_contains(base, ".tl-table--responsive thead", ["display: none;"])
    assert_selector_contains(base, ".tl-page", ["padding: var(--tl-space-2);"])

    assert_selector_contains(base, ".tl-table--responsive td::before", [
      "content: attr(data-label);"
    ])

    assert_selector_contains(base, ".tl-subview", [
      "width: 100vw;",
      "min-height: 100dvh;",
      "overflow: auto;"
    ])

    for selector <- [
          ".tl-secondary-ref",
          ".tl-value",
          ".tl-param",
          ".tl-record-card__ref",
          ".tl-kv__row"
        ] do
      assert Regex.match?(
               selector_block_pattern(selector, ~r/min-width:\s*0;|overflow-wrap:\s*anywhere;/),
               base
             ),
             "#{selector} must keep min-width: 0 or overflow-wrap: anywhere in the mobile/base layer"
    end

    refute Regex.match?(~r/(?:body|html|\.threadline-ui)\s*\{[^}]*overflow-x:\s*hidden;/s, src),
           "root/body overflow-x hidden masks responsive bugs instead of fixing components"
  end

  test "phase 142 responsive primitives keep tablet wrapping and desktop table restoration" do
    src = File.read!(@style_path)
    tablet = media_section(src, "768px")
    desktop = media_section(src, "1280px")

    assert_selector_contains(tablet, ".tl-page", ["padding: var(--tl-space-3);"])
    assert_selector_contains(desktop, ".tl-page", ["padding: var(--tl-space-4);"])

    assert_selector_contains(tablet, ".tl-timeline-command__facts", [
      "grid-template-columns: repeat(3, minmax(0, 1fr));"
    ])

    assert_selector_contains(tablet, ".tl-filter-grid--primary", [
      "grid-template-columns: repeat(2, minmax(0, 1fr));"
    ])

    assert_selector_contains(tablet, ".tl-filter-grid--advanced", [
      "grid-template-columns: repeat(3, minmax(0, 1fr));"
    ])

    assert_selector_contains(tablet, ".threadline-ui .tl-shell-nav__item", [
      "min-height: var(--tl-control-height-compact);"
    ])

    assert_selector_contains(desktop, ".tl-topbar__brand-logo", [
      "width: var(--tl-brand-logo-width-desktop);",
      "height: var(--tl-brand-logo-height-desktop);",
      "flex-basis: var(--tl-brand-logo-width-desktop);"
    ])

    assert_selector_contains(desktop, ".tl-filter-grid--primary", [
      "grid-template-columns: minmax(178px, .8fr) minmax(178px, .8fr) minmax(180px, 1fr) minmax(240px, 1.3fr);"
    ])

    assert_selector_contains(desktop, ".tl-toolbar.tl-timeline-command", [
      "position: static;",
      "padding: var(--tl-space-3);"
    ])

    assert_selector_contains(desktop, ".tl-timeline-command__summary", [
      "grid-template-columns: minmax(240px, .85fr) minmax(0, 1.15fr);",
      "align-items: center;"
    ])

    assert_selector_contains(desktop, ".tl-toolbar__actions", [
      "grid-column: 1 / -1;",
      "justify-content: flex-end;"
    ])

    assert_selector_contains(desktop, ".tl-timeline-command__utilities", [
      "grid-template-columns: repeat(2, minmax(0, 1fr));"
    ])

    refute String.contains?(tablet, ".tl-table--responsive thead"),
           "tablet layer must keep responsive tables in labelled card mode"

    assert_selector_contains(desktop, ".tl-subview", [
      "width: min(var(--tl-drawer-width), 100vw);"
    ])

    assert_selector_contains(desktop, ".tl-table-wrap .tl-table--responsive", [
      "min-width: var(--tl-table-min-width);"
    ])

    assert_selector_contains(desktop, ".tl-table--responsive thead", [
      "display: table-header-group;"
    ])

    assert_selector_contains(desktop, ".tl-table--coverage", [
      "table-layout: fixed;"
    ])

    assert_selector_contains(desktop, ".tl-table--coverage td:nth-child(1)", [
      "width: 22%;"
    ])

    assert_selector_contains(desktop, ".tl-table--coverage td:nth-child(4)", [
      "width: 48%;"
    ])

    assert_selector_contains(desktop, ".tl-table--responsive tr", [
      "display: table-row;"
    ])

    assert_selector_contains(desktop, ".tl-table--responsive td", [
      "display: table-cell;"
    ])

    assert_selector_contains(desktop, ".tl-table--responsive td::before", [
      "display: none;"
    ])
  end

  test "operator typography defaults stay readable and dense text is opt-in" do
    src = File.read!(@style_path)

    for token <- [
          "--tl-font-size-xs: 12px;",
          "--tl-font-size-sm: 13px;",
          "--tl-font-size-dense: 13px;",
          "--tl-font-size-body: 16px;",
          "--tl-font-size-label: 14px;",
          "--tl-font-size-ui: 15px;",
          "--tl-font-size-heading: 20px;",
          "--tl-font-size-title: 24px;",
          "--tl-font-size-display: 32px;"
        ] do
      assert String.contains?(src, token), "missing readable typography token #{token}"
    end

    assert String.contains?(src, "--tl-pad-page: var(--tl-space-4);")

    refute String.contains?(src, "--tl-pad-page: var(--tl-space-6);"),
           "page padding token must not imply a 24px body-like gutter"

    assert_exact_selector_contains(src, ".threadline-ui", ["font-size: var(--tl-font-size-body);"])

    assert_exact_selector_contains(src, ".tl-button", ["font-size: var(--tl-font-size-label);"])
    assert_exact_selector_contains(src, ".tl-chip", ["font-size: var(--tl-font-size-label);"])

    assert_exact_selector_contains(src, ".tl-toolbar__field", [
      "font-size: var(--tl-font-size-label);"
    ])

    assert_exact_selector_contains(src, ".tl-value", ["font-size: var(--tl-font-size-label);"])

    assert_selector_contains(src, ".tl-table--compact th,\n        .tl-table--compact td", [
      "font-size: var(--tl-font-size-dense);"
    ])

    assert_selector_contains(
      src,
      ".tl-table--compact .tl-table__code,\n        .tl-table--compact code",
      [
        "font-size: var(--tl-font-size-dense);"
      ]
    )
  end

  test "phase 143 accessibility tokens meet dark-surface contrast baseline" do
    src = File.read!(@style_path)

    tokens =
      src
      |> selector_block!(".threadline-ui")
      |> color_tokens()

    backgrounds = [
      "--tl-color-bg",
      "--tl-color-surface",
      "--tl-color-surface-raised",
      "--tl-color-surface-hover"
    ]

    for text_token <- [
          "--tl-color-text",
          "--tl-color-muted",
          "--tl-color-muted-soft",
          "--tl-color-info-text",
          "--tl-color-warning-text",
          "--tl-color-success-text",
          "--tl-color-danger",
          "--tl-color-accent-strong"
        ],
        background_token <- backgrounds do
      assert contrast_ratio(tokens[text_token], tokens[background_token]) >= 4.5,
             "#{text_token} must meet AA contrast on #{background_token}"
    end

    assert contrast_ratio(tokens["--tl-color-accent"], tokens["--tl-color-surface-raised"]) >=
             4.5,
           "base accent links must meet AA contrast on raised surfaces"
  end

  test "phase 168 alpha-aware color_tokens parses rgba and opaque hex" do
    src = """
    .threadline-ui[data-tl-theme="light"] {
      --tl-color-danger: #A33434;
      --tl-color-danger-bg: rgba(163, 52, 52, 0.10);
      --tl-color-accent-soft: rgba(21, 87, 192, 0.12);
    }
    """

    tokens = color_tokens(src)

    # Opaque hex passes through unchanged (straight into contrast_ratio/2).
    assert tokens["--tl-color-danger"] == "#A33434"

    # rgba(...) tokens are no longer silently dropped — they parse to {r,g,b,a}.
    assert tokens["--tl-color-danger-bg"] == {163, 52, 52, 0.10}
    assert tokens["--tl-color-accent-soft"] == {21, 87, 192, 0.12}
  end

  test "phase 168 composite blends translucent tokens over a per-mode opaque base" do
    # round(src*a + base*(1-a)) per channel, returning a "#RRGGBB" feedable to
    # relative_luminance/1 without change.
    danger_bg = {163, 52, 52, 0.10}

    over_white = composite(danger_bg, "#FFFFFF")
    over_dark = composite(danger_bg, "#141B2D")

    # 7-char opaque hex out.
    assert String.match?(over_white, ~r/^#[0-9A-Fa-f]{6}$/)
    assert String.match?(over_dark, ~r/^#[0-9A-Fa-f]{6}$/)

    # round(163*0.1 + 255*0.9) = round(245.8) = 246 = F6, etc.
    assert String.upcase(over_white) == "#F6EBEB"

    # The base is caller-named per mode: different base => different result.
    refute over_white == over_dark

    # An opaque hex passed through the composite path is unchanged (no double-composite).
    assert composite("#A33434", "#FFFFFF") == "#A33434"

    # Composite output feeds the existing WCAG pipeline verbatim.
    assert contrast_ratio("#A33434", over_white) >= 4.5
  end

  test "phase 168 light and system lanes meet AA contrast incl. composited tints" do
    src = File.read!(@style_path)

    light = src |> selector_block!(~s|.threadline-ui[data-tl-theme="light"]|) |> color_tokens()
    system = src |> system_lane_block!() |> color_tokens()

    # Both maps are non-empty and byte-identical in token values today.
    assert map_size(light) > 0
    assert map_size(system) > 0
    assert light["--tl-color-surface"] == "#FFFFFF"
    assert system["--tl-color-surface"] == "#FFFFFF"

    backgrounds = [
      "--tl-color-bg",
      "--tl-color-surface",
      "--tl-color-surface-raised",
      "--tl-color-surface-hover"
    ]

    # Per-mode plain-surface AA rows (text token over each chrome layer it paints on).
    plain_rows = [
      {"--tl-color-text", backgrounds},
      {"--tl-color-muted", backgrounds},
      {"--tl-color-info-text", ["--tl-color-surface", "--tl-color-surface-raised"]},
      {"--tl-color-warning-text", ["--tl-color-surface", "--tl-color-surface-raised"]},
      {"--tl-color-success-text", ["--tl-color-surface", "--tl-color-surface-raised"]},
      {"--tl-color-danger", ["--tl-color-surface", "--tl-color-surface-raised"]},
      {"--tl-color-accent-strong",
       ["--tl-color-surface", "--tl-color-surface-raised", "--tl-color-surface-hover"]},
      {"--tl-color-accent", ["--tl-color-surface-raised"]}
    ]

    # Composited status-text-on-its-own-tint rows — the rows the hex-only parser
    # could not see. *-bg status tints composite over surface (#FFFFFF); accent-soft
    # composites over surface-raised (#EEF3FA). The base is named per mode.
    composited_rows = fn map ->
      [
        {"--tl-color-info-text", composite(map["--tl-color-info-bg"], map["--tl-color-surface"]),
         "info-text on info-bg composited over surface"},
        {"--tl-color-warning-text",
         composite(map["--tl-color-warning-bg"], map["--tl-color-surface"]),
         "warning-text on warning-bg composited over surface"},
        {"--tl-color-success-text",
         composite(map["--tl-color-success-bg"], map["--tl-color-surface"]),
         "success-text on success-bg composited over surface"},
        {"--tl-color-danger", composite(map["--tl-color-danger-bg"], map["--tl-color-surface"]),
         "danger on danger-bg composited over surface"},
        {"--tl-color-accent",
         composite(map["--tl-color-accent-soft"], map["--tl-color-surface-raised"]),
         "accent on accent-soft composited over surface-raised"}
      ]
    end

    for {mode, map} <- [{"light", light}, {"system", system}] do
      for {text_token, bg_tokens} <- plain_rows, bg_token <- bg_tokens do
        assert contrast_ratio(map[text_token], map[bg_token]) >= 4.5,
               "#{mode}: #{text_token} must meet AA 4.5:1 on #{bg_token}"
      end

      for {text_token, bg_hex, label} <- composited_rows.(map) do
        assert contrast_ratio(map[text_token], bg_hex) >= 4.5,
               "#{mode}: #{label} must meet AA 4.5:1 (composited bg=#{bg_hex})"
      end

      # D-04 — disabled-text (muted-soft) contrast.
      #
      # WCAG 2.1 SC 1.4.3 exempts INACTIVE (disabled) controls from the 4.5:1
      # minimum. Threadline holds disabled text legible-by-default, so we still
      # MEASURE muted-soft on surface and surface-raised, but no uniform lane-root
      # darkening reaches 4.5:1 on surface-raised (#EEF3FA) without collapsing the
      # disabled/active read: the value needed (~#636F85) is perceptually adjacent
      # to --tl-color-muted (#3B4762, the ACTIVE secondary text), which would break
      # the "disabled looks disabled" affordance. Per D-04 the disabled rows ONLY
      # are downgraded to "exempt — documented" at a non-text legibility floor
      # (>= 3.0), citing WCAG 1.4.3 inactive controls. No other contrast row is
      # exemptable, and no token value is changed (muted-soft stays #73819C).
      for bg_token <- ["--tl-color-surface", "--tl-color-surface-raised"] do
        assert contrast_ratio(map["--tl-color-muted-soft"], map[bg_token]) >= 3.0,
               "#{mode}: muted-soft (disabled, WCAG 1.4.3 exempt) must stay legible on #{bg_token}"
      end
    end
  end

  test "phase 143 focus-visible and non-color status contracts stay locked" do
    src = File.read!(@style_path)

    assert String.contains?(src, "--tl-focus-ring:")

    for selector <- [
          ".threadline-ui button:focus-visible",
          ".threadline-ui [role=\"button\"]:focus-visible",
          ".threadline-ui input:focus-visible",
          ".threadline-ui select:focus-visible",
          ".threadline-ui a:focus-visible",
          ".threadline-ui summary:focus-visible"
        ] do
      assert String.contains?(src, selector), "missing focus-visible selector #{selector}"
    end

    focus_block =
      src
      |> String.split(".threadline-ui button:focus-visible,")
      |> Enum.at(1)
      |> String.split("}")
      |> List.first()

    assert String.contains?(focus_block, "box-shadow: var(--tl-focus-ring);")

    refute Regex.match?(~r/\.threadline-ui\s+\*\s*\{[^}]*outline:\s*none/s, src),
           "blanket focus outline removal is forbidden"

    for selector <- [
          ".tl-chip--info",
          ".tl-chip--warning",
          ".tl-chip--danger",
          ".tl-chip--success"
        ] do
      assert_selector_contains(src, selector, ["color:", "--tl-chip-dot:"])
    end

    for selector <- [
          ".tl-chip--info::before",
          ".tl-chip--warning::before",
          ".tl-chip--danger::before",
          ".tl-chip--success::before"
        ] do
      assert String.contains?(src, selector), "missing non-color status marker #{selector}"
    end

    assert String.contains?(src, "background: var(--tl-chip-dot);")
  end

  test "phase 168 focus ring clears non-text 3:1 per mode with halo reported only" do
    src = File.read!(@style_path)

    light_block = selector_block!(src, ~s|.threadline-ui[data-tl-theme="light"]|)
    system_block = system_lane_block!(src)

    for {mode, block} <- [{"light", light_block}, {"system", system_block}] do
      map = color_tokens(block)

      # WCAG 2.1 SC 1.4.11 — non-text contrast 3:1 (NOT 4.5). The load-bearing
      # affordance is the OPAQUE 1px border-focus edge; controls sit on both
      # surface and surface-raised.
      for bg_token <- ["--tl-color-surface", "--tl-color-surface-raised"] do
        assert contrast_ratio(map["--tl-color-border-focus"], map[bg_token]) >= 3.0,
               "#{mode}: 1px border-focus edge must clear non-text 3:1 on #{bg_token}"
      end

      # The 3px translucent halo (rgba first shadow layer) is composited and
      # REPORTED, never carrying the pass — a low-alpha halo (here ~1.4:1) would
      # otherwise mask a focus failure (Anti-Pattern: halo masking). The halo alpha
      # is parsed from the ACTUAL --tl-focus-ring source in this lane (not a
      # hardcoded literal) so the assertion tracks source and cannot silently rot.
      halo_over_surface = composite(focus_ring_halo!(block), map["--tl-color-surface"])
      halo_ratio = contrast_ratio(halo_over_surface, map["--tl-color-surface"])

      assert is_float(halo_ratio),
             "#{mode}: focus halo ratio is computed and reportable (value=#{halo_ratio})"

      refute halo_ratio >= 3.0,
             "#{mode}: the translucent halo alone must NOT reach 3:1 — the opaque edge carries the pass"
    end
  end

  test "phase 168 no --tl-color-* token escapes the alpha-aware parser (silent-drop guard)" do
    src = File.read!(@style_path)

    # Every --tl-color-* declaration in source must use a value format the parser
    # accepts (#RRGGBB or rgba(...)). A future #RRGGBBAA, #RGB, or hsl() value
    # would reintroduce the silent-drop blind spot this phase set out to close —
    # fail loudly here rather than relying on the absence of such tokens today.
    declared =
      ~r/(--tl-color-[a-z0-9-]+)\s*:\s*([^;]+);/
      |> Regex.scan(src)
      |> Enum.map(fn [_m, token, value] -> {token, String.trim(value)} end)

    unparsed =
      Enum.reject(declared, fn {_token, value} ->
        # var(...) aliases are indirection resolved at CSS runtime, not a static
        # color literal the contrast math consumes.
        String.starts_with?(value, "var(") or
          Regex.match?(~r/^#[0-9a-fA-F]{6}$/, value) or
          Regex.match?(~r/^rgba\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*[\d.]+\s*\)$/, value)
      end)

    assert unparsed == [],
           "these --tl-color-* declarations use a value format color_tokens/1 silently drops: #{inspect(unparsed)}"
  end

  test "phase 168 normalize_alpha handles leading-dot and bare-integer alpha" do
    # Exercises the parser branches no current source token hits, so they are not
    # silently dead if such an alpha is later authored.
    assert parse_color_value("rgba(1, 2, 3, .5)") == {1, 2, 3, 0.5}
    assert parse_color_value("rgba(4, 5, 6, 1)") == {4, 5, 6, 1.0}
  end

  test "phase 168 interaction states resolve to a perceptible per-mode delta" do
    src = File.read!(@style_path)

    light = src |> selector_block!(~s|.threadline-ui[data-tl-theme="light"]|) |> color_tokens()
    system = src |> system_lane_block!() |> color_tokens()

    for {mode, map} <- [{"light", light}, {"system", system}] do
      # Hover: surface-hover must differ perceptibly from the rest surface and
      # surface-raised in each mode (the hover background is a real delta).
      refute map["--tl-color-surface-hover"] == map["--tl-color-surface"],
             "#{mode}: hover surface must differ from rest surface"

      refute map["--tl-color-surface-hover"] == map["--tl-color-surface-raised"],
             "#{mode}: hover surface must differ from raised surface"

      # Active/pressed/selected uses accent-soft + a non-color cue (accent-border /
      # accent-inset). The selected tint and the active-nav text must both exist
      # and active-nav text (accent-strong) keeps its A11Y-01 4.5:1 read.
      assert Map.has_key?(map, "--tl-color-accent-soft"),
             "#{mode}: selected/pressed tint token present"

      assert Map.has_key?(map, "--tl-color-accent-border"),
             "#{mode}: non-color selected cue (accent-border) present"

      assert Map.has_key?(map, "--tl-color-accent-inset"),
             "#{mode}: non-color selected cue (accent-inset) present"

      refute map["--tl-color-surface-selected"] == map["--tl-color-surface"],
             "#{mode}: selected surface must differ from rest surface"

      # Disabled reads not-actionable via muted-soft (covered for contrast under
      # the D-04 exemption in the contrast mirror).
      assert Map.has_key?(map, "--tl-color-muted-soft"),
             "#{mode}: disabled text token present"
    end

    # Phase-167 coverage-table hover polarity flip must be present in BOTH lanes
    # (do NOT regress to white-on-white). The light/system overrides set a white
    # default with a tinted hover.
    assert String.contains?(
             src,
             ~s|.threadline-ui[data-tl-theme="light"] .tl-table--actionable tbody tr:hover|
           ),
           "light coverage-hover polarity override missing"

    assert String.contains?(
             src,
             ~s|.threadline-ui[data-tl-theme="system"] .tl-table--actionable tbody tr:hover|
           ),
           "system coverage-hover polarity override missing"

    assert String.contains?(
             src,
             ~s|.threadline-ui[data-tl-theme="light"] .tl-table {\n          background: var(--tl-color-surface);|
           ) or
             String.contains?(
               src,
               ~s|.threadline-ui[data-tl-theme="light"] .tl-table|
             ),
           "light coverage table default surface override missing"
  end

  test "phase 168 dark phase-143 contrast + focus guards remain byte-stable" do
    src = File.read!(@style_path)

    # The dark contrast baseline and dark focus guard consume only opaque hex /
    # source-string checks; the phase-168 parser/composite additions do not touch
    # their inputs. The seven theme-aware assertions stay intact. This test names
    # them so a reviewer can confirm byte-stability via git diff of the named test
    # bodies.
    assert String.contains?(src, "color-scheme: dark;")
    assert String.contains?(src, "--tl-focus-ring:")

    # The frozen dark focus-ring catalog (unchanged values).
    assert String.contains?(
             src,
             "--tl-focus-ring: 0 0 0 3px rgba(127, 169, 255, 0.42), 0 0 0 1px var(--tl-color-border-focus);"
           )
  end

  test "operator action primitives prevent host-link bleed and support icon buttons" do
    src = File.read!(@style_path)

    assert String.contains?(src, "--tl-shell-gutter: var(--tl-space-4);")
    assert String.contains?(src, "column-gap: var(--tl-shell-gutter);")

    assert String.contains?(src, ".threadline-ui a.tl-button,")
    assert String.contains?(src, ".threadline-ui a.tl-button:hover,")
    assert String.contains?(src, ".threadline-ui a.tl-chip,")
    assert String.contains?(src, ".threadline-ui a.tl-chip:hover,")
    assert String.contains?(src, ".threadline-ui a.tl-topbar__brand,")
    assert String.contains?(src, ".threadline-ui a.tl-topbar__brand:hover,")
    assert String.contains?(src, "text-decoration: none;")

    assert_selector_contains(
      src,
      ~S|.tl-button:active:not(:disabled):not([disabled]):not([aria-disabled="true"])|,
      ["transform: scale(0.96);"]
    )

    assert_selector_contains(src, ".tl-icon", [
      "width: 1em;",
      "height: 1em;",
      "stroke: currentColor;"
    ])

    assert_selector_contains(src, ".tl-button__icon", [
      "width: 16px;",
      "height: 16px;"
    ])

    for selector <- [
          ".threadline-ui a.tl-button--primary",
          ".threadline-ui a.tl-button--secondary",
          ".threadline-ui a.tl-button--ghost",
          ".threadline-ui a.tl-chip--accent",
          ".threadline-ui a.tl-chip--warning",
          ".threadline-ui a.tl-chip--success"
        ] do
      assert String.contains?(src, selector), "missing anchored color override #{selector}"
    end
  end

  test "phase 144 token freeze preserves the source token and canonical primitive catalog" do
    src = File.read!(@style_path)

    assert String.contains?(src, "Phase 144 token freeze")

    for token <- [
          "--tl-space-1: 4px;",
          "--tl-font-family:",
          "--tl-font-mono:",
          "--tl-font-size-body: 16px;",
          "--tl-font-size-label: 14px;",
          "--tl-font-size-dense: 13px;",
          "--tl-color-bg: var(--tl-color-threadline-black);",
          "--tl-color-surface: var(--tl-color-graphite);",
          "--tl-color-text: var(--tl-color-fog);",
          "--tl-color-muted: #A3AFC2;",
          "--tl-color-danger: #FF8585;",
          "--tl-color-success-text: #5AE0A2;",
          "--tl-radius-md: 6px;",
          "--tl-radius-pill: 999px;",
          "--tl-shadow-border:",
          "--tl-z-subview: 50;",
          "--tl-brand-logo-width: 132px;",
          "--tl-brand-logo-height: 32px;",
          "--tl-brand-logo-width-desktop: 148px;",
          "--tl-brand-logo-height-desktop: 36px;",
          "--tl-control-height: 40px;",
          "--tl-control-height-chip: 24px;",
          "--tl-shell-gutter: var(--tl-space-4);",
          "--tl-breakpoint-tablet: 768px;",
          "--tl-breakpoint-desktop: 1280px;",
          "--tl-motion-fast: 120ms;",
          "--tl-motion-base: 180ms;",
          "--tl-focus-ring:",
          "--tl-table-min-width: 720px;",
          "--tl-drawer-width: 760px;"
        ] do
      assert String.contains?(src, token), "missing phase 144 frozen token #{token}"
    end

    for selector <- [
          ".tl-button",
          ".tl-icon",
          ".tl-chip",
          ".tl-card",
          ".tl-alert",
          ".tl-empty",
          ".tl-table",
          ".tl-value",
          ".tl-kv",
          ".tl-diff",
          ".tl-copy",
          ".tl-subview",
          ".tl-topbar",
          ".tl-toolbar",
          ".tl-change__op"
        ] do
      assert String.contains?(src, selector), "missing phase 144 canonical primitive #{selector}"
    end

    for anti_pattern <- [
          "@tailwind",
          "shadcn",
          "daisyui",
          "heroicons"
        ] do
      refute String.contains?(src, anti_pattern), "phase 144 forbids #{anti_pattern}"
    end
  end

  test "phase 144 status verdict and operation semantics stay token-backed" do
    src = File.read!(@style_path)

    for selector <- [
          ".tl-alert--error",
          ".tl-alert--warning",
          ".tl-alert--success"
        ] do
      assert_selector_contains(src, selector, ["border-color:", "background:", "color:"])
      assert String.contains?(selector_block!(src, selector), "var(--tl-")
    end

    # Phase 167 (D-09): status chips carry status via a colored dot (--tl-chip-dot) on neutral
    # chrome inherited from base .tl-chip — they set color + --tl-chip-dot, not their own fill/border.
    for selector <- [
          ".tl-chip--info",
          ".tl-chip--warning",
          ".tl-chip--danger",
          ".tl-chip--success"
        ] do
      assert_selector_contains(src, selector, ["color:", "--tl-chip-dot:"])
      assert String.contains?(selector_block!(src, selector), "var(--tl-")
    end

    for selector <- [
          ".tl-change__op--insert",
          ".tl-change__op--update",
          ".tl-change__op--delete"
        ] do
      assert_selector_contains(src, selector, ["background:", "color:"])
      assert String.contains?(selector_block!(src, selector), "var(--tl-color-op-")
    end

    for token <- [
          "--tl-color-op-insert-bg: var(--tl-color-success-bg);",
          "--tl-color-op-insert-text: var(--tl-color-success-text);",
          "--tl-color-op-update-bg: var(--tl-color-info-bg);",
          "--tl-color-op-update-text: var(--tl-color-info-text);",
          "--tl-color-op-delete-bg: var(--tl-color-danger-bg);",
          "--tl-color-op-delete-text: var(--tl-color-danger);"
        ] do
      assert String.contains?(src, token), "missing phase 144 operation token #{token}"
    end
  end

  test "phase 167 light overrides are authored in both the light lane and the system branch (D-07a)" do
    src = File.read!(@style_path)

    # 167 fix-list (LIGHT-REVIEW.md): A = status-chip "signal dot" redesign (D-09), B = coverage row hover.

    # A (D-09) — status chip "signal dot": the dot paints from --tl-chip-dot, and the dedicated
    # warning dot token is authored per-theme (dark base + light lane + system branch).
    assert String.contains?(src, "background: var(--tl-chip-dot);"),
           "chip status dot must paint from --tl-chip-dot"

    warn_dot_count = src |> String.split("--tl-color-warning-dot:") |> length() |> Kernel.-(1)

    assert warn_dot_count >= 3,
           "expected --tl-color-warning-dot in dark base + light lane + system branch (found #{warn_dot_count})"

    # B — coverage table hover-polarity override, authored in both lanes.
    for selector <- [
          ~s|.threadline-ui[data-tl-theme="light"] .tl-table {|,
          ~s|.threadline-ui[data-tl-theme="system"] .tl-table {|,
          ~s|.threadline-ui[data-tl-theme="light"] .tl-table--actionable tbody tr:hover|,
          ~s|.threadline-ui[data-tl-theme="system"] .tl-table--actionable tbody tr:hover|
        ] do
      assert String.contains?(src, selector),
             "phase 167 coverage row-hover override missing dual-branch selector: #{selector}"
    end
  end

  test "phase 167 keeps status-tint a shared-token decision — no per-rider light override (D-07b / TOKEN-02)" do
    src = File.read!(@style_path)

    # The status-tint fix (A) adjusts shared light-lane TOKENS, never a per-component rider selector.
    # For each tint-rider class, refute a [data-tl-theme="light"] selector QUALIFIED by that class
    # (NOT bare absence — the lane root .threadline-ui[data-tl-theme="light"] legitimately occurs once).
    for klass <- ~w(tl-chip tl-alert tl-timeline-fact tl-change__op tl-redaction tl-policy tl-job) do
      pattern = ~r/\.#{klass}[A-Za-z0-9_-]*[^{]*\[data-tl-theme="light"\]/

      refute Regex.match?(pattern, src),
             ~s|#{klass} must not carry a per-component [data-tl-theme="light"] override (TOKEN-02); status-tint stays a shared-token decision|
    end
  end

  # --- Phase 178 (D-11 corrected): offline group anchor ----------------------
  #
  # The reconnect/offline-banner + disabled-actions group rides LiveView's built-in
  # connection classes. Phase 178 real-engine verification corrected the earlier
  # premise: the classes attach to the `[data-phx-main]` container in this app, and
  # `.threadline-ui` is the scoped descendant shell that contains the banner and
  # mutating controls. The legacy disconnected class still does not exist in
  # LiveView 1.x, and document-body anchors still match nothing useful.
  #
  # So the offline CSS MUST key off `[data-phx-main].phx-* .threadline-ui`, and
  # MUST NOT use the old same-element shell anchor, legacy disconnected class, or
  # document-body lifecycle selectors.
  test "offline group keys off [data-phx-main] with .threadline-ui descendant scoping" do
    src = File.read!(@style_path)

    for state <- ~w(loading error client-error) do
      assert String.contains?(src, "[data-phx-main].phx-#{state} .threadline-ui"),
             "offline group must anchor on [data-phx-main].phx-#{state} and scope into .threadline-ui (D-11)"
    end

    refute Regex.match?(~r/\.threadline-ui\.phx-(loading|error|client-error)/, src),
           "offline group must not put LiveView lifecycle classes on .threadline-ui itself (D-11)"

    refute String.contains?(src, ".phx-disconnected"),
           ".phx-disconnected does not exist in LiveView 1.x — use current LiveView lifecycle classes"

    refute String.contains?(src, "body.phx-"),
           "connection classes attach to [data-phx-main], not the document body"
  end

  # --- Phase 177 (GROUP-02 / D-10.1, RESEARCH Pitfall 2): overlay JS-transition utilities ---
  #
  # RED Wave-0 scaffold. modal/drawer/toast show_*/hide_* (ui.ex) reference a set of
  # JS-transition utility CLASSES that are NOT defined in style.ex today (grep-verified:
  # only the `@keyframes tl-fade-in`/`tl-rise-in` exist, which drive CSS `animation:`
  # mount reveals — NOT the JS `transition:` tuples the overlays use). The group-motion
  # work (Plan 04) must DEFINE these as real class selectors with token-backed
  # transitions. Each assertion is keyed to the class-SELECTOR form (`.x {` or `.x,`)
  # so the existing `@keyframes tl-fade-in`/`tl-rise-in` cannot false-green it.
  # This block is RED until Plan 04 defines the overlay utility classes + shells.
  test "phase 177 overlay JS-transition utility classes are defined as class selectors (not just keyframes)" do
    src = File.read!(@style_path)

    overlay_classes = [
      "tl-fade-in",
      "tl-fade-out",
      "tl-rise-in",
      "tl-rise-out",
      "tl-slide-in-right",
      "tl-slide-out-right",
      "opacity-0",
      "opacity-100",
      "translate-y-0",
      "translate-y-4",
      "translate-x-0",
      "translate-x-full",
      "tl-modal-container",
      "tl-drawer-container"
    ]

    for klass <- overlay_classes do
      # Class-selector form only: `.klass {` (own block) or `.klass,` (grouped) or
      # `.klass.` / `.klass ` (compound/descendant). Crucially NOT `@keyframes klass`.
      assert Regex.match?(~r/\.#{Regex.escape(klass)}\s*[\{,]/, src) or
               Regex.match?(~r/\.#{Regex.escape(klass)}[.\s:]/, src),
             "overlay utility .#{klass} must be defined as a CSS class selector in style.ex (D-10.1; keyframes don't count — RESEARCH Pitfall 2)"
    end

    # The data-region cross-fade (D-10.2): the region container fades in on the fast
    # motion token so a state swap reads as intentional. A `transition` can't fire here
    # (state swaps render different child markup, never toggle the region's own opacity),
    # so the mechanism is an opacity-in `animation` keyed to the state-suffixed region id;
    # see the .tl-data-panel__region comment in style.ex.
    assert Regex.match?(
             selector_block_pattern(
               ".tl-data-panel__region",
               ~r/animation:\s*tl-fade-in\s+var\(--tl-motion-fast\)/
             ),
             src
           ),
           ".tl-data-panel__region must fade in via animation: tl-fade-in var(--tl-motion-fast) for the state-swap motion (D-10.2)"
  end

  # --- Phase 178 (PAGE-03 / D-09, RESEARCH Pitfall 1): grid-item centering ---
  #
  # RED Wave-0 scaffold. `margin: 0 auto` does NOT center a CSS-grid item: at
  # >=768px both `.tl-container` (style.ex:675-678) and `.tl-home` (style.ex:689-692)
  # are grid items (grid-column: 2 via the `.threadline-ui > :not(...)` catch-all),
  # and under the default `justify-self: stretch` a max-width cap anchors them to the
  # column START (left) — the "left push." The grid-native fix is `justify-self:
  # center` (D-09), kept alongside max-width. This guard locks the fix so a silent
  # revert to bare `margin: 0 auto` on a grid item is impossible.
  #
  # `.tl-home` is the latent twin (RESEARCH Pitfall 1 / Open Q1 — RESOLVED: fold in):
  # it carries the identical capping CSS on a grid-item <main>, so it left-pushes
  # exactly like the transaction page. Both assertions are RED today (no
  # `justify-self` anywhere in style.ex). Plan 178-03 Task 1 applies the one-line fix
  # to BOTH selectors.
  test "phase 178 PAGE-03 .tl-container centers as a grid item via justify-self: center (D-09)" do
    src = File.read!(@style_path)

    container = selector_block!(src, ".tl-container")

    assert String.contains?(container, "max-width: 1000px;"),
           ".tl-container must keep its max-width cap"

    assert String.contains?(container, "justify-self: center;"),
           ".tl-container must carry justify-self: center so the max-width cap centers within grid column 2 (D-09); margin: 0 auto does NOT center a grid item"
  end

  test "phase 178 PAGE-03 latent twin .tl-home centers as a grid item via justify-self: center (RESEARCH Pitfall 1)" do
    src = File.read!(@style_path)

    home = selector_block!(src, ".tl-home")

    assert String.contains?(home, "max-width: 1000px;"),
           ".tl-home must keep its max-width cap"

    assert String.contains?(home, "justify-self: center;"),
           ".tl-home is the PAGE-03 latent twin (identical capping CSS on a grid-item <main>) and must ALSO carry justify-self: center (RESEARCH Pitfall 1, RESOLVED: fold in)"
  end

  # --- Phase 178 (PAGE-02 #10/#11): per-role contrast coverage extension ------
  #
  # Footgun #10 (unreadable contrast) / #11 (same-color text-on-bg). The dark
  # baseline (phase 143) and the light/system composited lanes (phase 168) already
  # assert the primary text/status roles. Phase 178 EXTENDS coverage to every
  # operator-surface secondary text role named in 178-UI-SPEC § Color that paints on
  # a chrome surface, so a future role/token edit that drops a pairing below AA fails
  # loudly. Reuses the existing contrast_ratio/2 + composite/2 engine (D-07; do NOT
  # build a new calculator). If all current pairings already pass this is
  # GREEN-confirming (the guard still becomes permanent) — documented in the SUMMARY.
  test "phase 178 PAGE-02 #10/#11 secondary text roles meet AA on every chrome surface (dark + light + system)" do
    src = File.read!(@style_path)

    dark = src |> selector_block!(".threadline-ui") |> color_tokens()
    light = src |> selector_block!(~s|.threadline-ui[data-tl-theme="light"]|) |> color_tokens()
    system = src |> system_lane_block!() |> color_tokens()

    backgrounds = [
      "--tl-color-bg",
      "--tl-color-surface",
      "--tl-color-surface-raised",
      "--tl-color-surface-hover"
    ]

    # Secondary/meta/label text roles that paint directly on chrome surfaces. These
    # extend the phase-143/168 primary-role rows with the muted-family secondary text
    # the operator pages lean on for meta/labels. (muted-soft is the WCAG 1.4.3
    # disabled-exempt role and is asserted at its >= 3.0 floor in the phase-168 mirror,
    # so it is deliberately excluded here.)
    secondary_text_roles = [
      "--tl-color-text",
      "--tl-color-muted"
    ]

    for {mode, map} <- [{"dark", dark}, {"light", light}, {"system", system}],
        text_token <- secondary_text_roles,
        background_token <- backgrounds,
        Map.has_key?(map, text_token) and Map.has_key?(map, background_token) do
      assert contrast_ratio(map[text_token], map[background_token]) >= 4.5,
             "#{mode}: #{text_token} must meet AA 4.5:1 on #{background_token} (footgun #10/#11)"
    end
  end

  # --- Phase 178 (PAGE-02 #1, D-06): surface-wide scroll-trap source scan ------
  #
  # RED Wave-0 scaffold. Footgun #1 (scroll traps / sticky occlusion). The mobile
  # base already reconciles scroll-padding-top to the .tl-target-row scroll-margin-top
  # (both `calc(var(--tl-header-height-mobile) + var(--tl-space-4))`), carries
  # overscroll-behavior: contain, and uses 100svh (phase 177 hardening). BUT at the
  # desktop grid shell (>=768px) the scroll container's reserved offset switches to
  # the DESKTOP header token (`calc(var(--tl-header-height) + var(--tl-space-4))`,
  # style.ex:3897) while `.tl-target-row` scroll-margin-top stays pinned to the
  # MOBILE token (style.ex:2647) with no desktop override — so a sticky desktop topbar
  # over-/under-shoots an anchored target. This guard requires the desktop offsets to
  # reconcile (a `.tl-target-row` rule carrying scroll-margin-top with the DESKTOP
  # `--tl-header-height` token, matching the desktop scroll-padding-top). RED today.
  # This is the surface-wide Tier A half D-06 mandates for #1; the Tier B sticky-
  # occlusion sweep half lives in operator-phase-178-uat.spec.ts.
  test "phase 178 PAGE-02 #1 desktop scroll offset reconciles scroll-padding-top to scroll-margin-top (D-06)" do
    src = File.read!(@style_path)

    # Desktop scroll container reserves the desktop header offset.
    assert src =~ "scroll-padding-top: calc(var(--tl-header-height) + var(--tl-space-4));",
           "desktop scroll container must reserve the desktop sticky-header offset (--tl-header-height)"

    # The anchored target's scroll-margin-top must reconcile to the SAME desktop
    # token at >=768px so a sticky desktop topbar never occludes an anchored row.
    # Mobile base alone (--tl-header-height-mobile) is not enough — extract the
    # desktop media layer and require a .tl-target-row scroll-margin-top using the
    # desktop --tl-header-height token there.
    desktop = media_section(src, "768px")

    assert Regex.match?(
             selector_block_pattern(
               ".tl-target-row",
               ~r/scroll-margin-top:\s*calc\(var\(--tl-header-height\)\s*\+\s*var\(--tl-space-4\)\)/
             ),
             desktop
           ),
           ".tl-target-row scroll-margin-top must reconcile to the DESKTOP --tl-header-height offset at >=768px (style.ex:2647 currently stays pinned to --tl-header-height-mobile — a sticky desktop topbar occludes the anchored target). #1 scroll-trap reconciliation, RED today (D-06)"
  end

  # --- Phase 178 (PAGE-02 #6, D-06): spacing-token source scan ----------------
  #
  # RED Wave-0 scaffold. Footgun #6 (misalignment / chopped-padding / spacing). The
  # cheap per-PR surface-wide source half of #6: stressed-page child spacing must
  # resolve through the --tl-space-* / token scale (or 0), never a raw px/rem/em
  # literal that drifts off the rhythm. `.tl-timeline-fact` (a timeline-page child)
  # carries a raw `gap: 2px` (style.ex:1105) that does NOT resolve through the space
  # scale — RED today. The boundingBox / within-viewport half of #6 lives in
  # operator-phase-178-uat.spec.ts. Scope the scan to the selector block via
  # selector_block! so a sibling rule cannot false-pass.
  test "phase 178 PAGE-02 #6 stressed-page child spacing resolves through the --tl-space-* token scale (no raw gap/margin literal) (D-06)" do
    src = File.read!(@style_path)

    # `.tl-timeline-fact` is a timeline-page child. Its gap must resolve through the
    # space scale (var(--tl-space-*)) — a raw `gap: 2px` is the off-rhythm offender.
    timeline_fact = selector_block!(src, ".tl-timeline-fact")

    gap_decl =
      case Regex.run(~r/gap:\s*([^;]+);/, timeline_fact) do
        [_, value] -> String.trim(value)
        _ -> flunk(".tl-timeline-fact must declare a gap")
      end

    assert String.contains?(gap_decl, "var(--tl-space-"),
           ".tl-timeline-fact gap must resolve through the --tl-space-* scale, got raw `#{gap_decl}` (footgun #6 spacing drift, RED today; Plan 04 retokenizes it)"
  end

  defp motion_inventory_rows(inventory) do
    inventory
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "| M-"))
    |> Enum.map(fn row ->
      [
        id,
        selector_or_keyframe,
        _surface,
        trigger,
        persona_jtbd,
        rationale,
        token,
        _properties,
        _frequency,
        reduced_motion,
        _source,
        _status
      ] =
        row
        |> String.trim()
        |> String.trim_leading("|")
        |> String.trim_trailing("|")
        |> String.split("|")
        |> Enum.map(&String.trim/1)

      %{
        id: id,
        selector_or_keyframe: selector_or_keyframe,
        trigger: trigger,
        persona_jtbd: persona_jtbd,
        rationale: rationale,
        token: token,
        reduced_motion: reduced_motion
      }
    end)
  end

  defp motion_inventory_row!(inventory, selector) do
    inventory
    |> motion_inventory_rows()
    |> Enum.find(fn row -> String.contains?(row.selector_or_keyframe, selector) end) ||
      flunk("motion inventory is missing #{selector}")
  end

  defp assert_selector_uses_animation(src, selector, keyframe) do
    pattern =
      ~r/#{Regex.escape(selector)}[^}]*animation:\s*#{Regex.escape(keyframe)}\s+var\(--tl-motion-[a-z-]+\)\s+var\(--tl-ease-[a-z-]+\)(?:\s+120ms)?(?:\s+both)?\s*;/s

    assert Regex.match?(pattern, src),
           "#{selector} must use #{keyframe} with var(--tl-motion-*) duration and named easing token"
  end

  defp assert_selector_uses_tokenized_transition(src, selector) do
    pattern =
      ~r/#{Regex.escape(selector)}[^}]*transition(?:-property|-duration)?:[^}]*var\(--tl-(?:transition-fast|motion-base|ease-out|ease-standard)/s

    refute src =~ "transition-duration: var(--tl-transition-fast);",
           "transition-duration cannot use --tl-transition-fast because that token includes easing"

    assert Regex.match?(pattern, src),
           "#{selector} must use var(--tl-transition-fast) or named motion/ease tokens"
  end

  defp allowed_motion_duration_line?(line) do
    String.contains?(line, "--tl-motion-") or
      String.contains?(line, "tl-thread-draw var(--tl-motion-slow) var(--tl-ease-out) 120ms both") or
      String.contains?(line, "1ms !important") or
      String.contains?(line, "0ms !important")
  end

  defp base_responsive_section(src) do
    src
    |> String.split("@media (min-width: 768px)")
    |> List.first()
  end

  defp media_section(src, width) do
    src
    |> String.split("@media (min-width: #{width}) {")
    |> Enum.at(1)
    |> String.split(next_media_boundary(width))
    |> List.first()
  end

  defp next_media_boundary("768px"), do: "@media (min-width: 1280px)"
  defp next_media_boundary("1280px"), do: "@media (prefers-reduced-motion: reduce)"

  defp assert_selector_contains(section, selector, declarations) do
    block = selector_block!(section, selector)

    for declaration <- declarations do
      assert String.contains?(block, declaration),
             "#{selector} is missing #{declaration}"
    end
  end

  defp assert_exact_selector_contains(section, selector, declarations) do
    pattern = ~r/(?:^|\n)\s*#{Regex.escape(selector)}\s*\{[^}]*\}/s

    case Regex.run(pattern, section) do
      [block] ->
        for declaration <- declarations do
          assert String.contains?(block, declaration),
                 "#{selector} is missing #{declaration}"
        end

      _ ->
        flunk("missing exact selector #{selector}")
    end
  end

  defp selector_block!(section, selector) do
    pattern = selector_block_pattern(selector)

    case Regex.run(pattern, section) do
      [block] -> block
      _ -> flunk("missing selector #{selector}")
    end
  end

  # Phase 168: the system lane lives inside an @media (prefers-color-scheme: light)
  # wrapper, so a bare selector_block! (non-nested [^}]* matcher, Pitfall 2) would
  # mis-extract. Mirror the media_section/2 precedent: slice on the media wrapper
  # first, then selector_block! the inner [data-tl-theme="system"] block. Take the
  # FIRST slice after the wrapper (the token block precedes the later coverage-hover
  # override that reuses the same @media wrapper).
  defp system_lane_block!(src) do
    src
    |> String.split("@media (prefers-color-scheme: light) {")
    |> Enum.at(1)
    |> selector_block!(~s|.threadline-ui[data-tl-theme="system"]|)
  end

  defp selector_block_pattern(selector, declaration_pattern \\ ~r/[^}]*/) do
    ~r/#{Regex.escape(selector)}\s*\{[^}]*#{Regex.source(declaration_pattern)}[^}]*\}/s
  end

  # Phase 168: alpha-aware token parser. Opaque `#RRGGBB` tokens stay as hex
  # strings (feed straight into contrast_ratio/2); translucent `rgba(r, g, b, a)`
  # tokens — every status `*-bg` tint, accent wash, and focus-ring layer the
  # hex-only regex used to silently drop — parse to an {r, g, b, a} tuple to be
  # composited over a caller-named per-mode opaque base before luminance math.
  defp color_tokens(src) do
    # Hardcode primitive mapping for tests so we don't need a complex recursive resolver
    primitives = %{
      "var(--tl-color-threadline-black)" => "#0B1020",
      "var(--tl-color-graphite)" => "#141B2D",
      "var(--tl-color-slate-line)" => "#23304A",
      "var(--tl-color-fog)" => "#D7DEEA",
      "var(--tl-color-paper)" => "#F7F9FC",
      "var(--tl-color-mist)" => "#E7ECF4",
      "var(--tl-color-ink)" => "#0F1728",
      "var(--tl-color-thread-blue)" => "#4F8CFF",
      "var(--tl-color-stitch-blue)" => "#4781E6",
      "var(--tl-color-signal-cyan)" => "#4EDFD1",
      "var(--tl-color-iris)" => "#8A7CFF",
      "var(--tl-color-ember)" => "#FF8A5B"
    }

    ~r/(--tl-color-[a-z0-9-]+):\s*(#[0-9a-fA-F]{6}|rgba\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*[\d.]+\s*\)|var\(--tl-color-[a-z0-9-]+\));/
    |> Regex.scan(src)
    |> Enum.map(fn [_match, token, value] ->
      val = Map.get(primitives, value, value)
      {token, val}
    end)
    |> Enum.map(fn {token, val} ->
      case Regex.run(~r/^(#[0-9a-fA-F]{6}|rgba\([^)]+\))$/, val) do
        [_, color_val] -> {token, parse_color_value(color_val)}
        nil -> {token, nil}
      end
    end)
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  # Parse the first rgba(...) layer (the translucent halo) out of the
  # `--tl-focus-ring` box-shadow declaration in a lane block. Used so the focus
  # halo assertion derives from source rather than a duplicated literal.
  defp focus_ring_halo!(block) do
    [_match, r, g, b, a] =
      Regex.run(
        ~r/--tl-focus-ring:[^;]*?rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)/,
        block
      )

    {String.to_integer(r), String.to_integer(g), String.to_integer(b),
     String.to_float(normalize_alpha(a))}
  end

  defp parse_color_value("#" <> _ = hex), do: hex

  defp parse_color_value("rgba(" <> _ = rgba) do
    [_match, r, g, b, a] =
      Regex.run(~r/rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)/, rgba)

    {String.to_integer(r), String.to_integer(g), String.to_integer(b),
     String.to_float(normalize_alpha(a))}
  end

  defp normalize_alpha("." <> _ = a), do: "0" <> a
  defp normalize_alpha(a), do: if(String.contains?(a, "."), do: a, else: a <> ".0")

  # Composite a translucent {r, g, b, a} token over an opaque base hex, returning
  # an opaque "#RRGGBB" string that relative_luminance/1 pattern-matches without
  # change. effective = round(src*a + base*(1 - a)) per channel. The base is
  # caller-named PER MODE (#FFFFFF / #EEF3FA / #F7F9FC light vs #141B2D / #1B253A /
  # #0B1020 dark) — never assumed single. Opaque hex passes through unchanged so
  # the same code path is safe for both kinds of token (no double-composite).
  defp composite("#" <> _ = hex, _base), do: hex

  defp composite({r, g, b, a}, base_hex) do
    {br, bg, bb} = hex_to_rgb(base_hex)
    blend = fn s, base -> round(s * a + base * (1 - a)) end

    # Output casing is uppercase BY CONTRACT (e.g. "#F6EBEB") so callers can
    # string-compare composite output without per-call defensive casing.
    ("#" <>
       Enum.map_join([{r, br}, {g, bg}, {b, bb}], "", fn {s, base} ->
         blend.(s, base) |> Integer.to_string(16) |> String.pad_leading(2, "0")
       end))
    |> String.upcase()
  end

  defp hex_to_rgb("#" <> hex) when byte_size(hex) == 6 do
    [r, g, b] =
      hex
      |> String.graphemes()
      |> Enum.chunk_every(2)
      |> Enum.map(fn pair -> pair |> Enum.join() |> String.to_integer(16) end)

    {r, g, b}
  end

  defp hex_to_rgb(other),
    do: flunk(~s|hex_to_rgb/1 expected an opaque "#RRGGBB" base, got: #{inspect(other)}|)

  defp contrast_ratio(foreground, background) do
    fg = relative_luminance(foreground)
    bg = relative_luminance(background)
    lighter = max(fg, bg)
    darker = min(fg, bg)

    (lighter + 0.05) / (darker + 0.05)
  end

  defp relative_luminance("#" <> hex) do
    [r, g, b] =
      hex
      |> String.graphemes()
      |> Enum.chunk_every(2)
      |> Enum.map(fn pair ->
        pair
        |> Enum.join()
        |> String.to_integer(16)
        |> Kernel./(255)
        |> linear_channel()
      end)

    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  defp linear_channel(channel) when channel <= 0.03928, do: channel / 12.92

  defp linear_channel(channel), do: :math.pow((channel + 0.055) / 1.055, 2.4)
end
