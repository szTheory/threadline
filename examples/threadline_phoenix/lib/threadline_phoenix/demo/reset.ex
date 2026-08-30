defmodule ThreadlinePhoenix.Demo.Reset do
  @moduledoc """
  Truncates demo fiction tables and re-runs `ThreadlinePhoenix.Demo.Seed.run/0`.

  Canonical walkthrough recovery is **`mix demo.reset`**. Use **`mix ecto.reset`**
  only when you need schema/trigger recovery (D-107-03c).

  In `MIX_ENV=prod`, raises unless `DEMO_ALLOW_RESET=1` is set.
  """

  alias ThreadlinePhoenix.{Demo, Repo}

  # Postgres advisory locks share one global keyspace per database; namespace
  # demo seed/reset serialization with a fixed Threadline-specific classid so
  # an unrelated tool's unnamespaced integer cannot silently collide and
  # serialize against it (IN-02). `@advisory_lock_objid` distinguishes this
  # lock from any other Threadline might introduce under the same classid.
  @advisory_lock_classid 84_672_301
  @advisory_lock_objid 1
  @lock_retry_interval_ms 500
  @lock_retry_max_attempts 90

  @doc false
  @spec advisory_lock_classid() :: integer()
  def advisory_lock_classid, do: @advisory_lock_classid

  @doc false
  @spec advisory_lock_objid() :: integer()
  def advisory_lock_objid, do: @advisory_lock_objid

  @doc """
  Serializes demo seed/reset work against other demo seed/reset work, on this
  connection or another (WR-01, WR-02).

  Every demo seed/reset entry point takes this lock — `run/1` here,
  `Demo.Seed.run/0`, and the `mix demo.reset` / `mix demo.seed` tasks that
  call them — so a partial guard can never leave an unguarded caller free to
  collide with a guarded one. The surviving contention this guards against
  is cross-OS-process: a parallel CI lane, a developer running
  `mix demo.seed`, or a second `mix test` invocation against the same
  database. ExUnit never runs two `async: false` modules concurrently within
  one `mix test`, so intra-run contention between this module's own callers
  cannot occur — that mechanism was disproven, not merely unlikely.

  Session-scoped, not transaction-scoped: the demo pipeline issues many
  independent `Repo.transaction/1` calls by design (each producing its own
  distinct audit transaction for the seeded fiction), so wrapping the whole
  pipeline in one outer transaction would collapse them into a single
  Postgres transaction and change the shape of the seeded audit trail.
  Rather than relying on commit/rollback for release, the lock is released
  unconditionally in `after`, and `pg_try_advisory_lock/2` is retried in a
  bounded loop (never the blocking, unbounded `pg_advisory_lock/1`) so a
  stranded peer surfaces as a named lock-timeout error within a bounded wait
  rather than an unbounded hang (WR-01).
  """
  @spec with_demo_lock((-> any())) :: :ok
  def with_demo_lock(fun) do
    acquire_demo_lock()

    try do
      fun.()
    after
      Repo.query!("SELECT pg_advisory_unlock($1, $2)", [
        @advisory_lock_classid,
        @advisory_lock_objid
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
            "waiting for advisory lock (classid=#{@advisory_lock_classid}, objid=#{@advisory_lock_objid}) " <>
            "— another session is still holding the demo seed/reset lock"
  end

  defp do_acquire_demo_lock(attempts_left) do
    %{rows: [[acquired]]} =
      Repo.query!("SELECT pg_try_advisory_lock($1, $2)", [
        @advisory_lock_classid,
        @advisory_lock_objid
      ])

    if acquired do
      :ok
    else
      Process.sleep(@lock_retry_interval_ms)
      do_acquire_demo_lock(attempts_left - 1)
    end
  end

  @doc """
  Truncates `@demo_tables` then invokes `Demo.Seed.run/0`.
  """
  @spec run(keyword()) :: :ok
  def run(opts \\ []) do
    unless Keyword.get(opts, :skip_assert, false) do
      assert_dev_or_allowed!()
    end

    with_demo_lock(fn ->
      Repo.query!(Demo.Tables.truncate_sql())
      Demo.Seed.run()
    end)

    :ok
  end

  @doc """
  Raises in `:prod` unless `DEMO_ALLOW_RESET=1` (T-107-03).

  Called from `mix demo.reset` before `app.start` so production fails fast
  without requiring database configuration.
  """
  @spec assert_dev_or_allowed!(atom()) :: :ok
  def assert_dev_or_allowed!(env \\ Mix.env()) do
    if env == :prod and System.get_env("DEMO_ALLOW_RESET") != "1" do
      raise RuntimeError, prod_reset_message()
    end

    :ok
  end

  defp prod_reset_message do
    "demo.reset: in MIX_ENV=prod set DEMO_ALLOW_RESET=1 to confirm this destructive operation."
  end
end
