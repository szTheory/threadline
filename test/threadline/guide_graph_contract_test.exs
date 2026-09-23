defmodule Threadline.GuideGraphContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @lanes %{
    evaluate: [
      "guides/evaluating-threadline.md",
      "guides/how-threadline-works.md",
      "guides/code-walkthrough.md",
      "guides/domain-reference.md"
    ],
    adopt: [
      "guides/getting-started-saas.md",
      "guides/production-checklist.md",
      "guides/brownfield-continuity.md",
      "guides/integration-contracts.md",
      "guides/local-docker-dx.md",
      "guides/upgrade-path.md",
      "guides/integrations/sigra.md",
      "guides/integrations/phx-gen-auth.md"
    ],
    operate: [
      "guides/operator-surface.md",
      "guides/incident-playbook.md",
      "guides/performance.md",
      "guides/audit-indexing.md",
      "guides/adoption-evidence-playbook.md"
    ],
    contribute: ["guides/adoption-pilot-backlog.md"]
  }

  @landings %{
    evaluate: "guides/evaluating-threadline.md",
    adopt: "guides/getting-started-saas.md",
    operate: "guides/operator-surface.md",
    contribute: "CONTRIBUTING.md"
  }

  @evaluate_owner_slice [
    "guides/adoption-evidence-playbook.md",
    "guides/adoption-pilot-backlog.md",
    "guides/brownfield-continuity.md",
    "guides/domain-reference.md",
    "guides/evaluating-threadline.md"
  ]

  @architecture_owner_slice [
    "guides/code-walkthrough.md",
    "guides/how-threadline-works.md"
  ]

  test "the Markdown resolver reports missing paths and normalized anchors" do
    files = %{
      "guides/source.md" => "# Source\n[valid](target.md#target-heading)\n[bad](missing.md)",
      "guides/target.md" => "# Target heading\n"
    }

    assert validate_links("guides/source.md", files["guides/source.md"], files) == [
             {:missing_path, "guides/source.md", "missing.md", "guides/missing.md"}
           ]

    bad_anchor = String.replace(files["guides/source.md"], "#target-heading", "#absent")

    assert {:missing_anchor, "guides/source.md", "target.md#absent", "absent"} in validate_links(
             "guides/source.md",
             bad_anchor,
             files
           )
  end

  test "lane assignment is exact, disjoint, nonempty, and sentinel-backed" do
    assigned = Map.values(@lanes) |> List.flatten()
    assert Enum.all?(@lanes, fn {_lane, paths} -> paths != [] end)
    assert length(assigned) == 18

    assert length(assigned) == MapSet.size(MapSet.new(assigned)),
           "guide belongs to multiple lanes"

    assert "guides/evaluating-threadline.md" in assigned
    assert "guides/getting-started-saas.md" in assigned
    assert "guides/operator-surface.md" in assigned

    configured =
      Threadline.MixProject.project()[:docs][:extras]
      |> Enum.filter(&(is_binary(&1) and String.starts_with?(&1, "guides/")))
      |> MapSet.new()

    on_disk = Path.wildcard("guides/**/*.md") |> MapSet.new()
    assert configured == on_disk, "all local guides must be explicit ExDoc extras"

    outside = MapSet.difference(on_disk, MapSet.new(assigned))
    assert outside in [MapSet.new(), MapSet.new(["guides/configuration-and-commands.md"])]
  end

  @tag :canonical_owners
  @tag :phase200_red
  test "the canonical config reference is the sole local guide outside the graph" do
    assigned = Map.values(@lanes) |> List.flatten() |> MapSet.new()
    outside = Path.wildcard("guides/**/*.md") |> MapSet.new() |> MapSet.difference(assigned)

    assert outside == MapSet.new(["guides/configuration-and-commands.md"]),
           "the canonical config reference must be the only guide outside the 18-node graph"
  end

  @tag :canonical_owner_tracer
  @tag :phase200_red
  test "installation and first-hour commands live only in Getting Started" do
    callers = ["README.md", "examples/threadline_phoenix/README.md"]

    assert sole_sequence_owner(
             "mix threadline.install",
             "guides/getting-started-saas.md",
             callers
           )

    assert sole_sequence_owner(
             "mix threadline.gen.triggers",
             "guides/getting-started-saas.md",
             callers
           )
  end

  @tag :operator_owner_tracer
  @tag :phase200_red
  test "mounting and authorization procedures live only in Operator Surface" do
    owner = "guides/operator-surface.md"

    routed_references = [
      "README.md",
      "guides/configuration-and-commands.md",
      "examples/threadline_phoenix/README.md"
    ]

    assert sole_sequence_owner("threadline_operator_surface", owner, routed_references)
    assert sole_sequence_owner("authorize_fn", owner, routed_references)

    content = File.read!(owner)

    assert link_target?(owner, content, "guides/configuration-and-commands.md"),
           "the Operate landing must reach the canonical configuration reference"
  end

  @tag :canonical_owners
  @tag :phase200_red
  test "Docker lifecycle commands live only in the Docker guide" do
    owner = "guides/local-docker-dx.md"

    routed_references = [
      "examples/threadline_phoenix/README.md",
      "guides/audit-indexing.md",
      "guides/incident-playbook.md",
      "guides/operator-surface.md",
      "guides/performance.md",
      "guides/production-checklist.md",
      "guides/upgrade-path.md"
    ]

    assert sole_sequence_owner("docker compose up", owner, routed_references)
    assert sole_sequence_owner("docker compose down", owner, routed_references)
  end

  @tag :guide_graph_evaluate
  @tag :phase200_red
  test "the evaluation and adoption-planning owners have valid graph contracts" do
    assert_graph_nodes!(@evaluate_owner_slice)
  end

  @tag :guide_graph_architecture
  @tag :phase200_red
  test "the architecture owners have valid graph contracts" do
    assert_graph_nodes!(@architecture_owner_slice)
  end

  @tag :guide_graph
  @tag :phase200_red
  @tag :phase200_aggregate
  test "all 18 guides form one complete intent-led graph" do
    Enum.each(Map.keys(@lanes), &assert_graph_slice!/1)
  end

  defp assert_graph_slice!(lane) do
    assert_graph_nodes!(Map.fetch!(@lanes, lane))
  end

  defp assert_graph_nodes!(nodes) do
    files = public_markdown_files()
    assert nodes != []

    edges = markdown_edges(files)

    for node <- nodes do
      lanes = for {lane, paths} <- @lanes, node in paths, do: lane
      assert [lane] = lanes, "#{node} must belong to exactly one intent lane"

      landing = Map.fetch!(@landings, lane)
      errors = validate_links(node, Map.fetch!(files, node), files)
      assert errors == [], "#{node} has broken Markdown links: #{inspect(errors)}"

      inbound =
        for {source, targets} <- edges, node in targets and source != "README.md", do: source

      outbound = Map.get(edges, node, [])
      assert inbound != [], "#{node} has no non-README inbound guide edge"
      assert outbound != [], "#{node} has no outbound guide edge"

      if node != landing do
        assert link_target?(landing, Map.fetch!(files, landing), node),
               "#{landing} does not route its #{lane} lane to #{node}"

        content = Map.fetch!(files, node)

        assert Regex.match?(~r/^## Next steps\s*$/mi, content),
               "#{node} lacks a terminal Next steps section"

        next_steps = content |> String.split(~r/^## Next steps\s*$/mi, parts: 2) |> List.last()

        assert link_target?(node, next_steps, landing),
               "#{node} Next steps does not return to its lane landing"

        next_targets =
          next_steps
          |> markdown_links()
          # Structural debt: resolve fn inside if inside the per-node loop — extract next-step target resolution
          # credo:disable-for-next-line Credo.Check.Refactor.Nesting
          |> Enum.map(fn {_label, target} -> resolved_path(node, target) end)
          |> Enum.reject(&is_nil/1)

        distinct = Enum.reject(next_targets, &(&1 in [node, landing]))
        assert distinct != [], "#{node} Next steps lacks a distinct task-adjacent successor"
      end
    end
  end

  defp public_markdown_files do
    ([
       "README.md",
       "CONTRIBUTING.md",
       "CHANGELOG.md",
       "DESIGN-SYSTEM.md",
       "examples/threadline_phoenix/README.md"
     ] ++ Path.wildcard("guides/**/*.md"))
    |> Map.new(&{&1, File.read!(&1)})
  end

  defp markdown_edges(files) do
    Map.new(files, fn {source, content} ->
      targets =
        content
        |> markdown_links()
        |> Enum.map(fn {_label, target} -> resolved_path(source, target) end)
        |> Enum.reject(&is_nil/1)
        |> Enum.filter(&Map.has_key?(files, &1))
        |> Enum.uniq()

      {source, targets}
    end)
  end

  defp validate_links(source, content, files) do
    for {_label, target} <- markdown_links(content),
        error <- validate_link(source, target, files),
        do: error
  end

  defp validate_link(source, target, files) do
    if external_or_asset?(target) do
      []
    else
      [raw_path, anchor] = split_target(target)
      path = if raw_path == "", do: source, else: resolved_path(source, raw_path)

      cond do
        not Map.has_key?(files, path) ->
          [{:missing_path, source, target, path}]

        anchor != nil and anchor not in heading_anchors(Map.fetch!(files, path)) ->
          [{:missing_anchor, source, target, anchor}]

        true ->
          []
      end
    end
  end

  defp markdown_links(content) do
    Regex.scan(~r/(?<!!)\[([^\]]+)\]\(([^\s)]+)(?:\s+"[^"]*")?\)/, content)
    |> Enum.map(fn [_, label, target] -> {label, target} end)
  end

  defp split_target(target) do
    case String.split(target, "#", parts: 2) do
      [path, anchor] -> [path, URI.decode(anchor)]
      [path] -> [path, nil]
    end
  end

  defp resolved_path(source, target) do
    target = target |> String.split("#", parts: 2) |> hd() |> URI.decode()

    cond do
      target == "" ->
        source

      String.starts_with?(target, "/") ->
        String.trim_leading(target, "/")

      true ->
        source |> Path.dirname() |> Path.join(target) |> Path.expand("/") |> Path.relative_to("/")
    end
  end

  defp heading_anchors(content) do
    content
    |> String.split("\n")
    |> Enum.filter(&Regex.match?(~r/^\#{1,6}\s+/, &1))
    |> Enum.map(fn heading ->
      heading
      |> String.replace(~r/^\#{1,6}\s+/, "")
      |> String.replace(~r/`([^`]*)`/, "\\1")
      |> String.downcase()
      # GitHub/ExDoc heading ids preserve underscores in identifiers such as
      # `correlation_id`; strip punctuation without collapsing identifier text.
      |> String.replace(~r/[^\p{L}\p{N}_\s-]/u, "")
      |> String.trim()
      |> String.replace(~r/\s+/, "-")
      |> String.replace(~r/-+/, "-")
    end)
    |> MapSet.new()
  end

  defp external_or_asset?(target) do
    String.starts_with?(target, ["http://", "https://", "mailto:", "#"]) or
      String.match?(target, ~r/\.(?:png|svg|jpg|jpeg|gif)(?:#.*)?$/i)
  end

  defp sole_sequence_owner(needle, owner, caller_paths) do
    subjects = [owner | caller_paths]

    matches =
      public_markdown_files()
      |> Map.take(subjects)
      |> Enum.filter(fn {_path, content} -> runnable_fence_contains?(content, needle) end)
      |> Enum.map(&elem(&1, 0))

    assert owner in matches, "canonical owner lost #{inspect(needle)}"

    assert matches == [owner],
           "#{inspect(needle)} procedure appears in a routed caller: #{inspect(matches)}"

    true
  end

  defp runnable_fence_contains?(content, needle) do
    Regex.scan(~r/```(?:bash|sh|elixir)\s*\n([\s\S]*?)```/m, content, capture: :all_but_first)
    |> Enum.any?(fn [body] -> String.contains?(body, needle) end)
  end

  defp link_target?(source, content, expected) do
    content
    |> markdown_links()
    |> Enum.any?(fn {_label, target} -> resolved_path(source, target) == expected end)
  end
end
