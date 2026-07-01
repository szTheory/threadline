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
    assert String.contains?(readme, "**1-Minute Mount**")
    assert contains_normalized?(readme, readme_mount_block())
    assert String.contains?(readme, "canonical first-hour Phoenix walkthrough")
    assert String.contains?(readme, "guides/getting-started-saas.md")
    assert String.contains?(readme, "guides/operator-surface.md")
    assert String.contains?(readme, "current support claims, stay with")
    # assert String.contains?(readme, "stays in-tree for now")

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
    assert String.contains?(doc, "`mix ecto.reset` is schema/trigger recovery only")
    assert String.contains?(doc, "`mix demo.reset` for the daily walkthrough loop")
    assert String.contains?(doc, "Mix task ownership")
    assert String.contains?(doc, "neutral")
    assert String.contains?(doc, "walkthrough fiction")
    assert String.contains?(doc, "skip generators on a normal clean clone")
    assert String.contains?(doc, "## Choose your path")
    assert String.contains?(doc, "## Base install (all paths)")
    assert String.contains?(doc, "### Tour in five minutes")
    assert String.contains?(doc, "walkthrough_happy_path_test.exs")
    assert String.contains?(doc, "walkthrough_evidence_test.exs")
    assert String.contains?(doc, "track_a_golden_path_test.exs")
    assert String.contains?(doc, "mix verify.example_browser")
    assert String.contains?(doc, "adoption-evidence-playbook.md")
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

  test "README Quick Start locks Threadline ecto_repos and storage schema ordering" do
    readme = File.read!("README.md")
    slice = section_slice(readme, @quick_start_start, @quick_start_end)

    literal =
      ~r/config :threadline,\s+ecto_repos: \[MyApp\.Repo\],\s+storage_schema: "audit"/

    assert slice =~ literal
    assert String.contains?(slice, "getting-started-saas.md#configure-threadline")

    {literal_idx, _} = Regex.run(literal, slice, return: :index) |> hd()
    {install_idx, _} = :binary.match(slice, "mix threadline.install")

    assert literal_idx < install_idx
  end

  test "README Quick Start documents custom storage schema generation timing" do
    readme = File.read!("README.md")
    slice = section_slice(readme, @quick_start_start, @quick_start_end)

    assert String.contains?(slice, ~S|storage_schema: "audit"|)
    assert String.contains?(slice, "before you run `mix threadline.install`")

    assert String.contains?(
             slice,
             "Generated migration files carry the configured storage schema name"
           )

    assert String.contains?(
             slice,
             "Changing `storage_schema` later does not rewrite existing migration files"
           )

    assert String.contains?(
             slice,
             "Threadline storage schema is separate from audited host-table schema"
           )

    assert String.contains?(
             slice,
             "Host tables can still live in `public`, `support`, or another app schema"
           )

    {audit_idx, _} = :binary.match(slice, ~S|storage_schema: "audit"|)
    {install_idx, _} = :binary.match(slice, "mix threadline.install")

    assert audit_idx < install_idx
    refute String.contains?(slice, "set `storage_schema` after `mix threadline.install`")
  end

  test "README Quick Start locks posts-only trigger step and SSOT cross-links" do
    readme = File.read!("README.md")
    slice = section_slice(readme, @quick_start_start, @quick_start_end)

    assert String.contains?(slice, "mix threadline.gen.triggers --tables posts")
    assert String.contains?(slice, "getting-started-saas.md")
    assert String.contains?(slice, "production-checklist.md")

    refute String.contains?(slice, "users,posts,comments")
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
