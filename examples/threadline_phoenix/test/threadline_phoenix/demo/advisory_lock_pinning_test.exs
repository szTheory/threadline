defmodule ThreadlinePhoenix.Demo.AdvisoryLockPinningTest do
  @moduledoc """
  Regression test for CR-01 (`198-REVIEW.md`): falsifies the claim that
  `Reset.with_demo_lock/1`'s nested acquire (the shape `Demo.Reset.run/1` to
  `Demo.Seed.run/0` produces) lands on the same Postgres backend as the
  outer acquire.

  This module deliberately does NOT use `Ecto.Adapters.SQL.Sandbox`'s
  connection-pinning helper (the one that checks out a single connection via
  `DBConnection.Ownership` for a whole `fn -> ... end` block) for the
  assertions under test. That helper structurally hides CR-01 — every
  existing test that exercises this code path (`demo_reset_test.exs`,
  `demo_contract_test.exs`, `walkthrough_case.ex`) wraps the call in it, and
  that pinning is precisely why none of them can observe a
  connection-identity defect. Instead, `setup` below
  puts the repo into `Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)`, which
  makes pool checkouts behave like the real `DBConnection.ConnectionPool`
  path that `mix demo.reset` / `mix demo.seed` use — every `Repo.query!/2`
  call outside an explicit checkout independently checks a connection out of
  and back into the pool, rather than being pinned by a sandbox owner.

  The sandbox mode is process-global for the repo (it is not a per-process
  setting like `start_owner!/2`), so this module is `async: false` and
  restores `:manual` in `on_exit` so no other module inherits `:auto` mode.
  """

  use ExUnit.Case, async: false

  alias ThreadlinePhoenix.Demo.Reset
  alias ThreadlinePhoenix.Repo

  setup do
    Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)
    end)

    :ok
  end

  defp backend_pid do
    %{rows: [[pid]]} = Repo.query!("SELECT pg_backend_pid()")
    pid
  end

  test "nested with_demo_lock/1 pins the whole guarded region to one checked-out connection" do
    refute Repo.checked_out?()

    :ok =
      Reset.with_demo_lock(fn ->
        Process.put(:outer_checked_out, Repo.checked_out?())

        Reset.with_demo_lock(fn ->
          Process.put(:inner_checked_out, Repo.checked_out?())
          :ok
        end)
      end)

    assert Process.get(:outer_checked_out) == true
    assert Process.get(:inner_checked_out) == true
  end

  test "nested guarded region observes the same backend connection identity across an intervening transaction, and a fresh acquire succeeds after release" do
    :ok =
      Reset.with_demo_lock(fn ->
        Process.put(:outer_pid, backend_pid())

        # An intervening database transaction, mirroring the seed pipeline's
        # own many independent `Repo.transaction/1` calls inside the guarded
        # region — its commit boundary must not release the connection pin.
        Repo.transaction(fn -> backend_pid() end)

        Process.put(:mid_pid, backend_pid())

        Reset.with_demo_lock(fn ->
          Process.put(:inner_pid, backend_pid())
          :ok
        end)
      end)

    outer_pid = Process.get(:outer_pid)
    mid_pid = Process.get(:mid_pid)
    inner_pid = Process.get(:inner_pid)

    assert is_integer(outer_pid)
    assert outer_pid == mid_pid
    assert mid_pid == inner_pid

    # After the outer guard returns, its release must have reached the
    # holding backend — a fresh acquire must succeed, proving the nested
    # inner release did not strand the lock on the pinned connection.
    Repo.checkout(fn ->
      %{rows: [[acquired]]} =
        Repo.query!("SELECT pg_try_advisory_lock($1, $2)", [
          Reset.advisory_lock_classid(),
          Reset.advisory_lock_objid()
        ])

      assert acquired == true

      Repo.query!("SELECT pg_advisory_unlock($1, $2)", [
        Reset.advisory_lock_classid(),
        Reset.advisory_lock_objid()
      ])
    end)
  end
end
