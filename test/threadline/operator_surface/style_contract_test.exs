defmodule Threadline.OperatorSurface.StyleContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @style_path "lib/threadline/operator_surface/style.ex"

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
end
