defmodule Threadline.AsyncHelpers do
  @moduledoc """
  Determinism helpers for tests that touch background processes, timers, or
  PostgreSQL advisory locks. Imported by `Threadline.DataCase`.

  The goal is to eliminate `Process.sleep`-based timing assumptions and the
  connection-pool/advisory-lock races that make GenServer tests flaky. Prefer
  these helpers over hand-rolled `eventually`/`sleep` loops.
  """

  import ExUnit.Assertions

  @doc """
  Polls `fun` until it returns a truthy value or `:timeout` ms elapse.

  Returns the truthy value on success; `flunk/1`s with `message` on timeout.
  Use this instead of `Process.sleep` + a fixed number of retries — it waits on
  a real deadline, so it is robust to slow CI without being racy on fast
  machines.

      assert_eventually(fn -> Repo.all(RetentionRun) != [] end)
  """
  @spec assert_eventually((-> any()), keyword()) :: any()
  def assert_eventually(fun, opts \\ []) when is_function(fun, 0) do
    timeout = Keyword.get(opts, :timeout, 2_000)
    interval = Keyword.get(opts, :interval, 20)

    message =
      Keyword.get(opts, :message, "assert_eventually: condition not met within #{timeout}ms")

    deadline = System.monotonic_time(:millisecond) + timeout
    do_eventually(fun, deadline, interval, message)
  end

  defp do_eventually(fun, deadline, interval, message) do
    case fun.() do
      result when result not in [nil, false] ->
        result

      _ ->
        if System.monotonic_time(:millisecond) >= deadline do
          flunk(message)
        else
          Process.sleep(interval)
          do_eventually(fun, deadline, interval, message)
        end
    end
  end

  @doc """
  Acquires a session-level PostgreSQL advisory lock on a **dedicated connection**
  (a fresh `Postgrex` session, separate from `repo`'s pool) for the duration of
  `fun`, then releases it.

  Holding the lock on its own session is what makes "skips when the lock is held
  elsewhere" tests deterministic: a pool connection can never share the
  lock-holder's session, so `pg_try_advisory_lock/1` from the pool reliably
  returns false. Acquiring the lock via the repo's own pool (size 2) instead
  races on pool allocation and advisory-lock re-entrancy.
  """
  @spec with_advisory_lock_held(module(), integer(), (-> any())) :: any()
  def with_advisory_lock_held(repo, key, fun) when is_function(fun, 0) do
    conn_opts = Keyword.take(repo.config(), [:hostname, :port, :username, :password, :database])
    {:ok, conn} = Postgrex.start_link(conn_opts)

    try do
      # pg_advisory_lock/1 blocks until acquired and returns void (the dedicated
      # session is uncontended, so this returns immediately).
      Postgrex.query!(conn, "SELECT pg_advisory_lock($1)", [key])
      fun.()
    after
      # Stopping the connection ends its session and releases the lock; the
      # explicit unlock keeps things tidy if the process lingers.
      _ = Postgrex.query(conn, "SELECT pg_advisory_unlock($1)", [key])
      GenServer.stop(conn)
    end
  end

  @doc """
  Synchronously stops the globally-named GenServer if it is running, waiting for
  it to terminate. Use in `setup` to guarantee a process started by a previous
  test (e.g. the singleton `Threadline.Retention.Pruner`) cannot leak work into
  the next test.
  """
  @spec stop_named_process!(GenServer.name()) :: :ok
  def stop_named_process!(name) do
    case Process.whereis(name) do
      nil ->
        :ok

      pid ->
        ref = Process.monitor(pid)
        :ok = GenServer.stop(pid, :normal, 1_000)

        receive do
          {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
        after
          1_000 -> :ok
        end
    end
  end

  @doc """
  Deterministically waits until `name` has processed everything currently in its
  mailbox, including messages it sends to itself while handling them.

  Two `:sys.get_state/1` round-trips are required: a single `get_state` can
  return before a self-sent message (e.g. `handle_cast` → `send(self(),
  :run_purge)`) is processed, because the self-send lands behind the first
  `get_state` call. The second round-trip drains it.
  """
  @spec drain_mailbox(GenServer.name()) :: :ok
  def drain_mailbox(name) do
    _ = :sys.get_state(name)
    _ = :sys.get_state(name)
    :ok
  end
end
