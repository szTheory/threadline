defmodule Threadline.BrowserJourneyEvidenceContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @e2e_root Path.join(@repo_root, "examples/threadline_phoenix/e2e")
  @inventory_path Path.join(@e2e_root, "support/operator-journey-inventory.json")
  @config_path Path.join(@e2e_root, "playwright.config.ts")
  @workflow_path Path.join(@repo_root, ".github/workflows/ci.yml")
  @playwright Path.join(@e2e_root, "node_modules/.bin/playwright")
  @projects ["desktop-chromium", "mobile-chromium"]

  defp read!(path), do: File.read!(path)

  defp inventory! do
    @inventory_path |> read!() |> Jason.decode!()
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

  test "required CI reconciles native evidence and ci-required still fails on every non-success" do
    workflow = read!(@workflow_path)
    config = read!(@config_path)
    [browser_job, required_job] = String.split(workflow, "  ci-required:\n", parts: 2)
    [_, test_workflow] = String.split(workflow, "  verify-test:\n", parts: 2)
    [test_job, _] = String.split(test_workflow, "\n  verify-capture:\n", parts: 2)

    assert test_job =~ "uses: actions/setup-node@"
    assert test_job =~ "cache-dependency-path: examples/threadline_phoenix/e2e/package-lock.json"
    assert test_job =~ "working-directory: examples/threadline_phoenix/e2e\n        run: npm ci"

    assert :binary.match(test_job, "run: npm ci") < :binary.match(test_job, "- name: Run tests"),
           "locked E2E dependencies must be installed before ExUnit invokes Playwright"

    assert browser_job =~ "  verify-example-browser:\n", "stable browser job ID changed"

    assert browser_job =~
             "mix verify.example_browser --project=desktop-chromium --project=mobile-chromium"

    assert browser_job =~
             "PLAYWRIGHT_JSON_OUTPUT_FILE: ${{ runner.temp }}/operator-ci-executed-${{ github.run_id }}.json"

    assert config =~ "process.env.PLAYWRIGHT_JSON_OUTPUT_FILE"
    assert config =~ "[[\"github\"], [\"json\"]]"

    assert browser_job =~
             "./node_modules/.bin/playwright test --list --project=desktop-chromium --project=mobile-chromium"

    assert browser_job =~ "support/operator-ci-evidence.ts --verify"
    assert browser_job =~ "operator-journey-inventory.json"
    assert browser_job =~ "actions/upload-artifact@"
    assert browser_job =~ "retention-days: 14"
    assert browser_job =~ "operator-ci-receipt-${{ github.run_id }}.json"
    refute browser_job =~ "path: examples/threadline_phoenix/e2e/test-results"

    assert required_job =~ "    if: always()"
    assert required_job =~ "      - verify-example-browser"
    assert required_job =~ "jobs: ${{ toJSON(needs) }}"
    assert workflow =~ "\n  ci-required:\n", "stable required job ID changed"
  end
end
