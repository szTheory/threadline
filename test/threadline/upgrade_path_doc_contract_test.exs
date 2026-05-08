defmodule Threadline.UpgradePathDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "upgrade-path guide keeps the locked section architecture" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(guide, "## Who this guide is for")
    assert String.contains?(guide, "## How to tell which lane you are on")
    assert String.contains?(guide, "## Supported compatibility matrix")
    assert String.contains?(guide, "## Upgrade by Threadline minor")
    assert String.contains?(guide, "## What breaks when Phoenix/LiveView floors move")
    assert String.contains?(guide, "## Surface-only deprecation and removal policy")
    assert String.contains?(guide, "## Release checklist for adopters")
    assert String.contains?(guide, "## Canonical references")
  end

  test "upgrade-path guide locks compatibility matrix headers and lane detection language" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(
             guide,
             "| Lane | Claim type | Declared support | Current tested resolution | Proof / CI coverage |"
           )

    assert String.contains?(guide, "You are on the `capture-only` lane")
    assert String.contains?(guide, "You are on the `phoenix-surface` lane")
    assert String.contains?(guide, "You are on the `sigra-reference` lane")
    assert String.contains?(guide, "mix verify.compile_no_optional")
    assert String.contains?(guide, "threadline_operator_surface/2")
  end

  test "upgrade-path guide keeps support claims narrow and tied to repo evidence" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(
             guide,
             "exact optional dependency ranges Threadline declares and CI-covers in this release"
           )

    assert String.contains?(
             guide,
             "Anything outside these named lanes is `unclaimed`, even if it may work."
           )

    assert String.contains?(
             guide,
             "Support claims in this table come from current in-repo proof only:"
           )

    assert String.contains?(guide, "`supported` means the lane is documented")
    assert String.contains?(guide, "`reference` means the repo maintains")
    assert String.contains?(guide, "`unclaimed` means the combination may be plausible locally")
    assert String.contains?(guide, "declared optional dependency ranges in `mix.exs`")
    assert String.contains?(guide, "current lock resolution in `mix.lock`")
    assert String.contains?(guide, "current CI coverage in `.github/workflows/ci.yml`")
    assert String.contains?(guide, "focused guide, doc-contract, and example-app verification")
    refute String.contains?(guide, "Phoenix 1.7+")
  end

  test "upgrade-path guide locks the three named lanes and their proof anchors" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(guide, "| `capture-only` | `supported` |")
    assert String.contains?(guide, "| `phoenix-surface` | `supported` |")
    assert String.contains?(guide, "| `sigra-reference` | `reference` |")
    assert String.contains?(guide, "`phoenix ~> 1.7`")
    assert String.contains?(guide, "`phoenix_live_view ~> 1.0`")
    assert String.contains?(guide, "`phoenix_html ~> 4.0`")
    assert String.contains?(guide, "`phoenix_pubsub ~> 2.1`")
    assert String.contains?(guide, "Phoenix `1.8.7`")
    assert String.contains?(guide, "Phoenix LiveView `1.1.30`")
    assert String.contains?(guide, "Phoenix HTML `4.3.0`")
    assert String.contains?(guide, "Phoenix PubSub `2.2.0`")
    assert String.contains?(guide, "Sigra `0.2.5`")
    assert String.contains?(guide, "Phoenix `1.8.5`")
    assert String.contains?(guide, "Phoenix LiveView `1.1.28`")
    assert String.contains?(guide, "mix verify.example")
    assert String.contains?(guide, "`verify-compile-no-optional`")
    assert String.contains?(guide, "`verify-test`")
    assert String.contains?(guide, "`verify-docs`")
  end

  test "upgrade-path guide locks the surface-only deprecation overlap policy" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(
             guide,
             "Threadline treats the operator surface as a public surface-only contract."
           )

    assert String.contains?(guide, "deprecate in docs and changelog first")

    assert String.contains?(
             guide,
             "remove no earlier than the next Threadline minor after at least one released overlap window"
           )

    assert String.contains?(
             guide,
             "Exceptions are allowed only for security issues, upstream hard incompatibility, or undocumented internals."
           )
  end

  test "mix.exs exposes the upgrade-path guide in ExDoc extras" do
    mix_exs = File.read!("mix.exs")
    assert String.contains?(mix_exs, "\"guides/upgrade-path.md\"")
  end
end
