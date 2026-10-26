defmodule Threadline.BrowserFullProjectsContractTest do
  @moduledoc """
  Browser-full project partition contract (Phase 218, ECON-04 / D-07).

  `ci.yml` runs some Playwright projects on every pull request and push to
  `main`; `browser-full.yml` runs the rest. The rest is derived, never
  hand-listed, by `bin/browser-full-projects`: the default-config projects in
  `examples/threadline_phoenix/e2e/playwright.config.ts` minus the projects
  ci.yml runs (its `--project` flags inside `run:` bodies, plus the flags
  inside the mix.exs function behind any `mix <alias>` ci.yml runs).

  This test proves the two lanes partition the config: their union is the
  whole default config set and their intersection is empty. A project that
  runs in neither lane is the silent coverage loss this guard exists to make
  impossible.

  The partition is over `--project` flags. Playwright also runs a selected
  project's declared `dependencies` first, so Browser-full can EXECUTE a ci.yml
  project without selecting it. A declared `dependencies` edge is the only
  allowed way that happens (`--list executed` minus `--list browser-full` must
  be exactly the dependency closure), and every cross-project filesystem
  prerequisite a spec states (`run the <project> lane first`) must be declared
  as such an edge (218-08). Since 246 the live config declares no edge and no
  spec states a prerequisite, and Browser-full runs exactly one project,
  `route-capture`; the edge, prerequisite and mix-alias controls run on
  synthetic mutations of copied inputs, so those rules stay tested.

  The test parses nothing itself: it runs the script against the live repo
  and against mutated copies under `tmp_dir` (`THREADLINE_BROWSER_FULL_ROOT`).
  Every mutation control first asserts the mutation changed its input, so a
  control can never pass over an unchanged file.
  """
  use ExUnit.Case, async: true
  @moduletag :repo_contract

  import Bitwise

  alias Threadline.Test.CiIssuePairing

  @moduletag :tmp_dir

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "bin/browser-full-projects")
  @config_rel "examples/threadline_phoenix/e2e/playwright.config.ts"
  @ci_rel ".github/workflows/ci.yml"
  @mix_rel "mix.exs"
  @browser_full Path.join(@repo_root, ".github/workflows/browser-full.yml")
  @specs_dir Path.join(@repo_root, "examples/threadline_phoenix/e2e/tests")

  # Cross-project filesystem prerequisites the specs state, keyed by the
  # dependent project: {spec file that states it, prerequisite project}. None
  # today: the last one left with the capture specs in 246.
  @stated_prerequisites %{}
  @stated_prerequisite ~r/run the ([a-z0-9-]+) lane first/

  @live_browser_full ~w(route-capture)
  @live_ci ~w(desktop-chromium mobile-chromium)
  @live_deps []

  # A synthetic Browser-full project for the controls that need a second one.
  @canary ~s(  { name: "canary-capture", use: {} },\n)
  @canary_on_desktop ~s(  { name: "canary-capture", dependencies: ["desktop-chromium"], use: {} },\n)

  defp run_script(args, root \\ @repo_root) do
    assert File.regular?(@script) and
             match?({:ok, %File.Stat{mode: mode}} when (mode &&& 0o111) != 0, File.stat(@script)),
           "bin/browser-full-projects is missing or not executable"

    System.cmd(@script, args,
      env: [{"THREADLINE_BROWSER_FULL_ROOT", root}],
      stderr_to_stdout: true
    )
  end

  defp lines(output), do: String.split(output, "\n", trim: true)

  defp list!(kind, root \\ @repo_root) do
    assert {output, 0} = run_script(["--list", kind], root)
    lines(output)
  end

  defp live(rel), do: File.read!(Path.join(@repo_root, rel))

  # Copy the three live inputs into tmp_dir at the same relative paths, apply
  # one mutation to one of them, and return the copy's root.
  defp mutated_root(tmp_dir, rel, mutate), do: mutated_root(tmp_dir, [{rel, mutate}])

  # The same, with one mutation per listed input (each must change its input).
  defp mutated_root(tmp_dir, mutations) do
    for input <- [@config_rel, @ci_rel, @mix_rel] do
      dest = Path.join(tmp_dir, input)
      File.mkdir_p!(Path.dirname(dest))
      File.write!(dest, live(input))
    end

    for {rel, mutate} <- mutations do
      original = live(rel)
      mutated = mutate.(original)
      refute mutated == original, "control did not change #{rel}"
      File.write!(Path.join(tmp_dir, rel), mutated)
    end

    tmp_dir
  end

  defp add_project(config, object),
    do: String.replace(config, "const projects = [\n", "const projects = [\n" <> object)

  # A `mix verify.fixture` alias whose function carries --project flags, the
  # shape bin/browser-full-projects resolves behind a ci.yml `run: mix <alias>`.
  defp add_fixture_alias(mix_src, project) do
    mix_src
    |> String.replace(
      ~s(      "verify.example_browser": &verify_example_browser/1,\n),
      ~s(      "verify.example_browser": &verify_example_browser/1,\n) <>
        ~s(      "verify.fixture": &verify_fixture/1,\n),
      global: false
    )
    |> String.replace(
      "  defp verify_operator_stress(args),\n",
      "  defp verify_fixture(args),\n" <>
        "    do: verify_example_browser([\"--project=#{project}\" | args])\n\n" <>
        "  defp verify_operator_stress(args),\n",
      global: false
    )
  end

  defp run_fixture_alias(yaml),
    do:
      String.replace(
        yaml,
        "run: mix verify.format\n",
        "run: mix verify.format && mix verify.fixture\n"
      )

  defp stated_prerequisites(specs_dir) do
    specs = for spec <- File.ls!(specs_dir), String.ends_with?(spec, ".spec.ts"), do: spec
    assert specs != [], "#{specs_dir} lists no specs; the prerequisite scan would pass vacuously"

    for spec <- specs,
        [_, prerequisite] <-
          Regex.scan(@stated_prerequisite, File.read!(Path.join(specs_dir, spec))),
        uniq: true,
        do: {spec, prerequisite}
  end

  defp flags(names), do: Enum.map(names, &"--project=#{&1}")

  # Every stated prerequisite of a Browser-full project that ci.yml owns must be
  # a declared `dependencies` edge, or Browser-full runs the dependent without it.
  defp prerequisite_violations(root, table \\ @stated_prerequisites) do
    full = list!("browser-full", root)
    deps = list!("deps", root)

    for {project, {_spec, prerequisite}} <- table,
        project in full,
        prerequisite not in full,
        "#{project} #{prerequisite}" not in deps do
      "#{project} needs #{prerequisite} (stated in its spec) but does not declare " <>
        "dependencies: [\"#{prerequisite}\"] in playwright.config.ts; Browser-full would " <>
        "run it without the prerequisite"
    end
  end

  describe "live repo partition" do
    test "--list config is the three default-config projects" do
      assert list!("config") ==
               Enum.sort(@live_ci ++ @live_browser_full)
    end

    test "--list ci is the projects ci.yml runs (inline flags; no alias carries one today)" do
      assert list!("ci") == @live_ci
    end

    test "default output is one sorted --project flag per browser-full project" do
      assert {output, 0} = run_script([])
      assert lines(output) == flags(@live_browser_full)
      assert list!("browser-full") == @live_browser_full
    end

    test "ci and browser-full partition the config: union is the config, intersection is empty" do
      config = MapSet.new(list!("config"))
      ci = MapSet.new(list!("ci"))
      full = MapSet.new(list!("browser-full"))

      nowhere = MapSet.difference(config, MapSet.union(ci, full))

      assert MapSet.size(nowhere) == 0,
             "default-config Playwright projects run by NEITHER ci.yml nor Browser-full: " <>
               "#{inspect(MapSet.to_list(nowhere))}. A project added to playwright.config.ts " <>
               "must land in exactly one lane."

      unknown = MapSet.difference(MapSet.union(ci, full), config)

      assert MapSet.size(unknown) == 0,
             "a lane runs projects the default config does not register: " <>
               "#{inspect(MapSet.to_list(unknown))}"

      both = MapSet.intersection(ci, full)

      assert MapSet.size(both) == 0,
             "projects run by BOTH ci.yml and Browser-full (repeated work): " <>
               "#{inspect(MapSet.to_list(both))}"
    end

    test "--list deps is the declared dependencies edges" do
      assert list!("deps") == @live_deps
    end

    test "Browser-full executes a ci.yml project only through a declared dependencies edge" do
      full = list!("browser-full")
      executed = list!("executed")
      ci = list!("ci")
      edges = for line <- list!("deps"), do: List.to_tuple(String.split(line, " "))

      closure =
        Stream.iterate(MapSet.new(full), fn set ->
          Enum.reduce(edges, set, fn {from, to}, acc ->
            if from in acc, do: MapSet.put(acc, to), else: acc
          end)
        end)
        |> Stream.chunk_every(2, 1)
        |> Enum.find_value(fn [a, b] -> if a == b, do: a end)

      assert executed == Enum.sort(MapSet.to_list(closure)),
             "--list executed must be the Browser-full projects plus their declared " <>
               "dependency closure, nothing else"

      pulled = MapSet.difference(MapSet.new(executed), MapSet.new(full))

      assert MapSet.subset?(pulled, MapSet.new(ci)),
             "a dependency pulls in a project that is in neither lane's flag set"

      assert executed == @live_browser_full
    end

    test "every stated cross-project filesystem prerequisite is in the table" do
      assert Enum.sort(stated_prerequisites(@specs_dir)) ==
               Enum.sort(Map.values(@stated_prerequisites)),
             "a spec states a `run the <project> lane first` prerequisite that " <>
               "@stated_prerequisites does not model (or the table names one no spec states)"
    end

    test "the prerequisite scan finds a stated prerequisite (non-vacuity)", %{tmp_dir: tmp_dir} do
      specs = Path.join(tmp_dir, "specs")
      File.mkdir_p!(specs)

      File.write!(
        Path.join(specs, "operator-canary.spec.ts"),
        ~s|test("canary", () => { throw new Error("run the desktop-chromium lane first"); });\n|
      )

      assert stated_prerequisites(specs) == [{"operator-canary.spec.ts", "desktop-chromium"}]
    end

    test "every stated prerequisite of a Browser-full project is a declared dependencies edge" do
      assert prerequisite_violations(@repo_root) == []
    end

    test "the env-gated light project is never output" do
      for args <- [
            [],
            ["--list", "config"],
            ["--list", "ci"],
            ["--list", "browser-full"],
            ["--list", "executed"]
          ] do
        assert {output, 0} = run_script(args)
        refute output =~ "desktop-chromium-light"
      end
    end

    test "browser-full.yml runs the script and carries no literal --project flag" do
      yaml = File.read!(@browser_full)
      assert yaml =~ "bin/browser-full-projects"
      refute Regex.match?(~r/--project[= ][a-z0-9-]+/, yaml)
    end
  end

  describe "usage" do
    test "an unknown argument exits 2" do
      assert {_output, 2} = run_script(["--bogus"])
      assert {_output, 2} = run_script(["--list", "nope"])
    end

    test "an unreadable root exits 2", %{tmp_dir: tmp_dir} do
      assert {_output, 2} = run_script([], Path.join(tmp_dir, "missing"))
    end
  end

  describe "mutation controls" do
    test "a project added to the config appears in the output", %{tmp_dir: tmp_dir} do
      root =
        mutated_root(
          tmp_dir,
          @config_rel,
          &String.replace(
            &1,
            "const projects = [\n",
            "const projects = [\n  { name: \"canary-capture\", use: {} },\n"
          )
        )

      assert {output, 0} = run_script([], root)
      assert "--project=canary-capture" in lines(output)
    end

    test "dropping --project=mobile-chromium from ci.yml moves it into the output", %{
      tmp_dir: tmp_dir
    } do
      root =
        mutated_root(
          tmp_dir,
          @ci_rel,
          &String.replace(
            &1,
            "--project=desktop-chromium --project=mobile-chromium",
            "--project=desktop-chromium"
          )
        )

      assert {output, 0} = run_script([], root)
      assert "--project=mobile-chromium" in lines(output)
      refute "--project=desktop-chromium" in lines(output)
    end

    test "a mix alias whose function carries --project flags counts as a ci.yml run", %{
      tmp_dir: tmp_dir
    } do
      root =
        mutated_root(tmp_dir, [
          {@config_rel, &add_project(&1, @canary)},
          {@mix_rel, &add_fixture_alias(&1, "canary-capture")},
          {@ci_rel, &run_fixture_alias/1}
        ])

      assert "canary-capture" in list!("ci", root)
      assert {output, 0} = run_script([], root)
      assert lines(output) == flags(@live_browser_full)
    end

    test "removing the run: of that alias moves its project into the output", %{
      tmp_dir: tmp_dir
    } do
      root =
        mutated_root(tmp_dir, [
          {@config_rel, &add_project(&1, @canary)},
          {@mix_rel, &add_fixture_alias(&1, "canary-capture")}
        ])

      refute "canary-capture" in list!("ci", root)
      assert {output, 0} = run_script([], root)
      assert "--project=canary-capture" in lines(output)
    end

    test "an empty projects array exits non-zero", %{tmp_dir: tmp_dir} do
      root =
        mutated_root(
          tmp_dir,
          @config_rel,
          &Regex.replace(~r/const projects = \[.*?\n\];/s, &1, "const projects = [];")
        )

      assert {_output, status} = run_script([], root)
      assert status != 0
    end

    test "an empty difference exits non-zero", %{tmp_dir: tmp_dir} do
      root =
        mutated_root(
          tmp_dir,
          @ci_rel,
          &String.replace(
            &1,
            "--project=desktop-chromium --project=mobile-chromium",
            Enum.join(flags(["desktop-chromium", "mobile-chromium" | @live_browser_full]), " ")
          )
        )

      assert {_output, status} = run_script([], root)
      assert status != 0
    end

    test "a declared dependencies edge executes a ci.yml project in Browser-full", %{
      tmp_dir: tmp_dir
    } do
      root = mutated_root(tmp_dir, @config_rel, &add_project(&1, @canary_on_desktop))
      table = %{"canary-capture" => {"operator-canary.spec.ts", "desktop-chromium"}}

      assert list!("browser-full", root) == ["canary-capture" | @live_browser_full]
      assert list!("deps", root) == ["canary-capture desktop-chromium"]

      assert list!("executed", root) == [
               "canary-capture",
               "desktop-chromium" | @live_browser_full
             ]

      assert prerequisite_violations(root, table) == []
    end

    test "a stated prerequisite without its dependencies declaration turns the contract red", %{
      tmp_dir: tmp_dir
    } do
      root = mutated_root(tmp_dir, @config_rel, &add_project(&1, @canary))
      table = %{"canary-capture" => {"operator-canary.spec.ts", "desktop-chromium"}}

      assert list!("browser-full", root) == ["canary-capture" | @live_browser_full]
      assert list!("deps", root) == []
      assert [violation] = prerequisite_violations(root, table)
      assert violation =~ "canary-capture needs desktop-chromium"
    end

    test "a dependency naming an unregistered project exits non-zero", %{tmp_dir: tmp_dir} do
      root =
        mutated_root(
          tmp_dir,
          @config_rel,
          &add_project(
            &1,
            ~s(  { name: "canary-capture", dependencies: ["ghost-capture"], use: {} },\n)
          )
        )

      assert {_output, status} = run_script([], root)
      assert status != 0
    end

    test "a project name outside the default and env-gated regions exits non-zero", %{
      tmp_dir: tmp_dir
    } do
      root =
        mutated_root(
          tmp_dir,
          @config_rel,
          &String.replace(
            &1,
            "export default defineConfig({",
            "const orphan = [{ name: \"orphan-capture\" }];\n\nexport default defineConfig({"
          )
        )

      assert {_output, status} = run_script([], root)
      assert status != 0
    end
  end

  describe "comment and name controls (only comment-stripped run: bodies count)" do
    test "a YAML comment naming a project leaves the output unchanged", %{tmp_dir: tmp_dir} do
      root =
        mutated_root(
          tmp_dir,
          @ci_rel,
          &String.replace(&1, "\njobs:\n", "\njobs:\n  # see --project=route-capture\n",
            global: false
          )
        )

      assert {output, 0} = run_script([], root)
      assert lines(output) == flags(@live_browser_full)
    end

    test "shell comments inside run: bodies leave the output unchanged", %{tmp_dir: tmp_dir} do
      root =
        mutated_root(tmp_dir, @ci_rel, fn yaml ->
          yaml
          |> String.replace(
            "          createdb -h",
            "          # e.g. --project=route-capture\n          createdb -h"
          )
          |> String.replace(
            "run: mix verify.format\n",
            "run: mix verify.format # --project=route-capture\n"
          )
        end)

      assert {output, 0} = run_script([], root)
      assert lines(output) == flags(@live_browser_full)
    end

    test "a name: value naming a project leaves the output unchanged", %{tmp_dir: tmp_dir} do
      root =
        mutated_root(
          tmp_dir,
          @ci_rel,
          &String.replace(
            &1,
            "- name: Run example Playwright suite\n",
            "- name: Run example Playwright suite --project=route-capture\n"
          )
        )

      assert {output, 0} = run_script([], root)
      assert lines(output) == flags(@live_browser_full)
    end
  end

  describe "conditional and non-command controls (218 review WR-05)" do
    # A --project flag counts as "CI runs it" only when it is an argument of a
    # mix/npx command in an unconditional step of an unconditional job. A flag
    # behind an if: (step or job) may never run on PR or push, so the script
    # refuses rather than dropping the project from Browser-full into nowhere.
    test "a step-level if: on the --project-bearing run step exits non-zero", %{
      tmp_dir: tmp_dir
    } do
      root =
        mutated_root(
          tmp_dir,
          @ci_rel,
          &String.replace(
            &1,
            "      - name: Run example Playwright suite\n        timeout-minutes: 14\n",
            "      - name: Run example Playwright suite\n" <>
              "        if: github.event_name == 'schedule'\n        timeout-minutes: 14\n"
          )
        )

      assert {output, status} = run_script([], root)
      assert status == 1
      assert output =~ "if:"
      assert output =~ "desktop-chromium"
    end

    test "a job-level if: on a job whose run body reaches --project flags exits non-zero", %{
      tmp_dir: tmp_dir
    } do
      root =
        mutated_root(
          tmp_dir,
          @ci_rel,
          &String.replace(
            &1,
            "  verify-example-browser:\n    name: ",
            "  verify-example-browser:\n    if: github.event_name == 'schedule'\n    name: "
          )
        )

      assert {output, status} = run_script([], root)
      assert status == 1
      assert output =~ "verify-example-browser"
    end

    test "an if: on a step with no --project flag leaves the output unchanged", %{
      tmp_dir: tmp_dir
    } do
      root =
        mutated_root(
          tmp_dir,
          @ci_rel,
          &String.replace(
            &1,
            "      - name: Discover required operator journeys\n",
            "      - name: Unrelated conditional step\n" <>
              "        if: github.event_name == 'schedule'\n        run: mix verify.format\n\n" <>
              "      - name: Discover required operator journeys\n"
          )
        )

      assert {output, 0} = run_script([], root)
      assert lines(output) == flags(@live_browser_full)
    end

    test "a --project flag inside echo text is not a CI run", %{tmp_dir: tmp_dir} do
      root =
        mutated_root(
          tmp_dir,
          @ci_rel,
          &String.replace(
            &1,
            ~s(echo "THREADLINE_EXAMPLE_BUILD_CACHE=${state} key=${EXAMPLE_BUILD_KEY}"),
            ~s(echo "THREADLINE_EXAMPLE_BUILD_CACHE=${state} key=${EXAMPLE_BUILD_KEY} --project=route-capture")
          )
        )

      assert {output, 0} = run_script([], root)
      assert lines(output) == flags(@live_browser_full)
    end

    test "a backslash-continued mix command still counts its --project flags", %{
      tmp_dir: tmp_dir
    } do
      root =
        mutated_root(
          tmp_dir,
          @ci_rel,
          &String.replace(
            &1,
            "run: mix verify.example_browser --project=desktop-chromium --project=mobile-chromium\n",
            "run: |\n          mix verify.example_browser \\\n" <>
              "            --project=desktop-chromium --project=mobile-chromium\n"
          )
        )

      assert {output, 0} = run_script([], root)
      assert lines(output) == flags(@live_browser_full)
    end
  end

  describe "matrix resolution (247-09, D-07 / RESEARCH Pitfall 1)" do
    # 247-10 splits verify-example-browser into a `strategy.matrix.project` job
    # whose run steps pass `--project=${{ matrix.project }}`. The script resolves
    # that expression from the enclosing job's matrix list and fails closed on
    # every other `${{ }}` value, so the split can never silently move the CI
    # projects into Browser-full or drop them from both lanes.
    @matrix_flag "--project=${{ matrix.project }}"
    @literal_flags "--project=desktop-chromium --project=mobile-chromium"
    @inline_matrix "        project: [desktop-chromium, mobile-chromium]\n"

    # Rewrite the live browser job into the matrix shape: a strategy.matrix block
    # under the job header, and the matrix expression in place of the literal
    # flags on both the mix and the --list lines.
    defp to_matrix_form(yaml, matrix_body \\ @inline_matrix) do
      header = "  verify-example-browser:\n"
      assert length(String.split(yaml, header)) == 2, "job header anchor is not unique"
      assert length(String.split(yaml, @literal_flags)) == 3, "literal flag anchors moved"

      yaml
      |> String.replace(
        header,
        header <> "    strategy:\n      fail-fast: false\n      matrix:\n" <> matrix_body,
        global: false
      )
      |> String.replace(@literal_flags, @matrix_flag)
    end

    defp matrix_root(tmp_dir, rewrite), do: mutated_root(tmp_dir, @ci_rel, rewrite)

    test "an inline matrix list resolves to CI and Browser-full excludes it", %{tmp_dir: tmp_dir} do
      root = matrix_root(tmp_dir, &to_matrix_form/1)
      assert live(@ci_rel) =~ @literal_flags
      refute File.read!(Path.join(root, @ci_rel)) =~ @literal_flags

      assert list!("ci", root) == @live_ci
      assert list!("browser-full", root) == @live_browser_full
      assert {output, 0} = run_script([], root)
      assert lines(output) == flags(@live_browser_full)
    end

    test "a block-sequence matrix list resolves the same way", %{tmp_dir: tmp_dir} do
      block =
        "        project:\n          - desktop-chromium # leg 1\n          - \"mobile-chromium\"\n"

      root = matrix_root(tmp_dir, &to_matrix_form(&1, block))

      assert list!("ci", root) == @live_ci
      assert list!("browser-full", root) == @live_browser_full
    end

    test "a matrix list missing mobile-chromium moves it into Browser-full", %{tmp_dir: tmp_dir} do
      root = matrix_root(tmp_dir, &to_matrix_form(&1, "        project: [desktop-chromium]\n"))

      assert list!("ci", root) == ["desktop-chromium"]
      assert "mobile-chromium" in list!("browser-full", root)
      assert {output, 0} = run_script([], root)
      assert "--project=mobile-chromium" in lines(output)
      refute "--project=desktop-chromium" in lines(output)
    end

    for {label, expression, reason} <- [
          {"${{ matrix.other }}", "${{ matrix.other }}", "matrix.other"},
          {"${{ env.P }}", "${{ env.P }}", "env.P"}
        ] do
      test "--project=#{label} exits 1 with a named message", %{tmp_dir: tmp_dir} do
        root =
          matrix_root(tmp_dir, fn yaml ->
            yaml
            |> to_matrix_form()
            |> String.replace(@matrix_flag, "--project=" <> unquote(expression), global: false)
          end)

        assert {output, 1} = run_script(["--list", "ci"], root)
        assert output =~ "job verify-example-browser"
        assert output =~ unquote(reason)
        assert output =~ "only ${{ matrix.project }} resolves"
      end
    end

    test "a project defined only under include: exits 1 with a named message", %{
      tmp_dir: tmp_dir
    } do
      include =
        "        include:\n          - project: desktop-chromium\n          - project: mobile-chromium\n"

      root = matrix_root(tmp_dir, &to_matrix_form(&1, include))

      assert {output, 1} = run_script(["--list", "ci"], root)
      assert output =~ "job verify-example-browser"
      assert output =~ "include:"
    end

    test "an empty matrix list exits 1 with a named message", %{tmp_dir: tmp_dir} do
      root = matrix_root(tmp_dir, &to_matrix_form(&1, "        project: []\n"))

      assert {output, 1} = run_script(["--list", "ci"], root)
      assert output =~ "job verify-example-browser"
      assert output =~ "strategy.matrix.project is empty"
    end

    test "an unparseable matrix list exits 1 with a named message", %{tmp_dir: tmp_dir} do
      dynamic = "        project: ${{ fromJSON(needs.plan.outputs.projects) }}\n"
      root = matrix_root(tmp_dir, &to_matrix_form(&1, dynamic))

      assert {output, 1} = run_script(["--list", "ci"], root)
      assert output =~ "job verify-example-browser"
      assert output =~ "cannot parse strategy.matrix.project"
    end

    test "a matrix flag in a job with no strategy.matrix exits 1", %{tmp_dir: tmp_dir} do
      root = matrix_root(tmp_dir, &String.replace(&1, @literal_flags, @matrix_flag))

      assert {output, 1} = run_script(["--list", "ci"], root)
      assert output =~ "job verify-example-browser"
      assert output =~ "no strategy.matrix.project"
    end

    test "a matrix flag behind a job-level if: is still refused", %{tmp_dir: tmp_dir} do
      root =
        matrix_root(tmp_dir, fn yaml ->
          yaml
          |> to_matrix_form()
          |> String.replace(
            "  verify-example-browser:\n",
            "  verify-example-browser:\n    if: github.event_name == 'schedule'\n",
            global: false
          )
        end)

      assert {output, 1} = run_script(["--list", "ci"], root)
      assert output =~ "verify-example-browser carries a job-level if:"
      assert output =~ "desktop-chromium"
    end
  end

  describe "browser-full.yml wiring" do
    @gate_if "if: steps.gate.outputs.decision == 'run'"
    @close_if "if: success() && steps.gate.outputs.decision == 'run'"
    @close_step "Close the browser-lane tracking issue on green"
    @issue_step "Open or update the nightly browser-lane tracking issue"
    @heavy_steps [
      "uses: erlef/setup-beam@",
      "uses: actions/setup-node@",
      "name: Cache deps",
      "name: Cache Playwright browsers",
      "name: Install root dependencies",
      "name: Ensure threadline_phoenix_test database exists",
      "name: Run example Playwright suite (projects ci.yml does not run)"
    ]

    # The body of the step whose first line contains `marker`, up to the next step.
    defp step(yaml, marker) do
      case String.split(yaml, marker, parts: 2) do
        [_, after_marker] -> after_marker |> String.split(~r/\n\s{6}- /, parts: 2) |> hd()
        [_] -> nil
      end
    end

    defp job_permissions(yaml) do
      [_, job] = String.split(yaml, "\n  verify-example-browser-full:\n", parts: 2)
      [header, _steps] = String.split(job, "\n    steps:\n", parts: 2)

      case Regex.run(~r/\n    permissions:\n((?:      .*\n)+)/, header <> "\n") do
        [_, block] -> block
        nil -> ""
      end
    end

    # True when the step body exists and contains every expected string/regex.
    defp has_all?(nil, _expected), do: false
    defp has_all?(body, expected), do: Enum.all?(expected, &(body =~ &1))

    defp wiring_violations(yaml) do
      gate = step(yaml, "name: Decide whether this SHA needs a browser-full run")
      close = step(yaml, @close_step)

      heavy =
        for marker <- @heavy_steps do
          {has_all?(step(yaml, marker), [@gate_if]), "heavy step #{marker} lacks the gate if:"}
        end

      [
        {has_all?(gate, [
           "id: gate",
           ~s(bin/ci-sha-gate --workflow browser-full.yml --sha "$GITHUB_SHA" --event "$GITHUB_EVENT_NAME")
         ]), "gate step must run bin/ci-sha-gate --workflow browser-full.yml as id: gate"},
        {job_permissions(yaml) =~ ~r/^\s+actions: read$/m, "job permissions lack actions: read"},
        {has_all?(close, [@close_if]), "close step must run only on success() of a run decision"},
        {has_all?(close, [
           ~s(bin/upsert-ci-issue --close --marker "$TITLE_PREFIX" --label "$LABEL" --body-file "$body_file")
         ]), "close step must call bin/upsert-ci-issue --close"},
        {has_all?(step(yaml, @issue_step), ["if: failure()"]),
         "failure-issue step must keep if: failure()"}
        | heavy
      ]
      |> Enum.reject(&elem(&1, 0))
      |> Enum.map(&elem(&1, 1))
      |> Kernel.++(CiIssuePairing.violations(yaml, @issue_step, @close_step))
    end

    test "gate, permissions, gated heavy steps, close-on-green and failure issue are wired" do
      assert wiring_violations(File.read!(@browser_full)) == []
    end

    test "wiring controls: dropped actions: read, ungated run step, or always() close are caught" do
      yaml = File.read!(@browser_full)

      no_actions = String.replace(yaml, "      actions: read\n", "")
      refute no_actions == yaml, "control did not change the input"
      assert "job permissions lack actions: read" in wiring_violations(no_actions)

      ungated =
        String.replace(
          yaml,
          "(projects ci.yml does not run)\n        #{@gate_if}\n",
          "(projects ci.yml does not run)\n"
        )

      refute ungated == yaml, "control did not change the input"
      assert Enum.any?(wiring_violations(ungated), &(&1 =~ "Run example Playwright suite"))

      always_close = String.replace(yaml, @close_if, "if: always()")
      refute always_close == yaml, "control did not change the input"

      assert "close step must run only on success() of a run decision" in wiring_violations(
               always_close
             )
    end

    test "wiring controls: renaming only the open step's TITLE_PREFIX or LABEL is caught (WR-06)" do
      yaml = File.read!(@browser_full)
      [before_close, close_and_after] = String.split(yaml, @close_step, parts: 2)

      for {from, to} <- [
            {~s|TITLE_PREFIX: "Browser (full project set) is failing"|,
             ~s|TITLE_PREFIX: "Browser-full is failing"|},
            {"LABEL: ci-browser-full\n", "LABEL: ci-browser\n"}
          ] do
        renamed_open = String.replace(before_close, from, to) <> @close_step <> close_and_after
        refute renamed_open == yaml, "control did not change the input"

        assert wiring_violations(renamed_open) != [],
               "renaming only the open step (#{to}) must fail the contract"
      end
    end
  end
end
