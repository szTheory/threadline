defmodule ThreadlinePhoenix.WalkthroughDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @walkthrough Path.expand("../../WALKTHROUGH.md", __DIR__)

  test "WALKTHROUGH.md carries walk-critical literals for RUN-01 self-containment" do
    doc = File.read!(@walkthrough)

    for literal <- [
          "4521",
          "4518",
          "walk-retention-offboarded-co",
          "2026-05-20T14:30:00Z",
          "demo_last_tuesday",
          "demo_epoch",
          "33123cc4-da21-5674-b030-e168cee90521",
          "mix demo.reset",
          "WALK-03-04",
          "--subject retention_run",
          "subject-ref-json"
        ] do
      assert String.contains?(doc, literal),
             "expected WALKTHROUGH.md to include #{inspect(literal)}"
    end
  end

  describe "WALK-01 verify cwd truth" do
    test "WALKTHROUGH optional verify uses mix threadline.verify_coverage" do
      doc = File.read!(@walkthrough)
      section_1 = section_slice(doc, "#### Step WALK-01-02", "#### Step WALK-01-03")
      section_5 = section_slice(doc, "#### Step WALK-04-03", "### §5 Checkpoint")

      assert String.contains?(section_1, "mix threadline.verify_coverage")
      assert String.contains?(section_5, "mix threadline.verify_coverage")
    end

    test "WALKTHROUGH refutes bare mix verify.threadline walk steps" do
      doc = File.read!(@walkthrough)
      refute String.contains?(doc, "mix verify.threadline")
    end

    test "WALKTHROUGH §0 locks examples/threadline_phoenix walk cwd" do
      doc = File.read!(@walkthrough)
      prereq = section_slice(doc, "### Prerequisites", "### Recovery")

      assert String.contains?(prereq, "examples/threadline_phoenix/")
      assert String.contains?(doc, "Walk vs contributor cwd")
    end
  end

  describe "WALK-02 row-history URL truth" do
    test "WALKTHROUGH documents canonical transaction-scoped row history route" do
      doc = File.read!(@walkthrough)

      assert String.contains?(
               doc,
               "/audit/transactions/:id/history/:table/:record_id"
             )
    end

    test "WALK-03-01 and WALK-03-04 Do steps refute pasteable /audit/rows/ URLs" do
      doc = File.read!(@walkthrough)

      walk_0301_do =
        step_do_slice(doc, "#### Step WALK-03-01", "#### Step WALK-03-02")

      walk_0304_do =
        step_do_slice(doc, "#### Step WALK-03-04", "### §4 Checkpoint")

      assert String.contains?(walk_0301_do, "History")
      assert String.contains?(walk_0304_do, "History")

      refute String.contains?(walk_0301_do, "/audit/rows/ticket_replies/")
      refute String.contains?(walk_0304_do, "/audit/rows/ticket_replies/")
    end

    test "WALK-04-02 corroboration avoids bare /audit/rows/ in Do prose" do
      doc = File.read!(@walkthrough)
      walk_0402_do = step_do_slice(doc, "#### Step WALK-04-02", "#### Step WALK-04-03")

      refute String.match?(walk_0402_do, ~r/\/audit\/rows\/ticket_replies\//)
    end

    test "shipped operator surface mounts transaction-scoped history route" do
      router =
        File.read!(
          Path.expand("../../../../lib/threadline/operator_surface/router.ex", __DIR__)
        )

      assert String.contains?(
               router,
               "/transactions/:id/history/:table/:record_id"
             )
    end
  end

  defp section_slice(doc, start_heading, end_heading) do
    doc
    |> String.split(start_heading, parts: 2)
    |> case do
      [_before, rest] ->
        rest
        |> String.split(end_heading, parts: 2)
        |> List.first()

      _ ->
        flunk("start heading #{inspect(start_heading)} not found")
    end
  end

  defp step_do_slice(doc, step_marker, next_marker) do
    doc
    |> String.split(step_marker, parts: 2)
    |> case do
      [_before, rest] ->
        rest
        |> String.split("**Do:**", parts: 2)
        |> case do
          [_pre, after_do] ->
            after_do
            |> String.split(next_marker, parts: 2)
            |> List.first()
            |> String.split("**Expected outcome:**", parts: 2)
            |> List.first()

          _ ->
            flunk("Do block not found after #{inspect(step_marker)}")
        end

      _ ->
        flunk("step marker #{inspect(step_marker)} not found")
    end
  end
end
