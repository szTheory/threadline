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
end
