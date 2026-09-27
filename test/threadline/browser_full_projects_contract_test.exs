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

  @live_browser_full ~w(graded-capture refute-capture route-capture storybook-capture)
  @live_ci ~w(desktop-chromium mobile-chromium tier-a-capture tier-a-capture-light)

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

    test "the env-gated light project is never output" do
      for args <- [[], ["--list", "config"], ["--list", "ci"], ["--list", "browser-full"]] do
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
