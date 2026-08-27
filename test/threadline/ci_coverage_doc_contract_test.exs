defmodule Threadline.CiCoverageDocContractTest do
  @moduledoc """
  CI Coverage doc contract (Phase 198, D-23c / GREEN-07).

  Phase 198 split the browser lane: pull requests run a reduced Playwright
  project set, and the full set moved to `main` + nightly. The OSS DNA's
  "honest default tests" rule says coverage may not move silently — so
  `CONTRIBUTING.md` carries a `## CI Coverage` table stating verbatim which
  projects run where, and this test asserts that table against the workflows
  themselves.

  Two failures, deliberately distinct:

    * A project a workflow actually runs is **missing** from the table — the
      table has drifted behind the pipeline.
    * The scan finds **no** `--project` flags at all — the derive source is
      broken (a moved workflow, a changed flag spelling), which would make this
      guard pass vacuously while asserting nothing. That is the failure mode
      `version_truth_doc_contract_test.exs:59` exists to prevent, transplanted.

  Deliberately a plain `*_contract_test.exs` picked up by bare `mix test`, NOT
  wired into a `mix verify.*` alias: Phase 204 deletes `verify.doc_contract`,
  and a guard that dies with an alias is not a guard.
  """
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  # The two workflows that invoke Playwright with project flags. A glob would
  # silently absorb a workflow being renamed away; naming them means a missing
  # file is a hard `File.read!/1` failure, not a quiet shrink of the scan.
  @workflow_paths [
    Path.join([@repo_root, ".github", "workflows", "ci.yml"]),
    Path.join([@repo_root, ".github", "workflows", "browser-full.yml"])
  ]

  @contributing Path.join(@repo_root, "CONTRIBUTING.md")
  @coverage_heading "## CI Coverage"

  defp projects_in_workflows do
    for path <- @workflow_paths,
        [_full, project] <- Regex.scan(~r/--project[= ]([a-z0-9-]+)/, File.read!(path)),
        uniq: true,
        do: project
  end

  defp coverage_section do
    contributing = File.read!(@contributing)

    assert String.contains?(contributing, @coverage_heading),
           "CONTRIBUTING.md has no `#{@coverage_heading}` heading. The split browser " <>
             "lane is only honest if what moved is stated in the contributor docs (D-23b)."

    contributing
    |> String.split(@coverage_heading, parts: 2)
    |> List.last()
    # Stop at the next top-level heading so a project name mentioned elsewhere
    # in CONTRIBUTING.md cannot launder a missing table row.
    |> String.split(~r/\n## /, parts: 2)
    |> List.first()
  end

  test "the workflow scan finds Playwright project flags at all" do
    projects = projects_in_workflows()

    assert projects != [],
           "no `--project` flags found across #{inspect(@workflow_paths)} — the derive " <>
             "source for the CI Coverage contract is broken. Without this assertion the " <>
             "test below would pass vacuously over an empty list while the CONTRIBUTING.md " <>
             "table drifted arbitrarily far from what CI actually runs."
  end

  test "every Playwright project a workflow runs appears in the CONTRIBUTING.md CI Coverage table" do
    section = coverage_section()

    for project <- projects_in_workflows() do
      # Require an actual TABLE ROW (`| \`project\` | ... |`), not merely the
      # substring somewhere in the section. Prose in the section mentions
      # several project names; a substring match would let a deleted row be
      # laundered by an unrelated sentence.
      row_regex = ~r/^\|\s*`#{Regex.escape(project)}`\s*\|/m

      assert Regex.match?(row_regex, section),
             "CONTRIBUTING.md's `#{@coverage_heading}` table has no row for the Playwright " <>
               "project `#{project}`, which a workflow under .github/workflows/ actually " <>
               "runs. Coverage that moves between the pull-request lane and the " <>
               "main/nightly lane must be stated verbatim in that table (D-23b/c) — a " <>
               "silent move is the quiet downgrade this phase exists to forbid."
    end
  end
end
