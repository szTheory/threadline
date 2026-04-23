defmodule Threadline.Telemetry do
  @moduledoc """
  Telemetry integration helpers for Threadline.

  Threadline emits three telemetry events:

  - `[:threadline, :transaction, :committed]` — after an `AuditTransaction` is
    committed. Automatically emitted (with `table_count: 0`) when
    `Threadline.record_action/2` succeeds. For accurate per-transaction counts,
    call `Threadline.Telemetry.transaction_committed/2` explicitly after a known
    DB transaction commit.

  - `[:threadline, :action, :recorded]` — after `Threadline.record_action/2`
    completes (success or failure).

  - `[:threadline, :health, :checked]` — after
    `Threadline.Health.trigger_coverage/1` returns.

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

  @doc false
  def emit_health_checked(covered, uncovered) do
    :telemetry.execute(
      [:threadline, :health, :checked],
      %{covered: covered, uncovered: uncovered},
      %{}
    )
  end
end
