defmodule Threadline.OperatorSurface.ThemeDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  # Literal-pin lock for the `theme:` option documentation in the operator-surface
  # guide. Pure source-reading (File.read! + String.contains?) so doc drift on the
  # documented theme triad or the D-04 daytime recommendation fails CI. Mirrors the
  # timeline_browse_doc_contract_test.exs analog. Each literal is asserted
  # individually so a failure pinpoints exactly which fragment regressed.
  #
  # This test does NOT lock the root README.md mount snippet — that is owned by
  # readme_doc_contract_test.exs (readme_mount_block/0). It only pins the guide's
  # Theme subsection (the additive lock per D-05; the existing snippet contracts
  # stay untouched).

  @guide_path "guides/operator-surface.md"

  test "guide documents the theme: option literal" do
    src = File.read!(@guide_path)

    assert String.contains?(src, "theme:"),
           "expected #{@guide_path} to document the `theme:` mount option literal"
  end

  test "guide documents the :dark theme value (default)" do
    src = File.read!(@guide_path)

    assert String.contains?(src, ":dark"),
           "expected #{@guide_path} to document the `:dark` theme value (the omitted default)"
  end

  test "guide documents the :light theme value" do
    src = File.read!(@guide_path)

    assert String.contains?(src, ":light"),
           "expected #{@guide_path} to document the `:light` theme value (forced light lane)"
  end

  test "guide documents the :system theme value" do
    src = File.read!(@guide_path)

    assert String.contains?(src, ":system"),
           "expected #{@guide_path} to document the `:system` theme value (OS-auto via scoped CSS)"
  end

  test "guide carries the D-04 daytime-use recommendation" do
    src = File.read!(@guide_path)

    assert String.contains?(src, "daytime-use recommendation"),
           "expected #{@guide_path} to carry the D-04 precedent phrasing `daytime-use recommendation`"
  end

  test "guide documents the runtime server-posted picker route" do
    section = theme_section()

    assert String.contains?(section, "runtime server-posted dark/light/system theme picker"),
           "expected #{@guide_path} Theme section to describe the implemented runtime picker"

    assert String.contains?(section, "POST `{base_path}/theme`"),
           "expected #{@guide_path} Theme section to document the server POST route"
  end

  test "guide documents native radio submission and CSRF" do
    section = theme_section()

    assert String.contains?(section, "native radio"),
           "expected #{@guide_path} Theme section to document the native radio controls"

    assert String.contains?(section, "`_csrf_token`"),
           "expected #{@guide_path} Theme section to document the hidden CSRF token"

    assert String.contains?(section, "`Apply theme`"),
           "expected #{@guide_path} Theme section to document the submit button label"
  end

  test "guide documents runtime picker modes and server-side resolution" do
    section = theme_section()

    assert String.contains?(section, "`dark`"),
           "expected #{@guide_path} Theme section to document the runtime dark picker value"

    assert String.contains?(section, "`light`"),
           "expected #{@guide_path} Theme section to document the runtime light picker value"

    assert String.contains?(section, "`system`"),
           "expected #{@guide_path} Theme section to document the runtime system picker value"

    assert String.contains?(section, "session-backed runtime choice"),
           "expected #{@guide_path} Theme section to document server-side session-backed resolution"

    assert String.contains?(section, "`tl_theme` response cookie mirrors the selected value"),
           "expected #{@guide_path} Theme section to document the response cookie without making it the LiveView authority"
  end

  test "guide documents runtime picker auth and session guard" do
    section = theme_section()

    assert String.contains?(section, "Threadline.OperatorSurface.ThemeAuthPlug"),
           "expected #{@guide_path} Theme section to document the theme route auth plug"

    assert String.contains?(section, "session-backed browser pipeline"),
           "expected #{@guide_path} Theme section to document the session-backed browser pipeline requirement"
  end

  test "guide documents no client-side storage or script requirement for the picker" do
    section = theme_section()

    assert String.contains?(section, "The picker needs no JavaScript"),
           "expected #{@guide_path} Theme section to document the no-JavaScript picker contract"

    assert String.contains?(section, "no `localStorage`"),
           "expected #{@guide_path} Theme section to document the no-localStorage picker contract"

    assert String.contains?(section, "no CSP `script-src` requirement"),
           "expected #{@guide_path} Theme section to document that the picker adds no CSP script requirement"
  end

  test "guide does not repeat stale host-only runtime theme language" do
    section = theme_section()

    refute String.contains?(section, "no runtime theme toggle"),
           "expected #{@guide_path} Theme section to avoid stale host-only runtime theme language"

    refute String.contains?(section, "There is no runtime per-operator toggle"),
           "expected #{@guide_path} Theme section to avoid stale host-only per-operator wording"
  end

  defp theme_section do
    @guide_path
    |> File.read!()
    |> guide_section("### Theme")
  end

  defp guide_section(markdown, heading) do
    case String.split(markdown, heading, parts: 2) do
      [_before, rest] ->
        rest
        |> String.split("\n## ", parts: 2)
        |> List.first()

      [_] ->
        flunk("missing #{heading} in #{@guide_path}")
    end
  end
end
