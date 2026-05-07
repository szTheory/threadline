defmodule Threadline.UpgradePathDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "upgrade-path guide keeps the locked section architecture" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(guide, "## Who this guide is for")
    assert String.contains?(guide, "## How to tell which track you are on")
    assert String.contains?(guide, "## Supported compatibility matrix")
    assert String.contains?(guide, "## Upgrade by Threadline minor")
    assert String.contains?(guide, "## What breaks when Phoenix/LiveView floors move")
    assert String.contains?(guide, "## Surface-only deprecation and removal policy")
    assert String.contains?(guide, "## Release checklist for adopters")
    assert String.contains?(guide, "## Canonical references")
  end

  test "upgrade-path guide locks compatibility matrix headers and track detection language" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(guide, "| Track | Declared support | Current tested resolution | Proof / CI coverage |")
    assert String.contains?(guide, "You are on the `capture-only` track")
    assert String.contains?(guide, "You are on the `surface-mounted` track")
    assert String.contains?(guide, "mix verify.compile_no_optional")
    assert String.contains?(guide, "threadline_operator_surface/2")
  end

  test "upgrade-path guide keeps support claims narrow and tied to repo evidence" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(guide, "exact dependency ranges Threadline declares and CI-covers in this release")
    assert String.contains?(guide, "Anything outside the listed ranges is not claimed, even if it may work.")
    assert String.contains?(guide, "Support claims in this table come from three in-repo sources only:")
    assert String.contains?(guide, "declared optional dependency ranges in `mix.exs`")
    assert String.contains?(guide, "current lock resolution in `mix.lock`")
    assert String.contains?(guide, "current CI coverage in `.github/workflows/ci.yml`")
    refute String.contains?(guide, "Phoenix 1.7+")
  end

  test "upgrade-path guide locks declared ranges, current lock resolution, and CI job anchors" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(guide, "`phoenix ~> 1.7`")
    assert String.contains?(guide, "`phoenix_live_view ~> 1.0`")
    assert String.contains?(guide, "`phoenix_html ~> 4.0`")
    assert String.contains?(guide, "`phoenix_pubsub ~> 2.1`")
    assert String.contains?(guide, "Phoenix `1.8.7`")
    assert String.contains?(guide, "Phoenix LiveView `1.1.30`")
    assert String.contains?(guide, "Phoenix HTML `4.3.0`")
    assert String.contains?(guide, "Phoenix PubSub `2.2.0`")
    assert String.contains?(guide, "`verify-compile-no-optional`")
    assert String.contains?(guide, "`verify-test`")
    assert String.contains?(guide, "`verify-docs`")
  end

  test "upgrade-path guide locks the surface-only deprecation overlap policy" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(guide, "Threadline treats the operator surface as a public surface-only contract.")
    assert String.contains?(guide, "deprecate in docs and changelog first")
    assert String.contains?(guide, "remove no earlier than the next Threadline minor after at least one released overlap window")
    assert String.contains?(guide, "Exceptions are allowed only for security issues, upstream hard incompatibility, or undocumented internals.")
  end

  test "mix.exs exposes the upgrade-path guide in ExDoc extras" do
    mix_exs = File.read!("mix.exs")
    assert String.contains?(mix_exs, "\"guides/upgrade-path.md\"")
  end
end
