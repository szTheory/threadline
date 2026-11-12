defmodule Threadline.BrandbookTokenParityTest do
  @moduledoc false
  use ExUnit.Case, async: true

  # This file retains contracts for historical brandbook consumers and adds
  # Phase 250's approved brand/brand.json → functional stylesheet palette checks.
  # New palette values are owned by brand/brand.json; the stylesheet remains the
  # runtime owner, and historical tokens.css/json are not a second authority.
  #
  # It also locks the brand-book.md UI-theming-posture literals and the
  # pressure-test.md dual-mode addendum + mechanical parity gate line, so the brand
  # documentation cannot silently regress away from the shipped truth.
  #
  # House style mirrors operator_surface_doc_contract_test.exs:
  # File.read! at the top of each test, one concern per test block, custom failure
  # messages, async: true (pure filesystem reads, no shared state). No token COUNT is
  # asserted anywhere — only value-equality on the named intersection.

  alias Threadline.Test.StyleSource

  @style_label "the operator stylesheet (lib/threadline/operator_surface/style/)"
  @brand_book_path "brandbook/brand-book.md"
  @pressure_test_path "brandbook/pressure-test.md"
  @tokens_css_path "brandbook/tokens.css"
  @tokens_json_path "brandbook/tokens.json"
  @approved_brand_path "brand/brand.json"

  @contrast_role_tokens %{
    "body" => {"--tl-color-text", "--tl-color-bg"},
    "descriptor" => {"--tl-color-muted", "--tl-color-bg"},
    "caption" => {"--tl-color-muted", "--tl-color-surface"},
    "application-copy" => {"--tl-color-text", "--tl-color-surface"},
    "hero" => {"--tl-color-accent", "--tl-color-bg"},
    "link" => {"--tl-color-accent", "--tl-color-surface"},
    "focus" => {"--tl-color-border-focus", "--tl-color-bg"},
    "artwork" => {"--tl-color-stitch-blue", "--tl-color-bg"}
  }

  # Curated parity intersection: the 18 semantic tokens the brandbook claims to mirror.
  # Names use style.ex conventions (muted, not text-muted; danger, not error-text;
  # on-accent, not accent-text). Same set in both dark and light.
  # Brand-exclusive: lives in the brandbook, intentionally absent from style.ex.
  @brand_exclusive ~w[logo-arc]

  defp style_source, do: StyleSource.read!()

  test "Phase 250 approved contrast, operation, and control roles match both functional lanes" do
    brand = @approved_brand_path |> File.read!() |> Jason.decode!()

    assert_brand_contract!(style_source(), brand)
  end

  test "Phase 250 palette controls reject a swapped lane and operation/control conflation" do
    brand = @approved_brand_path |> File.read!() |> Jason.decode!()
    source = style_source()

    swapped_dark_body = mutate_property(source, ".threadline-ui", "--tl-color-text", "#0F1728")

    assert_raise ExUnit.AssertionError, fn ->
      assert_brand_contract!(swapped_dark_body, brand)
    end

    operation_using_control_edge =
      mutate_property(
        source,
        ~s|.threadline-ui[data-tl-theme="light"]|,
        "--tl-color-op-insert-text",
        "var(--tl-color-border-strong)"
      )

    assert_raise ExUnit.AssertionError, fn ->
      assert_brand_contract!(operation_using_control_edge, brand)
    end
  end

  defp assert_brand_contract!(source, brand) do
    lanes = [
      {"dark", ".threadline-ui"},
      {"light", ~s|.threadline-ui[data-tl-theme="light"]|},
      {"system", ~s|.threadline-ui[data-tl-theme="system"]|}
    ]

    base_colors = source |> selector_block!(".threadline-ui") |> css_color_tokens!()

    for {mode, selector} <- lanes do
      lane_colors = source |> selector_block!(selector) |> css_color_tokens!()
      colors = Map.merge(base_colors, lane_colors)
      contrast_mode = if mode == "system", do: "light", else: mode

      for pair <- brand["color"]["contrastPairs"] do
        {text_token, ground_token} = Map.fetch!(@contrast_role_tokens, pair["id"])
        expected = Map.fetch!(pair, contrast_mode)
        actual_text = resolve_color!(colors, text_token)
        actual_ground = resolve_color!(colors, ground_token)

        assert actual_text == expected["text"],
               "#{mode}/#{pair["id"]} text must match approved #{expected["text"]}"

        assert actual_ground == expected["ground"],
               "#{mode}/#{pair["id"]} ground must match approved #{expected["ground"]}"

        assert contrast_ratio(actual_text, actual_ground) >= pair["minimum"],
               "#{mode}/#{pair["id"]} must meet the approved #{pair["minimum"]}:1 minimum"
      end

      operation_suffix = if contrast_mode == "dark", do: "Dark", else: "Light"

      for operation <- brand["color"]["operations"] do
        operation_id = String.downcase(operation["name"])
        text = Map.fetch!(operation, "text#{operation_suffix}")
        chip = Map.fetch!(operation, "chip#{operation_suffix}")

        assert resolve_color!(colors, "--tl-color-op-#{operation_id}-text") == text,
               "#{mode}/#{operation_id} text must match the approved operation color"

        assert resolve_color!(colors, "--tl-color-op-#{operation_id}-bg") == chip,
               "#{mode}/#{operation_id} chip must match the approved operation color"
      end

      edge_name = if contrast_mode == "dark", do: "Steel", else: "Control Edge"
      divider_name = if contrast_mode == "dark", do: "Slate Line", else: "Hairline"

      expected_edge = brand["color"]["secondary"] |> named_color!(edge_name)
      expected_divider = brand["color"][contrast_mode] |> named_color!(divider_name)
      actual_edge = resolve_color!(colors, "--tl-color-border-strong")
      actual_divider = resolve_color!(colors, "--tl-color-border")

      assert actual_edge == expected_edge,
             "#{mode} control edge must match the approved #{edge_name}"

      assert actual_divider == expected_divider,
             "#{mode} divider must match the approved #{divider_name}"

      refute actual_edge == actual_divider,
             "#{mode} control edges and space dividers must remain distinct roles"
    end

    for {selector, background, text} <- [
          {".tl-change__op--insert", "--tl-color-op-insert-bg", "--tl-color-op-insert-text"},
          {".tl-change__op--update", "--tl-color-op-update-bg", "--tl-color-op-update-text"},
          {".tl-change__op--delete", "--tl-color-op-delete-bg", "--tl-color-op-delete-text"},
          {".tl-value--redacted", "--tl-color-op-redacted-bg", "--tl-color-op-redacted-text"}
        ] do
      block = selector_block!(source, selector)

      assert String.contains?(block, "background: var(#{background});"),
             "#{selector} must use its approved operation chip role"

      assert String.contains?(block, "color: var(#{text});"),
             "#{selector} must use its approved operation text role"
    end
  end

  defp named_color!(colors, name) do
    case Enum.find(colors, &(&1["name"] == name)) do
      nil -> flunk("approved brand color #{name} is missing")
      color -> color["hex"]
    end
  end

  defp selector_block!(source, selector) do
    pattern = Regex.compile!(Regex.escape(selector) <> "\\s*\\{([^}]*)\\}", "s")

    case Regex.run(pattern, source) do
      [_, body] -> body
      _ -> flunk("missing CSS selector #{selector}")
    end
  end

  defp css_color_tokens!(block) do
    Regex.scan(
      ~r/(--tl-color-[a-z0-9-]+)\s*:\s*(#[0-9a-fA-F]{6}|var\(--tl-color-[a-z0-9-]+\));/,
      block
    )
    |> Map.new(fn [_, token, value] -> {token, value} end)
  end

  defp resolve_color!(colors, token) do
    case Regex.run(~r/^var\((--tl-color-[^)]+)\)$/, Map.fetch!(colors, token)) do
      [_, referenced] -> resolve_color!(colors, referenced)
      _ -> Map.fetch!(colors, token)
    end
  end

  defp mutate_property(source, selector, property, replacement) do
    block = selector_block!(source, selector)
    pattern = Regex.compile!("(" <> Regex.escape(property) <> "\\s*:\\s*)[^;]+;")

    updated =
      Regex.replace(
        pattern,
        block,
        fn _match, prefix -> prefix <> replacement <> ";" end,
        global: false
      )

    String.replace(source, block, updated, global: false)
  end

  defp contrast_ratio(foreground, background) do
    foreground_luminance = relative_luminance(foreground)
    background_luminance = relative_luminance(background)
    lighter = max(foreground_luminance, background_luminance)
    darker = min(foreground_luminance, background_luminance)

    (lighter + 0.05) / (darker + 0.05)
  end

  defp relative_luminance("#" <> hex) do
    [red, green, blue] =
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

    0.2126 * red + 0.7152 * green + 0.0722 * blue
  end

  defp linear_channel(channel) when channel <= 0.04045, do: channel / 12.92
  defp linear_channel(channel), do: :math.pow((channel + 0.055) / 1.055, 2.4)

  # Runtime-only: structural tokens in style.ex, intentionally absent from the
  # brandbook semantic blocks (rgba composites, var() aliases, status tints, op badges).
  # --- exclusion drift: brand-exclusive must be absent from style.ex ---

  test "brand-exclusive tokens are absent from style.ex" do
    src = style_source()

    for name <- @brand_exclusive do
      refute String.contains?(src, "--tl-color-#{name}:"),
             "--tl-color-#{name} is brand-exclusive but was found in style.ex; either it is no longer brand-exclusive (update @brand_exclusive) or the operator-surface lane drifted"
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

  # --- Phase 177 (GROUP-01 / D-02 / D-09): semantic --tl-gap-* parity ---
  #
  # RED Wave-0 scaffold. The stack/cluster layout primitives (D-02) own the group
  # spacing rhythm via three SEMANTIC gap tokens layered over the numeric
  # --tl-space-* scale (D-09):
  #
  #   --tl-gap-inline  -> --tl-space-2 (8px)   horizontal gap in a cluster
  #   --tl-gap-stack   -> --tl-space-4 (16px)  vertical rhythm in a stack
  #   --tl-gap-section -> --tl-space-8 (32px)  section break between page-stack sections
  #
  # Today --tl-gap-inline / --tl-gap-stack exist ONLY in style.ex (L175-176);
  # --tl-gap-section exists nowhere; NONE exist in tokens.css / tokens.json. The
  # brand SSOT parity rule (this file's whole reason for being) demands all three
  # land in tokens.css + tokens.json + style.ex, value-aligned. This block is RED
  # until Plans 02/04 add them. It turns GREEN when the three sources agree.
  test "semantic gap tokens are value-aligned across tokens.css, tokens.json, and style.ex (Phase 177)" do
    css = File.read!(@tokens_css_path)
    json = File.read!(@tokens_json_path)
    style = style_source()

    # The three semantic gap tokens and the numeric --tl-space-* step each aliases.
    gap_aliases = [
      {"--tl-gap-inline", "--tl-space-2"},
      {"--tl-gap-stack", "--tl-space-4"},
      {"--tl-gap-section", "--tl-space-8"}
    ]

    for {gap, space} <- gap_aliases do
      # tokens.css: literal CSS custom-property declaration aliasing the numeric step.
      assert String.contains?(css, "#{gap}: var(#{space});"),
             "#{@tokens_css_path} must declare #{gap}: var(#{space}); — the brand SSOT must mirror the gap rhythm"

      # style.ex: same literal aliasing declaration (the shipped operator-surface lane).
      assert String.contains?(style, "#{gap}: var(#{space});"),
             "#{@style_label} must declare #{gap}: var(#{space}); so the operator surface consumes the semantic gap token"
    end

    # tokens.json: a dedicated "gap" block keyed by the semantic name -> px value,
    # value-aligned with the --tl-space-* step each gap aliases (8/16/32px).
    for {key, value} <- [{"inline", "8px"}, {"stack", "16px"}, {"section", "32px"}] do
      assert String.contains?(json, ~s|"#{key}": "#{value}"|),
             ~s|#{@tokens_json_path} must carry a "gap" entry "#{key}": "#{value}" mirroring the semantic gap token|
    end
  end
end
