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
  @brand_book_path "brandbook/brand-book.md"
  @pressure_test_path "brandbook/pressure-test.md"
  @tokens_css_path "brandbook/tokens.css"
  @tokens_json_path "brandbook/tokens.json"

  # Curated parity intersection: the 18 semantic tokens the brandbook claims to mirror.
  # Names use style.ex conventions (muted, not text-muted; danger, not error-text;
  # on-accent, not accent-text). Same set in both dark and light.
  # Brand-exclusive: lives in the brandbook, intentionally absent from style.ex.
  @brand_exclusive ~w[logo-arc]

  defp style_source, do: File.read!(@style_path)

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
             "#{@style_path} must declare #{gap}: var(#{space}); so the operator surface consumes the semantic gap token"
    end

    # tokens.json: a dedicated "gap" block keyed by the semantic name -> px value,
    # value-aligned with the --tl-space-* step each gap aliases (8/16/32px).
    for {key, value} <- [{"inline", "8px"}, {"stack", "16px"}, {"section", "32px"}] do
      assert String.contains?(json, ~s|"#{key}": "#{value}"|),
             ~s|#{@tokens_json_path} must carry a "gap" entry "#{key}": "#{value}" mirroring the semantic gap token|
    end
  end
end
