defmodule ThreadlinePhoenix.Demo.Seed do
  @moduledoc """
  Plants deterministic demo fiction for walkthroughs (`mix demo.seed`).

  Hybrid synthesis: Sigra personas, anchor incidents, PRNG filler, temporal backfill.
  """

  alias ThreadlinePhoenix.Demo.{Reset, Seed}

  @doc """
  Runs the full demo seed pipeline (D-107-04).

  Takes the shared demo seed/reset advisory lock through
  `Reset.with_demo_lock/1` — `mix demo.seed` calls this function directly
  without going through `Reset.run/1`, so it must still be its own guarded
  entry point (WR-02), and remains one by delegating to the shared guard
  rather than maintaining a second, independently maintained copy of the
  acquire/retry/release trio (CR-01). The nested case reached from
  `Reset.run/1` (which has already taken the lock inside its own
  `Repo.checkout/2` region) is safe because the outer guard has pinned the
  connection for the whole guarded region, so the nested acquire necessarily
  runs on the same backend — not merely because advisory locks are
  session-scoped.
  """
  @spec run() :: :ok
  def run do
    Reset.assert_dev_or_allowed!()

    Reset.with_demo_lock(fn ->
      :rand.seed(:exsss, {1, 2, 3})

      ctx = %{timestamps: %{}}

      ctx =
        ctx
        |> Seed.Personas.run()
        |> Seed.Exports.run()
        |> Seed.Anchors.run()
        |> Seed.Filler.run()
        |> Seed.Temporal.run()
        |> Seed.RetentionTail.run()
        |> Seed.RetentionRuns.run()

      _ctx = ctx
      Mix.shell().info("demo.seed complete")
    end)

    :ok
  end
end
