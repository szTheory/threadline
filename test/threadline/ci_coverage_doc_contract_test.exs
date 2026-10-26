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

  Four failures, deliberately distinct:

    * A default-config project is **missing** from the table, so the table has
      drifted behind the pipeline.
    * A row names the **wrong lane**: a Browser-full project whose row does not
      name `verify-example-browser-full`, or a `ci.yml` project whose row does.
    * The derive source returns **no** projects at all, which would make this
      guard pass vacuously while asserting nothing. That is the failure mode
      `version_truth_doc_contract_test.exs:59` exists to prevent, transplanted.
    * A prose description of Browser-full's **coverage** overstates what the
      code runs (review WR-01, phase 246 gap closure). `CONTRIBUTING.md`'s
      `## CI Coverage` section, the `browser-full.yml` header comment and the
      `playwright.config.ts` route-capture comment must each state the curated
      render smoke in a phrase derived from `operator-page-capture.spec.ts`
      (`const ROUTES` entry count, `const BREAKPOINTS` widths) and say the
      inventory-wide route tests run only in evidence mode. The two false
      claims WR-01 found are refused outright.

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

  @capture_spec Path.join(
                  @repo_root,
                  "examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts"
                )
  @browser_full_workflow Path.join(@repo_root, ".github/workflows/browser-full.yml")
  @playwright_config Path.join(@repo_root, "examples/threadline_phoenix/e2e/playwright.config.ts")

  @evidence_only "only in evidence mode"
  # The two claims review WR-01 found: Browser-full never runs either.
  @false_claims ["every inventoried route", "at three viewports"]

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

  # The curated render smoke as the spec runs it, e.g. "6 curated operator
  # routes at 1280". Derived, never hand-written, so adding a route or a width
  # turns the prose red until the docs say so.
  defp curated_phrase do
    spec = File.read!(@capture_spec)
    "#{route_count(spec)} curated operator routes at #{breakpoints(spec)}"
  end

  defp route_count(spec) do
    body =
      case Regex.run(~r/const ROUTES\b.*?^\];$/ms, spec) do
        [body] -> body
        nil -> flunk("operator-page-capture.spec.ts has no `const ROUTES` array ending in `];`")
      end

    case length(Regex.scan(~r/\{ id: "/, body)) do
      0 -> flunk("operator-page-capture.spec.ts `const ROUTES` has no `{ id: \"...` entries")
      count -> count
    end
  end

  defp breakpoints(spec) do
    widths =
      case Regex.run(~r/const BREAKPOINTS = \[([^\]]*)\]/, spec) do
        [_, list] ->
          list |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

        nil ->
          []
      end

    if widths == [],
      do: flunk("operator-page-capture.spec.ts has no non-empty `const BREAKPOINTS = [...]` list")

    Enum.join(widths, "/")
  end

  # Comment-normalise so YAML (`#`) and TypeScript (`//`) comments may wrap a
  # phrase across lines.
  defp prose(text) do
    text
    |> String.split("\n")
    |> Enum.map_join(" ", &(&1 |> String.trim_leading() |> String.replace(~r/^(#+|\/\/+)/, "")))
    |> String.replace(~r/\s+/, " ")
  end

  # Pure: the errors for one labelled source. The count is matched exactly, so
  # "16 curated ..." or "... at 1280/768" can never satisfy "6 ... at 1280".
  defp coverage_wording_errors(label, text, phrase) do
    normalised = prose(text)
    exact = ~r/(?<!\d)#{Regex.escape(phrase)}(?!\d|\/\d)/

    missing =
      [
        {Regex.match?(exact, normalised), "#{label} lacks the spec-derived phrase `#{phrase}`"},
        {String.contains?(normalised, @evidence_only), "#{label} lacks `#{@evidence_only}`"}
      ]
      |> Enum.reject(&elem(&1, 0))
      |> Enum.map(&elem(&1, 1))

    false_claims =
      for claim <- @false_claims, String.contains?(normalised, claim) do
        "#{label} states the false claim `#{claim}` (review WR-01)"
      end

    missing ++ false_claims
  end

  defp coverage_sources do
    [
      {"CONTRIBUTING.md ## CI Coverage", coverage_section()},
      {"browser-full.yml", File.read!(@browser_full_workflow)},
      {"playwright.config.ts", File.read!(@playwright_config)}
    ]
  end

  test "every Browser-full coverage description matches what the spec runs (WR-01)" do
    phrase = curated_phrase()

    errors =
      Enum.flat_map(coverage_sources(), fn {label, text} ->
        coverage_wording_errors(label, text, phrase)
      end)

    assert errors == [],
           "Browser-full's coverage prose does not match operator-page-capture.spec.ts. " <>
             "Phase 247 measures CI from the CI Coverage table, so an overstated claim " <>
             "hands it a false baseline:\n" <> Enum.join(errors, "\n")
  end

  test "the curated-route derive is non-vacuous" do
    spec = File.read!(@capture_spec)

    assert route_count(spec) > 0
    assert breakpoints(spec) != ""
    refute curated_phrase() =~ ~r/^0 /
  end

  test "a false claim, a dropped phrase or a wrong route count turns the wording check red" do
    phrase = curated_phrase()
    passing = "It renders the #{phrase}; the inventory-wide tests run #{@evidence_only}."

    assert coverage_wording_errors("control", passing, phrase) == []

    for claim <- @false_claims do
      errors = coverage_wording_errors("control", passing <> " It covers #{claim}.", phrase)
      assert Enum.any?(errors, &String.contains?(&1, claim)), "#{claim}: #{inspect(errors)}"
    end

    dropped = String.replace(passing, phrase, "the curated routes")

    assert Enum.any?(
             coverage_wording_errors("control", dropped, phrase),
             &(&1 =~ "lacks the spec")
           )

    [count | rest] = String.split(phrase, " ", parts: 2)
    wrong = String.replace(passing, phrase, "#{String.to_integer(count) + 1} #{hd(rest)}")
    assert Enum.any?(coverage_wording_errors("control", wrong, phrase), &(&1 =~ "lacks the spec"))

    padded = String.replace(passing, phrase, "1#{phrase}")

    assert Enum.any?(
             coverage_wording_errors("control", padded, phrase),
             &(&1 =~ "lacks the spec")
           )
  end
end
