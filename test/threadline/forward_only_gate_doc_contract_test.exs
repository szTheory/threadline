defmodule Threadline.ForwardOnlyGateDocContractTest do
  @moduledoc """
  Pins the CONTRIBUTING.md "Forward-only gate — run one iteration" maintainer
  runbook (Phase 196, PROOF-01) so its canonical commands, the route ↔ page twin
  mapping, and the ρ-ranking trust bar cannot drift silently, and so the critic
  never leaks into the published ExDoc/hex adopter guides (RESEARCH A1).
  """
  use ExUnit.Case, async: true

  @contributing File.read!("CONTRIBUTING.md")

  test "CONTRIBUTING.md documents the forward-only gate runbook subsection" do
    assert String.contains?(@contributing, "## Forward-only gate — run one iteration")

    assert String.contains?(
             @contributing,
             "capture → score → gate → floor → ratify → commit"
           )
  end

  test "runbook pins the canonical capture / score / gate commands" do
    assert String.contains?(@contributing, "npm run capture:pages")
    assert String.contains?(@contributing, "npm run critic:score -- --page route.coverage")

    assert String.contains?(
             @contributing,
             "npm run critic:gate -- --page route.coverage --lens brand_fidelity"
           )

    assert String.contains?(@contributing, "mix verify.mechanical")
  end

  test "runbook pins the route ↔ page twin mapping table" do
    # Each live route.* cell maps to its committed page.<x>.happy mechanical-floor twin.
    for twin <- [
          "page.timeline.happy",
          "page.coverage.happy",
          "page.retention.happy",
          "page.actor.happy",
          "page.evidence.happy"
        ] do
      assert String.contains?(@contributing, twin),
             "CONTRIBUTING.md forward-only runbook is missing twin mapping for #{twin}"
    end

    # The two non-obvious real router paths must be the mounted literals, not guesses.
    assert String.contains?(@contributing, "/audit/policy/retention")
    assert String.contains?(@contributing, "/audit/actors/service_account/zendesk-sync")
  end

  test "trust bar is the Spearman ρ ranking bar, not the stale Krippendorff α bar" do
    assert String.contains?(@contributing, "Spearman ρ ≥ 0.70"),
           "CONTRIBUTING.md must state the ρ ≥ 0.70 ranking bar (Phase-195 pivot)"

    # The stale pre-pivot trust-bar phrasing must be gone.
    refute String.contains?(@contributing, "Krippendorff α ≥ 0.67, N ≥ 20, raw agreement ≥ 0.80"),
           "CONTRIBUTING.md still carries the stale α ≥ 0.67 trust-bar phrasing"
  end

  test "runbook states the blocking-panel and local-only invariants" do
    assert String.contains?(@contributing, "advisory only")
    assert String.contains?(@contributing, "never") and String.contains?(@contributing, "block")

    assert String.contains?(@contributing, "local-only") and
             String.contains?(@contributing, "out of CI")
  end

  test "the critic runbook never leaks into the published adopter guides" do
    # RESEARCH A1 / T-196-04-01: the critic is maintainer tooling. It must live in
    # CONTRIBUTING.md and never reach guides/ (ExDoc extras → hex adopter docs).
    for guide <- Path.wildcard("guides/**/*.md") do
      body = File.read!(guide)

      refute String.contains?(body, "critic:gate"),
             "#{guide} leaks the maintainer critic gate into published adopter docs"

      refute String.contains?(body, "Forward-only gate — run one iteration"),
             "#{guide} leaks the maintainer forward-only runbook into published adopter docs"
    end
  end
end
