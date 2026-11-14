defmodule Threadline.OperatorSurfaceDocContractTest do
  # KEEP 1: the install pin derives from Mix.Tasks.Release.Pins, the designated
  # sole writer of every documented install pin. KEEP 2: the remaining
  # sentences pin the auth / fail-closed / export-auth security boundary — a
  # security exception to the ordinary CUT shape (prose-to-literal checks are
  # cut everywhere else in this file).
  @moduledoc false
  use ExUnit.Case, async: true

  alias Mix.Tasks.Release.Pins

  test "README states the fail-closed security posture" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "fail-closed")
  end

  test "operator surface guide details fail-closed security and auth options" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(guide, "fail-closed")
    assert String.contains?(guide, ":authorize_fn")
    assert String.contains?(guide, ":adopter_acknowledges_unauthenticated: true")
  end

  test "operator surface introduction names Threadline Admin and preserves technical anchors" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(guide, "Threadline is an audit trail library for Phoenix apps.")
    assert String.contains?(guide, "Threadline Admin provides")
    assert String.contains?(guide, ~s|<a id="operator-surface"></a>|)

    assert String.contains?(
             Threadline.MixProject.project()[:description],
             "An audit trail library for Phoenix"
           )

    assert String.contains?(
             File.read!("lib/threadline.ex"),
             "Threadline is an open-source audit trail library for Elixir and Phoenix apps."
           )

    assert String.contains?(guide, "native submit buttons")
    refute String.contains?(guide, "`Apply theme`")

    for boundary <- [
          "Preview retention",
          "Review and confirm",
          "Prune now",
          "sequential estimates",
          "configured worker store",
          "Pruner.trigger/0",
          "mismatch"
        ] do
      assert String.contains?(guide, boundary), "missing current Retention boundary #{boundary}"
    end

    for heading <- [
          "# Threadline Admin",
          "## 1-Minute Mount",
          "### Theme",
          "### `:actor_fn`",
          "## Available Screens (v1.17)"
        ] do
      assert String.contains?(guide, heading), "missing stable technical heading #{heading}"
    end
  end

  test "all mount guides require explicit authorization separate from host pipelines" do
    guides = [
      "guides/operator-surface.md",
      "guides/integration-contracts.md",
      "guides/code-walkthrough.md"
    ]

    Enum.each(guides, fn path ->
      guide = path |> File.read!() |> String.replace(~r/\s+/, " ")

      assert String.contains?(guide, ":authorize_fn"), path
      assert String.contains?(guide, ":adopter_acknowledges_unauthenticated: true"), path
      assert String.contains?(guide, "`pipe_through` alone does not authorize"), path
      assert String.contains?(guide, "intentionally public"), path
    end)

    operator_surface_guide = File.read!("guides/operator-surface.md")
    refute String.contains?(operator_surface_guide, "raises in test")
    refute String.contains?(operator_surface_guide, "warning in prod")
  end

  test "operator surface guide's mount recipe keeps its auth and export-auth gates" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(guide, "pipe_through [:browser, :admin_auth]")
    assert String.contains?(guide, "export_authorize_fn")
  end

  test "operator surface guide's install pin is derived from mix release.pins" do
    guide = File.read!("guides/operator-surface.md")

    # Derived from `mix release.pins`, the designated sole writer of every
    # documented install pin, rather than hardcoded. A literal here goes red the
    # moment that writer does its job at a version bump.
    assert String.contains?(
             guide,
             ~s({:threadline, "~> #{Pins.target_pin_version()}"})
           )
  end

  test "operator surface guide states that LiveView auth does not cover HTTP routes" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(
             guide,
             "`live_session` and `on_mount` protect the LiveView pages only"
           )

    assert String.contains?(guide, "plain-text `403`")
  end

  test "operator surface guide documents direct export route authorization boundary" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(
             guide,
             "Direct HTTP export routes remain protected by server/controller auth"
           )

    assert String.contains?(guide, "LiveView hides affordances")
    assert String.contains?(guide, "HTTP export auth remains authoritative")
  end
end
