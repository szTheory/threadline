defmodule Threadline.BrandbookTokenParityTest do
  @moduledoc false
  use ExUnit.Case, async: true

  # Keystone brand-governance test: "correct by default" applied to the brand SSOT.
  #
  # The shipped operator-surface token lane (`style.ex`) is the source of truth. The
  # brandbook (`tokens.json` / `tokens.css`) must mirror it for the curated semantic
  # intersection — same NAME and same VALUE in BOTH dark and light lanes. This test
  # fails CI on any future drift in EITHER direction: the brandbook adding an
  # unmirrored token, or `style.ex` changing a mirrored value.
  #
  # It also locks the brand-book.md UI-theming-posture literals and the
  # pressure-test.md dual-mode addendum + mechanical parity gate line, so the brand
  # documentation cannot silently regress away from the shipped truth.
  #
  # House style mirrors operator_surface_doc_contract_test.exs / theme_doc_contract_test.exs:
  # File.read! at the top of each test, one concern per test block, custom failure
  # messages, async: true (pure filesystem reads, no shared state). No token COUNT is
  # asserted anywhere — only value-equality on the named intersection.

  @style_path "lib/threadline/operator_surface/style.ex"
  @tokens_json_path "brandbook/tokens.json"
  @tokens_css_path "brandbook/tokens.css"
  @brand_book_path "brandbook/brand-book.md"
  @pressure_test_path "brandbook/pressure-test.md"

  # Curated parity intersection: the 18 semantic tokens the brandbook claims to mirror.
  # Names use style.ex conventions (muted, not text-muted; danger, not error-text;
  # on-accent, not accent-text). Same set in both dark and light.
  @parity_intersection ~w[
    bg surface surface-raised surface-hover surface-selected
    border border-strong text muted muted-soft
    accent accent-strong on-accent signal
    success-text warning-text danger info-text
  ]

  # Brand-exclusive: lives in the brandbook, intentionally absent from style.ex.
  @brand_exclusive ~w[logo-arc]

  # Runtime-only: structural tokens in style.ex, intentionally absent from the
  # brandbook semantic blocks (rgba composites, var() aliases, status tints, op badges).
  @runtime_only ~w[
    surface-tint surface-tint-strong backdrop border-focus
    accent-soft accent-wash accent-border accent-inset
    signal-bg signal-border ink paper
    danger-bg danger-border warning-bg warning-dot warning-border
    success-bg success-border info-bg info-border
    neutral-bg neutral-text neutral-border
    op-insert-bg op-insert-text op-update-bg op-update-text
    op-delete-bg op-delete-text brand-rail
  ]

  # --- parsing helpers ---

  defp style_source, do: File.read!(@style_path)

  # Dark base block: everything before the first `[data-tl-theme` selector
  # (the dark values live in the unscoped `.threadline-ui { ... }` base block).
  defp style_dark_tokens do
    src = style_source()

    assert String.contains?(src, "[data-tl-theme"),
           "style.ex no longer carries a [data-tl-theme selector — the dark base block can no longer be delimited; the dark parity anchor was renamed or removed"

    [dark_section | _] = String.split(src, "[data-tl-theme")
    scan_tl_color(dark_section)
  end

  # Light block: the `[data-tl-theme="light"] { ... }` color-override block.
  # Anchored to that exact selector and trimmed BEFORE the first `@media`
  # (the `[data-tl-theme="system"]` block has identical values but a different
  # selector — Pitfall 3). The descendant rules later in the file (e.g.
  # `[data-tl-theme="light"] .tl-table`) carry `--tl-table*` vars, not the
  # `--tl-color-*` overrides this block holds, so capturing the first segment
  # up to `@media` is the canonical light color lane.
  defp style_light_tokens do
    src = style_source()

    assert String.contains?(src, ~s([data-tl-theme="light"] {)),
           ~s(style.ex no longer carries the [data-tl-theme="light"] { block — the light parity anchor was renamed or removed)

    [_, after_light | _] = String.split(src, ~s([data-tl-theme="light"] {))
    [light_section | _] = String.split(after_light, "@media")
    scan_tl_color(light_section)
  end

  defp scan_tl_color(block) do
    ~r/--tl-color-([^:]+):\s*([^;]+?)\s*;/
    |> Regex.scan(block)
    |> Map.new(fn [_, name, value] -> {String.trim(name), String.trim(value)} end)
  end

  defp tokens_json, do: @tokens_json_path |> File.read!() |> Jason.decode!()

  defp css_block_tokens(selector) do
    css = File.read!(@tokens_css_path)

    assert String.contains?(css, selector),
           "tokens.css no longer carries the #{inspect(selector)} selector — the CSS cross-check anchor was renamed or removed"

    [_, after_sel | _] = String.split(css, selector)
    [block | _] = String.split(after_sel, "}")
    scan_tl_color(block)
  end

  # --- parity: dark ---

  test "curated dark token intersection: brandbook values match style.ex" do
    style_dark = style_dark_tokens()
    brand_dark = tokens_json()["semantic"]["dark"]

    for name <- @parity_intersection do
      style_val = Map.get(style_dark, name)
      brand_val = Map.get(brand_dark, name)

      assert style_val != nil,
             "dark --tl-color-#{name} missing from style.ex — @parity_intersection is stale (a coordinated rename or a name typo would otherwise let nil == nil pass vacuously)"

      assert brand_val != nil,
             "dark #{name} missing from brandbook semantic.dark — @parity_intersection is stale (a coordinated rename or a name typo would otherwise let nil == nil pass vacuously)"

      assert style_val == brand_val,
             "dark --tl-color-#{name}: style.ex=#{inspect(style_val)}, brandbook=#{inspect(brand_val)} (style.ex is the source of truth — correct the brandbook)"
    end
  end

  # --- parity: light ---

  test "curated light token intersection: brandbook values match style.ex" do
    style_light = style_light_tokens()
    brand_light = tokens_json()["semantic"]["light"]

    for name <- @parity_intersection do
      style_val = Map.get(style_light, name)
      brand_val = Map.get(brand_light, name)

      assert style_val != nil,
             "light --tl-color-#{name} missing from style.ex — @parity_intersection is stale (a coordinated rename or a name typo would otherwise let nil == nil pass vacuously)"

      assert brand_val != nil,
             "light #{name} missing from brandbook semantic.light — @parity_intersection is stale (a coordinated rename or a name typo would otherwise let nil == nil pass vacuously)"

      assert style_val == brand_val,
             "light --tl-color-#{name}: style.ex=#{inspect(style_val)}, brandbook=#{inspect(brand_val)} (style.ex is the source of truth — correct the brandbook)"
    end
  end

  # --- exclusion drift: brand-exclusive must be absent from style.ex ---

  test "brand-exclusive tokens are absent from style.ex" do
    src = style_source()

    for name <- @brand_exclusive do
      refute String.contains?(src, "--tl-color-#{name}:"),
             "--tl-color-#{name} is brand-exclusive but was found in style.ex; either it is no longer brand-exclusive (update @brand_exclusive) or the operator-surface lane drifted"
    end
  end

  # --- exclusion drift: runtime-only must be absent from brandbook semantic blocks ---

  test "runtime-only tokens are absent from brandbook semantic blocks" do
    tokens = tokens_json()

    brand_keys =
      Enum.uniq(Map.keys(tokens["semantic"]["dark"]) ++ Map.keys(tokens["semantic"]["light"]))

    for name <- @runtime_only do
      refute name in brand_keys,
             "#{name} is a runtime-only structural token and must not appear in the brandbook semantic block; it belongs in excluded_from_brand_scope"
    end
  end

  # --- secondary: tokens.css must emit the same intersection values as tokens.json ---

  test "tokens.css emits the same curated intersection values as tokens.json in both modes" do
    json = tokens_json()
    css_dark = css_block_tokens(".tl-theme-dark,")
    css_light = css_block_tokens(".tl-theme-light {")

    for name <- @parity_intersection do
      assert css_dark[name] == json["semantic"]["dark"][name],
             "dark --tl-color-#{name}: tokens.css=#{inspect(css_dark[name])}, tokens.json=#{inspect(json["semantic"]["dark"][name])} (hand-duplicated files drifted)"

      assert css_light[name] == json["semantic"]["light"][name],
             "light --tl-color-#{name}: tokens.css=#{inspect(css_light[name])}, tokens.json=#{inspect(json["semantic"]["light"][name])} (hand-duplicated files drifted)"
    end
  end

  # --- doc-contract: brand-book.md UI theming posture note ---

  test "brand book states the settled UI theming posture" do
    book = File.read!(@brand_book_path)

    assert String.contains?(book, "UI theming posture"),
           "expected #{@brand_book_path} to carry the '### UI theming posture' subsection"

    assert String.contains?(book, "dark-primary"),
           "posture note should state the operator surface is dark-primary"

    assert String.contains?(book, "theme: :system | :light | :dark"),
           "posture note should cite the host theme config triad verbatim"

    assert String.contains?(book, "THEME-TOGGLE-01"),
           "posture note should cite the deferred runtime-toggle requirement THEME-TOGGLE-01"
  end

  # --- doc-contract: pressure-test.md dual-mode addendum + mechanical gate ---

  test "pressure-test carries the dual-mode addendum and mechanical parity gate" do
    pressure = File.read!(@pressure_test_path)

    assert String.contains?(pressure, "mix test test/threadline/brandbook_token_parity_test.exs"),
           "expected #{@pressure_test_path} mechanical suite to run the parity test verbatim"

    assert String.contains?(pressure, "Dual-mode addendum"),
           "expected dimension #11 to carry a 'Dual-mode addendum' paragraph"

    assert String.contains?(pressure, "dimension #5"),
           "the dual-mode addendum should cross-reference dimension #5 (Dark/light versatility)"
  end
end
