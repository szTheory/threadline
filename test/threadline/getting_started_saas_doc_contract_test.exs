defmodule Threadline.GettingStartedSaasDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.GettingStartedFixtures

  @repo_root File.cwd!()
  @guide_path ["guides", "getting-started-saas.md"]

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "quickstart guide locks the adopter walkthrough" do
    doc = read_rel!(@guide_path)

    headings = [
      "## 1. Prerequisites",
      "## 2. Add Threadline to your app",
      "## 3. Install the audit schema",
      "## 4. Generate triggers for posts",
      "## 5. Wire `Threadline.Plug` with actor and additive request metadata",
      "## 6. Exercise the first audited write",
      "## 7. Check trigger coverage",
      "## 8. Investigate the captured timeline",
      "## 9. Mount the operator surface and open `/audit`"
    ]

    Enum.each(headings, &assert(String.contains?(doc, &1)))
    assert String.contains?(doc, "phoenixframework.org")
    assert String.contains?(doc, "how-threadline-works.md")
    assert String.contains?(doc, "mix threadline.gen.triggers --tables posts")
    assert String.contains?(doc, "{:threadline, \"~> 0.6\"}")
    refute String.contains?(doc, "{:threadline, \"~> 0.5\"}")
    assert String.contains?(doc, "{:covered, _}")
    assert String.contains?(doc, "mix threadline.health.coverage")
    assert String.contains?(doc, "guides/integrations/phx-gen-auth.md")
    assert String.contains?(doc, "actor_fn: &MyApp.Audit.actor_ref_from_conn/1")
    refute String.contains?(doc, "The Phoenix example keeps")
    assert String.contains?(doc, blog_block())
    refute String.contains?(doc, "Legacy manual recipe")
    assert String.contains?(blog_block(), "Threadline.Audit.transaction")
    assert String.contains?(doc, "`actor_fn` remains the only actor-authority path")
    assert String.contains?(doc, "additive `request_id` and `correlation_id` metadata only")
    assert String.contains?(doc, "Explicit `x-request-id`, explicit")
    assert String.contains?(doc, "raises `ArgumentError`")
    assert String.contains?(doc, "timeline = Threadline.timeline(filters)")
    assert String.contains?(doc, "first_page = Threadline.timeline_page(filters, page_size: 100)")
    assert contains_normalized?(doc, mount_block())
    assert String.contains?(doc, "evidence_authorize_fn")
    assert String.contains?(doc, "my_evidence_authorize_fn")
    assert String.contains?(doc, "visit `http://localhost:4000/audit`")
    assert String.contains?(doc, "coverage dashboard")
    assert String.contains?(doc, "read-only redaction")
    assert String.contains?(doc, "mix threadline.incident")
    assert String.contains?(doc, "mix threadline.export --dry-run")
    assert String.contains?(doc, "appends those exact flags")
    assert String.contains?(doc, "mix threadline.policy.show")
    assert String.contains?(doc, "Threadline.actor_history/2")
    assert String.contains?(doc, "Threadline.history/3")
    assert String.contains?(doc, "capture-only path for now")
    assert String.contains?(doc, "temporary branch rather than")
    assert String.contains?(doc, "the main first-hour adoption story")
    assert String.contains?(doc, "`guides/upgrade-path.md`")
    assert String.contains?(doc, "`guides/integrations/sigra.md`")

    assert String.contains?(doc, "### HTTP requests and host auth")

    assert String.contains?(
             doc,
             "{:ok, bundle} = Threadline.incident_bundle(audit_transaction_id, repo: MyApp.Repo)"
           )

    assert String.contains?(doc, "`Threadline.timeline_page/2` is the same investigation path")

    assert String.contains?(
             doc,
             "Threadline.as_of(MyApp.Post, post_id, as_of_at, repo: MyApp.Repo)"
           )

    assert String.contains?(doc, "requires an authenticated actor before it serves")
    assert String.contains?(doc, "incident drill-down: auth is included")
    assert String.contains?(doc, "tenancy rules still belong to the")
    assert String.contains?(doc, "host app")
    assert String.contains?(doc, "support operators return an opaque host-owned scope")
    assert String.contains?(doc, "export_authorize_fn")
    assert String.contains?(doc, "`scope_query_fn` narrows timeline, actor, transaction,")
    assert String.contains?(doc, "row-history, and as-of queries to that scope")
    assert String.contains?(doc, "Treat row history and")
    assert String.contains?(doc, "point-in-time reconstruction as mounted")
    assert String.contains?(doc, "plain-text `403`")
    assert String.contains?(doc, "%{assigns: assigns}")
    assert String.contains?(doc, "policy_authorize_fn")
    assert String.contains?(doc, "Threadline.audit_changes_for_transaction/2")
    assert String.contains?(doc, "Threadline.transaction_context/2")
    assert String.contains?(doc, "Threadline.change_diff/2")
  end

  test "getting-started §6 locks IEx-first audited write and demo-corr handoff (DOC-01)" do
    doc = read_rel!(@guide_path)

    assert String.contains?(doc, "### Run your first audited write in IEx")
    assert String.contains?(doc, "### HTTP requests and host auth")
    refute String.contains?(doc, "### Authenticate before the audited API call")

    section_6 =
      section_slice(doc, "## 6. Exercise the first audited write", "## 7. Check trigger coverage")

    assert String.contains?(section_6, "demo-corr")
    assert String.contains?(section_6, "audit_transaction_id")

    open_section_6 =
      section_6
      |> String.split("<details>", parts: 2)
      |> List.first()

    refute String.contains?(open_section_6, "_threadline_phoenix_key")

    assert String.contains?(section_6, "getting-started-sigra-http-staging-fence")

    {fence_idx, _} = :binary.match(section_6, "getting-started-sigra-http-staging-fence")
    {key_idx, _} = :binary.match(section_6, "_threadline_phoenix_key")

    assert fence_idx < key_idx
  end

  test "getting-started §5 locks auth-neutral ADOPT-AUTH literals (DOC-02)" do
    doc = read_rel!(@guide_path)

    section_5 =
      section_slice(
        doc,
        "## 5. Wire `Threadline.Plug` with actor and additive request metadata",
        "## 6. Exercise the first audited write"
      )

    literals = [
      "Threadline does not own auth",
      "Choose an auth lane when you need a full cookbook:",
      "phx-gen-auth-reference",
      "sigra-reference",
      "Threadline does not require Sigra; do not use `Threadline.Integrations.Sigra`",
      "unless you adopt the optional sigra-reference lane."
    ]

    Enum.each(literals, fn literal ->
      assert String.contains?(section_5, literal)
    end)

    {section_5_idx, _} =
      :binary.match(doc, "## 5. Wire `Threadline.Plug` with actor and additive request metadata")

    {section_6_idx, _} = :binary.match(doc, "## 6. Exercise the first audited write")

    {neutrality_idx, _} = :binary.match(doc, "Threadline does not require Sigra")

    assert section_5_idx < neutrality_idx
    assert neutrality_idx < section_6_idx

    {phx_idx, _} = :binary.match(doc, "phx-gen-auth-reference")
    {sigra_idx, _} = :binary.match(doc, "sigra-reference")

    assert phx_idx < sigra_idx

    {fence_idx, _} = :binary.match(doc, "getting-started-sigra-reference-fence")

    {sigra_actor_idx, _} =
      :binary.match(doc, "Threadline.Integrations.Sigra.actor_ref_from_conn/1")

    assert neutrality_idx < fence_idx
    assert fence_idx < sigra_actor_idx
  end

  test "getting-started documents threadline ecto_repos before resolve_repo consumers" do
    doc = read_rel!(@guide_path)

    literal =
      ~r/config :threadline,\s+ecto_repos: \[MyApp\.Repo\],\s+storage_schema: "threadline"/

    assert String.contains?(doc, "### Configure Threadline")

    # ExDoc proxy: getting-started-saas.md#configure-threadline from locked heading (CFG-01 / D-11)
    assert doc =~ literal

    {literal_idx, _} = Regex.run(literal, doc, return: :index) |> hd()
    {section_7_idx, _} = :binary.match(doc, "## 7. Check trigger coverage")
    {section_3_idx, _} = :binary.match(doc, "## 3. Install the audit schema")
    {sigra_fence_idx, _} = :binary.match(doc, "getting-started-sigra-reference-fence")

    assert literal_idx < section_7_idx
    assert literal_idx < sigra_fence_idx
    assert literal_idx < section_3_idx

    assert String.contains?(doc, "Mix tasks")
    assert String.contains?(doc, "ecto_repos")
  end

  test "getting-started optional sigra-reference fence is scoped" do
    doc = read_rel!(@guide_path)

    assert String.contains?(doc, "getting-started-sigra-reference-fence")

    marker = "getting-started-sigra-reference-fence"
    [_before, after_marker] = String.split(doc, marker, parts: 2)
    subsection = after_marker

    assert String.contains?(subsection, router_block())
    refute String.contains?(subsection, "MyApp.Audit.actor_ref_from_conn")

    {generic_idx, _} =
      :binary.match(doc, "actor_fn: &MyApp.Audit.actor_ref_from_conn/1")

    {marker_idx, _} = :binary.match(doc, marker)

    {sigra_idx, _} =
      :binary.match(doc, "Threadline.Integrations.Sigra.actor_ref_from_conn/1")

    assert generic_idx < marker_idx
    assert marker_idx < sigra_idx
  end

  test "quickstart closing pointers stay in-repo and present" do
    doc = read_rel!(@guide_path)

    pointers = [
      "guides/production-checklist.md",
      "guides/incident-playbook.md",
      "guides/performance.md",
      "guides/integrations/phx-gen-auth.md",
      "guides/integrations/sigra.md",
      "guides/brownfield-continuity.md",
      "guides/adoption-pilot-backlog.md"
    ]

    Enum.each(pointers, fn path ->
      assert String.contains?(doc, path)
      assert File.exists?(Path.join(@repo_root, path))
    end)
  end

  test "mix docs extras includes the SaaS quickstart" do
    mix_exs = read_rel!(["mix.exs"])
    assert String.contains?(mix_exs, "\"guides/getting-started-saas.md\"")
    assert String.contains?(mix_exs, "\"guides/incident-playbook.md\"")
  end

  defp router_block do
    GettingStartedFixtures.extract!(
      "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex",
      "router-pipeline-actor-fn"
    )
  end

  defp blog_block do
    GettingStartedFixtures.extract!(
      "examples/threadline_phoenix/lib/threadline_phoenix/blog.ex",
      "blog-create-post-transaction"
    )
  end

  defp mount_block do
    GettingStartedFixtures.extract!(
      "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex",
      "operator-surface-mount"
    )
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
