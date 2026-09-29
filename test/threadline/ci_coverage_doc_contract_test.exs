defmodule Threadline.CiCoverageDocContractTest do
  @moduledoc """
  CI Coverage doc contract (Phase 198, D-23c / GREEN-07).

  Phase 198 split the browser lane, and Phase 218 (ECON-04) made the split a
  partition: `ci.yml` runs some Playwright projects on every pull request and
  push to `main`, and Browser-full runs the rest. The OSS DNA's "honest default
  tests" rule says coverage may not move silently, so `CONTRIBUTING.md` carries
  a `## CI Coverage` table stating which projects run where, and this test
  asserts that table against the pipeline.

  The project list is not scanned from workflow text here. It comes from
  `bin/browser-full-projects` (`--list config`, `--list ci`,
  `--list browser-full`), the same derivation Browser-full itself runs, which
  `browser_full_projects_contract_test.exs` proves partitions the config.

  Three failures, deliberately distinct:

    * A default-config project is **missing** from the table, so the table has
      drifted behind the pipeline.
    * A row names the **wrong lane**: a Browser-full project whose row does not
      name `verify-example-browser-full`, or a `ci.yml` project whose row does.
    * The derive source returns **no** projects at all, which would make this
      guard pass vacuously while asserting nothing. That is the failure mode
      `version_truth_doc_contract_test.exs:59` exists to prevent, transplanted.

  Deliberately a plain `*_contract_test.exs` picked up by bare `mix test`, NOT
  wired into a `mix verify.*` alias: the hand-listed doc-contract alias was
  deleted, and a guard that dies with an alias is not a guard.
  """
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  @script Path.join(@repo_root, "bin/browser-full-projects")

  @contributing Path.join(@repo_root, "CONTRIBUTING.md")
  @coverage_heading "## CI Coverage"
  @full_job "verify-example-browser-full"

  defp list(kind) do
    {output, status} = System.cmd(@script, ["--list", kind], stderr_to_stdout: true)

    assert status == 0,
           "bin/browser-full-projects --list #{kind} exited #{status}:\n#{output}"

    String.split(output, "\n", trim: true)
  end

  # The default-config project set: every project ci.yml or Browser-full runs.
  defp projects_in_workflows, do: list("config")

  defp row(section, project) do
    case Regex.run(~r/^\|\s*`#{Regex.escape(project)}`\s*\|.*$/m, section) do
      [row] -> row
      nil -> flunk("CONTRIBUTING.md `#{@coverage_heading}` has no table row for `#{project}`")
    end
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

  test "the derive source finds Playwright projects at all" do
    projects = projects_in_workflows()

    assert projects != [],
           "bin/browser-full-projects --list config returned no projects — the derive " <>
             "source for the CI Coverage contract is broken. Without this assertion the " <>
             "test below would pass vacuously over an empty list while the CONTRIBUTING.md " <>
             "table drifted arbitrarily far from what CI actually runs."
  end

  test "every default-config Playwright project appears in the CONTRIBUTING.md CI Coverage table" do
    section = coverage_section()

    for project <- projects_in_workflows() do
      # Require an actual TABLE ROW (`| \`project\` | ... |`), not merely the
      # substring somewhere in the section. Prose in the section mentions
      # several project names; a substring match would let a deleted row be
      # laundered by an unrelated sentence.
      row_regex = ~r/^\|\s*`#{Regex.escape(project)}`\s*\|/m

      assert Regex.match?(row_regex, section),
             "CONTRIBUTING.md's `#{@coverage_heading}` table has no row for the Playwright " <>
               "project `#{project}`, which ci.yml or Browser-full actually runs. " <>
               "Coverage that moves between the pull-request lane and the " <>
               "main/nightly lane must be stated verbatim in that table (D-23b/c) — a " <>
               "silent move is the quiet downgrade this phase exists to forbid."
    end
  end

  test "each CI Coverage row names the lane that actually runs the project" do
    section = coverage_section()
    full = list("browser-full")
    config = projects_in_workflows()
    ci = Enum.filter(list("ci"), &(&1 in config))

    assert full != [] and ci != [],
           "the lane lists are empty; the lane check below would pass vacuously"

    for project <- full do
      assert row(section, project) =~ @full_job,
             "`#{project}` runs only in Browser-full, but its CI Coverage row does not " <>
               "name `#{@full_job}`."
    end

    for project <- ci do
      refute row(section, project) =~ @full_job,
             "`#{project}` runs in ci.yml and never in Browser-full, but its CI Coverage " <>
               "row still names `#{@full_job}` (the old overlap wording)."
    end
  end
end
