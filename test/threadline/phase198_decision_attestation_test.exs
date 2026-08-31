defmodule Threadline.Phase198DecisionAttestationTest do
  @moduledoc """
  Attests the maintainer decisions Phase 198 recorded verbatim.

  ## Why this test exists

  Phase 198 closed with 36 `human_judgment: true` coverage entries, which
  `/gsd-verify-work` re-presents as manual checkpoints on every single run. Eight of
  those entries are not open questions at all — a maintainer already answered them at a
  recorded gate, and the answer is committed verbatim in an artifact. Their own
  rationales say so: 198-02 D4 states that "a verifier should read the recorded
  confirmation rather than trust a green check."

  This test *is* that read, performed mechanically. It converts "a human should go look
  at the file" into "CI looks at the file on every push," which is the only form of
  verification that does not rot.

  ## What this test does and does not claim

  It asserts that a decision was **recorded**, with its verbatim answer, its date, and
  its attribution intact. It does **not** claim the decision was *correct* — no test can
  adjudicate a policy posture, and pretending otherwise would be the laundering this
  phase's artifacts exist to prevent.

  Its teeth are against a specific, realistic failure: a later edit that silently
  softens, renumbers, retracts, or quietly re-scopes a recorded one-way-door decision.
  Every decision below was taken at a `gate="blocking-human"` checkpoint, which is never
  auto-approved in any mode; losing one to a careless edit should break the build.
  """

  use ExUnit.Case, async: true

  @planning Path.expand("../../.planning", __DIR__)

  defp read!(relative) do
    path = Path.join(@planning, relative)

    assert File.exists?(path),
           """
           Expected a committed decision artifact at #{relative}, but it is missing.

           This test attests maintainer decisions that Phase 198 recorded verbatim at
           blocking-human gates. If this file moved, update the path here in the same
           commit — do not delete the attestation, or the decision it guards becomes
           unverifiable and reverts to a manual UAT checkpoint.
           """

    File.read!(path)
  end

  defp assert_contains(haystack, needle, source, why) do
    assert String.contains?(haystack, needle),
           """
           #{source} no longer contains its recorded decision text.

           Expected to find: #{inspect(needle)}

           Why this matters: #{why}
           """
  end

  describe "198-39: GREEN-07 terminal disposition (one-way door)" do
    setup do
      %{doc: read!("phases/198-green-bringup/198-39-DECISION.md")}
    end

    test "records the maintainer's verbatim selection and its date", %{doc: doc} do
      assert_contains(
        doc,
        "option-a",
        "198-39-DECISION.md",
        "option-a is the maintainer's verbatim answer at the 198-39 Task 1 blocking-human gate."
      )

      assert_contains(
        doc,
        "**Status:** DECIDED",
        "198-39-DECISION.md",
        "A decision that loses its DECIDED status line reads as a draft."
      )

      assert_contains(
        doc,
        "Decided by:",
        "198-39-DECISION.md",
        "Attribution is what separates a recorded maintainer decision from an executor's inference."
      )
    end

    test "names both D-39-forced red lanes and each lane's unblock condition", %{doc: doc} do
      for lane <- ["verify-capture", "verify-example-browser"] do
        assert_contains(
          doc,
          lane,
          "198-39-DECISION.md",
          "Each accepted-Pending lane must stay named, or the disposition stops being auditable."
        )
      end

      assert_contains(
        doc,
        "scroll_cost",
        "198-39-DECISION.md",
        """
        verify-capture's unblock condition names the scroll_cost coupling explicitly. Phase 199
        acts under exactly this clause, so it must remain legible in the record.
        """
      )
    end

    test "option (b) was not selected, and says why it could not have been", %{doc: doc} do
      assert_contains(
        doc,
        "no target milestone",
        "198-39-DECISION.md",
        """
        The record distinguishes a genuine option-a from option-b wearing a different label by
        noting that no target milestone was supplied. That reasoning is the decision's own
        integrity check and must survive edits.
        """
      )
    end
  end

  describe "198-34: export status copy canonicalization" do
    setup do
      %{doc: read!("phases/198-green-bringup/198-34-DECISION.md")}
    end

    test "records option-b and the required sub-disposition", %{doc: doc} do
      assert_contains(
        doc,
        "option-b",
        "198-34-DECISION.md",
        "option-b is the maintainer's selection for the CR-01 round-4 copy contract."
      )

      assert_contains(
        doc,
        "retain-with-reason",
        "198-34-DECISION.md",
        """
        export_action_label/2 is public Hex surface, so its disposition is semver-visible.
        Option B was only valid together with this sub-disposition; dropping it would leave a
        decision that cannot be acted on correctly.
        """
      )
    end
  end

  describe "198-CONTEXT: lane dispositions D-39 through D-42" do
    setup do
      %{doc: read!("phases/198-green-bringup/198-CONTEXT.md")}
    end

    test "all four lane decisions remain recorded", %{doc: doc} do
      for id <- ~w(D-39 D-40 D-41 D-42) do
        assert_contains(
          doc,
          id,
          "198-CONTEXT.md",
          "#{id} was recorded append-only at the 198-20 blocking-human checkpoint."
        )
      end
    end

    test "D-42's standing interlock survives, because nothing else can catch its failure", %{
      doc: doc
    } do
      assert_contains(
        doc,
        "rulesets/main.json",
        "198-CONTEXT.md",
        """
        D-42 requires any change to ci-required's needs: list to be reconciled in the SAME diff
        against .github/rulesets/main.json and CONTRIBUTING.md's CI Coverage table.

        This one is load-bearing: the ruleset names only the single aggregate context
        "CI required", so it CANNOT detect a narrowing of what that aggregate asserts. A
        needs:-only edit is invisible at the protection layer by construction. If this
        interlock is lost from the record, silently dropping a lane becomes undetectable.
        """
      )
    end
  end

  describe "D-30: one-way publication authorization and the F-002/F-003 rider" do
    setup do
      %{doc: read!("audits/198-credential-audit.md")}
    end

    test "the publication authorization is recorded verbatim, dated, and marked one-way", %{
      doc: doc
    } do
      assert_contains(
        doc,
        "## D-30 authorization",
        "198-credential-audit.md",
        "198-02 D4's own rationale directs a verifier to read this section rather than trust a green check."
      )

      assert_contains(
        doc,
        "Publication of `.planning/` history is AUTHORIZED",
        "198-credential-audit.md",
        "This is the authorization itself. It gates an irreversible, outward-facing action."
      )

      assert_contains(
        doc,
        "auto foolow ur recs proceed",
        "198-credential-audit.md",
        """
        The maintainer's confirmation is quoted verbatim, typo included. Verbatim means
        verbatim: tidying this string would substitute the executor's words for the
        maintainer's on a one-way-door decision.
        """
      )

      assert_contains(
        doc,
        "one-way",
        "198-credential-audit.md",
        "The record must keep stating that publication cannot be undone by a history rewrite."
      )
    end

    test "F-002/F-003 stand as Class C with no rotation, and the counts still reconcile", %{
      doc: doc
    } do
      assert_contains(
        doc,
        "Class C stands",
        "198-credential-audit.md",
        "198-02 D3 is the policy call that these two example-app secret_key_base literals are Class C, not Class A."
      )

      assert_contains(
        doc,
        "A = 0 (rotated: 0) · B = 0 · C = 5",
        "198-credential-audit.md",
        """
        The class counts are the audit's verdict in numbers. A fabricated rotation row would
        put a misleading timestamp into a published register — the exact laundering this
        decision refused.
        """
      )
    end
  end

  describe "phase-199 supersession is append-only" do
    test "198-39's terminal disposition is preserved, not rewritten, by the D-39 exception" do
      audit = read!("audits/198-tier-a-byte-stability.md")

      assert_contains(
        audit,
        "Yes — fix cause, then regen",
        "198-tier-a-byte-stability.md",
        "Phase 199's bounded D-39 exception is itself a recorded maintainer decision and is attested the same way."
      )

      decision = read!("phases/198-green-bringup/198-39-DECISION.md")

      assert_contains(
        decision,
        "option-a",
        "198-39-DECISION.md",
        """
        Phase 199 supersedes D-39 under the unblock condition D-39 itself named. It does not
        retract it. If this assertion ever fails alongside a passing one above, someone edited
        a sealed decision instead of appending a new one.
        """
      )
    end
  end
end
