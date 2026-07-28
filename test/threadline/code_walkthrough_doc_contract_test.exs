defmodule Threadline.CodeWalkthroughDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @architecture_path "guides/how-threadline-works.md"
  @walkthrough_path "guides/code-walkthrough.md"

  @source_anchors %{
    "lib/threadline/storage_schema.ex" => [
      "Application.get_env(:threadline, :storage_schema, @default)"
    ],
    "lib/mix/tasks/threadline.gen.triggers.ex" => [
      "StorageSchema.threadline_table?"
    ],
    "lib/threadline/capture/trigger_sql.ex" => [
      "v_txid := txid_current();"
    ],
    "lib/threadline/plug.ex" => [
      "assign(conn, :audit_context, context)"
    ],
    "lib/threadline/audit.ex" => [
      ~S|repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])|
    ],
    "lib/threadline/query.ex" => [
      "on: at.action_id == aa.id and aa.correlation_id == ^cid"
    ],
    "lib/threadline/investigation.ex" => [
      "Threadline.change_diff(linked_change.audit_change)"
    ],
    "lib/threadline/operator_surface/scope.ex" => [
      "scope_query_fn.(query, scope, context)"
    ],
    "lib/threadline/export/orchestrator.ex" => [
      "storage.put(temp_path)"
    ]
  }

  test "walkthrough has a bounded set of parseable Elixir excerpts" do
    blocks = elixir_blocks(File.read!(@walkthrough_path))

    assert length(blocks) in 12..18
    assert length(blocks) == 17

    Enum.with_index(blocks, 1)
    |> Enum.each(fn {block, index} ->
      assert {:ok, _ast} = Code.string_to_quoted(block), "Elixir excerpt #{index} does not parse"
    end)

    assert Enum.count(blocks, &String.contains?(&1, "# ...")) >= 12
  end

  test "walkthrough source anchors still exist in both guide and implementation" do
    guide = File.read!(@walkthrough_path) |> normalize_whitespace()

    Enum.each(@source_anchors, fn {path, anchors} ->
      source = File.read!(path) |> normalize_whitespace()

      Enum.each(anchors, fn anchor ->
        normalized = normalize_whitespace(anchor)
        assert String.contains?(source, normalized), "source anchor drifted in #{path}: #{anchor}"
        assert String.contains?(guide, normalized), "walkthrough lost source anchor: #{anchor}"
      end)
    end)
  end

  test "walkthrough marks support boundaries and avoids brittle links" do
    guides = File.read!(@architecture_path) <> "\n" <> File.read!(@walkthrough_path)

    assert String.contains?(guides, "Public API versus internals")
    assert String.contains?(guides, "Reachability is not a support promise")

    refute Regex.match?(~r{/(?:Users|home)/}, guides)
    refute String.contains?(guides, "file://")
    refute Regex.match?(~r{https://github\.com/[^\s)]+/blob/}, guides)
    refute Regex.match?(~r{#L\d+}, guides)
  end

  test "architecture and walkthrough cross-link and occupy the Evaluate lane" do
    project = Threadline.MixProject.project()
    docs = project[:docs]
    extras = docs[:extras]
    groups = docs[:groups_for_extras]
    architecture = File.read!(@architecture_path)
    walkthrough = File.read!(@walkthrough_path)
    readme = File.read!("README.md")

    assert String.contains?(architecture, "[Code walkthrough](code-walkthrough.md)")
    assert String.contains?(walkthrough, "[How Threadline works](how-threadline-works.md)")

    architecture_index = Enum.find_index(extras, &(&1 == @architecture_path))
    assert Enum.at(extras, architecture_index + 1) == @walkthrough_path

    evaluate_pattern = Keyword.fetch!(groups, :Evaluate)
    assert Regex.match?(evaluate_pattern, @architecture_path)
    assert Regex.match?(evaluate_pattern, @walkthrough_path)

    assert Keyword.keys(groups) == [
             :Overview,
             :Integrations,
             :Evaluate,
             :Adopt,
             :Operate,
             :Contribute
           ]

    {readme_architecture, _} = :binary.match(readme, @architecture_path)
    {readme_walkthrough, _} = :binary.match(readme, @walkthrough_path)
    assert readme_architecture < readme_walkthrough
  end

  test "README keeps the four canonical Start here routes" do
    start_here =
      File.read!("README.md")
      |> String.split("## Start here", parts: 2)
      |> Enum.at(1, "")
      |> String.split("## Evidence plane", parts: 2)
      |> hd()

    labels =
      Regex.scan(~r/^\| \*\*(Evaluate|Adopt|Operate|Contribute)\*\*/m, start_here,
        capture: :all_but_first
      )
      |> List.flatten()

    assert labels == ["Evaluate", "Adopt", "Operate", "Contribute"]
    assert String.contains?(start_here, "guides/evaluating-threadline.md")
    assert String.contains?(start_here, "guides/getting-started-saas.md")
    assert String.contains?(start_here, "guides/operator-surface.md")
    assert String.contains?(start_here, "CONTRIBUTING.md")
  end

  test "ExDoc Mermaid hook is pinned, secure, theme-aware, and failure-readable" do
    docs = Threadline.MixProject.project()[:docs]
    head_hook = docs[:before_closing_head_tag]
    body_hook = docs[:before_closing_body_tag]
    head = head_hook.(:html)
    body = body_hook.(:html)

    assert String.contains?(head, ".threadline-mermaid")
    assert String.contains?(head, "overflow-x: auto")
    assert String.contains?(head, "body.dark")

    assert String.contains?(body, "mermaid@11.16.0/dist/mermaid.min.js")

    assert String.contains?(
             body,
             "sha384-T/0lMUdJpd2S1ZHtRiofG3htU3xPCrFVeAQ1UUE2TJwlEJSV5NUwn30kP28n238E"
           )

    assert String.contains?(body, "crossorigin=\"anonymous\"")
    assert String.contains?(body, "securityLevel: \"strict\"")
    assert String.contains?(body, "startOnLoad: false")
    assert String.contains?(body, "window.addEventListener(\"exdoc:loaded\"")
    assert String.contains?(body, "document.body.classList.contains(\"dark\")")
    assert String.contains?(body, "theme === \"dark\"")
    assert String.contains?(body, "new MutationObserver")
    assert String.contains?(body, "sourceBlock.hidden = false")
    assert String.contains?(body, "sourceBlock.hidden = true")
    assert String.contains?(body, "console.warn")
    assert head_hook.(:epub) == ""
    assert body_hook.(:epub) == ""
  end

  test "ExDoc uses the packaged Threadline favicon" do
    project = Threadline.MixProject.project()
    favicon = project[:docs][:favicon]

    assert favicon == "brandbook/favicon.svg"
    assert File.exists?(favicon)
    assert favicon in project[:package][:files]

    svg = File.read!(favicon)
    assert String.contains?(svg, "aria-label=\"Threadline\"")
    assert String.contains?(svg, "prefers-color-scheme: dark")
  end

  defp elixir_blocks(doc) do
    Regex.scan(~r/```elixir\n(.*?)```/s, doc, capture: :all_but_first)
    |> List.flatten()
  end

  defp normalize_whitespace(value) do
    value
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
