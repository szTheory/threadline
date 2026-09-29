defmodule Threadline.BranchProtectionComparisonContractTest do
  @moduledoc """
  Drives `bin/compare-required-contexts` directly against fixtures.

  ## Why this exists

  `bin/verify-branch-protection` asserts that `main`'s live required status-check contexts
  are exactly `["CI required"]`. Phase 198 demonstrated three of its four edges and
  recorded the fourth as an open gap (198-07 D9), honestly:

  > Edge 4 — the extra-context comparison — is NOT demonstrated. It was refused by the
  > execution environment before the ruleset was live, and was deliberately not retried
  > afterwards, because adding a second required context to the branch's sole live
  > protection purely to exercise a test is a change to production protection with no
  > operational justification. The comparison shares a code path with edges 1 and 2, but
  > "the same code path" is an argument, not a demonstration.

  That reasoning was right, and it is why the fix is structural rather than procedural: the
  pure decision now lives in its own script, so every edge is drivable from a fixture with
  no network, no token, and nothing live touched. The extra-context case below is the
  demonstration that was missing.

  This is the `bin/classify-flake-run` / `flake_classifier_contract_test.exs` pattern —
  a behaviour table run against the real script, sub-second, no mocking.

  ## What this does not cover

  Half (b) of the verifier — that the required check name has actually been *emitted* on
  `main`'s head — still needs the live API and is not exercised here.
  """

  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  @script Path.expand("../../bin/compare-required-contexts", __DIR__)

  defp rules(contexts) when is_list(contexts) do
    Jason.encode!([
      %{
        "type" => "required_status_checks",
        "parameters" => %{
          "required_status_checks" =>
            Enum.map(contexts, &%{"context" => &1, "integration_id" => 15_368})
        }
      }
    ])
  end

  defp raw_rules(checks) do
    Jason.encode!([
      %{
        "type" => "required_status_checks",
        "parameters" => %{"required_status_checks" => checks}
      }
    ])
  end

  # Feed stdin from a temp file rather than a Port: the script reads stdin to EOF either
  # way, and a file makes the redirect explicit and the test readable.
  defp compare(tmp_dir, json, args \\ ["CI required@15368"]) do
    path = Path.join(tmp_dir, "rules_#{System.unique_integer([:positive])}.json")
    File.write!(path, json)

    quoted = Enum.map_join(args, " ", &shell_quote/1)

    {output, status} =
      System.cmd("bash", ["-c", "#{@script} #{quoted} < #{shell_quote(path)}"],
        stderr_to_stdout: true
      )

    {status, output}
  end

  # Single-quote wrap with embedded-single-quote escaping, safe for any byte
  # sequence a describe/test name (and therefore an ExUnit tmp_dir path) can
  # contain — e.g. the apostrophe in "the comparison's four edges".
  defp shell_quote(value) when is_binary(value) do
    "'" <> String.replace(value, "'", "'\\''") <> "'"
  end

  describe "the comparison's four edges" do
    test "edge 1 — exactly the expected context passes", %{tmp_dir: tmp_dir} do
      assert {0, output} = compare(tmp_dir, rules(["CI required"]))
      assert output =~ "OK"
    end

    test "edge 2 — a MISSING context fails", %{tmp_dir: tmp_dir} do
      assert {1, output} = compare(tmp_dir, rules(["Some Other Check"]))
      assert output =~ "do not match"
    end

    test "edge 3 — ZERO required contexts fails, and says an unprotected branch is not a pass",
         %{tmp_dir: tmp_dir} do
      assert {1, output} = compare(tmp_dir, rules([]))
      assert output =~ "ZERO required status-check contexts"

      assert output =~ "must not read as passing",
             "an unprotected branch reading as passing is the worst failure this script has"
    end

    test "edge 4 — an EXTRA context fails (the case Phase 198 could not demonstrate)", %{
      tmp_dir: tmp_dir
    } do
      assert {1, output} = compare(tmp_dir, rules(["CI required", "Some Extra Gate"]))

      assert output =~ "do not match",
             """
             A live config carrying MORE required contexts than expected must fail.

             This is 198-07 D9's undemonstrated edge. It matters in both directions: an
             extra context means the live protection has drifted from what the repo's own
             ruleset file declares, and the verifier's whole job is to notice drift rather
             than to confirm a subset.
             """

      assert output =~ "Some Extra Gate",
             "the failure must name the unexpected context, or an operator cannot act on it"
    end
  end

  describe "matching is exact, not fuzzy" do
    test "a case difference fails", %{tmp_dir: tmp_dir} do
      assert {1, _} = compare(tmp_dir, rules(["ci required"]))
    end

    test "a trailing-space difference fails", %{tmp_dir: tmp_dir} do
      assert {1, _} = compare(tmp_dir, rules(["CI required "]))
    end

    test "a superstring does not satisfy the expected context", %{tmp_dir: tmp_dir} do
      assert {1, _} = compare(tmp_dir, rules(["CI required (strict)"]))
    end
  end

  describe "the check is pinned to the GitHub Actions app (integration_id 15368)" do
    test "a pinned check passes", %{tmp_dir: tmp_dir} do
      json = raw_rules([%{"context" => "CI required", "integration_id" => 15_368}])
      assert {0, output} = compare(tmp_dir, json)
      assert output =~ "CI required@15368"
    end

    test "an UNPINNED check fails and reads as @ANY", %{tmp_dir: tmp_dir} do
      json = raw_rules([%{"context" => "CI required"}])
      assert {1, output} = compare(tmp_dir, json)

      assert output =~ "CI required@ANY",
             "an unpinned required check accepts the context from any app or status " <>
               "writer, so it must fail against a pinned expectation"
    end

    test "a check pinned to a different app fails", %{tmp_dir: tmp_dir} do
      json = raw_rules([%{"context" => "CI required", "integration_id" => 12_345}])
      assert {1, output} = compare(tmp_dir, json)
      assert output =~ "CI required@12345"
    end

    test "a null integration_id is unpinned too", %{tmp_dir: tmp_dir} do
      json = raw_rules([%{"context" => "CI required", "integration_id" => nil}])
      assert {1, output} = compare(tmp_dir, json)
      assert output =~ "CI required@ANY"
    end
  end

  describe "unreadable input never reads as passing" do
    test "empty stdin fails", %{tmp_dir: tmp_dir} do
      assert {1, output} = compare(tmp_dir, "")
      assert output =~ "no rules JSON"
    end

    test "malformed JSON fails rather than being treated as zero contexts", %{tmp_dir: tmp_dir} do
      assert {1, output} = compare(tmp_dir, "{not json")
      assert output =~ "not valid JSON"
    end

    test "rules with no required_status_checks rule at all fail as zero contexts", %{
      tmp_dir: tmp_dir
    } do
      assert {1, output} = compare(tmp_dir, Jason.encode!([%{"type" => "deletion"}]))
      assert output =~ "ZERO required status-check contexts"
    end
  end

  describe "the verifier delegates to this script" do
    test "the hosted audit runs after CI so the aggregate check exists" do
      workflow = File.read!(".github/workflows/branch-protection.yml")

      assert workflow =~ "workflow_run:"
      assert workflow =~ ~s(workflows: ["CI"])
      assert workflow =~ "types: [completed]"
      assert workflow =~ "branches: [main]"
      refute Regex.match?(~r/^  push:/m, workflow)
    end

    test "bin/verify-branch-protection expects the pinned pair" do
      source = File.read!("bin/verify-branch-protection")
      assert source =~ ~s(EXPECTED_INTEGRATION_ID="15368")
      assert source =~ ~s(compare-required-contexts" "$EXPECTED_PAIR")
    end

    test "bin/verify-branch-protection calls compare-required-contexts" do
      source = File.read!("bin/verify-branch-protection")

      assert String.contains?(source, "compare-required-contexts"),
             """
             bin/verify-branch-protection no longer delegates its context comparison.

             If the comparison is inlined again, every edge above stops covering the code
             that actually runs in CI, and edge 4 silently returns to being undemonstrated.
             """
    end

    test "both scripts are executable" do
      for script <- ["bin/compare-required-contexts", "bin/verify-branch-protection"] do
        %{mode: mode} = File.stat!(script)

        assert Bitwise.band(mode, 0o111) != 0,
               "#{script} is not executable (mode #{Integer.to_string(mode, 8)})"
      end
    end

    test "classic protection treats only HTTP 404 as absent and fails closed otherwise", %{
      tmp_dir: tmp_dir
    } do
      verifier = Path.expand("../../bin/verify-branch-protection", __DIR__)

      for {http_status, gh_exit, expected_exit} <- [
            {404, 1, 0},
            {429, 1, 1},
            {500, 1, 1},
            {503, 1, 1}
          ] do
        fake_bin =
          Path.join(
            tmp_dir,
            "branch_protection_#{http_status}"
          )

        File.mkdir_p!(fake_bin)
        fake_gh = Path.join(fake_bin, "gh")

        File.write!(
          fake_gh,
          """
          #!/usr/bin/env bash
          case "$*" in
            *"rules/branches/main"*) printf '%s' '[{"type":"required_status_checks","parameters":{"required_status_checks":[{"context":"CI required","integration_id":15368}]}}]' ;;
            *"commits/main"*) printf '%s' 'abc123' ;;
            *"check-runs"*) printf '%s' '{"check_runs":[{"name":"CI required"}]}' ;;
            *"branches/main/protection"*) printf 'HTTP/2.0 #{http_status} Test\\r\\n\\r\\n'; exit #{gh_exit} ;;
            *) exit 2 ;;
          esac
          """
        )

        File.chmod!(fake_gh, 0o755)

        {_output, exit_status} =
          System.cmd("bash", [verifier],
            env: [
              {"GITHUB_REPOSITORY", "example/threadline"},
              {"PATH", fake_bin <> ":" <> System.fetch_env!("PATH")}
            ],
            stderr_to_stdout: true
          )

        assert exit_status == expected_exit, "HTTP #{http_status} produced exit #{exit_status}"
      end
    end

    test "classic protection falls back to branch metadata when REST denies the Actions token",
         %{tmp_dir: tmp_dir} do
      verifier = Path.expand("../../bin/verify-branch-protection", __DIR__)

      scenarios = [
        {"absent", ~s({"protected":true,"protection":{"enabled":false}}), 0, false, 0},
        {"present", ~s({"protected":true,"protection":{"enabled":true}}), 0, false, 1},
        {"unreadable", "not-json", 0, false, 1},
        {"api-error", "", 1, false, 1},
        {"actions-field-omission", ~s({"protected":true}), 0, true, 0},
        {"actions-api-error", "", 1, true, 1}
      ]

      for {scenario, branch_response, branch_exit, allow_unverified, expected_exit} <- scenarios do
        fake_bin =
          Path.join(
            tmp_dir,
            "branch_protection_metadata_#{scenario}"
          )

        File.mkdir_p!(fake_bin)
        fake_gh = Path.join(fake_bin, "gh")

        File.write!(
          fake_gh,
          """
          #!/usr/bin/env bash
          case "$*" in
            *"rules/branches/main"*) printf '%s' '[{"type":"required_status_checks","parameters":{"required_status_checks":[{"context":"CI required","integration_id":15368}]}}]' ;;
            *"commits/main"*) printf '%s' 'abc123' ;;
            *"check-runs"*) printf '%s' '{"check_runs":[{"name":"CI required"}]}' ;;
            *"branches/main/protection"*) printf 'HTTP/2.0 403 Forbidden\\r\\n\\r\\n'; exit 1 ;;
            *"branches/main"*) printf '%s' '#{branch_response}'; exit #{branch_exit} ;;
            *) exit 2 ;;
          esac
          """
        )

        File.chmod!(fake_gh, 0o755)

        {_output, exit_status} =
          System.cmd("bash", [verifier],
            env: [
              {"GITHUB_REPOSITORY", "example/threadline"},
              {"ALLOW_UNVERIFIED_CLASSIC_PROTECTION", if(allow_unverified, do: "1", else: "0")},
              {"PATH", fake_bin <> ":" <> System.fetch_env!("PATH")}
            ],
            stderr_to_stdout: true
          )

        assert exit_status == expected_exit, "#{scenario} produced exit #{exit_status}"
      end
    end
  end
end
