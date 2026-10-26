defmodule Threadline.DepsHealthDocContractTest do
  @moduledoc """
  SUP-04 doc contract: binds `.github/workflows/deps-health.yml` and
  `bin/deps-health-report`/`bin/verify-deps-audit`'s shared canonical
  lockfile-directory literal to CONTRIBUTING.md's "## Dependency freshness
  policy" section, and asserts the lane's structural safety invariants
  (least-privilege permissions, non-required status, label distinctness).

  Every fact is DERIVED from source with a regex — never restated as a
  literal expectation — except the mandatory policy terms (245 D-06: the
  Dependabot role, "one grouped monthly pull request", "does not support Hex
  security updates", `mix verify.deps_audit`, "never auto-merge", and
  "release train"). This
  keeps the test unable to drift silently: if the workflow's cron, label, or
  lockfile list ever changes, this test fails until CONTRIBUTING.md is
  updated to match, rather than the two files quietly diverging.

  Two failure modes are deliberately kept distinct, matching the pattern in
  `ci_coverage_doc_contract_test.exs`:

    * A derive source finds NOTHING (a moved workflow, a changed flag
      spelling) — the guard would otherwise pass vacuously while asserting
      nothing, which is worse than not having the guard at all.
    * A fact the workflow/scripts actually carry is MISSING from the
      CONTRIBUTING.md section — the doc has drifted behind the pipeline.

  Filename ends in `doc_contract_test.exs`, so `bin/verify-bump-rehearsal`
  also runs it in its throwaway clone; it is fully offline and static, so
  that is safe (no network, no mix hex.* calls of its own).
  """

  use ExUnit.Case, async: true
  @moduletag :repo_contract

  alias Threadline.Test.CiIssuePairing

  @repo_root File.cwd!()
  @deps_health_workflow Path.join([@repo_root, ".github", "workflows", "deps-health.yml"])
  @deps_health_report Path.join([@repo_root, "bin", "deps-health-report"])
  @verify_deps_audit Path.join([@repo_root, "bin", "verify-deps-audit"])
  @ci_yml Path.join([@repo_root, ".github", "workflows", "ci.yml"])
  @ruleset Path.join([@repo_root, ".github", "rulesets", "main.json"])
  @contributing Path.join(@repo_root, "CONTRIBUTING.md")
  @policy_heading "## Dependency freshness policy"

  defp deps_health_yaml, do: File.read!(@deps_health_workflow)

  defp crons do
    deps_health_yaml()
    |> then(&Regex.scan(~r/cron:\s*"([^"]+)"/, &1))
    |> Enum.map(fn [_, cron] -> cron end)
  end

  defp label do
    [_, value] = Regex.run(~r/LABEL:\s*(\S+)/, deps_health_yaml())
    value
  end

  defp canonical_dir_line!(path) do
    content = File.read!(path)

    case Regex.run(~r/^CANONICAL_DIRS=\((.+)\)$/m, content) do
      [_, dirs] -> dirs
      nil -> flunk("no CANONICAL_DIRS=(...) literal found in #{path}")
    end
  end

  defp lockfiles do
    @verify_deps_audit
    |> canonical_dir_line!()
    |> String.split()
    |> Enum.map(fn
      "." -> "mix.lock"
      dir -> dir <> "/mix.lock"
    end)
  end

  defp rank_names!(path) do
    content = File.read!(path)

    case Regex.run(~r/^RANK_NAMES=\((.+)\)$/m, content) do
      [_, names] -> String.split(names)
      nil -> flunk("no RANK_NAMES=(...) literal found in #{path}")
    end
  end

  defp policy_section do
    contributing = File.read!(@contributing)

    assert String.contains?(contributing, @policy_heading),
           "CONTRIBUTING.md has no `#{@policy_heading}` heading — the freshness policy this " <>
             "test derives from the workflow/scripts must be stated in the contributor docs."

    contributing
    |> String.split(@policy_heading, parts: 2)
    |> List.last()
    |> String.split(~r/\n## /, parts: 2)
    |> List.first()
  end

  defp other_workflow_labels do
    workflow_glob = Path.join([@repo_root, ".github", "workflows", "*.{yml,yaml}"])

    for path <- Path.wildcard(workflow_glob),
        path != @deps_health_workflow,
        [_, value] <- Regex.scan(~r/LABEL:\s*(\S+)/, File.read!(path)),
        uniq: true,
        do: value
  end

  defp workflow_level_block do
    yaml = deps_health_yaml()

    case String.split(yaml, "\njobs:", parts: 2) do
      [before, _] -> before
      _ -> flunk("deps-health.yml has no `jobs:` key to split the workflow-level block on")
    end
  end

  defp deps_health_job_block do
    yaml = deps_health_yaml()

    case String.split(yaml, "\n  deps-health:", parts: 2) do
      [_, tail] -> tail
      _ -> flunk("deps-health.yml has no `  deps-health:` job")
    end
  end

  test "derive sources are non-vacuous: crons, label, and canonical dirs are each non-empty" do
    assert crons() != [], "no cron: \"...\" schedules found in deps-health.yml"
    assert label() != nil and label() != "", "no LABEL: value found in deps-health.yml"

    report_dirs = canonical_dir_line!(@deps_health_report)
    audit_dirs = canonical_dir_line!(@verify_deps_audit)

    assert report_dirs != "", "no CANONICAL_DIRS literal found in bin/deps-health-report"
    assert audit_dirs != "", "no CANONICAL_DIRS literal found in bin/verify-deps-audit"
  end

  test "bin/deps-health-report and bin/verify-deps-audit declare the identical canonical dir literal" do
    report_dirs = canonical_dir_line!(@deps_health_report)
    audit_dirs = canonical_dir_line!(@verify_deps_audit)

    assert report_dirs == audit_dirs,
           "bin/deps-health-report's CANONICAL_DIRS (#{inspect(report_dirs)}) must match " <>
             "bin/verify-deps-audit's (#{inspect(audit_dirs)}) — a drift here means the weekly " <>
             "lane and the per-PR gate silently disagree on which lockfiles are covered"
  end

  test "every derived cron string appears in the freshness policy section" do
    section = policy_section()

    for cron <- crons() do
      assert section =~ cron,
             "CONTRIBUTING.md's #{@policy_heading} section is missing the cron schedule " <>
               "#{inspect(cron)}, which .github/workflows/deps-health.yml actually runs on"
    end
  end

  test "the derived label appears in the freshness policy section" do
    section = policy_section()

    assert section =~ label(),
           "CONTRIBUTING.md's #{@policy_heading} section is missing the label #{inspect(label())}"
  end

  test "every canonical lockfile path appears in the freshness policy section" do
    section = policy_section()

    lockfiles = lockfiles()

    assert length(lockfiles) >= 3,
           "expected >= 3 CANONICAL_DIRS lockfiles, got #{inspect(lockfiles)}"

    for lockfile <- lockfiles do
      assert section =~ lockfile,
             "CONTRIBUTING.md's #{@policy_heading} section is missing the lockfile path " <>
               "#{inspect(lockfile)}"
    end
  end

  test "the policy section states the mandatory sentences and terms" do
    section = policy_section()

    assert section =~ "one grouped monthly pull request"
    assert section =~ "does not support Hex security updates"
    assert section =~ "mix verify.deps_audit"
    assert section =~ "never auto-merge"
    assert section =~ "hex.audit"
    assert section =~ "release train"
    assert section =~ "verify-deps-audit"
    assert section =~ "hex_audit_ignores"
  end

  test "the policy section names the action pin provenance check and the pending setting (D-14, D-15)" do
    section = policy_section()

    assert section =~ "bin/verify-action-pins"
    assert section =~ "sha_pinning_required"
    assert section =~ "never runs on pull requests"
  end

  test "the deps-health report step passes GH_TOKEN to the pin provenance check" do
    report_step =
      case String.split(deps_health_yaml(), "- name: Classify hex.audit over all three lockfiles",
             parts: 2
           ) do
        [_, tail] -> tail |> String.split(~r/\n      - /, parts: 2) |> List.first()
        _ -> flunk("deps-health.yml has no `Classify hex.audit over all three lockfiles` step")
      end

    assert report_step =~ ~r/^\s*id: report\s*$/m

    assert report_step =~
             ~r/^        env:\n          GH_TOKEN: \$\{\{ secrets\.GITHUB_TOKEN \}\}$/m,
           "the report step runs bin/verify-action-pins, which needs GH_TOKEN for its read-only API calls"
  end

  test "bin/verify-action-pins is never run by ci.yml" do
    refute File.read!(@ci_yml) =~ "verify-action-pins",
           "the pin provenance check runs only in the scheduled deps-health lane, never in PR CI"
  end

  @tier_sections ["Blocking — shipped runtime", "Non-blocking — dev/test/bench/example"]

  test "the policy section states the SUP-03 tier rule and the D-16 policy change" do
    section = policy_section()

    assert section =~ "--only prod"

    assert section =~
             "Advisories in root dev/test-only dependencies no longer block a pull request or a release"

    assert section =~ "no longer block"

    for title <- @tier_sections do
      assert section =~ title, "CONTRIBUTING.md's #{@policy_heading} section must name #{title}"
    end
  end

  test "bin/deps-health-report writes both tier section titles CONTRIBUTING names" do
    report = File.read!(@deps_health_report)

    for title <- @tier_sections do
      assert report =~ title, "bin/deps-health-report must write the section #{title}"
    end
  end

  test "the class set CONTRIBUTING names equals bin/deps-health-report's RANK_NAMES (D-29)" do
    names = rank_names!(@deps_health_report)

    assert names == ["clean", "unknown", "retirement", "advisory"],
           "RANK_NAMES must be the D-25 precedence order, got #{inspect(names)}"

    section = policy_section()

    # The precedence sentence lists every class, highest first; compare it in
    # both directions so a class the classifier no longer emits cannot return.
    [_, chain] =
      Regex.run(~r/highest wins.*?:\s*(`[a-z]+`.*?`clean`)/s, section) ||
        flunk(
          "CONTRIBUTING.md's #{@policy_heading} section lost its `highest wins` precedence sentence"
        )

    documented = ~r/`([a-z]+)`/ |> Regex.scan(chain, capture: :all_but_first) |> List.flatten()

    assert documented == Enum.reverse(names),
           "CONTRIBUTING.md's precedence classes #{inspect(documented)} must equal RANK_NAMES highest first"

    refute section =~ "`outdated`",
           "`outdated` is not a class bin/deps-health-report emits (D-24)"
  end

  test "the policy section no longer says a finding alone stays green (D-24)" do
    refute policy_section() =~ "alone stays green"
  end

  test ".github/dependabot.yml exists and is the only Dependabot config" do
    assert File.exists?(Path.join([@repo_root, ".github", "dependabot.yml"]))
    refute File.exists?(Path.join([@repo_root, ".github", "dependabot.yaml"]))
  end

  test "deps-health.yml has workflow_dispatch and a schedule trigger" do
    yaml = deps_health_yaml()

    assert yaml =~ ~r/^\s*workflow_dispatch:\s*$/m
    assert yaml =~ ~r/^\s*schedule:\s*$/m
  end

  test "the workflow-level block before jobs: grants no write permission" do
    refute workflow_level_block() =~ "write",
           "deps-health.yml's workflow-level permissions (before `jobs:`) must not grant any " <>
             "write scope — issues: write is scoped to the deps-health job only"
  end

  test "the deps-health job grants issues: write" do
    assert deps_health_job_block() =~ ~r/issues:\s*write/,
           "the deps-health job must grant issues: write to upsert the ci-deps issue"
  end

  test "deps-health.yml declares a concurrency group with cancel-in-progress: false" do
    yaml = deps_health_yaml()

    assert yaml =~ ~r/concurrency:/
    assert yaml =~ ~r/cancel-in-progress:\s*false/
  end

  test "deps-health.yml calls bin/upsert-ci-issue" do
    assert deps_health_yaml() =~ "bin/upsert-ci-issue"
  end

  test "deps-health.yml closes the tracking issue only on a clean classification" do
    yaml = deps_health_yaml()

    assert yaml =~ "upsert-ci-issue --close",
           "deps-health.yml must close the ci-deps issue via bin/upsert-ci-issue --close (ECON-02)"

    close_step =
      case String.split(yaml, "- name: Close the dependency health issue on a clean run",
             parts: 2
           ) do
        [_, tail] ->
          tail |> String.split(~r/\n      - /, parts: 2) |> List.first()

        _ ->
          flunk("deps-health.yml has no `Close the dependency health issue on a clean run` step")
      end

    assert close_step =~ ~r/^\s*if: steps\.report\.outputs\.classification == 'clean'\s*$/m,
           "the close step must run only when classification == 'clean' (never on advisory, " <>
             "retirement, unknown, or an empty/crashed report)"

    assert close_step =~ "upsert-ci-issue --close",
           "the `clean` gate must sit on the step that runs upsert-ci-issue --close"
  end

  describe "close step targets the issue the open step files (218 review WR-06)" do
    @open_step "Open or update the dependency health issue"
    @close_step "Close the dependency health issue on a clean run"

    test "the close step's TITLE_PREFIX and LABEL equal the open step's" do
      assert CiIssuePairing.violations(deps_health_yaml(), @open_step, @close_step) == []
    end

    test "control: renaming only the open step's TITLE_PREFIX or LABEL is caught" do
      yaml = deps_health_yaml()
      [before_close, close_and_after] = String.split(yaml, "- name: " <> @close_step, parts: 2)

      for {from, to} <- [
            {~s(TITLE_PREFIX: "Dependency health"), ~s(TITLE_PREFIX: "Dependency report")},
            {"LABEL: ci-deps\n", "LABEL: ci-dependencies\n"}
          ] do
        renamed_open =
          String.replace(before_close, from, to) <> "- name: " <> @close_step <> close_and_after

        refute renamed_open == yaml, "control did not change the input"

        refute CiIssuePairing.violations(renamed_open, @open_step, @close_step) == [],
               "renaming only the open step (#{to}) must fail the contract"
      end
    end
  end

  test "the ci-deps label is distinct from every other workflow's LABEL: value" do
    others = other_workflow_labels()

    assert length(others) >= 2,
           "expected at least 2 other workflow LABEL: values to compare against (derive " <>
             "source broken?), found #{inspect(others)}"

    refute label() in others,
           "the deps-health label #{inspect(label())} must differ from every other in-repo " <>
             "workflow's LABEL: value #{inspect(others)}, so the dedup streams never merge"
  end

  defp required_context_hits(ruleset, name) do
    contexts =
      for %{"type" => "required_status_checks", "parameters" => params} <- ruleset["rules"],
          check <- params["required_status_checks"],
          do: check["context"]

    if contexts == [], do: flunk("no required_status_checks contexts in #{@ruleset}")
    Enum.filter(contexts, &(&1 == name))
  end

  test "the deps-health job name appears in no ruleset required context" do
    ruleset = @ruleset |> File.read!() |> Jason.decode!()
    job_name = YamlElixir.read_from_string!(deps_health_yaml())["jobs"]["deps-health"]["name"]

    assert is_binary(job_name) and job_name != "", "deps-health job has no name: in the workflow"

    assert required_context_hits(ruleset, job_name) == [],
           "#{@ruleset} must not name #{inspect(job_name)} as a required status check"

    # Negative control: the same ruleset with the job name appended must report a hit.
    rsc = Access.filter(&(&1["type"] == "required_status_checks"))
    path = ["rules", rsc, "parameters", "required_status_checks"]
    extra = %{"context" => job_name, "integration_id" => 15_368}
    promoted = update_in(ruleset, path, &(&1 ++ [extra]))

    refute promoted == ruleset
    assert required_context_hits(promoted, job_name) == [job_name]
  end
end
