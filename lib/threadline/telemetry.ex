defmodule Threadline.Telemetry do
  @moduledoc """
  Telemetry integration helpers for Threadline.

  Threadline emits four telemetry events:

  - `[:threadline, :transaction, :committed]` — after an `AuditTransaction` is
    committed. Automatically emitted (with `table_count: 0`) when
    `Threadline.record_action/2` succeeds. For accurate per-transaction counts,
    call `Threadline.Telemetry.transaction_committed/2` explicitly after a known
    DB transaction commit.

  - `[:threadline, :action, :recorded]` — after `Threadline.record_action/2`
    completes (success or failure).

  - `[:threadline, :health, :checked]` — after
    `Threadline.Health.trigger_coverage/1` returns. Measurements:
    `%{covered: integer, uncovered: integer, expected_uncovered: integer}`.
    The `expected_uncovered` measurement was added in Phase 66 (additive —
    subscribers that destructure only `covered` and `uncovered` keep working).

  - `[:threadline, :health, :checked, :error]` — sibling event emitted when a
    polled coverage check raises (Phase 66 D-30c). Metadata: `%{error: message}`.
    The dashboard keeps the last-good snapshot and reschedules the next poll;
    this event lets adopters alert on transient or sustained failure.

  ## Usage

  Attach handlers in your application's `start/2` callback:

      :telemetry.attach(
        "my-app-audit",
        [:threadline, :action, :recorded],
        &MyApp.Instrumentation.handle_event/4,
        nil
      )
  """

  @doc """
  Emits `[:threadline, :transaction, :committed]` with the given table count.

  Call this after a DB transaction that you know produced `AuditTransaction`
  records, when you need accurate `table_count` measurements.

  ## Example

      {:ok, txn} = MyApp.Repo.transaction(fn ->
        # ... your writes ...
      end)
      Threadline.Telemetry.transaction_committed(txn, table_count: 3)
  """
  def transaction_committed(_transaction, opts \\ []) do
    table_count = Keyword.get(opts, :table_count, 0)
    :telemetry.execute([:threadline, :transaction, :committed], %{table_count: table_count}, %{})
  end

  @doc false
  def emit_action_recorded(status) do
    :telemetry.execute([:threadline, :action, :recorded], %{status: status}, %{})
  end

  @doc false
  def emit_transaction_committed_proxy do
    :telemetry.execute([:threadline, :transaction, :committed], %{table_count: 0}, %{})
  end

  @doc """
  Emits the `[:threadline, :health, :checked]` event with covered / uncovered /
  expected_uncovered measurements.

  Phase 66 added the `expected_uncovered` measurement key (additive). External
  subscribers that destructure only `%{covered: c, uncovered: u}` continue to
  work unchanged.
  """
  def emit_health_checked(covered, uncovered, expected_uncovered) do
    :telemetry.execute(
      [:threadline, :health, :checked],
      %{covered: covered, uncovered: uncovered, expected_uncovered: expected_uncovered},
      %{}
    )
  end

  @doc """
  Emits the `[:threadline, :health, :checked, :error]` event when a polled
  coverage check fails (Phase 66 D-30c). The dashboard keeps the last-good
  snapshot and ALWAYS reschedules the next poll; this event lets adopters
  alert on transient or sustained failure.
  """
  def emit_health_checked_error(error_message) when is_binary(error_message) do
    :telemetry.execute(
      [:threadline, :health, :checked, :error],
      %{},
      %{error: error_message}
    )
  end
end
