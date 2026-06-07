defmodule Threadline.OperatorSurface.StyleContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @style_path "lib/threadline/operator_surface/style.ex"
  @motion_inventory_path ".planning/phases/141-motion-micro-animation/141-MOTION-INVENTORY.md"

  test "operator surface stays dark-only and token-driven" do
    src = File.read!(@style_path)

    assert String.contains?(src, "color-scheme: dark;")
    refute String.contains?(src, "prefers-color-scheme")
    refute String.contains?(src, "color-scheme: light")
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
    assert String.contains?(src, ".tl-target-row")
    assert String.contains?(src, ".tl-target-row:target")
    assert String.contains?(src, "scroll-margin-top: calc(var(--tl-header-height-mobile)")
    assert String.contains?(src, "font-family: var(--tl-font-mono)")
    assert String.contains?(src, "background: var(--tl-color-surface-raised)")
    assert String.contains?(src, "border-color: var(--tl-color-border)")
  end

  test "phase 138 find primitives stay token-backed and dark-only" do
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
    refute String.contains?(find_section, "prefers-color-scheme")
    refute String.contains?(find_section, "color-scheme: light")
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
          ".tl-topbar__brand-mark",
          ".tl-topbar__brand-text",
          ".tl-shell-nav",
          ".tl-shell-nav__toggle",
          ".tl-shell-nav__panel",
          ".tl-shell-nav__group",
          ".tl-shell-nav__label",
          ~s|.threadline-ui .tl-shell-nav__item[aria-current="page"]|
        ] do
      assert String.contains?(topbar_section, selector)
    end

    assert String.contains?(topbar_section, "var(--tl-")
    refute String.contains?(topbar_section, "@tailwind")
    refute String.contains?(topbar_section, "from shadcn")
    refute String.contains?(topbar_section, "prefers-color-scheme")
    refute String.contains?(topbar_section, "color-scheme: light")
    refute Regex.match?(~r/#[0-9a-fA-F]{6}/, topbar_section)
    refute String.contains?(topbar_section, ".tl-topbar__nav-label")

    assert_selector_contains(topbar_section, ".tl-topbar__brand", [
      "display: inline-flex;",
      "flex: 0 0 auto;",
      "gap: var(--tl-space-2);",
      "white-space: nowrap;"
    ])

    assert_selector_contains(topbar_section, ".tl-topbar__brand-mark", [
      "width: var(--tl-brand-mark-size);",
      "height: var(--tl-brand-mark-size);",
      "flex: 0 0 var(--tl-brand-mark-size);"
    ])

    assert_selector_contains(topbar_section, ".tl-topbar__brand-text", [
      "display: inline-block;"
    ])
  end

  test "phase 139 home orientation primitives stay scoped token-backed and dark-only" do
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
    refute String.contains?(home_section, "prefers-color-scheme")
    refute String.contains?(home_section, "color-scheme: light")
    refute Regex.match?(~r/#[0-9a-fA-F]{6}/, home_section)
  end

  test "phase 140 home earned-flow controls stay scoped token-backed and dark-only" do
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
    refute String.contains?(home_section, "prefers-color-scheme")
    refute String.contains?(home_section, "color-scheme: light")
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
          "transform: none;"
        ] do
      assert String.contains?(reduced_motion, required),
             "reduced-motion block missing #{required}"
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
      ".tl-shell-nav__control:checked + .tl-shell-nav .tl-shell-nav__panel",
      ["display: grid;"]
    )

    assert_selector_contains(base, ".tl-shell-nav__toggle", [
      "min-height: var(--tl-hit-area);",
      "cursor: pointer;"
    ])

    assert_selector_contains(base, ".tl-toolbar__form", [
      "flex-direction: column;",
      "align-items: stretch;"
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

    assert_selector_contains(tablet, ".tl-toolbar__form", [
      "flex-direction: row;",
      "flex-wrap: wrap;",
      "align-items: flex-end;"
    ])

    assert_selector_contains(tablet, ".threadline-ui .tl-shell-nav__item", [
      "min-height: var(--tl-control-height-compact);"
    ])

    assert_selector_contains(desktop, ".tl-topbar__brand-mark", [
      "width: var(--tl-brand-mark-size-desktop);",
      "height: var(--tl-brand-mark-size-desktop);",
      "flex-basis: var(--tl-brand-mark-size-desktop);"
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

    tokens = color_tokens(src)

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

    assert contrast_ratio(tokens["--tl-color-accent"], tokens["--tl-color-surface-raised"]) >= 4.5,
           "base accent links must meet AA contrast on raised surfaces"
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
      assert_selector_contains(src, selector, ["border-color:", "background:", "color:"])
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
          "--tl-color-bg: #0B1020;",
          "--tl-color-surface: #141B2D;",
          "--tl-color-text: #D7DEEA;",
          "--tl-color-muted: #A3AFC2;",
          "--tl-color-danger: #FF8585;",
          "--tl-color-success-text: #5AE0A2;",
          "--tl-radius-md: 6px;",
          "--tl-radius-pill: 999px;",
          "--tl-shadow-border:",
          "--tl-z-subview: 50;",
          "--tl-brand-mark-size: 24px;",
          "--tl-brand-mark-size-desktop: 26px;",
          "--tl-control-height: 40px;",
          "--tl-control-height-chip: 24px;",
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
          "prefers-color-scheme",
          "color-scheme: light",
          "theme-toggle",
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
          ".tl-chip--info",
          ".tl-chip--warning",
          ".tl-chip--danger",
          ".tl-chip--success",
          ".tl-alert--error",
          ".tl-alert--warning",
          ".tl-alert--success"
        ] do
      assert_selector_contains(src, selector, ["border-color:", "background:", "color:"])
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

  defp selector_block_pattern(selector, declaration_pattern \\ ~r/[^}]*/) do
    ~r/#{Regex.escape(selector)}\s*\{[^}]*#{Regex.source(declaration_pattern)}[^}]*\}/s
  end

  defp color_tokens(src) do
    ~r/(--tl-color-[a-z-]+):\s*(#[0-9a-fA-F]{6});/
    |> Regex.scan(src)
    |> Map.new(fn [_match, token, hex] -> {token, hex} end)
  end

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
