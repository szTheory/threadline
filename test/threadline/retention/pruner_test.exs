defmodule Threadline.Retention.PrunerTest do
  use Threadline.DataCase, async: false

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Governance.RetentionRun
  alias Threadline.Retention.Pruner

  @lock_key :erlang.phash2("threadline_retention_pruner")
  @worker_supervisor Threadline.Retention.PrunerTest.WorkerSupervisor

  setup do
    # The pruner is a singleton (named __MODULE__). A pruner left running by a
    # previous test could insert a RetentionRun into this test after our
    # delete_all, so stop it deterministically before we begin.
    stop_named_process!(Pruner)

    # on_exit runs after ExUnit has stopped the test-owned Pruner and its workers,
    # so a killed worker's queued or running run cannot outlive the test.
    on_exit(fn -> Repo.delete_all(RetentionRun, repo_opts()) end)

    prev = Application.get_env(:threadline, :retention)
    start_supervised!({Task.Supervisor, name: @worker_supervisor})

    on_exit(fn ->
      Application.put_env(:threadline, :retention, prev)
    end)

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: true,
      interval_ms: :timer.hours(24),
      sleep_ms: 0
    )

    :ok
  end

  defp start_application_supervisor!(opts \\ []) do
    retention = Application.get_env(:threadline, :retention, [])

    opts =
      [repo: Threadline.Test.Repo]
      |> Keyword.merge(Keyword.take(retention, [:interval_ms, :sleep_ms]))
      |> Keyword.merge(opts)

    interval_ms = Keyword.get(opts, :interval_ms, :timer.hours(24))
    startup_opts = Keyword.put(opts, :interval_ms, :timer.hours(24))
    pruner = start_supervised!({Threadline.Retention.Pruner, startup_opts})

    :sys.replace_state(pruner, fn state ->
      # Match Task.start's unlinked caller contract while giving ExUnit ownership
      # of workers that may still be purging when this test ends.
      %{
        state
        | interval_ms: interval_ms,
          task_start: &Task.Supervisor.start_child(@worker_supervisor, &1)
      }
    end)

    # Arm short scheduled-prune tests only after worker ownership is installed.
    if interval_ms != :timer.hours(24), do: Process.send_after(pruner, :run_purge, interval_ms)

    pruner
  end

  test "application-owned startup marks running RetentionRuns older than 24h as failed" do
    Repo.delete_all(RetentionRun, repo_opts())

    now = DateTime.utc_now()
    older_than_24h = DateTime.add(now, -25, :hour) |> DateTime.truncate(:microsecond)
    newer_than_24h = DateTime.add(now, -23, :hour) |> DateTime.truncate(:microsecond)

    r1 = Repo.insert!(%RetentionRun{status: "running", started_at: older_than_24h}, repo_opts())
    r2 = Repo.insert!(%RetentionRun{status: "running", started_at: newer_than_24h}, repo_opts())
    r3 = Repo.insert!(%RetentionRun{status: "completed", started_at: older_than_24h}, repo_opts())

    start_application_supervisor!()

    assert Pruner.started?()

    assert Repo.get!(RetentionRun, r1.id, repo_opts()).status == "failed"
    assert Repo.get!(RetentionRun, r1.id, repo_opts()).error_message == "Abandoned"

    assert Repo.get!(RetentionRun, r2.id, repo_opts()).status == "running"
    assert Repo.get!(RetentionRun, r3.id, repo_opts()).status == "completed"
  end

  test "schedules pruning on the named runtime" do
    Repo.delete_all(RetentionRun, repo_opts())

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: true,
      interval_ms: 10,
      sleep_ms: 0
    )

    start_application_supervisor!()

    assert_eventually(
      fn ->
        runs = Repo.all(RetentionRun, repo_opts())
        runs != [] and Enum.any?(runs, fn run -> run.status == "completed" end)
      end,
      message: "scheduled pruner should record a completed RetentionRun"
    )
  end

  test "trigger persists one run before acknowledgement and permits a later deliberate run" do
    Repo.delete_all(RetentionRun, repo_opts())
    start_application_supervisor!()

    pruner = Process.whereis(Pruner)
    :sys.suspend(pruner)
    trigger = Task.async(fn -> Pruner.trigger() end)

    try do
      assert Task.yield(trigger, 50) == nil,
             "trigger must wait for the pruner to finish synchronous acceptance"
    after
      :sys.resume(pruner)
    end

    assert :ok = Task.await(trigger)
    assert [_accepted] = Repo.all(RetentionRun, repo_opts())

    [accepted] = Repo.all(RetentionRun, repo_opts())

    assert_eventually(
      fn ->
        Repo.get!(RetentionRun, accepted.id, repo_opts()).status in ["completed", "failed"]
      end,
      message: "the accepted RetentionRun should reach a terminal state"
    )

    with_advisory_lock_held(Repo, @lock_key, fn ->
      assert :ok = Pruner.trigger()

      assert_eventually(
        fn -> length(Repo.all(RetentionRun, repo_opts())) == 2 end,
        message: "a deliberate request after terminal state should create a new run"
      )

      assert_eventually(
        fn -> Task.Supervisor.children(@worker_supervisor) != [] end,
        message: "the accepted worker must belong to the test supervisor"
      )
    end)
  end

  test "worker startup failure marks the accepted run failed and permits a later request" do
    Repo.delete_all(RetentionRun, repo_opts())
    start_application_supervisor!()

    pruner = Process.whereis(Pruner)

    :sys.replace_state(pruner, fn state ->
      Map.put(state, :task_start, fn _task -> {:error, :system_limit} end)
    end)

    assert :ok = Pruner.trigger()

    assert_eventually(
      fn ->
        case Repo.all(RetentionRun, repo_opts()) do
          [%RetentionRun{status: "failed"}] -> true
          _ -> false
        end
      end,
      message: "a run whose worker cannot start should reach a terminal failure"
    )

    [failed_run] = Repo.all(RetentionRun, repo_opts())
    assert failed_run.error_message == "prune_error"
    assert %DateTime{} = failed_run.completed_at

    assert :ok = Pruner.trigger()

    assert_eventually(
      fn -> length(Repo.all(RetentionRun, repo_opts())) == 2 end,
      message: "a failed worker start must not block a later deliberate run"
    )
  end

  test "rapid triggers coalesce while the accepted run is active" do
    Repo.delete_all(RetentionRun, repo_opts())

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: false,
      interval_ms: :timer.hours(24),
      sleep_ms: 100
    )

    transaction = insert_expired_transaction!()
    insert_expired_change!(transaction)
    start_application_supervisor!()

    assert :ok = Pruner.trigger()

    assert_eventually(
      fn ->
        case Repo.all(RetentionRun, repo_opts()) do
          [%RetentionRun{status: status}] -> status in ["queued", "running"]
          _ -> false
        end
      end,
      message: "accepted run should be visible while active"
    )

    send(Process.whereis(Pruner), :run_purge)

    for _ <- 1..5, do: assert(:ok = Pruner.trigger())

    assert_eventually(
      fn -> Enum.any?(Repo.all(RetentionRun, repo_opts()), &(&1.status == "completed")) end,
      message: "coalesced run should complete"
    )

    assert length(Repo.all(RetentionRun, repo_opts())) == 1
  end

  test "worker failure releases its lock and accepts a later valid run" do
    Repo.delete_all(RetentionRun, repo_opts())

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 0,
      delete_empty_transactions: false,
      interval_ms: :timer.hours(24),
      sleep_ms: 0
    )

    start_application_supervisor!()

    assert :ok = Pruner.trigger()

    assert_eventually(
      fn -> Enum.any?(Repo.all(RetentionRun, repo_opts()), &(&1.status == "failed")) end,
      message: "the worker should persist a terminal failure for an invalid policy"
    )

    [failed_run] = Repo.all(RetentionRun, repo_opts())
    assert failed_run.deleted_count == 0
    assert failed_run.error_message == "invalid_policy"

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: false,
      interval_ms: :timer.hours(24),
      sleep_ms: 0
    )

    assert :ok = Pruner.trigger()

    assert_eventually(
      fn -> Enum.any?(Repo.all(RetentionRun, repo_opts()), &(&1.status == "completed")) end,
      message: "a later run should acquire the released lock and complete"
    )

    assert length(Repo.all(RetentionRun, repo_opts())) == 2
  end

  test "skips purging while the advisory lock is held elsewhere, then resumes after release" do
    Repo.delete_all(RetentionRun, repo_opts())

    # 24h interval so the only prune attempts are the ones we trigger explicitly —
    # no timer-driven runs racing the assertions.
    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: true,
      interval_ms: :timer.hours(24),
      sleep_ms: 0
    )

    start_application_supervisor!()

    # Hold the lock on a dedicated session (outside the repo pool) so the pruner's
    # pg_try_advisory_lock reliably fails — no pool-allocation race.
    with_advisory_lock_held(Repo, @lock_key, fn ->
      Pruner.trigger()

      assert [%RetentionRun{status: "queued"}] = Repo.all(RetentionRun, repo_opts()),
             "accepted work should remain visibly queued while another session holds the execution lock"
    end)

    # Lock released: the accepted run acquires the lock and records completion.
    Pruner.trigger()

    assert_eventually(
      fn -> Enum.any?(Repo.all(RetentionRun, repo_opts()), &(&1.status == "completed")) end,
      message: "the queued RetentionRun should complete once the lock is free"
    )
  end

  test "startup marks abandoned runs only in the selected storage schema" do
    ensure_storage_schema!("audit")

    now = DateTime.utc_now()
    older_than_24h = DateTime.add(now, -25, :hour) |> DateTime.truncate(:microsecond)

    audit_run =
      Repo.insert!(
        %RetentionRun{status: "running", started_at: older_than_24h},
        repo_opts("audit")
      )

    default_run =
      Repo.insert!(%RetentionRun{status: "running", started_at: older_than_24h}, repo_opts())

    start_application_supervisor!(storage_schema: "audit")

    assert Repo.get!(RetentionRun, audit_run.id, repo_opts("audit")).status == "failed"
    assert Repo.get!(RetentionRun, audit_run.id, repo_opts("audit")).error_message == "Abandoned"

    assert Repo.get!(RetentionRun, default_run.id, repo_opts()).status == "running"
    assert Repo.get!(RetentionRun, default_run.id, repo_opts()).error_message == nil
  end

  test "triggered prune records runs only in the selected storage schema" do
    ensure_storage_schema!("audit")

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: true,
      interval_ms: :timer.hours(24),
      sleep_ms: 0
    )

    start_application_supervisor!(storage_schema: "audit")

    Pruner.trigger()
    drain_mailbox(Pruner)

    assert_eventually(
      fn ->
        runs = Repo.all(RetentionRun, repo_opts("audit"))
        runs != [] and Enum.any?(runs, fn run -> run.status == "completed" end)
      end,
      message: "selected-storage pruner should record a completed audit RetentionRun"
    )

    assert Repo.all(RetentionRun, repo_opts()) == []
  end

  defp insert_expired_transaction! do
    Repo.insert!(
      AuditTransaction.changeset(%AuditTransaction{}, %{
        txid: System.unique_integer([:positive]),
        occurred_at: DateTime.utc_now(:microsecond)
      }),
      repo_opts()
    )
  end

  defp insert_expired_change!(transaction) do
    Repo.insert!(
      AuditChange.changeset(%AuditChange{}, %{
        transaction_id: transaction.id,
        table_schema: "public",
        table_name: "pruner_fixture",
        table_pk: %{"id" => Ecto.UUID.generate()},
        op: "insert",
        captured_at: DateTime.add(DateTime.utc_now(:microsecond), -10, :day),
        data_after: %{"expired" => true}
      }),
      repo_opts()
    )
  end
end
