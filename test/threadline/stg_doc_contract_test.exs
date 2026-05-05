defmodule Threadline.StgDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "CONTRIBUTING documents host STG evidence for integrators" do
    doc = read_rel!(["CONTRIBUTING.md"])
    assert String.contains?(doc, "## Host STG evidence (integrators)")
  end

  test "production checklist points to backlog STG rubric" do
    doc = read_rel!(["guides", "production-checklist.md"])
    assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
    assert String.contains?(doc, "guides/adoption-pilot-backlog.md")
  end

  test "adoption pilot backlog retains STG template and rubric markers" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "STG-HOST-TOPOLOGY-TEMPLATE")
    assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
  end

  test "adoption pilot backlog includes the maintainer-walked example disclaimer and heading" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])

    assert String.contains?(doc, "<!-- ADOPT-EXAMPLE-DISCLAIMER -->")
    assert String.contains?(doc, "### Example: ExampleCloud walkthrough (maintainer-walked)")
  end

  test "walked example keeps evidence in-repo and avoids staging urls" do
    section = walked_example_section()

    assert String.contains?(section, "| `POST /api/posts` | HTTP | OK |")
    assert String.contains?(section, "test/threadline/getting_started_saas_doc_contract_test.exs")
    refute String.contains?(section, "https://staging.")
    refute String.contains?(section, "http://staging.")
  end

  test "walked example stays fictional and avoids real vendor names" do
    section = walked_example_section()

    assert String.contains?(section, "ExampleCloud")
    assert String.contains?(section, "GenericPooler")

    refute String.contains?(section, "AWS")
    refute String.contains?(section, "GCP")
    refute String.contains?(section, "Google Cloud")
    refute String.contains?(section, "Azure")
    refute String.contains?(section, "Heroku")
    refute String.contains?(section, "Render")
    refute String.contains?(section, "Fly.io")
    refute String.contains?(section, "Supabase")
  end

  defp walked_example_section do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    [_before, after_heading] = String.split(doc, "### Example: ExampleCloud walkthrough (maintainer-walked)", parts: 2)
    hd(String.split(after_heading, "\n## ", parts: 2))
  end
end
