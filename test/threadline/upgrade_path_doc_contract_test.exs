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
    assert String.contains?(guide, "## Packaging Boundary Scorecard")
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
    assert String.contains?(guide, "/audit/evidence")
    assert String.contains?(guide, "`supported`")
    assert String.contains?(guide, "`reference`")
    assert String.contains?(guide, "`unclaimed`")
    assert String.contains?(guide, "support-scoped row")
    assert String.contains?(guide, "transaction, support-scoped row history / as-of, and")
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

    assert String.contains?(
             guide,
             "The `{:sigra, \"~> 0.2\", optional: true}` declaration is a host install shape"
           )

    refute String.contains?(guide, "Phoenix 1.7+")
  end

  test "upgrade-path guide locks phx-gen-auth-reference lane detection and matrix row" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(guide, "You are on the `phx-gen-auth-reference` lane")
    assert String.contains?(guide, "| `phx-gen-auth-reference` | `reference` |")

    assert String.contains?(
             guide,
             "test/threadline/integrations/phx_gen_auth_integration_test.exs"
           )

    assert String.contains?(guide, "guides/integrations/phx-gen-auth.md")
    refute String.contains?(guide, "forthcoming")
  end

  test "phx-gen-auth guide cites integration test proof" do
    guide = File.read!("guides/integrations/phx-gen-auth.md")

    assert String.contains?(
             guide,
             "test/threadline/integrations/phx_gen_auth_integration_test.exs"
           )

    refute String.contains?(guide, "forthcoming")
    refute String.contains?(guide, "_, _ ->")
  end

  test "upgrade-path guide locks the four named lanes and their proof anchors" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(guide, "| `capture-only` | `supported` |")
    assert String.contains?(guide, "| `phoenix-surface` | `supported` |")
    assert String.contains?(guide, "| `phx-gen-auth-reference` | `reference` |")
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
    assert String.contains?(guide, "Root `mix.exs`, root `mix.lock`")
    assert String.contains?(guide, "`examples/threadline_phoenix/mix.lock`")
    assert String.contains?(guide, "`examples/threadline_phoenix/README.md`")
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

  test "upgrade-path guide locks the packaging scorecard and stay-in-tree decision" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(guide, "stay in-tree for now")
    assert String.contains?(guide, "Version Matrix Pressure")
    assert String.contains?(guide, "Release Cadence Divergence")
    assert String.contains?(guide, "Adopter Glue Burden")
    assert String.contains?(guide, "threadline_operator_surface/2")
    assert String.contains?(guide, "If a future split happens")
  end

  test "mix.exs exposes the upgrade-path guide in ExDoc extras" do
    mix_exs = File.read!("mix.exs")
    assert String.contains?(mix_exs, "\"guides/upgrade-path.md\"")
  end

  test "upgrade-path guide locks 0.5.x to 0.6.x minor upgrade bullet" do
    guide = File.read!("guides/upgrade-path.md")

    {idx_minor, _} = :binary.match(guide, "## Upgrade by Threadline minor")
    {idx_phoenix, _} = :binary.match(guide, "## What breaks when Phoenix")
    scope = {idx_minor, idx_phoenix - idx_minor}

    assert :binary.match(guide, "0.5.x → 0.6.x", scope: scope) != :nomatch or
             :binary.match(guide, "0.5.x -> 0.6.x", scope: scope) != :nomatch

    assert :binary.match(guide, "Threadline.Audit.transaction/3", scope: scope) != :nomatch or
             :binary.match(guide, "Threadline.Evidence", scope: scope) != :nomatch

    assert :binary.match(guide, "CHANGELOG.md", scope: scope) != :nomatch
    assert :binary.match(guide, "[0.6.0]", scope: scope) != :nomatch
  end
end
