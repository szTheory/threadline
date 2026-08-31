defmodule Threadline.CiAttestationContractTest do
  @moduledoc """
  Checks the CI run figures quoted in planning prose against committed attestations.

  ## Why this test exists

  Phase 198's D-01 rule is that only a measured CI run is admissible evidence for the
  GREEN-* requirements. The rule held; the bookkeeping did not scale. Run IDs, per-job
  conclusions, and red/green counts were transcribed by hand into `198-CI-MEASUREMENT.md`,
  `REQUIREMENTS.md`, and `STATE.md` across six measurement rounds. Fifteen of Phase 198's
  36 human-UAT checkpoints existed for no reason other than "a person must go read a CI
  run and vouch for what it said."

  `bin/record-ci-attestation` commits what GitHub actually reported. This test reads those
  attestations back and checks the prose against them, offline and on every push.

  ## The failure it is built to catch

  Not a typo on the day — a reviewer usually catches that. The real failure is **drift**:
  a figure that was accurate when written and quietly became false as later rounds
  superseded it, while the sentence around it still reads as current. That is invisible to
  human review precisely because nothing about the stale sentence looks wrong.

  ## Deliberately offline

  No network, no `gh`, no token. A verification gate that needs credentials is a gate that
  gets skipped on somebody's machine, and a skipped gate is worse than an absent one
  because it still reports green.
  """

  use ExUnit.Case, async: true

  @planning Path.expand("../../.planning", __DIR__)
  @audits Path.join(@planning, "audits")

  # Prose that cites measured CI runs. A run id appearing in any of these must have a
  # committed attestation backing it.
  @prose_sources [
    "REQUIREMENTS.md",
    "STATE.md",
    "phases/198-green-bringup/198-CI-MEASUREMENT.md",
    "phases/198-green-bringup/198-VERIFICATION.md"
  ]

  # GitHub Actions run ids are 11 digits today. Anchoring on a digit-run of this length
  # keeps ordinary numbers (test counts, durations, line numbers) out of the match set.
  @run_id_pattern ~r/\b(3\d{10})\b/

  defp attestations do
    @audits
    |> Path.join("ci-attestation-*.json")
    |> Path.wildcard()
    |> Map.new(fn path ->
      {Path.basename(path, ".json") |> String.replace_prefix("ci-attestation-", ""),
       path |> File.read!() |> Jason.decode!()}
    end)
  end

  defp prose_documents do
    @prose_sources
    |> Enum.map(&{&1, Path.join(@planning, &1)})
    |> Enum.filter(fn {_rel, path} -> File.exists?(path) end)
    |> Enum.map(fn {rel, path} -> {rel, File.read!(path)} end)
  end

  describe "committed attestations" do
    test "every attestation is well-formed and records a completed run" do
      for {run_id, doc} <- attestations() do
        assert doc["schema"] == "threadline.ci-attestation/1",
               "ci-attestation-#{run_id}.json has an unrecognised schema: #{inspect(doc["schema"])}"

        run = doc["run"] || %{}

        assert to_string(run["id"]) == run_id,
               """
               ci-attestation-#{run_id}.json records run id #{inspect(run["id"])}, which does not
               match its own filename. The filename is how prose is joined to evidence, so a
               mismatch silently detaches the attestation from everything citing it.
               """

        assert run["status"] == "completed",
               "ci-attestation-#{run_id}.json records a run that is not completed (#{inspect(run["status"])})"

        for field <- ~w(conclusion head_sha workflow url) do
          refute is_nil(run[field]),
                 "ci-attestation-#{run_id}.json is missing run.#{field}"
        end

        assert is_list(doc["jobs"]) and doc["jobs"] != [],
               "ci-attestation-#{run_id}.json records no jobs, so it attests nothing"
      end
    end

    test "recorded totals agree with the recorded job list" do
      for {run_id, doc} <- attestations() do
        jobs = doc["jobs"]
        totals = doc["totals"] || %{}

        success = Enum.count(jobs, &(&1["conclusion"] == "success"))
        not_success = length(jobs) - success

        assert totals["jobs"] == length(jobs),
               "ci-attestation-#{run_id}.json totals.jobs (#{totals["jobs"]}) disagrees with its own job list (#{length(jobs)})"

        assert totals["success"] == success,
               "ci-attestation-#{run_id}.json totals.success (#{totals["success"]}) disagrees with its own job list (#{success})"

        assert totals["not_success"] == not_success,
               """
               ci-attestation-#{run_id}.json totals.not_success (#{totals["not_success"]}) disagrees
               with its own job list (#{not_success}).

               Only the literal string "success" counts as success (D-09). `neutral`, `skipped`,
               and `cancelled` are all not-success and must never be folded into the success
               count — that is exactly how a red lane gets laundered into a green summary.
               """
      end
    end
  end

  describe "prose is joined to evidence" do
    test "every CI run id cited in planning prose has a committed attestation" do
      known = attestations() |> Map.keys() |> MapSet.new()

      cited =
        for {source, body} <- prose_documents(),
            [_, run_id] <- Regex.scan(@run_id_pattern, body),
            uniq: true,
            do: {run_id, source}

      missing =
        cited
        |> Enum.reject(fn {run_id, _source} -> MapSet.member?(known, run_id) end)
        |> Enum.uniq_by(&elem(&1, 0))

      assert missing == [],
             """
             These CI run ids are cited in planning prose but have no committed attestation:

             #{Enum.map_join(missing, "\n", fn {id, source} -> "  #{id}  (cited in #{source})" end)}

             Record each one so the figures around it can be checked mechanically:

                 bin/record-ci-attestation <run_id>

             Until then those numbers are unverifiable claims, and re-verifying them is manual
             work that has to happen again on every future read.
             """
    end

    test "a run's conclusion in prose matches what the attestation recorded" do
      # Guard the specific, load-bearing claim: a run recorded as `failure` must never be
      # described in prose as having concluded success. This is the direction that matters
      # — overclaiming green is the failure mode the whole D-01 rule exists to prevent.
      for {run_id, doc} <- attestations() do
        conclusion = doc["run"]["conclusion"]

        if conclusion != "success" do
          for {source, body} <- prose_documents(),
              String.contains?(body, run_id) do
            refute body =~
                     ~r/run\s+`?#{run_id}`?[^.\n]{0,80}concluded\s+(the literal string\s+)?`?success`?/i,
                   """
                   #{source} describes run #{run_id} as concluding success, but
                   ci-attestation-#{run_id}.json records its conclusion as #{inspect(conclusion)}.

                   One of the two is wrong. Fix the prose, or re-record the attestation if the
                   run was re-run — never leave them disagreeing.
                   """
          end
        end
      end
    end
  end

  describe "the recorder itself" do
    test "bin/record-ci-attestation is present and executable" do
      script = Path.expand("../../bin/record-ci-attestation", __DIR__)

      assert File.exists?(script),
             "bin/record-ci-attestation is missing — attestations cannot be produced without it"

      %{mode: mode} = File.stat!(script)

      assert Bitwise.band(mode, 0o111) != 0,
             "bin/record-ci-attestation is not executable (mode #{Integer.to_string(mode, 8)})"
    end

    test "it refuses to attest a run that has not completed" do
      script = File.read!(Path.expand("../../bin/record-ci-attestation", __DIR__))

      assert String.contains?(script, ~s|[ "$STATUS" = "completed" ]|),
             """
             bin/record-ci-attestation must refuse to snapshot an in-flight run.

             Attesting a run mid-flight would freeze a partial job list as though it were the
             final result — a green-so-far run recorded as green.
             """
    end
  end
end
