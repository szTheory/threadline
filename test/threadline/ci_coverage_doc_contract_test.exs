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
      and say the inventory-wide route tests run only in evidence mode. The
      phrase counts the distinct curated routes in `const ROUTES` and names
      the `degrade: true` entry as a degraded twin of one of them, at the
      `const BREAKPOINTS` widths (R2-WR-01). The file sources are scoped to
      the comment that describes coverage (the `browser-full.yml` header
      block, the comment directly above `name: "route-capture"`), and a
      regex denylist refuses the false claims WR-01 and R2-WR-02 found,
      including both inversions of which mode writes the route scorecards.

  Deliberately a plain `*_contract_test.exs` picked up by bare `mix test`, NOT
  wired into a `mix verify.*` alias: the hand-listed doc-contract alias was
  deleted, and a guard that dies with an alias is not a guard.
  """
  use ExUnit.Case, async: true
  @moduletag :repo_contract

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
  # The claims reviews WR-01 and R2-WR-02 found, as patterns so a paraphrase
  # cannot slip past: Browser-full never runs the inventory-wide tests or three
  # viewports, and the route scorecards are written by the curated smoke that
  # runs OUTSIDE evidence mode, so both inversions of that are refused too.
  # Each pattern is paired with a sample sentence that only it matches; the
  # mutation control below proves every one of them turns the check red.
  @false_claims [
    {~r/\b(every|all) inventor(y|ied) routes?\b/i, "It covers all inventory routes."},
    {~r/\bthree viewports\b/i, "It renders across three viewports."},
    {~r/in evidence mode,? writes the route scorecards/i,
     "It drives the routes and, in evidence mode, writes the route scorecards."},
    {~r/scorecards run only in evidence mode/i, "The route scorecards run only in evidence mode."}
  ]

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

  # The curated render smoke as the spec runs it, e.g. "5 curated operator
  # routes plus a degraded Timeline twin at 1280". Derived, never hand-written,
  # so adding a route, a twin or a width turns the prose red until the docs say
  # so (R2-WR-01: the degraded twin re-renders a curated path, so it is not a
  # sixth route).
  defp curated_phrase, do: curated_phrase(File.read!(@capture_spec))

  defp curated_phrase(spec) do
    {routes, twins} = curated_routes(spec)
    widths = breakpoints(spec)
    count = length(routes)

    if count == 0,
      do:
        flunk("operator-page-capture.spec.ts `const ROUTES` has no curated (non-degraded) routes")

    case twins do
      [] ->
        "#{count} curated operator routes at #{widths}"

      [twin] ->
        unless twin in routes,
          do: flunk("`const ROUTES` has a degraded entry for #{twin}, a twin of no curated route")

        "#{count} curated operator routes plus a degraded #{twin_label(twin)} twin at #{widths}"

      _ ->
        flunk(
          "`const ROUTES` has #{length(twins)} degraded entries; extend the phrase template " <>
            "in curated_phrase/1 before documenting them"
        )
    end
  end

  # `{routes, twins}`: the paths of the uncommented `const ROUTES` entries,
  # split on `degrade: true`.
  defp curated_routes(spec) do
    body =
      case Regex.run(~r/const ROUTES\b.*?^\];$/ms, spec) do
        [body] -> body
        nil -> flunk("operator-page-capture.spec.ts has no `const ROUTES` array ending in `];`")
      end

    {twins, routes} =
      body
      |> String.split("\n")
      |> Enum.reject(&line_comment?/1)
      |> Enum.filter(&String.contains?(&1, ~s({ id: ")))
      |> Enum.map(&route_entry/1)
      |> Enum.split_with(&elem(&1, 1))

    {Enum.map(routes, &elem(&1, 0)), Enum.map(twins, &elem(&1, 0))}
  end

  defp route_entry(line) do
    case Regex.run(~r/path: "([^"]*)"/, line) do
      [_, path] -> {path, String.contains?(line, "degrade: true")}
      nil -> flunk("`const ROUTES` entry has no `path: \"...\"`: #{line}")
    end
  end

  defp line_comment?(line), do: line |> String.trim_leading() |> String.starts_with?("//")

  defp twin_label(path),
    do: path |> String.split("/", trim: true) |> List.last() |> String.capitalize()

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
      for {claim, _sample} <- @false_claims, Regex.match?(claim, normalised) do
        "#{label} states the false claim `#{Regex.source(claim)}` (review WR-01 / R2-WR-02)"
      end

    missing ++ false_claims
  end

  defp coverage_sources do
    [
      {"CONTRIBUTING.md ## CI Coverage", coverage_section()},
      {"browser-full.yml header comment",
       scoped_source(:browser_full, File.read!(@browser_full_workflow))},
      {"playwright.config.ts route-capture comment",
       scoped_source(:playwright, File.read!(@playwright_config))}
    ]
  end

  # Only the comment that describes coverage counts (R2-WR-02), so the phrase in
  # an unrelated comment cannot launder a wrong block.
  #
  # browser-full.yml: the `#` header lines before the first `name:` line.
  defp scoped_source(:browser_full, text) do
    header =
      text
      |> String.split("\n")
      |> Enum.take_while(&(not Regex.match?(~r/^name:/, &1)))
      |> Enum.filter(&String.starts_with?(&1, "#"))

    if header == [],
      do: flunk("browser-full.yml has no `#` header comment before its first `name:` line")

    Enum.join(header, "\n")
  end

  # playwright.config.ts: the contiguous `//` block directly above the
  # `name: "route-capture"` line, skipping only the bare `{` that opens it.
  defp scoped_source(:playwright, text) do
    lines = String.split(text, "\n")

    above =
      case Enum.find_index(lines, &String.contains?(&1, ~s(name: "route-capture"))) do
        nil -> flunk(~s(playwright.config.ts has no `name: "route-capture"` project))
        index -> lines |> Enum.take(index) |> Enum.reverse()
      end

    block =
      above
      |> Enum.drop_while(&(String.trim(&1) in ["", "{"]))
      |> Enum.take_while(&line_comment?/1)
      |> Enum.reverse()

    if block == [],
      do:
        flunk(~s(playwright.config.ts has no `//` comment directly above `name: "route-capture"`))

    Enum.join(block, "\n")
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

  # Synthetic spec text in the shape `curated_routes/1` and `breakpoints/1` read.
  defp synthetic_spec(entries, widths) do
    """
    const BREAKPOINTS = [#{widths}] as const;
    const ROUTES: { id: string; path: string; degrade?: boolean }[] = [
    #{Enum.join(entries, "\n")}
    ];
    """
  end

  defp entry(id, path), do: ~s(  { id: "#{id}", path: "#{path}" },)
  defp twin(id, path), do: ~s(  { id: "#{id}", path: "#{path}", degrade: true },)

  test "the curated-route derive is non-vacuous and twin-aware" do
    spec = File.read!(@capture_spec)
    {routes, twins} = curated_routes(spec)

    assert length(routes) == 5
    assert [twin] = twins
    assert twin_label(twin) == "Timeline"
    assert breakpoints(spec) == "1280"
    refute curated_phrase() =~ ~r/^0 /

    # A commented-out entry is not a route.
    commented =
      synthetic_spec(
        [entry("route.a", "/audit/a"), ~s(  // { id: "route.b", path: "/audit/b" },)],
        "1280"
      )

    assert {["/audit/a"], []} = curated_routes(commented)

    # Zero twins: the phrase carries no twin clause.
    plain =
      synthetic_spec([entry("route.a", "/audit/a"), entry("route.b", "/audit/b")], "1280, 768")

    assert curated_phrase(plain) == "2 curated operator routes at 1280/768"

    # Shapes the template cannot state honestly must flunk, never pass vacuously.
    two_twins =
      synthetic_spec(
        [entry("route.a", "/audit/a"), twin("a.x", "/audit/a"), twin("a.y", "/audit/a")],
        "1280"
      )

    orphan = synthetic_spec([entry("route.a", "/audit/a"), twin("b.x", "/audit/b")], "1280")
    no_routes = synthetic_spec([twin("a.x", "/audit/a")], "1280")
    no_widths = synthetic_spec([entry("route.a", "/audit/a")], "")

    for bad <- [two_twins, orphan, no_routes, no_widths] do
      assert_raise ExUnit.AssertionError, fn -> curated_phrase(bad) end
    end
  end

  test "only the scoped coverage comment counts, not the phrase elsewhere in the file (R2-WR-02)" do
    phrase = curated_phrase()
    good = "renders the #{phrase}; the inventory-wide tests run #{@evidence_only}."

    playwright = """
      // Unrelated note: #{good}
      { name: "mobile-chromium" },
      // Route render smoke over the curated routes.
      {
        name: "route-capture",
    """

    errors = coverage_wording_errors("control", scoped_source(:playwright, playwright), phrase)
    assert Enum.any?(errors, &(&1 =~ "lacks the spec")), inspect(errors)

    fixed = String.replace(playwright, "over the curated routes.", good)
    assert coverage_wording_errors("control", scoped_source(:playwright, fixed), phrase) == []

    workflow = """
    # Browser-full lane over the curated routes.
    name: Browser (full project set)
    # #{good}
    """

    errors = coverage_wording_errors("control", scoped_source(:browser_full, workflow), phrase)
    assert Enum.any?(errors, &(&1 =~ "lacks the spec")), inspect(errors)
  end

  test "a false claim, a dropped phrase or a wrong route count turns the wording check red" do
    phrase = curated_phrase()
    passing = "It renders the #{phrase}; the inventory-wide tests run #{@evidence_only}."

    assert coverage_wording_errors("control", passing, phrase) == []

    # One mutation per false-claim pattern: its sample sentence trips that
    # pattern, and only that one.
    for {claim, sample} <- @false_claims do
      source = Regex.source(claim)
      errors = coverage_wording_errors("control", passing <> " " <> sample, phrase)
      claimed = Enum.filter(errors, &(&1 =~ "states the false claim"))

      assert [only] = claimed, "#{source}: #{inspect(errors)}"
      assert String.contains?(only, source), "#{source}: #{inspect(errors)}"
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

    # Dropping the degraded-twin clause is an overcount-in-waiting, not a pass.
    twin_clause = ~r/ plus a degraded \S+ twin/
    assert phrase =~ twin_clause
    no_twin = String.replace(passing, phrase, Regex.replace(twin_clause, phrase, ""))

    assert Enum.any?(
             coverage_wording_errors("control", no_twin, phrase),
             &(&1 =~ "lacks the spec")
           )
  end
end
