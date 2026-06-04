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

  test "phase 139 header nav primitives stay mobile-reachable and token-backed" do
    src = File.read!(@style_path)

    topbar_section =
      src
      |> String.split(".tl-topbar {")
      |> Enum.at(1)
      |> String.split("/* Mobile-first base:")
      |> List.first()

    for selector <- [
          ".tl-topbar__nav",
          ".tl-topbar__nav-group",
          ".tl-topbar__nav-label",
          ".tl-topbar__nav-handoff",
          ~s|.tl-topbar .tl-topbar__nav-item[aria-current="page"]|
        ] do
      assert String.contains?(topbar_section, selector)
    end

    assert String.contains?(topbar_section, "var(--tl-")
    refute String.contains?(topbar_section, "@tailwind")
    refute String.contains?(topbar_section, "from shadcn")
    refute String.contains?(topbar_section, "prefers-color-scheme")
    refute String.contains?(topbar_section, "color-scheme: light")
    refute Regex.match?(~r/#[0-9a-fA-F]{6}/, topbar_section)
    refute Regex.match?(~r/\.tl-topbar__nav-label\s*\{[^}]*display:\s*none/s, topbar_section)
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
end
