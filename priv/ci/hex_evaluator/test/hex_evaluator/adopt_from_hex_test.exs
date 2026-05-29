defmodule HexEvaluator.AdoptFromHexTest do
  @moduledoc """
  Proves `{:threadline, "~> 0.6"}` from hex.pm captures row mutations — not path dep.

  Run via root `mix verify.hex_evaluator` (CI job `verify-hex-evaluator`).
  """
  use HexEvaluator.DataCase, async: false

  alias HexEvaluator.{Post, Repo}
  alias Threadline.Capture.AuditChange

  @repo_root Path.expand("../../../../..", __DIR__)

  setup do
    slug = "hex-eval-#{System.unique_integer([:positive])}"

    {:ok, post} =
      Repo.insert(%Post{title: "Hex evaluator", slug: slug})

    on_exit(fn -> Repo.delete(post) end)

    {:ok, post: post}
  end

  test "hex-published threadline captures post insert via trigger", %{post: post} do
    count =
      Repo.aggregate(
        from(ac in AuditChange,
          where: ac.table_name == "posts",
          where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(post.id))
        ),
        :count
      )

    assert count >= 1
  end

  test "threadline dependency resolves from hex.pm not repo path override" do
    dep_path =
      Mix.Project.deps_paths()
      |> Map.fetch!(:threadline)
      |> Path.expand()

    refute dep_path == Path.expand(@repo_root),
           "expected hex package in deps/, not path dep to repo root"
  end
end
