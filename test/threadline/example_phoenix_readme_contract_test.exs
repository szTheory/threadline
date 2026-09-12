defmodule Threadline.ExamplePhoenixReadmeContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()
  @readme_path "examples/threadline_phoenix/README.md"
  @canonical_owner_links [
    {"../../guides/getting-started-saas.md", "1-prerequisites"},
    {"../../guides/operator-surface.md", "1-minute-mount"},
    {"../../guides/local-docker-dx.md", "try-the-ui-demo"}
  ]

  test "example README is a proof surface with an honest support boundary" do
    doc = read!(@readme_path)

    assert String.contains?(doc, "maintained, repository-only proof")
    assert contains_normalized?(doc, "It is not a second installation guide")
    assert String.contains?(doc, "current `sigra-reference` lane")
    assert String.contains?(doc, "without claiming that arbitrary Sigra")
    assert String.contains?(doc, "Audience:")
    assert String.contains?(doc, "Outcome:")
    assert String.contains?(doc, "Prerequisites:")
    assert String.contains?(doc, "Safety boundary:")
    assert String.contains?(doc, "the host owns authentication, authorization, tenancy")
  end

  test "package coordinates agree with the example Mix project" do
    doc = read!(@readme_path)
    mix_exs = read!("examples/threadline_phoenix/mix.exs")

    for coordinate <- [
          ~S|{:threadline, path: "../.."}|,
          ~S|{:phoenix, "~> 1.8.5"}|,
          ~S|{:sigra, "~> 0.2"}|
        ] do
      assert String.contains?(doc, coordinate)
      assert String.contains?(mix_exs, coordinate)
    end

    assert String.contains?(doc, "[`mix.exs`](mix.exs)")
    assert String.contains?(doc, "[`mix.lock`](mix.lock)")
  end

  test "example routes to all three canonical procedure owners at valid anchors" do
    doc = read!(@readme_path)

    for {target, anchor} <- @canonical_owner_links do
      assert String.contains?(doc, "(#{target}##{anchor})")
      assert :ok == validate_target(@readme_path, "#{target}##{anchor}")
    end
  end

  test "relative-link validation rejects missing paths and anchors" do
    assert {:error, :missing_path} ==
             validate_target(@readme_path, "../../guides/not-a-guide.md")

    assert {:error, :missing_anchor} ==
             validate_target(
               @readme_path,
               "../../guides/getting-started-saas.md#not-an-anchor"
             )
  end

  test "example README rejects a competing ordered setup block" do
    doc = read!(@readme_path)

    refute competing_procedure?(doc)

    assert competing_procedure?("""
           1. Install dependencies.

           ```bash
           mix deps.get
           mix ecto.migrate
           ```
           """)
  end

  test "example-specific claims point to source and executable proof" do
    doc = read!(@readme_path)

    required_paths = [
      "lib/threadline_phoenix_web/router.ex",
      "lib/threadline_phoenix/blog.ex",
      "test/threadline_phoenix_web/posts_audit_path_test.exs",
      "test/threadline_phoenix_web/posts_correlation_path_test.exs",
      "test/threadline_phoenix_web/posts_incident_json_path_test.exs",
      "test/threadline_phoenix_web/operator_surface_test.exs",
      "test/threadline_phoenix_web/walkthrough_happy_path_test.exs",
      "test/threadline_phoenix_web/walkthrough_evidence_test.exs",
      "test/threadline_phoenix_web/track_a_golden_path_test.exs"
    ]

    for path <- required_paths do
      assert String.contains?(doc, "](#{path})"), "README does not link #{path}"
      assert File.regular?(Path.join(@repo_root, "examples/threadline_phoenix/#{path}"))
    end
  end

  test "example keeps direct Sigra and mounted authorization proof without recipes" do
    doc = read!(@readme_path)

    assert String.contains?(doc, "Threadline.Integrations.Sigra.actor_ref_from_conn/1")

    assert String.contains?(
             doc,
             "Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1"
           )

    assert String.contains?(doc, "soft-loaded and host-owned")
    assert String.contains?(doc, "Threadline.Audit.transaction/3")
    assert String.contains?(doc, "Threadline.incident_bundle/2")
    assert String.contains?(doc, "one secured\n`/audit` tree")
    assert String.contains?(doc, "export/evidence access remains separately")
    assert String.contains?(doc, "Neither is a production route")
    refute String.contains?(doc, "threadline_operator_surface(")
    refute String.contains?(doc, "ThreadlinePhoenix.AuditActor")
  end

  test "example router still uses one assigns-shaped authorizer and real ActorRef" do
    router = read!("examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex")

    assert String.contains?(router, "def my_authorize_fn(%{assigns: assigns}) do")
    assert String.contains?(router, "alias Threadline.Semantics.ActorRef")
    assert String.contains?(router, "%ActorRef{type: :user, id: to_string(user.id)}")

    assert String.contains?(
             router,
             "scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3"
           )

    assert String.contains?(
             router,
             "export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1"
           )

    assert String.contains?(
             router,
             "evidence_authorize_fn: &ThreadlinePhoenixWeb.Router.my_evidence_authorize_fn/1"
           )

    refute String.contains?(router, "def my_authorize_fn(%Plug.Conn{}")
    refute String.contains?(router, "def my_authorize_fn(%Phoenix.LiveView.Socket{}")
  end

  defp competing_procedure?(doc) do
    ordered_command =
      Regex.match?(~r/^\s*\d+\.\s+.*(?:`mix\s|`bin\/|`docker\s)/m, doc)

    runnable_fence =
      Regex.match?(
        ~r/```(?:bash|sh|elixir)\s*\n[\s\S]*?(?:mix\s+(?:deps\.|ecto\.|phx\.|threadline\.)|bin\/demo-up|docker\s+compose)[\s\S]*?```/m,
        doc
      )

    ordered_command or runnable_fence
  end

  defp validate_target(source, target) do
    [raw_path, anchor] =
      case String.split(target, "#", parts: 2) do
        [path, fragment] -> [path, URI.decode(fragment)]
        [path] -> [path, nil]
      end

    resolved =
      source
      |> Path.dirname()
      |> Path.join(URI.decode(raw_path))
      |> Path.expand(@repo_root)

    cond do
      not File.regular?(resolved) ->
        {:error, :missing_path}

      anchor != nil and anchor not in heading_anchors(File.read!(resolved)) ->
        {:error, :missing_anchor}

      true ->
        :ok
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
      |> String.replace(~r/[^\p{L}\p{N}\s-]/u, "")
      |> String.trim()
      |> String.replace(~r/\s+/, "-")
      |> String.replace(~r/-+/, "-")
    end)
    |> MapSet.new()
  end

  defp contains_normalized?(doc, snippet) do
    String.contains?(normalize(doc), normalize(snippet))
  end

  defp normalize(value), do: String.replace(value, ~r/\s+/, " ")

  defp read!(path), do: @repo_root |> Path.join(path) |> File.read!()
end
