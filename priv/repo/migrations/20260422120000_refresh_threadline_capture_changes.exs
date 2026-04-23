defmodule ThreadlineRefreshCaptureChanges do
  use Ecto.Migration

  @doc """
  Reinstalls `threadline_capture_changes()` so `audit_transactions.actor_ref`
  is populated from the transaction-local GUC `threadline.actor_ref` (D-09).

  Depends on `20260102000000_threadline_semantics_schema.exs` adding the column.
  """

  def up do
    execute(Threadline.Capture.TriggerSQL.install_function([]))
  end

  def down do
    :ok
  end
end
