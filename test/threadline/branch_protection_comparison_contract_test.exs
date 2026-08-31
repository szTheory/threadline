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

  # Feed stdin from a temp file rather than a Port: the script reads stdin to EOF either
  # way, and a file makes the redirect explicit and the test readable.
  defp compare(json, args \\ ["CI required"]) do
    path = Path.join(System.tmp_dir!(), "rules_#{System.unique_integer([:positive])}.json")
    File.write!(path, json)

    quoted = Enum.map_join(args, " ", &"'#{&1}'")

    {output, status} =
      System.cmd("bash", ["-c", "#{@script} #{quoted} < #{path}"], stderr_to_stdout: true)

    File.rm(path)
    {status, output}
  end

  describe "the comparison's four edges" do
    test "edge 1 — exactly the expected context passes" do
      assert {0, output} = compare(rules(["CI required"]))
      assert output =~ "OK"
    end

    test "edge 2 — a MISSING context fails" do
      assert {1, output} = compare(rules(["Some Other Check"]))
      assert output =~ "do not match"
    end

    test "edge 3 — ZERO required contexts fails, and says an unprotected branch is not a pass" do
      assert {1, output} = compare(rules([]))
      assert output =~ "ZERO required status-check contexts"

      assert output =~ "must not read as passing",
             "an unprotected branch reading as passing is the worst failure this script has"
    end

    test "edge 4 — an EXTRA context fails (the case Phase 198 could not demonstrate)" do
      assert {1, output} = compare(rules(["CI required", "Some Extra Gate"]))

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
    test "a case difference fails" do
      assert {1, _} = compare(rules(["ci required"]))
    end

    test "a trailing-space difference fails" do
      assert {1, _} = compare(rules(["CI required "]))
    end

    test "a superstring does not satisfy the expected context" do
      assert {1, _} = compare(rules(["CI required (strict)"]))
    end
  end

  describe "unreadable input never reads as passing" do
    test "empty stdin fails" do
      assert {1, output} = compare("")
      assert output =~ "no rules JSON"
    end

    test "malformed JSON fails rather than being treated as zero contexts" do
      assert {1, output} = compare("{not json")
      assert output =~ "not valid JSON"
    end

    test "rules with no required_status_checks rule at all fail as zero contexts" do
      assert {1, output} = compare(Jason.encode!([%{"type" => "deletion"}]))
      assert output =~ "ZERO required status-check contexts"
    end
  end

  describe "the verifier delegates to this script" do
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
  end
end
