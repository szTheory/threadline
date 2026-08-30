defmodule ThreadlinePhoenix.Demo.Seed do
  @moduledoc """
  Plants deterministic demo fiction for walkthroughs (`mix demo.seed`).

  Hybrid synthesis: Sigra personas, anchor incidents, PRNG filler, temporal backfill.
  """

  alias ThreadlinePhoenix.Demo.{Reset, Seed}
  alias ThreadlinePhoenix.Repo

  @lock_retry_interval_ms 500
  @lock_retry_max_attempts 90

  @doc """
  Runs the full demo seed pipeline (D-107-04).

  Takes the shared demo seed/reset advisory lock independently of
  `Reset.run/1` — `mix demo.seed` calls this function directly without going
  through `Reset.run/1`, so it must be its own guarded entry point (WR-02).
  The lock is namespaced with `Reset`'s fixed classid (IN-02) and is
  reentrant on the same session, so calling this from within `Reset.run/1`
  (which has already taken the lock) succeeds immediately and cannot
  deadlock.
  """
  @spec run() :: :ok
  def run do
    Reset.assert_dev_or_allowed!()

    with_demo_lock(fn ->
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

  defp with_demo_lock(fun) do
    acquire_demo_lock()

    try do
      fun.()
    after
      Repo.query!("SELECT pg_advisory_unlock($1, $2)", [
        Reset.advisory_lock_classid(),
        Reset.advisory_lock_objid()
      ])
    end

    :ok
  end

  defp acquire_demo_lock(attempts_left \\ @lock_retry_max_attempts) do
    # Defense in depth: bounds any other blocking wait this connection might
    # incur while holding/acquiring the lock, even though `pg_try_advisory_lock/2`
    # itself never blocks — the retry loop below is what actually bounds the wait.
    Repo.query!("SET lock_timeout = '45s'")
    do_acquire_demo_lock(attempts_left)
  end

  defp do_acquire_demo_lock(0) do
    raise RuntimeError,
          "demo seed lock: timed out after #{@lock_retry_max_attempts * @lock_retry_interval_ms}ms " <>
            "waiting for advisory lock (classid=#{Reset.advisory_lock_classid()}, " <>
            "objid=#{Reset.advisory_lock_objid()}) — another session is still holding " <>
            "the demo seed/reset lock"
  end

  defp do_acquire_demo_lock(attempts_left) do
    %{rows: [[acquired]]} =
      Repo.query!("SELECT pg_try_advisory_lock($1, $2)", [
        Reset.advisory_lock_classid(),
        Reset.advisory_lock_objid()
      ])

    if acquired do
      :ok
    else
      Process.sleep(@lock_retry_interval_ms)
      do_acquire_demo_lock(attempts_left - 1)
    end
  end
end
