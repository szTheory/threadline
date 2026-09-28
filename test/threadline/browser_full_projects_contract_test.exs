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
  as such an edge. Before 218-08, `refute-capture` needed the `tier-a-capture`
  cell directories but declared nothing: it passed only while Browser-full ran
  every project, and went red the moment the partition removed `tier-a-capture`.

  The test parses nothing itself: it runs the script against the live repo
  and against mutated copies under `tmp_dir` (`THREADLINE_BROWSER_FULL_ROOT`).
  Every mutation control first asserts the mutation changed its input, so a
  control can never pass over an unchanged file.
  """
  use ExUnit.Case, async: true

  import Bitwise

  @moduletag :tmp_dir

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "bin/browser-full-projects")
  @config_rel "examples/threadline_phoenix/e2e/playwright.config.ts"
  @ci_rel ".github/workflows/ci.yml"
  @mix_rel "mix.exs"
  @browser_full Path.join(@repo_root, ".github/workflows/browser-full.yml")
  @specs_dir Path.join(@repo_root, "examples/threadline_phoenix/e2e/tests")

  # Cross-project filesystem prerequisites the specs state, keyed by the
  # dependent project: {spec file that states it, prerequisite project}.
  # operator-refute-capture.spec.ts only overwrites screenshot binaries inside
  # the artifacts/tier-a cell directories that tier-a-capture creates in the
  # same checkout, and fails with "run the tier-a-capture lane first" otherwise.
  @stated_prerequisites %{
    "refute-capture" => {"operator-refute-capture.spec.ts", "tier-a-capture"}
  }
  @stated_prerequisite ~r/run the ([a-z0-9-]+) lane first/

  @live_browser_full ~w(graded-capture refute-capture route-capture storybook-capture)
  @live_ci ~w(desktop-chromium mobile-chromium tier-a-capture tier-a-capture-light)
  @live_deps ["refute-capture tier-a-capture"]

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
  defp mutated_root(tmp_dir, rel, mutate) do
    for input <- [@config_rel, @ci_rel, @mix_rel] do
      dest = Path.join(tmp_dir, input)
      File.mkdir_p!(Path.dirname(dest))
      File.write!(dest, live(input))
    end

    original = live(rel)
    mutated = mutate.(original)
    refute mutated == original, "control did not change #{rel}"
    File.write!(Path.join(tmp_dir, rel), mutated)
    tmp_dir
  end

  defp flags(names), do: Enum.map(names, &"--project=#{&1}")

  # Every stated prerequisite of a Browser-full project that ci.yml owns must be
  # a declared `dependencies` edge, or Browser-full runs the dependent without it.
  defp prerequisite_violations(root) do
    full = list!("browser-full", root)
    deps = list!("deps", root)

    for {project, {_spec, prerequisite}} <- @stated_prerequisites,
        project in full,
        prerequisite not in full,
        "#{project} #{prerequisite}" not in deps do
      "#{project} needs #{prerequisite} (stated in its spec) but does not declare " <>
        "dependencies: [\"#{prerequisite}\"] in playwright.config.ts; Browser-full would " <>
        "run it without the prerequisite"
    end
  end

  describe "live repo partition" do
    test "--list config is the eight default-config projects" do
      assert list!("config") ==
               Enum.sort(@live_ci ++ @live_browser_full)
    end

    test "--list ci is the projects ci.yml runs, including those behind mix verify.capture" do
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

      assert executed == Enum.sort(@live_browser_full ++ ["tier-a-capture"])
    end

    test "every stated cross-project filesystem prerequisite is in the table" do
      stated =
        for spec <- File.ls!(@specs_dir),
            String.ends_with?(spec, ".spec.ts"),
            [_, prerequisite] <-
              Regex.scan(@stated_prerequisite, File.read!(Path.join(@specs_dir, spec))),
            uniq: true,
            do: {spec, prerequisite}

      assert stated != [], "the prerequisite scan found nothing; it would pass vacuously"

      assert Enum.sort(stated) == Enum.sort(Map.values(@stated_prerequisites)),
             "a spec states a `run the <project> lane first` prerequisite that " <>
               "@stated_prerequisites does not model (or the table names one no spec states)"
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

    test "removing run: mix verify.capture from ci.yml moves both tier-a projects into the output",
         %{tmp_dir: tmp_dir} do
      root =
        mutated_root(
          tmp_dir,
          @ci_rel,
          &String.replace(&1, "        run: mix verify.capture\n", "")
        )

      assert {output, 0} = run_script([], root)
      assert "--project=tier-a-capture" in lines(output)
      assert "--project=tier-a-capture-light" in lines(output)
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

    test "removing refute-capture's dependencies declaration turns the contract red", %{
      tmp_dir: tmp_dir
    } do
      root =
        mutated_root(
          tmp_dir,
          @config_rel,
          &Regex.replace(~r/\n\s*dependencies: \["tier-a-capture"\],/, &1, "")
        )

      assert list!("browser-full", root) == @live_browser_full
      assert list!("deps", root) == []
      assert [violation] = prerequisite_violations(root)
      assert violation =~ "refute-capture needs tier-a-capture"
    end

    test "a dependency naming an unregistered project exits non-zero", %{tmp_dir: tmp_dir} do
      root =
        mutated_root(
          tmp_dir,
          @config_rel,
          &String.replace(
            &1,
            ~s(dependencies: ["tier-a-capture"]),
            ~s(dependencies: ["ghost-capture"])
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
          &String.replace(&1, "\njobs:\n", "\njobs:\n  # see --project=graded-capture\n",
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
            "run: mix verify.format # --project=storybook-capture\n"
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
            "- name: Regenerate Tier A capture\n",
            "- name: Regenerate Tier A capture --project=refute-capture\n"
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
            "  verify-capture:\n    name: ",
            "  verify-capture:\n    if: github.event_name == 'schedule'\n    name: "
          )
        )

      assert {output, status} = run_script([], root)
      assert status == 1
      assert output =~ "verify-capture"
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
            "      - name: Regenerate Tier A capture\n        run: mix verify.capture\n",
            "      - name: Regenerate Tier A capture\n        run: mix verify.capture\n\n" <>
              "      - name: Unrelated conditional step\n" <>
              "        if: github.event_name == 'schedule'\n        run: mix verify.format\n"
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
            ~s(echo "Regenerate locally with 'mix verify.capture' and commit the result."),
            ~s(echo "Regenerate locally with 'mix verify.capture --project=graded-capture' and commit the result.")
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
        {has_all?(close, [
           ~s|TITLE_PREFIX: "Browser (full project set) is failing"|,
           ~r/^\s+LABEL: ci-browser-full$/m
         ]), "close step must use the issue step's TITLE_PREFIX and LABEL"},
        {has_all?(step(yaml, @issue_step), ["if: failure()"]),
         "failure-issue step must keep if: failure()"}
        | heavy
      ]
      |> Enum.reject(&elem(&1, 0))
      |> Enum.map(&elem(&1, 1))
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
  end
end
