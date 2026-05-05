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
      "## 8. Investigate the captured timeline"
    ]

    Enum.each(headings, &assert(String.contains?(doc, &1)))
    assert String.contains?(doc, "phoenixframework.org")
    assert String.contains?(doc, "mix threadline.gen.triggers --tables posts")
    assert String.contains?(doc, "{:threadline, \"~> 0.3\"}")
    assert String.contains?(doc, "{:covered, _}")
    assert String.contains?(doc, router_block())
    assert String.contains?(doc, blog_block())
    assert String.contains?(doc, "`actor_fn` remains the only actor-authority path")
    assert String.contains?(doc, "additive `request_id` and `correlation_id` metadata only")
    assert String.contains?(doc, "Explicit `x-request-id`, explicit")
    assert String.contains?(doc, "raises `ArgumentError`")
    assert String.contains?(doc, "timeline = Threadline.timeline(filters)")
    assert String.contains?(doc, "Threadline.as_of(MyApp.Post, post_id, as_of_at, repo: MyApp.Repo)")
    assert String.contains?(doc, "requires an authenticated actor before it serves")
    assert String.contains?(doc, "incident drill-down: auth is included")
    assert String.contains?(doc, "tenancy rules still belong to the")
    assert String.contains?(doc, "host app")
  end

  test "quickstart closing pointers stay in-repo and present" do
    doc = read_rel!(@guide_path)

    pointers = [
      "guides/production-checklist.md",
      "guides/incident-playbook.md",
      "guides/performance.md",
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
end
