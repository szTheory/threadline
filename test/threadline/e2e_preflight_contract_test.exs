defmodule Threadline.E2ePreflightContractTest do
  @moduledoc """
  Guards the e2e boot preflight in `examples/threadline_phoenix/e2e/run-e2e.sh`.

  ## Why this exists

  D-18 added a preflight so a broken operator-surface mount fails once, loudly, instead of
  letting ~382 Playwright tests each burn a 120s timeout rediscovering it. Phase 198's
  coverage entry 198-05 D3 recorded the check as verified only *syntactically*, and named
  its own hole precisely: `/audit` sits behind `:operator_auth`, so a 3xx was treated as
  healthy — and "if a future auth change makes /audit return 200-with-empty-shell on a
  broken mount, this check would pass wrongly."

  That hole is now closed. A 3xx must be the login redirect specifically, and a 2xx must
  carry the operator shell. This test keeps both halves from being weakened back to a bare
  status-class check, which is the shape they had for two phases and the shape a future
  refactor would naturally reach for.

  The preflight itself is shell that only runs with a booted server, so it cannot be
  exercised from ExUnit. What *can* be enforced mechanically is that its teeth are still
  in the file — which is the difference between a guard and a comment.
  """

  use ExUnit.Case, async: true

  @script "examples/threadline_phoenix/e2e/run-e2e.sh"

  setup_all do
    %{source: File.read!(@script)}
  end

  test "the preflight is still wired into the boot path", %{source: source} do
    assert String.contains?(source, "if ! operator_surface_ready; then"),
           """
           #{@script} no longer calls operator_surface_ready before running the suite.

           Without it a broken mount costs one 120s timeout per test instead of one fast,
           legible failure.
           """
  end

  test "a 3xx only passes when it is the login redirect", %{source: source} do
    assert String.contains?(source, "*/users/log_in*"),
           """
           The preflight accepts any 3xx again.

           A redirect only proves the operator surface is routed and alive if it is the
           :operator_auth redirect to the login page. A 3xx to anywhere else — a catch-all
           route, a stray root redirect — proves nothing about /audit being mounted.
           """

    assert String.contains?(source, "Location"),
           "the preflight must read the Location header to know where the 3xx points"
  end

  test "a 2xx only passes when the body carries the operator shell", %{source: source} do
    for marker <- ["threadline-ui", "tl-main"] do
      assert String.contains?(source, marker),
             """
             The preflight no longer checks the response body for #{inspect(marker)}.

             This is the exact hole 198-05 D3 flagged: a broken mount that answers 200 with
             an empty shell would pass the status check and hand every Playwright test a
             page with nothing to drive. Both markers are asserted by the suite itself, so
             a 200 without them is not a healthy surface.
             """
    end
  end

  test "the preflight does not follow redirects", %{source: source} do
    refute source =~ ~r/curl[^\n]*\s-L\b/,
           """
           The preflight follows redirects (-L).

           Following the :operator_auth redirect lands on the login page, which returns 200
           whether or not /audit is mounted — so the check would pass for a completely
           broken operator surface. The un-followed redirect IS the evidence.
           """
  end
end
