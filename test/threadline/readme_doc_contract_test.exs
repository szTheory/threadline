defmodule Threadline.ReadmeDocContractTest do
  @moduledoc false
  use Threadline.DataCase

  alias Threadline.Test.Repo

  @quick_start_start "## Quick Start"
  @quick_start_end "## Operator Surface"

  test "readme quickstart fixtures module is loadable" do
    assert Code.ensure_loaded?(Threadline.ReadmeQuickstartFixtures)
  end

  test "readme doc contract router compiles with Threadline.Plug" do
    assert Code.ensure_loaded?(Threadline.ReadmeDocContractRouter)
  end

  test "README declares the public API surface" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "Threadline.Plug")
    assert String.contains?(readme, "Threadline.Audit.transaction")
    assert String.contains?(readme, "Threadline.record_action/2")
    assert String.contains?(readme, "Threadline.history/3")
    assert String.contains?(readme, "Threadline.timeline/2")
    assert String.contains?(readme, "Threadline.timeline_page/2")
    assert String.contains?(readme, "Threadline.incident_bundle/2")
    assert String.contains?(readme, "Threadline.export_json/2")
    assert String.contains?(readme, "Threadline.as_of/4")
  end

  test "NARR discovery docs agree on Audit.transaction/3 literal" do
    readme = File.read!("README.md")
    how = File.read!("guides/how-threadline-works.md")
    getting_started = File.read!("guides/getting-started-saas.md")

    for doc <- [readme, how, getting_started] do
      assert String.contains?(doc, "Threadline.Audit.transaction/3")
    end

    assert String.contains?(readme, "New Phoenix integrations should use")
  end

  test "README links domain reference guide" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "guides/domain-reference.md")
  end

  test "README links the public docs hubs for adopters and operators" do
    readme = File.read!("README.md")

    assert String.contains?(readme, "\"which public API first?\"")
    assert String.contains?(readme, "guides/how-threadline-works.md")
    assert String.contains?(readme, "guides/getting-started-saas.md")
    assert String.contains?(readme, "guides/domain-reference.md")
    assert String.contains?(readme, "guides/upgrade-path.md")

    assert String.contains?(
             readme,
             "canonical `capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, and `sigra-reference` matrix"
           )

    assert String.contains?(readme, "guides/integrations/phx-gen-auth.md")
    assert String.contains?(readme, "Phoenix auth (reference lanes, pick one)")
    refute String.contains?(readme, "Using Sigra:")

    assert String.contains?(readme, "guides/integrations/sigra.md")
    assert String.contains?(readme, "guides/performance.md")
    assert String.contains?(readme, "guides/incident-playbook.md")
  end

  test "README maps evaluators to evaluating-threadline guide (PILOT-02)" do
    readme = File.read!("README.md")

    assert String.contains?(readme, "guides/evaluating-threadline.md")

    start_section =
      readme
      |> String.split("## Start here", parts: 2)
      |> Enum.at(1, "")
      |> String.split("## Evidence plane", parts: 2)
      |> hd()

    assert String.contains?(start_section, "evaluating-threadline.md")
  end

  test "README keeps the evidence-plane claim strip compact and outward-linking" do
    # Hub refute (guides/evidence-plane.md) is centralized in SemverAdopterDocContractTest.
    readme = File.read!("README.md")

    assert String.contains?(readme, "## Evidence plane")
    assert String.contains?(readme, "guides/how-threadline-works.md")
    assert String.contains?(readme, "guides/upgrade-path.md")
    assert String.contains?(readme, "guides/domain-reference.md")
    assert String.contains?(readme, "host-owned")
    assert String.contains?(readme, "legal hold")
    assert String.contains?(readme, "immutable-storage")
    refute String.contains?(readme, "| Lane | Claim type |")
    refute String.contains?(readme, "mix threadline.evidence.show")
  end

  test "named doc-contract coverage reads the public domain reference guide directly" do
    guide = File.read!("guides/domain-reference.md")

    assert String.contains?(guide, "claim_assessment")
    assert String.contains?(guide, "proven")
    assert String.contains?(guide, "inferred_posture")
    assert String.contains?(guide, "unsupported")
  end

  test "README keeps the operator surface section as a short pointer" do
    readme = File.read!("README.md")

    assert String.contains?(readme, "## Operator Surface")
    assert String.contains?(readme, "canonical first-hour Phoenix walkthrough")
    assert String.contains?(readme, "guides/getting-started-saas.md")
    assert String.contains?(readme, "guides/operator-surface.md")
    assert String.contains?(readme, "current support claims, stay with")

    assert contains_normalized?(
             readme,
             "The Threadline UI currently ships as an optional in-tree dependency"
           )

    assert contains_normalized?(
             readme,
             "rather than inferring broader compatibility from the README"
           )

    refute String.contains?(readme, "http://localhost:4000/audit")
    refute String.contains?(readme, "**1-Minute Mount**")
    refute runnable_fence_contains?(readme, "threadline_operator_surface")
    refute runnable_fence_contains?(readme, "authorize_fn")
  end

  test "README operator support wording contract rejects a temporary mutation" do
    readme = File.read!("README.md")

    assert operator_support_wording?(readme)

    mutated =
      String.replace(
        readme,
        "current support claims, stay with",
        "current support claims, infer from"
      )

    refute operator_support_wording?(mutated)
  end

  test "README links production checklist guide" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "guides/production-checklist.md")
  end

  test "README links adoption pilot backlog guide" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "guides/adoption-pilot-backlog.md")
  end

  test "examples README indexes Phoenix reference app" do
    doc = File.read!("examples/README.md")

    assert String.contains?(
             doc,
             "The canonical Phoenix reference integration lives at **`examples/threadline_phoenix/`**."
           )

    assert String.contains?(doc, "[`threadline_phoenix/README.md`](threadline_phoenix/README.md)")
  end

  test "example README routes procedures to their canonical owners" do
    doc = File.read!("examples/threadline_phoenix/README.md")

    assert String.contains?(doc, "../../guides/getting-started-saas.md#1-prerequisites")
    assert String.contains?(doc, "../../guides/operator-surface.md#1-minute-mount")
    assert String.contains?(doc, "../../guides/local-docker-dx.md#try-the-ui-demo")
    refute String.contains?(doc, "mix threadline.install")
    refute String.contains?(doc, "mix threadline.gen.triggers")
    refute String.contains?(doc, "mix phx.server")
  end

  test "example README preserves historical-reconstruction proof outcomes" do
    doc = File.read!("examples/threadline_phoenix/README.md")

    assert String.contains?(doc, "Incident and historical investigation")
    assert String.contains?(doc, "domain reference")
    assert String.contains?(doc, ":deleted_record")
    assert String.contains?(doc, ":before_audit_horizon")
  end

  test "example README indexes maintainer proof without copying its runbook" do
    doc = File.read!("examples/threadline_phoenix/README.md")

    assert String.contains?(doc, "## Maintainer proof surfaces")
    assert String.contains?(doc, "DEMO-MANIFEST.md")
    assert String.contains?(doc, "DEMO_USERS.md")
    assert String.contains?(doc, "walkthrough_happy_path_test.exs")
    assert String.contains?(doc, "walkthrough_evidence_test.exs")
    assert String.contains?(doc, "track_a_golden_path_test.exs")
    assert String.contains?(doc, "adoption-evidence-playbook.md")
    refute String.contains?(doc, "mix demo.seed")
    refute String.contains?(doc, "mix demo.reset")
  end

  test "example README carries audited HTTP and correlation literals" do
    doc = File.read!("examples/threadline_phoenix/README.md")

    assert String.contains?(doc, "Threadline.Plug")
    assert String.contains?(doc, "Threadline.Audit.transaction")
    assert String.contains?(doc, "posts_audit_path_test.exs")
    assert String.contains?(doc, "posts_correlation_path_test.exs")
    assert String.contains?(doc, "../../guides/domain-reference.md")
    assert String.contains?(doc, "../../guides/production-checklist.md")
  end

  test "fixture calls match public README API shapes" do
    map = Threadline.ReadmeQuickstartFixtures.actor_ref_map_examples()
    assert map.anonymous["type"] == "anonymous"
    assert is_binary(Threadline.ReadmeQuickstartFixtures.jason_encode_actor_example())

    assert {:ok, _} = Threadline.ReadmeQuickstartFixtures.record_action_call(Repo)

    assert %Threadline.Query.TimelinePage{} =
             Threadline.ReadmeQuickstartFixtures.timeline_page_call(Repo)

    cov = Threadline.ReadmeQuickstartFixtures.trigger_coverage_call()
    assert is_list(cov)

    assert Enum.all?(
             cov,
             &match?({tag, _} when tag in [:covered, :uncovered, :expected_uncovered], &1)
           )
  end

  test "README Quick Start is package orientation that routes to the canonical owner" do
    readme = File.read!("README.md")
    slice = section_slice(readme, @quick_start_start, @quick_start_end)

    # Derived from `mix release.pins`, the designated sole writer of every
    # documented install pin, rather than hardcoded. A literal here goes red the
    # moment that writer does its job at a version bump — the born-red shape
    # Plan 202-09 removed from release_artifact_contract_test.exs (which carries
    # the full rationale) and the bump rehearsal found four more copies of.
    assert String.contains?(
             slice,
             ~s({:threadline, "~> #{Mix.Tasks.Release.Pins.target_pin_version()}"})
           )

    assert String.contains?(slice, "guides/getting-started-saas.md")
    assert String.contains?(slice, "guides/configuration-and-commands.md")
    refute String.contains?(slice, "config :threadline")
    refute String.contains?(slice, "mix threadline.install")
    refute String.contains?(slice, "mix threadline.gen.triggers")
  end

  test "README leaves configuration and migration timing to its canonical guides" do
    readme = File.read!("README.md")
    slice = section_slice(readme, @quick_start_start, @quick_start_end)
    getting_started = File.read!("guides/getting-started-saas.md")
    reference = File.read!("guides/configuration-and-commands.md")

    refute String.contains?(slice, "storage_schema")
    # "threadline", not "audit" — see 202 D-01/D-02.
    assert String.contains?(getting_started, ~S|storage_schema: "threadline"|)
    assert String.contains?(getting_started, "before you run `mix threadline.install`")
    assert String.contains?(reference, "config :threadline, storage_schema:")
  end

  test "README Quick Start cannot grow a second ordered setup procedure" do
    readme = File.read!("README.md")
    slice = section_slice(readme, @quick_start_start, @quick_start_end)

    refute Regex.match?(~r/^\s*\d+\.\s+/m, slice)
    refute Regex.match?(~r/```(?:bash|sh|elixir)[\s\S]*?mix\s+(?:threadline\.|ecto\.)/m, slice)
  end

  defp contains_normalized?(doc, snippet) do
    String.contains?(normalize(doc), normalize(snippet))
  end

  defp runnable_fence_contains?(content, needle) do
    Regex.scan(~r/```(?:bash|sh|elixir)\s*\n([\s\S]*?)```/m, content, capture: :all_but_first)
    |> Enum.any?(fn [body] -> String.contains?(body, needle) end)
  end

  defp operator_support_wording?(doc) do
    String.contains?(doc, "current support claims, stay with") and
      contains_normalized?(doc, "rather than inferring broader compatibility from the README")
  end

  defp normalize(value) do
    value
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end

  defp section_slice(doc, start_heading, end_heading) do
    doc
    |> String.split(start_heading, parts: 2)
    |> case do
      [_, rest] ->
        rest
        |> String.split(end_heading, parts: 2)
        |> List.first()

      _ ->
        flunk("section starting with #{start_heading} not found")
    end
  end
end
