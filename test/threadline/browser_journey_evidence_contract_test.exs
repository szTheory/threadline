defmodule Threadline.BrowserJourneyEvidenceContractTest do
  use ExUnit.Case, async: true
  @moduletag :repo_contract

  @repo_root Path.expand("../..", __DIR__)
  @e2e_root Path.join(@repo_root, "examples/threadline_phoenix/e2e")
  @inventory_path Path.join(@e2e_root, "support/operator-journey-inventory.json")
  @config_path Path.join(@e2e_root, "playwright.config.ts")
  @workflow_path Path.join(@repo_root, ".github/workflows/ci.yml")
  @browser_full_workflow Path.join(@repo_root, ".github/workflows/browser-full.yml")
  @browser_full_projects Path.join(@repo_root, "bin/browser-full-projects")
  @playwright Path.join(@e2e_root, "node_modules/.bin/playwright")
  @projects ["desktop-chromium", "mobile-chromium"]

  defp read!(path), do: File.read!(path)

  defp inventory! do
    @inventory_path |> read!() |> Jason.decode!()
  end

  defp identity_pattern(identity) do
    title_path = Enum.join(identity["titlePath"], " › ")

    Regex.compile!(
      "^\\s+\\[#{Regex.escape(identity["project"])}\\] › #{Regex.escape(identity["file"])}:\\d+:\\d+ › #{Regex.escape(title_path)}$",
      "m"
    )
  end

  defp browser_full_row! do
    case Enum.filter(
           inventory!()["rows"],
           &(&1["voting"] == "nonvoting" and String.contains?(&1["reason"], "Browser-full"))
         ) do
      [row] -> row
      rows -> flunk("expected one nonvoting Browser-full inventory row, got #{length(rows)}")
    end
  end

  test "the inventory has a bounded required matrix and explicit nonvoting limits" do
    inventory = inventory!()
    required = Enum.filter(inventory["rows"], &(&1["voting"] == "required"))
    nonvoting = Enum.filter(inventory["rows"], &(&1["voting"] == "nonvoting"))
    categories = required |> Enum.map(& &1["category"]) |> MapSet.new()

    expected_categories =
      ~w(investigation actor-correlation saved-search evidence coverage-redaction export-download-return export-failure retention retention-denial disconnect-reconnect accessibility-responsive reduced-motion desktop-zoom)

    assert inventory["votingProjects"] == @projects
    assert length(required) >= 20 and length(required) <= 40

    assert Enum.all?(expected_categories, &MapSet.member?(categories, &1)),
           "required journeys omit a supported category"

    assert Enum.all?(nonvoting, &(is_binary(&1["reason"]) and String.trim(&1["reason"]) != ""))
    assert Enum.any?(nonvoting, &String.contains?(&1["reason"], "Light/System"))
    assert Enum.any?(nonvoting, &String.contains?(&1["reason"], "Browser-full"))

    assert Enum.any?(
             nonvoting,
             &String.contains?(String.downcase(&1["reason"]), "browser limitation")
           )

    identities = Enum.map(required, & &1["identity"])

    assert length(identities) == length(Enum.uniq_by(identities, &Jason.encode!/1)),
           "required identity is duplicated"
  end

  test "every required journey is discovered exactly once by the real voting Playwright projects" do
    assert File.regular?(@playwright),
           "Playwright CLI is missing; install the locked E2E dependencies"

    args = ["test", "--list"] ++ Enum.map(@projects, &"--project=#{&1}")
    {output, 0} = System.cmd(@playwright, args, cd: @e2e_root, stderr_to_stdout: true)
    assert output =~ "Total:", "Playwright list produced no test summary"

    for row <- inventory!()["rows"], row["voting"] == "required" do
      identity = row["identity"]
      title_path = Enum.join(identity["titlePath"], " › ")

      pattern =
        Regex.compile!(
          "^\\s+\\[#{Regex.escape(identity["project"])}\\] › #{Regex.escape(identity["file"])}:\\d+:\\d+ › #{Regex.escape(title_path)}$",
          "m"
        )

      matches = Regex.scan(pattern, output)

      assert length(matches) == 1,
             "expected one discovered identity for #{row["journey"]}: #{identity["project"]} / #{title_path}; got #{length(matches)}"
    end
  end

  # Browser-full runs the projects bin/browser-full-projects prints (since 246 only
  # route-capture). Every route-capture test except the render smoke skips unless
  # THREADLINE_E2E_EVIDENCE=1, so this proves the lane cannot go vacuously green:
  # the render smoke is discovered under the lane's own flags, and the only
  # non-project skip it carries (evidence mode) cannot fire there.
  test "Browser-full discovers and cannot skip its route-capture render smoke" do
    assert File.regular?(@playwright),
           "Playwright CLI is missing; install the locked E2E dependencies"

    {flags_output, 0} = System.cmd(@browser_full_projects, [], stderr_to_stdout: true)
    flags = String.split(flags_output, "\n", trim: true)

    assert flags != [] and Enum.all?(flags, &String.starts_with?(&1, "--project=")),
           "bin/browser-full-projects printed no --project flags: #{inspect(flags_output)}"

    {output, 0} =
      System.cmd(@playwright, ["test", "--list" | flags], cd: @e2e_root, stderr_to_stdout: true)

    assert [_, total] = Regex.run(~r/^Total: (\d+) tests? in \d+ files?$/m, output),
           "Playwright list produced no test summary"

    assert String.to_integer(total) >= 1, "Browser-full lists no tests"

    row = browser_full_row!()
    assert "--project=#{row["identity"]["project"]}" in flags

    assert length(Regex.scan(identity_pattern(row["identity"]), output)) == 1,
           "expected the Browser-full render smoke #{inspect(row["identity"]["titlePath"])} " <>
             "to be discovered exactly once"

    refute read!(@browser_full_workflow) =~ "THREADLINE_E2E_EVIDENCE",
           "browser-full.yml sets THREADLINE_E2E_EVIDENCE, which skips the render smoke"

    # Negative control: the same identity regex over a listing without the title.
    synthetic =
      "Listing tests:\n  [route-capture] › operator-page-capture.spec.ts:1:1 › other › title\n" <>
        "Total: 1 test in 1 file\n"

    assert Regex.scan(identity_pattern(row["identity"]), synthetic) == []
  end

  test "required CI reconciles native evidence and ci-required still fails on every non-success" do
    workflow = read!(@workflow_path)
    config = read!(@config_path)
    [browser_jobs, required_job] = String.split(workflow, "  ci-required:\n", parts: 2)

    # 247 D-07/D-07a: one matrix leg per project, then the fan-in receipt job.
    [browser_job, receipt_job] =
      String.split(browser_jobs, "\n  verify-example-browser-receipt:\n", parts: 2)

    [_, test_workflow] = String.split(workflow, "  verify-test:\n", parts: 2)
    [test_job, _] = String.split(test_workflow, "\n  verify-example-browser:\n", parts: 2)

    # Node runs only in :repo_contract files, which the min and latest lanes
    # drop, so both Node steps are guarded to the current lane only.
    current_only = "        if: matrix.lane == 'current'\n"

    assert test_job =~
             "- name: Set up Node for browser journey contract\n" <>
               current_only <> "        uses: actions/setup-node@"

    assert test_job =~ "cache-dependency-path: examples/threadline_phoenix/e2e/package-lock.json"

    assert test_job =~
             "- name: Install locked E2E dependencies for browser journey contract\n" <>
               current_only <>
               "        working-directory: examples/threadline_phoenix/e2e\n        run: npm ci"

    assert :binary.match(test_job, "run: npm ci") < :binary.match(test_job, "- name: Run tests"),
           "locked E2E dependencies must be installed before ExUnit invokes Playwright"

    assert browser_job =~ "  verify-example-browser:\n", "stable browser job ID changed"

    assert browser_job =~ "        project: [desktop-chromium, mobile-chromium]\n"
    assert browser_job =~ "mix verify.example_browser --project=${{ matrix.project }}"

    assert browser_job =~
             "PLAYWRIGHT_JSON_OUTPUT_FILE: ${{ runner.temp }}/operator-ci-executed-${{ matrix.project }}-${{ github.run_id }}.json"

    assert config =~ "process.env.PLAYWRIGHT_JSON_OUTPUT_FILE"
    assert config =~ "[[\"github\"], [\"json\"]]"

    assert browser_job =~
             "./node_modules/.bin/playwright test --list --project=${{ matrix.project }}"

    # Each leg uploads its own executed report and discovered list; the leg
    # reconciles nothing itself.
    assert browser_job =~ "name: operator-ci-executed-${{ matrix.project }}-${{ github.run_id }}"

    assert browser_job =~
             "name: operator-ci-discovered-${{ matrix.project }}-${{ github.run_id }}"

    assert browser_job =~ "name: browser-timings-${{ matrix.project }}-${{ github.run_id }}"
    assert browser_job =~ "name: example-browser-e2e-diagnostics-${{ matrix.project }}"
    assert browser_job =~ "actions/upload-artifact@"
    refute browser_job =~ "support/operator-ci-evidence.ts --verify"
    refute browser_job =~ "path: examples/threadline_phoenix/e2e/test-results"

    # The fan-in reconciles every leg's evidence into one receipt.
    assert receipt_job =~ "    needs: verify-example-browser\n"
    assert receipt_job =~ "pattern: operator-ci-executed-*-${{ github.run_id }}"
    assert receipt_job =~ "pattern: operator-ci-discovered-*-${{ github.run_id }}"
    assert receipt_job =~ "merge-multiple: true"
    assert receipt_job =~ "support/operator-ci-evidence.ts --verify"
    assert receipt_job =~ "operator-journey-inventory.json"
    assert receipt_job =~ "args+=(--discovered \"$f\")"
    assert receipt_job =~ "args+=(--executed \"$f\")"
    assert receipt_job =~ "actions/upload-artifact@"
    assert receipt_job =~ "retention-days: 14"
    assert receipt_job =~ "operator-ci-receipt-${{ github.run_id }}.json"
    assert receipt_job =~ "name: operator-ci-evidence-${{ github.run_id }}"
    refute receipt_job =~ "path: examples/threadline_phoenix/e2e/test-results"

    assert required_job =~ "    if: always()"
    assert required_job =~ "      - verify-example-browser\n"
    assert required_job =~ "      - verify-example-browser-receipt\n"
    assert required_job =~ "jobs: ${{ toJSON(needs) }}"
    assert workflow =~ "\n  ci-required:\n", "stable required job ID changed"
  end

  describe "CI-01 slowest browser specs (247 D-04..D-06)" do
    @package_json_path Path.join(@e2e_root, "package.json")
    @slow_specs_path Path.join(@e2e_root, "support/slow-specs.ts")
    @timings_step "Summarize slowest browser specs"
    @timings_upload "Upload browser spec timings"

    # Scope every search to the verify-example-browser job block so a timings
    # step anywhere else in ci.yml cannot satisfy the contract.
    defp browser_job_block(workflow_yaml) do
      with [before_required, _] <- String.split(workflow_yaml, "  ci-required:\n", parts: 2),
           [_, jobs] <- String.split(before_required, "  verify-example-browser:\n", parts: 2) do
        # Stop at the fan-in receipt job: the timings belong to the matrix legs.
        jobs |> String.split("\n  verify-example-browser-receipt:\n", parts: 2) |> hd()
      else
        _ -> ""
      end
    end

    defp step_block(job, name) do
      case String.split(job, "      - name: #{name}\n", parts: 2) do
        [_, rest] -> rest |> String.split("\n      - name: ", parts: 2) |> hd()
        _ -> ""
      end
    end

    defp test_unit_script(package_json) do
      case Jason.decode(package_json) do
        {:ok, %{"scripts" => %{"test:unit" => script}}} when is_binary(script) -> script
        _ -> ""
      end
    end

    defp slow_specs_errors(workflow_yaml, package_json) do
      job = browser_job_block(workflow_yaml)
      step = step_block(job, @timings_step)
      upload = step_block(job, @timings_upload)
      test_unit = test_unit_script(package_json)

      [
        {"rule=timings-step",
         step != "" and step =~ "working-directory: examples/threadline_phoenix/e2e" and
           step =~ "support/slow-specs.ts \"$report\" --label ${{ matrix.project }} --out"},
        {"rule=timings-always", step =~ ~r/^        if: always\(\)$/m},
        {"rule=timings-fail-soft", step != "" and not (step =~ "continue-on-error")},
        {"rule=timings-guard",
         step =~
           "report=\"${{ runner.temp }}/operator-ci-executed-${{ matrix.project }}-${{ github.run_id }}.json\"" and
           step =~ "if [ -f \"$report\" ]"},
        {"rule=timings-artifact",
         upload =~ ~r/^        if: always\(\)$/m and
           upload =~ "uses: actions/upload-artifact@" and
           upload =~ "name: browser-timings-" and
           upload =~ "path: ${{ runner.temp }}/browser-timings-"},
        {"rule=timings-retention", upload =~ ~r/^          retention-days: 14$/m},
        {"rule=test-unit-wiring",
         String.contains?(test_unit, "support/operator-ci-evidence.test.ts") and
           String.contains?(test_unit, "support/slow-specs.test.ts")}
      ]
      |> Enum.reject(fn {_rule, ok?} -> ok? end)
      |> Enum.map(fn {rule, _} -> rule end)
    end

    test "the live browser job publishes slowest-spec timings fail-soft" do
      assert slow_specs_errors(read!(@workflow_path), read!(@package_json_path)) == []

      script = read!(@slow_specs_path)
      assert script =~ "GITHUB_STEP_SUMMARY"
      assert script =~ "MAX_REPORT_BYTES"
      refute script =~ "process.exitCode = 1", "slow-specs must never fail the browser job"
      assert read!(@config_path) =~ "[[\"github\"], [\"json\"]]", "reporter config changed (D-04)"
    end

    test "each CI-01 rule goes red under its mutation" do
      workflow = read!(@workflow_path)
      package_json = read!(@package_json_path)

      step_header = "      - name: #{@timings_step}\n        if: always()\n"
      upload_header = "      - name: #{@timings_upload}\n        if: always()\n"

      controls = [
        {"rule=timings-step", String.replace(workflow, @timings_step, "Summarize browser specs"),
         package_json},
        {"rule=timings-always",
         String.replace(workflow, step_header, "      - name: #{@timings_step}\n"), package_json},
        {"rule=timings-fail-soft",
         String.replace(
           workflow,
           step_header,
           "      - name: #{@timings_step}\n        if: always()\n        continue-on-error: true\n"
         ), package_json},
        {"rule=timings-guard", String.replace(workflow, "if [ -f \"$report\" ] && ", "if "),
         package_json},
        {"rule=timings-artifact",
         String.replace(
           workflow,
           "name: browser-timings-${{ matrix.project }}-",
           "name: browser-durations-${{ matrix.project }}-"
         ), package_json},
        {"rule=timings-artifact",
         String.replace(workflow, upload_header, "      - name: #{@timings_upload}\n"),
         package_json},
        {"rule=timings-retention",
         String.replace(
           workflow,
           "          if-no-files-found: warn\n          retention-days: 14\n",
           "          if-no-files-found: warn\n          retention-days: 90\n"
         ), package_json},
        {"rule=test-unit-wiring", workflow,
         String.replace(package_json, " support/slow-specs.test.ts", "")},
        {"rule=test-unit-wiring", workflow,
         String.replace(package_json, " support/operator-ci-evidence.test.ts", "")}
      ]

      for {rule, mutated_workflow, mutated_package} <- controls do
        refute {mutated_workflow, mutated_package} == {workflow, package_json},
               "mutation anchor missing for #{rule}"

        assert rule in slow_specs_errors(mutated_workflow, mutated_package),
               "#{rule} stayed green under its mutation"
      end

      # Scope control: a timings step outside verify-example-browser does not count.
      job = browser_job_block(workflow)
      step = "      - name: #{@timings_step}\n" <> step_block(job, @timings_step) <> "\n"
      assert String.contains?(workflow, step), "mutation anchor missing for scope control"

      relocated =
        workflow
        |> String.replace(step, "")
        |> String.replace("  ci-required:\n", "  ci-required:\n    steps:\n" <> step)

      assert "rule=timings-step" in slow_specs_errors(relocated, package_json)
    end
  end
end
