defmodule Threadline.ReadmeDocContractTest do
  @moduledoc false
  use Threadline.DataCase

  alias Threadline.Test.Repo

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
             "canonical `capture-only`, `phoenix-surface`, and `sigra-reference` matrix"
           )

    assert String.contains?(readme, "guides/integrations/sigra.md")
    assert String.contains?(readme, "guides/performance.md")
    assert String.contains?(readme, "guides/incident-playbook.md")
  end

  test "README keeps the evidence-plane claim strip compact and outward-linking" do
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
    assert String.contains?(readme, "**1-Minute Mount**")
    assert contains_normalized?(readme, readme_mount_block())
    assert String.contains?(readme, "canonical first-hour Phoenix walkthrough")
    assert String.contains?(readme, "guides/getting-started-saas.md")
    assert String.contains?(readme, "guides/operator-surface.md")
    assert String.contains?(readme, "current support claims, stay with")
    assert String.contains?(readme, "stays in-tree for now")

    assert contains_normalized?(
             readme,
             "rather than inferring broader compatibility from the README"
           )

    refute String.contains?(readme, "http://localhost:4000/audit")
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

  test "example README carries runbook literals for REF-01" do
    doc = File.read!("examples/threadline_phoenix/README.md")

    assert String.contains?(doc, "mix threadline.install")
    assert String.contains?(doc, "mix threadline.gen.triggers")

    assert String.contains?(doc, "mix phx.server") or
             String.contains?(doc, "iex -S mix phx.server")

    assert String.contains?(doc, "mix test")
    assert String.contains?(doc, "ecto.migrate")
  end

  test "example README carries historical reconstruction walkthrough literals" do
    doc = File.read!("examples/threadline_phoenix/README.md")

    assert String.contains?(doc, "Historical reconstruction walkthrough")
    assert String.contains?(doc, "ThreadlinePhoenix.Post")
    assert String.contains?(doc, "as_of/4")
    assert String.contains?(doc, "cast: true")
    assert String.contains?(doc, ":deleted_record")
    assert String.contains?(doc, ":before_audit_horizon")
  end

  test "example README documents demo seed and reset tasks" do
    doc = File.read!("examples/threadline_phoenix/README.md")

    assert String.contains?(doc, "## Demo walkthrough data")
    assert String.contains?(doc, "mix demo.seed")
    assert String.contains?(doc, "mix demo.reset")
    assert String.contains?(doc, "DEMO-MANIFEST.md")
    assert String.contains?(doc, "DEMO_USERS.md")
    assert String.contains?(doc, "does **not** run `demo.seed` automatically")
  end

  test "example README carries audited HTTP and correlation literals" do
    doc = File.read!("examples/threadline_phoenix/README.md")

    assert String.contains?(doc, "Threadline.Plug")
    assert String.contains?(doc, "Threadline.Audit.transaction")
    assert String.contains?(doc, "Threadline.record_action/2")
    assert String.contains?(doc, "Threadline.timeline/2")
    assert String.contains?(doc, "Threadline.export_json/2")
    assert String.contains?(doc, "guides/domain-reference.md")
    assert String.contains?(doc, "guides/production-checklist.md")
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

  defp readme_mount_block do
    """
    scope "/audit", MyAppWeb do
      pipe_through [:browser, :require_authenticated_admin]

      threadline_operator_surface "/",
        actor_fn: &MyApp.Audit.current_actor/1,
        authorize_fn: &MyApp.Audit.authorize_operator/1
    end
    """
  end

  defp contains_normalized?(doc, snippet) do
    String.contains?(normalize(doc), normalize(snippet))
  end

  defp normalize(value) do
    value
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end
end
